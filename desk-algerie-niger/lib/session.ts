// Session de l'espace d'administration : cookie httpOnly signé (HMAC SHA-256).
// La clé de signature dérive du mot de passe ADMIN_PASSWORD : changer le mot de passe
// déconnecte toutes les sessions ouvertes.

import "server-only";
import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

export const COOKIE = "desk_admin";
const DUREE_S = 8 * 60 * 60; // 8 heures

function cle(): string | null {
  const mdp = process.env.ADMIN_PASSWORD;
  if (!mdp || mdp.length < 12) return null;
  return createHash("sha256").update(`desk-admin:${mdp}`).digest("hex");
}

function signer(valeur: string, k: string) {
  return createHmac("sha256", k).update(valeur).digest("base64url");
}

function egal(a: string, b: string) {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

export function adminConfigure() {
  return cle() !== null;
}

export function motDePasseValide(saisi: string): boolean {
  const mdp = process.env.ADMIN_PASSWORD;
  if (!mdp || !cle()) return false;
  // Comparaison des empreintes pour un temps constant quelle que soit la longueur.
  const a = createHash("sha256").update(saisi).digest("hex");
  const b = createHash("sha256").update(mdp).digest("hex");
  return egal(a, b);
}

export async function ouvrirSession() {
  const k = cle();
  if (!k) throw new Error("ADMIN_PASSWORD absent ou trop court");
  const expire = Math.floor(Date.now() / 1000) + DUREE_S;
  const valeur = `${expire}.${signer(String(expire), k)}`;
  (await cookies()).set(COOKIE, valeur, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    path: "/",
    maxAge: DUREE_S,
  });
}

export async function fermerSession() {
  (await cookies()).delete(COOKIE);
}

export async function estConnecte(): Promise<boolean> {
  const k = cle();
  if (!k) return false;
  const valeur = (await cookies()).get(COOKIE)?.value;
  if (!valeur) return false;
  const [expire, signature] = valeur.split(".");
  if (!expire || !signature) return false;
  if (Number(expire) < Date.now() / 1000) return false;
  return egal(signature, signer(expire, k));
}
