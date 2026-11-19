import { redirect } from "next/navigation";
import { Bell, LogOut, Plus, Search } from "lucide-react";
import Sidebar from "@/components/Sidebar";
import { signOut } from "@/lib/actions";
import { getSession } from "@/lib/supabase/server";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();
  if (!session) redirect("/connexion");
  if (!session.organization || !session.role) redirect("/bienvenue");

  return (
    <>
      <Sidebar orgName={session.organization.name} role={session.role} />
      <div className="px-4 pb-28 pt-4 md:pl-[17rem] md:pr-6 md:pb-8">
        <header className="glass mb-5 flex items-center gap-3 px-4 py-3">
          <span className="text-2xl font-black md:hidden">flo<span className="text-accent-2">.</span></span>
          <label className="flex flex-1 items-center gap-2 rounded-2xl bg-white/60 px-3 py-2 text-sm text-muted">
            <Search size={16} aria-hidden />
            <input placeholder="Rechercher un client, un RDV…" className="w-full bg-transparent text-ink outline-none placeholder:text-muted" />
          </label>
          <button aria-label="Notifications" className="relative rounded-2xl bg-white/60 p-2.5 hover:bg-white">
            <Bell size={18} />
            <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-accent-2" />
          </button>
          <button className="flex items-center gap-2 rounded-2xl bg-gradient-to-r from-accent-ink to-accent-2 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-accent/30 hover:brightness-105">
            <Plus size={18} aria-hidden /> <span className="hidden sm:inline">Nouveau RDV</span>
          </button>
          <div title={session.firstName} className="hidden h-10 w-10 place-items-center rounded-2xl bg-ink font-bold uppercase text-white sm:grid">
            {session.firstName.charAt(0) || "?"}
          </div>
          <form action={signOut}>
            <button aria-label="Se déconnecter" title="Se déconnecter" className="rounded-2xl bg-white/60 p-2.5 hover:bg-white">
              <LogOut size={18} />
            </button>
          </form>
        </header>
        {children}
      </div>
    </>
  );
}
