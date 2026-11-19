import Link from "next/link";
import { addDays, fmt, startOfMonth, weekday } from "@/lib/dates";

// Mois en cours ; `today` est la date du jour dans le fuseau de l'entreprise (AAAA-MM-JJ).
export default function MiniCalendar({ today, busyDays }: { today: string; busyDays: Set<string> }) {
  const first = startOfMonth(today);
  const offset = weekday(first) - 1; // lundi = 0
  const days: string[] = [];
  for (let d = first; d.slice(0, 7) === first.slice(0, 7); d = addDays(d, 1)) days.push(d);

  return (
    <div>
      <h2 className="mb-3 font-semibold first-letter:uppercase">{fmt(today, { month: "long", year: "numeric" })}</h2>
      <div className="grid grid-cols-7 gap-1 text-center text-xs">
        {["L", "M", "M", "J", "V", "S", "D"].map((d, i) => (
          <span key={i} className="pb-1 font-medium text-muted">{d}</span>
        ))}
        {Array.from({ length: offset }, (_, i) => <span key={`v${i}`} />)}
        {days.map((d) => {
          const isToday = d === today;
          return (
            <Link
              key={d}
              href={`/agenda?vue=jour&date=${d}`}
              aria-label={`${fmt(d, { weekday: "long", day: "numeric", month: "long" })}${busyDays.has(d) ? ", rendez-vous prévus" : ""}`}
              className={`relative grid aspect-square place-items-center text-sm transition-colors ${isToday ? "bg-accent-2 font-bold text-black" : "hover:bg-white/10"}`}
            >
              {Number(d.slice(8))}
              {busyDays.has(d) && !isToday && <span className="absolute bottom-1 h-1 w-1 rounded-full bg-accent-2" />}
            </Link>
          );
        })}
      </div>
    </div>
  );
}
