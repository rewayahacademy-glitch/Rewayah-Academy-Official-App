-- PRAXIS-PURGE-JOURNAL (ordre du pilote, 17/11/2026) : la purge du journal de Praxis a douze mois.
--
-- Pourquoi : la politique de confidentialite arbitree le 17/11/2026
-- (docs/current/TEXTES-VALIDES/POLITIQUE-CONFIDENTIALITE-PRAXIS.md) promet que le journal de Praxis
-- (`private.praxis_journal` : ce que l'assistant a envoye, jamais le texte d'un tiers) est conserve DOUZE MOIS, puis
-- efface. La dette etait notee : « la purge automatique n'existe pas encore et doit etre ecrite avant la publication ».
--
-- Ce fichier : une fonction `private.praxis_purger_journal(interval)` qui efface les lignes de plus de douze mois, et une
-- tache qui la lance UNE fois par jour (03:41 UTC, hors de l'heure pleine, apres la purge du journal des taches de 03:23).
--   * douze mois est un PLANCHER, pas un reglage : une duree plus courte est refusee (une promesse faite aux personnes
--     ne se raccourcit pas par un parametre) ; une duree plus longue est admise ;
--   * la fonction rend le nombre de lignes effacees ; rejouable (un deuxieme appel n'en efface aucune) ;
--   * proprietaire postgres, SECURITY DEFINER, search_path vide, AUCUN droit pour un role client (anon, authenticated,
--     service_role, agent_ro) : seule la tache planifiee (role postgres) l'appelle ;
--   * le declencheur « ajout seul » du journal ne porte que sur la modification : il n'empeche pas cet effacement, qui est
--     la seule voie autorisee, et reste borne a l'age.
--
-- Planification gardee par la presence de pg_cron (la CI rejoue les migrations sur un Postgres nu, sans elle) : sans
-- pg_cron, rien n'est planifie et la fonction reste appelable a la main par le role postgres.
--
-- FICHIER A MOT D'EFFACEMENT (compte : 1, dans la fonction ; aucun autre) : ARBITRAGE DU PILOTE REQUIS, puisque la loi
-- l'exige. Il ne touche que `private.praxis_journal`. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.praxis_journal') IS NULL THEN
    RAISE EXCEPTION 'PRAXIS-PURGE : le journal de Praxis (20261129600000) doit etre installe d''abord';
  END IF;
  IF pg_catalog.to_regprocedure('private.praxis_purger_journal(interval)') IS NOT NULL THEN
    RAISE EXCEPTION 'PRAXIS-PURGE : deja installee';
  END IF;
END
$preflight$;

CREATE FUNCTION private.praxis_purger_journal(p_conserver interval DEFAULT interval '12 months')
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  -- Garde positive : une duree absente, nulle ou inferieure a douze mois n'est jamais une instruction de purger.
  IF p_conserver IS NULL OR p_conserver < interval '12 months' THEN
    RAISE EXCEPTION 'purge du journal de Praxis : duree de conservation invalide (au moins douze mois)'
      USING ERRCODE = '22023';
  END IF;
  DELETE FROM private.praxis_journal j
   WHERE j.cree_le < pg_catalog.clock_timestamp() - p_conserver;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

ALTER FUNCTION private.praxis_purger_journal(interval) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.praxis_purger_journal(interval) FROM PUBLIC;
DO $droits$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.praxis_purger_journal(interval) FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.praxis_purger_journal(interval) IS
  'PRAXIS-PURGE-JOURNAL: guard_type=SCHEDULED_ONLY; aucun droit client ; efface les lignes de private.praxis_journal de plus de la duree gardee (douze mois par defaut, plancher douze mois) ; rend le nombre de lignes effacees. date=2026-11-17.';

DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('praxis-purge-journal', '41 3 * * *',
      'SELECT private.praxis_purger_journal()')$cron$;
  ELSE
    RAISE NOTICE 'PRAXIS-PURGE : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

DO $postflight$
DECLARE
  v_taches integer;
BEGIN
  IF pg_catalog.to_regprocedure('private.praxis_purger_journal(interval)') IS NULL THEN
    RAISE EXCEPTION 'PRAXIS-PURGE : la fonction de purge est absente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'private.praxis_purger_journal(interval)'::regprocedure
                    AND p.prosecdef AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'PRAXIS-PURGE : DEFINER, proprietaire ou search_path invalide';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.praxis_purger_journal(interval)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.praxis_purger_journal(interval)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.praxis_purger_journal(interval)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'private.praxis_purger_journal(interval)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS-PURGE : la fonction de purge est executable par un role client';
  END IF;
  -- Dynamique : sans pg_cron, cron.job n'existe pas.
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $q$SELECT pg_catalog.count(*)::integer FROM cron.job j
                 WHERE j.jobname = 'praxis-purge-journal' AND j.active AND j.schedule = '41 3 * * *'$q$
      INTO v_taches;
    IF v_taches <> 1 THEN
      RAISE EXCEPTION 'PRAXIS-PURGE : la tache de purge n''est pas planifiee une fois par jour';
    END IF;
  END IF;
END;
$postflight$;
