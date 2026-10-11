-- B-09: notify the primary guardian when a child request arrives or is refused.
-- The notification is produced in the same transaction as the request change.
BEGIN;

CREATE OR REPLACE FUNCTION public.tc_notification_demande_horaire_famille()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_evenement text;
  v_foyer_id uuid;
  v_destinataire uuid;
BEGIN
  IF NEW.type_public IS DISTINCT FROM 'enfant' THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_evenement := 'demande_recue';
  ELSIF OLD.etat IS DISTINCT FROM NEW.etat
        AND NEW.etat IN ('refusee', 'retiree') THEN
    v_evenement := 'demande_close';
  ELSE
    RETURN NEW;
  END IF;

  SELECT h.id, guardian.id
    INTO v_foyer_id, v_destinataire
    FROM public.profiles student
    JOIN public.households h ON h.id = student.household_id
    JOIN public.profiles guardian ON guardian.id = h.primary_guardian_id
   WHERE student.id = NEW.eleve_id
     AND student.role = 'student'
     AND student.deleted_at IS NULL
     AND guardian.role = 'guardian'
     AND guardian.account_status IN ('active', 'provisional_active')
     AND guardian.deleted_at IS NULL;

  IF v_destinataire IS NOT NULL THEN
    INSERT INTO public.notifications
      (destinataire, foyer_id, evenement, params, destination)
    VALUES
      (v_destinataire, v_foyer_id, v_evenement,
       jsonb_build_object('demande_id', NEW.id, 'etat', NEW.etat),
       '/tuteur/demandes');
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.tc_notification_demande_horaire_famille()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Replace the older notification trigger from the C-22 candidate, avoiding two
-- producers for the same request event when the migration lines are composed.
DROP TRIGGER IF EXISTS demandes_horaires_notification
  ON public.demandes_horaires_famille;
DROP TRIGGER IF EXISTS notifications_demande_horaire_famille
  ON public.demandes_horaires_famille;

CREATE TRIGGER notifications_demande_horaire_famille
AFTER INSERT OR UPDATE OF etat ON public.demandes_horaires_famille
FOR EACH ROW
EXECUTE FUNCTION public.tc_notification_demande_horaire_famille();

-- Keep the existing assignment transition but execute it with the caller's
-- authority. The assignment RPC owns the transaction and already runs as the
-- database owner; the trigger itself does not elevate privileges.
CREATE OR REPLACE FUNCTION public.tc_demandes_horaires_enseignant_affecte()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF OLD.teacher_id IS NULL AND NEW.teacher_id IS NOT NULL AND NEW.etat = 'active' THEN
    UPDATE public.demandes_horaires_famille
       SET etat = 'enseignant_affecte', updated_at = pg_catalog.now()
     WHERE groupe_id = NEW.id AND etat = 'classe_validee';
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION public.tc_demandes_horaires_enseignant_affecte()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $verification$
BEGIN
  IF pg_catalog.has_table_privilege('anon', 'public.notifications', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'public.notifications', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'public.notifications', 'INSERT')
     OR pg_catalog.has_table_privilege('service_role', 'public.notifications', 'UPDATE')
     OR EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'public'
         AND p.proname IN (
           'tc_notification_demande_horaire_famille',
           'tc_demandes_horaires_enseignant_affecte'
         )
         AND (p.prosecdef OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[])
     )
     OR EXISTS (
       SELECT 1
       FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.demandes_horaires_famille'::regclass
         AND t.tgname = 'demandes_horaires_notification'
         AND NOT t.tgisinternal
     ) THEN
    RAISE EXCEPTION 'B-09: notification trigger or table privilege postflight failed';
  END IF;
END
$verification$;

COMMIT;
