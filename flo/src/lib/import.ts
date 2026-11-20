// Import de clients depuis un fichier CSV (Excel, Google Contacts, autre logiciel) ou vCard (contacts du téléphone).
import { isEmail, isPhone } from "./form";

export type ImportedCustomer = {
  kind: "client" | "prospect"; first_name: string | null; last_name: string | null;
  email: string | null; phone: string | null; address: string | null; notes: string | null;
};
export type ImportResult = { customers: ImportedCustomer[]; noName: number; badContact: number };

// Texte d'un fichier : UTF-8, sinon Windows-1252 (CSV enregistré par Excel sous Windows).
export function decode(buf: ArrayBuffer) {
  try { return new TextDecoder("utf-8", { fatal: true }).decode(buf).replace(/^﻿/, ""); }
  catch { return new TextDecoder("windows-1252").decode(buf); }
}

// CSV : séparateur ; , ou tabulation détecté sur la 1re ligne ; champs entre guillemets gérés.
export function parseCsv(text: string): string[][] {
  const head = text.split(/\r?\n/, 1)[0];
  const sep = [";", ",", "\t"].reduce((best, s) => (head.split(s).length > head.split(best).length ? s : best), ";");
  const rows: string[][] = [];
  let row: string[] = [], field = "", quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') quoted = false;
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === sep) { row.push(field); field = ""; }
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && text[i + 1] === "\n") i++;
      row.push(field); rows.push(row); row = []; field = "";
    } else field += c;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  return rows.filter((r) => r.some((f) => f.trim()));
}

const norm = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]/g, "");
// Mots reconnus dans l'en-tête (comparés sans accents, espaces ni ponctuation).
const COLUMNS: Record<string, string[]> = {
  first: ["prenom", "firstname", "givenname"],
  last: ["nom", "lastname", "familyname", "surname", "nomdefamille"],
  full: ["nomcomplet", "fullname", "name", "client", "contact", "displayname"],
  company: ["societe", "entreprise", "company", "raisonsociale", "organization", "organisation"],
  phone: ["telephone", "tel", "portable", "mobile", "phone", "gsm", "numero"],
  email: ["email", "mail", "courriel", "adressemail"],
  address: ["adresse", "address", "rue"],
  zip: ["codepostal", "cp", "zip", "postalcode"],
  city: ["ville", "city", "commune", "localite"],
  notes: ["notes", "note", "commentaire", "commentaires", "remarque", "remarques", "observation", "observations"],
  kind: ["type", "statut", "categorie"],
};
function columnOf(header: string): string | null {
  const h = norm(header);
  for (const [k, words] of Object.entries(COLUMNS)) if (words.includes(h)) return k;
  let best: [string, number] | null = null; // sinon le mot connu le plus long par lequel l'en-tête commence (« Phone 1 - Value »)
  for (const [k, words] of Object.entries(COLUMNS)) for (const w of words) if (w.length > 2 && h.startsWith(w) && (!best || w.length > best[1])) best = [k, w.length];
  return best?.[0] ?? null;
}

export function csvToRecords(rows: string[][]): Record<string, string>[] {
  const [header, ...data] = rows;
  if (!header) return [];
  const cols = header.map(columnOf);
  return data.map((r) => {
    const rec: Record<string, string> = {};
    cols.forEach((c, i) => { const v = (r[i] ?? "").trim(); if (c && v && !rec[c]) rec[c] = v; });
    return rec;
  });
}

// vCard (.vcf) : FN, N, TEL, EMAIL, ADR, NOTE, ORG.
export function vcfToRecords(text: string): Record<string, string>[] {
  const unfolded = text.replace(/\r?\n[ \t]/g, ""); // lignes repliées
  return unfolded.split(/BEGIN:VCARD/i).slice(1).map((card) => {
    const rec: Record<string, string> = {};
    for (const line of card.split(/\r?\n/)) {
      const i = line.indexOf(":");
      if (i < 0) continue;
      const key = line.slice(0, i).split(";")[0].split(".").pop()!.toUpperCase();
      const val = line.slice(i + 1).replace(/\\n/gi, " ").replace(/\\([,;\\])/g, "$1").trim();
      if (!val) continue;
      if (key === "N") { const [last, first] = val.split(";"); rec.last ??= last; rec.first ??= first; }
      else if (key === "FN") rec.full ??= val;
      else if (key === "TEL") rec.phone ??= val;
      else if (key === "EMAIL") rec.email ??= val;
      else if (key === "ADR") rec.address ??= val.split(";").map((s) => s.trim()).filter(Boolean).join(" ");
      else if (key === "NOTE") rec.notes ??= val;
      else if (key === "ORG") rec.company ??= val.split(";")[0];
    }
    return rec;
  });
}

export function toCustomers(records: Record<string, string>[], asProspects: boolean): ImportResult {
  const res: ImportResult = { customers: [], noName: 0, badContact: 0 };
  for (const r of records) {
    const first = r.first?.slice(0, 80) || null;
    const last = (r.last || (!first ? r.full || r.company : "") || "").slice(0, 80) || null;
    if (!first && !last) { res.noName++; continue; }
    let email = r.email?.toLowerCase().slice(0, 254) || null, phone = r.phone?.slice(0, 30) || null;
    if (email && !isEmail(email)) { email = null; res.badContact++; }
    if (phone && !isPhone(phone)) { phone = null; res.badContact++; }
    const notes = [r.company && last !== r.company ? `Société : ${r.company}` : "", r.notes ?? ""].filter(Boolean).join("\n").slice(0, 5000) || null;
    res.customers.push({
      kind: asProspects || /prospect/i.test(r.kind ?? "") ? "prospect" : "client",
      first_name: first, last_name: last, email, phone,
      address: [r.address, r.zip, r.city].filter(Boolean).join(" ").slice(0, 300) || null, notes,
    });
  }
  return res;
}

// Clés de doublon : même e-mail OU même téléphone (chiffres seuls, +33 = 0) ; le nom seulement s'il n'y a ni l'un ni l'autre.
export function dupKeys(c: { email: string | null; phone: string | null; first_name: string | null; last_name: string | null }) {
  const keys = [c.email && `e:${c.email.toLowerCase()}`, c.phone && `t:${c.phone.replace(/\D/g, "").replace(/^33/, "0")}`].filter(Boolean) as string[];
  return keys.length ? keys : [`n:${norm(`${c.first_name ?? ""}${c.last_name ?? ""}`)}`];
}
