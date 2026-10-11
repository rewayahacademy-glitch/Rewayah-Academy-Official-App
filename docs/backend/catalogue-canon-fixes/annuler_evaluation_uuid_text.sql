CREATE OR REPLACE FUNCTION public.annuler_evaluation(p_evaluation_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'annulation d''une evaluation reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour annuler une evaluation';
  end if;

  update public.evaluations
  set statut = 'annulee', notes = p_motif, updated_at = now()
  where id = p_evaluation_id and statut = 'planifiee';

  if not found then
    raise exception 'evaluation introuvable ou deja realisee/annulee';
  end if;

  perform public.log_sensitive_access(
    'evaluation_annulee', 'evaluations', p_evaluation_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$

