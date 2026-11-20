"use server";
import { redirect } from "next/navigation";
import { createClient, getSession } from "@/lib/supabase/server";
import { parseEmail } from "@/lib/email";
import { dupKeys } from "@/lib/import";
import { go, isUuid, str } from "@/lib/form";

export async function resolveRequest(fd: FormData) {
  const id = str(fd, "id"), accept = str(fd, "accept") === "1";
  if (!isUuid(id)) redirect("/demandes");
  const sb = await createClient();
  const { error } = await sb.rpc("resolve_request", { p_id: id, p_accept: accept });
  if (error) go("/demandes", "erreur", error.code === "P0002" ? "Demande introuvable ou déjà traitée." : "Action impossible, veuillez réessayer.");
  go("/demandes", "info", !str(fd, "creneau") ? (accept ? "Demande marquée comme traitée." : "Demande refusée.")
    : accept ? "Demande acceptée : le rendez-vous est confirmé." : "Demande refusée : le créneau est libéré.");
}

// Demande reçue par e-mail, copiée-collée par l'artisan : fiche client retrouvée (même e-mail ou téléphone) ou créée.
export async function addEmailRequest(fd: FormData) {
  const session = await getSession();
  if (!session?.organization) redirect("/connexion");
  const back = "/demandes?email=1";
  const raw = String(fd.get("texte") ?? "").slice(0, 20000);
  if (raw.trim().length < 5) go(back, "erreur", "Collez le contenu de l’e-mail.");
  const p = parseEmail(raw, [session.user.email]);
  if (!p.email && !p.phone) go(back, "erreur", "Aucune adresse e-mail ni aucun téléphone trouvé. Copiez l’e-mail en entier, avec la ligne « De : ».");

  const sb = await createClient();
  // shortcut: compare aux 10 000 premières fiches, comme l'import.
  const { data: existing } = await sb.from("customers").select("id, first_name, last_name, email, phone").range(0, 9999);
  const keys = dupKeys(p);
  const known = (existing ?? []).find((c) => dupKeys(c).some((k) => keys.includes(k)));
  let cust = known?.id as string | undefined;
  if (!cust) {
    const { data, error } = await sb.from("customers").insert({
      organization_id: session.organization.id, kind: "prospect", first_name: p.first_name, last_name: p.last_name, email: p.email, phone: p.phone,
    }).select("id").single();
    if (error) go(back, "erreur", "Impossible de créer la fiche client, réessayez.");
    cust = data.id;
  }
  const { error } = await sb.from("requests").insert({ organization_id: session.organization.id, customer_id: cust, source: "email", message: p.message || null });
  if (error) go(back, "erreur", "Impossible d’ajouter la demande, réessayez.");
  const who = [known?.first_name ?? p.first_name, known?.last_name ?? p.last_name].filter(Boolean).join(" ");
  go("/demandes", "info", known ? `Demande ajoutée à la fiche existante de ${who}.` : `Demande ajoutée et fiche client créée pour ${who}.`);
}
