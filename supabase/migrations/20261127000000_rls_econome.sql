-- RLS-ECONOME (15/11/2026), étape 2 de docs/current/STRATEGIE-BASE-ECONOME-2026-11-15.md.
--
-- Constat en production (lecture seule, 15/11/2026, après la panne du jour) :
-- le Performance Advisor de Supabase signale 52 policies « auth_rls_initplan » :
-- elles appellent auth.uid() (ou auth.jwt(), auth.role()) sans l'envelopper, et
-- Postgres réévalue l'appel POUR CHAQUE LIGNE lue. Le dépôt compte aussi
-- 985 appels de public.app_account_valid() (SECURITY DEFINER, lit profiles),
-- dont 22 enveloppés, et 1 205 de public.app_role(), dont 25 enveloppés.
-- Supabase mesure le gain de l'enveloppe : 179 ms -> 9 ms pour auth.uid(),
-- 178 000 ms -> 12 ms pour une fonction (guides/troubleshooting/
-- rls-performance-and-best-practices).
--
-- Changement : chaque policy des schémas public et private est réécrite à
-- l'identique, sauf que ces appels sans argument deviennent
-- `( SELECT f())` : Postgres les calcule une fois par requête (initplan) au
-- lieu d'une fois par ligne. Ces fonctions sont STABLE et sans argument : le
-- résultat est le même pour toute la requête, donc la règle d'accès ne change
-- pas. Rien d'autre n'est touché (ni les fonctions, ni les tables, ni les
-- rôles visés). Les policies de storage.objects (propriété de Supabase) ne
-- sont pas touchées.
--
-- Rejouable : une policy déjà enveloppée n'est plus modifiée. Sans BEGIN ni
-- COMMIT de premier niveau. Aucun mot d'effacement.

DO $rls_econome$
DECLARE
  -- Un appel nu : ni précédé de « SELECT » (déjà enveloppé), ni d'un point
  -- ou d'une lettre (autre fonction au nom proche).
  v_motif constant text :=
    '(?<!SELECT )(?<![.[:alnum:]_])((auth\.(uid|jwt|role))|(public\.(app_account_valid|app_role|app_household_id)))\(\)';
  r record;
  v_using text;
  v_check text;
  v_sql text;
  v_nb integer := 0;
BEGIN
  -- Noms qualifiés dans le texte rendu par pg_get_expr.
  PERFORM pg_catalog.set_config('search_path', 'pg_catalog', true);

  FOR r IN
    SELECT n.nspname AS schema_nom, c.relname AS table_nom, p.polname AS policy_nom,
           p.polcmd,
           pg_catalog.pg_get_expr(p.polqual, p.polrelid) AS qual,
           pg_catalog.pg_get_expr(p.polwithcheck, p.polrelid) AS with_check
      FROM pg_catalog.pg_policy p
      JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname IN ('public', 'private')
  LOOP
    v_using := CASE WHEN r.qual IS NULL THEN NULL
                    ELSE pg_catalog.regexp_replace(r.qual, v_motif, '( SELECT \1())', 'g') END;
    v_check := CASE WHEN r.with_check IS NULL THEN NULL
                    ELSE pg_catalog.regexp_replace(r.with_check, v_motif, '( SELECT \1())', 'g') END;

    CONTINUE WHEN v_using IS NOT DISTINCT FROM r.qual
              AND v_check IS NOT DISTINCT FROM r.with_check;

    v_sql := pg_catalog.format('ALTER POLICY %I ON %I.%I', r.policy_nom, r.schema_nom, r.table_nom);
    IF v_using IS NOT NULL AND v_using IS DISTINCT FROM r.qual THEN
      v_sql := v_sql || ' USING (' || v_using || ')';
    END IF;
    IF v_check IS NOT NULL AND v_check IS DISTINCT FROM r.with_check THEN
      v_sql := v_sql || ' WITH CHECK (' || v_check || ')';
    END IF;
    EXECUTE v_sql;
    v_nb := v_nb + 1;
  END LOOP;

  RAISE NOTICE 'RLS-ECONOME : % policies réécrites', v_nb;
END;
$rls_econome$;

-- Contrôle : plus aucun appel nu dans les policies de public et private.
DO $postflight$
DECLARE
  v_reste integer;
BEGIN
  PERFORM pg_catalog.set_config('search_path', 'pg_catalog', true);
  SELECT pg_catalog.count(*) INTO v_reste
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname IN ('public', 'private')
     AND (coalesce(pg_catalog.pg_get_expr(p.polqual, p.polrelid), '') ~
            '(?<!SELECT )(?<![.[:alnum:]_])((auth\.(uid|jwt|role))|(public\.(app_account_valid|app_role|app_household_id)))\(\)'
       OR coalesce(pg_catalog.pg_get_expr(p.polwithcheck, p.polrelid), '') ~
            '(?<!SELECT )(?<![.[:alnum:]_])((auth\.(uid|jwt|role))|(public\.(app_account_valid|app_role|app_household_id)))\(\)');
  IF v_reste > 0 THEN
    RAISE EXCEPTION 'RLS-ECONOME : % policies gardent un appel nu', v_reste;
  END IF;
END;
$postflight$;
