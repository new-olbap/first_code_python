import type { SupabaseClient } from "@supabase/supabase-js";
import type { Role } from "@/lib/supabase/server";

export type Member = { user_id: string; role: Role; name: string };

// Membres de l'entreprise avec leur prénom (memberships et profiles ne sont pas liés directement).
export async function getTeam(sb: SupabaseClient): Promise<Member[]> {
  const [{ data: m }, { data: p }] = await Promise.all([
    sb.from("memberships").select("user_id, role"),
    sb.from("profiles").select("id, first_name"),
  ]);
  const names = new Map((p ?? []).map((x) => [x.id as string, (x.first_name as string | null) ?? ""]));
  return (m ?? []).map((x) => ({ user_id: x.user_id, role: x.role, name: names.get(x.user_id) || "Sans nom" }));
}

export const ROLE_LABEL: Record<Role, string> = { owner: "Propriétaire", admin: "Administrateur", member: "Collaborateur" };
