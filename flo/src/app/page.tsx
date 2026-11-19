import Link from "next/link";
import { ArrowRight, Clock } from "lucide-react";
import Card from "@/components/Card";
import MiniCalendar from "@/components/MiniCalendar";
import WeekChart from "@/components/WeekChart";
import { kpis, upcoming, user, week, type Status } from "@/lib/demo";

export const dynamic = "force-dynamic"; // le calendrier suit la date du jour

const badge: Record<Status, string> = {
  "confirmé": "bg-emerald-100 text-emerald-700",
  "à confirmer": "bg-amber-100 text-amber-700",
  "annulé": "bg-stone-200 text-stone-600",
};

export default function Dashboard() {
  const weekTotal = week.reduce((s, d) => s + d.rdv, 0);
  return (
    <main className="grid grid-cols-1 gap-5 lg:grid-cols-3">
      <Card i={0} className="relative overflow-hidden lg:col-span-2">
        <div className="absolute -right-16 -top-16 h-64 w-64 rounded-full bg-gradient-to-br from-accent/40 to-accent-2/30 blur-2xl" />
        <p className="text-xs font-semibold uppercase tracking-widest text-muted">Votre espace de travail</p>
        <h1 className="mt-2 text-3xl font-bold md:text-4xl">Bonjour, {user.firstName} 👋</h1>
        <p className="mt-2 text-muted">Votre activité est bien organisée aujourd’hui.</p>
        <div className="mt-6 flex flex-wrap items-center gap-3">
          <span className="rounded-2xl bg-white/70 px-4 py-2 text-sm font-semibold">
            <span className="text-accent-ink">{weekTotal}</span> rendez-vous cette semaine
          </span>
          <Link href="/demandes" className="flex items-center gap-1 rounded-2xl bg-ink px-4 py-2 text-sm font-semibold text-white hover:opacity-90">
            Demandes urgentes <ArrowRight size={16} aria-hidden />
          </Link>
        </div>
      </Card>

      <Card i={1} className="lg:row-span-1">
        <MiniCalendar />
      </Card>

      <div className="grid grid-cols-2 gap-5 md:grid-cols-4 lg:col-span-3">
        {kpis.map((k, i) => {
          const body = (
            <>
              <p className="text-3xl font-bold">{k.value}</p>
              <p className="mt-1 text-sm text-muted">{k.label}</p>
              <span className={`mt-3 inline-block rounded-full px-2 py-0.5 text-xs font-semibold ${k.delta === "urgent" ? "bg-accent-2 text-white" : "bg-white/80 text-accent-ink"}`}>
                {k.delta}
              </span>
            </>
          );
          return (
            <Card key={k.label} i={i + 2} className="p-4 md:p-5">
              {k.href ? <Link href={k.href} className="block">{body}</Link> : body}
            </Card>
          );
        })}
      </div>

      <Card i={6} className="lg:col-span-2">
        <div className="mb-2 flex items-center justify-between">
          <h2 className="font-semibold">Rendez-vous sur 7 jours</h2>
          <Link href="/statistiques" className="text-sm text-accent-ink hover:underline">Statistiques</Link>
        </div>
        <WeekChart />
      </Card>

      <Card i={7}>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-semibold">Prochains RDV</h2>
          <Link href="/agenda" className="text-sm text-accent-ink hover:underline">Agenda</Link>
        </div>
        <ul className="space-y-2">
          {upcoming.map((a) => (
            <li key={a.time} className="flex items-center gap-3 rounded-2xl bg-white/60 p-3">
              <span className="flex items-center gap-1 text-sm font-bold"><Clock size={14} aria-hidden />{a.time}</span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">{a.client}</p>
                <p className="truncate text-xs text-muted">{a.service} · {a.staff}</p>
              </div>
              <span className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold ${badge[a.status]}`}>{a.status}</span>
            </li>
          ))}
        </ul>
      </Card>
    </main>
  );
}
