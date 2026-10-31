// Région des Cloud Functions, lue dans le même fichier que l'application :
// config/firebase.json (copié dans lib/ au moment de la compilation).
// Pour migrer, on change ce fichier et rien d'autre.

import { existsSync, readFileSync } from "fs";
import { join } from "path";

function lireRegion(): string {
  const candidats = [join(__dirname, "firebase.json"), join(__dirname, "..", "..", "config", "firebase.json")];
  for (const chemin of candidats) {
    if (existsSync(chemin)) return JSON.parse(readFileSync(chemin, "utf8")).FIREBASE_REGION;
  }
  return "africa-south1";
}

export const REGION = lireRegion();
