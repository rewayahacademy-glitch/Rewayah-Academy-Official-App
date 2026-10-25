-- B2.2 bis (a), « la cloche » (plan de nuit du pilote, 24/10/2026).
--
-- Constat : `materialiser_seances_groupe` ne tourne qu'aux moments ou une
-- Classe change (creation, affectation, deplacement, inscription). Une Classe
-- que personne ne touche voit son horizon de quatre semaines
-- (`matching_horizon_weeks`) s'epuiser : apres la derniere seance
-- materialisee, plus rien a « Rejoindre ».
--
-- La cloche : chaque nuit, la meme fonction est rejouee sur toutes les
-- Classes actives. Elle est idempotente (elle saute toute seance deja
-- presente a la meme heure) : la rejouer ne cree aucun doublon et ne
-- reecrit rien. Une Classe en erreur (chevauchement de l'enseignant, par
-- exemple) est journalisee en WARNING et n'arrete pas les autres.
--
-- Planification gardee par la presence de pg_cron, comme
-- 20261024180000_ses_cloture_auto_planifiee.sql (la CI rejoue les migrations
-- sur un Postgres sans pg_cron). `cron.schedule` sur un nom existant met la
-- tache a jour.
--
-- Aucune suppression.

BEGIN;

CREATE OR REPLACE FUNCTION private.materialiser_classes_actives()
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid;
  v_n integer := 0;
BEGIN
  FOR v_groupe IN
    SELECT g.id FROM public.groupes g
    WHERE g.ended_at IS NULL AND g.etat = 'active' AND g.teacher_id IS NOT NULL
    ORDER BY g.id
  LOOP
    BEGIN
      v_n := v_n + public.materialiser_seances_groupe(v_groupe);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'la cloche : Classe % non materialisee (%, %)',
        v_groupe, SQLSTATE, SQLERRM;
    END;
  END LOOP;
  RETURN v_n;
END;
$function$;

REVOKE ALL ON FUNCTION private.materialiser_classes_actives() FROM PUBLIC;
DO $droits$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION private.materialiser_classes_actives() FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.materialiser_classes_actives() IS
  'B2.2 bis (a), la cloche : rejoue materialiser_seances_groupe sur toutes les Classes actives (pg_cron, chaque nuit).';

DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('seances_cloche', '17 2 * * *',
      'SELECT private.materialiser_classes_actives()')$cron$;
  ELSE
    RAISE NOTICE 'la cloche : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

COMMIT;
