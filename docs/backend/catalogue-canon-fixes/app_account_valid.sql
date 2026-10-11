CREATE OR REPLACE FUNCTION public.app_account_valid()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
      and (p.access_until is null or p.access_until > now())
  );
$function$

