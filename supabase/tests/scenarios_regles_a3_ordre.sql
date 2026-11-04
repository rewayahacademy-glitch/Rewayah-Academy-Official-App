-- REGLES-A3 (01/11/2026) : les trois delais de la regle A3 se reglent dans
-- Configuration > Regles ; le serveur exige leur ordre.
-- Migration 20261104200000_reglages_remplacement_ordre.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle), ecrit comme l'ecran
-- Regles (UPDATE direct de app_config sous le role de la direction) et annule
-- tout a la fin.
--   (a) les trois delais sont presents : 3, 8 et 11 ;
--   (b) forme : un entier de 0 a 999, ecrit en entier ;
--   (c) ordre : avertissement < perte < objectif, refus en exigence positive ;
--   (d) l'enchainement de la direction : la perte au-dela de l'objectif est
--       refusee ; l'objectif releve d'abord, la perte passe ensuite ; et
--       l'inverse pour descendre ; le journal garde chaque changement ;
--   (e) le passage de la minute A3 lit les nouvelles valeurs sans erreur ;
--   (f) personne d'autre que la direction active ne change un delai ;
--   (g) le nom d'un delai ne se change pas ;
--   (h) droits et forme du declencheur.
-- Chaque controle leve 'REGLES-A3 ROUGE : ...' s'il echoue.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'REGLES-A3 ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Un appel doit etre refuse avec ce SQLSTATE et un message qui commence ainsi.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'REGLES-A3 ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE IS DISTINCT FROM p_code OR SQLERRM NOT LIKE p_message || '%' THEN
      RAISE EXCEPTION 'REGLES-A3 ROUGE : % (%, « % » au lieu de %, « % »)',
        p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Lectures hors RLS (le proprietaire du scenario).
CREATE FUNCTION pg_temp.delai(p_cle text) RETURNS jsonb
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT value FROM public.app_config WHERE key = 'remplacement.' || p_cle;
$$;
CREATE FUNCTION pg_temp.trio() RETURNS text
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT pg_temp.delai('avertissement_minutes')::text || '/' ||
         pg_temp.delai('perte_acces_minutes')::text || '/' ||
         pg_temp.delai('debut_remplacant_minutes')::text;
$$;
CREATE FUNCTION pg_temp.journal() RETURNS text[]
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT coalesce(array_agg(pg_catalog.replace(key, 'remplacement.', '') || ':' ||
                            old_value::text || '>' || new_value::text ORDER BY id), ARRAY[]::text[])
    FROM public.app_config_history WHERE key LIKE 'remplacement.%';
$$;

-- Ecrire comme l'ecran Regles : un UPDATE direct, updated_by = soi.
CREATE FUNCTION pg_temp.poser(p_cle text, p_valeur jsonb) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.app_config SET value = p_valeur, updated_by = auth.uid()
   WHERE key = 'remplacement.' || p_cle;
END $$;

-- ------------------------------------------------------------------
-- Fixtures : une direction active, une direction desactivee, un enseignant.
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email)
SELECT ('a3a50000-0000-4000-8000-0000000000' || x.k)::uuid, 'regles-a3-' || x.k || '@example.test'
  FROM (VALUES ('01'), ('02'), ('a1')) x(k);

INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('a3a50000-0000-4000-8000-000000000001', 'REGA3ADMIN00001', 'admin', 'Fixture', 'Direction', 'active', 'female'),
  ('a3a50000-0000-4000-8000-000000000002', 'REGA3ADMIN00002', 'admin', 'Fixture', 'Desactivee', 'disabled', 'male'),
  ('a3a50000-0000-4000-8000-0000000000a1', 'REGA3TEACHER0A1', 'teacher', 'Fixture', 'Enseignant', 'provisional_active', 'male');

-- ------------------------------------------------------------------
-- (a) Presents
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.trio() = '3/8/11' AND pg_temp.journal() = ARRAY[]::text[],
  '(a) les trois delais valent 3, 8 et 11 ; aucun changement journalise');

-- ------------------------------------------------------------------
-- (b) Forme, sous la direction active
-- ------------------------------------------------------------------
SELECT pg_temp.qui('a3a50000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT pg_temp.poser('perte_acces_minutes', '9.5'::jsonb)$$,
  '22023', 'delai de remplacement : un nombre entier de minutes', '(b) 9,5 est refuse');
SELECT pg_temp.refus($$SELECT pg_temp.poser('perte_acces_minutes', '"9"'::jsonb)$$,
  '22023', 'delai de remplacement : un nombre entier de minutes', '(b) un texte est refuse');
SELECT pg_temp.refus($$SELECT pg_temp.poser('perte_acces_minutes', 'null'::jsonb)$$,
  '22023', 'delai de remplacement : un nombre entier de minutes', '(b) null est refuse');
SELECT pg_temp.refus($$SELECT pg_temp.poser('avertissement_minutes', '-1'::jsonb)$$,
  '22023', 'delai de remplacement : un nombre entier de minutes', '(b) un nombre negatif est refuse');
SELECT pg_temp.refus($$SELECT pg_temp.poser('debut_remplacant_minutes', '1000'::jsonb)$$,
  '22023', 'delai de remplacement : un nombre entier de minutes', '(b) 1000 est refuse');
SELECT pg_temp.poser('perte_acces_minutes', '9.0'::jsonb);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.delai('perte_acces_minutes') = '9'::jsonb
                    AND pg_catalog.jsonb_typeof(pg_temp.delai('perte_acces_minutes')) = 'number',
  '(b) 9.0 est ecrit en entier : 9');

-- ------------------------------------------------------------------
-- (c) Ordre
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT pg_temp.poser('avertissement_minutes', '9'::jsonb)$$,
  '22023', 'delais de remplacement : l''avertissement doit venir avant la perte de la seance (avertissement 9 min, perte 9 min',
  '(c) avertissement egal a la perte : refuse, avec les minutes');
SELECT pg_temp.refus($$SELECT pg_temp.poser('debut_remplacant_minutes', '9'::jsonb)$$,
  '22023', 'delais de remplacement : la perte de la seance doit venir avant le remplacant dans la salle (perte 9 min, objectif 9 min',
  '(c) objectif egal a la perte : refuse, avec les minutes');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.trio() = '3/9/11', '(c) apres les refus, rien n''a change : 3, 9, 11');

-- ------------------------------------------------------------------
-- (d) L'enchainement : monter la perte au-dela de l'objectif, puis redescendre
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT pg_temp.poser('perte_acces_minutes', '15'::jsonb)$$,
  '22023', 'delais de remplacement : la perte de la seance doit venir avant le remplacant dans la salle (perte 15 min, objectif 11 min',
  '(d) la perte a 15 avec l''objectif a 11 : refusee');
SELECT pg_temp.poser('debut_remplacant_minutes', '20'::jsonb);
SELECT pg_temp.poser('perte_acces_minutes', '15'::jsonb);
SELECT pg_temp.poser('avertissement_minutes', '10'::jsonb);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.trio() = '10/15/20',
  '(d) objectif releve a 20 d''abord, puis perte a 15, puis avertissement a 10 : 10, 15, 20');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT pg_temp.poser('debut_remplacant_minutes', '12'::jsonb)$$,
  '22023', 'delais de remplacement : la perte de la seance doit venir avant le remplacant dans la salle (perte 15 min, objectif 12 min',
  '(d) l''objectif a 12 avec la perte a 15 : refuse');
SELECT pg_temp.poser('avertissement_minutes', '3'::jsonb);
SELECT pg_temp.poser('perte_acces_minutes', '8'::jsonb);
SELECT pg_temp.poser('debut_remplacant_minutes', '11'::jsonb);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.trio() = '3/8/11',
  '(d) pour descendre : avertissement, perte, puis objectif : retour a 3, 8, 11');
SELECT pg_temp.vrai(pg_temp.journal() = ARRAY[
    'perte_acces_minutes:8>9',
    'debut_remplacant_minutes:11>20', 'perte_acces_minutes:9>15', 'avertissement_minutes:3>10',
    'avertissement_minutes:10>3', 'perte_acces_minutes:15>8', 'debut_remplacant_minutes:20>11'],
  '(d) le journal garde chaque changement accepte, et aucun refus');
SELECT pg_temp.vrai((SELECT bool_and(changed_by = 'a3a50000-0000-4000-8000-000000000001')
                       FROM public.app_config_history WHERE key LIKE 'remplacement.%'),
  '(d) chaque ligne du journal porte la direction comme auteur');

-- ------------------------------------------------------------------
-- (e) Le passage de la minute lit les delais sans erreur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_catalog.jsonb_typeof(private.remplacement_auto_passer(now())) = 'object',
  '(e) private.remplacement_auto_passer passe avec les delais en vigueur');

-- ------------------------------------------------------------------
-- (f) Personne d'autre ne change un delai
-- ------------------------------------------------------------------
SELECT pg_temp.qui('a3a50000-0000-4000-8000-000000000002', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.poser('perte_acces_minutes', '9'::jsonb);
RESET ROLE;
SELECT pg_temp.qui('a3a50000-0000-4000-8000-0000000000a1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.poser('perte_acces_minutes', '9'::jsonb);
RESET ROLE;
SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE anon;
DO $anon$
BEGIN
  UPDATE public.app_config SET value = '9'::jsonb WHERE key = 'remplacement.perte_acces_minutes';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END
$anon$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.trio() = '3/8/11' AND pg_catalog.array_length(pg_temp.journal(), 1) = 7,
  '(f) une direction desactivee, un enseignant et un visiteur ne changent rien');

-- ------------------------------------------------------------------
-- (g) Le nom ne change pas
-- ------------------------------------------------------------------
SELECT pg_temp.refus($$UPDATE public.app_config SET key = 'remplacement.autre' WHERE key = 'remplacement.perte_acces_minutes'$$,
  '42501', 'le reglage remplacement.perte_acces_minutes garde son nom', '(g) un delai ne se renomme pas');

-- ------------------------------------------------------------------
-- (h) Droits et forme
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.reglages_remplacement_valider()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.reglages_remplacement_valider()', 'EXECUTE')
  AND 'app_config_delais_remplacement' COLLATE "C" < 'app_config_history' COLLATE "C"
  AND EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t WHERE t.tgrelid = 'public.app_config'::regclass
                AND t.tgname = 'app_config_delais_remplacement' AND t.tgenabled = 'O'),
  '(h) aucun EXECUTE client ; declencheur actif, avant le journal');

SELECT pg_temp.vrai(coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int >= 19,
  'au moins 19 controles ont passe (20 avec celui-ci)');

ROLLBACK;
