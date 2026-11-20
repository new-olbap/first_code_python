// Usage : node scripts/test-import.mjs
import assert from "node:assert/strict";
import { register } from "node:module";
// Le code de l'app importe sans extension (« ./form ») comme le veut Next.js : on ajoute « .ts » (ou « .js » pour next/…) pour Node.
register("data:text/javascript," + encodeURIComponent(`export async function resolve(s, c, next) {
  try { return await next(s, c); } catch (e) { return next(s + (s.startsWith(".") ? ".ts" : ".js"), c); } }`));
const m = await import("../src/lib/import.ts");

// 1. CSV Excel français : « ; », accents en Windows-1252, guillemets, ligne sans nom, e-mail invalide
const excel = "Prénom;Nom;Téléphone;E-mail;Adresse;Code postal;Ville;Commentaire\r\n" +
  "Claire;Dubois;06 12 34 56 78;claire@exemple.fr;4 place Bellecour;69002;Lyon;\"Code portail 1234; chien\"\r\n" +
  ";;07 00 00 00 00;;;;;\r\n" +
  "Hélène;Martin;0612;pas-un-mail;;;;\r\n";
const bytes = Uint8Array.from([...excel].map((c) => ({ "é": 0xe9, "è": 0xe8 })[c] ?? c.charCodeAt(0)));
const text = m.decode(bytes.buffer);
assert.ok(text.startsWith("Prénom;Nom;Téléphone"), "accents Windows-1252 récupérés");
let r = m.toCustomers(m.csvToRecords(m.parseCsv(text)), false);
assert.equal(r.customers.length, 2); assert.equal(r.noName, 1); assert.equal(r.badContact, 2);
assert.deepEqual(r.customers[0], { kind: "client", first_name: "Claire", last_name: "Dubois", email: "claire@exemple.fr", phone: "06 12 34 56 78", address: "4 place Bellecour 69002 Lyon", notes: "Code portail 1234; chien" });
assert.equal(r.customers[1].first_name, "Hélène"); assert.equal(r.customers[1].email, null); assert.equal(r.customers[1].phone, null);

// 2. Export Google Contacts (anglais, « , », colonnes « Phone 1 - Value »)
const google = "First Name,Last Name,Organization Name,E-mail 1 - Value,Phone 1 - Value,Notes\n" +
  "Karim,Benali,,karim@exemple.fr,+33 7 98 76 54 32,\"Devis SDB, rappeler\"\n" +
  ",,Boulangerie Paul,contact@paul.fr,,\n";
r = m.toCustomers(m.csvToRecords(m.parseCsv(google)), true);
assert.equal(r.customers.length, 2);
assert.equal(r.customers[0].phone, "+33 7 98 76 54 32"); assert.equal(r.customers[0].notes, "Devis SDB, rappeler"); assert.equal(r.customers[0].kind, "prospect");
assert.equal(r.customers[1].last_name, "Boulangerie Paul"); assert.equal(r.customers[1].notes, null);

// 3. Contacts iPhone (.vcf), ligne repliée
const vcf = "BEGIN:VCARD\r\nVERSION:3.0\r\nN:Petit;Marc;;;\r\nFN:Marc Petit\r\nitem1.TEL;type=CELL:06 00 00 00 01\r\nEMAIL;type=INTERNET:marc@exemple.fr\r\nADR;type=HOME:;;12 rue des \r\n Lilas;Lyon;;69003;France\r\nEND:VCARD\r\n" +
  "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Sophie\r\nTEL:0700000002\r\nEND:VCARD\r\n";
r = m.toCustomers(m.vcfToRecords(vcf), false);
assert.equal(r.customers.length, 2);
assert.deepEqual([r.customers[0].first_name, r.customers[0].last_name, r.customers[0].phone, r.customers[0].address], ["Marc", "Petit", "06 00 00 00 01", "12 rue des Lilas Lyon 69003 France"]);
assert.equal(r.customers[1].last_name, "Sophie");

// 4. Doublons : même e-mail (casse) OU même numéro (+33 / 0, points, espaces) ; nom seul si aucun contact
const shared = (a, b) => m.dupKeys(a).some((k) => m.dupKeys(b).includes(k));
const c = (email, phone, first_name = "x", last_name = null) => ({ email, phone, first_name, last_name });
assert.ok(shared(c("A@B.fr", null), c("a@b.fr", "0600000000")));
assert.ok(shared(c("claire@x.fr", "06 12 34 56 78"), c(null, "+33 6.12.34.56.78")), "même téléphone, e-mail absent d'un côté");
assert.ok(!shared(c("a@x.fr", null), c("b@x.fr", null)));
assert.ok(shared(c(null, null, "Jean", "Martin"), c(null, null, "jean", "MARTIN")));
assert.ok(!shared(c(null, null, "Jean", "Martin"), c(null, "0600000000", "Jean", "Martin")), "homonyme avec téléphone : pas fusionné");
assert.deepEqual(m.parseCsv(""), []);
console.log("import : OK");
