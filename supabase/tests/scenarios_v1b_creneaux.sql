-- V1-b : les creneaux d'entretien, ouverts par la direction, reserves par le
-- candidat. Prouve :
--   1. ouvrir : direction de son cote (homme non super-admin refuse cote
--      femmes), super-admin des deux cotes au journal ; participants du cote ;
--      regle des fondateurs ; langues ;
--   2. le candidat ne voit que les creneaux libres de son cote, dans l'une de
--      ses langues (langueMaternelle, languesExplication) ;
--   3. reserver : geste planifier_entretien du moteur, auteur candidat ; la
--      seance d'entretien de V1-a et ses inscrits ; la cle rejoue ; un
--      creneau pris, d'une autre langue ou d'un autre cote est refuse ;
--   4. un creneau devenu intenable (fondateur decoche) disparait et se refuse ;
--   5. annuler un creneau libre (ligne gardee), jamais un creneau reserve ;
--      lister par cote ; mon_entretien pour /attente ;
--   6. aucun droit client sur les tables ; le candidat n'ouvre rien.
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

-- A1 : direction femme ; H1 : direction homme ; SA : super-admin homme (0088) ;
-- A2 : direction femme fondatrice ; T2 : enseignante active fondatrice ;
-- CF1, CF2 : candidates ; CM : candidat. Toutes les candidatures sont a
-- planifier en Salle de verification.
INSERT INTO auth.users (id, email) VALUES
 ('7e200000-0000-4000-8000-0000000000a1', 'v1b-a1@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000a2', 'v1b-a2@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000b1', 'v1b-h1@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000b2', 'v1b-sa@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000d2', 'v1b-t2@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000c1', 'v1b-cf1@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000c2', 'v1b-cf2@test.invalid'),
 ('7e200000-0000-4000-8000-0000000000c3', 'v1b-cm@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e200000-0000-4000-8000-0000000000a1', 'RA-26-7201', 'admin', NULL, 'Amina', 'V1b', 'active', 'female'),
 ('7e200000-0000-4000-8000-0000000000a2', 'RA-26-7202', 'admin', NULL, 'Asma', 'V1b', 'active', 'female'),
 ('7e200000-0000-4000-8000-0000000000b1', 'RA-26-7203', 'admin', NULL, 'Bilal', 'V1b', 'active', 'male'),
 ('7e200000-0000-4000-8000-0000000000b2', 'RA-26-7204', 'admin', NULL, 'Sami', 'V1b', 'active', 'male'),
 ('7e200000-0000-4000-8000-0000000000d2', 'RA-26-7205', 'teacher', NULL, 'Hafsa', 'V1b', 'provisional_active', 'female'),
 ('7e200000-0000-4000-8000-0000000000c1', 'RA-26-7206', 'teacher', NULL, 'Khadija', 'V1b', 'pending_kyc', 'female'),
 ('7e200000-0000-4000-8000-0000000000c2', 'RA-26-7207', 'teacher', NULL, 'Maryam', 'V1b', 'pending_kyc', 'female'),
 ('7e200000-0000-4000-8000-0000000000c3', 'RA-26-7208', 'teacher', NULL, 'Yahya', 'V1b', 'pending_kyc', 'male');
-- T2 passe active apres signature (meme fixture que scenarios_af_l1_05).
INSERT INTO public.teacher_profiles (profile_id) VALUES ('7e200000-0000-4000-8000-0000000000d2');
DO $fixture_t2b$
BEGIN
  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000d2', 'teacher');
  PERFORM public.signer_contrat((SELECT version FROM public.contract_texts
                                  WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current), 'Fixture V1-b');
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('7e200000-0000-4000-8000-0000000000d2', 'recording_and_control_notice',
          (SELECT version FROM public.contract_required_versions WHERE contract_kind = 'recording_and_control_notice'))
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('7e200000-0000-4000-8000-0000000000d2', 'teacher_conduct_code', public.code_conduite_version_requise())
  ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
  UPDATE public.profiles SET account_status = 'active' WHERE id = '7e200000-0000-4000-8000-0000000000d2';
  PERFORM pg_temp.personne();
END
$fixture_t2b$;
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('7e200000-0000-4000-8000-0000000000b2')
ON CONFLICT DO NOTHING;
INSERT INTO public.personnel_fondateurs (profile_id, fondateur, modifie_par) VALUES
 ('7e200000-0000-4000-8000-0000000000a2', true, '7e200000-0000-4000-8000-0000000000a1'),
 ('7e200000-0000-4000-8000-0000000000d2', true, '7e200000-0000-4000-8000-0000000000a1');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7e200000-0000-4000-8000-000000000101', 'enseignant', '7e200000-0000-4000-8000-0000000000c1', 'female',
  'Fixture V1b un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e200000-0000-4000-8000-000000000102', 'enseignant', '7e200000-0000-4000-8000-0000000000c2', 'female',
  'Fixture V1b deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7e200000-0000-4000-8000-000000000103', 'enseignant', '7e200000-0000-4000-8000-0000000000c3', 'male',
  'Fixture V1b trois', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');
-- Les langues : CF1 et CM francais (maternelle) et anglais ; CF2 francais
-- par explication seulement.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source) VALUES
 ('7e200000-0000-4000-8000-000000000101', 'salle-examen-1', '{"langueMaternelle": "fr", "languesExplication": ["en"]}', 'candidat'),
 ('7e200000-0000-4000-8000-000000000102', 'salle-examen-1', '{"langueMaternelle": "so", "languesExplication": ["fr"]}', 'candidat'),
 ('7e200000-0000-4000-8000-000000000103', 'salle-examen-1', '{"langueMaternelle": "fr", "languesExplication": ["en"]}', 'candidat');

-- ===========================================================================
-- 1. Ouvrir
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $ouvrir$
DECLARE
  v_r jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai(public.ouvrir_creneau_entretien('female', now() + interval '2 days', 45, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000d2']::uuid[]) ->> 'erreur' = 'hors_portee',
    '1. direction homme non super-admin : pas de creneau cote femmes');

  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM pg_temp.vrai(public.ouvrir_creneau_entretien('female', now() + interval '2 days', 45, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000b1']::uuid[]) ->> 'erreur' = 'participant_autre_cote',
    '1. un participant homme sur un creneau cote femmes : refuse (CAND-Q07)');
  v_r := public.ouvrir_creneau_entretien('female', now() + interval '2 days', 45, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000a1', '7e200000-0000-4000-8000-0000000000a2']::uuid[]);
  PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'fondateurs_insuffisants', '1. moins de deux fondateurs : refuse');
  PERFORM pg_temp.vrai(public.ouvrir_creneau_entretien('female', now() + interval '2 days', 45, ARRAY['FR!'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000d2']::uuid[]) ->> 'erreur' = 'langues_invalides',
    '1. une langue invalide est refusee');
  PERFORM pg_temp.vrai(public.ouvrir_creneau_entretien('female', now() + interval '10 minutes', 45, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000d2']::uuid[]) ->> 'erreur' = 'debut_invalide',
    '1. un creneau dans moins d''une heure est refuse');

  v_r := public.ouvrir_creneau_entretien('female', now() + interval '2 days', 45, ARRAY['fr', 'ar'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000d2']::uuid[]);
  PERFORM pg_temp.vrai(v_r ? 'creneauId', '1. creneau S1 (femmes, francais et arabe) ouvert : ' || v_r::text);
  PERFORM set_config('v1b.s1', v_r ->> 'creneauId', true);
  v_r := public.ouvrir_creneau_entretien('female', now() + interval '3 days', 45, ARRAY['ar'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000d2']::uuid[]);
  PERFORM set_config('v1b.s2', v_r ->> 'creneauId', true);
  PERFORM pg_temp.vrai(v_r ? 'creneauId', '1. creneau S2 (femmes, arabe seulement) ouvert');

  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000b2', 'admin');
  v_r := public.ouvrir_creneau_entretien('female', now() + interval '4 days', 60, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2', '7e200000-0000-4000-8000-0000000000d2']::uuid[]);
  PERFORM pg_temp.vrai(v_r ? 'creneauId', '1. le super-admin (homme) ouvre S3 cote femmes');
  PERFORM set_config('v1b.s3', v_r ->> 'creneauId', true);

  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000b1', 'admin');
  PERFORM pg_temp.vrai(public.ouvrir_creneau_entretien('male', now() + interval '2 days', 45, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000b1', '7e200000-0000-4000-8000-0000000000b2']::uuid[]) ->> 'erreur' = 'fondateurs_insuffisants',
    '1. cote hommes : la regle des fondateurs vaut aussi');
END
$ouvrir$;
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a
                             WHERE a.action = 'super_admin_hors_cote' AND a.actor = '7e200000-0000-4000-8000-0000000000b2'
                               AND a.row_id = current_setting('v1b.s3') AND a.payload ->> 'geste' = 'ouvrir_creneau'),
  '1. l''ouverture hors cote du super-admin est au journal sensible');
-- Regle desactivee le temps d'ouvrir un creneau cote hommes.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000b1', 'admin');
SELECT set_config('v1b.s4', public.ouvrir_creneau_entretien('male', now() + interval '2 days', 45, ARRAY['fr'],
         ARRAY['7e200000-0000-4000-8000-0000000000b1']::uuid[]) ->> 'creneauId', true);
RESET ROLE;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
SELECT pg_temp.vrai(current_setting('v1b.s4') <> '', '1. regle desactivee : creneau S4 cote hommes ouvert avec un seul participant');

-- ===========================================================================
-- 2. et 3. Voir, reserver
-- ===========================================================================
SET LOCAL ROLE authenticated;
DO $reserver$
DECLARE
  v_ids uuid[];
  v_r jsonb;
  v_r2 jsonb;
BEGIN
  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000c1', 'teacher');
  SELECT pg_catalog.array_agg(creneau_id ORDER BY debut) INTO v_ids FROM public.creneaux_entretien_disponibles();
  PERFORM pg_temp.vrai(v_ids = ARRAY[current_setting('v1b.s1')::uuid, current_setting('v1b.s3')::uuid],
    '2. CF1 (francais) voit S1 et S3, ni S2 (arabe) ni S4 (hommes) : ' || coalesce(v_ids::text, 'aucun'));
  BEGIN
    PERFORM public.ouvrir_creneau_entretien('female', now() + interval '2 days', 45, ARRAY['fr'],
      ARRAY['7e200000-0000-4000-8000-0000000000a2']::uuid[]);
    RAISE EXCEPTION 'ROUGE : 6. une candidate a ouvert un creneau';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 6. une candidate n''ouvre pas de creneau';
  END;
  PERFORM pg_temp.vrai(public.mon_entretien() IS NULL, '5. mon_entretien : rien avant la reservation');
  PERFORM pg_temp.vrai(public.reserver_creneau_entretien(current_setting('v1b.s2')::uuid,
                         pg_temp.version_cand('7e200000-0000-4000-8000-000000000101'), 'v1b-cle-cf1-s2') ->> 'erreur' = 'creneau_indisponible',
    '3. un creneau d''une autre langue est refuse');
  PERFORM pg_temp.vrai(public.reserver_creneau_entretien(current_setting('v1b.s4')::uuid,
                         pg_temp.version_cand('7e200000-0000-4000-8000-000000000101'), 'v1b-cle-cf1-s4') ->> 'erreur' = 'creneau_indisponible',
    '3. un creneau de l''autre cote est refuse');
  v_r := public.reserver_creneau_entretien(current_setting('v1b.s1')::uuid,
           pg_temp.version_cand('7e200000-0000-4000-8000-000000000101'), 'v1b-cle-cf1-s1');
  PERFORM pg_temp.vrai(v_r -> 'entretien' ? 'sessionId', '3. CF1 reserve S1 : ' || v_r::text);
  v_r2 := public.reserver_creneau_entretien(current_setting('v1b.s1')::uuid, 1, 'v1b-cle-cf1-s1');
  PERFORM pg_temp.vrai(v_r2 -> 'entretien' ->> 'sessionId' = v_r -> 'entretien' ->> 'sessionId',
    '3. la meme cle rejoue la meme reservation');
  PERFORM pg_temp.vrai(public.mon_entretien() ->> 'sessionId' = v_r -> 'entretien' ->> 'sessionId',
    '5. mon_entretien rend l''entretien reserve (pour /attente)');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.creneaux_entretien_disponibles()),
    '2. une fois planifiee, la candidate ne voit plus de creneau');
  PERFORM set_config('v1b.seance1', v_r -> 'entretien' ->> 'sessionId', true);

  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000c2', 'teacher');
  PERFORM pg_temp.vrai(public.reserver_creneau_entretien(current_setting('v1b.s1')::uuid,
                         pg_temp.version_cand('7e200000-0000-4000-8000-000000000102'), 'v1b-cle-cf2-s1') ->> 'erreur' = 'creneau_indisponible',
    '3. un creneau deja pris est refuse a une autre candidate');
  SELECT pg_catalog.array_agg(creneau_id) INTO v_ids FROM public.creneaux_entretien_disponibles();
  PERFORM pg_temp.vrai(v_ids = ARRAY[current_setting('v1b.s3')::uuid],
    '2. CF2 (francais par explication) ne voit plus que S3');

  PERFORM pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000c3', 'teacher');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.creneaux_entretien_disponibles()),
    '2. regle active : S4 (un seul participant) n''est montre a personne');
END
$reserver$;
RESET ROLE;
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000c3', 'teacher');
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(creneau_id) FROM public.creneaux_entretien_disponibles())
                    = ARRAY[current_setting('v1b.s4')::uuid],
  '2. regle desactivee : le candidat (homme) voit S4, et lui seul (cote hommes)');
RESET ROLE;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'entretiens.regle_fondateurs_active';
SELECT pg_temp.vrai(
  (SELECT s.session_type = 'entretien' AND s.teacher_id = '7e200000-0000-4000-8000-0000000000a1' AND s.status = 'planned'
     FROM public.sessions s WHERE s.id = current_setting('v1b.seance1')::uuid)
  AND (SELECT pg_catalog.array_agg(sp.role::text ORDER BY sp.role::text)
         FROM public.session_participants sp WHERE sp.session_id = current_setting('v1b.seance1')::uuid)
      = ARRAY['candidat', 'intervieweur', 'intervieweur']
  AND (SELECT count(*) FILTER (WHERE fondateur) FROM public.entretien_participants
        WHERE session_id = current_setting('v1b.seance1')::uuid) = 2
  AND (SELECT etat FROM public.candidatures WHERE id = '7e200000-0000-4000-8000-000000000101') = 'entretien_planifie'
  AND (SELECT session_id FROM public.entretien_creneaux WHERE id = current_setting('v1b.s1')::uuid)
      = current_setting('v1b.seance1')::uuid
  AND EXISTS (SELECT 1 FROM public.candidature_evenements ev
               WHERE ev.candidature_id = '7e200000-0000-4000-8000-000000000101' AND ev.type = 'entretien'
                 AND ev.auteur_id = '7e200000-0000-4000-8000-0000000000c1'),
  '3. la reservation cree l''entretien de V1-a (seance, deux intervieweuses fondatrices, la candidate), l''etat et le journal suivent');

-- ===========================================================================
-- 4. Un creneau devenu intenable
-- ===========================================================================
UPDATE public.personnel_fondateurs SET fondateur = false WHERE profile_id = '7e200000-0000-4000-8000-0000000000d2';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000c2', 'teacher');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.creneaux_entretien_disponibles()),
  '4. un fondateur decoche : S3 n''a plus deux fondateurs, il disparait');
SELECT pg_temp.vrai(public.reserver_creneau_entretien(current_setting('v1b.s3')::uuid,
         pg_temp.version_cand('7e200000-0000-4000-8000-000000000102'), 'v1b-cle-cf2-s3') ->> 'erreur' = 'creneau_indisponible',
  '4. et sa reservation est refusee');
RESET ROLE;
UPDATE public.personnel_fondateurs SET fondateur = true WHERE profile_id = '7e200000-0000-4000-8000-0000000000d2';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000c2', 'teacher');
SELECT pg_temp.vrai(public.reserver_creneau_entretien(current_setting('v1b.s3')::uuid,
         pg_temp.version_cand('7e200000-0000-4000-8000-000000000102'), 'v1b-cle-cf2-s3b') -> 'entretien' ? 'sessionId',
  '4. coche remise : CF2 reserve S3 (ouvert par le super-admin)');

-- ===========================================================================
-- 5. Annuler, lister
-- ===========================================================================
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.annuler_creneau_entretien(current_setting('v1b.s1')::uuid) ->> 'erreur' = 'creneau_reserve',
  '5. un creneau reserve ne s''annule pas');
SELECT pg_temp.vrai((public.annuler_creneau_entretien(current_setting('v1b.s2')::uuid) ->> 'annule')::boolean,
  '5. un creneau libre s''annule');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(etat ORDER BY debut) FROM public.lister_creneaux_entretien()
    WHERE creneau_id IN (current_setting('v1b.s1')::uuid, current_setting('v1b.s2')::uuid, current_setting('v1b.s3')::uuid))
  = ARRAY['reserve', 'annule', 'reserve']
  AND NOT EXISTS (SELECT 1 FROM public.lister_creneaux_entretien() WHERE creneau_id = current_setting('v1b.s4')::uuid),
  '5. la direction femme liste ses creneaux (reserve, annule, reserve), pas ceux des hommes');
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000b1', 'admin');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(creneau_id) FROM public.lister_creneaux_entretien())
    @> ARRAY[current_setting('v1b.s4')::uuid]
  AND NOT EXISTS (SELECT 1 FROM public.lister_creneaux_entretien() WHERE creneau_id = current_setting('v1b.s1')::uuid),
  '5. la direction homme liste les creneaux des hommes seulement');
SELECT pg_temp.en_tant_que('7e200000-0000-4000-8000-0000000000b2', 'admin');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.lister_creneaux_entretien()
    WHERE creneau_id IN (current_setting('v1b.s1')::uuid, current_setting('v1b.s4')::uuid)) = 2,
  '5. le super-admin liste les deux cotes');
RESET ROLE;
SELECT pg_temp.vrai((SELECT annule_le IS NOT NULL FROM public.entretien_creneaux WHERE id = current_setting('v1b.s2')::uuid),
  '5. le creneau annule garde sa ligne');

-- ===========================================================================
-- 6. Aucun droit client sur les tables
-- ===========================================================================
SELECT pg_temp.vrai(NOT has_table_privilege('authenticated', 'public.entretien_creneaux', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.entretien_creneau_participants', 'SELECT')
  AND NOT has_function_privilege('anon', 'public.reserver_creneau_entretien(uuid,integer,text)', 'EXECUTE'),
  '6. tables illisibles par un client, reservation fermee a anon');

ROLLBACK;
