"use server";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { go, str } from "@/lib/form";

const ERRORS: Record<string, string> = {
  FL003: "Ce créneau vient d’être pris ou n’est plus disponible : choisissez-en un autre.",
  "22023": "Vérifiez vos coordonnées : nom, téléphone et e-mail.",
  FL002: "Trop de demandes en attente : merci de contacter directement l’entreprise.",
  P0002: "Cette page de réservation n’est plus disponible.",
};

export async function publicBook(fd: FormData) {
  const slug = str(fd, "slug", 60), service = str(fd, "service", 40), date = str(fd, "date", 10), time = str(fd, "time", 5);
  const back = `/r/${encodeURIComponent(slug)}?service=${encodeURIComponent(service)}&date=${encodeURIComponent(date)}&time=${encodeURIComponent(time)}`;
  const merci = `/r/${encodeURIComponent(slug)}/merci?date=${encodeURIComponent(date)}&time=${encodeURIComponent(time)}`;
  // Anti-robots : champ invisible rempli ou formulaire envoyé en moins de 2 s → on fait semblant d'accepter.
  if (str(fd, "website") || Date.now() - Number(str(fd, "ts")) < 2000) redirect(merci);
  if (fd.get("consent") !== "on") go(back, "erreur", "Merci d’accepter l’utilisation de vos coordonnées pour traiter la demande.");

  const sb = await createClient();
  const { error } = await sb.rpc("public_book", {
    p_slug: slug, p_service: service, p_date: date, p_time: time,
    p_first: str(fd, "first_name", 80), p_last: str(fd, "last_name", 80), p_phone: str(fd, "phone", 30),
    p_email: str(fd, "email", 254), p_address: str(fd, "address", 300), p_message: str(fd, "message", 2000),
  });
  if (error) go(error.code === "FL003" ? back.replace(/&time=[^&]*/, "") : back, "erreur", ERRORS[error.code] ?? "La réservation n’a pas pu être enregistrée, veuillez réessayer.");
  redirect(merci);
}
