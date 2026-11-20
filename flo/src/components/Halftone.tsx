// Trame halftone : grille de points dont la taille diminue en s'éloignant du centre (cx, cy).
// La couleur vient de `className` (currentColor), ex. text-accent-2.
export default function Halftone({
  cols = 46, rows = 30, gap = 12, cx = 0.62, cy = 0.45, reach = 0.55, className = "",
}: { cols?: number; rows?: number; gap?: number; cx?: number; cy?: number; reach?: number; className?: string }) {
  const w = cols * gap, h = rows * gap;
  const R = reach * w; // distance à laquelle les points disparaissent
  const dots: React.ReactNode[] = [];
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const x = c * gap + gap / 2, y = r * gap + gap / 2;
      const t = 1 - Math.hypot(x - cx * w, y - cy * h) / R;
      const radius = (gap / 2) * 0.92 * Math.max(0, t) ** 0.9;
      if (radius > 0.35) dots.push(<circle key={`${r}-${c}`} cx={x} cy={y} r={radius.toFixed(2)} />);
    }
  }
  return (
    <svg aria-hidden viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="xMidYMid slice" fill="currentColor" className={className}>
      {dots}
    </svg>
  );
}
