import Link from "next/link";
import { ChevronLeft, ChevronRight, Plus } from "lucide-react";
import Card from "@/components/Card";
import { Notice, primaryBtn, secondaryBtn } from "@/components/ui";
import { addDays, addMonths, fmt, isIsoDate, nowTimeIn, startOfMonth, startOfWeek, todayIn } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";
import { toMin } from "./grid";
import TimeGrid from "./TimeGrid";
import { STATUS_CLS, type AgendaRow } from "./types";

const VUES = { jour: "Jour", semaine: "Semaine", mois: "Mois" } as const;
type Vue = keyof typeof VUES;

export default async function Agenda({ searchParams }: { searchParams: Promise<{ vue?: string; date?: string; erreur?: string; info?: string }> }) {
  const sp = await searchParams;
  const session = (await getSession())!;
  const today = todayIn(session.organization!.timezone);
  const vue: Vue = sp.vue && sp.vue in VUES ? (sp.vue as Vue) : "semaine";
  const date = isIsoDate(sp.date) ? sp.date : today;

  const from = vue === "jour" ? date : vue === "semaine" ? startOfWeek(date) : startOfWeek(startOfMonth(date));
  const days = Array.from({ length: vue === "jour" ? 1 : vue === "semaine" ? 7 : 42 }, (_, i) => addDays(from, i));
  const [prev, next] = vue === "jour" ? [addDays(date, -1), addDays(date, 1)]
    : vue === "semaine" ? [addDays(date, -7), addDays(date, 7)] : [addMonths(date, -1), addMonths(date, 1)];
  const title = vue === "jour" ? fmt(date, { weekday: "long", day: "numeric", month: "long", year: "numeric" })
    : vue === "semaine" ? `Semaine du ${fmt(days[0], { day: "numeric", month: "long" })} au ${fmt(days[6], { day: "numeric", month: "long", year: "numeric" })}`
    : fmt(date, { month: "long", year: "numeric" });

  const sb = await createClient();
  const { data } = await sb.rpc("agenda", { p_from: days[0], p_to: days[days.length - 1] });
  const byDay = new Map<string, AgendaRow[]>();
  for (const a of (data ?? []) as AgendaRow[]) byDay.set(a.day, [...(byDay.get(a.day) ?? []), a]);
  const url = (v: Vue, d: string) => `/agenda?vue=${v}&date=${d}`;

  return (
    <main className="space-y-5">
      <Card className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-2xl font-bold first-letter:uppercase">{title}</h1>
          <Link href={`/agenda/nouveau?date=${vue === "jour" ? date : today}`} className={`${primaryBtn} flex items-center gap-2`}>
            <Plus size={18} aria-hidden /> Nouveau RDV
          </Link>
        </div>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex gap-1">
            <Link href={url(vue, prev)} aria-label="Précédent" className={secondaryBtn}><ChevronLeft size={18} /></Link>
            <Link href={url(vue, today)} className={secondaryBtn}>Aujourd’hui</Link>
            <Link href={url(vue, next)} aria-label="Suivant" className={secondaryBtn}><ChevronRight size={18} /></Link>
          </div>
          <nav className="flex gap-1" aria-label="Affichage">
            {(Object.keys(VUES) as Vue[]).map((v) => (
              <Link key={v} href={url(v, date)} aria-current={v === vue ? "page" : undefined}
                className={`px-3 py-2 text-sm font-medium ${v === vue ? "bg-ink text-bg" : "bg-surface text-muted hover:text-ink"}`}>{VUES[v]}</Link>
            ))}
          </nav>
        </div>
        <Notice erreur={sp.erreur} info={sp.info} />
      </Card>

      {vue === "mois" ? (
        <Card className="p-2 md:p-3">
          <div className="grid grid-cols-7 text-center text-xs font-semibold text-muted">
            {["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"].map((d) => <span key={d} className="py-2">{d}</span>)}
          </div>
          <div className="grid grid-cols-7 gap-px bg-line">
            {days.map((d) => {
              const list = byDay.get(d) ?? [];
              return (
                <Link key={d} href={url("jour", d)} className={`min-h-20 bg-bg p-1.5 text-left hover:bg-surface md:min-h-28 ${d.slice(0, 7) !== date.slice(0, 7) ? "opacity-40" : ""}`}>
                  <span className={`inline-block px-1.5 text-sm font-semibold ${d === today ? "bg-accent-2 text-black" : ""}`}>{Number(d.slice(8))}</span>
                  <span className="mt-1 hidden space-y-0.5 md:block">
                    {list.slice(0, 3).map((a) => (
                      <span key={a.id} className={`block truncate px-1 text-xs ${STATUS_CLS[a.status]}`}>{a.start_time} {a.customer_name}</span>
                    ))}
                    {list.length > 3 && <span className="block px-1 text-xs text-muted">+{list.length - 3}</span>}
                  </span>
                  {list.length > 0 && <span className="mt-1 block text-xs text-muted md:hidden">{list.length} RDV</span>}
                </Link>
              );
            })}
          </div>
        </Card>
      ) : (
        <TimeGrid days={days} byDay={byDay} today={today} nowMin={toMin(nowTimeIn(session.organization!.timezone))} />
      )}
    </main>
  );
}
