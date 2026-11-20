import Link from "next/link";
import { fmt } from "@/lib/dates";
import { layoutDay } from "./grid";
import type { AgendaRow, Status } from "./types";

const HOUR = 56; // hauteur d'une heure en pixels
const BLOCK: Record<Status, string> = {
  confirmed: "bg-ink text-bg",
  pending: "bg-accent-2 text-black",
  cancelled: "border border-line bg-surface text-muted line-through",
};

// Grille horaire façon Google Agenda (jour ou semaine). Un clic sur un créneau vide ouvre « Nouveau rendez-vous ».
export default function TimeGrid({ days, byDay, today, nowMin }: {
  days: string[]; byDay: Map<string, AgendaRow[]>; today: string; nowMin: number;
}) {
  const placed = new Map(days.map((d) => [d, layoutDay(byDay.get(d) ?? [])]));
  const all = [...placed.values()].flat();
  const first = Math.min(7, ...all.map((p) => Math.floor(p.start / 60)));
  const last = Math.max(20, ...all.map((p) => Math.ceil(p.end / 60)));
  const hours = Array.from({ length: last - first }, (_, i) => first + i);
  const cols = { gridTemplateColumns: `3.5rem repeat(${days.length}, minmax(0, 1fr))` };
  const y = (min: number) => ((min - first * 60) * HOUR) / 60;

  return (
    <section className="glass overflow-x-auto p-0">
      <div className={days.length > 1 ? "min-w-[760px]" : ""}>
        <div className="sticky top-0 z-10 grid border-b border-line bg-[#111]" style={cols}>
          <span />
          {days.map((d) => (
            <Link key={d} href={`/agenda?vue=jour&date=${d}`} className="flex flex-col items-center gap-0.5 border-l border-line py-2 hover:bg-surface">
              <span className={`text-xs font-semibold uppercase ${d === today ? "text-accent-2" : "text-muted"}`}>{fmt(d, { weekday: "short" })}</span>
              <span className={`grid h-9 min-w-9 place-items-center px-1 text-xl font-bold ${d === today ? "bg-accent-2 text-black" : ""}`}>{Number(d.slice(8))}</span>
            </Link>
          ))}
        </div>
        <div className="grid" style={cols}>
          <div className="relative" style={{ height: hours.length * HOUR }}>
            {hours.map((h) => (
              <span key={h} className="absolute right-2 -translate-y-1/2 text-xs text-muted" style={{ top: (h - first) * HOUR }}>{h > first ? `${h}:00` : ""}</span>
            ))}
          </div>
          {days.map((d) => (
            <div key={d} className="relative border-l border-line" style={{ height: hours.length * HOUR }}>
              {hours.map((h) => (
                <Link key={h} href={`/agenda/nouveau?date=${d}&time=${String(h).padStart(2, "0")}:00`}
                  aria-label={`Nouveau rendez-vous le ${fmt(d, { weekday: "long", day: "numeric", month: "long" })} à ${h} h`}
                  className="absolute inset-x-0 border-t border-line/60 hover:bg-white/5" style={{ top: (h - first) * HOUR, height: HOUR }} />
              ))}
              {d === today && nowMin >= first * 60 && nowMin <= last * 60 && (
                <div aria-hidden className="pointer-events-none absolute inset-x-0 z-20 h-0.5 bg-accent-2" style={{ top: y(nowMin) }}>
                  <span className="absolute -left-1 -top-1 h-2.5 w-2.5 rounded-full bg-accent-2" />
                </div>
              )}
              {placed.get(d)!.map(({ e: a, start, end, lane, lanes }) => {
                const height = Math.max(((end - start) * HOUR) / 60, 22);
                return (
                  <Link key={a.id} href={`/agenda/${a.id}`}
                    className={`absolute z-10 overflow-hidden px-1.5 py-1 text-xs leading-tight transition hover:z-30 hover:brightness-90 ${BLOCK[a.status]}`}
                    style={{ top: y(start) + 1, height: height - 2, left: `calc(${(lane / lanes) * 100}% + 2px)`, width: `calc(${100 / lanes}% - 4px)` }}>
                    <span className="block truncate font-semibold">{a.customer_name ?? "Sans client"}</span>
                    {height >= 40 && <span className="block truncate opacity-80">{a.start_time} – {a.end_time}</span>}
                    {height >= 58 && <span className="block truncate opacity-80">{[a.service_name, a.staff_name].filter(Boolean).join(" · ")}</span>}
                  </Link>
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
