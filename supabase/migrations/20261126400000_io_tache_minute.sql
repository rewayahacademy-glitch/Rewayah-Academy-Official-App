-- IO-TACHE-MINUTE (14/11/2026) : alerte Supabase « Disk IO Budget » sur la
-- production, sans payer de compute (directeur, 14/11 : « je ne vais pas payer
-- pour compute »).
--
-- Constat en production (lecture seule, 14/11/2026, pg_stat_statements) :
-- le premier ecrivain du disque est pg_cron lui-meme. Sept taches tournent
-- chaque minute (courriels-envoi, push-envoi, remplacement_auto,
-- remplacement_fenetres, entretien_avis, observation-coupure, audit_chaine) ;
-- chaque passage ecrit 5 fois dans cron.job_run_details (insert + 4 updates) :
-- environ 10 000 passages et 50 000 ecritures par jour, la plus grosse part du
-- WAL de la base (91 Mo de journal pour une base de 149 Mo).
--
-- Changement : une seule tache par minute, `tache-minute`, qui passe les sept
-- l'une apres l'autre. Chaque tache garde sa commande exacte, lue dans
-- cron.job au moment du passage (rien n'est recopie : ni adresse, ni secret) ;
-- chacune tourne dans son propre bloc : l'echec de l'une n'empeche pas les
-- suivantes, et il est garde dans le message de retour. Les sept taches
-- restent dans cron.job, desactivees (cron.alter_job active => false) : rien
-- n'est efface, on revient en arriere en les reactivant.
-- Effet attendu : 7 fois moins de passages journalises (1 440 par jour).
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement.
-- Sans pg_cron (CI), rien n'est planifie.

CREATE OR REPLACE FUNCTION private.tache_minute()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY INVOKER
 SET search_path TO ''
AS $function$
DECLARE
  v_noms text[] := ARRAY['courriels-envoi', 'push-envoi', 'remplacement_auto',
                         'remplacement_fenetres', 'entretien_avis',
                         'observation-coupure', 'audit_chaine'];
  v_nom text;
  v_commande text;
  v_echecs text := '';
BEGIN
  FOREACH v_nom IN ARRAY v_noms LOOP
    v_commande := NULL;
    EXECUTE 'SELECT command FROM cron.job WHERE jobname = $1 LIMIT 1'
      INTO v_commande USING v_nom;
    CONTINUE WHEN v_commande IS NULL;
    BEGIN
      EXECUTE v_commande;
    EXCEPTION WHEN OTHERS THEN
      v_echecs := v_echecs || v_nom || ' : ' || SQLERRM || E'\n';
    END;
  END LOOP;
  IF v_echecs <> '' THEN
    RAISE WARNING 'tache-minute : %', v_echecs;
    RETURN 'echecs : ' || v_echecs;
  END IF;
  RETURN 'ok';
END;
$function$;
ALTER FUNCTION private.tache_minute() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.tache_minute() FROM PUBLIC, anon, authenticated;

DO $planification$
DECLARE
  v_id bigint;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    RAISE NOTICE 'IO-TACHE-MINUTE : pg_cron absente, rien n''est planifie';
    RETURN;
  END IF;
  EXECUTE $c$SELECT cron.schedule('tache-minute', '* * * * *', 'SELECT private.tache_minute()')$c$;
  FOR v_id IN EXECUTE $q$
      SELECT jobid FROM cron.job
       WHERE jobname IN ('courriels-envoi', 'push-envoi', 'remplacement_auto',
                         'remplacement_fenetres', 'entretien_avis',
                         'observation-coupure', 'audit_chaine')
         AND active$q$
  LOOP
    EXECUTE 'SELECT cron.alter_job(job_id => $1, active => false)' USING v_id;
  END LOOP;
END;
$planification$;
