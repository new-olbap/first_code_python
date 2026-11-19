export const inputCls =
  "w-full rounded-2xl border border-[#c9d8e4] bg-white/70 px-4 py-3 text-sm outline-none transition placeholder:text-muted focus:border-accent focus:ring-2 focus:ring-accent/30";
const btn = "rounded-2xl px-4 py-2.5 text-sm font-semibold transition";
export const primaryBtn = `${btn} bg-gradient-to-r from-accent-ink to-accent-2 text-white shadow-lg shadow-accent/30 hover:brightness-105`;
export const secondaryBtn = `${btn} border border-[#c9d8e4] bg-white/80 text-ink hover:bg-white`;
export const buttonCls = `${primaryBtn} w-full py-3`;

export function Field({ label, ...props }: { label: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="block text-sm font-medium">
      {label}
      <input {...props} className={`${inputCls} mt-1`} />
    </label>
  );
}

export function TextArea({ label, ...props }: { label: string } & React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <label className="block text-sm font-medium">
      {label}
      <textarea {...props} className={`${inputCls} mt-1 min-h-28`} />
    </label>
  );
}

export function Select({ label, options, ...props }: { label: string; options: [string, string][] } & React.SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <label className="block text-sm font-medium">
      {label}
      <select {...props} className={`${inputCls} mt-1`}>
        {options.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
      </select>
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
