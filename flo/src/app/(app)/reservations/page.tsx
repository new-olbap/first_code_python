import Link from "next/link";
import { Check, ExternalLink, TriangleAlert } from "lucide-react";
import Card from "@/components/Card";
import CopyButton from "@/components/CopyButton";
import { Notice, primaryBtn, secondaryBtn } from "@/components/ui";
import { bookingUrl } from "@/lib/booking";
import { createClient, getSession } from "@/lib/supabase/server";
import { setBookingEnabled } from "./actions";

export default async function Reservations({ searchParams }: { searchParams: Promise<{ erreur?: string; info?: string }> }) {
  const session = (await getSession())!;
  const org = session.organization!;
  const url = await bookingUrl(org.slug);
  const sb = await createClient();
  const [{ count: services }, { data: rules }] = await Promise.all([
    sb.from("services").select("id", { count: "exact", head: true }).is("archived_at", null),
    sb.from("availability_rules").select("user_id"),
  ]);
  const checks = [
    { ok: (services ?? 0) > 0, text: "Au moins une prestation", href: "/prestations", fix: "Ajouter une prestation" },
    { ok: (rules ?? []).length > 0, text: "Des horaires de travail enregistrés", href: "/equipe", fix: "Enregistrer mes horaires" },
  ];
  const canEdit = session.role === "owner" || session.role === "admin";

  return (
    <main className="space-y-5">
      <Card className="space-y-4">
        <h1 className="text-2xl font-bold">Réservation en ligne</h1>
        <p className="text-sm text-muted">Partagez ce lien sur votre site, vos réseaux, votre fiche Google ou dans votre signature d’e-mail : vos clients choisissent un créneau libre et la demande arrive dans « Demandes ».</p>
        <Notice {...await searchParams} />
        <div className="break-all border border-line bg-surface px-4 py-3 font-mono text-sm">{url}</div>
        <div className="flex flex-wrap gap-2">
          <CopyButton text={url} />
          <a href={url} target="_blank" rel="noopener noreferrer" className={`${secondaryBtn} flex items-center gap-2`}><ExternalLink size={16} aria-hidden /> Voir ma page</a>
          {canEdit && (
            <form action={setBookingEnabled}>
              <input type="hidden" name="on" value={org.booking_enabled ? "0" : "1"} />
              <button className={org.booking_enabled ? secondaryBtn : primaryBtn}>{org.booking_enabled ? "Fermer la réservation en ligne" : "Ouvrir la réservation en ligne"}</button>
            </form>
          )}
        </div>
        <p className={`text-sm font-semibold ${org.booking_enabled ? "" : "text-accent-2"}`}>
          {org.booking_enabled ? "La réservation en ligne est ouverte." : "La réservation en ligne est fermée : la page affiche « introuvable »."}
        </p>
      </Card>
      <Card className="space-y-3">
        <h2 className="font-semibold">Pour que des créneaux s’affichent</h2>
        {checks.map((c) => (
          <div key={c.text} className="flex flex-wrap items-center gap-3 bg-surface px-4 py-3 text-sm">
            {c.ok ? <Check size={18} aria-hidden /> : <TriangleAlert size={18} aria-hidden className="text-accent-2" />}
            <span className="flex-1">{c.text}</span>
            {!c.ok && <Link href={c.href} className="underline">{c.fix}</Link>}
          </div>
        ))}
        <p className="text-xs text-muted">Seuls les créneaux libres sont proposés : dans vos horaires, hors absences, sans chevaucher un rendez-vous, au moins 2 h à l’avance et jusqu’à 60 jours.</p>
      </Card>
    </main>
  );
}
