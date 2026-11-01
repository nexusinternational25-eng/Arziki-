import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { routing, type Langue } from "@/i18n/routing";
import { BandeauPage, Fleche, ListeCoches } from "@/components/Blocs";
import { SERVICES, trouverService } from "@/lib/contenu";
import { metadonnees } from "@/lib/seo";

export const dynamicParams = false;

export function generateStaticParams() {
  return routing.locales.flatMap((locale) => SERVICES.map((s) => ({ locale, slug: s.slug })));
}

export async function generateMetadata({ params }: PageProps<"/[locale]/services/[slug]">): Promise<Metadata> {
  const { locale, slug } = await params;
  const s = trouverService(slug);
  if (!s) return {};
  const langue = locale as Langue;
  return metadonnees(langue, `/services/${slug}`, s.titre[langue], s.resume[langue]);
}

export default async function PageService({ params }: PageProps<"/[locale]/services/[slug]">) {
  const { locale, slug } = await params;
  setRequestLocale(locale);
  const langue = locale as Langue;
  const s = trouverService(slug);
  if (!s) notFound();
  const t = await getTranslations("services");
  const autres = SERVICES.filter((x) => x.slug !== slug);

  return (
    <>
      <BandeauPage surtitre={t("titre")} titre={s.titre[langue]} intro={s.resume[langue]} image={s.image}>
        <div className="mt-7 flex flex-wrap gap-3">
          <Link href={{ pathname: "/contact", query: { service: s.slug } }} className="bouton bouton-principal">
            {t("demander")}
            <Fleche />
          </Link>
          <Link href="/services" className="bouton bouton-secondaire">
            {t("retour")}
          </Link>
        </div>
      </BandeauPage>

      <section className="conteneur grid gap-8 py-14 lg:grid-cols-[1.3fr_1fr]">
        <div className="carte p-6 sm:p-8">
          <h2 className="text-xl font-semibold">{t("inclus")}</h2>
          <div className="mt-5">
            <ListeCoches elements={s.inclus[langue]} />
          </div>
        </div>
        <div className="flex flex-col gap-6">
          <div className="carte p-6 sm:p-8">
            <h2 className="text-xl font-semibold">{t("livrables")}</h2>
            <ul className="mt-5 space-y-3">
              {s.livrables[langue].map((l) => (
                <li key={l} className="flex gap-3">
                  <span className="mt-2.5 h-0.5 w-4 shrink-0 bg-ocre" aria-hidden="true" />
                  <span>{l}</span>
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-xl bg-nuit p-6 text-sur-nuit sm:p-8">
            <p>{t("tarif")}</p>
            <Link href={{ pathname: "/contact", query: { service: s.slug } }} className="bouton bouton-principal mt-5 w-full">
              {t("demander")}
            </Link>
          </div>
        </div>
      </section>

      <section className="border-t border-ligne bg-surface">
        <div className="conteneur py-12">
          <h2 className="text-xl font-semibold">{t("autres")}</h2>
          <ul className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {autres.map((x) => (
              <li key={x.slug}>
                <Link
                  href={`/services/${x.slug}`}
                  className="flex h-full items-center justify-between gap-3 rounded-lg border border-ligne bg-sable p-4 font-semibold text-encre no-underline hover:border-ocre"
                >
                  {x.titre[langue]}
                  <Fleche className="size-4 shrink-0 text-ocre-fort" />
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </section>
    </>
  );
}
