import type { Metadata } from "next";
import Image from "next/image";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Langue } from "@/i18n/routing";
import { BandeauPage, Fleche } from "@/components/Blocs";
import { SECTEURS } from "@/lib/contenu";
import { metadonnees } from "@/lib/seo";

export async function generateMetadata({ params }: PageProps<"/[locale]/secteurs">): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "secteurs" });
  return metadonnees(locale as Langue, "/secteurs", t("titre"), t("intro"));
}

export default async function PageSecteurs({ params }: PageProps<"/[locale]/secteurs">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const langue = locale as Langue;
  const t = await getTranslations("secteurs");

  return (
    <>
      <BandeauPage titre={t("titre")} intro={t("intro")} />
      <section className="conteneur py-14">
        <div className="grid gap-6 md:grid-cols-2">
          {SECTEURS.map((s) => (
            <article key={s.code} id={s.code} className="carte grid scroll-mt-24 overflow-hidden sm:grid-cols-[0.8fr_1.2fr]">
              <div className="relative aspect-[16/10] sm:aspect-auto sm:min-h-56">
                <Image src={`/images/${s.image}`} alt="" fill sizes="(min-width: 768px) 20vw, 100vw" className="object-cover" />
              </div>
              <div className="flex flex-col p-6">
                <h2 className="text-xl font-semibold">{s.titre[langue]}</h2>
                <p className="mt-2 flex-1 text-gris">{s.texte[langue]}</p>
                <Link
                  href={{ pathname: "/contact", query: { secteur: s.code } }}
                  className="mt-4 inline-flex items-center gap-1.5 font-semibold text-ocre-fort no-underline hover:underline"
                >
                  {t("demander")}
                  <Fleche />
                </Link>
              </div>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
