import Link from "next/link";
import { Mail, Phone, Plus, Search } from "lucide-react";
import Card from "@/components/Card";
import { Notice, inputCls, primaryBtn, secondaryBtn } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { createCustomer } from "./actions";
import CustomerFields, { fullName, type Customer } from "./CustomerFields";

const VUES = { tous: "Tous", clients: "Clients", prospects: "Prospects", archives: "Archivés" } as const;
type Vue = keyof typeof VUES;

export default async function Clients({ searchParams }: {
  searchParams: Promise<{ q?: string; vue?: string; nouveau?: string; erreur?: string; info?: string }>;
}) {
  const sp = await searchParams;
  const vue: Vue = sp.vue && sp.vue in VUES ? (sp.vue as Vue) : "tous";
  const q = (sp.q ?? "").replace(/[,()*%\\]/g, " ").trim().slice(0, 80); // caractères spéciaux du filtre PostgREST retirés

  const sb = await createClient();
  // shortcut: 200 fiches max affichées ; ajouter une pagination au-delà.
  let query = sb.from("customers").select("id,kind,first_name,last_name,email,phone,archived_at")
    .order("last_name", { nullsFirst: false }).order("first_name").limit(200);
  query = vue === "archives" ? query.not("archived_at", "is", null) : query.is("archived_at", null);
  if (vue === "clients") query = query.eq("kind", "client");
  if (vue === "prospects") query = query.eq("kind", "prospect");
  if (q) query = query.or(["first_name", "last_name", "email", "phone"].map((f) => `${f}.ilike.*${q}*`).join(","));
  const { data } = await query;
  const rows = (data ?? []) as Customer[];

  return (
    <main className="space-y-5">
      <Card className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-2xl font-bold">Clients et prospects</h1>
          {!sp.nouveau && (
            <Link href="/clients?nouveau=1" className={`${primaryBtn} flex items-center gap-2`}><Plus size={18} aria-hidden /> Nouvelle fiche</Link>
          )}
        </div>
        <Notice erreur={sp.erreur} info={sp.info} />
        {sp.nouveau && (
          <form action={createCustomer} className="space-y-4 bg-surface p-4">
            <h2 className="font-semibold">Nouvelle fiche</h2>
            <CustomerFields />
            <div className="flex gap-3">
              <button className={primaryBtn}>Enregistrer</button>
              <Link href="/clients" className={secondaryBtn}>Annuler</Link>
            </div>
          </form>
        )}
        <form className="flex gap-2" role="search">
          <input type="hidden" name="vue" value={vue} />
          <label className="relative flex-1">
            <span className="sr-only">Rechercher</span>
            <Search size={16} aria-hidden className="absolute left-4 top-1/2 -translate-y-1/2 text-muted" />
            <input name="q" defaultValue={q} placeholder="Nom, téléphone, e-mail…" className={`${inputCls} pl-10`} />
          </label>
          <button className={secondaryBtn}>Rechercher</button>
        </form>
        <nav className="flex flex-wrap gap-2" aria-label="Filtrer">
          {(Object.keys(VUES) as Vue[]).map((v) => (
            <Link key={v} href={`/clients?vue=${v}${q ? `&q=${encodeURIComponent(q)}` : ""}`} aria-current={v === vue ? "page" : undefined}
              className={` px-3 py-1 text-sm font-medium ${v === vue ? "bg-ink text-bg" : "bg-surface text-muted hover:text-ink"}`}>
              {VUES[v]}
            </Link>
          ))}
        </nav>
      </Card>

      <Card className="p-2 md:p-3">
        {rows.length === 0 ? (
          <p className="p-6 text-center text-muted">{q ? "Aucun résultat." : "Aucune fiche pour l’instant."}</p>
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((c) => (
              <li key={c.id}>
                <Link href={`/clients/${c.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-3 py-3 hover:bg-surface">
                  <span className="w-full truncate font-semibold sm:w-auto sm:min-w-0 sm:flex-1">{fullName(c)}</span>
                  <span className={` px-2 py-0.5 text-xs font-semibold ${c.kind === "prospect" ? "bg-accent-2/15 text-accent-2" : "bg-white/10 text-ink"}`}>
                    {c.kind === "prospect" ? "Prospect" : "Client"}
                  </span>
                  {c.phone && <span className="flex items-center gap-1 text-sm text-muted"><Phone size={14} aria-hidden />{c.phone}</span>}
                  {c.email && <span className="hidden items-center gap-1 text-sm text-muted md:flex"><Mail size={14} aria-hidden />{c.email}</span>}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </main>
  );
}
