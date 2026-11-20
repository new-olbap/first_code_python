"use server";
import { createClient, getSession } from "@/lib/supabase/server";
import { go } from "@/lib/form";

export async function setBookingEnabled(fd: FormData) {
  const session = await getSession();
  if (session?.role !== "owner" && session?.role !== "admin") go("/reservations", "erreur", "Seuls le propriétaire et les administrateurs peuvent modifier ce réglage.");
  const on = fd.get("on") === "1";
  const sb = await createClient();
  const { data } = await sb.from("organizations").update({ booking_enabled: on }).eq("id", session.organization!.id).select("id");
  if (!data?.length) go("/reservations", "erreur", "Modification impossible.");
  go("/reservations", "info", on ? "Réservation en ligne ouverte." : "Réservation en ligne fermée : la page n’est plus accessible.");
}
