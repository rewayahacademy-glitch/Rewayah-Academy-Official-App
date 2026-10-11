CREATE OR REPLACE FUNCTION public.notifications_accuse_serveur()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.lu_le := coalesce(old.lu_le, pg_catalog.now());
  return new;
end;
$function$

