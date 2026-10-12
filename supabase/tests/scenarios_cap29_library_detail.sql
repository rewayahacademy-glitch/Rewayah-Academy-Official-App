-- C-30 detail read: allowlisted metadata for valid admin only.
-- Prepared for the isolated PostgreSQL 17 replay; not run in this session.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c29d1000-0000-0000-0000-000000000001', 'cap29-detail-admin@test.invalid'),
  ('c29d1000-0000-0000-0000-000000000002', 'cap29-detail-teacher@test.invalid');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('c29d1000-0000-0000-0000-000000000001', 'ADMN-C29-DTL-001', 'admin',
   NULL, 'Admin', 'Detail', 'active', 'female'),
  ('c29d1000-0000-0000-0000-000000000002', 'TEACH-C29-DTL-001', 'teacher',
   NULL, 'Teacher', 'Detail', 'provisional_active', 'male');

DO $teacher_contract_fixture$
DECLARE v_nda_version text; v_notice_version text;
BEGIN
  SELECT version INTO v_nda_version FROM public.contract_texts
   WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version FROM public.contract_required_versions
   WHERE contract_kind='recording_and_control_notice';
  PERFORM set_config('request.jwt.claim.sub','c29d1000-0000-0000-0000-000000000002',true);
  PERFORM set_config('test.uid','c29d1000-0000-0000-0000-000000000002',true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_nda_version,'Teacher Detail');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('c29d1000-0000-0000-0000-000000000002',
          'recording_and_control_notice',v_notice_version)
  ON CONFLICT DO NOTHING;
  UPDATE public.profiles SET account_status='active'
   WHERE id='c29d1000-0000-0000-0000-000000000002';
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('test.jwt','',true);
END
$teacher_contract_fixture$;

INSERT INTO public.library_resource
  (id, title, short_title, resource_type, language, category,
   access_policy, offline_policy)
VALUES
  ('c29d1000-0000-0000-0000-000000000003', 'Support détaillé', 'Support',
   'pdf', 'fr', 'cours', 'admin', 'jamais');
INSERT INTO public.resource_version
  (id, resource_id, numero_version, empreinte)
VALUES
  ('c29d1000-0000-0000-0000-000000000004',
   'c29d1000-0000-0000-0000-000000000003', 1,
   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
INSERT INTO private.library_rights_proofs
  (id, resource_id, resource_version_id, cle_stockage, sha256, mime, taille,
   deposee_par, statut)
VALUES
  ('c29d1000-0000-0000-0000-000000000005',
   'c29d1000-0000-0000-0000-000000000003',
   'c29d1000-0000-0000-0000-000000000004',
   'private/libraryproof/secret-object-key',
   'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
   'application/pdf', 1234, 'c29d1000-0000-0000-0000-000000000001', 'confirmee');
INSERT INTO public.library_version_rights
  (resource_version_id, source_titre, titulaire, preuve_id, usages, attribution,
   expire_le, approuve, revu_par, revu_le)
VALUES
  ('c29d1000-0000-0000-0000-000000000004', 'Source test', 'Titulaire test',
   'c29d1000-0000-0000-0000-000000000005', ARRAY['classe'], 'Attribution test',
   NULL, true, 'c29d1000-0000-0000-0000-000000000001', now());

SELECT set_config('test.uid', 'c29d1000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_detail jsonb;
BEGIN
  v_detail := public.library_get_detail('c29d1000-0000-0000-0000-000000000003');
  IF v_detail #>> '{support,titre}' <> 'Support détaillé'
     OR jsonb_array_length(v_detail->'versions') <> 1
     OR v_detail #>> '{versions,0,droits,preuveStatut}' <> 'confirmee'
     OR v_detail::text LIKE '%secret-object-key%'
     OR v_detail::text LIKE '%cle_stockage%' THEN
    RAISE EXCEPTION 'CAP-29: detail invalide ou cle de stockage divulguée: %', v_detail;
  END IF;
  IF (SELECT count(*) FROM public.audit_logs WHERE action = 'library_resource_detail_read' AND table_name = 'library_resource' AND row_id = 'c29d1000-0000-0000-0000-000000000003') <> 1 THEN
    RAISE EXCEPTION 'CAP-29: lecture detail non journalisee';
  END IF;
END;
$test$;
RESET ROLE;

SELECT set_config('test.uid', 'c29d1000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
SET LOCAL ROLE authenticated;
DO $test$
BEGIN
  BEGIN
    PERFORM public.library_get_detail('c29d1000-0000-0000-0000-000000000003');
    RAISE EXCEPTION 'CAP-29: enseignant non autorisé à lire la fiche admin';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$test$;
RESET ROLE;

DO $acl$
BEGIN
  IF has_function_privilege('anon', 'public.library_get_detail(uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.library_get_detail(uuid)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.library_get_detail(uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.library_get_detail(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAP-29: ACL library_get_detail incorrecte';
  END IF;
END;
$acl$;

ROLLBACK;
