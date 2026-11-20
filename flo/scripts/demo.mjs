// Compte de démonstration « Plomberie Martin » : crée le compte (ou le remet à zéro) et le remplit de données
// réalistes, datées à partir d'aujourd'hui. Relancez-le avant chaque démo.
// Usage : node --env-file=.env.local scripts/demo.mjs
// Nécessite DEMO_EMAIL, DEMO_EMAIL_EQUIPE et DEMO_PASSWORD dans .env.local, et « Confirm email » désactivé dans Supabase.
// Les téléphones (06 39 98 …) sont réservés aux fictions par l'ARCEP, les e-mails sont en @example.com : aucun vrai contact.
import { createClient } from "@supabase/supabase-js";

const { NEXT_PUBLIC_SUPABASE_URL: url, NEXT_PUBLIC_SUPABASE_ANON_KEY: key, DEMO_EMAIL, DEMO_EMAIL_EQUIPE, DEMO_PASSWORD: pw } = process.env;
if (!DEMO_EMAIL || !DEMO_EMAIL_EQUIPE || !pw) throw new Error("DEMO_EMAIL, DEMO_EMAIL_EQUIPE et DEMO_PASSWORD manquent dans .env.local");
const client = () => createClient(url, key, { auth: { persistSession: false } });
const ok = (r, what) => { if (r.error) throw new Error(`${what} : ${r.error.message}`); return r.data; };

async function login(email, firstName) {
  const sb = client();
  let r = await sb.auth.signInWithPassword({ email, password: pw });
  if (r.error?.code === "invalid_credentials") r = await sb.auth.signUp({ email, password: pw, options: { data: { first_name: firstName } } });
  const user = ok(r, `connexion ${email}`).user;
  return { sb, id: user.id };
}

// Dates locales (Paris) : jour J + n, au format AAAA-MM-JJ, et jour de la semaine (1 = lundi).
const today = new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Paris" }).format(new Date());
const day = (n) => { const d = new Date(`${today}T12:00:00Z`); d.setUTCDate(d.getUTCDate() + n); return d.toISOString().slice(0, 10); };
const weekday = (n) => ((new Date(`${day(n)}T12:00:00Z`).getUTCDay() + 6) % 7) + 1;
const hoursAgo = (h) => new Date(Date.now() - h * 3600_000).toISOString();
let seed = 7; const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647); // toujours les mêmes données
const pick = (a) => a[Math.floor(rnd() * a.length)];

// ===== 1. Comptes : Thomas (propriétaire) et Lucas (collaborateur) =====
const T = await login(DEMO_EMAIL, "Thomas");
let m = ok(await T.sb.from("memberships").select("organization_id").eq("user_id", T.id).maybeSingle(), "entreprise");
const org = m?.organization_id ?? ok(await T.sb.rpc("create_organization", { p_name: "Plomberie Martin", p_trade: "Plombier-chauffagiste", p_address: "12 rue de la République, 69002 Lyon" }), "création entreprise");
await T.sb.from("organizations").update({ slug: "plomberie-martin-demo", booking_enabled: true }).eq("id", org); // adresse lisible si libre

const L = await login(DEMO_EMAIL_EQUIPE, "Lucas");
if (!ok(await L.sb.from("memberships").select("organization_id").eq("user_id", L.id).maybeSingle(), "équipe")) {
  const { token } = ok(await T.sb.from("invitations").insert({ organization_id: org, role: "member" }).select("token").single(), "invitation");
  ok(await L.sb.rpc("accept_invitation", { p_token: token }), "Lucas rejoint l'équipe");
}

// ===== 2. Remise à zéro =====
for (const t of ["requests", "appointments", "customers", "services", "time_off"]) ok(await T.sb.from(t).delete().eq("organization_id", org), `vidage ${t}`);

// ===== 3. Horaires, absence, prestations =====
// Une plage par jour, comme la page Équipe (qui n'en gère qu'une).
const semaine = (fin) => [1, 2, 3, 4, 5].map((d) => ({ weekday: d, start_time: "08:00", end_time: fin }));
ok(await T.sb.rpc("set_weekly_hours", { p_user: T.id, p_rules: [...semaine("18:00"), { weekday: 6, start_time: "09:00", end_time: "12:00" }] }), "horaires Thomas");
ok(await T.sb.rpc("set_weekly_hours", { p_user: L.id, p_rules: semaine("17:00") }), "horaires Lucas");
const conge = [...Array(14).keys()].map((i) => i + 7).find((n) => weekday(n) === 4); // jeudi de la semaine prochaine
ok(await T.sb.from("time_off").insert({ organization_id: org, user_id: L.id, starts_on: day(conge), ends_on: day(conge + 1), reason: "Congés" }), "absence");

const S = Object.fromEntries(ok(await T.sb.from("services").insert([
  { name: "Dépannage fuite", duration_minutes: 60, price_cents: 8900 },
  { name: "Débouchage canalisation", duration_minutes: 60, price_cents: 11000 },
  { name: "Entretien chaudière", duration_minutes: 60, price_cents: 12000, repeat_months: 12 },
  { name: "Installation chauffe-eau", duration_minutes: 180, price_cents: 45000 },
  { name: "Visite pour devis", duration_minutes: 30, price_cents: 0 },
].map((s) => ({ ...s, organization_id: org }))).select("id, name"), "prestations").map((s) => [s.name, s.id]));

// ===== 4. Clients et prospects =====
const people = [
  ["Claire", "Dubois", "4 place Bellecour, 69002 Lyon", "Code portail 4512"], ["Martine", "Roux", "18 rue Mercière, 69002 Lyon", "Chaudière Saunier Duval, 2015"],
  ["Jean", "Morel", "7 cours Lafayette, 69006 Lyon", null], ["Sophie", "Garnier", "25 rue de Marseille, 69007 Lyon", "Chien dans le jardin"],
  ["Nicolas", "Faure", "3 rue Paul Bert, 69003 Lyon", null], ["Isabelle", "Mercier", "11 quai Saint-Antoine, 69002 Lyon", "Appeler avant de passer"],
  ["Pierre", "Blanc", "56 avenue Jean Jaurès, 69007 Lyon", null], ["Nathalie", "Guerin", "9 rue Garibaldi, 69006 Lyon", null],
  ["Laurent", "Boyer", "30 montée de la Grande Côte, 69001 Lyon", "4e étage sans ascenseur"], ["Céline", "Lefebvre", "2 rue Juliette Récamier, 69006 Lyon", null],
  ["Philippe", "Chevalier", "14 rue de Créqui, 69006 Lyon", null], ["Valérie", "Girard", "8 rue Saint-Jean, 69005 Lyon", null],
  ["Éric", "Bonnet", "41 rue Duguesclin, 69006 Lyon", "Chaudière Frisquet"], ["Sandrine", "François", "5 rue Tronchet, 69006 Lyon", null],
  ["Olivier", "Fontaine", "22 rue Ney, 69006 Lyon", null], ["Karim", "Benali", "17 rue Pasteur, 69007 Lyon", null],
  ["Julie", "Perrin", "6 rue Chevreul, 69007 Lyon", null], ["Antoine", "Lemoine", "33 rue de Sèze, 69006 Lyon", null],
];
const prospects = [["Amandine", "Colin", null], ["Hugo", "Masson", "10 rue Vaubecour, 69002 Lyon"], ["Léa", "Rey", null]];
const contact = (f, l, i) => ({ email: `${f}.${l}`.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase() + "@example.com", phone: `06 39 98 00 ${String(i + 10).padStart(2, "0")}` });
const C = ok(await T.sb.from("customers").insert([
  ...people.map(([f, l, address, notes], i) => ({ kind: "client", first_name: f, last_name: l, address, notes, ...contact(f, l, i) })),
  ...prospects.map(([f, l, address], i) => ({ kind: "prospect", first_name: f, last_name: l, address, created_at: hoursAgo(24 * (10 + 6 * i)), ...contact(f, l, i + 40) })),
].map((c) => ({ ...c, organization_id: org }))).select("id, first_name, last_name"), "clients");
const cid = (name) => C.find((c) => `${c.first_name} ${c.last_name}` === name).id;
const clients = C.filter((c) => !prospects.some(([f, l]) => c.first_name === f && c.last_name === l)).map((c) => c.id);

// ===== 5. Rendez-vous : 3 mois passés, 3 semaines à venir, entretiens annuels =====
const save = async (sb, staff, customer, service, n, time, notes = null) => {
  const r = await sb.rpc("save_appointment", { p_id: null, p_customer: customer, p_service: S[service], p_staff: staff, p_date: typeof n === "number" ? day(n) : n, p_time: time, p_duration: null, p_notes: notes });
  return r.error ? null : r.data; // chevauchement ou absence : on passe, comme le ferait l'agenda
};
const usuels = ["Dépannage fuite", "Débouchage canalisation", "Entretien chaudière", "Dépannage fuite", "Visite pour devis", "Installation chauffe-eau"];
const created = [];
for (let n = -90; n <= 20; n++) {
  if (weekday(n) > 5 || n === 0) continue;
  for (const [who, slots] of [[T.id, ["08:00", "10:00", "14:00", "16:00"]], [L.id, ["08:30", "10:30", "14:00", "15:30"]]]) {
    const count = n < 0 ? (rnd() < 0.35 ? 1 : 2) : (rnd() < 0.5 ? 2 : 3);
    for (const time of slots.filter(() => rnd() < count / 4)) {
      const id = await save(T.sb, who, pick(clients), pick(usuels), n, time);
      if (id) created.push({ id, n });
    }
  }
}
// Aujourd'hui : une journée bien remplie, pour le tableau de bord
if (weekday(0) <= 5) {
  await save(T.sb, T.id, cid("Claire Dubois"), "Dépannage fuite", 0, "08:30", "Fuite sous l'évier, code portail 4512");
  await save(T.sb, T.id, cid("Jean Morel"), "Entretien chaudière", 0, "10:00");
  await save(T.sb, T.id, cid("Isabelle Mercier"), "Visite pour devis", 0, "14:00", "Devis salle de bain");
  await save(T.sb, L.id, cid("Laurent Boyer"), "Débouchage canalisation", 0, "09:00");
  await save(T.sb, L.id, cid("Pierre Blanc"), "Installation chauffe-eau", 0, "13:30");
}
// Entretiens faits il y a environ 11 mois : ce sont les clients à relancer
for (const [name, n] of [["Martine Roux", -335], ["Éric Bonnet", -340], ["Céline Lefebvre", -345], ["Nathalie Guerin", -350]]) {
  const d = [0, 1, 2, 3].map((k) => n - k).find((x) => weekday(x) <= 5);
  await save(T.sb, T.id, cid(name), "Entretien chaudière", d, "11:00");
}
// Quelques annulations (passées et à venir)
const annules = created.filter((_, i) => i % 13 === 5).map((a) => a.id);
ok(await T.sb.from("appointments").update({ status: "cancelled" }).in("id", annules), "annulations");

// ===== 6. Demandes : tous les cas possibles =====
const anon = client();
const slug = ok(await T.sb.from("organizations").select("slug").eq("id", org).single(), "adresse").slug;
const slot = async (service, from) => {
  const s = ok(await anon.rpc("public_slots", { p_slug: slug, p_service: S[service], p_from: day(from), p_days: 7 }), "créneaux");
  return s[Math.floor(s.length / 3)];
};
// a) Réservation en ligne par un nouveau client, et par un client déjà connu (fiche retrouvée par son téléphone)
for (const [first, last, phone, email, service, msg] of [
  ["Thomas", "Petit", "06 39 98 00 90", "thomas.petit@example.com", "Débouchage canalisation", "Évier de cuisine bouché, l'eau ne s'écoule plus."],
  ["Claire", "Dubois", "06 39 98 00 10", "", "Entretien chaudière", "Entretien annuel, comme l'an dernier."],
]) {
  const s = await slot(service, 2);
  ok(await anon.rpc("public_book", { p_slug: slug, p_service: S[service], p_date: s.slot_day, p_time: s.slot_time, p_first: first, p_last: last, p_phone: phone, p_email: email, p_address: "", p_message: msg }), "réservation en ligne");
}
const req = async (r) => ok(await T.sb.from("requests").insert({ organization_id: org, ...r }), "demande");
// b) E-mail d'un nouveau client, sans créneau : à qui l'artisan répond avec son lien
const paul = ok(await T.sb.from("customers").insert({ organization_id: org, kind: "prospect", first_name: "Paul", last_name: "Durand", email: "paul.durand@example.com", phone: "06 39 98 00 91" }).select("id").single(), "Paul").id;
await req({ customer_id: paul, source: "email", created_at: hoursAgo(3), message: "Objet : Fuite sous l'évier\n\nBonjour,\nJ'ai une fuite sous l'évier de la cuisine depuis ce matin, j'ai coupé l'eau. Vous pourriez passer cette semaine ?\nMerci,\nPaul\n06 39 98 00 91" });
// c) E-mail d'une cliente déjà connue, sans créneau
// c bis) E-mail d'une prospecte resté sans réponse du client depuis 3 jours : il apparaît dans « À relancer »
await req({ customer_id: cid("Amandine Colin"), source: "email", created_at: hoursAgo(75), message: "Objet : Ballon d'eau chaude\n\nBonjour, mon ballon fait un bruit bizarre, pouvez-vous passer le voir ?\nAmandine Colin" });
await req({ customer_id: cid("Martine Roux"), source: "email", created_at: hoursAgo(26), message: "Objet : Entretien chaudière\n\nBonjour Monsieur Martin,\nC'est bientôt l'entretien annuel de ma chaudière. Quelles sont vos disponibilités ?\nBonne journée,\nMartine Roux" });
// d) E-mail auquel l'artisan a répondu avec son lien : le client a choisi un créneau, à confirmer
const sk = await slot("Visite pour devis", 3);
const karim = [cid("Karim Benali"), "Visite pour devis", sk.slot_day, sk.slot_time, "Plutôt en fin de journée si possible."];
const rk = (await save(T.sb, T.id, ...karim)) ?? (await save(T.sb, L.id, ...karim)); // le créneau libre peut être celui de Lucas
if (!rk) throw new Error("créneau de Karim introuvable");
ok(await T.sb.from("appointments").update({ status: "pending" }).eq("id", rk), "créneau à confirmer");
await req({ customer_id: cid("Karim Benali"), appointment_id: rk, source: "email", created_at: hoursAgo(20), message: "Objet : Devis salle de bain\n\nBonjour, je voudrais un devis pour remplacer ma baignoire par une douche à l'italienne.\nKarim Benali\n\nPlutôt en fin de journée si possible." });
// e) Déjà traitées : une acceptée, une refusée (démarchage)
const fut = created.find((a) => a.n > 2 && !annules.includes(a.id));
await req({ customer_id: cid("Julie Perrin"), appointment_id: fut.id, source: "booking", status: "accepted", created_at: hoursAgo(50), message: "Robinet de la salle de bain qui goutte." });
await req({ customer_id: null, source: "email", status: "refused", created_at: hoursAgo(30), message: "Objet : Boostez votre visibilité sur Google !\n\nBonjour, nous proposons le référencement de votre entreprise en 1re page…" });

const nb = async (t, f = (q) => q) => (await f(T.sb.from(t).select("id", { count: "exact", head: true }).eq("organization_id", org))).count;
console.log(`OK : compte de démonstration prêt
  ${await nb("customers")} clients et prospects, ${await nb("appointments")} rendez-vous, ${await nb("requests")} demandes (${await nb("requests", (q) => q.eq("status", "new"))} à traiter)
  Connexion : ${DEMO_EMAIL} (Thomas, propriétaire) ou ${DEMO_EMAIL_EQUIPE} (Lucas, collaborateur)
  Page de réservation : /r/${slug}`);
