-- FLO — RGPD : suppression d'un client à sa demande, suppression de son propre compte.
-- À coller dans Supabase > SQL Editor > Run (une seule fois, après 0001 à 0005).

-- Supprime définitivement un client (owner/admin) : ses demandes sont supprimées, ses rendez-vous
-- restent dans l'agenda mais anonymisés (plus de client, plus de notes). Droits de l'utilisateur appliqués (RLS).
create function public.delete_customer(p_id uuid) returns void
language plpgsql set search_path = '' as $$
declare org uuid;
begin
  select c.organization_id into org from public.customers c where c.id = p_id;
  if org is null or not public.has_role(org, array['owner', 'admin']::public.member_role[]) then
    raise exception using errcode = '42501', message = 'seuls le propriétaire et les administrateurs suppriment un client';
  end if;
  delete from public.requests where customer_id = p_id;
  update public.appointments set customer_id = null, notes = null where customer_id = p_id;
  delete from public.customers where id = p_id;
end;
$$;
revoke execute on function public.delete_customer(uuid) from public, anon;
grant execute on function public.delete_customer(uuid) to authenticated;

-- Supprime le compte de la personne connectée.
-- Seule dans son entreprise : l'entreprise et toutes ses données sont supprimées avec le compte.
-- Seule propriétaire d'une équipe : elle doit d'abord nommer un autre propriétaire.
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); m public.memberships;
begin
  if me is null then raise exception using errcode = '42501', message = 'non connecté'; end if;
  select * into m from public.memberships where user_id = me limit 1;
  if found then
    if not exists (select 1 from public.memberships x where x.organization_id = m.organization_id and x.user_id <> me) then
      delete from public.organizations where id = m.organization_id; -- seule : tout part avec le compte
    elsif m.role = 'owner' and not exists (select 1 from public.memberships x where x.organization_id = m.organization_id and x.user_id <> me and x.role = 'owner') then
      raise exception using errcode = 'FL006', message = 'nommez un autre propriétaire avant de supprimer votre compte';
    elsif exists (select 1 from public.appointments a where a.staff_id = me and a.organization_id = m.organization_id) then
      raise exception using errcode = 'FL007', message = 'réattribuez vos rendez-vous avant de supprimer votre compte';
    end if;
  end if;
  delete from auth.users where id = me; -- profil et appartenance supprimés en cascade
end;
$$;
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
