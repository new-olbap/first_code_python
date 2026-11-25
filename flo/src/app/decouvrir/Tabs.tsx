"use client";
import { useState } from "react";
import s from "./landing.module.css";

export type Feature = { tab: string; title: string; text: string; points: string[]; img: string; alt: string; phone?: boolean };

// Onglets des fonctionnalités, avec une vraie capture de Flo pour chacune.
export default function Tabs({ items }: { items: Feature[] }) {
  const [k, setK] = useState(0);
  const f = items[k];
  return (
    <>
      <div className={s.tabs} role="tablist" aria-label="Fonctionnalités">
        {items.map((it, i) => (
          <button key={it.tab} role="tab" aria-selected={i === k} aria-controls="panel-fonction" onClick={() => setK(i)}>{it.tab}</button>
        ))}
      </div>
      <div className={s.panel} id="panel-fonction" role="tabpanel">
        <div className={`${s.tx} ${s.fade}`} key={`t${k}`}>
          <h3>{f.title}</h3>
          <p className={s.lead}>{f.text}</p>
          <ul>{f.points.map((p) => <li key={p}>{p}</li>)}</ul>
        </div>
        <div className={s.shot}>
          {/* eslint-disable-next-line @next/next/no-img-element -- captures statiques, déjà optimisées en WebP */}
          <img key={f.img} className={s.fade} src={f.img} alt={f.alt} style={f.phone ? { maxWidth: 280 } : undefined} loading="lazy" />
        </div>
      </div>
    </>
  );
}
