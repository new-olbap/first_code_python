"use client";
import { useActionState } from "react";
import Link from "next/link";
import { Field, Notice, Select, TextArea, primaryBtn, secondaryBtn } from "@/components/ui";
import type { Member } from "@/lib/team";
import { saveAppointment } from "./actions";

export type FormValues = { client: string; service: string; staff: string; date: string; time: string; duration: string; notes: string };
type Option = [string, string];

const DUREES: Option[] = [["", "Selon la prestation"], ...[15, 30, 45, 60, 90, 120, 180, 240, 360, 480].map((m): Option =>
  [String(m), m < 60 ? `${m} min` : `${Math.floor(m / 60)} h${m % 60 ? ` ${m % 60}` : ""}`])];

export default function AppointmentForm({ id, values: initial, customers, services, team, cancelHref }: {
  id?: string; values: FormValues; customers: Option[]; services: Option[]; team: Member[]; cancelHref?: string;
}) {
  const [state, action, pending] = useActionState(saveAppointment, { error: null, values: initial, n: 0 });
  const values = state.values;
  const durations = values.duration && !DUREES.some(([v]) => v === values.duration)
    ? [...DUREES, [values.duration, `${values.duration} min`] as Option] : DUREES;
  return (
    // key : remonte les champs avec la saisie renvoyée après une erreur (React vide le formulaire après l'envoi)
    <form key={state.n} action={action} className="space-y-4">
      <Notice erreur={state.error ?? undefined} />
      {id && <input type="hidden" name="id" value={id} />}
      <div className="grid gap-4 sm:grid-cols-2">
        <Select label="Client" name="client" defaultValue={values.client} required options={[["", "Choisir un client…"], ...customers]} />
        <Select label="Prestation" name="service" defaultValue={values.service} options={[["", "Sans prestation"], ...services]} />
        <Field label="Date" name="date" type="date" defaultValue={values.date} required />
        <Field label="Heure" name="time" type="time" step={900} defaultValue={values.time} required />
        <Select label="Durée" name="duration" defaultValue={values.duration} options={durations} />
        <Select label="Avec" name="staff" defaultValue={values.staff} required options={team.map((m): Option => [m.user_id, m.name])} />
        <div className="sm:col-span-2"><TextArea label="Notes" name="notes" defaultValue={values.notes} maxLength={2000} placeholder="Matériel à prévoir, accès…" /></div>
      </div>
      {customers.length === 0 && (
        <p className="text-sm text-muted">Aucun client pour l’instant : <Link href="/clients?nouveau=1" className="underline">créez d’abord une fiche client</Link>.</p>
      )}
      <div className="flex flex-wrap gap-3">
        <button className={primaryBtn} disabled={pending}>{pending ? "Enregistrement…" : id ? "Enregistrer les modifications" : "Enregistrer le rendez-vous"}</button>
        {cancelHref && <Link href={cancelHref} className={secondaryBtn}>Annuler</Link>}
      </div>
    </form>
  );
}
