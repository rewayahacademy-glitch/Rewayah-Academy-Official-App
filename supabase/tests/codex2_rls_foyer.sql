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
  ('c2a2ffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('c2a2ffff-0000-0000-0000-000000000003', 'Europe/Paris');

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
   'c2a2ffff-0000-0000-0000-000000000003', 'Enseignant', 'A', 'active'),
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

INSERT INTO public.wallets (id, household_id) VALUES
  ('c2a2ffff-1000-0000-0000-000000000001', 'c2a2ffff-0000-0000-0000-000000000001'),
  ('c2a2ffff-1000-0000-0000-000000000002', 'c2a2ffff-0000-0000-0000-000000000002');
INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type) VALUES
  ('c2a2ffff-1000-0000-0000-000000000001', 1000, 'EUR', 'credit'),
  ('c2a2ffff-1000-0000-0000-000000000002', 2000, 'EUR', 'credit');
INSERT INTO public.payout_methods (id, profile_id, kind, details) VALUES
  ('c2a2ffff-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'bank', '{"masked":"A"}'),
  ('c2a2ffff-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'bank', '{"masked":"B"}');
INSERT INTO public.payouts (id, wallet_id, payout_method_id, amount_minor) VALUES
  ('c2a2ffff-3000-0000-0000-000000000001', 'c2a2ffff-1000-0000-0000-000000000001', 'c2a2ffff-2000-0000-0000-000000000001', 500),
  ('c2a2ffff-3000-0000-0000-000000000002', 'c2a2ffff-1000-0000-0000-000000000002', 'c2a2ffff-2000-0000-0000-000000000002', 700);
INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local) VALUES
  ('c2a20000-0000-0000-0000-000000000005', 'c2a20000-0000-0000-0000-000000000004', 1, 10),
  ('c2a20000-0000-0000-0000-000000000006', 'c2a20000-0000-0000-0000-000000000002', 2, 11);
INSERT INTO public.availability_slots (teacher_id, starts_at, ends_at) VALUES
  ('c2a20000-0000-0000-0000-000000000005', '2026-10-12 10:00:00+00', '2026-10-12 11:00:00+00'),
  ('c2a20000-0000-0000-0000-000000000006', '2026-10-13 11:00:00+00', '2026-10-13 12:00:00+00');
INSERT INTO public.rule_overrides (profile_id, key, value, reason, set_by) VALUES
  ('c2a20000-0000-0000-0000-000000000004', 'session_duration_minutes', '45', 'codex2 foyer A', 'c2a20000-0000-0000-0000-000000000001'),
  ('c2a20000-0000-0000-0000-000000000002', 'session_duration_minutes', '60', 'codex2 foyer B', 'c2a20000-0000-0000-0000-000000000001');
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local) VALUES
  ('c2a20000-0000-0000-0000-000000000004', 1, 10),
  ('c2a20000-0000-0000-0000-000000000002', 2, 11);
INSERT INTO public.prayer_settings (teacher_id, latitude, longitude) VALUES
  ('c2a20000-0000-0000-0000-000000000005', 48.85660, 2.35220),
  ('c2a20000-0000-0000-0000-000000000006', 9.50917, -13.71222);
INSERT INTO public.matching_requests (kind, subject_profile_id, reason, requested_by, requester_role) VALUES
  ('reassignment', 'c2a20000-0000-0000-0000-000000000004', 'codex2 foyer A', 'c2a20000-0000-0000-0000-000000000001', 'guardian'),
  ('reassignment', 'c2a20000-0000-0000-0000-000000000002', 'codex2 foyer B', 'c2a20000-0000-0000-0000-000000000002', 'student');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005', '2026-10-12 10:00:00+00', '2026-10-12 11:00:00+00'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006', '2026-10-13 11:00:00+00', '2026-10-13 12:00:00+00');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005', 'teacher'),
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'student'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006', 'teacher'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'student');
INSERT INTO public.session_events (session_id, profile_id, event_type, source) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'joined', 'codex2'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'joined', 'codex2');
INSERT INTO public.session_recordings (session_id, object_key, duration_seconds, size_bytes, expires_at) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'codex2/recording-a', 60, 1024, '2026-10-20 00:00:00+00'),
  ('c2a2e000-1000-0000-0000-000000000002', 'codex2/recording-b', 60, 1024, '2026-10-20 00:00:00+00');
INSERT INTO public.lesson_reports (id, session_id, idempotency_key, content, author_profile_id) VALUES
  ('c2a2e000-2000-0000-0000-000000000001', 'c2a2e000-1000-0000-0000-000000000001', 'codex2-report-a', '{}', 'c2a20000-0000-0000-0000-000000000005'),
  ('c2a2e000-2000-0000-0000-000000000002', 'c2a2e000-1000-0000-0000-000000000002', 'codex2-report-b', '{}', 'c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.makharij_findings (lesson_report_id, makhraj, finding) VALUES
  ('c2a2e000-2000-0000-0000-000000000001', 'lam', '{"note":"A"}'),
  ('c2a2e000-2000-0000-0000-000000000002', 'lam', '{"note":"B"}');

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

-- Les donnees de seance suivent les participants et leur foyer, sur les deux
-- cotes du lien enseignant-eleve.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.sessions WHERE id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-SESSION: teacher A cannot read own session'; END IF;
  SELECT count(*) INTO v_count FROM public.sessions WHERE id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-READ: teacher A sees session B'; END IF;
  UPDATE public.sessions SET room = room WHERE id = 'c2a2e000-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-WRITE: teacher A updated session B'; END IF;
  SELECT count(*) INTO v_count FROM public.session_participants WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-OWNER-SESSION-PARTICIPANTS: teacher A cannot read own roster'; END IF;
  SELECT count(*) INTO v_count FROM public.session_participants WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-PARTICIPANTS: teacher A sees roster B'; END IF;
  UPDATE public.session_participants SET entered_at = entered_at WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-PARTICIPANTS-WRITE: teacher A updated roster B'; END IF;
  SELECT count(*) INTO v_count FROM public.session_events WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-SESSION-EVENT: teacher A cannot read own event'; END IF;
  SELECT count(*) INTO v_count FROM public.session_events WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-EVENT: teacher A sees event B'; END IF;
  UPDATE public.session_events SET source = source WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-EVENT-WRITE: teacher A updated event B'; END IF;
  SELECT count(*) INTO v_count FROM public.session_recordings WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-SESSION-RECORDING: teacher A cannot read own recording'; END IF;
  SELECT count(*) INTO v_count FROM public.session_recordings WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SESSION-RECORDING: teacher A sees recording B'; END IF;
  SELECT count(*) INTO v_count FROM public.lesson_reports WHERE id = 'c2a2e000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-LESSON-REPORT: teacher A cannot read own report'; END IF;
  SELECT count(*) INTO v_count FROM public.lesson_reports WHERE id = 'c2a2e000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LESSON-REPORT: teacher A sees report B'; END IF;
  SELECT count(*) INTO v_count FROM public.makharij_findings WHERE lesson_report_id = 'c2a2e000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-MAKHARIJ-FINDING: teacher A cannot read own finding'; END IF;
  SELECT count(*) INTO v_count FROM public.makharij_findings WHERE lesson_report_id = 'c2a2e000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-MAKHARIJ-FINDING: teacher A sees finding B'; END IF;
  UPDATE public.lesson_reports SET content = content WHERE id = 'c2a2e000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LESSON-REPORT-WRITE: teacher A updated report B'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.sessions WHERE id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-SESSION: household A cannot read session A'; END IF;
  SELECT count(*) INTO v_count FROM public.sessions WHERE id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-SESSION: household A sees session B'; END IF;
  SELECT count(*) INTO v_count FROM public.session_participants WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-PARTICIPANTS: household A cannot read its student participant'; END IF;
  SELECT count(*) INTO v_count FROM public.session_participants WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-PARTICIPANTS: household A sees roster B'; END IF;
  SELECT count(*) INTO v_count FROM public.session_events WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-SESSION-EVENT: household A cannot read event A'; END IF;
  SELECT count(*) INTO v_count FROM public.session_events WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-SESSION-EVENT: household A sees event B'; END IF;
  SELECT count(*) INTO v_count FROM public.session_recordings WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-RECORDING: household A cannot read recording A'; END IF;
  SELECT count(*) INTO v_count FROM public.session_recordings WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-RECORDING: household A sees recording B'; END IF;
  SELECT count(*) INTO v_count FROM public.lesson_reports WHERE id = 'c2a2e000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-LESSON-REPORT: household A cannot read report A'; END IF;
  SELECT count(*) INTO v_count FROM public.lesson_reports WHERE id = 'c2a2e000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-LESSON-REPORT: household A sees report B'; END IF;
  SELECT count(*) INTO v_count FROM public.makharij_findings WHERE lesson_report_id = 'c2a2e000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-MAKHARIJ: household A cannot read finding A'; END IF;
  SELECT count(*) INTO v_count FROM public.makharij_findings WHERE lesson_report_id = 'c2a2e000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-MAKHARIJ: household A sees finding B'; END IF;
  UPDATE public.makharij_findings SET finding = finding
   WHERE lesson_report_id = 'c2a2e000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-MAKHARIJ-WRITE: household A updated finding B'; END IF;
  UPDATE public.session_recordings SET size_bytes = size_bytes
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-RECORDING-WRITE: household A updated recording B'; END IF;
  RESET ROLE;
END $$;

-- Les creneaux dates restent visibles a l'enseignant proprietaire et aux
-- parties de son affectation, jamais au foyer/enseignant B.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.availability_slots
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-AVAILABILITY-SLOT: teacher A slot not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.availability_slots
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000006';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-AVAILABILITY-READ: teacher B slot visible'; END IF;
  UPDATE public.availability_slots SET ends_at = ends_at + interval '1 minute'
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-AVAILABILITY-WRITE: teacher A cannot update own slot'; END IF;
  UPDATE public.availability_slots SET ends_at = ends_at + interval '1 minute'
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000006';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-AVAILABILITY-WRITE: teacher A updated slot B'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.availability_slots
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-ASSIGNED-AVAILABILITY: household A cannot read assigned teacher'; END IF;
  SELECT count(*) INTO v_count FROM public.availability_slots
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000006';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ASSIGNED-AVAILABILITY: household A sees teacher B'; END IF;
  RESET ROLE;
END $$;

-- Reglages/propositions visibles aux seules parties concernees; les insertions
-- des tables fonctionnelles gardent leurs capacites precises par policy.
DO $$
DECLARE v_count integer; v_rows integer; v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);

  SELECT count(*) INTO v_count FROM public.rule_overrides
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-RULE-OVERRIDE: foyer A override not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.rule_overrides
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-RULE-OVERRIDE-READ: foyer B override visible'; END IF;
  v_rows := 0;
  BEGIN
    UPDATE public.rule_overrides SET ended_at = now(), ended_by = auth.uid(), end_reason = 'codex2'
     WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-RULE-OVERRIDE-WRITE: guardian A closed B override'; END IF;

  SELECT count(*) INTO v_count FROM public.matching_requests
   WHERE subject_profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-MATCHING-REQUEST: foyer A request not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.matching_requests
   WHERE subject_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-MATCHING-REQUEST-READ: foyer B request visible'; END IF;
  v_denied := false;
  v_rows := 0;
  BEGIN
    UPDATE public.matching_requests SET status = 'rejected'
     WHERE subject_profile_id = 'c2a20000-0000-0000-0000-000000000002';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-MATCHING-REQUEST-WRITE: guardian A decided B request'; END IF;

  SELECT count(*) INTO v_count FROM public.weekly_availability
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-WEEKLY-AVAILABILITY: foyer A availability not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.weekly_availability
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WEEKLY-READ: foyer B availability visible'; END IF;
  INSERT INTO public.weekly_availability (profile_id, weekday, hour_local)
  VALUES ('c2a20000-0000-0000-0000-000000000004', 3, 12);
  v_denied := false;
  BEGIN
    INSERT INTO public.weekly_availability (profile_id, weekday, hour_local)
    VALUES ('c2a20000-0000-0000-0000-000000000002', 3, 13);
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WEEKLY-INSERT: guardian A scheduled student B'; END IF;

  SELECT count(*) INTO v_count FROM public.prayer_settings
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PRAYER-SETTINGS: assigned teacher A settings not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.prayer_settings
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000006';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PRAYER-READ: teacher B settings visible'; END IF;
  RESET ROLE;
END $$;

-- L'enseignant lit et modifie ses reglages de priere, pas ceux de B.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  UPDATE public.prayer_settings SET pause_minutes = 20
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PRAYER-WRITE: teacher A could not update own settings'; END IF;
  UPDATE public.prayer_settings SET pause_minutes = 25
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000006';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PRAYER-WRITE: teacher A updated teacher B settings'; END IF;
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

-- Les donnees financieres lisibles par un foyer ne franchissent pas sa frontiere;
-- le tuteur ne dispose d'aucune policy d'ecriture sur ces quatre relations.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);

  SELECT count(*) INTO v_count FROM public.wallets
   WHERE household_id = 'c2a2ffff-0000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-WALLET: household A wallet not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.wallets
   WHERE household_id = 'c2a2ffff-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WALLET-READ: household B wallet visible'; END IF;
  UPDATE public.wallets SET currency = currency
   WHERE household_id = 'c2a2ffff-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WALLET-WRITE: guardian A updated wallet B'; END IF;

  SELECT count(*) INTO v_count FROM public.wallet_entries
   WHERE wallet_id = 'c2a2ffff-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-WALLET-ENTRY: household A entry not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.wallet_entries
   WHERE wallet_id = 'c2a2ffff-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WALLET-ENTRY-READ: household B entry visible'; END IF;
  UPDATE public.wallet_entries SET amount_minor = amount_minor
   WHERE wallet_id = 'c2a2ffff-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-WALLET-ENTRY-WRITE: guardian A updated entry B'; END IF;

  SELECT count(*) INTO v_count FROM public.payout_methods
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PAYOUT-METHOD: household A method not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.payout_methods
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PAYOUT-METHOD-READ: household B method visible'; END IF;
  UPDATE public.payout_methods SET details = details
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PAYOUT-METHOD-WRITE: guardian A updated method B'; END IF;

  SELECT count(*) INTO v_count FROM public.payouts
   WHERE wallet_id = 'c2a2ffff-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PAYOUT: household A payout not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.payouts
   WHERE wallet_id = 'c2a2ffff-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PAYOUT-READ: household B payout visible'; END IF;
  UPDATE public.payouts SET amount_minor = amount_minor
   WHERE wallet_id = 'c2a2ffff-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PAYOUT-WRITE: guardian A updated payout B'; END IF;
  RESET ROLE;
END $$;

-- Les parties d'une affectation voient leur cours planifie, pas l'affectation B.
DO $$
DECLARE v_count integer; v_rows integer; v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.teacher_student_assignments
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-ASSIGNMENT: teacher A assignment not visible'; END IF;
  SELECT count(*) INTO v_count FROM public.teacher_student_assignments
   WHERE student_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ASSIGNMENT-READ: teacher A sees assignment B'; END IF;
  v_rows := 0;
  BEGIN
    UPDATE public.teacher_student_assignments SET ended_at = now(), ended_by = auth.uid(), end_reason = 'codex2'
     WHERE student_id = 'c2a20000-0000-0000-0000-000000000002';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ASSIGNMENT-WRITE: teacher A ended assignment B'; END IF;
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
