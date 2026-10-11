CREATE OR REPLACE FUNCTION public.creer_version_programme(p_source_version_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_numero int;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'creation de version de programme reservee a l''administration';
  end if;

  if p_source_version_id is not null and not exists (
    select 1 from public.programme_versions where id = p_source_version_id
  ) then
    raise exception 'version source introuvable';
  end if;

  select coalesce(max(numero_version), 0) + 1 into v_numero from public.programme_versions;

  insert into public.programme_versions (statut, numero_version, cree_par)
  values ('brouillon', v_numero, auth.uid())
  returning id into v_id;

  if p_source_version_id is not null then
    insert into public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre, description)
    select v_id, code_technique, nom_humain, cycle, ordre, description
    from public.programme_niveaux
    where version_id = p_source_version_id;
  end if;

  perform public.log_sensitive_access(
    'programme_version_creee', 'programme_versions', v_id::text,
    jsonb_build_object('numero_version', v_numero, 'source_version_id', p_source_version_id)
  );

  return v_id;
end;
$function$

