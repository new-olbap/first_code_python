"use server";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { go, isUuid, str } from "@/lib/form";

export async function resolveRequest(fd: FormData) {
  const id = str(fd, "id"), accept = str(fd, "accept") === "1";
  if (!isUuid(id)) redirect("/demandes");
  const sb = await createClient();
  const { error } = await sb.rpc("resolve_request", { p_id: id, p_accept: accept });
  if (error) go("/demandes", "erreur", error.code === "P0002" ? "Demande introuvable ou déjà traitée." : "Action impossible, veuillez réessayer.");
  go("/demandes", "info", accept ? "Demande acceptée : le rendez-vous est confirmé." : "Demande refusée : le créneau est libéré.");
}
