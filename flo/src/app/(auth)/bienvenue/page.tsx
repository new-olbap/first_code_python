import Link from "next/link";
import { redirect } from "next/navigation";
import { createOrganization, signOut } from "@/lib/actions";
import { getSession } from "@/lib/supabase/server";
import { Field, Notice, buttonCls, secondaryBtn, type Msg } from "@/components/ui";

export default async function Bienvenue({ searchParams }: { searchParams: Msg }) {
  const session = await getSession();
  if (session?.organization) redirect("/");
  return (
    <>
    <form action={createOrganization} className="space-y-4">
      <h1 className="text-2xl font-bold">Bienvenue{session?.firstName ? `, ${session.firstName}` : ""}</h1>
      <p className="text-sm text-muted">Dernière étape : saisissez le code d’accès reçu après votre commande, puis présentez votre entreprise. Pas encore de code ? <Link href="/tarif" className="underline">Commander Flo</Link>.</p>
      <Notice {...await searchParams} />
      <Field label="Code d’accès (reçu après votre commande)" name="code" placeholder="FLO-XXXX-XXXX" autoComplete="off" maxLength={20} required />
      <Field label="Nom de l’entreprise" name="name" minLength={2} maxLength={120} required />
      <Field label="Métier (ex. plombier, électricien…)" name="trade" maxLength={80} />
      <Field label="Adresse" name="address" autoComplete="street-address" maxLength={300} />
      <button className={buttonCls}>Créer mon espace</button>
    </form>
    {/* Pour changer de compte (ex. connecté par erreur avec un compte sans entreprise). */}
    <form action={signOut} className="mt-3"><button className={`${secondaryBtn} w-full`}>Ce n’est pas le bon compte ? Se déconnecter</button></form>
    </>
  );
}
