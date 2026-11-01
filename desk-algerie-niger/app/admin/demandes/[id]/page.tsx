import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { base, baseConfiguree, type LigneDemande } from "@/lib/base";
import { estConnecte } from "@/lib/session";
import { STATUTS } from "@/lib/formulaire";
import { budgetFr, dateFr, PAYS_FR, PROFILS_FR, secteurFr, serviceFr, statutFr } from "@/lib/admin";
import { changerStatut, enregistrerNotes } from "../../actions";
import { EnTeteAdmin } from "../../EnTeteAdmin";

export const dynamic = "force-dynamic";

export default async function DetailDemande({ params }: PageProps<"/admin/demandes/[id]">) {
  if (!(await estConnecte())) redirect("/admin");
  if (!baseConfiguree()) redirect("/admin");
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/i.test(id)) notFound();
  const { data } = await base().from("demandes").select("*").eq("id", id).maybeSingle();
  if (!data) notFound();
  const d = data as LigneDemande;

  const lignes: [string, React.ReactNode][] = [
    ["Reçue le", dateFr(d.cree_le)],
    ["Nom", d.nom],
    ["Entreprise", d.entreprise],
    ["Fonction", d.fonction],
    ["Pays", PAYS_FR[d.pays] ?? d.pays],
    ["Profil", PROFILS_FR[d.profil] ?? d.profil],
    ["Service", serviceFr(d.service)],
    ["Secteur", secteurFr(d.secteur)],
    ["Budget indicatif", budgetFr(d.budget)],
    ["E-mail", d.email ? <a className="lien" href={`mailto:${d.email}`}>{d.email}</a> : null],
    [
      "Téléphone / WhatsApp",
      d.telephone ? (
        <a className="lien" href={`https://wa.me/${d.telephone.replace(/[^0-9]/g, "")}`} target="_blank" rel="noopener">
          {d.telephone}
        </a>
      ) : null,
    ],
    ["Langue préférée", d.langue_preferee === "ar" ? "Arabe" : "Français"],
    ["Langue du site", d.langue === "ar" ? "Arabe" : "Français"],
    ["Page d'origine", d.source],
    ["Consentement", d.consentement ? "Oui" : "Non"],
  ];

  return (
    <>
      <EnTeteAdmin />
      <main className="conteneur py-8">
        <Link href="/admin" className="lien">
          Toutes les demandes
        </Link>
        <h1 className="mt-4 text-2xl font-semibold">{d.nom}</h1>
        <div className="mt-6 grid gap-6 lg:grid-cols-[1.4fr_1fr]">
          <div className="carte p-6">
            <dl className="divide-y divide-ligne">
              {lignes.map(([k, v]) => (
                <div key={k} className="grid gap-1 py-2.5 sm:grid-cols-[12rem_1fr]">
                  <dt className="text-sm text-gris">{k}</dt>
                  <dd>{v || <span className="text-gris">Non renseigné</span>}</dd>
                </div>
              ))}
            </dl>
            <h2 className="mt-6 font-semibold">Message</h2>
            <p className="mt-2 whitespace-pre-wrap rounded-lg bg-surface-2 p-4">{d.message || "Aucun message"}</p>
          </div>
          <div className="flex flex-col gap-6">
            <form action={changerStatut} className="carte p-6">
              <input type="hidden" name="id" value={d.id} />
              <label htmlFor="statut" className="font-semibold">
                Statut (actuel : {statutFr(d.statut)})
              </label>
              <select id="statut" name="statut" defaultValue={d.statut} className="champ mt-2">
                {STATUTS.map((s) => (
                  <option key={s} value={s}>
                    {statutFr(s)}
                  </option>
                ))}
              </select>
              <button type="submit" className="bouton bouton-principal mt-4 w-full">
                Changer le statut
              </button>
            </form>
            <form action={enregistrerNotes} className="carte p-6">
              <input type="hidden" name="id" value={d.id} />
              <label htmlFor="notes" className="font-semibold">
                Notes internes
              </label>
              <textarea id="notes" name="notes" rows={8} defaultValue={d.notes ?? ""} className="champ mt-2" />
              <button type="submit" className="bouton bouton-secondaire mt-4 w-full">
                Enregistrer les notes
              </button>
              {d.maj_le && <p className="mt-2 text-sm text-gris">Dernière modification : {dateFr(d.maj_le)}</p>}
            </form>
          </div>
        </div>
      </main>
    </>
  );
}
