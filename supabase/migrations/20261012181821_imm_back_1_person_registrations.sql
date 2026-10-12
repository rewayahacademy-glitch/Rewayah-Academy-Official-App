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

-- IMM-BACK-1 B: assign registry codes in the profile-creation transaction.
create or replace function public.profiles_attribuer_matricule()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  -- API sessions cannot choose a matricule, even when INSERT supplies one.
  -- The migration/test database owner may still seed explicit fixtures.
  if new.immutable_id is null or session_user <> 'postgres' then
    new.immutable_id := private.attribuer_matricule(new.id, new.created_at);
  end if;
  return new;
end;
$function$;

alter function public.profiles_attribuer_matricule() owner to postgres;
revoke all on function public.profiles_attribuer_matricule()
  from public, anon, authenticated, service_role;
create trigger profiles_assign_person_registration
before insert on public.profiles
for each row execute function public.profiles_attribuer_matricule();

create or replace function public.creer_profil_inscription(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender default null,
  p_timezone text default 'Europe/Paris',
  p_parent_suit_des_cours boolean default false
) returns public.profiles
language plpgsql security definer set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
begin
  if v_uid is null then raise exception 'aucune session'; end if;
  if p_role not in ('guardian', 'teacher') then
    raise exception 'role non ouvert a l''inscription publique : %', p_role;
  end if;
  v_role := p_role::public.app_role;
  if v_role <> 'guardian' and coalesce(p_parent_suit_des_cours, false) then
    raise exception 'profil apprenant personnel reserve au titulaire';
  end if;
  if exists (select 1 from public.profiles p where p.id = v_uid) then
    raise exception 'ce compte a deja un profil';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;

  if v_role = 'guardian' then
    insert into public.households (timezone)
    values (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    returning id into v_household;
  end if;
  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  values (v_uid, null, v_role, v_household,
    btrim(p_first_name), btrim(p_last_name), p_gender, 'pending_kyc')
  returning * into v_profile;

  if v_role = 'guardian' then
    update public.households set primary_guardian_id = v_uid where id = v_household;
    if coalesce(p_parent_suit_des_cours, false) then
      insert into public.student_profiles
        (profile_id, titulaire_profile_id, student_type, interface_mode,
         camera_policy, cohorte)
      values (v_uid, v_uid, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');
      perform public.log_sensitive_access(
        'profil_eleve_titulaire_cree', 'student_profiles', v_uid::text,
        jsonb_build_object('student_type', 'autonomous', 'source', 'inscription')
      );
    end if;
  else
    insert into public.teacher_profiles (profile_id) values (v_uid);
  end if;
  perform public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));
  return v_profile;
end;
$function$;

alter function public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) owner to postgres;
revoke execute on function public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) from public, anon;
grant execute on function public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) to authenticated;

create or replace function public.creer_profil_enfant(
  p_auth_user_id uuid,
  p_guardian_id uuid,
  p_first_name text,
  p_last_name text,
  p_age int,
  p_level text default null
) returns public.profiles
language plpgsql security definer set search_path = ''
as $function$
declare
  v_guardian public.profiles;
  v_profile public.profiles;
  v_mode public.interface_mode;
  v_camera public.camera_policy;
  v_seuil_enfant int;
  v_age_camera int;
begin
  select * into v_guardian
    from public.profiles p
   where p.id = p_guardian_id and p.deleted_at is null;
  if v_guardian.id is null or v_guardian.role <> 'guardian' then
    raise exception 'l''appelant n''est pas un tuteur';
  end if;
  if v_guardian.household_id is null then
    raise exception 'ce tuteur n''a pas de foyer';
  end if;
  if v_guardian.account_status not in ('active', 'provisional_active') then
    raise exception 'compte tuteur non valide';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;
  if p_age is null or p_age < 3 or p_age > 99 then
    raise exception 'age hors bornes';
  end if;

  select coalesce((public.get_config('child_ui_mode_max_age', '8'::jsonb) #>> '{}')::int, 8)
    into v_seuil_enfant;
  select coalesce((public.get_config('camera_auto_allow_min_age', '11'::jsonb) #>> '{}')::int, 11)
    into v_age_camera;
  v_mode := case when p_age <= v_seuil_enfant then 'child' else 'standard' end;
  v_camera := case when p_age >= v_age_camera then 'allowed' else 'forbidden' end;

  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, account_status)
  values (p_auth_user_id, null, 'student', v_guardian.household_id,
    btrim(p_first_name), btrim(p_last_name), v_guardian.account_status)
  returning * into v_profile;

  insert into public.student_profiles
    (profile_id, student_type, interface_mode, camera_policy, level)
  values (p_auth_user_id, 'minor', v_mode, v_camera, p_level);
  perform public.log_sensitive_access('profil_enfant_cree', 'profiles', p_auth_user_id::text,
    jsonb_build_object('household_id', v_guardian.household_id, 'mode', v_mode::text));
  return v_profile;
end;
$function$;

alter function public.creer_profil_enfant(uuid, uuid, text, text, integer, text) owner to postgres;
revoke execute on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  to service_role;

-- Backfill old profiles in their original UTC registration year, then restore
-- the existing unique/immutable guarantees with the server-issued RA value.
alter table public.profiles drop constraint profiles_immutable_id_unique;
drop trigger profiles_immutable_id_guard on public.profiles;
do $backfill$
declare
  v_profile record;
  v_matricule text;
begin
  for v_profile in
    select p.id, p.created_at from public.profiles p order by p.created_at, p.id
  loop
    v_matricule := private.attribuer_matricule(v_profile.id, v_profile.created_at);
    update public.profiles p set immutable_id = v_matricule where p.id = v_profile.id;
  end loop;
end;
$backfill$;
alter table public.profiles
  add constraint profiles_immutable_id_unique unique (immutable_id);
create trigger profiles_immutable_id_guard
before update on public.profiles
for each row execute function public.guard_profile_immutable_id();

commit;
