-- Test de la réservation publique : à coller dans Supabase > SQL Editor > Run APRÈS la migration 0004.
-- Tout le test s'annule à la fin : aucune donnée conservée. Résultat attendu : « OK : réservation vérifiée ».
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-0000000000a1';
  bob   constant uuid := '00000000-0000-0000-0000-0000000000b1';
  lundi constant date := (date_trunc('week', now() at time zone 'Europe/Paris') + interval '7 days')::date; -- lundi prochain (réservable : moins de 60 jours)
  a uuid; svc uuid; slug_a text; req uuid; n int; c1 uuid; c2 uuid;
begin
  delete from auth.users where id in (alice, bob);
  begin
    insert into auth.users (id, email, raw_user_meta_data) values
      (alice, 'a1@test.flo', '{"first_name":"Alice"}'), (bob, 'b1@test.flo', '{"first_name":"Bob"}');
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    perform public.create_organization('Entreprise de Bob', null, null);
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Plomberie Élan & Fils', 'Plombier', null);
    select slug into slug_a from public.organizations where id = a;
    assert slug_a ~ '^plomberie-elan-fils-[0-9a-f]{4}$', 'adresse publique mal formée : ' || coalesce(slug_a, 'rien');
    insert into public.services (organization_id, name, duration_minutes) values (a, 'Diagnostic', 60) returning id into svc;
    perform public.set_weekly_hours(alice, '[{"weekday":1,"start_time":"09:00","end_time":"12:00"}]');

    -- Visiteur non connecté
    perform set_config('request.jwt.claims', '', true);
    set local role anon;
    assert (public.public_booking(slug_a) ->> 'name') = 'Plomberie Élan & Fils', 'page publique introuvable';
    assert json_array_length(public.public_booking(slug_a) -> 'services') = 1, 'prestation absente de la page publique';
    assert public.public_booking('inexistant') is null, 'adresse inconnue acceptée';
    assert (select string_agg(slot_time, ',' order by slot_time) from public.public_slots(slug_a, svc, lundi, 1)) = '09:00,09:30,10:00,10:30,11:00',
      'créneaux proposés incorrects';
    assert (select count(*) from public.public_slots(slug_a, svc, lundi + 1, 1)) = 0, 'créneaux proposés un jour non travaillé';

    req := public.public_book(slug_a, svc, lundi, '10:00', 'Claire', 'Dubois', '06 12 34 56 78', 'Claire@Test.fr', '4 place Bellecour', 'Fuite sous évier');
    assert (select string_agg(slot_time, ',' order by slot_time) from public.public_slots(slug_a, svc, lundi, 1)) = '09:00,11:00',
      'le créneau réservé n''est pas bloqué';
    begin
      perform public.public_book(slug_a, svc, lundi, '10:30', 'Jean', 'Autre', '0700000000', null, null, null);
      raise exception 'créneau qui chevauche accepté';
    exception when sqlstate 'FL003' then null;
    end;
    begin
      perform public.public_book(slug_a, svc, lundi, '08:00', 'Jean', 'Autre', '0700000000', null, null, null);
      raise exception 'créneau hors horaires accepté';
    exception when sqlstate 'FL003' then null;
    end;
    begin
      perform public.public_book(slug_a, svc, lundi, '09:00', 'Jean', 'Autre', '0700000000', 'pas-un-mail', null, null);
      raise exception 'e-mail invalide accepté';
    exception when sqlstate '22023' then null;
    end;
    begin
      perform public.public_book(slug_a, svc, lundi, '09:00', 'Jean', '', '0700000000', null, null, null);
      raise exception 'réservation sans nom acceptée';
    exception when sqlstate '22023' then null;
    end;
    -- Même personne (téléphone écrit autrement) : même fiche client
    perform public.public_book(slug_a, svc, lundi, '11:00', 'Claire', 'Dubois', '+33 6.12.34.56.78', null, null, null);
    begin
      perform public.public_book(slug_a, svc, lundi + 7, '09:00', 'Claire', 'Dubois', '0612345678', null, null, null);
      perform public.public_book(slug_a, svc, lundi + 7, '11:00', 'Claire', 'Dubois', '0612345678', null, null, null);
      raise exception 'plus de 3 demandes en attente acceptées pour un même contact';
    exception when sqlstate 'FL002' then null;
    end;
    assert (select count(*) from public.requests) = 0, 'un visiteur voit les demandes';
    assert (select count(*) from public.customers) = 0, 'un visiteur voit les clients';

    -- Une autre entreprise ne voit rien
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    assert (select count(*) from public.requests) = 0, 'Bob voit les demandes d''Alice';
    begin
      perform public.resolve_request(req, true);
      raise exception 'Bob a accepté une demande d''Alice';
    exception when sqlstate 'P0002' then null;
    end;

    -- Le professionnel
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    assert (select count(*) from public.customers) = 1, 'le client connu a été recréé';
    select count(*) into n from public.requests where status = 'new';
    assert n = 2, 'nombre de demandes reçues incorrect : ' || n; -- la 3e a été annulée avec le refus de la 4e
    assert (select a.status from public.appointments a join public.requests r on r.appointment_id = a.id where r.id = req) = 'pending', 'créneau non bloqué « à confirmer »';
    perform public.resolve_request(req, true);
    assert (select a.status from public.appointments a join public.requests r on r.appointment_id = a.id where r.id = req) = 'confirmed', 'acceptation sans effet';
    begin
      perform public.resolve_request(req, false);
      raise exception 'demande traitée deux fois';
    exception when sqlstate 'P0002' then null;
    end;
    select r.id into req from public.requests r where r.status = 'new' limit 1;
    perform public.resolve_request(req, false);
    assert (select a.status from public.appointments a join public.requests r on r.appointment_id = a.id where r.id = req) = 'cancelled', 'refus sans effet';

    -- Confirmé directement depuis l'agenda : la demande liée passe en « acceptée »
    req := public.public_book(slug_a, svc, lundi + 7, '10:00', 'Paul', 'Nouveau', '0711111111', null, null, null);
    update public.appointments set status = 'confirmed' where id = (select appointment_id from public.requests where id = req);
    assert (select status from public.requests where id = req) = 'accepted', 'demande non mise à jour après confirmation depuis l''agenda';

    -- Absence : plus aucun créneau ce jour-là ; réservation désactivée : page fermée
    insert into public.time_off (organization_id, user_id, starts_on, ends_on) values (a, alice, lundi + 14, lundi + 14);
    assert (select count(*) from public.public_slots(slug_a, svc, lundi + 14, 1)) = 0, 'créneaux proposés pendant une absence';
    update public.organizations set booking_enabled = false where id = a;
    assert public.public_booking(slug_a) is null, 'page accessible alors que la réservation est désactivée';

    reset role;
    raise exception using errcode = 'FL000';
  exception when sqlstate 'FL000' then null;
  end;
end
$test$;

select 'OK : réservation vérifiée (aucune donnée de test conservée)' as resultat;
