import Halftone from "@/components/Halftone";
import Shape3D from "@/components/Shape3D";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="grid min-h-screen place-items-center px-4 py-10">
            <Halftone cols={70} rows={44} cx={0.7} cy={0.5} reach={0.45} className="fixed inset-0 -z-10 h-full w-full text-white/20" />
      <div className="glass w-full max-w-md p-8" style={{ background: "#111" }}>
        <p className="mb-6 flex items-center gap-3"><span className="text-4xl font-black tracking-tight">Flo</span><Shape3D size={26} /></p>
        {children}
      </div>
    </main>
  );
}
