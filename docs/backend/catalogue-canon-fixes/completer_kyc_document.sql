CREATE OR REPLACE FUNCTION public.completer_kyc_document()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_genre public.gender;
begin
  if new.purge_at is null then
    new.purge_at := now() + make_interval(days =>
      coalesce((public.get_config('kyc_retention_days', '90'::jsonb) #>> '{}')::int, 90));
  end if;

  select p.gender into v_genre
  from public.profiles p
  where p.id = new.profile_id and p.deleted_at is null;

  if v_genre is null then
    raise exception 'genre du titulaire inconnu : impossible de classer ce dossier';
  end if;

  new.gender := v_genre;
  return new;
end;
$function$

