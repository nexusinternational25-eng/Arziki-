import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Langue } from "@/i18n/routing";
import { BandeauPage, CarteLien } from "@/components/Blocs";
import { articlesVisibles } from "@/lib/articles";
import { metadonnees } from "@/lib/seo";

export async function generateMetadata({ params }: PageProps<"/[locale]/ressources">): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "ressources" });
  return metadonnees(locale as Langue, "/ressources", t("titre"), t("intro"));
}

export default async function PageRessources({ params }: PageProps<"/[locale]/ressources">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("ressources");
  const articles = articlesVisibles(locale as Langue);

  return (
    <>
      <BandeauPage titre={t("titre")} intro={t("intro")} image="port-oran.jpg" />
      <section className="conteneur py-14">
        {articles.length === 0 ? (
          <div className="carte max-w-2xl p-8">
            <p className="text-lg">{t("vide")}</p>
            <Link href="/contact" className="lien mt-4 inline-block">
              {t("videAction")}
            </Link>
          </div>
        ) : (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {articles.map((a) => (
              <CarteLien
                key={a.slug}
                href={`/ressources/${a.slug}`}
                titre={a.brouillon ? `${a.titre} (${t("brouillon")})` : a.titre}
                texte={a.resume}
                action={t("lire")}
              />
            ))}
          </div>
        )}
      </section>
    </>
  );
}
