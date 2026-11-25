-- Test des relances : à coller dans Supabase > SQL Editor > Run APRÈS la migration 0008.
-- Tout le test s'annule à la fin. Résultat attendu : « OK : relances vérifiées ».
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-0000000000a5';
  bob   constant uuid := '00000000-0000-0000-0000-0000000000b5';
  a uuid; b uuid; ent uuid; diag uuid; ent_b uuid; c uuid[] := '{}'; x uuid; i int;
  ago constant interval[] := array['11 months 10 days', '6 months', '13 months', '13 months', '13 months', '13 months']::interval[];
begin
  delete from auth.users where id in (alice, bob);
  begin
    insert into auth.users (id, email) values (alice, 'a5@test.flo'), (bob, 'b5@test.flo');
    update public.flo_reglages set code_obligatoire = false; -- ce test ne porte pas sur les codes d'accès (annulé à la fin)
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    b := public.create_organization('Entreprise de Bob', null, null);
    insert into public.services (organization_id, name, duration_minutes, repeat_months) values (b, 'Entretien Bob', 60, 12) returning id into ent_b;
    insert into public.customers (organization_id, last_name) values (b, 'Client de Bob') returning id into x;
    insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at)
      values (b, x, ent_b, bob, now() - interval '13 months', now() - interval '13 months' + interval '1 hour');

    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Chauffage Alice', null, null);
    insert into public.services (organization_id, name, duration_minutes, repeat_months) values (a, 'Entretien chaudière', 60, 12) returning id into ent;
    insert into public.services (organization_id, name, duration_minutes) values (a, 'Diagnostic', 60) returning id into diag;
    -- c1 dû dans 20 j · c2 fait il y a 6 mois · c3 dû mais RDV déjà prévu · c4 dû mais seul RDV annulé
    -- c5 dû mais client archivé · c6 prestation non périodique
    for i in 1..6 loop
      insert into public.customers (organization_id, last_name) values (a, 'Client ' || i) returning id into x;
      c := c || x;
      insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at, status)
        values (a, x, case when i = 6 then diag else ent end, alice, now() - ago[i] + make_interval(hours => i), now() - ago[i] + make_interval(hours => i + 1) - interval '1 minute',
                case when i = 4 then 'cancelled' else 'confirmed' end);
    end loop;
    insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at)
      values (a, c[3], ent, alice, now() + interval '5 days', now() + interval '5 days 1 hour');
    update public.customers set archived_at = now() where id = c[5];
    -- Nouveau passage d'un client (c1 avait aussi un entretien il y a 2 ans) : c'est le dernier qui compte
    insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at)
      values (a, c[1], ent, alice, now() - interval '24 months', now() - interval '24 months' + interval '1 hour');

    assert (select array_agg(customer_id) from public.due_maintenance()) = array[c[1]],
      'clients à relancer incorrects : ' || coalesce((select string_agg(cu.last_name, ', ') from public.due_maintenance() d join public.customers cu on cu.id = d.customer_id), 'aucun');
    assert (select due_on - last_day between 365 and 366 from public.due_maintenance()), 'échéance mal calculée';

    -- Bob ne voit que son client ; un visiteur ne peut pas appeler la fonction
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    assert (select count(*) from public.due_maintenance()) = 1, 'Bob voit les relances d''Alice';
    set local role anon;
    begin
      perform public.due_maintenance();
      raise exception 'un visiteur a lu les relances';
    exception when insufficient_privilege then null;
    end;

    reset role;
    raise exception using errcode = 'FL000';
  exception when sqlstate 'FL000' then null;
  end;
end
$test$;

select 'OK : relances vérifiées (aucune donnée de test conservée)' as resultat;
