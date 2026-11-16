-- IMAGE-CANDIDAT (16/11/2026) : un candidat (compte pending_kyc) envoie une image dans le
-- fil de sa candidature, et un message « [image] » sans image n'est montre a personne.
--
--   1. le candidat depose (demander) une image sur SON message ; son depot se relit et
--      s'annule ; il lit les miniatures du fil ;
--   2. il ne depose rien sur le message d'un autre, ni dans un fil qui n'est pas le sien ;
--   3. un tuteur actif, une enseignante active et la direction de l'autre cote n'obtiennent
--      ni depot ni miniatures sur ce fil ;
--   4. un message « [image] » SANS image ne se lit pour personne (candidat, direction) ni
--      dans le dernier message de la liste ni dans le compte des non lus ; avec une image
--      en attente il reste lisible de son auteur seulement ; un texte « Image » ecrit par
--      une personne reste lisible ;
--   5. un compte eleve mineur n'obtient toujours rien (rien d'ouvert en passant).
-- Doit ECHOUER avant 20261129400000 (le point 1).
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'IMG-CAND ROUGE : %', p_label;
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
-- Un appel qui doit etre refuse : rend le SQLSTATE, ou NULL s'il a abouti.
CREATE FUNCTION pg_temp.refus(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE;
END $$;
-- Les textes des messages que l'appelant lit dans le fil.
CREATE FUNCTION pg_temp.textes(p_fil uuid) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(m ->> 'texte' ORDER BY ord), ARRAY[]::text[])
    FROM jsonb_array_elements(public.com_lire_fil(p_fil) -> 'messages') WITH ORDINALITY AS t(m, ord) $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.refus(text), pg_temp.textes(uuid) TO authenticated;

-- A1 : direction (femmes) ; H1 : direction (hommes) ; C1, C2 : candidates (pending_kyc) ;
-- G1 : tuteur actif ; T2 : enseignante active ; E1 : eleve mineur.
INSERT INTO auth.users (id, email) VALUES
 ('7c500000-0000-4000-8000-0000000000a1', 'ic-a1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000b1', 'ic-h1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000c1', 'ic-c1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000c2', 'ic-c2@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000e1', 'ic-g1@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000d2', 'ic-t2@test.invalid'),
 ('7c500000-0000-4000-8000-0000000000e2', 'ic-e1@test.invalid');
INSERT INTO public.households (id, timezone) VALUES
 ('7c500000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7c500000-0000-4000-8000-0000000000a1', 'RA-26-7501', 'admin', NULL, 'Amina', 'IC', 'active', 'female'),
 ('7c500000-0000-4000-8000-0000000000b1', 'RA-26-7502', 'admin', NULL, 'Bilal', 'IC', 'active', 'male'),
 ('7c500000-0000-4000-8000-0000000000c1', 'RA-26-7503', 'teacher', NULL, 'Khadija', 'IC', 'pending_kyc', 'female'),
 ('7c500000-0000-4000-8000-0000000000c2', 'RA-26-7504', 'teacher', NULL, 'Maryam', 'IC', 'pending_kyc', 'female'),
 ('7c500000-0000-4000-8000-0000000000e1', 'RA-26-7505', 'guardian', '7c500000-0000-4000-8000-0000000000f1', 'Samir', 'IC', 'active', 'male'),
 ('7c500000-0000-4000-8000-0000000000d2', 'RA-26-7506', 'teacher', NULL, 'Hafsa', 'IC', 'provisional_active', 'female'),
 ('7c500000-0000-4000-8000-0000000000e2', 'RA-26-7507', 'student', '7c500000-0000-4000-8000-0000000000f1', 'Adam', 'IC', 'active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type)
  SELECT '7c500000-0000-4000-8000-0000000000e2', 'minor'
   WHERE EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'student_profiles'
                    AND column_name = 'student_type');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7c500000-0000-4000-8000-000000000101', 'enseignant', '7c500000-0000-4000-8000-0000000000c1', 'female',
  'Fixture IC un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7c500000-0000-4000-8000-000000000102', 'enseignant', '7c500000-0000-4000-8000-0000000000c2', 'female',
  'Fixture IC deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');

SET LOCAL ROLE authenticated;

-- 1. Le candidat envoie une image dans le fil de SA candidature.
DO $c1$
DECLARE
  v_fil jsonb;
  v_id uuid;
  v_msg uuid;
  v_dep jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  v_fil := public.com_ouvrir_conversation('candidature', '7c500000-0000-4000-8000-000000000101', 'administration');
  v_id := (v_fil ->> 'id')::uuid;
  PERFORM set_config('test.fil', v_id::text, true);
  v_msg := (public.com_envoyer_message(v_id, '[image]', '7c500000-0000-4000-8000-00000000b001') ->> 'id')::uuid;
  PERFORM set_config('test.msg', v_msg::text, true);
  v_dep := public.message_image_demander(v_msg, 'image/jpeg', 150000, 'image/webp', 8000, 800, 600, '#a1b2c3');
  PERFORM pg_temp.vrai(v_dep ->> 'image_id' IS NOT NULL AND v_dep ->> 'cle_r2' LIKE 'fils/%',
    '1. le candidat obtient son depot d''image sur SON message (plus de 403)');
  PERFORM set_config('test.image', v_dep ->> 'image_id', true);
  PERFORM pg_temp.vrai(public.message_image_lire_depot((v_dep ->> 'image_id')::uuid) ->> 'fil_id' = v_id::text,
    '1. il relit son depot avant de le confirmer');
  PERFORM pg_temp.vrai(public.message_images_a_signer(v_id) IS NOT NULL,
    '1. il lit les miniatures de son fil');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_image_demander('$q$ || v_msg
    || $q$', 'image/jpeg', 150000, 'image/webp', 8000, 800, 600)$q$) IS NULL,
    '1. redemander le meme depot (lien expire) reste permis');
END
$c1$;

-- 2. Pas sur le message d'un autre, pas dans le fil d'un autre.
DO $autre$
DECLARE
  v_msg uuid := current_setting('test.msg')::uuid;
  v_fil uuid := current_setting('test.fil')::uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c2', 'teacher');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_image_demander('$q$ || v_msg
    || $q$', 'image/jpeg', 150000, 'image/webp', 8000, 800, 600)$q$) = '42501',
    '2. une autre candidate ne depose rien sur le message de la premiere');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_images_a_signer('$q$ || v_fil || $q$')$q$) = '42501',
    '2. elle ne lit pas les miniatures de ce fil');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_image_annuler('$q$
    || current_setting('test.image') || $q$')$q$) IS NULL
    AND (SELECT i.etat FROM public.com_message_images i WHERE i.id = current_setting('test.image')::uuid) IS NULL,
    '2. elle n''annule pas le depot de la premiere (aucune ligne ne lui est visible)');
END
$autre$;

-- 3. Les autres comptes.
DO $autres$
DECLARE
  v_msg uuid := current_setting('test.msg')::uuid;
  v_fil uuid := current_setting('test.fil')::uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000e1', 'guardian');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_images_a_signer('$q$ || v_fil || $q$')$q$) = '42501',
    '3. un tuteur actif ne lit pas les miniatures du fil d''une candidate');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_images_a_signer('$q$ || v_fil || $q$')$q$) = '42501',
    '3. une enseignante active ne lit pas les miniatures du fil d''une candidate');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_images_a_signer('$q$ || v_fil || $q$')$q$) = '42501',
    '3. la direction de l''autre cote ne lit pas les miniatures de ce fil');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(public.message_images_a_signer(v_fil) IS NOT NULL,
    '3. la direction du bon cote les lit');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_image_demander('$q$ || v_msg
    || $q$', 'image/jpeg', 150000, 'image/webp', 8000, 800, 600)$q$) = '42501',
    '3. la direction ne depose pas sur le message du candidat (pas l''auteur)');
END
$autres$;

-- 4. « [image] » sans image : montre a personne.
DO $masque$
DECLARE
  v_fil uuid := current_setting('test.fil')::uuid;
  v_nu uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  -- Le message du point 1 a une image en attente : lisible de son auteur seulement.
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY['[image]'],
    '4. avec une image en attente, l''auteur lit son message');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY[]::text[],
    '4. la direction ne lit pas un message dont l''image n''est pas confirmee');
  -- Le depot est annule : plus d'image vivante, plus de message pour personne.
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM pg_temp.vrai(public.message_image_annuler(current_setting('test.image')::uuid),
    '4. le candidat annule son depot');
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY[]::text[],
    '4. depot annule : le candidat ne relit plus « [image] »');
  -- Un message « [image] » SANS aucune ligne d'image (le cas de production : 403).
  v_nu := (public.com_envoyer_message(v_fil, '[image]', '7c500000-0000-4000-8000-00000000b002') ->> 'id')::uuid;
  PERFORM pg_temp.vrai(v_nu IS NOT NULL AND pg_temp.textes(v_fil) = ARRAY[]::text[],
    '4. « [image] » sans aucune image : le candidat ne le lit pas');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY[]::text[],
    '4. ni la direction');
  PERFORM pg_temp.vrai((SELECT coalesce(max((f ->> 'non_lus')::int), 0)
                          FROM jsonb_array_elements(public.com_lister_fils()) f
                         WHERE f ->> 'id' = v_fil::text) = 0,
    '4. et il ne compte pas dans les non lus de la direction');
  -- Un texte ecrit par une personne reste lisible, meme « Image ».
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM public.com_envoyer_message(v_fil, 'Image', '7c500000-0000-4000-8000-00000000b003');
  PERFORM public.com_envoyer_message(v_fil, 'Bonjour', '7c500000-0000-4000-8000-00000000b004');
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY['Image', 'Bonjour'],
    '4. un texte ecrit par une personne reste lisible, meme « Image »');
END
$masque$;

-- 4 bis. Une image CONFIRMEE puis purgee (« supprimee » avec confirmee_le) : le message
-- reste lisible, avec son image a l'etat « supprimee » (ligne « image retiree », #519).
-- Seul un message « [image] » SANS AUCUNE ligne d'image est masque.
DO $purgee$
DECLARE
  v_fil uuid := current_setting('test.fil')::uuid;
  v_msg uuid;
  v_img uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  v_msg := (public.com_envoyer_message(v_fil, '[image]', '7c500000-0000-4000-8000-00000000b005') ->> 'id')::uuid;
  v_img := (public.message_image_demander(v_msg, 'image/jpeg', 150000, 'image/webp', 8000, 800, 600) ->> 'image_id')::uuid;
  RESET ROLE;
  -- La confirmation (HMAC) est jouee par la fonction Edge : ici, l'etat est pose a la main,
  -- puis la purge des 90 jours.
  UPDATE public.com_message_images
     SET etat = 'confirmee', confirmee_le = pg_catalog.clock_timestamp()
   WHERE id = v_img;
  UPDATE public.com_message_images
     SET etat = 'supprimee', supprimee_le = pg_catalog.clock_timestamp()
   WHERE id = v_img;
  SET LOCAL ROLE authenticated;

  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY['Image', 'Bonjour', '[image]']
    AND (SELECT m #>> '{image,etat}'
           FROM jsonb_array_elements(public.com_lire_fil(v_fil) -> 'messages') m
          WHERE m ->> 'id' = v_msg::text) = 'supprimee',
    '4bis. image confirmee puis purgee : l''auteur lit son message, image a l''etat supprimee');
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(pg_temp.textes(v_fil) = ARRAY['Image', 'Bonjour', '[image]']
    AND (SELECT m #>> '{image,etat}'
           FROM jsonb_array_elements(public.com_lire_fil(v_fil) -> 'messages') m
          WHERE m ->> 'id' = v_msg::text) = 'supprimee',
    '4bis. la direction le lit aussi, image a l''etat supprimee (ligne « image retiree »)');
END
$purgee$;

-- 5. Un eleve mineur n'obtient rien en passant.
DO $mineur$
BEGIN
  PERFORM pg_temp.en_tant_que('7c500000-0000-4000-8000-0000000000e2', 'student');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.message_images_a_signer('$q$
    || current_setting('test.fil') || $q$')$q$) = '42501'
    AND pg_temp.refus($q$SELECT public.message_image_demander('$q$ || current_setting('test.msg')
    || $q$', 'image/jpeg', 150000, 'image/webp', 8000, 800, 600)$q$) = '42501',
    '5. un eleve mineur n''obtient ni depot ni miniatures');
END
$mineur$;
RESET ROLE;

SELECT 'IMG-CAND VERT' AS resultat;
ROLLBACK;
