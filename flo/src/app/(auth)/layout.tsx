import Link from "next/link";
import Halftone from "@/components/Halftone";
import Shape3D from "@/components/Shape3D";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="grid min-h-screen place-items-center px-4 py-10">
            <Halftone cols={70} rows={44} cx={0.7} cy={0.5} reach={0.45} className="fixed inset-0 -z-10 h-full w-full text-white/20" />
      <div className="glass w-full max-w-md p-8" style={{ background: "#111" }}>
        <p className="mb-6 flex items-center gap-3"><span className="text-4xl font-black tracking-tight">Flo</span><Shape3D size={26} /></p>
        {children}
        <p className="mt-6 border-t border-line pt-4 text-center text-xs text-muted">
          <Link href="/tarif" className="underline">Tarif</Link> · <Link href="/cgu" className="underline">Conditions d’utilisation</Link> · <Link href="/confidentialite" className="underline">Confidentialité</Link> · <Link href="/mentions-legales" className="underline">Mentions légales</Link>
        </p>
      </div>
    </main>
  );
}
