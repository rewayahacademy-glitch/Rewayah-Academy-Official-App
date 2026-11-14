-- AUDIT-PORTAIL-CANDIDAT (migration 20261126700000) : etat_dossier() lit le
-- contrat et l'avis de l'enseignant a la regle de la salle 3, et
-- lire_candidature() rend les controles du dossier.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. un candidat qui a signe le contrat courant et l'avis requis : signes ;
--   2. une nouvelle version du contrat est publiee : contrat_signe redevient
--      faux (avant : vrai pour toujours, et la salle 3 refusait sans chemin) ;
--   3. un avis a une version qui n'est plus requise : accuse_signe faux ;
--   4. un tuteur garde la regle d'avant (toute version de ses conditions) ;
--   5. lire_candidature : controles nommes cadre, accords (premier manquant en
--      cause), piece (cause), et, apres l'envoi, questionnaire et versement ;
--   6. l'aide interne n'est executable par aucun role client.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'AUDIT-PORTAIL-CANDIDAT ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('audit-portail-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'audit-portail-' || x || '@test.invalid' FROM unnest(ARRAY['cand', 'tut']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('cand'), 'APC-ENS-0001', 'teacher', NULL, 'Candidat', 'Audit', 'pending_kyc', 'female'),
       (pg_temp.id('tut'), 'APC-TUT-0001', 'guardian', pg_temp.id('f'), 'Tuteur', 'Audit', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id) VALUES (pg_temp.id('cand'))
  ON CONFLICT (profile_id) DO NOTHING;

SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.contract_texts
                             WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current)
  AND EXISTS (SELECT 1 FROM public.contract_required_versions
               WHERE contract_kind = 'recording_and_control_notice'),
  'fixtures : un contrat courant et une version requise de l''avis');

-- 1. Le candidat signe le contrat courant et l'avis requis.
SELECT pg_temp.qui(pg_temp.id('cand'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.id('cand'), 'teacher_nda', t.version
  FROM public.contract_texts t
 WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current;
RESET ROLE;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.id('cand'), 'recording_and_control_notice', r.version
  FROM public.contract_required_versions r WHERE r.contract_kind = 'recording_and_control_notice';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etat_dossier() ->> 'contrat_signe')::boolean
  AND (public.etat_dossier() ->> 'accuse_signe')::boolean,
  'contrat courant et avis requis signes : vrai et vrai');
RESET ROLE;

-- 2. Une nouvelle version du contrat est publiee : a signer de nouveau.
UPDATE public.contract_texts SET is_current = false
 WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current;
INSERT INTO public.contract_texts (contract_kind, version, locale, body, sha256, is_current)
VALUES ('teacher_nda', 'audit-nouvelle', 'fr', 'Texte neuf',
        encode(extensions.digest(convert_to('Texte neuf', 'UTF8'), 'sha256'), 'hex'), true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.etat_dossier() ->> 'contrat_signe')::boolean,
  'nouvelle version du contrat : contrat_signe faux, la page des accords le redemande');
RESET ROLE;

-- 3. L'avis a une version qui n'est plus requise.
UPDATE public.contract_required_versions SET version = 'audit-avis-neuf'
 WHERE contract_kind = 'recording_and_control_notice';
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.etat_dossier() ->> 'accuse_signe')::boolean,
  'avis a une version qui n''est plus requise : accuse_signe faux');
RESET ROLE;

-- 4. Le tuteur garde la regle d'avant.
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES (pg_temp.id('tut'), 'guardian_terms', 'une-version-quelconque'),
       (pg_temp.id('tut'), 'recording_and_control_notice', 'une-version-quelconque');
SELECT pg_temp.qui(pg_temp.id('tut'), 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etat_dossier() ->> 'contrat_signe')::boolean
  AND (public.etat_dossier() ->> 'accuse_signe')::boolean,
  'tuteur : toute version de ses conditions et de l''avis compte, comme avant');
RESET ROLE;

-- 5. Les controles du dossier (lus par l'aide interne, sous la garde de
--    lire_candidature ; la garde elle-meme est prouvee par CAND-L1).
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.id('c1'), 'enseignant', pg_temp.id('cand'), 'female', 'Candidat Audit',
        'prequalification', 'a_completer', 'en_cours', false, 'lien_public');
DO $controles$
DECLARE
  r jsonb := private.candidature_controles_dossier(
    (SELECT c FROM public.candidatures c WHERE c.id = pg_temp.id('c1')));
BEGIN
  PERFORM pg_temp.vrai(
    (SELECT array_agg(x ->> 'nom' ORDER BY o) FROM jsonb_array_elements(r) WITH ORDINALITY AS e(x, o))
      = ARRAY['cadre_religieux', 'accords_signes', 'piece_validee'],
    'a completer : cadre, accords, piece (pas de questionnaire ni de versement avant l''envoi)');
  PERFORM pg_temp.vrai(r -> 1 ->> 'cause' = 'teacher_nda' AND r -> 2 ->> 'cause' = 'piece_absente',
    'causes : le contrat a resigner, aucune piece');
END $controles$;
-- La piece deposee, puis refusee par la direction (le depot nait en attente).
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
VALUES (pg_temp.id('cand'), 'passport', 'female', 'audit/piece.jpg');
UPDATE public.kyc_documents SET status = 'rejected' WHERE profile_id = pg_temp.id('cand');
DO $piece$
DECLARE
  r jsonb := private.candidature_controles_dossier(
    (SELECT c FROM public.candidatures c WHERE c.id = pg_temp.id('c1')));
BEGIN
  PERFORM pg_temp.vrai(r -> 2 ->> 'cause' = 'piece_a_redeposer',
    'piece refusee : a deposer de nouveau');
END $piece$;
UPDATE public.candidatures SET etat = 'en_examen' WHERE id = pg_temp.id('c1');
DO $envoi$
DECLARE
  r jsonb := private.candidature_controles_dossier(
    (SELECT c FROM public.candidatures c WHERE c.id = pg_temp.id('c1')));
BEGIN
  PERFORM pg_temp.vrai(
    (SELECT array_agg(x ->> 'nom' ORDER BY o) FROM jsonb_array_elements(r) WITH ORDINALITY AS e(x, o))
      = ARRAY['cadre_religieux', 'accords_signes', 'piece_validee', 'questionnaire_complet', 'paiement_compatible'],
    'apres l''envoi : questionnaire et versement en plus');
END $envoi$;
-- 6. Droits.
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated',
    'private.candidature_controles_dossier(public.candidatures)'::regprocedure, 'EXECUTE')
  AND NOT has_function_privilege('anon',
    'private.candidature_controles_dossier(public.candidatures)'::regprocedure, 'EXECUTE')
  AND coalesce(obj_description('public.lire_candidature(uuid)'::regprocedure, 'pg_proc'), '')
      LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.lire_candidature(uuid)'::regprocedure)) || '%'
  AND coalesce(obj_description('public.etat_dossier()'::regprocedure, 'pg_proc'), '')
      LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.etat_dossier()'::regprocedure)) || '%',
  'aide interne fermee aux clients ; empreintes F86 de lire_candidature et etat_dossier a jour');

ROLLBACK;
