/* eslint-disable @next/next/no-img-element -- captures de Flo déjà optimisées en WebP dans /public/decouvrir */
import type { Metadata } from "next";
import Link from "next/link";
import { CONTACT, TARIF, eur, mensualite } from "@/lib/tarif";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import FloLogo, { FloMark } from "@/components/FloLogo";
import Rotator from "./Rotator";
import { Cube, Mark3D, RevealInit, ThemeToggle, themeScript } from "./Effects";
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

const FAQ = [
  ["Faut-il payer un abonnement ?", `Non. Flo se paie une seule fois : ${eur(TARIF.lancement)} pour les ${TARIF.places} premiers artisans, puis ${eur(TARIF.normal)}, en une fois ou en ${TARIF.fois} virements sans frais. Les mises à jour sont comprises.`],
  ["Mes clients doivent-ils créer un compte ?", "Non. Ils ouvrent votre page de réservation, choisissent une prestation et un créneau, et laissent leurs coordonnées. C’est tout."],
  ["Est-ce que ça marche sur téléphone ?", "Oui. Flo s’utilise dans le navigateur, sur téléphone comme sur ordinateur, sans application à installer. Vos rendez-vous peuvent aussi s’afficher dans Google Agenda, sur l’iPhone ou dans Outlook."],
  ["Je ne suis pas à l’aise avec l’informatique.", "Pas besoin : on installe Flo avec vous, on ajoute vos prestations et vos clients, et on place votre lien de réservation sur votre fiche Google et votre site."],
  ["Je travaille en équipe, c’est possible ?", "Oui, avec autant de personnes que vous voulez. Chacun a son agenda, et vous choisissez qui peut modifier l’entreprise."],
  ["Où sont mes données ?", "Elles sont hébergées en France. Vous pouvez exporter vos clients à tout moment, et supprimer votre compte et vos données quand vous le souhaitez."],
];

const Check = () => <svg className={s.check} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden><path d="M3 8.5l3 3 7-7" /></svg>;

// Une grande section : titre, maquette qui s'efface vers le bas, phrase (noir puis gris) et liste de fonctions.
function Feature({ title, strong, rest, items, children, rev, id }: { title: string; strong: string; rest: string; items: string[]; children: React.ReactNode; rev?: boolean; id?: string }) {
  return (
    <section className={`${s.wrap} ${s.feature} ${rev ? s.rev : ""}`} id={id}>
      <h2 className={s.h2} data-reveal>{title}</h2>
      <div className={s.mock} data-reveal>{children}</div>
      <aside className={s.side} data-reveal>
        <p className={s.statement}><b>{strong}</b> {rest}</p>
        <p className={s.sideLabel}>Fonctions</p>
        <ul className={s.sideList}>{items.map((t) => <li key={t}>{t}</li>)}</ul>
      </aside>
    </section>
  );
}

export default function Decouvrir() {
  const jsonLd = {
    "@context": "https://schema.org", "@type": "SoftwareApplication", name: "Flo", applicationCategory: "BusinessApplication", operatingSystem: "Web",
    description: DESC, url: `${SITE}/`, inLanguage: "fr", offers: { "@type": "Offer", price: TARIF.lancement, priceCurrency: "EUR" },
  };
  return (
    <div className={`${s.page} ${GeistSans.variable} ${GeistMono.variable}`}>
      <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <RevealInit />

      <header className={s.nav}>
        <div className={`${s.wrap} ${s.navIn}`}>
          <Link href="/" aria-label="Flo, accueil" className={s.brand}><FloLogo size={20} /></Link>
          <nav className={s.links}><a href="#fonctions">Fonctionnalités</a><a href="#tarif">Tarif</a><a href="#questions">Questions</a></nav>
          <div className={s.navRight}>
            <a href={demo} className={`${s.btn} ${s.ghost} ${s.sm}`}>Demander une démo</a>
            <Link href="/connexion" className={`${s.btn} ${s.ghost} ${s.sm}`}>Se connecter</Link>
            <Link href="/tarif" className={`${s.btn} ${s.solid} ${s.sm}`}>Commander</Link>
            <ThemeToggle />
          </div>
          <div className={s.mobileTheme}><ThemeToggle /></div>
          <details className={s.menu}>
            <summary aria-label="Menu"><span /><span /></summary>
            <div className={s.menuPanel}>
              <a href="#fonctions">Fonctionnalités</a><a href="#tarif">Tarif</a><a href="#questions">Questions</a>
              <Link href="/connexion">Se connecter</Link>
              <a href={demo} className={`${s.btn} ${s.solid} ${s.pill}`}>Demander une démo</a>
            </div>
          </details>
        </div>
      </header>

      <main>
        {/* Accueil : titre à gauche, symbole lumineux au centre, trois phrases à droite */}
        <section className={`${s.wrap} ${s.hero}`}>
          <div className={s.heroText}>
            <h1 className={s.display}>Rendez-vous en ligne<br /> pour artisans</h1>
            <Rotator className={s.rotator} words={METIERS.map((m) => `Pour les ${m.toLowerCase()}`)} />
          </div>
          <div className={s.glow}><Mark3D /></div>
          <ul className={s.heroLines}>
            <li>Vos clients réservent eux-mêmes</li>
            <li>Les demandes arrivent rangées</li>
            <li>Les entretiens sont relancés</li>
          </ul>
        </section>

        <section className={s.strip} aria-label="Métiers">
          <div className={s.marquee}>
            {[0, 1].map((n) => <ul key={n} aria-hidden={n === 1}>{METIERS.map((m) => <li key={m}>{m}</li>)}</ul>)}
          </div>
        </section>

        <Feature id="fonctions" title="Vos clients réservent, sans vous appeler" strong="Une page de réservation à votre nom," rest="ouverte jour et nuit, sur votre fiche Google, votre site ou vos SMS."
          items={["Choix de la prestation", "Seulement vos créneaux libres", "Sans compte pour le client", "Accepter ou refuser en un geste"]}>
          <div className={`${s.window} ${s.windowBack}`}><img src="/decouvrir/ecran-agenda.webp" alt="Agenda de Flo" loading="lazy" width={1600} height={1111} /></div>
          <div className={s.phone}><img src="/decouvrir/ecran-reservation.webp" alt="Page de réservation de Flo sur téléphone" loading="lazy" width={700} height={1192} /></div>
        </Feature>

        <Feature rev title="Toutes les demandes au même endroit" strong="Réservations et e-mails arrivent dans Demandes," rest="rangés et prêts à être acceptés, même quand vous êtes sur un chantier."
          items={["Réservations en ligne", "E-mails des clients", "Réponses rapides", "Pastille pour les nouveautés"]}>
          <div className={s.window}><img src="/decouvrir/ecran-demandes.webp" alt="Demandes dans Flo" loading="lazy" width={1600} height={1111} /></div>
        </Feature>

        <Feature title="Votre semaine, dans votre téléphone" strong="Chaque rendez-vous s’affiche aussi" rest="dans l’agenda que vous utilisez déjà, avec l’adresse et le téléphone du client."
          items={["Jour, semaine et mois", "Un agenda par personne", "Google Agenda, iPhone, Outlook", "Fiches clients et historique"]}>
          <div className={s.calendar}>
            <div className={s.calHead}><b>Mardi 24</b><span>Novembre</span></div>
            {[["08:00", "Fuite sous l’évier", "Claire D. · 12 rue Sainte-Catherine"], ["10:30", "Entretien chaudière", "M. Dupont · Talence"], ["14:00", "Devis salle de bain", "Mme Laurent · Mérignac"]].map(([h, t, d], k) => (
              <div key={h} className={s.event} data-reveal style={{ "--d": k + 2 } as React.CSSProperties}><span>{h}</span><div><b>{t}</b><small>{d}</small></div><FloMark size={14} /></div>
            ))}
          </div>
        </Feature>

        {/* Trois cartes, comme une vitrine */}
        <section className={`${s.wrap} ${s.sec}`}>
          <h2 className={s.h2} data-reveal>Inclus dans Flo</h2>
          <div className={s.cards}>
            <article className={s.card} data-reveal>
              <p className={s.cardLabel}>Relances</p>
              <div className={s.mini}>
                <p><span>Entretien à refaire</span><b>M. Dupont · chaudière</b><small>Dernier passage il y a 11 mois</small></p>
                <p className={s.miniMsg}>« Bonjour M. Dupont, l’entretien annuel de votre chaudière arrive : voici mes prochains créneaux… »</p>
              </div>
              <h3 className={s.h4}>Relances d’entretien</h3><p className={s.small}>Flo se souvient des entretiens à refaire et rédige le message.</p>
            </article>
            <article className={s.card} data-reveal style={{ "--d": 1 } as React.CSSProperties}>
              <p className={s.cardLabel}>Équipe</p>
              <div className={s.mini}>
                {[["T", "Thomas", "Propriétaire"], ["L", "Léa", "Technicienne"], ["K", "Karim", "Apprenti"]].map(([a, n, r]) => <p key={n} className={s.member}><i>{a}</i><b>{n}</b><small>{r}</small></p>)}
              </div>
              <h3 className={s.h4}>Équipe illimitée</h3><p className={s.small}>Chacun son agenda. Vous choisissez qui peut modifier l’entreprise.</p>
            </article>
            <article className={`${s.card} ${s.dark}`} data-reveal style={{ "--d": 2 } as React.CSSProperties}>
              <p className={s.cardLabel}>Données</p>
              <div className={s.mini}><Cube faces={["FR", "RGPD", "FR", "UE", "", ""]} /></div>
              <h3 className={s.h4}>Hébergé en France</h3><p className={s.small}>Export de vos clients et suppression de vos données à tout moment.</p>
            </article>
          </div>
        </section>

        {/* Mise en route */}
        <section className={`${s.wrap} ${s.sec}`}>
          <h2 className={s.h2} data-reveal>On l’installe avec vous</h2>
          <ol className={s.steps}>
            <li data-reveal><span>01</span><h3 className={s.h4}>On prépare votre Flo</h3><p className={s.small}>Prestations, horaires, équipe, et vos clients importés.</p></li>
            <li data-reveal style={{ "--d": 1 } as React.CSSProperties}><span>02</span><h3 className={s.h4}>Vous partagez votre lien</h3><p className={s.small}>Sur votre fiche Google, votre site, Instagram et vos SMS. On peut le faire pour vous.</p></li>
            <li data-reveal style={{ "--d": 2 } as React.CSSProperties}><span>03</span><h3 className={s.h4}>Les rendez-vous arrivent</h3><p className={s.small}>Dans Flo et dans l’agenda de votre téléphone.</p></li>
          </ol>
        </section>

        {/* Tarif */}
        <section className={`${s.wrap} ${s.sec}`} id="tarif">
          <h2 className={s.h2} data-reveal>Un seul paiement, à vie</h2>
          <div className={s.priceGrid}>
            <div className={`${s.card} ${s.price}`} data-reveal>
              <p className={s.cardLabel}>Offre de lancement · {TARIF.places} premiers artisans</p>
              <div className={s.amount}>{eur(TARIF.lancement)} <s>{eur(TARIF.normal)}</s></div>
              <p className={s.small}>ou {TARIF.fois} × {eur(mensualite(TARIF.lancement))}, sans frais. TVA non applicable, art. 293 B du CGI.</p>
              <ul className={s.ticks}>
                <li><Check />Agenda, réservation en ligne, demandes</li><li><Check />Relances d’entretien et statistiques</li>
                <li><Check />Équipe : membres illimités</li><li><Check />Synchronisation avec le téléphone</li>
                <li><Check />Installation et assistance par e-mail</li><li><Check />Mises à jour comprises</li>
              </ul>
              <div className={s.ctas}>
                <Link href="/tarif" className={`${s.btn} ${s.solid} ${s.pill}`}>Commander</Link>
                <a href={demo} className={`${s.btn} ${s.ghost} ${s.pill}`}>Demander une démo</a>
              </div>
            </div>
            <aside className={s.side} data-reveal>
              <p className={s.statement}><b>Rentabilisé dès les premiers rendez-vous gagnés.</b> Un entretien relancé à temps ou une demande qui n’est plus oubliée suffit souvent à couvrir le prix.</p>
            </aside>
          </div>
        </section>

        <section className={`${s.wrap} ${s.sec}`} id="questions">
          <h2 className={s.h2} data-reveal>Questions fréquentes</h2>
          <div className={s.faq} data-reveal>
            {FAQ.map(([q, a], i) => <details key={q} open={i === 0}><summary>{q}</summary><p>{a}</p></details>)}
          </div>
        </section>

        <section className={`${s.wrap} ${s.final}`}>
          <h2 className={s.h2} data-reveal>Moins de téléphone. Plus de chantier.</h2>
          <div className={s.ctas}><a href={demo} className={`${s.btn} ${s.solid} ${s.pill}`}>Demander une démo</a><Link href="/tarif" className={`${s.btn} ${s.ghost} ${s.pill}`}>Voir le tarif</Link></div>
        </section>
      </main>

      <footer className={s.footer}>
        <div className={`${s.wrap} ${s.footCols}`}>
          <div><h4>Flo</h4><ul><li><a href="#fonctions">Fonctionnalités</a></li><li><Link href="/tarif">Tarif</Link></li><li><Link href="/connexion">Se connecter</Link></li></ul></div>
          <div><h4>Métiers</h4><ul>{METIERS.slice(0, 4).map((m) => <li key={m}>{m}</li>)}</ul></div>
          <div><h4>Informations</h4><ul><li><Link href="/mentions-legales">Mentions légales</Link></li><li><Link href="/cgu">Conditions d’utilisation</Link></li><li><Link href="/confidentialite">Confidentialité</Link></li><li><a href={`mailto:${CONTACT}`}>Contact</a></li></ul></div>
        </div>
        <div className={`${s.wrap} ${s.legal}`}><span className={s.brand}><FloLogo size={16} /></span><span>Conçu en France, données hébergées en France · © {new Date().getFullYear()}</span></div>
      </footer>
    </div>
  );
}
