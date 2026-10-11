CREATE OR REPLACE FUNCTION public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'retrait d''un eleve d''un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer un eleve d''un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = p_motif
  where groupe_id = p_groupe_id and student_id = p_student_profile_id and left_at is null;

  if not found then
    raise exception 'cet eleve n''est pas membre actif de ce groupe';
  end if;

  perform public.log_sensitive_access(
    'eleve_retire_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$

