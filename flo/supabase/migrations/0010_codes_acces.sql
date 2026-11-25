-- FLO — Inscription fermée : créer une entreprise demande un code d'accès à usage unique,
-- remis par l'éditeur après le paiement. Les invitations d'équipe restent sans code.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0009).
--
-- Pour un nouveau client, dans Supabase > SQL Editor :
--   select public.nouveau_code('Plomberie Martin');      -- affiche un code du type FLO-7K2M-Q9XD
-- Pour voir les codes et à quelle entreprise ils ont servi :
--   select * from public.codes_acces order by created_at desc;

create table public.flo_reglages (
  id boolean primary key default true check (id),
  code_obligatoire boolean not null default true
);
insert into public.flo_reglages default values;

create table public.codes_acces (
  code text primary key,
  note text check (length(note) <= 200),
  created_at timestamptz not null default now(),
  used_at timestamptz,
  used_by uuid references auth.users (id) on delete set null,
  organization_id uuid references public.organizations (id) on delete set null
);
-- Aucune politique : personne ne lit ni n'écrit ces tables depuis l'application (seulement par l'éditeur SQL).
alter table public.flo_reglages enable row level security;
alter table public.codes_acces enable row level security;

-- Code lisible au téléphone : sans 0/O ni 1/I.
create function public.nouveau_code(p_note text default null) returns text
language plpgsql set search_path = '' as $$
declare a text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; c text;
begin
  loop
    c := 'FLO-' || (select string_agg(substr(a, 1 + floor(random() * 32)::int, 1), '') from generate_series(1, 4))
         || '-' || (select string_agg(substr(a, 1 + floor(random() * 32)::int, 1), '') from generate_series(1, 4));
    begin
      insert into public.codes_acces (code, note) values (c, p_note);
      return c;
    exception when unique_violation then null; -- très rare : on retire un code
    end;
  end loop;
end;
$$;
revoke execute on function public.nouveau_code(text) from public, anon, authenticated;

-- Création d'une entreprise : le code est consommé dans la même transaction.
drop function public.create_organization(text, text, text);
create function public.create_organization(p_name text, p_trade text, p_address text, p_code text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare org_id uuid; c text := upper(trim(coalesce(p_code, '')));
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if (select code_obligatoire from public.flo_reglages) then
    perform 1 from public.codes_acces where code = c and used_at is null for update;
    if not found then raise exception using errcode = 'FL010', message = 'code d''accès invalide ou déjà utilisé'; end if;
  end if;
  insert into public.organizations (name, trade, address)
  values (trim(p_name), nullif(trim(p_trade), ''), nullif(trim(p_address), ''))
  returning id into org_id;
  insert into public.memberships (organization_id, user_id, role) values (org_id, auth.uid(), 'owner');
  update public.codes_acces set used_at = now(), used_by = auth.uid(), organization_id = org_id where code = c;
  return org_id;
end;
$$;
revoke execute on function public.create_organization(text, text, text, text) from public, anon;
grant execute on function public.create_organization(text, text, text, text) to authenticated;
