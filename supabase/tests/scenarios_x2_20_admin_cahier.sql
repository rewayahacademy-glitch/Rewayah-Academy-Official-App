BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c2200000-0000-0000-0000-000000000001', 'x220-admin@example.test'),
  ('c2200000-0000-0000-0000-000000000002', 'x220-teacher@example.test'),
  ('c2200000-0000-0000-0000-000000000003', 'x220-student-a@example.test'),
  ('c2200000-0000-0000-0000-000000000004', 'x220-student-b@example.test'),
  ('c2200000-0000-0000-0000-000000000005', 'x220-accountant@example.test'),
  ('c2200000-0000-0000-0000-000000000006', 'x220-guardian@example.test'),
  ('c2200000-0000-0000-0000-000000000007', 'x220-controller@example.test'),
  ('c2200000-0000-0000-0000-000000000008', 'x220-disabled-admin@example.test');

INSERT INTO public.households (id) VALUES
  ('c2200000-0000-0000-0000-000000000101'),
  ('c2200000-0000-0000-0000-000000000102');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('c2200000-0000-0000-0000-000000000001', 'X220-ADMIN', 'admin', 'c2200000-0000-0000-0000-000000000101', 'Direction', 'Test', 'active'),
  ('c2200000-0000-0000-0000-000000000002', 'X220-TEACHER', 'teacher', 'c2200000-0000-0000-0000-000000000101', 'Enseignant', 'Test', 'provisional_active'),
  ('c2200000-0000-0000-0000-000000000003', 'X220-STUDENT-A', 'student', 'c2200000-0000-0000-0000-000000000101', 'Eleve A', 'Test', 'active'),
  ('c2200000-0000-0000-0000-000000000004', 'X220-STUDENT-B', 'student', 'c2200000-0000-0000-0000-000000000101', 'Eleve B', 'Test', 'active'),
  ('c2200000-0000-0000-0000-000000000005', 'X220-ACCOUNTANT', 'accountant', 'c2200000-0000-0000-0000-000000000101', 'Comptable', 'Test', 'active'),
  ('c2200000-0000-0000-0000-000000000006', 'X220-GUARDIAN', 'guardian', 'c2200000-0000-0000-0000-000000000101', 'Tuteur', 'Test', 'active'),
  ('c2200000-0000-0000-0000-000000000007', 'X220-CONTROLLER', 'controller', 'c2200000-0000-0000-0000-000000000101', 'Controleur', 'Test', 'active'),
  ('c2200000-0000-0000-0000-000000000008', 'X220-DISABLED-ADMIN', 'admin', 'c2200000-0000-0000-0000-000000000101', 'Direction', 'Desactivee', 'disabled');

INSERT INTO public.student_profiles (profile_id) VALUES
  ('c2200000-0000-0000-0000-000000000003'),
  ('c2200000-0000-0000-0000-000000000004');
INSERT INTO public.teacher_profiles (profile_id) VALUES
  ('c2200000-0000-0000-0000-000000000002');
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
VALUES ('c2200000-0000-0000-0000-000000000201',
  'c2200000-0000-0000-0000-000000000002', 'enfant', 5, 'X2-20 classe test', 1, 10);
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at) VALUES
  ('c2200000-0000-0000-0000-000000000201', 'c2200000-0000-0000-0000-000000000003', now() - interval '2 days'),
  ('c2200000-0000-0000-0000-000000000201', 'c2200000-0000-0000-0000-000000000004', now() - interval '2 days');
INSERT INTO public.sessions
  (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('c2200000-0000-0000-0000-000000000301',
  'c2200000-0000-0000-0000-000000000002', now() - interval '2 hours',
  now() - interval '1 hour', 'ended', 'standard', 'c2200000-0000-0000-0000-000000000201');
INSERT INTO public.lesson_reports
  (session_id, idempotency_key, author_profile_id, content)
VALUES ('c2200000-0000-0000-0000-000000000301', 'x220-admin-cahier',
  'c2200000-0000-0000-0000-000000000002',
  '{"version":1,"session_id":"c2200000-0000-0000-0000-000000000301","note_groupe":"ne doit pas sortir","eleves":[{"student_id":"c2200000-0000-0000-0000-000000000003","confirme":true,"performance":"acquis","motif_exception":"note interne A"},{"student_id":"c2200000-0000-0000-0000-000000000004","confirme":true,"performance":"maitrise","motif_exception":"note interne B"}]}');

DO $scenario$
DECLARE
  v_admin uuid := 'c2200000-0000-0000-0000-000000000001';
  v_result jsonb;
  v_before bigint;
  v_after bigint;
  v_uid uuid;
  v_role text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_admin::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);

  v_result := public.lire_cahier_admin(
    'c2200000-0000-0000-0000-000000000301',
    'c2200000-0000-0000-0000-000000000003');
  IF v_result->>'eleve_id' <> 'c2200000-0000-0000-0000-000000000003'
     OR v_result::text LIKE '%c2200000-0000-0000-0000-000000000004%'
     OR v_result::text LIKE '%ne doit pas sortir%'
     OR v_result->'details_internes'->0->>'texte' <> 'note interne A' THEN
    RAISE EXCEPTION 'X2-20 ADM: le cahier sort du périmètre de l''élève demandé';
  END IF;
  SELECT count(*) INTO v_before FROM public.audit_logs
   WHERE action = 'cahier_admin_lu'
     AND row_id = 'c2200000-0000-0000-0000-000000000301:c2200000-0000-0000-0000-000000000003';
  PERFORM public.lire_cahier_admin(
    'c2200000-0000-0000-0000-000000000301',
    'c2200000-0000-0000-0000-000000000003');
  SELECT count(*) INTO v_after FROM public.audit_logs
   WHERE action = 'cahier_admin_lu'
     AND row_id = 'c2200000-0000-0000-0000-000000000301:c2200000-0000-0000-0000-000000000003';
  IF v_after <> v_before + 1 THEN
    RAISE EXCEPTION 'X2-20 ADM: une lecture autorisée n''a pas été auditée';
  END IF;

  v_result := public.comptes_rendus_classe('c2200000-0000-0000-0000-000000000201', 1, NULL);
  IF (v_result->>'total')::integer <> 2
     OR jsonb_array_length(v_result->'lignes') <> 2 THEN
    RAISE EXCEPTION 'X2-20 ADM: total de classe incorrect';
  END IF;
  v_result := public.comptes_rendus_classe(
    'c2200000-0000-0000-0000-000000000201', 2147483647, NULL);
  IF (v_result->>'page')::integer <> 42949672
     OR jsonb_array_length(v_result->'lignes') <> 0 THEN
    RAISE EXCEPTION 'X2-20 ADM: grande page non plafonnee';
  END IF;

  PERFORM set_config('request.jwt.claim.sub',
    'c2200000-0000-0000-0000-000000000008', true);
  BEGIN
    PERFORM public.lire_cahier_admin(
      'c2200000-0000-0000-0000-000000000301',
      'c2200000-0000-0000-0000-000000000003');
    RAISE EXCEPTION 'X2-20 ADM: admin désactivé autorisé à lire le cahier';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;

  FOREACH v_uid IN ARRAY ARRAY[
    'c2200000-0000-0000-0000-000000000005'::uuid,
    'c2200000-0000-0000-0000-000000000006'::uuid,
    'c2200000-0000-0000-0000-000000000003'::uuid,
    'c2200000-0000-0000-0000-000000000007'::uuid
  ] LOOP
    SELECT p.role::text INTO v_role FROM public.profiles p WHERE p.id = v_uid;
    PERFORM set_config('request.jwt.claim.sub', v_uid::text, true);
    PERFORM set_config('request.jwt.claims',
      jsonb_build_object('app_metadata', jsonb_build_object('role', v_role))::text, true);
    BEGIN
      PERFORM public.lire_cahier_admin(
        'c2200000-0000-0000-0000-000000000301',
        'c2200000-0000-0000-0000-000000000003');
      RAISE EXCEPTION 'X2-20 ADM: rôle % autorisé à lire le cahier', v_role;
    EXCEPTION WHEN insufficient_privilege THEN
      NULL;
    END;
  END LOOP;

  FOREACH v_uid IN ARRAY ARRAY[
    'c2200000-0000-0000-0000-000000000008'::uuid,
    'c2200000-0000-0000-0000-000000000005'::uuid,
    'c2200000-0000-0000-0000-000000000006'::uuid,
    'c2200000-0000-0000-0000-000000000003'::uuid,
    'c2200000-0000-0000-0000-000000000007'::uuid
  ] LOOP
    SELECT p.role::text INTO v_role FROM public.profiles p WHERE p.id = v_uid;
    PERFORM set_config('request.jwt.claim.sub', v_uid::text, true);
    PERFORM set_config('request.jwt.claims',
      jsonb_build_object('app_metadata', jsonb_build_object('role', v_role))::text, true);
    BEGIN
      PERFORM public.comptes_rendus_classe(
        'c2200000-0000-0000-0000-000000000201', 1, NULL);
      RAISE EXCEPTION 'X2-20 ADM: role % autorise a lister les cahiers', v_role;
    EXCEPTION WHEN insufficient_privilege THEN
      NULL;
    END;
  END LOOP;
END;
$scenario$;

ROLLBACK;
