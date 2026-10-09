-- Surface minimale de Supabase Storage pour appliquer les migrations sur Postgres nu.
-- Elle ne simule ni API Storage, ni RLS du service : les scenarios d'integration
-- doivent utiliser un projet Supabase dedie.
create schema storage;

create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false
);

create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null references storage.buckets(id),
  name text not null,
  owner_id uuid,
  metadata jsonb
);

create function storage.foldername(name text)
returns text[]
language sql
immutable
as $folder$
  select (regexp_split_to_array(trim(both '/' from name), '/'))[1:array_length(regexp_split_to_array(trim(both '/' from name), '/'), 1) - 1]
$folder$;

create function storage.extension(name text)
returns text
language sql
immutable
as $extension$
  select nullif(split_part(name, '.', array_length(string_to_array(name, '.'), 1)), name)
$extension$;
