/* eslint-disable @next/next/no-img-element -- images statiques déjà optimisées en WebP dans /public/decouvrir */
import type { Metadata } from "next";
import Link from "next/link";
import { CONTACT, TARIF, eur, mensualite } from "@/lib/tarif";
import Tabs, { type Feature } from "./Tabs";
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

const FEATURES: Feature[] = [
  { tab: "Agenda", title: "Toute votre semaine d’un coup d’œil", text: "Jour, semaine ou mois : vos rendez-vous et ceux de votre équipe, au même endroit.", img: "/decouvrir/ecran-agenda.webp", alt: "Agenda de la semaine dans Flo",
    points: ["Un créneau déjà pris est refusé, impossible de vous mettre deux clients en même temps", "Vos horaires et vos congés sont respectés", "Chaque rendez-vous garde l’historique du client"] },
  { tab: "Réservation en ligne", title: "Vos clients réservent eux-mêmes", text: "Une page à votre nom, à partager par SMS ou sur votre site : le client choisit sa prestation et un créneau libre.", img: "/decouvrir/ecran-reservation.webp", alt: "Page de réservation en ligne sur téléphone", phone: true,
    points: ["Pas de compte à créer pour le client", "Seuls vos créneaux libres sont proposés", "Vous acceptez ou refusez chaque demande en un geste"] },
  { tab: "Demandes", title: "Plus aucune demande oubliée", text: "Les réservations en ligne et les e-mails de vos clients arrivent au même endroit, avec une pastille tant qu’ils ne sont pas traités.", img: "/decouvrir/ecran-demandes.webp", alt: "Demandes à traiter dans Flo",
    points: ["Collez un e-mail : Flo retrouve la fiche du client, ou la crée", "Réponse prête à envoyer par e-mail ou SMS", "Le rendez-vous se crée en un clic"] },
  { tab: "Tableau de bord", title: "Ce qui compte aujourd’hui", text: "Le matin, vous voyez vos rendez-vous du jour, ce qu’il reste à confirmer et l’activité du mois.", img: "/decouvrir/ecran-tableau.webp", alt: "Tableau de bord de Flo",
    points: ["Prochains rendez-vous et calendrier du mois", "Rendez-vous à confirmer mis en avant", "Statistiques : rendez-vous, prospects, annulations"] },
];

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
      <div className={s.announce}>Offre de lancement : <b>{eur(TARIF.lancement)} à vie</b> pour les {TARIF.places} premiers artisans, au lieu de {eur(TARIF.normal)}.</div>
      <header className={s.header}>
        <div className={`${s.wrap} ${s.top}`}>
          <Link href="/" className={s.logo} aria-label="Flo, accueil">Flo<i /></Link>
          <nav className={s.nav} aria-label="Navigation"><a href="#fonctions">Fonctionnalités</a><a href="#telephone">Sur téléphone</a><a href="#tarif">Tarif</a><a href="#questions">Questions</a></nav>
          <Link href="/connexion" className={s.login}>Se connecter</Link>
          <a href={demo} className={`${s.btn} ${s.solid}`}>Demander une démo</a>
        </div>
      </header>

      <main>
        <section className={s.hero}>
          <div className={`${s.wrap} ${s.heroGrid}`}>
            <div>
              <span className={s.kicker}>Logiciel de rendez-vous pour artisans</span>
              <h1 className={s.h1}>Vos rendez-vous s’organisent. <span className={s.orange}>Vous restez sur le chantier.</span></h1>
              <p className={s.lead}>Agenda, réservation en ligne, demandes reçues par e-mail et relances d’entretien : Flo réunit tout ce qui vous fait perdre du temps au téléphone.</p>
              <div className={s.ctas}>
                <a href={demo} className={`${s.btn} ${s.solid}`}>Demander une démo <Arrow /></a>
                <a href="#tarif" className={`${s.btn} ${s.ghost}`}>Voir le tarif</a>
              </div>
              <div className={s.trust}><span>Paiement unique, pas d’abonnement</span><span>Hébergé en France</span><span>Équipe illimitée</span></div>
            </div>
            <div className={s.visual}>
              <img src="/decouvrir/artisan.webp" alt="Artisan sur un chantier" fetchPriority="high" />
              <div className={`${s.glass} ${s.g1}`}><span className={`${s.tag} ${s.tagNew}`}>Nouvelle demande</span><b>Entretien chaudière</b><small>Réservé en ligne · mardi 8 h 00</small></div>
              <div className={`${s.glass} ${s.g2}`}><span className={`${s.tag} ${s.tagOk}`}>Confirmé</span><b>Dépannage fuite</b><small>Ajouté à votre agenda de téléphone</small></div>
              <div className={`${s.glass} ${s.g3}`}><span className={`${s.tag} ${s.tagLine}`}>À relancer</span><b>3 entretiens annuels</b><small>Message prêt à envoyer</small></div>
            </div>
          </div>
        </section>

        <div className={s.wrap}>
          <p className={s.tradesNote}>Pensé pour les métiers qui travaillent sur rendez-vous</p>
          <div className={s.trades}><div>Plombiers</div><div>Chauffagistes</div><div>Électriciens</div><div>Paysagistes</div><div>Piscinistes</div><div>Dépanneurs</div></div>
        </div>

        <section className={s.sec} id="fonctions">
          <div className={s.wrap}>
            <div className={s.head}><h2 className={s.h2}>Tout votre planning, dans un seul outil.</h2><p className={s.lead}>Voici Flo, tel que vous l’utiliserez. Choisissez une fonction pour la voir.</p></div>
            <Tabs items={FEATURES} />
            <div className={s.cards}>
              <div className={s.card}><span className={s.ic}><svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6"><path d="M4 10a6 6 0 1 0 2-4.5M4 3v3h3" /></svg></span><h3>Relances d’entretien</h3><p>Flo repère les entretiens à refaire, les demandes restées sans réponse et les prospects à rappeler, avec le message déjà rédigé.</p></div>
              <div className={s.card}><span className={s.ic}><svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6"><circle cx="10" cy="7" r="3" /><path d="M4 17c1-3 3.5-4.5 6-4.5s5 1.5 6 4.5" /></svg></span><h3>Fiches clients</h3><p>Coordonnées, adresse, notes et historique des rendez-vous. Import depuis Excel ou Google Contacts, export quand vous voulez.</p></div>
              <div className={s.card}><span className={s.ic}><svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.6"><circle cx="7" cy="7" r="2.5" /><circle cx="14" cy="8" r="2" /><path d="M2 16c.8-2.5 2.6-3.8 5-3.8s4.2 1.3 5 3.8M12.5 12.4c2 0 3.6 1.1 4.5 3.6" /></svg></span><h3>Équipe illimitée</h3><p>Invitez vos salariés : chacun a son agenda, et vous décidez qui peut modifier les prestations et l’entreprise.</p></div>
            </div>
          </div>
        </section>

        <section className={`${s.sec} ${s.band}`} id="telephone">
          <div className={`${s.wrap} ${s.bandGrid}`}>
            <div className={s.phones}>
              <img src="/decouvrir/ecran-mobile.webp" alt="Flo sur téléphone : tableau de bord" loading="lazy" />
              <img src="/decouvrir/ecran-reservation.webp" alt="Page de réservation sur téléphone" loading="lazy" />
            </div>
            <div>
              <h2 className={s.h2}>Votre agenda Flo, aussi dans votre téléphone.</h2>
              <p className={s.lead} style={{ marginTop: 14 }}>Ajoutez votre lien Flo une seule fois : vos rendez-vous apparaissent dans l’agenda que vous utilisez déjà, et se mettent à jour tout seuls.</p>
              <div className={s.syncs}><span>Google Agenda</span><span>iPhone et Mac</span><span>Outlook</span></div>
              <ol className={s.steps}>
                <li><b>01</b>Le client réserve sur votre page, ou vous écrit par e-mail.</li>
                <li><b>02</b>Vous acceptez la demande en un geste, depuis le chantier.</li>
                <li><b>03</b>Le rendez-vous s’ajoute à votre agenda, avec l’adresse et le téléphone du client.</li>
              </ol>
              <a href={demo} className={`${s.btn} ${s.outlineW}`} style={{ marginTop: 26 }}>Voir une démonstration</a>
            </div>
          </div>
        </section>

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
          <div className={s.legal}><span>© {new Date().getFullYear()} Flo</span><span>Photos d’illustration : Unsplash</span></div>
        </div>
      </footer>

      <div className={s.mobileCta}><Link href="/tarif" className={`${s.btn} ${s.ghost}`}>Tarif</Link><a href={demo} className={`${s.btn} ${s.solid}`}>Démo</a></div>
    </div>
  );
}
