-- F86 : garde admin positive et NULL-safe pour les mutations de groupes.
create or replace function public.creer_groupe(
  p_teacher_profile_id uuid,
  p_type_public text,
  p_libelle text,
  p_weekday smallint,
  p_hour_local smallint,
  p_seuil_max smallint default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $function$
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

  insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
  values (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$;

create or replace function public.modifier_groupe(
  p_groupe_id uuid,
  p_libelle text,
  p_seuil_max smallint,
  p_weekday smallint,
  p_hour_local smallint
)
returns void
language plpgsql security definer set search_path = ''
as $function$
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
$function$;

create or replace function public.ajouter_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'ajout d''un eleve a un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour ajouter un eleve a un groupe';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.role = 'student'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if exists (
    select 1 from public.groupe_membres where student_id = p_student_profile_id and left_at is null
  ) then
    raise exception 'cet eleve appartient deja a un groupe actif';
  end if;

  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);

  perform public.log_sensitive_access(
    'eleve_ajoute_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$;

create or replace function public.retirer_eleve_groupe(
  p_groupe_id uuid,
  p_student_profile_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'retrait d''un eleve d''un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer un eleve d''un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = p_motif
  where groupe_id = p_groupe_id and student_id = p_student_profile_id and left_at is null;

  if not found then
    raise exception 'cet eleve n''est pas membre actif de ce groupe';
  end if;

  perform public.log_sensitive_access(
    'eleve_retire_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$;

create or replace function public.cloturer_groupe(
  p_groupe_id uuid,
  p_motif text
)
returns void
language plpgsql security definer set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'cloture de groupe reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour cloturer un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = 'groupe cloture : ' || p_motif
  where groupe_id = p_groupe_id and left_at is null;

  update public.groupes
  set ended_at = now(), ended_by = auth.uid(), end_reason = p_motif
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access('groupe_cloture', 'groupes', p_groupe_id::text, jsonb_build_object('motif', p_motif));
end;
$function$;

create or replace function public.creer_groupe(
  p_teacher_profile_id uuid,
  p_type_public text,
  p_libelle text,
  p_weekday smallint,
  p_hour_local smallint,
  p_seuil_max smallint default null,
  p_timezone_iana text default null,
  p_couleur_jeton smallint default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

create or replace function public.modifier_groupe(
  p_groupe_id uuid,
  p_libelle text,
  p_seuil_max smallint,
  p_weekday smallint,
  p_hour_local smallint,
  p_timezone_iana text default null,
  p_couleur_jeton smallint default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

alter function public.creer_groupe(uuid,text,text,smallint,smallint,smallint) owner to postgres;
comment on function public.creer_groupe(uuid,text,text,smallint,smallint,smallint) is 'F86 candidate allowlist: signature=public.creer_groupe(uuid,text,text,smallint,smallint,smallint); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';
alter function public.modifier_groupe(uuid,text,smallint,smallint,smallint) owner to postgres;
comment on function public.modifier_groupe(uuid,text,smallint,smallint,smallint) is 'F86 candidate allowlist: signature=public.modifier_groupe(uuid,text,smallint,smallint,smallint); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';
alter function public.ajouter_eleve_groupe(uuid,uuid,text) owner to postgres;
comment on function public.ajouter_eleve_groupe(uuid,uuid,text) is 'F86 candidate allowlist: signature=public.ajouter_eleve_groupe(uuid,uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';
alter function public.retirer_eleve_groupe(uuid,uuid,text) owner to postgres;
comment on function public.retirer_eleve_groupe(uuid,uuid,text) is 'F86 candidate allowlist: signature=public.retirer_eleve_groupe(uuid,uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';
alter function public.cloturer_groupe(uuid,text) owner to postgres;
comment on function public.cloturer_groupe(uuid,text) is 'F86 candidate allowlist: signature=public.cloturer_groupe(uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';
alter function public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint) owner to postgres;
comment on function public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint) is 'F86 candidate allowlist: signature=public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';
alter function public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint) owner to postgres;
comment on function public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint) is 'F86 candidate allowlist: signature=public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

do $f86_postflight$
declare
  v_signature text;
  v_proc record;
begin
  foreach v_signature in array array[
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint)',
    'public.ajouter_eleve_groupe(uuid,uuid,text)',
    'public.retirer_eleve_groupe(uuid,uuid,text)',
    'public.cloturer_groupe(uuid,text)',
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)'
  ] loop
    select p.prosecdef, p.proowner::regrole::text as owner_name,
           p.proconfig, p.prosrc
      into v_proc
      from pg_catalog.pg_proc p
      where p.oid = v_signature::regprocedure;
    if not found or not v_proc.prosecdef or v_proc.owner_name <> 'postgres'
       or not ('search_path=""' = any(v_proc.proconfig))
       or v_proc.prosrc not ilike '%not coalesce(public.app_role() = ''admin'' and public.app_account_valid(), false)%'
       or not pg_catalog.has_function_privilege('authenticated', v_signature, 'execute')
       or pg_catalog.has_function_privilege('anon', v_signature, 'execute') then
      raise exception 'F86 postflight echec pour %', v_signature;
    end if;
  end loop;
end
$f86_postflight$;
