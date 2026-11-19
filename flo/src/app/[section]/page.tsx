import { notFound } from "next/navigation";
import Card from "@/components/Card";
import { NAV } from "@/lib/nav";

// Pages pas encore construites : affiche les actions prévues (cahier des charges §4).
export const dynamicParams = false;
export const generateStaticParams = () => NAV.slice(1).map((n) => ({ section: n.href.slice(1) }));

export default async function Section({ params }: { params: Promise<{ section: string }> }) {
  const { section } = await params;
  const page = NAV.find((n) => n.href === `/${section}`);
  if (!page) notFound();
  const Icon = page.icon;
  return (
    <Card className="grid min-h-[60vh] place-items-center text-center">
      <div>
        <div className="mx-auto mb-4 grid h-16 w-16 place-items-center rounded-3xl bg-gradient-to-br from-accent to-accent-2 text-white shadow-lg shadow-accent/30">
          <Icon size={28} aria-hidden />
        </div>
        <h1 className="text-2xl font-bold">{page.label}</h1>
        <p className="mx-auto mt-2 max-w-md text-muted">{page.desc}</p>
        <p className="mt-6 text-xs font-semibold uppercase tracking-widest text-accent">Bientôt disponible</p>
      </div>
    </Card>
  );
}
