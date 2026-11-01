"use client";

import { useEffect, useState } from "react";
import { Link, usePathname } from "@/i18n/navigation";
import { ChoixTheme } from "./ChoixTheme";

type Props = {
  liens: { href: string; libelle: string }[];
  libelleOuvrir: string;
  libelleFermer: string;
  libelleDemande: string;
};

export function MenuMobile({ liens, libelleOuvrir, libelleFermer, libelleDemande }: Props) {
  const [ouvert, setOuvert] = useState(false);
  const chemin = usePathname();

  useEffect(() => {
    if (!ouvert) return;
    const fermer = (e: KeyboardEvent) => e.key === "Escape" && setOuvert(false);
    document.addEventListener("keydown", fermer);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", fermer);
      document.body.style.overflow = "";
    };
  }, [ouvert]);

  return (
    <div className="xl:hidden">
      <button
        type="button"
        aria-expanded={ouvert}
        aria-controls="menu-mobile"
        aria-label={ouvert ? libelleFermer : libelleOuvrir}
        onClick={() => setOuvert((o) => !o)}
        className="inline-flex size-11 items-center justify-center rounded-md border border-white/30 text-sur-nuit"
      >
        <svg viewBox="0 0 24 24" className="size-5" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          {ouvert ? <path d="M6 6l12 12M18 6L6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
        </svg>
      </button>
      {ouvert && (
        <div id="menu-mobile" className="fixed inset-x-0 top-16 bottom-0 z-40 overflow-y-auto bg-nuit lg:top-[4.5rem]">
          <nav className="conteneur py-4">
            <ul className="divide-y divide-white/10">
              {liens.map((l) => (
                <li key={l.href}>
                  <Link
                    href={l.href}
                    aria-current={chemin === l.href ? "page" : undefined}
                    onClick={() => setOuvert(false)}
                    className="block py-3.5 text-lg text-sur-nuit no-underline aria-[current=page]:text-ocre-clair"
                  >
                    {l.libelle}
                  </Link>
                </li>
              ))}
            </ul>
            <div className="mt-6 flex items-center gap-3">
              <Link href="/contact" onClick={() => setOuvert(false)} className="bouton bouton-principal flex-1">
                {libelleDemande}
              </Link>
              <ChoixTheme />
            </div>
          </nav>
        </div>
      )}
    </div>
  );
}
