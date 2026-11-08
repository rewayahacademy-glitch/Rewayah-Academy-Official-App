-- HYGIENE-GARDES, point 6 (08/11/2026, audit des gardes Codex ; plage
-- reservee par le garde-cap : 20261121800000-20261121899999, un fichier par
-- point). N'est ni installee ni fusionnee sans decision (pilote, 08/11).
--
-- Le defaut, prouve sur une base rejouee depuis le depot (Postgres 17) : dans
-- public.autoriser_ecoute_archive(uuid), la branche famille (seance d'un seul
-- foyer et appelant de ce foyer) ne testait pas le role. Un compte comptable
-- dont le profil porte un household_id (erreur de saisie de la direction,
-- que la contrainte profiles_household_required n'interdit pas) ecoutait les
-- enregistrements de ce foyer.
--
-- Ce que fait ce fichier, et rien d'autre : la branche famille exige aussi
-- v_role IN ('guardian', 'student'). Les branches direction/controle et
-- enseignant de la seance, la limite a un seul foyer, le gel legal et les
-- messages ne changent pas.
--
-- PREFLIGHT : md5(pg_get_functiondef) relu sur une base rejouee depuis le
-- depot : d4c1bf76b8b393252ab69671cb3a7c2b. En production (lu par le pilote
-- le 08/11/2026, en lecture seule), elle vaut d5d2cde6e1b9929f8cc4716e6326aa2b :
-- le MEME code, avec des commentaires plus courts (texte compare ligne a
-- ligne, commentaires retires : identique). Les deux empreintes sont admises ;
-- l'ancre porte sur des lignes de code, presentes une fois dans chacune.
-- A verifier en production par le
-- pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef('public.autoriser_ecoute_archive(uuid)'::regprocedure));
-- Une definition differente, sans le marqueur de ce lot, arrete le fichier.
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Aucun mot
-- d'effacement : applicable par apply_migration.

CREATE OR REPLACE FUNCTION pg_temp.hyg_remplacer(p_f pg_catalog.regprocedure, p_md5 text[], p_avant text, p_apres text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, 'HYGIENE-GARDES') > 0 THEN
    RAISE NOTICE '% : deja retouchee, rien n''est refait', p_f;
    RETURN;
  END IF;
  IF NOT (pg_catalog.md5(v_def) = ANY (p_md5)) THEN
    RAISE EXCEPTION '% a change (md5 %), rien n''est change', p_f, pg_catalog.md5(v_def);
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION '% : ancre trouvee % fois au lieu de 1, migration a revoir', p_f, v_n;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

DO $retouche$
BEGIN
  PERFORM pg_temp.hyg_remplacer('public.autoriser_ecoute_archive(uuid)'::regprocedure,
    ARRAY['d4c1bf76b8b393252ab69671cb3a7c2b', 'd5d2cde6e1b9929f8cc4716e6326aa2b'],
    $a$      v_foyers <= 1
      and public.session_in_household(v_archive.session_id, public.app_household_id())$a$,
    $b$      v_foyers <= 1
      -- HYGIENE-GARDES (08/11/2026) : la branche famille est celle du tuteur
      -- et de l'eleve ; un autre role rattache par erreur a un foyer n'y entre pas.
      and v_role in ('guardian', 'student')
      and public.session_in_household(v_archive.session_id, public.app_household_id())$b$);
END
$retouche$;

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.autoriser_ecoute_archive(uuid)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'HYGIENE-GARDES') = 0
     OR pg_catalog.strpos(v_def, 'v_role in (''guardian'', ''student'')') = 0
     OR pg_catalog.strpos(v_def, 'session_belongs_to_teacher') = 0
     OR pg_catalog.strpos(v_def, 'v_role in (''admin'', ''controller'')') = 0 THEN
    RAISE EXCEPTION 'HYGIENE-GARDES postflight : autoriser_ecoute_archive incomplete';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.autoriser_ecoute_archive(uuid)'::regprocedure AND p.prosecdef
          AND p.proconfig @> array['search_path=""']::text[]
          AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') THEN
    RAISE EXCEPTION 'HYGIENE-GARDES postflight : DEFINER, search_path ou proprietaire incorrect';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.autoriser_ecoute_archive(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.autoriser_ecoute_archive(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'HYGIENE-GARDES postflight : droits EXECUTE modifies';
  END IF;
END
$postflight$;
