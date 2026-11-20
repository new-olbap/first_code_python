-- FLO — Demandes reçues par e-mail : quand le client choisit un créneau avec le lien envoyé en réponse,
-- le créneau se rattache à sa demande ouverte au lieu de créer une deuxième demande.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0001 à 0006).

create or replace function public.public_book(
  p_slug text, p_service uuid, p_date date, p_time text,
  p_first text, p_last text, p_phone text, p_email text, p_address text, p_message text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare org uuid; tz text; dur int; s timestamptz; cust uuid; appt uuid; req uuid; staff uuid; em text; ph text;
begin
  select o.id, o.timezone into org, tz from public.organizations o where o.slug = p_slug and o.booking_enabled;
  if org is null then raise exception using errcode = 'P0002', message = 'page de réservation introuvable'; end if;

  em := nullif(lower(trim(coalesce(p_email, ''))), '');
  ph := nullif(trim(coalesce(p_phone, '')), '');
  if coalesce(trim(p_last), '') = '' or length(p_last) > 80 or length(coalesce(p_first, '')) > 80 then
    raise exception using errcode = '22023', message = 'nom'; end if;
  if ph is null or ph !~ '^[0-9+(). -]{6,30}$' then raise exception using errcode = '22023', message = 'téléphone'; end if;
  if em is not null and (length(em) > 254 or em !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then
    raise exception using errcode = '22023', message = 'e-mail'; end if;
  if length(coalesce(p_address, '')) > 300 or length(coalesce(p_message, '')) > 2000 then
    raise exception using errcode = '22023', message = 'texte trop long'; end if;

  -- Anti-abus : 30 réservations en ligne par heure et par entreprise au maximum.
  if (select count(*) from public.requests r where r.organization_id = org and r.source = 'booking' and r.created_at > now() - interval '1 hour') >= 30 then
    raise exception using errcode = 'FL002', message = 'trop de demandes'; end if;
  -- Le créneau doit faire partie de ceux proposés (horaires, absences, délai, chevauchements).
  if not exists (select 1 from public.public_slots(p_slug, p_service, p_date, 1) x where x.slot_day = p_date and x.slot_time = p_time) then
    raise exception using errcode = 'FL003', message = 'créneau indisponible'; end if;

  select sv.duration_minutes into dur from public.services sv where sv.id = p_service and sv.organization_id = org;
  s := (p_date + p_time::time) at time zone tz;

  -- Client déjà connu (même e-mail ou même téléphone) : on le réutilise sans modifier sa fiche.
  select c.id into cust from public.customers c
   where c.organization_id = org and ((em is not null and lower(c.email) = em) or public.phone_key(c.phone) = public.phone_key(ph))
   order by c.created_at limit 1;
  if cust is null then
    insert into public.customers (organization_id, kind, first_name, last_name, phone, email, address)
    values (org, 'prospect', nullif(trim(p_first), ''), trim(p_last), ph, em, nullif(trim(p_address), ''))
    returning id into cust;
  elsif (select count(*) from public.requests r join public.appointments a on a.id = r.appointment_id
          where r.customer_id = cust and r.status = 'new' and a.starts_at > now()) >= 3 then
    raise exception using errcode = 'FL002', message = 'trop de demandes en attente pour ce contact';
  end if;

  -- Première personne de l'équipe libre sur ce créneau.
  for staff in
    select r.user_id from public.availability_rules r
     where r.organization_id = org and r.weekday = extract(isodow from p_date)
       and r.start_time <= p_time::time and p_time::time + make_interval(mins => dur) <= r.end_time
     order by r.user_id
  loop
    begin
      insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at, status, notes)
      values (org, cust, p_service, staff, s, s + make_interval(mins => dur), 'pending', nullif(trim(p_message), ''))
      returning id into appt;
      exit;
    exception when exclusion_violation or sqlstate 'FL001' then null; -- déjà prise ou absente : personne suivante
    end;
  end loop;
  if appt is null then raise exception using errcode = 'FL003', message = 'créneau indisponible'; end if;

  -- Demande déjà ouverte sans créneau (e-mail, saisie) : elle reçoit le créneau choisi.
  update public.requests r
     set appointment_id = appt, message = left(concat_ws(E'\n\n', r.message, nullif(trim(p_message), '')), 5000)
   where r.id = (select x.id from public.requests x
                  where x.organization_id = org and x.customer_id = cust and x.status = 'new' and x.appointment_id is null
                  order by x.created_at desc limit 1)
  returning r.id into req;
  if req is null then
    insert into public.requests (organization_id, customer_id, appointment_id, source, message)
    values (org, cust, appt, 'booking', nullif(trim(p_message), ''))
    returning id into req;
  end if;
  return req;
end;
$$;
