"use server";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { go, str } from "@/lib/form";
const origin = async () => (await headers()).get("origin") ?? "";
// Lien d'invitation en cours (?invitation=…) : après connexion ou inscription, on y retourne.
const invitation = (fd: FormData) => { const t = str(fd, "invitation"); return /^[0-9a-f]{64}$/.test(t) ? t : null; };
const withInv = (path: string, t: string | null) => (t ? `${path}?invitation=${t}` : path);

export async function signIn(fd: FormData) {
  const inv = invitation(fd);
  const sb = await createClient();
  const { error } = await sb.auth.signInWithPassword({ email: str(fd, "email"), password: String(fd.get("password") ?? "") });
  if (error) {
    go(withInv("/connexion", inv), "erreur",
      error.code === "invalid_credentials" ? "E-mail ou mot de passe incorrect."
      : error.code === "email_not_confirmed" ? "Confirmez d’abord votre adresse e-mail (lien reçu par mail)."
      : "Connexion impossible pour le moment, réessayez dans un instant.");
  }
  redirect(inv ? `/invitation/${inv}` : "/");
}

export async function signUp(fd: FormData) {
  const inv = invitation(fd), next = inv ? `/invitation/${inv}` : "/bienvenue";
  const firstName = str(fd, "first_name");
  const password = String(fd.get("password") ?? "");
  if (!firstName || firstName.length > 80) go(withInv("/inscription", inv), "erreur", "Indiquez votre prénom.");
  if (password.length < 8) go(withInv("/inscription", inv), "erreur", "Le mot de passe doit faire au moins 8 caractères.");

  const sb = await createClient();
  const { data, error } = await sb.auth.signUp({
    email: str(fd, "email"),
    password,
    options: { data: { first_name: firstName }, emailRedirectTo: `${await origin()}/auth/callback?next=${next}` },
  });
  if (error) go(withInv("/inscription", inv), "erreur", error.code === "user_already_exists" ? "Un compte existe déjà avec cet e-mail." : "Inscription impossible. Vérifiez l’e-mail et le mot de passe.");
  if (!data.session) go(withInv("/connexion", inv), "info", "Compte créé ! Cliquez sur le lien reçu par e-mail pour l’activer.");
  redirect(next);
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
  if (error) go("/nouveau-mot-de-passe", "erreur", "Impossible de changer le mot de passe. Demandez un nouveau lien.");
  redirect("/");
}

export async function signOut() {
  const sb = await createClient();
  await sb.auth.signOut();
  redirect("/connexion");
}

export async function createOrganization(fd: FormData) {
  const name = str(fd, "name");
  if (name.length < 2 || name.length > 120) go("/bienvenue", "erreur", "Indiquez le nom de votre entreprise.");
  const sb = await createClient();
  const { error } = await sb.rpc("create_organization", {
    p_name: name, p_trade: str(fd, "trade").slice(0, 80), p_address: str(fd, "address").slice(0, 300), p_code: str(fd, "code").slice(0, 20),
  });
  if (error) go("/bienvenue", "erreur", error.code === "FL010" ? "Code d’accès invalide ou déjà utilisé. Vérifiez le code reçu après votre commande." : "Création impossible, veuillez réessayer.");
  redirect("/");
}

export async function acceptInvitation(fd: FormData) {
  const inv = invitation(fd);
  if (!inv) redirect("/");
  const sb = await createClient();
  const { error } = await sb.rpc("accept_invitation", { p_token: inv });
  if (error) go(`/invitation/${inv}`, "erreur", error.code === "FL004" ? "Ce compte appartient déjà à une entreprise."
    : error.code === "P0002" ? "Cette invitation est expirée ou a déjà été utilisée : demandez un nouveau lien." : "Impossible de rejoindre l’entreprise, réessayez.");
  redirect("/");
}
