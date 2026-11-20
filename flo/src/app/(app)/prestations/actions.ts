"use server";
import { redirect } from "next/navigation";
import { createClient, getSession } from "@/lib/supabase/server";
import { go, isUuid, parsePrice, str } from "@/lib/form";

function parseService(fd: FormData) {
  const repeat = str(fd, "repeat");
  const s = { name: str(fd, "name", 120), duration_minutes: Number(str(fd, "duration")), price_cents: parsePrice(str(fd, "price", 20)), repeat_months: repeat ? Number(repeat) : null };
  const error = s.name.length < 2 ? "Indiquez le nom de la prestation."
    : s.repeat_months !== null && !(Number.isInteger(s.repeat_months) && s.repeat_months >= 1 && s.repeat_months <= 60) ? "Périodicité invalide."
    : !Number.isInteger(s.duration_minutes) || s.duration_minutes < 5 || s.duration_minutes > 1440 ? "Durée invalide (5 min à 24 h)."
    : Number.isNaN(s.price_cents) ? "Prix invalide (ex. 80 ou 80,50)."
    : null;
  return { s, error };
}

async function requireManager() {
  const session = await getSession();
  if (!session?.organization) redirect("/connexion");
  if (session.role === "member") go("/prestations", "erreur", "Seuls le propriétaire et les administrateurs gèrent les prestations.");
  return session.organization.id;
}

export async function createService(fd: FormData) {
  const orgId = await requireManager();
  const { s, error } = parseService(fd);
  if (error) go("/prestations", "erreur", error);
  const sb = await createClient();
  const { error: e } = await sb.from("services").insert({ ...s, organization_id: orgId });
  if (e) go("/prestations", "erreur", "Enregistrement impossible, veuillez réessayer.");
  go("/prestations", "info", "Prestation ajoutée.");
}

export async function updateService(fd: FormData) {
  await requireManager();
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/prestations");
  const { s, error } = parseService(fd);
  if (error) go("/prestations", "erreur", error);
  const sb = await createClient();
  const { data } = await sb.from("services").update(s).eq("id", id).select("id");
  if (!data?.length) go("/prestations", "erreur", "Modification impossible.");
  go("/prestations", "info", "Prestation enregistrée.");
}

export async function setServiceArchived(fd: FormData) {
  await requireManager();
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/prestations");
  const archive = str(fd, "archive") === "1";
  const sb = await createClient();
  const { data } = await sb.from("services").update({ archived_at: archive ? new Date().toISOString() : null }).eq("id", id).select("id");
  if (!data?.length) go("/prestations", "erreur", "Action impossible.");
  go("/prestations", "info", archive ? "Prestation archivée." : "Prestation réactivée.");
}
