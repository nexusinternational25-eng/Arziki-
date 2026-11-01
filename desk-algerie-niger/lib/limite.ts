// Limitation de débit très simple, en mémoire : 5 demandes par heure et par adresse IP.
// Sur Vercel, chaque instance garde sa propre mémoire : c'est un frein contre les abus,
// pas une barrière absolue (le piège à robots et Turnstile complètent la protection).

const FENETRE_MS = 60 * 60 * 1000;
const MAXIMUM = 5;
const essais = new Map<string, number[]>();

export function autoriser(cle: string): boolean {
  const maintenant = Date.now();
  const recents = (essais.get(cle) ?? []).filter((t) => maintenant - t < FENETRE_MS);
  if (recents.length >= MAXIMUM) {
    essais.set(cle, recents);
    return false;
  }
  recents.push(maintenant);
  essais.set(cle, recents);
  // Nettoyage occasionnel pour ne pas garder des adresses inutiles en mémoire.
  if (essais.size > 5000) {
    for (const [k, v] of essais) if (v.every((t) => maintenant - t >= FENETRE_MS)) essais.delete(k);
  }
  return true;
}
