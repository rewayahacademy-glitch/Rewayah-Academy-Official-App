-- 0057 — persistance sûre de l'état de présentation d'une séance.
-- La table et sa RPC initiale viennent de 0032/0033; cette migration renforce
-- les gardes et fournit l'effacement explicite après clôture réelle.
begin;

revoke insert, update, delete on public.session_shared_content
  from public, anon, authenticated, agent_ro;
grant select on public.session_shared_content to authenticated;

drop policy if exists ssc_admin_read on public.session_shared_content;
create policy ssc_admin_read on public.session_shared_content
  for select to authenticated
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

create or replace function public.publier_etat_partage(
  p_session_id            uuid,
  p_resource_id           uuid,
  p_resource_version_id   uuid,
  p_content_position      jsonb,
  p_content_range         jsonb,
  p_display_mode          text,
  p_hidden_ranges         jsonb,
  p_semantic_markers      jsonb,
  p_group_resume_position jsonb,
  p_revision              integer
) returns public.session_shared_content
language plpgsql
security definer
set search_path = ''
as $function$
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
$function$;

create or replace function public.effacer_etat_partage(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
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
    raise exception 'effacement etat partage refuse' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.sessions s
     where s.id = p_session_id
       and s.status = 'ended'
       and (
         s.teacher_id = auth.uid()
         or public.app_role() = 'admin'
       )
  ) then
    raise exception 'etat partage effacable apres cloture de la seance';
  end if;

  delete from public.session_shared_content
   where session_id = p_session_id;
end;
$function$;

revoke all on function public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)
  from public, anon, agent_ro;
grant execute on function public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)
  to authenticated;
revoke all on function public.effacer_etat_partage(uuid) from public, anon, agent_ro;
grant execute on function public.effacer_etat_partage(uuid) to authenticated;

commit;
