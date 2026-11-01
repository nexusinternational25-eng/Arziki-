// Carte stylisée de la route Alger - Niamey (SVG, sans fond de carte officiel).
// Les positions viennent des coordonnées réelles, légèrement écartées autour de la
// frontière pour rester lisibles. Le tracé s'anime, sauf si le visiteur a demandé
// de réduire les animations (règle dans globals.css).

import type { Langue } from "@/i18n/routing";
import { VILLES } from "@/lib/contenu";

type Props = {
  langue: Langue;
  libelles: { algerie: string; niger: string; route: string; frontiere: string; aria: string };
};

// Projection simple : longitude vers x, latitude vers y.
const px = (lon: number) => 40 + (lon - 1.5) * 40;
const py = (lat: number) => 30 + (37.2 - lat) * 30;

// Écarts manuels pour séparer In-Guezzam et Assamaka de part et d'autre de la frontière.
const AJUSTEMENT_Y: Record<string, number> = { "in-guezzam": -10, assamaka: +14 };
// Côté de l'étiquette : à droite par défaut.
const ETIQUETTE_A_GAUCHE = new Set(["in-guezzam", "tahoua"]);

export function CarteRoute({ langue, libelles }: Props) {
  const points = VILLES.map((v) => ({
    ...v,
    x: Math.round(px(v.lon)),
    y: Math.round(py(v.lat) + (AJUSTEMENT_Y[v.code] ?? 0)),
  }));
  const trace = points.map((p, i) => `${i === 0 ? "M" : "L"}${p.x},${p.y}`).join(" ");
  const frontiere = "M96,584 L211,564 L398,505";

  return (
    <figure className="carte relative overflow-hidden p-3 sm:p-5">
      <svg viewBox="0 0 420 790" role="img" aria-label={libelles.aria} className="h-auto w-full" style={{ direction: "ltr" }}>
        <defs>
          <pattern id="grain" width="14" height="14" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1" fill="var(--c-ocre)" opacity="0.18" />
          </pattern>
        </defs>

        {/* Zones des deux pays, de part et d'autre de la frontière */}
        <path d={`M0,0 H420 V505 L398,505 L211,564 L96,584 L0,600 Z`} fill="var(--c-vert)" opacity="0.06" />
        <path d={`M0,600 L96,584 L211,564 L398,505 L420,505 V790 H0 Z`} fill="var(--c-ocre)" opacity="0.08" />
        <rect width="420" height="790" fill="url(#grain)" />

        {/* Côte méditerranéenne, en haut */}
        <path d="M0,22 C60,12 120,30 180,20 S300,10 420,24" fill="none" stroke="var(--c-nuit-2)" strokeOpacity="0.35" strokeWidth="2" />

        <text x="300" y="300" textAnchor="middle" fontSize="22" fontWeight="700" letterSpacing="4" fill="var(--c-vert)" opacity="0.55">
          {libelles.algerie}
        </text>
        <text x="330" y="745" textAnchor="middle" fontSize="22" fontWeight="700" letterSpacing="4" fill="var(--c-ocre-fort)" opacity="0.6">
          {libelles.niger}
        </text>

        {/* Frontière en pointillé */}
        <path d={frontiere} fill="none" stroke="var(--c-encre)" strokeOpacity="0.55" strokeWidth="2" strokeDasharray="6 7" />

        {/* Tracé de la route : fond puis trait animé */}
        <path d={trace} fill="none" stroke="var(--c-ligne)" strokeWidth="7" strokeLinecap="round" strokeLinejoin="round" />
        <path
          d={trace}
          pathLength={1}
          className="trace-route"
          fill="none"
          stroke="var(--c-ocre)"
          strokeWidth="4"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {points.map((p, i) => {
          const gauche = ETIQUETTE_A_GAUCHE.has(p.code);
          const extremite = i === 0 || i === points.length - 1;
          return (
            <g key={p.code} className="etape-carte" style={{ animationDelay: `${0.4 + i * 0.35}s` }}>
              <circle
                cx={p.x}
                cy={p.y}
                r={extremite ? 8 : 6}
                fill={p.pays === "dz" ? "var(--c-vert)" : "var(--c-ocre-fort)"}
                stroke="var(--c-surface)"
                strokeWidth="3"
              />
              <text
                x={gauche ? p.x - 14 : p.x + 14}
                y={p.y + 5}
                textAnchor={gauche ? "end" : "start"}
                fontSize={extremite ? 17 : 15}
                fontWeight={extremite ? 700 : 600}
                fill="var(--c-encre)"
                stroke="var(--c-surface)"
                strokeWidth="4"
                paintOrder="stroke"
              >
                {p.nom[langue]}
              </text>
            </g>
          );
        })}
      </svg>

      <figcaption className="mt-2 flex flex-wrap gap-x-5 gap-y-1 px-1 text-sm text-gris">
        <span className="inline-flex items-center gap-2">
          <span className="inline-block h-1 w-6 rounded bg-ocre" aria-hidden="true" />
          {libelles.route}
        </span>
        <span className="inline-flex items-center gap-2">
          <span className="inline-block w-6 border-t-2 border-dashed border-encre/60" aria-hidden="true" />
          {libelles.frontiere}
        </span>
      </figcaption>
    </figure>
  );
}
