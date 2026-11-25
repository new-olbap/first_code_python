-- Test des invitations et des rôles : à coller dans Supabase > SQL Editor > Run APRÈS la migration 0005.
-- Tout le test s'annule à la fin. Résultat attendu : « OK : équipe vérifiée ».
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-0000000000a2'; -- propriétaire
  bob   constant uuid := '00000000-0000-0000-0000-0000000000b2'; -- invité
  carol constant uuid := '00000000-0000-0000-0000-0000000000c2'; -- a déjà sa propre entreprise
  dan   constant uuid := '00000000-0000-0000-0000-0000000000d2'; -- 2e invité
  a uuid; tok text; tok2 text; n int;
begin
  delete from auth.users where id in (alice, bob, carol, dan);
  begin
    insert into auth.users (id, email, raw_user_meta_data) values
      (alice, 'a2@test.flo', '{"first_name":"Alice"}'), (bob, 'b2@test.flo', '{"first_name":"Bob"}'),
      (carol, 'c2@test.flo', '{"first_name":"Carol"}'), (dan, 'd2@test.flo', '{"first_name":"Dan"}');
    update public.flo_reglages set code_obligatoire = false; -- ce test ne porte pas sur les codes d'accès (annulé à la fin)
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', carol)::text, true);
    perform public.create_organization('Entreprise de Carol', null, null);
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Entreprise d''Alice', null, null);
    insert into public.invitations (organization_id, role, created_by) values (a, 'member', alice) returning token into tok;
    assert tok ~ '^[0-9a-f]{64}$', 'jeton d''invitation mal formé';
    begin
      insert into public.invitations (organization_id, role) values (a, 'owner');
      raise exception 'invitation comme propriétaire acceptée';
    exception when check_violation then null;
    end;

    -- Visiteur : voit seulement le nom de l'entreprise et le rôle
    perform set_config('request.jwt.claims', '', true);
    set local role anon;
    assert (public.invitation_info(tok) ->> 'organization') = 'Entreprise d''Alice', 'page d''invitation sans le nom de l''entreprise';
    assert public.invitation_info('0000') is null, 'jeton inconnu accepté';
    assert (select count(*) from public.invitations) = 0, 'un visiteur voit les invitations';
    begin
      perform public.accept_invitation(tok);
      raise exception 'un visiteur non connecté a rejoint l''entreprise';
    exception when insufficient_privilege then null;
    end;

    -- Bob accepte : il devient collaborateur ; l'invitation ne resert pas
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    assert public.accept_invitation(tok) = a, 'Bob n''a pas rejoint l''entreprise';
    assert (select role from public.memberships where user_id = bob) = 'member', 'mauvais rôle après invitation';
    assert (select count(*) from public.invitations) = 0, 'un collaborateur voit les invitations';
    begin
      insert into public.invitations (organization_id, role) values (a, 'member');
      raise exception 'un collaborateur a créé une invitation';
    exception when insufficient_privilege then null;
    end;
    perform set_config('request.jwt.claims', json_build_object('sub', dan)::text, true);
    begin
      perform public.accept_invitation(tok);
      raise exception 'invitation utilisée deux fois';
    exception when sqlstate 'P0002' then null;
    end;

    -- Carol a déjà une entreprise ; invitation expirée refusée
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    insert into public.invitations (organization_id, role) values (a, 'admin') returning token into tok2;
    perform set_config('request.jwt.claims', json_build_object('sub', carol)::text, true);
    begin
      perform public.accept_invitation(tok2);
      raise exception 'un compte avec une entreprise en a rejoint une deuxième';
    exception when sqlstate 'FL004' then null;
    end;
    reset role;
    update public.invitations set expires_at = now() - interval '1 minute' where token = tok2;
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', dan)::text, true);
    begin
      perform public.accept_invitation(tok2);
      raise exception 'invitation expirée acceptée';
    exception when sqlstate 'P0002' then null;
    end;

    -- Toujours un propriétaire : Alice seule propriétaire ne peut ni se rétrograder ni partir
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    begin
      update public.memberships set role = 'admin' where user_id = alice;
      raise exception 'la seule propriétaire s''est rétrogradée';
    exception when sqlstate 'FL005' then null;
    end;
    begin
      delete from public.memberships where user_id = alice;
      raise exception 'la seule propriétaire a quitté l''entreprise';
    exception when sqlstate 'FL005' then null;
    end;
    -- … mais elle peut transmettre la propriété puis se rétrograder
    update public.memberships set role = 'owner' where user_id = bob;
    update public.memberships set role = 'member' where user_id = alice;
    get diagnostics n = row_count;
    assert n = 1, 'transmission de la propriété impossible';

    -- Supprimer l'entreprise reste possible (cascade)
    reset role;
    delete from public.organizations where id = a;
    assert not exists (select 1 from public.memberships where organization_id = a), 'membres restants après suppression de l''entreprise';

    raise exception using errcode = 'FL000';
  exception when sqlstate 'FL000' then null;
  end;
end
$test$;

select 'OK : équipe vérifiée (aucune donnée de test conservée)' as resultat;
