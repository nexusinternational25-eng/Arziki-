// Création du compte super administrateur du propriétaire (une seule fois).
//
// Ce compte n'est jamais créé depuis l'application. Le script s'exécute sur
// l'ordinateur du propriétaire, avec les droits du projet Firebase :
//
//   gcloud auth application-default login
//   cd functions
//   SUPER_ADMIN_EMAIL=adresse@exemple.com GCLOUD_PROJECT=id-du-projet npm run creer-super-admin
//
// Le script affiche un lien pour choisir le mot de passe. À la première
// connexion, la console demande d'activer le double facteur.

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

async function principal(): Promise<void> {
  const email = (process.env.SUPER_ADMIN_EMAIL ?? "").trim().toLowerCase();
  if (!email.includes("@")) {
    throw new Error("Indiquez l'adresse dans la variable SUPER_ADMIN_EMAIL.");
  }
  initializeApp();
  const auth = getAuth();
  const utilisateur = await auth.getUserByEmail(email).catch(() =>
    auth.createUser({ email, displayName: "CEO NEXUS International" }),
  );
  await auth.setCustomUserClaims(utilisateur.uid, { role: "super_admin" });
  const db = getFirestore();
  await db.doc(`users/${utilisateur.uid}`).set(
    {
      role: "super_admin",
      niveau: null,
      statut: "actif",
      kycStatut: "valide",
      prenom: "CEO",
      nom: "NEXUS International",
      email,
      pays: "TG",
      creeLe: FieldValue.serverTimestamp(),
      majLe: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await db.collection("audit").add({
    acteurUid: "script",
    action: "creer_super_admin",
    cible: `users/${utilisateur.uid}`,
    avant: null,
    apres: "super_admin",
    date: FieldValue.serverTimestamp(),
  });
  const lien = await auth.generatePasswordResetLink(email);
  console.log(`Super administrateur prêt : ${email}`);
  console.log(`Choisissez votre mot de passe ici : ${lien}`);
}

principal().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
