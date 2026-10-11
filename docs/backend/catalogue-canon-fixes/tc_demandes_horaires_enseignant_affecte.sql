CREATE OR REPLACE FUNCTION public.tc_demandes_horaires_enseignant_affecte()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
BEGIN
  IF OLD.teacher_id IS NULL AND NEW.teacher_id IS NOT NULL AND NEW.etat = 'active' THEN
    UPDATE public.demandes_horaires_famille
       SET etat = 'enseignant_affecte', updated_at = pg_catalog.now()
     WHERE groupe_id = NEW.id AND etat = 'classe_validee';
  END IF;
  RETURN NEW;
END;
$function$

