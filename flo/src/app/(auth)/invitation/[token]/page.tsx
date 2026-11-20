import Link from "next/link";
import { Notice, buttonCls, secondaryBtn } from "@/components/ui";
import { acceptInvitation, signOut } from "@/lib/actions";
import { createClient, getSession } from "@/lib/supabase/server";
import { ROLE_LABEL } from "@/lib/team";
import type { Role } from "@/lib/supabase/server";

export default async function Invitation({ params, searchParams }: { params: Promise<{ token: string }>; searchParams: Promise<{ erreur?: string }> }) {
  const { token } = await params;
  const { erreur } = await searchParams;
  const valid = /^[0-9a-f]{64}$/.test(token);
  const sb = await createClient();
  const info = valid ? ((await sb.rpc("invitation_info", { p_token: token })).data as { organization: string; role: Role } | null) : null;
  const session = await getSession();

  if (!info) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold">Invitation invalide</h1>
        <p className="text-sm text-muted">Ce lien a expiré (7 jours), a déjà été utilisé ou a été annulé. Demandez un nouveau lien à votre responsable.</p>
        <Link href="/" className={`${secondaryBtn} inline-block`}>Retour</Link>
      </div>
    );
  }
  const title = <h1 className="text-2xl font-bold">Rejoindre {info.organization}</h1>;
  const role = <p className="text-sm text-muted">Vous êtes invité en tant que <strong className="text-ink">{ROLE_LABEL[info.role].toLowerCase()}</strong>.</p>;

  if (!session) {
    return (
      <div className="space-y-4">
        {title}{role}
        <Link href={`/inscription?invitation=${token}`} className={`${buttonCls} block text-center`}>Créer mon compte</Link>
        <Link href={`/connexion?invitation=${token}`} className={`${secondaryBtn} block text-center`}>J’ai déjà un compte</Link>
      </div>
    );
  }
  if (session.organization) {
    return (
      <div className="space-y-4">
        {title}
        <p className="text-sm text-muted">Ce compte appartient déjà à l’entreprise <strong className="text-ink">{session.organization.name}</strong>. Pour rejoindre {info.organization}, déconnectez-vous puis créez un compte avec une autre adresse e-mail.</p>
        <form action={signOut}><button className={`${secondaryBtn} w-full`}>Se déconnecter</button></form>
        <Link href="/" className="block text-center text-sm underline">Retour à mon espace</Link>
      </div>
    );
  }
  return (
    <form action={acceptInvitation} className="space-y-4">
      {title}{role}
      <Notice erreur={erreur} />
      <input type="hidden" name="invitation" value={token} />
      <button className={buttonCls}>Rejoindre {info.organization}</button>
    </form>
  );
}
