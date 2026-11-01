// Vérification du numéro de téléphone par WhatsApp (décision du propriétaire,
// 1er novembre 2026 : WhatsApp d'abord, SMS en secours). Voir CLAUDE.md, section 22.3.
//
// Deux façons de vérifier un numéro par WhatsApp :
//   1. « message » : le client envoie lui-même, depuis son WhatsApp, un message
//      déjà rédigé contenant un code. Meta nous transmet ce message (webhook) :
//      seul le vrai propriétaire du compte WhatsApp peut écrire depuis ce numéro.
//      Recevoir un message ne coûte rien à ARZIKI.
//   2. « code » : ARZIKI envoie un code à 6 chiffres par WhatsApp (modèle
//      d'authentification approuvé par Meta), le client le recopie.
// Le SMS reste géré par Firebase Authentication (dernier recours).
//
// Ce fichier ne dépend pas de Firebase : tout y est testable (test/whatsapp.test.ts).

import { createHash, createHmac, randomBytes, randomInt, timingSafeEqual } from "crypto";

import { normaliserTelephone } from "./acces";

export type CanalWhatsapp = "message" | "code";
export type StatutVerification = "en_attente" | "confirmee" | "utilisee" | "bloquee";

/** Un code est valable 10 minutes. */
export const DUREE_VALIDITE_MS = 10 * 60 * 1000;
/** Au plus 5 demandes de vérification par numéro et par heure. */
export const MAX_DEMANDES_PAR_HEURE = 5;
/** Au plus 5 essais de code par vérification. */
export const MAX_ESSAIS = 5;

/** Document verifications/{id} (jamais lisible ni modifiable par l'application). */
export interface VerificationDoc {
  telephone: string;
  canal: CanalWhatsapp;
  codeHache: string;
  sel: string;
  creeLeMs: number;
  expireLeMs: number;
  essais: number;
  statut: StatutVerification;
}

export function genererCode(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, "0");
}

export function genererSel(): string {
  return randomBytes(16).toString("hex");
}

/** Le code n'est jamais stocké en clair. */
export function hacherCode(code: string, sel: string): string {
  return createHash("sha256").update(`${sel}:${code}`).digest("hex");
}

export function codeCorrespond(code: string, doc: Pick<VerificationDoc, "codeHache" | "sel">): boolean {
  const a = Buffer.from(hacherCode(code.trim(), doc.sel), "hex");
  const b = Buffer.from(doc.codeHache, "hex");
  return a.length === b.length && timingSafeEqual(a, b);
}

/** Texte du message que le client envoie depuis son WhatsApp. */
export function messageAEnvoyer(code: string): string {
  return `Bonjour ARZIKI, voici mon code de vérification : ${code}`;
}

/** Lien qui ouvre WhatsApp avec le message déjà écrit, adressé au numéro d'ARZIKI. */
export function lienWhatsapp(numeroArziki: string, texte: string): string {
  const chiffres = numeroArziki.replace(/\D/g, "");
  return `https://wa.me/${chiffres}?text=${encodeURIComponent(texte)}`;
}

/** Retrouve le code à 6 chiffres dans un message reçu. */
export function extraireCode(texte: string): string | null {
  const m = /(?:^|\D)(\d{6})(?:\D|$)/.exec(texte);
  return m ? m[1] : null;
}

/**
 * Vérifie que la requête vient bien de Meta : en-tête X-Hub-Signature-256,
 * HMAC SHA-256 du corps brut avec le secret de l'application Meta.
 */
export function signatureValide(corpsBrut: Buffer, entete: string | undefined, secretApp: string): boolean {
  if (!entete || !entete.startsWith("sha256=") || !secretApp) return false;
  const attendu = Buffer.from(createHmac("sha256", secretApp).update(corpsBrut).digest("hex"), "hex");
  const recu = Buffer.from(entete.slice("sha256=".length), "hex");
  return attendu.length === recu.length && timingSafeEqual(attendu, recu);
}

export interface MessageRecu {
  /** Numéro de l'expéditeur, au format +228XXXXXXXX. */
  de: string;
  texte: string;
}

/** Extrait les messages texte d'une notification WhatsApp Business (format Meta). */
export function extraireMessages(charge: unknown): MessageRecu[] {
  const resultat: MessageRecu[] = [];
  const entrees = (charge as { entry?: unknown[] })?.entry;
  if (!Array.isArray(entrees)) return resultat;
  for (const entree of entrees) {
    const changements = (entree as { changes?: unknown[] })?.changes;
    if (!Array.isArray(changements)) continue;
    for (const changement of changements) {
      const messages = (changement as { value?: { messages?: unknown[] } })?.value?.messages;
      if (!Array.isArray(messages)) continue;
      for (const m of messages) {
        const msg = m as { from?: unknown; type?: unknown; text?: { body?: unknown } };
        if (msg.type !== "text" || typeof msg.from !== "string" || typeof msg.text?.body !== "string") continue;
        resultat.push({ de: normaliserTelephone(`+${msg.from.replace(/\D/g, "")}`), texte: msg.text.body });
      }
    }
  }
  return resultat;
}

/** Garde seulement les demandes de la dernière heure ; refuse au-delà de la limite. */
export function demandesRecentes(horodatages: number[], maintenantMs: number): number[] {
  const recentes = horodatages.filter((t) => t > maintenantMs - 60 * 60 * 1000);
  if (recentes.length >= MAX_DEMANDES_PAR_HEURE) {
    throw new ErreurVerification("Trop de demandes pour ce numéro. Réessayez dans une heure.", "resource-exhausted");
  }
  return [...recentes, maintenantMs];
}

export class ErreurVerification extends Error {
  constructor(
    message: string,
    public readonly code: "failed-precondition" | "permission-denied" | "resource-exhausted" | "not-found" = "failed-precondition",
  ) {
    super(message);
  }
}

export type ResultatFinalisation =
  | { etat: "en_attente" }
  | { etat: "valide"; telephone: string; maj: Partial<VerificationDoc> }
  | { etat: "refuse"; message: string; maj: Partial<VerificationDoc> };

/**
 * Décide si une vérification peut être utilisée pour se connecter.
 * - canal « message » : il faut que le webhook ait reçu le message (statut confirmee) ;
 * - canal « code » : le code saisi doit correspondre (5 essais au plus).
 * Une vérification ne sert qu'une seule fois.
 */
export function finaliser(doc: VerificationDoc, maintenantMs: number, code?: string): ResultatFinalisation {
  if (doc.statut === "utilisee") return { etat: "refuse", message: "Cette vérification a déjà été utilisée.", maj: {} };
  if (doc.statut === "bloquee") return { etat: "refuse", message: "Trop d'essais. Recommencez la vérification.", maj: {} };
  if (maintenantMs > doc.expireLeMs) return { etat: "refuse", message: "Le délai est dépassé. Recommencez la vérification.", maj: {} };

  if (doc.canal === "message") {
    if (doc.statut !== "confirmee") return { etat: "en_attente" };
    return { etat: "valide", telephone: doc.telephone, maj: { statut: "utilisee" } };
  }

  if (!code || !/^\d{6}$/.test(code.trim())) return { etat: "refuse", message: "Saisissez le code à 6 chiffres.", maj: {} };
  if (!codeCorrespond(code, doc)) {
    const essais = doc.essais + 1;
    return {
      etat: "refuse",
      message: essais >= MAX_ESSAIS ? "Trop d'essais. Recommencez la vérification." : "Code incorrect.",
      maj: { essais, ...(essais >= MAX_ESSAIS ? { statut: "bloquee" as const } : {}) },
    };
  }
  return { etat: "valide", telephone: doc.telephone, maj: { statut: "utilisee" } };
}

/** Un message reçu confirme-t-il cette vérification ? */
export function messageConfirme(doc: VerificationDoc, message: MessageRecu, maintenantMs: number): boolean {
  if (doc.canal !== "message" || doc.statut !== "en_attente" || maintenantMs > doc.expireLeMs) return false;
  if (doc.telephone !== message.de) return false;
  const code = extraireCode(message.texte);
  return code !== null && codeCorrespond(code, doc);
}

/**
 * Corps de la requête à l'API WhatsApp Cloud pour envoyer un code
 * (modèle d'authentification « arziki_code », en français, avec bouton « Copier le code »).
 */
export function corpsModeleCode(telephone: string, code: string, nomModele = "arziki_code") {
  return {
    messaging_product: "whatsapp",
    to: telephone.replace(/\D/g, ""),
    type: "template",
    template: {
      name: nomModele,
      language: { code: "fr" },
      components: [
        { type: "body", parameters: [{ type: "text", text: code }] },
        { type: "button", sub_type: "url", index: "0", parameters: [{ type: "text", text: code }] },
      ],
    },
  };
}
