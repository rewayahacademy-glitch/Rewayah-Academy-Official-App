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


INSERT INTO auth.users (id, email) VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'codex2-guardian-a@example.test'),
  ('c2a20000-0000-0000-0000-000000000002', 'codex2-student-b@example.test'),
  ('c2a20000-0000-0000-0000-000000000003', 'codex2-disabled-a@example.test');

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
   'c2a2ffff-0000-0000-0000-000000000001', 'Gardien', 'Suspendu', 'disabled');

INSERT INTO public.devices (profile_id, device_fingerprint, platform) VALUES
  ('c2a20000-0000-0000-0000-000000000002', 'codex2-device-other-household', 'web');

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
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.households
   WHERE id = 'c2a2ffff-0000-0000-0000-000000000001';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-NO-ROLE-CLAIM : foyer visible sans claim role'; END IF;
  RESET ROLE;
END $$;

DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000003', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.households
   WHERE id = 'c2a2ffff-0000-0000-0000-000000000001';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-DISABLED-ACCOUNT : compte disabled lit son foyer'; END IF;
  SELECT count(*) INTO v_count FROM public.profiles
   WHERE id = 'c2a20000-0000-0000-0000-000000000001';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-DISABLED-ACCOUNT-PROFILES : compte disabled lit des profils'; END IF;
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

ROLLBACK;