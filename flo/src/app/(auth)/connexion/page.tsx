import Link from "next/link";
import { signIn } from "@/lib/actions";
import { Field, Notice, buttonCls, type Msg } from "@/components/ui";

export default async function Connexion({ searchParams }: { searchParams: Msg }) {
  return (
    <form action={signIn} className="space-y-4">
      <h1 className="text-2xl font-bold">Connexion</h1>
      <Notice {...await searchParams} />
      <Field label="E-mail" name="email" type="email" autoComplete="email" required />
      <Field label="Mot de passe" name="password" type="password" autoComplete="current-password" required />
      <button className={buttonCls}>Se connecter</button>
      <div className="flex justify-between text-sm">
        <Link href="/mot-de-passe-oublie" className="text-accent-ink hover:underline">Mot de passe oublié ?</Link>
        <Link href="/inscription" className="font-semibold text-accent-ink hover:underline">Créer un compte</Link>
      </div>
    </form>
  );
}
