CREATE OR REPLACE FUNCTION public.guard_contract_acceptances_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  raise exception 'une acceptation de contrat ne se modifie ni ne s''efface';
end;
$function$

