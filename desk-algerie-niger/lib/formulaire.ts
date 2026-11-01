// Schéma unique du formulaire de demande, partagé par le navigateur et le serveur.
// Les messages d'erreur sont des codes, traduits dans messages/*.json (formulaire.erreurs).

import { z } from "zod";
import { SERVICES, SECTEURS } from "./contenu";

export const PAYS = ["DZ", "NE", "autre"] as const;
export const PROFILS = ["algerie", "niger", "autre"] as const;
export const LANGUES = ["ar", "fr"] as const;
export const CODES_SERVICES = SERVICES.map((s) => s.slug) as [string, ...string[]];
export const CODES_SECTEURS = ["autre", ...SECTEURS.map((s) => s.code)] as [string, ...string[]];

// Fourchettes de budget : la devise dépend du pays choisi.
export const BUDGETS = {
  DZ: [
    { code: "dzd-1", fr: "Moins de 1 million DZD", ar: "أقل من مليون دج" },
    { code: "dzd-2", fr: "De 1 à 5 millions DZD", ar: "من 1 إلى 5 ملايين دج" },
    { code: "dzd-3", fr: "De 5 à 20 millions DZD", ar: "من 5 إلى 20 مليون دج" },
    { code: "dzd-4", fr: "Plus de 20 millions DZD", ar: "أكثر من 20 مليون دج" },
  ],
  NE: [
    { code: "fcfa-1", fr: "Moins de 5 millions FCFA", ar: "أقل من 5 ملايين فرنك إفريقي" },
    { code: "fcfa-2", fr: "De 5 à 25 millions FCFA", ar: "من 5 إلى 25 مليون فرنك إفريقي" },
    { code: "fcfa-3", fr: "De 25 à 100 millions FCFA", ar: "من 25 إلى 100 مليون فرنك إفريقي" },
    { code: "fcfa-4", fr: "Plus de 100 millions FCFA", ar: "أكثر من 100 مليون فرنك إفريقي" },
  ],
  autre: [
    { code: "eur-1", fr: "Moins de 10 000 EUR", ar: "أقل من 10 000 يورو" },
    { code: "eur-2", fr: "De 10 000 à 50 000 EUR", ar: "من 10 000 إلى 50 000 يورو" },
    { code: "eur-3", fr: "De 50 000 à 200 000 EUR", ar: "من 50 000 إلى 200 000 يورو" },
    { code: "eur-4", fr: "Plus de 200 000 EUR", ar: "أكثر من 200 000 يورو" },
  ],
} as const;

export const CODES_BUDGET = [
  "inconnu",
  ...Object.values(BUDGETS).flatMap((l) => l.map((b) => b.code)),
] as [string, ...string[]];

export function libelleBudget(code: string, langue: "fr" | "ar"): string {
  if (code === "inconnu") return langue === "fr" ? "Je ne sais pas encore" : "لا أعرف بعد";
  for (const liste of Object.values(BUDGETS)) {
    const b = liste.find((x) => x.code === code);
    if (b) return b[langue];
  }
  return code;
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const TELEPHONE = /^\+?[0-9 ().-]{8,20}$/;

const texte = (max: number) => z.string().trim().max(max);
const choixOuVide = (valeurs: readonly [string, ...string[]]) =>
  z.union([z.enum(valeurs), z.literal("")], { error: "choix" });

export const schemaDemande = z
  .object({
    nom: texte(120).min(2, { error: "nom" }),
    entreprise: texte(160),
    fonction: texte(120),
    pays: z.enum(PAYS, { error: "choix" }),
    profil: z.enum(PROFILS, { error: "choix" }),
    service: choixOuVide(CODES_SERVICES),
    secteur: choixOuVide(CODES_SECTEURS),
    budget: choixOuVide(CODES_BUDGET),
    email: texte(160).refine((v) => v === "" || EMAIL.test(v), { error: "email" }),
    telephone: texte(30).refine((v) => v === "" || TELEPHONE.test(v), { error: "telephone" }),
    message: z.string().trim().max(4000, { error: "message" }),
    languePreferee: z.enum(LANGUES, { error: "choix" }),
    consentement: z.boolean().refine((v) => v === true, { error: "consentement" }),
    // Piège à robots : un humain ne voit pas ce champ et le laisse vide.
    siteWeb: z.string().max(200).optional(),
    // Page d'où vient la demande (renseignée automatiquement).
    source: texte(200).optional(),
  })
  .superRefine((d, ctx) => {
    if (d.email === "" && d.telephone === "") {
      ctx.addIssue({ code: "custom", path: ["email"], message: "contact" });
      ctx.addIssue({ code: "custom", path: ["telephone"], message: "contact" });
    }
  });

export type Demande = z.infer<typeof schemaDemande>;

export const STATUTS = ["nouveau", "en_cours", "devis_envoye", "gagne", "perdu"] as const;
export type Statut = (typeof STATUTS)[number];

export const LIBELLES_STATUT: Record<Statut, string> = {
  nouveau: "Nouveau",
  en_cours: "En cours",
  devis_envoye: "Devis envoyé",
  gagne: "Gagné",
  perdu: "Perdu",
};
