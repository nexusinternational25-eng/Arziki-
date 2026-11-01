import { defineRouting } from "next-intl/routing";

// Deux langues : l'arabe (par défaut) et le français.
export const routing = defineRouting({
  locales: ["ar", "fr"],
  defaultLocale: "ar",
  localePrefix: "always",
});

export type Langue = (typeof routing.locales)[number];
