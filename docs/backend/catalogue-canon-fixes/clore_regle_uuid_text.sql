CREATE OR REPLACE FUNCTION public.clore_regle(p_override_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'seul un administrateur clot une regle';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une cloture sans motif ne se relit pas';
  end if;

  update public.rule_overrides
  set ended_at = now(), ended_by = auth.uid(), end_reason = btrim(p_motif)
  where id = p_override_id and ended_at is null;

  if not found then
    raise exception 'regle introuvable ou deja close';
  end if;

  perform public.log_sensitive_access('regle_close', 'rule_overrides',
    p_override_id::text, jsonb_build_object('motif', btrim(p_motif)));
end;
$function$

