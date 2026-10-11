CREATE OR REPLACE FUNCTION public.regle_effective(p_profile_id uuid, p_key text)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not public.partie_concernee(p_profile_id) then
    raise exception 'regles hors du perimetre de lecture';
  end if;
  return public.regle_brute(p_profile_id, p_key);
end;
$function$

