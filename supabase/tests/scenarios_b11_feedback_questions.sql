-- B-11 feedback : echantillonnage stable, rotation par question, aucune lecture detaillee.
begin;

insert into auth.users (id, email) values
  ('f1650000-0000-0000-0000-000000000001', 'f1-feedback-teacher@example.test'),
  ('f1650000-0000-0000-0000-000000000002', 'f1-feedback-student@example.test');
insert into public.households (id, timezone)
values ('f16fffff-0000-0000-0000-000000000001', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('f1650000-0000-0000-0000-000000000001', 'F1FEEDBACKTEACH', 'teacher',
   'f16fffff-0000-0000-0000-000000000001', 'Fixture', 'Teacher', 'active'),
  ('f1650000-0000-0000-0000-000000000002', 'F1FEEDBACKSTUD', 'student',
   'f16fffff-0000-0000-0000-000000000001', 'Fixture', 'Student', 'active');
insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('f1650000-0000-0000-0000-000000000002', 'minor', 'child');
insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('f16fffff-0000-0000-0000-000000000002',
        'f1650000-0000-0000-0000-000000000001', 'enfant', 5,
        'Feedback fixture', 1, 10);

-- Recherche deterministe d'une seance echantillonnee par le hash et le sel de test.
do $feedback_seed$
declare
  v_session uuid;
  v_question jsonb;
  i integer;
begin
  for i in 1..80 loop
    v_session := ('f16fffff-0000-0000-0000-' || pg_catalog.lpad(i::text, 12, '0'))::uuid;
    insert into public.sessions (id, teacher_id, groupe_id, started_at, ended_at)
    values (v_session, 'f1650000-0000-0000-0000-000000000001',
            'f16fffff-0000-0000-0000-000000000002',
            pg_catalog.now() + pg_catalog.now() + pg_catalog.make_interval(days => i),
            pg_catalog.now() + pg_catalog.make_interval(days => i, hours => 1));
    insert into public.session_participants(session_id, profile_id, role)
    values (v_session, 'f1650000-0000-0000-0000-000000000002', 'student');
  end loop;

  perform pg_catalog.set_config('test.uid', 'f1650000-0000-0000-0000-000000000002', true);
  perform pg_catalog.set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"f16fffff-0000-0000-0000-000000000001"}}', true);
  for v_session in
    select s.id from public.sessions s
    where s.groupe_id = 'f16fffff-0000-0000-0000-000000000002'
    order by s.started_at
  loop
    v_question := public.question_feedback_pour(v_session);
    if v_question is not null then
      perform public.soumettre_feedback(v_session, v_question ->> 'id', 'bien');
      begin
        perform public.soumettre_feedback(v_session, v_question ->> 'id', 'bien');
        raise exception 'B-11 feedback: double depot accepte';
      exception when unique_violation then null;
      end;
      exit;
    end if;
  end loop;
  if not exists (
    select 1 from public.session_feedback
    where groupe_id = 'f16fffff-0000-0000-0000-000000000002'
  ) then
    raise exception 'B-11 feedback: aucun echantillon dans 80 seances';
  end if;
end
$feedback_seed$;

-- Reponses de fixture pour verifier que l'agregat courant ne melange pas les questions.
do $feedback_aggregate_fixture$
declare
  v_session uuid;
  i integer;
begin
  perform pg_catalog.set_config('test.uid', 'f1650000-0000-0000-0000-000000000002', true);
  for i in 81..90 loop
    v_session := ('f16fffff-0000-0000-0000-' || pg_catalog.lpad(i::text, 12, '0'))::uuid;
    insert into public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
    values (v_session, 'f1650000-0000-0000-0000-000000000001',
            'f16fffff-0000-0000-0000-000000000002',
            pg_catalog.now() + pg_catalog.make_interval(hours => i),
            pg_catalog.now() + pg_catalog.make_interval(hours => i + 1), 'scheduled');
    insert into public.session_participants(session_id, profile_id, role)
    values (v_session, 'f1650000-0000-0000-0000-000000000002', 'student');
    insert into public.session_feedback(session_id, groupe_id, question_id, reponse)
    values (v_session, 'f16fffff-0000-0000-0000-000000000002',
            case when i <= 85 then 'comprehension' else 'rythme' end, 'bien');
  end loop;
end
$feedback_aggregate_fixture$;

set local role authenticated;
select pg_catalog.set_config('test.uid', 'f1650000-0000-0000-0000-000000000001', true);
select pg_catalog.set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"f16fffff-0000-0000-0000-000000000001"}}', true);

do $feedback_teacher$
declare
  v_result jsonb;
  v_count integer;
  v_question_count integer;
begin
  v_result := public.tendance_feedback_comprehension('f16fffff-0000-0000-0000-000000000002');
  if (v_result ->> 'nombre_echantillons')::integer < 5 or (v_result ->> 'nombre_echantillons')::integer > 6
     or v_result ->> 'visible_par_enseignant' <> 'true'
     or (v_result -> 'repartition' ->> 'bien')::numeric <> 1 then
    raise exception 'B-11 feedback: agregat comprehension invalide (%)', v_result;
  end if;

  select count(*) into v_question_count from public.tendance_feedback_v
  where groupe_id = 'f16fffff-0000-0000-0000-000000000002'
    and question_id <> 'comprehension';
  if v_question_count <> 0 then
    raise exception 'B-11 feedback: une autre question est exposee dans la tendance';
  end if;

  begin
    select count(*) into v_count from public.session_feedback;
    raise exception 'B-11 feedback: lecture individuelle autorisee';
  exception when insufficient_privilege then null;
  end;
end
$feedback_teacher$;

reset role;
rollback;
