CREATE OR REPLACE FUNCTION public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_doc public.kyc_documents;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'seul un administrateur decide d''un dossier';
  end if;

  -- Un refus sans motif laisserait TUT-00b sans rien a dire, et la famille sans
  -- rien a corriger.
  if not p_approuve and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un refus exige un motif';
  end if;

  -- Le filtre de genre s'applique a la decision, pas seulement a l'affichage :
  -- sinon il suffirait de connaitre un identifiant pour le contourner.
  select * into v_doc from public.read_kyc_documents() k where k.id = p_document_id;
  if v_doc.id is null then
    raise exception 'dossier introuvable ou hors du perimetre de lecture';
  end if;

  update public.kyc_documents
  set status = case when p_approuve then 'approved'::public.kyc_doc_status
                    else 'rejected'::public.kyc_doc_status end,
      rejection_reason = case when p_approuve then null else btrim(p_motif) end,
      verified_by = auth.uid(),
      verified_at = now()
  where id = p_document_id;

  if p_approuve then
    update public.profiles
    set account_status = 'active', updated_at = now()
    where id = v_doc.profile_id and account_status = 'pending_kyc';
  end if;

  update public.teacher_profiles
  set kyc_status = case when p_approuve then 'approved' else 'rejected' end
  where profile_id = v_doc.profile_id;

  perform public.log_sensitive_access('kyc_decision', 'kyc_documents', p_document_id::text,
    jsonb_build_object('approuve', p_approuve, 'motif', btrim(coalesce(p_motif, ''))));
end;
$function$

