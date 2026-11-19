import GlowBackdrop from "@/components/GlowBackdrop";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="grid min-h-screen place-items-center px-4 py-10">
      <GlowBackdrop className="fixed inset-0 -z-10" />
      <div className="glass w-full max-w-md p-8" style={{ background: "rgb(255 255 255 / 0.88)" }}>
        <p className="mb-6 text-4xl font-black tracking-tight">flo<span className="text-accent-2">.</span></p>
        {children}
      </div>
    </main>
  );
}
