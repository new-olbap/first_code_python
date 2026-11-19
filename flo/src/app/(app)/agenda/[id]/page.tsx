import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, Check, MapPin, Phone, RotateCcw, X } from "lucide-react";
import Card from "@/components/Card";
import { Notice, secondaryBtn } from "@/components/ui";
import { fmt } from "@/lib/dates";
import { isUuid } from "@/lib/form";
import { createClient } from "@/lib/supabase/server";
import { getTeam } from "@/lib/team";
import { setAppointmentStatus } from "../actions";
import AppointmentForm, { formOptions } from "../AppointmentForm";
import { STATUS_LABEL, type AgendaRow, type Status } from "../types";

type SP = Partial<Record<"client" | "service" | "staff" | "date" | "time" | "duration" | "notes" | "erreur" | "info", string>>;

function StatusButton({ id, status, label, icon }: { id: string; status: Status; label: string; icon: React.ReactNode }) {
  return (
    <form action={setAppointmentStatus}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="status" value={status} />
      <button className={`${secondaryBtn} flex items-center gap-2`}>{icon}{label}</button>
    </form>
  );
}

export default async function RdvDetail({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<SP> }) {
  const { id } = await params;
  if (!isUuid(id)) notFound();
  const sp = await searchParams;
  const sb = await createClient();
  const { data } = await sb.rpc("agenda", { p_id: id });
  const a = (data as AgendaRow[] | null)?.[0];
  if (!a) notFound();
  const [opts, team] = await Promise.all([formOptions(sb), getTeam(sb)]);
  // Client ou prestation archivés depuis : on les garde dans les listes pour ce rendez-vous.
  if (a.customer_id && !opts.customers.some(([v]) => v === a.customer_id)) opts.customers.push([a.customer_id, `${a.customer_name} (archivé)`]);
  if (a.service_id && !opts.services.some(([v]) => v === a.service_id)) opts.services.push([a.service_id, `${a.service_name} (archivée)`]);
  // Valeurs saisies renvoyées après une erreur, sinon celles du rendez-vous.
  const values = {
    client: sp.client ?? a.customer_id ?? "", service: sp.service ?? a.service_id ?? "", staff: sp.staff ?? a.staff_id,
    date: sp.date ?? a.day, time: sp.time ?? a.start_time, duration: sp.duration ?? String(a.duration_minutes), notes: sp.notes ?? a.notes ?? "",
  };

  return (
    <main className="space-y-5">
      <Link href={`/agenda?vue=jour&date=${a.day}`} className="inline-flex items-center gap-1 text-sm font-medium hover:underline">
        <ArrowLeft size={16} aria-hidden /> Retour à l’agenda
      </Link>
      <Card className="space-y-4">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-muted">{fmt(a.day, { weekday: "long", day: "numeric", month: "long", year: "numeric" })}</p>
            <h1 className={`mt-1 text-3xl font-black ${a.status === "cancelled" ? "text-muted line-through" : ""}`}>{a.start_time} – {a.end_time}</h1>
            <p className="mt-1 text-lg font-semibold">
              {a.customer_id ? <Link href={`/clients/${a.customer_id}`} className="hover:underline">{a.customer_name}</Link> : "Sans client"}
              {a.service_name && <span className="font-normal text-muted"> · {a.service_name}</span>}
            </p>
            <p className="text-sm text-muted">Avec {a.staff_name || "—"}</p>
          </div>
          <span className={`px-2 py-1 text-xs font-semibold ${a.status === "pending" ? "bg-accent-2 text-black" : a.status === "confirmed" ? "bg-ink text-bg" : "bg-surface text-muted"}`}>
            {STATUS_LABEL[a.status]}
          </span>
        </div>
        <div className="flex flex-wrap gap-2 text-sm">
          {a.customer_phone && <a href={`tel:${a.customer_phone.replace(/[^\d+]/g, "")}`} className={`${secondaryBtn} flex items-center gap-2`}><Phone size={16} aria-hidden />{a.customer_phone}</a>}
          {a.customer_address && (
            <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(a.customer_address)}`} target="_blank" rel="noopener noreferrer" className={`${secondaryBtn} flex items-center gap-2`}>
              <MapPin size={16} aria-hidden />{a.customer_address}
            </a>
          )}
        </div>
        <Notice erreur={sp.erreur} info={sp.info} />
        <div className="flex flex-wrap gap-2">
          {a.status === "pending" && <StatusButton id={a.id} status="confirmed" label="Confirmer" icon={<Check size={16} aria-hidden />} />}
          {a.status !== "cancelled" && <StatusButton id={a.id} status="cancelled" label="Annuler le rendez-vous" icon={<X size={16} aria-hidden />} />}
          {a.status === "cancelled" && <StatusButton id={a.id} status="confirmed" label="Rétablir" icon={<RotateCcw size={16} aria-hidden />} />}
        </div>
      </Card>

      <Card className="space-y-4">
        <h2 className="font-semibold">Déplacer ou modifier</h2>
        <AppointmentForm id={a.id} values={values} team={team} {...opts} cancelHref={`/agenda?vue=jour&date=${a.day}`} />
      </Card>
    </main>
  );
}
