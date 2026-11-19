// Usage : node scripts/test-dates.mjs
import assert from "node:assert/strict";
const d = await import("../src/lib/dates.ts");
assert.equal(d.addDays("2026-12-31", 1), "2027-01-01");
assert.equal(d.addDays("2026-03-01", -1), "2026-02-28");
assert.equal(d.addDays("2026-03-28", 1), "2026-03-29"); // passage à l'heure d'été : pas de saut
assert.equal(d.weekday("2026-11-16"), 1); // lundi
assert.equal(d.weekday("2026-11-22"), 7); // dimanche
assert.equal(d.startOfWeek("2026-11-22"), "2026-11-16");
assert.equal(d.startOfWeek("2026-11-16"), "2026-11-16");
assert.equal(d.addMonths("2026-01-31", 1), "2026-02-01");
assert.equal(d.addMonths("2026-12-15", 1), "2027-01-01");
assert.ok(d.isIsoDate("2028-02-29") && !d.isIsoDate("2026-02-30") && !d.isIsoDate("2026-1-5") && !d.isIsoDate(undefined));
assert.ok(d.isTime("09:30") && d.isTime("23:59") && !d.isTime("24:00") && !d.isTime("9:30"));
assert.match(d.todayIn("Europe/Paris"), /^\d{4}-\d{2}-\d{2}$/);
assert.match(d.nowTimeIn("Europe/Paris"), /^([01]\d|2[0-3]):[0-5]\d$/);
assert.equal(d.fmt("2026-11-19", { weekday: "long", day: "numeric", month: "long" }), "jeudi 19 novembre");
console.log("dates : OK");
