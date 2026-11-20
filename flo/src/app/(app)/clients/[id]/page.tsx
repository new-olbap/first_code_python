import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, Archive, ArchiveRestore, Download, Mail, Phone, Plus, Trash2 } from "lucide-react";
import Card from "@/components/Card";
import { Notice, primaryBtn, secondaryBtn } from "@/components/ui";
import { isUuid } from "@/lib/form";
import { createClient, getSession } from "@/lib/supabase/server";
import { deleteCustomer, setCustomerArchived, updateCustomer } from "../actions";
import { fmt } from "@/lib/dates";
import { STATUS_CLS, STATUS_LABEL, type AgendaRow } from "../../agenda/types";
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
  const canDelete = (await getSession())?.role !== "member";
  const { data: rdv } = await sb.rpc("agenda", { p_customer: id });
  const history = ((rdv ?? []) as AgendaRow[]).reverse(); // plus récents d'abord

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

      <Card className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="font-semibold">Rendez-vous ({history.length})</h2>
          <Link href={`/agenda/nouveau?client=${c.id}`} className={`${secondaryBtn} flex items-center gap-2`}><Plus size={16} aria-hidden /> Nouveau rendez-vous</Link>
        </div>
        {history.length === 0 ? <p className="text-sm text-muted">Aucun rendez-vous pour l’instant.</p> : (
          <ul className="space-y-1">
            {history.map((a) => (
              <li key={a.id}>
                <Link href={`/agenda/${a.id}`} className={`flex flex-wrap gap-x-3 px-3 py-2 text-sm hover:bg-white/10 ${STATUS_CLS[a.status]}`}>
                  <span className="font-semibold first-letter:uppercase">{fmt(a.day, { weekday: "short", day: "numeric", month: "short", year: "numeric" })} · {a.start_time}</span>
                  <span>{a.service_name ?? "Sans prestation"}</span>
                  <span className="text-muted">{STATUS_LABEL[a.status]}</span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <form action={setCustomerArchived}>
        <input type="hidden" name="id" value={c.id} />
        <input type="hidden" name="archive" value={c.archived_at ? "0" : "1"} />
        <button className={`${secondaryBtn} flex items-center gap-2`}>
          {c.archived_at ? <><ArchiveRestore size={16} aria-hidden /> Restaurer la fiche</> : <><Archive size={16} aria-hidden /> Archiver la fiche</>}
        </button>
      </form>
      <Card className="space-y-3">
        <h2 className="font-semibold">Données personnelles (RGPD)</h2>
        <p className="text-sm text-muted">Si ce client vous demande ses données ou leur suppression, vous pouvez y répondre ici.</p>
        <a href={`/clients/${c.id}/export`} download className={`${secondaryBtn} inline-flex items-center gap-2`}><Download size={16} aria-hidden /> Exporter ses données</a>
        {canDelete && (
          <details className="border border-line p-3">
            <summary className="cursor-pointer text-sm font-semibold text-accent-2">Supprimer définitivement ce client</summary>
            <form action={deleteCustomer} className="mt-3 space-y-3">
              <input type="hidden" name="id" value={c.id} />
              <p className="text-sm text-muted">La fiche et les demandes de ce client sont effacées. Ses rendez-vous restent dans l’agenda, sans nom ni notes. C’est irréversible.</p>
              <label className="flex items-center gap-2 text-sm"><input type="checkbox" name="confirm" required className="h-4 w-4 accent-[var(--ink)]" /> Je confirme la suppression définitive</label>
              <button className={`${secondaryBtn} flex items-center gap-2 border-accent-2 text-accent-2`}><Trash2 size={16} aria-hidden /> Supprimer définitivement</button>
            </form>
          </details>
        )}
      </Card>
    </main>
  );
}
