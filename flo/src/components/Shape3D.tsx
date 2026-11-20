// Petit cube en fil de fer qui tourne en continu (CSS 3D, sans bibliothèque).
// Arrêté si l'utilisateur a demandé de réduire les animations.
const FACES = ["rotateY(0deg)", "rotateY(90deg)", "rotateY(180deg)", "rotateY(-90deg)", "rotateX(90deg)", "rotateX(-90deg)"];

export default function Shape3D({ size = 22 }: { size?: number }) {
  return (
    <span aria-hidden className="inline-block [perspective:240px]" style={{ width: size, height: size }}>
      <span className="relative block h-full w-full [transform-style:preserve-3d] [transform:rotateX(-25deg)_rotateY(35deg)] motion-safe:animate-tumble">
        {FACES.map((t) => (
          <span key={t} className="absolute inset-0 border-[1.5px] border-ink/90 bg-white/[0.04]" style={{ transform: `${t} translateZ(${size / 2}px)` }} />
        ))}
      </span>
    </span>
  );
}
