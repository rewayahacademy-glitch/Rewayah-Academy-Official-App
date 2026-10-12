-- IMM-BACK-1 A: synthetic RA format, uniqueness and collision retry cases.
begin;

create temporary table imm_back_1_draws (attempts integer not null) on commit drop;
insert into imm_back_1_draws values (0);
insert into private.person_registrations
  (profile_id, matricule, registration_year, issued_at)
values ('a1150000-0000-0000-0000-000000000001', 'RA-50-1234', 2050, '2050-01-01 UTC');

create or replace function private.tirer_nombre_matricule(p_width integer)
returns integer
language plpgsql security definer set search_path = ''
as $forced_draw$
declare
  v_attempt integer;
  v_number integer;
begin
  update pg_temp.imm_back_1_draws
     set attempts = attempts + 1
   returning attempts into v_attempt;
  if v_attempt = 1 then return 1234; end if;
  if v_attempt = 2 then return 5678; end if;
  if v_attempt = 3 then return 8765; end if;
  if p_width = 4 then
    select n into v_number
      from pg_catalog.generate_series(0, 9999) as candidates(n)
     where n > 0 and not exists (
       select 1 from private.person_registrations r
        where r.matricule = 'RA-'
          || pg_catalog.lpad((extract(year from now() at time zone 'UTC')::integer % 100)::text, 2, '0')
          || '-' || pg_catalog.lpad(n::text, 4, '0')
     )
     order by n limit 1;
    return v_number;
  end if;
  select n into v_number
    from pg_catalog.generate_series(10000, 99999) as candidates(n)
   where not exists (
     select 1 from private.person_registrations r
      where r.matricule = 'RA-'
        || pg_catalog.lpad((extract(year from now() at time zone 'UTC')::integer % 100)::text, 2, '0')
        || '-' || pg_catalog.lpad(n::text, 5, '0')
   )
   order by n limit 1;
  return v_number;
end;
$forced_draw$;

do $allocator$
declare
  v_code text;
  v_other text;
begin
  v_code := private.attribuer_matricule(
    'a1150000-0000-0000-0000-000000000002', '2050-01-02 UTC'
  );
  v_other := private.attribuer_matricule(
    'a1150000-0000-0000-0000-000000000003', '2050-01-03 UTC'
  );
  if v_code <> 'RA-50-5678'
     or v_other <> 'RA-50-8765'
     or v_code = v_other
     or (select attempts from imm_back_1_draws) <> 3
     or (select count(*) from private.person_registrations
          where profile_id in (
            'a1150000-0000-0000-0000-000000000002',
            'a1150000-0000-0000-0000-000000000003'
          )) <> 2 then
    raise exception 'IMM-01/02/03: format, unicite ou reprise apres collision incorrects';
  end if;
end;
$allocator$;

-- IMM-BACK-1 B: official creation paths and immutability.
insert into auth.users (id, email) values
  ('a1100000-0000-0000-0000-000000000001', 'imm1-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000002', 'imm1-outsider@example.test'),
  ('a1100000-0000-0000-0000-000000000003', 'imm1-child@example.test'),
  ('a1100000-0000-0000-0000-000000000004', 'imm1-admin@example.test'),
  ('a1100000-0000-0000-0000-000000000005', 'imm1-signup-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000006', 'imm1-signup-teacher@example.test'),
  ('a1100000-0000-0000-0000-000000000008', 'imm1-direct-insert@example.test'),
  ('a1100000-0000-0000-0000-000000000009', 'imm1-atomic-failure@example.test');
insert into public.households (id, timezone) values
  ('a11fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('a11fffff-0000-0000-0000-000000000002', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('a1100000-0000-0000-0000-000000000001', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Amira', 'Test', 'active'),
  ('a1100000-0000-0000-0000-000000000002', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000002', 'Nadia', 'Outside', 'active'),
  ('a1100000-0000-0000-0000-000000000004', null, 'admin',
   null, 'Admin', 'Fixture', 'active');

do $official_creation_paths$
declare
  v_profile public.profiles;
begin
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000005', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000005","app_metadata":{"role":"guardian"}}', true);
  v_profile := public.creer_profil_inscription(
    'guardian', 'Salma', 'Signup', null, 'Europe/Paris', false
  );
  if not exists (select 1 from private.person_registrations r
                  where r.profile_id = v_profile.id and r.matricule = v_profile.immutable_id) then
    raise exception 'IMM-01: inscription guardian sans registre';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000006', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000006","app_metadata":{"role":"teacher"}}', true);
  v_profile := public.creer_profil_inscription(
    'teacher', 'Omar', 'Signup', null, 'Europe/Paris', false
  );
  if not exists (select 1 from private.person_registrations r
                  where r.profile_id = v_profile.id and r.matricule = v_profile.immutable_id) then
    raise exception 'IMM-01: inscription teacher sans registre';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000001',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000001'
    )
  )::text, true);
  v_profile := public.creer_profil_enfant(
    'a1100000-0000-0000-0000-000000000003',
    'a1100000-0000-0000-0000-000000000001', 'Lina', 'Created', 10, null
  );
  if v_profile.immutable_id !~ '^RA-[0-9]{2}-[0-9]{4,5}$'
     or not exists (select 1 from private.person_registrations r
                     where r.profile_id = v_profile.id and r.matricule = v_profile.immutable_id) then
    raise exception 'IMM-01: parcours enfant sans matricule du registre';
  end if;
end;
$official_creation_paths$;

-- A dependent-row failure proves profile and reservation roll back together.
create function pg_temp.imm_back_1_fail_student_profile()
returns trigger language plpgsql set search_path = '' as $fail$
begin
  if new.profile_id = 'a1100000-0000-0000-0000-000000000009' then
    raise exception 'IMM-BACK-1 forced post-allocation failure';
  end if;
  return new;
end;
$fail$;
create trigger imm_back_1_force_student_failure
before insert on public.student_profiles
for each row execute function pg_temp.imm_back_1_fail_student_profile();
do $atomicity$
declare
  v_failed boolean := false;
begin
  begin
    perform public.creer_profil_enfant(
      'a1100000-0000-0000-0000-000000000009',
      'a1100000-0000-0000-0000-000000000001', 'Atomic', 'Rollback', 10, null
    );
  exception when raise_exception then
    v_failed := true;
  end;
  if not v_failed
     or exists (select 1 from public.profiles where id = 'a1100000-0000-0000-0000-000000000009')
     or exists (select 1 from private.person_registrations
                 where profile_id = 'a1100000-0000-0000-0000-000000000009') then
    raise exception 'IMM-BACK-1: profil ou matricule conservé après échec';
  end if;
end;
$atomicity$;
drop trigger imm_back_1_force_student_failure on public.student_profiles;
drop function pg_temp.imm_back_1_fail_student_profile();

do $coverage_and_immutability$
declare
  v_code text;
  v_immutable boolean := false;
begin
  if exists (
    select 1 from public.profiles p
    left join private.person_registrations r on r.profile_id = p.id
    where r.profile_id is null or r.matricule is distinct from p.immutable_id
  ) then
    raise exception 'IMM-02/04: profil sans matricule correspondant au registre';
  end if;
  select immutable_id into v_code from public.profiles
   where id = 'a1100000-0000-0000-0000-000000000003';
  update public.profiles set first_name = 'LinaRenommee', role = 'guardian'
   where id = 'a1100000-0000-0000-0000-000000000003';
  if (select immutable_id from public.profiles
       where id = 'a1100000-0000-0000-0000-000000000003') <> v_code then
    raise exception 'IMM-04: renommage ou changement de role a modifie le matricule';
  end if;
  begin
    update public.profiles set immutable_id = 'RA-00-0000'
     where id = 'a1100000-0000-0000-0000-000000000003';
  exception when raise_exception then
    v_immutable := true;
  end;
  if not v_immutable then
    raise exception 'IMM-04: modification directe du matricule acceptee';
  end if;
  if has_table_privilege('authenticated', 'private.person_registrations', 'SELECT')
     or has_table_privilege('service_role', 'private.person_registrations', 'SELECT') then
    raise exception 'IMM-09: lecture directe du registre accordee';
  end if;
end;
$coverage_and_immutability$;

-- Direct authenticated admin INSERT cannot preserve a caller-supplied code.
set local session authorization authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000004","role":"authenticated","app_metadata":{"role":"admin"}}', true);
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status)
values ('a1100000-0000-0000-0000-000000000008', 'RA-26-0000', 'guardian',
        'Direct', 'Insert', 'active');
do $caller_chosen_code$
begin
  if (select immutable_id from public.profiles
       where id = 'a1100000-0000-0000-0000-000000000008') = 'RA-26-0000'
     or not exists (
       select 1 from private.person_registrations r
        join public.profiles p on p.id = r.profile_id
        where r.profile_id = 'a1100000-0000-0000-0000-000000000008'
          and r.matricule = p.immutable_id
     ) then
    raise exception 'IMM-09: insertion directe a conserve le matricule fourni';
  end if;
end;
$caller_chosen_code$;

rollback;
