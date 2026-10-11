CREATE OR REPLACE FUNCTION public.guard_audit_logs_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  raise exception 'audit_logs est append-only';
end;
$function$

