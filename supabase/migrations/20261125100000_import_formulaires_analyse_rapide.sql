-- Import des reponses des candidats (ADM-23) : correctif urgent de la lenteur, 13/11/2026.
--
-- Constat en production : un export de 629 166 octets depasse 120 s (annule, 57014) ; l'algorithme est en
-- cause, pas le delai. Cause prouvee : private.parse_import_csv lisait le texte signe par signe avec
-- substring(texte from i for 1) et length(texte) a chaque tour, deux operations en O(i) sur du texte
-- multi-octets (arabe) : duree en O(n^2) (mesure locale : 50, 100, 200 lignes = 5 s, 20 s, 85 s).
--
-- Cette migration : (1) remplace private.parse_import_csv par une lecture en une seule passe (le texte est
-- decoupe une fois en jetons) qui rend EXACTEMENT les memes lignes, les memes erreurs et les memes messages
-- (preuve : supabase/tests/scenarios_import_formulaires_equivalence.sql) ; (2) inscrit dans le depot le delai
-- de 120 s pose a la main en production sur apercu_import_formulaires et confirmer_import_formulaires ;
-- (3) recalcule l'empreinte F86 de ces deux fonctions (pg_get_functiondef contient le reglage du delai).
-- Aucune regle d'import, de doublon, de rapprochement ni de droit n'est touchee. Rejouable ; aucune suppression de donnee ni d'objet. A coller AVANT la fusion de l'application.

CREATE OR REPLACE FUNCTION private.parse_import_csv(p_csv text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_csv text := p_csv;
  v_rows jsonb[] := ARRAY[]::jsonb[];
  v_cells text[] := ARRAY[]::text[];
  v_cell text := '';
  v_quoted boolean := false;
  v_pend boolean := false;
  v_closed boolean := false;
  v_tok text;
BEGIN
  IF v_csv IS NULL OR pg_catalog.length(v_csv) > 5000000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'CSV absent ou supérieur à 5 Mo';
  END IF;
  IF pg_catalog.left(v_csv, 1) = pg_catalog.chr(65279) THEN v_csv := pg_catalog.substr(v_csv, 2); END IF;
  -- Une seule passe : le texte est decoupe une fois en jetons (guillemet, virgule, fin de ligne,
  -- suite de signes ordinaires), jamais relu signe par signe depuis le debut.
  FOR v_tok IN SELECT m[1] FROM pg_catalog.regexp_matches(v_csv, '(\r\n|["\r\n,]|[^",\r\n]+)', 'g') AS m LOOP
    IF v_quoted THEN
      IF v_tok = '"' THEN
        IF v_pend THEN v_cell := v_cell || '"'; v_pend := false; ELSE v_pend := true; END IF;
        CONTINUE;
      END IF;
      IF NOT v_pend THEN v_cell := v_cell || v_tok; CONTINUE; END IF;
      -- le guillemet en attente fermait la cellule : on lit ce jeton hors guillemets
      v_quoted := false; v_pend := false; v_closed := true;
    END IF;
    IF v_tok = '"' THEN
      IF v_closed THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'CSV mal formé après un guillemet fermant'; END IF;
      IF v_cell <> '' THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'CSV mal formé'; END IF;
      v_quoted := true;
    ELSIF v_tok = ',' THEN
      v_cells := v_cells || v_cell; v_cell := ''; v_closed := false;
    ELSIF v_tok = E'\n' OR v_tok = E'\r' OR v_tok = E'\r\n' THEN
      v_cells := v_cells || v_cell;
      IF NOT (pg_catalog.cardinality(v_cells) = 1 AND v_cells[1] = '') THEN
        v_rows := v_rows || pg_catalog.to_jsonb(v_cells);
      END IF;
      v_cells := ARRAY[]::text[]; v_cell := ''; v_closed := false;
    ELSE
      IF v_closed THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'CSV mal formé après un guillemet fermant'; END IF;
      v_cell := v_cell || v_tok;
    END IF;
  END LOOP;
  IF v_quoted AND NOT v_pend THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'CSV mal formé: guillemet non fermé';
  END IF;
  IF v_cell <> '' OR pg_catalog.cardinality(v_cells) > 0 THEN
    v_rows := v_rows || pg_catalog.to_jsonb(v_cells || v_cell);
  END IF;
  RETURN coalesce(pg_catalog.to_jsonb(v_rows), '[]'::jsonb);
END;
$function$;

ALTER FUNCTION public.apercu_import_formulaires(text, text, text, jsonb, text)
  SET statement_timeout = '120s';
ALTER FUNCTION public.confirmer_import_formulaires(text, text, text, text, jsonb, text, jsonb, text)
  SET statement_timeout = '120s';

DO $empreintes$
DECLARE
  f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.apercu_import_formulaires(text,text,text,jsonb,text)'::regprocedure,
    'public.confirmer_import_formulaires(text,text,text,text,jsonb,text,jsonb,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f::text,
      pg_catalog.regexp_replace(pg_catalog.obj_description(f, 'pg_proc'), 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))));
  END LOOP;
END
$empreintes$;
