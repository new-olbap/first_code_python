-- Imite le strict minimum de Supabase (rôles, auth.users, auth.uid, droits par défaut)
-- pour lancer la migration et isolation.sql sur un PostgreSQL local. Inutile sur Supabase.
do $$ begin create role anon nologin; create role authenticated nologin;
exception when duplicate_object then null; end $$;
create schema auth;
create schema if not exists extensions;
grant usage on schema auth, public to anon, authenticated;
create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as $$
  select (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid
$$;
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant all on functions to anon, authenticated;
