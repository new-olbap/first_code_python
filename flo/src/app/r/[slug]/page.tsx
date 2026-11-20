import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Clock } from "lucide-react";
import { Field, Notice, TextArea, buttonCls } from "@/components/ui";
import { fmt, isIsoDate, todayIn } from "@/lib/dates";
import { createClient } from "@/lib/supabase/server";
import { publicBook } from "./actions";

type Info = { name: string; trade: string | null; timezone: string; services: { id: string; name: string; duration_minutes: number; price_cents: number | null }[] };
type SP = { service?: string; date?: string; time?: string; erreur?: string };

async function getInfo(slug: string) {
  const sb = await createClient();
  const { data } = await sb.rpc("public_booking", { p_slug: slug });
  return { sb, info: data as Info | null };
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { info } = await getInfo((await params).slug);
  return { title: info ? `Prendre rendez-vous — ${info.name}` : "Réservation introuvable" };
}

const duree = (m: number) => (m < 60 ? `${m} min` : `${Math.floor(m / 60)} h${m % 60 ? ` ${m % 60}` : ""}`);
const prix = (c: number | null) => (c === null ? null : `${(c / 100).toLocaleString("fr-FR", { minimumFractionDigits: c % 100 ? 2 : 0 })} €`);
const Step = ({ n, title, children }: { n: number; title: string; children: React.ReactNode }) => (
  <section className="space-y-3 border-t border-line pt-6">
    <h2 className="flex items-center gap-3 text-lg font-semibold"><span className="grid h-7 w-7 place-items-center bg-ink text-sm text-bg">{n}</span>{title}</h2>
    {children}
  </section>
);

export default async function Reserver({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<SP> }) {
  const { slug } = await params;
  const sp = await searchParams;
  const { sb, info } = await getInfo(slug);
  if (!info) notFound();
  const service = info.services.find((s) => s.id === sp.service);
  const base = `/r/${slug}`;

  const byDay = new Map<string, string[]>();
  if (service) {
    const { data } = await sb.rpc("public_slots", { p_slug: slug, p_service: service.id, p_from: todayIn(info.timezone), p_days: 21 });
    for (const s of (data ?? []) as { slot_day: string; slot_time: string }[]) byDay.set(s.slot_day, [...(byDay.get(s.slot_day) ?? []), s.slot_time]);
  }
  const date = isIsoDate(sp.date) && byDay.has(sp.date) ? sp.date : [...byDay.keys()][0];
  const time = date && sp.time && byDay.get(date)?.includes(sp.time) ? sp.time : null;
  const choice = (on: boolean) => `border px-3 py-2 text-sm font-medium transition ${on ? "border-ink bg-ink text-bg" : "border-line bg-surface hover:border-white/40"}`;

  return (
    <main className="mx-auto max-w-2xl space-y-6 px-4 py-10">
      <header>
        <p className="text-xs font-semibold uppercase tracking-widest text-muted">Prendre rendez-vous</p>
        <h1 className="mt-1 text-4xl font-black tracking-tight">{info.name}</h1>
        {info.trade && <p className="mt-1 text-muted">{info.trade}</p>}
      </header>
      <Notice erreur={sp.erreur} />

      <Step n={1} title="Prestation">
        {info.services.length === 0 ? <p className="text-muted">Aucune prestation n’est proposée en ligne pour le moment.</p> : (
          <div className="grid gap-2 sm:grid-cols-2">
            {info.services.map((s) => (
              <Link key={s.id} href={`${base}?service=${s.id}`} className={`${choice(s.id === service?.id)} block`}>
                <span className="block font-semibold">{s.name}</span>
                <span className="flex items-center gap-1 text-xs opacity-80"><Clock size={12} aria-hidden />{duree(s.duration_minutes)}{prix(s.price_cents) && ` · à partir de ${prix(s.price_cents)}`}</span>
              </Link>
            ))}
          </div>
        )}
      </Step>

      {service && (
        <Step n={2} title="Jour">
          {byDay.size === 0 ? <p className="text-muted">Aucun créneau libre dans les 3 prochaines semaines. Contactez directement l’entreprise.</p> : (
            <div className="flex gap-2 overflow-x-auto pb-1">
              {[...byDay.keys()].map((d) => (
                <Link key={d} href={`${base}?service=${service.id}&date=${d}`} className={`${choice(d === date)} min-w-20 shrink-0 text-center`}>
                  <span className="block text-xs uppercase opacity-80">{fmt(d, { weekday: "short" })}</span>
                  <span className="block text-lg font-bold">{Number(d.slice(8))}</span>
                  <span className="block text-xs opacity-80">{fmt(d, { month: "short" })}</span>
                </Link>
              ))}
            </div>
          )}
        </Step>
      )}

      {service && date && (
        <Step n={3} title={`Heure — ${fmt(date, { weekday: "long", day: "numeric", month: "long" })}`}>
          <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
            {byDay.get(date)!.map((t) => (
              <Link key={t} href={`${base}?service=${service.id}&date=${date}&time=${t}`} className={`${choice(t === time)} text-center`}>{t}</Link>
            ))}
          </div>
        </Step>
      )}

      {service && date && time && (
        <Step n={4} title="Vos coordonnées">
          <p className="bg-surface px-4 py-3 text-sm">
            <strong>{service.name}</strong> le <strong>{fmt(date, { weekday: "long", day: "numeric", month: "long" })}</strong> à <strong>{time}</strong>
          </p>
          <form action={publicBook} className="space-y-4">
            {[["slug", slug], ["service", service.id], ["date", date], ["time", time], ["ts", String(Date.now())]].map(([n, v]) => <input key={n} type="hidden" name={n} value={v} />)}
            <div aria-hidden className="absolute -left-[9999px]"><label>Site web <input name="website" tabIndex={-1} autoComplete="off" /></label></div>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Prénom" name="first_name" autoComplete="given-name" maxLength={80} />
              <Field label="Nom" name="last_name" autoComplete="family-name" maxLength={80} required />
              <Field label="Téléphone" name="phone" type="tel" autoComplete="tel" maxLength={30} required pattern="[0-9+\(\)\.\s\-]{6,30}" title="Chiffres, espaces, +, -, ( ) uniquement" />
              <Field label="E-mail (facultatif)" name="email" type="email" autoComplete="email" maxLength={254} />
              <div className="sm:col-span-2"><Field label="Adresse de l’intervention" name="address" autoComplete="street-address" maxLength={300} /></div>
              <div className="sm:col-span-2"><TextArea label="Votre demande (facultatif)" name="message" maxLength={2000} placeholder="Décrivez le problème, l’accès, le matériel…" /></div>
            </div>
            <label className="flex items-start gap-2 text-sm text-muted">
              <input type="checkbox" name="consent" required className="mt-0.5 h-4 w-4 shrink-0 accent-[var(--ink)]" />
              J’accepte que mes coordonnées soient utilisées par {info.name} pour traiter ma demande de rendez-vous (<Link href="/confidentialite" target="_blank" className="underline">confidentialité</Link>).
            </label>
            <button className={buttonCls}>Demander ce rendez-vous</button>
            <p className="text-xs text-muted">{info.name} vous confirmera le rendez-vous.</p>
          </form>
        </Step>
      )}
      <footer className="border-t border-line pt-6 text-xs text-muted">
        Réservation en ligne propulsée par <strong className="text-ink">Flo</strong> · <Link href="/mentions-legales" className="underline">Mentions légales</Link> · <Link href="/confidentialite" className="underline">Confidentialité</Link>
      </footer>
    </main>
  );
}
