-- B-12 : fils/messages et rapports projetes, append-only, aucune table KYC/contact.
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('b1200000-0000-0000-0000-000000000001','b12-admin@test.invalid'),
 ('b1200000-0000-0000-0000-000000000002','b12-controller@test.invalid'),
 ('b1200000-0000-0000-0000-000000000003','b12-other@test.invalid'),
 ('b1200000-0000-0000-0000-000000000004','b12-teacher@test.invalid'),
 ('b1200000-0000-0000-0000-000000000005','b12-student@test.invalid'),
 ('b1200000-0000-0000-0000-000000000099','b12-admin-no-profile@test.invalid');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender)
VALUES
 ('b1200000-0000-0000-0000-000000000001','B12-ADMIN-0001','admin',NULL,'Direction','B12','active','female'),
 ('b1200000-0000-0000-0000-000000000002','B12-CTRL-00001','controller',NULL,'Controleur','B12','active','male'),
 ('b1200000-0000-0000-0000-000000000003','B12-CTRL-00002','controller',NULL,'Autre','B12','active','female'),
 ('b1200000-0000-0000-0000-000000000004','B12-TEACH-0001','teacher',NULL,'Enseignant','B12','provisional_active','male'),
 ('b1200000-0000-0000-0000-000000000005','B12-STUD-00001','student',NULL,'Élève','Présent','active','female');

DO $fixture_teacher_contract$
DECLARE
  v_teacher_version text;
  v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version
  FROM public.contract_texts
  WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version
  FROM public.contract_required_versions
  WHERE contract_kind='recording_and_control_notice';
  PERFORM set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000004',true);
  PERFORM set_config('test.uid','b1200000-0000-0000-0000-000000000004',true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant B12');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('b1200000-0000-0000-0000-000000000004',
          'recording_and_control_notice',v_notice_version);
  UPDATE public.profiles SET account_status='active'
  WHERE id='b1200000-0000-0000-0000-000000000004';
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contract$;
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('b1210000-0000-0000-0000-000000000001','b1200000-0000-0000-0000-000000000004',
        'enfant',5,'Classe B12',1,9,'Europe/Paris');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('b1210000-0000-0000-0000-000000000002','b1200000-0000-0000-0000-000000000004',
        'enfant',5,'Classe B12 scope autre',2,10,'Europe/Paris');
INSERT INTO public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,session_type)
VALUES ('b1220000-0000-0000-0000-000000000001','b1200000-0000-0000-0000-000000000004',
        'b1210000-0000-0000-0000-000000000001',now()-interval '1 hour',now()+interval '1 hour',
        'planned','standard');
INSERT INTO public.session_participants(session_id,profile_id,role,entered_at)
VALUES ('b1220000-0000-0000-0000-000000000001',
        'b1200000-0000-0000-0000-000000000005','student',now()-interval '30 minutes');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('b1200000-0000-0000-0000-000000000002','b1200000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',true,'{}','{}',
        'b1230000-0000-0000-0000-000000000001');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('b1200000-0000-0000-0000-000000000003','b1200000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',false,
        ARRAY['b1210000-0000-0000-0000-000000000002'::uuid],'{}',
        'b1230000-0000-0000-0000-000000000002');

DO $fixture_control_rules$
BEGIN
  PERFORM set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000001',true);
  PERFORM set_config('test.uid','b1200000-0000-0000-0000-000000000001',true);
  PERFORM set_config('request.jwt.claims','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
  PERFORM set_config('test.jwt','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
  PERFORM public.enregistrer_regles_tirage(
    '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[{"id":"b1200000-0000-0000-0000-000000000004","type":"enseignant"}]}'::jsonb,
    'b1230000-0000-0000-0000-000000000020'
  );
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_control_rules$;

-- La mission est créée par le trigger serveur du cycle de séance, jamais par
-- insertion directe dans controle_missions; son démarrage passe par la RPC.
UPDATE public.sessions SET status='preflight'
 WHERE id='b1220000-0000-0000-0000-000000000001';
UPDATE public.sessions SET status='in_progress'
 WHERE id='b1220000-0000-0000-0000-000000000001';
SELECT set_config('test.b12_mission_id',
  (SELECT id::text FROM private.controle_missions
   WHERE session_id='b1220000-0000-0000-0000-000000000001'),true);
SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000002',true);
SELECT set_config('test.uid','b1200000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"controller"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"controller"}}',true);
SET LOCAL ROLE authenticated;
SELECT public.demarrer_mission_controle(current_setting('test.b12_mission_id')::uuid);
RESET ROLE;
INSERT INTO public.session_events(session_id,profile_id,event_type,server_ts,source)
VALUES ('b1220000-0000-0000-0000-000000000001','b1200000-0000-0000-0000-000000000005',
        'joined',now()-interval '30 minutes','server');
UPDATE public.sessions SET status='ended', ended_at=now()
 WHERE id='b1220000-0000-0000-0000-000000000001';
INSERT INTO public.session_events(session_id,profile_id,event_type,server_ts,source)
VALUES ('b1220000-0000-0000-0000-000000000001','b1200000-0000-0000-0000-000000000002',
        'joined',now()-interval '48 minutes','server');

DO $acl$
BEGIN
 IF EXISTS (
      SELECT 1 FROM unnest(ARRAY[
        'public.controleur_lister_fils()'::regprocedure,
        'public.controleur_fil_de_mission(uuid)'::regprocedure,
        'public.controleur_envoyer_message(uuid,uuid,text)'::regprocedure,
        'public.controleur_lister_rapports()'::regprocedure,
        'public.controleur_ajouter_complement(uuid,text,text)'::regprocedure
      ]) AS f(oid)
      WHERE NOT has_function_privilege('authenticated',f.oid,'EXECUTE')
         OR has_function_privilege('anon',f.oid,'EXECUTE')
         OR has_function_privilege('service_role',f.oid,'EXECUTE')
         OR has_function_privilege('agent_ro',f.oid,'EXECUTE')
    )
    OR has_table_privilege('authenticated','public.mission_messages','SELECT')
    OR has_table_privilege('authenticated','public.mission_fils','SELECT')
    OR has_table_privilege('authenticated','public.rapports_mission','SELECT')
    OR has_table_privilege('authenticated','public.rapport_complements','SELECT') THEN
   RAISE EXCEPTION 'B12: ACL/RLS directe invalide';
 END IF;
END;
$acl$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"controller"}}',true);
DO $nominal$
DECLARE v_thread jsonb; v_reports jsonb; v_report_id uuid; v_before jsonb;
BEGIN
 v_thread:=public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
 PERFORM set_config('test.b12_fil_id',v_thread->>'id',true);
 IF v_thread->>'mission_id'<>current_setting('test.b12_mission_id') THEN
   RAISE EXCEPTION 'B12: fil de mission absent';
 END IF;
 PERFORM public.controleur_envoyer_message(
   (v_thread->>'id')::uuid,'b1230000-0000-0000-0000-000000000010','Bonjour Direction');
 PERFORM public.controleur_envoyer_message(
   (v_thread->>'id')::uuid,'b1230000-0000-0000-0000-000000000010','Bonjour Direction');
  v_thread:=public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
  IF jsonb_array_length(v_thread->'messages')<>1 THEN
   RAISE EXCEPTION 'B12: la clé client ne rend pas l''envoi idempotent';
 END IF;
 v_reports:=public.controleur_lister_rapports();
 v_report_id:=(v_reports->0->>'id')::uuid;
 PERFORM set_config('test.b12_rapport_id',v_report_id::text,true);
 IF v_report_id IS NULL OR v_reports->0->>'classe'<>'Classe B12'
    OR v_reports::text ILIKE '%email%' OR v_reports::text ILIKE '%kyc%'
    OR NOT (v_reports->0->'presents' @> '["Élève P."]'::jsonb) THEN
   RAISE EXCEPTION 'B12: projection rapport absente ou trop large';
 END IF;
  v_before:=(v_reports->0)-'statut'-'complements';
 PERFORM public.controleur_ajouter_complement(v_report_id,'Précision ajoutée',NULL);
  v_reports:=public.controleur_lister_rapports();
  IF (v_reports->0)-'statut'-'complements'<>v_before
     OR jsonb_array_length(v_reports->0->'complements')<>1 THEN
   RAISE EXCEPTION 'B12: complément a modifié le rapport parent';
 END IF;
 BEGIN
   PERFORM public.controleur_fil_de_mission('b1240000-0000-0000-0000-000000000099');
   RAISE EXCEPTION 'B12: mission inexistante acceptée';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
   PERFORM public.controleur_envoyer_message((v_thread->>'id')::uuid,
     'b1230000-0000-0000-0000-000000000011','   ');
   RAISE EXCEPTION 'B12: message vide accepté';
 EXCEPTION WHEN invalid_parameter_value THEN NULL;
 END;
END;
$nominal$;
RESET ROLE;

-- Direction active lit les rapports et peut ecrire dans le fil.
SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $direction$
DECLARE v_thread jsonb; v_reports jsonb;
BEGIN
  v_thread:=public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
  v_reports:=public.controleur_lister_rapports();
  IF jsonb_array_length(v_reports)<>1 OR jsonb_array_length(v_thread->'messages')<>1 THEN
    RAISE EXCEPTION 'B12: Direction ne lit pas le fil et le rapport';
  END IF;
  PERFORM public.controleur_envoyer_message(
    (v_thread->>'id')::uuid,'b1230000-0000-0000-0000-000000000012','Reponse Direction');
END;
$direction$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000003',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"controller"}}',true);
SET LOCAL ROLE authenticated;
DO $wrong_controller$
DECLARE v_fils jsonb; v_rapports jsonb;
BEGIN
  v_fils:=public.controleur_lister_fils();
  v_rapports:=public.controleur_lister_rapports();
  IF jsonb_array_length(v_fils)<>0 OR jsonb_array_length(v_rapports)<>0 THEN
    RAISE EXCEPTION 'B12: un autre controleur voit des missions ou rapports';
  END IF;
  BEGIN
  PERFORM public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
  RAISE EXCEPTION 'B12: contrôleur hors mission accepté';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000013','Interdit');
    RAISE EXCEPTION 'B12: autre controleur a ecrit dans le fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: autre controleur a complete un rapport';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$wrong_controller$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $wrong_role$
BEGIN
 BEGIN
  PERFORM public.controleur_lister_fils();
  RAISE EXCEPTION 'B12: enseignant sans capacité a lu les fils';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.controleur_lister_rapports();
    RAISE EXCEPTION 'B12: enseignant sans capacite a lu les rapports';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
    RAISE EXCEPTION 'B12: enseignant sans capacite a ouvert un fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000014','Interdit');
    RAISE EXCEPTION 'B12: enseignant sans capacite a ecrit un message';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: enseignant sans capacite a ajoute un complement';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$wrong_role$;
RESET ROLE;

-- Un compte desactive ne peut plus appeler les RPC, meme avec un JWT de role admin.
UPDATE public.profiles SET account_status='disabled'
 WHERE id='b1200000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $disabled_admin$
BEGIN
  BEGIN PERFORM public.controleur_lister_fils();
    RAISE EXCEPTION 'B12: direction desactivee lit les fils';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
    RAISE EXCEPTION 'B12: direction desactivee ouvre un fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000015','Interdit');
    RAISE EXCEPTION 'B12: direction desactivee envoie un message';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_lister_rapports();
    RAISE EXCEPTION 'B12: direction desactivee lit les rapports';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: direction desactivee ajoute un complement';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$disabled_admin$;
RESET ROLE;

UPDATE public.profiles SET account_status='disabled'
 WHERE id='b1200000-0000-0000-0000-000000000002';
SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"controller"}}',true);
SET LOCAL ROLE authenticated;
DO $disabled_controller$
BEGIN
  BEGIN PERFORM public.controleur_lister_fils();
    RAISE EXCEPTION 'B12: controleur desactive lit les fils';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
    RAISE EXCEPTION 'B12: controleur desactive ouvre un fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000017','Interdit');
    RAISE EXCEPTION 'B12: controleur desactive envoie un message';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_lister_rapports();
    RAISE EXCEPTION 'B12: controleur desactive lit les rapports';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: controleur desactive ajoute un complement';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$disabled_controller$;
RESET ROLE;

-- Un JWT admin sans profil ne passe aucune RPC, même si son rôle est valide.
SELECT set_config('request.jwt.claim.sub','b1200000-0000-0000-0000-000000000099',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $admin_without_profile$
BEGIN
  BEGIN PERFORM public.controleur_lister_fils();
    RAISE EXCEPTION 'B12: admin sans profil lit les fils';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_fil_de_mission('b1240000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'B12: admin sans profil ouvre un fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000016','Interdit');
    RAISE EXCEPTION 'B12: admin sans profil envoie un message';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_lister_rapports();
    RAISE EXCEPTION 'B12: admin sans profil lit les rapports';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: admin sans profil ajoute un complement';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$admin_without_profile$;

-- Le complément n'est accessible qu'au contrôleur; vérifier ce rôle sans profil.
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"controller"}}',true);
DO $controller_without_profile$
BEGIN
  BEGIN PERFORM public.controleur_lister_fils();
    RAISE EXCEPTION 'B12: controleur sans profil lit les fils';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
    RAISE EXCEPTION 'B12: controleur sans profil ouvre un fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000018','Interdit');
    RAISE EXCEPTION 'B12: controleur sans profil envoie un message';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_lister_rapports();
    RAISE EXCEPTION 'B12: controleur sans profil lit les rapports';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: contrôleur sans profil ajoute un complément';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$controller_without_profile$;
RESET ROLE;

-- anon ne possede pas EXECUTE sur les RPC.
SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claims','{}',true);
SET LOCAL ROLE anon;
DO $anonymous$
BEGIN
  IF EXISTS (
    SELECT 1 FROM unnest(ARRAY[
      'public.controleur_lister_fils()'::regprocedure,
      'public.controleur_fil_de_mission(uuid)'::regprocedure,
      'public.controleur_envoyer_message(uuid,uuid,text)'::regprocedure,
      'public.controleur_lister_rapports()'::regprocedure,
      'public.controleur_ajouter_complement(uuid,text,text)'::regprocedure
    ]) AS rpc(oid)
    WHERE pg_catalog.has_function_privilege('anon', rpc.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'B12: anon conserve EXECUTE sur une RPC controleur';
  END IF;
  BEGIN PERFORM public.controleur_lister_fils();
    RAISE EXCEPTION 'B12: anon a execute la RPC';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_fil_de_mission(current_setting('test.b12_mission_id')::uuid);
    RAISE EXCEPTION 'B12: anon a ouvert un fil';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_envoyer_message(
      current_setting('test.b12_fil_id')::uuid,'b1230000-0000-0000-0000-000000000019','Interdit');
    RAISE EXCEPTION 'B12: anon a envoye un message';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_lister_rapports();
    RAISE EXCEPTION 'B12: anon a lu des rapports';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.controleur_ajouter_complement(
      current_setting('test.b12_rapport_id')::uuid,'Interdit',NULL);
    RAISE EXCEPTION 'B12: anon a ajoute un complement';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$anonymous$;
RESET ROLE;

-- Les triggers refusent aussi les mutations privilegiees; les ecritures RPC sont auditees.
DO $immutable$
BEGIN
  BEGIN UPDATE public.mission_messages SET texte='change'
    WHERE cle_client='b1230000-0000-0000-0000-000000000010';
    RAISE EXCEPTION 'B12: message modifie';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
  BEGIN DELETE FROM public.rapports_mission
    WHERE mission_id=current_setting('test.b12_mission_id')::uuid;
    RAISE EXCEPTION 'B12: rapport supprime';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
  BEGIN UPDATE public.rapport_complements SET texte='change'
    WHERE rapport_id=current_setting('test.b12_rapport_id')::uuid;
    RAISE EXCEPTION 'B12: complement modifie';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL; END;
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs
      WHERE action='b12_envoyer_message' AND table_name='mission_messages')
     OR NOT EXISTS (SELECT 1 FROM public.audit_logs
      WHERE action='b12_ajouter_complement' AND table_name='rapport_complements') THEN
    RAISE EXCEPTION 'B12: une ecriture ne produit pas de trace d''audit';
  END IF;
END;
$immutable$;

-- Le stub auth ne simule pas l'expiration JWT, validee par le gateway d'authentification.
ROLLBACK;
