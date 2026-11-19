import Link from "next/link";
import { forgotPassword } from "@/lib/actions";
import { Field, Notice, buttonCls, type Msg } from "@/components/ui";

export default async function MotDePasseOublie({ searchParams }: { searchParams: Msg }) {
  return (
    <form action={forgotPassword} className="space-y-4">
      <h1 className="text-2xl font-bold">Mot de passe oublié</h1>
      <p className="text-sm text-muted">Indiquez votre e-mail : vous recevrez un lien pour choisir un nouveau mot de passe.</p>
      <Notice {...await searchParams} />
      <Field label="E-mail" name="email" type="email" autoComplete="email" required />
      <button className={buttonCls}>Envoyer le lien</button>
      <Link href="/connexion" className="block text-center text-sm text-accent-ink hover:underline">Retour à la connexion</Link>
    </form>
  );
}
