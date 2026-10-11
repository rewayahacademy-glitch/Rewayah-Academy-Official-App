CREATE OR REPLACE FUNCTION public.tc_materialiser_apres_creation_groupe()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NEW.ended_at IS NULL
     AND NEW.teacher_id IS NOT NULL
     AND NEW.etat = 'active' THEN
    PERFORM public.materialiser_seances_groupe(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$

