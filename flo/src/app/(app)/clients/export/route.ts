import { createClient, getSession } from "@/lib/supabase/server";

// Tous les clients en CSV pour Excel (point-virgule, BOM UTF-8 pour les accents). Réimportable dans FLO.
export async function GET() {
  if (!(await getSession())?.organization) return new Response("Non connecté", { status: 401 });
  const sb = await createClient();
  const { data } = await sb.from("customers").select("first_name, last_name, phone, email, address, notes, kind, archived_at, created_at").order("last_name").range(0, 49999);
  // Une valeur qui commence par = @ ou +/- suivi de texte serait exécutée comme formule par Excel : on la neutralise.
  // shortcut: les numéros « +33 … » restent tels quels (chiffre après le +).
  const cell = (v: unknown) => { const s = String(v ?? ""); return `"${(/^([=@\t\r]|[+-](?![\d\s(]))/.test(s) ? "'" + s : s).replace(/"/g, '""')}"`; };
  const head = ["Prénom", "Nom", "Téléphone", "E-mail", "Adresse", "Notes", "Type", "Archivé", "Créé le"];
  const rows = (data ?? []).map((c) => [c.first_name, c.last_name, c.phone, c.email, c.address, c.notes, c.kind, c.archived_at ? "oui" : "", c.created_at?.slice(0, 10)].map(cell).join(";"));
  return new Response("﻿" + [head.map(cell).join(";"), ...rows].join("\r\n") + "\r\n", {
    headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="clients-flo-${new Date().toISOString().slice(0, 10)}.csv"` },
  });
}
