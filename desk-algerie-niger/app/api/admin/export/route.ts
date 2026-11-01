// Export CSV des demandes (séparateur point-virgule, encodage UTF-8 avec BOM pour Excel).

import { NextResponse, type NextRequest } from "next/server";
import { base, baseConfiguree, type LigneDemande } from "@/lib/base";
import { estConnecte } from "@/lib/session";
import { budgetFr, PAYS_FR, PROFILS_FR, secteurFr, serviceFr, statutFr } from "@/lib/admin";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function cellule(v: unknown): string {
  let s = v === null || v === undefined ? "" : String(v);
  // Neutralise les formules (protection contre l'injection dans les tableurs).
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return `"${s.replace(/"/g, '""')}"`;
}

export async function GET(req: NextRequest) {
  if (!(await estConnecte())) return new NextResponse("Accès refusé", { status: 401 });
  if (!baseConfiguree()) return new NextResponse("Base non configurée", { status: 503 });

  const p = req.nextUrl.searchParams;
  let q = base().from("demandes").select("*").order("cree_le", { ascending: false });
  for (const champ of ["statut", "pays", "service"] as const) {
    const v = p.get(champ);
    if (v) q = q.eq(champ, v);
  }
  const { data, error } = await q;
  if (error) return new NextResponse(error.message, { status: 500 });

  const entetes = [
    "Référence", "Date", "Statut", "Nom", "Entreprise", "Fonction", "Pays", "Profil", "Service", "Secteur",
    "Budget", "E-mail", "Téléphone", "Message", "Langue préférée", "Langue du site", "Page d'origine", "Notes",
  ];
  const lignes = (data as LigneDemande[]).map((d) =>
    [
      d.id, d.cree_le, statutFr(d.statut), d.nom, d.entreprise, d.fonction, PAYS_FR[d.pays] ?? d.pays,
      PROFILS_FR[d.profil] ?? d.profil, serviceFr(d.service), secteurFr(d.secteur), budgetFr(d.budget),
      d.email, d.telephone, d.message, d.langue_preferee, d.langue, d.source, d.notes,
    ]
      .map(cellule)
      .join(";"),
  );
  const csv = "﻿" + [entetes.map(cellule).join(";"), ...lignes].join("\r\n");
  const jour = new Date().toISOString().slice(0, 10);
  return new NextResponse(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="demandes-desk-${jour}.csv"`,
      "Cache-Control": "no-store",
    },
  });
}
