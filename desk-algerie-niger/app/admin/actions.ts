"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { headers } from "next/headers";
import { createHash } from "node:crypto";
import { base } from "@/lib/base";
import { STATUTS, type Statut } from "@/lib/formulaire";
import { autoriser } from "@/lib/limite";
import { estConnecte, fermerSession, motDePasseValide, ouvrirSession } from "@/lib/session";

export async function connexion(_etat: { erreur?: string } | undefined, donnees: FormData) {
  const ip = ((await headers()).get("x-forwarded-for") ?? "").split(",")[0].trim();
  const cle = "admin:" + createHash("sha256").update(ip).digest("hex").slice(0, 32);
  if (!autoriser(cle)) return { erreur: "Trop de tentatives. Réessayez dans une heure." };
  const mdp = String(donnees.get("motDePasse") ?? "");
  if (!motDePasseValide(mdp)) return { erreur: "Mot de passe incorrect." };
  await ouvrirSession();
  redirect("/admin");
}

export async function deconnexion() {
  await fermerSession();
  redirect("/admin");
}

async function exigerSession() {
  if (!(await estConnecte())) redirect("/admin");
}

export async function changerStatut(donnees: FormData) {
  await exigerSession();
  const id = String(donnees.get("id"));
  const statut = String(donnees.get("statut")) as Statut;
  if (!STATUTS.includes(statut)) return;
  await base().from("demandes").update({ statut, maj_le: new Date().toISOString() }).eq("id", id);
  revalidatePath("/admin");
  revalidatePath(`/admin/demandes/${id}`);
}

export async function enregistrerNotes(donnees: FormData) {
  await exigerSession();
  const id = String(donnees.get("id"));
  const notes = String(donnees.get("notes") ?? "").slice(0, 10000);
  await base().from("demandes").update({ notes, maj_le: new Date().toISOString() }).eq("id", id);
  revalidatePath(`/admin/demandes/${id}`);
}
