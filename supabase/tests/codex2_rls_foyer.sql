-- X2-02 : scenarios RLS de foyer / profil / appareil.
-- À rejouer après stub_auth.sql et les migrations 0001–0048.
-- Le bloc désactivé est une assertion de sécurité volontaire : il doit échouer
-- tant que les policies ne refusent pas réellement les comptes désactivés.
BEGIN;

DO $$
DECLARE v_missing text;
BEGIN
  SELECT string_agg(expected.table_name, ', ' ORDER BY expected.table_name)
    INTO v_missing
    FROM unnest(ARRAY[
    'public.households',
    'public.profiles',
    'public.teacher_profiles',
    'public.student_profiles',
    'public.kyc_documents',
    'public.devices',
    'public.recurrence_rules',
    'public.availability_slots',
    'public.sessions',
    'public.session_participants',
    'public.session_events',
    'public.session_recordings',
    'public.lesson_reports',
    'public.makharij_findings',
    'public.wallets',
    'public.wallet_entries',
    'public.payout_methods',
    'public.payouts',
    'public.fx_rates',
    'public.webhook_events',
    'public.audit_logs',
    'public.id_sequences',
    'public.app_config',
    'public.app_config_history',
    'public.rate_limits',
    'public.device_tokens',
    'public.contract_acceptances',
    'public.device_pairing_codes',
    'public.audit_logs_default',
    'public.rule_overrides',
    'public.teacher_student_assignments',
    'public.weekly_availability',
    'public.prayer_settings',
    'public.matching_requests',
    'public.mushaf',
    'public.sourate',
    'public.juz',
    'public.page_mushaf',
    'public.verset',
    'public.student_reading_position',
    'public.session_presence_override',
    'public.video_config',
    'public.session_video_route',
    'public.video_token_grants',
    'public.livekit_webhook_deliveries',
    'public.jetons_agent',
    'public.groupes',
    'public.groupe_membres',
    'public.programme_versions',
    'public.programme_niveaux',
    'public.progression_historique',
    'public.progression_exceptions',
    'public.evaluations',
    'public.controles_qualite',
    'public.library_resource',
    'public.resource_version',
    'public.download_asset',
    'public.library_resource_groupe',
    'public.library_reading_position',
    'public.annotation_layer',
    'public.annotation_trait',
    'public.annotation_marqueur',
    'public.learning_assignment',
    'public.session_shared_content',
    'public.guardian_session_visit',
    'public.session_feedback',
    'public.student_concern',
    'public.langues_cours',
    'public.cohortes_age',
    'public.offres_horaires',
    'public.intentions_horaire',
    'public.groupe_creneaux'
    ]::text[]) AS expected(table_name)
   WHERE NOT EXISTS (
     SELECT 1 FROM pg_catalog.pg_class c
     JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname || '.' || c.relname = expected.table_name
        AND c.relrowsecurity
   );
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'RLS-CATALOG : table(s) sans RLS activée : %', v_missing;
  END IF;
END $$;

CREATE TEMP TABLE codex2_rls_violations (
  scenario text NOT NULL,
  table_name text NOT NULL
) ON COMMIT DROP;
GRANT INSERT ON codex2_rls_violations TO authenticated;

-- Anon est exercé sur chaque table RLS réellement créée par les migrations,
-- pas seulement sur `profiles`. Une absence de privilège SQL est un refus
-- valide; si SELECT est accordé, aucune ligne ne doit devenir lisible.
DO $$
DECLARE
  v_table regclass;
  v_visible boolean;
BEGIN
  FOR v_table IN
    SELECT c.oid::regclass
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public'
       AND c.relrowsecurity
       AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
     ORDER BY c.oid::regclass::text
  LOOP
    v_visible := false;
    BEGIN
      SET LOCAL ROLE anon;
      EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s)', v_table)
        INTO v_visible;
      RESET ROLE;
    EXCEPTION WHEN insufficient_privilege THEN
      RESET ROLE;
      v_visible := false;
    END;
    IF v_visible THEN
      INSERT INTO codex2_rls_violations VALUES ('anon-read', v_table::text);
    END IF;
  END LOOP;
END $$;


INSERT INTO auth.users (id, email) VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'codex2-guardian-a@example.test'),
  ('c2a20000-0000-0000-0000-000000000002', 'codex2-student-b@example.test'),
  ('c2a20000-0000-0000-0000-000000000003', 'codex2-disabled-a@example.test'),
  ('c2a20000-0000-0000-0000-000000000004', 'codex2-student-a@example.test'),
  ('c2a20000-0000-0000-0000-000000000005', 'codex2-teacher-a@example.test'),
  ('c2a20000-0000-0000-0000-000000000006', 'codex2-teacher-b@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('c2a2ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('c2a2ffff-0000-0000-0000-000000000002', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'COD2-GUARD-A', 'guardian',
   'c2a2ffff-0000-0000-0000-000000000001', 'Gardien', 'A', 'active'),
  ('c2a20000-0000-0000-0000-000000000002', 'COD2-STUD-B', 'student',
   'c2a2ffff-0000-0000-0000-000000000002', 'Eleve', 'B', 'active'),
  ('c2a20000-0000-0000-0000-000000000003', 'COD2-GUARD-DISABLED', 'guardian',
   'c2a2ffff-0000-0000-0000-000000000001', 'Gardien', 'Suspendu', 'disabled'),
  ('c2a20000-0000-0000-0000-000000000004', 'COD2-STUD-A', 'student',
   'c2a2ffff-0000-0000-0000-000000000001', 'Eleve', 'A', 'active'),
  ('c2a20000-0000-0000-0000-000000000005', 'COD2-TEACH-A', 'teacher',
   'c2a2ffff-0000-0000-0000-000000000001', 'Enseignant', 'A', 'active'),
  ('c2a20000-0000-0000-0000-000000000006', 'COD2-TEACH-B', 'teacher',
   'c2a2ffff-0000-0000-0000-000000000002', 'Enseignant', 'B', 'active');

INSERT INTO public.student_profiles (profile_id) VALUES
  ('c2a20000-0000-0000-0000-000000000002'),
  ('c2a20000-0000-0000-0000-000000000004');
INSERT INTO public.teacher_profiles (profile_id) VALUES
  ('c2a20000-0000-0000-0000-000000000005'),
  ('c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.student_reading_position
  (student_profile_id, mushaf_id, page_mushaf, sourate, verset)
SELECT sp.profile_id, m.id, 2, 2, 1
  FROM public.student_profiles sp
  CROSS JOIN public.mushaf m
 WHERE sp.profile_id IN (
   'c2a20000-0000-0000-0000-000000000002',
   'c2a20000-0000-0000-0000-000000000004'
 )
   AND m.code = 'madina-hafs-604';

INSERT INTO public.devices (profile_id, device_fingerprint, platform) VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'codex2-device-owner-household', 'web'),
  ('c2a20000-0000-0000-0000-000000000002', 'codex2-device-other-household', 'web');

INSERT INTO public.contract_acceptances (profile_id, contract_kind, version) VALUES
  ('c2a20000-0000-0000-0000-000000000004', 'recording_and_control_notice', 'codex2-v1'),
  ('c2a20000-0000-0000-0000-000000000002', 'recording_and_control_notice', 'codex2-v1');

DO $$
DECLARE v_denied boolean := false;
BEGIN
  SET LOCAL ROLE anon;
  BEGIN
    PERFORM 1 FROM public.profiles LIMIT 1;
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  RESET ROLE;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'RLS-PROFILE-ANON : lecture anon non refusée par privilège/RLS';
  END IF;
END $$;

DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.devices
   WHERE device_fingerprint = 'codex2-device-owner-household';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-DEVICE: owner device is not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.households
   WHERE id = 'c2a2ffff-0000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-HOUSEHOLD : foyer propriétaire invisible'; END IF;
  SELECT count(*) INTO v_count FROM public.profiles
   WHERE id = 'c2a20000-0000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PROFILE : profil propriétaire invisible'; END IF;
  SELECT count(*) INTO v_count FROM public.profiles
   WHERE id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-READ : profil du foyer B visible'; END IF;
  SELECT count(*) INTO v_count FROM public.devices
   WHERE device_fingerprint = 'codex2-device-other-household';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-DEVICE : appareil du foyer B visible'; END IF;
  RESET ROLE;
END $$;

DO $$
DECLARE v_table regclass; v_visible boolean;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  FOR v_table IN
    SELECT c.oid::regclass FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relrowsecurity
      AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
    ORDER BY c.oid::regclass::text
  LOOP
    v_visible := false;
    BEGIN
      EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s)', v_table)
        INTO v_visible;
    EXCEPTION WHEN insufficient_privilege THEN
      v_visible := false;
    END;
    IF v_visible THEN
      INSERT INTO codex2_rls_violations VALUES ('missing-role-claim', v_table::text);
    END IF;
  END LOOP;
  RESET ROLE;
END $$;

-- Le tuteur A voit et modifie son eleve A, mais ni ne voit ni ne modifie
-- la ligne student_profiles de l'eleve B.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.student_profiles
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-STUDENT-PROFILE: household A student not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.student_profiles
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-STUDENT-READ: household B student visible'; END IF;
  UPDATE public.student_profiles SET level = 'codex2-positive'
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-STUDENT-WRITE: household A update was not accepted'; END IF;
  UPDATE public.student_profiles SET level = 'codex2-cross-household'
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-STUDENT-WRITE: household B row was updated'; END IF;
  RESET ROLE;
END $$;

-- Un enseignant du foyer A lit sa fiche propre, pas celle du foyer B.
DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.teacher_profiles
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000005';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-TEACHER-PROFILE: teacher A profile not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.teacher_profiles
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000006';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-TEACHER-READ: teacher B profile visible'; END IF;
  RESET ROLE;
END $$;

-- La position personnelle est modifiable par l'eleve A; ni lui ni son foyer
-- ne lisent la position de l'eleve B.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000004', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"student","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.student_reading_position
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-READING-POSITION: student A row not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.student_reading_position
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-READING-READ: student B row visible'; END IF;
  UPDATE public.student_reading_position SET page_mushaf = 3
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000004';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-READING-WRITE: student A could not update own row'; END IF;
  UPDATE public.student_reading_position SET page_mushaf = 3
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-READING-WRITE: student A updated student B row'; END IF;
  RESET ROLE;
END $$;

-- Le tuteur A peut lire la position de l'eleve A, pas celle de B.
DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.student_reading_position
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-READING-GUARDIAN: household A position not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.student_reading_position
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-READING-GUARDIAN: household B position visible'; END IF;
  RESET ROLE;
END $$;

-- Chaque acceptation est lisible et inscriptible par son signataire seulement.
DO $$
DECLARE v_count integer; v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000004', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"student","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.contract_acceptances
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-CONTRACT-ACCEPTANCE: signer A cannot read own acceptance'; END IF;
  SELECT count(*) INTO v_count FROM public.contract_acceptances
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-CONTRACT-READ: signer A sees signer B acceptance'; END IF;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('c2a20000-0000-0000-0000-000000000004', 'recording_and_control_notice', 'codex2-v2');
  BEGIN
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES ('c2a20000-0000-0000-0000-000000000002', 'recording_and_control_notice', 'codex2-v2');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-CONTRACT-INSERT: signer A inserted for B'; END IF;
  RESET ROLE;
END $$;

DO $$
DECLARE v_table regclass; v_visible boolean;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000003', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  FOR v_table IN
    SELECT c.oid::regclass FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relrowsecurity
      AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
    ORDER BY c.oid::regclass::text
  LOOP
    v_visible := false;
    BEGIN
      EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s)', v_table)
        INTO v_visible;
    EXCEPTION WHEN insufficient_privilege THEN
      v_visible := false;
    END;
    IF v_visible THEN
      INSERT INTO codex2_rls_violations VALUES ('disabled-account', v_table::text);
    END IF;
  END LOOP;
  RESET ROLE;
END $$;

DO $$
DECLARE v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  UPDATE public.devices SET revoked_at = now()
   WHERE device_fingerprint = 'codex2-device-other-household';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WRITE : appareil étranger modifié'; END IF;
  RESET ROLE;
END $$;

DO $$
DECLARE v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  BEGIN
    INSERT INTO public.devices (profile_id, device_fingerprint, platform)
    VALUES ('c2a20000-0000-0000-0000-000000000002', 'codex2-device-cross-household-insert', 'web');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WRITE: cross-household device insert was not denied';
  END IF;
  RESET ROLE;
END $$;

DO $$
DECLARE v_failures text;
BEGIN
  SELECT string_agg(scenario || ':' || table_name, ', ' ORDER BY scenario, table_name)
    INTO v_failures
    FROM codex2_rls_violations;
  IF v_failures IS NOT NULL THEN
    RAISE EXCEPTION 'RLS-X2-02 negative assertion(s) failed: %', v_failures;
  END IF;
END $$;

ROLLBACK;
