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
  ('b0800000-0000-0000-0000-000000000006', 'b08-other-teacher@example.test'),
  ('b0800000-0000-0000-0000-000000000007', 'b08-admin@example.test');

INSERT INTO public.households (id, timezone, status)
VALUES
  ('b0800000-0000-0000-0000-000000000101', 'Europe/Paris', 'active'),
  ('b0800000-0000-0000-0000-000000000102', 'Europe/Paris', 'active');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('b0800000-0000-0000-0000-000000000001', 'B08-TEACHER', 'teacher',
   NULL, 'Enseignant', 'A', 'provisional_active'::public.account_status, 'male'),
  ('b0800000-0000-0000-0000-000000000002', 'B08-GUARDIAN', 'guardian',
   'b0800000-0000-0000-0000-000000000101', 'Parent', 'A', 'active'::public.account_status, 'female'),
  ('b0800000-0000-0000-0000-000000000003', 'B08-STUDENT', 'student',
   'b0800000-0000-0000-0000-000000000101', 'Élève', 'A', 'active'::public.account_status, 'female'),
  ('b0800000-0000-0000-0000-000000000004', 'B08-OTHER-GUARDIAN', 'guardian',
   'b0800000-0000-0000-0000-000000000102', 'Parent', 'B', 'active'::public.account_status, 'male'),
  ('b0800000-0000-0000-0000-000000000005', 'B08-OTHER-STUDENT', 'student',
   'b0800000-0000-0000-0000-000000000102', 'Élève', 'B', 'active'::public.account_status, 'male'),
  ('b0800000-0000-0000-0000-000000000006', 'B08-OTHER-TEACHER', 'teacher',
   NULL, 'Enseignant', 'B', 'provisional_active'::public.account_status, 'female'),
  ('b0800000-0000-0000-0000-000000000007', 'B08-ADMIN', 'admin',
   NULL, 'Direction', 'A', 'active'::public.account_status, 'female');

UPDATE public.households SET primary_guardian_id = 'b0800000-0000-0000-0000-000000000002'
WHERE id = 'b0800000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id = 'b0800000-0000-0000-0000-000000000004'
WHERE id = 'b0800000-0000-0000-0000-000000000102';

INSERT INTO public.student_profiles (profile_id, student_type, level)
VALUES
  ('b0800000-0000-0000-0000-000000000003', 'minor', 'lecture_lente'),
  ('b0800000-0000-0000-0000-000000000005', 'minor', 'debut_lettres');

INSERT INTO public.programme_versions
  (id, statut, numero_version, cree_par, publiee_par, publiee_at)
VALUES
  ('b0800000-0000-0000-0000-000000000401', 'publiee', 99991,
   'b0800000-0000-0000-0000-000000000001',
   'b0800000-0000-0000-0000-000000000001', now()),
  ('b0800000-0000-0000-0000-000000000402', 'brouillon', 99992,
   'b0800000-0000-0000-0000-000000000001', NULL, NULL),
  ('b0800000-0000-0000-0000-000000000403', 'archivee', 99990,
   'b0800000-0000-0000-0000-000000000001',
   'b0800000-0000-0000-0000-000000000001', now());

INSERT INTO public.programme_niveaux
  (id, version_id, code_technique, nom_humain, cycle, ordre)
VALUES
  ('b0800000-0000-0000-0000-000000000411',
   'b0800000-0000-0000-0000-000000000401', 'lecture_lente',
   'Lecture lente', 'Lecture', 1),
  ('b0800000-0000-0000-0000-000000000412',
   'b0800000-0000-0000-0000-000000000401', 'autre_niveau',
   'Autre niveau', 'Lecture', 2),
  ('b0800000-0000-0000-0000-000000000413',
   'b0800000-0000-0000-0000-000000000402', 'lecture_lente',
   'Brouillon privé', 'Lecture', 1),
  ('b0800000-0000-0000-0000-000000000414',
   'b0800000-0000-0000-0000-000000000403', 'lecture_lente',
   'Archivé privé', 'Lecture', 1);

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

INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at)
VALUES
  ('b0800000-0000-0000-0000-000000000201',
   'b0800000-0000-0000-0000-000000000003', now() - interval '3 hours'),
  ('b0800000-0000-0000-0000-000000000202',
   'b0800000-0000-0000-0000-000000000005', now() - interval '3 hours');

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
  PERFORM set_config('request.jwt.claim.sub', v_teacher::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'teacher'))::text, true);

  PERFORM public.enregistrer_resume_seance(
    v_session, v_student, 'Lecture régulière; revoir les liaisons.', NULL, false
  );

  IF (SELECT r.publie_le FROM public.seance_resumes r
      WHERE r.session_id = v_session AND r.student_id = v_student) IS NOT NULL THEN
    RAISE EXCEPTION 'B-08: le brouillon a été publié sans geste explicite';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_guardian::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0800000-0000-0000-0000-000000000101'))::text, true);
  v_result := public.progression_famille(v_student);
  IF jsonb_array_length(v_result->'seances') <> 0
     OR public.resume_seance_famille(v_session, v_student) IS NOT NULL THEN
    RAISE EXCEPTION 'B-08: un brouillon est visible au foyer avant publication';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_teacher::text, true);
  PERFORM set_config('request.jwt.claims',
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

  v_denied := false;
  BEGIN
    PERFORM public.enregistrer_resume_seance(
      v_session, v_student, 'Jalon du brouillon.',
      'b0800000-0000-0000-0000-000000000413', true
    );
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: un jalon d''une version brouillon a été accepté';
  END IF;

  v_denied := false;
  BEGIN
    PERFORM public.enregistrer_resume_seance(
      v_session, v_student, 'Jalon archivé.',
      'b0800000-0000-0000-0000-000000000414', true
    );
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: un jalon d''une version archivée a été accepté';
  END IF;

  v_denied := false;
  BEGIN
    PERFORM public.enregistrer_resume_seance(
      v_session, v_student, 'Jalon d''un autre niveau.',
      'b0800000-0000-0000-0000-000000000412', true
    );
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: un jalon incohérent avec le niveau a été accepté';
  END IF;

  PERFORM public.enregistrer_resume_seance(
    v_session, v_student, 'Lecture régulière; revoir les liaisons.',
    'b0800000-0000-0000-0000-000000000411', true
  );

  v_denied := false;
  BEGIN
    PERFORM public.enregistrer_resume_seance(
      v_session, v_student, 'BROUILLON PAS PRÊT', NULL, false
    );
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied OR NOT EXISTS (
    SELECT 1 FROM public.seance_resumes r
    WHERE r.session_id = v_session AND r.student_id = v_student
      AND r.texte_famille = 'Lecture régulière; revoir les liaisons.'
      AND r.publie_le IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'B-08: un brouillon a remplacé le résumé déjà publié';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_guardian::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0800000-0000-0000-0000-000000000101'))::text, true);

  v_result := public.progression_famille(v_student);
  IF NOT (v_result ? 'niveau_humain')
     OR jsonb_typeof(v_result->'jalons') <> 'array'
     OR v_result->>'niveau_humain' <> 'Lecture lente'
     OR v_result::text LIKE '%lecture_lente%'
     OR v_result::text LIKE '%Brouillon privé%'
     OR v_result::text LIKE '%Archivé privé%'
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
  PERFORM set_config('request.jwt.claim.sub', v_other_guardian::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0800000-0000-0000-0000-000000000102'))::text, true);
  v_denied := false;
  BEGIN
    PERFORM public.resume_seance_famille(v_session, v_student);
  EXCEPTION WHEN OTHERS THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-08: la RPC de résumé a divulgué un autre foyer';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_other_teacher::text, true);
  PERFORM set_config('request.jwt.claims',
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
SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims',
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

SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000004', true);
SELECT set_config('request.jwt.claims',
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

SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"teacher"}}', true);
SELECT public.enregistrer_resume_seance(
  'b0800000-0000-0000-0000-000000000301',
  'b0800000-0000-0000-0000-000000000003',
  'Lecture régulière; revoir les liaisons.', NULL, true
);

SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"b0800000-0000-0000-0000-000000000101"}}', true);
SET LOCAL ROLE authenticated;
DO $publication_auditee$
DECLARE
  v_count integer;
BEGIN
  IF public.resume_seance_famille(
    'b0800000-0000-0000-0000-000000000301',
    'b0800000-0000-0000-0000-000000000003'
  ) IS DISTINCT FROM 'Lecture régulière; revoir les liaisons.' THEN
    RAISE EXCEPTION 'B-08: la publication courante est absente de la RPC';
  END IF;
  SELECT count(*) INTO v_count FROM public.seance_resumes r
  WHERE r.session_id = 'b0800000-0000-0000-0000-000000000301'
    AND r.student_id = 'b0800000-0000-0000-0000-000000000003';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-08: RLS ne montre pas exactement la publication courante';
  END IF;
END
$publication_auditee$;

-- audit_logs n'est lisible que par admin/contrôleur via RLS. Vérifier la trace
-- avec le rôle propriétaire du scénario, après les assertions familiales qui
-- restent exécutées sous authenticated.
RESET ROLE;
DO $publication_audit$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.audit_logs a
  WHERE a.action = 'resume_seance_famille_publie'
    AND a.table_name = 'seance_resumes'
    AND a.row_id = 'b0800000-0000-0000-0000-000000000301:b0800000-0000-0000-0000-000000000003';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-08: la publication n''a pas produit une entrée d''audit';
  END IF;
END
$publication_audit$;

RESET ROLE;
SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000007', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $publication_revoquee$
DECLARE
  v_first jsonb;
  v_replay jsonb;
  v_denied boolean := false;
BEGIN
  v_first := public.revoquer_resume_seance(
    'b0800000-0000-0000-0000-000000000301',
    'b0800000-0000-0000-0000-000000000003', '1', 'b08-revoquer-001'
  );
  v_replay := public.revoquer_resume_seance(
    'b0800000-0000-0000-0000-000000000301',
    'b0800000-0000-0000-0000-000000000003', '1', 'b08-revoquer-001'
  );
  IF v_first IS DISTINCT FROM v_replay OR v_first->>'etat' <> 'revoque' THEN
    RAISE EXCEPTION 'X2-20: la révocation n''est pas idempotente';
  END IF;
  PERFORM set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000002', true);
  PERFORM set_config('request.jwt.claims',
    '{"app_metadata":{"role":"guardian","household_id":"b0800000-0000-0000-0000-000000000101"}}', true);
  v_denied := false;
  BEGIN
    PERFORM public.revoquer_resume_seance(
      'b0800000-0000-0000-0000-000000000301',
      'b0800000-0000-0000-0000-000000000003', '2', 'b08-guardian-revoke'
    );
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'X2-20: un tuteur a révoqué un compte rendu'; END IF;
END
$publication_revoquee$;

SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"b0800000-0000-0000-0000-000000000101"}}', true);
DO $retrait_famille$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.seance_resumes
   WHERE session_id = 'b0800000-0000-0000-0000-000000000301'
     AND student_id = 'b0800000-0000-0000-0000-000000000003';
  IF v_count <> 0 OR public.resume_seance_famille(
    'b0800000-0000-0000-0000-000000000301',
    'b0800000-0000-0000-0000-000000000003'
  ) IS NOT NULL THEN
    RAISE EXCEPTION 'X2-20: une famille lit encore un compte rendu révoqué';
  END IF;
  IF jsonb_array_length(public.progression_famille(
    'b0800000-0000-0000-0000-000000000003')->'seances') <> 0 THEN
    RAISE EXCEPTION 'X2-20: progression_famille expose un compte rendu révoqué';
  END IF;
END
$retrait_famille$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000007', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $publication_manuelle$
DECLARE v_result jsonb;
BEGIN
  v_result := public.publier_resume_seance(
    'b0800000-0000-0000-0000-000000000301',
    'b0800000-0000-0000-0000-000000000003', '2', 'b08-publier-001'
  );
  IF v_result->>'etat' <> 'partageManuel' OR v_result->>'version' <> '3' THEN
    RAISE EXCEPTION 'X2-20: la publication manuelle n''a pas été confirmée';
  END IF;
END
$publication_manuelle$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', 'b0800000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"b0800000-0000-0000-0000-000000000101"}}', true);
SET LOCAL ROLE authenticated;
DO $publication_retablie$
BEGIN
  IF public.resume_seance_famille(
    'b0800000-0000-0000-0000-000000000301',
    'b0800000-0000-0000-0000-000000000003'
  ) IS DISTINCT FROM 'Lecture régulière; revoir les liaisons.' THEN
    RAISE EXCEPTION 'X2-20: la republication manuelle ne rétablit pas la lecture';
  END IF;
END
$publication_retablie$;
RESET ROLE;
DO $audit_retrait$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.audit_logs a
   WHERE a.action = 'resume_seance_famille_revoque'
     AND a.table_name = 'seance_resumes'
     AND a.row_id = 'b0800000-0000-0000-0000-000000000301:b0800000-0000-0000-0000-000000000003';
  IF v_count <> 1 THEN RAISE EXCEPTION 'X2-20: la révocation n''est pas auditée'; END IF;
  SELECT count(*) INTO v_count FROM public.audit_logs a
   WHERE a.action = 'resume_seance_famille_publie_manuellement'
     AND a.table_name = 'seance_resumes'
     AND a.row_id = 'b0800000-0000-0000-0000-000000000301:b0800000-0000-0000-0000-000000000003';
  IF v_count <> 1 THEN RAISE EXCEPTION 'X2-20: la publication manuelle n''est pas auditée'; END IF;
END
$audit_retrait$;

ROLLBACK;
