import { getTranslations } from "next-intl/server";
import { CONTACT } from "@/lib/contenu";
import { IconeWhatsApp } from "./IconeWhatsApp";

export function lienWhatsApp(message: string) {
  return `https://wa.me/${CONTACT.whatsappLien}?text=${encodeURIComponent(message)}`;
}

// Bouton flottant, toujours visible, avec un message prérempli dans la langue active.
export async function BoutonWhatsApp() {
  const t = await getTranslations("whatsapp");
  return (
    <a
      href={lienWhatsApp(t("message"))}
      target="_blank"
      rel="noopener"
      aria-label={t("bouton")}
      title={t("bouton")}
      className="fixed end-4 bottom-4 z-30 inline-flex size-14 items-center justify-center rounded-full bg-[#0f6b45] text-white shadow-lg shadow-black/20 transition-transform hover:scale-105 sm:end-6 sm:bottom-6"
    >
      <IconeWhatsApp className="size-7" />
    </a>
  );
}

