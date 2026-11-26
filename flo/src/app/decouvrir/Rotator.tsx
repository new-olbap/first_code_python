"use client";
import { useEffect, useState } from "react";

// Ligne qui fait défiler les métiers, un par un.
export default function Rotator({ words, className }: { words: string[]; className?: string }) {
  const [k, setK] = useState(0);
  useEffect(() => {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const t = setInterval(() => setK((n) => (n + 1) % words.length), 2200);
    return () => clearInterval(t);
  }, [words.length]);
  return <p className={className} aria-live="off"><span key={k}>{words[k]}</span></p>;
}
