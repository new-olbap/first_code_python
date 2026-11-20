import Link from "next/link";
import { ArrowRight, Plus } from "lucide-react";
import Card from "@/components/Card";
import Halftone from "@/components/Halftone";
import MiniCalendar from "@/components/MiniCalendar";
import WeekChart, { type DayStat } from "@/components/WeekChart";
import { primaryBtn, secondaryBtn } from "@/components/ui";
import { addDays, addMonths, fmt, nowTimeIn, startOfMonth, startOfWeek, todayIn } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";
import { STATUS_LABEL, type AgendaRow } from "./agenda/types";

export default async function Dashboard() {
  const session = (await getSession())!;
  const tz = session.organization!.timezone;
  const today = todayIn(tz), now = nowTimeIn(tz);
  const monthStart = startOfMonth(today), nextMonth = addMonths(today, 1), prevMonth = addMonths(today, -1);
  const chartFrom = addDays(today, -29);

  const sb = await createClient();
  const [{ data }, { count: prospects }] = await Promise.all([
    sb.rpc("agenda", { p_from: chartFrom < prevMonth ? chartFrom : prevMonth, p_to: addDays(today, 60) }),
    sb.from("customers").select("id", { count: "exact", head: true }).eq("kind", "prospect").gte("created_at", monthStart),
  ]);
  const all = (data ?? []) as AgendaRow[];
  const active = all.filter((a) => a.status !== "cancelled");
  const inMonth = (a: AgendaRow) => a.day >= monthStart && a.day < nextMonth;

  const rdvMonth = active.filter(inMonth).length;
  const rdvPrev = active.filter((a) => a.day >= prevMonth && a.day < monthStart).length;
  const monthAll = all.filter(inMonth);
  const cancelRate = monthAll.length ? Math.round((100 * monthAll.filter((a) => a.status === "cancelled").length) / monthAll.length) : 0;
  const pending = all.filter((a) => a.status === "pending" && a.day >= today);
  // fin < début = le rendez-vous se termine après minuit
  const upcoming = active.filter((a) => a.day > today || (a.day === today && (a.end_time > now || a.end_time < a.start_time))).slice(0, 5);
  const weekStart = startOfWeek(today);
  const weekTotal = active.filter((a) => a.day >= weekStart && a.day <= addDays(weekStart, 6)).length;
  const busyDays = new Set(active.filter(inMonth).map((a) => a.day));
  const chart: DayStat[] = Array.from({ length: 30 }, (_, i) => {
    const day = addDays(chartFrom, i);
    return {
      day, short: fmt(day, { weekday: "short", day: "numeric" }), long: fmt(day, { weekday: "long", day: "numeric", month: "long" }),
      rdv: active.filter((a) => a.day === day).length, annules: all.filter((a) => a.day === day && a.status === "cancelled").length,
    };
  });
  const diff = rdvMonth - rdvPrev;
  const kpis = [
    { value: rdvMonth, label: "RDV ce mois", note: rdvPrev ? `${diff >= 0 ? "+" : ""}${diff} vs mois dernier` : "ce mois-ci", href: "/agenda?vue=mois" },
    { value: prospects ?? 0, label: "Nouveaux prospects", note: "ce mois-ci", href: "/clients?vue=prospects" },
    { value: pending.length, label: "À confirmer", note: pending.length ? "à traiter" : "rien en attente", urgent: pending.length > 0, href: pending[0] ? `/agenda/${pending[0].id}` : "/agenda" },
    { value: `${cancelRate} %`, label: "Annulations", note: "ce mois-ci", href: "/agenda?vue=mois" },
  ];
  const dayLabel = (d: string) => d === today ? "Aujourd’hui" : d === addDays(today, 1) ? "Demain" : fmt(d, { weekday: "short", day: "numeric", month: "short" });

  return (
    <main className="grid grid-cols-1 gap-5 lg:grid-cols-3">
      <Card className="relative overflow-hidden lg:col-span-2">
        {/* Mobile : bandeau de points en haut ; ordinateur : points à droite, à côté du texte */}
        <Halftone cols={34} rows={10} cx={0.7} cy={0.1} reach={0.6} className="absolute inset-x-0 top-0 h-28 w-full text-white/40 [mask-image:linear-gradient(to_bottom,#000_40%,transparent)] md:hidden" />
        <Halftone className="absolute inset-y-0 right-0 hidden h-full w-3/5 text-white/40 [mask-image:linear-gradient(to_right,transparent,#000_35%)] md:block" />
        <div className="relative pt-20 md:pt-0">
          <p className="text-xs font-semibold uppercase tracking-widest text-muted">Votre espace de travail</p>
          <h1 className="mt-2 text-4xl font-black uppercase tracking-tight md:text-5xl">Bonjour{session.firstName ? `, ${session.firstName}` : ""}</h1>
          <p className="mt-2 max-w-xs font-medium text-muted">
            {pending.length ? `${pending.length} rendez-vous à confirmer.` : "Tout est à jour."} {weekTotal} rendez-vous cette semaine.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <Link href="/agenda/nouveau" className={`${primaryBtn} flex items-center gap-2`}><Plus size={16} aria-hidden /> Nouveau rendez-vous</Link>
            <Link href="/agenda" className={`${secondaryBtn} flex items-center gap-1 bg-bg`}>Voir l’agenda <ArrowRight size={16} aria-hidden /></Link>
          </div>
        </div>
      </Card>

      <Card>
        <MiniCalendar today={today} busyDays={busyDays} />
      </Card>

      <div className="grid grid-cols-2 gap-5 md:grid-cols-4 lg:col-span-3">
        {kpis.map((k) => (
          <Card key={k.label} interactive className="p-0">
            <Link href={k.href} className="block p-4 md:p-5">
              <p className="text-3xl font-bold">{k.value}</p>
              <p className="mt-1 text-sm text-muted">{k.label}</p>
              <span className={`mt-3 inline-block px-2 py-0.5 text-xs font-semibold ${k.urgent ? "bg-accent-2 text-black" : "bg-surface text-ink"}`}>{k.note}</span>
            </Link>
          </Card>
        ))}
      </div>

      <Card className="lg:col-span-2">
        <h2 className="mb-2 font-semibold">Activité</h2>
        <WeekChart data={chart} />
      </Card>

      <Card>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-semibold">Prochains rendez-vous</h2>
          <Link href="/agenda" className="text-sm hover:underline">Agenda</Link>
        </div>
        {upcoming.length === 0 ? (
          <p className="text-sm text-muted">Aucun rendez-vous à venir. <Link href="/agenda/nouveau" className="text-ink underline">En créer un</Link></p>
        ) : (
          <ul className="space-y-2">
            {upcoming.map((a) => (
              <li key={a.id}>
                <Link href={`/agenda/${a.id}`} className="lift flex items-center gap-3 border border-transparent bg-surface p-3">
                  <span className="w-16 shrink-0 text-xs text-muted first-letter:uppercase">{dayLabel(a.day)}<span className="block text-sm font-bold text-ink">{a.start_time}</span></span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold">{a.customer_name ?? "Sans client"}</span>
                    <span className="block truncate text-xs text-muted">{[a.service_name, a.staff_name].filter(Boolean).join(" · ")}</span>
                  </span>
                  {a.status === "pending" && <span className="shrink-0 bg-accent-2/15 px-2 py-0.5 text-xs font-semibold text-accent-2">{STATUS_LABEL.pending}</span>}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </main>
  );
}
