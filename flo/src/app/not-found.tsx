import Link from "next/link";
import Halftone from "@/components/Halftone";
import { primaryBtn } from "@/components/ui";

export default function NotFound() {
  return (
    <main className="relative grid min-h-[70vh] place-items-center overflow-hidden px-4 text-center">
      <Halftone cols={60} rows={40} cx={0.5} cy={0.5} reach={0.4} className="absolute inset-0 -z-10 h-full w-full text-white/10" />
      <div>
        <p className="text-7xl font-black tracking-tight">404</p>
        <h1 className="mt-2 text-2xl font-bold">Page introuvable</h1>
        <p className="mt-2 text-muted">Cette page n’existe pas ou n’est plus disponible.</p>
        <Link href="/" className={`${primaryBtn} mt-6 inline-block`}>Retour à l’accueil</Link>
      </div>
    </main>
  );
}
