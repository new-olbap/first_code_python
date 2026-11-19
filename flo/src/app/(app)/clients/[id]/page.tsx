import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, Archive, ArchiveRestore, Mail, Phone } from "lucide-react";
import Card from "@/components/Card";
import { Notice, primaryBtn, secondaryBtn } from "@/components/ui";
import { isUuid } from "@/lib/form";
import { createClient } from "@/lib/supabase/server";
import { setCustomerArchived, updateCustomer } from "../actions";
import CustomerFields, { fullName, type Customer } from "../CustomerFields";

export default async function ClientDetail({ params, searchParams }: {
  params: Promise<{ id: string }>; searchParams: Promise<{ erreur?: string; info?: string }>;
}) {
  const { id } = await params;
  if (!isUuid(id)) notFound();
  const sb = await createClient();
  const { data } = await sb.from("customers").select("*").eq("id", id).maybeSingle(); // RLS : uniquement les fiches de l'entreprise
  if (!data) notFound();
  const c = data as Customer;

  return (
    <main className="space-y-5">
      <Link href="/clients" className="inline-flex items-center gap-1 text-sm font-medium text-accent-ink hover:underline">
        <ArrowLeft size={16} aria-hidden /> Tous les clients
      </Link>
      <Card className="space-y-4">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold">{fullName(c)}</h1>
            <p className="text-sm text-muted">{c.kind === "prospect" ? "Prospect" : "Client"}{c.archived_at && " · archivé"}</p>
          </div>
          <div className="flex flex-wrap gap-2">
            {c.phone && <a href={`tel:${c.phone.replace(/[^\d+]/g, "")}`} className={`${secondaryBtn} flex items-center gap-2`}><Phone size={16} aria-hidden /> Appeler</a>}
            {c.email && <a href={`mailto:${c.email}`} className={`${secondaryBtn} flex items-center gap-2`}><Mail size={16} aria-hidden /> E-mail</a>}
          </div>
        </div>
        <Notice {...await searchParams} />
        <form action={updateCustomer} className="space-y-4">
          <input type="hidden" name="id" value={c.id} />
          <CustomerFields c={c} />
          <button className={primaryBtn}>Enregistrer les modifications</button>
        </form>
      </Card>

      <Card className="space-y-2">
        <h2 className="font-semibold">Historique des rendez-vous</h2>
        <p className="text-sm text-muted">Les rendez-vous de ce client apparaîtront ici dès que l’agenda sera en place.</p>
      </Card>

      <form action={setCustomerArchived}>
        <input type="hidden" name="id" value={c.id} />
        <input type="hidden" name="archive" value={c.archived_at ? "0" : "1"} />
        <button className={`${secondaryBtn} flex items-center gap-2`}>
          {c.archived_at ? <><ArchiveRestore size={16} aria-hidden /> Restaurer la fiche</> : <><Archive size={16} aria-hidden /> Archiver la fiche</>}
        </button>
      </form>
    </main>
  );
}
