import { notFound } from "next/navigation";
import Card from "@/components/Card";
import { NAV } from "@/lib/nav";
import { getSession } from "@/lib/supabase/server";

// Pages pas encore construites : affiche les actions prévues (cahier des charges §4).

export default async function Section({ params }: { params: Promise<{ section: string }> }) {
  const { section } = await params;
  const page = NAV.find((n) => n.href === `/${section}`);
  if (!page) notFound();
  if (page.ownerOnly && (await getSession())?.role !== "owner") notFound(); // contrôle côté serveur, pas seulement le menu
  const Icon = page.icon;
  return (
    <Card className="grid min-h-[60vh] place-items-center text-center">
      <div>
        <div className="mx-auto mb-4 grid h-16 w-16 place-items-center border border-line bg-surface text-ink">
          <Icon size={28} aria-hidden />
        </div>
        <h1 className="text-2xl font-bold">{page.label}</h1>
        <p className="mx-auto mt-2 max-w-md text-muted">{page.desc}</p>
        <p className="mt-6 text-xs font-semibold uppercase tracking-widest text-accent-ink">Bientôt disponible</p>
      </div>
    </Card>
  );
}
