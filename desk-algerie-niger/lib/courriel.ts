// Envoi des e-mails avec Resend : notification à NEXUS et accusé de réception au visiteur.

import "server-only";
import { Resend } from "resend";
import { SERVICES, SECTEURS } from "./contenu";
import { libelleBudget, type Demande } from "./formulaire";

const EXPEDITEUR = process.env.RESEND_FROM || "Desk Algérie-Niger <onboarding@resend.dev>";
const DESTINATAIRE = process.env.CONTACT_TO_EMAIL || "operation@amanexus.com";

export function courrielConfigure(): boolean {
  return Boolean(process.env.RESEND_API_KEY);
}

function echapper(v: string): string {
  return v
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

const PAYS: Record<string, string> = { DZ: "Algérie", NE: "Niger", autre: "Autre pays" };
const PROFILS: Record<string, string> = {
  algerie: "Entreprise algérienne",
  niger: "Opérateur nigérien",
  autre: "Autre",
};

function lignesNexus(d: Demande, langueSite: string) {
  const service = SERVICES.find((s) => s.slug === d.service)?.titre.fr ?? "Non précisé";
  const secteur =
    d.secteur === "autre" ? "Autre" : (SECTEURS.find((s) => s.code === d.secteur)?.titre.fr ?? "Non précisé");
  return [
    ["Nom", d.nom],
    ["Entreprise", d.entreprise || "Non précisée"],
    ["Fonction", d.fonction || "Non précisée"],
    ["Pays", PAYS[d.pays]],
    ["Profil", PROFILS[d.profil]],
    ["Service", service],
    ["Secteur", secteur],
    ["Budget", d.budget ? libelleBudget(d.budget, "fr") : "Non précisé"],
    ["E-mail", d.email || "Non indiqué"],
    ["Téléphone / WhatsApp", d.telephone || "Non indiqué"],
    ["Langue préférée", d.languePreferee === "ar" ? "Arabe" : "Français"],
    ["Langue du site", langueSite === "ar" ? "Arabe" : "Français"],
    ["Page d'origine", d.source || "Inconnue"],
  ] as const;
}

/** E-mail interne à NEXUS, lisible sur téléphone (une colonne, gros caractères). */
export async function envoyerANexus(d: Demande, langueSite: string, id: string | null) {
  const resend = new Resend(process.env.RESEND_API_KEY);
  const lignes = lignesNexus(d, langueSite);
  const html = `<!doctype html><html lang="fr"><body style="margin:0;background:#f4efe6;font-family:Arial,sans-serif;color:#16233a">
<div style="max-width:560px;margin:0 auto;padding:16px">
<div style="background:#1b2d52;color:#fff;padding:16px;border-radius:8px 8px 0 0">
<div style="font-size:13px;opacity:.8">Desk Algérie-Niger</div>
<div style="font-size:20px;font-weight:bold;margin-top:4px">Nouvelle demande : ${echapper(d.nom)}</div>
</div>
<div style="background:#fffdf8;padding:16px;border-radius:0 0 8px 8px">
${lignes
  .map(
    ([k, v]) =>
      `<div style="padding:8px 0;border-bottom:1px solid #e6dfd2"><div style="font-size:12px;color:#5d6573">${k}</div><div style="font-size:16px">${echapper(v)}</div></div>`,
  )
  .join("")}
<div style="padding:12px 0"><div style="font-size:12px;color:#5d6573">Message</div>
<div style="font-size:16px;white-space:pre-wrap">${echapper(d.message || "Aucun message")}</div></div>
${id ? `<div style="font-size:12px;color:#5d6573">Référence : ${id}</div>` : `<div style="font-size:13px;color:#b42318">Attention : la demande n'a pas pu être enregistrée en base.</div>`}
</div></div></body></html>`;
  const texte = lignes.map(([k, v]) => `${k} : ${v}`).join("\n") + `\n\nMessage :\n${d.message || "Aucun message"}`;
  const { error } = await resend.emails.send({
    from: EXPEDITEUR,
    to: DESTINATAIRE,
    replyTo: d.email || undefined,
    subject: `Nouvelle demande Desk Algérie-Niger : ${d.nom}`,
    html,
    text: texte,
  });
  if (error) throw new Error(error.message);
}

/** Accusé de réception au visiteur, dans sa langue préférée. */
export async function envoyerAccuse(d: Demande) {
  if (!d.email) return;
  const resend = new Resend(process.env.RESEND_API_KEY);
  const ar = d.languePreferee === "ar";
  const sujet = ar ? "تم استلام طلبكم - مكتب الجزائر - النيجر" : "Votre demande a bien été reçue - Desk Algérie-Niger";
  const corps = ar
    ? [
        `${echapper(d.nom)}،`,
        "شكرا لكم على ثقتكم. لقد استلمنا طلبكم، وسيدرسه فريق نيكسوس إنترناشونال ثم يعود إليكم.",
        "للتواصل المباشر: operation@amanexus.com أو واتساب ‎+228 91 97 80 80.",
        "مكتب الجزائر - النيجر، مبادرة خاصة من نيكسوس إنترناشونال. ليس موقعا رسميا للحكومة الجزائرية ولا للحكومة النيجرية.",
      ]
    : [
        `Bonjour ${echapper(d.nom)},`,
        "Merci de votre confiance. Nous avons bien reçu votre demande. L'équipe NEXUS International l'étudie et revient vers vous.",
        "Pour nous joindre directement : operation@amanexus.com ou WhatsApp +228 91 97 80 80.",
        "Desk Algérie-Niger, initiative privée de NEXUS International. Ce portail n'est pas un site officiel des gouvernements algérien ou nigérien.",
      ];
  const html = `<!doctype html><html lang="${ar ? "ar" : "fr"}" dir="${ar ? "rtl" : "ltr"}"><body style="margin:0;background:#f4efe6;font-family:Arial,sans-serif;color:#16233a">
<div style="max-width:560px;margin:0 auto;padding:16px">
<div style="background:#1b2d52;color:#fff;padding:16px;border-radius:8px 8px 0 0;font-size:18px;font-weight:bold">${ar ? "مكتب الجزائر - النيجر" : "Desk Algérie-Niger"}</div>
<div style="background:#fffdf8;padding:16px;border-radius:0 0 8px 8px;font-size:16px;line-height:1.6">
${corps.map((p, i) => `<p style="margin:0 0 12px;${i === corps.length - 1 ? "font-size:12px;color:#5d6573" : ""}">${p}</p>`).join("")}
</div></div></body></html>`;
  const { error } = await resend.emails.send({
    from: EXPEDITEUR,
    to: d.email,
    replyTo: DESTINATAIRE,
    subject: sujet,
    html,
    text: corps.join("\n\n"),
  });
  if (error) throw new Error(error.message);
}
