-- D11 (24/10/2026) : planifier la cloture automatique des seances.
--
-- Constat en production (lecture seule, 24/10) : la migration
-- 20261018180000_ses_cloture_auto.sql ne planifie la tache que si pg_cron est
-- installee au moment ou elle tourne ; elle ne l'etait pas. `cron.job` ne
-- contient que `courriels-envoi` : aucune seance ne passe jamais a `ended`
-- (ni `teacher_absent`), et la paie, qui ne compte que les seances `ended`,
-- ne se calcule pas. pg_cron 1.6.4 est maintenant installee.
--
-- Meme planification que 20261018180000 (toutes les 15 minutes, meme
-- fonction, meme nom de tache), idempotente : `cron.schedule` sur un nom
-- existant met la tache a jour au lieu d'en creer une seconde. Gardee par la
-- presence de pg_cron, comme l'originale (la CI rejoue les migrations sur un
-- Postgres sans pg_cron).
--
-- Effet au premier passage : les seances deja echues encore « planned »
-- (une le 24/10 a 16:00 UTC) sont closes par la machine d'etats, avec leur
-- journal `seance_cloturee_auto`.
--
-- Aucune suppression.

BEGIN;

DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('ses_cloture_auto', '*/15 * * * *',
      'SELECT private.ses_cloturer_seances_echues(pg_catalog.clock_timestamp())')$cron$;
  ELSE
    RAISE NOTICE 'D11 : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

COMMIT;
