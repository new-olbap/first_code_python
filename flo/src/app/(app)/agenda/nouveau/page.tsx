import Card from "@/components/Card";
import NewAppointment, { type NewSP } from "./NewAppointment";

export default async function NouveauRdv({ searchParams }: { searchParams: Promise<NewSP> }) {
  return (
    <main><Card><NewAppointment sp={await searchParams} /></Card></main>
  );
}
