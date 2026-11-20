import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "FLO — Gestion des rendez-vous",
  description: "Centralisez vos demandes, organisez vos rendez-vous, automatisez vos rappels.",
};

export const viewport: Viewport = { viewportFit: "cover", themeColor: "#0a0a0a" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body className="antialiased">{children}</body>
    </html>
  );
}
