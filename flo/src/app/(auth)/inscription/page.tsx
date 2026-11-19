import Link from "next/link";
import { signUp } from "@/lib/actions";
import { Field, Notice, buttonCls, type Msg } from "@/components/ui";

export default async function Inscription({ searchParams }: { searchParams: Msg }) {
  return (
    <form action={signUp} className="space-y-4">
      <h1 className="text-2xl font-bold">Créer un compte</h1>
      <Notice {...await searchParams} />
      <Field label="Prénom" name="first_name" autoComplete="given-name" maxLength={80} required />
      <Field label="E-mail" name="email" type="email" autoComplete="email" required />
      <Field label="Mot de passe (8 caractères min.)" name="password" type="password" autoComplete="new-password" minLength={8} required />
      <button className={buttonCls}>Créer mon compte</button>
      <p className="text-center text-sm">
        Déjà inscrit ? <Link href="/connexion" className="font-semibold text-accent-ink hover:underline">Se connecter</Link>
      </p>
    </form>
  );
}
