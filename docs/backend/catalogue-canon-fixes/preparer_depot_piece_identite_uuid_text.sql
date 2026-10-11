CREATE OR REPLACE FUNCTION public.preparer_depot_piece_identite(p_profile_id uuid, p_doc_type text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_document_id uuid := gen_random_uuid();
  v_cible uuid := coalesce(p_profile_id, auth.uid());
  v_cle text;
begin
  -- La cle de service contourne la RLS ; cette fonction est `security definer`
  -- et la contourne aussi. Elle rejoue donc la porte, qui vit a part pour que
  -- la confirmation pose exactement la meme question.
  if v_cible is null then
    raise exception 'authentification requise' using errcode = '42501';
  end if;

  if not public.peut_deposer_piece_identite(v_cible) then
    raise exception 'depot refuse pour ce profil' using errcode = '42501';
  end if;

  if p_doc_type is null or p_doc_type not in ('id_card', 'passport', 'residence_permit', 'other') then
    raise exception 'type de piece inconnu' using errcode = '22023';
  end if;

  -- La convention de `_shared/r2/cles.ts`, cote base, au caractere pres :
  -- identity/<profile_id>/<document_id>. Aucune donnee lisible, que des UUID.
  v_cle := 'identity/' || v_cible::text || '/' || v_document_id::text;

  insert into public.kyc_documents
    (id, profile_id, doc_type, object_key, storage_backend, status, deleted_at)
  values (v_document_id, v_cible, p_doc_type, v_cle, 'r2', 'pending', now());

  -- Meme raison qu'a la lecture : la nature du document n'entre pas dans un
  -- journal que toute l'administration lit.
  perform public.log_sensitive_access(
    'kyc_document_prepare',
    'kyc_documents',
    v_document_id::text,
    jsonb_build_object('profile_id', v_cible, 'storage_backend', 'r2')
  );

  return jsonb_build_object('document_id', v_document_id, 'object_key', v_cle);
end;
$function$

