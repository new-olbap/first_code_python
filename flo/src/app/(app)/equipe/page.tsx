import { Trash2 } from "lucide-react";
import Card from "@/components/Card";
import { Field, Notice, Select, primaryBtn, secondaryBtn } from "@/components/ui";
import { fmt, todayIn } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";
import { ROLE_LABEL, getTeam } from "@/lib/team";
import { addTimeOff, deleteTimeOff, saveWeeklyHours } from "./actions";

const JOURS = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
type Rule = { user_id: string; weekday: number; start_time: string; end_time: string };
type TimeOff = { id: string; user_id: string; starts_on: string; ends_on: string; reason: string | null };

export default async function Equipe({ searchParams }: { searchParams: Promise<{ erreur?: string; info?: string }> }) {
  const session = (await getSession())!;
  const canManage = session.role === "owner" || session.role === "admin";
  const today = todayIn(session.organization!.timezone);
  const sb = await createClient();
  const [team, { data: r }, { data: t }] = await Promise.all([
    getTeam(sb),
    sb.from("availability_rules").select("user_id, weekday, start_time, end_time").order("weekday"),
    sb.from("time_off").select("id, user_id, starts_on, ends_on, reason").gte("ends_on", today).order("starts_on"),
  ]);
  const rules = (r ?? []) as Rule[];
  const absences = (t ?? []) as TimeOff[];
  const editable = team.filter((m) => canManage || m.user_id === session.user.id);

  return (
    <main className="space-y-5">
      <Card className="space-y-2">
        <h1 className="text-2xl font-bold">Équipe</h1>
        <p className="text-sm text-muted">Horaires de travail et absences. Un rendez-vous ne peut pas être pris pendant une absence.</p>
        <Notice {...await searchParams} />
      </Card>

      {team.map((m) => {
        const own = rules.filter((x) => x.user_id === m.user_id);
        const canEdit = canManage || m.user_id === session.user.id;
        const fresh = own.length === 0; // aucun horaire enregistré : on propose lundi–vendredi 8 h–18 h
        return (
          <Card key={m.user_id} className="space-y-4">
            <div className="flex flex-wrap items-baseline gap-x-3">
              <h2 className="text-lg font-semibold">{m.name}</h2>
              <span className="text-sm text-muted">{ROLE_LABEL[m.role]}</span>
              {fresh && <span className="text-sm text-accent-2">Aucun horaire enregistré</span>}
            </div>
            <form action={saveWeeklyHours} className="space-y-3">
              <input type="hidden" name="user" value={m.user_id} />
              <fieldset disabled={!canEdit} className="grid gap-x-6 gap-y-2 md:grid-cols-2">
                <legend className="sr-only">Horaires de {m.name}</legend>
                {JOURS.map((jour, i) => {
                  const d = i + 1, rule = own.find((x) => x.weekday === d);
                  return (
                    <div key={d} className="flex items-center gap-3 border-b border-line py-1.5">
                      <label className="flex w-28 items-center gap-2 text-sm font-medium">
                        <input type="checkbox" name={`on_${d}`} defaultChecked={!!rule || (fresh && d <= 5)} className="h-4 w-4 accent-[var(--ink)]" />
                        {jour}
                      </label>
                      <input type="time" name={`start_${d}`} step={900} aria-label={`${jour} début`} defaultValue={rule?.start_time.slice(0, 5) ?? "08:00"} className="border border-line bg-surface px-2 py-1 text-sm" />
                      <span className="text-muted">–</span>
                      <input type="time" name={`end_${d}`} step={900} aria-label={`${jour} fin`} defaultValue={rule?.end_time.slice(0, 5) ?? "18:00"} className="border border-line bg-surface px-2 py-1 text-sm" />
                    </div>
                  );
                })}
              </fieldset>
              {canEdit && <button className={secondaryBtn}>Enregistrer les horaires</button>}
            </form>
            <div className="space-y-2">
              <h3 className="text-sm font-semibold">Absences à venir</h3>
              {absences.filter((x) => x.user_id === m.user_id).map((x) => (
                <div key={x.id} className="flex items-center gap-3 bg-surface px-3 py-2 text-sm">
                  <span className="flex-1">
                    {x.starts_on === x.ends_on ? fmt(x.starts_on, { day: "numeric", month: "long" }) : `Du ${fmt(x.starts_on, { day: "numeric", month: "long" })} au ${fmt(x.ends_on, { day: "numeric", month: "long", year: "numeric" })}`}
                    {x.reason && <span className="text-muted"> · {x.reason}</span>}
                  </span>
                  {canEdit && (
                    <form action={deleteTimeOff}>
                      <input type="hidden" name="id" value={x.id} />
                      <button aria-label="Supprimer l’absence" className="p-1 text-muted hover:text-ink"><Trash2 size={16} /></button>
                    </form>
                  )}
                </div>
              ))}
              {!absences.some((x) => x.user_id === m.user_id) && <p className="text-sm text-muted">Aucune absence prévue.</p>}
            </div>
          </Card>
        );
      })}

      <Card className="space-y-3">
        <h2 className="font-semibold">Ajouter une absence ou des congés</h2>
        <form action={addTimeOff} className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {editable.length > 1
            ? <Select label="Personne" name="user" defaultValue={session.user.id} options={editable.map((m): [string, string] => [m.user_id, m.name])} />
            : <input type="hidden" name="user" value={session.user.id} />}
          <Field label="Du" name="from" type="date" defaultValue={today} required />
          <Field label="Au (inclus)" name="to" type="date" defaultValue={today} required />
          <Field label="Motif (facultatif)" name="reason" maxLength={200} placeholder="Congés, formation…" />
          <div className="sm:col-span-2 lg:col-span-4"><button className={primaryBtn}>Ajouter l’absence</button></div>
        </form>
      </Card>
    </main>
  );
}
