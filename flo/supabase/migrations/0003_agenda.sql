-- FLO — Étape 04 (2/3) : horaires, absences, rendez-vous.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0001 et 0002).

create extension if not exists btree_gist with schema extensions; -- refus des chevauchements (uuid + période)

-- Permet aux rendez-vous de vérifier qu'un client / une prestation appartient à la même entreprise.
alter table public.customers add constraint customers_id_org_key unique (id, organization_id);
alter table public.services add constraint services_id_org_key unique (id, organization_id);

-- Horaires hebdomadaires (1 = lundi … 7 = dimanche).
create table public.availability_rules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  user_id uuid not null,
  weekday smallint not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null check (end_time > start_time),
  foreign key (organization_id, user_id) references public.memberships (organization_id, user_id) on delete cascade
);
create index on public.availability_rules (organization_id, user_id);

-- Absences / congés, en journées entières.
-- shortcut: pas d'absence d'une demi-journée ; passer en timestamptz si besoin.
create table public.time_off (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  user_id uuid not null,
  starts_on date not null,
  ends_on date not null check (ends_on >= starts_on),
  reason text check (length(reason) <= 200),
  created_at timestamptz not null default now(),
  foreign key (organization_id, user_id) references public.memberships (organization_id, user_id) on delete cascade
);
create index on public.time_off (organization_id, user_id);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  customer_id uuid,
  service_id uuid,
  staff_id uuid not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'confirmed' check (status in ('pending', 'confirmed', 'cancelled')),
  notes text check (length(notes) <= 2000),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  foreign key (customer_id, organization_id) references public.customers (id, organization_id),
  foreign key (service_id, organization_id) references public.services (id, organization_id),
  foreign key (organization_id, staff_id) references public.memberships (organization_id, user_id),
  -- Jamais deux rendez-vous actifs qui se chevauchent pour la même personne.
  constraint appointments_no_overlap exclude using gist (staff_id with =, tstzrange(starts_at, ends_at) with &&)
    where (status <> 'cancelled')
);
create index on public.appointments (organization_id, starts_at);
create index on public.appointments (customer_id);

-- Refuse un rendez-vous pendant une absence de la personne.
create function public.appointments_check_time_off()
returns trigger language plpgsql set search_path = '' as $$
declare tz text;
begin
  if new.status = 'cancelled' then return new; end if;
  select o.timezone into tz from public.organizations o where o.id = new.organization_id;
  if exists (
    select 1 from public.time_off t
    where t.organization_id = new.organization_id and t.user_id = new.staff_id
      and t.starts_on <= (new.ends_at at time zone tz)::date
      and t.ends_on >= (new.starts_at at time zone tz)::date
  ) then
    raise exception using errcode = 'FL001', message = 'la personne est absente à cette date';
  end if;
  return new;
end;
$$;
create trigger appointments_time_off before insert or update on public.appointments
  for each row execute function public.appointments_check_time_off();

-- Création / modification d'un rendez-vous à partir d'une date et d'une heure locales (fuseau de l'entreprise).
-- Sans durée, on prend celle de la prestation. Tourne avec les droits de l'utilisateur (RLS appliquée).
create function public.save_appointment(
  p_id uuid, p_customer uuid, p_service uuid, p_staff uuid,
  p_date date, p_time time, p_duration int, p_notes text
) returns uuid language plpgsql set search_path = '' as $$
declare org uuid; tz text; d int; s timestamptz; rid uuid;
begin
  -- shortcut: une seule entreprise par utilisateur (comme dans l'app).
  select m.organization_id into org from public.memberships m where m.user_id = auth.uid() limit 1;
  if org is null then raise exception using errcode = '42501', message = 'aucune entreprise'; end if;
  select o.timezone into tz from public.organizations o where o.id = org;
  d := coalesce(p_duration, (select sv.duration_minutes from public.services sv where sv.id = p_service));
  if d is null or d < 5 or d > 1440 then raise exception using errcode = '22023', message = 'durée invalide'; end if;
  s := (p_date + p_time) at time zone tz;
  if p_id is null then
    insert into public.appointments (organization_id, customer_id, service_id, staff_id, starts_at, ends_at, notes)
    values (org, p_customer, p_service, p_staff, s, s + make_interval(mins => d), p_notes)
    returning id into rid;
  else
    update public.appointments
       set customer_id = p_customer, service_id = p_service, staff_id = p_staff,
           starts_at = s, ends_at = s + make_interval(mins => d), notes = p_notes
     where id = p_id
    returning id into rid;
    if rid is null then raise exception using errcode = 'P0002', message = 'rendez-vous introuvable'; end if;
  end if;
  return rid;
end;
$$;

-- Lecture de l'agenda en heures locales, avec noms du client, de la prestation et de la personne.
create function public.agenda(p_from date default null, p_to date default null, p_customer uuid default null, p_id uuid default null)
returns table (
  id uuid, day date, start_time text, end_time text, duration_minutes int, status text,
  staff_id uuid, staff_name text, customer_id uuid, customer_name text, customer_phone text, customer_address text,
  service_id uuid, service_name text, notes text
) language sql stable set search_path = '' as $$
  select a.id,
         (a.starts_at at time zone o.timezone)::date,
         to_char(a.starts_at at time zone o.timezone, 'HH24:MI'),
         to_char(a.ends_at at time zone o.timezone, 'HH24:MI'),
         (extract(epoch from a.ends_at - a.starts_at) / 60)::int,
         a.status, a.staff_id, p.first_name,
         a.customer_id, nullif(concat_ws(' ', c.first_name, c.last_name), ''), c.phone, c.address,
         a.service_id, sv.name, a.notes
    from public.appointments a
    join public.organizations o on o.id = a.organization_id
    left join public.customers c on c.id = a.customer_id
    left join public.services sv on sv.id = a.service_id
    left join public.profiles p on p.id = a.staff_id
   where (p_from is null or a.starts_at >= (p_from::timestamp at time zone o.timezone))
     and (p_to is null or a.starts_at < ((p_to + 1)::timestamp at time zone o.timezone))
     and (p_customer is null or a.customer_id = p_customer)
     and (p_id is null or a.id = p_id)
   order by a.starts_at;
$$;

-- Remplace les horaires hebdomadaires d'une personne (en une seule opération).
-- p_rules : [{"weekday":1,"start_time":"08:00","end_time":"18:00"}, …]
create function public.set_weekly_hours(p_user uuid, p_rules jsonb)
returns void language plpgsql set search_path = '' as $$
declare org uuid;
begin
  select m.organization_id into org from public.memberships m where m.user_id = auth.uid() limit 1;
  delete from public.availability_rules where organization_id = org and user_id = p_user;
  insert into public.availability_rules (organization_id, user_id, weekday, start_time, end_time)
  select org, p_user, r.weekday, r.start_time, r.end_time
    from jsonb_to_recordset(p_rules) as r(weekday smallint, start_time time, end_time time);
end;
$$;

revoke execute on function public.save_appointment(uuid, uuid, uuid, uuid, date, time, int, text) from public, anon;
revoke execute on function public.agenda(date, date, uuid, uuid) from public, anon;
revoke execute on function public.set_weekly_hours(uuid, jsonb) from public, anon;
grant execute on function public.save_appointment(uuid, uuid, uuid, uuid, date, time, int, text) to authenticated;
grant execute on function public.agenda(date, date, uuid, uuid) to authenticated;
grant execute on function public.set_weekly_hours(uuid, jsonb) to authenticated;

alter table public.availability_rules enable row level security;
alter table public.time_off enable row level security;
alter table public.appointments enable row level security;

-- Horaires et absences : toute l'équipe les voit ; chacun gère les siens ; owner/admin gèrent ceux de tous.
create policy "équipe lit les horaires" on public.availability_rules
  for select to authenticated using (public.is_member(organization_id));
create policy "gérer ses horaires ou ceux de l'équipe (owner/admin)" on public.availability_rules
  for all to authenticated
  using ((user_id = auth.uid() and public.is_member(organization_id)) or public.has_role(organization_id, array['owner', 'admin']::public.member_role[]))
  with check ((user_id = auth.uid() and public.is_member(organization_id)) or public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));

create policy "équipe lit les absences" on public.time_off
  for select to authenticated using (public.is_member(organization_id));
create policy "gérer ses absences ou celles de l'équipe (owner/admin)" on public.time_off
  for all to authenticated
  using ((user_id = auth.uid() and public.is_member(organization_id)) or public.has_role(organization_id, array['owner', 'admin']::public.member_role[]))
  with check ((user_id = auth.uid() and public.is_member(organization_id)) or public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));

-- Rendez-vous : toute l'équipe les voit et les gère ; seuls owner/admin les suppriment (sinon : annuler).
-- shortcut: un collaborateur voit tous les rendez-vous de l'entreprise ; restreindre aux siens si demandé.
create policy "équipe lit les rendez-vous" on public.appointments
  for select to authenticated using (public.is_member(organization_id));
create policy "équipe crée des rendez-vous" on public.appointments
  for insert to authenticated with check (public.is_member(organization_id));
create policy "équipe modifie les rendez-vous" on public.appointments
  for update to authenticated using (public.is_member(organization_id)) with check (public.is_member(organization_id));
create policy "owner/admin suppriment les rendez-vous" on public.appointments
  for delete to authenticated using (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));
