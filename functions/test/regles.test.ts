// Tests des règles Firestore et Storage, rôle par rôle, sur l'émulateur.
// Lancement : npm run test:regles (démarre et arrête les émulateurs).

import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { join } from "path";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";
import { addDoc, collection, deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { ref, uploadString, getBytes } from "firebase/storage";

let env: RulesTestEnvironment;

// Les administrateurs se connectent avec le double facteur.
const deuxFacteurs = { firebase: { sign_in_provider: "password", sign_in_second_factor: "totp" } };

function contexte(uid: string, role: string, avecDeuxFacteurs = false) {
  return env.authenticatedContext(uid, { role, ...(avecDeuxFacteurs ? deuxFacteurs : {}) });
}
const db = (uid: string, role: string, a2f = false) => contexte(uid, role, a2f).firestore();

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-arziki",
    firestore: { rules: readFileSync(join(__dirname, "..", "..", "firestore.rules"), "utf8") },
    storage: { rules: readFileSync(join(__dirname, "..", "..", "storage.rules"), "utf8") },
  });
});

afterAll(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const f = c.firestore();
    const profil = (role: string, statut = "actif", kycStatut = "valide") => ({ role, statut, kycStatut, nom: "X", prenom: "Y" });
    await setDoc(doc(f, "users/sa"), profil("super_admin"));
    await setDoc(doc(f, "users/ad"), profil("admin"));
    await setDoc(doc(f, "users/an"), profil("analyste"));
    await setDoc(doc(f, "users/membre"), profil("membre"));
    await setDoc(doc(f, "users/membre_attente"), profil("membre", "en_attente", "en_cours"));
    await setDoc(doc(f, "users/partenaire"), profil("partenaire"));
    await setDoc(doc(f, "users/candidat"), profil("candidat_cercle", "en_attente", "valide"));
    await setDoc(doc(f, "users/ent"), profil("entreprise"));
    await setDoc(doc(f, "users/ent2"), profil("entreprise"));
    await setDoc(doc(f, "users/notaire"), profil("notaire"));
    await setDoc(doc(f, "users/fourn"), profil("fournisseur"));
    await setDoc(doc(f, "invitations/ARZ-AAAA-BBBB"), { pourNom: "Awa", pourTelephone: "+22890123456", niveau: "membre" });
    await setDoc(doc(f, "candidatures/candidat"), { uid: "candidat", statut: "soumise" });
    await setDoc(doc(f, "audit/a1"), { action: "test" });
    const op = (visibilite: string, statut = "financement_ouvert") => ({
      statut,
      visibilite,
      entrepriseUid: "ent",
      notaireUid: "notaire",
      fournisseurUids: ["fourn"],
      minParticipant: 500000,
      maxParticipant: 5000000,
    });
    await setDoc(doc(f, "operations/pme"), op("membre"));
    await setDoc(doc(f, "operations/grand"), op("partenaire"));
    await setDoc(doc(f, "operations/fermee"), op("membre", "en_verification"));
    await setDoc(doc(f, "operations/pme/participations/p1"), { uid: "membre", montant: 1000000, statut: "versement_confirme" });
    await setDoc(doc(f, "operations/pme/evenements/e1"), { type: "statut" });
  });
});

describe("profils", () => {
  it("chacun lit son profil, pas celui des autres", async () => {
    await assertSucceeds(getDoc(doc(db("membre", "membre"), "users/membre")));
    await assertFails(getDoc(doc(db("membre", "membre"), "users/partenaire")));
    await assertFails(getDoc(doc(db("ent", "entreprise"), "users/membre")));
  });

  it("l'équipe lit les profils, avec double facteur obligatoire", async () => {
    await assertSucceeds(getDoc(doc(db("an", "analyste", true), "users/membre")));
    await assertFails(getDoc(doc(db("an", "analyste", false), "users/membre")));
  });

  it("on modifie son nom, jamais son rôle, son statut ou son KYC", async () => {
    const f = db("membre", "membre");
    await assertSucceeds(updateDoc(doc(f, "users/membre"), { prenom: "Essi" }));
    await assertFails(updateDoc(doc(f, "users/membre"), { role: "super_admin" }));
    await assertFails(updateDoc(doc(f, "users/membre"), { statut: "suspendu" }));
    await assertFails(updateDoc(doc(f, "users/membre"), { kycStatut: "en_cours" }));
    await assertFails(updateDoc(doc(f, "users/membre"), { niveau: "partenaire_strategique" }));
    await assertFails(updateDoc(doc(db("membre_attente", "membre"), "users/membre_attente"), { statut: "actif" }));
  });

  it("personne ne crée ni ne supprime un profil depuis l'application", async () => {
    await assertFails(setDoc(doc(db("nouveau", "membre"), "users/nouveau"), { role: "membre" }));
    await assertFails(deleteDoc(doc(db("sa", "super_admin", true), "users/membre")));
  });
});

describe("invitations, candidatures et journal", () => {
  it("les invitations : administrateurs seulement, en lecture", async () => {
    await assertSucceeds(getDoc(doc(db("sa", "super_admin", true), "invitations/ARZ-AAAA-BBBB")));
    await assertSucceeds(getDoc(doc(db("ad", "admin", true), "invitations/ARZ-AAAA-BBBB")));
    await assertFails(getDoc(doc(db("an", "analyste", true), "invitations/ARZ-AAAA-BBBB")));
    await assertFails(getDoc(doc(db("membre", "membre"), "invitations/ARZ-AAAA-BBBB")));
    await assertFails(setDoc(doc(db("sa", "super_admin", true), "invitations/ARZ-CCCC-DDDD"), { niveau: "membre" }));
  });

  it("une invitation ne se lit pas sans être connecté", async () => {
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "invitations/ARZ-AAAA-BBBB")));
  });

  it("le candidat voit sa candidature mais ne peut pas la modifier", async () => {
    await assertSucceeds(getDoc(doc(db("candidat", "candidat_cercle"), "candidatures/candidat")));
    await assertFails(updateDoc(doc(db("candidat", "candidat_cercle"), "candidatures/candidat"), { statut: "admise" }));
    await assertFails(getDoc(doc(db("membre", "membre"), "candidatures/candidat")));
  });

  it("le journal d'audit n'est jamais modifiable, même par le super administrateur", async () => {
    const sa = db("sa", "super_admin", true);
    await assertSucceeds(getDoc(doc(sa, "audit/a1")));
    await assertFails(updateDoc(doc(sa, "audit/a1"), { action: "effacé" }));
    await assertFails(deleteDoc(doc(sa, "audit/a1")));
    await assertFails(addDoc(collection(sa, "audit"), { action: "faux" }));
    await assertFails(getDoc(doc(db("membre", "membre"), "audit/a1")));
  });
});

describe("vérifications WhatsApp", () => {
  it("aucune lecture ni écriture depuis l'application, même pour le super administrateur", async () => {
    const sa = db("sa", "super_admin", true);
    await assertFails(getDoc(doc(sa, "verifications/v1")));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "verifications/v1")));
    await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), "verifications/v2"), { statut: "confirmee" }));
    await assertFails(setDoc(doc(db("membre", "membre"), "limites_verification/+22890000021"), { demandes: [] }));
  });
});

describe("opérations du Cercle", () => {
  it("un membre vérifié voit les opérations PME ouvertes, pas les grands comptes", async () => {
    await assertSucceeds(getDoc(doc(db("membre", "membre"), "operations/pme")));
    await assertFails(getDoc(doc(db("membre", "membre"), "operations/grand")));
    await assertFails(getDoc(doc(db("membre", "membre"), "operations/fermee")));
  });

  it("un partenaire voit aussi les opérations Entreprises", async () => {
    await assertSucceeds(getDoc(doc(db("partenaire", "partenaire"), "operations/grand")));
  });

  it("aucune opération pour un compte non validé ou un candidat", async () => {
    await assertFails(getDoc(doc(db("membre_attente", "membre"), "operations/pme")));
    await assertFails(getDoc(doc(db("candidat", "candidat_cercle"), "operations/pme")));
  });

  it("l'entreprise voit son opération mais jamais les participations", async () => {
    await assertSucceeds(getDoc(doc(db("ent", "entreprise"), "operations/pme")));
    await assertSucceeds(getDoc(doc(db("ent", "entreprise"), "operations/pme/evenements/e1")));
    await assertFails(getDoc(doc(db("ent", "entreprise"), "operations/pme/participations/p1")));
    await assertFails(getDoc(doc(db("ent2", "entreprise"), "operations/pme")));
  });

  it("notaire et fournisseur : seulement ce qui leur est assigné", async () => {
    await assertSucceeds(getDoc(doc(db("notaire", "notaire"), "operations/pme")));
    await assertSucceeds(getDoc(doc(db("fourn", "fournisseur"), "operations/pme")));
    await assertFails(getDoc(doc(db("autre_notaire", "notaire"), "operations/pme")));
  });

  it("un membre crée une intention de participation conforme, rien de plus", async () => {
    const f = db("membre", "membre");
    const ok = { uid: "membre", montant: 1000000, statut: "en_attente_versement", creeLe: serverTimestamp() };
    await assertSucceeds(setDoc(doc(f, "operations/pme/participations/p2"), ok));
    await assertFails(setDoc(doc(f, "operations/pme/participations/p3"), { ...ok, statut: "versement_confirme" }));
    await assertFails(setDoc(doc(f, "operations/pme/participations/p4"), { ...ok, montant: 100 }));
    await assertFails(setDoc(doc(f, "operations/pme/participations/p5"), { ...ok, montant: 1000000.5 }));
    await assertFails(setDoc(doc(f, "operations/pme/participations/p6"), { ...ok, uid: "partenaire" }));
    await assertFails(setDoc(doc(f, "operations/grand/participations/p7"), ok));
    await assertFails(updateDoc(doc(f, "operations/pme/participations/p1"), { montant: 2000000 }));
    await assertFails(deleteDoc(doc(f, "operations/pme/participations/p1")));
  });

  it("un membre voit sa participation, pas celle des autres", async () => {
    await assertSucceeds(getDoc(doc(db("membre", "membre"), "operations/pme/participations/p1")));
    await assertFails(getDoc(doc(db("partenaire", "partenaire"), "operations/pme/participations/p1")));
  });
});

describe("pièces d'identité (Storage)", () => {
  it("chacun dépose dans son dossier, l'équipe lit, personne d'autre", async () => {
    const proprio = contexte("membre", "membre").storage();
    await assertSucceeds(uploadString(ref(proprio, "kyc/membre/recto.jpg"), "image", "raw", { contentType: "image/jpeg" }));
    await assertFails(uploadString(ref(proprio, "kyc/partenaire/recto.jpg"), "image", "raw", { contentType: "image/jpeg" }));
    await assertFails(uploadString(ref(proprio, "kyc/membre/script.js"), "x", "raw", { contentType: "text/javascript" }));
    await assertFails(getBytes(ref(contexte("partenaire", "partenaire").storage(), "kyc/membre/recto.jpg")));
    await assertSucceeds(getBytes(ref(contexte("an", "analyste", true).storage(), "kyc/membre/recto.jpg")));
  });
});
