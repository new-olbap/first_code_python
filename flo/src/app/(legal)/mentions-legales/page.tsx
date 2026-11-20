export const metadata = { title: "Mentions légales — Flo" };
const A = ({ children }: { children: React.ReactNode }) => <mark>[À COMPLÉTER : {children}]</mark>;

export default function MentionsLegales() {
  return (
    <>
      <h1>Mentions légales</h1>
      <h2>Éditeur du service</h2>
      <p>Le service Flo est édité par <A>nom et prénom, ou raison sociale et forme juridique (et capital)</A>, <A>adresse du siège</A>.</p>
      <ul>
        <li>SIRET : <A>numéro SIRET</A> — RCS : <A>ville et numéro, si société</A></li>
        <li>TVA intracommunautaire : <A>numéro, ou « TVA non applicable, art. 293 B du CGI »</A></li>
        <li>Contact : <A>adresse e-mail</A> — <A>téléphone</A></li>
        <li>Directeur ou directrice de la publication : <A>nom</A></li>
      </ul>
      <h2>Hébergement</h2>
      <p>L’application est hébergée par <strong>Vercel Inc.</strong> (États-Unis), sur des serveurs situés en Europe (Paris). Les données sont stockées par <strong>Supabase Inc.</strong>, dans la région <A>région du projet Supabase</A>.</p>
      <h2>Propriété intellectuelle</h2>
      <p>Le logiciel Flo, sa marque et ses contenus sont protégés. Toute reproduction sans autorisation est interdite. Les données saisies par les utilisateurs leur appartiennent.</p>
    </>
  );
}
