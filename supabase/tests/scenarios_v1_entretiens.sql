-- V1-a (20261107700000, 20261108000000 et 20261108000001) et V1-a-bis
-- (20261109100000, le super-admin des deux cotes) : la visio
-- d'entretien, plusieurs intervieweurs, fondateurs comptes, cote impose.
-- Prouve :
--   0. aucun inscrit n'emploie le role `intervieweur` avant ce lot ; les
--      reglages sont semes et valides ;
--   1. la coche fondateur (direction active, personnel actif seulement) ; la
--      liste du personnel de son cote (CAND-Q07, exception super-admin) ;
--   2. planifier : direction de son cote ; participants choisis librement dans
--      le personnel actif, du cote de la candidature (super-admin admis tant
--      que l'exception est active) ; au moins N fondateurs, phrase claire ;
--      la regle desactivee ne verifie plus rien ; la cle rejoue ;
--   3. ajouter et retirer un participant : cote impose, jamais sous le minimum
--      de fondateurs, jamais le dernier ;
--   4. le jeton : candidate `pending_kyc` dans SA seance ; intervieweurs
--      inscrits (voix, image, nommes, sans canal de donnees) ; refus a une
--      autre candidate, a un participant retire, a la direction non inscrite,
--      au role intervieweur dans un cours, au chemin tuteur ;
--   5. comptes rendus : un par participant, apres le debut, du cote ; la
--      direction les lit tous, un participant le sien ; journal des presents ;
--   6. consigner : tenu exige un compte rendu, non tenu un motif ; la
--      conclusion pour la salle 3 (STABLE, sans droit client) ;
--   7. exclusions : aucune tresorerie, aucune vue d'enseignant ni de famille,
--      aucun remplacement ; mes_entretiens par cote et par participation ;
--      tables illisibles par un client ; une reunion n'admet que ses inscrits.
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
-- Les super-admins (0088), lus pour le test.
CREATE FUNCTION pg_temp.super_admins() RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER AS $$ SELECT profile_id FROM private.super_admin_kyc $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.version_cand(uuid), pg_temp.super_admins() TO authenticated;

-- 0. Avant tout geste.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.session_participants WHERE role::text = 'intervieweur'),
  '0. aucun inscrit n''emploie le role intervieweur avant ce lot');
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'entretiens.fondateurs_minimum') = '2'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'entretiens.regle_fondateurs_active') = 'true'::jsonb,
  '0. reglages semes : 2 fondateurs, regle active');
DO $reglages$
BEGIN
  BEGIN
    UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'entretiens.fondateurs_minimum';
    RAISE EXCEPTION 'ROUGE : 0. un minimum de 0 fondateur est admis';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'OK 0. le minimum de fondateurs est un entier de 1 a 99';
  END;
  BEGIN
    UPDATE public.app_config SET value = '"oui"'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
    RAISE EXCEPTION 'ROUGE : 0. la regle admet autre chose qu''un booleen';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'OK 0. la regle des fondateurs est oui ou non';
  END;
END
$reglages$;

-- A1, A2 : direction, femmes ; H1 : direction, homme ; SA : super-admin
-- (homme, 0088) ; T2 : enseignante active ; T1 : enseignant provisoire ;
-- CF1, CF2 : candidates (`pending_kyc`) ; G1 et son enfant E1.
INSERT INTO auth.users (id, email) VALUES
 ('7e100000-0000-4000-8000-0000000000a1', 'v1-a1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000a2', 'v1-a2@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000b1', 'v1-h1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000b2', 'v1-sa@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000c1', 'v1-cf1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000c2', 'v1-cf2@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000d1', 'v1-t1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000d2', 'v1-t2@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000e1', 'v1-g1@test.invalid'),
 ('7e100000-0000-4000-8000-0000000000e2', 'v1-e1@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('7e100000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e100000-0000-4000-8000-0000000000a1', 'RA-26-7101', 'admin', NULL, 'Amina', 'V1', 'active', 'female'),
 ('7e100000-0000-4000-8000-0000000000a2', 'RA-26-7102', 'admin', NULL, 'Asma', 'V1', 'active', 'female'),
 ('7e100000-0000-4000-8000-0000000000b1', 'RA-26-7103', 'admin', NULL, 'Bilal', 'V1', 'active', 'male'),
 ('7e100000-0000-4000-8000-0000000000b2', 'RA-26-7109', 'admin', NULL, 'Sami', 'V1', 'active', 'male'),
 ('7e100000-0000-4000-8000-0000000000c1', 'RA-26-7104', 'teacher', NULL, 'Khadija', 'V1', 'pending_kyc', 'female'),
 ('7e100000-0000-4000-8000-0000000000c2', 'RA-26-7105', 'teacher', NULL, 'Maryam', 'V1', 'pending_kyc', 'female'),
 ('7e100000-0000-4000-8000-0000000000d1', 'RA-26-7106', 'teacher', NULL, 'Yusuf', 'V1', 'provisional_active', 'male'),
 ('7e100000-0000-4000-8000-0000000000d2', 'RA-26-7110', 'teacher', NULL, 'Hafsa', 'V1', 'provisional_active', 'female'),
 ('7e100000-0000-4000-8000-0000000000e1', 'RA-26-7107', 'guardian', '7e100000-0000-4000-8000-0000000000f1', 'Samir', 'V1', 'active', 'male'),
 ('7e100000-0000-4000-8000-0000000000e2', 'RA-26-7108', 'student', '7e100000-0000-4000-8000-0000000000f1', 'Hakim', 'V1', 'active', 'male');
-- T2 passe active apres signature (meme fixture que scenarios_af_l1_05).
INSERT INTO public.teacher_profiles (profile_id) VALUES ('7e100000-0000-4000-8000-0000000000d2');
DO $fixture_t2$
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM public.signer_contrat((SELECT version FROM public.contract_texts
                                  WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current), 'Fixture V1-a');
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('7e100000-0000-4000-8000-0000000000d2', 'recording_and_control_notice',
          (SELECT version FROM public.contract_required_versions WHERE contract_kind = 'recording_and_control_notice'))
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('7e100000-0000-4000-8000-0000000000d2', 'teacher_conduct_code', public.code_conduite_version_requise())
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  UPDATE public.profiles SET account_status = 'active' WHERE id = '7e100000-0000-4000-8000-0000000000d2';
  PERFORM pg_temp.personne();
END
$fixture_t2$;
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('7e100000-0000-4000-8000-0000000000b2');
INSERT INTO auth.users (id, email) VALUES ('7e100000-0000-4000-8000-0000000000c3', 'v1-cf3@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e100000-0000-4000-8000-0000000000c3', 'RA-26-7111', 'teacher', NULL, 'Zaynab', 'V1', 'pending_kyc', 'female');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7e100000-0000-4000-8000-000000000101', 'enseignant', '7e100000-0000-4000-8000-0000000000c1', 'female',
  'Fixture V1 un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e100000-0000-4000-8000-000000000102', 'enseignant', '7e100000-0000-4000-8000-0000000000c2', 'female',
  'Fixture V1 deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e100000-0000-4000-8000-000000000103', 'enseignant', '7e100000-0000-4000-8000-0000000000c3', 'female',
  'Fixture V1 trois', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');

-- ===========================================================================
-- 1. Les fondateurs et le personnel
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $fondateurs$
DECLARE
  v_ids uuid[];
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d2', 'teacher');
  BEGIN
    PERFORM public.poser_fondateur('7e100000-0000-4000-8000-0000000000d2', true);
    RAISE EXCEPTION 'ROUGE : 1. une enseignante s''est cochee fondatrice';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 1. seule la direction tient la coche fondateur';
  END;
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  BEGIN
    PERFORM public.poser_fondateur('7e100000-0000-4000-8000-0000000000c1', true);
    RAISE EXCEPTION 'ROUGE : 1. une candidate a ete cochee fondatrice';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'OK 1. une candidate (pending_kyc) ne peut pas etre fondatrice';
  END;
  PERFORM pg_temp.vrai(public.poser_fondateur('7e100000-0000-4000-8000-0000000000a2', true)
    AND public.poser_fondateur('7e100000-0000-4000-8000-0000000000d2', true)
    AND public.poser_fondateur('7e100000-0000-4000-8000-0000000000b2', true)
    AND public.poser_fondateur('7e100000-0000-4000-8000-0000000000a1', true)
    AND NOT public.poser_fondateur('7e100000-0000-4000-8000-0000000000a1', false),
    '1. la direction coche A2, T2 et SA, coche puis decoche A1 (sans effacer)');
  -- Les seules personnes de ce scenario (une batterie en une base en laisse d'autres).
  SELECT pg_catalog.array_agg(profile_id ORDER BY profile_id) INTO v_ids FROM public.personnel_entretiens()
   WHERE profile_id::text LIKE '7e100000-%';
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.personnel_entretiens() pe
                                     JOIN public.profiles p ON p.id = pe.profile_id
                                    WHERE p.gender <> 'female'
                                      AND NOT EXISTS (SELECT 1 FROM pg_temp.super_admins() s WHERE s = pe.profile_id)),
    '1. personnel de son cote : aucun homme hors un super-admin (exception 0088)');
  PERFORM pg_temp.vrai(v_ids = ARRAY['7e100000-0000-4000-8000-0000000000a1', '7e100000-0000-4000-8000-0000000000a2',
                                     '7e100000-0000-4000-8000-0000000000b2', '7e100000-0000-4000-8000-0000000000d2']::uuid[],
    '1. personnel de son cote : A1, A2, T2 et le super-admin ; ni H1, ni T1 provisoire : ' || v_ids::text);
  PERFORM pg_temp.vrai((SELECT fondateur FROM public.personnel_entretiens() WHERE profile_id = '7e100000-0000-4000-8000-0000000000a2')
    AND NOT (SELECT fondateur FROM public.personnel_entretiens() WHERE profile_id = '7e100000-0000-4000-8000-0000000000a1'),
    '1. la liste porte la coche');
  PERFORM pg_temp.vrai((public.capacites_candidatures() ->> 'peutChoisirParticipants')::boolean
    AND (public.capacites_candidatures() ->> 'peutPoserFondateur')::boolean
    AND (public.capacites_candidatures() ->> 'fondateursExiges')::integer = 2
    AND (public.capacites_candidatures() -> 'gestes' ->> 'planifierEntretien')::boolean
    AND (public.capacites_candidatures() -> 'gestes' ->> 'consignerEntretien')::boolean,
    '1. capacites : choisir les participants, poser la coche, 2 fondateurs exiges');
  -- La salle 3 (20261108300000) n'est jamais defaite par la retouche V1-a.
  PERFORM pg_temp.vrai(public.capacites_candidatures() -> 'gestes' -> 'validerPiece'
                       = public.capacites_candidatures() -> 'peutDecider',
    '1. capacites : validerPiece suit toujours peutDecider (salle 3)');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d2', 'teacher');
  BEGIN
    PERFORM public.personnel_entretiens();
    RAISE EXCEPTION 'ROUGE : 1. une enseignante a lu la liste du personnel';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 1. la liste du personnel est reservee a la direction';
  END;
END
$fondateurs$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.personnel_fondateurs) = 4
  AND NOT (SELECT fondateur FROM public.personnel_fondateurs WHERE profile_id = '7e100000-0000-4000-8000-0000000000a1'),
  '1. decocher garde la ligne a faux');

-- ===========================================================================
-- 2. Planifier
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $planifier$
DECLARE
  v_r jsonb;
  v_version integer;
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2']::uuid[], 1, 'v1-cle-h1');
  PERFORM pg_temp.vrai(v_r ? 'erreur', '2. la direction de l''autre cote ne planifie pas : ' || (v_r ->> 'erreur'));

  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d2', 'teacher');
  BEGIN
    PERFORM public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
              ARRAY['7e100000-0000-4000-8000-0000000000a2']::uuid[], 1, 'v1-cle-t2');
    RAISE EXCEPTION 'ROUGE : 2. une enseignante a planifie un entretien';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 2. une enseignante ne planifie pas (CAND-Q19)';
  END;

  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2',
                 '7e100000-0000-4000-8000-0000000000b1']::uuid[], 1, 'v1-cle-a1-h1');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'participant_autre_cote'
                       AND v_r ->> 'profil' = '7e100000-0000-4000-8000-0000000000b1',
    '2. CAND-Q07 : un participant de l''autre cote est refuse par le serveur');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d1']::uuid[], 1, 'v1-cle-a1-t1');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'participant_non_autorise',
    '2. un compte provisoire n''est pas du personnel actif');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000c2']::uuid[], 1, 'v1-cle-a1-c2');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'participant_non_autorise', '2. une autre candidate n''est pas participante');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a1', '7e100000-0000-4000-8000-0000000000a2']::uuid[], 1, 'v1-cle-a1-1f');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'fondateurs_insuffisants' AND (v_r ->> 'exiges')::integer = 2
                       AND (v_r ->> 'presents')::integer = 1
                       AND v_r ->> 'message' = 'Il faut au moins 2 fondateurs parmi les participants (1 choisi).',
    '2. moins de 2 fondateurs : refus avec une phrase claire : ' || coalesce(v_r ->> 'message', v_r::text));
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           '{}'::uuid[], 1, 'v1-cle-a1-vide');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'participants_requis', '2. au moins un participant');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 200,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2']::uuid[], 1, 'v1-cle-a1-duree');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'duree_invalide', '2. une duree hors bornes est refusee');

  -- A1 planifie : deux fondatrices (A2, T2) et le super-admin, sans y etre elle-meme.
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2',
                 '7e100000-0000-4000-8000-0000000000b2']::uuid[], 1, 'v1-cle-a1');
  PERFORM pg_temp.vrai(v_r -> 'entretien' ? 'sessionId' AND (v_r -> 'entretien' ->> 'fondateurs')::integer = 3,
    '2. deux fondatrices et le super-admin (exception 0088) : planifie : ' || coalesce(v_r::text, 'null'));
  PERFORM pg_temp.vrai(public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2']::uuid[], 1, 'v1-cle-a1')
         -> 'entretien' ->> 'sessionId' = v_r -> 'entretien' ->> 'sessionId',
    '2. la meme cle rejoue le meme entretien');
  v_version := pg_temp.version_cand('7e100000-0000-4000-8000-000000000101');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000101', now() + interval '2 days', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2']::uuid[], v_version, 'v1-cle-a1-bis');
  PERFORM pg_temp.vrai(v_r ? 'erreur', '2. un second entretien ouvert est refuse : ' || (v_r ->> 'erreur'));
END
$planifier$;
RESET ROLE;

SELECT set_config('v1.seance', (SELECT session_id::text FROM public.entretiens
                                  WHERE candidature_id = '7e100000-0000-4000-8000-000000000101'), true);
SELECT pg_temp.vrai(
  (SELECT s.session_type = 'entretien' AND s.teacher_id = '7e100000-0000-4000-8000-0000000000a1'
          AND s.groupe_id IS NULL AND s.status = 'planned'
     FROM public.sessions s WHERE s.id = current_setting('v1.seance')::uuid)
  AND (SELECT pg_catalog.array_agg(sp.role::text ORDER BY sp.role::text, sp.profile_id)
         FROM public.session_participants sp WHERE sp.session_id = current_setting('v1.seance')::uuid)
      = ARRAY['candidat', 'intervieweur', 'intervieweur', 'intervieweur']
  AND (SELECT count(*) FILTER (WHERE fondateur) FROM public.entretien_participants
        WHERE session_id = current_setting('v1.seance')::uuid) = 3
  AND (SELECT etat FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000101') = 'entretien_planifie'
  AND EXISTS (SELECT 1 FROM public.candidature_evenements ev
               WHERE ev.candidature_id = '7e100000-0000-4000-8000-000000000101' AND ev.type = 'entretien'),
  '2. seance entretien sans Classe (teacher_id = la direction qui planifie), trois intervieweurs et la candidate, etat et journal suivis');

-- Sans l'exception super-admin, le super-admin n'est plus admis.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'kyc_exception_super_admin';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.planifier_entretien('7e100000-0000-4000-8000-000000000102', now() + interval '1 day', 45,
         ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2',
               '7e100000-0000-4000-8000-0000000000b2']::uuid[], 1, 'v1-cle-sans-exception') ->> 'erreur' = 'participant_autre_cote',
  '2. exception super-admin desactivee : le super-admin est refuse');
RESET ROLE;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'kyc_exception_super_admin';

-- La regle desactivee : une seule participante, non fondatrice, suffit.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.capacites_candidatures() -> 'fondateursExiges' = 'null'::jsonb,
  '2. regle desactivee : aucun minimum annonce');
SELECT pg_temp.vrai(public.planifier_entretien('7e100000-0000-4000-8000-000000000102', now() + interval '3 days', 30,
         ARRAY['7e100000-0000-4000-8000-0000000000a1']::uuid[], 1, 'v1-cle-regle-off') -> 'entretien' ? 'sessionId',
  '2. regle desactivee : aucune verification des fondateurs');
RESET ROLE;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
SELECT set_config('v1.seance2', (SELECT session_id::text FROM public.entretiens
                                   WHERE candidature_id = '7e100000-0000-4000-8000-000000000102'), true);

-- ===========================================================================
-- 2 bis. V1-a-bis (20261109100000), directeur, 03/11 vers 20:30 : le super-admin (homme) agit des deux
-- cotes ; une direction homme non super-admin, non ; un participant homme sur
-- une candidate, jamais (CAND-Q07)
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $super_admin$
DECLARE
  v_r jsonb;
  v_seance uuid;
  v_ids uuid[];
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000103', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2']::uuid[], 1, 'v1-cle-sa-h1');
  PERFORM pg_temp.vrai(v_r ? 'erreur' AND NOT v_r ? 'entretien',
    '2 bis. direction homme non super-admin sur une candidate : refuse : ' || (v_r ->> 'erreur'));
  BEGIN
    PERFORM public.personnel_pour_entretien('7e100000-0000-4000-8000-000000000103');
    RAISE EXCEPTION 'ROUGE : 2 bis. une direction homme a lu le personnel d''une candidate';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 2 bis. la liste du personnel d''une candidate est refusee a une direction homme non super-admin';
  END;

  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b2', 'admin');
  SELECT pg_catalog.array_agg(profile_id ORDER BY profile_id) INTO v_ids
    FROM public.personnel_pour_entretien('7e100000-0000-4000-8000-000000000103') WHERE profile_id::text LIKE '7e100000-%';
  PERFORM pg_temp.vrai(v_ids = ARRAY['7e100000-0000-4000-8000-0000000000a1', '7e100000-0000-4000-8000-0000000000a2',
                                     '7e100000-0000-4000-8000-0000000000b2', '7e100000-0000-4000-8000-0000000000d2']::uuid[],
    '2 bis. le super-admin lit le personnel du cote de la candidate (et lui-meme), pas celui de son cote : ' || v_ids::text);
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000103', now() + interval '1 day', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000b1']::uuid[], 1, 'v1-cle-sa-hp');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'participant_autre_cote',
    '2 bis. meme pour le super-admin, un participant homme sur une candidate est refuse (CAND-Q07)');
  -- V1-c (20261109800000) : A2 et T2 sont deja dans un entretien a J+1 ; une
  -- personne n'est jamais dans deux entretiens qui se chevauchent, celui-ci
  -- se pose donc a J+4.
  v_r := public.planifier_entretien('7e100000-0000-4000-8000-000000000103', now() + interval '4 days', 45,
           ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2']::uuid[], 1, 'v1-cle-sa');
  PERFORM pg_temp.vrai(v_r -> 'entretien' ? 'sessionId',
    '2 bis. le super-admin (homme) planifie l''entretien d''une candidate : ' || coalesce(v_r::text, 'null'));
  v_seance := (v_r -> 'entretien' ->> 'sessionId')::uuid;
  PERFORM pg_temp.vrai(public.ajouter_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000b1')
                       ->> 'erreur' = 'participant_autre_cote',
    '2 bis. le super-admin n''ajoute pas un homme a l''entretien d''une candidate');
  PERFORM pg_temp.vrai(NOT public.ajouter_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000a1') ? 'erreur',
    '2 bis. le super-admin ajoute une participante');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.mes_entretiens() WHERE session_id = v_seance) = 1,
    '2 bis. le super-admin voit l''entretien de l''autre cote');
  v_r := public.consigner_entretien(v_seance, 'annule', 'Reporte par la direction.',
           pg_temp.version_cand('7e100000-0000-4000-8000-000000000103'), 'v1-cle-sa-annule');
  PERFORM pg_temp.vrai(NOT v_r ? 'erreur', '2 bis. le super-admin consigne l''issue : ' || v_r::text);
  PERFORM set_config('v1.seance_sa', v_seance::text, true);
END
$super_admin$;
RESET ROLE;
-- Decider la candidature d'une femme (garde-cap, 03/11 20:40 : tous les
-- gestes de la direction) : la mettre en pause.
SET LOCAL ROLE authenticated;
DO $decider$
DECLARE
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  v_r := public.mettre_en_pause_candidat('7e100000-0000-4000-8000-000000000103', 'Pause de test.', 'pause_general',
           NULL, pg_temp.version_cand('7e100000-0000-4000-8000-000000000103'), 'v1-cle-pause-h1');
  PERFORM pg_temp.vrai(v_r ? 'erreur' OR v_r IS NULL OR NOT v_r ? 'candidature',
    '2 bis. direction homme non super-admin : ne decide pas la candidature d''une femme : ' || coalesce(v_r::text, 'null'));
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b2', 'admin');
  v_r := public.mettre_en_pause_candidat('7e100000-0000-4000-8000-000000000103', 'Pause de test.', 'pause_general',
           NULL, pg_temp.version_cand('7e100000-0000-4000-8000-000000000103'), 'v1-cle-pause-sa');
  PERFORM pg_temp.vrai(NOT v_r ? 'erreur',
    '2 bis. le super-admin (homme) decide la candidature d''une femme (mise en pause) : ' || coalesce(v_r::text, 'null'));
END
$decider$;
RESET ROLE;
SELECT pg_temp.vrai((SELECT pause_modele FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000103') = 'pause_general',
  '2 bis. la pause du super-admin est posee');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(a.payload ->> 'geste' ORDER BY a.id) FROM public.audit_logs a
    WHERE a.action = 'super_admin_hors_cote'
      AND a.actor = '7e100000-0000-4000-8000-0000000000b2' AND a.payload ->> 'mention' = 'super-admin hors côté')
  -- planifier_entretien deux fois : la tentative avec un participant homme,
  -- refusee apres l'ouverture du geste par le moteur, est tracee aussi.
  = ARRAY['planifier_entretien', 'planifier_entretien', 'ajouter_participant', 'consigner_entretien_non_tenu',
          'mettre_en_pause'],
  '2 bis. chaque geste (ou tentative) du super-admin hors de son cote est au journal sensible (« super-admin hors côté »)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'super_admin_hors_cote'
                                  AND a.actor <> '7e100000-0000-4000-8000-0000000000b2'),
  '2 bis. une direction de son cote, ou refusee, n''ecrit rien au journal hors cote');
-- Exception desactivee : le super-admin redevient une direction de son cote.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'kyc_exception_super_admin';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b2', 'admin');
SELECT pg_temp.vrai(public.planifier_entretien('7e100000-0000-4000-8000-000000000103', now() + interval '2 days', 45,
         ARRAY['7e100000-0000-4000-8000-0000000000a2', '7e100000-0000-4000-8000-0000000000d2']::uuid[],
         pg_temp.version_cand('7e100000-0000-4000-8000-000000000103'), 'v1-cle-sa-off') ? 'erreur',
  '2 bis. exception desactivee : le super-admin ne planifie plus de l''autre cote');
RESET ROLE;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'kyc_exception_super_admin';

-- ===========================================================================
-- 3. Ajouter, retirer
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $participants$
DECLARE
  v_seance uuid := current_setting('v1.seance')::uuid;
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai(public.ajouter_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000b1')
                       ->> 'erreur' = 'absente', '3. la direction de l''autre cote ne voit pas l''entretien');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(public.ajouter_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000b1')
                       ->> 'erreur' = 'participant_autre_cote', '3. ajouter un participant de l''autre cote : refuse');
  PERFORM pg_temp.vrai(NOT public.ajouter_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000a1') ? 'erreur',
    '3. ajouter A1 (experte, non fondatrice) : fait');
  -- Fondatrices actives : A2, T2, SA (3) ; retirer SA laisse 2, retirer ensuite A2 en laisserait 1.
  PERFORM pg_temp.vrai(NOT public.retirer_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000b2') ? 'erreur',
    '3. retirer le super-admin : il reste deux fondatrices');
  v_r := public.retirer_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000a2');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'fondateurs_insuffisants'
                       AND v_r ->> 'message' = 'Il faut au moins 2 fondateurs parmi les participants (1 choisi).',
    '3. retirer une fondatrice sous le minimum : refuse, avec la phrase');
  PERFORM pg_temp.vrai(public.retirer_participant_entretien(v_seance, '7e100000-0000-4000-8000-0000000000b2')
                       ->> 'erreur' = 'participant_absent', '3. retirer deux fois : participant absent');
  PERFORM pg_temp.vrai(public.retirer_participant_entretien(current_setting('v1.seance2')::uuid,
                         '7e100000-0000-4000-8000-0000000000a1') ->> 'erreur' IN ('dernier_participant', 'fondateurs_insuffisants'),
    '3. jamais le dernier participant');
END
$participants$;
RESET ROLE;

-- ===========================================================================
-- 4. Le jeton
-- ===========================================================================
-- Avant le debut : un compte rendu est refuse.
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a2', 'admin');
SELECT pg_temp.vrai(public.ecrire_compte_rendu_entretien(current_setting('v1.seance')::uuid, 'Trop tot.', 'favorable',
         NULL, NULL, NULL, NULL) ->> 'erreur' = 'entretien_pas_commence', '5. aucun compte rendu avant le debut');
RESET ROLE;
UPDATE public.sessions SET started_at = now() - interval '5 minutes', ended_at = now() + interval '40 minutes',
                           join_opens_at = now() - interval '15 minutes'
 WHERE id = current_setting('v1.seance')::uuid;
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000d2',
        now() - interval '5 minutes', now() + interval '40 minutes', 'planned', 'standard',
        now() - interval '15 minutes');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
 ('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000c1', 'candidat'),
 ('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000a2', 'intervieweur');

DO $jeton$
DECLARE
  v_seance uuid := current_setting('v1.seance')::uuid;
  v_j jsonb;
  v_motif text;
BEGIN
  v_j := public.autoriser_jeton_video(v_seance, '7e100000-0000-4000-8000-0000000000c1',
                                      'wss://v1.cloud.test', 'wss://v1.auto.test');
  PERFORM pg_temp.vrai(v_j ->> 'role' = 'candidat'
                       AND (v_j -> 'capabilities' ->> 'can_publish')::boolean
                       AND (v_j -> 'capabilities' ->> 'can_publish_video')::boolean
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'can_publish_data')::boolean, false)
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'hidden')::boolean, false),
    '4. la candidate pending_kyc entre dans SA seance : voix, image, sans donnees, visible');
  v_j := public.autoriser_jeton_video(v_seance, '7e100000-0000-4000-8000-0000000000d2',
                                      'wss://v1.cloud.test', 'wss://v1.auto.test');
  PERFORM pg_temp.vrai(v_j ->> 'role' = 'intervieweur'
                       AND (v_j -> 'capabilities' ->> 'can_publish')::boolean
                       AND (v_j -> 'capabilities' ->> 'can_publish_video')::boolean
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'can_publish_data')::boolean, false)
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'can_moderate')::boolean, false)
                       AND NOT coalesce((v_j -> 'capabilities' ->> 'hidden')::boolean, false),
    '4. une intervieweuse (enseignante) entre : voix, image, nommee, sans donnees ni moderation : '
    || coalesce(v_j -> 'capabilities', 'null'::jsonb)::text);
  PERFORM pg_temp.vrai(public.autoriser_jeton_video(v_seance, '7e100000-0000-4000-8000-0000000000a1',
                         'wss://v1.cloud.test', 'wss://v1.auto.test') ->> 'role' = 'intervieweur',
    '4. l''experte ajoutee entre');
  v_motif := pg_temp.jeton_refuse(v_seance, '7e100000-0000-4000-8000-0000000000b2');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '4. jeton refuse au participant retire : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse(v_seance, '7e100000-0000-4000-8000-0000000000c2');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '4. jeton refuse a une autre candidate : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse(v_seance, '7e100000-0000-4000-8000-0000000000b1');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '4. jeton refuse a la direction non inscrite : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000a2');
  PERFORM pg_temp.vrai(v_motif = 'non inscrit a cette seance',
    '4. le role intervieweur ne vaut rien dans un cours : ' || coalesce(v_motif, 'accorde'));
  v_motif := pg_temp.jeton_refuse('7e100000-0000-4000-8000-000000000201', '7e100000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(v_motif IS NOT NULL, '4. le role candidat ne vaut rien dans un cours : ' || coalesce(v_motif, 'accorde'));
  BEGIN
    PERFORM public.autoriser_jeton_video_eleve(v_seance, '7e100000-0000-4000-8000-0000000000e1',
      '7e100000-0000-4000-8000-0000000000e2', 'wss://v1.cloud.test', 'wss://v1.auto.test');
    RAISE EXCEPTION 'ROUGE : 4. le chemin tuteur a ouvert un entretien';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 4. le chemin « tuteur pour un eleve » refuse un entretien';
  END;
END
$jeton$;
INSERT INTO public.session_events (session_id, profile_id, event_type, server_ts, source)
VALUES (current_setting('v1.seance')::uuid, '7e100000-0000-4000-8000-0000000000d2', 'joined', now() - interval '4 minutes', 'livekit_webhook'),
       (current_setting('v1.seance')::uuid, '7e100000-0000-4000-8000-0000000000c1', 'joined', now() - interval '3 minutes', 'livekit_webhook');

-- ===========================================================================
-- 5. et 6. Comptes rendus, consigner, conclusion
-- ===========================================================================
SELECT pg_temp.vrai(NOT (private.entretien_conclusion('7e100000-0000-4000-8000-000000000101') ->> 'tenu')::boolean,
  '6. conclusion avant consignation : non tenu');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.entretien_conclusion(uuid)', 'EXECUTE')
  AND (SELECT provolatile FROM pg_proc WHERE oid = 'private.entretien_conclusion(uuid)'::regprocedure) = 's',
  '6. entretien_conclusion : STABLE, aucun droit client');
SET LOCAL ROLE authenticated;
DO $comptes_rendus$
DECLARE
  v_seance uuid := current_setting('v1.seance')::uuid;
  v_version integer;
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  BEGIN
    PERFORM public.ecrire_compte_rendu_entretien(v_seance, 'Intrus.', 'favorable', NULL, NULL, NULL, NULL);
    RAISE EXCEPTION 'ROUGE : 5. un non-participant a ecrit un compte rendu';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 5. un non-participant n''ecrit pas de compte rendu';
  END;
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b2', 'admin');
  BEGIN
    PERFORM public.ecrire_compte_rendu_entretien(v_seance, 'Retire.', 'favorable', NULL, NULL, NULL, NULL);
    RAISE EXCEPTION 'ROUGE : 5. un participant retire a ecrit un compte rendu';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 5. un participant retire n''ecrit plus';
  END;
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM pg_temp.vrai(public.ecrire_compte_rendu_entretien(v_seance, 'Bonne lecture.', 'excellent',
                         NULL, NULL, NULL, NULL) ->> 'erreur' = 'constat_invalide', '5. un avis inconnu est refuse');
  PERFORM pg_temp.vrai(public.ecrire_compte_rendu_entretien(v_seance, 'Lecture correcte, quelques hesitations.', 'reserve',
                         'moins_10_juz', 'tajwid_applique', NULL, NULL) ->> 'enregistre' = 'true',
    '5. l''enseignante participante ecrit son compte rendu');
  PERFORM pg_temp.vrai(pg_catalog.jsonb_array_length(public.lire_entretien(v_seance) -> 'comptesRendus') = 1
                       AND public.lire_entretien(v_seance) -> 'presences' = '[]'::jsonb,
    '5. un participant lit son seul compte rendu, sans le journal');
  PERFORM pg_temp.vrai((SELECT je_participe AND mon_compte_rendu AND participants = 3 AND fondateurs = 2
                          FROM public.mes_entretiens() WHERE session_id = v_seance),
    '7. mes_entretiens d''une participante : elle y est, son compte rendu, 3 participants dont 2 fondatrices');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a2', 'admin');
  PERFORM pg_temp.vrai(public.ecrire_compte_rendu_entretien(v_seance, 'Recitation solide, tajwid enseigne.', 'favorable',
                         'de_10_a_29_juz', 'tajwid_enseigne', ARRAY['hafs', 'warsh'], 'pret_test') ->> 'enregistre' = 'true',
    '5. une fondatrice ecrit un compte rendu favorable et complet');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  v_r := public.lire_entretien(v_seance);
  PERFORM pg_temp.vrai(pg_catalog.jsonb_array_length(v_r -> 'comptesRendus') = 2
                       AND pg_catalog.jsonb_array_length(v_r -> 'presences') = 2
                       AND pg_catalog.jsonb_array_length(v_r -> 'participants') = 4,
    '5. la direction lit les deux comptes rendus, le journal des presents et les participants (retire compris)');
  v_version := pg_temp.version_cand('7e100000-0000-4000-8000-000000000101');
  v_r := public.consigner_entretien(v_seance, 'tenu', NULL, v_version, 'v1-cle-tenu');
  PERFORM pg_temp.vrai(NOT v_r ? 'erreur', '6. tenu, avec des comptes rendus : consigne : ' || v_r::text);
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM pg_temp.vrai(public.ecrire_compte_rendu_entretien(v_seance, 'Apres coup.', 'favorable', NULL, NULL, NULL, NULL)
                       ->> 'erreur' = 'entretien_consigne', '5. plus de compte rendu une fois consigne');

  -- La seconde : tenu sans compte rendu, puis non tenu sans motif, puis avec.
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  v_version := pg_temp.version_cand('7e100000-0000-4000-8000-000000000102');
  v_r := public.consigner_entretien(current_setting('v1.seance2')::uuid, 'tenu', NULL, v_version, 'v1-cle-tenu-vide');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'compte_rendu_requis', '6. tenu sans compte rendu : refuse');
  v_r := public.consigner_entretien(current_setting('v1.seance2')::uuid, 'manque_candidat', NULL, v_version, 'v1-cle-sans-motif');
  PERFORM pg_temp.vrai(v_r ? 'erreur', '6. non tenu sans motif : refuse : ' || (v_r ->> 'erreur'));
  v_r := public.consigner_entretien(current_setting('v1.seance2')::uuid, 'manque_candidat',
                                    'La candidate ne s''est pas presentee.', v_version, 'v1-cle-manque');
  PERFORM pg_temp.vrai(NOT v_r ? 'erreur', '6. manque de la candidate, avec motif : consigne');

  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.mes_entretiens()) = 0, '7. mes_entretiens : rien de l''autre cote');
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.mes_entretiens()) = 3, '7. mes_entretiens : les trois de son cote');
  BEGIN
    PERFORM pg_temp.vrai((SELECT count(*) FROM public.entretiens) + (SELECT count(*) FROM public.entretien_participants)
                         + (SELECT count(*) FROM public.entretien_comptes_rendus) + (SELECT count(*) FROM public.personnel_fondateurs) = 0,
      '7. les tables ne rendent aucune ligne a un client (RLS sans politique)');
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 7. les tables d''entretien ne sont pas lisibles par un client';
  END;
  PERFORM pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000e1', 'guardian');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_v WHERE session_id = v_seance),
    '7. aucune vue de famille ne porte l''entretien');
END
$comptes_rendus$;
RESET ROLE;
SELECT pg_temp.personne();

SELECT pg_temp.vrai(
  (private.entretien_conclusion('7e100000-0000-4000-8000-000000000101') ->> 'tenu')::boolean
  AND (private.entretien_conclusion('7e100000-0000-4000-8000-000000000101') ->> 'avisFavorable')::boolean
  AND (private.entretien_conclusion('7e100000-0000-4000-8000-000000000101') ->> 'constatComplet')::boolean
  AND private.entretien_conclusion('7e100000-0000-4000-8000-000000000101') -> 'constat'
      = '{"memorisation": "de_10_a_29_juz", "tajwid": "tajwid_enseigne", "riwayat": ["hafs", "warsh"], "ijaza": "pret_test"}'::jsonb
  AND private.entretien_conclusion('7e100000-0000-4000-8000-000000000101') ->> 'sessionId' = current_setting('v1.seance'),
  '6. conclusion : tenu, avis favorable, constat complet, celui du compte rendu complet');
SELECT pg_temp.vrai(
  NOT (private.entretien_conclusion('7e100000-0000-4000-8000-000000000102') ->> 'tenu')::boolean
  AND private.entretien_conclusion('7e100000-0000-4000-8000-000000000102') -> 'sessionId' = 'null'::jsonb,
  '6. conclusion d''un entretien manque : non tenu');
SELECT pg_temp.vrai(
  (SELECT status = 'ended' FROM public.sessions WHERE id = current_setting('v1.seance')::uuid)
  AND (SELECT status = 'canceled' FROM public.sessions WHERE id = current_setting('v1.seance2')::uuid)
  AND (SELECT etat FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000101') = 'decision_en_attente'
  AND (SELECT etat FROM public.candidatures WHERE id = '7e100000-0000-4000-8000-000000000102') = 'entretien_a_planifier',
  '6. tenu : seance terminee, decision en attente ; manque : seance annulee, entretien a replanifier');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre t JOIN public.entretiens e ON t.source_id = e.session_id::text)
  AND NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements t JOIN public.entretiens e ON t.source_id = e.session_id::text)
  AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation r JOIN public.entretiens e ON r.session_id = e.session_id),
  '7. aucune tresorerie, aucun remplacement pour un entretien');
SELECT pg_temp.vrai(pg_temp.jeton_refuse(current_setting('v1.seance')::uuid, '7e100000-0000-4000-8000-0000000000c1') IS NOT NULL,
  '4. plus de jeton pour la candidate une fois l''entretien consigne');
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e100000-0000-4000-8000-0000000000d1', 'teacher');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_seances_enseignant_v v
                                 WHERE v.session_id IN (current_setting('v1.seance')::uuid, current_setting('v1.seance2')::uuid)),
  '7. aucun entretien dans les vues d''un enseignant');
RESET ROLE;
SELECT pg_temp.personne();

-- ===========================================================================
-- 7. Une reunion : seuls ses inscrits entrent ; la CHECK refuse l'inconnu
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
  '7. reunion : l''inscrite entre ; la titulaire de teacher_id non inscrite et un enseignant, non');
DO $check$
BEGIN
  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type)
  VALUES ('7e100000-0000-4000-8000-0000000000a1', now() + interval '1 day', now() + interval '25 hours',
          'planned', 'webinaire');
  RAISE EXCEPTION 'ROUGE : 7. un type de seance inconnu est admis';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'OK 7. la CHECK refuse un type inconnu';
END
$check$;

ROLLBACK;
