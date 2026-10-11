CREATE OR REPLACE FUNCTION public.publier_version_programme(p_version_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_statut text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'publication du programme reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour publier une version';
  end if;

  select statut into v_statut from public.programme_versions where id = p_version_id;

  if v_statut is null then
    raise exception 'version introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'cette version est deja publiee ou archivee';
  end if;

  if not exists (select 1 from public.programme_niveaux where version_id = p_version_id) then
    raise exception 'impossible de publier une version sans aucun niveau';
  end if;

  update public.programme_versions
  set statut = 'publiee', publiee_at = now(), publiee_par = auth.uid()
  where id = p_version_id;

  perform public.log_sensitive_access(
    'programme_version_publiee', 'programme_versions', p_version_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$

