// Tests des règles d'accès côté serveur (mêmes règles que l'application).

import { describe, expect, it } from "vitest";

import {
  Acteur,
  ErreurAcces,
  InvitationDoc,
  exigerAdministration,
  exigerDroitAttribution,
  genererCodeInvitation,
  normaliserTelephone,
  statutApres,
  verifierInvitation,
} from "../src/acces";

const superAdmin: Acteur = { uid: "sa", role: "super_admin", doubleFacteur: true };
const admin: Acteur = { uid: "ad", role: "admin", doubleFacteur: true };
const analyste: Acteur = { uid: "an", role: "analyste", doubleFacteur: true };

const maintenant = new Date("2026-11-01T10:00:00Z");
const invitation = (modif: Partial<InvitationDoc> = {}): InvitationDoc => ({
  pourNom: "Awa Traoré",
  pourTelephone: "+22890123456",
  niveau: "partenaire",
  creePar: "sa",
  creeLe: new Date("2026-10-30"),
  expireLe: new Date("2026-11-30"),
  ...modif,
});

describe("administration", () => {
  it("exige un rôle validateur", () => {
    expect(() => exigerAdministration(analyste, ["super_admin", "admin"], true)).toThrow(ErreurAcces);
    expect(() => exigerAdministration({ uid: "m", role: "membre", doubleFacteur: true }, ["admin"], true)).toThrow();
    expect(() => exigerAdministration(admin, ["super_admin", "admin"], true)).not.toThrow();
  });

  it("exige le double facteur", () => {
    expect(() => exigerAdministration({ ...admin, doubleFacteur: false }, ["admin"], true)).toThrow(/double facteur/);
  });
});

describe("attribution des rôles", () => {
  it("personne ne modifie son propre rôle", () => {
    expect(() => exigerDroitAttribution(admin, "ad", "admin", "membre")).toThrow(/propre rôle/);
  });
  it("le rôle super_admin ne se donne jamais", () => {
    expect(() => exigerDroitAttribution(superAdmin, "x", "admin", "super_admin")).toThrow();
  });
  it("seul le super_admin touche à l'administration", () => {
    expect(() => exigerDroitAttribution(admin, "x", "membre", "admin")).toThrow();
    expect(() => exigerDroitAttribution(admin, "x", "analyste", "membre")).toThrow();
    expect(() => exigerDroitAttribution(superAdmin, "x", "membre", "analyste")).not.toThrow();
  });
  it("un admin change le niveau d'un investisseur", () => {
    expect(() => exigerDroitAttribution(admin, "x", "membre", "partenaire")).not.toThrow();
  });
});

describe("invitations", () => {
  it("valide pour le bon numéro", () => {
    expect(verifierInvitation(invitation(), "+22890123456", maintenant).niveau).toBe("partenaire");
  });
  it("refusée pour un autre numéro, utilisée, annulée ou expirée", () => {
    expect(() => verifierInvitation(invitation(), "+22899999999", maintenant)).toThrow();
    expect(() => verifierInvitation(invitation(), undefined, maintenant)).toThrow();
    expect(() => verifierInvitation(invitation({ utiliseLe: new Date() }), "+22890123456", maintenant)).toThrow();
    expect(() => verifierInvitation(invitation({ annuleeLe: new Date() }), "+22890123456", maintenant)).toThrow();
    expect(() => verifierInvitation(invitation({ expireLe: new Date("2026-10-31") }), "+22890123456", maintenant)).toThrow();
    expect(() => verifierInvitation(undefined, "+22890123456", maintenant)).toThrow();
  });
  it("codes lisibles, sans caractères ambigus", () => {
    for (let i = 0; i < 200; i++) {
      const code = genererCodeInvitation();
      expect(code).toMatch(/^ARZ-[A-Z2-9]{4}-[A-Z2-9]{4}$/);
      expect(code).not.toMatch(/[01OIL]/);
    }
  });
});

describe("outils", () => {
  it("normalise les numéros", () => {
    expect(normaliserTelephone("90 12 34 56")).toBe("+22890123456");
    expect(normaliserTelephone("0022990123456")).toBe("+22990123456");
    expect(normaliserTelephone("+225 07 00 00 00 00")).toBe("+2250700000000");
  });
  it("un candidat reste en attente même avec une identité validée", () => {
    expect(statutApres("candidat_cercle", "valide")).toBe("en_attente");
    expect(statutApres("membre", "valide")).toBe("actif");
    expect(statutApres("membre", "en_cours")).toBe("en_attente");
  });
});
