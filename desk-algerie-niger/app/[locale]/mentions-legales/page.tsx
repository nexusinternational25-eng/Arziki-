import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";
import type { Langue } from "@/i18n/routing";
import { PageLegale } from "@/components/PageLegale";
import { MENTIONS } from "@/lib/legal";
import { metadonnees } from "@/lib/seo";

export async function generateMetadata({ params }: PageProps<"/[locale]/mentions-legales">): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "pied" });
  return metadonnees(locale as Langue, "/mentions-legales", t("mentions"), t("avertissement"));
}

export default async function Page({ params }: PageProps<"/[locale]/mentions-legales">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("pied");
  return <PageLegale titre={t("mentions")} blocs={MENTIONS} langue={locale as Langue} />;
}
