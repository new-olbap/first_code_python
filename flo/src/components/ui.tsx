export const inputCls =
  "w-full rounded-2xl border border-white/80 bg-white/70 px-4 py-3 text-sm outline-none transition placeholder:text-muted focus:border-accent focus:ring-2 focus:ring-accent/30";
export const buttonCls =
  "w-full rounded-2xl bg-gradient-to-r from-accent-ink to-accent-2 px-4 py-3 text-sm font-semibold text-white shadow-lg shadow-accent/30 hover:brightness-105";

export function Field({ label, ...props }: { label: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="block text-sm font-medium">
      {label}
      <input {...props} className={`${inputCls} mt-1`} />
    </label>
  );
}

// Message passé dans l'URL par les actions serveur (?erreur=… ou ?info=…).
export function Notice({ erreur, info }: { erreur?: string; info?: string }) {
  if (!erreur && !info) return null;
  return (
    <p role={erreur ? "alert" : "status"}
      className={`rounded-2xl px-4 py-3 text-sm font-medium ${erreur ? "bg-accent-2/10 text-[#a0236c]" : "bg-accent/10 text-accent-ink"}`}>
      {erreur ?? info}
    </p>
  );
}

export type Msg = Promise<{ erreur?: string; info?: string }>;
