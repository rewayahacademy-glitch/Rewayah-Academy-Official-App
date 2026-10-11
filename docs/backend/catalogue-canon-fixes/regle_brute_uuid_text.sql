CREATE OR REPLACE FUNCTION public.regle_brute(p_profile_id uuid, p_key text)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_valeur text;
begin
  select r.value #>> '{}' into v_valeur
  from public.rule_overrides r
  where r.profile_id = p_profile_id and r.key = p_key and r.ended_at is null;

  if v_valeur is null then
    select public.get_config(p_key, null) #>> '{}' into v_valeur;
  end if;

  if v_valeur is null then
    raise exception 'regle inconnue : %', p_key;
  end if;
  return v_valeur::int;
end;
$function$

