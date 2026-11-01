import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";

export default function PageIntrouvable() {
  const t = useTranslations("erreur404");
  return (
    <section className="conteneur flex min-h-[60vh] flex-col items-start justify-center py-16">
      <p className="font-titre text-6xl font-semibold text-ocre">404</p>
      <h1 className="mt-4 text-3xl font-semibold">{t("titre")}</h1>
      <p className="mt-3 text-lg text-gris">{t("texte")}</p>
      <Link href="/" className="bouton bouton-principal mt-8">
        {t("retour")}
      </Link>
    </section>
  );
}
