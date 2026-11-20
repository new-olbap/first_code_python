"use client";
import { useState } from "react";
import { Check, Copy } from "lucide-react";
import { secondaryBtn } from "@/components/ui";

export default function CopyButton({ text, label = "Copier le lien" }: { text: string; label?: string }) {
  const [done, setDone] = useState(false);
  return (
    <button type="button" className={`${secondaryBtn} flex items-center gap-2`}
      onClick={async () => { await navigator.clipboard.writeText(text); setDone(true); setTimeout(() => setDone(false), 2000); }}>
      {done ? <><Check size={16} aria-hidden /> Copié</> : <><Copy size={16} aria-hidden /> {label}</>}
    </button>
  );
}
