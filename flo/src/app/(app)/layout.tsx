import { redirect } from "next/navigation";
import Link from "next/link";
import { LogOut, Plus, Search } from "lucide-react";
import Sidebar from "@/components/Sidebar";
import { signOut } from "@/lib/actions";
import { createClient, getSession } from "@/lib/supabase/server";

export default async function AppLayout({ children, modal }: { children: React.ReactNode; modal: React.ReactNode }) {
  const session = await getSession();
  if (!session) redirect("/connexion");
  if (!session.organization || !session.role) redirect("/bienvenue");
  const { count: newRequests } = await (await createClient()).from("requests").select("id", { count: "exact", head: true }).eq("status", "new");

  return (
    <>
      <Sidebar orgName={session.organization.name} role={session.role} newRequests={newRequests ?? 0} />
      <div className="px-4 pb-28 pt-4 md:pl-[17.5rem] md:pr-6 md:pb-8">
        <header className="glass mb-5 flex items-center gap-3 px-4 py-3">
          <span className="text-2xl font-black md:hidden">Flo</span>
          <form action="/clients" role="search" className="flex min-w-0 flex-1 items-center gap-2 bg-surface px-3 py-2 text-sm text-muted">
            <Search size={16} aria-hidden className="shrink-0" />
            <label className="sr-only" htmlFor="recherche-globale">Rechercher un client</label>
            <input id="recherche-globale" name="q" placeholder="Rechercher un client…" className="w-full min-w-0 bg-transparent text-ink outline-none placeholder:text-muted" />
          </form>
          <Link href="/agenda/nouveau" className="hidden items-center gap-2 bg-ink md:flex px-4 py-2.5 text-sm font-semibold text-bg hover:opacity-90">
            <Plus size={18} aria-hidden /> Nouveau RDV
          </Link>
          <div title={session.firstName} className="hidden h-10 w-10 place-items-center border border-line bg-surface font-bold uppercase text-ink md:grid">
            {session.firstName.charAt(0) || "?"}
          </div>
          <form action={signOut} className="hidden md:block">
            <button aria-label="Se déconnecter" title="Se déconnecter" className="bg-surface p-2.5 hover:bg-white/10">
              <LogOut size={18} />
            </button>
          </form>
        </header>
        {children}
      </div>
      {modal}
    </>
  );
}
