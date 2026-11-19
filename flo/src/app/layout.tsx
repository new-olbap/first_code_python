import type { Metadata } from "next";
import { Bell, Plus, Search } from "lucide-react";
import Sidebar from "@/components/Sidebar";
import "./globals.css";

export const metadata: Metadata = {
  title: "FLO — Gestion des rendez-vous",
  description: "Centralisez vos demandes, organisez vos rendez-vous, automatisez vos rappels.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body className="antialiased">
        <Sidebar />
        <div className="px-4 pb-28 pt-4 md:pl-[17rem] md:pr-6 md:pb-8">
          <header className="glass mb-5 flex items-center gap-3 px-4 py-3">
            <span className="text-2xl font-black md:hidden">flo<span className="text-accent">.</span></span>
            <label className="flex flex-1 items-center gap-2 rounded-2xl bg-white/60 px-3 py-2 text-sm text-muted">
              <Search size={16} aria-hidden />
              <input placeholder="Rechercher un client, un RDV…" className="w-full bg-transparent text-ink outline-none placeholder:text-muted" />
            </label>
            <button aria-label="Notifications" className="relative rounded-2xl bg-white/60 p-2.5 hover:bg-white">
              <Bell size={18} />
              <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-accent" />
            </button>
            <button className="flex items-center gap-2 rounded-2xl bg-gradient-to-r from-accent to-accent-2 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-accent/30 hover:brightness-105">
              <Plus size={18} aria-hidden /> <span className="hidden sm:inline">Nouveau RDV</span>
            </button>
            <div aria-label="Thomas" className="hidden h-10 w-10 place-items-center rounded-2xl bg-ink font-bold text-white sm:grid">T</div>
          </header>
          {children}
        </div>
      </body>
    </html>
  );
}
