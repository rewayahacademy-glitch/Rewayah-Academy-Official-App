begin;

-- C-35: the object key is a public storage locator, never a credential.
-- Read access remains decided under the authenticated caller JWT.
create or replace function public.autoriser_lecture_version(
  p_resource_version_id uuid
) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
  v_resource_id uuid;
  v_asset_id uuid;
  v_version integer;
  v_access_policy public.library_access_policy;
  v_key text;
begin
  if not coalesce(
    public.app_account_valid()
      and public.app_role() in ('admin', 'accountant', 'controller', 'teacher', 'guardian', 'student'),
    false
  ) then
    raise exception 'lecture refusee' using errcode = '42501';
  end if;

  v_role := public.app_role();

  select r.id, da.id, v.numero_version, r.access_policy, da.cle_stockage
    into v_resource_id, v_asset_id, v_version, v_access_policy, v_key
    from public.resource_version v
    join public.library_resource r
      on r.id = v.resource_id
     and r.current_version_id = v.id
     and r.archived_at is null
    join public.download_asset da
      on da.id = v.download_asset_id
     and da.resource_version_id = v.id
    join public.library_version_rights rights
      on rights.resource_version_id = v.id
     and rights.resource_id = r.id
     and rights.approuve
     and 'application' = any(rights.usages)
     and (rights.expire_le is null or rights.expire_le > clock_timestamp())
    left join private.library_rights_proofs proof
      on proof.id = rights.preuve_id
     and proof.resource_version_id = v.id
     and proof.resource_id = r.id
   where v.id = p_resource_version_id
     and v.statut = 'publiee'
     and (rights.preuve_id is null or proof.statut = 'confirmee')
     and (
       v_role = 'admin'
       or v_access_policy in ('publique', 'inscrits')
       or (
         v_access_policy in ('groupe_assigne', 'enseignant_seul')
         and exists (
           select 1
             from public.library_resource_groupe lrg
             join public.groupes g on g.id = lrg.groupe_id
            where lrg.resource_id = r.id
              and g.ended_at is null
              and (
                g.teacher_id = auth.uid()
                or (
                  v_access_policy = 'groupe_assigne'
                  and exists (
                    select 1
                      from public.groupe_membres m
                     where m.groupe_id = g.id
                       and m.left_at is null
                       and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
                  )
                )
              )
         )
       )
     );

  if not found
     or v_key is null
     or v_key !~ ('^supports/' || v_asset_id::text || '/' || v_version::text || '/[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') then
    raise exception 'lecture refusee' using errcode = '42501';
  end if;

  perform public.log_sensitive_access(
    'library_read',
    'resource_version',
    p_resource_version_id::text,
    jsonb_build_object('resource_id', v_resource_id, 'operation', 'lecture')
  );

  return v_key;
end;
$$;
alter function public.autoriser_lecture_version(uuid) owner to postgres;
revoke all on function public.autoriser_lecture_version(uuid) from public, anon, service_role, agent_ro;
grant execute on function public.autoriser_lecture_version(uuid) to authenticated;
revoke all on table public.download_asset from public, anon, authenticated, service_role, agent_ro;

comment on function public.autoriser_lecture_version(uuid) is
  'C-35/F86 candidate; signature=public.autoriser_lecture_version(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=empty; caller_jwt_required=true; audit=library_read; cle_stockage=locator_not_secret; runtime_replay_required.';

do $$
declare
  v_owner text;
  v_search_path text[];
  v_definition text;
begin
  select pg_catalog.pg_get_userbyid(p.proowner), p.proconfig, p.prosrc
    into v_owner, v_search_path, v_definition
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname = 'autoriser_lecture_version'
     and pg_catalog.pg_get_function_identity_arguments(p.oid) = 'p_resource_version_id uuid';
  if v_owner is distinct from 'postgres'
     or not coalesce(v_search_path @> array['search_path=""'], false)
     or position('if not coalesce(' in lower(v_definition) = 0
     or has_function_privilege('anon', 'public.autoriser_lecture_version(uuid)', 'EXECUTE')
     or has_function_privilege('service_role', 'public.autoriser_lecture_version(uuid)', 'EXECUTE')
     or has_function_privilege('agent_ro', 'public.autoriser_lecture_version(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.autoriser_lecture_version(uuid)', 'EXECUTE')
     or has_table_privilege('authenticated', 'public.download_asset', 'SELECT')
     or has_table_privilege('agent_ro', 'public.download_asset', 'SELECT') then
    raise exception 'C-35/F86 postflight failed';
  end if;
  if exists (
    select 1
      from pg_catalog.pg_trigger t
      join pg_catalog.pg_proc p on p.oid = t.tgfoid
     where t.tgname in ('cap29_bump_resource_revision', 'cap29_require_approved_rights')
       and not t.tgisinternal and p.prosecdef
  ) then
    raise exception 'C-35: SECURITY DEFINER trigger forbidden';
  end if;
end;
$$;

commit;
