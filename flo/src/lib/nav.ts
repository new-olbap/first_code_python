import {
  LayoutDashboard, CalendarDays, Users, Inbox, Link2, UsersRound, Wrench,
  BarChart3, Settings, CreditCard,
} from "lucide-react";

// Pages du cahier des charges (section 4). href "/" = dashboard. ownerOnly = réservé au propriétaire.
export const NAV = [
  { href: "/", label: "Tableau de bord", icon: LayoutDashboard, desc: "" },
  { href: "/agenda", label: "Agenda", icon: CalendarDays, desc: "Créer, déplacer, modifier, annuler ou confirmer un RDV." },
  { href: "/clients", label: "Clients", icon: Users, desc: "Ajouter, rechercher, modifier, archiver un client." },
  { href: "/prestations", label: "Prestations", icon: Wrench, desc: "Vos services, leur durée et leur prix." },
  { href: "/demandes", label: "Demandes", icon: Inbox, desc: "Qualifier, attribuer, accepter ou refuser une demande." },
  { href: "/reservations", label: "Réservations", icon: Link2, desc: "Définir les disponibilités, personnaliser et copier le lien public." },
  { href: "/equipe", label: "Équipe", icon: UsersRound, desc: "Inviter un collaborateur, définir son rôle et ses disponibilités." },
  { href: "/statistiques", label: "Statistiques", icon: BarChart3, desc: "Filtrer les périodes, suivre les réservations et les annulations." },
  { href: "/parametres", label: "Paramètres", icon: Settings, desc: "Modifier l’entreprise, connecter Google, configurer les rappels." },
  { href: "/abonnement", label: "Licence", icon: CreditCard, desc: "Votre licence à vie et sa facture.", ownerOnly: true },
];
