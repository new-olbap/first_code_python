import Link from "next/link";
import { CalendarPlus, Check, Mail, MapPin, Phone, X } from "lucide-react";
import ReplyButtons from "@/components/ReplyButtons";
import Card from "@/components/Card";
import { Notice, inputCls, primaryBtn, secondaryBtn } from "@/components/ui";
import { bookingUrl as getBookingUrl } from "@/lib/booking";
import { fmt } from "@/lib/dates";
import { createClient, getSession } from "@/lib/supabase/server";
import type { AgendaRow } from "../agenda/types";
import { addEmailRequest, resolveRequest } from "./actions";

type Req = {
  id: string; status: "new" | "accepted" | "refused"; source: "booking" | "email" | "manual"; message: string | null; created_at: string; appointment_id: string | null;
  customer: { id: string; first_name: string | null; last_name: string | null; phone: string | null; email: string | null; address: string | null } | null;
};
const SOURCE = { booking: "Réservation en ligne", email: "E-mail", manual: "Saisie manuelle" };
const ETAT = { new: "À traiter", accepted: "Acceptée", refused: "Refusée" };

export default async function Demandes({ searchParams }: { searchParams: Promise<{ vue?: string; email?: string; erreur?: string; info?: string }> }) {
  const sp = await searchParams;
  const traitees = sp.vue === "traitees";
  const org = (await getSession())!.organization!, tz = org.timezone;
  const bookingUrl = await getBookingUrl(org.slug);
  const sb = await createClient();
  const q = sb.from("requests").select("id, status, source, message, created_at, appointment_id, customer:customers(id, first_name, last_name, phone, email, address)");
  const { data } = traitees ? await q.neq("status", "new").order("created_at", { ascending: false }).limit(50)
    : await q.eq("status", "new").order("created_at").limit(100);
  const rows = (data ?? []) as unknown as Req[];
  // Créneau demandé, en heure locale (shortcut: un appel par demande ; regrouper si les listes deviennent longues).
  const slots = new Map((await Promise.all(rows.filter((r) => r.appointment_id).map((r) => sb.rpc("agenda", { p_id: r.appointment_id }))))
    .map(({ data }) => (data as AgendaRow[] | null)?.[0]).filter(Boolean).map((a) => [a!.id, a!]));

  return (
    <main className="space-y-5">
      <Card className="space-y-4">
        <h1 className="text-2xl font-bold">Demandes</h1>
        <p className="text-sm text-muted">Les réservations faites sur votre page en ligne arrivent ici, ainsi que les e-mails que vous y ajoutez. Un créneau choisi par un client est bloqué en attendant votre réponse.</p>
        <details open={!!sp.email} className="border border-line">
          <summary className="cursor-pointer px-4 py-3 text-sm font-semibold">Ajouter une demande reçue par e-mail</summary>
          <form action={addEmailRequest} className="space-y-3 border-t border-line p-4">
            <p className="text-xs text-muted">Copiez tout l’e-mail du client (avec la ligne « De : » si possible) et collez-le ici. Flo retrouve la fiche du client par son e-mail ou son téléphone, ou la crée.</p>
            <textarea name="texte" required maxLength={20000} placeholder={"De : Paul Durand <paul.durand@exemple.fr>\nObjet : Fuite sous l’évier\n\nBonjour, vous pourriez passer cette semaine ?\n06 12 34 56 78"} className={`${inputCls} min-h-40`} />
            <button className={primaryBtn}>Ajouter la demande</button>
          </form>
        </details>
        <nav className="flex gap-1" aria-label="Filtrer">
          {[["", "À traiter"], ["traitees", "Traitées"]].map(([v, l]) => (
            <Link key={v} href={v ? `/demandes?vue=${v}` : "/demandes"} aria-current={traitees === !!v ? "page" : undefined}
              className={`px-3 py-2 text-sm font-medium ${traitees === !!v ? "bg-ink text-bg" : "bg-surface text-muted hover:text-ink"}`}>{l}</Link>
          ))}
        </nav>
        <Notice erreur={sp.erreur} info={sp.info} />
      </Card>

      {rows.length === 0 && (
        <Card><p className="text-center text-muted">{traitees ? "Aucune demande traitée." : <>Aucune demande en attente. Partagez votre <Link href="/reservations" className="text-ink underline">page de réservation</Link> pour en recevoir.</>}</p></Card>
      )}
      {rows.map((r) => {
        const c = r.customer, a = r.appointment_id ? slots.get(r.appointment_id) : undefined;
        const name = [c?.first_name, c?.last_name].filter(Boolean).join(" ") || "Client inconnu";
        return (
          <Card key={r.id} className="space-y-3">
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div>
                <h2 className="text-lg font-semibold">{c ? <Link href={`/clients/${c.id}`} className="hover:underline">{name}</Link> : name}</h2>
                <p className="text-xs text-muted">{SOURCE[r.source]} · reçue le {new Date(r.created_at).toLocaleString("fr-FR", { timeZone: tz, day: "numeric", month: "long", hour: "2-digit", minute: "2-digit" })}</p>
              </div>
              <span className={`px-2 py-0.5 text-xs font-semibold ${r.status === "new" ? "bg-accent-2 text-black" : r.status === "accepted" ? "bg-ink text-bg" : "bg-surface text-muted"}`}>{ETAT[r.status]}</span>
            </div>
            {a && (
              <p className="bg-surface px-4 py-3 text-sm">
                <strong className="first-letter:uppercase">{fmt(a.day, { weekday: "long", day: "numeric", month: "long" })}</strong> · {a.start_time} – {a.end_time}
                {a.service_name && <> · {a.service_name}</>}{a.staff_name && <> · avec {a.staff_name}</>}
              </p>
            )}
            {r.message && <p className="whitespace-pre-line border-l-2 border-line pl-3 text-sm">{r.message}</p>}
            <div className="flex flex-wrap gap-2 text-sm">
              {c?.phone && <a href={`tel:${c.phone.replace(/[^\d+]/g, "")}`} className={`${secondaryBtn} flex items-center gap-2`}><Phone size={16} aria-hidden />{c.phone}</a>}
              {c?.email && <a href={`mailto:${c.email}`} className={`${secondaryBtn} flex items-center gap-2`}><Mail size={16} aria-hidden />{c.email}</a>}
              {c?.address && <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(c.address)}`} target="_blank" rel="noopener noreferrer" className={`${secondaryBtn} flex items-center gap-2`}><MapPin size={16} aria-hidden />{c.address}</a>}
            </div>
            {r.status === "new" && !a && c && (() => {
              const reply = `Bonjour${c.first_name ? ` ${c.first_name}` : ""},\n\nMerci pour votre message. Vous pouvez choisir directement le créneau qui vous convient ici :\n${bookingUrl}\n\nLes horaires proposés sont ceux où je suis disponible. Je confirme ensuite votre rendez-vous.\n\nCordialement,\n${org.name}`;
              return (
                <div className="space-y-3 bg-surface p-4">
                  <p className="text-sm font-semibold">Pas encore de créneau : proposez vos disponibilités</p>
                  <p className="text-xs text-muted">Le client choisit parmi vos créneaux libres. Cette demande se met alors à jour ici avec le créneau choisi, et le créneau est bloqué.{!org.booking_enabled && <strong className="text-accent-2"> Votre réservation en ligne est fermée : ouvrez-la dans Réservations, sinon le lien ne marchera pas.</strong>}</p>
                  <div className="flex flex-wrap gap-2">
                    <ReplyButtons email={c.email} phone={c.phone} subject={`Votre demande — ${org.name}`} text={reply} />
                    <Link href={`/agenda/nouveau?client=${c.id}`} className={`${secondaryBtn} flex items-center gap-2 text-sm`}><CalendarPlus size={16} aria-hidden />Créer le rendez-vous moi-même</Link>
                  </div>
                </div>
              );
            })()}
            {r.status === "new" && (
              <div className="flex flex-wrap gap-2 border-t border-line pt-3">
                {[["1", a ? "Accepter" : "Marquer comme traitée", <Check key="i" size={16} aria-hidden />, primaryBtn], ["0", "Refuser", <X key="i" size={16} aria-hidden />, secondaryBtn]].map(([v, l, icon, cls]) => (
                  <form key={v as string} action={resolveRequest}>
                    <input type="hidden" name="id" value={r.id} /><input type="hidden" name="accept" value={v as string} /><input type="hidden" name="creneau" value={a ? "1" : ""} />
                    <button className={`${cls} flex items-center gap-2`}>{icon}{l}</button>
                  </form>
                ))}
                {a && <Link href={`/agenda/${a.id}`} className={secondaryBtn}>Changer le créneau</Link>}
              </div>
            )}
          </Card>
        );
      })}
    </main>
  );
}
