import Link from "next/link";
import { TARIF, eur } from "@/lib/tarif";
export const metadata = { title: "Conditions d’utilisation — Flo" };
const A = ({ children }: { children: React.ReactNode }) => <mark>[À COMPLÉTER : {children}]</mark>;

export default function Cgu() {
  return (
    <>
      <h1>Conditions générales d’utilisation et de vente</h1>
      <p><A>modèle à faire valider par un professionnel du droit avant la commercialisation</A></p>
      <h2>1. Objet</h2>
      <p>Flo est un logiciel en ligne de gestion des rendez-vous destiné aux professionnels (artisans et entreprises de services) : agenda, fiches clients, prestations, réservation en ligne et demandes. Les présentes conditions régissent son utilisation.</p>
      <h2>2. Accès et compte</h2>
      <p>Le service est réservé aux professionnels. Chaque utilisateur est responsable de la confidentialité de son mot de passe et des actions effectuées depuis son compte. Le propriétaire d’un espace entreprise gère les accès de son équipe.</p>
      <h2>3. Prix, paiement et durée</h2>
      <p>Flo est vendu sous forme de <strong>licence à vie</strong>, en un seul paiement de {eur(TARIF.normal)} (offre de lancement : {eur(TARIF.lancement)} pour les {TARIF.places} premiers clients). TVA non applicable, article 293 B du CGI. Il n’y a pas d’abonnement.</p>
      <p>Le paiement se fait par virement bancaire. L’accès est activé dès réception du paiement, et une facture est remise au client.</p>
      <p>« À vie » signifie : pendant toute la durée d’exploitation du service Flo par l’éditeur. Si l’éditeur arrête le service, il prévient les clients au moins 6 mois à l’avance, pour leur laisser le temps d’exporter leurs données. <A>conditions de remboursement éventuel</A></p>
      <h2>4. Données des clients du professionnel</h2>
      <p>Pour les données de ses propres clients (coordonnées, rendez-vous, demandes), le professionnel est <strong>responsable de traitement</strong> ; l’éditeur de Flo agit en tant que <strong>sous-traitant</strong> au sens de l’article 28 du RGPD et ne les utilise que pour fournir le service. Le professionnel s’engage à informer ses clients et à disposer d’une base légale. Voir la <Link href="/confidentialite" className="underline">politique de confidentialité</Link>.</p>
      <h2>5. Disponibilité et responsabilité</h2>
      <p>L’éditeur met en œuvre les moyens raisonnables pour assurer la disponibilité et la sécurité du service, sans garantie d’absence d’interruption. Sa responsabilité est limitée aux dommages directs et plafonnée au prix payé pour la licence. <A>à valider</A></p>
      <h2>6. Fin du service et données</h2>
      <p>L’utilisateur peut exporter ses clients à tout moment et supprimer son compte depuis la page Paramètres. À la suppression, les données de l’entreprise sont effacées <A>délai éventuel de conservation des sauvegardes</A>.</p>
      <h2>7. Modification des conditions</h2>
      <p>Les utilisateurs sont informés de toute modification au moins 30 jours avant son entrée en vigueur.</p>
      <h2>8. Droit applicable</h2>
      <p>Les présentes conditions sont soumises au droit français. En cas de litige entre professionnels, compétence est attribuée aux tribunaux de <A>ville</A>.</p>
    </>
  );
}
