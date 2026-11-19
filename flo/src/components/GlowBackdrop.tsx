// Fond décoratif : taches bleu/rose/violet floues + trame halftone.
export default function GlowBackdrop({ className = "absolute inset-0" }: { className?: string }) {
  return (
    <div aria-hidden className={`${className} overflow-hidden bg-[#04628c]`}>
      <div className="absolute -right-10 -top-16 h-80 w-80 rounded-full bg-[#4cc3f5] opacity-80 blur-3xl motion-safe:animate-drift" />
      <div className="absolute right-[18%] top-1/4 h-72 w-56 rounded-full bg-accent-2 opacity-85 blur-3xl motion-safe:animate-drift [animation-delay:-6s]" />
      <div className="absolute -bottom-20 right-1/3 h-64 w-72 rounded-full bg-[#7b4dd6] opacity-60 blur-3xl motion-safe:animate-drift [animation-delay:-11s]" />
      <div className="absolute inset-0 bg-gradient-to-r from-[#04628c]/80 via-[#04628c]/30 to-transparent" />
      <div className="halftone absolute bottom-0 right-0 h-2/3 w-1/2 text-white/35" />
    </div>
  );
}
