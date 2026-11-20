export const metadata = { title: "Confidentialité — Flo" };
const A = ({ children }: { children: React.ReactNode }) => <mark>[À COMPLÉTER : {children}]</mark>;

export default function Confidentialite() {
  return (
    <>
      <h1>Politique de confidentialité</h1>
      <h2>Qui est responsable ?</h2>
      <ul>
        <li><strong>Comptes des professionnels</strong> (utilisateurs de Flo) : l’éditeur de Flo, <A>nom ou raison sociale</A>, est responsable de traitement.</li>
        <li><strong>Données des clients d’un professionnel</strong> (par exemple une personne qui réserve un rendez-vous) : le professionnel concerné est responsable de traitement ; Flo n’intervient que comme sous-traitant pour son compte.</li>
      </ul>
      <h2>Données traitées</h2>
      <ul>
        <li>Compte : prénom, adresse e-mail, mot de passe (stocké chiffré, jamais lisible), rôle dans l’entreprise.</li>
        <li>Entreprise : nom, métier, adresse, horaires, prestations.</li>
        <li>Clients du professionnel : nom, prénom, téléphone, e-mail, adresse d’intervention, message, rendez-vous et notes.</li>
      </ul>
      <h2>Pourquoi ?</h2>
      <ul>
        <li>Fournir le service de gestion des rendez-vous (exécution du contrat).</li>
        <li>Traiter une demande de rendez-vous faite sur une page de réservation (mesures précontractuelles à la demande de la personne).</li>
        <li>Sécuriser le service et lutter contre les abus (intérêt légitime).</li>
      </ul>
      <h2>Qui y a accès ?</h2>
      <p>Uniquement les membres de l’entreprise concernée — chaque entreprise est isolée des autres — et nos prestataires techniques : <strong>Supabase</strong> (base de données et connexion) et <strong>Vercel</strong> (hébergement). <A>ajouter le prestataire d’envoi d’e-mails quand il sera branché</A>. Ces prestataires peuvent être situés hors de l’Union européenne ; les transferts sont encadrés par <A>clauses contractuelles types / Data Privacy Framework — à vérifier</A>.</p>
      <h2>Combien de temps ?</h2>
      <ul>
        <li>Compte et données de l’entreprise : tant que le compte est actif, puis supprimés avec le compte.</li>
        <li>Clients du professionnel : tant que le professionnel les conserve ; il peut les supprimer à tout moment. Pour les prospects sans relation commerciale, la CNIL recommande 3 ans au plus après le dernier contact.</li>
        <li><A>durée de conservation des sauvegardes</A></li>
      </ul>
      <h2>Cookies</h2>
      <p>Flo n’utilise que les cookies strictement nécessaires à la connexion. Aucun cookie publicitaire ou de mesure d’audience : aucun consentement n’est donc demandé.</p>
      <h2>Vos droits</h2>
      <p>Vous pouvez accéder à vos données, les rectifier, les effacer, en demander la portabilité, vous opposer à leur traitement ou en demander la limitation. Si vous êtes client d’un professionnel, adressez-vous d’abord à lui. Sinon, écrivez à <A>adresse e-mail de contact</A>. Vous pouvez aussi saisir la CNIL (cnil.fr).</p>
      <h2>Sécurité</h2>
      <p>Connexion chiffrée (HTTPS), mots de passe chiffrés, isolation stricte des données de chaque entreprise vérifiée par des tests automatiques.</p>
    </>
  );
}
