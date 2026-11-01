// Page commune aux deux publics (entreprises algériennes, opérateurs nigériens).

import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Langue } from "@/i18n/routing";
import { BandeauPage, Fleche, ListeCoches } from "./Blocs";
import { FormulaireDemande } from "./FormulaireDemande";
import { SERVICES, type Public } from "@/lib/contenu";

export async function PagePublic({ p, langue }: { p: Public; langue: Langue }) {
  const t = await getTranslations("publics");
  const n = await getTranslations("nav");

  return (
    <>
      <BandeauPage titre={p.titre[langue]} intro={p.accroche[langue]} image={p.image}>
        <a href="#formulaire" className="bouton bouton-principal mt-7">
          {n("demande")}
          <Fleche />
        </a>
      </BandeauPage>

      <section className="conteneur grid gap-8 py-14 lg:grid-cols-[1.2fr_1fr]">
        <div className="carte p-6 sm:p-8">
          <h2 className="text-xl font-semibold">{t("besoins")}</h2>
          <div className="mt-5">
            <ListeCoches elements={p.besoins[langue]} />
          </div>
        </div>
        <div className="carte p-6 sm:p-8">
          <h2 className="text-xl font-semibold">{t("servicesUtiles")}</h2>
          <ul className="mt-4 divide-y divide-ligne">
            {SERVICES.map((s) => (
              <li key={s.slug}>
                <Link href={`/services/${s.slug}`} className="flex items-center justify-between gap-3 py-3 font-semibold text-encre no-underline hover:text-ocre-fort">
                  {s.titre[langue]}
                  <Fleche className="size-4 shrink-0 text-ocre-fort" />
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="border-y border-ligne bg-surface">
        <div className="conteneur py-14">
          <h2 className="text-2xl font-semibold">{t("faq")}</h2>
          <div className="mt-6 grid gap-3 lg:grid-cols-2">
            {p.faq.map((f) => (
              <details key={f.q.fr} className="group rounded-lg border border-ligne bg-sable p-5 open:bg-surface-2">
                <summary className="flex cursor-pointer list-none items-start justify-between gap-4 font-semibold">
                  {f.q[langue]}
                  <span className="mt-0.5 text-xl leading-none text-ocre-fort transition-transform group-open:rotate-45" aria-hidden="true">
                    +
                  </span>
                </summary>
                <p className="mt-3 text-gris">{f.r[langue]}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      <section id="formulaire" className="conteneur scroll-mt-24 py-14">
        <h2 className="text-2xl font-semibold">{t("formulaire")}</h2>
        <div className="mt-6 max-w-3xl">
          <FormulaireDemande profil={p.profil} source={`/${langue}/${p.slug}`} />
        </div>
      </section>
    </>
  );
}
