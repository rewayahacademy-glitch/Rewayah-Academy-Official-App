-- SALLE-3-ACCUEIL (07/11/2026) : l'enseignant dont le compte est active
-- recoit une notification « Bienvenue dans l'equipe » dans l'application.
-- Migrations 20261119000000_bienvenue_equipe_evenement.sql et
-- 20261119000100_bienvenue_equipe_notification.sql.
--
--   (a) decider_dossier approuve la piece d'un enseignant pending_kyc : le
--       compte passe active et UNE notification `bienvenue_equipe` est posee
--       pour lui (destination /enseignant/journee, aucun parametre) ;
--   (b) un second passage pending_kyc -> active n'en ajoute pas ;
--   (c) un refus de piece n'en pose pas ;
--   (d) une validation refusee par la garde d'activation n'en pose pas ;
--   (e) un compte qui n'est pas enseignant n'en recoit pas ;
--   (f) la fonction du declencheur n'est executable par personne ;
--   (g) l'evenement est dans la contrainte ET aucun des evenements d'avant n'en
--       est sorti.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations).
-- Chaque controle leve 'BIENVENUE ROUGE : ...' s'il echoue. Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'BIENVENUE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.courriels(p_profil uuid) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.notifications
   WHERE evenement = 'bienvenue_equipe' AND destinataire = p_profil;
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
  '(a) une notification bienvenue_equipe est posee');
SELECT pg_temp.vrai((SELECT n.destination = '/enseignant/journee' AND n.params = '{}'::jsonb
                        AND n.foyer_id IS NULL AND n.lu_le IS NULL
                       FROM public.notifications n
                      WHERE n.evenement = 'bienvenue_equipe'
                        AND n.destinataire = '0d2e0000-0000-4000-8000-000000000002'),
  '(a) destination la Journee, aucun parametre, non lue');

-- (b) un second passage
UPDATE public.profiles SET account_status = 'pending_kyc' WHERE id = '0d2e0000-0000-4000-8000-000000000002';
UPDATE public.profiles SET account_status = 'active' WHERE id = '0d2e0000-0000-4000-8000-000000000002';
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000002') = 1,
  '(b) un second passage a active n''ajoute aucune notification');

-- (c) le refus
SET LOCAL ROLE authenticated;
SELECT pg_temp.admin();
SELECT public.decider_dossier('0d2e0000-0000-4000-8000-000000000202', false, 'Piece illisible');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000003') = 0,
  '(c) un refus ne pose rien');

-- (d) la garde d'activation refuse : rien ne part
SET LOCAL ROLE authenticated;
SELECT pg_temp.admin();
DO $$
BEGIN
  PERFORM public.decider_dossier('0d2e0000-0000-4000-8000-000000000203', true, NULL);
  RAISE EXCEPTION 'BIENVENUE ROUGE : (d) la validation sans code de conduite est passee';
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM LIKE 'BIENVENUE ROUGE%' THEN RAISE; END IF;
END $$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.courriels('0d2e0000-0000-4000-8000-000000000004') = 0
    AND (SELECT account_status FROM public.profiles
          WHERE id = '0d2e0000-0000-4000-8000-000000000004') = 'pending_kyc',
  '(d) validation refusee par la garde : compte en attente, aucune notification');

-- (e) un tuteur
UPDATE public.profiles SET account_status = 'active' WHERE id = '0d2e0000-0000-4000-8000-000000000005';
SELECT pg_temp.vrai((SELECT count(*) FROM public.notifications
                      WHERE evenement = 'bienvenue_equipe'
                        AND destinataire = '0d2e0000-0000-4000-8000-000000000005') = 0,
  '(e) un compte qui n''est pas enseignant ne recoit rien');

-- (f) les droits
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.notification_bienvenue_equipe()', 'execute')
    AND NOT has_function_privilege('anon', 'private.notification_bienvenue_equipe()', 'execute'),
  '(f) la fonction du declencheur n''est executable ni par anon ni par authenticated');

-- (g) la contrainte garde tout ce qu'elle avait
SELECT pg_temp.vrai((SELECT pg_get_constraintdef(c.oid) LIKE '%''bienvenue_equipe''%'
                        AND pg_get_constraintdef(c.oid) LIKE '%''demande_recue''%'
                        AND pg_get_constraintdef(c.oid) LIKE '%''message_academie_eleve''%'
                        AND pg_get_constraintdef(c.oid) LIKE '%''remplacement_propose''%'
                       FROM pg_constraint c
                      WHERE c.conrelid = 'public.notifications'::regclass
                        AND c.conname = 'notifications_evenement_check'),
  '(g) bienvenue_equipe est dans la contrainte, les evenements d''avant aussi');

\o
SELECT 'BIENVENUE VERT' AS resultat;
ROLLBACK;
