CREATE OR REPLACE FUNCTION public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_statut text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  select statut into v_statut from public.programme_versions where id = p_version_id;

  if v_statut is null then
    raise exception 'version introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  end if;

  insert into public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre, description)
  values (p_version_id, p_code_technique, p_nom_humain, p_cycle, p_ordre, p_description)
  returning id into v_id;

  perform public.log_sensitive_access(
    'niveau_programme_ajoute', 'programme_niveaux', v_id::text,
    jsonb_build_object('version_id', p_version_id, 'code_technique', p_code_technique)
  );

  return v_id;
end;
$function$

