import type { MetadataRoute } from "next";
import { URL_SITE } from "@/lib/seo";
import { SERVICES } from "@/lib/contenu";
import { articlesVisibles } from "@/lib/articles";

const PAGES = [
  "",
  "/services",
  ...SERVICES.map((s) => `/services/${s.slug}`),
  "/entreprises-algeriennes",
  "/operateurs-nigeriens",
  "/secteurs",
  "/ressources",
  "/a-propos",
  "/contact",
  "/mentions-legales",
  "/confidentialite",
];

export default function sitemap(): MetadataRoute.Sitemap {
  const articles = articlesVisibles("fr")
    .filter((a) => !a.brouillon)
    .map((a) => `/ressources/${a.slug}`);
  return [...PAGES, ...articles].flatMap((chemin) =>
    (["ar", "fr"] as const).map((langue) => ({
      url: `${URL_SITE}/${langue}${chemin}`,
      lastModified: new Date("2026-11-01"),
      changeFrequency: "monthly" as const,
      priority: chemin === "" ? 1 : 0.7,
      alternates: { languages: { ar: `${URL_SITE}/ar${chemin}`, fr: `${URL_SITE}/fr${chemin}` } },
    })),
  );
}
