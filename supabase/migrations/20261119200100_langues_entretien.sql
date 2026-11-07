-- SALLE-2-ENTRETIEN (07/11/2026) : les langues d'un creneau d'entretien sont
-- celles que le candidat peut declarer. Plage reservee par le garde-cap :
-- 20261119200000-20261119299999. Feu vert du garde-cap du 07/11/2026.
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ;
-- installable par apply_migration. Sans BEGIN ni COMMIT de premier niveau.
--
-- Le defaut (V1-b, 20261109200000, en production) : ouvrir_creneau_entretien
-- n'acceptait qu'un code de deux ou trois lettres (ou « autre »). Or le
-- candidat declare ses langues dans le questionnaire : le referentiel
-- public.langues_cours (poular, francais, english, man, ar, pt) puis les codes
-- hors referentiel du questionnaire en vigueur. Un creneau « francais » ne
-- pouvait pas s'ouvrir, et un candidat francophone ne voyait aucun creneau.
--
-- UNE source (condition 1 du garde-cap) : private.langues_entretien(), lue en
-- base, jamais recopiee : private.questionnaire_langues() du questionnaire
-- enseignant en vigueur (private.questionnaire_courant('enseignant')), c'est-a-
-- dire le referentiel actif puis les codes hors referentiel, dans cet ordre.
-- private.langue_candidature_valide(code) la consulte ; ouvrir_creneau_entretien
-- l'appelle ; l'ecran de la direction lit la meme liste par la RPC
-- public.langues_creneaux_entretien() (direction active seulement).
--
-- ouvrir_creneau_entretien ne change que par ancre (condition 2) : la seule
-- ligne `x !~ '^([a-z]{2,3}|autre)$'` devient
-- `NOT private.langue_candidature_valide(x)`. Preflight : corps de production
-- (md5 dd1ee805a59c59a6fb4740b976533a7b). Signature, proprietaire, SECURITY
-- DEFINER, search_path et droits gardes ; le postflight le verifie, et que le
-- reste de la definition est identique a l'octet pres.
--
-- private.questionnaire_definition_valide n'est pas touchee (condition 4).

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  f CONSTANT regprocedure := pg_catalog.to_regprocedure(
    'public.ouvrir_creneau_entretien(public.gender,timestamp with time zone,integer,text[],uuid[])');
BEGIN
  IF pg_catalog.to_regprocedure('private.langues_entretien()') IS NOT NULL THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : deja installee';
  END IF;
  IF f IS NULL
     OR pg_catalog.to_regprocedure('private.questionnaire_courant(text)') IS NULL
     OR pg_catalog.to_regprocedure('private.questionnaire_langues(jsonb)') IS NULL
     OR pg_catalog.to_regclass('public.langues_cours') IS NULL THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : V1-b ou le moteur du questionnaire manque';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = f)
     <> 'dd1ee805a59c59a6fb4740b976533a7b' THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : ouvrir_creneau_entretien a change depuis le depot (md5 %)',
      (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = f);
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La source unique
-- ---------------------------------------------------------------------------
-- Les codes que le candidat peut declarer, dans l'ordre du questionnaire.
CREATE FUNCTION private.langues_entretien()
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.array_agg(x.l ->> 'code' ORDER BY x.ord), '{}'::text[])
    FROM pg_catalog.jsonb_array_elements(
           private.questionnaire_langues((private.questionnaire_courant('enseignant')).definition))
         WITH ORDINALITY AS x(l, ord);
$function$;

-- Vrai si [p_code] est une langue que le candidat peut declarer.
CREATE FUNCTION private.langue_candidature_valide(p_code text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_code IS NOT NULL AND p_code = ANY (private.langues_entretien());
$function$;

-- La meme liste, pour l'ecran des creneaux de la direction.
CREATE FUNCTION public.langues_creneaux_entretien()
RETURNS text[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'langues des creneaux reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN private.langues_entretien();
END;
$function$;

ALTER FUNCTION private.langues_entretien() OWNER TO postgres;
ALTER FUNCTION private.langue_candidature_valide(text) OWNER TO postgres;
ALTER FUNCTION public.langues_creneaux_entretien() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.langues_entretien() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.langue_candidature_valide(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.langues_creneaux_entretien() FROM PUBLIC;
DO $droits$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.langues_entretien() FROM %I', v_role);
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.langue_candidature_valide(text) FROM %I', v_role);
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON FUNCTION public.langues_creneaux_entretien() FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
    GRANT EXECUTE ON FUNCTION public.langues_creneaux_entretien() TO authenticated;
  END IF;
END
$droits$;
COMMENT ON FUNCTION private.langues_entretien() IS
  'SALLE-2-ENTRETIEN (07/11/2026) : les codes de langue que le candidat peut declarer (referentiel actif '
  'puis hors referentiel du questionnaire enseignant en vigueur). Source unique des langues d''un creneau.';
COMMENT ON FUNCTION public.langues_creneaux_entretien() IS
  'SALLE-2-ENTRETIEN (07/11/2026) : la liste de private.langues_entretien(), pour l''ecran des creneaux '
  '(direction active seulement).';

-- ---------------------------------------------------------------------------
-- 2. ouvrir_creneau_entretien : la regle des langues, par ancre
-- ---------------------------------------------------------------------------
DO $ancre$
DECLARE
  f CONSTANT regprocedure :=
    'public.ouvrir_creneau_entretien(public.gender,timestamp with time zone,integer,text[],uuid[])'::regprocedure;
  c_ancre CONSTANT text := 'x !~ ''^([a-z]{2,3}|autre)$''';
  c_neuf CONSTANT text := 'NOT private.langue_candidature_valide(x)';
  v_avant record;
  v_def text;
  v_apres text;
  v_n integer;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = f;
  v_def := pg_catalog.pg_get_functiondef(f);
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
         / pg_catalog.length(c_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : ancre trouvee % fois (attendu 1) : %', v_n, c_ancre;
  END IF;

  EXECUTE pg_catalog.replace(v_def, c_ancre, c_neuf);

  -- Postflight : la regle est la nouvelle, et rien d'autre n'a change.
  v_apres := pg_catalog.pg_get_functiondef(f);
  IF pg_catalog.strpos(v_apres, c_neuf) = 0 OR pg_catalog.strpos(v_apres, c_ancre) > 0 THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : la regle des langues n''est pas celle attendue';
  END IF;
  IF pg_catalog.replace(v_apres, c_neuf, c_ancre) <> v_def THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : la definition differe ailleurs que par la regle des langues';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = f
          AND p.prosecdef = v_avant.prosecdef
          AND p.proowner = v_avant.proowner
          AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
          AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : proprietaire, SECURITY DEFINER, search_path ou droits modifies';
  END IF;
END
$ancre$;

-- ---------------------------------------------------------------------------
-- 3. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT private.langue_candidature_valide('francais')
     OR NOT ('francais' = ANY (private.langues_entretien()))
     OR private.langue_candidature_valide('xx')
     OR private.langue_candidature_valide(NULL) THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : la source des langues ne rend pas ce qui est attendu : %',
      private.langues_entretien();
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'authenticated')
     AND (pg_catalog.has_function_privilege('authenticated', 'private.langues_entretien()', 'EXECUTE')
          OR pg_catalog.has_function_privilege('authenticated', 'private.langue_candidature_valide(text)', 'EXECUTE')
          OR NOT pg_catalog.has_function_privilege('authenticated', 'public.langues_creneaux_entretien()', 'EXECUTE')) THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : droits inattendus';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon')
     AND pg_catalog.has_function_privilege('anon', 'public.langues_creneaux_entretien()', 'EXECUTE') THEN
    RAISE EXCEPTION 'LANGUES-ENTRETIEN : la liste est ouverte a anon';
  END IF;
END
$postflight$;
