// Réception d'une demande : validation, anti-spam, enregistrement, e-mails.
// La réponse « ok » n'est renvoyée que si la demande est réellement parvenue à NEXUS
// (enregistrée en base ou envoyée par e-mail). Sinon, le visiteur voit les contacts directs.

import { NextResponse, type NextRequest } from "next/server";
import { createHash } from "node:crypto";
import { schemaDemande } from "@/lib/formulaire";
import { autoriser } from "@/lib/limite";
import { base, baseConfiguree } from "@/lib/base";
import { courrielConfigure, envoyerAccuse, envoyerANexus } from "@/lib/courriel";

export const runtime = "nodejs";

async function verifierTurnstile(jeton: unknown, ip: string): Promise<boolean> {
  const secret = process.env.TURNSTILE_SECRET_KEY;
  if (!secret) return true; // Option désactivée tant que la clé n'est pas fournie.
  if (typeof jeton !== "string" || !jeton) return false;
  const corps = new URLSearchParams({ secret, response: jeton, remoteip: ip });
  const rep = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body: corps,
  });
  const json = (await rep.json()) as { success?: boolean };
  return json.success === true;
}

export async function POST(req: NextRequest) {
  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "inconnue";
  const cleIp = createHash("sha256").update(ip).digest("hex").slice(0, 32);

  if (!autoriser(cleIp)) {
    return NextResponse.json({ ok: false, raison: "trop" }, { status: 429 });
  }

  let brut: Record<string, unknown>;
  try {
    brut = await req.json();
  } catch {
    return NextResponse.json({ ok: false, raison: "invalide" }, { status: 400 });
  }

  const langueSite = brut.langueSite === "fr" ? "fr" : "ar";
  const resultat = schemaDemande.safeParse(brut);
  if (!resultat.success) {
    return NextResponse.json(
      { ok: false, raison: "invalide", champs: resultat.error.issues.map((i) => i.path.join(".")) },
      { status: 400 },
    );
  }
  const d = resultat.data;

  // Piège à robots rempli : on fait comme si tout allait bien, sans rien enregistrer.
  if (d.siteWeb) return NextResponse.json({ ok: true });

  if (!(await verifierTurnstile(brut.turnstile, ip))) {
    return NextResponse.json({ ok: false, raison: "robot" }, { status: 400 });
  }

  let id: string | null = null;
  if (baseConfiguree()) {
    try {
      const { data, error } = await base()
        .from("demandes")
        .insert({
          statut: "nouveau",
          langue: langueSite,
          source: d.source || null,
          nom: d.nom,
          entreprise: d.entreprise || null,
          fonction: d.fonction || null,
          pays: d.pays,
          profil: d.profil,
          service: d.service || null,
          secteur: d.secteur || null,
          budget: d.budget || null,
          email: d.email || null,
          telephone: d.telephone || null,
          message: d.message || null,
          langue_preferee: d.languePreferee,
          consentement: d.consentement,
        })
        .select("id")
        .single();
      if (error) throw error;
      id = data.id as string;
    } catch (e) {
      console.error("Enregistrement de la demande impossible :", (e as Error).message);
    }
  }

  let notifie = false;
  if (courrielConfigure()) {
    try {
      await envoyerANexus(d, langueSite, id);
      notifie = true;
    } catch (e) {
      console.error("E-mail à NEXUS impossible :", (e as Error).message);
    }
  }

  const recue = id !== null || notifie;
  if (!recue) {
    return NextResponse.json({ ok: false, raison: "envoi" }, { status: 503 });
  }

  // L'accusé de réception ne conditionne pas le succès : la demande est déjà chez NEXUS.
  if (courrielConfigure() && d.email) {
    try {
      await envoyerAccuse(d);
    } catch (e) {
      console.error("Accusé de réception impossible :", (e as Error).message);
    }
  }

  return NextResponse.json({ ok: true });
}
