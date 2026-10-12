-- IMM-BACK-1: synthetic registration, lifecycle, authorization and threshold cases.
begin;

create temporary table imm_back_1_codes (
  kind text primary key,
  profile_id uuid not null,
  matricule text not null
) on commit drop;

insert into auth.users (id, email) values
  ('a1100000-0000-0000-0000-000000000001', 'imm1-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000002', 'imm1-outsider@example.test'),
  ('a1100000-0000-0000-0000-000000000003', 'imm1-child@example.test'),
  ('a1100000-0000-0000-0000-000000000004', 'imm1-admin@example.test'),
  ('a1100000-0000-0000-0000-000000000005', 'imm1-signup-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000006', 'imm1-signup-teacher@example.test'),
  ('a1100000-0000-0000-0000-000000000007', 'imm1-retired@example.test'),
  ('a1100000-0000-0000-0000-000000000008', 'imm1-direct-insert@example.test'),
  ('a1100000-0000-0000-0000-000000000009', 'imm1-atomic-failure@example.test');
insert into public.households (id, timezone) values
  ('a11fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('a11fffff-0000-0000-0000-000000000002', 'Europe/Paris');

-- NULL is the server-owned allocation request used by every official path.
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('a1100000-0000-0000-0000-000000000001', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Amira', 'Test', 'active'),
  ('a1100000-0000-0000-0000-000000000002', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000002', 'Nadia', 'Outside', 'active'),
  ('a1100000-0000-0000-0000-000000000004', null, 'admin',
   null, 'Admin', 'Fixture', 'active'),
  ('a1100000-0000-0000-0000-000000000007', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Retired', 'Fixture', 'active');

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
  insert into imm_back_1_codes values ('signup_guardian', v_profile.id, v_profile.immutable_id);

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000006', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000006","app_metadata":{"role":"teacher"}}', true);
  v_profile := public.creer_profil_inscription(
    'teacher', 'Omar', 'Signup', null, 'Europe/Paris', false
  );
  insert into imm_back_1_codes values ('signup_teacher', v_profile.id, v_profile.immutable_id);

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000001',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000001'
    )
  )::text, true);
  v_profile := public.creer_profil_enfant(
    'a1100000-0000-0000-0000-000000000003',
    'a1100000-0000-0000-0000-000000000001',
    'Lina', 'Created', 10, null
  );
  if v_profile.immutable_id !~ '^RA-[0-9]{2}-[0-9]{4,5}$' then
    raise exception 'IMM-01: parcours enfant sans matricule RA';
  end if;
  if not exists (
    select 1 from private.person_registrations r
     where r.profile_id = v_profile.id
       and r.matricule = v_profile.immutable_id
  ) then
    raise exception 'IMM-01: parcours enfant absent du registre';
  end if;
  insert into imm_back_1_codes values ('child', v_profile.id, v_profile.immutable_id);
end;
$official_creation_paths$;

-- A failure after allocation rolls back both the profile and its reservation.
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
      'a1100000-0000-0000-0000-000000000001',
      'Atomic', 'Rollback', 10, null
    );
  exception when raise_exception then
    v_failed := true;
  end;
  if not v_failed
     or exists (select 1 from public.profiles
                 where id = 'a1100000-0000-0000-0000-000000000009')
     or exists (select 1 from private.person_registrations
                 where profile_id = 'a1100000-0000-0000-0000-000000000009') then
    raise exception 'IMM-BACK-1: profil ou matricule conservé après échec post-allocation';
  end if;
end;
$atomicity$;
drop trigger imm_back_1_force_student_failure on public.student_profiles;
drop function pg_temp.imm_back_1_fail_student_profile();

do $coverage_and_format$
begin
  if exists (
    select 1
      from public.profiles p
      left join private.person_registrations r on r.profile_id = p.id
     where r.profile_id is null
        or r.matricule is distinct from p.immutable_id
        or r.matricule !~ '^RA-[0-9]{2}-[0-9]{4,5}$'
  ) then
    raise exception 'IMM-01/02: profil absent, code legacy ou format non conforme';
  end if;
  if (select count(distinct matricule) from imm_back_1_codes) <> 3
     or exists (
       select 1 from imm_back_1_codes c
       where c.matricule !~ '^RA-[0-9]{2}-[0-9]{4,5}$'
          or c.matricule ~* '(GUARDIAN|TEACHER|STUDENT|AMIRA|NADIA|LINA|SALMA|OMAR)'
     ) then
    raise exception 'IMM-02/03: matricule dérivé du rôle, du nom ou du code en doublon';
  end if;
end;
$coverage_and_format$;

-- A forced collision proves that a unique conflict retries without changing the person.
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
begin
  update pg_temp.imm_back_1_draws set attempts = attempts + 1 returning attempts into v_attempt;
  if p_width = 5 then return 45678; end if;
  return case when v_attempt = 1 then 1234 else 5678 end;
end;
$forced_draw$;
do $collision_retry$
declare
  v_code text;
begin
  v_code := private.attribuer_matricule(
    'a1150000-0000-0000-0000-000000000002', '2050-01-02 UTC'
  );
  if v_code <> 'RA-50-5678'
     or (select attempts from imm_back_1_draws) <> 2 then
    raise exception 'IMM-03: collision non retentée';
  end if;
end;
$collision_retry$;

-- Threshold semantics: the 4,500th code is still four digits; later codes use five.
insert into private.person_registrations
  (profile_id, matricule, registration_year, issued_at)
select
  ('a1290000-0000-0000-0000-' || pg_catalog.lpad(n::text, 12, '0'))::uuid,
  'RA-99-' || pg_catalog.lpad(n::text, 4, '0'),
  2099,
  '2099-01-01 UTC'
from generate_series(0, 4498) as n;
do $threshold$
declare
  v_four text;
  v_five text;
begin
  v_four := private.attribuer_matricule(
    'a1299999-0000-0000-0000-000000000001', '2099-01-02 UTC'
  );
  v_five := private.attribuer_matricule(
    'a1299999-0000-0000-0000-000000000002', '2099-01-03 UTC'
  );
  if v_four !~ '^RA-99-[0-9]{4}$' or v_five !~ '^RA-99-[0-9]{5}$' then
    raise exception 'IMM-11: seuil de 4 500 matricules incorrect';
  end if;
end;
$threshold$;

-- The code survives rename, role change, and account reactivation; profile deletion
-- does not erase the registry reservation or make the code reusable.
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000004","app_metadata":{"role":"admin"}}', true);
update public.profiles
   set first_name = 'LinaRenommee', role = 'guardian', account_status = 'provisional_active'
 where id = 'a1100000-0000-0000-0000-000000000003';
do $stability$
declare
  v_code text;
begin
  select c.matricule into v_code from imm_back_1_codes c where c.kind = 'child';
  if (select immutable_id from public.profiles
       where id = 'a1100000-0000-0000-0000-000000000003') <> v_code
     or (select matricule from private.person_registrations
          where profile_id = 'a1100000-0000-0000-0000-000000000003') <> v_code then
    raise exception 'IMM-04/05: changement de rôle ou de nom a modifié le matricule';
  end if;
  update public.profiles set account_status = 'active'
   where id = 'a1100000-0000-0000-0000-000000000003';
  if (select immutable_id from public.profiles
       where id = 'a1100000-0000-0000-0000-000000000003') <> v_code then
    raise exception 'IMM-04: réactivation a modifié le matricule';
  end if;
  if private.attribuer_matricule('a1100000-0000-0000-0000-000000000003', now()) <> v_code then
    raise exception 'IMM-04: réessai a régénéré le matricule';
  end if;
end;
$stability$;

select set_config('imm.back1.child_code',
  (select immutable_id from public.profiles where id = 'a1100000-0000-0000-0000-000000000003'), true);
select set_config('imm.back1.outsider_code',
  (select immutable_id from public.profiles where id = 'a1100000-0000-0000-0000-000000000002'), true);
select set_config('imm.back1.deleted_code',
  (select immutable_id from public.profiles where id = 'a1100000-0000-0000-0000-000000000007'), true);
delete from auth.users where id = 'a1100000-0000-0000-0000-000000000007';
do $non_reassignment$
declare
  v_code text := current_setting('imm.back1.deleted_code');
begin
  if exists (select 1 from public.profiles where id = 'a1100000-0000-0000-0000-000000000007')
     or not exists (select 1 from private.person_registrations
                     where profile_id = 'a1100000-0000-0000-0000-000000000007'
                       and matricule = v_code)
     or private.attribuer_matricule('a1100000-0000-0000-0000-000000000007', now()) <> v_code then
    raise exception 'IMM-12: suppression du profil a libéré ou changé le matricule';
  end if;
end;
$non_reassignment$;

-- The unique B-tree supports exact lookup and no public role can resolve a code.
do $catalogue$
begin
  if not exists (
    select 1 from pg_catalog.pg_index i
    join pg_catalog.pg_class t on t.oid = i.indrelid
    join pg_catalog.pg_namespace n on n.oid = t.relnamespace
    join pg_catalog.pg_attribute a on a.attrelid = t.oid
      and a.attname = 'matricule' and a.attnum = i.indkey[0]
    where n.nspname = 'private' and t.relname = 'person_registrations'
      and i.indisunique and i.indisvalid and i.indpred is null and i.indexprs is null
  ) then
    raise exception 'IMM-14: index exact du matricule absent';
  end if;
  if exists (
       select 1 from pg_catalog.pg_proc p
        where p.oid in (
          'private.tirer_nombre_matricule(integer)'::regprocedure,
          'private.attribuer_matricule(uuid,timestamptz)'::regprocedure,
          'public.profiles_attribuer_matricule()'::regprocedure,
          'public.rechercher_personne_par_matricule(text)'::regprocedure
        )
          and (not p.prosecdef
            or p.proowner <> 'postgres'::regrole
            or not (p.proconfig @> array['search_path=""']))
     ) then
    raise exception 'IMM-BACK-1: nouveau DEFINER sans owner postgres et search_path vide';
  end if;
  if has_table_privilege('authenticated', 'private.person_registrations', 'SELECT')
     or has_table_privilege('service_role', 'private.person_registrations', 'SELECT')
     or has_function_privilege('anon', 'private.attribuer_matricule(uuid,timestamptz)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.attribuer_matricule(uuid,timestamptz)', 'EXECUTE')
     or has_function_privilege('service_role', 'private.attribuer_matricule(uuid,timestamptz)', 'EXECUTE')
     or has_function_privilege('anon', 'private.tirer_nombre_matricule(integer)', 'EXECUTE')
     or has_function_privilege('service_role', 'private.tirer_nombre_matricule(integer)', 'EXECUTE')
     or has_function_privilege('anon', 'public.profiles_attribuer_matricule()', 'EXECUTE')
     or has_function_privilege('service_role', 'public.profiles_attribuer_matricule()', 'EXECUTE')
     or has_function_privilege('anon', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or has_function_privilege('service_role', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE') then
    raise exception 'IMM-09: registre ou résolution exposés hors du périmètre authentifié';
  end if;
end;
$catalogue$;

set local role authenticated;
do $lookup_and_guards$
declare
  v_code text := current_setting('imm.back1.child_code');
  v_outsider_code text := current_setting('imm.back1.outsider_code');
  v_rows integer;
  v_denied boolean := false;
  v_immutable boolean := false;
begin
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000001',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000001'
    )
  )::text, true);
  select count(*) into v_rows
    from public.rechercher_personne_par_matricule(lower(replace(v_code, '-', ' '))) r
   where r.profile_id = 'a1100000-0000-0000-0000-000000000003'
     and r.matricule = v_code
     and r.first_name = 'LinaRenommee'
     and r.role = 'guardian';
  if v_rows <> 1 then
    raise exception 'IMM-05/09: recherche tolérante autorisée ou rôle serveur incorrect';
  end if;
  if exists (select 1 from public.rechercher_personne_par_matricule(v_outsider_code)) then
    raise exception 'IMM-05: code syntaxiquement valide hors du foyer retourné';
  end if;
  if exists (select 1 from public.rechercher_personne_par_matricule('RA-O1-12I4')) then
    raise exception 'IMM-05: caractères non numériques acceptés';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000002', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000002',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000002'
    )
  )::text, true);
  if exists (select 1 from public.rechercher_personne_par_matricule(v_code)) then
    raise exception 'IMM-09: tuteur étranger a résolu le matricule connu';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000004', true);
  perform set_config('request.jwt.claims',
    '{"sub":"a1100000-0000-0000-0000-000000000004","app_metadata":{"role":"admin"}}', true);
  begin
    perform 1 from private.person_registrations;
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'IMM-09: lecture directe du registre permise';
  end if;
  begin
    update public.profiles set immutable_id = 'IMMUTABLE-CHANGE'
     where id = 'a1100000-0000-0000-0000-000000000003';
  exception when raise_exception then
    v_immutable := true;
  end;
  if not v_immutable then
    raise exception 'IMM-04: modification directe du matricule acceptée';
  end if;
end;
$lookup_and_guards$;
reset role;

-- A direct API insertion cannot smuggle a caller-chosen immutable_id.
set local session authorization authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims', '{"sub":"a1100000-0000-0000-0000-000000000004","role":"authenticated","app_metadata":{"role":"admin"}}', true);
insert into public.profiles
  (id, immutable_id, role, first_name, last_name, account_status)
values
  ('a1100000-0000-0000-0000-000000000008', 'RA-26-0000', 'guardian', 'Direct', 'Insert', 'active');
do $caller_chosen_code$
begin
  if (select immutable_id from public.profiles where id = 'a1100000-0000-0000-0000-000000000008') = 'RA-26-0000'
     or not exists (
       select 1 from private.person_registrations r
        join public.profiles p on p.id = r.profile_id
        where r.profile_id = 'a1100000-0000-0000-0000-000000000008'
          and r.matricule = p.immutable_id
          and r.matricule ~ '^RA-[0-9]{2}-[0-9]{4,5}$'
     ) then
    raise exception 'IMM-BACK-1: insertion directe a conservé un matricule fourni';
  end if;
end;
$caller_chosen_code$;

rollback;
