// Lecture des articles MDX : content/articles/<langue>/<slug>.mdx
// En-tête de chaque fichier :
//   ---
//   titre: "..."
//   resume: "..."
//   date: "2026-11-01"
//   brouillon: true      (true = non publié)
//   ---

import "server-only";
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import type { Langue } from "@/i18n/routing";

export type Article = {
  slug: string;
  titre: string;
  resume: string;
  date: string;
  brouillon: boolean;
  contenu: string;
};

const DOSSIER = path.join(process.cwd(), "content", "articles");

// Pour relire les brouillons en local : AFFICHER_BROUILLONS=1 npm run dev
const voirBrouillons = process.env.AFFICHER_BROUILLONS === "1";

export function tousLesArticles(langue: Langue): Article[] {
  const dossier = path.join(DOSSIER, langue);
  if (!fs.existsSync(dossier)) return [];
  return fs
    .readdirSync(dossier)
    .filter((f) => f.endsWith(".mdx"))
    .map((f) => {
      const { data, content } = matter(fs.readFileSync(path.join(dossier, f), "utf8"));
      return {
        slug: f.replace(/\.mdx$/, ""),
        titre: String(data.titre ?? ""),
        resume: String(data.resume ?? ""),
        date: String(data.date ?? ""),
        brouillon: data.brouillon !== false,
        contenu: content,
      };
    })
    .sort((a, b) => b.date.localeCompare(a.date));
}

export function articlesVisibles(langue: Langue): Article[] {
  return tousLesArticles(langue).filter((a) => voirBrouillons || !a.brouillon);
}

export function trouverArticle(langue: Langue, slug: string): Article | undefined {
  return articlesVisibles(langue).find((a) => a.slug === slug);
}
