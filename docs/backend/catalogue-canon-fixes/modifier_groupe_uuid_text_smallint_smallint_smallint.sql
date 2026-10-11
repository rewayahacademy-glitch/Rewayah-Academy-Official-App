CREATE OR REPLACE FUNCTION public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actifs int;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle, seuil_max = p_seuil_max, weekday = p_weekday, hour_local = p_hour_local
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$

