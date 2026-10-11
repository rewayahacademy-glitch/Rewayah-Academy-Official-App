CREATE OR REPLACE FUNCTION public.compte_en_parcours()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(
    (
      select p.deleted_at is null
         and p.account_status in ('pending_kyc', 'active', 'provisional_active')
         and (p.access_until is null or p.access_until > now())
      from public.profiles p
      where p.id = auth.uid()
    ),
    false
  );
$function$

