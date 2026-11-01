import Link from "next/link";
import { base, baseConfiguree, type LigneDemande } from "@/lib/base";
import { adminConfigure, estConnecte } from "@/lib/session";
import { SERVICES } from "@/lib/contenu";
import { STATUTS, type Statut } from "@/lib/formulaire";
import { COULEUR_STATUT, dateFr, PAYS_FR, serviceFr, statutFr } from "@/lib/admin";
import { Connexion } from "./Connexion";
import { EnTeteAdmin } from "./EnTeteAdmin";

export const dynamic = "force-dynamic";

const un = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";

export default async function Admin({ searchParams }: PageProps<"/admin">) {
  if (!adminConfigure()) {
    return (
      <div className="carte mx-auto mt-24 max-w-md p-8">
        <h1 className="text-xl font-semibold">Espace d&apos;administration fermé</h1>
        <p className="mt-2 text-gris">
          Le mot de passe n&apos;est pas encore configuré (variable ADMIN_PASSWORD, 12 caractères au moins). Voir A_COMPLETER.md.
        </p>
      </div>
    );
  }
  if (!(await estConnecte())) return <Connexion />;

  const q = await searchParams;
  const filtres = { statut: un(q.statut), pays: un(q.pays), service: un(q.service) };

  let demandes: LigneDemande[] = [];
  let erreur: string | null = null;
  if (!baseConfiguree()) {
    erreur = "La base Supabase n'est pas encore configurée : les demandes arrivent seulement par e-mail.";
  } else {
    let req = base().from("demandes").select("*").order("cree_le", { ascending: false }).limit(500);
    if (filtres.statut) req = req.eq("statut", filtres.statut);
    if (filtres.pays) req = req.eq("pays", filtres.pays);
    if (filtres.service) req = req.eq("service", filtres.service);
    const { data, error } = await req;
    if (error) erreur = `Lecture impossible : ${error.message}`;
    else demandes = data as LigneDemande[];
  }

  const exportUrl = `/api/admin/export?${new URLSearchParams(Object.entries(filtres).filter(([, v]) => v)).toString()}`;

  return (
    <>
      <EnTeteAdmin />
      <main className="conteneur py-8">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <h1 className="text-2xl font-semibold">Demandes reçues</h1>
          <a href={exportUrl} className="bouton bouton-secondaire min-h-10 py-2 text-sm">
            Exporter la sélection en CSV
          </a>
        </div>

        <form className="carte mt-6 grid gap-4 p-4 sm:grid-cols-4" method="get">
          <label className="text-sm font-semibold">
            Statut
            <select name="statut" defaultValue={filtres.statut} className="champ mt-1 min-h-10 py-1.5">
              <option value="">Tous</option>
              {STATUTS.map((s) => (
                <option key={s} value={s}>
                  {statutFr(s)}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm font-semibold">
            Pays
            <select name="pays" defaultValue={filtres.pays} className="champ mt-1 min-h-10 py-1.5">
              <option value="">Tous</option>
              {Object.entries(PAYS_FR).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm font-semibold">
            Service
            <select name="service" defaultValue={filtres.service} className="champ mt-1 min-h-10 py-1.5">
              <option value="">Tous</option>
              {SERVICES.map((s) => (
                <option key={s.slug} value={s.slug}>
                  {s.titre.fr}
                </option>
              ))}
            </select>
          </label>
          <div className="flex items-end gap-2">
            <button type="submit" className="bouton bouton-principal min-h-10 flex-1 py-2 text-sm">
              Filtrer
            </button>
            <Link href="/admin" className="bouton bouton-secondaire min-h-10 py-2 text-sm">
              Effacer
            </Link>
          </div>
        </form>

        {erreur && <p className="mt-6 rounded-lg bg-erreur-pale p-4 font-semibold text-erreur">{erreur}</p>}

        {!erreur && (
          <div className="carte mt-6 overflow-x-auto">
            <table className="w-full min-w-[720px] text-start text-sm">
              <thead className="border-b border-ligne bg-surface-2 text-gris">
                <tr>
                  {["Date", "Nom", "Entreprise", "Pays", "Service", "Statut"].map((h) => (
                    <th key={h} className="px-4 py-3 text-start font-semibold">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-ligne">
                {demandes.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-gris">
                      Aucune demande pour ces critères.
                    </td>
                  </tr>
                )}
                {demandes.map((d) => (
                  <tr key={d.id} className="hover:bg-surface-2">
                    <td className="px-4 py-3 whitespace-nowrap">{dateFr(d.cree_le)}</td>
                    <td className="px-4 py-3">
                      <Link href={`/admin/demandes/${d.id}`} className="lien">
                        {d.nom}
                      </Link>
                    </td>
                    <td className="px-4 py-3">{d.entreprise}</td>
                    <td className="px-4 py-3">{PAYS_FR[d.pays] ?? d.pays}</td>
                    <td className="px-4 py-3">{serviceFr(d.service)}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded px-2 py-0.5 text-xs font-semibold ${COULEUR_STATUT[d.statut as Statut]}`}>
                        {statutFr(d.statut)}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </>
  );
}
