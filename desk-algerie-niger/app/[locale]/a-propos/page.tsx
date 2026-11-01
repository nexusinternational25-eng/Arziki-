import type { Metadata } from "next";
import Image from "next/image";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Langue } from "@/i18n/routing";
import { BandeauPage, Fleche } from "@/components/Blocs";
import { metadonnees } from "@/lib/seo";

export async function generateMetadata({ params }: PageProps<"/[locale]/a-propos">): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "aPropos" });
  return metadonnees(locale as Langue, "/a-propos", t("titre"), t("intro"));
}

export default async function PageAPropos({ params }: PageProps<"/[locale]/a-propos">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("aPropos");
  const n = await getTranslations("nav");

  return (
    <>
      <BandeauPage titre={t("titre")} intro={t("intro")} image="reunion-affaires.jpg" />

      <section className="conteneur grid gap-8 py-14 lg:grid-cols-2">
        <div className="carte p-6 sm:p-8">
          <h2 className="text-2xl font-semibold">{t("nexusTitre")}</h2>
          <p className="mt-4">{t("nexusTexte")}</p>
          <h3 className="mt-8 font-titre text-lg font-semibold">{t("referencesTitre")}</h3>
          <ul className="mt-4 space-y-3">
            {[t("reference1"), t("reference2")].map((r) => (
              <li key={r} className="flex gap-3 rounded-lg bg-surface-2 p-4">
                <span className="mt-2 size-2 shrink-0 rounded-full bg-ocre" aria-hidden="true" />
                <span>{r}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="carte overflow-hidden">
          <div className="relative aspect-[16/9]">
            <Image src="/images/formation-equipe.jpg" alt="" fill sizes="(min-width: 1024px) 45vw, 100vw" className="object-cover object-top" />
          </div>
          <div className="p-6 sm:p-8">
            <p className="surtitre">{t("fondateurTitre")}</p>
            <h2 className="mt-2 text-2xl font-semibold">{t("fondateurNom")}</h2>
            <p className="mt-4">{t("fondateurTexte1")}</p>
            <p className="mt-3">{t("fondateurTexte2")}</p>
          </div>
        </div>
      </section>

      <section className="border-t border-ligne bg-surface">
        <div className="conteneur flex flex-col gap-6 py-14 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-2xl">
            <h2 className="text-2xl font-semibold">{t("pourquoiTitre")}</h2>
            <p className="mt-3 text-lg text-gris">{t("pourquoiTexte")}</p>
          </div>
          <Link href="/contact" className="bouton bouton-principal shrink-0">
            {n("demande")}
            <Fleche />
          </Link>
        </div>
      </section>
    </>
  );
}
