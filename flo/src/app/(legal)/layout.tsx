import Link from "next/link";

export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="mx-auto max-w-3xl px-4 py-10">
      <Link href="/" className="text-2xl font-black tracking-tight">Flo</Link>
      <article className="mt-8 space-y-4 text-sm leading-relaxed text-muted [&_h1]:text-3xl [&_h1]:font-black [&_h1]:text-ink [&_h2]:pt-4 [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-ink [&_li]:ml-5 [&_li]:list-disc [&_strong]:text-ink [&_mark]:bg-accent-2/20 [&_mark]:px-1 [&_mark]:text-accent-2">
        {children}
      </article>
      <p className="mt-10 border-t border-line pt-6 text-xs text-muted">
        <Link href="/mentions-legales" className="underline">Mentions légales</Link> · <Link href="/cgu" className="underline">Conditions d’utilisation</Link> · <Link href="/confidentialite" className="underline">Confidentialité</Link>
      </p>
    </main>
  );
}
