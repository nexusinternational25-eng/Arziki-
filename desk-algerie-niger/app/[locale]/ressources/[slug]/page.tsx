import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { MDXRemote } from "next-mdx-remote/rsc";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { routing, type Langue } from "@/i18n/routing";
import { articlesVisibles, trouverArticle } from "@/lib/articles";
import { metadonnees } from "@/lib/seo";

// Seuls les articles publiés existent ; toute autre adresse renvoie la page 404.
export const dynamicParams = false;

export function generateStaticParams() {
  const liste = routing.locales.flatMap((locale) => articlesVisibles(locale).map((a) => ({ locale, slug: a.slug })));
  // Next.js exige au moins une entrée : celle-ci mène à la page 404.
  return liste.length ? liste : [{ locale: "ar", slug: "aucun-article" }];
}

export async function generateMetadata({ params }: PageProps<"/[locale]/ressources/[slug]">): Promise<Metadata> {
  const { locale, slug } = await params;
  const a = trouverArticle(locale as Langue, slug);
  if (!a) return {};
  return { ...metadonnees(locale as Langue, `/ressources/${slug}`, a.titre, a.resume), robots: a.brouillon ? { index: false } : undefined };
}

export default async function PageArticle({ params }: PageProps<"/[locale]/ressources/[slug]">) {
  const { locale, slug } = await params;
  setRequestLocale(locale);
  const langue = locale as Langue;
  const a = trouverArticle(langue, slug);
  if (!a) notFound();
  const t = await getTranslations("ressources");
  const date = new Intl.DateTimeFormat(langue === "ar" ? "ar-DZ" : "fr-FR", { dateStyle: "long" }).format(new Date(a.date));

  return (
    <article className="conteneur py-12">
      <Link href="/ressources" className="lien">
        {t("retour")}
      </Link>
      <header className="mt-6 max-w-3xl">
        {a.brouillon && (
          <span className="inline-block rounded bg-ocre/15 px-2 py-0.5 text-sm font-semibold text-ocre-fort">{t("brouillon")}</span>
        )}
        <h1 className="mt-2 text-3xl font-semibold sm:text-4xl">{a.titre}</h1>
        <p className="mt-3 text-lg text-gris">{a.resume}</p>
        <p className="mt-2 text-sm text-gris">
          {t("publieLe")} {date}
        </p>
      </header>
      <div className="prose-desk mt-8 max-w-3xl">
        <MDXRemote source={a.contenu} />
      </div>
    </article>
  );
}
