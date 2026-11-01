// Petits blocs de mise en page réutilisés par toutes les pages.

import Image from "next/image";
import type { ReactNode } from "react";
import { Link } from "@/i18n/navigation";

export function TitreSection({
  surtitre,
  titre,
  intro,
  id,
}: {
  surtitre?: string;
  titre: string;
  intro?: string;
  id?: string;
}) {
  return (
    <div className="max-w-3xl">
      {surtitre && <p className="surtitre">{surtitre}</p>}
      <h2 id={id} className="mt-2 text-2xl font-semibold sm:text-[2rem]">
        {titre}
      </h2>
      {intro && <p className="mt-3 text-lg text-gris">{intro}</p>}
    </div>
  );
}

/** Bandeau en haut des pages intérieures : titre, introduction, image optionnelle. */
export function BandeauPage({
  titre,
  intro,
  image,
  surtitre,
  children,
}: {
  titre: string;
  intro?: string;
  image?: string;
  surtitre?: string;
  children?: ReactNode;
}) {
  return (
    <section className="border-b border-ligne bg-surface">
      <div className={`conteneur grid gap-8 py-10 sm:py-14 ${image ? "lg:grid-cols-[1.3fr_1fr] lg:items-center" : ""}`}>
        <div className="max-w-3xl">
          {surtitre && <p className="surtitre">{surtitre}</p>}
          <h1 className="mt-2 text-3xl font-semibold sm:text-[2.5rem]">{titre}</h1>
          {intro && <p className="mt-4 text-lg text-gris">{intro}</p>}
          {children}
        </div>
        {image && (
          <div className="relative aspect-[16/10] overflow-hidden rounded-xl lg:aspect-[4/3]">
            <Image
              src={`/images/${image}`}
              alt=""
              fill
              priority
              sizes="(min-width: 1024px) 40vw, 100vw"
              className="object-cover"
            />
          </div>
        )}
      </div>
    </section>
  );
}

export function CarteLien({
  href,
  image,
  titre,
  texte,
  action,
  numero,
}: {
  href: string;
  image?: string;
  titre: string;
  texte: string;
  action: string;
  numero?: number;
}) {
  return (
    <Link
      href={href}
      className="carte group flex h-full flex-col overflow-hidden text-encre no-underline transition-shadow hover:shadow-[0_8px_30px_rgb(var(--c-ombre)/0.10)]"
    >
      {image && (
        <div className="relative aspect-[16/9] overflow-hidden">
          <Image
            src={`/images/${image}`}
            alt=""
            fill
            sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
            className="object-cover transition-transform duration-500 group-hover:scale-[1.03]"
          />
        </div>
      )}
      <div className="flex flex-1 flex-col p-5">
        {numero !== undefined && (
          <span className="font-titre text-sm font-semibold text-ocre-fort">{String(numero).padStart(2, "0")}</span>
        )}
        <h3 className="mt-1 text-lg font-semibold">{titre}</h3>
        <p className="mt-2 flex-1 text-[0.9375rem] text-gris">{texte}</p>
        <span className="mt-4 inline-flex items-center gap-1.5 font-semibold text-ocre-fort">
          {action}
          <Fleche />
        </span>
      </div>
    </Link>
  );
}

/** Flèche qui s'inverse automatiquement en arabe. */
export function Fleche({ className = "size-4" }: { className?: string }) {
  return (
    <svg viewBox="0 0 20 20" aria-hidden="true" className={`${className} rtl:-scale-x-100`} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 10h12M11 5l5 5-5 5" />
    </svg>
  );
}

export function Coche({ className = "size-5" }: { className?: string }) {
  return (
    <svg viewBox="0 0 20 20" aria-hidden="true" className={className} fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4.5 10.5l3.5 3.5 7.5-8" />
    </svg>
  );
}

export function ListeCoches({ elements }: { elements: string[] }) {
  return (
    <ul className="space-y-3">
      {elements.map((e) => (
        <li key={e} className="flex gap-3">
          <span className="mt-0.5 inline-flex size-6 shrink-0 items-center justify-center rounded-full bg-vert-pale text-vert">
            <Coche className="size-4" />
          </span>
          <span>{e}</span>
        </li>
      ))}
    </ul>
  );
}
