-- GUIDE-AVIS (migration 20261130971000) : les « J'aime » et « Pas clair » du guide de l'enseignant.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. anonyme : aucun droit d'execution ;
--   2. tuteur, et candidat sans ses accords : 42501, sans une ligne ;
--   3. enseignant actif : 14 parties p1 a p14 a zero, aucun commentaire (commentaires_ouverts : voir scenarios_guide_commentaires) ;
--   4. deux enseignants : « J'aime » puis « Pas clair » sur p4 donnent jaime 1, pas_clair 1, chacun son mon_avis ;
--   5. changer d'avis remplace l'avis (jamais deux) ; retirer (NULL) le remet a zero, la ligne reste (jamais d'effacement) ;
--   6. avis inconnu et partie inconnue : 22023 ;
--   7. lecture directe de la table refusee a authenticated ;
--   8. droits : EXECUTE a authenticated seul, aides privees fermees, RLS active sans politique.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'GUIDE-AVIS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('guide-avis-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', CASE WHEN p_id IS NULL THEN '' ELSE pg_catalog.json_build_object(
    'sub', p_id, 'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text END, true);
END $$;

-- L'etat SQL d'un appel fait sous le jeton de [p_id] : 'ok' ou le code d'erreur.
CREATE FUNCTION pg_temp.code(p_id uuid, p_role text, p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  SET LOCAL ROLE authenticated;
  BEGIN
    EXECUTE p_sql;
    RESET ROLE;
    RETURN 'ok';
  EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    RETURN SQLSTATE;
  END;
END $$;

-- La reponse d'un appel fait sous le jeton de [p_id].
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE
  r jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  SET LOCAL ROLE authenticated;
  EXECUTE p_sql INTO r;
  RESET ROLE;
  RETURN r;
END $$;

-- Fixtures ------------------------------------------------------------------------------------------------------------------
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'guide-avis-' || x || '@test.invalid' FROM unnest(ARRAY['tut', 'ens', 'en2', 'c0']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, access_until)
VALUES (pg_temp.id('tut'), 'GAV-TUT-0001', 'guardian', pg_temp.id('f'), 'Tuteur', 'Fictif', 'active', 'male', NULL),
       (pg_temp.id('ens'), 'GAV-ENS-0001', 'teacher', NULL, 'Enseignant', 'Un', 'pending_kyc', 'male', NULL),
       (pg_temp.id('en2'), 'GAV-ENS-0002', 'teacher', NULL, 'Enseignante', 'Deux', 'pending_kyc', 'female', NULL),
       (pg_temp.id('c0'), 'GAV-ENS-0003', 'teacher', NULL, 'Candidat', 'Zero', 'pending_kyc', 'male', NULL);
INSERT INTO public.teacher_profiles (profile_id)
SELECT pg_temp.id(x) FROM unnest(ARRAY['ens', 'en2', 'c0']) AS x
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.id('k0'), 'enseignant', pg_temp.id('c0'), 'male', 'Candidat Zero', 'prequalification', 'a_completer',
        'en_cours', false, 'lien_public');

-- Les deux enseignants a activer signent ce que la garde d'activation exige, puis passent actifs.
DO $signer$
DECLARE
  x text;
BEGIN
  FOREACH x IN ARRAY ARRAY['ens', 'en2'] LOOP
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
SELECT pg_temp.id(x), 'teacher_conduct_code', public.code_conduite_version_requise()
  FROM unnest(ARRAY['ens', 'en2']) AS x;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.id(x), 'recording_and_control_notice', r.version
  FROM public.contract_required_versions r, unnest(ARRAY['ens', 'en2']) AS x
 WHERE r.contract_kind = 'recording_and_control_notice';
UPDATE public.profiles SET account_status = 'active' WHERE id IN (pg_temp.id('ens'), pg_temp.id('en2'));

-- 1. Anonyme ----------------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.lire_interactions_guide()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.donner_avis_guide(text,text)', 'EXECUTE'),
  'anon : aucun droit d''execution');

-- 2. Refus ------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('tut'), 'guardian', 'SELECT public.lire_interactions_guide()') = '42501'
  AND pg_temp.code(pg_temp.id('tut'), 'guardian', 'SELECT public.donner_avis_guide(''p1'', ''jaime'')') = '42501',
  'tuteur : 42501');
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('c0'), 'teacher', 'SELECT public.lire_interactions_guide()') = '42501'
  AND pg_temp.code(pg_temp.id('c0'), 'teacher', 'SELECT public.donner_avis_guide(''p1'', ''jaime'')') = '42501',
  'candidat sans ses accords : 42501');
SELECT pg_temp.vrai((SELECT count(*) FROM private.guide_avis) = 0, 'aucun refus n''a ecrit une ligne');

-- 3. Lecture a zero ---------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(r -> 'parties') = 14
      AND ARRAY(SELECT x ->> 'code' FROM jsonb_array_elements(r -> 'parties') WITH ORDINALITY e(x, o) ORDER BY o)
          = ARRAY(SELECT 'p' || g FROM generate_series(1, 14) g)
      AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(r -> 'parties') x
                       WHERE (x ->> 'jaime')::int <> 0 OR (x ->> 'pas_clair')::int <> 0 OR x ->> 'mon_avis' IS NOT NULL)
      AND r -> 'commentaires' = '[]'::jsonb
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.lire_interactions_guide()') AS r) s),
  'enseignant actif : 14 parties a zero, aucun commentaire');

-- 4. Deux avis --------------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT r = '{"code": "p4", "jaime": 1, "pas_clair": 0, "mon_avis": "jaime"}'::jsonb
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(''p4'', ''jaime'')') AS r) s),
  'J''aime : la ligne a jour');
SELECT pg_temp.vrai(
  (SELECT r = '{"code": "p4", "jaime": 1, "pas_clair": 1, "mon_avis": "pas_clair"}'::jsonb
     FROM (SELECT pg_temp.en(pg_temp.id('en2'), 'teacher', 'SELECT public.donner_avis_guide(''p4'', ''pas_clair'')') AS r) s),
  'Pas clair d''un second lecteur : les deux totaux, son avis');
SELECT pg_temp.vrai(
  (SELECT x = '{"code": "p4", "jaime": 1, "pas_clair": 1, "mon_avis": "jaime"}'::jsonb
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.lire_interactions_guide()') AS r) s,
          jsonb_array_elements(s.r -> 'parties') x
    WHERE x ->> 'code' = 'p4'),
  'la lecture rend les totaux et l''avis du premier lecteur');

-- 5. Changer d'avis, le retirer ----------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT r = '{"code": "p4", "jaime": 0, "pas_clair": 2, "mon_avis": "pas_clair"}'::jsonb
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(''p4'', ''pas_clair'')') AS r) s),
  'changer d''avis remplace l''avis');
SELECT pg_temp.vrai(
  (SELECT r = '{"code": "p4", "jaime": 0, "pas_clair": 1, "mon_avis": null}'::jsonb
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(''p4'', NULL)') AS r) s),
  'retirer son avis');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM private.guide_avis) = 2
  AND (SELECT avis FROM private.guide_avis WHERE profil_id = pg_temp.id('ens') AND partie = 'p4') IS NULL,
  'une ligne par lecteur et par partie ; l''avis retire reste une ligne a NULL');

-- 6. Valeurs refusees -------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(''p4'', ''adore'')') = '22023'
  AND pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(''p99'', ''jaime'')') = '22023'
  AND pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(NULL, ''jaime'')') = '22023',
  'avis inconnu, partie inconnue ou nulle : 22023');

-- 7. Table fermee -----------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT count(*) FROM private.guide_avis') = '42501',
  'lecture directe de la table refusee');

-- 8. Droits -----------------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.lire_interactions_guide()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.donner_avis_guide(text,text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.donner_avis_guide(text,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.guide_avis_acces()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.guide_avis_ligne(text)', 'EXECUTE')
  AND (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.guide_avis'::regclass)
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = 'private.guide_avis'::regclass),
  'droits : authenticated seul, aides fermees, RLS sans politique');

ROLLBACK;
