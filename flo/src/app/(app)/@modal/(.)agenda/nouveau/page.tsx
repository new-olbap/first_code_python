import Modal from "@/components/Modal";
import NewAppointment, { type NewSP } from "../../../agenda/nouveau/NewAppointment";

// Intercepte /agenda/nouveau quand on y arrive depuis l'app : formulaire en fenêtre, sans quitter l'écran.
export default async function NouveauRdvModal({ searchParams }: { searchParams: Promise<NewSP> }) {
  return <Modal label="Nouveau rendez-vous"><NewAppointment sp={await searchParams} inModal /></Modal>;
}
