-- PE (21/10/2026, CAND-Q15 lot conduite) : le code de conduite se signe avant
-- l'activation, et la garde d'activation l'exige
-- (20261021210400_pe_code_conduite_avant_activation.sql).
--
--   (a) un enseignant pending_kyc accepte la version requise sur son profil ;
--       l'ancienne version et l'acceptation au nom d'un autre sont refusees ;
--   (b) la validation de sa piece est refusee sans le code : le compte reste
--       pending_kyc et la piece reste en attente (retour arriere) ; la meme
--       garde refuse la voie d'une mise a jour directe ;
--   (c) apres acceptation, la meme validation active le compte ;
--   (d) une acceptation de la seule ancienne version ne suffit pas ;
--   (e) l'insertion est refusee pour un enseignant desactive ou supprime, pour
--       une famille, et pour une famille qui se presente comme enseignant ;
--   (f) etat_dossier() rend code_conduite_signe faux puis vrai pour
--       l'enseignant, faux pour l'ancienne version, vrai pour un tuteur ;
--       teacher_signature_statuses() dit l'etat du code a la direction ;
--   (g) un enseignant deja actif n'est pas bloque dans ses mises a jour, et
--       peut toujours accepter le code depuis son profil ;
--   (h) structure : garde INVOKER qui lit le code, policy RESTRICTIVE sans
--       app_account_valid(), inventaire des policies a neuf, droits du dossier.
--
-- Base PostgreSQL neuve apres rejeu des migrations. Tout se defait a la fin
-- (ROLLBACK) : le scenario se rejoue sur la meme base.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c0de0000-0000-0000-0000-000000000001', 'cond-admin@example.test'),
  ('c0de0000-0000-0000-0000-000000000002', 'cond-t1@example.test'),
  ('c0de0000-0000-0000-0000-000000000003', 'cond-t2@example.test'),
  ('c0de0000-0000-0000-0000-000000000004', 'cond-t3@example.test'),
  ('c0de0000-0000-0000-0000-000000000005', 'cond-t4@example.test'),
  ('c0de0000-0000-0000-0000-000000000006', 'cond-famille@example.test'),
  ('c0de0000-0000-0000-0000-000000000007', 'cond-t5@example.test'),
  ('c0de0000-0000-0000-0000-000000000008', 'cond-t6@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('c0de0000-0000-0000-0000-000000000101', 'Europe/Paris');

-- T1 : enseignant invite, en attente (sujet principal).
-- T2 : en attente, n'a accepte que l'ancienne version du code.
-- T3 : enseignant desactive. T4 : enseignant supprime.
-- T5 : enseignant deja actif avant ce lot, sans le code.
-- T6 : provisoire, passe a actif par une mise a jour directe.
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender,
   account_status, deleted_at)
VALUES
  ('c0de0000-0000-0000-0000-000000000001', 'COND-ADMIN-M', 'admin',
   'c0de0000-0000-0000-0000-000000000101', 'Admin', 'Conduite', 'male', 'active', NULL),
  ('c0de0000-0000-0000-0000-000000000002', 'COND-T1-M', 'teacher',
   NULL, 'Teacher', 'Un', 'male', 'pending_kyc', NULL),
  ('c0de0000-0000-0000-0000-000000000003', 'COND-T2-M', 'teacher',
   NULL, 'Teacher', 'Deux', 'male', 'pending_kyc', NULL),
  ('c0de0000-0000-0000-0000-000000000004', 'COND-T3-M', 'teacher',
   NULL, 'Teacher', 'Trois', 'male', 'disabled', NULL),
  ('c0de0000-0000-0000-0000-000000000005', 'COND-T4-M', 'teacher',
   NULL, 'Teacher', 'Quatre', 'male', 'pending_kyc', pg_catalog.now()),
  ('c0de0000-0000-0000-0000-000000000006', 'COND-FAM-F', 'guardian',
   'c0de0000-0000-0000-0000-000000000101', 'Famille', 'Conduite', 'female', 'active', NULL),
  ('c0de0000-0000-0000-0000-000000000008', 'COND-T6-M', 'teacher',
   NULL, 'Teacher', 'Six', 'male', 'provisional_active', NULL);

UPDATE public.households
   SET primary_guardian_id = 'c0de0000-0000-0000-0000-000000000006'
 WHERE id = 'c0de0000-0000-0000-0000-000000000101';

INSERT INTO public.teacher_profiles (profile_id)
VALUES
  ('c0de0000-0000-0000-0000-000000000002'),
  ('c0de0000-0000-0000-0000-000000000003'),
  ('c0de0000-0000-0000-0000-000000000008');

-- T5 : un compte enseignant deja actif avant ce lot (aucune acceptation ne
-- se fabrique, ADR-011). Le declencheur est suspendu le temps de poser la
-- fixture, puis remis.
ALTER TABLE public.profiles DISABLE TRIGGER profiles_guard_teacher_activation_signatures;
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, gender, account_status)
VALUES
  ('c0de0000-0000-0000-0000-000000000007', 'COND-T5-M', 'teacher',
   'Teacher', 'Cinq', 'male', 'active');
ALTER TABLE public.profiles ENABLE TRIGGER profiles_guard_teacher_activation_signatures;

-- T1, T2 et T6 ont signe le contrat et l'accuse (fixture du proprietaire du
-- scenario, comme scenarios_af_l1_05_decider_dossier_une_fois.sql) ; T2 a en
-- plus accepte l'ancienne version du code, posee sans passer par la policy.
DO $fixture_signatures$
DECLARE
  v_teacher uuid;
  v_teacher_version text;
  v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version FROM public.contract_texts
   WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current;
  SELECT version INTO v_notice_version FROM public.contract_required_versions
   WHERE contract_kind = 'recording_and_control_notice';
  FOREACH v_teacher IN ARRAY ARRAY[
    'c0de0000-0000-0000-0000-000000000002'::uuid,
    'c0de0000-0000-0000-0000-000000000003'::uuid,
    'c0de0000-0000-0000-0000-000000000008'::uuid] LOOP
    PERFORM set_config('test.uid', v_teacher::text, true);
    PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    PERFORM public.signer_contrat(v_teacher_version, 'Fixture conduite');
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES (v_teacher, 'recording_and_control_notice', v_notice_version);
  END LOOP;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('c0de0000-0000-0000-0000-000000000003', 'teacher_conduct_code', '2026-10-cond');
  PERFORM set_config('test.uid', '', true);
  PERFORM set_config('test.jwt', '', true);
END
$fixture_signatures$;

INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key, status)
VALUES
  ('c0de0000-0000-0000-0000-000000000201', 'c0de0000-0000-0000-0000-000000000002',
   'id_card', 'male', 'cond/t1-id', 'pending'),
  ('c0de0000-0000-0000-0000-000000000202', 'c0de0000-0000-0000-0000-000000000003',
   'id_card', 'male', 'cond/t2-id', 'pending');

SET LOCAL ROLE authenticated;

-- ===========================================================================
-- (f) Avant : etat_dossier() rend faux pour T1 et pour T2 (ancienne version),
--     vrai pour un tuteur.
-- ===========================================================================
DO $cond_f_avant$
DECLARE
  v_etat jsonb;
BEGIN
  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  v_etat := public.etat_dossier();
  IF NOT (v_etat ? 'code_conduite_signe')
     OR (v_etat ->> 'code_conduite_signe') <> 'false'
     OR (v_etat ->> 'contrat_signe') <> 'true'
     OR (v_etat ->> 'accuse_signe') <> 'true' THEN
    RAISE EXCEPTION 'COND f ECHEC : T1 avant acceptation : %', v_etat;
  END IF;

  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000003', true);
  v_etat := public.etat_dossier();
  IF (v_etat ->> 'code_conduite_signe') <> 'false' THEN
    RAISE EXCEPTION 'COND f ECHEC : l ancienne version compte pour signee : %', v_etat;
  END IF;

  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000006', true);
  PERFORM set_config('test.jwt',
    '{"app_metadata":{"role":"guardian","household_id":"c0de0000-0000-0000-0000-000000000101"}}', true);
  v_etat := public.etat_dossier();
  IF (v_etat ->> 'code_conduite_signe') <> 'true' THEN
    RAISE EXCEPTION 'COND f ECHEC : un tuteur se voit demander le code : %', v_etat;
  END IF;
  RAISE NOTICE 'COND ok (f) avant : faux pour T1 et pour l ancienne version, vrai pour un tuteur';
END
$cond_f_avant$;

-- ===========================================================================
-- (b) et (d) Validation de la piece refusee sans le code ; retour arriere.
-- ===========================================================================
DO $cond_b_d$
DECLARE
  v_statut public.account_status;
  v_piece public.kyc_doc_status;
  v_doc uuid;
  v_profil uuid;
BEGIN
  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  FOR v_doc, v_profil IN
    SELECT * FROM (VALUES
      ('c0de0000-0000-0000-0000-000000000201'::uuid, 'c0de0000-0000-0000-0000-000000000002'::uuid),
      ('c0de0000-0000-0000-0000-000000000202'::uuid, 'c0de0000-0000-0000-0000-000000000003'::uuid)) d
  LOOP
    BEGIN
      PERFORM public.decider_dossier(v_doc, true, NULL);
      RAISE EXCEPTION 'COND b/d ECHEC : piece % validee sans le code de conduite', v_doc;
    EXCEPTION WHEN check_violation THEN
      IF pg_catalog.strpos(SQLERRM, 'contract_not_signed_current:teacher_conduct_code') = 0 THEN
        RAISE;
      END IF;
    END;
  END LOOP;
  RESET ROLE;
  SELECT account_status INTO v_statut FROM public.profiles
   WHERE id = 'c0de0000-0000-0000-0000-000000000002';
  SELECT status INTO v_piece FROM public.kyc_documents
   WHERE id = 'c0de0000-0000-0000-0000-000000000201';
  IF v_statut <> 'pending_kyc' OR v_piece <> 'pending' THEN
    RAISE EXCEPTION 'COND b ECHEC : pas de retour arriere (compte %, piece %)', v_statut, v_piece;
  END IF;
  SELECT account_status INTO v_statut FROM public.profiles
   WHERE id = 'c0de0000-0000-0000-0000-000000000003';
  IF v_statut <> 'pending_kyc' THEN
    RAISE EXCEPTION 'COND d ECHEC : l ancienne version a active T2 (%)', v_statut;
  END IF;
  IF EXISTS (SELECT 1 FROM public.audit_logs
              WHERE action = 'kyc_decision'
                AND row_id IN ('c0de0000-0000-0000-0000-000000000201',
                               'c0de0000-0000-0000-0000-000000000202')) THEN
    RAISE EXCEPTION 'COND b ECHEC : une decision refusee reste au journal';
  END IF;
  RAISE NOTICE 'COND ok (b)(d) : validation refusee sans le code (ni avec l ancienne version), compte et piece inchanges';
END
$cond_b_d$;

-- (b) Quelle que soit la voie : une mise a jour directe vers active est
-- refusee de la meme facon.
DO $cond_b_voie$
BEGIN
  UPDATE public.profiles SET account_status = 'active'
   WHERE id = 'c0de0000-0000-0000-0000-000000000008';
  RAISE EXCEPTION 'COND b ECHEC : T6 active sans le code par mise a jour directe';
EXCEPTION WHEN check_violation THEN
  IF pg_catalog.strpos(SQLERRM, 'contract_not_signed_current:teacher_conduct_code') = 0 THEN
    RAISE;
  END IF;
  RAISE NOTICE 'COND ok (b) : la mise a jour directe vers active est refusee aussi';
END
$cond_b_voie$;

SET LOCAL ROLE authenticated;

-- ===========================================================================
-- (a) T1 en attente accepte la version requise, et rien d'autre.
-- ===========================================================================
DO $cond_a$
DECLARE
  v_version text := public.code_conduite_version_requise();
  v_n integer;
BEGIN
  IF v_version IS DISTINCT FROM '2026-10-19' THEN
    RAISE EXCEPTION 'COND a ECHEC : version requise inattendue (%)', v_version;
  END IF;
  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

  BEGIN
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES ('c0de0000-0000-0000-0000-000000000002', 'teacher_conduct_code', '2026-10-cond');
    RAISE EXCEPTION 'COND a ECHEC : ancienne version acceptee';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;

  BEGIN
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES ('c0de0000-0000-0000-0000-000000000003', 'teacher_conduct_code', v_version);
    RAISE EXCEPTION 'COND a ECHEC : acceptation au nom d un autre enseignant';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;

  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('c0de0000-0000-0000-0000-000000000002', 'teacher_conduct_code', v_version);

  BEGIN
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES ('c0de0000-0000-0000-0000-000000000002', 'teacher_conduct_code', v_version);
    RAISE EXCEPTION 'COND a ECHEC : double acceptation';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  SELECT count(*) INTO v_n FROM public.contract_acceptances
   WHERE profile_id = 'c0de0000-0000-0000-0000-000000000002'
     AND contract_kind = 'teacher_conduct_code';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'COND a ECHEC : % acceptations du code pour T1 (1 attendue)', v_n;
  END IF;
  RAISE NOTICE 'COND ok (a) : pending_kyc accepte la version requise ; ancienne version et autre profil refuses';
END
$cond_a$;

-- ===========================================================================
-- (f) Apres : etat_dossier() rend vrai pour T1 ; la direction lit l'etat du
--     code dans teacher_signature_statuses().
-- ===========================================================================
DO $cond_f_apres$
DECLARE
  v_etat jsonb;
  v_statuts jsonb;
BEGIN
  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  v_etat := public.etat_dossier();
  IF (v_etat ->> 'code_conduite_signe') <> 'true' THEN
    RAISE EXCEPTION 'COND f ECHEC : T1 apres acceptation : %', v_etat;
  END IF;

  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  v_statuts := public.teacher_signature_statuses('c0de0000-0000-0000-0000-000000000002');
  IF v_statuts #>> '{code_conduite,status}' IS DISTINCT FROM 'signe_version_courante'
     OR v_statuts #>> '{code_conduite,version_courante}' IS DISTINCT FROM '2026-10-19'
     OR v_statuts #>> '{contrat,status}' IS DISTINCT FROM 'signe_version_courante'
     OR v_statuts #>> '{accuse,status}' IS DISTINCT FROM 'signe_version_courante' THEN
    RAISE EXCEPTION 'COND f ECHEC : statuts de T1 : %', v_statuts;
  END IF;
  v_statuts := public.teacher_signature_statuses('c0de0000-0000-0000-0000-000000000003');
  IF v_statuts #>> '{code_conduite,status}' IS DISTINCT FROM 'signe_ancienne_version'
     OR v_statuts #>> '{code_conduite,version_signee}' IS DISTINCT FROM '2026-10-cond' THEN
    RAISE EXCEPTION 'COND f ECHEC : statuts de T2 : %', v_statuts;
  END IF;
  v_statuts := public.teacher_signature_statuses('c0de0000-0000-0000-0000-000000000008');
  IF v_statuts #>> '{code_conduite,status}' IS DISTINCT FROM 'non_signe' THEN
    RAISE EXCEPTION 'COND f ECHEC : statuts de T6 : %', v_statuts;
  END IF;
  RAISE NOTICE 'COND ok (f) apres : vrai pour T1 ; la direction lit signe, ancienne version, non signe';
END
$cond_f_apres$;

-- ===========================================================================
-- (c) Apres acceptation, la meme validation active T1.
-- ===========================================================================
DO $cond_c$
BEGIN
  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  PERFORM public.decider_dossier('c0de0000-0000-0000-0000-000000000201', true, NULL);
END
$cond_c$;

RESET ROLE;
DO $cond_c_controle$
DECLARE
  v_statut public.account_status;
  v_piece public.kyc_doc_status;
BEGIN
  SELECT account_status INTO v_statut FROM public.profiles
   WHERE id = 'c0de0000-0000-0000-0000-000000000002';
  SELECT status INTO v_piece FROM public.kyc_documents
   WHERE id = 'c0de0000-0000-0000-0000-000000000201';
  IF v_statut <> 'active' OR v_piece <> 'approved' THEN
    RAISE EXCEPTION 'COND c ECHEC : T1 non active apres acceptation (compte %, piece %)', v_statut, v_piece;
  END IF;
  RAISE NOTICE 'COND ok (c) : apres acceptation du code, la validation active le compte';
END
$cond_c_controle$;

SET LOCAL ROLE authenticated;

-- ===========================================================================
-- (e) Refus : enseignant desactive, enseignant supprime, famille, famille qui
--     se presente comme enseignant.
-- ===========================================================================
DO $cond_e$
DECLARE
  v_version text := public.code_conduite_version_requise();
  v_cas record;
BEGIN
  FOR v_cas IN
    SELECT * FROM (VALUES
      ('c0de0000-0000-0000-0000-000000000004'::uuid,
       '{"app_metadata":{"role":"teacher"}}', 'enseignant desactive'),
      ('c0de0000-0000-0000-0000-000000000005'::uuid,
       '{"app_metadata":{"role":"teacher"}}', 'enseignant supprime'),
      ('c0de0000-0000-0000-0000-000000000006'::uuid,
       '{"app_metadata":{"role":"guardian","household_id":"c0de0000-0000-0000-0000-000000000101"}}',
       'famille'),
      ('c0de0000-0000-0000-0000-000000000006'::uuid,
       '{"app_metadata":{"role":"teacher","household_id":"c0de0000-0000-0000-0000-000000000101"}}',
       'famille au jeton enseignant')) c(uid, jwt, quoi)
  LOOP
    PERFORM set_config('test.uid', v_cas.uid::text, true);
    PERFORM set_config('test.jwt', v_cas.jwt, true);
    BEGIN
      INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
      VALUES (v_cas.uid, 'teacher_conduct_code', v_version);
      RAISE EXCEPTION 'COND e ECHEC : % a accepte le code de conduite', v_cas.quoi;
    EXCEPTION WHEN insufficient_privilege THEN
      NULL;
    END;
  END LOOP;
  RAISE NOTICE 'COND ok (e) : desactive, supprime, famille et faux enseignant refuses (42501)';
END
$cond_e$;

-- ===========================================================================
-- (g) Un enseignant deja actif n'est pas bloque ; il accepte depuis son profil.
-- ===========================================================================
RESET ROLE;
DO $cond_g$
DECLARE
  v_n integer;
BEGIN
  UPDATE public.profiles SET first_name = 'Ancien'
   WHERE id = 'c0de0000-0000-0000-0000-000000000007';
  UPDATE public.profiles SET account_status = 'active', updated_at = pg_catalog.now()
   WHERE id = 'c0de0000-0000-0000-0000-000000000007';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'COND g ECHEC : mise a jour de T5 perdue';
  END IF;
END
$cond_g$;

SET LOCAL ROLE authenticated;
DO $cond_g_profil$
DECLARE
  v_etat jsonb;
BEGIN
  PERFORM set_config('test.uid', 'c0de0000-0000-0000-0000-000000000007', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  v_etat := public.etat_dossier();
  IF (v_etat ->> 'code_conduite_signe') <> 'false' THEN
    RAISE EXCEPTION 'COND g ECHEC : T5 actif sans le code lu comme signe : %', v_etat;
  END IF;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('c0de0000-0000-0000-0000-000000000007', 'teacher_conduct_code',
          public.code_conduite_version_requise());
  v_etat := public.etat_dossier();
  IF (v_etat ->> 'code_conduite_signe') <> 'true' THEN
    RAISE EXCEPTION 'COND g ECHEC : T5 apres acceptation : %', v_etat;
  END IF;
  RAISE NOTICE 'COND ok (g) : un enseignant deja actif garde ses mises a jour et accepte depuis son profil';
END
$cond_g_profil$;

RESET ROLE;

-- ===========================================================================
-- (h) Structure.
-- ===========================================================================
DO $cond_h$
DECLARE
  v_policy record;
  v_liste text;
  v_nb integer;
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.guard_teacher_activation_signatures()'::regprocedure
          AND NOT p.prosecdef
          AND pg_catalog.strpos(p.prosrc, 'teacher_conduct_code') > 0) THEN
    RAISE EXCEPTION 'COND h ECHEC : la garde est DEFINER ou ne lit pas le code';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'public.guard_teacher_activation_signatures()', 'EXECUTE') THEN
    RAISE EXCEPTION 'COND h ECHEC : la garde est appelable';
  END IF;

  SELECT permissive, cmd, with_check INTO v_policy FROM pg_catalog.pg_policies
   WHERE schemaname = 'public' AND tablename = 'contract_acceptances'
     AND policyname = 'contract_acceptances_code_conduite_enseignant';
  IF v_policy.permissive IS DISTINCT FROM 'RESTRICTIVE'
     OR v_policy.cmd IS DISTINCT FROM 'INSERT'
     OR pg_catalog.strpos(v_policy.with_check, '(profile_id = auth.uid())') = 0
     OR pg_catalog.strpos(v_policy.with_check, 'app_account_valid') > 0 THEN
    RAISE EXCEPTION 'COND h ECHEC : policy du code : %', v_policy;
  END IF;

  SELECT count(*), string_agg(tablename || '.' || policyname, ', ' ORDER BY tablename || '.' || policyname)
    INTO v_nb, v_liste
    FROM pg_catalog.pg_policies
   WHERE schemaname = 'public'
     AND (coalesce(qual, '') || coalesce(with_check, '')) LIKE '%app_role()%'
     AND (coalesce(qual, '') || coalesce(with_check, '')) NOT LIKE '%app_account_valid%';
  IF v_nb <> 9
     OR pg_catalog.strpos(v_liste, 'contract_acceptances.contract_acceptances_code_conduite_enseignant') = 0 THEN
    RAISE EXCEPTION 'COND h ECHEC : % policies sans app_account_valid (9 attendues) : %', v_nb, v_liste;
  END IF;

  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.etat_dossier()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.etat_dossier()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.etat_dossier()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.etat_dossier()', 'EXECUTE') THEN
    RAISE EXCEPTION 'COND h ECHEC : droits de etat_dossier';
  END IF;
  RAISE NOTICE 'COND ok (h) : garde INVOKER, policy RESTRICTIVE sans app_account_valid, 9 policies, droits du dossier';
END
$cond_h$;

ROLLBACK;
SELECT 'PE code de conduite avant activation PASS' AS resultat;
