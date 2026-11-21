// Opérations ARZIKI : vente à terme (CLAUDE.md, section 24).
//
// Une opération est un achat-revente :
//   1. le ou les partenaires financiers achètent la marchandise au fournisseur
//      (prix d'achat) et en deviennent propriétaires ;
//   2. ils la revendent à l'entreprise au prix de revente = prix d'achat + majoration,
//      payable à l'échéance.
// La majoration est un montant FIXE en FCFA. ARZIKI est courtier : il perçoit une
// commission, il n'achète ni ne vend la marchandise, et il ne détient jamais l'argent.
//
// Ce fichier ne dépend pas de Firebase : tout est testé (test/operations.test.ts),
// avec les mêmes cas que l'application (test/vecteurs/operations.json).

// ---------------------------------------------------------------------------
// Statuts et transitions (règle R4)
// ---------------------------------------------------------------------------

export const STATUTS = [
  "soumise", // demande envoyée par l'entreprise
  "en_analyse", // vérification par ARZIKI
  "pieces_demandees", // l'entreprise doit compléter son dossier
  "refusee",
  "proposee", // proposée à des partenaires choisis
  "interet_manifeste", // au moins une manifestation d'intérêt (non engageante)
  "signee", // contrats signés devant notaire : seule étape qui engage
  "fournisseur_paye", // fonds versés directement au fournisseur ou au séquestre
  "livree",
  "echeance_payee", // l'entreprise a payé le prix de revente à l'échéance
  "cloturee",
  "en_retard",
  "en_recouvrement",
  "annulee",
] as const;
export type Statut = (typeof STATUTS)[number];

/** Passages autorisés d'un statut à l'autre. */
export const TRANSITIONS: Record<Statut, readonly Statut[]> = {
  soumise: ["en_analyse", "annulee"],
  en_analyse: ["pieces_demandees", "refusee", "proposee", "annulee"],
  pieces_demandees: ["en_analyse", "annulee"],
  refusee: [],
  proposee: ["interet_manifeste", "annulee"],
  interet_manifeste: ["signee", "proposee", "annulee"],
  signee: ["fournisseur_paye", "annulee"],
  fournisseur_paye: ["livree", "en_retard"],
  livree: ["echeance_payee", "en_retard"],
  en_retard: ["echeance_payee", "en_recouvrement"],
  en_recouvrement: ["echeance_payee", "cloturee"],
  echeance_payee: ["cloturee"],
  cloturee: [],
  annulee: [],
};

/** Statuts où l'opération est en cours (pour les tableaux de bord et les plafonds). */
export const STATUTS_EN_COURS: readonly Statut[] = [
  "signee",
  "fournisseur_paye",
  "livree",
  "en_retard",
  "en_recouvrement",
];

export function estStatut(v: unknown): v is Statut {
  return typeof v === "string" && (STATUTS as readonly string[]).includes(v);
}

export class ErreurOperation extends Error {
  constructor(
    message: string,
    public readonly code: "failed-precondition" | "invalid-argument" | "permission-denied" = "failed-precondition",
  ) {
    super(message);
  }
}

// ---------------------------------------------------------------------------
// Garanties OHADA (règle R4)
// ---------------------------------------------------------------------------

export const TYPES_GARANTIE = [
  "reserve_propriete",
  "nantissement_creance",
  "cautionnement",
  "hypotheque",
  "nantissement_materiel",
  "nantissement_fonds_commerce",
] as const;
export type TypeGarantie = (typeof TYPES_GARANTIE)[number];

export const STATUTS_GARANTIE = ["a_constituer", "signee", "inscrite_rccm"] as const;
export type StatutGarantie = (typeof STATUTS_GARANTIE)[number];

export interface Garantie {
  type: TypeGarantie;
  statut: StatutGarantie;
  /** Chemin Cloud Storage de la pièce jointe (acte), jamais un lien public. */
  piece?: string | null;
}

/** Une garantie est constituée quand l'acte est signé (et, le cas échéant, inscrit). */
export function garantieConstituee(g: Garantie): boolean {
  return g.statut === "signee" || g.statut === "inscrite_rccm";
}

// ---------------------------------------------------------------------------
// Calculs (montants entiers en FCFA)
// ---------------------------------------------------------------------------

/** Seuil d'alerte par défaut du coût annuel équivalent, en pourcentage (paramétrable). */
export const SEUIL_ALERTE_COUT_ANNUEL = 24;

export interface Conditions {
  prixAchat: number;
  majoration: number;
  dureeJours: number;
}

function entierPositif(v: number, nom: string, zeroAutorise = false): void {
  if (!Number.isInteger(v) || v < 0 || (!zeroAutorise && v === 0)) {
    throw new ErreurOperation(`${nom} : montant entier ${zeroAutorise ? "positif ou nul" : "strictement positif"} attendu.`, "invalid-argument");
  }
}

export function verifierConditions(c: Conditions): void {
  entierPositif(c.prixAchat, "Prix d'achat");
  entierPositif(c.majoration, "Majoration", true);
  if (!Number.isInteger(c.dureeJours) || c.dureeJours < 1 || c.dureeJours > 365) {
    throw new ErreurOperation("La durée doit être comprise entre 1 et 365 jours.", "invalid-argument");
  }
}

export function prixRevente(c: Conditions): number {
  verifierConditions(c);
  return c.prixAchat + c.majoration;
}

/**
 * Coût annuel équivalent de la majoration, en pourcentage arrondi au centième.
 * Formule simple (sans capitalisation) : majoration / prix d'achat × 365 / durée.
 * Indicateur réservé à l'administrateur : il n'est jamais affiché comme un « taux ».
 */
export function coutAnnuelEquivalent(c: Conditions): number {
  verifierConditions(c);
  return Math.round(((c.majoration / c.prixAchat) * (365 / c.dureeJours) * 100) * 100) / 100;
}

export function alerteCoutAnnuel(c: Conditions, seuil = SEUIL_ALERTE_COUT_ANNUEL): boolean {
  return coutAnnuelEquivalent(c) > seuil;
}

export interface Apport {
  partenaireUid: string;
  /** Part du prix d'achat apportée par ce partenaire. */
  montant: number;
}

export interface Repartition {
  partenaireUid: string;
  montant: number;
  /** Part de la majoration revenant à ce partenaire. */
  partMajoration: number;
  /** Montant total que ce partenaire reçoit à l'échéance. */
  aRecevoir: number;
}

/**
 * Répartit le prix de revente entre les partenaires, au prorata de leurs apports.
 * Les apports doivent couvrir exactement le prix d'achat. Arrondi à l'unité
 * inférieure ; le reliquat d'arrondi va au partenaire au plus gros apport
 * (le premier en cas d'égalité), pour que la somme reste exacte.
 */
export function repartir(c: Conditions, apports: Apport[]): Repartition[] {
  verifierConditions(c);
  if (apports.length === 0) throw new ErreurOperation("Au moins un partenaire est nécessaire.");
  const vus = new Set<string>();
  for (const a of apports) {
    entierPositif(a.montant, "Apport");
    if (vus.has(a.partenaireUid)) throw new ErreurOperation("Un partenaire apparaît deux fois.", "invalid-argument");
    vus.add(a.partenaireUid);
  }
  const total = apports.reduce((s, a) => s + a.montant, 0);
  if (total !== c.prixAchat) {
    throw new ErreurOperation(
      `Les apports (${total} FCFA) doivent couvrir exactement le prix d'achat (${c.prixAchat} FCFA).`,
    );
  }
  const parts = apports.map((a) => Math.floor((a.montant * c.majoration) / c.prixAchat));
  const reliquat = c.majoration - parts.reduce((s, p) => s + p, 0);
  let indexMax = 0;
  apports.forEach((a, i) => {
    if (a.montant > apports[indexMax].montant) indexMax = i;
  });
  parts[indexMax] += reliquat;
  return apports.map((a, i) => ({
    partenaireUid: a.partenaireUid,
    montant: a.montant,
    partMajoration: parts[i],
    aRecevoir: a.montant + parts[i],
  }));
}

// ---------------------------------------------------------------------------
// Changement de statut : conditions
// ---------------------------------------------------------------------------

export interface EtatOperation {
  statut: Statut;
  garanties: Garantie[];
  /** Apports retenus pour la signature (vide avant). */
  apportsRetenus: Apport[];
  prixAchat: number;
  /** Nombre de manifestations d'intérêt reçues. */
  nombreInterets: number;
}

/**
 * Vérifie qu'un passage de statut est permis. Lève une ErreurOperation sinon.
 * - « interet_manifeste » demande au moins une manifestation d'intérêt ;
 * - « signee » demande des apports qui couvrent le prix d'achat et au moins une garantie ;
 * - « fournisseur_paye » demande que toutes les garanties soient constituées.
 */
export function verifierTransition(op: EtatOperation, vers: Statut): void {
  if (!TRANSITIONS[op.statut].includes(vers)) {
    throw new ErreurOperation(`Passage impossible de « ${op.statut} » à « ${vers} ».`);
  }
  if (vers === "interet_manifeste" && op.nombreInterets < 1) {
    throw new ErreurOperation("Aucune manifestation d'intérêt n'a été reçue.");
  }
  if (vers === "signee") {
    const total = op.apportsRetenus.reduce((s, a) => s + a.montant, 0);
    if (total !== op.prixAchat) {
      throw new ErreurOperation("Les apports retenus doivent couvrir exactement le prix d'achat avant la signature.");
    }
    if (op.garanties.length === 0) {
      throw new ErreurOperation("Ajoutez au moins une garantie avant la signature devant notaire.");
    }
  }
  if (vers === "fournisseur_paye" && !op.garanties.every(garantieConstituee)) {
    throw new ErreurOperation("Toutes les garanties doivent être signées avant le paiement au fournisseur.");
  }
}

/** Une opération dont l'échéance est dépassée et non payée passe « en retard ». */
export function doitPasserEnRetard(statut: Statut, echeanceMs: number, maintenantMs: number): boolean {
  return (statut === "fournisseur_paye" || statut === "livree") && maintenantMs > echeanceMs;
}

// ---------------------------------------------------------------------------
// Plafond de partenaires (règle R3)
// ---------------------------------------------------------------------------

export const PLAFOND_PARTENAIRES_DEFAUT = 50;
export const PLAFOND_PARTENAIRES_MAXIMUM = 99;

/** Le plafond réglé par l'administrateur doit rester entre 1 et 99. */
export function verifierPlafondParametre(plafond: number): void {
  if (!Number.isInteger(plafond) || plafond < 1 || plafond > PLAFOND_PARTENAIRES_MAXIMUM) {
    throw new ErreurOperation(
      `Le plafond de partenaires doit être compris entre 1 et ${PLAFOND_PARTENAIRES_MAXIMUM}.`,
      "invalid-argument",
    );
  }
}

/**
 * Peut-on inviter ou activer un partenaire de plus ? On compte les partenaires
 * actifs et les invitations encore valables. Le blocage à 99 s'applique quel que
 * soit le réglage.
 */
export function verifierPlaceDisponible(occupes: number, plafond = PLAFOND_PARTENAIRES_DEFAUT): void {
  verifierPlafondParametre(plafond);
  const limite = Math.min(plafond, PLAFOND_PARTENAIRES_MAXIMUM);
  if (occupes >= limite) {
    throw new ErreurOperation(
      `Plafond atteint : ${limite} partenaires au maximum. Le Cercle reste privé (pas d'appel public à l'épargne).`,
    );
  }
}
