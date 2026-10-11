-- B-09: notify the primary guardian when a child request arrives or is refused.
-- The notification is produced in the same transaction as the request change.
BEGIN;

CREATE FUNCTION public.tc_notification_demande_horaire_famille()
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
  ELSIF OLD.etat IS DISTINCT FROM NEW.etat AND NEW.etat = 'refusee' THEN
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
     AND guardian.account_status = 'active'
     AND guardian.deleted_at IS NULL;

  IF v_destinataire IS NOT NULL THEN
    INSERT INTO public.notifications
      (destinataire, foyer_id, evenement, params, destination)
    VALUES
      (v_destinataire, v_foyer_id, v_evenement,
       jsonb_build_object('etat', NEW.etat), '/tuteur/demandes');
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.tc_notification_demande_horaire_famille()
  FROM PUBLIC, anon, authenticated, agent_ro;

CREATE TRIGGER notifications_demande_horaire_famille
AFTER INSERT OR UPDATE OF etat ON public.demandes_horaires_famille
FOR EACH ROW
EXECUTE FUNCTION public.tc_notification_demande_horaire_famille();

COMMIT;
