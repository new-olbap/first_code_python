"use server";
import { redirect } from "next/navigation";
import { createClient, getSession } from "@/lib/supabase/server";
import { go, str } from "@/lib/form";

async function orgId() {
  const s = await getSession();
  if (!s?.organization) redirect("/connexion");
  if (s.role === "member") go("/parametres", "erreur", "Seuls le propriétaire et les administrateurs modifient l’entreprise.");
  return s.organization.id;
}

export async function updateOrganization(fd: FormData) {
  const id = await orgId();
  const name = str(fd, "name", 120);
  if (name.length < 2) go("/parametres", "erreur", "Indiquez le nom de l’entreprise.");
  const sb = await createClient();
  const { data } = await sb.from("organizations").update({ name, trade: str(fd, "trade", 80) || null, address: str(fd, "address", 300) || null }).eq("id", id).select("id");
  if (!data?.length) go("/parametres", "erreur", "Modification impossible.");
  go("/parametres", "info", "Entreprise mise à jour.");
}

export async function updateSlug(fd: FormData) {
  const id = await orgId();
  // Même règle que la base : minuscules, chiffres et tirets (3 à 60 caractères).
  const slug = str(fd, "slug", 60).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  if (!/^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$/.test(slug)) go("/parametres", "erreur", "Adresse invalide : 3 à 60 caractères, lettres, chiffres et tirets.");
  const sb = await createClient();
  const { data, error } = await sb.from("organizations").update({ slug }).eq("id", id).select("id");
  if (error?.code === "23505") go("/parametres", "erreur", "Cette adresse est déjà prise : choisissez-en une autre.");
  if (error || !data?.length) go("/parametres", "erreur", "Modification impossible.");
  go("/parametres", "info", "Adresse de réservation modifiée. Pensez à mettre à jour les liens déjà partagés.");
}

export async function updateProfile(fd: FormData) {
  const s = await getSession();
  if (!s) redirect("/connexion");
  const first = str(fd, "first_name", 80);
  if (!first) go("/parametres", "erreur", "Indiquez votre prénom.");
  const sb = await createClient();
  const { data } = await sb.from("profiles").update({ first_name: first }).eq("id", s.user.id).select("id");
  if (!data?.length) go("/parametres", "erreur", "Modification impossible.");
  go("/parametres", "info", "Profil mis à jour.");
}
