-- Stub identique a celui de .github/workflows/ci.yml, plus de quoi simuler un
-- appelant : auth.uid() et auth.jwt() lisent une variable de session.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create role supabase_auth_admin nologin bypassrls;
create schema auth;
grant usage on schema auth to anon, authenticated;
create table auth.users (
  id uuid primary key,
  email text,
  email_confirmed_at timestamptz
);

create function auth.uid() returns uuid language sql stable as $auth_uid$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    nullif(current_setting('test.uid', true), '')
  )::uuid
$auth_uid$publication$;

create function auth.jwt() returns jsonb language sql stable as $auth_jwt$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true), ''),
    nullif(current_setting('test.jwt', true), ''),
    '{}'
  )::jsonb
$auth_jwt$publication$;

-- Storage minimal pour migrations et tests sur Postgres nu.
-- Ce stub ne remplace jamais le service Storage d'un projet Supabase.
create schema if not exists storage;
create table if not exists storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false
);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null references storage.buckets(id),
  name text not null,
  owner_id uuid
);
alter table storage.objects enable row level security;

create or replace function storage.foldername(name text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case
    when array_length(string_to_array(name, '/'), 1) > 1
      then (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
    else array[]::text[]
  end;
$$publication$;

-- C20 references this publication even on a plain PostgreSQL test instance.
DO $publication$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication
    WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END;
$publication$;
