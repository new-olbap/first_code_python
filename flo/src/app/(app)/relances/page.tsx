import Link from "next/link";
import { CalendarPlus } from "lucide-react";
import Card from "@/components/Card";
import ReplyButtons from "@/components/ReplyButtons";
import { secondaryBtn } from "@/components/ui";
import { bookingUrl } from "@/lib/booking";
import { fmt, todayIn } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";

export const metadata = { title: "À relancer — Flo" };

type Contact = { id: string; first_name: string | null; last_name: string | null; phone: string | null; email: string | null };
type Row = { key: string; c: Contact; why: string; text: string; service?: string };

const name = (c: Contact) => [c.first_name, c.last_name].filter(Boolean).join(" ");
const longDate = (d: string) => fmt(d, { day: "numeric", month: "long", year: "numeric" });
const ago = (days: number) => new Date(Date.now() - days * 86_400_000).toISOString();

// Trois raisons de relancer, calculées à chaque visite.
// shortcut: pas de « marquer comme relancé » : un client reste listé tant qu'il n'a pas de rendez-vous ; ajouter une date de relance si la liste devient longue.
export default async function Relances() {
  const org = (await getSession())!.organization!;
  const [url, sb] = [await bookingUrl(org.slug), await createClient()];
  const hello = (c: Contact) => `Bonjour${c.first_name ? ` ${c.first_name}` : ""},\n\n`;
  const sign = `\n\nCordialement,\n${org.name}`;

  const [{ data: due }, { data: waiting }, { data: prospects }] = await Promise.all([
    sb.rpc("due_maintenance"),
    sb.from("requests").select("id, created_at, customer:customers(id, first_name, last_name, phone, email)")
      .eq("status", "new").is("appointment_id", null).lt("created_at", ago(2)).order("created_at").limit(50),
    sb.from("customers").select("id, first_name, last_name, phone, email, created_at")
      .eq("kind", "prospect").is("archived_at", null).lt("created_at", ago(7)).order("created_at", { ascending: false }).limit(100),
  ]);

  // 1. Entretiens à refaire
  const dueRows = (due ?? []) as { customer_id: string; service_id: string; last_day: string; due_on: string }[];
  const [{ data: dc }, { data: ds }] = await Promise.all([
    sb.from("customers").select("id, first_name, last_name, phone, email").in("id", dueRows.map((d) => d.customer_id)),
    sb.from("services").select("id, name").in("id", dueRows.map((d) => d.service_id)),
  ]);
  const today = todayIn(org.timezone);
  const entretiens: Row[] = dueRows.flatMap((d) => {
    const c = (dc as Contact[] | null)?.find((x) => x.id === d.customer_id), s = ds?.find((x) => x.id === d.service_id)?.name as string | undefined;
    if (!c || !s) return [];
    return [{
      key: d.customer_id + d.service_id, c, service: d.service_id,
      why: `${s} · dernier passage le ${longDate(d.last_day)} · ${d.due_on < today ? "échéance dépassée depuis le" : "à refaire le"} ${longDate(d.due_on)}`,
      text: `${hello(c)}Votre ${s.toLowerCase()} arrive à échéance (dernier passage le ${longDate(d.last_day)}). Vous pouvez choisir le créneau qui vous convient ici :\n${url}${sign}`,
    }];
  });

  // 2. Demandes restées sans créneau
  const waitingRows = ((waiting ?? []) as unknown as { id: string; created_at: string; customer: Contact | null }[]).filter((r) => r.customer);
  const sansReponse: Row[] = waitingRows.map((r) => ({
    key: r.id, c: r.customer!,
    why: `Demande du ${longDate(r.created_at.slice(0, 10))} : le client n’a pas encore choisi de créneau`,
    text: `${hello(r.customer!)}Je reviens vers vous suite à votre demande. Vous pouvez toujours choisir le créneau qui vous convient ici :\n${url}${sign}`,
  }));

  // 3. Prospects sans aucun rendez-vous (hors ceux déjà listés ci-dessus)
  const pIds = (prospects ?? []).map((p) => p.id as string);
  const { data: withAppt } = await sb.from("appointments").select("customer_id").in("customer_id", pIds);
  const skip = new Set([...(withAppt ?? []).map((a) => a.customer_id), ...waitingRows.map((r) => r.customer!.id)]);
  const aRelancer: Row[] = ((prospects ?? []) as (Contact & { created_at: string })[]).filter((p) => !skip.has(p.id)).map((p) => ({
    key: p.id, c: p,
    why: `Prospect depuis le ${longDate(p.created_at.slice(0, 10))}, sans rendez-vous`,
    text: `${hello(p)}Avez-vous toujours besoin d’une intervention ? Vous pouvez choisir le créneau qui vous convient ici :\n${url}${sign}`,
  }));

  const sections = [
    { title: "Entretiens à prévoir", empty: "Aucun entretien à l’échéance. Réglez « À refaire » dans Prestations (ex. entretien chaudière : tous les ans).", rows: entretiens, subject: "Votre entretien" },
    { title: "Demandes sans réponse du client", empty: "Aucune demande en attente depuis plus de 2 jours.", rows: sansReponse, subject: "Votre demande" },
    { title: "Prospects à relancer", empty: "Aucun prospect sans rendez-vous depuis plus d’une semaine.", rows: aRelancer, subject: "Votre projet" },
  ];
  const total = sections.reduce((n, s) => n + s.rows.length, 0);

  return (
    <main className="space-y-5">
      <Card className="space-y-2">
        <h1 className="text-2xl font-bold">À relancer</h1>
        <p className="text-sm text-muted">
          {total ? `${total} ${total > 1 ? "personnes à relancer" : "personne à relancer"} aujourd’hui.` : "Personne à relancer aujourd’hui."} Chaque message est déjà rédigé, avec votre lien de réservation : il part de votre messagerie ou de vos SMS.
        </p>
      </Card>
      {sections.map((s) => (
        <Card key={s.title} className="space-y-3">
          <h2 className="flex items-center gap-2 text-lg font-semibold">
            {s.title}{s.rows.length > 0 && <span className="bg-accent-2 px-1.5 text-xs font-bold text-black">{s.rows.length}</span>}
          </h2>
          {s.rows.length === 0 && <p className="text-sm text-muted">{s.empty}</p>}
          {s.rows.map((r) => (
            <div key={r.key} className="space-y-3 bg-surface p-4">
              <div>
                <Link href={`/clients/${r.c.id}`} className="font-semibold hover:underline">{name(r.c) || "Client"}</Link>
                <p className="text-sm text-muted">{r.why}</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <ReplyButtons email={r.c.email} phone={r.c.phone} subject={`${s.subject} — ${org.name}`} text={r.text} verb="Relancer" />
                <Link href={`/agenda/nouveau?client=${r.c.id}${r.service ? `&service=${r.service}` : ""}`} className={`${secondaryBtn} flex items-center gap-2 text-sm`}><CalendarPlus size={16} aria-hidden />Créer le rendez-vous</Link>
              </div>
            </div>
          ))}
        </Card>
      ))}
    </main>
  );
}
