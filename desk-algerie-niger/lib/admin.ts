// Libellés et filtres utilisés par l'espace d'administration.

import { SECTEURS, SERVICES } from "./contenu";
import { libelleBudget, LIBELLES_STATUT, type Statut } from "./formulaire";

export const PAYS_FR: Record<string, string> = { DZ: "Algérie", NE: "Niger", autre: "Autre" };
export const PROFILS_FR: Record<string, string> = { algerie: "Entreprise algérienne", niger: "Opérateur nigérien", autre: "Autre" };

export const serviceFr = (c: string | null) => (c ? (SERVICES.find((s) => s.slug === c)?.titre.fr ?? c) : "");
export const secteurFr = (c: string | null) =>
  c === "autre" ? "Autre" : c ? (SECTEURS.find((s) => s.code === c)?.titre.fr ?? c) : "";
export const budgetFr = (c: string | null) => (c ? libelleBudget(c, "fr") : "");
export const statutFr = (s: Statut) => LIBELLES_STATUT[s] ?? s;

export const COULEUR_STATUT: Record<Statut, string> = {
  nouveau: "bg-ocre/15 text-ocre-fort",
  en_cours: "bg-nuit/10 text-encre",
  devis_envoye: "bg-[#2c5aa0]/12 text-[#2c5aa0]",
  gagne: "bg-vert-pale text-vert",
  perdu: "bg-erreur-pale text-erreur",
};

export const dateFr = (iso: string) =>
  new Intl.DateTimeFormat("fr-FR", { dateStyle: "short", timeStyle: "short", timeZone: "Africa/Lome" }).format(new Date(iso));
