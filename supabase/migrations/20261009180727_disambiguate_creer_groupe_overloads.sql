-- 0045: disambiguate the short and extended group RPC overloads.
-- 0044 is already present on STAGING. PostgreSQL cannot remove argument
-- defaults with CREATE OR REPLACE, so replace the two exact extended
-- signatures atomically. Their optional final color stays optional, while the
-- preceding timezone is required. Six-argument create and five-argument edit
-- calls now resolve to their short overloads.
BEGIN;

DROP FUNCTION public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint);
CREATE FUNCTION public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_seuil smallint;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'creation de groupe reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  if p_timezone_iana is not null then
    perform 1 from pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  v_seuil := coalesce(
    p_seuil_max,
    case p_type_public
      when 'enfant' then 5
      when 'adulte' then 6
      else null
    end
  );

  if v_seuil is null then
    raise exception 'type de public inconnu : %', p_type_public;
  end if;

  insert into public.groupes
    (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, couleur_jeton)
  values
    (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local,
     coalesce(p_timezone_iana, 'Europe/Paris'), p_couleur_jeton)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$;
REVOKE EXECUTE ON FUNCTION public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint) TO authenticated;

DROP FUNCTION public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint);
CREATE FUNCTION public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint DEFAULT NULL::smallint)
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

  if p_timezone_iana is not null then
    perform 1 from pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle,
      seuil_max = p_seuil_max,
      weekday = p_weekday,
      hour_local = p_hour_local,
      timezone_iana = coalesce(p_timezone_iana, timezone_iana),
      couleur_jeton = coalesce(p_couleur_jeton, couleur_jeton)
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$;
REVOKE EXECUTE ON FUNCTION public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint) TO authenticated;

COMMIT;
