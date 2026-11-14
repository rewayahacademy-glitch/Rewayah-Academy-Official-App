-- CANDIDATURE-UX (directeur, 14/11/2026, relaye par le pilote) : la langue de
-- la candidature accepte l'anglais.
--
-- Le candidat choisit desormais sa langue parmi toutes celles de
-- l'application (francais, arabe, anglais). La colonne
-- `candidatures.langue` (CHECK fr ou ar, 20261022000600) et la validation de
-- `inscrire_candidat` refusaient « en » : un candidat anglophone y etait note
-- « fr ». Cette migration :
--   1. remplace le CHECK de la colonne par fr, ar ou en (feu vert du pilote,
--      14/11/2026 : DROP CONSTRAINT puis ADD CONSTRAINT) ;
--   2. change, par ancre et une seule fois, la ligne de validation de
--      `inscrire_candidat` : `p_langue NOT IN ('fr', 'ar')` devient
--      `p_langue NOT IN ('fr', 'ar', 'en')`. Signature, proprietaire,
--      SECURITY DEFINER, search_path et droits restent ceux de la fonction
--      (CREATE OR REPLACE les garde) ; l'empreinte F86 du commentaire est
--      recalculee. Le postflight verifie chacun de ces points, et que le reste
--      de la definition est identique a l'octet pres.
--
-- Rejouable : deja appliquee, elle ne fait rien. Pas de BEGIN ni de COMMIT.
-- MOT D'EFFACEMENT : une contrainte retiree puis reposee (DROP CONSTRAINT) ;
-- le directeur colle ce fichier dans l'editeur SQL (regle du 23/10/2026).

-- 1. La colonne : fr, ar ou en.
ALTER TABLE public.candidatures DROP CONSTRAINT IF EXISTS candidatures_langue_check;
ALTER TABLE public.candidatures
  ADD CONSTRAINT candidatures_langue_check CHECK (langue IN ('fr', 'ar', 'en'));
COMMENT ON COLUMN public.candidatures.langue IS
  'CAND-L3 : langue de l interface choisie a l inscription (fr, ar ou en ; en depuis CANDIDATURE-UX, '
  '14/11/2026), pour les courriels de la file (L5) ; jamais deduite.';

-- 2. La validation de inscrire_candidat.
DO $migration$
DECLARE
  f CONSTANT regprocedure :=
    'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure;
  c_ancre CONSTANT text := 'p_langue NOT IN (''fr'', ''ar'')';
  c_neuf CONSTANT text := 'p_langue NOT IN (''fr'', ''ar'', ''en'')';
  v_avant record;
  v_def text;
  v_apres text;
  v_n integer;
  v_com text;
BEGIN
  SELECT p.prosrc, p.prosecdef, p.proowner, p.proconfig, p.proacl
    INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = f;

  -- Rejeu : deja corrigee, rien a faire.
  IF pg_catalog.strpos(v_avant.prosrc, c_neuf) > 0 THEN
    RAISE NOTICE 'inscrire_candidat : accepte deja l''anglais, rien a faire';
    RETURN;
  END IF;

  -- Preflight : l'ancre, une seule fois.
  v_def := pg_catalog.pg_get_functiondef(f);
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
         / pg_catalog.length(c_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'inscrire_candidat : ancre trouvee % fois (attendu 1) : %', v_n, c_ancre;
  END IF;

  EXECUTE pg_catalog.replace(v_def, c_ancre, c_neuf);

  -- L'empreinte F86 du commentaire suit la definition.
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;

  -- Postflight.
  v_apres := pg_catalog.pg_get_functiondef(f);
  IF pg_catalog.strpos(v_apres, c_neuf) = 0 THEN
    RAISE EXCEPTION 'inscrire_candidat : la validation de la langue n''est pas celle attendue';
  END IF;
  IF pg_catalog.replace(v_apres, c_neuf, c_ancre) <> v_def THEN
    RAISE EXCEPTION 'inscrire_candidat : la definition differe ailleurs que par la validation de la langue';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = f
          AND p.prosecdef = v_avant.prosecdef
          AND p.proowner = v_avant.proowner
          AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
          AND p.proacl IS NOT DISTINCT FROM v_avant.proacl)
     OR NOT (SELECT p.prosecdef AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
               FROM pg_catalog.pg_proc p WHERE p.oid = f) THEN
    RAISE EXCEPTION 'inscrire_candidat : proprietaire, SECURITY DEFINER, search_path ou droits modifies';
  END IF;
  IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('public', f, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'inscrire_candidat : les droits d''execution ne sont plus ceux attendus (authenticated seul)';
  END IF;
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%'
     AND v_com NOT LIKE '%md5_functiondef=' || pg_catalog.md5(v_apres) || '%' THEN
    RAISE EXCEPTION 'inscrire_candidat : l''empreinte F86 du commentaire n''a pas suivi la definition';
  END IF;
END
$migration$;
