// Données fictives du prototype — seront remplacées par Supabase (étape 03).
export const user = { firstName: "Thomas", company: "Martin Plomberie" };

export const kpis = [
  { label: "RDV ce mois", value: "24", delta: "+12 %" },
  { label: "Nouveaux prospects", value: "12", delta: "+4" },
  { label: "À confirmer", value: "5", delta: "urgent", href: "/demandes" },
  { label: "Présence", value: "87 %", delta: "+3 pts" },
];

export const week = [
  { day: "L", rdv: 3, annules: 0 },
  { day: "M", rdv: 5, annules: 1 },
  { day: "M", rdv: 2, annules: 0 },
  { day: "J", rdv: 6, annules: 1 },
  { day: "V", rdv: 4, annules: 0 },
  { day: "S", rdv: 1, annules: 0 },
  { day: "D", rdv: 0, annules: 0 },
];

export type Status = "confirmé" | "à confirmer" | "annulé";
export const upcoming: { time: string; client: string; service: string; staff: string; status: Status }[] = [
  { time: "09:00", client: "Claire Dubois", service: "Diagnostic fuite", staff: "Thomas", status: "confirmé" },
  { time: "11:30", client: "Karim Benali", service: "Pose chauffe-eau", staff: "Lucas", status: "à confirmer" },
  { time: "14:00", client: "Sophie Laurent", service: "Devis salle de bain", staff: "Thomas", status: "confirmé" },
  { time: "16:30", client: "Marc Petit", service: "Entretien chaudière", staff: "Lucas", status: "annulé" },
];

// Jours du mois courant ayant au moins un RDV (démo).
export const busyDays = [3, 5, 8, 11, 12, 15, 18, 19, 22, 24, 26, 29];
