-- L2-01 : le jeton video suit l'enseignant effectif ; le retrait d'un eleve coupe ses seances a venir.
-- Chaque refus est prouve par SQLSTATE exact (42501), jamais par un message.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('a2010000-0000-0000-0000-000000000001','l201-holder@test.invalid'),
 ('a2010000-0000-0000-0000-000000000002','l201-first@test.invalid'),
 ('a2010000-0000-0000-0000-000000000003','l201-second@test.invalid'),
 ('a2010000-0000-0000-0000-000000000004','l201-admin@test.invalid'),
 ('a2010000-0000-0000-0000-000000000005','l201-wrong-gender@test.invalid');
INSERT INTO auth.users (id, email) VALUES
 ('a2010000-0000-0000-0000-000000000011','l201-teacher2@test.invalid');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('a2010000-0000-0000-0000-000000000011','L201-T2','teacher',NULL,'Teacher','Two','provisional_active','male');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
 ('a2010000-0000-0000-0000-000000000011','approved');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('a2010000-0000-0000-0000-000000000001','L201-HOLDER','teacher',NULL,'Holder','A','provisional_active','male'),
 ('a2010000-0000-0000-0000-000000000002','L201-FIRST','teacher',NULL,'First','B','provisional_active','male'),
 ('a2010000-0000-0000-0000-000000000003','L201-SECOND','teacher',NULL,'Second','C','provisional_active','male'),
 ('a2010000-0000-0000-0000-000000000004','L201-ADMIN','admin',NULL,'Admin','D','active','female'),
 ('a2010000-0000-0000-0000-000000000005','L201-WRONG','teacher',NULL,'Wrong','E','provisional_active','female');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
 ('a2010000-0000-0000-0000-000000000001','approved'),
 ('a2010000-0000-0000-0000-000000000002','approved'),
 ('a2010000-0000-0000-0000-000000000003','approved'),
 ('a2010000-0000-0000-0000-000000000005','approved');
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
VALUES ('a2010000-0000-0000-0000-000000000101',
 'a2010000-0000-0000-0000-000000000001','enfant',5,'L201 class',1,18,'Europe/Paris','hommes');

-- Second enseignant, sa classe, un eleve (fixtures du retrait).
INSERT INTO auth.users (id, email) VALUES
 ('a2010000-0000-0000-0000-000000000012','l201-student@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('a20100ff-0000-0000-0000-00000000000a','Europe/Paris');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('a2010000-0000-0000-0000-000000000012','L201-STUD','student','a20100ff-0000-0000-0000-00000000000a','Eleve','Un','active','male');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
VALUES ('a2010000-0000-0000-0000-000000000012','minor','standard','allowed');
INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES ('a2010000-0000-0000-0000-000000000102',
 'a2010000-0000-0000-0000-000000000011','enfant',5,'L201 class 2',3,9,'Europe/Paris','hommes');
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('a2010000-0000-0000-0000-000000000102','a2010000-0000-0000-0000-000000000012');

-- Partie 1 : seance du groupe 101, attitre = holder (001), salle ouverte.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id, join_opens_at)
VALUES ('a2010000-0000-0000-0000-000000000202',
 'a2010000-0000-0000-0000-000000000001', ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '3 days 3 hours') at time zone 'Europe/Paris'), ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '3 days 4 hours') at time zone 'Europe/Paris'),
 'planned','standard','a2010000-0000-0000-0000-000000000101', clock_timestamp()-interval '1 hour');
-- L'attitre garde meme une ligne participant 'teacher' : elle ne doit plus ouvrir la salle une fois remplace.
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES ('a2010000-0000-0000-0000-000000000202','a2010000-0000-0000-0000-000000000001','teacher');

-- Avant remplacement : l'attitre obtient son jeton enseignant.
SELECT set_config('test.uid','a2010000-0000-0000-0000-000000000001',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE service_role;
DO $avant$
DECLARE v jsonb;
BEGIN
 v := public.autoriser_jeton_video('a2010000-0000-0000-0000-000000000202',
   'a2010000-0000-0000-0000-000000000001','wss://x','wss://y');
 IF v->>'role' <> 'teacher' OR (v->'capabilities'->>'can_publish')::boolean IS NOT TRUE THEN
  RAISE EXCEPTION 'L201: l''attitre non remplace n''a pas son jeton enseignant';
 END IF;
END;
$avant$;
RESET ROLE;

-- Designation par l'administration.
SELECT set_config('request.jwt.claim.sub','a2010000-0000-0000-0000-000000000004',true);
SELECT set_config('test.uid','a2010000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $designer$
BEGIN
 IF public.designer_remplacant_admin('a2010000-0000-0000-0000-000000000202',
   'a2010000-0000-0000-0000-000000000003','a2010000-0000-0000-0000-000000000305')->>'etat' <> 'designe' THEN
  RAISE EXCEPTION 'L201: designation refusee';
 END IF;
END;
$designer$;
RESET ROLE;

-- Apres : le remplacant a un jeton, l'attitre non (42501).
SELECT set_config('test.uid','a2010000-0000-0000-0000-000000000003',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE service_role;
DO $apres$
DECLARE v jsonb; v_state text;
BEGIN
 v := public.autoriser_jeton_video('a2010000-0000-0000-0000-000000000202',
   'a2010000-0000-0000-0000-000000000003','wss://x','wss://y');
 IF v->>'identity' <> 'a2010000-0000-0000-0000-000000000003'
    OR v->>'role' <> 'teacher'
    OR (v->'capabilities'->>'can_publish')::boolean IS NOT TRUE THEN
  RAISE EXCEPTION 'L201: le remplacant n''obtient pas un jeton enseignant : %', v;
 END IF;
 IF NOT EXISTS (SELECT 1 FROM public.video_token_grants
   WHERE session_id='a2010000-0000-0000-0000-000000000202'
     AND profile_id='a2010000-0000-0000-0000-000000000003' AND role='teacher' AND can_publish) THEN
  RAISE EXCEPTION 'L201: jeton du remplacant non journalise';
 END IF;

 BEGIN
  PERFORM public.autoriser_jeton_video('a2010000-0000-0000-0000-000000000202',
   'a2010000-0000-0000-0000-000000000001','wss://x','wss://y');
  RAISE EXCEPTION 'L201: l''attitre remplace a obtenu un jeton';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
  IF v_state <> '42501' THEN RAISE EXCEPTION 'L201: refus attitre avec SQLSTATE % au lieu de 42501', v_state; END IF;
 END;
END;
$apres$;
RESET ROLE;

-- Partie 2 : retrait d'un eleve. Une seance a venir et une passee, avec participant.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id, join_opens_at)
VALUES ('a2010000-0000-0000-0000-000000000203',
 'a2010000-0000-0000-0000-000000000011', ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '5 days 3 hours') at time zone 'Europe/Paris'), ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '5 days 4 hours') at time zone 'Europe/Paris'),
 'planned','standard','a2010000-0000-0000-0000-000000000102', clock_timestamp()-interval '1 hour');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES ('a2010000-0000-0000-0000-000000000204',
 'a2010000-0000-0000-0000-000000000011', ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '-6 days 3 hours') at time zone 'Europe/Paris'), ((date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '-6 days 4 hours') at time zone 'Europe/Paris'),
 'ended','standard','a2010000-0000-0000-0000-000000000102');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
 ('a2010000-0000-0000-0000-000000000203','a2010000-0000-0000-0000-000000000012','student'),
 ('a2010000-0000-0000-0000-000000000204','a2010000-0000-0000-0000-000000000012','student')
ON CONFLICT (session_id, profile_id) DO UPDATE SET deleted_at = NULL;

-- Avant retrait : l'eleve entre dans la seance a venir.
SELECT set_config('test.uid','a2010000-0000-0000-0000-000000000012',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"student"}}',true);
SET LOCAL ROLE service_role;
DO $eleve_avant$
BEGIN
 IF public.autoriser_jeton_video('a2010000-0000-0000-0000-000000000203',
   'a2010000-0000-0000-0000-000000000012','wss://x','wss://y')->>'role' <> 'student' THEN
  RAISE EXCEPTION 'L201: l''eleve membre n''a pas de jeton avant retrait';
 END IF;
END;
$eleve_avant$;
RESET ROLE;

-- Retrait par l'administration.
SELECT set_config('request.jwt.claim.sub','a2010000-0000-0000-0000-000000000004',true);
SELECT set_config('test.uid','a2010000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
SELECT public.retirer_eleve_groupe('a2010000-0000-0000-0000-000000000102',
  'a2010000-0000-0000-0000-000000000012','L201 retrait');
RESET ROLE;

DO $apres_retrait$
DECLARE v_state text;
BEGIN
 IF (SELECT deleted_at FROM public.session_participants
      WHERE session_id='a2010000-0000-0000-0000-000000000203'
        AND profile_id='a2010000-0000-0000-0000-000000000012') IS NULL THEN
  RAISE EXCEPTION 'L201: participation a venir non coupee';
 END IF;
 IF (SELECT deleted_at FROM public.session_participants
      WHERE session_id='a2010000-0000-0000-0000-000000000204'
        AND profile_id='a2010000-0000-0000-0000-000000000012') IS NOT NULL THEN
  RAISE EXCEPTION 'L201: l''historique passe a ete efface';
 END IF;
 IF EXISTS (SELECT 1 FROM public.session_participants sp
     JOIN public.sessions s ON s.id=sp.session_id
    WHERE sp.profile_id='a2010000-0000-0000-0000-000000000012' AND s.groupe_id='a2010000-0000-0000-0000-000000000102'
      AND s.started_at > now() AND sp.deleted_at IS NULL) THEN
  RAISE EXCEPTION 'L201: il reste une participation a venir';
 END IF;
END;
$apres_retrait$;

SELECT set_config('test.uid','a2010000-0000-0000-0000-000000000012',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"student"}}',true);
SET LOCAL ROLE service_role;
DO $eleve_apres$
DECLARE v_state text;
BEGIN
 BEGIN
  PERFORM public.autoriser_jeton_video('a2010000-0000-0000-0000-000000000203',
   'a2010000-0000-0000-0000-000000000012','wss://x','wss://y');
  RAISE EXCEPTION 'L201: l''eleve retire a obtenu un jeton';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
  IF v_state <> '42501' THEN RAISE EXCEPTION 'L201: refus eleve avec SQLSTATE % au lieu de 42501', v_state; END IF;
 END;
END;
$eleve_apres$;
RESET ROLE;

-- ACL : aucune fonction nouvelle, droits inchanges.
DO $acl$
BEGIN
 IF has_function_privilege('anon','public.autoriser_jeton_video(uuid,uuid,text,text)','EXECUTE')
    OR has_function_privilege('authenticated','public.autoriser_jeton_video(uuid,uuid,text,text)','EXECUTE')
    OR has_function_privilege('authenticated','private.c29_enseignant_effectif_session(uuid)','EXECUTE') THEN
  RAISE EXCEPTION 'L201: ACL elargie';
 END IF;
END;
$acl$;
ROLLBACK;
