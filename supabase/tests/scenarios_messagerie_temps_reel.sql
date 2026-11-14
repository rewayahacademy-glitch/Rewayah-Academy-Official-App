-- MESSAGERIE-TEMPS-REEL (14/11/2026) : le signal publie dans Realtime a chaque
-- message et a chaque lecture (migration 20261125800000).
-- Prouve :
--   1. un message du candidat signale la direction de SON cote et le
--      super-admin ; ni la direction de l'autre cote, ni l'auteur, ni un autre
--      candidat ;
--   2. RLS : chacun ne lit que SA ligne ; anon ne lit rien ; aucun client
--      n'ecrit (insert, update) ;
--   3. la reponse de la direction signale le candidat (pending_kyc) ;
--   4. une lecture signale la personne elle-meme (autres appareils) ;
--   5. un fil de foyer signale les adultes du foyer, jamais un mineur ;
--   6. la table ne grossit pas : une ligne par personne, le rang monte ;
--   7. aucun emetteur n'est executable par un client.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'MSG-TR ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.refus(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE;
END $$;
-- Le signal de [p_qui], lu en superutilisateur (hors RLS).
CREATE FUNCTION pg_temp.signal(p_qui uuid) RETURNS public.com_signaux
LANGUAGE sql AS $$ SELECT s FROM public.com_signaux s WHERE s.destinataire = p_qui $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.refus(text) TO authenticated, anon;

-- 7. Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.com_signaler_message()', 'execute')
  AND NOT has_function_privilege('anon', 'private.com_signaler_lecture()', 'execute')
  AND NOT has_function_privilege('authenticated', 'private.com_signal_poser(uuid,uuid,text)', 'execute')
  AND NOT has_function_privilege('authenticated', 'private.com_destinataires_signal(uuid,uuid)', 'execute')
  AND NOT has_table_privilege('anon', 'public.com_signaux', 'select')
  AND NOT has_table_privilege('authenticated', 'public.com_signaux', 'insert')
  AND NOT has_table_privilege('authenticated', 'public.com_signaux', 'update')
  AND has_table_privilege('authenticated', 'public.com_signaux', 'select')
  AND (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid = 'public.com_signaux'::regclass),
  '7. emetteurs fermes aux clients ; com_signaux en lecture seule, sous RLS');

INSERT INTO auth.users (id, email) VALUES
 ('7c500000-0000-4000-8000-0000000000a1', 'tr-a1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000b1', 'tr-h1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000b2', 'tr-sa@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000c1', 'tr-c1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000c2', 'tr-c2@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000e1', 'tr-g1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000e2', 'tr-s1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000d2', 'tr-t2@test.invalid');
INSERT INTO public.households (id, timezone) VALUES
 ('7c500000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7c500000-0000-4000-8000-0000000000a1', 'RA-26-7501', 'admin', NULL, 'Amina', 'TR', 'active', 'female'),
 ('7c500000-0000-4000-8000-0000000000b1', 'RA-26-7502', 'admin', NULL, 'Bilal', 'TR', 'active', 'male'),
 ('7c500000-0000-4000-8000-0000000000b2', 'RA-26-7503', 'admin', NULL, 'Sami', 'TR', 'active', 'male'),
 ('7c500000-0000-4000-8000-0000000000c1', 'RA-26-7504', 'teacher', NULL, 'Khadija', 'TR', 'pending_kyc', 'female'),
 ('7c500000-0000-4000-8000-0000000000c2', 'RA-26-7505', 'teacher', NULL, 'Maryam', 'TR', 'pending_kyc', 'female'),
 ('7c500000-0000-4000-8000-0000000000e1', 'RA-26-7506', 'guardian', '7c500000-0000-4000-8000-0000000000f1', 'Samir', 'TR', 'active', 'male'),
 ('7c500000-0000-4000-8000-0000000000e2', 'RA-26-7507', 'student', '7c500000-0000-4000-8000-0000000000f1', 'Ilyas', 'TR', 'active', 'male'),
 ('7c500000-0000-4000-8000-0000000000d2', 'RA-26-7508', 'teacher', NULL, 'Hafsa', 'TR', 'provisional_active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('7c500000-0000-4000-8000-0000000000b2');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7c500000-0000-4000-8000-000000000101', 'enseignant', '7c500000-0000-4000-8000-0000000000c1', 'female',
  'Fixture TR un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7c500000-0000-4000-8000-000000000102', 'enseignant', '7c500000-0000-4000-8000-0000000000c2', 'female',
  'Fixture TR deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');

SET LOCAL ROLE authenticated;

-- 1. Le candidat ecrit.
DO $c1$
DECLARE
  v_id uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  v_id := (public.com_ouvrir_conversation('candidature', '7c500000-0000-4000-8000-000000000101', 'administration') ->> 'id')::uuid;
  PERFORM set_config('test.fil', v_id::text, true);
  PERFORM public.com_envoyer_message(v_id, 'Bonjour.', '7c500000-0000-4000-8000-00000000a001');
END
$c1$;
RESET ROLE;

SELECT pg_temp.vrai(
  (pg_temp.signal('7c500000-0000-4000-8000-0000000000a1')).nature = 'message'
  AND (pg_temp.signal('7c500000-0000-4000-8000-0000000000a1')).fil_id = current_setting('test.fil')::uuid
  AND (pg_temp.signal('7c500000-0000-4000-8000-0000000000b2')).nature = 'message',
  '1. la direction du cote du candidat et le super-admin sont signales');
SELECT pg_temp.vrai(
  (pg_temp.signal('7c500000-0000-4000-8000-0000000000b1')).destinataire IS NULL
  AND (pg_temp.signal('7c500000-0000-4000-8000-0000000000c2')).destinataire IS NULL
  AND coalesce((pg_temp.signal('7c500000-0000-4000-8000-0000000000c1')).nature, 'lecture') = 'lecture',
  '1. ni l''autre cote, ni un autre candidat, ni l''auteur (sauf sa lecture) ne recoivent de message');

-- 2. RLS.
SET LOCAL ROLE authenticated;
DO $c2$
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.com_signaux) = 1
    AND (SELECT destinataire FROM public.com_signaux) = '7c500000-0000-4000-8000-0000000000a1',
    '2. la direction ne lit que SA ligne');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c2', 'teacher');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.com_signaux) = 0,
    '2. un autre candidat ne lit aucune ligne');
  PERFORM pg_temp.vrai(
    pg_temp.refus($q$INSERT INTO public.com_signaux (destinataire, fil_id, nature) VALUES ('7c500000-0000-4000-8000-0000000000c2', gen_random_uuid(), 'message')$q$) = '42501'
    AND pg_temp.refus($q$UPDATE public.com_signaux SET rang = 9$q$) = '42501',
    '2. aucun client n''ecrit dans com_signaux');
END
$c2$;
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refus('SELECT 1 FROM public.com_signaux') = '42501',
  '2. anon ne lit pas com_signaux');
RESET ROLE;

-- 3 et 4. La direction repond ; le candidat lit.
SET LOCAL ROLE authenticated;
DO $c3$
DECLARE
  v_id uuid := current_setting('test.fil')::uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM public.com_envoyer_message(v_id, 'Bonjour, merci.', '7c500000-0000-4000-8000-00000000a002');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM pg_temp.vrai((SELECT nature FROM public.com_signaux) = 'message'
    AND (SELECT fil_id FROM public.com_signaux) = v_id,
    '3. le candidat (pending_kyc) lit le signal de la reponse');
  PERFORM set_config('test.rang', (SELECT rang FROM public.com_signaux)::text, true);
  PERFORM public.com_marquer_lu(v_id);
  PERFORM pg_temp.vrai((SELECT nature FROM public.com_signaux) = 'lecture'
    AND (SELECT rang FROM public.com_signaux) > current_setting('test.rang')::bigint,
    '4. une lecture signale la personne elle-meme, le rang monte');
END
$c3$;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.com_signaux
    WHERE destinataire IN ('7c500000-0000-4000-8000-0000000000a1', '7c500000-0000-4000-8000-0000000000c1')) = 2,
  '6. une ligne par personne, jamais empilee');

-- 5. Un fil de foyer : adultes oui, mineur non.
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
VALUES ('7c500000-0000-4000-8000-000000000201', 'eleve', '7c500000-0000-4000-8000-0000000000e2',
        'foyer', '7c500000-0000-4000-8000-0000000000f1', 'profil', '7c500000-0000-4000-8000-0000000000d2');
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte)
VALUES ('7c500000-0000-4000-8000-000000000201', '7c500000-0000-4000-8000-0000000000d2',
        '7c500000-0000-4000-8000-00000000a003', 'Message de l''enseignante.');
SELECT pg_temp.vrai(
  (pg_temp.signal('7c500000-0000-4000-8000-0000000000e1')).fil_id = '7c500000-0000-4000-8000-000000000201'
  AND (pg_temp.signal('7c500000-0000-4000-8000-0000000000e2')).destinataire IS NULL
  AND (pg_temp.signal('7c500000-0000-4000-8000-0000000000d2')).destinataire IS NULL,
  '5. le tuteur est signale, jamais l''eleve mineur ni l''auteur');

ROLLBACK;
