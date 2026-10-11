CREATE OR REPLACE FUNCTION public.creer_offre_horaire(p_type_public text, p_langue_code text, p_fuseau_iana text, p_jours smallint[], p_heure_locale smallint, p_duree_minutes smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_duree smallint;
  v_attendu smallint := public.app_config_int('groupe.seances_par_semaine', 3)::smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'creation d''offre reservee a l''administration';
  end if;

  if p_type_public not in ('enfant', 'adulte') then
    raise exception 'public inconnu : %', coalesce(p_type_public, 'aucun');
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_iana) then
    raise exception 'fuseau IANA inconnu : %', coalesce(p_fuseau_iana, 'aucun');
  end if;

  if not public.jours_iso_valides(p_jours) then
    raise exception 'jours invalides : un tableau non vide de jours ISO distincts est attendu';
  end if;

  if array_length(p_jours, 1) <> v_attendu then
    raise exception 'l''academie annonce % seances par semaine, % jours fournis',
      v_attendu, array_length(p_jours, 1);
  end if;

  v_duree := coalesce(
    p_duree_minutes,
    case p_type_public
      when 'adulte' then public.app_config_int('seance.duree_minutes_adulte', 90)::smallint
      else public.app_config_int('seance.duree_minutes_enfant', 60)::smallint
    end
  );

  insert into public.offres_horaires
    (type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, created_by)
  values
    (p_type_public, p_langue_code, p_fuseau_iana, p_jours, p_heure_locale, v_duree, auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access(
    'offre_horaire_creee', 'offres_horaires', v_id::text,
    jsonb_build_object('type_public', p_type_public, 'langue', p_langue_code,
                       'jours', p_jours, 'heure', p_heure_locale)
  );

  return v_id;
end;
$function$

