-- MESSAGES-CANDIDAT (07/11/2026) : le fil « candidature » entre un candidat
-- enseignant (compte pending_kyc) et la direction, par la messagerie metier
-- COM-BACK-1. Migrations 20261119400000 et 20261119400100.
-- Prouve (ouvrir une messagerie a un compte non valide est une question de
-- securite : l'ouverture doit etre etanche) :
--   0. com_appelant, com_est_partie et com_profil_valide n'ont pas bouge
--      (md5 de production), et aucune fonction d'annonces ne lit
--      com_appelant_msg ;
--   1. le candidat ouvre SON fil, ecrit, le lit, le liste ; seul ce fil ;
--   2. la direction de son cote lit et repond (non lus compris) ; la direction
--      de l'autre cote ne lit, n'ecrit et n'ouvre rien ; le super-admin lit
--      les deux cotes ;
--   3. un candidat ne lit ni n'ouvre le fil d'un autre ;
--   4. un candidat n'obtient RIEN d'autre : aucun fil classe, eleve, dossier,
--      remplacement ni profilPaiement ; ses capacites n'ouvrent ni annonce ni
--      programmation ; les annonces lui sont fermees ;
--   5. une demande de famille (pending_kyc) n'ouvre rien ;
--   6. lecture seule : refusee, retiree, en pause, confirmee : le candidat et
--      la direction lisent, personne n'ecrit ;
--   7. le plafond de l'auteur candidat : 30 messages par 24 heures et par fil,
--      une cle rejouee n'est pas comptee, la direction n'est pas bornee ;
--   8. un appelant valide ne voit aucun fil « candidature » qui n'est pas le
--      sien (tuteur, enseignante active).
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'MSG-CAND ROUGE : %', p_label;
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
CREATE FUNCTION pg_temp.personne() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '', true); PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('test.uid', '', true); PERFORM set_config('test.jwt', '', true);
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
-- Le nombre de fils « candidature » que l'appelant liste.
CREATE FUNCTION pg_temp.nb_fils_cand() RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::integer FROM jsonb_array_elements(public.com_lister_fils()) f
   WHERE f #>> '{objet,type}' = 'candidature' $$;
CREATE FUNCTION pg_temp.nb_fils() RETURNS integer
LANGUAGE sql AS $$ SELECT jsonb_array_length(public.com_lister_fils()) $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.personne(), pg_temp.refus(text), pg_temp.nb_fils_cand(), pg_temp.nb_fils() TO authenticated;

-- 0. Les fonctions que l'ouverture ne devait pas toucher.
SELECT pg_temp.vrai(
  (SELECT md5(p.prosrc) FROM pg_proc p WHERE p.oid = 'private.com_appelant()'::regprocedure) = '228d6c8b9ced797a5de12cae4b2251fb'
  AND (SELECT md5(p.prosrc) FROM pg_proc p WHERE p.oid = 'private.com_est_partie(uuid,text,uuid,text,text,uuid)'::regprocedure) = '1c3cb14974bc909fa4f870d20707a62f'
  AND (SELECT md5(p.prosrc) FROM pg_proc p WHERE p.oid = 'private.com_profil_valide(uuid,text)'::regprocedure) = '50b93d06d9034e69cd3f3fa422c02072',
  '0. com_appelant, com_est_partie et com_profil_valide sont ceux de production');
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM pg_proc p WHERE p.pronamespace IN ('public'::regnamespace, 'private'::regnamespace)
     AND p.proname IN ('com_annonce_publier', 'com_annonces_administration', 'com_annonces_cibles', 'com_regles_audience')
     AND strpos(p.prosrc, 'com_appelant_msg') > 0),
  '0. aucune fonction d''annonces ne lit com_appelant_msg');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.com_appelant_msg()', 'execute')
  AND NOT has_function_privilege('anon', 'private.com_appelant_candidat()', 'execute')
  AND NOT has_function_privilege('authenticated', 'private.com_candidature_lisible(uuid,uuid)', 'execute'),
  '0. les fonctions nouvelles ne sont executables par aucun client');

-- A1 : direction (femmes) ; H1 : direction (hommes) ; SA : super-admin ;
-- C1, C2 : candidates (pending_kyc) ; M1 : candidat (homme) ; F1 : demande de
-- famille ; G1 : tuteur actif ; T2 : enseignante active.
INSERT INTO auth.users (id, email) VALUES
 ('7c400000-0000-4000-8000-0000000000a1', 'mc-a1@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000b1', 'mc-h1@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000b2', 'mc-sa@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000c1', 'mc-c1@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000c2', 'mc-c2@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000c3', 'mc-m1@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000c4', 'mc-f1@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000e1', 'mc-g1@test.invalid'),
 ('7c400000-0000-4000-8000-0000000000d2', 'mc-t2@test.invalid');
INSERT INTO public.households (id, timezone) VALUES
 ('7c400000-0000-4000-8000-0000000000f1', 'Europe/Paris'),
 ('7c400000-0000-4000-8000-0000000000f2', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7c400000-0000-4000-8000-0000000000a1', 'RA-26-7401', 'admin', NULL, 'Amina', 'MC', 'active', 'female'),
 ('7c400000-0000-4000-8000-0000000000b1', 'RA-26-7402', 'admin', NULL, 'Bilal', 'MC', 'active', 'male'),
 ('7c400000-0000-4000-8000-0000000000b2', 'RA-26-7403', 'admin', NULL, 'Sami', 'MC', 'active', 'male'),
 ('7c400000-0000-4000-8000-0000000000c1', 'RA-26-7404', 'teacher', NULL, 'Khadija', 'MC', 'pending_kyc', 'female'),
 ('7c400000-0000-4000-8000-0000000000c2', 'RA-26-7405', 'teacher', NULL, 'Maryam', 'MC', 'pending_kyc', 'female'),
 ('7c400000-0000-4000-8000-0000000000c3', 'RA-26-7406', 'teacher', NULL, 'Yusuf', 'MC', 'pending_kyc', 'male'),
 ('7c400000-0000-4000-8000-0000000000c4', 'RA-26-7407', 'guardian', '7c400000-0000-4000-8000-0000000000f2', 'Nadia', 'MC', 'pending_kyc', 'female'),
 ('7c400000-0000-4000-8000-0000000000e1', 'RA-26-7408', 'guardian', '7c400000-0000-4000-8000-0000000000f1', 'Samir', 'MC', 'active', 'male'),
 ('7c400000-0000-4000-8000-0000000000d2', 'RA-26-7409', 'teacher', NULL, 'Hafsa', 'MC', 'provisional_active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('7c400000-0000-4000-8000-0000000000b2');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7c400000-0000-4000-8000-000000000101', 'enseignant', '7c400000-0000-4000-8000-0000000000c1', 'female',
  'Fixture MC un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7c400000-0000-4000-8000-000000000102', 'enseignant', '7c400000-0000-4000-8000-0000000000c2', 'female',
  'Fixture MC deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7c400000-0000-4000-8000-000000000103', 'enseignant', '7c400000-0000-4000-8000-0000000000c3', 'male',
  'Fixture MC trois', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7c400000-0000-4000-8000-000000000104', 'famille', '7c400000-0000-4000-8000-0000000000c4', 'female',
  'Fixture MC quatre', 'prequalification', 'en_examen', 'en_cours', 'lien_public');

SET LOCAL ROLE authenticated;

-- 1. Le candidat ouvre son fil, ecrit, lit, liste.
DO $c1$
DECLARE
  v_fil jsonb;
  v_id uuid;
  v_msg jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'teacher');
  v_fil := public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000101', 'administration');
  PERFORM pg_temp.vrai(v_fil IS NOT NULL AND (v_fil ->> 'peut_ecrire')::boolean
    AND v_fil #>> '{objet,type}' = 'candidature',
    '1. le candidat ouvre le fil de SA candidature, et peut y ecrire');
  v_id := (v_fil ->> 'id')::uuid;
  PERFORM set_config('test.fil_c1', v_id::text, true);
  v_msg := public.com_envoyer_message(v_id, '  Bonjour, voici ma question.  ', '7c400000-0000-4000-8000-00000000a001');
  PERFORM pg_temp.vrai(v_msg ->> 'id' IS NOT NULL, '1. le candidat envoie un message');
  PERFORM pg_temp.vrai(
    (public.com_envoyer_message(v_id, 'Bonjour, voici ma question.', '7c400000-0000-4000-8000-00000000a001') ->> 'id')
      = (v_msg ->> 'id'),
    '1. une cle rejouee rend le meme accuse, sans second message');
  PERFORM pg_temp.vrai(pg_temp.nb_fils() = 1 AND pg_temp.nb_fils_cand() = 1,
    '1. il ne liste que ce fil, rien d''autre');
  PERFORM pg_temp.vrai(public.com_lire_fil(v_id) #>> '{messages,0,texte}' = 'Bonjour, voici ma question.'
    AND jsonb_array_length(public.com_lire_fil(v_id) -> 'messages') = 1
    AND (public.com_lire_fil(v_id) #>> '{parties,1,nature}') = 'equipe',
    '1. il relit son message (espaces retires), en face l''equipe, rien d''une personne');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', repeat('x', 5001), gen_random_uuid())$q$) = '22023',
    '1. un message de plus de 5000 caracteres est refuse (plafond de longueur existant)');
END
$c1$;

-- 2. La direction : son cote, l'autre cote, le super-admin.
DO $direction$
DECLARE
  v_id uuid := current_setting('test.fil_c1')::uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(pg_temp.nb_fils_cand() = 1
    AND (SELECT (f ->> 'non_lus')::int FROM jsonb_array_elements(public.com_lister_fils()) f
          WHERE f ->> 'id' = v_id::text) = 1,
    '2. la direction du cote femmes voit le fil, avec 1 message non lu');
  PERFORM public.com_envoyer_message(v_id, 'Bonjour, nous vous repondons.', '7c400000-0000-4000-8000-00000000a002');
  PERFORM public.com_marquer_lu(v_id);
  PERFORM pg_temp.vrai((public.com_lire_fil(v_id) ->> 'non_lus')::int = 0,
    '2. la direction marque le fil lu : plus de non lu pour elle');

  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai(pg_temp.nb_fils_cand() = 0 AND public.com_lire_fil(v_id) IS NULL
    AND pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', 'Intrusion', gen_random_uuid())$q$) = '42501'
    AND pg_temp.refus($q$SELECT public.com_marquer_lu('$q$ || v_id || $q$')$q$) = '42501'
    AND public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000101', '7c400000-0000-4000-8000-0000000000c1') IS NULL,
    '2. la direction de l''autre cote (hommes) ne liste, ne lit, n''ecrit et n''ouvre rien');
  PERFORM pg_temp.vrai(jsonb_array_length(public.com_conversations_pour_objet('candidature', '7c400000-0000-4000-8000-000000000101')) = 0,
    '2. et la liste des conversations de cette candidature lui est vide');

  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000b2', 'admin');
  PERFORM pg_temp.vrai(public.com_lire_fil(v_id) IS NOT NULL AND pg_temp.nb_fils_cand() >= 1,
    '2. le super-admin (exception active) lit le fil du cote femmes');

  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM pg_temp.vrai((public.com_lire_fil(v_id) ->> 'non_lus')::int = 1
    AND jsonb_array_length(public.com_lire_fil(v_id) -> 'messages') = 2,
    '2. le candidat voit la reponse de la direction (1 non lu), sans nom de personne : l''administration');
  PERFORM public.com_marquer_lu(v_id);
  PERFORM pg_temp.vrai((public.com_lire_fil(v_id) ->> 'non_lus')::int = 0, '2. le candidat marque lu : 0 non lu');
END
$direction$;

-- 3. Un candidat face au fil d'un autre.
DO $autre$
DECLARE
  v_id uuid := current_setting('test.fil_c1')::uuid;
  v_fil_m uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c2', 'teacher');
  PERFORM pg_temp.vrai(public.com_lire_fil(v_id) IS NULL
    AND pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', 'Intrusion', gen_random_uuid())$q$) = '42501'
    AND public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000101', 'administration') IS NULL
    AND jsonb_array_length(public.com_conversations_pour_objet('candidature', '7c400000-0000-4000-8000-000000000101')) = 0
    AND pg_temp.nb_fils() = 0,
    '3. un candidat ne lit, n''ecrit et n''ouvre pas le fil d''un autre, et ne liste rien');
  -- Le candidat homme ouvre le sien ; la direction femmes ne le lit pas.
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c3', 'teacher');
  v_fil_m := (public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000103', 'administration') ->> 'id')::uuid;
  PERFORM public.com_envoyer_message(v_fil_m, 'Bonjour de la part d''un candidat.', gen_random_uuid());
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(public.com_lire_fil(v_fil_m) IS NULL
    AND pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_fil_m || $q$', 'Intrusion', gen_random_uuid())$q$) = '42501',
    '3. la direction femmes ne lit pas le fil d''un candidat homme (CAND-Q07, en base)');
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai(public.com_lire_fil(v_fil_m) IS NOT NULL, '3. la direction hommes le lit');
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000b2', 'admin');
  PERFORM pg_temp.vrai(public.com_lire_fil(v_fil_m) IS NOT NULL AND public.com_lire_fil(v_id) IS NOT NULL,
    '3. le super-admin lit les deux cotes');
END
$autre$;

-- 4. Un candidat n'obtient RIEN d'autre.
DO $rien$
DECLARE
  v_t text;
  v_id uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'teacher');
  FOREACH v_t IN ARRAY ARRAY['classe', 'eleve', 'dossier', 'remplacement', 'profilPaiement'] LOOP
    v_id := '7c400000-0000-4000-8000-0000000000c1';
    PERFORM pg_temp.vrai(
      public.com_ouvrir_conversation(v_t, v_id, 'administration') IS NULL
      AND public.com_ouvrir_conversation(v_t, gen_random_uuid(), 'administration') IS NULL
      AND jsonb_array_length(public.com_conversations_pour_objet(v_t, v_id)) = 0
      AND public.com_fil_pour_objet(v_t, v_id) IS NULL
      AND NOT (public.com_mes_capacites(v_t, v_id) ->> 'ecrire_dans_fil')::boolean,
      '4. type ' || v_t || ' : aucune conversation, aucun fil, aucune capacite d''ecrire');
  END LOOP;
  PERFORM pg_temp.vrai(
    NOT (public.com_mes_capacites() ->> 'publier_annonce')::boolean
    AND NOT (public.com_mes_capacites() ->> 'programmer')::boolean
    AND NOT (public.com_mes_capacites() ->> 'envoyer_vocal')::boolean,
    '4. ses capacites n''ouvrent ni annonce, ni programmation, ni vocal');
  PERFORM pg_temp.vrai(
    (public.com_mes_capacites('candidature', '7c400000-0000-4000-8000-000000000101') ->> 'ecrire_dans_fil')::boolean
    AND NOT (public.com_mes_capacites('candidature', '7c400000-0000-4000-8000-000000000102') ->> 'ecrire_dans_fil')::boolean,
    '4. il peut ecrire sur SA candidature, pas sur celle d''un autre');
  PERFORM pg_temp.vrai(
    pg_temp.refus('SELECT public.com_annonces_administration()') = '42501'
    AND pg_temp.refus('SELECT public.com_regles_audience()') = '42501'
    AND pg_temp.refus($q$SELECT public.com_annonce_publier('academie', 'Titre', 'Texte', NULL, gen_random_uuid())$q$) = '42501'
    AND pg_temp.refus('SELECT public.com_annonces_cibles(NULL)') = '42501',
    '4. les annonces lui sont fermees (publier, lire la direction, regles, cibles)');
END
$rien$;

-- 5. Une demande de famille (pending_kyc) n'ouvre rien.
DO $famille$
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c4', 'guardian');
  PERFORM pg_temp.vrai(
    pg_temp.refus('SELECT public.com_lister_fils()') = '42501'
    AND pg_temp.refus($q$SELECT public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000104', 'administration')$q$) = '42501',
    '5. une demande de famille (pending_kyc, candidature famille) n''ouvre aucune messagerie');
  -- Un candidat enseignant dont le jeton porte un autre role est refuse.
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'guardian');
  PERFORM pg_temp.vrai(pg_temp.refus('SELECT public.com_lister_fils()') = '42501',
    '5. un jeton au role different du role en base est refuse');
END
$famille$;

-- 6. Lecture seule : refusee, retiree, en pause, confirmee.
RESET ROLE;
DO $etats$
DECLARE
  v_etat text;
  v_id uuid := current_setting('test.fil_c1')::uuid;
BEGIN
  FOREACH v_etat IN ARRAY ARRAY['refusee', 'retiree', 'pause', 'confirmee'] LOOP
    UPDATE public.candidatures SET etape = 'verifications', etat = 'entretien_a_planifier',
           issue = 'en_cours', en_pause = false, issue_modele = NULL
     WHERE id = '7c400000-0000-4000-8000-000000000101';
    IF v_etat IN ('refusee', 'retiree') THEN
      UPDATE public.candidatures SET issue = v_etat, issue_modele = CASE v_etat WHEN 'refusee' THEN 'refus_general' END
       WHERE id = '7c400000-0000-4000-8000-000000000101';
    ELSIF v_etat = 'pause' THEN
      UPDATE public.candidatures SET en_pause = true WHERE id = '7c400000-0000-4000-8000-000000000101';
    ELSE
      UPDATE public.candidatures SET etape = 'confirmee', etat = NULL WHERE id = '7c400000-0000-4000-8000-000000000101';
    END IF;
    SET LOCAL ROLE authenticated;
    PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'teacher');
    PERFORM pg_temp.vrai(public.com_lire_fil(v_id) IS NOT NULL
      AND NOT (public.com_lire_fil(v_id) ->> 'peut_ecrire')::boolean
      AND jsonb_array_length(public.com_lire_fil(v_id) -> 'messages') = 2
      AND pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', 'Apres', gen_random_uuid())$q$) = '42501',
      '6. ' || v_etat || ' : le candidat lit son fil, n''y ecrit plus');
    PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000a1', 'admin');
    PERFORM pg_temp.vrai(public.com_lire_fil(v_id) IS NOT NULL
      AND NOT (public.com_lire_fil(v_id) ->> 'peut_ecrire')::boolean
      AND pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', 'Apres', gen_random_uuid())$q$) = '42501',
      '6. ' || v_etat || ' : la direction lit l''historique, n''y ecrit plus');
    RESET ROLE;
  END LOOP;
  UPDATE public.candidatures SET etape = 'verifications', etat = 'entretien_a_planifier',
         issue = 'en_cours', en_pause = false
   WHERE id = '7c400000-0000-4000-8000-000000000101';
END
$etats$;

-- 7. Le plafond de l'auteur candidat.
SET LOCAL ROLE authenticated;
DO $plafond$
DECLARE
  v_id uuid := current_setting('test.fil_c1')::uuid;
  i integer;
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'teacher');
  -- 1 message du candidat deja envoye au point 1 : 29 de plus font 30.
  FOR i IN 1 .. 29 LOOP
    PERFORM public.com_envoyer_message(v_id, 'Message ' || i, gen_random_uuid());
  END LOOP;
  PERFORM pg_temp.vrai(
    pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', 'Le trente et unieme', gen_random_uuid())$q$) = '53400',
    '7. le 31e message de 24 heures du candidat est refuse (SQLSTATE 53400)');
  PERFORM pg_temp.vrai(
    (public.com_envoyer_message(v_id, 'Bonjour, voici ma question.', '7c400000-0000-4000-8000-00000000a001') ->> 'id') IS NOT NULL,
    '7. la meme cle rejouee n''est pas comptee, meme au plafond');
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000a1', 'admin');
  FOR i IN 1 .. 35 LOOP
    PERFORM public.com_envoyer_message(v_id, 'Reponse ' || i, gen_random_uuid());
  END LOOP;
  PERFORM pg_temp.vrai(true, '7. la direction n''est pas bornee (35 messages de plus)');
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM pg_temp.vrai(
    pg_temp.refus($q$SELECT public.com_envoyer_message('$q$ || v_id || $q$', 'Toujours refuse', gen_random_uuid())$q$) = '53400',
    '7. les reponses de la direction ne reduisent pas le plafond du candidat');
END
$plafond$;
RESET ROLE;
SET LOCAL ROLE authenticated;

-- 8. Un appelant valide ne voit aucun fil « candidature » qui n'est pas le sien.
DO $valides$
BEGIN
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000e1', 'guardian');
  PERFORM pg_temp.vrai(pg_temp.nb_fils_cand() = 0
    AND public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000101', 'administration') IS NULL,
    '8. un tuteur actif ne voit ni n''ouvre aucun fil candidature');
  PERFORM pg_temp.en_tant_que('7c400000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM pg_temp.vrai(pg_temp.nb_fils_cand() = 0
    AND public.com_ouvrir_conversation('candidature', '7c400000-0000-4000-8000-000000000101', 'administration') IS NULL,
    '8. une enseignante active ne voit ni n''ouvre le fil d''une candidate');
END
$valides$;
RESET ROLE;

SELECT 'MSG-CAND VERT' AS resultat;
ROLLBACK;
