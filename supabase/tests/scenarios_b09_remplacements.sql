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
 ('b0900000-0000-0000-0000-000000000001','B09-HOLDER','teacher',NULL,'Holder','A','active','male'),
 ('b0900000-0000-0000-0000-000000000002','B09-FIRST','teacher',NULL,'First','B','active','male'),
 ('b0900000-0000-0000-0000-000000000003','B09-SECOND','teacher',NULL,'Second','C','active','male'),
 ('b0900000-0000-0000-0000-000000000004','B09-ADMIN','admin',NULL,'Admin','D','active','female'),
 ('b0900000-0000-0000-0000-000000000005','B09-WRONG','teacher',NULL,'Wrong','E','active','female');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
 ('b0900000-0000-0000-0000-000000000001','approved'),
 ('b0900000-0000-0000-0000-000000000002','approved'),
 ('b0900000-0000-0000-0000-000000000003','approved'),
 ('b0900000-0000-0000-0000-000000000005','approved');
INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES ('b0900000-0000-0000-0000-000000000101',
 'b0900000-0000-0000-0000-000000000001','enfant',5,'B09 class',1,18,'Europe/Paris','hommes');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('b0900000-0000-0000-0000-000000000201',
 'b0900000-0000-0000-0000-000000000001', now()+interval '2 days', now()+interval '2 days 1 hour',
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
 IF v_result->>'etat' <> 'acceptee' THEN RAISE EXCEPTION 'B09: premier remplaçant refusé'; END IF;
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
 'b0900000-0000-0000-0000-000000000001', now()+interval '3 days', now()+interval '3 days 1 hour',
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
 IF v_result->>'etat' <> 'designe' THEN RAISE EXCEPTION 'B09: désignation admin refusée'; END IF;
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
 IF has_function_privilege('anon','public.prendre_remplacement(uuid,uuid)','EXECUTE')
    OR has_function_privilege('service_role','public.prendre_remplacement(uuid,uuid)','EXECUTE')
    OR has_function_privilege('agent_ro','public.prendre_remplacement(uuid,uuid)','EXECUTE') THEN
   RAISE EXCEPTION 'B09: ACL prendre_remplacement incorrecte';
 END IF;
END;
$postflight$;
ROLLBACK;
