-- B-15 : assignations partagees et annotations de seance sous RLS.
-- Base PostgreSQL jetable apres rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('b1500000-0000-0000-0000-000000000001', 'b15-teacher-a@example.test'),
  ('b1500000-0000-0000-0000-000000000002', 'b15-teacher-b@example.test'),
  ('b1500000-0000-0000-0000-000000000003', 'b15-teacher-disabled@example.test'),
  ('b1500000-0000-0000-0000-000000000004', 'b15-student-a@example.test'),
  ('b1500000-0000-0000-0000-000000000005', 'b15-student-outside@example.test');

insert into public.households (id, timezone)
values ('b15fffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b1500000-0000-0000-0000-000000000001', 'B15TEACHERA001', 'teacher',
   'b15fffff-0000-0000-0000-000000000001', 'Teacher', 'A', 'active'),
  ('b1500000-0000-0000-0000-000000000002', 'B15TEACHERB001', 'teacher',
   'b15fffff-0000-0000-0000-000000000001', 'Teacher', 'B', 'active'),
  ('b1500000-0000-0000-0000-000000000003', 'B15TEACHERD001', 'teacher',
   'b15fffff-0000-0000-0000-000000000001', 'Teacher', 'Disabled', 'disabled'),
  ('b1500000-0000-0000-0000-000000000004', 'B15STUDENTA001', 'student',
   'b15fffff-0000-0000-0000-000000000001', 'Student', 'A', 'active'),
  ('b1500000-0000-0000-0000-000000000005', 'B15STUDENTX001', 'student',
   'b15fffff-0000-0000-0000-000000000001', 'Student', 'Outside', 'active');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('b15fffff-0000-0000-0000-000000000002',
   'b1500000-0000-0000-0000-000000000001', 'enfant', 5, 'B15 groupe A', 1, 10),
  ('b15fffff-0000-0000-0000-000000000003',
   'b1500000-0000-0000-0000-000000000002', 'enfant', 5, 'B15 groupe B', 2, 11),
  ('b15fffff-0000-0000-0000-000000000004',
   'b1500000-0000-0000-0000-000000000003', 'enfant', 5, 'B15 disabled', 3, 12);

insert into public.groupe_membres (groupe_id, student_id)
values
  ('b15fffff-0000-0000-0000-000000000002',
   'b1500000-0000-0000-0000-000000000004');

insert into public.sessions (id, teacher_id, groupe_id, started_at, ended_at)
values
  ('b15fffff-0000-0000-0000-000000000005',
   'b1500000-0000-0000-0000-000000000001',
   'b15fffff-0000-0000-0000-000000000002', now(), now() + interval '1 hour'),
  ('b15fffff-0000-0000-0000-000000000006',
   'b1500000-0000-0000-0000-000000000002',
   'b15fffff-0000-0000-0000-000000000003', now(), now() + interval '1 hour');

insert into public.session_participants (session_id, profile_id, role)
values
  ('b15fffff-0000-0000-0000-000000000005',
   'b1500000-0000-0000-0000-000000000001', 'teacher'),
  ('b15fffff-0000-0000-0000-000000000005',
   'b1500000-0000-0000-0000-000000000004', 'student');

insert into public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy)
values
  ('b15fffff-0000-0000-0000-000000000007',
   'B15 fixture A', 'B15A', 'quran', 'enseignant_seul', 'jamais'),
  ('b15fffff-0000-0000-0000-000000000008',
   'B15 fixture B', 'B15B', 'quran', 'enseignant_seul', 'jamais');

set local role authenticated;
select set_config('test.uid', 'b1500000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"b15fffff-0000-0000-0000-000000000001"}}',
  true);

insert into public.learning_assignment
  (group_id, student_id, resource_id, purpose, instructions, starts_at,
   due_at, created_by, status)
values
  ('b15fffff-0000-0000-0000-000000000002',
   'b1500000-0000-0000-0000-000000000004',
   'b15fffff-0000-0000-0000-000000000007',
   'review', 'B15 fixture', now(), now() + interval '1 day',
   'b1500000-0000-0000-0000-000000000001', 'a_faire');

do $b15_teacher_guards$
declare
  v_count integer;
  v_id uuid;
  v_traits integer;
  v_markers integer;
begin
  begin
    insert into public.learning_assignment
      (group_id, student_id, resource_id, purpose, starts_at, created_by, status)
    values
      ('b15fffff-0000-0000-0000-000000000002',
       'b1500000-0000-0000-0000-000000000005',
       'b15fffff-0000-0000-0000-000000000007',
       'review', now(), 'b1500000-0000-0000-0000-000000000001', 'a_faire');
    raise exception 'B-15: assignment to a non-member was accepted';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into public.annotation_layer
      (id, resource_id, session_id, auteur_profile_id, portee)
    values
      ('b15fffff-0000-0000-0000-000000000009',
       'b15fffff-0000-0000-0000-000000000007',
       'b15fffff-0000-0000-0000-000000000005',
       'b1500000-0000-0000-0000-000000000001', 'temporaire');
    raise exception 'B-15: temporary annotation was persisted';
  exception when check_violation or insufficient_privilege then
    null;
  end;

  insert into public.annotation_layer
    (id, resource_id, session_id, auteur_profile_id, portee)
  values
    ('b15fffff-0000-0000-0000-000000000010',
     'b15fffff-0000-0000-0000-000000000007',
     'b15fffff-0000-0000-0000-000000000005',
     'b1500000-0000-0000-0000-000000000001', 'seance');

  if pg_catalog.has_table_privilege('authenticated', 'public.annotation_marqueur', 'INSERT')
     or pg_catalog.has_table_privilege('authenticated', 'public.annotation_marqueur', 'UPDATE') then
    raise exception 'B-15: marker mutations must use the atomic RPC';
  end if;

  insert into public.annotation_trait (layer_id, ancrage, points, outil, cree_le)
  values
    ('b15fffff-0000-0000-0000-000000000010',
     '{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"type_ancrage":"page","page":2}',
     '[{"x":0.2,"y":0.3}]', 'stylet', now() - interval '1 second');

  perform public.tc_poser_annotation_marqueur(
    'b15fffff-0000-0000-0000-000000000010',
    'b15fffff-0000-0000-0000-000000000011',
    '{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"debut":{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"type_ancrage":"page","page":1},"fin":{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"type_ancrage":"page","page":2}}',
    'learn', 'remplace');
  perform public.tc_poser_annotation_marqueur(
    'b15fffff-0000-0000-0000-000000000010',
    'b15fffff-0000-0000-0000-000000000012',
    '{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"debut":{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"type_ancrage":"page","page":1},"fin":{"resource_id":"b15fffff-0000-0000-0000-000000000007","resource_version_id":null,"type_ancrage":"page","page":2}}',
    'reinforce', 'dernier');

  select count(*), max(id) into v_count, v_id
    from public.annotation_marqueur
   where layer_id = 'b15fffff-0000-0000-0000-000000000010';
  if v_count <> 1 or v_id <> 'b15fffff-0000-0000-0000-000000000012' then
    raise exception 'B-15: a marker on the same range must replace its predecessor';
  end if;

  update public.annotation_marqueur
     set cree_le = now() - interval '2 seconds'
   where id = 'b15fffff-0000-0000-0000-000000000012';
  perform public.tc_annuler_derniere_annotation(
    'b15fffff-0000-0000-0000-000000000010'
  );

  select count(*) into v_traits from public.annotation_trait
   where layer_id = 'b15fffff-0000-0000-0000-000000000010';
  select count(*) into v_markers from public.annotation_marqueur
   where layer_id = 'b15fffff-0000-0000-0000-000000000010';
  if v_traits <> 0 or v_markers <> 1 then
    raise exception 'B-15: undo must remove the latest gesture across both tables';
  end if;

  begin
    insert into public.annotation_layer
      (resource_id, session_id, auteur_profile_id, portee)
    values
      ('b15fffff-0000-0000-0000-000000000007',
       'b15fffff-0000-0000-0000-000000000005',
       'b1500000-0000-0000-0000-000000000002', 'seance');
    raise exception 'B-15: a different teacher wrote into the session';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into public.annotation_trait (layer_id, ancrage, points, outil)
    values
      ('b15fffff-0000-0000-0000-000000000010',
       '{"resource_id":"b15fffff-0000-0000-0000-000000000008","type_ancrage":"page","page":1}',
       '[{"x":0.2,"y":0.3}]', 'stylet');
    raise exception 'B-15: a trait for another resource was accepted';
  exception when check_violation then
    null;
  end;
end
$b15_teacher_guards$;

select set_config('test.uid', 'b1500000-0000-0000-0000-000000000004', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"student","household_id":"b15fffff-0000-0000-0000-000000000001"}}',
  true);

do $b15_student_read_only$
declare
  v_count integer;
begin
  select count(*) into v_count from public.learning_assignment
   where group_id = 'b15fffff-0000-0000-0000-000000000002';
  if v_count <> 1 then
    raise exception 'B-15: active student must read the assigned work';
  end if;

  update public.learning_assignment set status = 'fait'
   where group_id = 'b15fffff-0000-0000-0000-000000000002';
  get diagnostics v_count = row_count;
  if v_count <> 0 then
    raise exception 'B-15: student changed a shared assignment status';
  end if;

  select count(*) into v_count from public.annotation_layer
   where id = 'b15fffff-0000-0000-0000-000000000010';
  if v_count <> 1 then
    raise exception 'B-15: a session participant must read session annotations';
  end if;
end
$b15_student_read_only$;

reset role;
rollback;
