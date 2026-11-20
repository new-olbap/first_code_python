// Lit un e-mail copié-collé (Gmail, Outlook, téléphone…) : expéditeur, téléphone et texte du message.
export type ParsedEmail = { first_name: string | null; last_name: string | null; email: string | null; phone: string | null; message: string };

const EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i;
const PHONE = /(?:\+33\s?|0)[1-9](?:[\s.-]?\d{2}){4}/;
// Lignes d'en-tête ajoutées par les messageries : on les retire du message gardé.
const HEADER = /^\s*(de|from|à|a|to|cc|date|envoyé|sent|répondre à|reply-to)\s*:/i;
const cap = (w: string) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();

export function parseEmail(text: string, ignore: string[] = []): ParsedEmail {
  const lines = text.replace(/\r/g, "").split("\n");
  const skip = new Set(ignore.map((e) => e.toLowerCase()));
  // Expéditeur : ligne « De : Nom <adresse> » si présente, sinon la première adresse qui n'est pas celle de l'artisan.
  const from = lines.find((l) => /^\s*(de|from)\s*:/i.test(l) && EMAIL.test(l));
  const all = [...text.matchAll(new RegExp(EMAIL, "gi"))].map((m) => m[0].toLowerCase()).filter((e) => !skip.has(e));
  const email = (from?.match(EMAIL)?.[0].toLowerCase() ?? null) || all[0] || null;

  let first: string | null = null, last: string | null = null;
  const name = from?.replace(/^\s*(de|from)\s*:\s*/i, "").replace(/<[^>]*>|\S+@\S+/g, "").replace(/["']/g, "").trim();
  if (name) {
    const w = name.split(/\s+/);
    [first, last] = w.length > 1 ? [w[0], w.slice(1).join(" ")] : [null, w[0]];
  } else if (email) {
    // Pas de nom affiché : « paul.durand@… » → Paul Durand
    const w = email.split("@")[0].split(/[._-]+/).filter((x) => /^[a-zà-ÿ]{2,}$/i.test(x)).map(cap);
    [first, last] = w.length > 1 ? [w[0], w.slice(1).join(" ")] : [null, w[0] ?? null];
  }

  const phone = text.match(PHONE)?.[0].trim() ?? null;
  const message = lines.filter((l) => !HEADER.test(l)).join("\n").replace(/\n{3,}/g, "\n\n").trim().slice(0, 5000);
  return { first_name: first?.slice(0, 80) ?? null, last_name: last?.slice(0, 80) || (email || phone ? "Contact e-mail" : null), email, phone, message };
}
