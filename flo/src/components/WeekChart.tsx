"use client";
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis } from "recharts";
import { week } from "@/lib/demo";

export default function WeekChart() {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={week} barGap={4}>
        <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: "var(--muted)", fontSize: 12 }} />
        <Tooltip
          cursor={{ fill: "rgb(255 255 255 / 0.05)" }}
          contentStyle={{ borderRadius: 16, border: "1px solid rgb(255 255 255 / .12)", background: "#141414", color: "#f5f5f5" }}
        />
        <Bar dataKey="rdv" name="Rendez-vous" fill="var(--accent)" radius={0} />
        <Bar dataKey="annules" name="Annulés" fill="#3a3a3a" radius={0} />
      </BarChart>
    </ResponsiveContainer>
  );
}
