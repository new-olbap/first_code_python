import { Field, Select, TextArea } from "@/components/ui";

export type Customer = {
  id: string; kind: "client" | "prospect"; first_name: string | null; last_name: string | null;
  email: string | null; phone: string | null; address: string | null; notes: string | null; archived_at: string | null;
};

export default function CustomerFields({ c }: { c?: Customer }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Select label="Type" name="kind" defaultValue={c?.kind ?? "client"} options={[["client", "Client"], ["prospect", "Prospect"]]} />
      <div className="hidden sm:block" />
      <Field label="Prénom" name="first_name" defaultValue={c?.first_name ?? ""} maxLength={80} autoComplete="off" />
      <Field label="Nom (ou société)" name="last_name" defaultValue={c?.last_name ?? ""} maxLength={80} autoComplete="off" required />
      <Field label="Téléphone" name="phone" type="tel" defaultValue={c?.phone ?? ""} maxLength={30} autoComplete="off" pattern="[0-9+\(\)\.\s\-]{6,30}" title="Chiffres, espaces, +, -, ( ) uniquement" />
      <Field label="E-mail" name="email" type="email" defaultValue={c?.email ?? ""} maxLength={254} autoComplete="off" />
      <div className="sm:col-span-2"><Field label="Adresse d’intervention" name="address" defaultValue={c?.address ?? ""} maxLength={300} autoComplete="off" /></div>
      <div className="sm:col-span-2"><TextArea label="Notes" name="notes" defaultValue={c?.notes ?? ""} maxLength={5000} placeholder="Code portail, chien, préférences…" /></div>
    </div>
  );
}

export const fullName = (c: Pick<Customer, "first_name" | "last_name">) => [c.first_name, c.last_name].filter(Boolean).join(" ");
