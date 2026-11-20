import Link from "next/link";
import { Check } from "lucide-react";
import { primaryBtn } from "@/components/ui";
import { CONTACT, TARIF, eur } from "@/lib/tarif";

export const metadata = { title: "Tarif — Flo" };

const INCLUS = [
  "Agenda jour, semaine et mois",
  "Fiches clients, import et export",
  "Page de réservation en ligne",
  "Équipe : membres illimités",
  "Toutes les mises à jour",
  "Données hébergées en France",
  "Assistance par e-mail",
];

export default function Tarif() {
  const sujet = encodeURIComponent("Commande Flo — licence à vie");
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Un seul paiement, à vie</h1>
        <p className="mt-1 text-sm text-muted">Pas d’abonnement. Vous payez une fois, Flo est à vous.</p>
      </div>

      <div className="border border-line p-5">
        <p className="text-xs font-semibold uppercase tracking-wider text-accent-2">Offre de lancement</p>
        <p className="mt-2 flex items-baseline gap-3">
          <span className="text-5xl font-black tracking-tight">{eur(TARIF.lancement)}</span>
          <s className="text-lg text-muted">{eur(TARIF.normal)}</s>
        </p>
        <p className="mt-1 text-xs text-muted">Pour les {TARIF.places} premiers artisans, puis {eur(TARIF.normal)}. TVA non applicable, art. 293 B du CGI.</p>
        <ul className="mt-5 space-y-2 text-sm">
          {INCLUS.map((t) => <li key={t} className="flex items-center gap-2"><Check size={16} aria-hidden className="text-accent-2" />{t}</li>)}
        </ul>
      </div>

      <a href={`mailto:${CONTACT}?subject=${sujet}`} className={`${primaryBtn} block w-full py-3 text-center`}>Commander</a>
      <p className="text-xs text-muted">Paiement par virement bancaire. Votre accès est activé dès réception, avec une facture.</p>
      <p className="text-center text-sm"><Link href="/connexion" className="text-accent-ink hover:underline">Déjà client ? Se connecter</Link></p>
    </div>
  );
}
