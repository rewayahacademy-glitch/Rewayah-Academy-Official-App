CREATE OR REPLACE FUNCTION public.refuser_empreinte_contrat_fournie()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if new.signed_sha256 is not null then
    raise exception using
      errcode = '42501',
      message = 'signed_sha256_server_managed';
  end if;
  return new;
end;
$function$

