// Cloud Functions ARZIKI : comptes et accès (jalon 2).
// Chaque fonction vérifie le rôle de l'appelant et écrit au journal d'audit.
// L'application mobile ne décide jamais seule d'un rôle ou d'un statut.

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import {
  Acteur,
  ErreurAcces,
  InvitationDoc,
  LIMITE_TAILLE_CERCLE,
  NIVEAUX,
  ROLES_INSCRIPTION_LIBRE,
  ROLES_VALIDATEURS,
  Role,
  estNiveau,
  estRole,
  exigerAdministration,
  exigerDroitAttribution,
  genererCodeInvitation,
  normaliserTelephone,
  statutApres,
  verifierInvitation,
} from "./acces";
import { ecrireAudit } from "./audit";
import { REGION } from "./region";

initializeApp();
setGlobalOptions({ region: REGION, maxInstances: 10 });

const db = getFirestore();
const enEmulateur = process.env.FUNCTIONS_EMULATOR === "true";

// App Check (Play Integrity sur Android, reCAPTCHA sur la console) et double facteur
// des administrateurs : obligatoires en production, assouplis sur les émulateurs locaux.
const options = { enforceAppCheck: !enEmulateur };
const EXIGER_DOUBLE_FACTEUR = !enEmulateur;

// ---------------------------------------------------------------------------
// Outils communs
// ---------------------------------------------------------------------------

function acteurDe(req: CallableRequest): Acteur {
  if (!req.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const role = req.auth.token.role;
  const facteur = (req.auth.token.firebase as { sign_in_second_factor?: string } | undefined)?.sign_in_second_factor;
  return { uid: req.auth.uid, role: estRole(role) ? role : undefined, doubleFacteur: Boolean(facteur) };
}

function administrateur(req: CallableRequest, roles: readonly Role[] = ROLES_VALIDATEURS): Acteur {
  const acteur = acteurDe(req);
  exigerAdministration(acteur, roles, EXIGER_DOUBLE_FACTEUR);
  return acteur;
}

function texte(valeur: unknown, champ: string, min = 1, max = 200): string {
  if (typeof valeur !== "string" || valeur.trim().length < min || valeur.trim().length > max) {
    throw new HttpsError("invalid-argument", `Champ « ${champ} » invalide.`);
  }
  return valeur.trim();
}

/** Transforme les erreurs métier en erreurs lisibles par l'application. */
function proteger<T>(gestionnaire: (req: CallableRequest) => Promise<T>) {
  return async (req: CallableRequest): Promise<T> => {
    try {
      return await gestionnaire(req);
    } catch (e) {
      if (e instanceof ErreurAcces) throw new HttpsError(e.code, e.message);
      throw e;
    }
  };
}

/** Le rôle officiel est dans les custom claims ; on le recopie dans users/{uid} pour l'affichage. */
async function poserRole(uid: string, role: Role): Promise<void> {
  await getAuth().setCustomUserClaims(uid, { role });
}

async function lireProfil(uid: string) {
  const snap = await db.doc(`users/${uid}`).get();
  if (!snap.exists) throw new ErreurAcces("Compte introuvable.", "not-found");
  return snap.data() as { role: Role; statut: string; kycStatut: string; telephone?: string };
}

async function tailleDuCercle(): Promise<number> {
  const agg = await db
    .collection("users")
    .where("role", "in", [...NIVEAUX])
    .where("statut", "in", ["actif", "en_attente"])
    .count()
    .get();
  return agg.data().count;
}

// ---------------------------------------------------------------------------
// Inscription (après vérification du numéro par SMS dans Firebase Auth)
// ---------------------------------------------------------------------------

export const inscrire = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const telephone = req.auth?.token.phone_number as string | undefined;
    if (!telephone) throw new HttpsError("failed-precondition", "Numéro de téléphone non vérifié.");
    const { parcours, codeInvitation, cgVersion } = req.data ?? {};
    texte(cgVersion, "version des conditions", 1, 40);

    const refProfil = db.doc(`users/${acteur.uid}`);
    return db.runTransaction(async (tx) => {
      if ((await tx.get(refProfil)).exists) {
        throw new ErreurAcces("Ce numéro a déjà un compte.", "failed-precondition");
      }

      let role: Role;
      let code: string | null = null;
      if (parcours === "invitation") {
        // Cercle fermé : code nominatif, lié au numéro vérifié par SMS.
        code = texte(codeInvitation, "code d'invitation", 5, 20).toUpperCase();
        const refInv = db.doc(`invitations/${code}`);
        const snap = await tx.get(refInv);
        const brut = snap.data();
        const inv = brut ? convertirInvitation(brut) : undefined;
        role = verifierInvitation(inv, telephone, new Date()).niveau;
        tx.update(refInv, { utiliseLe: FieldValue.serverTimestamp(), utilisePar: acteur.uid });
      } else {
        const roles: Record<string, Role> = {
          entreprise: "entreprise",
          candidature: "candidat_cercle",
          fournisseur: "fournisseur",
          notaire: "notaire",
        };
        role = roles[parcours as string];
        if (!role || !ROLES_INSCRIPTION_LIBRE.includes(role)) {
          throw new ErreurAcces("Parcours d'inscription inconnu.", "invalid-argument");
        }
      }

      tx.create(refProfil, {
        role,
        niveau: estNiveau(role) ? role : null,
        statut: "en_attente",
        kycStatut: "non_commence",
        telephone: normaliserTelephone(telephone),
        pays: "TG",
        nom: "",
        prenom: "",
        invitationCode: code,
        cgVersionAcceptee: cgVersion,
        cgAccepteeLe: FieldValue.serverTimestamp(),
        creeLe: FieldValue.serverTimestamp(),
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "inscription", `users/${acteur.uid}`, null, `${role} (${parcours})`);
      if (code) ecrireAudit(tx, acteur.uid, "utiliser_invitation", `invitations/${code}`);
      return { role };
    }).then(async (resultat) => {
      await poserRole(acteur.uid, resultat.role);
      return resultat;
    });
  }),
);

function convertirInvitation(d: FirebaseFirestore.DocumentData): InvitationDoc {
  const date = (v: unknown) => (v instanceof Timestamp ? v.toDate() : (v as Date | null | undefined));
  return {
    pourNom: d.pourNom,
    pourTelephone: d.pourTelephone,
    niveau: d.niveau,
    creePar: d.creePar,
    creeLe: date(d.creeLe) as Date,
    expireLe: date(d.expireLe) as Date,
    utiliseLe: date(d.utiliseLe),
    utilisePar: d.utilisePar,
    annuleeLe: date(d.annuleeLe),
  };
}

// ---------------------------------------------------------------------------
// Investisseurs privés : invitations nominatives
// ---------------------------------------------------------------------------

export const creerInvitation = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const pourNom = texte(req.data?.pourNom, "nom", 3, 120);
    const pourTelephone = normaliserTelephone(texte(req.data?.pourTelephone, "téléphone", 8, 20));
    const niveau = req.data?.niveau;
    if (!estNiveau(niveau)) throw new HttpsError("invalid-argument", "Niveau invalide.");
    const jours = Number(req.data?.joursValidite ?? 30);
    if (!Number.isInteger(jours) || jours < 1 || jours > 90) {
      throw new HttpsError("invalid-argument", "La durée de validité doit être comprise entre 1 et 90 jours.");
    }
    const deja = await db.collection("users").where("telephone", "==", pourTelephone).limit(1).get();
    if (!deja.empty) throw new HttpsError("already-exists", "Ce numéro a déjà un compte ARZIKI.");

    const expireLe = Timestamp.fromMillis(Date.now() + jours * 24 * 3600 * 1000);
    for (let essai = 0; essai < 5; essai++) {
      const code = genererCodeInvitation();
      try {
        await db.runTransaction(async (tx) => {
          tx.create(db.doc(`invitations/${code}`), {
            pourNom,
            pourTelephone,
            niveau,
            note: typeof req.data?.note === "string" ? req.data.note.slice(0, 300) : null,
            creePar: acteur.uid,
            creeLe: FieldValue.serverTimestamp(),
            expireLe,
            utiliseLe: null,
            utilisePar: null,
            annuleeLe: null,
          });
          ecrireAudit(tx, acteur.uid, "creer_invitation", `invitations/${code}`, null, `${pourNom}, ${niveau}`);
        });
        return { code, expireLe: expireLe.toMillis() };
      } catch (e) {
        if ((e as { code?: number }).code !== 6) throw e; // 6 = ALREADY_EXISTS : on retire un code
      }
    }
    throw new HttpsError("internal", "Impossible de générer un code unique.");
  }),
);

export const annulerInvitation = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const code = texte(req.data?.code, "code", 5, 20);
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`invitations/${code}`);
      const snap = await tx.get(ref);
      if (!snap.exists) throw new ErreurAcces("Invitation introuvable.", "not-found");
      if (snap.get("utiliseLe")) throw new ErreurAcces("Cette invitation a déjà été utilisée.", "failed-precondition");
      tx.update(ref, { annuleeLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, "annuler_invitation", `invitations/${code}`);
    });
    return { ok: true };
  }),
);

// ---------------------------------------------------------------------------
// Candidatures au Cercle
// ---------------------------------------------------------------------------

export const deposerCandidature = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    if (acteur.role !== "candidat_cercle") {
      throw new HttpsError("permission-denied", "Seul un candidat au Cercle peut déposer une candidature.");
    }
    const prenom = texte(req.data?.prenom, "prénom", 1, 80);
    const nom = texte(req.data?.nom, "nom", 1, 80);
    const niveauSouhaite = req.data?.niveauSouhaite;
    if (!estNiveau(niveauSouhaite)) throw new HttpsError("invalid-argument", "Niveau invalide.");
    const tranche = texte(req.data?.trancheEnvisagee, "tranche", 3, 80);
    const source = texte(req.data?.commentNousConnu, "source", 3, 120);

    await db.runTransaction(async (tx) => {
      const ref = db.doc(`candidatures/${acteur.uid}`);
      const existante = await tx.get(ref);
      if (existante.exists && existante.get("statut") === "soumise") {
        throw new ErreurAcces("Votre candidature est déjà en cours d'examen.", "failed-precondition");
      }
      const profil = await tx.get(db.doc(`users/${acteur.uid}`));
      tx.update(profil.ref, { prenom, nom, majLe: FieldValue.serverTimestamp() });
      tx.set(ref, {
        uid: acteur.uid,
        nomComplet: `${prenom} ${nom}`,
        telephone: profil.get("telephone") ?? "",
        niveauSouhaite,
        trancheEnvisagee: tranche,
        commentNousConnu: source,
        soumiseLe: FieldValue.serverTimestamp(),
        statut: "soumise",
        decidePar: null,
        decideLe: null,
        motif: null,
      });
      ecrireAudit(tx, acteur.uid, "deposer_candidature", `candidatures/${acteur.uid}`, null, niveauSouhaite);
    });
    return { ok: true };
  }),
);

export const deciderCandidature = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const uid = texte(req.data?.uid, "uid", 1, 128);
    const decision = req.data?.decision;

    if (decision === "refuser") {
      const motif = texte(req.data?.motif, "motif", 3, 300);
      await db.runTransaction(async (tx) => {
        const ref = db.doc(`candidatures/${uid}`);
        const c = await tx.get(ref);
        if (!c.exists || c.get("statut") !== "soumise") {
          throw new ErreurAcces("Aucune candidature en attente pour ce compte.", "failed-precondition");
        }
        tx.update(ref, { statut: "refusee", decidePar: acteur.uid, decideLe: FieldValue.serverTimestamp(), motif });
        ecrireAudit(tx, acteur.uid, "refuser_candidat", `candidatures/${uid}`, null, motif);
      });
      return { ok: true };
    }

    if (decision !== "admettre") throw new HttpsError("invalid-argument", "Décision inconnue.");
    const niveau = req.data?.niveau;
    if (!estNiveau(niveau)) throw new HttpsError("invalid-argument", "Niveau invalide.");
    if ((await tailleDuCercle()) >= LIMITE_TAILLE_CERCLE) {
      throw new HttpsError(
        "failed-precondition",
        "Le Cercle a atteint sa taille maximale. Consultez votre avocat avant toute nouvelle admission.",
      );
    }
    await db.runTransaction(async (tx) => {
      const refC = db.doc(`candidatures/${uid}`);
      const refU = db.doc(`users/${uid}`);
      const [c, u] = await Promise.all([tx.get(refC), tx.get(refU)]);
      if (!c.exists || c.get("statut") !== "soumise" || !u.exists) {
        throw new ErreurAcces("Aucune candidature en attente pour ce compte.", "failed-precondition");
      }
      const statut = statutApres(niveau, u.get("kycStatut"));
      tx.update(refC, { statut: "admise", decidePar: acteur.uid, decideLe: FieldValue.serverTimestamp() });
      tx.update(refU, { role: niveau, niveau, statut, majLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, "admettre_candidat", `users/${uid}`, u.get("role"), niveau);
    });
    await poserRole(uid, niveau);
    return { ok: true };
  }),
);

// ---------------------------------------------------------------------------
// Vérification d'identité et statut des comptes
// ---------------------------------------------------------------------------

export const soumettreKyc = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const pieces = req.data?.pieces as Record<string, string> | undefined;
    if (!pieces || typeof pieces !== "object" || Object.keys(pieces).length === 0) {
      throw new HttpsError("invalid-argument", "Aucune pièce reçue.");
    }
    // On ne garde que des chemins Cloud Storage dans le dossier de la personne.
    for (const chemin of Object.values(pieces)) {
      if (typeof chemin !== "string" || !chemin.startsWith(`kyc/${acteur.uid}/`)) {
        throw new HttpsError("invalid-argument", "Chemin de pièce invalide.");
      }
    }
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`users/${acteur.uid}`);
      const u = await tx.get(ref);
      if (!u.exists) throw new ErreurAcces("Compte introuvable.", "not-found");
      tx.set(db.doc(`kyc/${acteur.uid}`), {
        pieces,
        origineFonds: typeof req.data?.origineFonds === "string" ? req.data.origineFonds.slice(0, 120) : null,
        soumisLe: FieldValue.serverTimestamp(),
      });
      tx.update(ref, { kycStatut: "en_cours", majLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, "soumettre_kyc", `users/${acteur.uid}`, u.get("kycStatut"), "en_cours");
    });
    return { ok: true };
  }),
);

export const validerKyc = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const uid = texte(req.data?.uid, "uid", 1, 128);
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`users/${uid}`);
      const u = await tx.get(ref);
      if (!u.exists) throw new ErreurAcces("Compte introuvable.", "not-found");
      tx.update(ref, {
        kycStatut: "valide",
        kycValideLe: FieldValue.serverTimestamp(),
        kycValidePar: acteur.uid,
        statut: statutApres(u.get("role"), "valide"),
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "valider_kyc", `users/${uid}`, u.get("kycStatut"), "valide");
    });
    return { ok: true };
  }),
);

export const demanderComplementKyc = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const uid = texte(req.data?.uid, "uid", 1, 128);
    const motif = texte(req.data?.motif, "motif", 3, 300);
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`users/${uid}`);
      const u = await tx.get(ref);
      if (!u.exists) throw new ErreurAcces("Compte introuvable.", "not-found");
      tx.update(ref, { kycStatut: "a_completer", majLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, "demander_complement_kyc", `users/${uid}`, u.get("kycStatut"), motif);
    });
    return { ok: true };
  }),
);

export const changerStatutCompte = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const uid = texte(req.data?.uid, "uid", 1, 128);
    const action = req.data?.action;
    if (action !== "suspendre" && action !== "reactiver") throw new HttpsError("invalid-argument", "Action inconnue.");
    if (uid === acteur.uid) throw new HttpsError("permission-denied", "Vous ne pouvez pas modifier votre propre compte.");
    const profil = await lireProfil(uid);
    if (["super_admin", "admin", "analyste"].includes(profil.role) && acteur.role !== "super_admin") {
      throw new HttpsError("permission-denied", "Seul le super administrateur gère les comptes d'administration.");
    }
    const statut = action === "suspendre" ? "suspendu" : statutApres(profil.role, profil.kycStatut);
    await db.runTransaction(async (tx) => {
      tx.update(db.doc(`users/${uid}`), { statut, majLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, action === "suspendre" ? "suspendre_compte" : "reactiver_compte", `users/${uid}`, profil.statut, statut);
    });
    // Un compte suspendu est déconnecté de tous ses appareils.
    if (action === "suspendre") await getAuth().revokeRefreshTokens(uid);
    return { statut };
  }),
);

// ---------------------------------------------------------------------------
// Rôles et équipe interne
// ---------------------------------------------------------------------------

export const attribuerRole = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const uid = texte(req.data?.uid, "uid", 1, 128);
    const role = req.data?.role;
    if (!estRole(role)) throw new HttpsError("invalid-argument", "Rôle invalide.");
    const profil = await lireProfil(uid);
    exigerDroitAttribution(acteur, uid, profil.role, role);
    await db.runTransaction(async (tx) => {
      tx.update(db.doc(`users/${uid}`), {
        role,
        niveau: estNiveau(role) ? role : null,
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "attribuer_role", `users/${uid}`, profil.role, role);
    });
    await poserRole(uid, role);
    return { ok: true };
  }),
);

export const creerCompteEquipe = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req, ["super_admin"]);
    const prenom = texte(req.data?.prenom, "prénom", 1, 80);
    const nom = texte(req.data?.nom, "nom", 1, 80);
    const email = texte(req.data?.email, "e-mail", 5, 120).toLowerCase();
    const role = req.data?.role;
    if (role !== "admin" && role !== "analyste") {
      throw new HttpsError("invalid-argument", "Un compte d'équipe est soit administrateur, soit analyste.");
    }
    const utilisateur = await getAuth().createUser({ email, displayName: `${prenom} ${nom}`, emailVerified: false });
    await poserRole(utilisateur.uid, role);
    await db.runTransaction(async (tx) => {
      tx.create(db.doc(`users/${utilisateur.uid}`), {
        role,
        niveau: null,
        statut: "actif",
        kycStatut: "valide",
        prenom,
        nom,
        email,
        pays: "TG",
        creeLe: FieldValue.serverTimestamp(),
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "creer_compte_equipe", `users/${utilisateur.uid}`, null, role);
    });
    // Lien à transmettre à la personne pour qu'elle choisisse son mot de passe.
    // Elle devra ensuite activer son double facteur à la première connexion.
    const lien = await getAuth().generatePasswordResetLink(email);
    return { uid: utilisateur.uid, lienMotDePasse: lien };
  }),
);

export const signalerAccesRefuse = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const chemin = typeof req.data?.chemin === "string" ? req.data.chemin.slice(0, 100) : "console";
    await db.runTransaction(async (tx) => {
      ecrireAudit(tx, acteur.uid, "acces_console_refuse", chemin, acteur.role ?? null, null);
    });
    return { ok: true };
  }),
);
