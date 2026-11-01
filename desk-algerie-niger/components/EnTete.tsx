import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { Embleme } from "./Logo";
import { ChoixLangue } from "./ChoixLangue";
import { ChoixTheme } from "./ChoixTheme";
import { MenuMobile } from "./MenuMobile";

export const LIENS_NAV = [
  { href: "/services", cle: "services" },
  { href: "/entreprises-algeriennes", cle: "algerie" },
  { href: "/operateurs-nigeriens", cle: "niger" },
  { href: "/secteurs", cle: "secteurs" },
  { href: "/ressources", cle: "ressources" },
  { href: "/a-propos", cle: "aPropos" },
] as const;

export async function EnTete() {
  const t = await getTranslations("nav");
  const m = await getTranslations("meta");
  const liens = LIENS_NAV.map((l) => ({ href: l.href, libelle: t(l.cle) }));

  return (
    <header className="sticky top-0 z-40 bg-nuit text-sur-nuit shadow-[0_1px_0_rgb(255_255_255/0.06)]">
      <a
        href="#contenu"
        className="sr-only focus:not-sr-only focus:absolute focus:start-4 focus:top-3 focus:z-50 focus:rounded focus:bg-surface focus:px-4 focus:py-2 focus:text-encre"
      >
        {t("allerContenu")}
      </a>
      <div className="conteneur flex h-16 items-center gap-4 lg:h-[4.5rem]">
        <Link href="/" className="flex items-center gap-2.5 text-sur-nuit no-underline">
          <Embleme className="size-9 shrink-0" />
          <span className="font-titre text-lg leading-tight font-semibold whitespace-nowrap">{m("nomSite")}</span>
        </Link>

        <nav aria-label={t("menu")} className="ms-4 hidden xl:block">
          <ul className="flex items-center gap-0.5">
            {liens.map((l) => (
              <li key={l.href}>
                <Link
                  href={l.href}
                  className="rounded-md px-2 py-2 text-[0.9375rem] whitespace-nowrap text-sur-nuit-2 no-underline hover:bg-white/5 hover:text-sur-nuit"
                >
                  {l.libelle}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        <div className="ms-auto flex items-center gap-2">
          <ChoixLangue />
          <div className="hidden sm:block">
            <ChoixTheme />
          </div>
          <Link href="/contact" className="bouton bouton-principal hidden min-h-11 py-2 text-[0.9375rem] whitespace-nowrap lg:inline-flex xl:hidden 2xl:inline-flex">
            {t("demande")}
          </Link>
          <MenuMobile
            liens={[{ href: "/", libelle: t("accueil") }, ...liens, { href: "/contact", libelle: t("contact") }]}
            libelleOuvrir={t("menu")}
            libelleFermer={t("fermer")}
            libelleDemande={t("demande")}
          />
        </div>
      </div>
    </header>
  );
}
