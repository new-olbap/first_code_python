import { createClient } from "@/lib/supabase/server";
import { buildIcs, type FeedEvent } from "@/lib/ics";

// Flux d'agenda d'une personne : /cal/<jeton>.ics, relu par Google Agenda, Apple Calendrier, Outlook.
export async function GET(_req: Request, { params }: { params: Promise<{ file: string }> }) {
  const token = (await params).file.replace(/\.ics$/, "");
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(token)) return new Response("Introuvable", { status: 404 });
  const sb = await createClient();
  const { data, error } = await sb.rpc("calendar_feed", { p_token: token });
  if (error) return new Response("Erreur", { status: 500 });
  if (!data) return new Response("Introuvable", { status: 404 });
  const feed = data as { name: string; staff: string; events: FeedEvent[] };
  const name = feed.staff ? `FLO · ${feed.name} (${feed.staff})` : `FLO · ${feed.name}`;
  return new Response(buildIcs(name, feed.events), {
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": 'inline; filename="flo.ics"',
      "Cache-Control": "private, no-store",
      "X-Robots-Tag": "noindex",
    },
  });
}
