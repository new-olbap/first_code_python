"use server";
import { redirect } from "next/navigation";
import { createClient, getSession } from "@/lib/supabase/server";
import { go, isEmail, isPhone, isUuid, str } from "@/lib/form";
import { csvToRecords, decode, dupKeys, parseCsv, toCustomers, vcfToRecords } from "@/lib/import";

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
  const error = !c.first_name && !c.last_name ? "Indiquez le nom du client ou de la société."
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
  if (e || !data) go("/clients?nouveau=1", "erreur", "Enregistrement impossible, veuillez réessayer.");
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

// Import d'un fichier CSV (Excel, Google Contacts…) ou vCard (contacts du téléphone). Les doublons sont ignorés.
export async function importCustomers(fd: FormData) {
  const session = await getSession();
  if (!session?.organization) redirect("/connexion");
  const back = "/clients?import=1";
  const file = fd.get("file");
  if (!(file instanceof File) || file.size === 0) go(back, "erreur", "Choisissez un fichier.");
  if (file.size > 2_000_000) go(back, "erreur", "Fichier trop lourd (2 Mo maximum).");
  const text = decode(await file.arrayBuffer());
  const records = /\.vcf$/i.test(file.name) || /BEGIN:VCARD/i.test(text.slice(0, 500)) ? vcfToRecords(text) : csvToRecords(parseCsv(text));
  if (records.length > 5000) go(back, "erreur", "5 000 fiches maximum par import : découpez le fichier.");
  const { customers, noName, badContact } = toCustomers(records, fd.get("prospects") === "on");
  if (!customers.length) go(back, "erreur", "Aucune fiche lisible. La 1re ligne doit contenir les titres des colonnes (Nom, Prénom, Téléphone…).");

  const sb = await createClient();
  // shortcut: compare aux 10 000 premières fiches existantes ; au-delà, des doublons peuvent passer.
  const { data: existing } = await sb.from("customers").select("first_name, last_name, email, phone").range(0, 9999);
  const seen = new Set((existing ?? []).flatMap(dupKeys));
  const fresh = customers.filter((c) => {
    const keys = dupKeys(c);
    if (keys.some((k) => seen.has(k))) return false;
    keys.forEach((k) => seen.add(k));
    return true;
  });
  for (let i = 0; i < fresh.length; i += 500) {
    const { error } = await sb.from("customers").insert(fresh.slice(i, i + 500).map((c) => ({ ...c, organization_id: session.organization!.id })));
    if (error) go(back, "erreur", i ? `Import interrompu après ${i} fiches : relancez-le, les fiches déjà importées seront ignorées.` : "Import impossible, veuillez réessayer.");
  }
  const n = (k: number, one: string, many: string) => `${k} ${k > 1 ? many : one}`;
  go("/clients", "info", [
    n(fresh.length, "fiche importée", "fiches importées"),
    customers.length > fresh.length && n(customers.length - fresh.length, "déjà présente, ignorée", "déjà présentes, ignorées"),
    noName && n(noName, "ligne sans nom ignorée", "lignes sans nom ignorées"),
    badContact && n(badContact, "e-mail ou téléphone invalide laissé vide", "e-mails ou téléphones invalides laissés vides"),
  ].filter(Boolean).join(" · "));
}

// Suppression définitive (RGPD) : demandes supprimées, rendez-vous anonymisés. Owner/admin seulement (vérifié en base).
export async function deleteCustomer(fd: FormData) {
  const id = str(fd, "id");
  if (!isUuid(id)) redirect("/clients");
  if (fd.get("confirm") !== "on") go(`/clients/${id}`, "erreur", "Cochez la case de confirmation pour supprimer définitivement.");
  const sb = await createClient();
  const { error } = await sb.rpc("delete_customer", { p_id: id });
  if (error) go(`/clients/${id}`, "erreur", error.code === "42501" ? "Seuls le propriétaire et les administrateurs peuvent supprimer un client." : "Suppression impossible, veuillez réessayer.");
  go("/clients", "info", "Client supprimé définitivement. Ses rendez-vous passés restent dans l’agenda, anonymisés.");
}
