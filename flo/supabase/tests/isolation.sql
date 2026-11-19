-- Test d'isolation : à coller dans Supabase > SQL Editor > Run APRÈS la migration.
-- Tout est annulé à la fin (rollback) : aucune donnée de test ne reste.
-- Résultat attendu : une ligne « OK : isolation vérifiée ». Sinon une erreur indique le problème.
begin;

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.flo', '{"first_name":"Alice"}'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.flo', '{"first_name":"Bob"}'),
  ('00000000-0000-0000-0000-00000000000c', 'c@test.flo', '{"first_name":"Chloé"}'),
  ('00000000-0000-0000-0000-00000000000d', 'd@test.flo', '{"first_name":"David"}');

create temp table t_ids (k text primary key, id uuid) on commit drop;
grant select, insert on t_ids to authenticated;

set local role authenticated;

-- Alice crée l'entreprise A, Bob l'entreprise B.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a"}', true);
insert into t_ids values ('A', public.create_organization('Entreprise A', 'Plombier', null));
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b"}', true);
insert into t_ids values ('B', public.create_organization('Entreprise B', 'Électricien', null));

-- Alice ajoute Chloé (admin) et David (collaborateur) dans A.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a"}', true);
insert into public.memberships (organization_id, user_id, role)
  select id, '00000000-0000-0000-0000-00000000000c', 'admin' from t_ids where k = 'A';
insert into public.memberships (organization_id, user_id, role)
  select id, '00000000-0000-0000-0000-00000000000d', 'member' from t_ids where k = 'A';

-- Bob (entreprise B) ne voit ni ne modifie rien de A.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b"}', true);
do $$
declare a uuid := (select id from t_ids where k = 'A'); n int;
begin
  assert (select count(*) from public.organizations) = 1, 'Bob voit une autre entreprise';
  assert (select name from public.organizations) = 'Entreprise B', 'Bob ne voit pas la sienne';
  assert (select count(*) from public.memberships) = 1, 'Bob voit les membres d''une autre entreprise';
  assert (select count(*) from public.profiles) = 1, 'Bob voit des profils d''une autre entreprise';
  update public.organizations set name = 'piraté' where id = a;
  get diagnostics n = row_count;
  assert n = 0, 'Bob a modifié l''entreprise A';
  begin
    insert into public.memberships values (a, auth.uid(), 'owner');
    raise exception 'Bob a pu rejoindre A';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.organizations (name) values ('Création directe');
    raise exception 'insertion directe d''entreprise autorisée';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Chloé (admin de A) gère l'équipe mais ne peut pas devenir propriétaire ni retirer Alice.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c"}', true);
do $$
declare n int;
begin
  assert (select count(*) from public.memberships) = 3, 'Chloé ne voit pas toute son équipe';
  assert (select count(*) from public.profiles) = 3, 'Chloé ne voit pas les profils de son équipe';
  begin
    update public.memberships set role = 'owner' where user_id = auth.uid();
    raise exception 'Chloé (admin) s''est promue propriétaire';
  exception when insufficient_privilege then null;
  end;
  delete from public.memberships where user_id = '00000000-0000-0000-0000-00000000000a';
  get diagnostics n = row_count;
  assert n = 0, 'Chloé (admin) a retiré la propriétaire';
  update public.memberships set role = 'admin' where user_id = '00000000-0000-0000-0000-00000000000d';
  get diagnostics n = row_count;
  assert n = 1, 'Chloé (admin) ne peut pas gérer un collaborateur';
end $$;

-- David (collaborateur) ne peut ni modifier l'entreprise ni l'équipe.
-- Chloé l'a passé admin juste avant : on le remet collaborateur.
reset role;
update public.memberships set role = 'member' where user_id = '00000000-0000-0000-0000-00000000000d';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000d"}', true);
do $$
declare n int;
begin
  update public.organizations set name = 'renommé' where true;
  get diagnostics n = row_count;
  assert n = 0, 'un collaborateur a modifié l''entreprise';
  delete from public.memberships where true;
  get diagnostics n = row_count;
  assert n = 0, 'un collaborateur a retiré des membres';
end $$;

-- Un visiteur non connecté ne voit rien.
set local role anon;
do $$
begin
  assert (select count(*) from public.organizations) = 0, 'anonyme voit des entreprises';
  assert (select count(*) from public.memberships) = 0, 'anonyme voit des membres';
  assert (select count(*) from public.profiles) = 0, 'anonyme voit des profils';
end $$;

select 'OK : isolation vérifiée' as resultat;
rollback;
