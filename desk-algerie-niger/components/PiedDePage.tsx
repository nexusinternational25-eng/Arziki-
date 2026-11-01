import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { Embleme } from "./Logo";
import { LIENS_NAV } from "./EnTete";
import { CONTACT } from "@/lib/contenu";

export async function PiedDePage() {
  const t = await getTranslations("pied");
  const n = await getTranslations("nav");
  const m = await getTranslations("meta");
  const annee = 2026;

  return (
    <footer className="mt-auto bg-nuit text-sur-nuit-2">
      <div className="conteneur grid gap-10 py-12 md:grid-cols-[1.4fr_1fr_1fr]">
        <div>
          <div className="flex items-center gap-2.5 text-sur-nuit">
            <Embleme className="size-9" />
            <span className="font-titre text-lg font-semibold">{m("nomSite")}</span>
          </div>
          <p className="mt-4 max-w-md text-[0.9375rem]">{t("animePar")}</p>
        </div>
        <div>
          <h2 className="font-titre text-base text-sur-nuit">{t("liens")}</h2>
          <ul className="mt-3 space-y-2 text-[0.9375rem]">
            {LIENS_NAV.map((l) => (
              <li key={l.href}>
                <Link href={l.href} className="text-sur-nuit-2 no-underline hover:text-sur-nuit hover:underline">
                  {n(l.cle)}
                </Link>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <h2 className="font-titre text-base text-sur-nuit">{t("nousJoindre")}</h2>
          <ul className="mt-3 space-y-2 text-[0.9375rem]">
            <li>
              <a href={`mailto:${CONTACT.email}`} className="text-sur-nuit-2 hover:text-sur-nuit" dir="ltr">
                {CONTACT.email}
              </a>
            </li>
            <li>
              <a
                href={`https://wa.me/${CONTACT.whatsappLien}`}
                className="text-sur-nuit-2 hover:text-sur-nuit"
                dir="ltr"
                rel="noopener"
                target="_blank"
              >
                WhatsApp {CONTACT.whatsappAffiche}
              </a>
            </li>
            <li>
              <Link href="/contact" className="font-semibold text-ocre-clair no-underline hover:underline">
                {n("demande")}
              </Link>
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/10">
        <div className="conteneur flex flex-col gap-3 py-6 text-sm md:flex-row md:items-center md:justify-between">
          <p className="max-w-2xl font-semibold text-sur-nuit">{t("avertissement")}</p>
          <div className="flex flex-wrap gap-x-5 gap-y-2">
            <Link href="/mentions-legales" className="text-sur-nuit-2 hover:text-sur-nuit">
              {t("mentions")}
            </Link>
            <Link href="/confidentialite" className="text-sur-nuit-2 hover:text-sur-nuit">
              {t("confidentialite")}
            </Link>
            <span>
              © {annee} {t("droits")}
            </span>
          </div>
        </div>
      </div>
    </footer>
  );
}
