// Tests des opérations en vente à terme (CLAUDE.md, section 24).
// Les cas chiffrés viennent de test/vecteurs/operations.json, partagé avec l'application.

import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";

import {
  EtatOperation,
  PLAFOND_PARTENAIRES_DEFAUT,
  STATUTS,
  TRANSITIONS,
  alerteCoutAnnuel,
  coutAnnuelEquivalent,
  doitPasserEnRetard,
  prixRevente,
  repartir,
  verifierPlaceDisponible,
  verifierPlafondParametre,
  verifierTransition,
} from "../src/operations";

type Ligne = [string, number];
const vecteurs = JSON.parse(readFileSync(join(__dirname, "..", "..", "test", "vecteurs", "operations.json"), "utf8"));

describe("prix de revente et coût annuel équivalent", () => {
  for (const c of vecteurs.conditions) {
    it(c.cas, () => {
      expect(prixRevente(c)).toBe(c.prixRevente);
      expect(coutAnnuelEquivalent(c)).toBe(c.coutAnnuel);
      expect(alerteCoutAnnuel(c)).toBe(c.alerte);
    });
  }
  it("le seuil d'alerte est paramétrable", () => {
    const c = { prixAchat: 10000000, majoration: 300000, dureeJours: 60 }; // 18,25 %
    expect(alerteCoutAnnuel(c, 15)).toBe(true);
    expect(alerteCoutAnnuel(c, 20)).toBe(false);
  });
  for (const c of vecteurs.invalides) {
    it(`refuse : ${c.cas}`, () => expect(() => prixRevente(c)).toThrow());
  }
});

describe("répartition entre partenaires", () => {
  for (const r of vecteurs.repartitions) {
    it(r.cas, () => {
      const res = repartir(r, (r.apports as Ligne[]).map(([partenaireUid, montant]) => ({ partenaireUid, montant })));
      expect(res.map((x) => [x.partenaireUid, x.partMajoration, x.aRecevoir])).toEqual(r.attendu);
      // La somme reçue est exactement le prix de revente : rien ne se perd à l'arrondi.
      expect(res.reduce((s, x) => s + x.aRecevoir, 0)).toBe(r.prixAchat + r.majoration);
    });
  }
  for (const r of vecteurs.repartitionsInvalides) {
    it(`refuse : ${r.cas}`, () =>
      expect(() => repartir(r, (r.apports as Ligne[]).map(([partenaireUid, montant]) => ({ partenaireUid, montant })))).toThrow());
  }
});

describe("cycle de vie (R4)", () => {
  const base: EtatOperation = {
    statut: "proposee",
    garanties: [],
    apportsRetenus: [],
    prixAchat: 10000000,
    nombreInterets: 0,
  };

  it("chaque statut a ses transitions, et les statuts finaux n'en ont pas", () => {
    for (const s of STATUTS) expect(TRANSITIONS[s]).toBeDefined();
    expect(TRANSITIONS.cloturee).toEqual([]);
    expect(TRANSITIONS.refusee).toEqual([]);
    expect(TRANSITIONS.annulee).toEqual([]);
  });

  it("parcours complet de la soumission à la clôture", () => {
    const chemin = ["soumise", "en_analyse", "proposee", "interet_manifeste", "signee", "fournisseur_paye", "livree", "echeance_payee", "cloturee"] as const;
    const op: EtatOperation = {
      ...base,
      statut: "soumise",
      nombreInterets: 1,
      apportsRetenus: [{ partenaireUid: "a", montant: 10000000 }],
      garanties: [{ type: "reserve_propriete", statut: "signee" }],
    };
    for (let i = 1; i < chemin.length; i++) {
      verifierTransition({ ...op, statut: chemin[i - 1] }, chemin[i]);
    }
  });

  it("pas de saut d'étape ni de retour en arrière", () => {
    expect(() => verifierTransition({ ...base, statut: "soumise" }, "signee")).toThrow(/impossible/);
    expect(() => verifierTransition({ ...base, statut: "cloturee" }, "en_analyse")).toThrow(/impossible/);
    expect(() => verifierTransition({ ...base, statut: "signee" }, "proposee")).toThrow(/impossible/);
  });

  it("l'intérêt manifesté exige au moins une manifestation", () => {
    expect(() => verifierTransition(base, "interet_manifeste")).toThrow(/manifestation/);
    verifierTransition({ ...base, nombreInterets: 2 }, "interet_manifeste");
  });

  it("la signature exige des apports exacts et au moins une garantie", () => {
    const op: EtatOperation = { ...base, statut: "interet_manifeste", nombreInterets: 1 };
    expect(() => verifierTransition(op, "signee")).toThrow(/apports/);
    const avecApports = { ...op, apportsRetenus: [{ partenaireUid: "a", montant: 10000000 }] };
    expect(() => verifierTransition(avecApports, "signee")).toThrow(/garantie/);
    verifierTransition({ ...avecApports, garanties: [{ type: "cautionnement", statut: "a_constituer" }] }, "signee");
  });

  it("pas de paiement au fournisseur sans garanties signées", () => {
    const op: EtatOperation = {
      ...base,
      statut: "signee",
      garanties: [
        { type: "reserve_propriete", statut: "signee" },
        { type: "hypotheque", statut: "a_constituer" },
      ],
    };
    expect(() => verifierTransition(op, "fournisseur_paye")).toThrow(/garanties/);
    op.garanties[1].statut = "inscrite_rccm";
    verifierTransition(op, "fournisseur_paye");
  });

  it("retard puis recouvrement", () => {
    verifierTransition({ ...base, statut: "livree" }, "en_retard");
    verifierTransition({ ...base, statut: "en_retard" }, "en_recouvrement");
    verifierTransition({ ...base, statut: "en_recouvrement" }, "cloturee");
    expect(doitPasserEnRetard("livree", 1000, 2000)).toBe(true);
    expect(doitPasserEnRetard("livree", 3000, 2000)).toBe(false);
    expect(doitPasserEnRetard("echeance_payee", 1000, 2000)).toBe(false);
  });
});

describe("plafond de partenaires (R3)", () => {
  it("50 par défaut", () => {
    expect(PLAFOND_PARTENAIRES_DEFAUT).toBe(50);
    verifierPlaceDisponible(49);
    expect(() => verifierPlaceDisponible(50)).toThrow(/Plafond atteint : 50/);
  });
  it("réglable entre 1 et 99, jamais au-delà", () => {
    verifierPlaceDisponible(80, 99);
    expect(() => verifierPlaceDisponible(99, 99)).toThrow(/99/);
    expect(() => verifierPlafondParametre(100)).toThrow();
    expect(() => verifierPlafondParametre(0)).toThrow();
    expect(() => verifierPlafondParametre(30.5)).toThrow();
  });
});
