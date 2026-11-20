import { cache } from "react";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";

export async function createClient() {
  const store = await cookies();
  return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => store.getAll(),
      setAll: (list) => {
        try {
          list.forEach(({ name, value, options }) => store.set(name, value, options));
        } catch {
          // Appelé depuis un Server Component : le middleware rafraîchit déjà la session.
        }
      },
    },
  });
}

export type Role = "owner" | "admin" | "member";

// Utilisateur connecté + son entreprise, mis en cache pour la durée d'une requête.
export const getSession = cache(async () => {
  const sb = await createClient();
  // Vérifie la signature du jeton localement (clé publique du projet) : pas d'aller-retour vers Supabase.
  const { data } = await sb.auth.getClaims();
  const id = data?.claims?.sub;
  if (!id) return null;
  const user = { id };
  const [{ data: profile }, { data: membership }] = await Promise.all([
    sb.from("profiles").select("first_name").eq("id", user.id).maybeSingle(),
    // shortcut: une seule entreprise par utilisateur ; ajouter un sélecteur d'entreprise si besoin.
    sb.from("memberships").select("role, organization:organizations(id, name, timezone)").eq("user_id", user.id).limit(1).maybeSingle(),
  ]);
  return {
    user,
    firstName: (profile?.first_name as string | null) ?? "",
    role: (membership?.role as Role | undefined) ?? null,
    organization: (membership?.organization as unknown as { id: string; name: string; timezone: string } | null) ?? null,
  };
});
