// Règles d'accès ARZIKI, sans dépendance à Firebase pour pouvoir les tester.
// Elles sont identiques à celles de l'application (lib/comptes/depot_comptes.dart,
// classe ReglesAcces). Toute modification doit être faite des deux côtés.
// Voir CLAUDE.md, sections 2 et 21.

import { randomInt } from "crypto";

export const ROLES = [
  "super_admin",
  "admin",
  "analyste",
  "entreprise",
  "membre",
  "partenaire",
  "partenaire_strategique",
  "fournisseur",
  "notaire",
  "candidat_cercle",
] as const;
export type Role = (typeof ROLES)[number];

export const NIVEAUX = ["membre", "partenaire", "partenaire_strategique"] as const;
export type Niveau = (typeof NIVEAUX)[number];

/** Rôles de l'administration : console web, e-mail + double facteur. */
export const ROLES_ADMINISTRATION: readonly Role[] = ["super_admin", "admin", "analyste"];

/** Rôles qui peuvent valider des comptes, inviter, admettre. */
export const ROLES_VALIDATEURS: readonly Role[] = ["super_admin", "admin"];

/** Rôles qu'une personne peut se donner elle-même à l'inscription (statut en_attente). */
export const ROLES_INSCRIPTION_LIBRE: readonly Role[] = ["entreprise", "fournisseur", "notaire", "candidat_cercle"];

/** Au-delà de 100 personnes sans lien juridique : appel public à l'épargne (UMOA). */
export const LIMITE_TAILLE_CERCLE = 100;
export const SEUIL_ALERTE_TAILLE_CERCLE = 90;

export class ErreurAcces extends Error {
  constructor(
    message: string,
    public readonly code: "permission-denied" | "invalid-argument" | "failed-precondition" | "not-found" = "permission-denied",
  ) {
    super(message);
  }
}

export interface Acteur {
  uid: string;
  role: Role | undefined;
  /** Vrai si la connexion a utilisé le double facteur. */
  doubleFacteur: boolean;
}

export function estRole(valeur: unknown): valeur is Role {
  return typeof valeur === "string" && (ROLES as readonly string[]).includes(valeur);
}

export function estNiveau(valeur: unknown): valeur is Niveau {
  return typeof valeur === "string" && (NIVEAUX as readonly string[]).includes(valeur);
}

/** Toute action d'administration exige le rôle et le double facteur. */
export function exigerAdministration(acteur: Acteur, roles: readonly Role[], exigerDoubleFacteur: boolean): void {
  if (!acteur.role || !roles.includes(acteur.role)) {
    throw new ErreurAcces("Action réservée aux administrateurs.");
  }
  if (exigerDoubleFacteur && !acteur.doubleFacteur) {
    throw new ErreurAcces("Connexion avec double facteur obligatoire pour cette action.");
  }
}

/**
 * Qui peut donner quel rôle :
 * - personne ne change son propre rôle ;
 * - le rôle super_admin ne se donne jamais depuis l'application ;
 * - seul un super_admin donne ou retire un rôle d'administration.
 */
export function exigerDroitAttribution(acteur: Acteur, cibleUid: string, roleActuel: Role | undefined, nouveauRole: Role): void {
  if (acteur.uid === cibleUid) {
    throw new ErreurAcces("Vous ne pouvez pas modifier votre propre rôle.");
  }
  if (nouveauRole === "super_admin") {
    throw new ErreurAcces("Le rôle de super administrateur ne se donne pas depuis l'application.");
  }
  const toucheAdministration =
    ROLES_ADMINISTRATION.includes(nouveauRole) || (roleActuel !== undefined && ROLES_ADMINISTRATION.includes(roleActuel));
  if (toucheAdministration && acteur.role !== "super_admin") {
    throw new ErreurAcces("Seul le super administrateur gère les comptes d'administration.");
  }
}

/** Format international : +228XXXXXXXX. */
export function normaliserTelephone(brut: string): string {
  const chiffres = (brut ?? "").replace(/[^0-9+]/g, "");
  if (chiffres.startsWith("+")) return chiffres;
  if (chiffres.startsWith("00")) return `+${chiffres.substring(2)}`;
  return `+228${chiffres}`;
}

/** Code lisible, sans caractères ambigus : ARZ-7KQM-3XWP. */
export function genererCodeInvitation(): string {
  const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
  const bloc = () => Array.from({ length: 4 }, () => alphabet[randomInt(alphabet.length)]).join("");
  return `ARZ-${bloc()}-${bloc()}`;
}

export interface InvitationDoc {
  pourNom: string;
  pourTelephone: string;
  niveau: Niveau;
  creePar: string;
  creeLe: Date;
  expireLe: Date;
  utiliseLe?: Date | null;
  utilisePar?: string | null;
  annuleeLe?: Date | null;
}

/**
 * Une invitation est utilisable si elle existe, n'est ni utilisée, ni annulée, ni expirée,
 * et si le numéro (vérifié par SMS par Firebase Auth) est celui de la personne invitée.
 * Le message est le même dans tous les cas : on ne révèle pas si un code existe.
 */
export function verifierInvitation(inv: InvitationDoc | undefined, telephoneVerifie: string | undefined, maintenant: Date): InvitationDoc {
  const refus = new ErreurAcces(
    "Ce code d'invitation n'est pas valable pour ce numéro. Vérifiez-le ou contactez la personne qui vous a invité.",
    "failed-precondition",
  );
  if (!inv || inv.utiliseLe || inv.annuleeLe || maintenant > inv.expireLe) throw refus;
  if (!telephoneVerifie || normaliserTelephone(telephoneVerifie) !== inv.pourTelephone) throw refus;
  return inv;
}

/** Statut du compte après une décision, selon l'identité et l'admission. */
export function statutApres(role: Role, kycStatut: string): "actif" | "en_attente" {
  if (role === "candidat_cercle") return "en_attente";
  return kycStatut === "valide" ? "actif" : "en_attente";
}
