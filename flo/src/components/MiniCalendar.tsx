import { busyDays } from "@/lib/demo";

// shortcut: uses the server's clock/timezone, switch to the organization's timezone once Supabase holds it.
export default function MiniCalendar({ today = new Date() }: { today?: Date }) {
  const y = today.getFullYear(), m = today.getMonth();
  const offset = (new Date(y, m, 1).getDay() + 6) % 7; // lundi = 0
  const days = new Date(y, m + 1, 0).getDate();
  const cells = [...Array(offset).fill(null), ...Array.from({ length: days }, (_, d) => d + 1)];
  const title = today.toLocaleDateString("fr-FR", { month: "long", year: "numeric" });

  return (
    <div>
      <h2 className="mb-3 font-semibold capitalize">{title}</h2>
      <div className="grid grid-cols-7 gap-1 text-center text-xs">
        {["L", "M", "M", "J", "V", "S", "D"].map((d, i) => (
          <span key={i} className="pb-1 font-medium text-muted">{d}</span>
        ))}
        {cells.map((d, i) => {
          const isToday = d === today.getDate();
          return (
            <span
              key={i}
              className={`relative grid aspect-square place-items-center rounded-xl text-sm
                ${isToday ? "bg-gradient-to-br from-accent-ink to-accent-2 font-bold text-white shadow-md shadow-accent/40" : d ? "hover:bg-white/70" : ""}`}
            >
              {d}
              {d && busyDays.includes(d) && !isToday && (
                <span className="absolute bottom-1 h-1 w-1 rounded-full bg-accent-2" />
              )}
            </span>
          );
        })}
      </div>
    </div>
  );
}
