/* eslint-disable @next/next/no-img-element -- captures de Flo déjà optimisées en WebP dans /public/decouvrir */
import type { Metadata } from "next";
import Link from "next/link";
import { CONTACT, TARIF, eur, mensualite } from "@/lib/tarif";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import FloLogo, { FloMark } from "@/components/FloLogo";
import s from "./site.module.css";

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

const METIERS = ["Plombiers", "Chauffagistes", "Électriciens", "Pisciniers", "Paysagistes", "Serruriers", "Climaticiens"];

// Journal d'une matinée type : ce que Flo fait pendant que l'artisan travaille.
const JOURNAL: [string, string, boolean][] = [
  ["08:02", "Nouvelle réservation : Claire D. · fuite sous l’évier · mardi 8 h 00", false],
  ["08:02", "Ajoutée à votre agenda et à votre téléphone", true],
  ["09:15", "E-mail reçu : « Bonjour, ma chaudière fait un bruit bizarre… »", false],
  ["09:15", "Rangé dans Demandes, prêt à être accepté", true],
  ["10:30", "Entretien à refaire : M. Dupont, chaudière, il y a 11 mois", false],
  ["10:30", "Message de relance déjà rédigé", true],
];

const FAQ = [
  ["Faut-il payer un abonnement ?", `Non. Flo se paie une seule fois : ${eur(TARIF.lancement)} pour les ${TARIF.places} premiers artisans, puis ${eur(TARIF.normal)}, en une fois ou en ${TARIF.fois} virements sans frais. Les mises à jour sont comprises.`],
  ["Mes clients doivent-ils créer un compte ?", "Non. Ils ouvrent votre page de réservation, choisissent une prestation et un créneau, et laissent leurs coordonnées. C’est tout."],
  ["Est-ce que ça marche sur téléphone ?", "Oui. Flo s’utilise dans le navigateur, sur téléphone comme sur ordinateur, sans application à installer. Vos rendez-vous peuvent aussi s’afficher dans Google Agenda, sur l’iPhone ou dans Outlook."],
  ["Je ne suis pas à l’aise avec l’informatique.", "Pas besoin : on installe Flo avec vous, on ajoute vos prestations et vos clients, et on place votre lien de réservation sur votre fiche Google et votre site."],
  ["Je travaille en équipe, c’est possible ?", "Oui, avec autant de personnes que vous voulez. Chacun a son agenda, et vous choisissez qui peut modifier l’entreprise."],
  ["Où sont mes données ?", "Elles sont hébergées en France. Vous pouvez exporter vos clients à tout moment, et supprimer votre compte et vos données quand vous le souhaitez."],
];

const Check = () => <svg className={s.check} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden><path d="M3 8.5l3 3 7-7" /></svg>;

export default function Decouvrir() {
  const jsonLd = {
    "@context": "https://schema.org", "@type": "SoftwareApplication", name: "Flo", applicationCategory: "BusinessApplication", operatingSystem: "Web",
    description: DESC, url: `${SITE}/`, inLanguage: "fr", offers: { "@type": "Offer", price: TARIF.lancement, priceCurrency: "EUR" },
  };
  return (
    <div className={`${s.page} ${GeistSans.variable} ${GeistMono.variable}`}>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <header className={s.nav}>
        <div className={`${s.wrap} ${s.navIn}`}>
          <Link href="/" aria-label="Flo, accueil" className={s.brand}><FloLogo size={20} /></Link>
          <nav className={s.links}><a href="#fonctions">Fonctionnalités</a><a href="#tarif">Tarif</a><a href="#questions">Questions</a></nav>
          <div className={s.navRight}>
            <Link href="/connexion" className={`${s.btn} ${s.ghost}`}>Se connecter</Link>
            <a href={demo} className={`${s.btn} ${s.solid} ${s.pill}`}>Demander une démo</a>
          </div>
        </div>
      </header>

      <main>
        {/* Accueil : titre à gauche, symbole au centre, ce qui est inclus à droite */}
        <section className={`${s.wrap} ${s.hero}`}>
          <div className={s.heroText}>
            <p className={s.eyebrow}>Logiciel de rendez-vous pour artisans</p>
            <h1 className={s.display}>Vos clients réservent. Vous restez sur le chantier.</h1>
            <p className={s.lead}>Agenda, réservation en ligne, demandes et relances d’entretien, au même endroit. Un seul paiement, données hébergées en France.</p>
            <div className={s.ctas}>
              <a href={demo} className={`${s.btn} ${s.solid}`}>Demander une démo</a>
              <a href="#tarif" className={`${s.btn} ${s.ghost}`}>Voir le tarif</a>
            </div>
          </div>
          <FloMark className={s.heroMark} size={240} color="#000" />
          <ul className={s.heroStack}>
            {["Agenda", "Réservation en ligne", "Demandes", "Relances d’entretien", "Équipe illimitée"].map((t, k) => <li key={t}><span>0{k + 1}</span>{t}</li>)}
          </ul>
        </section>

        {/* Le produit en action, comme un journal */}
        <section className={s.wrap}>
          <div className={s.journal}>
            <div className={s.journalHead}><span>Journal de Flo · Plomberie Martin</span><span>Mardi</span></div>
            <ol>
              {JOURNAL.map(([h, t, ok], k) => (
                <li key={k} className={ok ? s.ok : undefined}>
                  <span className={s.time}>{h}</span>
                  {ok ? <Check /> : <FloMark size={12} color="#000" className={s.bullet} />}
                  <span>{t}</span>
                </li>
              ))}
            </ol>
          </div>
        </section>

        <section className={`${s.wrap} ${s.strip}`}>
          <p className={s.eyebrow}>Pensé pour les artisans</p>
          <ul>{METIERS.map((m) => <li key={m}>{m}</li>)}</ul>
        </section>

        {/* Réservation en ligne */}
        <section className={`${s.wrap} ${s.sec} ${s.split}`}>
          <div>
            <p className={s.eyebrow}>Réservation en ligne</p>
            <h2 className={s.h2}>Une page de réservation à votre nom.</h2>
            <p className={s.body}>Le client choisit sa prestation et un créneau libre, sans créer de compte. Vous mettez le lien sur votre fiche Google, votre site, Instagram ou vos SMS.</p>
            <ul className={s.ticks}>
              <li><Check />Seulement vos créneaux libres, selon vos horaires</li>
              <li><Check />Vous acceptez ou refusez en un geste</li>
              <li><Check />Coordonnées et adresse du client incluses</li>
            </ul>
          </div>
          <div className={`${s.card} ${s.phoneCard}`}>
            <img src="/decouvrir/ecran-reservation.webp" alt="Page de réservation de Flo sur téléphone" loading="lazy" width={700} height={1192} />
          </div>
        </section>

        {/* Fonctionnalités */}
        <section className={`${s.wrap} ${s.sec}`} id="fonctions">
          <p className={s.eyebrow}>Tout est inclus</p>
          <h2 className={s.h2}>Tout ce qu’il faut, rien de plus.</h2>
          <div className={s.grid2}>
            <article className={s.card}>
              <h3 className={s.h3}>Agenda</h3>
              <p className={s.body}>Jour, semaine, mois. Chaque membre de l’équipe a le sien.</p>
              <img className={s.shot} src="/decouvrir/ecran-agenda.webp" alt="Agenda de Flo" loading="lazy" width={1600} height={1111} />
            </article>
            <article className={s.card}>
              <h3 className={s.h3}>Demandes</h3>
              <p className={s.body}>Réservations et e-mails arrivent au même endroit, prêts à être traités.</p>
              <img className={s.shot} src="/decouvrir/ecran-demandes.webp" alt="Demandes dans Flo" loading="lazy" width={1600} height={1111} />
            </article>
          </div>
          <div className={s.grid4}>
            <article className={s.card}>
              <h3 className={s.h4}>Relances d’entretien</h3>
              <p className={s.small}>Flo se souvient des entretiens à refaire et rédige le message.</p>
            </article>
            <article className={s.card}>
              <h3 className={s.h4}>Agenda du téléphone</h3>
              <p className={s.small}>Vos rendez-vous dans le calendrier que vous utilisez déjà.</p>
              <div className={s.chips}><span>Google Agenda</span><span>iPhone</span><span>Outlook</span></div>
            </article>
            <article className={s.card}>
              <h3 className={s.h4}>Fiches clients</h3>
              <p className={s.small}>Historique, adresse, téléphone. Import depuis Excel ou vos contacts.</p>
            </article>
            <article className={`${s.card} ${s.dark}`}>
              <h3 className={s.h4}>Hébergé en France</h3>
              <p className={s.small}>Vos données restent à vous : export et suppression à tout moment.</p>
            </article>
          </div>
        </section>

        {/* Mise en route */}
        <section className={`${s.wrap} ${s.sec}`}>
          <p className={s.eyebrow}>Mise en route</p>
          <h2 className={s.h2}>On l’installe avec vous.</h2>
          <ol className={s.steps}>
            <li><span>01</span><h3 className={s.h4}>On prépare votre Flo</h3><p className={s.small}>Prestations, horaires, équipe, et vos clients importés.</p></li>
            <li><span>02</span><h3 className={s.h4}>Vous partagez votre lien</h3><p className={s.small}>Sur votre fiche Google, votre site, Instagram et vos SMS. On peut le faire pour vous.</p></li>
            <li><span>03</span><h3 className={s.h4}>Les rendez-vous arrivent</h3><p className={s.small}>Dans Flo et dans l’agenda de votre téléphone.</p></li>
          </ol>
        </section>

        {/* Tarif */}
        <section className={`${s.wrap} ${s.sec}`} id="tarif">
          <p className={s.eyebrow}>Tarif</p>
          <h2 className={s.h2}>Un seul paiement, à vie.</h2>
          <div className={s.priceGrid}>
            <div className={`${s.card} ${s.price}`}>
              <p className={s.eyebrow}>Offre de lancement · {TARIF.places} premiers artisans</p>
              <div className={s.amount}>{eur(TARIF.lancement)} <s>{eur(TARIF.normal)}</s></div>
              <p className={s.body}>ou {TARIF.fois} × {eur(mensualite(TARIF.lancement))}, sans frais. TVA non applicable, art. 293 B du CGI.</p>
              <ul className={s.ticks}>
                <li><Check />Agenda, réservation en ligne, demandes</li><li><Check />Relances d’entretien et statistiques</li>
                <li><Check />Équipe : membres illimités</li><li><Check />Synchronisation avec le téléphone</li>
                <li><Check />Installation et assistance par e-mail</li><li><Check />Mises à jour comprises</li>
              </ul>
              <div className={s.ctas}>
                <Link href="/tarif" className={`${s.btn} ${s.solid}`}>Commander</Link>
                <a href={demo} className={`${s.btn} ${s.ghost}`}>Demander une démo</a>
              </div>
            </div>
            <div className={`${s.card} ${s.dark} ${s.priceSide}`}>
              <FloMark size={56} color="#fff" />
              <p className={s.h3}>Rentabilisé dès les premiers rendez-vous gagnés.</p>
              <p className={s.small}>Un entretien relancé à temps ou une demande qui n’est plus oubliée suffit souvent à couvrir le prix.</p>
            </div>
          </div>
        </section>

        <section className={`${s.wrap} ${s.sec}`} id="questions">
          <p className={s.eyebrow}>Questions</p>
          <h2 className={s.h2}>Questions fréquentes</h2>
          <div className={s.faq}>
            {FAQ.map(([q, a], i) => <details key={q} open={i === 0}><summary>{q}</summary><p>{a}</p></details>)}
          </div>
        </section>

        <section className={`${s.wrap} ${s.sec} ${s.final}`}>
          <FloMark size={64} color="#000" />
          <h2 className={s.display}>Moins de téléphone. Plus de chantier.</h2>
          <div className={s.ctas}><a href={demo} className={`${s.btn} ${s.solid}`}>Demander une démo</a><Link href="/tarif" className={`${s.btn} ${s.ghost}`}>Voir le tarif</Link></div>
        </section>
      </main>

      <footer className={s.footer}>
        <div className={`${s.wrap} ${s.footCols}`}>
          <div><FloLogo size={18} /><p>Le logiciel de rendez-vous des artisans. Conçu en France, données hébergées en France.</p></div>
          <div><h4>Flo</h4><ul><li><a href="#fonctions">Fonctionnalités</a></li><li><Link href="/tarif">Tarif</Link></li><li><Link href="/connexion">Se connecter</Link></li></ul></div>
          <div><h4>Informations</h4><ul><li><Link href="/mentions-legales">Mentions légales</Link></li><li><Link href="/cgu">Conditions d’utilisation</Link></li><li><Link href="/confidentialite">Confidentialité</Link></li><li><a href={`mailto:${CONTACT}`}>Contact</a></li></ul></div>
        </div>
        <div className={`${s.wrap} ${s.legal}`}>© {new Date().getFullYear()} Flo</div>
      </footer>
    </div>
  );
}
