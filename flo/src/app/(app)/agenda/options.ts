import type { SupabaseClient } from "@supabase/supabase-js";

type Option = [string, string];

// Listes du formulaire de rendez-vous (clients et prestations actifs).
export async function formOptions(sb: SupabaseClient) {
  const [{ data: c }, { data: s }] = await Promise.all([
    sb.from("customers").select("id, first_name, last_name").is("archived_at", null).order("last_name").limit(500),
    sb.from("services").select("id, name, duration_minutes").is("archived_at", null).order("name"),
  ]);
  return {
    customers: (c ?? []).map((x): Option => [x.id, [x.first_name, x.last_name].filter(Boolean).join(" ")]),
    services: (s ?? []).map((x): Option => [x.id, `${x.name} (${x.duration_minutes} min)`]),
  };
}
