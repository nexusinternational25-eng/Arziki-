// Métadonnées communes : adresse canonique, hreflang ar/fr, Open Graph par langue.

import type { Metadata } from "next";
import type { Langue } from "@/i18n/routing";

export const URL_SITE = (process.env.NEXT_PUBLIC_SITE_URL || "https://desk-algerie-niger.vercel.app").replace(/\/$/, "");

export const NOM_SITE = { fr: "Desk Algérie-Niger", ar: "مكتب الجزائر - النيجر" };

/** Construit les métadonnées d'une page. `chemin` commence par « / » (ou vaut « »). */
export function metadonnees(langue: Langue, chemin: string, titre: string | null, description: string): Metadata {
  const nom = NOM_SITE[langue];
  const titreComplet = titre ? `${titre} | ${nom}` : `${nom} | ${langue === "fr" ? "La passerelle d'affaires entre l'Algérie et le Niger" : "جسر الأعمال بين الجزائر والنيجر"}`;
  const url = `${URL_SITE}/${langue}${chemin}`;
  return {
    metadataBase: new URL(URL_SITE),
    title: titreComplet,
    description,
    alternates: {
      canonical: url,
      languages: {
        ar: `${URL_SITE}/ar${chemin}`,
        fr: `${URL_SITE}/fr${chemin}`,
        "x-default": `${URL_SITE}/ar${chemin}`,
      },
    },
    openGraph: {
      type: "website",
      siteName: nom,
      title: titreComplet,
      description,
      url,
      locale: langue === "ar" ? "ar_DZ" : "fr_FR",
      alternateLocale: langue === "ar" ? ["fr_FR"] : ["ar_DZ"],
      images: [{ url: `/og/partage-${langue}.png`, width: 1200, height: 630, alt: nom }],
    },
    twitter: {
      card: "summary_large_image",
      title: titreComplet,
      description,
      images: [`/og/partage-${langue}.png`],
    },
  };
}
