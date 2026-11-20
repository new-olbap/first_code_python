import Link from "next/link";
import Card from "@/components/Card";
import { addDays, fmt, startOfMonth, startOfWeek, todayIn, weekday } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";
import type { AgendaRow } from "../agenda/types";

const PERIODES = { "30j": { label: "30 jours", days: 30 }, "3m": { label: "3 mois", days: 91 }, "12m": { label: "12 mois", days: 365 } } as const;
type Periode = keyof typeof PERIODES;
const JOURS = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
const euros = (c: number) => (c / 100).toLocaleString("fr-FR", { style: "currency", currency: "EUR", maximumFractionDigits: 0 });
const heures = (m: number) => `${Math.floor(m / 60)} h${m % 60 ? ` ${String(m % 60).padStart(2, "0")}` : ""}`;

// Liste de barres horizontales triées (prestations, équipe, jours).
function Bars({ rows }: { rows: [string, number][] }) {
  const max = Math.max(1, ...rows.map(([, n]) => n));
  if (!rows.length) return <p className="text-sm text-muted">Pas encore de données.</p>;
  return (
    <ul className="space-y-2">
      {rows.map(([label, n]) => (
        <li key={label} className="grid grid-cols-[minmax(0,10rem)_1fr_2.5rem] items-center gap-3 text-sm">
          <span className="truncate">{label}</span>
          <span className="h-2 bg-surface"><span className="block h-full bg-ink" style={{ width: `${(n / max) * 100}%` }} /></span>
          <span className="text-right font-semibold">{n}</span>
        </li>
      ))}
    </ul>
  );
}

export default async function Statistiques({ searchParams }: { searchParams: Promise<{ p?: string }> }) {
  const sp = await searchParams;
  const periode: Periode = sp.p && sp.p in PERIODES ? (sp.p as Periode) : "30j";
  const session = (await getSession())!;
  const today = todayIn(session.organization!.timezone);
  const from = addDays(today, -PERIODES[periode].days + 1);
  const sb = await createClient();
  const [{ data }, { data: svc }, { count: nouveaux }, { data: req }] = await Promise.all([
    sb.rpc("agenda", { p_from: from, p_to: today }),
    sb.from("services").select("id, price_cents"),
    sb.from("customers").select("id", { count: "exact", head: true }).gte("created_at", from),
    sb.from("requests").select("status").eq("source", "booking").gte("created_at", from),
  ]);
  const all = (data ?? []) as AgendaRow[];
  const done = all.filter((a) => a.status !== "cancelled");
  const annules = all.length - done.length;
  const prix = new Map((svc ?? []).map((s) => [s.id as string, (s.price_cents as number | null) ?? 0]));
  const ca = done.reduce((s, a) => s + (a.service_id ? prix.get(a.service_id) ?? 0 : 0), 0);
  const minutes = done.reduce((s, a) => s + a.duration_minutes, 0);
  const traitees = (req ?? []).filter((r) => r.status !== "new");
  const acceptees = traitees.filter((r) => r.status === "accepted").length;

  // Évolution : par semaine (30 j / 3 mois) ou par mois (12 mois).
  const parMois = periode === "12m";
  const cle = (d: string) => (parMois ? startOfMonth(d) : startOfWeek(d));
  const buckets: string[] = [];
  for (let d = cle(from); d <= today; d = parMois ? addDays(d, 32).slice(0, 8) + "01" : addDays(d, 7)) buckets.push(d);
  const serie = buckets.map((b) => [b, done.filter((a) => cle(a.day) === b).length] as const);
  const maxSerie = Math.max(1, ...serie.map(([, n]) => n));

  const compte = (f: (a: AgendaRow) => string) => [...done.reduce((m, a) => m.set(f(a), (m.get(f(a)) ?? 0) + 1), new Map<string, number>())].sort((x, y) => y[1] - x[1]);
  const kpis = [
    { label: "Rendez-vous", value: String(done.length) },
    { label: "Heures d’intervention", value: heures(minutes) },
    { label: "Chiffre d’affaires estimé", value: euros(ca), note: "d’après le prix des prestations" },
    { label: "Annulations", value: all.length ? `${Math.round((100 * annules) / all.length)} %` : "—", note: `${annules} sur ${all.length}` },
    { label: "Nouveaux clients", value: String(nouveaux ?? 0) },
    { label: "Demandes en ligne acceptées", value: traitees.length ? `${Math.round((100 * acceptees) / traitees.length)} %` : "—", note: `${acceptees} sur ${traitees.length} traitées` },
  ];

  return (
    <main className="space-y-5">
      <Card className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">Statistiques</h1>
        <nav className="flex gap-1" aria-label="Période">
          {(Object.keys(PERIODES) as Periode[]).map((p) => (
            <Link key={p} href={`/statistiques?p=${p}`} aria-current={p === periode ? "page" : undefined}
              className={`px-3 py-2 text-sm font-medium ${p === periode ? "bg-ink text-bg" : "bg-surface text-muted hover:text-ink"}`}>{PERIODES[p].label}</Link>
          ))}
        </nav>
      </Card>

      <div className="grid grid-cols-2 gap-5 md:grid-cols-3">
        {kpis.map((k) => (
          <Card key={k.label} className="p-4 md:p-5">
            <p className="text-3xl font-bold">{k.value}</p>
            <p className="mt-1 text-sm text-muted">{k.label}</p>
            {k.note && <p className="mt-1 text-xs text-muted">{k.note}</p>}
          </Card>
        ))}
      </div>

      <Card className="space-y-4">
        <h2 className="font-semibold">Rendez-vous par {parMois ? "mois" : "semaine"}</h2>
        <div className="flex h-48 items-end gap-1" role="img" aria-label={`Rendez-vous par ${parMois ? "mois" : "semaine"}`}>
          {serie.map(([b, n]) => (
            <div key={b} className="group relative flex h-full flex-1 flex-col justify-end" title={`${parMois ? fmt(b, { month: "long", year: "numeric" }) : `Semaine du ${fmt(b, { day: "numeric", month: "short" })}`} : ${n}`}>
              <span className="mb-1 text-center text-xs text-muted opacity-0 group-hover:opacity-100">{n}</span>
              <span className="block bg-ink transition-[height]" style={{ height: `${(n / maxSerie) * 85}%`, minHeight: n ? 2 : 0 }} />
            </div>
          ))}
        </div>
        <div className="flex justify-between text-xs text-muted">
          <span>{parMois ? fmt(buckets[0], { month: "short", year: "numeric" }) : fmt(buckets[0], { day: "numeric", month: "short" })}</span>
          <span>{parMois ? fmt(today, { month: "short", year: "numeric" }) : fmt(today, { day: "numeric", month: "short" })}</span>
        </div>
      </Card>

      <div className="grid gap-5 lg:grid-cols-3">
        <Card className="space-y-3"><h2 className="font-semibold">Par prestation</h2><Bars rows={compte((a) => a.service_name ?? "Sans prestation")} /></Card>
        <Card className="space-y-3"><h2 className="font-semibold">Par personne</h2><Bars rows={compte((a) => a.staff_name ?? "—")} /></Card>
        <Card className="space-y-3">
          <h2 className="font-semibold">Par jour de la semaine</h2>
          <Bars rows={JOURS.map((j, i) => [j, done.filter((a) => weekday(a.day) === i + 1).length] as [string, number]).filter(([, n]) => n > 0)} />
        </Card>
      </div>
    </main>
  );
}
