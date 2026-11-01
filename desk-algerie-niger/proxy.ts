import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";

// Redirige « / » vers « /ar » et garde la langue dans l'adresse.
export default createMiddleware(routing);

export const config = {
  // Ni l'API, ni l'administration, ni les fichiers statiques.
  matcher: ["/((?!api|admin|_next|_vercel|images|og|.*\\..*).*)"],
};
