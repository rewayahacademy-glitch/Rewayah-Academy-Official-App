CREATE OR REPLACE FUNCTION public.guard_devices_max_reactivation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  max_devices int;
begin
  if old.revoked_at is null or new.revoked_at is not null then
    return new;
  end if;

  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into max_devices;

  if (select count(*) from public.devices d
      where d.profile_id = new.profile_id
        and d.id <> new.id
        and d.revoked_at is null
        and d.deleted_at is null) >= max_devices then
    raise exception 'plafond d''appareils atteint';
  end if;

  return new;
end;
$function$

