-- IMM-BACK-1 A: synthetic RA format, uniqueness and collision retry cases.
begin;

-- Test-only Supabase Auth fields used by the server-origin guard; the shared
-- stub_auth.sql remains untouched.
alter table auth.users add column if not exists raw_app_meta_data jsonb not null default '{}'::jsonb;
alter table auth.users add column if not exists created_at timestamptz not null default now();

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
        where pg_catalog.split_part(r.matricule, '-', 3) = pg_catalog.lpad(n::text, 4, '0')
     )
     order by n limit 1;
    return v_number;
  end if;
  select n into v_number
    from pg_catalog.generate_series(10000, 99999) as candidates(n)
   where not exists (
     select 1 from private.person_registrations r
      where pg_catalog.split_part(r.matricule, '-', 3) = pg_catalog.lpad(n::text, 5, '0')
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
  ('a1100000-0000-0000-0000-000000000009', 'imm1-atomic-failure@example.test'),
  ('a1100000-0000-0000-0000-000000000010', 'imm1-teacher@example.test'),
  ('a1100000-0000-0000-0000-000000000011', 'imm1-student@example.test'),
  ('a1100000-0000-0000-0000-000000000012', 'imm1-pending-guardian@example.test'),
  ('a1100000-0000-0000-0000-000000000013', 'imm1-expired-guardian@example.test');
update auth.users set raw_app_meta_data = jsonb_build_object(
  'child_of', 'a1100000-0000-0000-0000-000000000001'
) where id in ('a1100000-0000-0000-0000-000000000003',
               'a1100000-0000-0000-0000-000000000009');
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
   null, 'Admin', 'Fixture', 'active'),
  ('a1100000-0000-0000-0000-000000000010', null, 'teacher',
   'a11fffff-0000-0000-0000-000000000001', 'Teacher', 'Fixture', 'active'),
  ('a1100000-0000-0000-0000-000000000011', null, 'student',
   'a11fffff-0000-0000-0000-000000000001', 'Student', 'Fixture', 'active'),
  ('a1100000-0000-0000-0000-000000000012', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Pending', 'Guardian', 'pending_kyc'),
  ('a1100000-0000-0000-0000-000000000013', null, 'guardian',
   'a11fffff-0000-0000-0000-000000000001', 'Expired', 'Guardian', 'active');
update public.profiles set access_until = '2000-01-01 UTC'
 where id = 'a1100000-0000-0000-0000-000000000013';

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
end;
$official_creation_paths$;

do $child_rpc_acl$
begin
  if not has_function_privilege(
       'authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE'
     )
     or has_function_privilege(
       'service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE'
     )
     or has_function_privilege(
       'anon',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE'
     )
     or has_function_privilege(
       'service_role',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE'
     ) then
    raise exception 'IMM-BACK-1: droits EXECUTE enfant incorrects';
  end if;
end;
$child_rpc_acl$;

-- F86 negative contexts: active non-guardians, a pending guardian and a
-- disabled administrator must not gain child-creation capability.
do $child_rpc_denies_roles_and_status$
declare
  v_actor uuid;
  v_role text;
  v_accepted boolean;
begin
  for v_actor, v_role in
    select * from (values
      ('a1100000-0000-0000-0000-000000000010'::uuid, 'teacher'),
      ('a1100000-0000-0000-0000-000000000011'::uuid, 'student'),
      ('a1100000-0000-0000-0000-000000000012'::uuid, 'guardian'),
      ('a1100000-0000-0000-0000-000000000013'::uuid, 'guardian'),
      ('a1100000-0000-0000-0000-000000000004'::uuid, 'admin')
    ) as actors(id, role_name)
  loop
    if v_role = 'admin' then
      update public.profiles set account_status = 'disabled' where id = v_actor;
    end if;
    update auth.users set raw_app_meta_data = jsonb_build_object('child_of', v_actor::text)
      where id = 'a1100000-0000-0000-0000-000000000009';
    perform set_config('request.jwt.claim.sub', v_actor::text, true);
    perform set_config('request.jwt.claims', jsonb_build_object(
      'sub', v_actor::text, 'app_metadata', jsonb_build_object('role', v_role)
    )::text, true);
    v_accepted := false;
    begin
      set local role authenticated;
      perform public.creer_profil_enfant(
        'a1100000-0000-0000-0000-000000000009', v_actor,
        'Refuse', 'Fixture', 10, null
      );
      v_accepted := true;
      raise exception '__rollback_accepted_child_probe__';
    exception when others then
      if sqlerrm = '__rollback_accepted_child_probe__' then
        null;
      else
        v_accepted := false;
      end if;
    end;
    if v_accepted then
      raise exception 'IMM-BACK-1: role/status probe accepted %', v_role;
    end if;
    if v_role = 'admin' then
      update public.profiles set account_status = 'active' where id = v_actor;
    end if;
  end loop;
  update auth.users set raw_app_meta_data = jsonb_build_object(
    'child_of', 'a1100000-0000-0000-0000-000000000001'
  ) where id = 'a1100000-0000-0000-0000-000000000009';
end;
$child_rpc_denies_roles_and_status$;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000002","app_metadata":{"role":"guardian"}}', true);
do $child_rpc_denies_other_guardian$
begin
  begin
    perform public.creer_profil_enfant(
      'a1100000-0000-0000-0000-000000000009',
      'a1100000-0000-0000-0000-000000000001', 'Intrus', 'Fixture', 10, null
    );
    raise exception 'IMM-BACK-1: un autre compte a pu créer un enfant';
  exception when insufficient_privilege then
    null;
  end;
end;
$child_rpc_denies_other_guardian$;

select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000001","app_metadata":{"role":"guardian","household_id":"a11fffff-0000-0000-0000-000000000001"}}', true);
select public.creer_profil_enfant(
  'a1100000-0000-0000-0000-000000000003',
  'a1100000-0000-0000-0000-000000000001', 'Lina', 'Created', 10, null
);
do $child_rpc_denies_existing_profile$
begin
  begin
    perform public.creer_profil_enfant(
      'a1100000-0000-0000-0000-000000000003',
      'a1100000-0000-0000-0000-000000000001', 'Duplicate', 'Profile', 10, null
    );
    raise exception 'IMM-BACK-1: profil existant accepte une seconde creation';
  exception when insufficient_privilege then
    null;
  end;
end;
$child_rpc_denies_existing_profile$;
do $child_rpc_denies_unproven_account$
begin
  begin
    perform public.creer_profil_enfant(
      'a1100000-0000-0000-0000-000000000008',
      'a1100000-0000-0000-0000-000000000001', 'Sans', 'Preuve', 10, null
    );
    raise exception 'IMM-BACK-1: compte auth arbitraire accepte comme enfant';
  exception when insufficient_privilege then
    null;
  end;
end;
$child_rpc_denies_unproven_account$;
reset role;
do $child_profile_registry$
begin
  if not exists (
    select 1 from public.profiles p
    join private.person_registrations r on r.profile_id = p.id
    where p.id = 'a1100000-0000-0000-0000-000000000003'
      and p.immutable_id ~ '^RA-[0-9]{2}-[0-9]{4,5}$'
      and r.matricule = p.immutable_id
  ) then
    raise exception 'IMM-01: parcours enfant sans matricule du registre';
  end if;
end;
$child_profile_registry$;

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

-- IMM-BACK-1 C: the 4,500th code remains four digits; later ones use five.
insert into private.person_registrations
  (profile_id, matricule, registration_year, issued_at)
select
  ('a1290000-0000-0000-0000-' || pg_catalog.lpad(n::text, 12, '0'))::uuid,
  'RA-99-' || pg_catalog.lpad(n::text, 4, '0'),
  2099, '2099-01-01 UTC'
from pg_catalog.generate_series(0, 4498) as candidates(n);
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
    raise exception 'IMM-11: seuil 4500 incorrect';
  end if;
end;
$threshold$;

-- A deleted account keeps its permanent reservation and cannot receive a new code.
insert into auth.users (id, email)
values ('a1100000-0000-0000-0000-000000000007', 'imm1-retired@example.test');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values ('a1100000-0000-0000-0000-000000000007', null, 'guardian',
        'a11fffff-0000-0000-0000-000000000001', 'Retired', 'Fixture', 'active');
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
    raise exception 'IMM-12: code libere apres suppression';
  end if;
end;
$non_reassignment$;

-- Direct authenticated admin INSERT cannot preserve a caller-supplied code.
set local session authorization authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims',
  '{"sub":"a1100000-0000-0000-0000-000000000004","role":"authenticated","app_metadata":{"role":"admin"}}', true);
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values ('a1100000-0000-0000-0000-000000000008', 'RA-26-0000', 'guardian',
        'a11fffff-0000-0000-0000-000000000001', 'Direct', 'Insert', 'active');
reset session authorization;
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
set local session authorization authenticated;

-- Exact lookup accepts separators/case but never reveals non-related profiles.
do $lookup_and_acl$
declare
  v_code text := (select immutable_id from public.profiles
                   where id = 'a1100000-0000-0000-0000-000000000003');
  v_outsider_code text := (select immutable_id from public.profiles
                            where id = 'a1100000-0000-0000-0000-000000000002');
  v_rows integer;
  v_denied boolean := false;
begin
  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000001',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000001'
    )
  )::text, true);
  select count(*) into v_rows
    from public.rechercher_personne_par_matricule(lower(replace(v_code, '-', ' '))) r
   where r.profile_id = 'a1100000-0000-0000-0000-000000000003'
     and r.matricule = v_code and r.first_name = 'LinaRenommee'
     and r.role = 'guardian';
  if v_rows <> 1
     or exists (select 1 from public.rechercher_personne_par_matricule(v_outsider_code))
     or exists (select 1 from public.rechercher_personne_par_matricule('RA-O1-12I4'))
     or exists (select 1 from public.rechercher_personne_par_matricule('RA-26-')) then
    raise exception 'IMM-05: recherche exacte ou droits du foyer incorrects';
  end if;

  perform set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000002', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a1100000-0000-0000-0000-000000000002',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000002'
    )
  )::text, true);
  if exists (select 1 from public.rechercher_personne_par_matricule(v_code)) then
    raise exception 'IMM-09: foyer etranger a resolu un matricule connu';
  end if;

  begin
    perform 1 from private.person_registrations;
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'IMM-09: lecture directe du registre permise';
  end if;
end;
$lookup_and_acl$;

reset session authorization;
update public.profiles set account_status = 'disabled'
 where id = 'a1100000-0000-0000-0000-000000000002';
select set_config('imm.back1.disabled_lookup_code',
  (select immutable_id from public.profiles
    where id = 'a1100000-0000-0000-0000-000000000002'), true);
set local session authorization authenticated;
select set_config('request.jwt.claim.sub', 'a1100000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'a1100000-0000-0000-0000-000000000002',
  'role', 'authenticated',
  'app_metadata', jsonb_build_object(
    'role', 'guardian', 'household_id', 'a11fffff-0000-0000-0000-000000000002'
  )
)::text, true);
do $disabled_lookup$
declare
  v_code text := current_setting('imm.back1.disabled_lookup_code');
begin
  if exists (select 1 from public.rechercher_personne_par_matricule(v_code)) then
    raise exception 'IMM-BACK-1: compte désactivé a recherché un matricule';
  end if;
end;
$disabled_lookup$;

reset session authorization;
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
    raise exception 'IMM-14: index unique exact du matricule absent';
  end if;
  if exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid in (
       'private.tirer_nombre_matricule(integer)'::regprocedure,
       'private.attribuer_matricule(uuid,timestamptz)'::regprocedure,
       'public.profiles_attribuer_matricule()'::regprocedure,
       'public.rechercher_personne_par_matricule(text)'::regprocedure
     )
       and (not p.prosecdef or p.proowner <> 'postgres'::regrole
         or not (p.proconfig @> array['search_path=""']))
  ) then
    raise exception 'IMM-BACK-1: nouveau DEFINER sans owner postgres et search_path vide';
  end if;
end;
$catalogue$;

rollback;
