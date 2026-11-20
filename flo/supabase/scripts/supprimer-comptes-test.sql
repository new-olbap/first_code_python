-- Supprime les comptes de test (test-flo-…) et leurs entreprises de test.
-- À coller dans Supabase > SQL Editor > Run. Ne touche à aucun autre compte.
delete from public.organizations
where id in (
  select m.organization_id from public.memberships m
  join auth.users u on u.id = m.user_id
  where u.email like 'test-flo-%' or u.email like '%@test.flo'
);

delete from auth.users where email like 'test-flo-%' or email like '%@test.flo';

select count(*) as comptes_test_restants from auth.users
where email like 'test-flo-%' or email like '%@test.flo';
