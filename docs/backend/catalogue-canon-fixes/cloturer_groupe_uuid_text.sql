CREATE OR REPLACE FUNCTION public.cloturer_groupe(p_groupe_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'cloture de groupe reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour cloturer un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = 'groupe cloture : ' || p_motif
  where groupe_id = p_groupe_id and left_at is null;

  update public.groupes
  set ended_at = now(), ended_by = auth.uid(), end_reason = p_motif
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access('groupe_cloture', 'groupes', p_groupe_id::text, jsonb_build_object('motif', p_motif));
end;
$function$

