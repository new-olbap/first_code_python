-- Test de la synchronisation d'agenda (0009). Tout est annulé à la fin.
-- Local : psql -d <base> -f local_stub.sql -f migrations/0001…0009 -f tests/calendrier.sql
begin;
-- Données : une entreprise avec deux personnes, une autre entreprise.
insert into auth.users (id, email) values
 ('11111111-1111-1111-1111-111111111111','a@x.fr'),('22222222-2222-2222-2222-222222222222','b@x.fr'),('33333333-3333-3333-3333-333333333333','c@x.fr');
do $$
declare o uuid; o2 uuid; c uuid; s uuid;
begin
  insert into public.organizations (id, name) values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Plomberie Martin'),('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','Autre') on conflict do nothing;
  insert into public.profiles (id, first_name) values ('11111111-1111-1111-1111-111111111111','Paul'),('22222222-2222-2222-2222-222222222222','Léa'),('33333333-3333-3333-3333-333333333333','Zoé') on conflict (id) do update set first_name = excluded.first_name;
  delete from public.memberships where user_id in ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222','33333333-3333-3333-3333-333333333333');
  insert into public.memberships values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','owner'),('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','22222222-2222-2222-2222-222222222222','member'),('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','33333333-3333-3333-3333-333333333333','owner');
  insert into public.customers (id, organization_id, first_name, last_name, phone, address) values ('cccccccc-cccc-cccc-cccc-cccccccccccc','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Claire','Dupont','0612345678','12 rue X');
  insert into public.services (id, organization_id, name, duration_minutes) values ('dddddddd-dddd-dddd-dddd-dddddddddddd','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Chauffe-eau',60);
  insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at, status) values
   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','cccccccc-cccc-cccc-cccc-cccccccccccc','dddddddd-dddd-dddd-dddd-dddddddddddd','11111111-1111-1111-1111-111111111111', now()+interval '1 day', now()+interval '1 day 1 hour','confirmed'),
   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',null,null,'11111111-1111-1111-1111-111111111111', now()+interval '2 day', now()+interval '2 day 1 hour','cancelled'),
   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',null,null,'11111111-1111-1111-1111-111111111111', now()-interval '200 day', now()-interval '200 day'+interval '1 hour','confirmed'),
   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',null,null,'22222222-2222-2222-2222-222222222222', now()+interval '3 day', now()+interval '3 day 1 hour','pending');
end $$;

-- Tests, avec les droits réels.
do $$
declare t1 uuid; t1b uuid; t2 uuid; t3 uuid; f json; ok boolean;
begin
  perform set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);
  set local role authenticated;
  t1 := public.my_calendar_token();
  t1b := public.my_calendar_token();
  if t1 is distinct from t1b then raise exception 'le jeton doit rester le même'; end if;
  -- lecture directe de la table interdite (RLS sans politique)
  if exists (select 1 from public.calendar_feeds) then raise exception 'la table ne doit pas être lisible'; end if;
  reset role;

  perform set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222"}', true);
  set local role authenticated; t2 := public.my_calendar_token(); reset role;
  perform set_config('request.jwt.claims', '{"sub":"33333333-3333-3333-3333-333333333333"}', true);
  set local role authenticated; t3 := public.my_calendar_token(); reset role;

  -- flux en anonyme
  perform set_config('request.jwt.claims', '', true);
  set local role anon;
  f := public.calendar_feed(t1);
  if json_array_length(f->'events') <> 1 then raise exception 'Paul : 1 rdv attendu (sans annulé ni trop ancien), obtenu %', f->'events'; end if;
  if f->'events'->0->>'customer' <> 'Claire Dupont' or f->>'name' <> 'Plomberie Martin' or f->>'staff' <> 'Paul' then raise exception 'contenu inattendu %', f; end if;
  f := public.calendar_feed(t2);
  if json_array_length(f->'events') <> 1 or f->'events'->0->>'status' <> 'pending' then raise exception 'Léa : 1 rdv en attente attendu'; end if;
  f := public.calendar_feed(t3);
  if json_array_length(f->'events') <> 0 then raise exception 'Zoé ne doit rien voir de l''autre entreprise'; end if;
  if public.calendar_feed(gen_random_uuid()) is not null then raise exception 'jeton inconnu : rien attendu'; end if;
  begin
    perform public.my_calendar_token();
    raise exception 'anon ne doit pas pouvoir créer de jeton';
  exception when insufficient_privilege then null; end;
  reset role;

  -- nouveau lien : l'ancien ne marche plus
  perform set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111"}', true);
  set local role authenticated; t1b := public.my_calendar_token(true); reset role;
  if t1b = t1 then raise exception 'le jeton doit changer'; end if;
  set local role anon;
  if public.calendar_feed(t1) is not null then raise exception 'l''ancien lien doit être mort'; end if;
  if public.calendar_feed(t1b) is null then raise exception 'le nouveau lien doit marcher'; end if;
  reset role;

  raise notice 'OK : synchronisation d''agenda vérifiée';
end $$;
rollback;
