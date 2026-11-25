-- Test des demandes reçues par e-mail : à coller dans Supabase > SQL Editor > Run APRÈS la migration 0007.
-- Tout le test s'annule à la fin. Résultat attendu : « OK : demandes par e-mail vérifiées ».
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-0000000000a4';
  lundi constant date := (date_trunc('week', now() at time zone 'Europe/Paris') + interval '7 days')::date;
  a uuid; svc uuid; slug_a text; cli uuid; dem uuid; r1 uuid; r2 uuid;
begin
  delete from auth.users where id = alice;
  begin
    insert into auth.users (id, email) values (alice, 'a4@test.flo');
    update public.flo_reglages set code_obligatoire = false; -- ce test ne porte pas sur les codes d'accès (annulé à la fin)
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Plomberie Test E-mail', null, null);
    select slug into slug_a from public.organizations where id = a;
    insert into public.services (organization_id, name, duration_minutes) values (a, 'Dépannage', 60) returning id into svc;
    perform public.set_weekly_hours(alice, '[{"weekday":1,"start_time":"09:00","end_time":"12:00"}]');
    -- L'artisan ajoute la demande reçue par e-mail (fiche client + demande sans créneau)
    insert into public.customers (organization_id, kind, last_name, email) values (a, 'prospect', 'Durand', 'paul@exemple.fr') returning id into cli;
    insert into public.requests (organization_id, customer_id, source, message) values (a, cli, 'email', 'Fuite sous l''évier') returning id into dem;

    -- Le client choisit un créneau avec le lien : sa demande e-mail reçoit le créneau, pas de deuxième demande
    perform set_config('request.jwt.claims', '', true);
    set local role anon;
    r1 := public.public_book(slug_a, svc, lundi, '09:00', 'Paul', 'Durand', '0611111111', 'PAUL@exemple.fr', null, 'Plutôt le matin');
    reset role;
    assert r1 = dem, 'le créneau a créé une deuxième demande au lieu de compléter la demande e-mail';
    assert (select count(*) from public.requests where customer_id = cli) = 1, 'demande en double';
    assert (select source = 'email' and appointment_id is not null and message = E'Fuite sous l''évier\n\nPlutôt le matin'
              from public.requests where id = dem), 'demande e-mail mal complétée';
    assert (select a2.status from public.appointments a2 join public.requests q on q.appointment_id = a2.id where q.id = dem) = 'pending', 'créneau non bloqué';

    -- Une nouvelle réservation du même client (plus de demande ouverte sans créneau) crée une demande normale
    set local role anon;
    r2 := public.public_book(slug_a, svc, lundi, '11:00', 'Paul', 'Durand', '0611111111', 'paul@exemple.fr', null, null);
    reset role;
    assert r2 <> dem and (select source from public.requests where id = r2) = 'booking', 'deuxième réservation mal enregistrée';

    raise exception using errcode = 'FL000';
  exception when sqlstate 'FL000' then null;
  end;
end
$test$;

select 'OK : demandes par e-mail vérifiées (aucune donnée de test conservée)' as resultat;
