"use server";
import { redirect } from "next/navigation";
import { createClient, getSession } from "@/lib/supabase/server";
import { go, isUuid, str } from "@/lib/form";
import { isIsoDate, isTime } from "@/lib/dates";

const NOT_ALLOWED = "Vous ne pouvez modifier que vos propres horaires et absences.";

export async function saveWeeklyHours(fd: FormData) {
  const user = str(fd, "user");
  if (!isUuid(user)) redirect("/equipe");
  const rules = [];
  for (let d = 1; d <= 7; d++) {
    if (!fd.get(`on_${d}`)) continue;
    const start = str(fd, `start_${d}`), end = str(fd, `end_${d}`);
    if (!isTime(start) || !isTime(end) || end <= start) go("/equipe", "erreur", "Horaires invalides : l’heure de fin doit être après l’heure de début.");
    rules.push({ weekday: d, start_time: start, end_time: end });
  }
  const sb = await createClient();
  const { error } = await sb.rpc("set_weekly_hours", { p_user: user, p_rules: rules });
  if (error) go("/equipe", "erreur", error.code === "42501" ? NOT_ALLOWED : "Enregistrement impossible, veuillez réessayer.");
  go("/equipe", "info", "Horaires enregistrés.");
}

export async function addTimeOff(fd: FormData) {
  const session = await getSession();
  if (!session?.organization) redirect("/connexion");
  const user = str(fd, "user"), from = str(fd, "from"), to = str(fd, "to"), reason = str(fd, "reason", 200);
  if (!isUuid(user) || !isIsoDate(from) || !isIsoDate(to) || to < from) go("/equipe", "erreur", "Dates d’absence invalides.");
  const sb = await createClient();
  const { error } = await sb.from("time_off").insert({ organization_id: session.organization.id, user_id: user, starts_on: from, ends_on: to, reason: reason || null });
  if (error) go("/equipe", "erreur", error.code === "42501" ? NOT_ALLOWED : "Enregistrement impossible, veuillez réessayer.");
  go("/equipe", "info", "Absence enregistrée.");
}

export async function deleteTimeOff(fd: FormData) {
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/equipe");
  const sb = await createClient();
  const { data } = await sb.from("time_off").delete().eq("id", id).select("id");
  if (!data?.length) go("/equipe", "erreur", NOT_ALLOWED);
  go("/equipe", "info", "Absence supprimée.");
}

const TEAM_ERRORS: Record<string, string> = {
  FL005: "L’entreprise doit garder au moins un propriétaire : nommez d’abord quelqu’un d’autre propriétaire.",
  "23503": "Cette personne a des rendez-vous dans l’agenda : réattribuez-les à quelqu’un d’autre avant de la retirer.",
};

export async function createInvitation(fd: FormData) {
  const session = await getSession();
  if (!session?.organization) redirect("/connexion");
  const role = str(fd, "role") === "admin" ? "admin" : "member";
  const sb = await createClient();
  const { error } = await sb.from("invitations").insert({ organization_id: session.organization.id, role, created_by: session.user.id });
  if (error) go("/equipe", "erreur", error.code === "42501" ? "Seuls le propriétaire et les administrateurs peuvent inviter." : "Impossible de créer l’invitation, veuillez réessayer.");
  go("/equipe", "info", "Invitation créée : copiez le lien ci-dessous et envoyez-le (SMS, e-mail, WhatsApp…). Il est valable 7 jours.");
}

export async function revokeInvitation(fd: FormData) {
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/equipe");
  const sb = await createClient();
  await sb.from("invitations").delete().eq("id", id);
  go("/equipe", "info", "Invitation annulée : le lien ne fonctionne plus.");
}

export async function setMemberRole(fd: FormData) {
  const user = str(fd, "user"), role = str(fd, "role");
  if (!isUuid(user) || !["owner", "admin", "member"].includes(role)) redirect("/equipe");
  const sb = await createClient();
  const { data, error } = await sb.from("memberships").update({ role }).eq("user_id", user).select("user_id");
  if (error || !data?.length) go("/equipe", "erreur", TEAM_ERRORS[error?.code ?? ""] ?? "Vous n’avez pas le droit de modifier ce rôle.");
  go("/equipe", "info", "Rôle modifié.");
}

export async function removeMember(fd: FormData) {
  const user = str(fd, "user");
  if (!isUuid(user)) redirect("/equipe");
  const sb = await createClient();
  const { data, error } = await sb.from("memberships").delete().eq("user_id", user).select("user_id");
  if (error || !data?.length) go("/equipe", "erreur", TEAM_ERRORS[error?.code ?? ""] ?? "Vous n’avez pas le droit de retirer cette personne.");
  go("/equipe", "info", "Personne retirée de l’entreprise.");
}
