-- FLO — Relances : prestations à refaire régulièrement (entretien annuel…) et clients arrivés à échéance.
-- À coller dans Supabase > SQL Editor > Run (après 0001 à 0007 ; peut être relancée sans risque).

alter table public.services add column if not exists repeat_months int check (repeat_months between 1 and 60);

-- Clients dont une prestation périodique arrive à échéance dans les 30 jours (ou est dépassée) :
-- dernier passage confirmé + périodicité, sans rendez-vous déjà prévu pour cette prestation.
-- Tourne avec les droits de l'utilisateur (RLS) : seulement son entreprise.
create or replace function public.due_maintenance()
returns table (customer_id uuid, service_id uuid, last_day date, due_on date)
language sql stable set search_path = '' as $$
  with last as (
    select a.customer_id, a.service_id, s.repeat_months, o.timezone as tz, max(a.starts_at) as last_at
      from public.appointments a
      join public.services s on s.id = a.service_id and s.repeat_months is not null and s.archived_at is null
      join public.customers c on c.id = a.customer_id and c.archived_at is null
      join public.organizations o on o.id = a.organization_id
     where a.status = 'confirmed' and a.starts_at < now()
     group by a.customer_id, a.service_id, s.repeat_months, o.timezone
  )
  select l.customer_id, l.service_id, (l.last_at at time zone l.tz)::date,
         ((l.last_at at time zone l.tz) + make_interval(months => l.repeat_months))::date
    from last l
   where l.last_at + make_interval(months => l.repeat_months) <= now() + interval '30 days'
     and not exists (select 1 from public.appointments f
                      where f.customer_id = l.customer_id and f.service_id = l.service_id
                        and f.status <> 'cancelled' and f.starts_at >= now())
   order by 4;
$$;
revoke execute on function public.due_maintenance() from public, anon;
grant execute on function public.due_maintenance() to authenticated;
