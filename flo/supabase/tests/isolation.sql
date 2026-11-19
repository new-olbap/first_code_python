-- Test d'isolation : à coller dans Supabase > SQL Editor > Run APRÈS les migrations 0001 et 0002.
-- Tout le test tient dans un seul bloc qui s'annule lui-même à la fin :
-- aucune donnée de test ne reste dans la base.
-- Résultat attendu : « OK : isolation vérifiée ». Sinon une erreur rouge indique le problème.
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-00000000000a';
  bob   constant uuid := '00000000-0000-0000-0000-00000000000b';
  chloe constant uuid := '00000000-0000-0000-0000-00000000000c';
  david constant uuid := '00000000-0000-0000-0000-00000000000d';
  a uuid; b uuid; n int; client_a uuid; presta_a uuid;
begin
  -- Nettoie les comptes fictifs qu'une ancienne version de ce test a pu laisser.
  delete from auth.users where id in (alice, bob, chloe, david);

  begin -- sous-bloc annulé à la fin grâce à l'erreur « sentinelle » FL000
    insert into auth.users (id, email, raw_user_meta_data) values
      (alice, 'a@test.flo', '{"first_name":"Alice"}'),
      (bob,   'b@test.flo', '{"first_name":"Bob"}'),
      (chloe, 'c@test.flo', '{"first_name":"Chloé"}'),
      (david, 'd@test.flo', '{"first_name":"David"}');

    set local role authenticated;

    -- Alice crée l'entreprise A, Bob l'entreprise B.
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Entreprise A', 'Plombier', null);
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    b := public.create_organization('Entreprise B', 'Électricien', null);

    -- Alice ajoute Chloé (admin) et David (collaborateur) dans A.
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    insert into public.memberships (organization_id, user_id, role) values (a, chloe, 'admin'), (a, david, 'member');
    insert into public.customers (organization_id, first_name, phone) values (a, 'Claire', '0600000000') returning id into client_a;
    insert into public.services (organization_id, name, duration_minutes) values (a, 'Diagnostic', 60) returning id into presta_a;

    -- Bob (entreprise B) ne voit ni ne modifie rien de A.
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    assert (select count(*) from public.organizations) = 1, 'Bob voit une autre entreprise';
    assert (select name from public.organizations) = 'Entreprise B', 'Bob ne voit pas la sienne';
    assert (select count(*) from public.memberships) = 1, 'Bob voit les membres d''une autre entreprise';
    assert (select count(*) from public.profiles) = 1, 'Bob voit des profils d''une autre entreprise';
    assert (select count(*) from public.customers) = 0, 'Bob voit les clients d''une autre entreprise';
    assert (select count(*) from public.services) = 0, 'Bob voit les prestations d''une autre entreprise';
    update public.customers set notes = 'piraté' where id = client_a;
    get diagnostics n = row_count;
    assert n = 0, 'Bob a modifié un client de A';
    begin
      insert into public.customers (organization_id, first_name) values (a, 'Intrus');
      raise exception 'Bob a ajouté un client chez A';
    exception when insufficient_privilege then null;
    end;
    update public.organizations set name = 'piraté' where id = a;
    get diagnostics n = row_count;
    assert n = 0, 'Bob a modifié l''entreprise A';
    begin
      insert into public.memberships (organization_id, user_id, role) values (a, bob, 'owner');
      raise exception 'Bob a pu rejoindre A';
    exception when insufficient_privilege then null;
    end;
    begin
      insert into public.organizations (name) values ('Création directe');
      raise exception 'insertion directe d''entreprise autorisée';
    exception when insufficient_privilege then null;
    end;

    -- Chloé (admin de A) gère l'équipe mais ne peut pas devenir propriétaire ni retirer Alice.
    perform set_config('request.jwt.claims', json_build_object('sub', chloe)::text, true);
    assert (select count(*) from public.memberships) = 3, 'Chloé ne voit pas toute son équipe';
    assert (select count(*) from public.profiles) = 3, 'Chloé ne voit pas les profils de son équipe';
    begin
      update public.memberships set role = 'owner' where user_id = chloe;
      raise exception 'Chloé (admin) s''est promue propriétaire';
    exception when insufficient_privilege then null;
    end;
    delete from public.memberships where user_id = alice;
    get diagnostics n = row_count;
    assert n = 0, 'Chloé (admin) a retiré la propriétaire';
    update public.memberships set role = 'admin' where user_id = david;
    get diagnostics n = row_count;
    assert n = 1, 'Chloé (admin) ne peut pas gérer un collaborateur';

    -- David (collaborateur) ne peut ni modifier l'entreprise ni l'équipe.
    reset role; -- Chloé l'a passé admin juste avant : on le remet collaborateur.
    update public.memberships set role = 'member' where user_id = david;
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', david)::text, true);
    update public.organizations set name = 'renommé' where true;
    get diagnostics n = row_count;
    assert n = 0, 'un collaborateur a modifié l''entreprise';
    delete from public.memberships where true;
    get diagnostics n = row_count;
    assert n = 0, 'un collaborateur a retiré des membres';
    assert (select count(*) from public.customers) = 1, 'un collaborateur ne voit pas les clients de son entreprise';
    insert into public.customers (organization_id, last_name) values (a, 'Martin');
    update public.customers set notes = 'rappeler' where id = client_a;
    get diagnostics n = row_count;
    assert n = 1, 'un collaborateur ne peut pas modifier un client';
    delete from public.customers where id = client_a;
    get diagnostics n = row_count;
    assert n = 0, 'un collaborateur a supprimé définitivement un client';
    assert (select count(*) from public.services) = 1, 'un collaborateur ne voit pas les prestations';
    update public.services set duration_minutes = 5 where id = presta_a;
    get diagnostics n = row_count;
    assert n = 0, 'un collaborateur a modifié une prestation';
    begin
      insert into public.services (organization_id, name, duration_minutes) values (a, 'Pirate', 30);
      raise exception 'un collaborateur a créé une prestation';
    exception when insufficient_privilege then null;
    end;

    -- Un visiteur non connecté ne voit rien.
    set local role anon;
    assert (select count(*) from public.organizations) = 0, 'anonyme voit des entreprises';
    assert (select count(*) from public.memberships) = 0, 'anonyme voit des membres';
    assert (select count(*) from public.profiles) = 0, 'anonyme voit des profils';
    assert (select count(*) from public.customers) = 0, 'anonyme voit des clients';
    assert (select count(*) from public.services) = 0, 'anonyme voit des prestations';

    reset role;
    raise exception using errcode = 'FL000'; -- tout est bon : on annule les données de test
  exception when sqlstate 'FL000' then null;
  end;
end
$test$;

select 'OK : isolation vérifiée (aucune donnée de test conservée)' as resultat;
