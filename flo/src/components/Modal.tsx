"use client";
import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { X } from "lucide-react";

// Fenêtre par-dessus la page courante. Échap, la croix ou un clic à côté la ferment (retour arrière).
export default function Modal({ children, label }: { children: React.ReactNode; label: string }) {
  const ref = useRef<HTMLDialogElement>(null);
  const router = useRouter();
  useEffect(() => { if (!ref.current?.open) ref.current?.showModal(); }, []);
  return (
    <dialog
      ref={ref}
      aria-label={label}
      onClose={() => router.back()}
      onClick={(e) => { if (e.target === ref.current) ref.current?.close(); }}
      className="m-0 mt-auto max-h-[92vh] w-full max-w-none overflow-y-auto border border-line bg-[#111] p-0 text-ink backdrop:bg-black/70 backdrop:backdrop-blur-sm md:m-auto md:max-w-2xl motion-safe:animate-[modal-in_.2s_ease-out]"
    >
      <div className="relative p-5 md:p-6">
        <button onClick={() => ref.current?.close()} aria-label="Fermer" className="absolute right-3 top-3 p-2 text-muted hover:bg-surface hover:text-ink">
          <X size={20} />
        </button>
        {children}
      </div>
    </dialog>
  );
}
