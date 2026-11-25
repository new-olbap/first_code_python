// Fichier iCalendar (RFC 5545) lu par Google Agenda, Apple Calendrier et Outlook.
export type FeedEvent = {
  id: string; starts_at: string; ends_at: string; status: string; notes: string | null;
  service: string | null; customer: string | null; phone: string | null; address: string | null;
};

// Heures en UTC (suffixe Z) : pas besoin de décrire le fuseau, chaque agenda convertit dans le sien.
const utc = (iso: string) => new Date(iso).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
const esc = (t: string) => t.replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\r?\n/g, "\\n");

// Lignes de 75 octets au plus, la suite commence par un espace (sans couper un caractère accentué).
function fold(line: string) {
  const out: string[] = [];
  let cur = "", size = 0;
  for (const ch of line) {
    const n = new TextEncoder().encode(ch).length;
    if (size + n > (out.length ? 74 : 75)) { out.push(cur); cur = ""; size = 0; }
    cur += ch; size += n;
  }
  out.push(cur);
  return out.join("\r\n ");
}

export function buildIcs(calName: string, events: FeedEvent[], now = new Date()) {
  const stamp = utc(now.toISOString());
  const lines = [
    "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//FLO//Agenda//FR", "CALSCALE:GREGORIAN", "METHOD:PUBLISH",
    `X-WR-CALNAME:${esc(calName)}`, "REFRESH-INTERVAL;VALUE=DURATION:PT1H", "X-PUBLISHED-TTL:PT1H",
  ];
  for (const e of events) {
    const title = [e.service, e.customer].filter(Boolean).join(" · ") || "Rendez-vous";
    const desc = [e.customer && `Client : ${e.customer}`, e.phone && `Téléphone : ${e.phone}`, e.notes].filter(Boolean).join("\n");
    lines.push(
      "BEGIN:VEVENT", `UID:${e.id}@flo`, `DTSTAMP:${stamp}`, `DTSTART:${utc(e.starts_at)}`, `DTEND:${utc(e.ends_at)}`,
      `SUMMARY:${esc(e.status === "pending" ? `À confirmer · ${title}` : title)}`,
      `STATUS:${e.status === "pending" ? "TENTATIVE" : "CONFIRMED"}`,
    );
    if (e.address) lines.push(`LOCATION:${esc(e.address)}`);
    if (desc) lines.push(`DESCRIPTION:${esc(desc)}`);
    lines.push("END:VEVENT");
  }
  lines.push("END:VCALENDAR");
  return lines.map(fold).join("\r\n") + "\r\n";
}
