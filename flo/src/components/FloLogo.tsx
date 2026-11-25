// Symbole de Flo : un « F » fait de créneaux d'agenda (la colonne de la journée et deux rendez-vous empilés).
export function FloMark({ size = 28, color = "#ff5a1f", className }: { size?: number; color?: string; className?: string }) {
  return (
    <svg viewBox="0 0 40 48" width={size * (40 / 48)} height={size} className={className} aria-hidden fill={color}>
      <rect x="0" y="0" width="11" height="48" />
      <rect x="14" y="0" width="26" height="12" />
      <rect x="14" y="17" width="18" height="12" />
    </svg>
  );
}

// Symbole + nom, pour l'en-tête et le pied de page.
export default function FloLogo({ size = 26, color = "#ff5a1f", text = "currentColor" }: { size?: number; color?: string; text?: string }) {
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: size * 0.32, color: text }}>
      <FloMark size={size} color={color} />
      <span style={{ fontSize: size * 1.05, fontWeight: 700, letterSpacing: "-0.05em", lineHeight: 1 }}>flo</span>
    </span>
  );
}
