"use client";
/* eslint-disable @next/next/no-img-element -- captures de Flo et photos déjà optimisées en WebP */
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import FloLogo, { FloMark } from "@/components/FloLogo";
import r from "./reel.module.css";

const N = 16;      // nombre de plans
const STEP = 1;    // une hauteur d'écran par plan
const WIPES = [r.l, r.b, r.r, r.t];

const Laptop = ({ src, alt }: { src: string; alt: string }) => (
  <div className={r.laptop}><div className={r.lid}><img src={src} alt={alt} decoding="async" /></div><div className={r.base} /></div>
);
const Phone = ({ src, alt, className }: { src: string; alt: string; className?: string }) => (
  <div className={`${r.phone} ${className ?? ""}`}><img src={src} alt={alt} decoding="async" /></div>
);

export default function Reel({ demo }: { demo: string }) {
  const root = useRef<HTMLDivElement>(null), stage = useRef<HTMLDivElement>(null);
  const [i, setI] = useState(0);

  // Le plan affiché dépend de la position de défilement ; on ne change que quand on passe au plan suivant.
  useEffect(() => {
    const el = root.current!;
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) { el.classList.add(r.calm); return; }
    const html = document.documentElement;
    let raf = 0;
    const update = () => {
      raf = 0;
      const step = stage.current!.offsetHeight * STEP; // hauteur stable (svh), insensible à la barre d'adresse de l'iPhone
      const box = el.getBoundingClientRect();
      setI(Math.min(N - 1, Math.max(0, Math.floor(-box.top / step))));
      // Arrêt obligatoire sur chaque plan tant qu'on est dans le film, défilement libre ailleurs.
      html.style.scrollSnapType = box.top <= 2 && box.bottom > innerHeight * 0.5 ? "y mandatory" : "none";
    };
    const on = () => { if (!raf) raf = requestAnimationFrame(update); };
    addEventListener("scroll", on, { passive: true }); addEventListener("resize", on); update();
    return () => { removeEventListener("scroll", on); removeEventListener("resize", on); cancelAnimationFrame(raf); html.style.scrollSnapType = ""; };
  }, []);

  const sc = (k: number, extra = "") => `${r.scene} ${WIPES[k % 4]} ${extra} ${k === i ? r.on : k < i ? r.past : ""} ${k < i - 1 ? r.gone : ""}`;

  return (
    <div className={r.reel} ref={root} style={{ height: `calc(${(N - 1) * STEP * 100 + 140}svh)` }}>
      <header className={r.header}>
        <Link href="/" className={r.logoBox} aria-label="Flo, accueil"><FloLogo size={20} text="#fff" /></Link>
        <div className={r.headRight}><Link href="/connexion" className={`${r.btn} ${r.btnNight}`}>Se connecter</Link><a href={demo} className={`${r.btn} ${r.btnOrange}`}>Démo</a></div>
      </header>

      {Array.from({ length: N }, (_, k) => <div key={k} className={r.snap} style={{ top: `${(k + 0.25) * STEP * 100}svh` }} aria-hidden />)}
      <div className={r.snap} style={{ top: "100%" }} aria-hidden />{/* sortie du film : la suite de la page */}
      <div className={r.stage} ref={stage}>
        {/* 1. Le logo */}
        <section className={sc(0, r.intro)} style={{ zIndex: 1 }}>
          <div className={r.introLogo}><FloMark className={r.grow} size={200} /><span className={`${r.word} ${r.a}`}>flo</span></div>
          <h1>Logiciel de rendez-vous pour artisans</h1>
        </section>

        {/* 2. Le symbole en géant */}
        <section className={sc(1)} style={{ zIndex: 2 }}>
          <FloMark className={`${r.giant} ${r.zoom}`} size={900} />
          <span className={r.label}>Flo · Les rendez-vous des artisans</span>
          <h2 className={`${r.big} ${r.giantText} ${r.a}`}>Les rendez-vous des artisans, <span className={r.orange}>réinventés.</span></h2>
        </section>

        {/* 3. Sur l'ordinateur */}
        <section className={sc(2, r.sLaptop)} style={{ zIndex: 3 }}>
          <div className={`${r.orangeBlock} ${r.zoom}`} />
          <div className={`${r.laptopPos} ${r.a}`}><Laptop src="/decouvrir/ecran-tableau.webp" alt="Tableau de bord de Flo sur ordinateur" /></div>
          <div className={r.cap}><p className={`${r.mid} ${r.a} ${r.a2}`}>Toute votre semaine, dans un seul écran.</p></div>
        </section>

        {/* 4. Le symbole seul */}
        <section className={sc(3, r.sWhite)} style={{ zIndex: 4 }}>
          <span className={r.label}>01 — Le symbole</span>
          <FloMark className={r.grow} size={130} />
          <p className={`${r.cornerNote} ${r.a}`}>Un F fait de créneaux d’agenda : la journée, et deux rendez-vous bien rangés.</p>
        </section>

        {/* 5. Le téléphone */}
        <section className={sc(4, r.sPhone)} style={{ zIndex: 5 }}>
          <Phone src="/decouvrir/ecran-reservation.webp" alt="Page de réservation de Flo sur téléphone" className={`${r.tilted} ${r.a}`} />
          <div className={r.cap}><p className={`${r.big} ${r.a} ${r.a2}`}>Vos clients réservent <span className={r.orange}>eux-mêmes.</span></p><p className={`${r.small} ${r.a} ${r.a3}`}>Une page à votre nom : le client choisit sa prestation et un créneau libre, sans créer de compte.</p></div>
        </section>

        {/* 6. La palette */}
        <section className={sc(5)} style={{ zIndex: 6 }}>
          <div className={r.palette}>
            <div className={r.swatch} style={{ background: "#ff5a1f" }}>Orange chantier<small>#FF5A1F</small></div>
            <div className={r.swatch} style={{ background: "#ff8a50" }}>Petit matin<small>#FF8A50</small></div>
            <div className={r.swatch} style={{ background: "#0d111c" }}>Nuit<small>#0D111C</small></div>
            <div className={r.swatch} style={{ background: "#f6f5f1", color: "#0d111c" }}>Plâtre<small>#F6F5F1</small></div>
          </div>
        </section>

        {/* 7. La typographie */}
        <section className={sc(6, r.sWhite)} style={{ zIndex: 7 }}>
          <span className={r.label}>03 — Typographie</span>
          <div className={`${r.typeBlock} ${r.zoom}`} />
          <p className={`${r.typeWord} ${r.a}`}>Geist</p>
          <p className={r.alphabet}>Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 0123456789</p>
        </section>

        {/* 8. Tout ce qui est inclus, en échelle de titres */}
        <section className={sc(7, r.sWhite)} style={{ zIndex: 8 }}>
          <span className={r.label}>04 — Tout est inclus</span>
          <div className={`${r.scale} ${r.a}`}>
            <div style={{ fontSize: "clamp(44px, 7vw, 104px)" }}>Agenda<small>jour · semaine · mois</small></div>
            <div style={{ fontSize: "clamp(32px, 4.6vw, 68px)" }}>Réservation en ligne<small>votre page</small></div>
            <div style={{ fontSize: "clamp(26px, 3.4vw, 50px)" }}>Demandes<small>e-mails et réservations</small></div>
            <div style={{ fontSize: "clamp(22px, 2.6vw, 38px)" }}>Relances d’entretien<small>message rédigé</small></div>
            <div style={{ fontSize: "clamp(19px, 2vw, 28px)" }}>Équipe illimitée<small>chacun son agenda</small></div>
            <div style={{ fontSize: "clamp(17px, 1.6vw, 22px)" }}>Statistiques<small>chaque mois</small></div>
          </div>
        </section>

        {/* 9. Photo et message */}
        <section className={sc(8)} style={{ zIndex: 9 }}>
          <div className={r.split}>
            <div style={{ overflow: "hidden" }}><img className={r.zoom} src="/decouvrir/artisan.webp" alt="Artisan sur un chantier" decoding="async" /></div>
            <div className={r.splitText}>
              <p className={`${r.big} ${r.a}`}>Moins de téléphone. <span className={r.orange}>Plus de chantier.</span></p>
              <p className={`${r.small} ${r.a} ${r.a2}`}>Flo range les demandes, prépare les réponses et remplit l’agenda pendant que vous travaillez.</p>
              <FloMark className={r.splitMark} size={300} />
            </div>
          </div>
        </section>

        {/* 10. Panneau d'affichage */}
        <section className={sc(9, r.wall)} style={{ zIndex: 10 }}>
          <div className={`${r.board} ${r.a}`}>
            <img src="/decouvrir/plombier.webp" alt="" decoding="async" />
            <p className={`${r.boardText} ${r.mid}`} style={{ color: "#fff" }}>Le client réserve. Vous restez sur le chantier.</p>
            <span className={r.boardLogo}><FloLogo size={20} text="#fff" color="#ffffff" /></span>
          </div>
        </section>

        {/* 11. Imagerie */}
        <section className={sc(10)} style={{ zIndex: 11 }}>
          <span className={r.label}>05 — Sur le terrain</span>
          <div className={`${r.grid} ${r.a}`}>
            <img src="/decouvrir/artisan.webp" alt="" decoding="async" />
            <img src="/decouvrir/plombier.webp" alt="" decoding="async" />
            <img src="/decouvrir/electricien.webp" alt="" decoding="async" />
            <img src="/decouvrir/salle-de-bain.webp" alt="" decoding="async" />
            <img src="/decouvrir/chaufferie.webp" alt="" decoding="async" />
          </div>
        </section>

        {/* 12. Les écrans de Flo */}
        <section className={sc(11, r.sScreens)} style={{ zIndex: 12 }}>
          <span className={r.label}>06 — Le produit</span>
          <img className={`${r.screen} ${r.sc1} ${r.a}`} src="/decouvrir/ecran-agenda.webp" alt="Agenda de Flo" decoding="async" />
          <img className={`${r.screen} ${r.sc2} ${r.a} ${r.a2}`} src="/decouvrir/ecran-demandes.webp" alt="Demandes dans Flo" decoding="async" />
          <img className={`${r.screen} ${r.sc3} ${r.a} ${r.a3}`} src="/decouvrir/ecran-tableau.webp" alt="Tableau de bord de Flo" decoding="async" />
          <div className={r.cap}><p className={`${r.mid} ${r.a}`}>Agenda, demandes, relances : tout au même endroit.</p></div>
        </section>

        {/* 13. Synchronisé avec le téléphone */}
        <section className={sc(12, r.sOrange)} style={{ zIndex: 13 }}>
          <div className={`${r.phones} ${r.a}`}>
            <Phone src="/decouvrir/ecran-mobile.webp" alt="Flo sur téléphone" />
            <Phone src="/decouvrir/ecran-reservation.webp" alt="Réservation sur téléphone" />
          </div>
          <div className={r.cap}>
            <p className={`${r.big} ${r.a} ${r.a2}`}>Dans votre agenda de téléphone.</p>
            <div className={`${r.chips} ${r.a} ${r.a3}`}><span>Google Agenda</span><span>iPhone et Mac</span><span>Outlook</span></div>
          </div>
        </section>

        {/* 14. Affiches */}
        <section className={sc(13, r.hall)} style={{ zIndex: 14 }}>
          {[["/decouvrir/plombier.webp", "Vous réparez. Flo s’occupe des rendez-vous."], ["/decouvrir/salle-de-bain.webp", "Le client réserve en ligne, tout seul."], ["/decouvrir/chaufferie.webp", "L’entretien annuel ? Flo s’en souvient."]].map(([img, t], k) => (
            <figure key={t} className={`${r.poster} ${r.a} ${k === 1 ? r.a2 : k === 2 ? r.a3 : ""}`} style={{ margin: 0 }}>
              <img src={img} alt="" decoding="async" /><span><FloLogo size={14} text="#fff" color="#ffffff" /></span><p>{t}</p>
            </figure>
          ))}
        </section>

        {/* 15. Le rendez-vous ajouté */}
        <section className={sc(14, r.sCard)} style={{ zIndex: 15 }}>
          <span className={r.label}>07 — Exemple de rendez-vous</span>
          <div className={`${r.card} ${r.a}`}>
            <div className={r.cardHead}>Ajouté à votre agenda <FloMark size={16} color="#ffffff" /></div>
            <div className={r.cardBody}><b>Mardi · 8 h 00</b><p>Fuite sous l’évier</p><small>Claire D. · Bordeaux · téléphone et adresse inclus</small></div>
          </div>
        </section>

        {/* 16. Fin */}
        <section className={sc(15, r.end)} style={{ zIndex: 16 }}>
          <FloMark className={`${r.endMark} ${r.zoom}`} size={900} color="#0d111c" />
          <div className={r.endText}>
            <p className={`${r.big} ${r.a}`}>Essayez Flo.</p>
            <p className={`${r.small} ${r.a} ${r.a2}`} style={{ opacity: 0.85 }}>1 190 € à vie pour les 20 premiers artisans, au lieu de 1 790 €. Sans abonnement, données hébergées en France.</p>
            <div className={`${r.endBtns} ${r.a} ${r.a3}`}><a href={demo} className={`${r.btn} ${r.btnNight}`}>Demander une démo</a><a href="#tarif" className={`${r.btn} ${r.btnLine}`}>Voir le tarif</a></div>
          </div>
        </section>

        <div className={r.hud}><a href="#tarif">Passer ↓</a><span>{String(i + 1).padStart(2, "0")} / {N}</span></div>
        <div className={r.bar} style={{ transform: `scaleX(${(i + 1) / N})` }} />
      </div>
    </div>
  );
}
