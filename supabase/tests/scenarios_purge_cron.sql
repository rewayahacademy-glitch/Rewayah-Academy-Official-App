-- PERF-ATTENTE dette 9 (migration 20261120200100) : la purge du journal des
-- taches planifiees garde sept jours.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. la fonction purge ce qui a plus de sept jours, garde le reste, et ne
--      touche jamais une execution en cours ;
--   2. elle rend le nombre de lignes purgees ; un deuxieme appel n'en purge
--      aucune (rejouable) ;
--   3. une duree absente, nulle ou inferieure a un jour est refusee : jamais
--      une instruction de tout purger ;
--   4. aucun client ne peut l'executer (has_function_privilege) ;
--   5. sans la table de pg_cron, elle rend 0 sans erreur.
--
-- Postgres nu apres stub_auth.sql et toutes les migrations, sans pg_cron : le
-- scenario monte un schema cron minimal (memes colonnes que pg_cron) dans sa
-- transaction. Tout est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PURGE-CRON ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- 5. Sans la table de pg_cron : 0, sans erreur.
SELECT pg_temp.vrai(
  pg_catalog.to_regclass('cron.job_run_details') IS NOT NULL
  OR private.purger_cron_run_details() = 0,
  'sans la table de pg_cron, la purge rend 0');

CREATE SCHEMA IF NOT EXISTS cron;
CREATE TABLE IF NOT EXISTS cron.job_run_details (
  jobid bigint, runid bigint, job_pid integer, database text, username text,
  command text, status text, return_message text,
  start_time timestamptz, end_time timestamptz);

INSERT INTO cron.job_run_details (jobid, runid, username, command, status, start_time, end_time)
VALUES (1, 1, 'postgres', 'SELECT 1', 'succeeded', now() - interval '1 day',   now() - interval '1 day'),
       (1, 2, 'postgres', 'SELECT 1', 'succeeded', now() - interval '6 days',  now() - interval '6 days'),
       (1, 3, 'postgres', 'SELECT 1', 'succeeded', now() - interval '8 days',  now() - interval '8 days'),
       (1, 4, 'postgres', 'SELECT 1', 'failed',    now() - interval '40 days', now() - interval '40 days'),
       (1, 5, 'postgres', 'SELECT 1', 'running',   now() - interval '9 days',  NULL);

-- 1 et 2. Sept jours gardes, le reste purge, l'execution en cours intacte.
SELECT pg_temp.vrai(private.purger_cron_run_details() = 2,
  'la purge rend 2 : les lignes de 8 et de 40 jours');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(d.runid ORDER BY d.runid) FROM cron.job_run_details d) = ARRAY[1, 2, 5]::bigint[],
  'restent les lignes de 1 et 6 jours, et l''execution en cours');
SELECT pg_temp.vrai(private.purger_cron_run_details() = 0,
  'un deuxieme appel ne purge rien (rejouable)');
SELECT pg_temp.vrai(private.purger_cron_run_details(interval '2 days') = 1,
  'une duree plus courte purge davantage : la ligne de 6 jours');

-- 3. Jamais « tout purger ».
DO $$
BEGIN
  PERFORM private.purger_cron_run_details(interval '0');
  RAISE EXCEPTION 'PURGE-CRON ROUGE : une duree nulle a ete acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK une duree nulle est refusee';
END $$;
DO $$
BEGIN
  PERFORM private.purger_cron_run_details(NULL);
  RAISE EXCEPTION 'PURGE-CRON ROUGE : une duree absente a ete acceptee';
EXCEPTION WHEN invalid_parameter_value THEN
  RAISE NOTICE 'OK une duree absente est refusee';
END $$;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM cron.job_run_details) = 2,
  'les refus n''ont rien purge');

-- 4. Aucun client.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'private.purger_cron_run_details(interval)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.purger_cron_run_details(interval)', 'EXECUTE'),
  'ni anon ni authenticated ne peut executer la purge');
SELECT pg_temp.vrai(
  (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
     FROM pg_catalog.pg_proc p WHERE p.oid = 'private.purger_cron_run_details(interval)'::regprocedure),
  'SECURITY DEFINER, search_path vide');

ROLLBACK;
