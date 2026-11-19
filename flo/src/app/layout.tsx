import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "FLO — Gestion des rendez-vous",
  description: "Centralisez vos demandes, organisez vos rendez-vous, automatisez vos rappels.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body className="antialiased">{children}</body>
    </html>
  );
}
