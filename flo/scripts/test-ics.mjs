// Usage : node scripts/test-ics.mjs
import assert from "node:assert/strict";
const { buildIcs } = await import("../src/lib/ics.ts");
const ics = buildIcs("FLO · Plomberie, Martin", [
  { id: "a1", starts_at: "2026-11-26T08:00:00+00:00", ends_at: "2026-11-26T09:30:00+00:00", status: "confirmed", notes: "Code portail 1234\nSonner fort", service: "Remplacement chauffe-eau", customer: "Claire Dupont", phone: "06 12 34 56 78", address: "12 rue Sainte-Catherine; Bordeaux" },
  { id: "a2", starts_at: "2026-11-27T13:00:00Z", ends_at: "2026-11-27T14:00:00Z", status: "pending", notes: null, service: null, customer: null, phone: null, address: null },
], new Date("2026-11-25T10:00:00Z"));
assert.ok(ics.startsWith("BEGIN:VCALENDAR\r\n") && ics.endsWith("END:VCALENDAR\r\n"));
assert.match(ics, /DTSTART:20261126T080000Z\r\nDTEND:20261126T093000Z/);
assert.match(ics, /X-WR-CALNAME:FLO · Plomberie\\, Martin/); // virgule échappée
assert.ok(ics.includes("LOCATION:12 rue Sainte-Catherine\\; Bordeaux"));
assert.match(ics, /SUMMARY:À confirmer · Rendez-vous\r\nSTATUS:TENTATIVE/);
assert.equal((ics.match(/BEGIN:VEVENT/g) || []).length, 2);
// Aucune ligne de plus de 75 octets, et le dépliage redonne le texte d'origine.
for (const l of ics.split("\r\n")) assert.ok(new TextEncoder().encode(l).length <= 75, l);
assert.match(ics.replace(/\r\n /g, ""), /DESCRIPTION:Client : Claire Dupont\\nTéléphone : 06 12 34 56 78\\nCode portail 1234\\nSonner fort/);
console.log("ics : OK");
