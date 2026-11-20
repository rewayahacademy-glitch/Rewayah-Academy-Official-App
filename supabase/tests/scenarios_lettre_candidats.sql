-- LETTRE-SERVEUR (migration 20261130970000) : la lettre aux candidats enseignants n'est rendue qu'a l'enseignant actif et au
-- candidat enseignant dont les trois accords sont acceptes (lus par public.etat_dossier()).
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. anonyme : aucun droit d'execution (42501), aucune lecture de la table ;
--   2. tuteur, eleve, direction, comptable : refus « role », sans texte ;
--   3. enseignant actif : la lettre, 14 parties p1 a p14, version 2026-11-20 ;
--   4. candidat sans accord : refus « accords », manques contrat, conduite, cadre (dans cet ordre) ;
--   5. candidat a qui manque un seul accord (le code de conduite) : manques = conduite ;
--   6. candidat aux trois accords : la lettre ;
--   7. compte desactive, acces expire : refus « compte » ; jeton enseignant sur un profil d'un autre role : « compte » ;
--   8. lecture directe de la table refusee a authenticated (et a anon) ;
--   9. langue : ar et en rendus dans leur langue, « en-GB » rend l'anglais, langue inconnue ou nulle : le francais ;
--  10. droits : EXECUTE a authenticated seul, RLS active sans politique.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('lettre-serveur-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', CASE WHEN p_id IS NULL THEN '' ELSE pg_catalog.json_build_object(
    'sub', p_id, 'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text END, true);
END $$;

-- Un refus : exactement les cles attendues, aucune partie, aucun titre de la lettre dans la reponse.
CREATE FUNCTION pg_temp.refus(r jsonb, p_raison text, p_manques text[]) RETURNS boolean
LANGUAGE sql AS $$
  SELECT (r ->> 'acces') = 'false'
     AND r ->> 'raison' = p_raison
     AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(r) k)
         = CASE WHEN p_manques IS NULL THEN ARRAY['acces', 'raison'] ELSE ARRAY['acces', 'manques', 'raison'] END
     AND (p_manques IS NULL OR ARRAY(SELECT jsonb_array_elements_text(r -> 'manques')) = p_manques)
     AND strpos(r::text, 'Rewayah') = 0 AND strpos(r::text, 'Praxis') = 0
$$;

-- Une lettre ouverte : 14 parties p1 a p14 dans l'ordre, la version et la langue attendues.
CREATE FUNCTION pg_temp.ouverte(r jsonb, p_langue text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT (r ->> 'acces') = 'true'
     AND r ->> 'version' = '2026-11-20'
     AND r ->> 'langue' = p_langue
     AND jsonb_array_length(r -> 'parties') = 14
     AND ARRAY(SELECT x ->> 'code' FROM jsonb_array_elements(r -> 'parties') WITH ORDINALITY e(x, o) ORDER BY o)
         = ARRAY(SELECT 'p' || g FROM generate_series(1, 14) g)
     AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(r -> 'parties') x
                      WHERE coalesce(x ->> 'titre', '') = '' OR coalesce(x ->> 'corps', '') = '')
$$;

-- Fixtures ------------------------------------------------------------------------------------------------------------------
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'lettre-serveur-' || x || '@test.invalid'
  FROM unnest(ARRAY['tut', 'elv', 'adm', 'cpt', 'ens', 'c0', 'c1', 'c3', 'sus', 'exp']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, access_until)
VALUES (pg_temp.id('tut'), 'LTS-TUT-0001', 'guardian', pg_temp.id('f'), 'Tuteur', 'Fictif', 'active', 'male', NULL),
       (pg_temp.id('elv'), 'LTS-ELV-0001', 'student', pg_temp.id('f'), 'Eleve', 'Fictif', 'active', 'male', NULL),
       (pg_temp.id('adm'), 'LTS-ADM-0001', 'admin', NULL, 'Direction', 'Fictive', 'active', 'male', NULL),
       (pg_temp.id('cpt'), 'LTS-CPT-0001', 'accountant', NULL, 'Comptable', 'Fictif', 'active', 'female', NULL),
       (pg_temp.id('ens'), 'LTS-ENS-0001', 'teacher', NULL, 'Enseignant', 'Actif', 'pending_kyc', 'male', NULL),
       (pg_temp.id('c0'), 'LTS-ENS-0002', 'teacher', NULL, 'Candidat', 'Zero', 'pending_kyc', 'female', NULL),
       (pg_temp.id('c1'), 'LTS-ENS-0003', 'teacher', NULL, 'Candidat', 'Un', 'pending_kyc', 'male', NULL),
       (pg_temp.id('c3'), 'LTS-ENS-0004', 'teacher', NULL, 'Candidat', 'Trois', 'pending_kyc', 'female', NULL),
       (pg_temp.id('sus'), 'LTS-ENS-0005', 'teacher', NULL, 'Enseignant', 'Desactive', 'pending_kyc', 'male', NULL),
       (pg_temp.id('exp'), 'LTS-ENS-0006', 'teacher', NULL, 'Enseignant', 'Expire', 'pending_kyc', 'male', NULL);
INSERT INTO public.teacher_profiles (profile_id)
SELECT pg_temp.id(x) FROM unnest(ARRAY['ens', 'c0', 'c1', 'c3', 'sus', 'exp']) AS x
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.id('k0'), 'enseignant', pg_temp.id('c0'), 'female', 'Candidat Zero', 'prequalification', 'a_completer', 'en_cours', false, 'lien_public'),
       (pg_temp.id('k1'), 'enseignant', pg_temp.id('c1'), 'male', 'Candidat Un', 'prequalification', 'a_completer', 'en_cours', false, 'lien_public'),
       (pg_temp.id('k3'), 'enseignant', pg_temp.id('c3'), 'female', 'Candidat Trois', 'prequalification', 'a_completer', 'en_cours', false, 'lien_public');

SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.contract_texts WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current)
  AND public.code_conduite_version_requise() IS NOT NULL
  AND public.cadre_religieux_version_requise() IS NOT NULL,
  'fixtures : un contrat courant, une version requise du code de conduite et du cadre religieux');

-- Les accords : c1 signe le contrat et le cadre (pas le code de conduite) ; c3 signe les trois ; les enseignants a activer
-- (ens, sus, exp) signent contrat, code de conduite et avis, que la garde d'activation exige.
-- Le contrat se signe par la personne connectee (garde de signature) : une signature par compte, sous son jeton.
DO $signer$
DECLARE
  x text;
BEGIN
  FOREACH x IN ARRAY ARRAY['c1', 'c3', 'ens', 'sus', 'exp'] LOOP
    PERFORM pg_temp.qui(pg_temp.id(x), 'teacher');
    SET LOCAL ROLE authenticated;
    INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
    SELECT pg_temp.id(x), 'teacher_nda', t.version
      FROM public.contract_texts t
     WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current;
    RESET ROLE;
  END LOOP;
END
$signer$;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.id(x), 'teacher_religious_framework', public.cadre_religieux_version_requise()
  FROM unnest(ARRAY['c1', 'c3']) AS x;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.id(x), 'teacher_conduct_code', public.code_conduite_version_requise()
  FROM unnest(ARRAY['c3', 'ens', 'sus', 'exp']) AS x;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.id(x), 'recording_and_control_notice', r.version
  FROM public.contract_required_versions r, unnest(ARRAY['ens', 'sus', 'exp']) AS x
 WHERE r.contract_kind = 'recording_and_control_notice';
-- Puis les statuts : actif, desactive, actif a l'acces expire.
UPDATE public.profiles SET account_status = 'active' WHERE id = pg_temp.id('ens');
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.id('sus');
UPDATE public.profiles SET account_status = 'active', access_until = pg_catalog.now() - interval '1 day'
 WHERE id = pg_temp.id('exp');

-- 1. Anonyme -----------------------------------------------------------------------------------------------------------------
SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE anon;
DO $anon$
BEGIN
  BEGIN
    PERFORM public.lire_lettre_candidats('fr');
    RAISE EXCEPTION 'LETTRE-SERVEUR ROUGE : anon a execute la lecture';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK anonyme : execution refusee (42501)';
  END;
  BEGIN
    PERFORM 1 FROM private.lettre_candidats_parties;
    RAISE EXCEPTION 'LETTRE-SERVEUR ROUGE : anon a lu la table';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK anonyme : lecture directe de la table refusee';
  END;
END
$anon$;
RESET ROLE;

-- 2. Les autres roles -----------------------------------------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('tut'), 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'role', NULL), 'tuteur : refus role, sans texte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('elv'), 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'role', NULL), 'eleve : refus role, sans texte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('adm'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'role', NULL), 'direction : refus role, sans texte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('cpt'), 'accountant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'role', NULL), 'comptable : refus role, sans texte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('ens'), NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'role', NULL), 'jeton sans role : refus role');
RESET ROLE;

-- 3. Enseignant actif -----------------------------------------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('ens'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats('fr'), 'fr'), 'enseignant actif : la lettre en francais, 14 parties');

-- 9. Langues (enseignant actif) ------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats('ar'), 'ar')
  AND public.lire_lettre_candidats('ar') -> 'parties' -> 0 ->> 'titre' = 'لماذا يصلك هذا الدليل',
  'langue ar : la lettre en arabe');
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats('en'), 'en')
  AND public.lire_lettre_candidats('en') -> 'parties' -> 0 ->> 'titre' = 'Why you are receiving this guide',
  'langue en : la lettre en anglais');
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats(' en-GB '), 'en'), 'langue en-GB : l''anglais');
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats('es'), 'fr')
  AND public.lire_lettre_candidats('es') -> 'parties' -> 0 ->> 'titre' = 'Pourquoi vous recevez ce guide',
  'langue inconnue (es) : repli sur le francais');
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats(NULL), 'fr'), 'langue nulle : le francais');
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats(''), 'fr'), 'langue vide : le francais');

-- 8. Lecture directe de la table, meme par un enseignant actif -----------------------------------------------------------------
DO $direct$
BEGIN
  PERFORM 1 FROM private.lettre_candidats_parties;
  RAISE EXCEPTION 'LETTRE-SERVEUR ROUGE : authenticated a lu la table';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK authenticated : lecture directe de la table refusee';
END
$direct$;
RESET ROLE;

-- 4. Candidat sans accord ------------------------------------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('c0'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'accords', ARRAY['contrat', 'conduite', 'cadre']),
  'candidat sans accord : refus accords, manques contrat, conduite, cadre');
RESET ROLE;

-- 5. Candidat a qui manque le code de conduite -----------------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('c1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('ar'), 'accords', ARRAY['conduite']),
  'candidat sans code de conduite : manques = conduite');
RESET ROLE;

-- 6. Candidat aux trois accords ------------------------------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('c3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.ouverte(public.lire_lettre_candidats('ar'), 'ar'), 'candidat aux trois accords : la lettre');
RESET ROLE;

-- Un cadre religieux neuf est publie : le candidat doit l'accepter de nouveau (la regle de etat_dossier, rien de recopie).
UPDATE public.contract_required_versions SET version = 'lettre-cadre-neuf'
 WHERE contract_kind = 'teacher_religious_framework';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'accords', ARRAY['cadre']),
  'cadre neuf publie : le candidat aux anciens accords voit manques = cadre');
RESET ROLE;

-- 7. Comptes fermes ------------------------------------------------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('sus'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'compte', NULL), 'compte desactive : refus compte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('exp'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'compte', NULL), 'acces expire : refus compte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('tut'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'compte', NULL),
  'jeton enseignant sur un profil de tuteur : refus compte');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('inconnu'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.refus(public.lire_lettre_candidats('fr'), 'compte', NULL), 'sans profil : refus compte');
RESET ROLE;

-- 10. Droits -------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.lire_lettre_candidats(text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.lire_lettre_candidats(text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.lire_lettre_candidats(text)', 'EXECUTE')
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.lettre_candidats_parties'::regclass)
  AND NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = 'private.lettre_candidats_parties'::regclass)
  AND NOT has_table_privilege('authenticated', 'private.lettre_candidats_parties', 'SELECT')
  AND NOT has_table_privilege('anon', 'private.lettre_candidats_parties', 'SELECT'),
  'droits : execution a authenticated seul ; table sous RLS, sans politique, sans droit client');

ROLLBACK;
