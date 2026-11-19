export const inputCls =
  "w-full border border-line bg-surface px-4 py-3 text-sm outline-none transition placeholder:text-muted focus:border-white/50 focus:ring-2 focus:ring-white/15";
const btn = "px-4 py-2.5 text-sm font-semibold transition active:scale-[0.98]";
export const primaryBtn = `${btn} bg-ink text-bg hover:opacity-90`;
export const secondaryBtn = `${btn} border border-line bg-surface text-ink hover:bg-white/10`;
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
      className={`px-4 py-3 text-sm font-medium ${erreur ? "bg-accent-2/15 text-accent-2" : "bg-white/10 text-ink"}`}>
      {erreur ?? info}
    </p>
  );
}

export type Msg = Promise<{ erreur?: string; info?: string }>;
