CREATE OR REPLACE FUNCTION public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_statut text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour supprimer un niveau';
  end if;

  select pv.statut into v_statut
  from public.programme_niveaux pn
  join public.programme_versions pv on pv.id = pn.version_id
  where pn.id = p_niveau_id;

  if v_statut is null then
    raise exception 'niveau introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : impossible de supprimer un niveau publie';
  end if;

  delete from public.programme_niveaux where id = p_niveau_id;

  perform public.log_sensitive_access(
    'niveau_programme_supprime', 'programme_niveaux', p_niveau_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$

