-- Salle en groupe (30/10/2026), migration 20261102100000.
-- 1. Un eleve ajoute a la Classe pendant la seance du jour y est inscrit et
--    obtient son jeton ; une seance terminee n'est pas touchee.
-- 2. Les gestes de l'enseignant (couper micro ou camera, faire sortir) ne
--    passent que pour l'enseignant effectif de CETTE seance, sur un eleve
--    inscrit ; ils sont journalises ; l'eleve sorti n'a plus de jeton tant
--    que l'enseignant ne le readmet pas.
-- Chaque refus est prouve par son SQLSTATE, jamais par un message.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('5a1e0000-0000-0000-0000-000000000001','sg-teacher@test.invalid'),
 ('5a1e0000-0000-0000-0000-000000000002','sg-teacher2@test.invalid'),
 ('5a1e0000-0000-0000-0000-000000000003','sg-admin@test.invalid'),
 ('5a1e0000-0000-0000-0000-000000000011','sg-e1@test.invalid'),
 ('5a1e0000-0000-0000-0000-000000000012','sg-e2@test.invalid'),
 ('5a1e0000-0000-0000-0000-000000000013','sg-e3@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('5a1e00ff-0000-0000-0000-00000000000a','Europe/Paris');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('5a1e0000-0000-0000-0000-000000000001','SG-T1','teacher',NULL,'Enseignant','Un','provisional_active','male'),
 ('5a1e0000-0000-0000-0000-000000000002','SG-T2','teacher',NULL,'Enseignant','Deux','provisional_active','male'),
 ('5a1e0000-0000-0000-0000-000000000003','SG-ADM','admin',NULL,'Direction','A','active','female'),
 ('5a1e0000-0000-0000-0000-000000000011','SG-E1','student','5a1e00ff-0000-0000-0000-00000000000a','Eleve','Un','active','male'),
 ('5a1e0000-0000-0000-0000-000000000012','SG-E2','student','5a1e00ff-0000-0000-0000-00000000000a','Eleve','Deux','active','male'),
 ('5a1e0000-0000-0000-0000-000000000013','SG-E3','student','5a1e00ff-0000-0000-0000-00000000000a','Eleve','Trois','active','male');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
 ('5a1e0000-0000-0000-0000-000000000001','approved'),
 ('5a1e0000-0000-0000-0000-000000000002','approved');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy) VALUES
 ('5a1e0000-0000-0000-0000-000000000011','minor','standard','allowed'),
 ('5a1e0000-0000-0000-0000-000000000012','minor','standard','allowed'),
 ('5a1e0000-0000-0000-0000-000000000013','minor','standard','allowed');
DO $fixture_contrats$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 FOR v_teacher IN SELECT id FROM public.profiles WHERE immutable_id IN ('SG-T1','SG-T2') LOOP
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
$fixture_contrats$;

INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES ('5a1e0000-0000-0000-0000-000000000101',
 '5a1e0000-0000-0000-0000-000000000001','enfant',5,'SG classe',1,18,'Europe/Paris','hommes');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
 ('5a1e0000-0000-0000-0000-000000000101','5a1e0000-0000-0000-0000-000000000011');

-- La seance du jour, commencee il y a dix minutes, et une seance terminee.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id, join_opens_at)
VALUES
 ('5a1e0000-0000-0000-0000-000000000201','5a1e0000-0000-0000-0000-000000000001',
  clock_timestamp() - interval '10 minutes', clock_timestamp() + interval '50 minutes',
  'planned','child','5a1e0000-0000-0000-0000-000000000101', clock_timestamp() - interval '30 minutes'),
 ('5a1e0000-0000-0000-0000-000000000202','5a1e0000-0000-0000-0000-000000000001',
  clock_timestamp() - interval '2 days', clock_timestamp() - interval '2 days' + interval '1 hour',
  'planned','child','5a1e0000-0000-0000-0000-000000000101', clock_timestamp() - interval '2 days 20 minutes');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
 ('5a1e0000-0000-0000-0000-000000000201','5a1e0000-0000-0000-0000-000000000011','student'),
 ('5a1e0000-0000-0000-0000-000000000202','5a1e0000-0000-0000-0000-000000000011','student');

-- 1. Avant l'ajout : E2 n'a pas de jeton (42501).
SET LOCAL ROLE service_role;
DO $avant_ajout$
DECLARE v_state text;
BEGIN
 BEGIN
  PERFORM public.autoriser_jeton_video('5a1e0000-0000-0000-0000-000000000201',
    '5a1e0000-0000-0000-0000-000000000012','wss://x','wss://y');
  RAISE EXCEPTION 'SG: E2 a un jeton avant d''etre dans la Classe';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
  IF v_state <> '42501' THEN RAISE EXCEPTION 'SG: refus E2 avec SQLSTATE % au lieu de 42501 (%)', v_state, SQLERRM; END IF;
 END;
END;
$avant_ajout$;
RESET ROLE;

-- La direction ajoute E2 pendant la seance.
SELECT set_config('request.jwt.claim.sub','5a1e0000-0000-0000-0000-000000000003',true);
SELECT set_config('test.uid','5a1e0000-0000-0000-0000-000000000003',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
SELECT public.ajouter_eleve_groupe('5a1e0000-0000-0000-0000-000000000101',
  '5a1e0000-0000-0000-0000-000000000012','Arrivee en cours de seance');
RESET ROLE;

DO $apres_ajout$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.session_participants
   WHERE session_id='5a1e0000-0000-0000-0000-000000000201'
     AND profile_id='5a1e0000-0000-0000-0000-000000000012'
     AND role='student' AND deleted_at IS NULL) THEN
  RAISE EXCEPTION 'SG: E2 ajoute n''est pas inscrit a la seance en cours';
 END IF;
 IF EXISTS (SELECT 1 FROM public.session_participants
   WHERE session_id='5a1e0000-0000-0000-0000-000000000202'
     AND profile_id='5a1e0000-0000-0000-0000-000000000012') THEN
  RAISE EXCEPTION 'SG: E2 a ete inscrit a une seance terminee';
 END IF;
END;
$apres_ajout$;

-- Les jetons : E2 entre ; la capacite can_moderate n'est qu'a l'enseignant.
SET LOCAL ROLE service_role;
DO $jetons$
DECLARE v jsonb;
BEGIN
 v := public.autoriser_jeton_video('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000012','wss://x','wss://y');
 IF v->>'role' <> 'student' OR (v->'capabilities'->>'can_moderate')::boolean IS NOT FALSE THEN
  RAISE EXCEPTION 'SG: jeton eleve inattendu : %', v;
 END IF;
 v := public.autoriser_jeton_video('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000001','wss://x','wss://y');
 IF v->>'role' <> 'teacher' OR (v->'capabilities'->>'can_moderate')::boolean IS NOT TRUE THEN
  RAISE EXCEPTION 'SG: jeton enseignant sans can_moderate : %', v;
 END IF;
END;
$jetons$;

-- 2. Les gestes : refus.
DO $refus$
DECLARE v_state text; v_cas record;
BEGIN
 FOR v_cas IN SELECT * FROM (VALUES
   -- un eleve ne fait pas sortir un camarade
   ('5a1e0000-0000-0000-0000-000000000011'::uuid, '5a1e0000-0000-0000-0000-000000000012'::uuid, 'faire_sortir', '42501'),
   -- l'enseignant d'une autre Classe non plus
   ('5a1e0000-0000-0000-0000-000000000002'::uuid, '5a1e0000-0000-0000-0000-000000000012'::uuid, 'couper_micro', '42501'),
   -- l'enseignant ne se vise pas lui-meme
   ('5a1e0000-0000-0000-0000-000000000001'::uuid, '5a1e0000-0000-0000-0000-000000000001'::uuid, 'couper_micro', '42501'),
   -- ni un eleve hors de la seance
   ('5a1e0000-0000-0000-0000-000000000001'::uuid, '5a1e0000-0000-0000-0000-000000000013'::uuid, 'faire_sortir', '42501'),
   -- un geste inconnu est refuse
   ('5a1e0000-0000-0000-0000-000000000001'::uuid, '5a1e0000-0000-0000-0000-000000000012'::uuid, 'bannir', '22023')
 ) AS c(appelant, cible, geste, attendu) LOOP
  BEGIN
   PERFORM public.autoriser_geste_salle('5a1e0000-0000-0000-0000-000000000201',
     v_cas.appelant, v_cas.cible, v_cas.geste);
   RAISE EXCEPTION 'SG: geste % de % sur % accepte', v_cas.geste, v_cas.appelant, v_cas.cible;
  EXCEPTION WHEN OTHERS THEN
   GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
   IF v_state <> v_cas.attendu THEN
    RAISE EXCEPTION 'SG: geste % de % : SQLSTATE % au lieu de % (%)',
      v_cas.geste, v_cas.appelant, v_state, v_cas.attendu, SQLERRM;
   END IF;
  END;
 END LOOP;
 -- Une seance terminee : salle fermee (23514).
 BEGIN
  PERFORM public.autoriser_geste_salle('5a1e0000-0000-0000-0000-000000000202',
    '5a1e0000-0000-0000-0000-000000000001','5a1e0000-0000-0000-0000-000000000011','couper_micro');
  RAISE EXCEPTION 'SG: geste accepte sur une seance terminee';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
  IF v_state <> '23514' THEN RAISE EXCEPTION 'SG: seance terminee : SQLSTATE % (%)', v_state, SQLERRM; END IF;
 END;
END;
$refus$;

-- Les gestes de l'enseignant effectif : route rendue, journal ecrit, sortie.
DO $gestes$
DECLARE v jsonb; v_state text;
BEGIN
 v := public.autoriser_geste_salle('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000001','5a1e0000-0000-0000-0000-000000000012','couper_micro');
 IF v->>'identity' <> '5a1e0000-0000-0000-0000-000000000012' OR coalesce(v->>'room_name','') = ''
    OR coalesce(v->>'ws_url','') = '' THEN
  RAISE EXCEPTION 'SG: route du geste incomplete : %', v;
 END IF;
 IF NOT EXISTS (SELECT 1 FROM public.audit_logs
   WHERE action='salle_geste_couper_micro' AND row_id='5a1e0000-0000-0000-0000-000000000201'
     AND payload->>'enseignant'='5a1e0000-0000-0000-0000-000000000001'
     AND payload->>'eleve'='5a1e0000-0000-0000-0000-000000000012') THEN
  RAISE EXCEPTION 'SG: geste non journalise';
 END IF;

 PERFORM public.autoriser_geste_salle('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000001','5a1e0000-0000-0000-0000-000000000012','faire_sortir');
 -- Deux fois : idempotent, une seule sortie active.
 PERFORM public.autoriser_geste_salle('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000001','5a1e0000-0000-0000-0000-000000000012','faire_sortir');
 IF (SELECT count(*) FROM public.salle_exclusions
     WHERE session_id='5a1e0000-0000-0000-0000-000000000201' AND readmis_le IS NULL) <> 1 THEN
  RAISE EXCEPTION 'SG: sortie non enregistree une fois';
 END IF;

 -- E2 sorti : plus de jeton ; E1 entre toujours.
 BEGIN
  PERFORM public.autoriser_jeton_video('5a1e0000-0000-0000-0000-000000000201',
    '5a1e0000-0000-0000-0000-000000000012','wss://x','wss://y');
  RAISE EXCEPTION 'SG: l''eleve sorti a obtenu un jeton';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
  IF v_state <> '42501' THEN RAISE EXCEPTION 'SG: refus de l''eleve sorti : SQLSTATE % (%)', v_state, SQLERRM; END IF;
 END;
 PERFORM public.autoriser_jeton_video('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000011','wss://x','wss://y');
END;
$gestes$;
RESET ROLE;

-- La liste des sortis et la readmission : l'enseignant effectif seulement.
SELECT set_config('request.jwt.claim.sub','5a1e0000-0000-0000-0000-000000000011',true);
SELECT set_config('test.uid','5a1e0000-0000-0000-0000-000000000011',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"student"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"student"}}',true);
SET LOCAL ROLE authenticated;
DO $eleve$
DECLARE v_state text;
BEGIN
 IF (SELECT count(*) FROM public.eleves_sortis_salle('5a1e0000-0000-0000-0000-000000000201')) <> 0 THEN
  RAISE EXCEPTION 'SG: un eleve lit la liste des sortis';
 END IF;
 BEGIN
  PERFORM public.readmettre_eleve_salle('5a1e0000-0000-0000-0000-000000000201',
    '5a1e0000-0000-0000-0000-000000000012');
  RAISE EXCEPTION 'SG: un eleve a readmis un camarade';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
  IF v_state <> '42501' THEN RAISE EXCEPTION 'SG: readmission eleve : SQLSTATE % (%)', v_state, SQLERRM; END IF;
 END;
 BEGIN
  PERFORM public.autoriser_geste_salle('5a1e0000-0000-0000-0000-000000000201',
    '5a1e0000-0000-0000-0000-000000000001','5a1e0000-0000-0000-0000-000000000011','couper_micro');
  RAISE EXCEPTION 'SG: un compte connecte appelle autoriser_geste_salle';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
  PERFORM 1 FROM public.salle_exclusions;
  RAISE EXCEPTION 'SG: un compte connecte lit salle_exclusions';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$eleve$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub','5a1e0000-0000-0000-0000-000000000001',true);
SELECT set_config('test.uid','5a1e0000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $enseignant$
BEGIN
 IF (SELECT array_agg(profile_id) FROM public.eleves_sortis_salle('5a1e0000-0000-0000-0000-000000000201'))
    IS DISTINCT FROM ARRAY['5a1e0000-0000-0000-0000-000000000012'::uuid] THEN
  RAISE EXCEPTION 'SG: l''enseignant ne lit pas l''eleve sorti';
 END IF;
 PERFORM public.readmettre_eleve_salle('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000012');
 IF (SELECT count(*) FROM public.eleves_sortis_salle('5a1e0000-0000-0000-0000-000000000201')) <> 0 THEN
  RAISE EXCEPTION 'SG: l''eleve readmis reste dans la liste des sortis';
 END IF;
END;
$enseignant$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $readmis$
BEGIN
 PERFORM public.autoriser_jeton_video('5a1e0000-0000-0000-0000-000000000201',
   '5a1e0000-0000-0000-0000-000000000012','wss://x','wss://y');
 IF NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action='salle_geste_readmettre'
   AND payload->>'eleve'='5a1e0000-0000-0000-0000-000000000012') THEN
  RAISE EXCEPTION 'SG: readmission non journalisee';
 END IF;
END;
$readmis$;
RESET ROLE;

ROLLBACK;
