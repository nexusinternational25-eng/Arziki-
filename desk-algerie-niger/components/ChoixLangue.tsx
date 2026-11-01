"use client";

// Bascule arabe / français qui conserve la page courante.
import { useLocale, useTranslations } from "next-intl";
import { useParams } from "next/navigation";
import { usePathname, useRouter } from "@/i18n/navigation";
import { useTransition } from "react";

export function ChoixLangue({ className = "" }: { className?: string }) {
  const t = useTranslations("nav");
  const langue = useLocale();
  const autre = langue === "ar" ? "fr" : "ar";
  const chemin = usePathname();
  const params = useParams();
  const router = useRouter();
  const [enCours, demarrer] = useTransition();

  return (
    <button
      type="button"
      lang={autre}
      aria-label={t("langueAria")}
      disabled={enCours}
      onClick={() =>
        demarrer(() => {
          // @ts-expect-error -- les paramètres de la route courante sont valides pour l'autre langue.
          router.replace({ pathname: chemin, params }, { locale: autre, scroll: false });
        })
      }
      className={`inline-flex min-h-11 items-center rounded-md border border-white/30 px-3 text-sm font-semibold text-sur-nuit hover:border-ocre-clair ${className}`}
    >
      {t("langue")}
    </button>
  );
}
