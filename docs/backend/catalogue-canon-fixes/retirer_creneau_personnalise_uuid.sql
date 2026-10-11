CREATE OR REPLACE FUNCTION public.retirer_creneau_personnalise(p_membre_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform public.retirer_demande_horaire(p_membre_id, 'retrait_famille');
end;
$function$

