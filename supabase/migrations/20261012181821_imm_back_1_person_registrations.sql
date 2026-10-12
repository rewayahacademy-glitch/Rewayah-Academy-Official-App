-- IMM-BACK-1 A: permanent RA matricule registry and collision-safe allocator.
begin;

create schema if not exists private;

create table private.person_registrations (
  profile_id uuid primary key,
  matricule text not null unique
    check (matricule ~ '^RA-[0-9]{2}-[0-9]{4,5}$'),
  registration_year smallint not null,
  issued_at timestamptz not null,
  constraint person_registrations_year_valid check (
    registration_year between 2000 and 2199
  )
);
create index person_registrations_year_idx
  on private.person_registrations (registration_year);
alter table private.person_registrations enable row level security;
revoke all on private.person_registrations from public, anon, authenticated, service_role;

comment on table private.person_registrations is
  'Permanent server-issued RA matricules. Rows survive profile deletion so a matricule is never reassigned.';

create or replace function private.tirer_nombre_matricule(p_width integer)
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_random bytea;
  v_number bigint;
begin
  if p_width not in (4, 5) then
    raise exception 'ImmatriculationFormatInvalide' using errcode = '22023';
  end if;
  v_random := extensions.gen_random_bytes(4);
  v_number := pg_catalog.get_byte(v_random, 0)::bigint * 16777216
            + pg_catalog.get_byte(v_random, 1)::bigint * 65536
            + pg_catalog.get_byte(v_random, 2)::bigint * 256
            + pg_catalog.get_byte(v_random, 3)::bigint;
  if p_width = 4 then
    return pg_catalog.mod(v_number, 10000)::integer;
  end if;
  return (10000 + pg_catalog.mod(v_number, 90000))::integer;
end;
$function$;

alter function private.tirer_nombre_matricule(integer) owner to postgres;
revoke all on function private.tirer_nombre_matricule(integer)
  from public, anon, authenticated, service_role;

create or replace function private.attribuer_matricule(
  p_profile_id uuid,
  p_issued_at timestamptz
)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_existing text;
  v_year integer;
  v_year_suffix text;
  v_count bigint;
  v_width integer;
  v_number integer;
  v_matricule text;
  v_attempt integer;
begin
  if p_profile_id is null or p_issued_at is null then
    raise exception 'ImmatriculationParametresInvalides' using errcode = '22023';
  end if;

  select r.matricule into v_existing
    from private.person_registrations r
   where r.profile_id = p_profile_id;
  if found then
    return v_existing;
  end if;

  v_year := extract(year from p_issued_at at time zone 'UTC')::integer;
  if v_year not between 2000 and 2199 then
    raise exception 'ImmatriculationAnneeInvalide' using errcode = '22023';
  end if;
  v_year_suffix := pg_catalog.lpad((v_year % 100)::text, 2, '0');

  -- Serialize the 4-to-5 digit threshold per UTC year while keeping independent
  -- years concurrent. A registration is reserved in the caller's transaction.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('person-registration:' || v_year::text, 0)
  );

  select r.matricule into v_existing
    from private.person_registrations r
   where r.profile_id = p_profile_id;
  if found then
    return v_existing;
  end if;

  select pg_catalog.count(*) into v_count
    from private.person_registrations r
   where r.registration_year = v_year;
  if v_count >= 94500 then
    raise exception 'ImmatriculationCapaciteAnnuelleAtteinte' using errcode = '54000';
  end if;
  v_width := case when v_count < 4500 then 4 else 5 end;

  for v_attempt in 1..1000 loop
    v_number := private.tirer_nombre_matricule(v_width);
    v_matricule := 'RA-' || v_year_suffix || '-'
      || pg_catalog.lpad(v_number::text, v_width, '0');

    begin
      insert into private.person_registrations
        (profile_id, matricule, registration_year, issued_at)
      values (p_profile_id, v_matricule, v_year, p_issued_at);
      return v_matricule;
    exception when unique_violation then
      -- A collision retries with a fresh random value. If the same profile was
      -- concurrently assigned, return its original registration unchanged.
      select r.matricule into v_existing
        from private.person_registrations r
       where r.profile_id = p_profile_id;
      if found then
        return v_existing;
      end if;
    end;
  end loop;

  raise exception 'ImmatriculationTiragesEpuises' using errcode = '54000';
end;
$function$;

alter function private.attribuer_matricule(uuid, timestamptz) owner to postgres;
revoke all on function private.attribuer_matricule(uuid, timestamptz)
  from public, anon, authenticated, service_role;

commit;
