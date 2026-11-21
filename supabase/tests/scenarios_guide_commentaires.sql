-- GUIDE-COMMENTAIRES (migration 20261130972000) : commentaires prives du guide, lus et repondus par la direction.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. anonyme : aucun droit ; tuteur et candidat sans accords : 42501 pour commenter ;
--   2. un enseignant commente p4 ; un second commente p4 ; chacun ne lit que son fil, commentaires_ouverts vrai ;
--   3. la direction lit p4 en tete (le plus de « Pas clair »), deux fils avec les noms ; un enseignant ne lit pas la liste ;
--   4. la direction repond : la reponse entre dans le seul fil du lecteur, auteur « direction » ;
--   5. corps vide ou trop long, partie inconnue : 22023 ; table fermee aux roles clients.
BEGIN;


CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'GUIDE-COMMENTAIRES ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('guide-com-' || p)::uuid $$;

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
SELECT pg_temp.id(x), 'guide-com-' || x || '@test.invalid' FROM unnest(ARRAY['tut', 'ens', 'en2', 'c0', 'adm']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, access_until)
VALUES (pg_temp.id('tut'), 'GAV-TUT-0001', 'guardian', pg_temp.id('f'), 'Tuteur', 'Fictif', 'active', 'male', NULL),
       (pg_temp.id('ens'), 'GAV-ENS-0001', 'teacher', NULL, 'Enseignant', 'Un', 'pending_kyc', 'male', NULL),
       (pg_temp.id('en2'), 'GAV-ENS-0002', 'teacher', NULL, 'Enseignante', 'Deux', 'pending_kyc', 'female', NULL),
       (pg_temp.id('c0'), 'GAV-ENS-0003', 'teacher', NULL, 'Candidat', 'Zero', 'pending_kyc', 'male', NULL),
       (pg_temp.id('adm'), 'GAV-ADM-0001', 'admin', NULL, 'Direction', 'Fictive', 'active', 'male', NULL);
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


-- Un « Pas clair » sur p4 pour que p4 passe en tete de la liste de la direction.
SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.donner_avis_guide(''p4'', ''pas_clair'')');

-- 1. Refus ------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.commenter_guide(text,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.commentaires_guide_direction()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.repondre_commentaire_guide(uuid,text)', 'EXECUTE'),
  'anon : aucun droit');
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('tut'), 'guardian', 'SELECT public.commenter_guide(''p4'', ''Bonjour'')') = '42501'
  AND pg_temp.code(pg_temp.id('c0'), 'teacher', 'SELECT public.commenter_guide(''p4'', ''Bonjour'')') = '42501',
  'tuteur et candidat sans accords : 42501');

-- 2. Les lecteurs commentent ------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT r ->> 'auteur' = 'moi' AND r ->> 'partie' = 'p4' AND r ->> 'corps' = 'Et pour les adultes ?'
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher',
             'SELECT public.commenter_guide(''p4'', ''  Et pour les adultes ?  '')') AS r) s),
  'commenter : le commentaire cree, sans espaces autour');
SELECT pg_temp.en(pg_temp.id('en2'), 'teacher', 'SELECT public.commenter_guide(''p4'', ''Question deux'')');
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(r -> 'commentaires') = 1 AND r -> 'commentaires_ouverts' = 'true'::jsonb
          AND r #>> '{commentaires,0,corps}' = 'Et pour les adultes ?'
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.lire_interactions_guide()') AS r) s),
  'chaque lecteur ne lit que son fil ; commentaires ouverts');

-- 3. La direction lit -------------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT public.commentaires_guide_direction()') = '42501',
  'un enseignant ne lit pas la liste de la direction');
SELECT pg_temp.vrai(
  (SELECT r #>> '{parties,0,code}' = 'p4' AND (r #>> '{parties,0,pas_clair}')::int = 1
          AND jsonb_array_length(r #> '{parties,0,fils}') = 2
          AND jsonb_array_length(r -> 'parties') = 14
          AND r::text LIKE '%Enseignant Un%' AND r::text LIKE '%Enseignante Deux%'
     FROM (SELECT pg_temp.en(pg_temp.id('adm'), 'admin', 'SELECT public.commentaires_guide_direction()') AS r) s),
  'la direction : p4 en tete, deux fils nommes, 14 parties');

-- 4. La direction repond ----------------------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT r ->> 'auteur' = 'direction'
     FROM (SELECT pg_temp.en(pg_temp.id('adm'), 'admin', pg_catalog.format(
             'SELECT public.repondre_commentaire_guide(%L, %L)',
             (SELECT id FROM private.guide_commentaires WHERE lecteur_id = pg_temp.id('ens')), 'Oui, la meme regle.')) AS r) s),
  'repondre : auteur direction');
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(r -> 'commentaires') = 2 AND r #>> '{commentaires,1,auteur}' = 'direction'
     FROM (SELECT pg_temp.en(pg_temp.id('ens'), 'teacher', 'SELECT public.lire_interactions_guide()') AS r) s)
  AND (SELECT jsonb_array_length(r -> 'commentaires') = 1
     FROM (SELECT pg_temp.en(pg_temp.id('en2'), 'teacher', 'SELECT public.lire_interactions_guide()') AS r) s),
  'la reponse entre dans le seul fil du lecteur');

-- 5. Valeurs refusees, table fermee -----------------------------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT public.commenter_guide(''p4'', ''   '')') = '22023'
  AND pg_temp.code(pg_temp.id('ens'), 'teacher', pg_catalog.format('SELECT public.commenter_guide(''p4'', %L)', repeat('x', 2001))) = '22023'
  AND pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT public.commenter_guide(''p99'', ''Bonjour'')') = '22023'
  AND pg_temp.code(pg_temp.id('ens'), 'teacher', 'SELECT count(*) FROM private.guide_commentaires') = '42501',
  'corps vide ou trop long, partie inconnue : 22023 ; table fermee');

ROLLBACK;
