import type { Metadata } from "next";
import { setRequestLocale } from "next-intl/server";
import type { Langue } from "@/i18n/routing";
import { PagePublic } from "@/components/PagePublic";
import { PUBLICS } from "@/lib/contenu";
import { metadonnees } from "@/lib/seo";

const p = PUBLICS.find((x) => x.slug === "entreprises-algeriennes")!;

export async function generateMetadata({ params }: PageProps<"/[locale]/entreprises-algeriennes">): Promise<Metadata> {
  const { locale } = await params;
  const langue = locale as Langue;
  return metadonnees(langue, "/entreprises-algeriennes", p.titre[langue], p.accroche[langue]);
}

export default async function Page({ params }: PageProps<"/[locale]/entreprises-algeriennes">) {
  const { locale } = await params;
  setRequestLocale(locale);
  return <PagePublic p={p} langue={locale as Langue} />;
}
