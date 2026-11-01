import type { Metadata } from "next";
import { IBM_Plex_Sans_Arabic } from "next/font/google";
import "../globals.css";

const texte = IBM_Plex_Sans_Arabic({
  subsets: ["arabic", "latin"],
  weight: ["400", "600", "700"],
  variable: "--font-plex-arabic",
  display: "swap",
});

// L'espace d'administration n'est jamais indexé.
export const metadata: Metadata = {
  title: "Administration | Desk Algérie-Niger",
  robots: { index: false, follow: false, nocache: true },
};

export default function LayoutAdmin({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" dir="ltr" className={texte.variable}>
      <body className="min-h-dvh antialiased">{children}</body>
    </html>
  );
}
