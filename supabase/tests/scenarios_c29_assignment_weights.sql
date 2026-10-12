-- Exercise C-29's session trigger, candidate selection, active controller
-- capacity, and the three configured weighting levels.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c2900000-0000-0000-0000-000000000001', 'c29-admin@test.invalid'),
  ('c2900000-0000-0000-0000-000000000002', 'c29-controller@test.invalid'),
  ('c2900000-0000-0000-0000-000000000003', 'c29-recent@test.invalid'),
  ('c2900000-0000-0000-0000-000000000004', 'c29-concern@test.invalid');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('c2900000-0000-0000-0000-000000000001', 'C29-ADMIN', 'admin', 'Admin', 'Weights', 'active', 'female'),
  ('c2900000-0000-0000-0000-000000000002', 'C29-CONTROLLER', 'controller', 'Controller', 'Weights', 'active', 'female'),
  ('c2900000-0000-0000-0000-000000000003', 'C29-RECENT', 'teacher', 'Recent', 'Teacher', 'provisional_active', 'male'),
  ('c2900000-0000-0000-0000-000000000004', 'C29-CONCERN', 'teacher', 'Concern', 'Teacher', 'provisional_active', 'male');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
  ('c2900000-0000-0000-0000-000000000003', 'approved'),
  ('c2900000-0000-0000-0000-000000000004', 'approved');
DO $fixture_teacher_contracts$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version FROM public.contract_texts
   WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version FROM public.contract_required_versions
   WHERE contract_kind='recording_and_control_notice';
  FOR v_teacher IN SELECT id FROM public.profiles
    WHERE role='teacher' AND account_status='provisional_active'
  LOOP
    PERFORM set_config('request.jwt.claim.sub',v_teacher.id::text,true);
    PERFORM set_config('test.uid',v_teacher.id::text,true);
    PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
    PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
    PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
    INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
    VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version)
    ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
    UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public,
   ended_at, ended_by, end_reason)
VALUES
  ('c2900000-0000-0000-0000-000000000101', 'c2900000-0000-0000-0000-000000000003', 'enfant', 5, 'C29 recent weight', 1, 18, 'Europe/Paris', 'hommes', NULL, NULL, NULL),
  ('c2900000-0000-0000-0000-000000000102', 'c2900000-0000-0000-0000-000000000004', 'enfant', 5, 'C29 concern weight', 1, 18, 'Europe/Paris', 'hommes', NULL, NULL, NULL),
  ('c2900000-0000-0000-0000-000000000103', 'c2900000-0000-0000-0000-000000000004', 'enfant', 5, 'C29 closed trigger group', 1, 18, 'Europe/Paris', 'hommes', TIMESTAMPTZ '2098-12-01 00:00:00+00', 'c2900000-0000-0000-0000-000000000001', 'scenario trigger only');
-- The fixed future window avoids overlap with ambient or time-shifted sessions;
-- the effective-teacher history remains within the rolling 90-day threshold.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES
  ('c2900000-0000-0000-0000-000000000201', 'c2900000-0000-0000-0000-000000000003', TIMESTAMPTZ '2099-01-01 11:55:00+00', TIMESTAMPTZ '2099-01-01 12:55:00+00', 'in_progress', 'standard', 'c2900000-0000-0000-0000-000000000101'),
  ('c2900000-0000-0000-0000-000000000202', 'c2900000-0000-0000-0000-000000000004', TIMESTAMPTZ '2099-01-01 11:55:00+00', TIMESTAMPTZ '2099-01-01 12:55:00+00', 'in_progress', 'standard', 'c2900000-0000-0000-0000-000000000102'),
  ('c2900000-0000-0000-0000-000000000203', 'c2900000-0000-0000-0000-000000000003', TIMESTAMPTZ '2098-12-22 12:00:00+00', TIMESTAMPTZ '2098-12-22 13:00:00+00', 'ended', 'standard', NULL);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
SELECT ('c2900000-0000-0000-0000-' || lpad((300 + n)::text, 12, '0'))::uuid,
       'c2900000-0000-0000-0000-000000000004',
       TIMESTAMPTZ '2099-01-01 12:00:00+00' - (2 * n + 2) * interval '1 hour',
       TIMESTAMPTZ '2099-01-01 12:00:00+00' - (2 * n + 1) * interval '1 hour',
       'preflight', 'standard', 'c2900000-0000-0000-0000-000000000103'
FROM generate_series(1, 400) AS n;
INSERT INTO public.student_concern
  (categorie, groupe_id, student_id, teacher_id, internal_details)
VALUES
  ('pedagogique', 'c2900000-0000-0000-0000-000000000102', 'c2900000-0000-0000-0000-000000000001', 'c2900000-0000-0000-0000-000000000004', 'Scenario concern weight');

INSERT INTO public.controle_regles
  (version, missions_par_semaine, ponderations, payload, cree_par, cle)
VALUES
  (1, 5,
   '{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"}',
   '{"scenario":"C29 assignment weights"}',
   'c2900000-0000-0000-0000-000000000001',
   'c2900000-0000-0000-0000-000000000301');
INSERT INTO private.controle_capacites
  (profile_id, approved_by, active_from, expires_at, scope_all_groups,
   scope_group_ids, scope_teacher_ids, grant_idempotency_key)
VALUES
  ('c2900000-0000-0000-0000-000000000002',
   'c2900000-0000-0000-0000-000000000001', now() - interval '1 minute', now() + interval '1 day',
   true, '{}', '{}', 'c2900000-0000-0000-0000-000000000302');

-- The candidate pool consists of sessions already in progress before the
-- trigger fires. Their INSERT bypasses the UPDATE-only assignment trigger.
DO $test$
DECLARE
  n integer;
  v_recent integer := 0;
  v_assigned uuid;
  v_trigger_id uuid;
BEGIN
  -- A fixed seed makes the 400-trial distribution reproducible. Roll each
  -- assignment back after observing it so capacity and mission history do not
  -- influence later trials.
  PERFORM setseed(0.25);
  FOR n IN 1..400 LOOP
    v_trigger_id := ('c2900000-0000-0000-0000-' || lpad((300 + n)::text, 12, '0'))::uuid;
    BEGIN
      UPDATE public.sessions SET status='in_progress' WHERE id=v_trigger_id;
      SELECT session_id INTO v_assigned FROM private.controle_missions
       WHERE controleur_id='c2900000-0000-0000-0000-000000000002'
         AND version_regles=1 AND critere='ponderation';
      IF v_assigned IS NULL THEN
        RAISE EXCEPTION 'C29: trigger did not assign an already-running candidate';
      END IF;
      IF v_assigned='c2900000-0000-0000-0000-000000000201' THEN
        v_recent:=v_recent+1;
      ELSIF v_assigned<>'c2900000-0000-0000-0000-000000000202' THEN
        RAISE EXCEPTION 'C29: trigger selected an unexpected session %', v_assigned;
      END IF;
      RAISE EXCEPTION USING ERRCODE='ZX001', MESSAGE='rollback this sampling trial';
    EXCEPTION WHEN SQLSTATE 'ZX001' THEN
      NULL;
    END;
  END LOOP;
  -- With weights 2 (recent, normal) and 4 (reported class, strong), the
  -- exponential race selects the recent candidate about one third of the time.
  -- This broad four-sigma band detects equal or reversed weights without a
  -- flaky exact-count assertion.
  IF v_recent NOT BETWEEN 95 AND 170 THEN
    RAISE EXCEPTION 'C29: expected roughly one-third recent assignments (weight 2 vs 4), got %/400', v_recent;
  END IF;
  IF (SELECT ponderations FROM public.controle_regles WHERE version=1) <>
      '{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"}'::jsonb THEN
    RAISE EXCEPTION 'C29: normal, strong, and disabled weighting levels were not retained';
  END IF;

  INSERT INTO public.controle_regles
    (version, missions_par_semaine, ponderations, payload, cree_par, cle)
  VALUES
    (2, 1,
     '{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"}',
     '{"scenario":"C29 versioned cap one"}',
     'c2900000-0000-0000-0000-000000000001',
     'c2900000-0000-0000-0000-000000000303');
  UPDATE public.sessions SET status='in_progress'
   WHERE id='c2900000-0000-0000-0000-000000000301';
  UPDATE public.sessions SET status='in_progress'
   WHERE id='c2900000-0000-0000-0000-000000000302';
  IF (SELECT count(*) FROM private.controle_missions WHERE version_regles=2) <> 1 THEN
    RAISE EXCEPTION 'C29: versioned weekly cap 1 was not enforced';
  END IF;

  INSERT INTO public.controle_regles
    (version, missions_par_semaine, ponderations, payload, cree_par, cle)
  VALUES
    (3, 0,
     '{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"}',
     '{"scenario":"C29 versioned cap zero"}',
     'c2900000-0000-0000-0000-000000000001',
     'c2900000-0000-0000-0000-000000000304');
  UPDATE public.sessions SET status='in_progress'
   WHERE id='c2900000-0000-0000-0000-000000000303';
  IF EXISTS (SELECT 1 FROM private.controle_missions WHERE version_regles=3) THEN
    RAISE EXCEPTION 'C29: versioned cap zero still assigned a mission';
  END IF;
END;
$test$;

ROLLBACK;
