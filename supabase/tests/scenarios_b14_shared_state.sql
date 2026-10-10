-- B-14 : etat partage persistant, autorise par seance et revision monotone.
-- Base PostgreSQL jetable apres rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('b1400000-0000-0000-0000-000000000001', 'b14-teacher-a@example.test'),
  ('b1400000-0000-0000-0000-000000000002', 'b14-teacher-b@example.test'),
  ('b1400000-0000-0000-0000-000000000003', 'b14-admin@example.test');

insert into public.households (id, timezone)
values ('b14fffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b1400000-0000-0000-0000-000000000001', 'B14TEACHERA001', 'teacher',
   'b14fffff-0000-0000-0000-000000000001', 'Teacher', 'A', 'active'),
  ('b1400000-0000-0000-0000-000000000002', 'B14TEACHERB001', 'teacher',
   'b14fffff-0000-0000-0000-000000000001', 'Teacher', 'B', 'active'),
  ('b1400000-0000-0000-0000-000000000003', 'B14ADMIN000001', 'admin',
   'b14fffff-0000-0000-0000-000000000001', 'Fixture', 'Admin', 'active');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('b14fffff-0000-0000-0000-000000000002',
   'b1400000-0000-0000-0000-000000000001', 'enfant', 5, 'B14 groupe A', 1, 10),
  ('b14fffff-0000-0000-0000-000000000003',
   'b1400000-0000-0000-0000-000000000002', 'enfant', 5, 'B14 groupe B', 2, 11);

insert into public.sessions (id, teacher_id, started_at, ended_at)
values
  ('b14fffff-0000-0000-0000-000000000004',
   'b1400000-0000-0000-0000-000000000001', now(), now() + interval '1 hour'),
  ('b14fffff-0000-0000-0000-000000000005',
   'b1400000-0000-0000-0000-000000000002', now(), now() + interval '1 hour');

insert into public.sessions (id, teacher_id, started_at, ended_at, status)
values
  ('b14fffff-0000-0000-0000-000000000009',
   'b1400000-0000-0000-0000-000000000001',
   now() - interval '1 hour', now(), 'ended');

insert into public.session_participants (session_id, profile_id, role)
values
  ('b14fffff-0000-0000-0000-000000000004',
   'b1400000-0000-0000-0000-000000000001', 'teacher'),
  ('b14fffff-0000-0000-0000-000000000005',
   'b1400000-0000-0000-0000-000000000002', 'teacher');

insert into public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy)
values
  ('b14fffff-0000-0000-0000-000000000006',
   'B14 fixture', 'B14', 'quran', 'enseignant_seul', 'jamais');

set local role authenticated;
select set_config('test.uid', 'b1400000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"b14fffff-0000-0000-0000-000000000001"}}',
  true);

do $b14_write_and_monotonicity$
declare
  v_revision integer;
begin
  if pg_catalog.has_table_privilege('authenticated', 'public.session_shared_content', 'INSERT')
     or pg_catalog.has_table_privilege('authenticated', 'public.session_shared_content', 'UPDATE')
     or pg_catalog.has_table_privilege('authenticated', 'public.session_shared_content', 'DELETE')
     or pg_catalog.has_table_privilege('authenticated', 'public.session_shared_content', 'TRUNCATE') then
    raise exception 'B-14: direct write grants remain (relation ACL: %)',
      (select c.relacl::text from pg_catalog.pg_class c
        where c.oid = 'public.session_shared_content'::regclass);
  end if;

  perform public.publier_etat_partage(
    'b14fffff-0000-0000-0000-000000000004',
    'b14fffff-0000-0000-0000-000000000006',
    null,
    '{"resource_id":"b14fffff-0000-0000-0000-000000000006","resource_version_id":null,"type_ancrage":"page","page":4,"sourate":null,"ayah":null,"section_id":null,"fraction":null}',
    null, 'page', '[]', '[]', null, 2
  );

  perform public.publier_etat_partage(
    'b14fffff-0000-0000-0000-000000000004',
    'b14fffff-0000-0000-0000-000000000006',
    null,
    '{"resource_id":"b14fffff-0000-0000-0000-000000000006","resource_version_id":null,"type_ancrage":"page","page":1,"sourate":null,"ayah":null,"section_id":null,"fraction":null}',
    null, 'page', '[]', '[]', null, 1
  );

  select revision into v_revision
    from public.session_shared_content
   where session_id = 'b14fffff-0000-0000-0000-000000000004';
  if v_revision <> 2 then
    raise exception 'B-14: stale revision replaced the stored state';
  end if;

  begin
    perform public.publier_etat_partage(
      'b14fffff-0000-0000-0000-000000000004',
      'b14fffff-0000-0000-0000-000000000006',
      null,
      '{"resource_id":"b14fffff-0000-0000-0000-000000000006","resource_version_id":null,"type_ancrage":"page","page":5,"sourate":null,"ayah":null,"section_id":null,"fraction":null}',
      null, 'page', '[]', '[]', null, 3
    );
  exception when others then
    raise;
  end;
end
$b14_write_and_monotonicity$;

select set_config('test.uid', 'b1400000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"b14fffff-0000-0000-0000-000000000001"}}',
  true);

do $b14_isolation$
declare
  v_count integer;
begin
  select count(*) into v_count
    from public.session_shared_content
   where session_id = 'b14fffff-0000-0000-0000-000000000004';
  if v_count <> 0 then
    raise exception 'B-14: a different teacher read the session state';
  end if;

  begin
    perform public.publier_etat_partage(
      'b14fffff-0000-0000-0000-000000000004',
      'b14fffff-0000-0000-0000-000000000006',
      null,
      '{"resource_id":"b14fffff-0000-0000-0000-000000000006","resource_version_id":null,"type_ancrage":"page","page":7,"sourate":null,"ayah":null,"section_id":null,"fraction":null}',
      null, 'page', '[]', '[]', null, 4
    );
    raise exception 'B-14: another teacher wrote into a session';
  exception when insufficient_privilege then
    null;
  end;
end
$b14_isolation$;

reset role;
-- La fixture déjà clôturée évite de contourner le garde de transitions métier.


set local role authenticated;
select set_config('test.uid', 'b1400000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"b14fffff-0000-0000-0000-000000000001"}}',
  true);
select public.effacer_etat_partage('b14fffff-0000-0000-0000-000000000009');

reset role;
rollback;
