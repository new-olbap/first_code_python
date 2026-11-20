-- Test RGPD : à coller dans Supabase > SQL Editor > Run APRÈS la migration 0006.
-- Tout le test s'annule à la fin. Résultat attendu : « OK : RGPD vérifié ».
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-0000000000a3'; -- propriétaire avec équipe
  bob   constant uuid := '00000000-0000-0000-0000-0000000000b3'; -- collaborateur
  solo  constant uuid := '00000000-0000-0000-0000-0000000000e3'; -- seul dans son entreprise
  a uuid; s uuid; cli uuid; svc uuid; r uuid;
begin
  delete from auth.users where id in (alice, bob, solo);
  begin
    insert into auth.users (id, email) values (alice, 'a3@test.flo'), (bob, 'b3@test.flo'), (solo, 's3@test.flo');
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Équipe d''Alice', null, null);
    insert into public.customers (organization_id, first_name, last_name, phone) values (a, 'Claire', 'Dubois', '0600000000') returning id into cli;
    insert into public.services (organization_id, name, duration_minutes) values (a, 'Diag', 60) returning id into svc;
    reset role;
    insert into public.memberships (organization_id, user_id, role) values (a, bob, 'member');
    insert into public.requests (organization_id, customer_id, source, message) values (a, cli, 'manual', 'demande');
    set local role authenticated;
    r := public.save_appointment(null, cli, svc, alice, current_date + 3, '10:00', null, 'Code portail 1234');

    -- Un collaborateur ne peut pas supprimer un client
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    begin
      perform public.delete_customer(cli);
      raise exception 'un collaborateur a supprimé un client';
    exception when insufficient_privilege then null;
    end;

    -- La propriétaire supprime le client : demandes supprimées, rendez-vous anonymisé
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    perform public.delete_customer(cli);
    assert not exists (select 1 from public.customers where id = cli), 'client non supprimé';
    assert not exists (select 1 from public.requests where customer_id = cli), 'demandes du client conservées';
    assert (select customer_id is null and notes is null from public.appointments where id = r), 'rendez-vous non anonymisé';

    -- Alice, seule propriétaire d'une équipe, ne peut pas supprimer son compte ; Bob a un rendez-vous : non plus
    begin
      perform public.delete_my_account();
      raise exception 'la seule propriétaire d''une équipe a supprimé son compte';
    exception when sqlstate 'FL006' then null;
    end;
    update public.appointments set staff_id = bob where id = r;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    begin
      perform public.delete_my_account();
      raise exception 'compte supprimé alors qu''il a des rendez-vous';
    exception when sqlstate 'FL007' then null;
    end;
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    update public.appointments set staff_id = alice where id = r;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    perform public.delete_my_account();
    reset role;
    assert not exists (select 1 from auth.users where id = bob), 'compte de Bob non supprimé';
    assert exists (select 1 from public.organizations where id = a), 'l''entreprise d''Alice a disparu avec Bob';

    -- Seul dans son entreprise : tout est supprimé avec le compte
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', solo)::text, true);
    s := public.create_organization('Solo', null, null);
    insert into public.customers (organization_id, last_name) values (s, 'Client du solo');
    perform public.delete_my_account();
    reset role;
    assert not exists (select 1 from auth.users where id = solo), 'compte solo non supprimé';
    assert not exists (select 1 from public.organizations where id = s), 'entreprise solo conservée';
    assert not exists (select 1 from public.customers where organization_id = s), 'clients du solo conservés';

    -- Un visiteur ne peut rien supprimer
    set local role anon;
    begin
      perform public.delete_my_account();
      raise exception 'un visiteur a appelé la suppression de compte';
    exception when insufficient_privilege then null;
    end;

    reset role;
    raise exception using errcode = 'FL000';
  exception when sqlstate 'FL000' then null;
  end;
end
$test$;

select 'OK : RGPD vérifié (aucune donnée de test conservée)' as resultat;
