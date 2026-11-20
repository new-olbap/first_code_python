import { Notice } from "@/components/ui";
import { isIsoDate, todayIn } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";
import { getTeam } from "@/lib/team";
import AppointmentForm from "../AppointmentForm";
import { formOptions } from "../options";

export type NewSP = Partial<Record<"client" | "service" | "staff" | "date" | "time" | "duration" | "notes" | "erreur" | "info", string>>;

// Formulaire de création, affiché en page (/agenda/nouveau) ou en fenêtre par-dessus l'écran courant.
export default async function NewAppointment({ sp, inModal = false }: { sp: NewSP; inModal?: boolean }) {
  const session = (await getSession())!;
  const sb = await createClient();
  const [opts, team] = await Promise.all([formOptions(sb), getTeam(sb)]);
  const values = {
    client: sp.client ?? "", service: sp.service ?? "", staff: sp.staff ?? session.user.id,
    date: isIsoDate(sp.date) ? sp.date : todayIn(session.organization!.timezone),
    time: sp.time ?? "09:00", duration: sp.duration ?? "", notes: sp.notes ?? "",
  };
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Nouveau rendez-vous</h1>
      <Notice erreur={sp.erreur} info={sp.info} />
      <AppointmentForm values={values} team={team} {...opts} cancelHref={inModal ? undefined : `/agenda?date=${values.date}`} />
    </div>
  );
}
