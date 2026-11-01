import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";
import type { Langue } from "@/i18n/routing";
import { BandeauPage, CarteLien } from "@/components/Blocs";
import { SERVICES } from "@/lib/contenu";
import { metadonnees } from "@/lib/seo";

export async function generateMetadata({ params }: PageProps<"/[locale]/services">): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "services" });
  return metadonnees(locale as Langue, "/services", t("titre"), t("intro"));
}

export default async function PageServices({ params }: PageProps<"/[locale]/services">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const langue = locale as Langue;
  const t = await getTranslations("services");
  const a = await getTranslations("accueil");

  return (
    <>
      <BandeauPage titre={t("titre")} intro={t("intro")} image="logistique-port.jpg" />
      <section className="conteneur py-14">
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {SERVICES.map((s, i) => (
            <CarteLien
              key={s.slug}
              href={`/services/${s.slug}`}
              image={s.image}
              numero={i + 1}
              titre={s.titre[langue]}
              texte={s.resume[langue]}
              action={a("enSavoirPlus")}
            />
          ))}
        </div>
      </section>
    </>
  );
}
