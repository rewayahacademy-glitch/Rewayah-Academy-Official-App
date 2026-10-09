-- B-08 — le cahier famille est une projection publiée, propre au foyer.
-- Aucun accès à lesson_reports ni aux projections administratives.
BEGIN;

INSERT INTO auth.users (id, email)
VALUES
  ('b0800000-0000-0000-0000-000000000001', 'b08-teacher@example.test'),
  ('b0800000-0000-0000-0000-000000000002', 'b08-guardian@example.test'),
  ('b0800000-0000-0000-0000-000000000003', 'b08-student@example.test'),
  ('b0800000-0000-0000-0000-000000000004', 'b08-other-guardian@example.test'),
  ('b0800000-0000-0000-0000-000000000005', 'b08-other-student@example.test'),
  ('b0800000-0000-0000-0000-000000000006', 'b08-other-teacher@example.test');

INSERT INTO public.households (id, timezone, status)
VALUES
  ('b0800000-0000-0000-0000-000000000101', 'Europe/Paris', 'active'),
  ('b0800000-0000-0000-0000-000000000102', 'Europe/Paris', 'active');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('b0800000-0000-0000-0000-000000000001', 'B08-TEACHER', 'teacher',
   NULL, 'Enseignant', 'A', 'active'::public.account_status, 'male'),
  ('b0800000-0000-0000-0000-000000000002', 'B08-GUARDIAN', 'guardian',
   'b0800000-0000-0000-0000-000000000101', 'Parent', 'A', 'active'::public.account_status, 'female'),
  ('b0800000-0000-0000-0000-000000000003', 'B08-STUDENT', 'student',
   'b0800000-0000-0000-0000-000000000101', 'Élève', 'A', 'active'::public.account_status, 'female'),
  ('b0800000-0000-0000-0000-000000000004', 'B08-OTHER-GUARDIAN', 'guardian',
   'b0800000-0000-0000-0000-000000000102', 'Parent', 'B', 'active'::public.account_status, 'male'),
  ('b0800000-0000-0000-0000-000000000005', 'B08-OTHER-STUDENT', 'student',
   'b0800000-0000-0000-0000-000000000102', 'Élève', 'B', 'active'::public.account_status, 'male'),
  ('b0800000-0000-0000-0000-000000000006', 'B08-OTHER-TEACHER', 'teacher',
   NULL, 'Enseignant', 'B', 'active'::public.account_status, 'female');

UPDATE public.households SET primary_guardian_id = 'b0800000-0000-0000-0000-000000000002'
WHERE id = 'b0800000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id = 'b0800000-0000-0000-0000-000000000004'
WHERE id = 'b0800000-0000-0000-0000-000000000102';

INSERT INTO public.student_profiles (profile_id, student_type, level)
VALUES
  ('b0800000-0000-0000-0000-000000000003', 'minor', 'lecture_lente'),
  ('b0800000-0000-0000-0000-000000000005', 'minor', 'debut_lettres');

INSERT INTO public.teacher_profiles (profile_id, country)
VALUES
  ('b0800000-0000-0000-0000-000000000001', 'FR'),
  ('b0800000-0000-0000-0000-000000000006', 'SA');

INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES
  ('b0800000-0000-0000-0000-000000000201',
   'b0800000-0000-0000-0000-000000000001', 'enfant', 5, 'B08 classe A', 1, 18, 'Europe/Paris'),
  ('b0800000-0000-0000-0000-000000000202',
   'b0800000-0000-0000-0000-000000000006', 'enfant', 5, 'B08 classe B', 2, 18, 'Europe/Paris');

INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES
  ('b0800000-0000-0000-0000-000000000201', 'b0800000-0000-0000-0000-000000000003'),
  ('b0800000-0000-0000-0000-000000000202', 'b0800000-0000-0000-0000-000000000005');

INSERT INTO public.sessions
  (id, teacher_id, started_at, ended_at, status, session_type,
   credit_amount_minor, currency, prayer_pause_minutes, groupe_id)
VALUES
  ('b0800000-0000-0000-0000-000000000301',
   'b0800000-0000-0000-0000-000000000001',
   now() - interval '2 hours', now() - interval '1 hour',
   'ended'::public.session_status, 'standard', 0, 'EUR', 0,
   'b0800000-0000-0000-0000-000000000201');

DO $scenario$
DECLARE
  v_teacher uuid := 'b0800000-0000-0000-0000-000000000001';
  v_other_teacher uuid := 'b0800000-0000-0000-0000-000000000006';
  v_guardian uuid := 'b0800000-0000-0000-0000-000000000002';
  v_student uuid := 'b0800000-0000-0000-0000-000000000003';
  v_other_guardian uuid := 'b0800000-0000-0000-0000-000000000004';
  v_other_student uuid := 'b0800000-0000-0000-0000-000000000005';
  v_session uuid := 'b0800000-0000-0000-0000-000000000301';
  v_result jsonb;
  v_count integer;
  v_denied boolean;
BEGIN
  PERFORM set_config('test.uid', v_teacher::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'teacher'))::text, true);

  PERFORM public.enregistrer_resume_seance(
    v_session, v_student, 'Lecture régulière; revoir les liaisons.', NULL, false
  );

  IF (SELECT r.publie_le FROM public.seance_resumes r
      WHERE r.session_id = v_session AND r.student_id = v_student) IS NOT NULL THEN
    RAISE EXCEPTION 'B-08: le brouillon a été publié sans geste explicite';
  END IF;

  PERFORM set_config('test.uid', v_guardian::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0800000-0000-0000-0000-000000000101'))::text, true);
  v_result := public.progression_famille(v_student);
  IF jsonb_array_length(v_result->'seances') <> 0
     OR public.resume_seance_famille(v_session, v_student) IS NOT NULL THEN
    RAISE EXCEPTION 'B-08: un brouillon est visible au foyer avant publication';
  END IF;

  PERFORM set_config('test.uid', v_teacher::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'teacher'))::text, true);
  v_denied := false;
  BEGIN
    PERFORM public.enregistrer_resume_seance(
      v_session, v_other_student, 'Résumé hors classe.', NULL, true
    );
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: l''enseignant a écrit pour un élève hors de sa classe';
  END IF;

  PERFORM public.enregistrer_resume_seance(
    v_session, v_student, 'Lecture régulière; revoir les liaisons.', NULL, true
  );

  PERFORM set_config('test.uid', v_guardian::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0800000-0000-0000-0000-000000000101'))::text, true);

  v_result := public.progression_famille(v_student);
  IF NOT (v_result ? 'niveau_humain')
     OR jsonb_typeof(v_result->'jalons') <> 'array'
     OR v_result->>'niveau_humain' = 'lecture_lente'
     OR jsonb_array_length(v_result->'seances') <> 1
     OR v_result->'seances'->0->>'texte_famille'
        <> 'Lecture régulière; revoir les liaisons.'
     OR v_result->'seances'->0->>'publie_le' IS NULL
     OR public.resume_seance_famille(v_session, v_student)
        <> 'Lecture régulière; revoir les liaisons.' THEN
    RAISE EXCEPTION 'B-08: la projection famille publiée est incomplète';
  END IF;

  v_denied := false;
  BEGIN
    PERFORM public.progression_famille(v_other_student);
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: la RPC famille a divulgué un autre foyer';
  END IF;
  v_denied := false;
  BEGIN
    PERFORM public.resume_seance_famille(v_session, v_student);
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: la RPC de résumé a divulgué un autre foyer';
  END IF;

  PERFORM set_config('test.uid', v_other_teacher::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'teacher'))::text, true);
  v_denied := false;
  BEGIN
    PERFORM public.enregistrer_resume_seance(
      v_session, v_student, 'Un autre enseignant ne peut pas publier.', NULL, true
    );
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: un enseignant non assigné a publié le résumé';
  END IF;
END
$scenario$;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0800000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b0800000-0000-0000-0000-000000000101"}}',
  true);
DO $rls_foyer$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.seance_resumes r
  WHERE r.session_id = 'b0800000-0000-0000-0000-000000000301'
    AND r.student_id = 'b0800000-0000-0000-0000-000000000003';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-08: le foyer ne lit pas le résumé publié de son élève';
  END IF;
END
$rls_foyer$;

SELECT set_config('test.uid', 'b0800000-0000-0000-0000-000000000004', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b0800000-0000-0000-0000-000000000102"}}',
  true);
DO $rls_autre_foyer$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.seance_resumes r
  WHERE r.session_id = 'b0800000-0000-0000-0000-000000000301'
    AND r.student_id = 'b0800000-0000-0000-0000-000000000003';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'B-08: RLS divulgue le résumé à un autre foyer';
  END IF;
END
$rls_autre_foyer$;
RESET ROLE;
ROLLBACK;
