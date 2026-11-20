import { isUuid } from "@/lib/form";
import { createClient } from "@/lib/supabase/server";

// Toutes les données d'un client (droit d'accès / portabilité RGPD), en JSON lisible.
export async function GET(_: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!isUuid(id)) return new Response("Introuvable", { status: 404 });
  const sb = await createClient();
  const { data: client } = await sb.from("customers").select("first_name, last_name, phone, email, address, notes, kind, archived_at, created_at").eq("id", id).maybeSingle();
  if (!client) return new Response("Introuvable", { status: 404 });
  const [{ data: rdv }, { data: demandes }] = await Promise.all([
    sb.rpc("agenda", { p_customer: id }),
    sb.from("requests").select("source, status, message, created_at").eq("customer_id", id),
  ]);
  const rendez_vous = ((rdv ?? []) as Record<string, unknown>[]).map((a) => ({ date: a.day, debut: a.start_time, fin: a.end_time, statut: a.status, prestation: a.service_name, avec: a.staff_name, notes: a.notes }));
  return new Response(JSON.stringify({ exporte_le: new Date().toISOString(), client, rendez_vous, demandes: demandes ?? [] }, null, 2), {
    headers: { "Content-Type": "application/json; charset=utf-8", "Content-Disposition": `attachment; filename="client-${id.slice(0, 8)}.json"` },
  });
}
