import Link from "next/link";
import { headers } from "next/headers";
import Card from "@/components/Card";
import { Field, Notice, inputCls, primaryBtn, secondaryBtn } from "@/components/ui";
import { createClient, getSession } from "@/lib/supabase/server";
import { updateOrganization, updateProfile, updateSlug } from "./actions";

export default async function Parametres({ searchParams }: { searchParams: Promise<{ erreur?: string; info?: string }> }) {
  const session = (await getSession())!;
  const org = session.organization!;
  const canEdit = session.role !== "member";
  const sb = await createClient();
  const { data } = await sb.from("organizations").select("trade, address").eq("id", org.id).single();
  const h = await headers();
  const site = `${h.get("x-forwarded-proto") ?? "https"}://${h.get("host")}/r/`;

  return (
    <main className="space-y-5">
      <Card className="space-y-2">
        <h1 className="text-2xl font-bold">Paramètres</h1>
        <Notice {...await searchParams} />
      </Card>

      <Card className="space-y-4">
        <h2 className="text-lg font-semibold">Entreprise</h2>
        <form action={updateOrganization} className="space-y-4">
          <fieldset disabled={!canEdit} className="grid gap-4 sm:grid-cols-2">
            <Field label="Nom de l’entreprise" name="name" defaultValue={org.name} minLength={2} maxLength={120} required />
            <Field label="Métier" name="trade" defaultValue={data?.trade ?? ""} maxLength={80} placeholder="Plombier, électricien…" />
            <div className="sm:col-span-2"><Field label="Adresse" name="address" defaultValue={data?.address ?? ""} maxLength={300} /></div>
          </fieldset>
          {canEdit ? <button className={primaryBtn}>Enregistrer</button> : <p className="text-xs text-muted">Seuls le propriétaire et les administrateurs peuvent modifier l’entreprise.</p>}
        </form>
      </Card>

      {canEdit && (
        <Card className="space-y-4">
          <h2 className="text-lg font-semibold">Adresse de la page de réservation</h2>
          <form action={updateSlug} className="space-y-3">
            <label className="block text-sm font-medium" htmlFor="slug">Adresse</label>
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-sm text-muted">{site}</span>
              <input id="slug" name="slug" defaultValue={org.slug} required minLength={3} maxLength={60} className={`${inputCls} max-w-xs font-mono`} />
            </div>
            <p className="text-xs text-muted">Lettres, chiffres et tirets. Attention : l’ancien lien ne fonctionnera plus.</p>
            <button className={secondaryBtn}>Changer l’adresse</button>
          </form>
        </Card>
      )}

      <Card className="space-y-4">
        <h2 className="text-lg font-semibold">Mon profil</h2>
        <form action={updateProfile} className="flex flex-wrap items-end gap-3">
          <div className="w-64"><Field label="Prénom" name="first_name" defaultValue={session.firstName} maxLength={80} required /></div>
          <button className={secondaryBtn}>Enregistrer</button>
        </form>
        <Link href="/nouveau-mot-de-passe" className="inline-block text-sm underline">Changer mon mot de passe</Link>
      </Card>
    </main>
  );
}
