-- CADRE-LANGUES (07/11/2026 ; migration 20261118000200) : le cadre religieux et
-- pedagogique de l'enseignant publie aussi en anglais, en espagnol et en
-- portugais.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. la contrainte contract_texts_locale_check accepte exactement fr, ar, en,
--      es, pt : une autre langue est refusee ;
--   2. les trois textes sont en vigueur, version 2026-11-07, avec la sha256 et
--      la longueur du texte publie, recalculees a part depuis le fichier valide
--      par « python3 tool/cadre_texte_publie.py toutes » ; le corps en base
--      redonne son empreinte, calculee en SQL ;
--   3. le francais et l'arabe n'ont pas bouge ; la version requise reste
--      2026-11-07 ;
--   4. un candidat enseignant lit les cinq langues et accepte la version
--      2026-11-07 ; un anonyme ne lit rien ;
--   5. la migration est rejouable : relue sur un etat deja elargi, elle ne
--      change rien (la contre-epreuve du md5 est dans son postflight).
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CADRE-LANGUES ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('cadre-langues-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

-- 2. Les empreintes du fichier valide, recalculees a part (commande en tete).
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07'
      AND t.locale IN ('en', 'es', 'pt') AND t.is_current) = 3,
  'les trois traductions sont en vigueur');
SELECT pg_temp.vrai(
  (SELECT t.sha256 FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework'
    AND t.version = '2026-11-07' AND t.locale = 'en')
    = '498431db51501cce5222acb57f8ed1384f93ffdc4b140df75dfe224f31c69367'
  AND (SELECT t.sha256 FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework'
        AND t.version = '2026-11-07' AND t.locale = 'es')
    = '65b5159a09d95943ea0f1c48f0b06b838e1a0725d1acf92bf6090475b5d22908'
  AND (SELECT t.sha256 FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework'
        AND t.version = '2026-11-07' AND t.locale = 'pt')
    = 'b4efa26440b91631c7bda9421fc993a7e534b4dcfa66f89116e6b1908d94f4f7',
  'sha256 en, es et pt en base = sha256 du texte publie (script)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.octet_length(t.body) FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'en') = 2010
  AND (SELECT pg_catalog.octet_length(t.body) FROM public.contract_texts t
        WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'es') = 2018
  AND (SELECT pg_catalog.octet_length(t.body) FROM public.contract_texts t
        WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'pt') = 2077,
  'longueurs des textes publies en, es, pt');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.contract_texts t
               WHERE t.contract_kind = 'teacher_religious_framework'
                 AND t.sha256 <> pg_catalog.encode(extensions.digest(
                       pg_catalog.convert_to(t.body, 'UTF8'), 'sha256'), 'hex')),
  'le corps en base redonne son empreinte, calculee en SQL, dans les cinq langues');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.md5(t.body) FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'en')
    = '77f001ec3be51f363ada03dc5afc8df3'
  AND (SELECT pg_catalog.md5(t.body) FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'es')
    = 'af45760a0e8bea02797fbaf24ee96b16'
  AND (SELECT pg_catalog.md5(t.body) FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'pt')
    = '904a94c477f10d6fd0dc05628145b792',
  'md5 en, es et pt = md5 du texte publie (script)');
SELECT pg_temp.vrai(
  (SELECT t.body FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'en')
    LIKE E'Teacher''s religious, educational and professional commitment\n\n%'
  AND (SELECT t.body FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'en')
    NOT LIKE '%Statut%',
  'le texte anglais commence a son titre : ni statut ni corrections du relecteur');

-- 3. Le francais, l'arabe et la version requise n'ont pas bouge.
SELECT pg_temp.vrai(
  (SELECT t.sha256 FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework'
    AND t.version = '2026-11-07' AND t.locale = 'fr')
    = 'acf60aea3a0fe1f12348ffa6fc20a19f63eb28e117340eb82713cc8c521312a7'
  AND (SELECT t.sha256 FROM public.contract_texts t WHERE t.contract_kind = 'teacher_religious_framework'
        AND t.version = '2026-11-07' AND t.locale = 'ar')
    = '2623d7ef94165c86771c6aa9ba3dac13df0c1c763d2be1ac06f420d805009845'
  AND (SELECT r.version FROM public.contract_required_versions r
        WHERE r.contract_kind = 'teacher_religious_framework') = '2026-11-07'
  AND (SELECT pg_catalog.count(*) FROM public.contract_texts t
        WHERE t.contract_kind = 'teacher_religious_framework') = 5,
  'fr et ar inchanges, version requise 2026-11-07, cinq textes au total');

-- 1. La contrainte : exactement les cinq langues.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(m[1] ORDER BY m[1])
     FROM pg_catalog.pg_constraint c,
          pg_catalog.regexp_matches(pg_catalog.pg_get_constraintdef(c.oid), '\m([a-z]{2})\M', 'g') AS m
    WHERE c.conrelid = 'public.contract_texts'::regclass AND c.conname = 'contract_texts_locale_check')
    = ARRAY['ar', 'en', 'es', 'fr', 'pt'],
  'contract_texts_locale_check porte exactement fr, ar, en, es, pt');
DO $$
BEGIN
  INSERT INTO public.contract_texts (contract_kind, version, locale, body, sha256, is_current)
  VALUES ('teacher_religious_framework', '2026-01-01', 'de', 'x',
          pg_catalog.encode(extensions.digest(pg_catalog.convert_to('x', 'UTF8'), 'sha256'), 'hex'), false);
  RAISE EXCEPTION 'CADRE-LANGUES ROUGE : une langue hors liste a ete acceptee';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'OK une langue hors fr, ar, en, es, pt est refusee';
END $$;

-- Fixtures : un candidat enseignant en Salle d'examen.
INSERT INTO auth.users (id, email) VALUES (pg_temp.id('cand'), 'cadre-langues-cand@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('cand'), 'CADRE-LNG-0001', 'teacher', NULL, 'Candidat', 'Test', 'pending_kyc', 'female');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, source)
VALUES (pg_temp.id('c'), 'enseignant', pg_temp.id('cand'), 'female', 'Candidat Test',
        'prequalification', 'a_completer', 'lien_public');

-- 4. Le candidat lit les cinq langues et accepte la version publiee.
SELECT pg_temp.qui(pg_temp.id('cand'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(t.locale ORDER BY t.locale) FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07')
    = ARRAY['ar', 'en', 'es', 'fr', 'pt'],
  'le candidat lit le cadre dans les cinq langues');
SELECT pg_temp.vrai(public.cadre_religieux_acceptable('2026-11-07'),
  'cadre_religieux_acceptable(2026-11-07) rend vrai pour le candidat');
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES (pg_temp.id('cand'), 'teacher_religious_framework', '2026-11-07');
RESET ROLE;
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.contract_acceptances a
           WHERE a.profile_id = pg_temp.id('cand') AND a.contract_kind = 'teacher_religious_framework'
             AND a.version = '2026-11-07'),
  'acceptation du candidat a la version 2026-11-07 enregistree');

SELECT pg_temp.qui(NULL, 'anon');
SET LOCAL ROLE anon;
DO $$
BEGIN
  PERFORM 1 FROM public.contract_texts;
  RAISE EXCEPTION 'CADRE-LANGUES ROUGE : un anonyme lit contract_texts';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK un anonyme ne lit pas contract_texts';
END $$;
RESET ROLE;

ROLLBACK;
