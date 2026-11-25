-- FLO — Synchronisation avec Google Agenda, Apple Calendrier et Outlook (abonnement iCal).
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0008).
-- Chaque personne a un lien secret (jeton) : l'agenda du téléphone le relit régulièrement
-- et affiche ses rendez-vous FLO. Lecture seule : rien n'est modifié depuis le téléphone.

create table public.calendar_feeds (
  organization_id uuid not null,
  user_id uuid not null,
  token uuid not null unique default gen_random_uuid(),
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id),
  foreign key (organization_id, user_id) references public.memberships (organization_id, user_id) on delete cascade
);
-- Aucune politique : personne ne lit la table directement, tout passe par les fonctions ci-dessous
-- (un collègue ne peut pas voir le jeton d'un autre).
alter table public.calendar_feeds enable row level security;

-- Jeton de la personne connectée (créé au premier appel). Avec p_reset, un nouveau jeton remplace l'ancien :
-- l'ancien lien cesse de fonctionner (à utiliser si le lien a été partagé par erreur).
create function public.my_calendar_token(p_reset boolean default false)
returns uuid language plpgsql security definer set search_path = '' as $$
declare org uuid; tok uuid;
begin
  if auth.uid() is null then raise exception using errcode = '42501', message = 'non connecté'; end if;
  -- shortcut: une seule entreprise par utilisateur (comme dans l'app).
  select m.organization_id into org from public.memberships m where m.user_id = auth.uid() limit 1;
  if org is null then raise exception using errcode = '42501', message = 'aucune entreprise'; end if;
  insert into public.calendar_feeds as f (organization_id, user_id) values (org, auth.uid())
  on conflict (organization_id, user_id) do update set token = case when p_reset then gen_random_uuid() else f.token end
  returning f.token into tok;
  return tok;
end;
$$;

-- Rendez-vous d'une personne pour le flux iCal : 60 jours en arrière, 1 an en avant, sans les annulés.
-- Appelée sans compte (par Google / Apple), d'où SECURITY DEFINER : le jeton secret sert de clé.
create function public.calendar_feed(p_token uuid)
returns json language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'name', o.name,
    'staff', coalesce(p.first_name, ''),
    'events', coalesce((
      select json_agg(json_build_object(
        'id', a.id, 'starts_at', a.starts_at, 'ends_at', a.ends_at, 'status', a.status, 'notes', a.notes,
        'service', s.name,
        'customer', nullif(trim(concat_ws(' ', c.first_name, c.last_name)), ''),
        'phone', c.phone, 'address', c.address
      ) order by a.starts_at)
      from public.appointments a
      left join public.services s on s.id = a.service_id
      left join public.customers c on c.id = a.customer_id
      where a.organization_id = f.organization_id and a.staff_id = f.user_id
        and a.status <> 'cancelled'
        and a.starts_at >= now() - interval '60 days' and a.starts_at < now() + interval '366 days'
    ), '[]'::json)
  )
  from public.calendar_feeds f
  join public.organizations o on o.id = f.organization_id
  left join public.profiles p on p.id = f.user_id
  where f.token = p_token;
$$;

revoke execute on function public.my_calendar_token(boolean) from public, anon;
revoke execute on function public.calendar_feed(uuid) from public;
grant execute on function public.my_calendar_token(boolean) to authenticated;
grant execute on function public.calendar_feed(uuid) to anon, authenticated;
