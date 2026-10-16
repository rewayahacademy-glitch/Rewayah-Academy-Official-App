-- B-09 replacement producer invariants. Prepared for Claude's isolated PG16/17 replay; not run here.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('b0900000-0000-0000-0000-000000000001','b09-holder@test.invalid'),
 ('b0900000-0000-0000-0000-000000000002','b09-first@test.invalid'),
 ('b0900000-0000-0000-0000-000000000003','b09-second@test.invalid'),
 ('b0900000-0000-0000-0000-000000000004','b09-admin@test.invalid'),
 ('b0900000-0000-0000-0000-000000000005','b09-wrong-gender@test.invalid');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('b0900000-0000-0000-0000-000000000001','B09-HOLDER','teacher',NULL,'Holder','A','provisional_active','male'),
 ('b0900000-0000-0000-0000-000000000002','B09-FIRST','teacher',NULL,'First','B','provisional_active','male'),
 ('b0900000-0000-0000-0000-000000000003','B09-SECOND','teacher',NULL,'Second','C','provisional_active','male'),
 ('b0900000-0000-0000-0000-000000000004','B09-ADMIN','admin',NULL,'Admin','D','active','female'),
 ('b0900000-0000-0000-0000-000000000005','B09-WRONG','teacher',NULL,'Wrong','E','provisional_active','female');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
 ('b0900000-0000-0000-0000-000000000001','approved'),
 ('b0900000-0000-0000-0000-000000000002','approved'),
 ('b0900000-0000-0000-0000-000000000003','approved'),
 ('b0900000-0000-0000-0000-000000000005','approved');
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
  UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
 END LOOP;
 PERFORM set_config('request.jwt.claim.sub','',true); PERFORM set_config('request.jwt.claims','',true);
 PERFORM set_config('test.uid','',true); PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;
INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES ('b0900000-0000-0000-0000-000000000101',
 'b0900000-0000-0000-0000-000000000001','enfant',5,'B09 class',1,18,'Europe/Paris','hommes');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('b0900000-0000-0000-0000-000000000201',
 'b0900000-0000-0000-0000-000000000001', ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '2 days 3 hours') at time zone 'Europe/Paris'), ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '2 days 4 hours') at time zone 'Europe/Paris'),
 'planned','standard','b0900000-0000-0000-0000-000000000101');

SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_result jsonb;
BEGIN
 v_result := public.declarer_absence_seance(
   'b0900000-0000-0000-0000-000000000201','b0900000-0000-0000-0000-000000000301');
 IF v_result->>'etat' <> 'absence_declaree' THEN RAISE EXCEPTION 'B09: absence non declaree'; END IF;
 IF (SELECT public.declarer_absence_seance(
   'b0900000-0000-0000-0000-000000000201','b0900000-0000-0000-0000-000000000301')->>'etat') <> 'absence_declaree'
 THEN RAISE EXCEPTION 'B09: reprise idempotente incorrecte'; END IF;
END;
$test$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000005',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_result jsonb;
BEGIN
 v_result := public.prendre_remplacement(
   'b0900000-0000-0000-0000-000000000201','b0900000-0000-0000-0000-000000000302');
 IF v_result->>'etat' <> 'dejaPrise' THEN RAISE EXCEPTION 'B09: offre incompatible visible'; END IF;
END;
$test$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_result jsonb;
BEGIN
 v_result := public.prendre_remplacement(
   'b0900000-0000-0000-0000-000000000201','b0900000-0000-0000-0000-000000000303');
 IF v_result->>'etat' <> 'acceptee' THEN RAISE EXCEPTION 'B09: premier remplaأ§ant refusأ©'; END IF;
END;
$test$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000003',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_result jsonb;
BEGIN
 v_result := public.prendre_remplacement(
   'b0900000-0000-0000-0000-000000000201','b0900000-0000-0000-0000-000000000304');
 IF v_result->>'etat' <> 'dejaPrise' THEN RAISE EXCEPTION 'B09: une seconde prise a ete acceptee'; END IF;
END;
$test$;
RESET ROLE;

INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('b0900000-0000-0000-0000-000000000202',
 'b0900000-0000-0000-0000-000000000001', ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '3 days 3 hours') at time zone 'Europe/Paris'), ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '3 days 4 hours') at time zone 'Europe/Paris'),
 'planned','standard','b0900000-0000-0000-0000-000000000101');
SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_result jsonb;
BEGIN
 v_result := public.designer_remplacant_admin(
   'b0900000-0000-0000-0000-000000000202',
   'b0900000-0000-0000-0000-000000000003',
   'b0900000-0000-0000-0000-000000000305');
 IF v_result->>'etat' <> 'designe' THEN RAISE EXCEPTION 'B09: dأ©signation admin refusأ©e'; END IF;
 v_result := public.designer_remplacant_admin(
   'b0900000-0000-0000-0000-000000000202',
   'b0900000-0000-0000-0000-000000000003',
   'b0900000-0000-0000-0000-000000000305');
 IF v_result->>'etat' <> 'designe' THEN RAISE EXCEPTION 'B09: reprise idempotente admin incorrecte'; END IF;
 BEGIN
   PERFORM public.designer_remplacant_admin(
     'b0900000-0000-0000-0000-000000000202',
     'b0900000-0000-0000-0000-000000000002',
     'b0900000-0000-0000-0000-000000000305');
   RAISE EXCEPTION 'B09: reutilisation de cle avec charge differente acceptee';
 EXCEPTION WHEN unique_violation THEN NULL;
 END;
END;
$test$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000003',true);
SELECT set_config('test.uid','b0900000-0000-0000-0000-000000000003',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $wrong_role$
BEGIN
 BEGIN
  PERFORM public.designer_remplacant_admin(
   'b0900000-0000-0000-0000-000000000202',
   'b0900000-0000-0000-0000-000000000002',
   'b0900000-0000-0000-0000-000000000306');
  RAISE EXCEPTION 'B09: un enseignant a désigné un remplaçant admin';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$wrong_role$;
SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000004',true);
SELECT set_config('test.uid','b0900000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
DO $wrong_role_admin$
BEGIN
 BEGIN
  PERFORM public.declarer_absence_seance(
   'b0900000-0000-0000-0000-000000000201',
   'b0900000-0000-0000-0000-000000000310');
  RAISE EXCEPTION 'B09: un administrateur a déclaré une absence enseignant';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
  PERFORM public.prendre_remplacement(
   'b0900000-0000-0000-0000-000000000201',
   'b0900000-0000-0000-0000-000000000311');
  RAISE EXCEPTION 'B09: un administrateur a pris un remplacement enseignant';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$wrong_role_admin$;
RESET ROLE;

UPDATE public.profiles SET account_status='disabled'
 WHERE id IN ('b0900000-0000-0000-0000-000000000001',
              'b0900000-0000-0000-0000-000000000002');
SELECT set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000001',true);
SELECT set_config('test.uid','b0900000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $disabled_teacher$
BEGIN
 BEGIN
  PERFORM public.declarer_absence_seance(
   'b0900000-0000-0000-0000-000000000201',
   'b0900000-0000-0000-0000-000000000301');
  RAISE EXCEPTION 'B09: un enseignant désactivé a déclaré une absence';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 PERFORM set_config('request.jwt.claim.sub','b0900000-0000-0000-0000-000000000002',true);
 PERFORM set_config('test.uid','b0900000-0000-0000-0000-000000000002',true);
 BEGIN
  PERFORM public.prendre_remplacement(
   'b0900000-0000-0000-0000-000000000201',
   'b0900000-0000-0000-0000-000000000303');
  RAISE EXCEPTION 'B09: un remplaçant désactivé a conservé sa prise';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$disabled_teacher$;
RESET ROLE;

SET LOCAL ROLE anon;
DO $anonymous$
BEGIN
 BEGIN
  PERFORM public.declarer_absence_seance(
   'b0900000-0000-0000-0000-000000000201',
   'b0900000-0000-0000-0000-000000000307');
  RAISE EXCEPTION 'B09: anon a déclaré une absence';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
  PERFORM public.prendre_remplacement(
   'b0900000-0000-0000-0000-000000000201',
   'b0900000-0000-0000-0000-000000000308');
  RAISE EXCEPTION 'B09: anon a pris un remplacement';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
  PERFORM public.designer_remplacant_admin(
   'b0900000-0000-0000-0000-000000000202',
   'b0900000-0000-0000-0000-000000000003',
   'b0900000-0000-0000-0000-000000000309');
  RAISE EXCEPTION 'B09: anon a désigné un remplaçant';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$anonymous$;
RESET ROLE;

DO $postflight$
BEGIN
 IF (SELECT count(*) FROM public.notifications WHERE evenement='remplacement_propose' AND params->>'session_id'='b0900000-0000-0000-0000-000000000201') <> 2
    OR (SELECT count(*) FROM public.notifications WHERE evenement='remplacement_pris' AND params->>'session_id'='b0900000-0000-0000-0000-000000000201') <> 1
    OR EXISTS (SELECT 1 FROM public.notifications WHERE destinataire='b0900000-0000-0000-0000-000000000005' AND params->>'session_id'='b0900000-0000-0000-0000-000000000201')
    OR (SELECT count(*) FROM public.remplacements_seance WHERE session_id='b0900000-0000-0000-0000-000000000201') <> 2
    OR (SELECT teacher_id FROM public.sessions WHERE id='b0900000-0000-0000-0000-000000000201') <> 'b0900000-0000-0000-0000-000000000001'
    OR (SELECT count(*) FROM public.audit_logs WHERE action IN ('replacement_absence_declared','replacement_claimed') AND row_id='b0900000-0000-0000-0000-000000000201') <> 2 THEN
   RAISE EXCEPTION 'B09: append-only state, titulaire ou audit incorrect';
 END IF;
 IF has_function_privilege('anon','public.declarer_absence_seance(uuid,uuid)','EXECUTE')
    OR has_function_privilege('anon','public.prendre_remplacement(uuid,uuid)','EXECUTE')
    OR has_function_privilege('anon','public.designer_remplacant_admin(uuid,uuid,uuid)','EXECUTE')
    OR has_function_privilege('service_role','public.declarer_absence_seance(uuid,uuid)','EXECUTE')
    OR has_function_privilege('service_role','public.prendre_remplacement(uuid,uuid)','EXECUTE')
    OR has_function_privilege('service_role','public.designer_remplacant_admin(uuid,uuid,uuid)','EXECUTE')
    OR has_function_privilege('agent_ro','public.declarer_absence_seance(uuid,uuid)','EXECUTE')
    OR has_function_privilege('agent_ro','public.prendre_remplacement(uuid,uuid)','EXECUTE')
    OR has_function_privilege('agent_ro','public.designer_remplacant_admin(uuid,uuid,uuid)','EXECUTE') THEN
   RAISE EXCEPTION 'B09: ACL RPC remplacement incorrecte';
 END IF;
END;
$postflight$;
ROLLBACK;
