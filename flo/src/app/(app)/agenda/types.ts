export type Status = "pending" | "confirmed" | "cancelled";
export type AgendaRow = {
  id: string; day: string; start_time: string; end_time: string; duration_minutes: number; status: Status;
  staff_id: string; staff_name: string | null; customer_id: string | null; customer_name: string | null;
  customer_phone: string | null; customer_address: string | null; service_id: string | null; service_name: string | null; notes: string | null;
};
export const STATUS_LABEL: Record<Status, string> = { pending: "À confirmer", confirmed: "Confirmé", cancelled: "Annulé" };
export const STATUS_CLS: Record<Status, string> = {
  confirmed: "border-l-2 border-ink bg-surface",
  pending: "border-l-2 border-accent-2 bg-accent-2/10",
  cancelled: "border-l-2 border-line bg-surface text-muted line-through opacity-60",
};
