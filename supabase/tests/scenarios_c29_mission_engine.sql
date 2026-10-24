BEGIN;

INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  ('c2910000-0000-0000-0000-000000000001', 'c29-engine-admin@test.invalid', now()),
  ('c2910000-0000-0000-0000-000000000002', 'c29-engine-teacher@test.invalid', now());
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status)
VALUES
  ('c2910000-0000-0000-0000-000000000001', 'C29-ENG-ADM-01', 'admin', 'Admin', 'Engine', 'active'),
  ('c2910000-0000-0000-0000-000000000002', 'C29-ENG-TCH-01', 'teacher', 'Teacher', 'Engine', 'provisional_active');
INSERT INTO public.teacher_profiles (profile_id, kyc_status)
VALUES ('c2910000-0000-0000-0000-000000000002', 'approved');
DO $fixture_teacher_contracts$
DECLARE v_teacher_version text; v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version FROM public.contract_texts
   WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version FROM public.contract_required_versions
   WHERE contract_kind='recording_and_control_notice';
  PERFORM set_config('request.jwt.claim.sub','c2910000-0000-0000-0000-000000000002',true);
  PERFORM set_config('test.uid','c2910000-0000-0000-0000-000000000002',true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('c2910000-0000-0000-0000-000000000002','recording_and_control_notice',v_notice_version)
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('c2910000-0000-0000-0000-000000000002','teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active'
   WHERE id='c2910000-0000-0000-0000-000000000002';
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;

INSERT INTO public.notifications (destinataire, evenement, params, destination)
VALUES ('c2910000-0000-0000-0000-000000000001','demande_presentation',
  '{"demande_id":"c2912000-0000-0000-0000-000000000001"}'::jsonb,
  '/tuteur/demandes');
DO $presentation_event_assert$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.notifications
    WHERE destinataire='c2910000-0000-0000-0000-000000000001'
      AND evenement='demande_presentation'
      AND params->>'demande_id'='c2912000-0000-0000-0000-000000000001') THEN
    RAISE EXCEPTION 'C29: presentation notification event is not accepted';
  END IF;
END
$presentation_event_assert$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'c2910000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);

DO $test$
DECLARE
  v_payload jsonb := '{
    "missions_par_semaine": 5,
    "ponderations": {
      "enseignants_recents": "normal",
      "classes_signalees": "fort",
      "heures_de_pointe": "aucun"
    },
    "cibles": [{"id":"c2910000-0000-0000-0000-000000000002","type":"enseignant"}]
  }'::jsonb;
  v_first integer;
  v_repeat integer;
  v_rejected boolean := false;
  v_invalid boolean := false;
BEGIN
  v_first := (public.enregistrer_regles_tirage(
    v_payload, 'c2911000-0000-0000-0000-000000000001'
  )->>'version')::integer;
  v_repeat := (public.enregistrer_regles_tirage(
    v_payload, 'c2911000-0000-0000-0000-000000000001'
  )->>'version')::integer;
  IF v_first IS NULL OR v_first <> v_repeat THEN
    RAISE EXCEPTION 'C29: enregistrement des règles non idempotent';
  END IF;
  BEGIN
    PERFORM public.enregistrer_regles_tirage(
      v_payload || '{"missions_par_semaine":6}'::jsonb,
      'c2911000-0000-0000-0000-000000000001'
    );
  EXCEPTION WHEN SQLSTATE '22023' THEN
    v_rejected := true;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'C29: réutilisation de clé avec payload différent acceptée';
  END IF;
  IF (public.lire_regles_tirage()->>'missions_par_semaine')::integer <> 5 THEN
    RAISE EXCEPTION 'C29: la version courante des règles est incorrecte';
  END IF;
  IF public.candidats_cible_tirage()->'cibles' <>
      '[{"id":"c2910000-0000-0000-0000-000000000002","type":"enseignant","libelle":"Teacher Engine"}]'::jsonb THEN
    RAISE EXCEPTION 'C29: la cible enseignant active n''est pas exacte';
  END IF;
  BEGIN
    PERFORM public.enregistrer_regles_tirage(
      '{"missions_par_semaine":5.5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[]}'::jsonb,
      'c2911000-0000-0000-0000-000000000003'
    );
  EXCEPTION WHEN SQLSTATE '22023' THEN
    v_invalid := true;
  END;
  IF NOT v_invalid THEN
    RAISE EXCEPTION 'C29: une quota hebdomadaire décimale a été acceptée';
  END IF;
END;
$test$;

SELECT set_config('request.jwt.claims', '{"aal":"aal1","app_metadata":{"role":"admin"}}', true);
DO $test$
BEGIN
  BEGIN
    PERFORM public.enregistrer_regles_tirage(
      '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[]}'::jsonb,
      'c2911000-0000-0000-0000-000000000002'
    );
    RAISE EXCEPTION 'C29: une session aal1 a modifié les règles';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$test$;

RESET ROLE;
UPDATE public.profiles SET account_status='disabled'
 WHERE id='c2910000-0000-0000-0000-000000000001';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c2910000-0000-0000-0000-000000000001',true);
SELECT set_config('test.uid','c2910000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
DO $disabled_admin$
DECLARE v_capacites jsonb;
BEGIN
  v_capacites := public.capacites_tirage_controle();
  IF v_capacites->>'peut_lire' <> 'false' OR v_capacites->>'peut_modifier' <> 'false' THEN
    RAISE EXCEPTION 'C29: un admin désactivé conserve les capacités de tirage';
  END IF;
  IF public.lire_regles_tirage()->>'erreur' <> 'autorisation_direction_requise' THEN
    RAISE EXCEPTION 'C29: un admin désactivé lit les règles';
  END IF;
  BEGIN
    PERFORM public.candidats_cible_tirage();
    RAISE EXCEPTION 'C29: un admin désactivé lit les cibles';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.enregistrer_regles_tirage(
      '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[]}'::jsonb,
      'c2911000-0000-0000-0000-000000000004'
    );
    RAISE EXCEPTION 'C29: un admin désactivé modifie les règles';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$disabled_admin$;
RESET ROLE;

SET LOCAL ROLE anon;
DO $anonymous$
BEGIN
  BEGIN PERFORM public.capacites_tirage_controle();
    RAISE EXCEPTION 'C29: anon consulte les capacités de tirage';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.lire_regles_tirage();
    RAISE EXCEPTION 'C29: anon lit les règles';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.candidats_cible_tirage();
    RAISE EXCEPTION 'C29: anon lit les cibles';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.enregistrer_regles_tirage(
      '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[]}'::jsonb,
      'c2911000-0000-0000-0000-000000000005'
    );
    RAISE EXCEPTION 'C29: anon modifie les règles';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$anonymous$;
RESET ROLE;

DO $postflight$
DECLARE v_append_only boolean := false;
BEGIN
  IF has_function_privilege('anon', 'public.capacites_tirage_controle()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.lire_regles_tirage()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.candidats_cible_tirage()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.enregistrer_regles_tirage(jsonb,uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.capacites_tirage_controle()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.lire_regles_tirage()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.candidats_cible_tirage()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.enregistrer_regles_tirage(jsonb,uuid)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.capacites_tirage_controle()', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.lire_regles_tirage()', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.candidats_cible_tirage()', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.enregistrer_regles_tirage(jsonb,uuid)', 'EXECUTE')
     OR has_table_privilege('anon', 'public.controle_regles', 'SELECT') THEN
    RAISE EXCEPTION 'C29: ACL des règles expose une surface interdite';
  END IF;
  IF (SELECT count(*) FROM public.audit_logs WHERE action = 'tirage_regles_modifiees'
      AND row_id = (SELECT max(version)::text FROM public.controle_regles)) <> 1 THEN
    RAISE EXCEPTION 'C29: mise à jour des règles non auditée exactement une fois';
  END IF;
  BEGIN
    UPDATE public.controle_regles SET missions_par_semaine = 6 WHERE version =
      (SELECT max(version) FROM public.controle_regles);
  EXCEPTION WHEN SQLSTATE '55000' THEN
    v_append_only := true;
  END;
  IF NOT v_append_only THEN
    RAISE EXCEPTION 'C29: une version de règles a pu être modifiée';
  END IF;
  v_append_only := false;
  BEGIN
    DELETE FROM public.controle_regles
    WHERE version = (SELECT max(version) FROM public.controle_regles);
  EXCEPTION WHEN SQLSTATE '55000' THEN
    v_append_only := true;
  END;
  IF NOT v_append_only THEN RAISE EXCEPTION 'C29: rule version deletion was allowed'; END IF;

  v_append_only := false;
  BEGIN
    UPDATE public.controle_regles_cibles SET libelle = 'changed'
    WHERE version = (SELECT max(version) FROM public.controle_regles)
      AND type = 'enseignant';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    v_append_only := true;
  END;
  IF NOT v_append_only THEN RAISE EXCEPTION 'C29: target update was allowed'; END IF;

  v_append_only := false;
  BEGIN
    DELETE FROM public.controle_regles_cibles
    WHERE version = (SELECT max(version) FROM public.controle_regles)
      AND type = 'enseignant';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    v_append_only := true;
  END;
  IF NOT v_append_only THEN RAISE EXCEPTION 'C29: target deletion was allowed'; END IF;
END;
$postflight$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'c2910000-0000-0000-0000-000000000002', true);
SELECT set_config('test.uid', 'c2910000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.jwt', '{"aal":"aal2","app_metadata":{"role":"teacher"}}', true);
DO $test$
DECLARE v_capacites jsonb;
BEGIN
  v_capacites := public.capacites_tirage_controle();
  IF v_capacites->>'peut_lire' <> 'false' OR v_capacites->>'peut_modifier' <> 'false' THEN
    RAISE EXCEPTION 'C29: un enseignant conserve les capacités de direction';
  END IF;
  IF public.lire_regles_tirage()->>'erreur' <> 'autorisation_direction_requise' THEN
    RAISE EXCEPTION 'C29: un enseignant lit les règles';
  END IF;
  BEGIN
    PERFORM public.candidats_cible_tirage();
    RAISE EXCEPTION 'C29: un enseignant lit les cibles de tirage';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.enregistrer_regles_tirage(
      '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[]}'::jsonb,
      'c2911000-0000-0000-0000-000000000006'
    );
    RAISE EXCEPTION 'C29: un enseignant modifie les règles';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF (SELECT count(*) FROM public.controle_regles) <> 0 THEN
    RAISE EXCEPTION 'C29: un enseignant peut lire les règles de la direction';
  END IF;
END;
$test$;
RESET ROLE;

ROLLBACK;
