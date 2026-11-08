-- HARMONISATION-A (08/11/2026, plan valide par le garde-cap ; une cause par
-- fichier) : la sortie rapide de private.remplacement_auto_passer. Aucun mot
-- d'effacement.
--
-- Le cron tourne chaque minute (10 342 appels, 35 ms en moyenne, jusqu'a
-- 1,5 s, mesure du 07/11). Une fonction privee,
-- private.remplacement_auto_a_faire, dit s'il existe au moins une seance dans
-- l'une des cinq fenetres que la fonction lit deja (a. pre-alerte,
-- b. titulaire entre pendant la pre-alerte, c. perte d'acces, d. alerte de la
-- direction, e. seance non tenue). C'est le sur-ensemble exact de ces
-- fenetres, jamais un sous-ensemble ; sinon la fonction rend aussitot ses
-- compteurs a zero, sans rien lire d'autre. Remplacement par ancre, preflight
-- md5 de la version retouchee par PUSH-1 (20261112000200), egalite exacte
-- apres.
--
-- Rejeu : stub_auth, toutes les migrations, puis
-- supabase/tests/scenarios_harmonisation_a_fuseau_sortie.sql (s1 a s7).

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.remplacement_auto_a_faire(timestamptz,integer,integer,integer)') IS NOT NULL THEN
    RAISE EXCEPTION 'HARMONISATION-A (sortie rapide) : deja installee';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Sortie rapide : y a-t-il quelque chose a faire ?
-- ---------------------------------------------------------------------------
-- Les memes conditions que les cinq boucles de remplacement_auto_passer,
-- reunies sans ce qui n'en fait que retirer des lignes (sous-requetes NOT
-- EXISTS) : le resultat est un sur-ensemble. Les reglages sont ceux deja lus
-- par la fonction appelante.
CREATE FUNCTION private.remplacement_auto_a_faire(
  p_maintenant timestamptz, p_avert integer, p_alerte integer, p_non_tenue integer
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (
    -- a, c, d : seance commencee depuis le plus petit seuil, pas finie.
    -- e : seance commencee depuis seance_non_tenue (finie ou non), pas reportee.
    SELECT 1
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')
       AND s.teacher_id IS NOT NULL
       AND ((s.started_at + pg_catalog.make_interval(mins => LEAST(p_avert, p_alerte)) <= p_maintenant
             AND s.ended_at > p_maintenant)
            OR (s.started_at + pg_catalog.make_interval(mins => p_non_tenue) <= p_maintenant
                AND NOT EXISTS (SELECT 1 FROM public.seances_reportees x WHERE x.session_id = s.id)))
  ) OR EXISTS (
    -- b : une pre-alerte ouverte (sans borne de temps, comme la boucle b).
    SELECT 1
      FROM public.sessions s
      JOIN public.remplacements_preparation pa ON pa.session_id = s.id AND pa.evenement = 'pre_alerte'
     WHERE s.deleted_at IS NULL
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation x
                        WHERE x.session_id = s.id AND x.evenement = 'remplacement_inutile')
       AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance r WHERE r.session_id = s.id)
  );
$function$;
ALTER FUNCTION private.remplacement_auto_a_faire(timestamptz, integer, integer, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacement_auto_a_faire(timestamptz, integer, integer, integer)
  FROM PUBLIC;
DO $droits$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = r) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION private.remplacement_auto_a_faire(timestamptz, integer, integer, integer) FROM %I', r);
    END IF;
  END LOOP;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 2. remplacement_auto_passer : la sortie rapide, par ancre
-- ---------------------------------------------------------------------------
DO $ancre$
DECLARE
  c_f CONSTANT regprocedure := 'private.remplacement_auto_passer(timestamptz)'::regprocedure;
  c_ancre CONSTANT text :=
    E'    RAISE EXCEPTION ''reglages remplacement.* incoherents'' USING ERRCODE = ''22023'';\n  END IF;\n';
  c_neuf CONSTANT text :=
    E'    RAISE EXCEPTION ''reglages remplacement.* incoherents'' USING ERRCODE = ''22023'';\n  END IF;\n'
    || E'  -- HARMONISATION-A : rien dans aucune fenetre, sortie aussitot.\n'
    || E'  IF NOT private.remplacement_auto_a_faire(p_maintenant, v_avert, v_alerte, v_non_tenue) THEN\n'
    || E'    RETURN pg_catalog.jsonb_build_object(\n'
    || E'      ''reportees'', 0, ''alertes_direction'', 0,\n'
    || E'      ''pre_alertes'', 0, ''inutiles'', 0,\n'
    || E'      ''absences'', 0, ''prises'', 0, ''erreurs'', 0);\n'
    || E'  END IF;\n';
  v_avant record;
  v_def text;
  v_apres text;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, pg_catalog.md5(p.prosrc) AS empreinte
    INTO v_avant FROM pg_catalog.pg_proc p WHERE p.oid = c_f;
  IF v_avant.empreinte <> 'e7a48a4c9e57f17495fdf04ef6988377' THEN
    RAISE EXCEPTION 'HARMONISATION-A (sortie rapide) : remplacement_auto_passer a change depuis le depot (md5 %)', v_avant.empreinte;
  END IF;
  v_def := pg_catalog.pg_get_functiondef(c_f);
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
     / pg_catalog.length(c_ancre) <> 1 THEN
    RAISE EXCEPTION 'HARMONISATION-A : ancre introuvable ou multiple dans remplacement_auto_passer';
  END IF;
  EXECUTE pg_catalog.replace(v_def, c_ancre, c_neuf);
  v_apres := pg_catalog.pg_get_functiondef(c_f);
  IF pg_catalog.replace(v_apres, c_neuf, c_ancre) <> v_def THEN
    RAISE EXCEPTION 'HARMONISATION-A : remplacement_auto_passer differe ailleurs que par la sortie rapide';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = c_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'HARMONISATION-A : proprietaire, DEFINER, search_path ou droits modifies';
  END IF;
END
$ancre$;

-- ---------------------------------------------------------------------------
-- 3. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated',
       'private.remplacement_auto_a_faire(timestamptz,integer,integer,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'HARMONISATION-A (sortie rapide) : droits inattendus';
  END IF;
END
$postflight$;
