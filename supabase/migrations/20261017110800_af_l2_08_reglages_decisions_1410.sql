-- AF L2-08 (ALIGN-1410-BACK) : reglages serveur alignes sur les decisions du
-- 29/09 au 14/10/2026 (matrice D-16 a D-19).
--
-- Le registre dit « correction par update, sans migration » : cela vaut pour la
-- base distante. Une valeur posee a la main sur STAGING n'est pas rejouable ;
-- cette migration de donnees, idempotente, fait dire la meme chose a la CI, a
-- STAGING et a la production.
--
-- Valeurs (fiche L2-08, section 1) :
--   cohortes 6-9, 10-13, 14-17, 18+ (29/09, confirme 12/10)
--   age minimum 6 ans, exception tracee par l'administration (13/10)
--   groupe.minimum_lancement = 4 ; seance.pause_minutes_enfant = 5 (12/10)
--   groupe.capacite_debutant = 4 (cle seule : groupes n'a pas de niveau)
--   child_ui_mode_max_age = 9 (interface guidee jusqu'a 9 ans inclus)
--
-- creer_profil_enfant : l'appel reste celui du tuteur connecte (derniere
-- definition : 20261013000200). L'exception d'age passe par une surcharge a sept
-- parametres, appelee par un administrateur valide avec un motif ; la signature
-- a six parametres est conservee et delegue sans exception.
begin;

-- (a) les quatre nouveaux codes, puis (b) les references, puis (c) la purge.
insert into public.cohortes_age
  (code, nom_humain, age_min, age_max_inclus, type_public, student_type, interface_mode, ordre) values
  ('enfant_6_9',     '6 à 9 ans',      6,  9,    'enfant', 'minor',      'child',    1),
  ('enfant_10_13',   '10 à 13 ans',    10, 13,   'enfant', 'minor',      'standard', 2),
  ('ado_14_17',      '14 à 17 ans',    14, 17,   'enfant', 'minor',      'standard', 3),
  ('adulte_18_plus', '18 ans et plus', 18, null, 'adulte', 'autonomous', 'standard', 5)
on conflict (code) do update set
  nom_humain = excluded.nom_humain,
  age_min = excluded.age_min,
  age_max_inclus = excluded.age_max_inclus,
  type_public = excluded.type_public,
  student_type = excluded.student_type,
  interface_mode = excluded.interface_mode,
  ordre = excluded.ordre,
  actif = true;

-- student_profiles n'a pas l'age : correspondance par tranche, faute de mieux.
update public.student_profiles set cohorte = 'enfant_6_9'
 where cohorte in ('enfant_5_7', 'enfant_8_10');
update public.student_profiles set cohorte = 'enfant_10_13' where cohorte = 'ado_11_14';
update public.student_profiles set cohorte = 'ado_14_17'    where cohorte = 'ado_15_17';

do $purge$
declare
  v_ref record;
  v_n bigint;
begin
  -- Aucune table ne doit encore pointer vers un ancien code, quelle qu'elle soit.
  for v_ref in
    select c.conrelid::regclass::text as tbl, a.attname::text as col
      from pg_catalog.pg_constraint c
      join pg_catalog.pg_attribute a
        on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
     where c.contype = 'f' and c.confrelid = 'public.cohortes_age'::regclass
  loop
    execute format(
      'select count(*) from %s where %I in (%L, %L, %L, %L)',
      v_ref.tbl, v_ref.col, 'enfant_5_7', 'enfant_8_10', 'ado_11_14', 'ado_15_17')
      into v_n;
    if v_n > 0 then
      raise exception 'L2-08: % ligne(s) de %.% referencent encore un ancien code de cohorte',
        v_n, v_ref.tbl, v_ref.col;
    end if;
  end loop;
end;
$purge$;

delete from public.cohortes_age
 where code in ('enfant_5_7', 'enfant_8_10', 'ado_11_14', 'ado_15_17');

-- (d) app_config. Le trigger app_config_history journalise les changements de
-- valeur ; une cle nouvelle n'a pas d'ancienne valeur a journaliser.
insert into public.app_config (key, value) values
  ('groupe.minimum_lancement',    to_jsonb(4)),
  ('seance.pause_minutes_enfant', to_jsonb(5)),
  ('groupe.capacite_debutant',    to_jsonb(4)),
  ('child_ui_mode_max_age',       to_jsonb(9))
on conflict (key) do update set value = excluded.value, updated_at = now();

-- STAGING porte aussi `groupe.pause_enfant_minutes` (MESURES 3.4) : aucun code
-- du depot ne la lit ; si elle existe, elle suit.
update public.app_config set value = to_jsonb(5), updated_at = now()
 where key = 'groupe.pause_enfant_minutes' and value is distinct from to_jsonb(5);

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
  -- Exception d'age : motif non vide ET administrateur valide. Un tuteur qui
  -- fournit un motif reste un tuteur : il n'obtient aucune exception.
  v_exception := coalesce(btrim(p_exception_admin_motif), '') <> ''
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
  if v_exception and p_age < 6 then
    perform public.log_sensitive_access('age_exception', 'profiles', p_auth_user_id::text,
      jsonb_build_object('admin_id', auth.uid(), 'age', p_age,
        'motif', btrim(p_exception_admin_motif), 'household_id', v_guardian.household_id));
  end if;
  return v_profile;
end;
$function$;

-- La signature a six parametres garde ses droits et delegue sans exception.
create or replace function public.creer_profil_enfant(
  p_auth_user_id uuid,
  p_guardian_id uuid,
  p_first_name text,
  p_last_name text,
  p_age integer,
  p_level text default null
) returns public.profiles
language plpgsql security definer set search_path = ''
as $function$
begin
  return public.creer_profil_enfant(
    p_auth_user_id, p_guardian_id, p_first_name, p_last_name, p_age, p_level, null::text);
end;
$function$;

alter function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text) owner to postgres;
alter function public.creer_profil_enfant(uuid, uuid, text, text, integer, text) owner to postgres;
revoke all on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text)
  from public, anon, service_role, agent_ro;
grant execute on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text)
  to authenticated;
revoke all on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  from public, anon, service_role, agent_ro;
grant execute on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  to authenticated;

-- Empreintes F86 : calculees sur la definition reelle, pas recopiees a la main.
do $allowlist$
declare
  v_sig text;
  v_oid oid;
  v_guard text;
begin
  foreach v_sig in array array[
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)',
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'
  ] loop
    v_oid := v_sig::regprocedure;
    v_guard := case when v_sig like '%,text,text)'
      then 'AUTHENTICATED_GUARDIAN_OR_ADMIN_AGE_EXCEPTION_AND_SERVER_CHILD_OF_RECENT_UNCONFIRMED_NO_SESSION_NO_PROFILE'
      else 'AUTHENTICATED_GUARDIAN_DELEGATES_NO_EXCEPTION' end;
    execute format('comment on function %s is %L', v_sig, format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17; L2-08: age minimum 6 ans, exception tracee par l administration.',
      v_sig,
      md5(pg_get_functiondef(v_oid)), v_guard));
  end loop;
end;
$allowlist$;

-- (f) postflight.
do $postflight$
declare
  v_codes text;
begin
  select string_agg(code, ',' order by code) into v_codes from public.cohortes_age;
  if v_codes is distinct from 'ado_14_17,adulte_18_plus,enfant_10_13,enfant_6_9' then
    raise exception 'L2-08 postflight: cohortes = %', v_codes;
  end if;
  if public.app_config_int('groupe.minimum_lancement', 0) <> 4
     or public.app_config_int('seance.pause_minutes_enfant', 0) <> 5
     or public.app_config_int('groupe.capacite_debutant', 0) <> 4 then
    raise exception 'L2-08 postflight: valeurs app_config incorrectes';
  end if;
  if position('âge minimum 6 ans' in pg_get_functiondef(
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure)) = 0 then
    raise exception 'L2-08 postflight: garde d''age absente';
  end if;
  if has_function_privilege('anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or has_function_privilege('service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE') then
    raise exception 'L2-08 postflight: droits EXECUTE incorrects';
  end if;
end;
$postflight$;

commit;
