CREATE OR REPLACE FUNCTION public.publier_offre_horaire(p_offre_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication d''offre reservee a l''administration';
  end if;

  update public.offres_horaires
  set etat = 'publiee', publiee_at = now(), publiee_par = auth.uid()
  where id = p_offre_id and etat = 'brouillon';

  if not found then
    raise exception 'offre introuvable ou deja publiee';
  end if;

  perform public.log_sensitive_access(
    'offre_horaire_publiee', 'offres_horaires', p_offre_id::text, '{}'::jsonb);
end;
$function$

