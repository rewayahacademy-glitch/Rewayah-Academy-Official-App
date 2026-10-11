CREATE OR REPLACE FUNCTION public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text DEFAULT NULL::text)
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

  select pv.statut into v_statut
  from public.programme_niveaux pn
  join public.programme_versions pv on pv.id = pn.version_id
  where pn.id = p_niveau_id;

  if v_statut is null then
    raise exception 'niveau introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  end if;

  update public.programme_niveaux
  set nom_humain = p_nom_humain, cycle = p_cycle, ordre = p_ordre, description = p_description
  where id = p_niveau_id;

  perform public.log_sensitive_access(
    'niveau_programme_modifie', 'programme_niveaux', p_niveau_id::text,
    jsonb_build_object('nom_humain', p_nom_humain, 'cycle', p_cycle)
  );
end;
$function$

