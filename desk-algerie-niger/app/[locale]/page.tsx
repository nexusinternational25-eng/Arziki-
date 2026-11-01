import Image from "next/image";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Langue } from "@/i18n/routing";
import { CarteRoute } from "@/components/CarteRoute";
import { CarteLien, Fleche, TitreSection } from "@/components/Blocs";
import { lienWhatsApp } from "@/components/BoutonWhatsApp";
import { IconeWhatsApp } from "@/components/IconeWhatsApp";
import { CONTEXTE, ETAPES, PUBLICS, SECTEURS, SERVICES } from "@/lib/contenu";

export default async function Accueil({ params }: PageProps<"/[locale]">) {
  const { locale } = await params;
  setRequestLocale(locale);
  const langue = locale as Langue;
  const t = await getTranslations("accueil");
  const tw = await getTranslations("whatsapp");

  const chiffres = [
    { valeur: t("chiffreFrontiere"), texte: t("chiffreFrontiereTexte") },
    { valeur: t("chiffreLangues"), texte: t("chiffreLanguesTexte") },
    { valeur: t("chiffrePays"), texte: t("chiffrePaysTexte") },
  ];

  return (
    <>
      {/* En-tête de page */}
      <section className="relative overflow-hidden bg-nuit text-sur-nuit">
        <div className="conteneur grid items-center gap-10 py-12 sm:py-16 lg:grid-cols-[1.15fr_1fr] lg:py-20">
          <div>
            <p className="inline-flex items-center gap-2 text-sm font-semibold text-ocre-clair">
              <span className="h-0.5 w-6 bg-current" aria-hidden="true" />
              {t("surtitre")}
            </p>
            <h1 className="mt-3 text-[2rem] leading-tight font-semibold sm:text-5xl">{t("titre")}</h1>
            <p className="mt-5 max-w-xl text-lg text-sur-nuit-2">{t("accroche")}</p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link href={{ pathname: "/contact", query: { profil: "algerie" } }} className="bouton bouton-principal">
                {t("boutonAlgerie")}
                <Fleche />
              </Link>
              <Link href={{ pathname: "/contact", query: { profil: "niger" } }} className="bouton bouton-clair">
                {t("boutonNiger")}
                <Fleche />
              </Link>
            </div>
          </div>
          <div className="relative">
            <div className="relative aspect-[4/5] overflow-hidden rounded-2xl sm:aspect-[16/11] lg:aspect-[4/5]">
              <Image
                src="/images/hero-route-sahara.jpg"
                alt=""
                fill
                priority
                sizes="(min-width: 1024px) 45vw, 100vw"
                className="object-cover"
              />
              <div className="absolute inset-0 bg-linear-to-t from-nuit/70 via-transparent to-transparent" />
            </div>
            <div className="absolute start-4 bottom-4 end-4 rounded-xl bg-surface/95 p-4 text-encre shadow-lg backdrop-blur sm:start-6 sm:end-auto sm:max-w-xs">
              <p className="font-titre text-sm font-semibold text-ocre-fort">{t("routeTitre")}</p>
              <p className="mt-1 text-sm">
                {langue === "fr" ? "Alger, Tamanrasset, In-Guezzam, Agadez, Niamey" : "الجزائر العاصمة، تمنراست، عين قزام، أغاديس، نيامي"}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Chiffres */}
      <section aria-label={t("surtitre")} className="border-b border-ligne bg-surface">
        <div className="conteneur grid divide-y divide-ligne sm:grid-cols-3 sm:divide-x sm:divide-y-0">
          {chiffres.map((c) => (
            <div key={c.texte} className="py-6 sm:px-6 sm:first:ps-0">
              <p className="font-titre text-3xl font-semibold text-vert">{c.valeur}</p>
              <p className="mt-1 text-gris">{c.texte}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Carte de la route */}
      <section className="conteneur grid items-center gap-10 py-16 lg:grid-cols-[1fr_1.1fr] lg:py-20">
        <div>
          <TitreSection surtitre={t("routeLegendeRoute")} titre={t("routeTitre")} intro={t("routeTexte")} />
          <div className="mt-8 grid grid-cols-2 gap-3">
            <div className="relative aspect-[4/5] overflow-hidden rounded-xl">
              <Image src="/images/hoggar-tamanrasset.jpg" alt="" fill sizes="(min-width: 1024px) 20vw, 50vw" className="object-cover" />
            </div>
            <div className="relative aspect-[4/5] overflow-hidden rounded-xl">
              <Image src="/images/agadez-ville.jpg" alt="" fill sizes="(min-width: 1024px) 20vw, 50vw" className="object-cover" />
            </div>
          </div>
        </div>
        <div className="mx-auto w-full max-w-md">
          <CarteRoute
            langue={langue}
            libelles={{
              algerie: t("routeAlgerie"),
              niger: t("routeNiger"),
              route: t("routeLegendeRoute"),
              frontiere: t("routeLegendeFrontiere"),
              aria: t("carteAria"),
            }}
          />
        </div>
      </section>

      {/* Pourquoi maintenant */}
      <section className="border-y border-ligne bg-surface">
        <div className="conteneur grid gap-10 py-16 lg:grid-cols-[1.1fr_1fr] lg:py-20">
          <div>
            <TitreSection surtitre={t("maintenantSurtitre")} titre={t("maintenantTitre")} />
            <p className="mt-5 text-lg">{CONTEXTE.introduction[langue]}</p>
            <ol className="mt-8 space-y-5 border-s-2 border-ocre/40 ps-6">
              {CONTEXTE.dates.map((d) => (
                <li key={d.date.fr} className="relative">
                  <span className="absolute -start-[1.95rem] top-1.5 size-3.5 rounded-full border-2 border-surface bg-ocre" aria-hidden="true" />
                  <p className="font-titre font-semibold text-ocre-fort">{d.date[langue]}</p>
                  <p className="mt-0.5">{d.texte[langue]}</p>
                </li>
              ))}
            </ol>
          </div>
          <div>
            <h3 className="font-titre text-lg font-semibold">{t("maintenantProjets")}</h3>
            <ul className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-1 xl:grid-cols-2">
              {CONTEXTE.projets.map((p) => (
                <li key={p.fr} className="flex items-start gap-3 rounded-lg border border-ligne bg-sable p-4">
                  <span className="mt-2 size-2 shrink-0 rounded-full bg-vert" aria-hidden="true" />
                  <span>{p[langue]}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* Services */}
      <section className="conteneur py-16 lg:py-20">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <TitreSection surtitre={t("servicesSurtitre")} titre={t("servicesTitre")} />
          <Link href="/services" className="lien shrink-0">
            {t("servicesTous")}
          </Link>
        </div>
        <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {SERVICES.map((s, i) => (
            <CarteLien
              key={s.slug}
              href={`/services/${s.slug}`}
              numero={i + 1}
              titre={s.titre[langue]}
              texte={s.resume[langue]}
              action={t("enSavoirPlus")}
            />
          ))}
        </div>
      </section>

      {/* Les deux publics */}
      <section className="bg-surface-2 py-16 lg:py-20">
        <div className="conteneur">
          <TitreSection surtitre={t("publicsSurtitre")} titre={t("publicsTitre")} />
          <div className="mt-8 grid gap-6 lg:grid-cols-2">
            {PUBLICS.map((p) => (
              <Link
                key={p.slug}
                href={`/${p.slug}`}
                className="carte group grid overflow-hidden text-encre no-underline sm:grid-cols-[0.9fr_1.1fr]"
              >
                <div className="relative aspect-[16/10] sm:aspect-auto">
                  <Image src={`/images/${p.image}`} alt="" fill sizes="(min-width: 1024px) 22vw, (min-width: 640px) 45vw, 100vw" className="object-cover" />
                </div>
                <div className="flex flex-col p-6">
                  <h3 className="text-xl font-semibold">{p.titre[langue]}</h3>
                  <p className="mt-2 flex-1 text-gris">{p.accroche[langue]}</p>
                  <span className="mt-4 inline-flex items-center gap-1.5 font-semibold text-ocre-fort">
                    {t("enSavoirPlus")}
                    <Fleche />
                  </span>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Secteurs */}
      <section className="conteneur py-16 lg:py-20">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <TitreSection surtitre={t("secteursSurtitre")} titre={t("secteursTitre")} />
          <Link href="/secteurs" className="lien shrink-0">
            {t("enSavoirPlus")}
          </Link>
        </div>
        <ul className="mt-8 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-6">
          {SECTEURS.map((s) => (
            <li key={s.code}>
              <Link href={`/secteurs#${s.code}`} className="group block text-encre no-underline">
                <div className="relative aspect-square overflow-hidden rounded-xl">
                  <Image src={`/images/${s.image}`} alt="" fill sizes="(min-width: 1024px) 15vw, (min-width: 768px) 30vw, 45vw" className="object-cover transition-transform duration-500 group-hover:scale-105" />
                </div>
                <p className="mt-2 font-semibold">{s.titre[langue]}</p>
              </Link>
            </li>
          ))}
        </ul>
      </section>

      {/* Méthode en quatre étapes */}
      <section className="border-t border-ligne bg-surface py-16 lg:py-20">
        <div className="conteneur">
          <TitreSection surtitre={t("etapesSurtitre")} titre={t("etapesTitre")} />
          <ol className="mt-10 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
            {ETAPES.map((e, i) => (
              <li key={e.titre.fr}>
                <span className="inline-flex size-11 items-center justify-center rounded-full bg-nuit font-titre text-lg font-semibold text-sur-nuit">
                  {i + 1}
                </span>
                <h3 className="mt-4 text-lg font-semibold">{e.titre[langue]}</h3>
                <p className="mt-1.5 text-gris">{e.texte[langue]}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* Appel à l'action final */}
      <section className="bg-nuit text-sur-nuit">
        <div className="conteneur flex flex-col gap-6 py-14 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-2xl">
            <h2 className="text-2xl font-semibold sm:text-3xl">{t("ctaTitre")}</h2>
            <p className="mt-3 text-lg text-sur-nuit-2">{t("ctaTexte")}</p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <Link href="/contact" className="bouton bouton-principal">
              {t("ctaBouton")}
              <Fleche />
            </Link>
            <a href={lienWhatsApp(tw("message"))} target="_blank" rel="noopener" className="bouton bouton-clair">
              <IconeWhatsApp className="size-5" />
              {t("ctaWhatsapp")}
            </a>
          </div>
        </div>
      </section>
    </>
  );
}
