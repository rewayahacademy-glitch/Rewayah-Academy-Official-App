-- N3, D3 (03/11/2026) : la mission du controleur et l'envoi de son compte
-- rendu (migration 20261105800000), sous `authenticated`.
--   1. la mission rend ce que l'ecran affiche (Classe, prenom de
--      l'enseignant, eleves attendus, etat de la seance) ;
--   2. avant « Commencer le controle », aucun compte rendu ;
--   3. le controleur transmet la visite, puis joint sa reponse une fois ;
--      la meme cle rend le meme resultat, une autre reponse est refusee ;
--   4. une observation invalide (texte manquant, eleve hors seance) est
--      refusee ;
--   5. le roster de la visite (prenom et initiale) et l'Historique, qui rend
--      la reponse choisie apres la fin de la seance ;
--   6. un autre controleur, un enseignant et un controleur sans seconde
--      etape de connexion sont refuses (envoi et roster).
-- La fixture reprend celle de B-12 (scenarios_b12_control_mission.sql).
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('c3d00000-0000-0000-0000-000000000001','n3d-admin@test.invalid'),
 ('c3d00000-0000-0000-0000-000000000002','n3d-controller@test.invalid'),
 ('c3d00000-0000-0000-0000-000000000003','n3d-other@test.invalid'),
 ('c3d00000-0000-0000-0000-000000000004','n3d-teacher@test.invalid'),
 ('c3d00000-0000-0000-0000-000000000005','n3d-student@test.invalid'),
 ('c3d00000-0000-0000-0000-000000000099','n3d-admin-no-profile@test.invalid');
INSERT INTO public.households(id,timezone)
VALUES ('c3d40000-0000-0000-0000-000000000001','Europe/Paris');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender)
VALUES
 ('c3d00000-0000-0000-0000-000000000001','N3D-ADMIN-0001','admin',NULL,'Direction','N3D','active','female'),
 ('c3d00000-0000-0000-0000-000000000002','N3D-CTRL-00001','controller',NULL,'Controleur','N3D','active','male'),
 ('c3d00000-0000-0000-0000-000000000003','N3D-CTRL-00002','controller',NULL,'Autre','N3D','active','female'),
 ('c3d00000-0000-0000-0000-000000000004','N3D-TEACH-0001','teacher',NULL,'Enseignant','N3D','provisional_active','male'),
 ('c3d00000-0000-0000-0000-000000000005','N3D-STUD-00001','student','c3d40000-0000-0000-0000-000000000001','Élève','Présent','active','female');
INSERT INTO public.teacher_profiles(profile_id,kyc_status)
VALUES ('c3d00000-0000-0000-0000-000000000004','approved');

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
  PERFORM set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000004',true);
  PERFORM set_config('test.uid','c3d00000-0000-0000-0000-000000000004',true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant N3D');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('c3d00000-0000-0000-0000-000000000004',
          'recording_and_control_notice',v_notice_version);
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('c3d00000-0000-0000-0000-000000000004','teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active'
  WHERE id='c3d00000-0000-0000-0000-000000000004';
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contract$;
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('c3d10000-0000-0000-0000-000000000001','c3d00000-0000-0000-0000-000000000004',
        'enfant',5,'Classe N3D',1,9,'Europe/Paris');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('c3d10000-0000-0000-0000-000000000002','c3d00000-0000-0000-0000-000000000004',
        'enfant',5,'Classe N3D scope autre',2,10,'Europe/Paris');
INSERT INTO public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,session_type)
VALUES ('c3d20000-0000-0000-0000-000000000001','c3d00000-0000-0000-0000-000000000004',
        'c3d10000-0000-0000-0000-000000000001',now()-interval '1 hour',now()+interval '1 hour',
        'planned','standard');
INSERT INTO public.session_participants(session_id,profile_id,role,entered_at)
VALUES ('c3d20000-0000-0000-0000-000000000001',
        'c3d00000-0000-0000-0000-000000000005','student',now()-interval '30 minutes');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('c3d00000-0000-0000-0000-000000000002','c3d00000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',true,'{}','{}',
        'c3d30000-0000-0000-0000-000000000001');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('c3d00000-0000-0000-0000-000000000003','c3d00000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',false,
        ARRAY['c3d10000-0000-0000-0000-000000000002'::uuid],'{}',
        'c3d30000-0000-0000-0000-000000000002');

DO $fixture_control_rules$
BEGIN
  PERFORM set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000001',true);
  PERFORM set_config('test.uid','c3d00000-0000-0000-0000-000000000001',true);
  PERFORM set_config('request.jwt.claims','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
  PERFORM set_config('test.jwt','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
  PERFORM public.enregistrer_regles_tirage(
    '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[{"id":"c3d00000-0000-0000-0000-000000000004","type":"enseignant"}]}'::jsonb,
    'c3d30000-0000-0000-0000-000000000020'
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
 WHERE id='c3d20000-0000-0000-0000-000000000001';
UPDATE public.sessions SET status='in_progress'
 WHERE id='c3d20000-0000-0000-0000-000000000001';
SELECT set_config('test.n3d_mission_id',
  (SELECT id::text FROM private.controle_missions
   WHERE session_id='c3d20000-0000-0000-0000-000000000001'),true);

-- Le controleur, connexion en deux etapes, autorisation fraiche.
SELECT set_config('test.ctrl_claims', jsonb_build_object(
  'sub','c3d00000-0000-0000-0000-000000000002','aal','aal2',
  'app_metadata', jsonb_build_object('role','controller','authorization_version',
    (SELECT authorization_version FROM public.profiles WHERE id='c3d00000-0000-0000-0000-000000000002')))::text, true);
SELECT set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims',current_setting('test.ctrl_claims'),true);
SET LOCAL ROLE authenticated;
DO $mission$
DECLARE v jsonb;
BEGIN
  v := public.ma_mission_controle();
  IF v->>'id' IS DISTINCT FROM current_setting('test.n3d_mission_id')
     OR v->>'classe' IS DISTINCT FROM 'Classe N3D'
     OR v->>'enseignant_prenom' IS DISTINCT FROM 'Enseignant'
     OR (v->>'nombre_eleves')::int <> 1
     OR v->>'seance_statut' IS DISTINCT FROM 'in_progress'
     OR v->>'debut' IS NULL OR v->>'fin_prevue' IS NULL THEN
    RAISE EXCEPTION 'N3: projection de la mission incomplete : %', v;
  END IF;
  IF v::text ILIKE '%Présent%' OR v::text ILIKE '%email%' THEN
    RAISE EXCEPTION 'N3: la mission expose un nom de famille ou un contact';
  END IF;
  BEGIN
    PERFORM public.controleur_envoyer_compte_rendu(
      'c3d20000-0000-0000-0000-000000000001', NULL, NULL, NULL);
    RAISE EXCEPTION 'N3: compte rendu accepte avant le debut de la visite';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  PERFORM public.demarrer_mission_controle(current_setting('test.n3d_mission_id')::uuid);
END;
$mission$;

DO $envoi$
DECLARE v jsonb; v2 jsonb;
BEGIN
  -- Le roster de la visite : l'eleve de la seance, prenom et initiale.
  v := public.controleur_roster_visite('c3d20000-0000-0000-0000-000000000001');
  IF jsonb_array_length(v) <> 1 OR v->0->>'id' <> 'c3d00000-0000-0000-0000-000000000005'
     OR v->0->>'prenom' <> 'Élève' OR v->0->>'initiale' <> 'P'
     OR v::text ILIKE '%Présent%' THEN
    RAISE EXCEPTION 'N3: roster de la visite invalide : %', v;
  END IF;
  -- La visite part des la sortie, sans reponse.
  v := public.controleur_envoyer_compte_rendu(
    'c3d20000-0000-0000-0000-000000000001', NULL, NULL, NULL);
  IF v->>'transmise_le' IS NULL OR v->>'choix' IS NOT NULL OR v->>'envoye_le' IS NOT NULL THEN
    RAISE EXCEPTION 'N3: transmission de la visite invalide : %', v;
  END IF;
  -- Point important sans texte : refuse.
  BEGIN
    PERFORM public.controleur_envoyer_compte_rendu(
      'c3d20000-0000-0000-0000-000000000001', 'point_important',
      '{"nature":"a_suivre","domaine":"pedagogie","personne":"enseignant","texte":"  "}'::jsonb,
      'c3d30000-0000-0000-0000-000000000031');
    RAISE EXCEPTION 'N3: point important sans texte accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  -- Eleve hors de la seance : refuse.
  BEGIN
    PERFORM public.controleur_envoyer_compte_rendu(
      'c3d20000-0000-0000-0000-000000000001', 'ajouter_observation',
      '{"nature":"point_positif","domaine":"climat","personne":"eleve_precis","eleve_id":"c3d00000-0000-0000-0000-000000000003","texte":""}'::jsonb,
      'c3d30000-0000-0000-0000-000000000032');
    RAISE EXCEPTION 'N3: eleve hors seance accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  -- Le compte rendu, avec une observation sur l'eleve present.
  v := public.controleur_envoyer_compte_rendu(
    'c3d20000-0000-0000-0000-000000000001', 'point_important',
    '{"nature":"intervention_admin","domaine":"respect_cadre","personne":"eleve_precis","eleve_id":"c3d00000-0000-0000-0000-000000000005","texte":"A voir avec la direction."}'::jsonb,
    'c3d30000-0000-0000-0000-000000000033');
  IF v->>'choix' IS DISTINCT FROM 'point_important' OR v->>'envoye_le' IS NULL THEN
    RAISE EXCEPTION 'N3: compte rendu non envoye : %', v;
  END IF;
  -- Meme cle : meme resultat.
  v2 := public.controleur_envoyer_compte_rendu(
    'c3d20000-0000-0000-0000-000000000001', 'point_important',
    '{"nature":"intervention_admin","domaine":"respect_cadre","personne":"eleve_precis","eleve_id":"c3d00000-0000-0000-0000-000000000005","texte":"A voir avec la direction."}'::jsonb,
    'c3d30000-0000-0000-0000-000000000033');
  IF v2 IS DISTINCT FROM v THEN
    RAISE EXCEPTION 'N3: la meme cle ne rend pas le meme resultat';
  END IF;
  -- La meme cle avec une autre reponse : refusee.
  BEGIN
    PERFORM public.controleur_envoyer_compte_rendu(
      'c3d20000-0000-0000-0000-000000000001', 'rien_a_signaler', NULL,
      'c3d30000-0000-0000-0000-000000000033');
    RAISE EXCEPTION 'N3: meme cle, autre reponse acceptee';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
  -- Une autre reponse ensuite : refusee.
  BEGIN
    PERFORM public.controleur_envoyer_compte_rendu(
      'c3d20000-0000-0000-0000-000000000001', 'rien_a_signaler', NULL,
      'c3d30000-0000-0000-0000-000000000034');
    RAISE EXCEPTION 'N3: seconde reponse acceptee';
  EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
  END;
END;
$envoi$;
RESET ROLE;

DO $base$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM private.controle_missions m
                  WHERE m.id = current_setting('test.n3d_mission_id')::uuid
                    AND m.rapport_envoye AND m.rapport_envoye_le IS NOT NULL) THEN
    RAISE EXCEPTION 'N3: la mission n''est pas marquee rapport envoye';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.controle_comptes_rendus cr
                  WHERE cr.mission_id = current_setting('test.n3d_mission_id')::uuid
                    AND cr.observation->>'eleve_id' = 'c3d00000-0000-0000-0000-000000000005'
                    AND (cr.observation->>'important')::boolean) THEN
    RAISE EXCEPTION 'N3: observation absente ou incomplete';
  END IF;
END;
$base$;

-- La seance finit : le rapport est cree ; l'Historique rend la reponse.
UPDATE public.sessions SET status='ended', ended_at=now()
 WHERE id='c3d20000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims',current_setting('test.ctrl_claims'),true);
SET LOCAL ROLE authenticated;
DO $historique$
DECLARE v jsonb;
BEGIN
  v := public.controleur_lister_rapports();
  IF jsonb_array_length(v) <> 1 OR v->0->>'choix' IS DISTINCT FROM 'point_important'
     OR v->0->>'statut' IS DISTINCT FROM 'envoye'
     OR v->0->'observation'->>'nature' IS DISTINCT FROM 'intervention_admin'
     OR v->0->>'eleve' IS DISTINCT FROM 'Élève P.' THEN
    RAISE EXCEPTION 'N3: l''Historique ne rend pas la reponse : %', v;
  END IF;
END;
$historique$;
RESET ROLE;

-- Un autre controleur : refuse.
SELECT set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000003',true);
SELECT set_config('request.jwt.claims','{"aal":"aal2","app_metadata":{"role":"controller"}}',true);
SET LOCAL ROLE authenticated;
DO $autre$
BEGIN
  PERFORM public.controleur_envoyer_compte_rendu(
    'c3d20000-0000-0000-0000-000000000001', 'rien_a_signaler', NULL,
    'c3d30000-0000-0000-0000-000000000035');
  RAISE EXCEPTION 'N3: un autre controleur a envoye le compte rendu';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$autre$;
DO $autre_roster$
BEGIN
  PERFORM public.controleur_roster_visite('c3d20000-0000-0000-0000-000000000001');
  RAISE EXCEPTION 'N3: un autre controleur a lu le roster';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$autre_roster$;
RESET ROLE;

-- L'enseignant de la seance : refuse.
SELECT set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"aal":"aal2","app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $enseignant$
BEGIN
  PERFORM public.controleur_envoyer_compte_rendu(
    'c3d20000-0000-0000-0000-000000000001', 'rien_a_signaler', NULL,
    'c3d30000-0000-0000-0000-000000000036');
  RAISE EXCEPTION 'N3: un enseignant a envoye un compte rendu';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$enseignant$;
DO $enseignant_roster$
BEGIN
  PERFORM public.controleur_roster_visite('c3d20000-0000-0000-0000-000000000001');
  RAISE EXCEPTION 'N3: un enseignant a lu le roster du controleur';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$enseignant_roster$;
RESET ROLE;

-- Le controleur de la mission, sans seconde etape : refuse.
SELECT set_config('request.jwt.claim.sub','c3d00000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"aal":"aal1","app_metadata":{"role":"controller"}}',true);
SET LOCAL ROLE authenticated;
DO $aal1$
BEGIN
  PERFORM public.controleur_envoyer_compte_rendu(
    'c3d20000-0000-0000-0000-000000000001', NULL, NULL, NULL);
  RAISE EXCEPTION 'N3: compte rendu accepte sans seconde etape';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$aal1$;
RESET ROLE;

ROLLBACK;
