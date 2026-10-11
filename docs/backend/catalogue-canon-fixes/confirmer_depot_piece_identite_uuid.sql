CREATE OR REPLACE FUNCTION public.confirmer_depot_piece_identite(p_document_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_touche int;
  v_profil uuid;
begin
  if p_document_id is null then
    raise exception 'document non precise' using errcode = '22023';
  end if;

  -- Seule une reservation R2 encore non confirmee peut etre rendue visible.
  -- Les trois conditions comptent : `storage_backend = 'r2'` empeche de
  -- ressusciter une piece du stockage historique, `status = 'pending'` empeche
  -- de rouvrir un dossier deja tranche, et `deleted_at is not null` fait que la
  -- fonction est sans effet sur une piece deja vivante.
  update public.kyc_documents k
  set deleted_at = null
  where k.id = p_document_id
    and k.storage_backend = 'r2'
    and k.status = 'pending'
    and k.deleted_at is not null
  returning k.profile_id into v_profil;

  get diagnostics v_touche = row_count;
  if v_touche = 0 then
    raise exception 'aucune reservation a confirmer' using errcode = '42501';
  end if;

  perform public.log_sensitive_access(
    'kyc_document_confirm',
    'kyc_documents',
    p_document_id::text,
    jsonb_build_object('profile_id', v_profil, 'storage_backend', 'r2')
  );

  return true;
end;
$function$

