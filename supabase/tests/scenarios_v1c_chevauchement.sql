-- V1-c : le chevauchement des entretiens. Prouve :
--   1. deux entretiens en meme temps, planifies par la meme direction, avec
--      des intervieweurs differents : acceptes (la contrainte ne vaut plus
--      que pour les cours) ;
--   2. le meme intervieweur dans les deux : refuse, avec son nom et l'heure ;
--      ajouter une personne occupee : refuse ; la direction qui a planifie
--      sans participer n'est pas occupee ;
--   3. une enseignante qui fait cours a cette heure : refusee comme
--      intervieweuse ; un cours d'enseignant reste protege par la contrainte
--      (23P01) ;
--   4. reserver un creneau dont le personnel est occupe : « indisponible »,
--      sans nom ; un creneau libre se reserve ;
--   5. la contrainte en vigueur, et aucun droit client sur la fonction.
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
CREATE FUNCTION pg_temp.version_cand(p_id uuid) RETURNS integer
LANGUAGE sql SECURITY DEFINER AS $$ SELECT version FROM public.candidatures WHERE id = p_id $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.version_cand(uuid) TO authenticated;

-- A1 : direction femme (planifie, ne participe pas) ; A2 : direction femme ;
-- T2 : enseignante active ; T3 : enseignant (cours) ; CF1..CF4 : candidates.
-- La regle des fondateurs est coupee ici : ce scenario ne mesure que le
-- chevauchement (la regle a ses propres scenarios, V1-a et V1-b).
INSERT INTO auth.users (id, email) VALUES
 ('7e300000-0000-4000-8000-0000000000a1', 'v1c-a1@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000a2', 'v1c-a2@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000d2', 'v1c-t2@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000d3', 'v1c-t3@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000c1', 'v1c-cf1@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000c2', 'v1c-cf2@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000c3', 'v1c-cf3@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000c4', 'v1c-cf4@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e300000-0000-4000-8000-0000000000a1', 'RA-26-7301', 'admin', NULL, 'Amina', 'V1c', 'active', 'female'),
 ('7e300000-0000-4000-8000-0000000000a2', 'RA-26-7302', 'admin', NULL, 'Asma', 'V1c', 'active', 'female'),
 ('7e300000-0000-4000-8000-0000000000d2', 'RA-26-7303', 'teacher', NULL, 'Hafsa', 'V1c', 'provisional_active', 'female'),
 ('7e300000-0000-4000-8000-0000000000d3', 'RA-26-7304', 'teacher', NULL, 'Yusuf', 'V1c', 'provisional_active', 'male'),
 ('7e300000-0000-4000-8000-0000000000c1', 'RA-26-7305', 'teacher', NULL, 'Khadija', 'V1c', 'pending_kyc', 'female'),
 ('7e300000-0000-4000-8000-0000000000c2', 'RA-26-7306', 'teacher', NULL, 'Maryam', 'V1c', 'pending_kyc', 'female'),
 ('7e300000-0000-4000-8000-0000000000c3', 'RA-26-7307', 'teacher', NULL, 'Sara', 'V1c', 'pending_kyc', 'female'),
 ('7e300000-0000-4000-8000-0000000000c4', 'RA-26-7308', 'teacher', NULL, 'Zaynab', 'V1c', 'pending_kyc', 'female');
-- T2 passe active apres signature (meme fixture que scenarios_v1b_creneaux).
INSERT INTO public.teacher_profiles (profile_id) VALUES ('7e300000-0000-4000-8000-0000000000d2');
DO $fixture_t2$
BEGIN
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM public.signer_contrat((SELECT version FROM public.contract_texts
                                  WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current), 'Fixture V1-c');
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('7e300000-0000-4000-8000-0000000000d2', 'recording_and_control_notice',
          (SELECT version FROM public.contract_required_versions WHERE contract_kind = 'recording_and_control_notice'))
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('7e300000-0000-4000-8000-0000000000d2', 'teacher_conduct_code', public.code_conduite_version_requise())
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  UPDATE public.profiles SET account_status = 'active' WHERE id = '7e300000-0000-4000-8000-0000000000d2';
  PERFORM pg_temp.personne();
END
$fixture_t2$;
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7e300000-0000-4000-8000-000000000101', 'enseignant', '7e300000-0000-4000-8000-0000000000c1', 'female',
  'Fixture V1c un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e300000-0000-4000-8000-000000000102', 'enseignant', '7e300000-0000-4000-8000-0000000000c2', 'female',
  'Fixture V1c deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e300000-0000-4000-8000-000000000103', 'enseignant', '7e300000-0000-4000-8000-0000000000c3', 'female',
  'Fixture V1c trois', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e300000-0000-4000-8000-000000000104', 'enseignant', '7e300000-0000-4000-8000-0000000000c4', 'female',
  'Fixture V1c quatre', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source) VALUES
 ('7e300000-0000-4000-8000-000000000104', 'salle-examen-1', '{"langueMaternelle": "francais", "languesExplication": []}', 'candidat');
-- Le cours de T2, dans trois jours a 14 h (UTC) ; et un cours de T3.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type) VALUES
 ('7e300000-0000-4000-8000-0000000005c1', '7e300000-0000-4000-8000-0000000000d2',
  date_trunc('day', now()) + interval '3 days 14 hours', date_trunc('day', now()) + interval '3 days 15 hours',
  'planned', 'standard'),
 ('7e300000-0000-4000-8000-0000000005c3', '7e300000-0000-4000-8000-0000000000d3',
  date_trunc('day', now()) + interval '3 days 14 hours', date_trunc('day', now()) + interval '3 days 15 hours',
  'planned', 'standard');

-- ===========================================================================
-- 1 et 2. Deux entretiens en meme temps, par la meme direction
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $planifier$
DECLARE
  v_d timestamptz := date_trunc('day', now()) + interval '2 days 10 hours';
  v_r jsonb;
  v_e2 uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000a1', 'admin');
  v_r := public.planifier_entretien('7e300000-0000-4000-8000-000000000101', v_d, 45,
    ARRAY['7e300000-0000-4000-8000-0000000000a2']::uuid[],
    pg_temp.version_cand('7e300000-0000-4000-8000-000000000101'), 'v1c-cle-e1');
  PERFORM pg_temp.vrai(v_r ? 'entretien', '1. E1 (A2 intervieweuse) : planifie ' || v_r::text);

  v_r := public.planifier_entretien('7e300000-0000-4000-8000-000000000102', v_d, 45,
    ARRAY['7e300000-0000-4000-8000-0000000000d2']::uuid[],
    pg_temp.version_cand('7e300000-0000-4000-8000-000000000102'), 'v1c-cle-e2');
  PERFORM pg_temp.vrai(v_r ? 'entretien',
    '1. E2 en meme temps, meme direction, autre intervieweuse (T2) : accepte ' || v_r::text);
  v_e2 := (v_r -> 'entretien' ->> 'sessionId')::uuid;

  v_r := public.planifier_entretien('7e300000-0000-4000-8000-000000000103', v_d + interval '15 minutes', 45,
    ARRAY['7e300000-0000-4000-8000-0000000000a2']::uuid[],
    pg_temp.version_cand('7e300000-0000-4000-8000-000000000103'), 'v1c-cle-e3');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'personne_occupee'
      AND v_r ->> 'profil' = '7e300000-0000-4000-8000-0000000000a2'
      AND v_r ->> 'nom' = 'Asma V1c'
      AND (v_r ->> 'debut')::timestamptz = v_d
      AND v_r ->> 'message' LIKE 'Asma V1c a déjà une séance ou un entretien le % de 10:00 à 10:45 (UTC).',
    '2. E3 avec la meme intervieweuse (A2), qui chevauche : refuse, nom et heure ' || coalesce(v_r::text, 'NULL'));

  v_r := public.ajouter_participant_entretien(v_e2, '7e300000-0000-4000-8000-0000000000a2');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'personne_occupee' AND v_r ->> 'nom' = 'Asma V1c',
    '2. ajouter A2 (occupee par E1) a E2 : refuse ' || v_r::text);
  v_r := public.ajouter_participant_entretien(v_e2, '7e300000-0000-4000-8000-0000000000a1');
  PERFORM pg_temp.vrai(v_r ->> 'ajoute' = '7e300000-0000-4000-8000-0000000000a1',
    '2. ajouter A1 (a planifie E1 sans y participer) a E2 : accepte ' || v_r::text);
  PERFORM pg_temp.personne();
END
$planifier$;
RESET ROLE;

DO $base$
BEGIN
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.entretiens e
                          JOIN public.sessions s ON s.id = e.session_id
                         WHERE s.teacher_id = '7e300000-0000-4000-8000-0000000000a1'
                           AND e.issue IS NULL) = 2,
    '1. base : deux entretiens ouverts, meme direction, meme heure');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.entretiens
                                    WHERE candidature_id = '7e300000-0000-4000-8000-000000000103'),
    '2. base : aucun entretien pour la candidature refusee');
END
$base$;

-- ===========================================================================
-- 3. Un cours d'enseignant reste protege
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $cours$
DECLARE
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000a1', 'admin');
  v_r := public.planifier_entretien('7e300000-0000-4000-8000-000000000103',
    date_trunc('day', now()) + interval '3 days 14 hours 30 minutes', 30,
    ARRAY['7e300000-0000-4000-8000-0000000000d2']::uuid[],
    pg_temp.version_cand('7e300000-0000-4000-8000-000000000103'), 'v1c-cle-e4');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'personne_occupee' AND v_r ->> 'nom' = 'Hafsa V1c'
      AND v_r ->> 'message' LIKE '% de 14:00 à 15:00 (UTC).',
    '3. T2 fait cours a cette heure : refusee comme intervieweuse ' || coalesce(v_r::text, 'NULL'));
  PERFORM pg_temp.personne();
END
$cours$;
RESET ROLE;

DO $contrainte$
DECLARE
  v_etat text;
BEGIN
  BEGIN
    INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type) VALUES
     ('7e300000-0000-4000-8000-0000000000d3',
      date_trunc('day', now()) + interval '3 days 14 hours 30 minutes',
      date_trunc('day', now()) + interval '3 days 15 hours 30 minutes', 'planned', 'standard');
    v_etat := 'accepte';
  EXCEPTION WHEN exclusion_violation THEN
    v_etat := '23P01';
  END;
  PERFORM pg_temp.vrai(v_etat = '23P01',
    '3. un second cours de T3 qui chevauche le premier : refuse par la contrainte (' || v_etat || ')');
  BEGIN
    INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type) VALUES
     ('7e300000-0000-4000-8000-0000000000d3',
      date_trunc('day', now()) + interval '3 days 14 hours 30 minutes',
      date_trunc('day', now()) + interval '3 days 15 hours 30 minutes', 'planned', 'child');
    v_etat := 'accepte';
  EXCEPTION WHEN exclusion_violation THEN
    v_etat := '23P01';
  END;
  PERFORM pg_temp.vrai(v_etat = '23P01',
    '3. un cours enfant de T3 qui chevauche : refuse aussi (' || v_etat || ')');
END
$contrainte$;

-- ===========================================================================
-- 4. Reserver un creneau
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $reserver$
DECLARE
  v_d timestamptz := date_trunc('day', now()) + interval '2 days 10 hours';
  v_occupe uuid;
  v_libre uuid;
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000a1', 'admin');
  -- A2 est dans E1 a v_d : un creneau avec elle a v_d est intenable.
  v_r := public.ouvrir_creneau_entretien('female', v_d, 45, ARRAY['francais'],
    ARRAY['7e300000-0000-4000-8000-0000000000a2']::uuid[]);
  v_occupe := (v_r ->> 'creneauId')::uuid;
  PERFORM pg_temp.vrai(v_occupe IS NOT NULL, '4. creneau ouvert a l''heure de E1 ' || v_r::text);
  v_r := public.ouvrir_creneau_entretien('female', v_d + interval '3 hours', 45, ARRAY['francais'],
    ARRAY['7e300000-0000-4000-8000-0000000000a2']::uuid[]);
  v_libre := (v_r ->> 'creneauId')::uuid;
  PERFORM pg_temp.vrai(v_libre IS NOT NULL, '4. creneau ouvert trois heures plus tard ' || v_r::text);

  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000c4', 'teacher');
  v_r := public.reserver_creneau_entretien(v_occupe,
    pg_temp.version_cand('7e300000-0000-4000-8000-000000000104'), 'v1c-cle-r1');
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'creneau_indisponible' AND NOT (v_r ? 'nom'),
    '4. reserver un creneau dont l''intervieweuse est occupee : indisponible, sans nom ' || v_r::text);
  v_r := public.reserver_creneau_entretien(v_libre,
    pg_temp.version_cand('7e300000-0000-4000-8000-000000000104'), 'v1c-cle-r2');
  PERFORM pg_temp.vrai(v_r ? 'entretien', '4. reserver le creneau libre : accepte ' || v_r::text);
  PERFORM pg_temp.personne();
END
$reserver$;
RESET ROLE;

-- ===========================================================================
-- 5. La contrainte et les droits
-- ===========================================================================
DO $etat$
DECLARE
  v_def text := (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.sessions'::regclass AND c.conname = 'sessions_no_teacher_overlap');
BEGIN
  PERFORM pg_temp.vrai(v_def LIKE '%session_type = ANY (ARRAY[''standard''::text, ''child''::text])%',
    '5. la contrainte ne vaut que pour les cours : ' || v_def);
  PERFORM pg_temp.vrai(NOT has_function_privilege('authenticated',
      'private.entretien_personne_occupee(uuid[],timestamptz,timestamptz,uuid)', 'EXECUTE')
    AND NOT has_function_privilege('anon',
      'private.entretien_personne_occupee(uuid[],timestamptz,timestamptz,uuid)', 'EXECUTE'),
    '5. aucun droit client sur entretien_personne_occupee');
END
$etat$;

SELECT 'V1-c : chevauchement des entretiens, scenarios verts' AS resultat;
ROLLBACK;
