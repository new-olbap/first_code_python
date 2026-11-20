// Usage : node scripts/test-grid.mjs
import assert from "node:assert/strict";
const { layoutDay, toMin } = await import("../src/app/(app)/agenda/grid.ts");
const ev = (start_time, end_time, id) => ({ id, start_time, end_time });
const pos = (list) => Object.fromEntries(layoutDay(list).map((p) => [p.e.id, [p.lane, p.lanes]]));
assert.equal(toMin("09:30"), 570);
assert.deepEqual(pos([ev("09:00", "10:00", "a"), ev("10:00", "11:00", "b")]), { a: [0, 1], b: [0, 1] }); // collés : pleine largeur
assert.deepEqual(pos([ev("09:00", "11:00", "a"), ev("10:00", "12:00", "b")]), { a: [0, 2], b: [1, 2] }); // chevauchement : côte à côte
assert.deepEqual(pos([ev("09:00", "12:00", "a"), ev("09:00", "10:00", "b"), ev("10:00", "11:00", "c")]), { a: [0, 2], b: [1, 2], c: [1, 2] }); // c reprend la place de b
assert.deepEqual(pos([ev("09:00", "10:00", "a"), ev("09:30", "10:30", "b"), ev("14:00", "15:00", "c")]), { a: [0, 2], b: [1, 2], c: [0, 1] }); // groupes séparés
assert.equal(layoutDay([ev("23:00", "00:00", "a")])[0].end, 1440); // finit à minuit
assert.deepEqual(layoutDay([]), []);
console.log("grille : OK");
