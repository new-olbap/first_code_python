/* eslint-disable @next/next/no-img-element -- images statiques déjà optimisées en WebP dans /public/decouvrir */
import type { Metadata } from "next";
import Link from "next/link";
import { CONTACT, TARIF, eur, mensualite } from "@/lib/tarif";
import Cinema from "./Cinema";
import s from "./landing.module.css";

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://flo-theta-gray.vercel.app";
const TITLE = "Flo — Logiciel de prise de rendez-vous pour artisans";
const DESC = "Agenda, réservation en ligne, demandes reçues par e-mail et relances d’entretien : Flo organise les rendez-vous des artisans. Paiement unique, données hébergées en France.";

export const metadata: Metadata = {
  title: TITLE,
  description: DESC,
  alternates: { canonical: `${SITE}/` },
  openGraph: { title: TITLE, description: DESC, url: `${SITE}/`, siteName: "Flo", locale: "fr_FR", type: "website", images: [{ url: `${SITE}/decouvrir/apercu.jpg`, width: 1200, height: 630 }] },
  robots: { index: true, follow: true },
};

const demo = `mailto:${CONTACT}?subject=${encodeURIComponent("Démonstration de Flo")}&body=${encodeURIComponent("Bonjour,\n\nJe souhaiterais voir une démonstration de Flo.\n\nMon métier :\nMon téléphone :\n")}`;
const Arrow = () => <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden><path d="M3 8h10M9 4l4 4-4 4" /></svg>;

const FAQ = [
  ["Faut-il payer un abonnement ?", `Non. Flo se paie une seule fois : ${eur(TARIF.lancement)} pour les ${TARIF.places} premiers artisans, puis ${eur(TARIF.normal)}, en une fois ou en ${TARIF.fois} virements sans frais. Les mises à jour sont comprises.`],
  ["Mes clients doivent-ils créer un compte ?", "Non. Ils ouvrent votre page de réservation, choisissent une prestation et un créneau, et laissent leurs coordonnées. C’est tout."],
  ["Est-ce que ça marche sur téléphone ?", "Oui. Flo s’utilise dans le navigateur, sur téléphone comme sur ordinateur, sans application à installer. Vos rendez-vous peuvent aussi s’afficher dans Google Agenda, sur l’iPhone ou dans Outlook."],
  ["Je travaille en équipe, c’est possible ?", "Oui, avec autant de personnes que vous voulez. Chacun a son agenda, et vous choisissez qui peut modifier l’entreprise."],
  ["Où sont mes données ?", "Elles sont hébergées en France. Vous pouvez exporter vos clients à tout moment, et supprimer votre compte et vos données quand vous le souhaitez."],
  ["Je peux reprendre mes clients existants ?", "Oui : importez-les d’un coup depuis Excel, Google Contacts ou votre téléphone. Flo repère les doublons."],
];

export default function Decouvrir() {
  const jsonLd = {
    "@context": "https://schema.org", "@type": "SoftwareApplication", name: "Flo", applicationCategory: "BusinessApplication", operatingSystem: "Web",
    description: DESC, url: `${SITE}/`, inLanguage: "fr", offers: { "@type": "Offer", price: TARIF.lancement, priceCurrency: "EUR" },
  };
  return (
    <div className={s.page}>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <Cinema demo={demo} />

      <main>
        <section className={s.sec} id="tarif">
          <div className={s.wrap}>
            <div className={s.head}><h2 className={s.h2}>Un seul paiement, à vie.</h2><p className={s.lead}>Pas d’abonnement : vous payez une fois, Flo est à vous, mises à jour comprises.</p></div>
            <div className={s.priceGrid}>
              <div className={s.price}>
                <span className={s.kicker}>Offre de lancement</span>
                <div className={s.big}>{eur(TARIF.lancement)} <s>{eur(TARIF.normal)}</s></div>
                <p style={{ marginTop: 8, fontWeight: 600 }}>ou {TARIF.fois} × {eur(mensualite(TARIF.lancement))}, sans frais</p>
                <p className={s.small}>Pour les {TARIF.places} premiers artisans, puis {eur(TARIF.normal)}. TVA non applicable, art. 293 B du CGI.</p>
                <ul className={s.incl}>
                  <li>Agenda jour, semaine et mois</li><li>Page de réservation en ligne</li><li>Demandes, relances et statistiques</li>
                  <li>Fiches clients, import et export</li><li>Équipe : membres illimités</li><li>Synchronisation avec l’agenda du téléphone</li>
                  <li>Données hébergées en France</li><li>Assistance par e-mail</li>
                </ul>
                <div className={s.ctas} style={{ marginTop: 0 }}>
                  <Link href="/tarif" className={`${s.btn} ${s.solid}`}>Commander <Arrow /></Link>
                  <a href={demo} className={`${s.btn} ${s.ghost}`}>Demander une démo</a>
                </div>
              </div>
              <div className={`${s.photoCard}`}>
                <img src="/decouvrir/chaufferie.webp" alt="Chaufferie entretenue par un artisan" loading="lazy" />
                <div className={`${s.glass} ${s.quote}`} style={{ position: "absolute", width: "auto", animation: "none", opacity: 1, transform: "none" }}>
                  <b>Rentabilisé dès les premiers rendez-vous gagnés</b>
                  <small>Un entretien relancé à temps ou une demande qui n’est plus oubliée suffit souvent à couvrir le prix.</small>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className={s.sec} id="questions" style={{ paddingTop: 0 }}>
          <div className={s.wrap}>
            <div className={s.head}><h2 className={s.h2}>Questions fréquentes</h2></div>
            <div className={s.faq}>
              {FAQ.map(([q, a], i) => <details key={q} open={i === 0}><summary>{q}</summary><p>{a}</p></details>)}
            </div>
          </div>
        </section>

        <section className={`${s.sec} ${s.final}`} style={{ paddingTop: 0 }}>
          <div className={s.wrap}>
            <h2 className={s.h2}>Moins de temps au téléphone, plus de temps sur le chantier.</h2>
            <div className={s.ctas}><a href={demo} className={`${s.btn} ${s.solid}`}>Demander une démo <Arrow /></a><Link href="/tarif" className={`${s.btn} ${s.ghost}`}>Voir le tarif</Link></div>
          </div>
        </section>
      </main>

      <footer className={s.footer}>
        <div className={s.wrap}>
          <div className={s.footCols}>
            <div><span className={s.logo}>Flo<i /></span><p>Le logiciel de rendez-vous des artisans. Conçu en France, données hébergées en France.</p></div>
            <div><h4>Flo</h4><ul><li><a href="#fonctions">Fonctionnalités</a></li><li><Link href="/tarif">Tarif</Link></li><li><Link href="/connexion">Se connecter</Link></li></ul></div>
            <div><h4>Informations</h4><ul><li><Link href="/mentions-legales">Mentions légales</Link></li><li><Link href="/cgu">Conditions d’utilisation</Link></li><li><Link href="/confidentialite">Confidentialité</Link></li><li><a href={`mailto:${CONTACT}`}>Contact</a></li></ul></div>
          </div>
          <div className={s.legal}><span>© {new Date().getFullYear()} Flo</span><span>Photos et vidéo d’illustration : Unsplash, Pexels</span></div>
        </div>
      </footer>

      <div className={s.mobileCta}><Link href="/tarif" className={`${s.btn} ${s.ghost}`}>Tarif</Link><a href={demo} className={`${s.btn} ${s.solid}`}>Démo</a></div>
    </div>
  );
}
