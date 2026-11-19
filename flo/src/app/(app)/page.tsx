import Link from "next/link";
import { ArrowRight, Clock } from "lucide-react";
import Card from "@/components/Card";
import Halftone from "@/components/Halftone";
import MiniCalendar from "@/components/MiniCalendar";
import WeekChart from "@/components/WeekChart";
import { kpis, upcoming, week, type Status } from "@/lib/demo";
import { getSession } from "@/lib/supabase/server";

const badge: Record<Status, string> = {
  "confirmé": "bg-ink text-bg",
  "à confirmer": "bg-accent-2/15 text-accent-2",
  "annulé": "bg-surface text-muted line-through",
};

export default async function Dashboard() {
  const session = await getSession();
  const weekTotal = week.reduce((s, d) => s + d.rdv, 0);
  return (
    <main className="grid grid-cols-1 gap-5 lg:grid-cols-3">
      <Card i={0} className="relative overflow-hidden lg:col-span-2">
        {/* Mobile : bandeau de points en haut ; ordinateur : points à droite, à côté du texte */}
        <Halftone cols={34} rows={10} cx={0.7} cy={0.1} reach={0.6} className="absolute inset-x-0 top-0 h-28 w-full text-white/40 [mask-image:linear-gradient(to_bottom,#000_40%,transparent)] md:hidden" />
        <Halftone className="absolute inset-y-0 right-0 hidden h-full w-3/5 text-white/40 [mask-image:linear-gradient(to_right,transparent,#000_35%)] md:block" />
        <div className="relative pt-20 md:pt-0">
          <p className="text-xs font-semibold uppercase tracking-widest text-muted">Votre espace de travail</p>
          <h1 className="mt-2 text-4xl font-black uppercase tracking-tight md:text-5xl">Bonjour{session?.firstName ? `, ${session.firstName}` : ""}</h1>
          <p className="mt-2 max-w-xs font-medium text-muted">Votre activité est bien organisée aujourd’hui.</p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <span className=" border border-line bg-bg px-4 py-2 text-sm font-semibold text-ink">
              <span className="text-accent-ink">{weekTotal}</span> rendez-vous cette semaine
            </span>
            <Link href="/demandes" className="flex items-center gap-1 bg-ink px-4 py-2 text-sm font-semibold text-bg hover:opacity-90">
              Demandes urgentes <ArrowRight size={16} aria-hidden />
            </Link>
          </div>
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
              <span className={`mt-3 inline-block px-2 py-0.5 text-xs font-semibold ${k.delta === "urgent" ? "bg-accent-2 text-black" : "bg-surface text-ink"}`}>
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
            <li key={a.time} className="flex items-center gap-3 bg-surface p-3">
              <span className="flex items-center gap-1 text-sm font-bold"><Clock size={14} aria-hidden />{a.time}</span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">{a.client}</p>
                <p className="truncate text-xs text-muted">{a.service} · {a.staff}</p>
              </div>
              <span className={`shrink-0 px-2 py-0.5 text-xs font-semibold ${badge[a.status]}`}>{a.status}</span>
            </li>
          ))}
        </ul>
      </Card>
    </main>
  );
}
