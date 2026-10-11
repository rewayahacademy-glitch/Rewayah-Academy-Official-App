CREATE OR REPLACE FUNCTION public.renoncer_intention_horaire(p_membre_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform public.retirer_demande_horaire(p_membre_id, p_motif);
end;
$function$

