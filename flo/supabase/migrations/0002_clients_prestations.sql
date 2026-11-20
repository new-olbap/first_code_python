-- FLO — Étape 04 (1/3) : clients/prospects et prestations.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0001).

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  kind text not null default 'client' check (kind in ('client', 'prospect')),
  first_name text check (length(first_name) <= 80),
  last_name text check (length(last_name) <= 80),
  email text check (length(email) <= 254),
  phone text check (length(phone) <= 30),
  address text check (length(address) <= 300),
  notes text check (length(notes) <= 5000),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  check (coalesce(trim(first_name), '') <> '' or coalesce(trim(last_name), '') <> '')
);
create index on public.customers (organization_id, archived_at);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 120),
  duration_minutes int not null check (duration_minutes between 5 and 1440),
  price_cents int check (price_cents between 0 and 100000000),
  archived_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.services (organization_id);

alter table public.customers enable row level security;
alter table public.services enable row level security;

-- Clients : toute l'équipe les consulte et les gère ; seuls owner/admin peuvent les supprimer définitivement.
-- shortcut: un collaborateur voit tous les clients de l'entreprise ; restreindre par attribution si un client le demande.
create policy "équipe lit les clients" on public.customers
  for select to authenticated using (public.is_member(organization_id));
create policy "équipe ajoute des clients" on public.customers
  for insert to authenticated with check (public.is_member(organization_id));
create policy "équipe modifie les clients" on public.customers
  for update to authenticated using (public.is_member(organization_id)) with check (public.is_member(organization_id));
create policy "owner/admin suppriment les clients" on public.customers
  for delete to authenticated using (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));

-- Prestations : toute l'équipe les voit ; owner/admin les gèrent.
create policy "équipe lit les prestations" on public.services
  for select to authenticated using (public.is_member(organization_id));
create policy "owner/admin gèrent les prestations" on public.services
  for all to authenticated
  using (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]))
  with check (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));
