"use server";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

const go = (path: string, key: "erreur" | "info", msg: string): never =>
  redirect(`${path}?${key}=${encodeURIComponent(msg)}`);
const str = (fd: FormData, k: string) => String(fd.get(k) ?? "").trim();
const origin = async () => (await headers()).get("origin") ?? "";

export async function signIn(fd: FormData) {
  const sb = await createClient();
  const { error } = await sb.auth.signInWithPassword({ email: str(fd, "email"), password: String(fd.get("password") ?? "") });
  if (error) {
    go("/connexion", "erreur",
      error.code === "invalid_credentials" ? "E-mail ou mot de passe incorrect."
      : error.code === "email_not_confirmed" ? "Confirme d’abord ton adresse e-mail (lien reçu par mail)."
      : "Connexion impossible pour le moment, réessaie dans un instant.");
  }
  redirect("/");
}

export async function signUp(fd: FormData) {
  const firstName = str(fd, "first_name");
  const password = String(fd.get("password") ?? "");
  if (!firstName || firstName.length > 80) go("/inscription", "erreur", "Indique ton prénom.");
  if (password.length < 8) go("/inscription", "erreur", "Le mot de passe doit faire au moins 8 caractères.");

  const sb = await createClient();
  const { data, error } = await sb.auth.signUp({
    email: str(fd, "email"),
    password,
    options: { data: { first_name: firstName }, emailRedirectTo: `${await origin()}/auth/callback?next=/bienvenue` },
  });
  if (error) go("/inscription", "erreur", error.code === "user_already_exists" ? "Un compte existe déjà avec cet e-mail." : "Inscription impossible. Vérifie l’e-mail et le mot de passe.");
  if (!data.session) go("/connexion", "info", "Compte créé ! Clique sur le lien reçu par e-mail pour l’activer.");
  redirect("/bienvenue");
}

export async function forgotPassword(fd: FormData) {
  const sb = await createClient();
  await sb.auth.resetPasswordForEmail(str(fd, "email"), {
    redirectTo: `${await origin()}/auth/callback?next=/nouveau-mot-de-passe`,
  });
  // Même message que le compte existe ou non (ne pas révéler les adresses inscrites).
  go("/mot-de-passe-oublie", "info", "Si un compte existe, un lien de réinitialisation vient d’être envoyé.");
}

export async function updatePassword(fd: FormData) {
  const password = String(fd.get("password") ?? "");
  if (password.length < 8) go("/nouveau-mot-de-passe", "erreur", "Au moins 8 caractères.");
  const sb = await createClient();
  const { error } = await sb.auth.updateUser({ password });
  if (error) go("/nouveau-mot-de-passe", "erreur", "Impossible de changer le mot de passe. Redemande un lien.");
  redirect("/");
}

export async function signOut() {
  const sb = await createClient();
  await sb.auth.signOut();
  redirect("/connexion");
}

export async function createOrganization(fd: FormData) {
  const name = str(fd, "name");
  if (name.length < 2 || name.length > 120) go("/bienvenue", "erreur", "Indique le nom de ton entreprise.");
  const sb = await createClient();
  const { error } = await sb.rpc("create_organization", {
    p_name: name, p_trade: str(fd, "trade").slice(0, 80), p_address: str(fd, "address").slice(0, 300),
  });
  if (error) go("/bienvenue", "erreur", "Création impossible, réessaie.");
  redirect("/");
}
