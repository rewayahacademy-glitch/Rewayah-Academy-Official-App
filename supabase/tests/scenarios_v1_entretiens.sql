-- V1 (20261107700000 et 20261107700001) : la visio d'entretien, partie serveur.
-- Prouve :
--   1. seule la direction active, de son cote, planifie ; l'intervieweur est
--      de la direction et du genre de la candidature ; la cle rejoue ;
--   2. la seance est un entretien (session_type), ses deux inscrits, l'etat
--      de la candidature suit (entretien_planifie), les capacites sont vraies ;
--   3. le jeton : le candidat `pending_kyc` entre dans SA seance (role
--      candidat, voix et image, pas de canal de donnees, visible) ; un autre
--      candidat est refuse, comme un enseignant non inscrit, le chemin
--      « tuteur pour un eleve », et le candidat dans une seance de cours ;
--   4. consigner : compte rendu obligatoire si tenu, motif si non tenu ;
--      seance terminee ou annulee ; plus de jeton une fois consigne ;
--   5. exclusions : aucune tresorerie a la cloture, ni par consigner ni par la
--      cloture automatique ; aucune vue de famille ni d'eleve ; aucun
--      remplacement ; aucun avis de fin ;
--   6. mes_entretiens : de son cote seulement ; la table n'est pas lisible
--      par un client ; une reunion est admise par la CHECK et n'admet que ses
--      inscrits.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
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
-- Le refus d'un jeton, et son motif.
CREATE FUNCTION pg_temp.jeton_refuse(p_seance uuid, p_qui uuid) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.autoriser_jeton_video(p_seance, p_qui, 'wss://v1.cloud.test', 'wss://v1.auto.test');
  RETURN NULL;
EXCEPTION WHEN insufficient_privilege OR check_violation OR no_data_found THEN
  RETURN SQLERRM;
END $$;
-- La version d'une candidature, lue pour le test (le client ne lit pas la table).
CREATE FUNCTION pg_temp.version_cand(p_id uuid) RETURNS integer
LANGUAGE sql SECURITY DEFINER AS $$ SELECT version FROM public.candidatures WHERE id = p_id $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.version_cand(uuid) TO authenticated;

-- A1, A2 : direction, femmes ; H1 : direction, homme. CF1, CF2 : candidates
-- (compte `pending_kyc`) ; T1 : un enseignant au compte valide ; G1 et son enfant E1.
INSERT INTO auth.users (id, email) VALUES
 ('7e100000-0000-4000-8000-0000000000a1', 'v1-a1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000a2', 'v1-a2@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000b1', 'v1-h1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000c1', 'v1-cf1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000c2', 'v1-cf2@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000d1', 'v1-t1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000e1', 'v1-g1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000e2', 'v1-e1@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('7e100000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e100000-0000-4000-8000-0000000000a1', 'RA-26-7101', 'admin', NULL, 'Amina', 'V1', 'active', 'female'),
 ('7e100000-0000-4000-8000-0000000000a2', 'RA-26-7102', 'admin', NULL, 'Asma', 'V1', 'active', 'female'),
 ('7e100000-0000-4000-8000-0000000000b1', 'RA-26-7103', 'admin', NULL, 'Bilal', 'V1', 'active', 'male'),
 ('7e100000-0000-4000-8000-0000000000c1', 'RA-26-7104', 'teacher', NULL, 'Khadija', 'V1', 'pending_kyc', 'female'),
 ('7e100000-0000-4000-8000-0000000000c2', 'RA-26-7105', 'teacher', NULL, 'Maryam', 'V1', 'pending_kyc', 'female'),
 ('7e100000-0000-4000-8000-0000000000d1', 'RA-26-7106', 'teacher', NULL, 'Yusuf', 'V1', 'provisional_active', 'male'),
 ('7e100000-0000-4000-8000-0000000000e1', 'RA-26-7107', 'guardian', '7e100000-0000-4000-8000-0000000000f1', 'Samir', 'V1', 'active', 'male'),
 ('7e100000-0000-4000-8000-0000000000e2', 'RA-26-7108', 'student', '7e100000-0000-4000-8000-0000000000f1', 'Hakim', 'V1', 'active', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7e100000-0000-4000-8000-000000000101', 'enseignant', '7e100000-0000-4000-8000-0000000000c1', 'female',
  'Fixture V1 un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e100000-0000-4000-8000-000000000102', 'enseignant', '7e100000-0000-4000-8000-0000000000c2', 'female',
  'Fixture V1 deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');

-- ===========================================================================
-- 1. Qui planifie
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $planifier$
DECLARE
  v_r jsonb;
  v_version integer;
BEGIN
  -- L'autre cote : la direction masculine ne planifie pas une candidature de femme.
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
                                    NULL, 1, 'v1-cle-planifier-h1');
  PERFORM pg_temp.vrai(v_r ? 'erreur',
    '1. la direction de l''autre cote ne planifie pas : ' || (v_r ->> 'erreur'));

  -- Un enseignant actif : refuse.
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d1', 'teacher');
  BEGIN
    PERFORM public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
                                       NULL, 1, 'v1-cle-planifier-t1');
    RAISE EXCEPTION 'ROUGE : 1. un enseignant a planifie un entretien';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 1. un enseignant ne planifie pas (CAND-Q19)';
  END;

  -- Un intervieweur de l'autre genre : refuse.
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
                                    '7e100000-0000-4000-8000-0000000000b1', 1, 'v1-cle-planifier-a1-h1');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'intervieweur_non_autorise',
    '1. l''intervieweur est du genre de la candidature');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 200,
                                    NULL, 1, 'v1-cle-planifier-a1-duree');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'duree_invalide', '1. une duree hors bornes est refusee');

  -- A1 planifie, A2 mene l'entretien.
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
                                    '7e100000-0000-4000-8000-0000000000a2', 1, 'v1-cle-planifier-a1');
  PERFORM pg_temp.vrai(v_r -> 'entretien' ? 'sessionId',
    '1. la direction de son cote planifie : ' || coalesce(v_r::text, 'null'));
  PERFORM pg_temp.vrai(public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day',
                         45, '7e100000-0000-4000-8000-0000000000a2', 1, 'v1-cle-planifier-a1')
                       -> 'entretien' ->> 'sessionId' = v_r -> 'entretien' ->> 'sessionId',
    '1. la meme cle rejoue le meme entretien');
  v_version := pg_temp.version_cand('7e100000-0000-4000-8000-000000000101');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '2 days', 45,
                                    NULL, v_version, 'v1-cle-planifier-a1-bis');
  PERFORM pg_temp.vrai(v_r ? 'erreur', '1. un second entretien ouvert est refuse : ' || (v_r ->> 'erreur'));

  -- 2. Les capacites.
  PERFORM pg_temp.vrai((public.capacites_candidatures() -> 'gestes' ->> 'planifierEntretien')::boolean
                       AND (public.capacites_candidatures() -> 'gestes' ->> 'consignerEntretien')::boolean
                       AND (public.capacites_candidatures() ->> 'peutMenerEntretien')::boolean,
    '2. planifierEntretien, consignerEntretien et peutMenerEntretien vrais pour la direction');
END
$planifier$;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT s.session_type = 'entretien' AND s.teacher_id = '7e100000-0000-4000-8000-0000000000a2'
          AND s.groupe_id IS NULL AND s.status = 'planned'
     FROM public.entretiens e JOIN public.sessions s ON s.id = e.session_id
    WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000101')
  AND (SELECT pg_catalog.array_agg(sp.role::text ORDER BY sp.role::text)
         FROM public.entretiens e JOIN public.session_participants sp ON sp.session_id = e.session_id
        WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000101') = ARRAY['admin_visible', 'candidat']
  AND (SELECT etat FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000101') = 'entretien_planifie'
  AND EXISTS (SELECT 1 FROM public.candidature_evenements ev
               WHERE ev.candidature_id = '7e100000-0000-4000-8000-000000000101' AND ev.type = 'entretien'),
  '2. une seance entretien sans Classe, l''intervieweur et la candidate inscrits, etat et journal suivis');

-- ===========================================================================
-- 3. Le jeton
-- ===========================================================================
-- L'entretien est avance a maintenant (sa fenetre d'ouverture).
UPDATE public.sessions s SET started_at = now() - interval '5 minutes', ended_at = now() + interval '40 minutes',
                             join_opens_at = now() - interval '15 minutes'
  FROM public.entretiens e
 WHERE e.session_id = s.id AND e.candidature_id = '7e100000-0000-4000-8000-000000000101';
-- Une seance de cours ou la candidate s'inscrirait comme candidat.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000d1',
        now() - interval '5 minutes', now() + interval '40 minutes', 'planned', 'standard',
        now() - interval '15 minutes');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
 ('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000c1', 'candidat'),
 ('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000e2', 'candidat');

DO $jeton$
DECLARE
  v_seance uuid := (SELECT session_id FROM public.entretiens
                     WHERE candidature_id = '7e100000-0000-4000-8000-000000000101');
  v_j jsonb;
  v_motif text;
BEGIN
  v_j := public.autoriser_jeton_video(v_seance, '7e100000-0000-4000-8000-0000000000c1',
                                      'wss://v1.cloud.test', 'wss://v1.auto.test');
  PERFORM pg_temp.vrai(v_j ->> 'role' = 'candidat'
                       AND (v_j -> 'capabilities' ->> 'can_publish')::boolean
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'can_publish_data')::boolean, false)
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'hidden')::boolean, false),
    '3. la candidate pending_kyc entre dans SA seance : candidat, voix et image, sans donnees, visible : '
    || coalesce(v_j -> 'capabilities', 'null'::jsonb)::text);
  PERFORM pg_temp.vrai(public.autoriser_jeton_video(v_seance, '7e100000-0000-4000-8000-0000000000a2',
                         'wss://v1.cloud.test', 'wss://v1.auto.test') ->> 'role' = 'admin_visible',
    '3. l''intervieweuse entre (admin_visible)');

  v_motif := pg_temp.jeton_refuse(v_seance, '7e100000-0000-4000-8000-0000000000c2');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '3. jeton refuse a une autre candidate : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse(v_seance, '7e100000-0000-4000-8000-0000000000d1');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '3. jeton refuse a un enseignant non inscrit : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse(v_seance, '7e100000-0000-4000-8000-0000000000a1');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '3. jeton refuse a la direction non inscrite : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL,
    '3. le role candidat ne vaut rien dans une seance de cours : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000e2');
  PERFORM pg_temp.vrai(v_motif = 'non inscrit a cette seance',
    '3. meme un compte valide, inscrit candidat dans un cours, est refuse : ' || coalesce(v_motif, 'accorde'));
  BEGIN
    PERFORM public.autoriser_jeton_video_eleve(v_seance, '7e100000-0000-4000-8000-0000000000e1',
      '7e100000-0000-4000-8000-0000000000e2', 'wss://v1.cloud.test', 'wss://v1.auto.test');
    RAISE EXCEPTION 'ROUGE : 3. le chemin tuteur a ouvert un entretien';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 3. le chemin « tuteur pour un eleve » refuse un entretien';
  END;
END
$jeton$;

-- ===========================================================================
-- 4. et 5. Consigner, puis les exclusions
-- ===========================================================================
SELECT set_config('v1.seance', (SELECT session_id::text FROM public.entretiens
                                  WHERE candidature_id = '7e100000-0000-4000-8000-000000000101'), true);
SET LOCAL ROLE authenticated;
DO $consigner$
DECLARE
  v_seance uuid := current_setting('v1.seance')::uuid;
  v_version integer := pg_temp.version_cand('7e100000-0000-4000-8000-000000000101');
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a2', 'admin');
  v_r := public.consigner_entretien(v_seance, true, '   ', NULL, v_version, 'v1-cle-consigner-vide');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'compte_rendu_requis', '4. tenu sans compte rendu : refuse');
  v_r := public.consigner_entretien(v_seance, true, 'Recitation solide, tajwid a revoir.', NULL, v_version,
                                    'v1-cle-consigner-tenu');
  PERFORM pg_temp.vrai(NOT v_r ? 'erreur', '4. tenu avec compte rendu : consigne');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.mes_entretiens()) = 0,
    '6. mes_entretiens : rien de l''autre cote');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.mes_entretiens() m WHERE m.issue = 'tenu' AND NOT m.par_moi) = 1,
    '6. mes_entretiens : l''entretien de son cote, mene par une autre');
  -- Aucun droit client (vrai apres la migration) ; et si un droit de table
  -- traine (scenarios adm04 et adm05 accordent tout sans annuler, dans la
  -- batterie en une base), la RLS sans politique ne rend aucune ligne.
  BEGIN
    PERFORM pg_temp.vrai((SELECT count(*) FROM public.entretiens) = 0,
      '6. la table entretiens ne rend aucune ligne a un client (RLS sans politique)');
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 6. la table entretiens n''est pas lisible par un client';
  END;
  -- Les vues de la candidate et d'une famille : rien.
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000e1', 'guardian');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v WHERE session_id = v_seance),
    '5. aucune vue de famille ne porte l''entretien');
END
$consigner$;
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT s.status = 'ended' FROM public.sessions s WHERE s.id =
     (SELECT session_id FROM public.entretiens WHERE candidature_id = '7e100000-0000-4000-8000-000000000101'))
  AND (SELECT etat FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000101') = 'decision_en_attente',
  '4. tenu : seance terminee, candidature en decision');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre t, public.entretiens e
               WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000101' AND t.source_id = e.session_id::text)
  AND NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements t, public.entretiens e
               WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000101' AND t.source_id = e.session_id::text),
  '5. aucune tresorerie a la cloture d''un entretien');
SELECT pg_temp.vrai(
  pg_temp.jeton_refuse((SELECT session_id FROM public.entretiens
                         WHERE candidature_id = '7e100000-0000-4000-8000-000000000101'),
                       '7e100000-0000-4000-8000-0000000000c1') IS NOT NULL,
  '4. plus de jeton une fois l''entretien consigne');

-- Non tenu : motif obligatoire, seance annulee, retour a « a planifier ».
SET LOCAL ROLE authenticated;
DO $non_tenu$
DECLARE
  v_r jsonb;
  v_seance uuid;
  v_version integer;
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000102', now() + interval '3 days', 30,
                                    NULL, 1, 'v1-cle-planifier-c2');
  v_seance := (v_r -> 'entretien' ->> 'sessionId')::uuid;
  v_version := pg_temp.version_cand('7e100000-0000-4000-8000-000000000102');
  v_r := public.consigner_entretien(v_seance, false, NULL, NULL, v_version, 'v1-cle-non-tenu-sans-motif');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'motif_requis', '4. non tenu sans motif : refuse');
  v_r := public.consigner_entretien(v_seance, false, NULL, 'La candidate ne s''est pas presentee.', v_version,
                                    'v1-cle-non-tenu');
  PERFORM pg_temp.vrai(NOT v_r ? 'erreur', '4. non tenu avec motif : consigne');
END
$non_tenu$;
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT s.status = 'canceled' FROM public.entretiens e JOIN public.sessions s ON s.id = e.session_id
    WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000102')
  AND (SELECT etat FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000102') = 'entretien_a_planifier',
  '4. non tenu : seance annulee, entretien a replanifier');

-- La cloture automatique d'un entretien passe sans tresorerie ni remplacement.
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.planifier_entretien('7e100000-0000-4000-8000-000000000102', now() + interval '4 days', 30,
                      NULL, pg_temp.version_cand('7e100000-0000-4000-8000-000000000102'),
                      'v1-cle-planifier-c2-bis') -> 'entretien' ? 'sessionId',
  '5. un entretien a replanifier se replanifie');
RESET ROLE;
SELECT pg_temp.personne();
UPDATE public.sessions s SET join_opens_at = now() - interval '4 hours', started_at = now() - interval '3 hours',
                             ended_at = now() - interval '2 hours'
  FROM public.entretiens e
 WHERE e.session_id = s.id AND e.candidature_id = '7e100000-0000-4000-8000-000000000102' AND e.issue IS NULL;
INSERT INTO public.session_events (session_id, profile_id, event_type, server_ts, source)
SELECT e.session_id, '7e100000-0000-4000-8000-0000000000a1', 'joined', now() - interval '175 minutes', 'livekit_webhook'
  FROM public.entretiens e WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000102' AND e.issue IS NULL;
UPDATE public.sessions s SET status = 'preflight'
  FROM public.entretiens e WHERE e.session_id = s.id AND e.candidature_id = '7e100000-0000-4000-8000-000000000102' AND e.issue IS NULL;
UPDATE public.sessions s SET status = 'in_progress'
  FROM public.entretiens e WHERE e.session_id = s.id AND e.candidature_id = '7e100000-0000-4000-8000-000000000102' AND e.issue IS NULL;
SELECT private.ses_cloturer_seances_echues(now());
SELECT pg_temp.vrai(
  (SELECT s.status = 'ended' FROM public.entretiens e JOIN public.sessions s ON s.id = e.session_id
    WHERE e.candidature_id = '7e100000-0000-4000-8000-000000000102' AND e.issue IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre t JOIN public.entretiens e ON t.source_id = e.session_id::text)
  AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation r JOIN public.entretiens e ON r.session_id = e.session_id),
  '5. cloture automatique : ni tresorerie, ni remplacement');
SELECT set_config('v1.entretiens', (SELECT string_agg(session_id::text, ',') FROM public.entretiens), true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d1', 'teacher');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_enseignant_v v
                                 WHERE v.session_id::text = ANY (string_to_array(current_setting('v1.entretiens'), ','))),
  '5. aucun entretien dans les vues d''un enseignant');
RESET ROLE;
SELECT pg_temp.personne();

-- ===========================================================================
-- 6. Une reunion : la CHECK l'admet ; seuls ses inscrits entrent
-- ===========================================================================
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('7e100000-0000-4000-8000-000000000301', '7e100000-0000-4000-8000-0000000000a1',
        now() - interval '5 minutes', now() + interval '40 minutes', 'planned', 'reunion',
        now() - interval '15 minutes');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
 ('7e100000-0000-4000-8000-000000000301', '7e100000-0000-4000-8000-0000000000a2', 'admin_visible');
SELECT pg_temp.vrai(
  public.autoriser_jeton_video('7e100000-0000-4000-8000-000000000301', '7e100000-0000-4000-8000-0000000000a2',
                               'wss://v1.cloud.test', 'wss://v1.auto.test') ->> 'role' = 'admin_visible'
  AND pg_temp.jeton_refuse('7e100000-0000-4000-8000-000000000301', '7e100000-0000-4000-8000-0000000000a1') IS NOT NULL
  AND pg_temp.jeton_refuse('7e100000-0000-4000-8000-000000000301', '7e100000-0000-4000-8000-0000000000d1') IS NOT NULL,
  '6. reunion : l''inscrite entre ; la titulaire de teacher_id non inscrite et un enseignant, non');
DO $check$
BEGIN
  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type)
  VALUES ('7e100000-0000-4000-8000-0000000000a1', now() + interval '1 day', now() + interval '25 hours',
          'planned', 'webinaire');
  RAISE EXCEPTION 'ROUGE : 6. un type de seance inconnu est admis';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'OK 6. la CHECK refuse un type inconnu';
END
$check$;

ROLLBACK;
