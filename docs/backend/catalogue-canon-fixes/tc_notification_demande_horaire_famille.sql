CREATE OR REPLACE FUNCTION public.tc_notification_demande_horaire_famille()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE
  v_evenement text;
  v_foyer_id uuid;
  v_destinataire uuid;
BEGIN
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

  INSERT INTO public.notifications
    (destinataire, foyer_id, evenement, params, destination)
  SELECT DISTINCT destinataire, v_foyer_id, v_evenement,
         jsonb_strip_nulls(jsonb_build_object(
           'demande_id', NEW.id,
           'etat', NEW.etat,
           'motif', CASE WHEN TG_OP = 'UPDATE' THEN NEW.motif END
         )),
         '/tuteur/demandes'
    FROM unnest(ARRAY[
      v_destinataire,
      CASE WHEN NEW.type_public = 'adulte' THEN NEW.eleve_id END
    ]::uuid[]) AS destinataire
   WHERE destinataire IS NOT NULL;

  RETURN NEW;
END;
$function$

