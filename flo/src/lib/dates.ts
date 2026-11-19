// Dates « locales » au format AAAA-MM-JJ, calculées en UTC pour éviter tout effet de fuseau.
// Le fuseau de l'entreprise n'intervient que pour savoir quel jour on est (todayIn) ;
// les heures des rendez-vous sont converties par la base (fonctions agenda / save_appointment).
const toDate = (iso: string) => new Date(iso + "T00:00:00Z");

export const isIsoDate = (v: string | undefined): v is string =>
  !!v && /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(toDate(v).getTime()) && toDate(v).toISOString().startsWith(v);
export const isTime = (v: string) => /^([01]\d|2[0-3]):[0-5]\d$/.test(v);

export const todayIn = (tz: string) => new Intl.DateTimeFormat("en-CA", { timeZone: tz }).format(new Date());
export function addDays(iso: string, n: number) {
  const d = toDate(iso); d.setUTCDate(d.getUTCDate() + n); return d.toISOString().slice(0, 10);
}
export const weekday = (iso: string) => ((toDate(iso).getUTCDay() + 6) % 7) + 1; // 1 = lundi … 7 = dimanche
export const startOfWeek = (iso: string) => addDays(iso, 1 - weekday(iso));
export const startOfMonth = (iso: string) => iso.slice(0, 8) + "01";
export function addMonths(iso: string, n: number) {
  const d = toDate(startOfMonth(iso)); d.setUTCMonth(d.getUTCMonth() + n); return d.toISOString().slice(0, 10);
}
export const fmt = (iso: string, opts: Intl.DateTimeFormatOptions) =>
  new Intl.DateTimeFormat("fr-FR", { timeZone: "UTC", ...opts }).format(toDate(iso));
export const nowTimeIn = (tz: string) =>
  new Intl.DateTimeFormat("fr-FR", { timeZone: tz, hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).format(new Date());
