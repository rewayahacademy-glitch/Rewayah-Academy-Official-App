CREATE OR REPLACE FUNCTION public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)
 RETURNS session_shared_content
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_ligne public.session_shared_content;
begin
  if not coalesce(
    public.app_account_valid()
    and (
      (public.app_role() = 'teacher'
       and public.session_belongs_to_teacher(p_session_id, auth.uid()))
      or public.app_role() = 'admin'
    ),
    false
  ) then
    raise exception 'publication etat partage refusee' using errcode = '42501';
  end if;

  if p_session_id is null or p_resource_id is null
     or p_revision is null or p_revision < 0
     or not coalesce(p_display_mode in ('page', 'verse', 'focus'), false)
     or not coalesce(pg_catalog.jsonb_typeof(p_content_position) = 'object', false)
     or p_content_position ->> 'resource_id' is distinct from p_resource_id::text
     or p_content_position ->> 'resource_version_id'
          is distinct from p_resource_version_id::text
     or not coalesce(pg_catalog.jsonb_typeof(p_hidden_ranges) = 'array', false)
     or not coalesce(pg_catalog.jsonb_typeof(p_semantic_markers) = 'array', false) then
    raise exception 'etat partage invalide';
  end if;

  if p_content_range is not null and (
    not coalesce(pg_catalog.jsonb_typeof(p_content_range) = 'object', false)
    or p_content_range ->> 'resource_id' is distinct from p_resource_id::text
  ) then
    raise exception 'plage partagee incompatible avec la ressource';
  end if;

  if p_group_resume_position is not null and (
    not coalesce(pg_catalog.jsonb_typeof(p_group_resume_position) = 'object', false)
    or p_group_resume_position ->> 'resource_id' is distinct from p_resource_id::text
  ) then
    raise exception 'position de reprise incompatible avec la ressource';
  end if;

  if p_resource_version_id is not null and not exists (
    select 1 from public.resource_version rv
     where rv.id = p_resource_version_id
       and rv.resource_id = p_resource_id
  ) then
    raise exception 'version de ressource invalide';
  end if;

  insert into public.session_shared_content as c (
    session_id, resource_id, resource_version_id, content_position,
    content_range, display_mode, hidden_ranges, semantic_markers,
    group_resume_position, revision, updated_by, updated_at
  ) values (
    p_session_id, p_resource_id, p_resource_version_id, p_content_position,
    p_content_range, p_display_mode, p_hidden_ranges, p_semantic_markers,
    p_group_resume_position, p_revision, auth.uid(), pg_catalog.now()
  )
  on conflict (session_id) do update
    set resource_id = excluded.resource_id,
        resource_version_id = excluded.resource_version_id,
        content_position = excluded.content_position,
        content_range = excluded.content_range,
        display_mode = excluded.display_mode,
        hidden_ranges = excluded.hidden_ranges,
        semantic_markers = excluded.semantic_markers,
        group_resume_position = excluded.group_resume_position,
        revision = excluded.revision,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at
    where c.revision < excluded.revision
  returning * into v_ligne;

  if v_ligne.session_id is null then
    select * into v_ligne
      from public.session_shared_content
     where session_id = p_session_id;
  end if;

  return v_ligne;
end;
$function$

