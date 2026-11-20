import { redirect } from "next/navigation";
import { createOrganization } from "@/lib/actions";
import { getSession } from "@/lib/supabase/server";
import { Field, Notice, buttonCls, type Msg } from "@/components/ui";

export default async function Bienvenue({ searchParams }: { searchParams: Msg }) {
  const session = await getSession();
  if (session?.organization) redirect("/");
  return (
    <form action={createOrganization} className="space-y-4">
      <h1 className="text-2xl font-bold">Bienvenue{session?.firstName ? `, ${session.firstName}` : ""}</h1>
      <p className="text-sm text-muted">Dernière étape : présentez votre entreprise.</p>
      <Notice {...await searchParams} />
      <Field label="Nom de l’entreprise" name="name" minLength={2} maxLength={120} required />
      <Field label="Métier (ex. plombier, électricien…)" name="trade" maxLength={80} />
      <Field label="Adresse" name="address" autoComplete="street-address" maxLength={300} />
      <button className={buttonCls}>Créer mon espace</button>
    </form>
  );
}
