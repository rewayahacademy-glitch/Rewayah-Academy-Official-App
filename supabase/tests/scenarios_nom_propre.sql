-- NOM-PROPRE (INCIDENT-CANDIDATS, 14/11/2026, migration 20261125950000).
-- Une candidate s'est inscrite avec « ٠ » (zero arabe) pour prenom et nom.
-- Prouve : la regle (toutes ecritures, harakat, apostrophes ; ni chiffre, ni
-- symbole, ni emoji ; au moins deux lettres) ; le declencheur ne controle que
-- le nom qu'une personne ecrit pour elle-meme ; un profil existant invalide
-- n'est pas casse ; mon_nom_a_corriger le dit ; corriger_mon_nom corrige,
-- refuse un nom invalide et journalise ; droits d'execution.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'NOM-PROPRE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('nom-propre-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RAISE EXCEPTION 'NOM-PROPRE ROUGE : % (accepte)', p_label;
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM LIKE 'NOM-PROPRE ROUGE%' THEN
    RAISE;
  END IF;
  IF SQLSTATE <> p_code OR pg_catalog.strpos(SQLERRM, p_message) = 0 THEN
    RAISE EXCEPTION 'NOM-PROPRE ROUGE : % (% % au lieu de % %)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.refus(text, text, text, text) TO authenticated;

-- 1. La regle.
SELECT pg_temp.vrai(
  private.nom_propre_valide('مُحَمَّد') AND private.nom_propre_valide('عبد الله')
  AND private.nom_propre_valide('Zoë-Anne d''Arc') AND private.nom_propre_valide('O’Neil')
  AND private.nom_propre_valide('Lê Văn') AND private.nom_propre_valide('Compte')
  AND private.nom_propre_valide('supprimé'),
  'lettres de toutes ecritures, harakat, trait d''union, apostrophes acceptes');
SELECT pg_temp.vrai(
  NOT private.nom_propre_valide('٠') AND NOT private.nom_propre_valide('Ali2')
  AND NOT private.nom_propre_valide('A') AND NOT private.nom_propre_valide('..')
  AND NOT private.nom_propre_valide('😀ab') AND NOT private.nom_propre_valide('')
  AND NOT private.nom_propre_valide(NULL) AND NOT private.nom_propre_valide('١٢٣'),
  'chiffres (latins et arabes), une seule lettre, ponctuation, emoji, vide refuses');

-- Fixtures : un profil existant invalide (cree par la base, comme un import
-- ou un compte d'avant la regle), et un compte sans profil.
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'nom-propre-' || x || '@test.invalid'
  FROM unnest(ARRAY['ancien', 'neuf', 'autre']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('ancien'), 'NOMPROPRE-ANCIEN', 'teacher', NULL, '٠', '٠', 'pending_kyc', 'female'),
       (pg_temp.id('autre'), 'NOMPROPRE-AUTRE', 'teacher', NULL, 'Autre', 'Personne', 'pending_kyc', 'male');
SELECT pg_temp.vrai(true, 'un profil invalide existant s''ecrit hors de la session de la personne (import, base)');

-- 2. Le profil existant n'est pas casse : un changement qui ne touche pas
-- le nom passe, meme par la personne elle-meme.
SELECT pg_temp.qui(pg_temp.id('ancien'), 'teacher');
UPDATE public.profiles SET updated_at = pg_catalog.now() WHERE id = pg_temp.id('ancien');
SELECT pg_temp.vrai(true, 'profil invalide existant : une mise a jour sans le nom passe');

-- 3. mon_nom_a_corriger le dit.
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.mon_nom_a_corriger() ->> 'a_corriger')::boolean,
  'mon_nom_a_corriger : le nom « ٠ » est a corriger');
-- 4. corriger_mon_nom refuse un nom invalide, puis corrige.
SELECT pg_temp.refus($$SELECT public.corriger_mon_nom('Asma2', 'Jamil')$$, '22023', 'nom_non_conforme',
  'corriger_mon_nom : un chiffre est refuse');
SELECT public.corriger_mon_nom(' أسماء ', 'جميل');
SELECT pg_temp.vrai(NOT (public.mon_nom_a_corriger() ->> 'a_corriger')::boolean
  AND public.mon_nom_a_corriger() ->> 'prenom' = 'أسماء',
  'corriger_mon_nom : nom corrige (espaces retires), plus rien a corriger');
-- 5. Ecrire soi-meme un nom invalide directement est refuse par le declencheur.
SELECT pg_temp.refus($$UPDATE public.profiles SET first_name = '٠' WHERE id = auth.uid()$$,
  '22023', 'nom_non_conforme', 'declencheur : la personne ne s''ecrit pas un nom invalide');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a
                             WHERE a.action = 'nom_corrige' AND a.row_id = pg_temp.id('ancien')::text
                               AND a.payload -> 'avant' ->> 'prenom' = '٠'),
  'corriger_mon_nom : une ligne d''audit avec l''avant et l''apres');

-- 6. Une inscription (profil cree par la personne elle-meme) au nom invalide
-- est refusee ; au nom valide, elle passe.
SELECT pg_temp.qui(pg_temp.id('neuf'), 'teacher');
DO $ins$
BEGIN
  BEGIN
    INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    VALUES (pg_temp.id('neuf'), 'NOMPROPRE-NEUF', 'teacher', NULL, '٠', '٠', 'pending_kyc', 'female');
    RAISE EXCEPTION 'NOM-PROPRE ROUGE : une inscription au nom « ٠ » est acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'OK inscription au nom invalide refusee';
  END;
END
$ins$;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('neuf'), 'NOMPROPRE-NEUF', 'teacher', NULL, 'Mariam', 'Diallo', 'pending_kyc', 'female');
SELECT pg_temp.vrai(true, 'inscription au nom valide acceptee');

-- 7. Le nom d'une AUTRE personne (direction, import) n'est pas controle par
-- le declencheur.
SELECT pg_temp.qui(pg_temp.id('neuf'), 'teacher');
UPDATE public.profiles SET first_name = 'X1' WHERE id = pg_temp.id('autre');
SELECT pg_temp.vrai((SELECT first_name FROM public.profiles WHERE id = pg_temp.id('autre')) = 'X1',
  'le nom d''une autre personne, ecrit par la base, n''est pas controle ici');

-- 8. Compte sans profil, anon, droits.
SELECT pg_temp.qui(pg_temp.id('sans-profil'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.mon_nom_a_corriger() ->> 'a_corriger')::boolean,
  'compte sans profil : rien a corriger');
SELECT pg_temp.refus($$SELECT public.corriger_mon_nom('Mariam', 'Diallo')$$, '42501', 'acces refuse',
  'compte sans profil : correction refusee');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.mon_nom_a_corriger()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.corriger_mon_nom(text,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.corriger_mon_nom(text,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.nom_propre_valide(text)', 'EXECUTE'),
  'droits : authenticated seul ; la regle n''est appelable par aucun compte');

ROLLBACK;
