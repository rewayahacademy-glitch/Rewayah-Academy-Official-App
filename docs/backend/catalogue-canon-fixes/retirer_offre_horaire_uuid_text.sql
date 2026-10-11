CREATE OR REPLACE FUNCTION public.retirer_offre_horaire(p_offre_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'retrait d''offre reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer une offre';
  end if;

  update public.offres_horaires
  set etat = 'retiree', retiree_at = now(), retiree_par = auth.uid(),
      retrait_motif = btrim(p_motif)
  where id = p_offre_id and etat <> 'retiree';

  if not found then
    raise exception 'offre introuvable ou deja retiree';
  end if;

  perform public.log_sensitive_access(
    'offre_horaire_retiree', 'offres_horaires', p_offre_id::text,
    jsonb_build_object('motif', btrim(p_motif)));
end;
$function$

