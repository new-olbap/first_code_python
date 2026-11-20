import { Archive, ArchiveRestore, Clock } from "lucide-react";
import Card from "@/components/Card";
import { Field, Notice, Select, primaryBtn, secondaryBtn } from "@/components/ui";
import { createClient, getSession } from "@/lib/supabase/server";
import { createService, setServiceArchived, updateService } from "./actions";

type Service = { id: string; name: string; duration_minutes: number; price_cents: number | null; archived_at: string | null };

const DUREES: [string, string][] = [15, 30, 45, 60, 90, 120, 180, 240, 480].map((m) => [String(m), formatDuration(m)]);
function formatDuration(m: number) {
  const h = Math.floor(m / 60), r = m % 60;
  return h ? `${h} h${r ? ` ${r}` : ""}` : `${m} min`;
}
const formatPrice = (c: number | null) => (c === null ? "" : (c / 100).toLocaleString("fr-FR", { minimumFractionDigits: c % 100 ? 2 : 0 }));

function ServiceFields({ s }: { s?: Service }) {
  const d = String(s?.duration_minutes ?? 60);
  const options = DUREES.some(([v]) => v === d) ? DUREES : [...DUREES, [d, formatDuration(Number(d))] as [string, string]];
  return (
    <div className="grid gap-3 sm:grid-cols-[2fr_1fr_1fr]">
      <Field label="Prestation" name="name" defaultValue={s?.name ?? ""} placeholder="Ex. Diagnostic fuite" minLength={2} maxLength={120} required />
      <Select label="Durée" name="duration" defaultValue={d} options={options} />
      <Field label="Prix indicatif (€)" name="price" defaultValue={formatPrice(s?.price_cents ?? null)} placeholder="Ex. 80" inputMode="decimal" maxLength={20} />
    </div>
  );
}

export default async function Prestations({ searchParams }: { searchParams: Promise<{ erreur?: string; info?: string }> }) {
  const session = await getSession();
  const canEdit = session?.role === "owner" || session?.role === "admin";
  const sb = await createClient();
  const { data } = await sb.from("services").select("id,name,duration_minutes,price_cents,archived_at").order("archived_at", { nullsFirst: true }).order("name");
  const rows = (data ?? []) as Service[];

  return (
    <main className="space-y-5">
      <Card className="space-y-4">
        <h1 className="text-2xl font-bold">Prestations</h1>
        <p className="text-sm text-muted">La durée sert à bloquer le bon créneau dans l’agenda et sur la page de réservation.</p>
        <Notice {...await searchParams} />
        {canEdit && (
          <form key={rows.length} action={createService} className="space-y-3 bg-surface p-4">
            <h2 className="font-semibold">Ajouter une prestation</h2>
            <ServiceFields />
            <button className={primaryBtn}>Ajouter</button>
          </form>
        )}
      </Card>

      <Card className="space-y-3">
        {rows.length === 0 && <p className="p-4 text-center text-muted">Aucune prestation pour l’instant.</p>}
        {rows.map((s) => canEdit ? (
          <div key={s.id} className={`space-y-3 bg-surface p-4 ${s.archived_at ? "opacity-60" : ""}`}>
            <form action={updateService} className="space-y-3">
              <input type="hidden" name="id" value={s.id} />
              <ServiceFields s={s} />
              <div className="flex flex-wrap gap-2">
                <button className={secondaryBtn}>Enregistrer</button>
                <button formAction={setServiceArchived} name="archive" value={s.archived_at ? "0" : "1"} className={`${secondaryBtn} flex items-center gap-2`}>
                  {s.archived_at ? <><ArchiveRestore size={16} aria-hidden /> Réactiver</> : <><Archive size={16} aria-hidden /> Archiver</>}
                </button>
              </div>
            </form>
          </div>
        ) : (
          <div key={s.id} className="flex items-center gap-4 bg-surface p-4">
            <span className="flex-1 font-semibold">{s.name}</span>
            <span className="flex items-center gap-1 text-sm text-muted"><Clock size={14} aria-hidden />{formatDuration(s.duration_minutes)}</span>
            {s.price_cents !== null && <span className="text-sm font-semibold">{formatPrice(s.price_cents)} €</span>}
          </div>
        ))}
      </Card>
    </main>
  );
}
