import type { Metadata, Viewport } from "next";
import { Reem_Kufi, IBM_Plex_Sans_Arabic } from "next/font/google";
import { notFound } from "next/navigation";
import { NextIntlClientProvider, hasLocale } from "next-intl";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { routing, type Langue } from "@/i18n/routing";
import { EnTete } from "@/components/EnTete";
import { PiedDePage } from "@/components/PiedDePage";
import { BoutonWhatsApp } from "@/components/BoutonWhatsApp";
import { SCRIPT_THEME } from "@/components/ChoixTheme";
import { metadonnees, URL_SITE } from "@/lib/seo";
import { CONTACT } from "@/lib/contenu";
import "../globals.css";

const titres = Reem_Kufi({
  subsets: ["arabic", "latin"],
  weight: ["500", "600", "700"],
  variable: "--font-reem-kufi",
  display: "swap",
});

const texte = IBM_Plex_Sans_Arabic({
  subsets: ["arabic", "latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-plex-arabic",
  display: "swap",
});

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#1b2d52" },
    { media: "(prefers-color-scheme: dark)", color: "#0c1530" },
  ],
};

export async function generateMetadata({ params }: LayoutProps<"/[locale]">): Promise<Metadata> {
  const { locale } = await params;
  if (!hasLocale(routing.locales, locale)) return {};
  const t = await getTranslations({ locale, namespace: "meta" });
  return metadonnees(locale, "", null, t("description"));
}

export default async function LayoutLangue({ children, params }: LayoutProps<"/[locale]">) {
  const { locale } = await params;
  if (!hasLocale(routing.locales, locale)) notFound();
  setRequestLocale(locale);
  const langue = locale as Langue;
  const t = await getTranslations({ locale, namespace: "meta" });

  // Données structurées : l'organisation et le service professionnel.
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "@id": `${URL_SITE}/#nexus`,
        name: "NEXUS International",
        url: URL_SITE,
        email: CONTACT.email,
        telephone: CONTACT.whatsappAffiche.replace(/ /g, ""),
        address: { "@type": "PostalAddress", addressLocality: "Lomé", addressCountry: "TG" },
      },
      {
        "@type": "ProfessionalService",
        "@id": `${URL_SITE}/#desk`,
        name: t("nomSite"),
        description: t("description"),
        url: `${URL_SITE}/${langue}`,
        inLanguage: langue,
        provider: { "@id": `${URL_SITE}/#nexus` },
        areaServed: [
          { "@type": "Country", name: langue === "fr" ? "Algérie" : "الجزائر" },
          { "@type": "Country", name: langue === "fr" ? "Niger" : "النيجر" },
        ],
        availableLanguage: ["ar", "fr"],
        email: CONTACT.email,
      },
    ],
  };

  return (
    <html
      lang={langue}
      dir={langue === "ar" ? "rtl" : "ltr"}
      className={`${titres.variable} ${texte.variable}`}
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: SCRIPT_THEME }} />
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      </head>
      <body className="flex min-h-dvh flex-col antialiased">
        <NextIntlClientProvider>
          <EnTete />
          <main id="contenu" className="flex-1">
            {children}
          </main>
          <PiedDePage />
          <BoutonWhatsApp />
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
