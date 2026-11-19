"use server";
import { redirect } from "next/navigation";
import { createClient, getSession } from "@/lib/supabase/server";
import { go, isEmail, isPhone, isUuid, str } from "@/lib/form";

function parseCustomer(fd: FormData) {
  const c = {
    kind: str(fd, "kind") === "prospect" ? "prospect" : "client",
    first_name: str(fd, "first_name", 80) || null,
    last_name: str(fd, "last_name", 80) || null,
    email: str(fd, "email", 254).toLowerCase() || null,
    phone: str(fd, "phone", 30) || null,
    address: str(fd, "address", 300) || null,
    notes: str(fd, "notes", 5000) || null,
  };
  const error = !c.first_name && !c.last_name ? "Indique au moins un prénom ou un nom."
    : c.email && !isEmail(c.email) ? "Adresse e-mail invalide."
    : c.phone && !isPhone(c.phone) ? "Numéro de téléphone invalide."
    : null;
  return { c, error };
}

export async function createCustomer(fd: FormData) {
  const session = await getSession();
  if (!session?.organization) redirect("/connexion");
  const { c, error } = parseCustomer(fd);
  if (error) go("/clients?nouveau=1", "erreur", error);
  const sb = await createClient();
  const { data, error: e } = await sb.from("customers").insert({ ...c, organization_id: session.organization.id }).select("id").single();
  if (e || !data) go("/clients?nouveau=1", "erreur", "Enregistrement impossible, réessaie.");
  go(`/clients/${data.id}`, "info", "Fiche créée.");
}

export async function updateCustomer(fd: FormData) {
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/clients");
  const { c, error } = parseCustomer(fd);
  if (error) go(`/clients/${id}`, "erreur", error);
  const sb = await createClient();
  const { data } = await sb.from("customers").update(c).eq("id", id).select("id");
  if (!data?.length) go(`/clients/${id}`, "erreur", "Modification impossible.");
  go(`/clients/${id}`, "info", "Modifications enregistrées.");
}

export async function setCustomerArchived(fd: FormData) {
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/clients");
  const archive = str(fd, "archive") === "1";
  const sb = await createClient();
  const { data } = await sb.from("customers").update({ archived_at: archive ? new Date().toISOString() : null }).eq("id", id).select("id");
  if (!data?.length) go(`/clients/${id}`, "erreur", "Action impossible.");
  go(`/clients/${id}`, "info", archive ? "Fiche archivée." : "Fiche restaurée.");
}
