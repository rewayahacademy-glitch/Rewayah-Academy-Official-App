-- C-29 must exclude the effective replacement teacher, not the titular teacher.
-- Requires the canonical migrations including B-09 and C-29 control rules.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c29e0000-0000-0000-0000-000000000001', 'c29-effective-holder@test.invalid'),
  ('c29e0000-0000-0000-0000-000000000002', 'c29-effective-cover@test.invalid'),
  ('c29e0000-0000-0000-0000-000000000003', 'c29-effective-admin@test.invalid');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('c29e0000-0000-0000-0000-000000000001', 'C29-EFF-HOLDER', 'teacher', NULL, 'Holder', 'One', 'provisional_active', 'male'),
  ('c29e0000-0000-0000-0000-000000000002', 'C29-EFF-COVER', 'teacher', NULL, 'Cover', 'Two', 'provisional_active', 'male'),
  ('c29e0000-0000-0000-0000-000000000003', 'C29-EFF-ADMIN', 'admin', NULL, 'Admin', 'Three', 'active', 'female');
INSERT INTO public.teacher_profiles(profile_id,kyc_status) VALUES
 ('c29e0000-0000-0000-0000-000000000001','approved'),
 ('c29e0000-0000-0000-0000-000000000002','approved');
DO $fixture_teacher_contracts$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active' LOOP
  PERFORM set_config('request.jwt.claim.sub',v_teacher.id::text,true); PERFORM set_config('test.uid',v_teacher.id::text,true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true); PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version) ON CONFLICT DO NOTHING;
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES (v_teacher.id,'teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
 END LOOP;
 PERFORM set_config('request.jwt.claim.sub','',true); PERFORM set_config('request.jwt.claims','',true);
 PERFORM set_config('test.uid','',true); PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES
  ('c29e0000-0000-0000-0000-000000000101',
   'c29e0000-0000-0000-0000-000000000001', 'enfant', 5, 'Effective Teacher', 1, 18, 'Europe/Paris', 'hommes');
-- Keep this session well outside the live clock so unrelated fixtures cannot
-- collide with it under time-shifted or concurrent scenario replays.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES
  ('c29e0000-0000-0000-0000-000000000201',
   'c29e0000-0000-0000-0000-000000000001',
   TIMESTAMPTZ '2099-01-01 11:55:00+00', TIMESTAMPTZ '2099-01-01 12:55:00+00',
   'in_progress', 'standard',
   'c29e0000-0000-0000-0000-000000000101');

DO $test$
DECLARE v_effective uuid;
BEGIN
  v_effective := private.c29_enseignant_effectif_session(
    'c29e0000-0000-0000-0000-000000000201'
  );
  IF v_effective <> 'c29e0000-0000-0000-0000-000000000001' THEN
    RAISE EXCEPTION 'C29: titular must remain effective before B-09 replacement';
  END IF;

  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence, cree_le)
  VALUES
    ('c29e0000-0000-0000-0000-000000000201', 'absence_declaree',
     'c29e0000-0000-0000-0000-000000000001', NULL,
     'c29e0000-0000-0000-0000-000000000001', 'c29e0000-0000-0000-0000-000000000301',
     pg_catalog.clock_timestamp());
  IF private.c29_enseignant_effectif_session(
       'c29e0000-0000-0000-0000-000000000201'
     ) <> 'c29e0000-0000-0000-0000-000000000001' THEN
    RAISE EXCEPTION 'C29: absence declaration alone must not change effective teacher';
  END IF;

  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence, cree_le)
  VALUES
    ('c29e0000-0000-0000-0000-000000000201', 'remplacement_pris',
     'c29e0000-0000-0000-0000-000000000001', 'c29e0000-0000-0000-0000-000000000002',
     'c29e0000-0000-0000-0000-000000000002', 'c29e0000-0000-0000-0000-000000000302',
     pg_catalog.clock_timestamp() + interval '1 millisecond');
  IF private.c29_enseignant_effectif_session(
       'c29e0000-0000-0000-0000-000000000201'
     ) <> 'c29e0000-0000-0000-0000-000000000002' THEN
    RAISE EXCEPTION 'C29: confirmed replacement must be the effective teacher';
  END IF;
END;
$test$;

ROLLBACK;
