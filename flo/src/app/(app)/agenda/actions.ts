"use server";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { go, isUuid, str } from "@/lib/form";
import { isIsoDate, isTime } from "@/lib/dates";
import type { FormValues } from "./AppointmentForm";

const ERRORS: Record<string, string> = {
  "23P01": "Ce créneau chevauche un autre rendez-vous de cette personne.",
  FL001: "Cette personne est absente ce jour-là.",
  "22023": "Choisissez une prestation ou indiquez une durée.",
  "23503": "Client, prestation ou personne invalide.",
  P0002: "Rendez-vous introuvable.",
};

export type SaveState = { error: string | null; values: FormValues; n: number };

// Erreurs renvoyées au formulaire (sans changer d'adresse, donc sans rouvrir la fenêtre) ; succès : redirection.
export async function saveAppointment(prev: SaveState, fd: FormData): Promise<SaveState> {
  const id = str(fd, "id");
  const v = {
    client: str(fd, "client"), service: str(fd, "service"), staff: str(fd, "staff"),
    date: str(fd, "date"), time: str(fd, "time"), duration: str(fd, "duration"), notes: str(fd, "notes", 2000),
  };
  const duration = v.duration ? Number(v.duration) : null;
  const error = id && !isUuid(id) ? "Rendez-vous introuvable."
    : !isUuid(v.client) ? "Choisissez un client."
    : v.service && !isUuid(v.service) ? "Prestation invalide."
    : !isUuid(v.staff) ? "Choisissez la personne qui intervient."
    : !isIsoDate(v.date) ? "Date invalide."
    : !isTime(v.time) ? "Heure invalide."
    : duration !== null && (!Number.isInteger(duration) || duration < 5 || duration > 1440) ? "Durée invalide."
    : !v.service && duration === null ? ERRORS["22023"]
    : null;
  const fail = (msg: string): SaveState => ({ error: msg, values: v, n: prev.n + 1 });
  if (error) return fail(error);

  const sb = await createClient();
  const { data, error: e } = await sb.rpc("save_appointment", {
    p_id: id || null, p_customer: v.client, p_service: v.service || null, p_staff: v.staff,
    p_date: v.date, p_time: v.time, p_duration: duration, p_notes: v.notes || null,
  });
  if (e || !data) return fail(ERRORS[e?.code ?? ""] ?? "Enregistrement impossible, veuillez réessayer.");
  go(`/agenda?vue=jour&date=${v.date}`, "info", id ? "Rendez-vous modifié." : "Rendez-vous enregistré.");
}

export async function setAppointmentStatus(fd: FormData) {
  const id = str(fd, "id"), status = str(fd, "status");
  if (!isUuid(id) || !["pending", "confirmed", "cancelled"].includes(status)) redirect("/agenda");
  const sb = await createClient();
  const { data, error } = await sb.from("appointments").update({ status }).eq("id", id).select("id");
  if (error || !data?.length) go(`/agenda/${id}`, "erreur", ERRORS[error?.code ?? ""] ?? "Action impossible.");
  go(`/agenda/${id}`, "info", status === "cancelled" ? "Rendez-vous annulé." : "Rendez-vous confirmé.");
}
