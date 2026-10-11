CREATE OR REPLACE FUNCTION public.guard_profile_immutable_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.immutable_id is distinct from new.immutable_id then
    raise exception 'immutable_id ne peut pas être modifié';
  end if;
  return new;
end;
$function$

