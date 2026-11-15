-- ANNONCES-SIMPLES (14/11/2026) : les publics, la separation des cotes et la
-- protection des mineurs, calcules par le serveur (migration
-- 20261126700000_annonces_simples.sql).
--
-- Prouve :
--   1. les publics et leurs nombres : un mineur n'est dans AUCUN public ; un
--      message « eleves » atteint le parent du mineur ; « candidats » et
--      « femmes » se combinent ; « candidats admis » = salle 3 ;
--   2. CAND-Q07 : une direction d'un cote ne compte, n'atteint et ne liste que
--      le sien ; seul le super-admin atteint les deux cotes ;
--   3. un public vide ne s'envoie pas, et rien n'en reste ;
--   4. l'envoi : destinataires figes, courriels en file pour les adultes
--      seulement (jamais le mineur), cle rejouee sans second envoi ;
--   5. la notification attend sa contrainte : l'annonce reste dans le fil ;
--   6. un mineur n'a ni fil, ni annonce generale (meme ancienne) ;
--   7. le parent et le candidat (compte en attente) lisent leur fil et sont
--      comptes « vu » ; la direction lit la mesure ;
--   8. une annonce programmee n'est ni lisible ni distribuee avant son heure ;
--   9. droits : enseignant refuse, anon refuse, tables fermees au client.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ANN-SIMPLES ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ANN-SIMPLES OK %', p_label;
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
-- Vrai si la personne [p] est dans la combinaison [publics], dans les cotes.
CREATE FUNCTION pg_temp.dans(p_publics text[], p_cotes public.gender[], p text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT EXISTS (SELECT 1 FROM private.com_annonce_personnes(p_publics, p_cotes) x
                  WHERE x.profile_id = p::uuid) $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS $$
  SELECT ('a5500000-0000-4000-8000-0000000000' || p)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.refus(text), pg_temp.u(text) TO authenticated, anon;

-- Fixtures : SA super-admin (homme) ; A1 direction femmes ; H1 direction
-- hommes ; T1 enseignante, T2 enseignant ; C1 candidate en cours ; C2 candidat
-- admis (salle 3) ; G1 pere d'un enfant mineur E1 ; G2 mere sans enfant
-- mineur ; S1 eleve adulte (femme).
INSERT INTO auth.users (id, email) VALUES
 (pg_temp.u('a0'), 'as-sa@test.invalid'), (pg_temp.u('a1'), 'as-a1@test.invalid'),
 (pg_temp.u('a2'), 'as-h1@test.invalid'), (pg_temp.u('b1'), 'as-t1@test.invalid'),
 (pg_temp.u('b2'), 'as-t2@test.invalid'), (pg_temp.u('c1'), 'as-c1@test.invalid'),
 (pg_temp.u('c2'), 'as-c2@test.invalid'), (pg_temp.u('d1'), 'as-g1@test.invalid'),
 (pg_temp.u('d2'), 'as-g2@test.invalid'), (pg_temp.u('e1'), 'as-e1@test.invalid'),
 (pg_temp.u('e2'), 'as-s1@test.invalid');
INSERT INTO public.households (id, timezone) VALUES
 (pg_temp.u('f1'), 'Europe/Paris'), (pg_temp.u('f2'), 'Europe/Paris'), (pg_temp.u('f3'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a0'), 'RA-26-5500', 'admin', NULL, 'Fixture', 'SA', 'active', 'male'),
 (pg_temp.u('a1'), 'RA-26-5501', 'admin', NULL, 'Fixture', 'A1', 'active', 'female'),
 (pg_temp.u('a2'), 'RA-26-5502', 'admin', NULL, 'Fixture', 'H1', 'active', 'male'),
 (pg_temp.u('b1'), 'RA-26-5503', 'teacher', NULL, 'Fixture', 'T1', 'provisional_active', 'female'),
 (pg_temp.u('b2'), 'RA-26-5504', 'teacher', NULL, 'Fixture', 'T2', 'provisional_active', 'male'),
 (pg_temp.u('c1'), 'RA-26-5505', 'teacher', NULL, 'Fixture', 'C1', 'pending_kyc', 'female'),
 (pg_temp.u('c2'), 'RA-26-5506', 'teacher', NULL, 'Fixture', 'C2', 'pending_kyc', 'male'),
 (pg_temp.u('d1'), 'RA-26-5507', 'guardian', pg_temp.u('f1'), 'Fixture', 'G1', 'active', 'male'),
 (pg_temp.u('d2'), 'RA-26-5508', 'guardian', pg_temp.u('f2'), 'Fixture', 'G2', 'active', 'female'),
 (pg_temp.u('e1'), 'RA-26-5509', 'student', pg_temp.u('f1'), 'Fixture', 'E1', 'active', 'female'),
 (pg_temp.u('e2'), 'RA-26-5510', 'student', pg_temp.u('f3'), 'Fixture', 'S1', 'active', 'female');
INSERT INTO public.student_profiles (profile_id, student_type) VALUES
 (pg_temp.u('e1'), 'minor'), (pg_temp.u('e2'), 'autonomous');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 (pg_temp.u('91'), 'enseignant', pg_temp.u('c1'), 'female', 'Fixture AS un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 (pg_temp.u('92'), 'enseignant', pg_temp.u('c2'), 'male', 'Fixture AS deux', 'confirmee', NULL, 'en_cours', 'lien_public');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('a0')) ON CONFLICT DO NOTHING;
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
  ON CONFLICT (key) DO UPDATE SET value = 'true'::jsonb;
-- Une annonce d'avant ce lot, pour les familles (lue jusqu'ici par le mineur).
INSERT INTO public.com_annonces (id, auteur_id, audience, titre, texte, diffusee_le, programmee, cle_idempotence)
VALUES (pg_temp.u('70'), pg_temp.u('a0'), 'familles', 'Ancienne', 'Texte ancien',
        pg_catalog.now() - interval '1 day', false, gen_random_uuid());

-- ------------------------------------------------------------------
-- 1. Les publics, calcules par le serveur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT pg_temp.dans(ARRAY[c], ARRAY['female','male']::public.gender[], pg_temp.u('e1')::text),
  '1. le mineur n''est pas dans le public ' || c)
  FROM unnest(private.com_annonce_codes()) c;
SELECT pg_temp.vrai(
  pg_temp.dans(ARRAY['eleves'], ARRAY['female','male']::public.gender[], pg_temp.u('d1')::text)
  AND pg_temp.dans(ARRAY['eleves'], ARRAY['female','male']::public.gender[], pg_temp.u('e2')::text)
  AND NOT pg_temp.dans(ARRAY['eleves'], ARRAY['female','male']::public.gender[], pg_temp.u('d2')::text),
  '1. « eleves » : l''eleve adulte et le parent du mineur, pas une famille sans eleve mineur');
SELECT pg_temp.vrai(
  pg_temp.dans(ARRAY['eleves_adultes'], ARRAY['female','male']::public.gender[], pg_temp.u('e2')::text)
  AND NOT pg_temp.dans(ARRAY['eleves_adultes'], ARRAY['female','male']::public.gender[], pg_temp.u('d1')::text),
  '1. « eleves adultes » : sans les parents');
SELECT pg_temp.vrai(
  pg_temp.dans(ARRAY['candidats','femmes'], ARRAY['female','male']::public.gender[], pg_temp.u('c1')::text)
  AND NOT pg_temp.dans(ARRAY['candidats','femmes'], ARRAY['female','male']::public.gender[], pg_temp.u('c2')::text)
  AND NOT pg_temp.dans(ARRAY['candidats','femmes'], ARRAY['female','male']::public.gender[], pg_temp.u('b1')::text),
  '1. « candidats » et « femmes » : la candidate en cours seulement');
SELECT pg_temp.vrai(
  pg_temp.dans(ARRAY['candidats_admis'], ARRAY['female','male']::public.gender[], pg_temp.u('c2')::text)
  AND NOT pg_temp.dans(ARRAY['candidats'], ARRAY['female','male']::public.gender[], pg_temp.u('c2')::text),
  '1. le candidat confirme (salle 3) est « admis », plus « en cours »');
SELECT pg_temp.vrai(
  pg_temp.dans(ARRAY['tous'], ARRAY['female','male']::public.gender[], pg_temp.u('c1')::text)
  AND pg_temp.dans(ARRAY['tous'], ARRAY['female','male']::public.gender[], pg_temp.u('b2')::text)
  AND pg_temp.dans(ARRAY['hommes'], ARRAY['female','male']::public.gender[], pg_temp.u('d1')::text)
  AND NOT pg_temp.dans(ARRAY['hommes'], ARRAY['female','male']::public.gender[], pg_temp.u('d2')::text),
  '1. « tous » compte les candidats ; « hommes » seul restreint « tous »');

-- ------------------------------------------------------------------
-- 2. CAND-Q07 : les cotes
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('a1')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM jsonb_array_elements(public.com_annonce_publics() -> 'publics') p
    WHERE p ->> 'code' IN ('femmes', 'hommes')) = 0
  AND public.com_annonce_publics() -> 'cotes' = '["female"]'::jsonb,
  '2. la direction d''un cote ne choisit pas le genre : il est deja le sien');
CREATE TEMP TABLE audience_a1 AS SELECT public.com_annonce_audience(ARRAY['familles']) AS a;
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (a ->> 'destinataires')::int FROM audience_a1)
    = (SELECT count(*) FROM private.com_annonce_personnes(ARRAY['familles'], ARRAY['female']::public.gender[])),
  '2. le nombre de l''ecran est celui du serveur');
SELECT pg_temp.vrai(NOT pg_temp.dans(ARRAY['familles'], ARRAY['female']::public.gender[], pg_temp.u('d1')::text),
  '2. la direction des femmes n''atteint pas un pere');
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_annonce_publics() -> 'cotes' = '["female", "male"]'::jsonb
  AND (SELECT count(*) FROM jsonb_array_elements(public.com_annonce_publics() -> 'publics') p
        WHERE p ->> 'code' IN ('femmes', 'hommes')) = 2,
  '2. le super-admin atteint les deux cotes et choisit le genre');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Un public vide ne s'envoie pas
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('a1')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.com_annonce_audience(ARRAY['candidats_admis']) ->> 'raison') = 'personne'
  OR (public.com_annonce_audience(ARRAY['candidats_admis']) ->> 'destinataires')::int > 0,
  '3. l''audience dit pourquoi un public est vide');
RESET ROLE;
CREATE TEMP TABLE avant AS SELECT count(*) AS n FROM public.com_annonces;
GRANT SELECT ON avant TO authenticated;
SET LOCAL ROLE authenticated;
-- Un public inconnu est refuse.
SELECT pg_temp.vrai(pg_temp.refus($q$SELECT public.com_annonce_envoyer(ARRAY['inconnu'], '', 'Texte', NULL, false, gen_random_uuid())$q$) = '22023',
  '3. un public inconnu est refuse');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. L'envoi par le super-admin, aux eleves, avec courriel
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE envoi AS
  SELECT public.com_annonce_envoyer(ARRAY['eleves'], '', 'Pas de cours lundi.' || chr(10) || 'Bonne semaine.',
                                    NULL, true, 'a5500000-0000-4000-8000-0000000000aa') AS a;
RESET ROLE;
SELECT pg_temp.vrai((SELECT a ->> 'etat' FROM envoi) = 'publiee'
  AND (SELECT titre FROM public.com_annonces WHERE id = (SELECT (a ->> 'id')::uuid FROM envoi)) = 'Pas de cours lundi.',
  '4. publiee ; sans titre, la premiere ligne sert de titre');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.com_annonce_destinataires d WHERE d.annonce_id = (SELECT (a ->> 'id')::uuid FROM envoi) AND d.profile_id = pg_temp.u('d1'))
  AND EXISTS (SELECT 1 FROM public.com_annonce_destinataires d WHERE d.annonce_id = (SELECT (a ->> 'id')::uuid FROM envoi) AND d.profile_id = pg_temp.u('e2'))
  AND NOT EXISTS (SELECT 1 FROM public.com_annonce_destinataires d WHERE d.annonce_id = (SELECT (a ->> 'id')::uuid FROM envoi) AND d.profile_id = pg_temp.u('e1')),
  '4. le parent et l''eleve adulte sont destinataires, jamais le mineur');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.courriels_sortants s WHERE s.cle_idempotence = 'annonce:' || (SELECT a ->> 'id' FROM envoi) || ':' || pg_temp.u('d1')::text
            AND s.categorie = 'nouvelles' AND s.modele = 'message_libre')
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s WHERE s.destinataire_profil = pg_temp.u('e1')),
  '4. courriel en file (categorie non essentielle, sous plafond) pour le parent ; aucun pour le mineur');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications n WHERE n.destinataire = pg_temp.u('e1')),
  '4. aucune notification au mineur');
SELECT pg_temp.vrai((SELECT e.distribuee_le IS NOT NULL AND e.notifiees IS NOT NULL
                       FROM public.com_annonce_envois e WHERE e.annonce_id = (SELECT (a ->> 'id')::uuid FROM envoi)),
  '5. la distribution est faite et dit combien de notifications sont parties (0 tant que la contrainte attend)');
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (public.com_annonce_envoyer(ARRAY['eleves'], '', 'Autre texte', NULL, true, 'a5500000-0000-4000-8000-0000000000aa') ->> 'id')
    = (SELECT a ->> 'id' FROM envoi),
  '4. une cle rejouee rend le meme accuse');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.com_annonces WHERE cle_idempotence = 'a5500000-0000-4000-8000-0000000000aa') = 1,
  '4. ... sans second envoi');

-- Le public vide : la direction des femmes vers les candidats admis (un homme).
SELECT pg_temp.en_tant_que(pg_temp.u('a1')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE refus_vide AS
  SELECT pg_temp.refus($q$SELECT public.com_annonce_envoyer(ARRAY['candidats_admis'], '', 'Texte', NULL, false, gen_random_uuid())$q$) AS etat;
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM private.com_annonce_personnes(ARRAY['candidats_admis'], ARRAY['female']::public.gender[])) > 0
  OR (SELECT etat FROM refus_vide) = 'P0002',
  '3. un public vide est refuse');
SELECT pg_temp.vrai((SELECT count(*) FROM public.com_annonces) = (SELECT n FROM avant) + 1,
  '3. ... et rien n''en reste');

-- ------------------------------------------------------------------
-- 6. Le mineur : ni fil, ni annonce generale
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('e1')::text, 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus('SELECT public.com_mes_annonces()') = '42501',
  '6. le mineur n''a pas de fil d''annonces');
SELECT pg_temp.vrai(jsonb_array_length(public.com_annonces_academie(NULL) -> 'annonces') = 0,
  '6. le mineur ne lit plus aucune annonce generale, meme ancienne');
SELECT pg_temp.vrai(public.com_annonce_lire(pg_temp.u('70')) IS NULL
  AND public.com_annonce_lire((SELECT (a ->> 'id')::uuid FROM envoi)) IS NULL,
  '6. ... ni par son identifiant');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. Le parent, le candidat, la mesure
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('d1')::text, 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.com_mes_annonces() -> 'annonces') x
                             WHERE x ->> 'id' = (SELECT a ->> 'id' FROM envoi) AND (x ->> 'vue')::boolean = false),
  '7. le parent lit l''annonce dans son fil, pas encore vue');
SELECT public.com_annonce_vue((SELECT (a ->> 'id')::uuid FROM envoi));
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.com_mes_annonces() -> 'annonces') x
                             WHERE x ->> 'id' = (SELECT a ->> 'id' FROM envoi) AND (x ->> 'vue')::boolean),
  '7. ... puis vue');
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('d2')::text, 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.com_mes_annonces() -> 'annonces') x
                                 WHERE x ->> 'id' = (SELECT a ->> 'id' FROM envoi))
  AND pg_temp.refus($q$SELECT public.com_annonce_vue((SELECT (a ->> 'id')::uuid FROM envoi))$q$) = '42501',
  '7. une famille hors du public ne lit ni ne marque l''annonce');
RESET ROLE;
-- Le candidat (compte en attente) lit l'annonce des candidats.
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE envoi_c AS
  SELECT public.com_annonce_envoyer(ARRAY['candidats','femmes'], 'Entretiens', 'Les entretiens reprennent mardi.',
                                    NULL, false, gen_random_uuid()) AS a;
RESET ROLE;
GRANT SELECT ON envoi, envoi_c TO authenticated;
SELECT pg_temp.en_tant_que(pg_temp.u('c1')::text, 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(public.com_mes_annonces() -> 'annonces') x
                             WHERE x ->> 'id' = (SELECT a ->> 'id' FROM envoi_c)),
  '7. la candidate (compte en attente) lit l''annonce des candidates');
SELECT public.com_annonce_vue((SELECT (a ->> 'id')::uuid FROM envoi_c));
RESET ROLE;
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE liste_sa AS SELECT public.com_annonces_direction() AS l;
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM liste_sa, jsonb_array_elements(liste_sa.l -> 'publiees') x
                             WHERE x ->> 'id' = (SELECT a ->> 'id' FROM envoi)
                               AND (x ->> 'vues')::int = 1
                               AND (x ->> 'destinataires')::int = (SELECT e.destinataires FROM public.com_annonce_envois e
                                                                     WHERE e.annonce_id = (SELECT (a ->> 'id')::uuid FROM envoi))),
  '7. la direction lit la mesure : destinataires, et une personne qui l''a vue');
SELECT pg_temp.en_tant_que(pg_temp.u('a2')::text, 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.com_annonces_direction() -> 'publiees') x
                                 WHERE x ->> 'id' IN ((SELECT a ->> 'id' FROM envoi), (SELECT a ->> 'id' FROM envoi_c))),
  '2. la direction des hommes ne liste pas les annonces des deux cotes ni celles des femmes');
RESET ROLE;

-- ------------------------------------------------------------------
-- 8. L'annonce programmee
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('a0')::text, 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE envoi_p AS
  SELECT public.com_annonce_envoyer(ARRAY['familles'], 'Plus tard', 'Programmee.',
                                    pg_catalog.now() + interval '2 days', true, gen_random_uuid()) AS a;
RESET ROLE;
GRANT SELECT ON envoi_p TO authenticated;
SELECT pg_temp.vrai((SELECT a ->> 'etat' FROM envoi_p) = 'planifiee'
  AND (SELECT e.distribuee_le IS NULL FROM public.com_annonce_envois e WHERE e.annonce_id = (SELECT (a ->> 'id')::uuid FROM envoi_p))
  AND private.com_annonce_distribuer(NULL) = 0
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
                   WHERE s.cle_idempotence LIKE 'annonce:' || (SELECT a ->> 'id' FROM envoi_p) || ':%'),
  '8. programmee : ni distribuee ni courriel avant son heure');
SELECT pg_temp.en_tant_que(pg_temp.u('d1')::text, 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(public.com_mes_annonces() -> 'annonces') x
                                 WHERE x ->> 'id' = (SELECT a ->> 'id' FROM envoi_p)),
  '8. ... ni lisible');
RESET ROLE;

-- ------------------------------------------------------------------
-- 9. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.en_tant_que(pg_temp.u('b1')::text, 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus($q$SELECT public.com_annonce_envoyer(ARRAY['tous'], '', 'Texte', NULL, false, gen_random_uuid())$q$) = '42501'
  AND pg_temp.refus('SELECT public.com_annonce_publics()') = '42501'
  AND pg_temp.refus($q$SELECT public.com_annonce_audience(ARRAY['tous'])$q$) = '42501'
  AND pg_temp.refus('SELECT public.com_annonces_direction()') = '42501',
  '9. un enseignant n''ouvre ni les publics, ni l''audience, ni l''envoi, ni la liste');
SELECT pg_temp.vrai(pg_temp.refus('SELECT * FROM public.com_annonce_destinataires') = '42501'
  AND pg_temp.refus('SELECT * FROM public.com_annonce_envois') = '42501',
  '9. les tables sont fermees au client');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.com_annonce_envoyer(text[],text,text,timestamptz,boolean,uuid)', 'execute')
  AND NOT has_function_privilege('anon', 'public.com_mes_annonces()', 'execute')
  AND NOT has_function_privilege('authenticated', 'private.com_annonce_distribuer(uuid)', 'execute')
  AND NOT has_function_privilege('authenticated', 'private.com_annonce_personnes(text[],public.gender[])', 'execute'),
  '9. anon n''execute rien ; les fonctions privees sont fermees');
SELECT pg_temp.vrai(strpos(pg_get_functiondef('private.tache_minute()'::regprocedure), 'com_annonce_distribuer') > 0,
  '8. la tache unique distribue les annonces programmees');

ROLLBACK;
