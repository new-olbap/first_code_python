import { updatePassword } from "@/lib/actions";
import { Field, Notice, buttonCls, type Msg } from "@/components/ui";

export default async function NouveauMotDePasse({ searchParams }: { searchParams: Msg }) {
  return (
    <form action={updatePassword} className="space-y-4">
      <h1 className="text-2xl font-bold">Nouveau mot de passe</h1>
      <Notice {...await searchParams} />
      <Field label="Nouveau mot de passe (8 caractères min.)" name="password" type="password" autoComplete="new-password" minLength={8} required />
      <button className={buttonCls}>Enregistrer</button>
    </form>
  );
}
