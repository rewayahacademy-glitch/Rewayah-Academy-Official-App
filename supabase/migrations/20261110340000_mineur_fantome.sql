-- MINEUR-FANTOME (06/11/2026, ordre du directeur relaye par le garde-cap) :
-- `creer_profil_enfant` ne cree plus de profil eleve MINEUR pour un adulte.
--
-- Constat (lecture seule en production, 06/11/2026) : deux adultes inscrits
-- « pour moi » ont un profil eleve mineur a leurs propres prenom et nom, cree
-- 9 et 25 minutes apres leur compte, par le formulaire « Ajouter un profil
-- eleve » (fonction Edge creer-profil-enfant -> cette fonction). Le Foyer leur
-- disait « Aucun profil eleve » (UX-023) ; la fonction acceptait jusqu'a
-- 99 ans et posait toujours student_type = 'minor'.
--
-- Deux refus nouveaux, dans la surcharge a sept parametres (toute la logique ;
-- celle a six parametres delegue et ne change pas) :
--   * un age de 18 ans ou plus : un mineur a moins de 18 ans ;
--   * un prenom + nom identiques a ceux du titulaire appelant, compares sans
--     casse, sans accents latins courants et sans espaces doubles.
-- Les deux messages commencent par un marqueur stable que le client reconnait
-- (« profil du titulaire » et « age adulte ») et renvoient vers « Creer mon
-- profil eleve » (creer_profil_eleve_titulaire, 0052).
--
-- L'exception d'age de la direction (3 a 5 ans, L2-08 reprise) ne change pas.
-- Le corps reprend la version en production (md5 de pg_get_functiondef
-- 52fa141491170592a9041094880c322d, relu le 06/11/2026, controle par le
-- preflight) ; seules les deux regles s'ajoutent, apres « âge minimum 6 ans ».
-- Aucune donnee touchee, aucune instruction d'effacement.
begin;

-- ---------------------------------------------------------------------------
-- 1. Preflight : la fonction remplacee est bien celle de la production
-- ---------------------------------------------------------------------------
do $preflight$
declare
  v_def text;
begin
  select pg_catalog.pg_get_functiondef(p.oid) into v_def
    from pg_catalog.pg_proc p
   where p.oid = 'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure;
  if v_def is null then
    raise exception 'MINEUR-FANTOME : creer_profil_enfant a sept parametres absente';
  end if;
  -- La version de production, ou celle de ce fichier (rejeu).
  if pg_catalog.md5(v_def) <> '52fa141491170592a9041094880c322d'
     and pg_catalog.strpos(v_def, 'profil du titulaire') = 0 then
    raise exception 'MINEUR-FANTOME : creer_profil_enfant a change depuis la lecture du 06/11 (md5 %)',
      pg_catalog.md5(v_def);
  end if;
end;
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. La surcharge a sept parametres, avec les deux refus
-- ---------------------------------------------------------------------------
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
  -- MINEUR-FANTOME (06/11/2026) : un profil eleve cree ici est un mineur.
  if p_age >= 18 then
    raise exception 'age adulte : un profil eleve de 18 ans ou plus ne se cree pas ici ; pour soi-meme, creer mon profil eleve'
      using errcode = 'check_violation';
  end if;
  -- MINEUR-FANTOME : le titulaire ne se recree pas en mineur (memes prenom et
  -- nom, sans casse, accents latins courants ni espaces doubles).
  if pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.translate(
         pg_catalog.btrim(p_first_name) || ' ' || pg_catalog.btrim(p_last_name),
         'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖòóôõöÙÚÛÜùúûüÝýÿ',
         'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOoooooUUUUuuuuYyy')), '\s+', ' ', 'g')
     = pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.translate(
         pg_catalog.btrim(v_guardian.first_name) || ' ' || pg_catalog.btrim(v_guardian.last_name),
         'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖòóôõöÙÚÛÜùúûüÝýÿ',
         'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOoooooUUUUuuuuYyy')), '\s+', ' ', 'g') then
    raise exception 'profil du titulaire : ce prenom et ce nom sont ceux du titulaire ; pour soi-meme, creer mon profil eleve'
      using errcode = 'check_violation';
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

-- ---------------------------------------------------------------------------
-- 3. Empreinte F86 recalculee sur la definition reelle
-- ---------------------------------------------------------------------------
do $allowlist$
declare
  v_sig constant text := 'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)';
begin
  execute pg_catalog.format('comment on function %s is %L', v_sig, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-06; L2-08 reprise D-6: exception d age bornee aux moins de 6 ans, tracee par l administration; MINEUR-FANTOME: refus de 18 ans ou plus et des prenom et nom du titulaire.',
    v_sig,
    pg_catalog.md5(pg_catalog.pg_get_functiondef(v_sig::regprocedure)),
    'AUTHENTICATED_GUARDIAN_OR_ADMIN_AGE_EXCEPTION_UNDER_6_AND_SERVER_CHILD_OF_RECENT_UNCONFIRMED_NO_SESSION_NO_PROFILE_MINOR_ONLY_NOT_SELF'));
end;
$allowlist$;

-- ---------------------------------------------------------------------------
-- 4. Postflight
-- ---------------------------------------------------------------------------
do $postflight$
declare
  v_def text := pg_catalog.pg_get_functiondef(
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure);
begin
  if pg_catalog.strpos(v_def, 'p_age >= 18') = 0
     or pg_catalog.strpos(v_def, 'profil du titulaire') = 0
     or pg_catalog.strpos(v_def, 'age adulte') = 0
     or pg_catalog.strpos(v_def, 'p_age between 3 and 5') = 0
     or pg_catalog.strpos(v_def, 'âge minimum 6 ans') = 0 then
    raise exception 'MINEUR-FANTOME postflight : regles absentes';
  end if;
  if pg_catalog.has_function_privilege('anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or pg_catalog.has_function_privilege('service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or not pg_catalog.has_function_privilege('authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE') then
    raise exception 'MINEUR-FANTOME postflight : droits EXECUTE incorrects';
  end if;
  if not exists (
       select 1 from pg_catalog.pg_proc p
        where p.oid = 'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure
          and p.proconfig @> array['search_path=""']::text[]
          and pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') then
    raise exception 'MINEUR-FANTOME postflight : search_path ou proprietaire incorrect';
  end if;
end;
$postflight$;

commit;
