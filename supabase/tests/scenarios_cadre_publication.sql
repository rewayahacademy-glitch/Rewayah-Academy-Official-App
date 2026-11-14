-- CADRE-MIGRATIONS (07/11/2026 ; migrations 20261118000000 et
-- 20261118000100) : le cadre religieux et pedagogique de l'enseignant publie
-- en francais et en arabe.
--
-- Ce que le scenario prouve :
--   1. un candidat enseignant (Salle d'examen) lit les deux langues du texte
--      en vigueur ;
--   2. son acceptation a la version 2026-11-07 passe, et
--      cadre_religieux_acceptable('2026-11-07') rend vrai pour lui ;
--   3. une version inventee est refusee ;
--   4. un anonyme ne lit rien ; une personne connectee ne lit que les textes
--      en vigueur ;
--   5. la sha256 en base est celle du texte publie, recalculee a part
--      depuis le fichier valide par « python3 tool/cadre_texte_publie.py »
--      (normalisation en texte brut arbitree par le garde-cap le 07/11) ;
--      (et le corps en base redonne cette meme empreinte, calculee en SQL) ;
--   6. le contrat teacher_nda reste accepte en francais seulement (sa policy
--      d'insertion n'est pas touchee).
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CADRE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('cadre-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

-- 5. Les empreintes du fichier valide, recalculees a part (commande en tete).
SELECT pg_temp.vrai(
  (SELECT t.sha256 FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07' AND t.locale = 'fr')
    = 'acf60aea3a0fe1f12348ffa6fc20a19f63eb28e117340eb82713cc8c521312a7'
  AND (SELECT t.sha256 FROM public.contract_texts t
        WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07' AND t.locale = 'ar')
    = 'b0bb7668e35135c3df423ff96c271ecbacec17b9b10cbade6b0d1493a7a25ffb',
  'sha256 fr et ar en base = sha256 du texte publie (script)');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.contract_texts t
               WHERE t.contract_kind = 'teacher_religious_framework'
                 AND t.sha256 <> pg_catalog.encode(extensions.digest(
                       pg_catalog.convert_to(t.body, 'UTF8'), 'sha256'), 'hex')),
  'le corps en base redonne son empreinte, calculee en SQL');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.octet_length(t.body) FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'fr') = 2055
  AND (SELECT pg_catalog.octet_length(t.body) FROM public.contract_texts t
        WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'ar') = 2354
  AND (SELECT r.version FROM public.contract_required_versions r
        WHERE r.contract_kind = 'teacher_religious_framework') = '2026-11-07',
  'longueurs du texte publie, version requise 2026-11-07');

-- Fixtures : un candidat enseignant en Salle d'examen (compte en attente, le
-- seul que CAND-L1B permet), un tuteur actif.
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'cadre-' || x || '@test.invalid' FROM unnest(ARRAY['cand', 'tut']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('cand'), 'CADRE-ENS-0001', 'teacher', NULL, 'Candidat', 'Test', 'pending_kyc', 'female'),
       (pg_temp.id('tut'), 'CADRE-TUT-0001', 'guardian', pg_temp.id('f'), 'Tuteur', 'Test', 'active', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, source)
VALUES (pg_temp.id('c'), 'enseignant', pg_temp.id('cand'), 'female', 'Candidat Test',
        'prequalification', 'a_completer', 'lien_public');

-- 1. Le candidat lit les deux langues.
SELECT pg_temp.qui(pg_temp.id('cand'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(t.locale ORDER BY t.locale) FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_religious_framework' AND t.version = '2026-11-07')
    @> ARRAY['ar', 'fr'],
  'le candidat lit le cadre en francais et en arabe (20261118000200 y ajoute en, es, pt)');

-- 2. Son acceptation a la version publiee passe.
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

-- 3. Une version inventee est refusee.
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT public.cadre_religieux_acceptable('2099-01-01'),
  'cadre_religieux_acceptable(version inventee) rend faux');
DO $$
BEGIN
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES (pg_temp.id('cand'), 'teacher_religious_framework', '2099-01-01');
  RAISE EXCEPTION 'CADRE ROUGE : une version inventee a ete acceptee';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK une version inventee est refusee (RLS)';
END $$;
-- 6. Le contrat teacher_nda : jamais une acceptation hors francais (aucune
-- ligne nda en arabe n'existe, et sa policy lit locale = 'fr').
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.contract_texts t
                                 WHERE t.contract_kind = 'teacher_nda' AND t.locale <> 'fr'),
  'aucun contrat teacher_nda hors du francais');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.pg_get_expr(p.polwithcheck, p.polrelid) FROM pg_catalog.pg_policy p
    WHERE p.polrelid = 'public.contract_acceptances'::regclass
      AND p.polname = 'contract_acceptances_self_insert') LIKE '%(t.locale = ''fr''::text)%',
  'la policy d''acceptation du teacher_nda reste bornee au francais');

-- 4. Un anonyme ne lit rien ; une personne connectee ne lit que l'en vigueur.
SELECT pg_temp.qui(NULL, 'anon');
SET LOCAL ROLE anon;
DO $$
BEGIN
  PERFORM 1 FROM public.contract_texts;
  RAISE EXCEPTION 'CADRE ROUGE : un anonyme lit contract_texts';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK un anonyme ne lit pas contract_texts';
END $$;
RESET ROLE;
INSERT INTO public.contract_texts (contract_kind, version, locale, body, sha256, is_current)
VALUES ('teacher_religious_framework', '2026-01-01', 'fr', 'ancien texte',
        pg_catalog.encode(extensions.digest(pg_catalog.convert_to('ancien texte', 'UTF8'), 'sha256'), 'hex'),
        false);
SELECT pg_temp.qui(pg_temp.id('tut'), 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.contract_texts t WHERE NOT t.is_current)
  AND EXISTS (SELECT 1 FROM public.contract_texts t
               WHERE t.contract_kind = 'teacher_religious_framework' AND t.locale = 'ar'),
  'une personne connectee ne lit que les textes en vigueur, toutes langues');
RESET ROLE;

ROLLBACK;
