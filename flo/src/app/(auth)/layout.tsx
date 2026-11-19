import Halftone from "@/components/Halftone";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="grid min-h-screen place-items-center px-4 py-10">
      <div aria-hidden className="fixed inset-0 -z-10 bg-white" />
      <Halftone cols={70} rows={44} cx={0.7} cy={0.5} reach={0.45} className="fixed inset-0 -z-10 h-full w-full text-accent-2" />
      <div className="glass w-full max-w-md p-8" style={{ background: "#fff" }}>
        <p className="mb-6 text-4xl font-black tracking-tight">flo<span className="text-accent-2">.</span></p>
        {children}
      </div>
    </main>
  );
}
