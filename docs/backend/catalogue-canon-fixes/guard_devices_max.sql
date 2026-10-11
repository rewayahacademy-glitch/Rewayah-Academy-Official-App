CREATE OR REPLACE FUNCTION public.guard_devices_max()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  max_devices int;
begin
  select coalesce(value #>> '{}', '2')::int into max_devices
  from public.app_config where key = 'max_devices_per_student';

  if (select count(*) from public.devices d
      where d.profile_id = new.profile_id and d.revoked_at is null and d.deleted_at is null
     ) >= max_devices then
    raise exception 'plafond d''appareils atteint';
  end if;
  return new;
end;
$function$

