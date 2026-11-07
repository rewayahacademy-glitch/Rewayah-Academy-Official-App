-- PERF-ATTENTE, dette 9 (garde-cap, 07/11/2026) : la purge du journal des
-- taches planifiees.
--
-- Constat (production, lecture seule du 07/11/2026) : cron.job_run_details
-- compte 40 528 lignes et pese 89 MB, plus ancienne ligne au 23/10 ; deux
-- taches tournent chaque minute (courriels-envoi, remplacement_auto) et le
-- journal grossit d'environ mille lignes par heure, sans jamais diminuer.
-- Chaque execution y ajoute une ligne : le journal ralentit tout ce qu'il
-- touche et prend de la place pour rien.
--
-- Ce fichier : une fonction qui garde SEPT JOURS et une tache qui la lance UNE
-- fois par jour (03:23 UTC, hors de l'heure pleine).
--
-- Faits lus en production avant d'ecrire : la table appartient a
-- supabase_admin ; le role postgres y a le droit de suppression ; une
-- politique de securite par ligne (username = CURRENT_USER) borne ce que
-- postgres voit : la fonction (proprietaire postgres, SECURITY DEFINER) ne
-- purge donc que les lignes des taches lancees par postgres, ce qui est le cas
-- de toutes les taches du projet.
--
-- FICHIER A MOT D'EFFACEMENT (compte : 1, dans la fonction ; aucun autre) :
-- PAGE COLLEE PAR LE DIRECTEUR. Il ne touche aucune table de l'application,
-- seulement le journal de pg_cron. Sans BEGIN ni COMMIT de premier niveau.
-- Rejouable : la fonction est remplacee a l'identique, la tache est mise a
-- jour sur son nom. Planification gardee par la presence de pg_cron (la CI
-- rejoue les migrations sur un Postgres sans pg_cron).

CREATE OR REPLACE FUNCTION private.purger_cron_run_details(p_conserver interval DEFAULT interval '7 days')
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  -- Une duree absente, nulle ou negative n'est jamais une instruction de tout
  -- purger : garde positive, au moins un jour.
  IF p_conserver IS NULL OR p_conserver < interval '1 day' THEN
    RAISE EXCEPTION 'purge du journal des taches : duree de conservation invalide (au moins un jour)'
      USING ERRCODE = '22023';
  END IF;
  -- Sans pg_cron (Postgres nu, CI), il n'y a rien a purger.
  IF pg_catalog.to_regclass('cron.job_run_details') IS NULL THEN
    RETURN 0;
  END IF;
  DELETE FROM cron.job_run_details d
   WHERE d.start_time < pg_catalog.now() - p_conserver
     AND d.status IS DISTINCT FROM 'running';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

REVOKE ALL ON FUNCTION private.purger_cron_run_details(interval) FROM PUBLIC;
DO $droits$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION private.purger_cron_run_details(interval) FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.purger_cron_run_details(interval) IS
  'PERF-ATTENTE dette 9 : purge cron.job_run_details au-dela de la duree gardee (sept jours par defaut, au moins un jour), sans toucher aux executions en cours ; rend le nombre de lignes purgees ; 0 sans pg_cron. Lancee une fois par jour par la tache purge-cron-run-details. Aucun EXECUTE client.';

DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('purge-cron-run-details', '23 3 * * *',
      'SELECT private.purger_cron_run_details()')$cron$;
  ELSE
    RAISE NOTICE 'purge du journal des taches : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

DO $postflight$
DECLARE
  v_taches integer;
BEGIN
  IF pg_catalog.to_regprocedure('private.purger_cron_run_details(interval)') IS NULL THEN
    RAISE EXCEPTION 'PERF-ATTENTE : la fonction de purge est absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.purger_cron_run_details(interval)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.purger_cron_run_details(interval)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PERF-ATTENTE : la fonction de purge est executable par un client';
  END IF;
  -- Dynamique : sans pg_cron, cron.job n'existe pas et la requete ne se planifie pas.
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $q$SELECT pg_catalog.count(*)::integer FROM cron.job j
                 WHERE j.jobname = 'purge-cron-run-details' AND j.active AND j.schedule = '23 3 * * *'$q$
      INTO v_taches;
    IF v_taches <> 1 THEN
      RAISE EXCEPTION 'PERF-ATTENTE : la tache de purge n''est pas planifiee une fois par jour';
    END IF;
  END IF;
END;
$postflight$;
