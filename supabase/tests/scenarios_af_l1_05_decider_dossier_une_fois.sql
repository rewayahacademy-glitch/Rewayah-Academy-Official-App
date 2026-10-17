-- AF L1-05 (P1-1) : decider_dossier refuse une seconde decision, et le rejet
-- d'un enseignant sans autre piece approuvee retire son acces ; le rejet d'un
-- enseignant qui garde une autre piece approuvee ne touche pas son compte.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a1050000-0000-0000-0000-000000000001', 'l105-admin@example.test'),
  ('a1050000-0000-0000-0000-000000000003', 'l105-t1@example.test'),
  ('a1050000-0000-0000-0000-000000000004', 'l105-t2@example.test'),
  ('a1050000-0000-0000-0000-000000000005', 'l105-t3@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('a1050000-0000-0000-0000-000000000101', 'Europe/Paris');

-- Les enseignants entrent en provisional_active puis passent active apres
-- signature du NDA et de l'avis (meme fixture que scenarios_c21_kyc_access_verdict.sql).
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender,
   account_status)
VALUES
  ('a1050000-0000-0000-0000-000000000001', 'L105-ADMIN-M', 'admin',
   'a1050000-0000-0000-0000-000000000101', 'Admin', 'L105', 'male', 'active'),
  ('a1050000-0000-0000-0000-000000000003', 'L105-T1-M', 'teacher',
   'a1050000-0000-0000-0000-000000000101', 'Teacher', 'Un', 'male', 'provisional_active'),
  ('a1050000-0000-0000-0000-000000000004', 'L105-T2-M', 'teacher',
   'a1050000-0000-0000-0000-000000000101', 'Teacher', 'Deux', 'male', 'provisional_active'),
  ('a1050000-0000-0000-0000-000000000005', 'L105-T3-M', 'teacher',
   'a1050000-0000-0000-0000-000000000101', 'Teacher', 'Trois', 'male', 'provisional_active');

INSERT INTO public.teacher_profiles (profile_id)
VALUES
  ('a1050000-0000-0000-0000-000000000003'),
  ('a1050000-0000-0000-0000-000000000004'),
  ('a1050000-0000-0000-0000-000000000005');

DO $fixture_teacher_nda$
DECLARE
  v_teacher record;
  v_teacher_version text;
  v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version
    FROM public.contract_texts
   WHERE contract_kind = 'teacher_nda'
     AND locale = 'fr'
     AND is_current;

  SELECT version INTO v_notice_version
    FROM public.contract_required_versions
   WHERE contract_kind = 'recording_and_control_notice';

  FOR v_teacher IN
    SELECT id FROM public.profiles
     WHERE id IN (
       'a1050000-0000-0000-0000-000000000003',
       'a1050000-0000-0000-0000-000000000004',
       'a1050000-0000-0000-0000-000000000005'
     )
  LOOP
    PERFORM set_config('request.jwt.claim.sub', v_teacher.id::text, true);
    PERFORM set_config('test.uid', v_teacher.id::text, true);
    PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
    PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    PERFORM public.signer_contrat(v_teacher_version, 'Fixture enseignant L1-05');
    INSERT INTO public.contract_acceptances(profile_id, contract_kind, version)
    VALUES (v_teacher.id, 'recording_and_control_notice', v_notice_version)
    ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
    UPDATE public.profiles SET account_status = 'active' WHERE id = v_teacher.id;
  END LOOP;

  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('test.uid', '', true);
  PERFORM set_config('test.jwt', '', true);
END
$fixture_teacher_nda$;

-- D1 : T1, seule piece, en attente.
-- D2 : T2, en attente, avec D2a deja approuvee (autre piece).
-- D3 : T3, seule piece, en attente.
INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key, status)
VALUES
  ('a1050000-0000-0000-0000-000000000201', 'a1050000-0000-0000-0000-000000000003',
   'id_card', 'male', 'l105/t1-id', 'pending'),
  ('a1050000-0000-0000-0000-000000000202', 'a1050000-0000-0000-0000-000000000004',
   'passport', 'male', 'l105/t2-passeport', 'pending'),
  ('a1050000-0000-0000-0000-000000000203', 'a1050000-0000-0000-0000-000000000004',
   'other', 'male', 'l105/t2-justificatif', 'approved'),
  ('a1050000-0000-0000-0000-000000000204', 'a1050000-0000-0000-0000-000000000005',
   'id_card', 'male', 'l105/t3-id', 'pending');

-- Decision sous le jeton de l'administrateur A.
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'a1050000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $l105_seconde_decision$
BEGIN
  PERFORM public.decider_dossier('a1050000-0000-0000-0000-000000000201', true, null);
  BEGIN
    PERFORM public.decider_dossier('a1050000-0000-0000-0000-000000000201', false, 'test');
    RAISE EXCEPTION 'L1-05: seconde décision acceptée';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END
$l105_seconde_decision$;

DO $l105_rejets$
BEGIN
  PERFORM public.decider_dossier('a1050000-0000-0000-0000-000000000202', false, 'Photo illisible');
  PERFORM public.decider_dossier('a1050000-0000-0000-0000-000000000204', false, 'Piece expiree');
END
$l105_rejets$;

RESET ROLE;

DO $l105_controles$
DECLARE
  v_statut public.account_status;
  v_payload jsonb;
BEGIN
  SELECT account_status INTO v_statut FROM public.profiles
   WHERE id = 'a1050000-0000-0000-0000-000000000003';
  IF v_statut <> 'active' THEN
    RAISE EXCEPTION 'L1-05: approbation de T1 perdue (%)', v_statut;
  END IF;

  SELECT account_status INTO v_statut FROM public.profiles
   WHERE id = 'a1050000-0000-0000-0000-000000000004';
  IF v_statut <> 'active' THEN
    RAISE EXCEPTION 'L1-05: T2 retire malgre une autre piece approuvee (%)', v_statut;
  END IF;

  SELECT account_status INTO v_statut FROM public.profiles
   WHERE id = 'a1050000-0000-0000-0000-000000000005';
  IF v_statut <> 'disabled' THEN
    RAISE EXCEPTION 'L1-05: T3 non desactive au rejet (%)', v_statut;
  END IF;

  SELECT payload INTO v_payload FROM public.audit_logs
   WHERE action = 'kyc_decision' AND row_id = 'a1050000-0000-0000-0000-000000000204'
   ORDER BY created_at DESC, id DESC LIMIT 1;
  IF v_payload IS NULL OR v_payload ->> 'acces_retire' IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'L1-05: acces_retire absent du journal de T3 (%)', v_payload;
  END IF;
END
$l105_controles$;

ROLLBACK;
