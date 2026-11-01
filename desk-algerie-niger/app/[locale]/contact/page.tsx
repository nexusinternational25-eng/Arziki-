import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";
import type { Langue } from "@/i18n/routing";
import { BandeauPage } from "@/components/Blocs";
import { FormulaireDemande } from "@/components/FormulaireDemande";
import { IconeWhatsApp } from "@/components/IconeWhatsApp";
import { lienWhatsApp } from "@/components/BoutonWhatsApp";
import { CONTACT, SECTEURS, SERVICES } from "@/lib/contenu";
import { metadonnees } from "@/lib/seo";

export async function generateMetadata({ params }: PageProps<"/[locale]/contact">): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "contact" });
  return metadonnees(locale as Langue, "/contact", t("titre"), t("intro"));
}

const un = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

export default async function PageContact({ params, searchParams }: PageProps<"/[locale]/contact">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const langue = locale as Langue;
  const q = await searchParams;
  const t = await getTranslations("contact");
  const tw = await getTranslations("whatsapp");

  // Préremplissage depuis les boutons du site (profil, service ou secteur).
  const profilQ = un(q.profil);
  const profil = profilQ === "algerie" || profilQ === "niger" || profilQ === "autre" ? profilQ : undefined;
  const serviceQ = un(q.service);
  const service = SERVICES.some((s) => s.slug === serviceQ) ? serviceQ : undefined;
  const secteurQ = un(q.secteur);
  const secteur = SECTEURS.some((s) => s.code === secteurQ) ? secteurQ : undefined;

  return (
    <>
      <BandeauPage titre={t("titre")} intro={t("intro")} />
      <section className="conteneur grid gap-8 py-12 lg:grid-cols-[1.6fr_1fr]">
        <FormulaireDemande
          key={`${profil}-${service}-${secteur}`}
          profil={profil}
          service={service}
          secteur={secteur}
          source={`/${langue}/contact`}
        />
        <aside className="flex flex-col gap-5">
          <div className="rounded-xl bg-nuit p-6 text-sur-nuit">
            <h2 className="text-lg font-semibold">{t("direct")}</h2>
            <dl className="mt-4 space-y-4">
              <div>
                <dt className="text-sm text-sur-nuit-2">{t("email")}</dt>
                <dd>
                  <a href={`mailto:${CONTACT.email}`} dir="ltr" className="font-semibold text-sur-nuit">
                    {CONTACT.email}
                  </a>
                </dd>
              </div>
              <div>
                <dt className="text-sm text-sur-nuit-2">{t("whatsapp")}</dt>
                <dd>
                  <a href={lienWhatsApp(tw("message"))} target="_blank" rel="noopener" dir="ltr" className="inline-flex items-center gap-2 font-semibold text-sur-nuit">
                    <IconeWhatsApp className="size-5" />
                    {CONTACT.whatsappAffiche}
                  </a>
                </dd>
              </div>
            </dl>
          </div>
        </aside>
      </section>
    </>
  );
}
