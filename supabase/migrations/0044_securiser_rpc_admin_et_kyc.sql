-- 0044: ferme les RPC d'administration/KYC aux rôles anonymes et agent_ro.
-- Sources des définitions : pg_get_functiondef relu en lecture seule sur PROD le 2026-10-09.
-- Les gardes exigent explicitement un rôle autorisé, même si app_role() retourne NULL.
-- Aucun changement de schéma ni d'API; les signatures et résultats sont conservés.

CREATE OR REPLACE FUNCTION public.comptes_admin()
 RETURNS TABLE(profile_id uuid, immutable_id text, prenom text, nom text, role app_role, etat_compte account_status, inscrit_le timestamp with time zone, acces_jusqu_au timestamp with time zone, foyer_id uuid, etat_piece text, contrats integer, a_enseignant boolean, enfants_du_foyer integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.role,
    p.account_status,
    p.created_at,
    p.access_until,
    p.household_id,
    case
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'pending' and k.deleted_at is null
      ) then 'a_verifier'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'approved' and k.deleted_at is null
      ) then 'validee'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'rejected' and k.deleted_at is null
      ) then 'refusee'
      else 'aucune'
    end::text,
    (select count(*)::int from public.contract_acceptances c where c.profile_id = p.id),
    exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p.id and a.ended_at is null
    ),
    (select count(*)::int from public.profiles e
      where e.household_id = p.household_id
        and e.role = 'student' and e.deleted_at is null)
  from public.profiles p
  where p.deleted_at is null
    and public.app_role() = 'admin'
    and public.app_account_valid()
  order by
    case p.account_status
      when 'pending_kyc' then 0
      when 'provisional_active' then 1
      else 2
    end,
    p.created_at asc;
$function$;

CREATE OR REPLACE FUNCTION public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text DEFAULT NULL::text, p_couleur_jeton smallint DEFAULT NULL::smallint)
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

CREATE OR REPLACE FUNCTION public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint DEFAULT NULL::smallint)
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

CREATE OR REPLACE FUNCTION public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text DEFAULT NULL::text, p_couleur_jeton smallint DEFAULT NULL::smallint)
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
$function$;

CREATE OR REPLACE FUNCTION public.read_kyc_documents()
 RETURNS SETOF kyc_documents
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  reader_gender public.gender;
begin
  if not coalesce(public.app_role() in ('admin', 'controller'), false) then
    raise exception 'acces KYC refuse';
  end if;

  select p.gender into reader_gender
  from public.profiles p
  where p.id = auth.uid() and p.deleted_at is null;

  -- I9 : un genre inconnu ferme, il ne filtre pas a moitie. Un repli silencieux
  -- rendait la moitie des dossiers invisible sans que personne ne le sache.
  --
  -- Ce refus precede volontairement la journalisation : une exception annule la
  -- transaction, donc journaliser d'abord ecrirait la trace d'une lecture qui
  -- n'a jamais eu lieu, puis l'effacerait. On refuse, puis on journalise ce qui
  -- va reellement sortir.
  if reader_gender is null then
    raise exception 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier';
  end if;

  -- Chaque lecture est journalisee avant que la moindre ligne ne sorte
  -- (invariant I8, scenario 12 de l'etape 1).
  perform public.log_sensitive_access('kyc_read', 'kyc_documents', null::text,
    jsonb_build_object('reader_gender', reader_gender));

  return query
    select k.* from public.kyc_documents k
    where k.deleted_at is null and k.gender = reader_gender;
end;
$function$;

revoke execute on function public.comptes_admin() from public, anon, agent_ro;
grant execute on function public.comptes_admin() to authenticated;
revoke execute on function public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint) from public, anon, agent_ro;
grant execute on function public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint) to authenticated;
revoke execute on function public.creer_groupe(uuid,text,text,smallint,smallint,smallint) from public, anon, agent_ro;
grant execute on function public.creer_groupe(uuid,text,text,smallint,smallint,smallint) to authenticated;
revoke execute on function public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint) from public, anon, agent_ro;
grant execute on function public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint) to authenticated;
revoke execute on function public.modifier_groupe(uuid,text,smallint,smallint,smallint) from public, anon, agent_ro;
grant execute on function public.modifier_groupe(uuid,text,smallint,smallint,smallint) to authenticated;
revoke execute on function public.read_kyc_documents() from public, anon, agent_ro;
grant execute on function public.read_kyc_documents() to authenticated;

do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'public.comptes_admin()',
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)',
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)',
    'public.modifier_groupe(uuid,text,smallint,smallint,smallint)',
    'public.read_kyc_documents()'
  ] loop
    if pg_catalog.has_function_privilege('anon', v_signature, 'execute') then
      raise exception '0044 incomplete: anon retains EXECUTE on %', v_signature;
    end if;
    if pg_catalog.has_function_privilege('agent_ro', v_signature, 'execute') then
      raise exception '0044 incomplete: agent_ro retains EXECUTE on %', v_signature;
    end if;
    if not pg_catalog.has_function_privilege('authenticated', v_signature, 'execute') then
      raise exception '0044 incomplete: authenticated lacks EXECUTE on %', v_signature;
    end if;
  end loop;
end $$;
