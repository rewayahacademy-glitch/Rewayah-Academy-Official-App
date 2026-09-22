-- Minimal Storage catalog for the plain PostgreSQL migration replay in CI.
-- This is a test harness, not a replacement for Supabase Storage at runtime.
create schema storage;

create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false
);

create table storage.objects (
  id uuid primary key,
  bucket_id text not null references storage.buckets(id),
  name text not null
);

alter table storage.buckets enable row level security;
alter table storage.objects enable row level security;

create function storage.foldername(p_name text)
returns text[] language sql immutable set search_path = '' as $$
  select case
    when p_name like '%/%'
      then pg_catalog.string_to_array(
        pg_catalog.regexp_replace(p_name, '/[^/]*$', ''), '/'
      )
    else array[]::text[]
  end
$$;
