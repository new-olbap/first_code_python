// Vérifie l'isolation des entreprises sur le vrai projet Supabase, via la vraie connexion.
// Usage : node --env-file=.env.local scripts/check-isolation.mjs
// Nécessite « Confirm email » désactivé. Crée 2 comptes test-flo-…@mailinator.com
// (à supprimer ensuite dans Supabase > Authentication > Users).
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL, key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const client = () => createClient(url, key, { auth: { persistSession: false } });
const ts = Date.now();
let failed = 0;
const check = (ok, label) => { console.log(`${ok ? "✅" : "❌"} ${label}`); if (!ok) failed++; };

async function newOwner(name, company) {
  const sb = client();
  const { data, error } = await sb.auth.signUp({
    email: `test-flo-${ts}-${name.toLowerCase()}@mailinator.com`, password: `Test-${ts}!`,
    options: { data: { first_name: name } },
  });
  if (error || !data.session) throw new Error(`inscription ${name} : ${error?.message ?? "pas de session (Confirm email activé ?)"}`);
  const { data: orgId, error: e2 } = await sb.rpc("create_organization", { p_name: company, p_trade: "Test", p_address: "" });
  if (e2) throw new Error(`création entreprise ${name} : ${e2.message}`);
  return { sb, id: data.user.id, orgId };
}

const A = await newOwner("Alice", `Test A ${ts}`);
const B = await newOwner("Bob", `Test B ${ts}`);

const orgsA = (await A.sb.from("organizations").select("id,name")).data;
const orgsB = (await B.sb.from("organizations").select("id,name")).data;
check(orgsA?.length === 1 && orgsA[0].id === A.orgId, "Alice voit uniquement son entreprise");
check(orgsB?.length === 1 && orgsB[0].id === B.orgId, "Bob voit uniquement son entreprise");

const hack = await B.sb.from("organizations").update({ name: "piraté" }).eq("id", A.orgId).select();
check(!hack.error && hack.data.length === 0, "Bob ne peut pas modifier l'entreprise d'Alice");

const join = await B.sb.from("memberships").insert({ organization_id: A.orgId, user_id: B.id, role: "owner" });
check(!!join.error, "Bob ne peut pas s'ajouter dans l'entreprise d'Alice");

const direct = await B.sb.from("organizations").insert({ name: "Création directe" });
check(!!direct.error, "Création d'entreprise impossible sans passer par la fonction prévue");

const profs = (await B.sb.from("profiles").select("id,first_name")).data;
check(profs?.length === 1 && profs[0].first_name === "Bob", "Bob ne voit que son propre profil (prénom enregistré)");

const memB = (await B.sb.from("memberships").select("role")).data;
check(memB?.length === 1 && memB[0].role === "owner", "Bob est propriétaire de son entreprise");

// Clients et prestations (étape 04)
const cliA = await A.sb.from("customers").insert({ organization_id: A.orgId, first_name: "Claire" }).select("id").single();
const preA = await A.sb.from("services").insert({ organization_id: A.orgId, name: "Diagnostic", duration_minutes: 60 }).select("id").single();
check(!cliA.error && !preA.error, "Alice ajoute un client et une prestation");
check((await B.sb.from("customers").select("id")).data?.length === 0, "Bob ne voit pas les clients d'Alice");
check((await B.sb.from("services").select("id")).data?.length === 0, "Bob ne voit pas les prestations d'Alice");
const cliHack = await B.sb.from("customers").update({ notes: "piraté" }).eq("id", cliA.data?.id).select();
check(!cliHack.error && cliHack.data.length === 0, "Bob ne peut pas modifier un client d'Alice");
check(!!(await B.sb.from("customers").insert({ organization_id: A.orgId, first_name: "Intrus" })).error, "Bob ne peut pas ajouter un client chez Alice");

const anon = client();
const anonOrgs = (await anon.from("organizations").select("id")).data;
const anonRpc = await anon.rpc("create_organization", { p_name: "x", p_trade: "", p_address: "" });
const anonCli = (await anon.from("customers").select("id")).data;
check(anonOrgs?.length === 0 && anonCli?.length === 0 && !!anonRpc.error, "Un visiteur non connecté ne voit rien et ne crée rien");

console.log(failed ? `\n${failed} vérification(s) échouée(s)` : "\nOK : isolation vérifiée sur le vrai projet");
process.exit(failed ? 1 : 0);
