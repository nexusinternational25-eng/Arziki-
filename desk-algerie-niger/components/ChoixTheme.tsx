"use client";

// Bouton clair / sombre. Le choix est mémorisé dans le navigateur.
import { useTranslations } from "next-intl";

export function ChoixTheme() {
  const t = useTranslations("nav");

  function basculer() {
    const racine = document.documentElement;
    const sombreActuel =
      racine.dataset.theme === "sombre" ||
      (!racine.dataset.theme && window.matchMedia("(prefers-color-scheme: dark)").matches);
    const nouveau = sombreActuel ? "clair" : "sombre";
    racine.dataset.theme = nouveau;
    try {
      localStorage.setItem("desk-theme", nouveau);
    } catch {
      // Stockage indisponible : le choix vaut pour la page en cours seulement.
    }
  }

  return (
    <button
      type="button"
      onClick={basculer}
      aria-label={t("theme")}
      title={t("theme")}
      className="inline-flex size-11 items-center justify-center rounded-md border border-white/30 text-sur-nuit hover:border-ocre-clair"
    >
      <svg viewBox="0 0 24 24" className="size-5" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8">
        <circle cx="12" cy="12" r="8" />
        <path d="M12 4 a8 8 0 0 1 0 16 z" fill="currentColor" stroke="none" />
      </svg>
    </button>
  );
}

/** Script exécuté avant l'affichage pour éviter un flash de mauvais thème. */
export const SCRIPT_THEME = `try{var t=localStorage.getItem("desk-theme");if(t==="clair"||t==="sombre")document.documentElement.dataset.theme=t}catch(e){}`;
