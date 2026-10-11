CREATE OR REPLACE FUNCTION public.guard_app_config_history()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.value is distinct from new.value then
    insert into public.app_config_history (key, old_value, new_value, changed_by)
    values (new.key, old.value, new.value, coalesce(new.updated_by, auth.uid()));
  end if;
  return new;
end;
$function$

