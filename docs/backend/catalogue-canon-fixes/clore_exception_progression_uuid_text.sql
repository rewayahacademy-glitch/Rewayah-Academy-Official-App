CREATE OR REPLACE FUNCTION public.clore_exception_progression(p_exception_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'cloture d''une exception de progression reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour clore une exception';
  end if;

  update public.progression_exceptions
  set closed_at = now(), closed_par = auth.uid(), close_motif = p_motif
  where id = p_exception_id and closed_at is null;

  if not found then
    raise exception 'exception introuvable ou deja cloturee';
  end if;

  perform public.log_sensitive_access(
    'exception_progression_cloturee', 'progression_exceptions', p_exception_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$

