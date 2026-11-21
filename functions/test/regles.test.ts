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
    await setDoc(doc(f, "users/ent"), profil("entreprise"));
    await setDoc(doc(f, "users/ent2"), profil("entreprise"));
    await setDoc(doc(f, "users/notaire"), profil("notaire"));
    await setDoc(doc(f, "users/fourn"), profil("fournisseur"));
    await setDoc(doc(f, "invitations/ARZ-AAAA-BBBB"), { pourNom: "Awa", pourTelephone: "+22890123456", niveau: "membre" });
    await setDoc(doc(f, "candidatures/ancien"), { uid: "ancien", statut: "soumise" });
    await setDoc(doc(f, "audit/a1"), { action: "test" });
    const op = (partenairesProposes: string[], statut = "proposee") => ({
      statut,
      partenairesProposes,
      entrepriseUid: "ent",
      notaireUid: "notaire",
      fournisseurUids: ["fourn"],
      prixAchat: 10000000,
      majoration: 300000,
    });
    await setDoc(doc(f, "operations/pme"), op(["membre", "membre_attente"]));
    await setDoc(doc(f, "operations/grand"), op(["partenaire"]));
    await setDoc(doc(f, "operations/fermee"), op([], "en_analyse"));
    await setDoc(doc(f, "operations/pme/interets/membre"), { uid: "membre", montantIndicatif: 1000000, engageant: false });
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

describe("invitations et journal", () => {
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

  it("les candidatures spontanées n'existent plus (invitation seule)", async () => {
    await assertFails(getDoc(doc(db("ancien", "membre"), "candidatures/ancien")));
    await assertFails(getDoc(doc(db("sa", "super_admin", true), "candidatures/ancien")));
    await assertFails(setDoc(doc(db("ancien", "membre"), "candidatures/ancien"), { statut: "soumise" }));
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

describe("opérations en vente à terme", () => {
  it("un partenaire vérifié voit seulement les opérations qui lui sont proposées", async () => {
    await assertSucceeds(getDoc(doc(db("membre", "membre"), "operations/pme")));
    await assertFails(getDoc(doc(db("membre", "membre"), "operations/grand")));
    await assertFails(getDoc(doc(db("membre", "membre"), "operations/fermee")));
    await assertSucceeds(getDoc(doc(db("partenaire", "partenaire"), "operations/grand")));
    await assertFails(getDoc(doc(db("partenaire", "partenaire"), "operations/pme")));
  });

  it("aucune opération pour un compte non validé, même s'il est dans la liste", async () => {
    await assertFails(getDoc(doc(db("membre_attente", "membre"), "operations/pme")));
  });

  it("l'entreprise voit son opération mais jamais les manifestations d'intérêt", async () => {
    await assertSucceeds(getDoc(doc(db("ent", "entreprise"), "operations/pme")));
    await assertSucceeds(getDoc(doc(db("ent", "entreprise"), "operations/pme/evenements/e1")));
    await assertFails(getDoc(doc(db("ent", "entreprise"), "operations/pme/interets/membre")));
    await assertFails(getDoc(doc(db("ent2", "entreprise"), "operations/pme")));
  });

  it("notaire et fournisseur : seulement ce qui leur est assigné", async () => {
    await assertSucceeds(getDoc(doc(db("notaire", "notaire"), "operations/pme")));
    await assertSucceeds(getDoc(doc(db("fourn", "fournisseur"), "operations/pme")));
    await assertFails(getDoc(doc(db("autre_notaire", "notaire"), "operations/pme")));
  });

  it("un partenaire voit sa manifestation d'intérêt, pas celle des autres, et n'écrit rien lui-même", async () => {
    await assertSucceeds(getDoc(doc(db("membre", "membre"), "operations/pme/interets/membre")));
    await assertFails(getDoc(doc(db("partenaire", "partenaire"), "operations/pme/interets/membre")));
    await assertFails(setDoc(doc(db("membre", "membre"), "operations/pme/interets/membre"), { montantIndicatif: 1, engageant: true }));
    await assertFails(updateDoc(doc(db("membre", "membre"), "operations/pme"), { majoration: 0 }));
  });

  it("l'équipe lit tout, mais n'écrit rien sans passer par le serveur", async () => {
    await assertSucceeds(getDoc(doc(db("an", "analyste", true), "operations/pme/interets/membre")));
    await assertFails(updateDoc(doc(db("sa", "super_admin", true), "operations/pme"), { statut: "cloturee" }));
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
    // Formats limités : PDF, JPG, PNG.
    await assertFails(uploadString(ref(proprio, "kyc/membre/photo.gif"), "x", "raw", { contentType: "image/gif" }));
    await assertSucceeds(uploadString(ref(proprio, "kyc/membre/releve.pdf"), "x", "raw", { contentType: "application/pdf" }));
  });

  it("documents d'opération : seule l'équipe dépose et lit directement", async () => {
    const pdf = { contentType: "application/pdf" };
    await assertSucceeds(uploadString(ref(contexte("sa", "super_admin", true).storage(), "operations/pme/projet.pdf"), "x", "raw", pdf));
    await assertFails(uploadString(ref(contexte("membre", "membre").storage(), "operations/pme/faux.pdf"), "x", "raw", pdf));
    await assertFails(uploadString(ref(contexte("ent", "entreprise").storage(), "operations/pme/faux.pdf"), "x", "raw", pdf));
    await assertFails(getBytes(ref(contexte("ent", "entreprise").storage(), "operations/pme/projet.pdf")));
    await assertFails(getBytes(ref(contexte("membre", "membre").storage(), "operations/pme/projet.pdf")));
    // Le notaire dépose ses actes dans son propre dossier.
    await assertSucceeds(uploadString(ref(contexte("notaire", "notaire").storage(), "notaires/notaire/acte.pdf"), "x", "raw", pdf));
    await assertFails(uploadString(ref(contexte("notaire", "notaire").storage(), "notaires/autre/acte.pdf"), "x", "raw", pdf));
    await assertFails(uploadString(ref(contexte("membre", "membre").storage(), "notaires/membre/acte.pdf"), "x", "raw", pdf));
  });
});
