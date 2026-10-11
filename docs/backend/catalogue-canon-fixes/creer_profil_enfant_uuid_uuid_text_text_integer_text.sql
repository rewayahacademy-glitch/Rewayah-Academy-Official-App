CREATE OR REPLACE FUNCTION public.creer_profil_enfant(p_auth_user_id uuid, p_guardian_id uuid, p_first_name text, p_last_name text, p_age integer, p_level text DEFAULT NULL::text)
 RETURNS profiles
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_guardian public.profiles;
  v_profile public.profiles;
  v_mode public.interface_mode;
  v_camera public.camera_policy;
  v_seuil_enfant int;
  v_age_camera int;
begin
  select * into v_guardian
  from public.profiles p
  where p.id = p_guardian_id and p.deleted_at is null;

  if v_guardian.id is null or v_guardian.role <> 'guardian' then
    raise exception 'l''appelant n''est pas un tuteur';
  end if;
  if v_guardian.household_id is null then
    raise exception 'ce tuteur n''a pas de foyer';
  end if;
  if v_guardian.account_status not in ('active', 'provisional_active') then
    raise exception 'compte tuteur non valide';
  end if;
  if coalesce(btrim(p_first_name), '') = '' or coalesce(btrim(p_last_name), '') = '' then
    raise exception 'prenom et nom sont requis';
  end if;
  if p_age is null or p_age < 3 or p_age > 99 then
    raise exception 'age hors bornes';
  end if;

  -- Les deux valeurs initiales viennent de la configuration, jamais du client :
  -- ce sont elles qui decident du mode d'interface et de la politique camera
  -- (ADR-009). Le tuteur les modifie ensuite, enfant par enfant, depuis TUT-05.
  select coalesce((public.get_config('child_ui_mode_max_age', '8'::jsonb) #>> '{}')::int, 8)
    into v_seuil_enfant;
  select coalesce((public.get_config('camera_auto_allow_min_age', '11'::jsonb) #>> '{}')::int, 11)
    into v_age_camera;

  v_mode := case when p_age <= v_seuil_enfant then 'child' else 'standard' end;
  v_camera := case when p_age >= v_age_camera then 'allowed' else 'forbidden' end;

  insert into public.profiles (
    id, immutable_id, role, household_id, first_name, last_name, account_status
  ) values (
    p_auth_user_id,
    public.next_immutable_id('student', upper(left(btrim(p_first_name), 1) || left(btrim(p_last_name), 1))),
    'student',
    v_guardian.household_id,
    btrim(p_first_name),
    btrim(p_last_name),
    -- L'enfant herite de l'acces de son foyer : le dossier valide est celui du
    -- tuteur, l'enfant n'en depose aucun.
    v_guardian.account_status
  )
  returning * into v_profile;

  insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy, level)
  values (p_auth_user_id, 'minor', v_mode, v_camera, p_level);

  perform public.log_sensitive_access('profil_enfant_cree', 'profiles', p_auth_user_id::text,
    jsonb_build_object('household_id', v_guardian.household_id, 'mode', v_mode::text));

  return v_profile;
end;
$function$

