// Usage : node scripts/test-email.mjs
import assert from "node:assert/strict";
const { parseEmail } = await import("../src/lib/email.ts");

// 1. Copie Gmail : en-têtes, nom affiché, téléphone dans la signature, adresse de l'artisan ignorée
const gmail = `De : Paul Durand <paul.durand@exemple.fr>
Date : lun. 23 nov. 2026 à 08:14
À : plomberie.martin@gmail.com
Objet : Fuite sous l'évier

Bonjour,
J'ai une fuite sous l'évier depuis ce matin, vous pourriez passer cette semaine ?
Merci,
Paul
06 12 34 56 78`;
let r = parseEmail(gmail, ["plomberie.martin@gmail.com"]);
assert.equal(r.first_name, "Paul"); assert.equal(r.last_name, "Durand");
assert.equal(r.email, "paul.durand@exemple.fr"); assert.equal(r.phone, "06 12 34 56 78");
assert.ok(r.message.startsWith("Objet : Fuite sous l'évier"), r.message);
assert.ok(!/plomberie\.martin|Date :|De :/.test(r.message), "en-têtes gardés");

// 2. Corps seul, sans nom : nom tiré de l'adresse, adresse de l'artisan ignorée, +33
r = parseEmail("Bonjour, devis pour une chaudière svp. marie-claire.petit@orange.fr / +33 7 11 22 33 44. Copie à plomberie.martin@gmail.com", ["Plomberie.Martin@gmail.com"]);
assert.equal(r.email, "marie-claire.petit@orange.fr"); assert.equal(r.first_name, "Marie"); assert.equal(r.last_name, "Claire Petit");
assert.equal(r.phone, "+33 7 11 22 33 44");

// 3. Outlook en anglais, nom entre guillemets, un seul mot
r = parseEmail(`From: "Dupont" <j.dupont@ex.com>\nSent: Monday\nTo: moi@ex.com\n\nHello`);
assert.equal(r.first_name, null); assert.equal(r.last_name, "Dupont"); assert.equal(r.message, "Hello");

// 4. Ni e-mail ni téléphone : pas de contact
r = parseEmail("Bonjour, rappelez-moi");
assert.equal(r.email, null); assert.equal(r.phone, null); assert.equal(r.last_name, null);

// 5. Adresse sans nom lisible (chiffres) : « Contact e-mail »
r = parseEmail("écrit par 06123@free.fr");
assert.equal(r.last_name, "Contact e-mail"); assert.equal(r.first_name, null);
console.log("OK : lecture des e-mails vérifiée (5 cas)");
