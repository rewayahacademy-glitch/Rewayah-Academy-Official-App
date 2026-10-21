-- AF L2-08 reprise (defaut D-6, verification L2-V) : l'exception d'age de
-- creer_profil_enfant ne vaut que pour l'age qu'elle deroge.
--
-- Avant : tout administrateur valide qui donnait un motif obtenait l'exception
-- pour n'importe quel age, et elle levait aussi la verification « l'appelant est
-- ce tuteur ». Apres : l'exception exige un administrateur valide, un motif non
-- vide ET un age de 3 a 5 ans (moins de 6 ans ; borne basse 3 inchangee). Au-dela,
-- le motif est ignore et la voie tuteur s'applique (appelant = tuteur, sinon
-- 42501). Le foyer du tuteur, le lien child_of et le compte recent restent
-- verifies dans tous les cas. L'exception est journalisee (age_exception).
--
-- La surcharge a six parametres delegue avec un motif nul : inchangee.
begin;

-- (e) creer_profil_enfant. Surcharge a sept parametres : toute la logique.
create or replace function public.creer_profil_enfant(
  p_auth_user_id uuid,
  p_guardian_id uuid,
  p_first_name text,
  p_last_name text,
  p_age integer,
  p_level text,
  p_exception_admin_motif text
) returns public.profiles
language plpgsql security definer set search_path = ''
as $function$
declare
  v_guardian public.profiles;
  v_profile public.profiles;
  v_mode public.interface_mode;
  v_camera public.camera_policy;
  v_seuil_enfant integer;
  v_age_camera integer;
  v_cohorte text;
  v_auth_user jsonb;
  v_has_session boolean := false;
  v_exception boolean;
begin
  -- Exception d'age : motif non vide, administrateur valide ET age de 3 a 5 ans
  -- (seul age qu'elle deroge). Un tuteur qui fournit un motif reste un tuteur ;
  -- un administrateur pour 6 ans ou plus est traite en appelant ordinaire.
  v_exception := coalesce(btrim(p_exception_admin_motif), '') <> ''
    and coalesce(p_age between 3 and 5, false)
    and coalesce(public.app_role() = 'admin' and public.app_account_valid(), false);

  if not v_exception
     and not coalesce(auth.uid() = p_guardian_id and public.app_account_valid(), false) then
    raise exception 'appelant tuteur invalide' using errcode = 'insufficient_privilege';
  end if;

  select * into v_guardian from public.profiles p
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
  if p_age < 6 and not v_exception then
    raise exception 'âge minimum 6 ans' using errcode = 'check_violation';
  end if;

  select pg_catalog.to_jsonb(u) into v_auth_user
    from auth.users u where u.id = p_auth_user_id for update;

  -- auth.sessions fait partie de Supabase Auth mais manque au stub CI minimal.
  if pg_catalog.to_regclass('auth.sessions') is not null then
    execute 'select exists (select 1 from auth.sessions where user_id = $1)'
       into v_has_session using p_auth_user_id;
  end if;

  if v_auth_user is null
     or v_auth_user #>> '{raw_app_meta_data,child_of}' is distinct from p_guardian_id::text
     or nullif(v_auth_user->>'created_at', '') is null
     or (v_auth_user->>'created_at')::timestamptz < pg_catalog.now() - interval '15 minutes'
     or (v_auth_user->>'created_at')::timestamptz > pg_catalog.now() + interval '1 minute'
     or nullif(v_auth_user->>'email_confirmed_at', '') is not null
     or v_has_session
     or exists (select 1 from public.profiles p where p.id = p_auth_user_id) then
    raise exception 'compte enfant non issu de la creation serveur recente'
      using errcode = 'insufficient_privilege';
  end if;

  select coalesce((public.get_config('child_ui_mode_max_age', '9'::jsonb) #>> '{}')::integer, 9)
    into v_seuil_enfant;
  select coalesce((public.get_config('camera_auto_allow_min_age', '11'::jsonb) #>> '{}')::integer, 11)
    into v_age_camera;
  v_mode := case when p_age <= v_seuil_enfant then 'child' else 'standard' end;
  v_camera := case when p_age >= v_age_camera then 'allowed' else 'forbidden' end;

  -- La cohorte se deduit de l'age, cote serveur ; sous 6 ans (exception) aucune
  -- cohorte ne couvre l'enfant et l'administration l'affecte a la main.
  select c.code into v_cohorte
    from public.cohortes_age c
   where c.actif and c.type_public = 'enfant'
     and p_age between c.age_min and coalesce(c.age_max_inclus, 999)
   order by c.ordre
   limit 1;

  insert into public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, account_status)
  values (p_auth_user_id, null, 'student', v_guardian.household_id,
    btrim(p_first_name), btrim(p_last_name), v_guardian.account_status)
  returning * into v_profile;
  insert into public.student_profiles
    (profile_id, student_type, interface_mode, camera_policy, level, cohorte)
  values (p_auth_user_id, 'minor', v_mode, v_camera, p_level, v_cohorte);
  perform public.log_sensitive_access('profil_enfant_cree', 'profiles', p_auth_user_id::text,
    jsonb_build_object('household_id', v_guardian.household_id, 'mode', v_mode::text));
  if v_exception then
    perform public.log_sensitive_access('age_exception', 'profiles', p_auth_user_id::text,
      jsonb_build_object('admin_id', auth.uid(), 'age', p_age,
        'motif', btrim(p_exception_admin_motif), 'household_id', v_guardian.household_id));
  end if;
  return v_profile;
end;
$function$;

-- Droits inchanges (create or replace les conserve) ; reaffirmes par prudence.
alter function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text) owner to postgres;
revoke all on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text)
  from public, anon, service_role, agent_ro;
grant execute on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text)
  to authenticated;

-- Empreinte F86 recalculee sur la definition reelle de la sept parametres.
do $allowlist$
declare
  v_sig constant text := 'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)';
begin
  execute format('comment on function %s is %L', v_sig, format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17; L2-08 reprise D-6: exception d age bornee aux moins de 6 ans, tracee par l administration.',
    v_sig,
    md5(pg_get_functiondef(v_sig::regprocedure)),
    'AUTHENTICATED_GUARDIAN_OR_ADMIN_AGE_EXCEPTION_UNDER_6_AND_SERVER_CHILD_OF_RECENT_UNCONFIRMED_NO_SESSION_NO_PROFILE'));
end;
$allowlist$;

do $postflight$
declare
  v_def text := pg_get_functiondef(
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure);
begin
  if position('p_age between 3 and 5' in v_def) = 0
     or position('âge minimum 6 ans' in v_def) = 0 then
    raise exception 'L2-08 reprise postflight: exception non bornee a 3-5 ans';
  end if;
  if has_function_privilege('anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or has_function_privilege('service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE') then
    raise exception 'L2-08 reprise postflight: droits EXECUTE incorrects';
  end if;
end;
$postflight$;

commit;
