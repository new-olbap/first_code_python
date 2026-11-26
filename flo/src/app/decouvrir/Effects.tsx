"use client";
import { useEffect, useRef, useState } from "react";
import s from "./site.module.css";

const KEY = "flo-theme";
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches;

// Bouton mode clair / sombre : pose data-theme sur <html> et s'en souvient.
export function ThemeToggle() {
  const [dark, setDark] = useState(false);
  useEffect(() => setDark(document.documentElement.dataset.theme === "dark"), []);
  const flip = () => {
    const next = !dark;
    setDark(next);
    if (next) document.documentElement.dataset.theme = "dark"; else delete document.documentElement.dataset.theme;
    try { localStorage.setItem(KEY, next ? "dark" : "light"); } catch {}
  };
  return (
    <button type="button" className={s.theme} onClick={flip} aria-label={dark ? "Passer en mode clair" : "Passer en mode sombre"} aria-pressed={dark}>
      {dark
        ? <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden><circle cx="12" cy="12" r="4.5" /><path d="M12 2v2.5M12 19.5V22M2 12h2.5M19.5 12H22M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M4.9 19.1l1.8-1.8M17.3 6.7l1.8-1.8" /></svg>
        : <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z" /></svg>}
    </button>
  );
}
// Appliqué avant l'affichage pour éviter un éclair blanc en mode sombre.
export const themeScript = `try{if(localStorage.getItem("${KEY}")==="dark")document.documentElement.dataset.theme="dark"}catch(e){}`;

// Apparition des blocs [data-reveal] quand ils entrent à l'écran.
export function RevealInit() {
  useEffect(() => {
    if (reduced() || !("IntersectionObserver" in window)) return;
    const html = document.documentElement;
    html.dataset.anim = "1";
    const io = new IntersectionObserver((list) => list.forEach((e) => {
      if (e.isIntersecting) { (e.target as HTMLElement).dataset.shown = "1"; io.unobserve(e.target); }
    }), { rootMargin: "0px 0px -8% 0px" });
    document.querySelectorAll("[data-reveal]").forEach((el) => io.observe(el));
    return () => { io.disconnect(); delete html.dataset.anim; };
  }, []);
  return null;
}

// Le symbole de Flo en relief : trois blocs (la colonne et les deux créneaux), qui se balancent et suivent la souris.
const BOXES = [[0, 0, 11, 48], [14, 0, 26, 12], [14, 17, 18, 12]];
const FACES = ["fr", "bk", "ri", "le", "to", "bo"] as const;
export function Mark3D() {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (reduced() || !matchMedia("(pointer: fine)").matches) return;
    const el = ref.current!;
    let raf = 0;
    const move = (e: PointerEvent) => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        el.style.setProperty("--ry", `${((e.clientX / innerWidth) - 0.5) * 40}deg`);
        el.style.setProperty("--rx", `${((e.clientY / innerHeight) - 0.5) * -24}deg`);
      });
    };
    addEventListener("pointermove", move, { passive: true });
    return () => { removeEventListener("pointermove", move); cancelAnimationFrame(raf); };
  }, []);
  return (
    <div className={s.mark3d} ref={ref} aria-hidden>
      <div className={s.tilt}>
        <div className={s.sway}>
          {BOXES.map(([x, y, w, h]) => (
            <div key={`${x}-${y}`} className={s.box} style={{ "--x": x, "--y": y, "--w": w, "--h": h } as React.CSSProperties}>
              {FACES.map((f) => <i key={f} className={s[f]} />)}
            </div>
          ))}
        </div>
      </div>
      <div className={s.floor} />
    </div>
  );
}

// Petit cube qui tourne sur lui-même, avec un mot sur chaque face.
export function Cube({ faces }: { faces: string[] }) {
  return (
    <div className={s.cubeWrap} aria-hidden>
      <div className={s.cube}>{faces.slice(0, 6).map((t, k) => <span key={k} className={s[`c${k}`]}>{t}</span>)}</div>
    </div>
  );
}
