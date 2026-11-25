"use client";
/* eslint-disable @next/next/no-img-element -- captures et images du film déjà optimisées en WebP */
import { useEffect, useRef } from "react";
import Link from "next/link";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import Lenis from "lenis";
import c from "./cinema.module.css";

const FRAMES = 179; // 12 images par seconde, fondu entre deux images pour la fluidité
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

    // La barre d'adresse de l'iPhone qui apparaît/disparaît ne doit pas tout recalculer.
    ScrollTrigger.config({ ignoreMobileResize: true });

    // Défilement doux (Lenis), synchronisé avec ScrollTrigger.
    const lenis = new Lenis({ lerp: 0.09, anchors: true });
    lenis.on("scroll", ScrollTrigger.update);
    const tick = (t: number) => lenis.raf(t * 1000);
    gsap.ticker.add(tick);
    gsap.ticker.lagSmoothing(0);

    // 1. Le film : images décodées à l'avance (jamais pendant le défilement), dessinées une fois par
    //    rafraîchissement d'écran, avec un fondu entre deux images voisines pour un mouvement continu.
    const canvas = el.querySelector("canvas")!, ctx = canvas.getContext("2d", { alpha: false })!;
    const frames: (ImageBitmap | HTMLImageElement | null)[] = new Array(FRAMES).fill(null);
    let alive = true, dirty = true;
    const load = async (i: number) => {
      const im = new Image(); im.src = frameUrl(i);
      try { await im.decode(); } catch { return; }
      if (!alive) return;
      frames[i] = typeof createImageBitmap === "function" ? await createImageBitmap(im).catch(() => im) : im;
      dirty = true;
    };
    (async () => { // première image d'abord, puis le reste, 6 à la fois
      await load(0);
      let next = 1;
      await Promise.all(Array.from({ length: 6 }, async () => { while (alive && next < FRAMES) await load(next++); }));
    })();
    const near = (i: number) => { for (let d = 0; d < FRAMES; d++) { if (frames[i - d]) return frames[i - d]; if (frames[i + d]) return frames[i + d]; } return null; };
    const paint = (img: ImageBitmap | HTMLImageElement, alpha: number) => {
      const s = Math.max(canvas.width / img.width, canvas.height / img.height), w = img.width * s, h = img.height * s;
      ctx.globalAlpha = alpha; ctx.drawImage(img, (canvas.width - w) * 0.42, (canvas.height - h) / 2, w, h);
    };
    let cw = 0, ch = 0;
    const size = () => { // seulement si la largeur change vraiment (pas pour la barre d'adresse)
      // dessin limité à 960 px (gros plan flou : l’agrandissement ne se voit pas) pour rester fluide
      const r = Math.min(devicePixelRatio, 1.5, 960 / canvas.clientWidth, 960 / canvas.clientHeight), w = Math.round(canvas.clientWidth * r), h = Math.round(canvas.clientHeight * r);
      if (w === cw && Math.abs(h - ch) < 160) return;
      canvas.width = cw = w; canvas.height = ch = h; dirty = true;
    };
    size(); addEventListener("resize", size);

    const beats = [...el.querySelectorAll<HTMLElement>(`.${c.beat}`)], cards = [...el.querySelectorAll<HTMLElement>(`.${c.card}`)];
    const bar = el.querySelector<HTMLElement>(`.${c.progress}`)!, hint = el.querySelector<HTMLElement>(`.${c.hint}`)!;
    const win = (p: number, a: number, b: number) => Math.min(1, Math.max(0, (p - a) / 0.05), Math.max(0, (b - p) / 0.05));
    let target = 0, shown = -1;
    const film = ScrollTrigger.create({ trigger: el.querySelector(`.${c.film}`), start: "top top", end: "bottom bottom", onUpdate: ({ progress }) => { target = progress; } });
    const render = () => {
      // Lissage : le film rattrape le défilement en douceur (utile au doigt, où Lenis n'intervient pas).
      const p = shown < 0 ? target : shown + (target - shown) * 0.3;
      if (Math.abs(p - shown) > 0.0002 || dirty) {
        shown = p; dirty = false;
        const f = p * (FRAMES - 1), i = Math.floor(f), t = f - i, a = near(i), b2 = t > 0.02 ? frames[i + 1] : null;
        if (a) { paint(a, 1); if (b2) paint(b2, t); }
        beats.forEach((b, k) => {
          const o = k === 0 ? Math.min(1, (BEATS[0][1] - p) / 0.05) : k === BEATS.length - 1 ? Math.min(1, Math.max(0, (p - BEATS[k][0]) / 0.05)) : win(p, ...BEATS[k]);
          b.style.opacity = String(o); b.style.transform = `translate3d(0, ${(1 - o) * 24}px, 0)`; b.classList.toggle(c.live, o > 0.5);
        });
        cards.forEach((card, k) => { const o = win(p, 0.56 + k * 0.05, 0.8); card.style.opacity = String(o); card.style.transform = `translate3d(0, ${(1 - o) * 20}px, 0)`; });
        bar.style.transform = `scaleX(${p})`; hint.style.opacity = String(Math.max(0, 1 - p * 12));
      }
    };
    gsap.ticker.add(render);

    // 2. L'écran de Flo arrive incliné et se redresse.
    const screen = el.querySelector<HTMLElement>(`.${c.screen}`)!;
    const reveal = ScrollTrigger.create({
      trigger: el.querySelector(`.${c.reveal}`), start: "top top", end: "bottom bottom",
      onUpdate: ({ progress: p }) => {
        const q = Math.min(1, p / 0.6), e = 1 - Math.pow(1 - q, 3);
        // Pas de 3D ici : Safari (iPhone) fait clignoter les transformations 3D dans une zone épinglée.
        screen.style.transform = `translate3d(0, ${(1 - e) * 90}px, 0) scale(${0.82 + e * 0.18})`; screen.style.opacity = String(0.25 + e * 0.75);
      },
    });

    // 3. Visite guidée : l'écran reste en place, le texte défile ; l'écran change en fondu à chaque étape.
    const steps = [...el.querySelectorAll<HTMLElement>(`.${c.step}`)], shots = [...el.querySelectorAll<HTMLElement>(`.${c.tourShot}`)];
    const io = new IntersectionObserver((es) => es.forEach((e) => {
      if (!e.isIntersecting) return;
      const k = steps.indexOf(e.target as HTMLElement);
      steps.forEach((st, i) => st.classList.toggle(c.on, i === k)); shots.forEach((sh, i) => sh.classList.toggle(c.on, i === k));
    }), { rootMargin: "-45% 0px -45% 0px" });
    steps.forEach((st) => io.observe(st));

    // 4. Les téléphones montent à des vitesses différentes.
    const ph = [...el.querySelectorAll<HTMLElement>(`.${c.phonePair} img`)];
    const tweens = ph.map((img, i) => gsap.fromTo(img, { y: 90 + i * 70 }, { y: -40 - i * 40, ease: "none", scrollTrigger: { trigger: img.parentElement, start: "top bottom", end: "bottom top", scrub: true } }));

    addEventListener("load", () => ScrollTrigger.refresh());
    return () => {
      alive = false; removeEventListener("resize", size); gsap.ticker.remove(tick); gsap.ticker.remove(render); lenis.destroy();
      [film, reveal].forEach((s) => s.kill()); io.disconnect(); tweens.forEach((t) => { t.scrollTrigger?.kill(); t.kill(); });
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
        </div>
      </section>

      <section className={c.tour} id="fonctions" aria-label="Fonctionnalités">
        <div className={c.tourStage}>
          {PANELS.map((x, i) => (
            <img key={x.n} className={`${c.tourShot} ${i === 0 ? c.on : ""}`} src={x.img} alt={x.alt} decoding="async" />
          ))}
        </div>
        <div className={c.steps}>
          {PANELS.map((x, i) => (
            <article key={x.n} className={`${c.step} ${i === 0 ? c.on : ""}`}>
              <img className={c.stepShot} src={x.img} alt="" loading="lazy" decoding="async" /><span className={c.num}>{x.n} / 0{PANELS.length}</span><h3>{x.t}</h3><p>{x.p}</p><ul>{x.l.map((li) => <li key={li}>{li}</li>)}</ul>
            </article>
          ))}
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
