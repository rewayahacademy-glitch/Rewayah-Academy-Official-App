-- Uniquement sur PostgreSQL de test nu. Ne jamais appliquer en Supabase.
-- Complement du stub auth pour les migrations Teaching Core >= 0030.
create schema storage;
create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text not null,
  unique (bucket_id, name)
);
alter table storage.buckets enable row level security;
alter table storage.objects enable row level security;
grant usage on schema storage to authenticated, service_role;
grant all on storage.objects to authenticated, service_role;
create function storage.foldername(name text) returns text[]
language sql immutable set search_path = '' as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1)-1];
$$;
