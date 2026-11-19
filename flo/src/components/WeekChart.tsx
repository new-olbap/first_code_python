"use client";
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis } from "recharts";
import { week } from "@/lib/demo";

export default function WeekChart() {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={week} barGap={4}>
        <defs>
          <linearGradient id="coral" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--accent)" />
            <stop offset="100%" stopColor="var(--accent-2)" />
          </linearGradient>
        </defs>
        <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: "var(--muted)", fontSize: 12 }} />
        <Tooltip
          cursor={{ fill: "rgb(255 255 255 / 0.5)" }}
          contentStyle={{ borderRadius: 16, border: "none", boxShadow: "0 8px 30px rgb(0 0 0 / .08)" }}
        />
        <Bar dataKey="rdv" name="Rendez-vous" fill="url(#coral)" radius={[10, 10, 10, 10]} />
        <Bar dataKey="annules" name="Annulés" fill="#e8cfc8" radius={[10, 10, 10, 10]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
