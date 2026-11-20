export const metadata = { title: "Mentions légales — Flo" };
const A = ({ children }: { children: React.ReactNode }) => <mark>[À COMPLÉTER : {children}]</mark>;

export default function MentionsLegales() {
  return (
    <>
      <h1>Mentions légales</h1>
      <h2>Éditeur du service</h2>
      <p>Le service Flo est édité par <strong>Daniel Alexandre</strong>, entrepreneur individuel (micro-entreprise), <A>adresse</A>.</p>
      <ul>
        <li>SIRET : <A>numéro SIRET</A></li>
        <li>TVA non applicable, article 293 B du Code général des impôts.</li>
        <li>Contact : <a href="mailto:ddmpalexandre@gmail.com" className="underline">ddmpalexandre@gmail.com</a></li>
        <li>Directeur de la publication : Daniel Alexandre</li>
      </ul>
      <h2>Hébergement</h2>
      <p>L’application est hébergée par <strong>Vercel Inc.</strong> (États-Unis), sur des serveurs situés en Europe (Paris). Les données sont stockées par <strong>Supabase Inc.</strong>, sur des serveurs situés à Paris (France).</p>
      <h2>Propriété intellectuelle</h2>
      <p>Le logiciel Flo, sa marque et ses contenus sont protégés. Toute reproduction sans autorisation est interdite. Les données saisies par les utilisateurs leur appartiennent.</p>
    </>
  );
}
