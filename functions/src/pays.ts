// Pays de la sous-région (CLAUDE.md, section 23.1), côté serveur.
// La liste vient de pays.json, produit à partir de lib/core/pays.dart par
// `dart run tool/exporter_pays.dart`. Ne pas modifier pays.json à la main.

import config from "./pays.json";

export interface Pays {
  code: string;
  nom: string;
  indicatif: string;
  longueurNumero: number;
  prefixesNationaux: string[];
  statut: string;
}

export const PAYS: readonly Pays[] = config.pays;
export const PAYS_PAR_DEFAUT: Pays = PAYS.find((p) => p.code === config.parDefaut)!;

export function paysParCode(code: unknown): Pays | undefined {
  return PAYS.find((p) => p.code === code);
}

/** Pays d'un numéro international (+22890123456), d'après son indicatif. */
export function paysDuTelephone(numero: string): Pays | undefined {
  return PAYS.find((p) => numero.startsWith(p.indicatif));
}

/**
 * Contrôle un numéro international : pays connu, ouvert, numéro bien formé.
 * Renvoie un message d'erreur, ou null si le numéro est accepté.
 */
export function erreurTelephone(numero: string, exigerPaysActif = true): string | null {
  const pays = paysDuTelephone(numero);
  if (!pays) return "Ce pays ne fait pas partie de la zone ARZIKI.";
  if (exigerPaysActif && pays.statut !== "actif") {
    return `ARZIKI n'est pas encore ouvert dans ce pays (${pays.nom}).`;
  }
  const national = numero.substring(pays.indicatif.length);
  const forme =
    /^\d+$/.test(national) &&
    national.length === pays.longueurNumero &&
    (pays.prefixesNationaux.length === 0 || pays.prefixesNationaux.some((p) => national.startsWith(p)));
  return forme ? null : `Numéro de téléphone invalide pour ce pays (${pays.nom}).`;
}
