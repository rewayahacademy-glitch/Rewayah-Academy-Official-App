BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a8000000-0000-0000-0000-000000000001', 'age-parent-a@example.test'),
  ('a8000000-0000-0000-0000-000000000002', 'age-parent-b@example.test'),
  ('a8000000-0000-0000-0000-000000000003', 'age-child@example.test'),
  ('a8000000-0000-0000-0000-000000000004', 'age-adult@example.test'),
  ('a8000000-0000-0000-0000-000000000005', 'age-child-b@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('a8000000-0000-0000-0000-000000000101', 'Europe/Paris'),
  ('a8000000-0000-0000-0000-000000000102', 'Europe/London');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender,
   account_status)
VALUES
  ('a8000000-0000-0000-0000-000000000001', 'AGE-PARENT-A', 'guardian',
   'a8000000-0000-0000-0000-000000000101', 'Parent', 'A', 'female', 'active'),
  ('a8000000-0000-0000-0000-000000000002', 'AGE-PARENT-B', 'guardian',
   'a8000000-0000-0000-0000-000000000102', 'Parent', 'B', 'male', 'active'),
  ('a8000000-0000-0000-0000-000000000003', 'AGE-CHILD', 'student',
   'a8000000-0000-0000-0000-000000000101', 'Child', 'A', 'female', 'active'),
  ('a8000000-0000-0000-0000-000000000004', 'AGE-ADULT', 'student',
   'a8000000-0000-0000-0000-000000000102', 'Adult', 'B', 'male', 'active'),
  ('a8000000-0000-0000-0000-000000000005', 'AGE-CHILD-B', 'student',
   'a8000000-0000-0000-0000-000000000102', 'Child', 'B', 'male', 'active');

UPDATE public.households
SET primary_guardian_id = 'a8000000-0000-0000-0000-000000000001'
WHERE id = 'a8000000-0000-0000-0000-000000000101';
UPDATE public.households
SET primary_guardian_id = 'a8000000-0000-0000-0000-000000000002'
WHERE id = 'a8000000-0000-0000-0000-000000000102';

INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
VALUES
  ('a8000000-0000-0000-0000-000000000003', 'minor', 'child'),
  ('a8000000-0000-0000-0000-000000000004', 'autonomous', 'standard'),
  ('a8000000-0000-0000-0000-000000000005', 'minor', 'child');

-- Privileged fixture for a stale request whose student's household changed.
INSERT INTO public.demandes_presentation (id, eleve_id, foyer_id)
VALUES (
  'a8000000-0000-0000-0000-000000000201',
  'a8000000-0000-0000-0000-000000000004',
  'a8000000-0000-0000-0000-000000000101'
);

DO $age_hook$
DECLARE
  v_event jsonb;
BEGIN
  v_event := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'a8000000-0000-0000-0000-000000000003',
    'claims', '{"app_metadata":{"role":"forged"}}'::jsonb
  ));
  IF v_event #>> '{claims,tranche_age}' <> 'enfant'
     OR v_event #>> '{claims,app_metadata,role}' <> 'student'
     OR v_event #>> '{claims,app_metadata,household_id}'
        <> 'a8000000-0000-0000-0000-000000000101' THEN
    RAISE EXCEPTION 'A81/C22: hook enfant did not replace profile claims';
  END IF;

  v_event := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'a8000000-0000-0000-0000-000000000004',
    'claims', '{}'::jsonb
  ));
  IF v_event #>> '{claims,tranche_age}' <> 'adulte' THEN
    RAISE EXCEPTION 'A81/C22: autonomous student age claim is not adult';
  END IF;
END
$age_hook$;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000003', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

DO $student_request$
DECLARE
  v_id uuid;
  v_count integer;
BEGIN
  PERFORM public.demander_presentation_standard();
  PERFORM public.demander_presentation_standard();
  BEGIN
    SELECT count(*) INTO v_count FROM public.demandes_presentation;
    RAISE EXCEPTION 'A81/C22: direct table read was allowed';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$student_request$;

SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
DO $second_household_request$
BEGIN
  PERFORM public.demander_presentation_standard();
END
$second_household_request$;

SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000004', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
DO $adult_denied$
BEGIN
  BEGIN
    PERFORM public.demander_presentation_standard();
    RAISE EXCEPTION 'A81/C22: an autonomous adult created a minor presentation request';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$adult_denied$;

SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"a8000000-0000-0000-0000-000000000101"}}', true);
DO $guardian_decision$
DECLARE
  v_id uuid;
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.lire_demandes_presentation_en_attente();
  SELECT id INTO v_id
  FROM public.lire_demandes_presentation_en_attente()
  ORDER BY id
  LIMIT 1;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'A81/C22: household guardian did not receive exactly one request';
  END IF;
  IF (SELECT count(*)
      FROM public.lire_demandes_presentation_en_attente_avec_fuseau()) <> 1 THEN
    RAISE EXCEPTION 'C22: timezone projection exposed a request for a student in another household';
  END IF;

  IF public.accepter_demande_presentation(v_id) <> 'acceptee'
     OR public.accepter_demande_presentation(v_id) <> 'acceptee' THEN
    RAISE EXCEPTION 'A81/C22: repeated accept is not idempotent';
  END IF;

  PERFORM set_config('test.presentation_id', v_id::text, true);

  SELECT count(*) INTO v_count FROM public.lire_demandes_presentation_en_attente();
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'A81/C22: answered request remained pending';
  END IF;

  BEGIN
    PERFORM public.refuser_demande_presentation(v_id);
    RAISE EXCEPTION 'A81/C22: conflicting second decision was accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'demande déjà tranchée%' THEN RAISE; END IF;
  END;
END
$guardian_decision$;

SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"a8000000-0000-0000-0000-000000000102"}}', true);
DO $other_household_denied$
DECLARE
  v_id uuid := current_setting('test.presentation_id')::uuid;
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.lire_demandes_presentation_en_attente();
  IF v_count <> 1 OR EXISTS (
    SELECT 1 FROM public.lire_demandes_presentation_en_attente()
    WHERE id = v_id
  ) THEN
    RAISE EXCEPTION 'A81/C22: household B should see only its own pending request';
  END IF;
  SELECT count(*) INTO v_count
    FROM public.lire_demandes_presentation_en_attente_avec_fuseau();
  IF v_count <> 1 OR EXISTS (
    SELECT 1 FROM public.lire_demandes_presentation_en_attente_avec_fuseau()
    WHERE id = v_id
  ) THEN
    RAISE EXCEPTION 'C22: household B should see only its own pending request';
  END IF;
  BEGIN
    PERFORM public.accepter_demande_presentation(v_id);
    RAISE EXCEPTION 'A81/C22: another household accepted the request';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$other_household_denied$;

RESET ROLE;
DO $notifications$
DECLARE
  v_count integer;
  v_id uuid := current_setting('test.presentation_id')::uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.demandes_presentation
    WHERE id = v_id AND statut = 'acceptee'
      AND repondu_le IS NOT NULL
      AND repondu_par = 'a8000000-0000-0000-0000-000000000001'
  ) THEN
    RAISE EXCEPTION 'A81/C22: decision is not server-timestamped or attributed';
  END IF;
  SELECT count(*) INTO v_count FROM public.notifications
  WHERE destinataire = 'a8000000-0000-0000-0000-000000000001'
    AND evenement = 'demande_presentation'
    AND params ->> 'demande_id' = v_id::text
    AND destination = '/tuteur/demandes';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'A81/C22: request must produce one household notification';
  END IF;
END
$notifications$;

-- A81/C22/F86: these RPCs are authenticated-only. Check both the ACL and the
-- observable denial under the anonymous database role.
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.uid', '', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE anon;
DO $anonymous_denied$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM unnest(ARRAY[
      'public.demander_presentation_standard()'::regprocedure,
      'public.lire_demandes_presentation_en_attente()'::regprocedure,
      'public.lire_demandes_presentation_en_attente_avec_fuseau()'::regprocedure,
      'public.repondre_demande_presentation(uuid,text)'::regprocedure,
      'public.accepter_demande_presentation(uuid)'::regprocedure,
      'public.refuser_demande_presentation(uuid)'::regprocedure
    ]) AS rpc(oid)
    WHERE pg_catalog.has_function_privilege('anon', rpc.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'A81/C22: anon conserve EXECUTE sur une RPC de presentation';
  END IF;

  BEGIN
    PERFORM public.demander_presentation_standard();
    RAISE EXCEPTION 'A81/C22: anon a cree une demande de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM 1 FROM public.lire_demandes_presentation_en_attente();
    RAISE EXCEPTION 'A81/C22: anon a lu les demandes de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM 1 FROM public.lire_demandes_presentation_en_attente_avec_fuseau();
    RAISE EXCEPTION 'C22: anon a lu les demandes avec fuseau';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.repondre_demande_presentation(
      'a8000000-0000-0000-0000-000000000201', 'refusee'
    );
    RAISE EXCEPTION 'A81: anon a repondu a une demande de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.accepter_demande_presentation(
      'a8000000-0000-0000-0000-000000000201'
    );
    RAISE EXCEPTION 'A81: anon a accepte une demande de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.refuser_demande_presentation(
      'a8000000-0000-0000-0000-000000000201'
    );
    RAISE EXCEPTION 'A81: anon a refuse une demande de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$anonymous_denied$;
RESET ROLE;

-- Invalid account status must stop the RPCs even when the JWT role is correct.
UPDATE public.profiles SET account_status = 'disabled'
WHERE id = 'a8000000-0000-0000-0000-000000000003';
SELECT set_config('request.jwt.claim.sub', 'a8000000-0000-0000-0000-000000000003', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"student"}}', true);
SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000003', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
SET LOCAL ROLE authenticated;
DO $disabled_student_denied$
BEGIN
  BEGIN
    PERFORM public.demander_presentation_standard();
    RAISE EXCEPTION 'F86: un eleve desactive a cree une demande de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$disabled_student_denied$;
RESET ROLE;
UPDATE public.profiles SET account_status = 'active'
WHERE id = 'a8000000-0000-0000-0000-000000000003';

UPDATE public.profiles SET account_status = 'disabled'
WHERE id = 'a8000000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub', 'a8000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"a8000000-0000-0000-0000-000000000101"}}', true);
SELECT set_config('test.uid', 'a8000000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"a8000000-0000-0000-0000-000000000101"}}', true);
SET LOCAL ROLE authenticated;
DO $disabled_guardian_denied$
DECLARE
  v_id uuid := current_setting('test.presentation_id')::uuid;
BEGIN
  BEGIN
    PERFORM 1 FROM public.lire_demandes_presentation_en_attente();
    RAISE EXCEPTION 'F86: un tuteur desactive a lu les demandes de presentation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM 1 FROM public.lire_demandes_presentation_en_attente_avec_fuseau();
    RAISE EXCEPTION 'F86: un tuteur desactive a lu les demandes avec fuseau';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.accepter_demande_presentation(v_id);
    RAISE EXCEPTION 'F86: un tuteur desactive a accepte une demande';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.refuser_demande_presentation(v_id);
    RAISE EXCEPTION 'F86: un tuteur desactive a refuse une demande';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$disabled_guardian_denied$;
RESET ROLE;

ROLLBACK;
