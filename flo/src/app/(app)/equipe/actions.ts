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
