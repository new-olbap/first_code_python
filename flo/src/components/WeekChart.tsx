"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

export type DayStat = { day: string; short: string; long: string; rdv: number; annules: number };

// Graphique des rendez-vous : 7 ou 30 derniers jours ; un clic sur une barre ouvre ce jour dans l'agenda.
export default function WeekChart({ data }: { data: DayStat[] }) {
  const [period, setPeriod] = useState<7 | 30>(7);
  const router = useRouter();
  const shown = data.slice(-period);
  const total = shown.reduce((s, d) => s + d.rdv, 0);

  return (
    <div>
      <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
        <p className="text-sm text-muted"><span className="text-2xl font-bold text-ink">{total}</span> rendez-vous sur {period} jours</p>
        <div className="flex" role="group" aria-label="Période">
          {([7, 30] as const).map((p) => (
            <button key={p} onClick={() => setPeriod(p)} aria-pressed={period === p}
              className={`px-3 py-1.5 text-sm font-medium transition-colors ${period === p ? "bg-ink text-bg" : "bg-surface text-muted hover:text-ink"}`}>
              {p} jours
            </button>
          ))}
        </div>
      </div>
      <ResponsiveContainer width="100%" height={220}>
        <BarChart data={shown} barGap={2} onClick={(e) => {
          const day = shown[Number(e?.activeTooltipIndex)]?.day; // index de la barre survolée
          if (day) router.push(`/agenda?vue=jour&date=${day}`);
        }}>
          <XAxis dataKey="short" axisLine={false} tickLine={false} interval={period === 7 ? 0 : 4} tick={{ fill: "var(--muted)", fontSize: 12 }} />
          <YAxis allowDecimals={false} axisLine={false} tickLine={false} width={24} tick={{ fill: "var(--muted)", fontSize: 12 }} />
          <Tooltip
            cursor={{ fill: "rgb(255 255 255 / 0.06)" }}
            labelFormatter={(_, p) => (p?.[0]?.payload as DayStat | undefined)?.long ?? ""}
            contentStyle={{ borderRadius: 0, border: "1px solid rgb(255 255 255 / .12)", background: "#141414", color: "#f5f5f5" }}
          />
          <Bar dataKey="rdv" name="Rendez-vous" fill="var(--accent)" radius={0} className="cursor-pointer" animationDuration={500} />
          <Bar dataKey="annules" name="Annulés" fill="#3a3a3a" radius={0} className="cursor-pointer" animationDuration={500} />
        </BarChart>
      </ResponsiveContainer>
      <p className="mt-1 text-xs text-muted">Cliquez sur une barre pour ouvrir la journée dans l’agenda.</p>
    </div>
  );
}
