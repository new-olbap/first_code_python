"use client";
/* eslint-disable @next/next/no-img-element -- captures et images du film déjà optimisées en WebP */
import { useEffect, useRef } from "react";
import Link from "next/link";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import Lenis from "lenis";
import c from "./cinema.module.css";

const FRAMES = 119;
const frameUrl = (i: number) => `/decouvrir/film/f${String(i + 1).padStart(3, "0")}.webp`;
// Les 4 phrases du film : [début, fin] en part du défilement de la scène (la dernière reste affichée).
const BEATS: [number, number][] = [[0, 0.24], [0.28, 0.5], [0.54, 0.76], [0.8, 1]];

const PANELS = [
  { n: "01", t: "L’agenda", p: "Jour, semaine ou mois, pour vous et votre équipe.", l: ["Un créneau déjà pris est refusé", "Horaires et congés respectés", "Historique de chaque client"], img: "/decouvrir/ecran-agenda.webp", alt: "Agenda de la semaine dans Flo" },
  { n: "02", t: "La réservation en ligne", p: "Une page à votre nom : le client choisit sa prestation et un créneau libre, sans créer de compte.", l: ["Seuls vos créneaux libres sont proposés", "Vous acceptez en un geste"], img: "/decouvrir/ecran-reservation.webp", alt: "Page de réservation sur téléphone", phone: true },
  { n: "03", t: "Les demandes", p: "Réservations en ligne et e-mails de clients arrivent au même endroit, avec la réponse déjà prête.", l: ["Collez un e-mail : la fiche client est retrouvée ou créée", "Rendez-vous créé en un clic"], img: "/decouvrir/ecran-demandes.webp", alt: "Demandes à traiter dans Flo" },
  { n: "04", t: "Le tableau de bord", p: "Le matin, vos rendez-vous du jour, ce qu’il reste à confirmer et l’activité du mois. Et la page « À relancer » : entretiens à refaire, demandes sans réponse, avec le message déjà rédigé.", l: ["Rendez-vous à confirmer mis en avant", "Entretiens annuels repérés tout seuls"], img: "/decouvrir/ecran-tableau.webp", alt: "Tableau de bord de Flo" },
];

export default function Cinema({ demo }: { demo: string }) {
  const root = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = root.current!;
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) { el.classList.add(c.calm); return; }
    gsap.registerPlugin(ScrollTrigger);

    // Défilement doux (Lenis), synchronisé avec ScrollTrigger.
    const lenis = new Lenis({ lerp: 0.09, anchors: true });
    lenis.on("scroll", ScrollTrigger.update);
    const tick = (t: number) => lenis.raf(t * 1000);
    gsap.ticker.add(tick);
    gsap.ticker.lagSmoothing(0);

    // 1. Le film : une image par position de défilement, dessinée dans un canvas (plus fluide qu'une vidéo).
    const canvas = el.querySelector("canvas")!, ctx = canvas.getContext("2d")!;
    const imgs: HTMLImageElement[] = [];
    let current = 0;
    const draw = (i: number) => {
      let k = i; // image pas encore chargée : on prend la plus proche déjà prête
      while (k > 0 && !imgs[k]?.complete) k--;
      const img = imgs[k];
      if (!img?.naturalWidth) return;
      const s = Math.max(canvas.width / img.naturalWidth, canvas.height / img.naturalHeight);
      const w = img.naturalWidth * s, h = img.naturalHeight * s;
      ctx.drawImage(img, (canvas.width - w) * 0.42, (canvas.height - h) / 2, w, h);
    };
    const size = () => { const r = Math.min(devicePixelRatio, 2); canvas.width = canvas.clientWidth * r; canvas.height = canvas.clientHeight * r; draw(current); };
    for (let i = 0; i < FRAMES; i++) { const im = new Image(); im.src = frameUrl(i); if (i === 0) im.onload = () => draw(0); imgs.push(im); }
    size(); addEventListener("resize", size);

    const beats = [...el.querySelectorAll<HTMLElement>(`.${c.beat}`)], cards = [...el.querySelectorAll<HTMLElement>(`.${c.card}`)];
    const bar = el.querySelector<HTMLElement>(`.${c.progress}`)!, hint = el.querySelector<HTMLElement>(`.${c.hint}`)!;
    const win = (p: number, a: number, b: number) => Math.min(1, Math.max(0, (p - a) / 0.05), Math.max(0, (b - p) / 0.05));
    const film = ScrollTrigger.create({
      trigger: el.querySelector(`.${c.film}`), start: "top top", end: "bottom bottom", scrub: true,
      onUpdate: ({ progress: p }) => {
        current = Math.round(p * (FRAMES - 1)); draw(current);
        beats.forEach((b, i) => { const o = i === 0 ? Math.min(1, (BEATS[0][1] - p) / 0.05) : i === BEATS.length - 1 ? Math.min(1, Math.max(0, (p - BEATS[i][0]) / 0.05)) : win(p, ...BEATS[i]); b.style.opacity = String(o); b.style.transform = `translateY(${(1 - o) * 24}px)`; b.classList.toggle(c.live, o > 0.5); });
        cards.forEach((card, i) => { const o = win(p, 0.56 + i * 0.05, 0.8); card.style.opacity = String(o); card.style.transform = `translateY(${(1 - o) * 20}px)`; });
        bar.style.transform = `scaleX(${p})`; hint.style.opacity = String(Math.max(0, 1 - p * 12));
      },
    });

    // 2. L'écran de Flo arrive incliné et se redresse.
    const screen = el.querySelector<HTMLElement>(`.${c.screen}`)!, labels = [...el.querySelectorAll<HTMLElement>(`.${c.label}`)];
    const reveal = ScrollTrigger.create({
      trigger: el.querySelector(`.${c.reveal}`), start: "top top", end: "bottom bottom", scrub: true,
      onUpdate: ({ progress: p }) => {
        const q = Math.min(1, p / 0.6), e = 1 - Math.pow(1 - q, 3);
        screen.style.transform = `rotateX(${(1 - e) * 38}deg) scale(${0.72 + e * 0.28}) translateY(${(1 - e) * 60}px)`;
        labels.forEach((l, i) => { const o = Math.min(1, Math.max(0, (p - 0.62 - i * 0.07) / 0.08)); l.style.opacity = String(o); });
      },
    });

    // 3. Les fonctions défilent de côté pendant que l'on descend.
    const track = el.querySelector<HTMLElement>(`.${c.track}`)!, count = el.querySelector<HTMLElement>(`.${c.hCount}`)!;
    const hs = ScrollTrigger.create({
      trigger: el.querySelector(`.${c.hscroll}`), start: "top top", end: "bottom bottom", scrub: true,
      onUpdate: ({ progress: p }) => {
        track.style.transform = `translateX(${-p * (track.scrollWidth - innerWidth)}px)`;
        count.textContent = `0${Math.min(PANELS.length, Math.floor(p * PANELS.length * 0.999) + 1)} / 0${PANELS.length}`;
      },
    });

    // 4. Les téléphones montent à des vitesses différentes.
    const ph = [...el.querySelectorAll<HTMLElement>(`.${c.phonePair} img`)];
    const tweens = ph.map((img, i) => gsap.fromTo(img, { y: 90 + i * 70 }, { y: -40 - i * 40, ease: "none", scrollTrigger: { trigger: img.parentElement, start: "top bottom", end: "bottom top", scrub: true } }));

    addEventListener("load", () => ScrollTrigger.refresh());
    return () => {
      removeEventListener("resize", size); gsap.ticker.remove(tick); lenis.destroy();
      [film, reveal, hs].forEach((s) => s.kill()); tweens.forEach((t) => { t.scrollTrigger?.kill(); t.kill(); });
    };
  }, []);

  return (
    <div className={c.dark} ref={root}>
      <div className={c.bar}>Offre de lancement : <b>1 190 € à vie</b> pour les 20 premiers artisans.</div>
      <header className={c.header}>
        <div className={c.top}>
          <Link href="/" className={c.logo} aria-label="Flo, accueil">Flo<i /></Link>
          <nav className={c.nav} aria-label="Navigation"><a href="#fonctions">Fonctionnalités</a><a href="#telephone">Sur téléphone</a><a href="#tarif">Tarif</a><a href="#questions">Questions</a><Link href="/connexion">Se connecter</Link></nav>
          <a href={demo} className={`${c.btn} ${c.white}`}>Demander une démo</a>
        </div>
      </header>

      <section className={c.film} aria-label="Présentation de Flo">
        <div className={c.stage}>
          <canvas aria-hidden />
          <div className={c.shade} />
          <div className={c.beat} style={{ opacity: 1 }}>
            {/* Le titre principal (h1) porte les mots-clés pour Google ; la grande phrase reste l'accroche visuelle. */}
            <h1 className={c.kicker}>Logiciel de rendez-vous pour artisans</h1>
            <p className={c.huge}>Vous réparez.</p>
          </div>
          <div className={c.beat}><p className={c.big}>Le téléphone sonne. <span className={c.orange}>Encore.</span></p></div>
          <div className={c.beat}><p className={c.big}>Flo range la demande et prépare la réponse.</p></div>
          <div className={c.beat}>
            <p className={c.big}>Vous, vous restez <span className={c.orange}>sur le chantier.</span></p>
            <p className={c.sub}>Agenda, réservation en ligne, demandes et relances d’entretien : Flo organise vos rendez-vous. Paiement unique, données en France.</p>
            <div className={c.ctas}><a href={demo} className={`${c.btn} ${c.white}`}>Demander une démo</a><a href="#tarif" className={`${c.btn} ${c.ghost}`}>Voir le tarif</a></div>
          </div>
          <div className={c.cards} aria-hidden>
            <div className={c.card}><span className={`${c.tag} ${c.tagNew}`}>Nouvelle demande</span><b>Fuite sous l’évier</b><small>Réservé en ligne · mardi 8 h 00</small></div>
            <div className={c.card}><span className={c.tag}>Réponse prête</span><b>« Bonjour, je passe mardi à 8 h. »</b><small>À envoyer par SMS ou e-mail</small></div>
          </div>
          <div className={c.progress} />
          <div className={c.hint}>Faites défiler</div>
        </div>
      </section>

      <section className={c.reveal} aria-label="Voici Flo">
        <div className={c.revealStage}>
          <div className={c.revealTitle}><p className={c.big} style={{ maxWidth: "none" }}>Voici <span className={c.orange}>Flo.</span></p><p>Tout ce qui vous fait perdre du temps au téléphone, réuni dans un seul écran.</p></div>
          <div className={c.screen}><img src="/decouvrir/ecran-tableau.webp" alt="Tableau de bord de Flo" /></div>
          <div className={c.labels} aria-hidden>
            <span className={c.label} style={{ left: "8%", top: "40%" }}>Rendez-vous du jour</span>
            <span className={c.label} style={{ right: "8%", top: "34%" }}>Demandes à traiter</span>
            <span className={c.label} style={{ left: "14%", bottom: "14%" }}>Statistiques du mois</span>
          </div>
        </div>
      </section>

      <section className={c.hscroll} id="fonctions" aria-label="Fonctionnalités">
        <div className={c.hStage}>
          <div className={c.track}>
            {PANELS.map((x) => (
              <article key={x.n} className={c.panel}>
                <div><span className={c.num}>{x.n}</span><h3>{x.t}</h3><p>{x.p}</p><ul>{x.l.map((li) => <li key={li}>{li}</li>)}</ul></div>
                <div className={c.shot}><img src={x.img} alt={x.alt} loading="lazy" style={x.phone ? { maxWidth: 300 } : undefined} /></div>
              </article>
            ))}
          </div>
          <div className={c.hCount}>01 / 04</div>
        </div>
      </section>

      <section className={c.phones} id="telephone">
        <div className={c.phonesGrid}>
          <div className={c.phonePair}><img src="/decouvrir/ecran-mobile.webp" alt="Flo sur téléphone : tableau de bord" loading="lazy" /><img src="/decouvrir/ecran-reservation.webp" alt="Page de réservation sur téléphone" loading="lazy" /></div>
          <div>
            <p className={c.big}>Aussi dans <span className={c.orange}>votre téléphone.</span></p>
            <p className={c.sub}>Ajoutez votre lien Flo une seule fois : vos rendez-vous apparaissent dans l’agenda que vous utilisez déjà, avec l’adresse et le téléphone du client.</p>
            <div className={c.syncs}><span>Google Agenda</span><span>iPhone et Mac</span><span>Outlook</span></div>
            <a href={demo} className={`${c.btn} ${c.ghost}`}>Voir une démonstration</a>
          </div>
        </div>
      </section>
      <div className={c.fadeToLight} />
    </div>
  );
}
