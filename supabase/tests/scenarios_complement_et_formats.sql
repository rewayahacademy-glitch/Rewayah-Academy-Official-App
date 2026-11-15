-- COMPLEMENT-ET-FORMATS (migration 20261126800000) : en salle 1, la direction
-- redemande tout ce que le candidat fournit, et le candidat lit la date de la
-- demande en cours.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. la liste de la salle 1 : les cartes du questionnaire, le cadre, puis
--      contrat, avis, code de conduite, piece, photo, accord de publication ;
--      la salle 2 ne change pas ;
--   2. sans demande, complementDemandeLe est nul ;
--   3. la direction demande la piece, la photo et l'accord de publication a
--      une candidature envoyee (transition 7) : accepte ;
--   4. le candidat lit la liste demandee et sa date ;
--   5. un code inconnu reste refuse (jamais un texte libre) ;
--   6. les aides internes restent fermees a anon.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('complement-formats-' || p)::uuid $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'complement-formats-' || x || '@test.invalid' FROM unnest(ARRAY['adm', 'cand']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('adm'), 'CEF-ADM-0001', 'admin', 'Direction', 'Essai', 'active', 'male'),
       (pg_temp.id('cand'), 'CEF-ENS-0001', 'teacher', 'Candidat', 'Essai', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.id('c1'), 'enseignant', pg_temp.id('cand'), 'male', 'Candidat Essai',
        'prequalification', 'en_examen', 'en_cours', false, 'lien_public');

-- 1. Les listes.
SELECT pg_temp.vrai(
  (SELECT x[array_position(x, 'cadre_religieux') : cardinality(x)]
     FROM (SELECT private.candidature_complement_codes('prequalification', 'enseignant') AS x) s)
    = ARRAY['cadre_religieux', 'contrat', 'avis', 'code_conduite', 'piece_identite', 'photo', 'accord_publication'],
  'salle 1 : le cadre puis les six documents et accords, dans l''ordre du parcours');
SELECT pg_temp.vrai(private.candidature_complement_codes('verifications', 'enseignant')
    = ARRAY['piece_identite', 'cadre_religieux', 'contrat', 'avis'],
  'salle 2 : inchangee');

-- 2. Sans demande : pas de date.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.id('cand'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$)
    -> 'complementDemandeLe' = 'null'::jsonb,
  'sans demande de complement : complementDemandeLe nul');

-- 3. La direction redemande la piece, la photo et l'accord de publication.
DO $demande$
DECLARE
  v jsonb := pg_temp.en(pg_temp.id('adm'), 'admin', pg_catalog.format(
    $q$SELECT public.demander_complement_candidat(%L, ARRAY['piece_identite', 'photo', 'accord_publication'],
       'Piece illisible', %s, 'cle-cef-0001')$q$,
    pg_temp.id('c1'), (SELECT version FROM public.candidatures WHERE id = pg_temp.id('c1'))));
BEGIN
  PERFORM pg_temp.vrai(v -> 'aCompleter' = '["piece_identite", "photo", "accord_publication"]'::jsonb
    AND v -> 'candidature' ->> 'etat' = 'a_completer',
    'transition 7 : piece, photo et accord de publication demandes ; la candidature repasse a completer');
END $demande$;

-- 4. Le candidat lit la liste et la date.
DO $lu$
DECLARE
  v jsonb := pg_temp.en(pg_temp.id('cand'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$);
BEGIN
  PERFORM pg_temp.vrai(v -> 'complementDemande' = '["piece_identite", "photo", "accord_publication"]'::jsonb
    AND (v ->> 'complementDemandeLe') IS NOT NULL
    AND (v ->> 'complementDemandeLe')::timestamptz
        = (SELECT max(e.cree_le) FROM public.candidature_evenements e
            WHERE e.candidature_id = pg_temp.id('c1') AND e.details ? 'aCompleter'),
    'le candidat lit la liste demandee et la date de la demande');
END $lu$;

-- 5. Un code inconnu reste refuse.
DO $inconnu$
DECLARE
  v jsonb;
BEGIN
  UPDATE public.candidatures SET etat = 'en_examen' WHERE id = pg_temp.id('c1');
  v := pg_temp.en(pg_temp.id('adm'), 'admin', pg_catalog.format(
    $q$SELECT public.demander_complement_candidat(%L, ARRAY['photo', 'Une phrase libre'], 'Motif', %s, 'cle-cef-0002')$q$,
    pg_temp.id('c1'), (SELECT version FROM public.candidatures WHERE id = pg_temp.id('c1'))));
  PERFORM pg_temp.vrai(v ->> 'erreur' = 'elements_invalides' AND v -> 'elements' = '["?"]'::jsonb,
    'un texte libre reste refuse');
END $inconnu$;

-- 6. Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'private.candidature_complement_codes(text,text)'::regprocedure, 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.candidature_etat_candidat()'::regprocedure, 'EXECUTE'),
  'aides internes fermees a anon');

ROLLBACK;
