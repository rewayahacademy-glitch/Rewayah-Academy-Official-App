-- B-13 : un compte admin suspendu ne lit pas l'historique des visites.
-- Base PostgreSQL jetable apres rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('b1300000-0000-0000-0000-000000000001', 'b13-admin-active@example.test'),
  ('b1300000-0000-0000-0000-000000000002', 'b13-admin-disabled@example.test'),
  ('b1300000-0000-0000-0000-000000000003', 'b13-teacher@example.test'),
  ('b1300000-0000-0000-0000-000000000004', 'b13-guardian@example.test'),
  ('b1300000-0000-0000-0000-000000000005', 'b13-student@example.test');

insert into public.households (id, timezone)
values ('b13fffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b1300000-0000-0000-0000-000000000001', 'B13ADMIN000001', 'admin',
   'b13fffff-0000-0000-0000-000000000001', 'Active', 'Admin', 'active'),
  ('b1300000-0000-0000-0000-000000000002', 'B13ADMIN000002', 'admin',
   'b13fffff-0000-0000-0000-000000000001', 'Disabled', 'Admin', 'disabled'),
  ('b1300000-0000-0000-0000-000000000003', 'B13TEACHER0001', 'teacher',
   'b13fffff-0000-0000-0000-000000000001', 'Fixture', 'Teacher', 'provisional_active'),
  ('b1300000-0000-0000-0000-000000000004', 'B13GUARDIAN001', 'guardian',
   'b13fffff-0000-0000-0000-000000000001', 'Fixture', 'Guardian', 'active'),
  ('b1300000-0000-0000-0000-000000000005', 'B13STUDENT0001', 'student',
   'b13fffff-0000-0000-0000-000000000001', 'Fixture', 'Student', 'active');

update public.households
   set primary_guardian_id = 'b1300000-0000-0000-0000-000000000004'
 where id = 'b13fffff-0000-0000-0000-000000000001';

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('b13fffff-0000-0000-0000-000000000002',
   'b1300000-0000-0000-0000-000000000003', 'enfant', 5, 'B13 fixture', 1, 10);

insert into public.sessions
  (id, teacher_id, started_at, ended_at)
values
  ('b13fffff-0000-0000-0000-000000000003',
   'b1300000-0000-0000-0000-000000000003',
   TIMESTAMPTZ '2030-01-02 03:00:00+00',
   TIMESTAMPTZ '2030-01-02 04:00:00+00');

insert into public.guardian_session_visit
  (id, session_id, groupe_id, observateur_profile_id, role, enfant_profile_id,
   visit_number, policy_version)
values
  ('b13fffff-0000-0000-0000-000000000004',
   'b13fffff-0000-0000-0000-000000000003',
   'b13fffff-0000-0000-0000-000000000002',
   'b1300000-0000-0000-0000-000000000004',
   'guardian_observer',
   'b1300000-0000-0000-0000-000000000005',
   1, 'b13-test');

set local role authenticated;
select set_config('test.uid', 'b1300000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b13fffff-0000-0000-0000-000000000001"}}',
  true);

do $b13_active_admin$
declare
  v_count integer;
begin
  if not pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'SELECT'
     )
     or pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'INSERT'
     )
     or pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'UPDATE'
     )
     or pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'DELETE'
     ) THEN
    raise exception 'B-13: authenticated must have read-only visit access';
  end if;

  select count(*) into v_count from public.guardian_session_visit
   where id = 'b13fffff-0000-0000-0000-000000000004';
  if v_count <> 1 then
    raise exception 'B-13: an active admin must read the observation history';
  end if;
end
$b13_active_admin$;

select set_config('test.uid', 'b1300000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b13fffff-0000-0000-0000-000000000001"}}',
  true);

do $b13_disabled_admin$
declare
  v_count integer;
begin
  select count(*) into v_count from public.guardian_session_visit
   where id = 'b13fffff-0000-0000-0000-000000000004';
  if v_count <> 0 then
    raise exception 'B-13: a disabled admin must not read observation history';
  end if;
end
$b13_disabled_admin$;

reset role;

do $b13_anonymous_acl$
begin
  if pg_catalog.has_table_privilege(
       'anon', 'public.guardian_session_visit', 'SELECT'
     ) then
    raise exception 'B-13: anon retains SELECT on observation history';
  end if;
end
$b13_anonymous_acl$;

set local role anon;
do $b13_anonymous_denied$
begin
  begin
    perform 1 from public.guardian_session_visit;
    raise exception 'B-13: anonymous observation-history read was accepted';
  exception when insufficient_privilege then
    null;
  end;
end
$b13_anonymous_denied$;

reset role;
rollback;
