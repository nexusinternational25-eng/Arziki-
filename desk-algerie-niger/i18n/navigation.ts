import { createNavigation } from "next-intl/navigation";
import { routing } from "./routing";

// Liens et navigation qui conservent la langue active.
export const { Link, redirect, usePathname, useRouter, getPathname } = createNavigation(routing);
