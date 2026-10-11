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
  ('c2a20000-0000-0000-0000-000000000006', 'codex2-teacher-b@example.test'),
  ('c2a20000-0000-0000-0000-000000000007', 'codex2-admin@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('c2a2ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('c2a2ffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('c2a2ffff-0000-0000-0000-000000000003', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'COD2-GUARD-A', 'guardian',
   'c2a2ffff-0000-0000-0000-000000000001', 'Gardien', 'A', 'active', 'male'),
  ('c2a20000-0000-0000-0000-000000000002', 'COD2-STUD-B', 'student',
   'c2a2ffff-0000-0000-0000-000000000002', 'Eleve', 'B', 'active', 'female'),
  ('c2a20000-0000-0000-0000-000000000003', 'COD2-GUARD-DISABLED', 'guardian',
   'c2a2ffff-0000-0000-0000-000000000001', 'Gardien', 'Suspendu', 'disabled', 'male'),
  ('c2a20000-0000-0000-0000-000000000004', 'COD2-STUD-A', 'student',
   'c2a2ffff-0000-0000-0000-000000000001', 'Eleve', 'A', 'active', 'male'),
  ('c2a20000-0000-0000-0000-000000000005', 'COD2-TEACH-A', 'teacher',
   'c2a2ffff-0000-0000-0000-000000000003', 'Enseignant', 'A', 'active', 'male'),
  ('c2a20000-0000-0000-0000-000000000006', 'COD2-TEACH-B', 'teacher',
   'c2a2ffff-0000-0000-0000-000000000002', 'Enseignant', 'B', 'active', 'female'),
  ('c2a20000-0000-0000-0000-000000000007', 'COD2-ADMIN', 'admin',
   'c2a2ffff-0000-0000-0000-000000000001', 'Administrateur', 'Codex2', 'active', 'male');

INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key) VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'id_card', 'male', 'codex2/kyc-a'),
  ('c2a20000-0000-0000-0000-000000000002', 'id_card', 'female', 'codex2/kyc-b');

INSERT INTO public.student_profiles (profile_id) VALUES
  ('c2a20000-0000-0000-0000-000000000002'),
  ('c2a20000-0000-0000-0000-000000000004');
INSERT INTO public.teacher_profiles (profile_id) VALUES
  ('c2a20000-0000-0000-0000-000000000005'),
  ('c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.programme_versions (id, statut, numero_version, cree_par) VALUES
  ('c2a2f000-3000-0000-0000-000000000001', 'brouillon', 9902, 'c2a20000-0000-0000-0000-000000000007');
INSERT INTO public.programme_niveaux (id, version_id, code_technique, nom_humain, cycle, ordre) VALUES
  ('c2a2f100-3000-0000-0000-000000000001', 'c2a2f000-3000-0000-0000-000000000001', 'COD2-A', 'Niveau A', 'Codex2', 1),
  ('c2a2f100-3000-0000-0000-000000000002', 'c2a2f000-3000-0000-0000-000000000001', 'COD2-B', 'Niveau B', 'Codex2', 2);
INSERT INTO public.progression_historique
  (id, student_id, niveau_id, type_mouvement, decide_par, motif) VALUES
  ('c2a2f200-3000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'c2a2f100-3000-0000-0000-000000000001', 'diagnostic_initial', 'c2a20000-0000-0000-0000-000000000007', 'codex2 A'),
  ('c2a2f200-3000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'c2a2f100-3000-0000-0000-000000000002', 'diagnostic_initial', 'c2a20000-0000-0000-0000-000000000007', 'codex2 B');
INSERT INTO public.progression_exceptions (id, student_id, type, motif, cree_par) VALUES
  ('c2a2f300-3000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'blocage', 'codex2 A', 'c2a20000-0000-0000-0000-000000000007'),
  ('c2a2f300-3000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'derogation', 'codex2 B', 'c2a20000-0000-0000-0000-000000000007');
INSERT INTO public.evaluations (id, student_id, niveau_id, type, date_prevue) VALUES
  ('c2a2f400-3000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'c2a2f100-3000-0000-0000-000000000001', 'initiale', '2026-10-15'),
  ('c2a2f400-3000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'c2a2f100-3000-0000-0000-000000000002', 'initiale', '2026-10-16');
INSERT INTO public.controles_qualite (id, type_anomalie, ref_table, ref_id) VALUES
  ('c2a2f500-3000-0000-0000-000000000001', 'blocage_sans_suivi', 'progression_exceptions', 'c2a2f300-3000-0000-0000-000000000001'),
  ('c2a2f500-3000-0000-0000-000000000002', 'blocage_sans_suivi', 'progression_exceptions', 'c2a2f300-3000-0000-0000-000000000002');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local) VALUES
  ('c2a2a000-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005', 'enfant', 5, 'Codex2 A', 1, 10),
  ('c2a2a000-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006', 'enfant', 5, 'Codex2 B', 2, 11);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('c2a2a000-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004'),
  ('c2a2a000-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002');
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale,
   duree_minutes, etat, created_by, publiee_at, publiee_par) VALUES
  ('c2a2a200-2000-0000-0000-000000000001', 'enfant', 'francais', 'Europe/Paris', ARRAY[1,3,5]::smallint[], 18,
   60, 'publiee', 'c2a20000-0000-0000-0000-000000000007', now(), 'c2a20000-0000-0000-0000-000000000007'),
  ('c2a2a200-2000-0000-0000-000000000002', 'enfant', 'francais', 'Europe/Paris', ARRAY[2,4,6]::smallint[], 19,
   60, 'publiee', 'c2a20000-0000-0000-0000-000000000007', now(), 'c2a20000-0000-0000-0000-000000000007');
INSERT INTO public.intentions_horaire
  (id, eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by) VALUES
  ('c2a2a300-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'c2a2a200-2000-0000-0000-000000000001',
   'Europe/Paris', 18, ARRAY[1,3,5]::smallint[], 'c2a20000-0000-0000-0000-000000000001'),
  ('c2a2a300-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'c2a2a200-2000-0000-0000-000000000002',
   'Europe/Paris', 19, ARRAY[2,4,6]::smallint[], 'c2a20000-0000-0000-0000-000000000002');
-- La migration copie automatiquement l'ancre de chaque groupe dans
-- groupe_creneaux; ces deux lignes servent de temoins A/B.
INSERT INTO public.recurrence_rules (id, local_time, timezone_iana, rule) VALUES
  ('c2a2a100-2000-0000-0000-000000000001', '10:00', 'Europe/Paris', 'weekly'),
  ('c2a2a100-2000-0000-0000-000000000002', '11:00', 'Europe/Paris', 'biweekly');
INSERT INTO public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy) VALUES
  ('c2a2b000-2000-0000-0000-000000000001', 'Codex2 resource', 'Codex2', 'quran', 'publique', 'jamais');
INSERT INTO public.library_resource_groupe (resource_id, groupe_id, ajoutee_par) VALUES
  ('c2a2b000-2000-0000-0000-000000000001', 'c2a2a000-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005'),
  ('c2a2b000-2000-0000-0000-000000000001', 'c2a2a000-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.library_reading_position (profile_id, resource_id, type_ancrage, page) VALUES
  ('c2a20000-0000-0000-0000-000000000004', 'c2a2b000-2000-0000-0000-000000000001', 'page', 2),
  ('c2a20000-0000-0000-0000-000000000002', 'c2a2b000-2000-0000-0000-000000000001', 'page', 3);
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
INSERT INTO public.device_pairing_codes
  (student_profile_id, code_hash, created_by, expires_at) VALUES
  ('c2a20000-0000-0000-0000-000000000004', 'codex2-hash-a', 'c2a20000-0000-0000-0000-000000000005', '2026-10-20 00:00:00+00'),
  ('c2a20000-0000-0000-0000-000000000002', 'codex2-hash-b', 'c2a20000-0000-0000-0000-000000000006', '2026-10-20 00:00:00+00');

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
INSERT INTO public.availability_slots (teacher_id, starts_at, ends_at, recurrence_id) VALUES
  ('c2a20000-0000-0000-0000-000000000005', '2026-10-12 10:00:00+00', '2026-10-12 11:00:00+00', 'c2a2a100-2000-0000-0000-000000000001'),
  ('c2a20000-0000-0000-0000-000000000006', '2026-10-13 11:00:00+00', '2026-10-13 12:00:00+00', 'c2a2a100-2000-0000-0000-000000000002');
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
INSERT INTO public.learning_assignment
  (id, group_id, student_id, resource_id, purpose, starts_at, due_at, created_by, status) VALUES
  ('c2a2d000-2000-0000-0000-000000000001', 'c2a2a000-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'c2a2b000-2000-0000-0000-000000000001', 'learn', '2026-10-12 00:00:00+00', '2026-10-19 00:00:00+00', 'c2a20000-0000-0000-0000-000000000005', 'a_faire'),
  ('c2a2d000-2000-0000-0000-000000000002', 'c2a2a000-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'c2a2b000-2000-0000-0000-000000000001', 'review', '2026-10-13 00:00:00+00', '2026-10-20 00:00:00+00', 'c2a20000-0000-0000-0000-000000000006', 'a_faire');
INSERT INTO public.session_shared_content
  (session_id, resource_id, content_position, display_mode, revision, updated_by) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a2b000-2000-0000-0000-000000000001', '{"page":2}', 'page', 1, 'c2a20000-0000-0000-0000-000000000005'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a2b000-2000-0000-0000-000000000001', '{"page":3}', 'page', 1, 'c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.annotation_layer (id, resource_id, session_id, auteur_profile_id, portee) VALUES
  ('c2a2c000-2000-0000-0000-000000000001', 'c2a2b000-2000-0000-0000-000000000001', 'c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005', 'seance'),
  ('c2a2c000-2000-0000-0000-000000000002', 'c2a2b000-2000-0000-0000-000000000001', 'c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006', 'seance');
INSERT INTO public.annotation_trait (layer_id, ancrage, points, outil) VALUES
  ('c2a2c000-2000-0000-0000-000000000001', '{"page":2}', '[{"x":1,"y":2}]', 'stylet'),
  ('c2a2c000-2000-0000-0000-000000000002', '{"page":3}', '[{"x":3,"y":4}]', 'stylet');
INSERT INTO public.annotation_marqueur (layer_id, plage, intention) VALUES
  ('c2a2c000-2000-0000-0000-000000000001', '{"start":1,"end":2}', 'learn'),
  ('c2a2c000-2000-0000-0000-000000000002', '{"start":3,"end":4}', 'review');
INSERT INTO public.guardian_session_visit
  (session_id, groupe_id, observateur_profile_id, role, enfant_profile_id, visit_number, policy_version) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a2a000-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000001', 'guardian_observer', 'c2a20000-0000-0000-0000-000000000004', 1, 'codex2-v1'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a2a000-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'student', 'c2a20000-0000-0000-0000-000000000002', 1, 'codex2-v1');
INSERT INTO public.session_video_route (session_id, provider, ws_url, room_name) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'cloud', 'wss://a.example.invalid', 'codex2-room-a'),
  ('c2a2e000-1000-0000-0000-000000000002', 'cloud', 'wss://b.example.invalid', 'codex2-room-b');
INSERT INTO public.livekit_webhook_deliveries (event_id, event_type, room_name, detail) VALUES
  ('codex2-event-a', 'participant_joined', 'codex2-room-a', '{"source":"fixture"}'),
  ('codex2-event-b', 'participant_joined', 'codex2-room-b', '{"source":"fixture"}');
INSERT INTO public.session_presence_override
  (session_id, profile_id, etat, motif, decide_par) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'excusee', 'codex2 A', 'c2a20000-0000-0000-0000-000000000005'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'excusee', 'codex2 B', 'c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.video_token_grants
  (session_id, profile_id, role, provider, can_publish, can_publish_video, can_publish_data, expire_le) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'student', 'cloud', false, false, true, '2026-10-20 00:00:00+00'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'student', 'cloud', false, false, true, '2026-10-20 00:00:00+00');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005', 'teacher'),
  ('c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004', 'student'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006', 'teacher'),
  ('c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002', 'student');
INSERT INTO public.student_concern
  (categorie, groupe_id, session_id, student_id, teacher_id, internal_details) VALUES
  ('pedagogique', 'c2a2a000-2000-0000-0000-000000000002',
   'c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002',
   'c2a20000-0000-0000-0000-000000000006', 'codex2 internal B');
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

-- Temoins supplementaires pour les relations systeme, rolees, reference et
-- ressources; leurs regles sont distinctes d'une isolation foyer A/B.
INSERT INTO public.fx_rates (from_currency, to_currency, rate, effective_at)
VALUES ('XAA', 'XBB', 1.25, '2026-10-11 00:00:00+00');
INSERT INTO public.webhook_events (external_ref, source, payload)
VALUES ('codex2-webhook-event', 'codex2-test', '{"fixture":true}');
INSERT INTO public.audit_logs (actor, actor_role, action, table_name, row_id, payload, prev_hash, hash, created_at)
VALUES ('c2a20000-0000-0000-0000-000000000007', 'admin', 'codex2_fixture', 'codex2', 'x2-02',
        '{"fixture":true}', '', 'codex2-audit-hash', '2099-12-31 00:00:00+00');
INSERT INTO public.id_sequences (code, last_value)
VALUES ('codex2-fixture', 1);
INSERT INTO public.app_config_history (key, old_value, new_value, changed_by)
VALUES ('codex2-fixture', NULL, 'true', 'c2a20000-0000-0000-0000-000000000007');
INSERT INTO public.rate_limits (bucket, tokens)
VALUES ('codex2-fixture', 1);
INSERT INTO public.device_tokens (profile_id, token, platform) VALUES
  ('c2a20000-0000-0000-0000-000000000001', 'codex2-device-token-a', 'web'),
  ('c2a20000-0000-0000-0000-000000000002', 'codex2-device-token-b', 'web');
INSERT INTO public.jetons_agent
  (id, libelle, prefixe, empreinte, profil_observe, parcours, expire_le, cree_par, cree_le)
VALUES ('c2a2d000-0000-0000-0000-000000000001', 'Codex2 fixture', 'rag_c2test01', repeat('a', 64),
        'c2a20000-0000-0000-0000-000000000001', 'guardian', now() + interval '1 hour',
        'c2a20000-0000-0000-0000-000000000007', now());

INSERT INTO public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy) VALUES
  ('c2a2b000-2000-0000-0000-000000000011', 'Codex2 group A', 'C2A', 'lesson', 'groupe_assigne', 'jamais'),
  ('c2a2b000-2000-0000-0000-000000000012', 'Codex2 group B', 'C2B', 'lesson', 'groupe_assigne', 'jamais');
INSERT INTO public.library_resource_groupe (resource_id, groupe_id, ajoutee_par) VALUES
  ('c2a2b000-2000-0000-0000-000000000011', 'c2a2a000-2000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000005'),
  ('c2a2b000-2000-0000-0000-000000000012', 'c2a2a000-2000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000006');
INSERT INTO public.resource_version
  (id, resource_id, numero_version, statut, publiee_le, publiee_par, empreinte) VALUES
  ('c2a2b100-2000-0000-0000-000000000011', 'c2a2b000-2000-0000-0000-000000000011', 1, 'publiee', now(), 'c2a20000-0000-0000-0000-000000000005', 'codex2-version-a'),
  ('c2a2b100-2000-0000-0000-000000000012', 'c2a2b000-2000-0000-0000-000000000012', 1, 'publiee', now(), 'c2a20000-0000-0000-0000-000000000006', 'codex2-version-b');
INSERT INTO public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, origine) VALUES
  ('c2a2b200-2000-0000-0000-000000000011', 'c2a2b100-2000-0000-0000-000000000011', 'pdf', 'codex2/asset-a', 16, 'importe_tel_quel'),
  ('c2a2b200-2000-0000-0000-000000000012', 'c2a2b100-2000-0000-0000-000000000012', 'pdf', 'codex2/asset-b', 16, 'importe_tel_quel');
UPDATE public.resource_version SET download_asset_id = id
 WHERE id IN ('c2a2b100-2000-0000-0000-000000000011', 'c2a2b100-2000-0000-0000-000000000012');
UPDATE public.library_resource SET current_version_id = resource_version.id
  FROM public.resource_version
 WHERE public.library_resource.id = resource_version.resource_id
   AND public.library_resource.id IN ('c2a2b000-2000-0000-0000-000000000011', 'c2a2b000-2000-0000-0000-000000000012');

-- Les tables operationnelles/admin ne doivent exposer aucune des lignes
-- temoins aux comptes de foyer, y compris la partition physique d'audit.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.fx_rates WHERE from_currency = 'XAA';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-ADMIN-FX-RATES: guardian reads system rate'; END IF;
  SELECT count(*) INTO v_count FROM public.webhook_events WHERE external_ref = 'codex2-webhook-event';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-ADMIN-WEBHOOK: guardian reads webhook'; END IF;
  SELECT count(*) INTO v_count FROM public.audit_logs WHERE action = 'codex2_fixture';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-ADMIN-AUDIT: guardian reads audit row'; END IF;
  SELECT count(*) INTO v_count FROM public.audit_logs_default WHERE action = 'codex2_fixture';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-AUDIT-PARTITION: guardian reads physical partition'; END IF;
  SELECT count(*) INTO v_count FROM public.id_sequences WHERE code = 'codex2-fixture';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-SEQUENCE: guardian reads sequence'; END IF;
  SELECT count(*) INTO v_count FROM public.app_config_history WHERE key = 'codex2-fixture';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-ADMIN-CONFIG-HISTORY: guardian reads config history'; END IF;
  SELECT count(*) INTO v_count FROM public.rate_limits WHERE bucket = 'codex2-fixture';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-RATE-LIMIT: guardian reads rate limit'; END IF;
  SELECT count(*) INTO v_count FROM public.device_tokens WHERE token LIKE 'codex2-device-token-%';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-DEVICE-TOKEN: guardian reads device token'; END IF;
  SELECT count(*) INTO v_count FROM public.jetons_agent WHERE prefixe = 'rag_c2test01';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-ADMIN-AGENT-TOKEN: guardian reads agent token'; END IF;
  BEGIN
    UPDATE public.fx_rates SET rate = rate WHERE from_currency = 'XAA';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_rows := 0;
  END;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-ADMIN-FX-WRITE: guardian updated rate'; END IF;
  RESET ROLE;
END $$;

-- Les lectures explicitement reservees a l'administration restent positives.
DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000007', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin","household_id":"c2a2ffff-0000-0000-0000-000000000007"}}', true);
  SELECT count(*) INTO v_count FROM public.fx_rates WHERE from_currency = 'XAA';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-FX-RATES-POSITIVE: admin cannot read rate'; END IF;
  SELECT count(*) INTO v_count FROM public.webhook_events WHERE external_ref = 'codex2-webhook-event';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-WEBHOOK-POSITIVE: admin cannot read webhook'; END IF;
  SELECT count(*) INTO v_count FROM public.audit_logs WHERE action = 'codex2_fixture';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-AUDIT-POSITIVE: admin cannot read audit row'; END IF;
  SELECT count(*) INTO v_count FROM public.app_config WHERE key = 'max_participants_per_session';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-CONFIG-POSITIVE: admin cannot read config'; END IF;
  SELECT count(*) INTO v_count FROM public.app_config_history WHERE key = 'codex2-fixture';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-CONFIG-HISTORY-POSITIVE: admin cannot read history'; END IF;
  SELECT count(*) INTO v_count FROM public.jetons_agent WHERE prefixe = 'rag_c2test01';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-AGENT-TOKEN-POSITIVE: admin cannot read agent token'; END IF;
  RESET ROLE;
END $$;

-- Les cinq tables Quran sont des references globales: les deux foyers lisent
-- les memes lignes de corpus; leur partage ne constitue pas une fuite foyer.
DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.mushaf WHERE code = 'madina-hafs-604';
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-MUSHAF: guardian A cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.sourate WHERE numero = 2;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-SOURATE: guardian A cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.juz LIMIT 1;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-JUZ: guardian A cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.page_mushaf WHERE mushaf_id = (SELECT id FROM public.mushaf WHERE code = 'madina-hafs-604') AND numero = 2;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-PAGE: guardian A cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.verset WHERE sourate_numero = 2 AND numero = 1;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-VERSET: guardian A cannot read corpus'; END IF;
  RESET ROLE;
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000002"}}', true);
  SELECT count(*) INTO v_count FROM public.mushaf WHERE code = 'madina-hafs-604';
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-MUSHAF-B: guardian B cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.sourate WHERE numero = 2;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-SOURATE-B: guardian B cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.juz;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-JUZ-B: guardian B cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.page_mushaf WHERE mushaf_id = (SELECT id FROM public.mushaf WHERE code = 'madina-hafs-604') AND numero = 2;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-PAGE-B: guardian B cannot read corpus'; END IF;
  SELECT count(*) INTO v_count FROM public.verset WHERE sourate_numero = 2 AND numero = 1;
  IF v_count = 0 THEN RAISE EXCEPTION 'RLS-SHARED-VERSET-B: guardian B cannot read corpus'; END IF;
  RESET ROLE;
END $$;

-- Les ressources assignees, leurs versions et artefacts suivent le groupe;
-- les deux foyers ont un temoin positif et ne voient pas l'autre groupe.
DO $$
DECLARE v_count integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.library_resource WHERE id = 'c2a2b000-2000-0000-0000-000000000011';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-RESOURCE-GROUP-A: assigned resource invisible'; END IF;
  SELECT count(*) INTO v_count FROM public.library_resource WHERE id = 'c2a2b000-2000-0000-0000-000000000012';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-RESOURCE-GROUP-CROSS: group B resource visible'; END IF;
  SELECT count(*) INTO v_count FROM public.resource_version WHERE id = 'c2a2b100-2000-0000-0000-000000000011';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-RESOURCE-VERSION-A: assigned version invisible'; END IF;
  SELECT count(*) INTO v_count FROM public.resource_version WHERE id = 'c2a2b100-2000-0000-0000-000000000012';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-RESOURCE-VERSION-CROSS: group B version visible'; END IF;
  SELECT count(*) INTO v_count FROM public.download_asset WHERE id = 'c2a2b200-2000-0000-0000-000000000011';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-DOWNLOAD-ASSET-A: assigned asset invisible'; END IF;
  SELECT count(*) INTO v_count FROM public.download_asset WHERE id = 'c2a2b200-2000-0000-0000-000000000012';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-DOWNLOAD-ASSET-CROSS: group B asset visible'; END IF;
  RESET ROLE;
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000002"}}', true);
  SELECT count(*) INTO v_count FROM public.library_resource WHERE id = 'c2a2b000-2000-0000-0000-000000000012';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-RESOURCE-GROUP-B: assigned resource invisible'; END IF;
  SELECT count(*) INTO v_count FROM public.library_resource WHERE id = 'c2a2b000-2000-0000-0000-000000000011';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-RESOURCE-GROUP-REVERSE-CROSS: group A resource visible'; END IF;
  RESET ROLE;
END $$;

-- Anon est re-exerce apres le seed pour inclure les lignes representatives.
DO $$
DECLARE v_table regclass; v_visible boolean;
BEGIN
  FOR v_table IN
    SELECT c.oid::regclass FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relrowsecurity
      AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
    ORDER BY c.oid::regclass::text
  LOOP
    v_visible := false;
    BEGIN
      SET LOCAL ROLE anon;
      EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s)', v_table) INTO v_visible;
      RESET ROLE;
    EXCEPTION WHEN insufficient_privilege THEN
      RESET ROLE;
      v_visible := false;
    END;
    IF v_visible THEN
      INSERT INTO codex2_rls_violations VALUES ('anon-read-after-seed', v_table::text);
    END IF;
  END LOOP;
END $$;

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

-- La trace du jeton n'est visible que par le participant auquel elle appartient.
DO $$
DECLARE v_count integer; v_rows integer; v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000004', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"student","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.video_token_grants
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-VIDEO-TOKEN: student A cannot read own token trace'; END IF;
  SELECT count(*) INTO v_count FROM public.video_token_grants
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-VIDEO-TOKEN: student A sees token trace B'; END IF;
  BEGIN
    UPDATE public.video_token_grants SET hidden = hidden
     WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
    v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-VIDEO-TOKEN-WRITE: student A updated trace B'; END IF;
  RESET ROLE;
END $$;

-- Le tuteur ne peut deposer un document KYC que pour son propre foyer.
DO $$
DECLARE v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
  VALUES ('c2a20000-0000-0000-0000-000000000001', 'passport', 'male', 'codex2/kyc-a-upload');
  BEGIN
    INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
    VALUES ('c2a20000-0000-0000-0000-000000000002', 'passport', 'female', 'codex2/kyc-b-cross');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-KYC-INSERT: guardian A inserted KYC for B'; END IF;
  RESET ROLE;
END $$;

DO $$
DECLARE v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000003', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  BEGIN
    INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
    VALUES ('c2a20000-0000-0000-0000-000000000003', 'passport', 'male', 'codex2/kyc-disabled');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-DISABLED-KYC-INSERT: disabled guardian submitted KYC'; END IF;
  RESET ROLE;
END $$;

-- Les corrections de presence sont lisibles/ecrites par l'enseignant de la
-- seance, jamais par celui d'une autre seance.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.session_presence_override
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PRESENCE-OVERRIDE: teacher A cannot read own correction'; END IF;
  SELECT count(*) INTO v_count FROM public.session_presence_override
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PRESENCE-OVERRIDE-READ: teacher A sees correction B'; END IF;
  UPDATE public.session_presence_override SET motif = motif
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PRESENCE-OVERRIDE-WRITE: teacher A cannot update own correction'; END IF;
  UPDATE public.session_presence_override SET motif = motif
   WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PRESENCE-OVERRIDE-WRITE: teacher A updated correction B'; END IF;
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
DECLARE v_visible_tables text;
BEGIN
  SELECT string_agg(table_name, ', ' ORDER BY table_name)
    INTO v_visible_tables
    FROM codex2_rls_violations
   WHERE scenario = 'disabled-account';
  IF v_visible_tables IS NOT NULL THEN
    RAISE EXCEPTION 'RLS-DISABLED-ACCOUNT: compte désactivé peut lire : %', v_visible_tables;
  END IF;
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

-- Les groupes et leurs membres sont visibles a l'enseignant proprietaire et
-- au foyer du membre; les mutations directes sont reservees aux RPC.
DO $$
DECLARE v_count integer; v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.groupes WHERE id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-GROUP: teacher A cannot read own group'; END IF;
  SELECT count(*) INTO v_count FROM public.groupes WHERE id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-GROUP-READ: teacher A sees group B'; END IF;
  BEGIN
    UPDATE public.groupes SET libelle = libelle WHERE id = 'c2a2a000-2000-0000-0000-000000000002';
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-GROUP-DIRECT-WRITE: authenticated teacher updated a group'; END IF;
  v_denied := false;
  SELECT count(*) INTO v_count FROM public.groupe_membres WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-GROUP-MEMBER: teacher A cannot read own roster'; END IF;
  SELECT count(*) INTO v_count FROM public.groupe_membres WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-GROUP-MEMBER-READ: teacher A sees roster B'; END IF;
  BEGIN
    UPDATE public.groupe_membres SET left_at = now()
     WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-GROUP-MEMBER-DIRECT-WRITE: authenticated teacher updated a roster'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.groupes WHERE id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-GROUP: household A cannot read group of its student'; END IF;
  SELECT count(*) INTO v_count FROM public.groupes WHERE id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-GROUP: household A sees group B'; END IF;
  SELECT count(*) INTO v_count FROM public.groupe_membres WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-GROUP-MEMBER: household A cannot read its student membership'; END IF;
  SELECT count(*) INTO v_count FROM public.groupe_membres WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-GROUP-MEMBER: household A sees roster B'; END IF;
  RESET ROLE;
END $$;

-- Un retour de seance est deposable par le participant, mais la table brute
-- reste privee aux administrateurs et aucun second foyer ne peut voter.
DO $$
DECLARE v_denied boolean := false;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  INSERT INTO public.session_feedback (session_id, groupe_id, question_id, reponse)
  VALUES ('c2a2e000-1000-0000-0000-000000000001', 'c2a2a000-2000-0000-0000-000000000001', 'codex2-q1', 'bien');
  BEGIN
    INSERT INTO public.session_feedback (session_id, groupe_id, question_id, reponse)
    VALUES ('c2a2e000-1000-0000-0000-000000000002', 'c2a2a000-2000-0000-0000-000000000002', 'codex2-q1', 'bien');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FEEDBACK-INSERT: participant A voted for session B'; END IF;
  RESET ROLE;
END $$;

-- Un signalement n'est ecrit que par l'enseignant du groupe et de la seance.
DO $$
DECLARE v_count integer; v_denied boolean := false; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  INSERT INTO public.student_concern
    (categorie, groupe_id, session_id, student_id, teacher_id, internal_details)
  VALUES ('pedagogique', 'c2a2a000-2000-0000-0000-000000000001',
          'c2a2e000-1000-0000-0000-000000000001', 'c2a20000-0000-0000-0000-000000000004',
          'c2a20000-0000-0000-0000-000000000005', 'codex2 internal A');
  BEGIN
    INSERT INTO public.student_concern
      (categorie, groupe_id, session_id, student_id, teacher_id, internal_details)
    VALUES ('pedagogique', 'c2a2a000-2000-0000-0000-000000000002',
            'c2a2e000-1000-0000-0000-000000000002', 'c2a20000-0000-0000-0000-000000000002',
            'c2a20000-0000-0000-0000-000000000005', 'codex2 cross B');
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-CONCERN-INSERT: teacher A wrote concern for B'; END IF;
  SELECT count(*) INTO v_count FROM public.student_concern
   WHERE teacher_id = 'c2a20000-0000-0000-0000-000000000005';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-CONCERN-READ: teacher A cannot read own concern'; END IF;
  SELECT count(*) INTO v_count FROM public.student_concern
   WHERE student_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-CONCERN-READ: teacher A sees concern B'; END IF;
  UPDATE public.student_concern SET internal_details = internal_details
   WHERE student_id = 'c2a20000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-CONCERN-WRITE: teacher A updated concern B'; END IF;
  RESET ROLE;
END $$;

-- La progression de lecture dans la bibliotheque appartient au profil lui-meme.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000004', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"student","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.library_reading_position
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-LIBRARY-POSITION: student A cannot read own progress'; END IF;
  SELECT count(*) INTO v_count FROM public.library_reading_position
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LIBRARY-POSITION-READ: student A sees B progress'; END IF;
  UPDATE public.library_reading_position SET page = page
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000004';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-LIBRARY-POSITION-WRITE: student A cannot update own progress'; END IF;
  UPDATE public.library_reading_position SET page = page
   WHERE profile_id = 'c2a20000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LIBRARY-POSITION-WRITE: student A updated B progress'; END IF;
  RESET ROLE;
END $$;

-- Une ressource affectee ne suit que le groupe A, pour son enseignant et son foyer.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.library_resource_groupe WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-LIBRARY-GROUP: teacher A cannot read own resource assignment'; END IF;
  SELECT count(*) INTO v_count FROM public.library_resource_groupe WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LIBRARY-GROUP-READ: teacher A sees B resource assignment'; END IF;
  UPDATE public.library_resource_groupe SET epinglee = epinglee WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LIBRARY-GROUP-WRITE: teacher A changed B assignment'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.library_resource_groupe WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-LIBRARY-GROUP: household A cannot read assigned resource'; END IF;
  SELECT count(*) INTO v_count FROM public.library_resource_groupe WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-LIBRARY-GROUP: household A sees B assignment'; END IF;
  RESET ROLE;
END $$;

-- Les visites d'observation ne sont lisibles que par leur observateur.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.guardian_session_visit
   WHERE observateur_profile_id = 'c2a20000-0000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-GUARDIAN-VISIT: guardian A cannot read own visit'; END IF;
  SELECT count(*) INTO v_count FROM public.guardian_session_visit
   WHERE observateur_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-GUARDIAN-VISIT-READ: guardian A sees B visit'; END IF;
  UPDATE public.guardian_session_visit SET left_at = now()
   WHERE observateur_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-GUARDIAN-VISIT-WRITE: guardian A updated B visit'; END IF;
  RESET ROLE;
END $$;

-- Les devoirs suivent le groupe: enseignant et foyer A voient A, pas B.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.learning_assignment WHERE id = 'c2a2d000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-LEARNING-ASSIGNMENT: teacher A cannot read own assignment'; END IF;
  SELECT count(*) INTO v_count FROM public.learning_assignment WHERE id = 'c2a2d000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LEARNING-ASSIGNMENT-READ: teacher A sees assignment B'; END IF;
  UPDATE public.learning_assignment SET status = status WHERE id = 'c2a2d000-2000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-LEARNING-ASSIGNMENT-WRITE: teacher A cannot update own assignment'; END IF;
  UPDATE public.learning_assignment SET status = status WHERE id = 'c2a2d000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-LEARNING-ASSIGNMENT-WRITE: teacher A updated assignment B'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.learning_assignment WHERE id = 'c2a2d000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-FAMILY-LEARNING-ASSIGNMENT: guardian A cannot read assignment for own student'; END IF;
  SELECT count(*) INTO v_count FROM public.learning_assignment WHERE id = 'c2a2d000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-LEARNING-ASSIGNMENT: guardian A sees assignment B'; END IF;
  UPDATE public.learning_assignment SET status = status WHERE id = 'c2a2d000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-FAMILY-LEARNING-ASSIGNMENT-WRITE: guardian A updated assignment B'; END IF;
  RESET ROLE;
END $$;

-- Le contenu de seance est lisible par les participants de cette seance;
-- son ecriture directe reste reservee a la RPC.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.session_shared_content WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-SHARED-CONTENT: teacher A cannot read own session content'; END IF;
  SELECT count(*) INTO v_count FROM public.session_shared_content WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-SHARED-CONTENT: teacher A sees session B content'; END IF;
  UPDATE public.session_shared_content SET revision = revision WHERE session_id = 'c2a2e000-1000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-SHARED-CONTENT-DIRECT-WRITE: teacher A updated content outside the RPC'; END IF;
  RESET ROLE;
END $$;

-- Les couches d'annotation et leurs enfants sont accessibles a leur auteur,
-- jamais a l'enseignant d'un autre foyer/seance.
DO $$
DECLARE v_count integer; v_rows integer; v_denied boolean;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.annotation_layer WHERE id = 'c2a2c000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-ANNOTATION-LAYER: teacher A cannot read own layer'; END IF;
  SELECT count(*) INTO v_count FROM public.annotation_layer WHERE id = 'c2a2c000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-LAYER: teacher A sees layer B'; END IF;
  UPDATE public.annotation_layer SET maj_le = maj_le WHERE id = 'c2a2c000-2000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-ANNOTATION-LAYER-WRITE: teacher A cannot update own layer'; END IF;
  UPDATE public.annotation_layer SET maj_le = maj_le WHERE id = 'c2a2c000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-LAYER-WRITE: teacher A updated layer B'; END IF;

  SELECT count(*) INTO v_count FROM public.annotation_trait WHERE layer_id = 'c2a2c000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-ANNOTATION-TRAIT: teacher A cannot read own trait'; END IF;
  SELECT count(*) INTO v_count FROM public.annotation_trait WHERE layer_id = 'c2a2c000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-TRAIT-READ: teacher A sees trait B'; END IF;
  INSERT INTO public.annotation_trait (layer_id, ancrage, points, outil)
  VALUES ('c2a2c000-2000-0000-0000-000000000001', '{"page":2}', '[{"x":5,"y":6}]', 'stylet');
  v_denied := false;
  BEGIN
    INSERT INTO public.annotation_trait (layer_id, ancrage, points, outil)
    VALUES ('c2a2c000-2000-0000-0000-000000000002', '{"page":3}', '[{"x":7,"y":8}]', 'stylet');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-TRAIT-WRITE: teacher A wrote trait B'; END IF;
  UPDATE public.annotation_trait SET points = points WHERE layer_id = 'c2a2c000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-TRAIT-UPDATE: teacher A updated trait B'; END IF;

  SELECT count(*) INTO v_count FROM public.annotation_marqueur WHERE layer_id = 'c2a2c000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-ANNOTATION-MARKER: teacher A cannot read own marker'; END IF;
  SELECT count(*) INTO v_count FROM public.annotation_marqueur WHERE layer_id = 'c2a2c000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-MARKER-READ: teacher A sees marker B'; END IF;
  INSERT INTO public.annotation_marqueur (layer_id, plage, intention)
  VALUES ('c2a2c000-2000-0000-0000-000000000001', '{"start":5,"end":6}', 'review');
  v_denied := false;
  BEGIN
    INSERT INTO public.annotation_marqueur (layer_id, plage, intention)
    VALUES ('c2a2c000-2000-0000-0000-000000000002', '{"start":7,"end":8}', 'review');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-MARKER-WRITE: teacher A wrote marker B'; END IF;
  UPDATE public.annotation_marqueur SET plage = plage WHERE layer_id = 'c2a2c000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-ANNOTATION-MARKER-UPDATE: teacher A updated marker B'; END IF;
  RESET ROLE;
END $$;

-- Ces donnees pedagogiques sont admin-only: l'admin lit A et B, les foyers
-- n'accedent pas aux tables, et les mutations passent par des RPC dediees.
DO $$
DECLARE v_count integer; v_rows integer; v_denied boolean;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000007', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.programme_versions;
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-ADMIN-PROGRAMME-VERSIONS: admin cannot read version'; END IF;
  v_denied := false;
  BEGIN
    UPDATE public.programme_versions SET statut = statut WHERE id = 'c2a2f000-3000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true; v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-PROGRAMME-VERSION-DIRECT-WRITE: admin changed version outside RPC'; END IF;

  SELECT count(*) INTO v_count FROM public.programme_niveaux;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-ADMIN-PROGRAMME-NIVEAUX: admin cannot read levels'; END IF;
  v_denied := false;
  BEGIN
    UPDATE public.programme_niveaux SET ordre = ordre WHERE id = 'c2a2f100-3000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true; v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-PROGRAMME-NIVEAU-DIRECT-WRITE: admin changed level outside RPC'; END IF;

  SELECT count(*) INTO v_count FROM public.progression_historique;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-ADMIN-PROGRESSION-HISTORIQUE: admin cannot read history'; END IF;
  v_denied := false;
  BEGIN
    UPDATE public.progression_historique SET motif = motif WHERE id = 'c2a2f200-3000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true; v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-PROGRESSION-HISTORY-DIRECT-WRITE: admin changed append-only history'; END IF;

  SELECT count(*) INTO v_count FROM public.progression_exceptions;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-ADMIN-PROGRESSION-EXCEPTIONS: admin cannot read exceptions'; END IF;
  v_denied := false;
  BEGIN
    UPDATE public.progression_exceptions SET motif = motif WHERE id = 'c2a2f300-3000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true; v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-PROGRESSION-EXCEPTION-DIRECT-WRITE: admin changed exception outside RPC'; END IF;

  SELECT count(*) INTO v_count FROM public.evaluations;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-ADMIN-EVALUATIONS: admin cannot read evaluations'; END IF;
  v_denied := false;
  BEGIN
    UPDATE public.evaluations SET notes = notes WHERE id = 'c2a2f400-3000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true; v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-EVALUATION-DIRECT-WRITE: admin changed evaluation outside RPC'; END IF;

  SELECT count(*) INTO v_count FROM public.controles_qualite;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-ADMIN-CONTROLES-QUALITE: admin cannot read controls'; END IF;
  v_denied := false;
  BEGIN
    UPDATE public.controles_qualite SET note = note WHERE id = 'c2a2f500-3000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true; v_rows := 0;
  END;
  IF NOT v_denied AND v_rows <> 0 THEN RAISE EXCEPTION 'RLS-CONTROLE-QUALITE-DIRECT-WRITE: admin changed control outside RPC'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.programme_versions;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-PROGRAMME-VERSIONS: guardian reads admin curriculum'; END IF;
  SELECT count(*) INTO v_count FROM public.programme_niveaux;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-PROGRAMME-NIVEAUX: guardian reads admin levels'; END IF;
  SELECT count(*) INTO v_count FROM public.progression_historique;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-PROGRESSION-HISTORIQUE: guardian reads admin history'; END IF;
  SELECT count(*) INTO v_count FROM public.progression_exceptions;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-PROGRESSION-EXCEPTIONS: guardian reads admin exceptions'; END IF;
  SELECT count(*) INTO v_count FROM public.evaluations;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-EVALUATIONS: guardian reads admin evaluations'; END IF;
  SELECT count(*) INTO v_count FROM public.controles_qualite;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-CONTROLES-QUALITE: guardian reads admin controls'; END IF;
  RESET ROLE;
END $$;

-- Les references sont globales en lecture; offres publiees visibles a tout
-- compte authentifie; intentions et creneaux restent lies au foyer/groupe.
DO $$
DECLARE v_count integer; v_rows integer; v_denied boolean;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.langues_cours;
  IF v_count < 1 THEN RAISE EXCEPTION 'RLS-COURSE-LANGUAGE-CATALOG: guardian A cannot read shared catalog'; END IF;
  SELECT count(*) INTO v_count FROM public.cohortes_age;
  IF v_count < 1 THEN RAISE EXCEPTION 'RLS-AGE-COHORT-CATALOG: guardian A cannot read shared catalog'; END IF;
  v_rows := 0;
  UPDATE public.langues_cours SET actif = actif WHERE code = 'francais';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-COURSE-LANGUAGE-WRITE: guardian changed shared catalog'; END IF;
  UPDATE public.cohortes_age SET actif = actif WHERE code = 'enfant_5_7';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-AGE-COHORT-WRITE: guardian changed shared catalog'; END IF;

  SELECT count(*) INTO v_count FROM public.offres_horaires WHERE etat = 'publiee';
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-PUBLISHED-OFFERS: guardian A cannot read published offers'; END IF;
  UPDATE public.offres_horaires SET heure_locale = heure_locale
   WHERE id = 'c2a2a200-2000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OFFER-DIRECT-WRITE: guardian changed published offer'; END IF;

  SELECT count(*) INTO v_count FROM public.intentions_horaire;
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-INTENTION: household A does not see only its intention'; END IF;
  SELECT count(*) INTO v_count FROM public.intentions_horaire
   WHERE id = 'c2a2a300-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-INTENTION: household A sees intention B'; END IF;
  UPDATE public.intentions_horaire SET heure_affichee = heure_affichee
   WHERE id = 'c2a2a300-2000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-INTENTION-DIRECT-WRITE: guardian changed intention outside RPC'; END IF;
  v_denied := false;
  BEGIN
    INSERT INTO public.intentions_horaire
      (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
    VALUES ('c2a20000-0000-0000-0000-000000000004', 'c2a2a200-2000-0000-0000-000000000001',
      'Europe/Paris', 18, ARRAY[1,3,5]::smallint[], 'c2a20000-0000-0000-0000-000000000001');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'RLS-INTENTION-DIRECT-INSERT: guardian inserted outside RPC'; END IF;

  SELECT count(*) INTO v_count FROM public.recurrence_rules;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-RECURRENCE-RULES: valid account cannot read shared rules'; END IF;
  UPDATE public.recurrence_rules SET local_time = local_time
   WHERE id = 'c2a2a100-2000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-RECURRENCE-DIRECT-WRITE: guardian changed recurrence'; END IF;

  SELECT count(*) INTO v_count FROM public.groupe_creneaux
   WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000001';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-GROUP-SLOT: household A cannot read its group slot'; END IF;
  SELECT count(*) INTO v_count FROM public.groupe_creneaux
   WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-GROUP-SLOT: household A sees group B slot'; END IF;
  UPDATE public.groupe_creneaux SET hour_local = hour_local
   WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-GROUP-SLOT-WRITE: guardian changed B slot'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"student","household_id":"c2a2ffff-0000-0000-0000-000000000002"}}', true);
  SELECT count(*) INTO v_count FROM public.langues_cours;
  IF v_count < 1 THEN RAISE EXCEPTION 'RLS-COURSE-LANGUAGE-CATALOG-B: student B cannot read shared catalog'; END IF;
  SELECT count(*) INTO v_count FROM public.cohortes_age;
  IF v_count < 1 THEN RAISE EXCEPTION 'RLS-AGE-COHORT-CATALOG-B: student B cannot read shared catalog'; END IF;
  SELECT count(*) INTO v_count FROM public.offres_horaires WHERE etat = 'publiee';
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-PUBLISHED-OFFERS-OTHER-HOUSEHOLD: household B cannot read shared offers'; END IF;
  SELECT count(*) INTO v_count FROM public.intentions_horaire;
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-INTENTION-B: household B cannot read its intention'; END IF;
  SELECT count(*) INTO v_count FROM public.groupe_creneaux
   WHERE groupe_id = 'c2a2a000-2000-0000-0000-000000000002';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-GROUP-SLOT-B: household B cannot read its group slot'; END IF;
  SELECT count(*) INTO v_count FROM public.recurrence_rules;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-RECURRENCE-RULES-B: valid account cannot read shared rules'; END IF;
  RESET ROLE;
END $$;

-- L'administration lit les empreintes d'appairage; le foyer utilise la vue
-- expurgee et ne lit jamais les codes bruts ni ceux d'un autre foyer.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000007', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  SELECT count(*) INTO v_count FROM public.device_pairing_codes;
  IF v_count <> 2 THEN RAISE EXCEPTION 'RLS-ADMIN-PAIRING-CODES: admin cannot read pairing records'; END IF;
  BEGIN
    UPDATE public.device_pairing_codes SET code_hash = code_hash WHERE code_hash = 'codex2-hash-b';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_rows := 0;
  END;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-PAIRING-CODE-DIRECT-WRITE: admin updated a code outside the RPC'; END IF;
  RESET ROLE;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  v_count := 0;
  BEGIN
    SELECT count(*) INTO v_count FROM public.device_pairing_codes;
  EXCEPTION WHEN insufficient_privilege THEN
    v_count := 0;
  END;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-FAMILY-PAIRING-CODE-RAW: guardian can read raw code rows'; END IF;
  SELECT count(*) INTO v_count FROM public.mes_codes_appairage_v
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000004';
  IF v_count <> 1 THEN RAISE EXCEPTION 'RLS-OWNER-PAIRING-CODE-VIEW: household A cannot read safe child code metadata'; END IF;
  SELECT count(*) INTO v_count FROM public.mes_codes_appairage_v
   WHERE student_profile_id = 'c2a20000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-OTHER-HOUSEHOLD-PAIRING-CODE-VIEW: household A sees B code metadata'; END IF;
  RESET ROLE;
END $$;

-- Les tables de routage/configuration video et de webhooks sont service-only:
-- aucune policy client ne doit exposer leurs lignes ni permettre une mutation.
DO $$
DECLARE v_count integer; v_rows integer;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'c2a20000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian","household_id":"c2a2ffff-0000-0000-0000-000000000001"}}', true);
  v_count := 0;
  BEGIN
    SELECT count(*) INTO v_count FROM public.video_config;
  EXCEPTION WHEN insufficient_privilege THEN
    v_count := 0;
  END;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-VIDEO-CONFIG-READ: client can read video config'; END IF;
  BEGIN
    UPDATE public.video_config SET token_ttl_seconds = token_ttl_seconds WHERE id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_rows := 0;
  END;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-VIDEO-CONFIG-WRITE: client changed video config'; END IF;
  v_count := 0;
  BEGIN
    SELECT count(*) INTO v_count FROM public.session_video_route;
  EXCEPTION WHEN insufficient_privilege THEN
    v_count := 0;
  END;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-VIDEO-ROUTE-READ: client can read session routing'; END IF;
  BEGIN
    UPDATE public.session_video_route SET room_name = room_name WHERE session_id = 'c2a2e000-1000-0000-0000-000000000002';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_rows := 0;
  END;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-VIDEO-ROUTE-WRITE: client changed session routing'; END IF;
  v_count := 0;
  BEGIN
    SELECT count(*) INTO v_count FROM public.livekit_webhook_deliveries;
  EXCEPTION WHEN insufficient_privilege THEN
    v_count := 0;
  END;
  IF v_count <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-WEBHOOK-READ: client can read webhook delivery rows'; END IF;
  BEGIN
    UPDATE public.livekit_webhook_deliveries SET applique = true WHERE event_id = 'codex2-event-b';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  EXCEPTION WHEN insufficient_privilege THEN
    v_rows := 0;
  END;
  IF v_rows <> 0 THEN RAISE EXCEPTION 'RLS-SERVICE-WEBHOOK-WRITE: client changed webhook delivery'; END IF;
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
