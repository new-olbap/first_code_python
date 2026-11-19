-- FLO — Étape 03 : comptes, entreprises, rôles.
-- À coller dans Supabase > SQL Editor > Run.

create type public.member_role as enum ('owner', 'admin', 'member');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 120),
  trade text check (length(trade) <= 80),
  address text check (length(address) <= 300),
  timezone text not null default 'Europe/Paris',
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text check (length(first_name) <= 80),
  created_at timestamptz not null default now()
);

create table public.memberships (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.member_role not null default 'member',
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);
create index on public.memberships (user_id);

-- Helpers en SECURITY DEFINER pour éviter la récursion des politiques sur memberships.
create function public.has_role(org uuid, roles public.member_role[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.memberships m
    where m.organization_id = org and m.user_id = auth.uid() and m.role = any (roles)
  );
$$;

create function public.is_member(org uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.has_role(org, array['owner', 'admin', 'member']::public.member_role[]);
$$;

-- Profil créé automatiquement à l'inscription (prénom pris dans les métadonnées).
create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, first_name)
  values (new.id, left(new.raw_user_meta_data ->> 'first_name', 80));
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Création d'une entreprise + rattachement du créateur comme propriétaire, en une transaction.
create function public.create_organization(p_name text, p_trade text, p_address text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare org_id uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into public.organizations (name, trade, address)
  values (trim(p_name), nullif(trim(p_trade), ''), nullif(trim(p_address), ''))
  returning id into org_id;
  insert into public.memberships (organization_id, user_id, role) values (org_id, auth.uid(), 'owner');
  return org_id;
end;
$$;
revoke execute on function public.create_organization(text, text, text) from public, anon;
grant execute on function public.create_organization(text, text, text) to authenticated;

-- Isolation des entreprises (RLS). Sans politique = refusé.
alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.memberships enable row level security;

create policy "membres lisent leur entreprise" on public.organizations
  for select to authenticated using (public.is_member(id));
create policy "owner/admin modifient l'entreprise" on public.organizations
  for update to authenticated
  using (public.has_role(id, array['owner', 'admin']::public.member_role[]))
  with check (public.has_role(id, array['owner', 'admin']::public.member_role[]));

create policy "lire son profil et ceux de ses collègues" on public.profiles
  for select to authenticated using (
    id = auth.uid() or exists (
      select 1 from public.memberships m where m.user_id = profiles.id and public.is_member(m.organization_id)
    )
  );
create policy "modifier son profil" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "membres voient l'équipe" on public.memberships
  for select to authenticated using (public.is_member(organization_id));
-- Le propriétaire gère tout ; l'admin gère l'équipe sans toucher aux propriétaires.
create policy "owner gère l'équipe" on public.memberships
  for all to authenticated
  using (public.has_role(organization_id, array['owner']::public.member_role[]))
  with check (public.has_role(organization_id, array['owner']::public.member_role[]));
create policy "admin gère les non-propriétaires" on public.memberships
  for all to authenticated
  using (role <> 'owner' and public.has_role(organization_id, array['admin']::public.member_role[]))
  with check (role <> 'owner' and public.has_role(organization_id, array['admin']::public.member_role[]));
-- shortcut: un propriétaire peut encore se retirer lui-même et laisser l'entreprise sans propriétaire ; à bloquer quand la page Équipe existera.
