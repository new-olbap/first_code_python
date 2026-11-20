-- FLO — Étape 04 (3/3) : page de réservation publique et demandes.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0001 à 0003).

-- Adresse publique de réservation : /r/<slug>
create function public.slugify(t text) returns text language sql immutable set search_path = '' as $$
  select trim(both '-' from regexp_replace(
    translate(lower(t), 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ', 'aaaaaaceeeeiiiinooooouuuuyy'), '[^a-z0-9]+', '-', 'g'))
$$;

alter table public.organizations
  add column slug text unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$'),
  add column booking_enabled boolean not null default true;

create function public.organizations_set_slug() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.slug is null then
    new.slug := left(coalesce(nullif(public.slugify(new.name), ''), 'flo'), 50) || '-' || substr(md5(new.id::text), 1, 4);
  end if;
  return new;
end;
$$;
create trigger organizations_slug before insert on public.organizations
  for each row execute function public.organizations_set_slug();
update public.organizations
   set slug = left(coalesce(nullif(public.slugify(name), ''), 'flo'), 50) || '-' || substr(md5(id::text), 1, 4)
 where slug is null;

-- Téléphone comparable : chiffres seuls, +33 → 0.
create function public.phone_key(p text) returns text language sql immutable set search_path = '' as $$
  select nullif(regexp_replace(regexp_replace(coalesce(p, ''), '\D', '', 'g'), '^33', '0'), '')
$$;

-- Demandes reçues (réservation en ligne ; plus tard : e-mails transférés).
create table public.requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  customer_id uuid,
  appointment_id uuid references public.appointments (id) on delete set null,
  source text not null check (source in ('booking', 'email', 'manual')),
  status text not null default 'new' check (status in ('new', 'accepted', 'refused')),
  message text check (length(message) <= 5000),
  created_at timestamptz not null default now(),
  foreign key (customer_id, organization_id) references public.customers (id, organization_id)
);
create index on public.requests (organization_id, status, created_at desc);

alter table public.requests enable row level security;
create policy "équipe lit les demandes" on public.requests
  for select to authenticated using (public.is_member(organization_id));
create policy "équipe crée des demandes" on public.requests
  for insert to authenticated with check (public.is_member(organization_id));
create policy "équipe traite les demandes" on public.requests
  for update to authenticated using (public.is_member(organization_id)) with check (public.is_member(organization_id));
create policy "owner/admin suppriment les demandes" on public.requests
  for delete to authenticated using (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));

-- ===== Fonctions publiques (visiteurs non connectés) =====
-- SECURITY DEFINER : elles lisent les données nécessaires, mais ne renvoient que le strict minimum.

-- Nom de l'entreprise et prestations proposées.
create function public.public_booking(p_slug text) returns json
language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'name', o.name, 'trade', o.trade, 'timezone', o.timezone,
    'services', coalesce((
      select json_agg(json_build_object('id', s.id, 'name', s.name, 'duration_minutes', s.duration_minutes, 'price_cents', s.price_cents) order by s.name)
        from public.services s where s.organization_id = o.id and s.archived_at is null), '[]'::json))
    from public.organizations o
   where o.slug = p_slug and o.booking_enabled;
$$;

-- Créneaux libres : dans les horaires d'au moins une personne, hors absence, sans chevauchement,
-- au moins 2 h à l'avance et au plus 60 jours. Pas de 30 minutes.
create function public.public_slots(p_slug text, p_service uuid, p_from date, p_days int)
returns table (slot_day date, slot_time text)
language plpgsql stable security definer set search_path = '' as $$
declare org uuid; tz text; dur int;
begin
  select o.id, o.timezone into org, tz from public.organizations o where o.slug = p_slug and o.booking_enabled;
  if org is null then return; end if;
  select s.duration_minutes into dur from public.services s where s.id = p_service and s.organization_id = org and s.archived_at is null;
  if dur is null then return; end if;
  return query
  with days as (
    select (p_from + g)::date as d from generate_series(0, least(greatest(p_days, 1), 31) - 1) g
     where p_from + g <= (now() at time zone tz)::date + 60
  ), cand as (
    select r.user_id, dd.d, ts as local_start
      from days dd
      join public.availability_rules r on r.organization_id = org and r.weekday = extract(isodow from dd.d)
     cross join lateral generate_series(dd.d + r.start_time, dd.d + r.end_time - make_interval(mins => dur), interval '30 minutes') ts
  )
  select distinct c.d, to_char(c.local_start, 'HH24:MI')
    from cand c
   where (c.local_start at time zone tz) > now() + interval '2 hours'
     and not exists (select 1 from public.time_off t
                      where t.organization_id = org and t.user_id = c.user_id and c.d between t.starts_on and t.ends_on)
     and not exists (select 1 from public.appointments a
                      where a.staff_id = c.user_id and a.status <> 'cancelled'
                        and tstzrange(a.starts_at, a.ends_at) && tstzrange(c.local_start at time zone tz, (c.local_start + make_interval(mins => dur)) at time zone tz))
   order by 1, 2;
end;
$$;

-- Réservation : vérifie tout, crée (ou retrouve) le client, bloque le créneau « à confirmer » et crée la demande.
create function public.public_book(
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

  insert into public.requests (organization_id, customer_id, appointment_id, source, message)
  values (org, cust, appt, 'booking', nullif(trim(p_message), ''))
  returning id into req;
  return req;
end;
$$;

-- Rendez-vous « à confirmer » confirmé ou annulé depuis l'agenda : la demande liée suit.
create function public.appointments_sync_request() returns trigger language plpgsql set search_path = '' as $$
begin
  if old.status = 'pending' and new.status <> 'pending' then
    update public.requests set status = case when new.status = 'confirmed' then 'accepted' else 'refused' end
     where appointment_id = new.id and status = 'new';
  end if;
  return new;
end;
$$;
create trigger appointments_sync_request after update of status on public.appointments
  for each row execute function public.appointments_sync_request();

-- Accepter (rendez-vous confirmé) ou refuser (rendez-vous annulé) une demande, en une seule opération.
create function public.resolve_request(p_id uuid, p_accept boolean) returns void
language plpgsql set search_path = '' as $$
declare appt uuid;
begin
  update public.requests set status = case when p_accept then 'accepted' else 'refused' end
   where id = p_id and status = 'new'
  returning appointment_id into appt;
  if not found then raise exception using errcode = 'P0002', message = 'demande introuvable ou déjà traitée'; end if;
  if appt is not null then
    update public.appointments set status = case when p_accept then 'confirmed' else 'cancelled' end where id = appt;
  end if;
end;
$$;

revoke execute on function public.public_booking(text) from public;
revoke execute on function public.public_slots(text, uuid, date, int) from public;
revoke execute on function public.public_book(text, uuid, date, text, text, text, text, text, text, text) from public;
revoke execute on function public.resolve_request(uuid, boolean) from public, anon;
grant execute on function public.public_booking(text) to anon, authenticated;
grant execute on function public.public_slots(text, uuid, date, int) to anon, authenticated;
grant execute on function public.public_book(text, uuid, date, text, text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.resolve_request(uuid, boolean) to authenticated;
