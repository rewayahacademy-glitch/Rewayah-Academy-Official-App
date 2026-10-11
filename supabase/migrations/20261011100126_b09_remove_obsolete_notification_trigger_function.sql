-- Retire the C-22 SECURITY DEFINER trigger function after B-09 replaced its
-- trigger with the SECURITY INVOKER producer. Leaving an unattached trigger
-- function in public still makes the security-definer catalog gate reject it.
BEGIN;

DROP TRIGGER IF EXISTS demandes_horaires_notification
  ON public.demandes_horaires_famille;
DROP FUNCTION IF EXISTS public.tc_demande_horaire_notification();

DO $verification$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'tc_demande_horaire_notification'
  ) OR EXISTS (
    SELECT 1
    FROM pg_catalog.pg_trigger t
    WHERE t.tgrelid = 'public.demandes_horaires_famille'::regclass
      AND t.tgname = 'demandes_horaires_notification'
      AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'B-09: obsolete SECURITY DEFINER producer remains';
  END IF;
END
$verification$;

COMMIT;
