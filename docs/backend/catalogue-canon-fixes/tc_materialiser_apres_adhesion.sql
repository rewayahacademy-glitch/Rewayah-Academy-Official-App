CREATE OR REPLACE FUNCTION public.tc_materialiser_apres_adhesion()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform public.materialiser_seances_groupe(new.groupe_id);
  return new;
end;
$function$

