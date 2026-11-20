-- FLO — Équipe : invitations par lien, et toujours au moins un propriétaire.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0001 à 0004).

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  role public.member_role not null default 'member' check (role <> 'owner'),
  -- 2 × 122 bits aléatoires : impossible à deviner.
  token text not null unique default replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', ''),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  used_at timestamptz,
  used_by uuid references auth.users (id) on delete set null
);
create index on public.invitations (organization_id);

alter table public.invitations enable row level security;
create policy "owner/admin gèrent les invitations" on public.invitations
  for all to authenticated
  using (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]))
  with check (public.has_role(organization_id, array['owner', 'admin']::public.member_role[]));

-- Ce que montre la page d'invitation (visiteur non connecté compris) : nom de l'entreprise et rôle proposé.
create function public.invitation_info(p_token text) returns json
language sql stable security definer set search_path = '' as $$
  select json_build_object('organization', o.name, 'role', i.role)
    from public.invitations i join public.organizations o on o.id = i.organization_id
   where i.token = p_token and i.used_at is null and i.expires_at > now();
$$;

-- Rejoindre l'entreprise avec une invitation valide (une seule utilisation).
create function public.accept_invitation(p_token text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare inv public.invitations;
begin
  if auth.uid() is null then raise exception using errcode = '42501', message = 'non connecté'; end if;
  select * into inv from public.invitations
   where token = p_token and used_at is null and expires_at > now() for update;
  if not found then raise exception using errcode = 'P0002', message = 'invitation invalide, expirée ou déjà utilisée'; end if;
  -- shortcut: une seule entreprise par compte (comme dans l'app).
  if exists (select 1 from public.memberships m where m.user_id = auth.uid()) then
    raise exception using errcode = 'FL004', message = 'ce compte appartient déjà à une entreprise';
  end if;
  insert into public.memberships (organization_id, user_id, role) values (inv.organization_id, auth.uid(), inv.role);
  update public.invitations set used_at = now(), used_by = auth.uid() where id = inv.id;
  return inv.organization_id;
end;
$$;

revoke execute on function public.invitation_info(text) from public;
revoke execute on function public.accept_invitation(text) from public, anon;
grant execute on function public.invitation_info(text) to anon, authenticated;
grant execute on function public.accept_invitation(text) to authenticated;

-- Une entreprise garde toujours au moins un propriétaire (sauf si l'entreprise elle-même est supprimée).
create function public.memberships_keep_owner() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if old.role = 'owner'
     and exists (select 1 from public.organizations o where o.id = old.organization_id)
     and not exists (select 1 from public.memberships m where m.organization_id = old.organization_id and m.role = 'owner') then
    raise exception using errcode = 'FL005', message = 'l''entreprise doit garder au moins un propriétaire';
  end if;
  return null;
end;
$$;
create trigger memberships_keep_owner after delete or update of role on public.memberships
  for each row execute function public.memberships_keep_owner();
