// Cloud Functions ARZIKI : comptes et accès (jalon 2).
// Chaque fonction vérifie le rôle de l'appelant et écrit au journal d'audit.
// L'application mobile ne décide jamais seule d'un rôle ou d'un statut.

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineSecret, defineString } from "firebase-functions/params";
import { CallableRequest, HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

import {
  Acteur,
  ErreurAcces,
  InvitationDoc,
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
import {
  DUREE_VALIDITE_MS,
  ErreurVerification,
  VerificationDoc,
  corpsModeleCode,
  demandesRecentes,
  extraireMessages,
  finaliser,
  genererCode,
  genererSel,
  hacherCode,
  lienWhatsapp,
  messageAEnvoyer,
  messageConfirme,
  signatureValide,
} from "./whatsapp";
import {
  Apport,
  ErreurOperation,
  Garantie,
  PLAFOND_PARTENAIRES_DEFAUT,
  SEUIL_ALERTE_COUT_ANNUEL,
  STATUTS_GARANTIE,
  Statut,
  TYPES_GARANTIE,
  coutAnnuelEquivalent,
  estStatut,
  prixRevente,
  repartir,
  verifierPlaceDisponible,
  verifierPlafondParametre,
  verifierTransition,
} from "./operations";
import { erreurTelephone, paysDuTelephone } from "./pays";
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
      if (e instanceof ErreurOperation) throw new HttpsError(e.code, e.message);
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

/**
 * Places occupées dans le Cercle (section 24.2) : partenaires actifs ou en attente,
 * plus les invitations encore valables (non utilisées, non annulées, non expirées).
 */
async function placesOccupees(): Promise<number> {
  const comptes = await db
    .collection("users")
    .where("role", "in", [...NIVEAUX])
    .where("statut", "in", ["actif", "en_attente"])
    .count()
    .get();
  const invitations = await db.collection("invitations").where("utiliseLe", "==", null).where("annuleeLe", "==", null).get();
  const maintenant = Date.now();
  const valables = invitations.docs.filter((d) => (d.get("expireLe") as Timestamp).toMillis() > maintenant).length;
  return comptes.data().count + valables;
}

/** Paramètres réglés par le super administrateur, avec leurs valeurs par défaut. */
async function lireParametres() {
  const d = (await db.doc("parametres/global").get()).data() ?? {};
  return {
    plafondPartenaires: Number.isInteger(d.plafondPartenaires) ? (d.plafondPartenaires as number) : PLAFOND_PARTENAIRES_DEFAUT,
    seuilAlerteCoutAnnuel: typeof d.seuilAlerteCoutAnnuel === "number" ? d.seuilAlerteCoutAnnuel : SEUIL_ALERTE_COUT_ANNUEL,
    tauxTva: typeof d.tauxTva === "number" ? d.tauxTva : 18,
    numeroIpdcp: typeof d.numeroIpdcp === "string" ? d.numeroIpdcp : "",
  };
}

// ---------------------------------------------------------------------------
// Inscription (après vérification du numéro par SMS dans Firebase Auth)
// ---------------------------------------------------------------------------

export const inscrire = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    // Numéro vérifié par SMS (Firebase) ou par WhatsApp (jeton créé par finaliserVerification).
    const telephone = (req.auth?.token.phone_number ?? req.auth?.token.telephone_verifie) as string | undefined;
    if (!telephone) throw new HttpsError("failed-precondition", "Numéro de téléphone non vérifié.");
    // Section 23 : inscription seulement depuis un pays ouvert.
    const refusPays = erreurTelephone(normaliserTelephone(telephone));
    if (refusPays) throw new HttpsError("failed-precondition", refusPays);
    const pays = paysDuTelephone(normaliserTelephone(telephone))!.code;
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
        pays,
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
    const refusPays = erreurTelephone(pourTelephone);
    if (refusPays) throw new HttpsError("invalid-argument", refusPays);
    const niveau = req.data?.niveau;
    if (!estNiveau(niveau)) throw new HttpsError("invalid-argument", "Niveau invalide.");
    const jours = Number(req.data?.joursValidite ?? 30);
    if (!Number.isInteger(jours) || jours < 1 || jours > 90) {
      throw new HttpsError("invalid-argument", "La durée de validité doit être comprise entre 1 et 90 jours.");
    }
    const deja = await db.collection("users").where("telephone", "==", pourTelephone).limit(1).get();
    if (!deja.empty) throw new HttpsError("already-exists", "Ce numéro a déjà un compte ARZIKI.");
    // Plafond de partenaires (section 24.2) : 50 par défaut, jamais plus de 99.
    verifierPlaceDisponible(await placesOccupees(), (await lireParametres()).plafondPartenaires);

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
      // Partenaires financiers (R6) : déclaration de personne politiquement exposée obligatoire.
      const estPartenaire = (NIVEAUX as readonly string[]).includes(u.get("role"));
      const ppe = req.data?.personnePolitiquementExposee;
      if (estPartenaire && typeof ppe !== "boolean") {
        throw new ErreurAcces("Indiquez si vous êtes une personne politiquement exposée.", "invalid-argument");
      }
      // Fusion : une nouvelle pièce s'ajoute, rien n'est effacé (conservation 10 ans, R6).
      tx.set(
        db.doc(`kyc/${acteur.uid}`),
        {
          pieces,
          origineFonds: typeof req.data?.origineFonds === "string" ? req.data.origineFonds.slice(0, 120) : null,
          ...(estPartenaire ? { personnePolitiquementExposee: ppe } : {}),
          soumisLe: FieldValue.serverTimestamp(),
          conserverJusquA: Timestamp.fromMillis(Date.now() + 10 * 365.25 * 24 * 3600 * 1000),
        },
        { merge: true },
      );
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

// ---------------------------------------------------------------------------
// Vérification du numéro par WhatsApp (CLAUDE.md, section 22.3)
// WhatsApp d'abord, SMS en secours (le SMS reste géré par Firebase Authentication).
// ---------------------------------------------------------------------------

// Réglages WhatsApp Business (Meta). Les clés sont des secrets Firebase, jamais dans Git.
const WHATSAPP_JETON = defineSecret("WHATSAPP_JETON"); // jeton d'accès permanent de l'API
const WHATSAPP_SECRET_APP = defineSecret("WHATSAPP_SECRET_APP"); // secret de l'application Meta
const WHATSAPP_JETON_WEBHOOK = defineSecret("WHATSAPP_JETON_WEBHOOK"); // mot de passe choisi pour le webhook
const WHATSAPP_ID_NUMERO = defineString("WHATSAPP_ID_NUMERO", { default: "" }); // identifiant du numéro chez Meta
const WHATSAPP_NUMERO_ARZIKI = defineString("WHATSAPP_NUMERO_ARZIKI", { default: "" }); // ex. +22890000000
const VERSION_API_META = "v21.0";

/** Envoie un message par l'API WhatsApp Cloud. */
async function envoyerWhatsapp(corps: object): Promise<void> {
  const reponse = await fetch(`https://graph.facebook.com/${VERSION_API_META}/${WHATSAPP_ID_NUMERO.value()}/messages`, {
    method: "POST",
    headers: { Authorization: `Bearer ${WHATSAPP_JETON.value()}`, "Content-Type": "application/json" },
    body: JSON.stringify(corps),
  });
  if (!reponse.ok) {
    // Pas de numéro de téléphone dans les journaux (CLAUDE.md, section 14).
    console.error("Envoi WhatsApp refusé", reponse.status);
    throw new HttpsError("unavailable", "WhatsApp est indisponible. Essayez de recevoir le code par SMS.");
  }
}

function protegerVerification<T>(gestionnaire: (req: CallableRequest) => Promise<T>) {
  return async (req: CallableRequest): Promise<T> => {
    try {
      return await gestionnaire(req);
    } catch (e) {
      if (e instanceof ErreurVerification) throw new HttpsError(e.code, e.message);
      throw e;
    }
  };
}

/**
 * Démarre une vérification. Appelée avant toute connexion (pas besoin d'être connecté,
 * mais App Check obligatoire). Canal « message » : renvoie le lien WhatsApp à ouvrir.
 * Canal « code » : envoie le code par WhatsApp.
 */
export const demarrerVerification = onCall(
  { ...options, secrets: [WHATSAPP_JETON] },
  protegerVerification(async (req) => {
    const telephone = normaliserTelephone(texte(req.data?.telephone, "telephone", 8, 20));
    const canal = req.data?.canal === "code" ? "code" : "message";
    const refusPays = erreurTelephone(telephone);
    if (refusPays) throw new HttpsError("invalid-argument", refusPays);
    if (!WHATSAPP_NUMERO_ARZIKI.value() || !WHATSAPP_ID_NUMERO.value()) {
      throw new HttpsError("unavailable", "La vérification par WhatsApp n'est pas encore active. Utilisez le SMS.");
    }

    const maintenant = Date.now();
    const code = genererCode();
    const sel = genererSel();
    const ref = db.collection("verifications").doc();
    // Limite de 5 demandes par heure et par numéro.
    await db.runTransaction(async (tx) => {
      const refLimite = db.doc(`limites_verification/${telephone}`);
      const limite = await tx.get(refLimite);
      const demandes = demandesRecentes((limite.get("demandes") as number[] | undefined) ?? [], maintenant);
      tx.set(refLimite, { demandes });
      const doc: VerificationDoc = {
        telephone,
        canal,
        codeHache: hacherCode(code, sel),
        sel,
        creeLeMs: maintenant,
        expireLeMs: maintenant + DUREE_VALIDITE_MS,
        essais: 0,
        statut: "en_attente",
      };
      tx.create(ref, doc);
    });

    if (canal === "code") {
      await envoyerWhatsapp(corpsModeleCode(telephone, code));
      return { id: ref.id };
    }
    const message = messageAEnvoyer(code);
    return { id: ref.id, message, lien: lienWhatsapp(WHATSAPP_NUMERO_ARZIKI.value(), message) };
  }),
);

/**
 * Termine une vérification et renvoie un jeton de connexion Firebase.
 * Canal « message » : renvoie { etat: "en_attente" } tant que le message n'est pas arrivé
 * (l'application redemande toutes les 3 secondes).
 */
export const finaliserVerification = onCall(
  options,
  protegerVerification(async (req) => {
    const id = texte(req.data?.id, "id", 10, 40);
    const code = typeof req.data?.code === "string" ? req.data.code : undefined;
    const ref = db.doc(`verifications/${id}`);

    const resultat = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new ErreurVerification("Vérification introuvable. Recommencez.", "not-found");
      const r = finaliser(snap.data() as VerificationDoc, Date.now(), code);
      if (r.etat !== "en_attente" && Object.keys(r.maj).length) tx.update(ref, r.maj);
      return r;
    });
    if (resultat.etat === "en_attente") return { etat: "en_attente" };
    if (resultat.etat === "refuse") throw new HttpsError("failed-precondition", resultat.message);

    // Compte Firebase lié à ce numéro (créé s'il n'existe pas encore).
    const auth = getAuth();
    let uid: string;
    try {
      const existant = await auth.getUserByPhoneNumber(resultat.telephone);
      if (estRole(existant.customClaims?.role) && ["super_admin", "admin", "analyste"].includes(existant.customClaims!.role)) {
        throw new HttpsError("permission-denied", "Les administrateurs se connectent avec leur adresse e-mail.");
      }
      uid = existant.uid;
    } catch (e) {
      if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
      uid = (await auth.createUser({ phoneNumber: resultat.telephone })).uid;
    }
    const jeton = await auth.createCustomToken(uid, { telephone_verifie: resultat.telephone });
    return { etat: "valide", jeton };
  }),
);

/**
 * Point d'arrivée des messages WhatsApp (webhook Meta).
 * GET : vérification de l'adresse par Meta. POST : messages reçus.
 * Chaque requête est authentifiée par la signature de Meta.
 */
export const webhookWhatsapp = onRequest(
  { secrets: [WHATSAPP_JETON, WHATSAPP_SECRET_APP, WHATSAPP_JETON_WEBHOOK] },
  async (req, res) => {
    if (req.method === "GET") {
      const ok = req.query["hub.mode"] === "subscribe" && req.query["hub.verify_token"] === WHATSAPP_JETON_WEBHOOK.value();
      if (ok) res.status(200).send(String(req.query["hub.challenge"] ?? ""));
      else res.sendStatus(403);
      return;
    }
    if (req.method !== "POST") {
      res.sendStatus(405);
      return;
    }
    if (!signatureValide(req.rawBody, req.get("x-hub-signature-256"), WHATSAPP_SECRET_APP.value())) {
      res.sendStatus(401);
      return;
    }

    const maintenant = Date.now();
    for (const message of extraireMessages(req.body)) {
      const attente = await db
        .collection("verifications")
        .where("telephone", "==", message.de)
        .where("statut", "==", "en_attente")
        .get();
      for (const doc of attente.docs) {
        if (!messageConfirme(doc.data() as VerificationDoc, message, maintenant)) continue;
        await doc.ref.update({ statut: "confirmee", confirmeeLeMs: maintenant });
        // Réponse au client (gratuite : elle suit son propre message).
        await envoyerWhatsapp({
          messaging_product: "whatsapp",
          to: message.de.replace(/\D/g, ""),
          type: "text",
          text: { body: "Merci, votre numéro est vérifié. Vous pouvez revenir dans l'application ARZIKI." },
        }).catch(() => undefined);
      }
    }
    // Toujours répondre 200 à Meta, sinon il renvoie le message.
    res.sendStatus(200);
  },
);

// ---------------------------------------------------------------------------
// Paramètres (super administrateur) : plafond de partenaires, seuil d'alerte,
// TVA, numéro de déclaration IPDCP (CLAUDE.md, section 24)
// ---------------------------------------------------------------------------

export const definirParametres = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req, ["super_admin"]);
    const actuels = await lireParametres();
    const nouveaux = { ...actuels };
    const d = req.data ?? {};
    if (d.plafondPartenaires !== undefined) {
      verifierPlafondParametre(Number(d.plafondPartenaires));
      nouveaux.plafondPartenaires = Number(d.plafondPartenaires);
    }
    if (d.seuilAlerteCoutAnnuel !== undefined) {
      const seuil = Number(d.seuilAlerteCoutAnnuel);
      if (!Number.isFinite(seuil) || seuil <= 0 || seuil > 100) {
        throw new HttpsError("invalid-argument", "Le seuil d'alerte doit être compris entre 0 et 100 %.");
      }
      nouveaux.seuilAlerteCoutAnnuel = seuil;
    }
    if (d.tauxTva !== undefined) {
      const tva = Number(d.tauxTva);
      if (!Number.isFinite(tva) || tva < 0 || tva > 50) throw new HttpsError("invalid-argument", "Taux de TVA invalide.");
      nouveaux.tauxTva = tva;
    }
    if (d.numeroIpdcp !== undefined) nouveaux.numeroIpdcp = texte(d.numeroIpdcp, "numéro IPDCP", 0, 60);
    await db.runTransaction(async (tx) => {
      tx.set(db.doc("parametres/global"), nouveaux, { merge: true });
      ecrireAudit(tx, acteur.uid, "modifier_parametres", "parametres/global", JSON.stringify(actuels), JSON.stringify(nouveaux));
    });
    return nouveaux;
  }),
);

// ---------------------------------------------------------------------------
// Opérations en vente à terme (CLAUDE.md, section 24 ; logique dans operations.ts)
// L'application ne décide jamais d'un statut ni d'un montant : tout passe ici.
// ---------------------------------------------------------------------------

const EQUIPE: readonly Role[] = ["super_admin", "admin", "analyste"];

function montant(valeur: unknown, champ: string, zeroAutorise = false): number {
  const n = Number(valeur);
  if (!Number.isInteger(n) || n < 0 || (!zeroAutorise && n === 0) || n > 10_000_000_000) {
    throw new HttpsError("invalid-argument", `Champ « ${champ} » : montant entier en FCFA attendu.`);
  }
  return n;
}

/** Profil actif et identité validée (R6) : condition pour agir sur une opération. */
async function exigerCompteVerifie(uid: string, roles: readonly Role[]) {
  const p = await lireProfil(uid);
  if (!roles.includes(p.role)) throw new ErreurAcces("Action réservée à un autre type de compte.");
  if (p.statut !== "actif" || p.kycStatut !== "valide") {
    throw new ErreurAcces("Votre compte doit être actif et votre identité validée.", "failed-precondition");
  }
  return p;
}

/** Une entreprise soumet une commande à financer (statut « soumise »). */
export const soumettreDemande = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const p = await exigerCompteVerifie(acteur.uid, ["entreprise"]);
    const d = req.data ?? {};
    const ref = db.collection("operations").doc();
    const doc = {
      entrepriseUid: acteur.uid,
      pays: (p as { pays?: string }).pays ?? "TG",
      titre: texte(d.titre, "titre", 5, 120),
      description: texte(d.description, "description", 10, 2000),
      clientFinal: {
        nom: texte(d.clientFinal?.nom, "client final", 2, 160),
        rccm: typeof d.clientFinal?.rccm === "string" ? d.clientFinal.rccm.slice(0, 60) : null,
        contact: texte(d.clientFinal?.contact, "contact du client final", 5, 160),
      },
      fournisseur: {
        nom: texte(d.fournisseur?.nom, "fournisseur", 2, 160),
        contact: texte(d.fournisseur?.contact, "contact du fournisseur", 5, 160),
      },
      montantCommande: montant(d.montantCommande, "montant de la commande"),
      prixAchatDemande: montant(d.prixAchatDemande, "prix d'achat"),
      delaiJours: Math.min(365, Math.max(1, Math.trunc(Number(d.delaiJours) || 0))),
      garantiesProposees: Array.isArray(d.garantiesProposees)
        ? d.garantiesProposees.filter((g: unknown) => (TYPES_GARANTIE as readonly unknown[]).includes(g))
        : [],
      statut: "soumise" as Statut,
      garanties: [] as Garantie[],
      partenairesProposes: [] as string[],
      apportsRetenus: [] as Apport[],
      nombreInterets: 0,
      creeLe: FieldValue.serverTimestamp(),
      majLe: FieldValue.serverTimestamp(),
    };
    await db.runTransaction(async (tx) => {
      tx.create(ref, doc);
      ecrireAudit(tx, acteur.uid, "soumettre_demande", `operations/${ref.id}`, null, String(doc.montantCommande));
    });
    return { id: ref.id };
  }),
);

/**
 * L'administrateur fixe les conditions de la vente à terme. Le serveur calcule le
 * prix de revente et le coût annuel équivalent, et lève l'alerte au-delà du seuil.
 */
export const definirConditions = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req, EQUIPE);
    const id = texte(req.data?.id, "id", 5, 64);
    const conditions = {
      prixAchat: montant(req.data?.prixAchat, "prix d'achat"),
      majoration: montant(req.data?.majoration, "majoration", true),
      dureeJours: Math.trunc(Number(req.data?.dureeJours)),
    };
    const commissionArziki = montant(req.data?.commissionArziki ?? 0, "commission ARZIKI", true);
    const { seuilAlerteCoutAnnuel } = await lireParametres();
    const revente = prixRevente(conditions);
    const cout = coutAnnuelEquivalent(conditions);
    const ref = db.doc(`operations/${id}`);
    await db.runTransaction(async (tx) => {
      const op = await tx.get(ref);
      if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
      if (!["en_analyse", "proposee"].includes(op.get("statut"))) {
        throw new ErreurAcces("Les conditions se fixent pendant l'analyse, avant toute signature.", "failed-precondition");
      }
      tx.update(ref, {
        ...conditions,
        prixRevente: revente,
        commissionArziki,
        coutAnnuelEquivalent: cout,
        alerteCoutAnnuel: cout > seuilAlerteCoutAnnuel,
        echeance: Timestamp.fromMillis(Date.now() + conditions.dureeJours * 24 * 3600 * 1000),
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "definir_conditions", `operations/${id}`, null, `${conditions.prixAchat} + ${conditions.majoration} sur ${conditions.dureeJours} j (${cout} %)`);
    });
    return { prixRevente: revente, coutAnnuelEquivalent: cout, alerte: cout > seuilAlerteCoutAnnuel };
  }),
);

/** Propose l'opération à des partenaires choisis, tous actifs et vérifiés. */
export const proposerOperation = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const id = texte(req.data?.id, "id", 5, 64);
    const uids = Array.isArray(req.data?.partenaires) ? (req.data.partenaires as unknown[]).map((u) => texte(u, "partenaire", 1, 128)) : [];
    if (uids.length === 0) throw new HttpsError("invalid-argument", "Choisissez au moins un partenaire.");
    for (const uid of uids) await exigerCompteVerifie(uid, NIVEAUX);
    const ref = db.doc(`operations/${id}`);
    await db.runTransaction(async (tx) => {
      const op = await tx.get(ref);
      if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
      if (!op.get("prixRevente")) throw new ErreurAcces("Fixez d'abord les conditions de la vente à terme.", "failed-precondition");
      const statut = op.get("statut") as Statut;
      if (statut !== "proposee") verifierTransition(etatDe(op), "proposee");
      tx.update(ref, {
        statut: "proposee",
        partenairesProposes: FieldValue.arrayUnion(...uids),
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "proposer_operation", `operations/${id}`, statut, uids.join(", "));
    });
    return { ok: true };
  }),
);

/**
 * Un partenaire invité dit « Je suis intéressé ». Cette manifestation n'engage
 * à rien : seule la signature devant notaire engage (R4).
 */
export const manifesterInteret = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    await exigerCompteVerifie(acteur.uid, NIVEAUX);
    const id = texte(req.data?.id, "id", 5, 64);
    const montantIndicatif = montant(req.data?.montantIndicatif, "montant indicatif");
    const ref = db.doc(`operations/${id}`);
    await db.runTransaction(async (tx) => {
      const op = await tx.get(ref);
      if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
      if (!(op.get("partenairesProposes") as string[]).includes(acteur.uid)) {
        throw new ErreurAcces("Cette opération ne vous a pas été proposée.");
      }
      const statut = op.get("statut") as Statut;
      if (statut !== "proposee" && statut !== "interet_manifeste") {
        throw new ErreurAcces("Cette opération n'est plus ouverte aux manifestations d'intérêt.", "failed-precondition");
      }
      if (montantIndicatif > (op.get("prixAchat") as number)) {
        throw new ErreurAcces("Le montant indiqué dépasse le prix d'achat de l'opération.", "invalid-argument");
      }
      const refInteret = ref.collection("interets").doc(acteur.uid);
      const deja = (await tx.get(refInteret)).exists;
      tx.set(refInteret, {
        uid: acteur.uid,
        montantIndicatif,
        engageant: false,
        creeLe: FieldValue.serverTimestamp(),
      });
      tx.update(ref, {
        statut: "interet_manifeste",
        nombreInterets: deja ? op.get("nombreInterets") : (op.get("nombreInterets") as number) + 1,
        majLe: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "manifester_interet", `operations/${id}`, null, String(montantIndicatif));
    });
    return { ok: true };
  }),
);

/** L'administrateur retient les apports pour la signature et calcule ce que chacun recevra. */
export const retenirApports = onCall(
  options,
  proteger(async (req) => {
    const acteur = administrateur(req);
    const id = texte(req.data?.id, "id", 5, 64);
    const apports: Apport[] = (Array.isArray(req.data?.apports) ? req.data.apports : []).map(
      (a: { partenaireUid?: unknown; montant?: unknown }) => ({
        partenaireUid: texte(a?.partenaireUid, "partenaire", 1, 128),
        montant: montant(a?.montant, "apport"),
      }),
    );
    const ref = db.doc(`operations/${id}`);
    return db.runTransaction(async (tx) => {
      const op = await tx.get(ref);
      if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
      if (op.get("statut") !== "interet_manifeste") {
        throw new ErreurAcces("Les apports se retiennent après les manifestations d'intérêt, avant la signature.", "failed-precondition");
      }
      for (const a of apports) {
        if (!(await tx.get(ref.collection("interets").doc(a.partenaireUid))).exists) {
          throw new ErreurAcces("Un partenaire retenu n'a pas manifesté son intérêt.", "failed-precondition");
        }
      }
      const repartition = repartir(
        { prixAchat: op.get("prixAchat"), majoration: op.get("majoration"), dureeJours: op.get("dureeJours") },
        apports,
      );
      tx.update(ref, { apportsRetenus: apports, repartition, majLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, "retenir_apports", `operations/${id}`, null, apports.map((a) => `${a.partenaireUid}:${a.montant}`).join(", "));
      return { repartition };
    });
  }),
);

/** Ajoute ou met à jour une garantie (administrateur, ou notaire assigné). */
export const majGarantie = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const id = texte(req.data?.id, "id", 5, 64);
    const type = req.data?.type;
    const statut = req.data?.statut ?? "a_constituer";
    if (!(TYPES_GARANTIE as readonly unknown[]).includes(type)) throw new HttpsError("invalid-argument", "Type de garantie inconnu.");
    if (!(STATUTS_GARANTIE as readonly unknown[]).includes(statut)) throw new HttpsError("invalid-argument", "Statut de garantie inconnu.");
    // Pièce : dans le dossier de l'opération (équipe) ou dans le dossier du notaire qui agit.
    const brute = typeof req.data?.piece === "string" ? req.data.piece : null;
    const piece =
      brute && (brute.startsWith(`operations/${id}/`) || brute.startsWith(`notaires/${acteur.uid}/`)) && !brute.includes("..")
        ? brute
        : null;
    const ref = db.doc(`operations/${id}`);
    await db.runTransaction(async (tx) => {
      const op = await tx.get(ref);
      if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
      const estNotaire = acteur.role === "notaire" && op.get("notaireUid") === acteur.uid;
      if (!estNotaire) exigerAdministration(acteur, ROLES_VALIDATEURS, EXIGER_DOUBLE_FACTEUR);
      const garanties = [...((op.get("garanties") as Garantie[]) ?? [])];
      const i = garanties.findIndex((g) => g.type === type);
      const avant = i >= 0 ? garanties[i].statut : null;
      const g: Garantie = { type, statut, piece: piece ?? (i >= 0 ? garanties[i].piece ?? null : null) };
      if (i >= 0) garanties[i] = g;
      else garanties.push(g);
      tx.update(ref, { garanties, majLe: FieldValue.serverTimestamp() });
      ecrireAudit(tx, acteur.uid, "maj_garantie", `operations/${id}`, avant, `${type}: ${statut}`);
    });
    return { ok: true };
  }),
);

function etatDe(op: FirebaseFirestore.DocumentSnapshot) {
  return {
    statut: op.get("statut") as Statut,
    garanties: (op.get("garanties") as Garantie[]) ?? [],
    apportsRetenus: (op.get("apportsRetenus") as Apport[]) ?? [],
    prixAchat: (op.get("prixAchat") as number) ?? 0,
    nombreInterets: (op.get("nombreInterets") as number) ?? 0,
  };
}

/**
 * Change le statut d'une opération après vérification des conditions (R4).
 * - analyste : mise en analyse, demande de pièces ;
 * - notaire assigné : signature devant notaire, paiement au fournisseur (séquestre) ;
 * - administrateur : tout le reste.
 */
export const changerStatutOperation = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const id = texte(req.data?.id, "id", 5, 64);
    const vers = req.data?.statut;
    if (!estStatut(vers)) throw new HttpsError("invalid-argument", "Statut inconnu.");
    const motif = typeof req.data?.motif === "string" ? req.data.motif.slice(0, 500) : null;
    if ((vers === "refusee" || vers === "annulee" || vers === "pieces_demandees") && !motif) {
      throw new HttpsError("invalid-argument", "Un motif est obligatoire.");
    }
    const ref = db.doc(`operations/${id}`);
    await db.runTransaction(async (tx) => {
      const op = await tx.get(ref);
      if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
      const estNotaire = acteur.role === "notaire" && op.get("notaireUid") === acteur.uid;
      const pourAnalyste: Statut[] = ["en_analyse", "pieces_demandees"];
      const pourNotaire: Statut[] = ["signee", "fournisseur_paye"];
      if (estNotaire) {
        if (!pourNotaire.includes(vers)) throw new ErreurAcces("Le notaire confirme seulement la signature et le paiement au fournisseur.");
      } else if (acteur.role === "analyste") {
        exigerAdministration(acteur, EQUIPE, EXIGER_DOUBLE_FACTEUR);
        if (!pourAnalyste.includes(vers)) throw new ErreurAcces("Un analyste ne peut pas faire avancer cette étape.");
      } else {
        exigerAdministration(acteur, ROLES_VALIDATEURS, EXIGER_DOUBLE_FACTEUR);
      }
      const avant = op.get("statut") as Statut;
      verifierTransition(etatDe(op), vers);
      tx.update(ref, { statut: vers, majLe: FieldValue.serverTimestamp(), ...(motif ? { dernierMotif: motif } : {}) });
      tx.create(ref.collection("evenements").doc(), {
        de: avant,
        vers,
        par: acteur.uid,
        motif,
        le: FieldValue.serverTimestamp(),
      });
      ecrireAudit(tx, acteur.uid, "changer_statut_operation", `operations/${id}`, avant, vers);
    });
    return { ok: true };
  }),
);

/**
 * Lien temporaire (15 minutes) vers un document d'une opération, après contrôle :
 * équipe, entreprise concernée, notaire assigné, ou partenaire vérifié à qui
 * l'opération a été proposée. Chaque téléchargement est inscrit au journal (R7).
 */
export const lienDocument = onCall(
  options,
  proteger(async (req) => {
    const acteur = acteurDe(req);
    const id = texte(req.data?.id, "id", 5, 64);
    const chemin = texte(req.data?.chemin, "chemin", 5, 300);
    const op = await db.doc(`operations/${id}`).get();
    if (!op.exists) throw new ErreurAcces("Opération introuvable.", "not-found");
    const documents = [
      ...((op.get("garanties") as Garantie[]) ?? []).map((g) => g.piece).filter(Boolean),
      ...(((op.get("documents") as string[] | undefined) ?? [])),
    ];
    if (!documents.includes(chemin)) throw new ErreurAcces("Document inconnu pour cette opération.", "not-found");
    let autorise = EQUIPE.includes(acteur.role as Role) && acteur.doubleFacteur;
    autorise ||= acteur.role === "entreprise" && op.get("entrepriseUid") === acteur.uid;
    autorise ||= acteur.role === "notaire" && op.get("notaireUid") === acteur.uid;
    if (!autorise && (NIVEAUX as readonly string[]).includes(acteur.role ?? "")) {
      const p = await lireProfil(acteur.uid);
      autorise = p.statut === "actif" && p.kycStatut === "valide" && (op.get("partenairesProposes") as string[]).includes(acteur.uid);
    }
    if (!autorise) throw new ErreurAcces("Vous n'avez pas accès à ce document.");
    const [url] = await getStorage().bucket().file(chemin).getSignedUrl({ action: "read", expires: Date.now() + 15 * 60 * 1000 });
    await db.runTransaction(async (tx) => {
      ecrireAudit(tx, acteur.uid, "telecharger_document", `operations/${id}`, null, chemin);
    });
    return { url };
  }),
);
