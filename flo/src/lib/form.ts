import { redirect } from "next/navigation";

// Redirige avec un message affiché par <Notice> (?erreur=… ou ?info=…).
// Déclaration `function` (et non flèche) pour que TypeScript sache que la suite n'est pas atteinte.
export function go(path: string, key: "erreur" | "info", msg: string): never {
  redirect(`${path}${path.includes("?") ? "&" : "?"}${key}=${encodeURIComponent(msg)}`);
}

export const str = (fd: FormData, k: string, max = 300) => String(fd.get(k) ?? "").trim().slice(0, max);

export const isUuid = (v: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
export const isEmail = (v: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
export const isPhone = (v: string) => /^[0-9+().\s-]{6,30}$/.test(v);

// "80" / "80,50" / "80.5" -> centimes ; "" -> null ; invalide -> NaN
export function parsePrice(v: string): number | null {
  if (!v) return null;
  const m = v.replace(/\s|€/g, "").replace(",", ".").match(/^(\d{1,7})(?:\.(\d{1,2}))?$/);
  return m ? Number(m[1]) * 100 + Number((m[2] ?? "0").padEnd(2, "0")) : NaN;
}
