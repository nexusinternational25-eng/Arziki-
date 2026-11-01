import Link from "next/link";
import { deconnexion } from "./actions";

export function EnTeteAdmin() {
  return (
    <header className="bg-nuit text-sur-nuit">
      <div className="conteneur flex h-14 items-center justify-between">
        <Link href="/admin" className="font-semibold text-sur-nuit no-underline">
          Desk Algérie-Niger · Demandes
        </Link>
        <div className="flex items-center gap-4 text-sm">
          {/* Téléchargement d'un fichier : un lien classique est voulu ici. */}
          {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
          <a href="/api/admin/export" className="text-sur-nuit-2 hover:text-sur-nuit">
            Export CSV
          </a>
          <form action={deconnexion}>
            <button type="submit" className="rounded border border-white/30 px-3 py-1.5 hover:border-ocre-clair">
              Se déconnecter
            </button>
          </form>
        </div>
      </div>
    </header>
  );
}
