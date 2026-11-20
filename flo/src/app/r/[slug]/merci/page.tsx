import Link from "next/link";
import { Check } from "lucide-react";
import { fmt, isIsoDate } from "@/lib/dates";

export default async function Merci({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ date?: string; time?: string }> }) {
  const { slug } = await params;
  const { date, time } = await searchParams;
  return (
    <main className="mx-auto grid min-h-[70vh] max-w-xl place-items-center px-4 text-center">
      <div className="space-y-4">
        <div className="mx-auto grid h-14 w-14 place-items-center bg-ink text-bg"><Check size={28} aria-hidden /></div>
        <h1 className="text-3xl font-black">Demande envoyée</h1>
        <p className="text-muted">
          {isIsoDate(date) && time && /^\d{2}:\d{2}$/.test(time) ? <>Votre demande pour le <strong className="text-ink">{fmt(date, { weekday: "long", day: "numeric", month: "long" })} à {time}</strong> a bien été transmise. </> : "Votre demande a bien été transmise. "}
          Le professionnel va la confirmer.
        </p>
        <Link href={`/r/${slug}`} className="inline-block text-sm underline">Faire une autre demande</Link>
      </div>
    </main>
  );
}
