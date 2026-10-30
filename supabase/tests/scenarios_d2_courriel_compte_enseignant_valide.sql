-- D2 (30/10/2026) : l'enseignant recoit un e-mail quand la direction valide
-- son compte. Migration 20261031200100_d2_courriel_compte_enseignant_valide.sql.
--
--   (a) decider_dossier approuve la piece d'un enseignant pending_kyc : le
--       compte passe active et UNE ligne `compte_enseignant_valide` entre dans
--       la file (categorie recrutement, son adresse, son prenom) ;
--   (b) un second passage pending_kyc -> active n'ajoute rien (idempotence) ;
--   (c) un refus de piece n'envoie rien ;
--   (d) une validation refusee par la garde d'activation (code de conduite
--       absent) n'envoie rien : tout revient en arriere ;
--   (e) un compte qui n'est pas enseignant n'envoie rien ;
--   (f) la fonction du declencheur n'est executable par personne.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations).
-- Chaque controle leve 'D2 ROUGE : ...' s'il echoue. Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'D2 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.courriels(p_profil uuid) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.courriels_sortants
   WHERE modele = 'compte_enseignant_valide' AND destinataire_profil = p_profil;
$$;

CREATE FUNCTION pg_temp.admin() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '0d2e0000-0000-4000-8000-000000000001', true);
  PERFORM set_config('test.uid', '0d2e0000-0000-4000-8000-000000000001', true);
  PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
END $$;

-- ...01 direction ; ...02 enseignant (sujet) ; ...03 enseignant refuse ;
-- ...04 enseignant sans code de conduite ; ...05 tuteur.
INSERT INTO auth.users (id, email) VALUES
  ('0d2e0000-0000-4000-8000-000000000001', 'd2-direction@example.test'),
  ('0d2e0000-0000-4000-8000-000000000002', 'D2-Enseignant@Example.test'),
  ('0d2e0000-0000-4000-8000-000000000003', 'd2-refuse@example.test'),
  ('0d2e0000-0000-4000-8000-000000000004', 'd2-sans-code@example.test'),
  ('0d2e0000-0000-4000-8000-000000000005', 'd2-tuteur@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('0d2effff-0000-4000-8000-000000000005', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
VALUES
  ('0d2e0000-0000-4000-8000-000000000001', 'D2-ADMIN', 'admin', NULL, 'Fixture', 'Direction', 'male', 'active'),
  ('0d2e0000-0000-4000-8000-000000000002', 'D2-T1', 'teacher', NULL, 'Hakim', 'Fixture', 'male', 'pending_kyc'),
  ('0d2e0000-0000-4000-8000-000000000003', 'D2-T2', 'teacher', NULL, 'Fixture', 'Refuse', 'male', 'pending_kyc'),
  ('0d2e0000-0000-4000-8000-000000000004', 'D2-T3', 'teacher', NULL, 'Fixture', 'SansCode', 'male', 'pending_kyc'),
  ('0d2e0000-0000-4000-8000-000000000005', 'D2-G1', 'guardian', '0d2effff-0000-4000-8000-000000000005',
   'Fixture', 'Tuteur', 'female', 'pending_kyc');

INSERT INTO public.teacher_profiles (profile_id) VALUES
  ('0d2e0000-0000-4000-8000-000000000002'),
  ('0d2e0000-0000-4000-8000-000000000003'),
  ('0d2e0000-0000-4000-8000-000000000004');

-- Signatures : T1 et T2 ont tout signe ; T3 n'a pas le code de conduite.
DO $signatures$
DECLARE
  v_teacher uuid;
  v_nda text;
  v_avis text;
BEGIN
  SELECT version INTO v_nda FROM public.contract_texts
   WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current;
  SELECT version INTO v_avis FROM public.contract_required_versions
   WHERE contract_kind = 'recording_and_control_notice';
  FOREACH v_teacher IN ARRAY ARRAY[
    '0d2e0000-0000-4000-8000-000000000002'::uuid,
    '0d2e0000-0000-4000-8000-000000000003'::uuid,
    '0d2e0000-0000-4000-8000-000000000004'::uuid] LOOP
    PERFORM set_config('test.uid', v_teacher::text, true);
    PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    PERFORM public.signer_contrat(v_nda, 'Fixture D2');
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    VALUES (v_teacher, 'recording_and_control_notice', v_avis);
  END LOOP;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version) VALUES
    ('0d2e0000-0000-4000-8000-000000000002', 'teacher_conduct_code', public.code_conduite_version_requise()),
    ('0d2e0000-0000-4000-8000-000000000003', 'teacher_conduct_code', public.code_conduite_version_requise());
  PERFORM set_config('test.uid', '', true);
  PERFORM set_config('test.jwt', '', true);
END
$signatures$;

INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key, status) VALUES
  ('0d2e0000-0000-4000-8000-000000000201', '0d2e0000-0000-4000-8000-000000000002', 'id_card', 'male', 'd2/t1', 'pending'),
  ('0d2e0000-0000-4000-8000-000000000202', '0d2e0000-0000-4000-8000-000000000003', 'id_card', 'male', 'd2/t2', 'pending'),
  ('0d2e0000-0000-4000-8000-000000000203', '0d2e0000-0000-4000-8000-000000000004', 'id_card', 'male', 'd2/t3', 'pending');

-- (a) la validation
SET LOCAL ROLE authenticated;
SELECT pg_temp.admin();
SELECT public.decider_dossier('0d2e0000-0000-4000-8000-000000000201', true, NULL);
RESET ROLE;
SELECT pg_temp.vrai((SELECT account_status FROM public.profiles
                      WHERE id = '0d2e0000-0000-4000-8000-000000000002') = 'active',
  '(a) decider_dossier active le compte de l''enseignant');
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000002') = 1,
  '(a) une ligne compte_enseignant_valide entre dans la file');
SELECT pg_temp.vrai((SELECT c.categorie = 'recrutement'
                        AND c.destinataire_adresse = 'd2-enseignant@example.test'
                        AND c.donnees ->> 'prenom' = 'Hakim'
                        AND c.cle_idempotence = 'compte_enseignant_valide:0d2e0000-0000-4000-8000-000000000002'
                        AND c.cree_par = '0d2e0000-0000-4000-8000-000000000001'
                       FROM public.courriels_sortants c
                      WHERE c.modele = 'compte_enseignant_valide'
                        AND c.destinataire_profil = '0d2e0000-0000-4000-8000-000000000002'),
  '(a) categorie recrutement, son adresse, son prenom, cle unique, auteur la direction');

-- (b) un second passage
UPDATE public.profiles SET account_status = 'pending_kyc' WHERE id = '0d2e0000-0000-4000-8000-000000000002';
UPDATE public.profiles SET account_status = 'active' WHERE id = '0d2e0000-0000-4000-8000-000000000002';
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000002') = 1,
  '(b) un second passage a active n''ajoute aucun e-mail');

-- (c) le refus
SET LOCAL ROLE authenticated;
SELECT pg_temp.admin();
SELECT public.decider_dossier('0d2e0000-0000-4000-8000-000000000202', false, 'Piece illisible');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000003') = 0,
  '(c) un refus n''envoie rien');

-- (d) la garde d'activation refuse : rien ne part
SET LOCAL ROLE authenticated;
SELECT pg_temp.admin();
DO $$
BEGIN
  PERFORM public.decider_dossier('0d2e0000-0000-4000-8000-000000000203', true, NULL);
  RAISE EXCEPTION 'D2 ROUGE : (d) la validation sans code de conduite est passee';
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM LIKE 'D2 ROUGE%' THEN RAISE; END IF;
END $$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000004') = 0
    AND (SELECT account_status FROM public.profiles
          WHERE id = '0d2e0000-0000-4000-8000-000000000004') = 'pending_kyc',
  '(d) validation refusee par la garde : compte en attente, aucun e-mail');

-- (e) un tuteur
UPDATE public.profiles SET account_status = 'active' WHERE id = '0d2e0000-0000-4000-8000-000000000005';
SELECT pg_temp.vrai((SELECT count(*) FROM public.courriels_sortants
                      WHERE modele = 'compte_enseignant_valide'
                        AND destinataire_profil = '0d2e0000-0000-4000-8000-000000000005') = 0,
  '(e) un compte qui n''est pas enseignant n''envoie rien');

-- (f) les droits
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.courriel_compte_enseignant_valide()', 'execute')
    AND NOT has_function_privilege('anon', 'private.courriel_compte_enseignant_valide()', 'execute'),
  '(f) la fonction du declencheur n''est executable ni par anon ni par authenticated');

\o
SELECT 'D2 VERT' AS resultat;
ROLLBACK;
