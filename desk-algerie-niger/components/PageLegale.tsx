import type { Langue } from "@/i18n/routing";
import type { Bloc } from "@/lib/legal";
import { MISE_A_JOUR } from "@/lib/legal";
import { BandeauPage } from "./Blocs";

export function PageLegale({ titre, blocs, langue }: { titre: string; blocs: Bloc[]; langue: Langue }) {
  return (
    <>
      <BandeauPage titre={titre} intro={`${langue === "fr" ? "Mise à jour :" : "آخر تحديث:"} ${MISE_A_JOUR[langue]}`} />
      <section className="conteneur py-12">
        <div className="prose-desk carte max-w-3xl p-6 sm:p-10">
          {blocs.map((b) => (
            <div key={b.titre.fr}>
              <h2>{b.titre[langue]}</h2>
              {b.paragraphes.map((p) => (
                <p key={p.fr}>{p[langue]}</p>
              ))}
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
