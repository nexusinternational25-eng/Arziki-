// Tests de la vérification du numéro par WhatsApp (logique pure, sans Firebase).

import { createHmac } from "crypto";
import { describe, expect, it } from "vitest";

import {
  DUREE_VALIDITE_MS,
  MAX_DEMANDES_PAR_HEURE,
  MAX_ESSAIS,
  VerificationDoc,
  codeCorrespond,
  corpsModeleCode,
  demandesRecentes,
  extraireCode,
  extraireMessages,
  finaliser,
  genererCode,
  genererSel,
  hacherCode,
  lienWhatsapp,
  messageAEnvoyer,
  messageConfirme,
  signatureValide,
} from "../src/whatsapp";

const T0 = 1_800_000_000_000;

function verification(canal: "message" | "code", code = "482915", maj: Partial<VerificationDoc> = {}): VerificationDoc {
  const sel = genererSel();
  return {
    telephone: "+22890000021",
    canal,
    codeHache: hacherCode(code, sel),
    sel,
    creeLeMs: T0,
    expireLeMs: T0 + DUREE_VALIDITE_MS,
    essais: 0,
    statut: "en_attente",
    ...maj,
  };
}

describe("codes", () => {
  it("génère toujours 6 chiffres", () => {
    for (let i = 0; i < 200; i++) expect(genererCode()).toMatch(/^\d{6}$/);
  });
  it("ne stocke jamais le code en clair et le compare correctement", () => {
    const doc = verification("code", "000123");
    expect(doc.codeHache).not.toContain("000123");
    expect(codeCorrespond("000123", doc)).toBe(true);
    expect(codeCorrespond(" 000123 ", doc)).toBe(true);
    expect(codeCorrespond("000124", doc)).toBe(false);
  });
  it("retrouve le code dans le message du client", () => {
    expect(extraireCode(messageAEnvoyer("482915"))).toBe("482915");
    expect(extraireCode("bonjour")).toBeNull();
    expect(extraireCode("1234567")).toBeNull();
  });
  it("fabrique le lien WhatsApp vers le numéro d'ARZIKI", () => {
    const lien = lienWhatsapp("+228 90 00 00 00", "Bonjour ARZIKI : 482915");
    expect(lien).toBe("https://wa.me/22890000000?text=Bonjour%20ARZIKI%20%3A%20482915");
  });
});

describe("signature de Meta", () => {
  const corps = Buffer.from('{"entry":[]}');
  const bonne = "sha256=" + createHmac("sha256", "secret").update(corps).digest("hex");
  it("accepte la bonne signature", () => expect(signatureValide(corps, bonne, "secret")).toBe(true));
  it("refuse une signature fausse, absente ou un secret vide", () => {
    expect(signatureValide(corps, bonne, "autre")).toBe(false);
    expect(signatureValide(corps, undefined, "secret")).toBe(false);
    expect(signatureValide(corps, "sha256=abcd", "secret")).toBe(false);
    expect(signatureValide(corps, bonne, "")).toBe(false);
  });
});

describe("messages reçus", () => {
  const charge = {
    entry: [
      {
        changes: [
          {
            value: {
              messages: [
                { from: "22890000021", type: "text", text: { body: messageAEnvoyer("482915") } },
                { from: "22890000022", type: "image", image: {} },
              ],
            },
          },
        ],
      },
    ],
  };
  it("extrait seulement les messages texte, numéro au format international", () => {
    expect(extraireMessages(charge)).toEqual([{ de: "+22890000021", texte: messageAEnvoyer("482915") }]);
    expect(extraireMessages(null)).toEqual([]);
    expect(extraireMessages({ entry: [{ changes: [{ value: { statuses: [] } }] }] })).toEqual([]);
  });
  it("confirme seulement le bon numéro avec le bon code, avant l'expiration", () => {
    const doc = verification("message");
    const ok = { de: "+22890000021", texte: messageAEnvoyer("482915") };
    expect(messageConfirme(doc, ok, T0 + 1000)).toBe(true);
    expect(messageConfirme(doc, { ...ok, de: "+22890000099" }, T0 + 1000)).toBe(false);
    expect(messageConfirme(doc, { ...ok, texte: messageAEnvoyer("111111") }, T0 + 1000)).toBe(false);
    expect(messageConfirme(doc, ok, T0 + DUREE_VALIDITE_MS + 1)).toBe(false);
    expect(messageConfirme({ ...doc, statut: "utilisee" }, ok, T0 + 1000)).toBe(false);
    expect(messageConfirme(verification("code"), ok, T0 + 1000)).toBe(false);
  });
});

describe("finalisation", () => {
  it("canal message : en attente, puis valide une seule fois", () => {
    expect(finaliser(verification("message"), T0 + 1000).etat).toBe("en_attente");
    const r = finaliser(verification("message", "482915", { statut: "confirmee" }), T0 + 1000);
    expect(r).toMatchObject({ etat: "valide", telephone: "+22890000021", maj: { statut: "utilisee" } });
    expect(finaliser(verification("message", "482915", { statut: "utilisee" }), T0 + 1000).etat).toBe("refuse");
  });
  it("canal code : bon code accepté, mauvais code compté, blocage après 5 essais", () => {
    expect(finaliser(verification("code"), T0 + 1000, "482915").etat).toBe("valide");
    const faux = finaliser(verification("code"), T0 + 1000, "000000");
    expect(faux).toMatchObject({ etat: "refuse", message: "Code incorrect.", maj: { essais: 1 } });
    const dernier = finaliser(verification("code", "482915", { essais: MAX_ESSAIS - 1 }), T0 + 1000, "000000");
    expect(dernier).toMatchObject({ etat: "refuse", maj: { statut: "bloquee" } });
    expect(finaliser(verification("code", "482915", { statut: "bloquee" }), T0 + 1000, "482915").etat).toBe("refuse");
  });
  it("refuse après 10 minutes et sans code", () => {
    expect(finaliser(verification("code"), T0 + DUREE_VALIDITE_MS + 1, "482915").etat).toBe("refuse");
    expect(finaliser(verification("code"), T0 + 1000).etat).toBe("refuse");
  });
});

describe("limites et envoi", () => {
  it("accepte 5 demandes par heure, refuse la 6e, oublie les anciennes", () => {
    let d: number[] = [];
    for (let i = 0; i < MAX_DEMANDES_PAR_HEURE; i++) d = demandesRecentes(d, T0 + i);
    expect(() => demandesRecentes(d, T0 + 10)).toThrow(/Trop de demandes/);
    expect(demandesRecentes(d, T0 + 60 * 60 * 1000 + 10)).toHaveLength(1);
  });
  it("prépare le modèle d'authentification WhatsApp en français", () => {
    const c = corpsModeleCode("+22890000021", "482915");
    expect(c.to).toBe("22890000021");
    expect(c.template.language.code).toBe("fr");
    expect(JSON.stringify(c)).toContain("482915");
  });
});
