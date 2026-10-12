-- CAP-29 §5.4: hide draft/withdrawn resources from every non-admin surface.
-- The preceding CAP-29 integrity migration guarantees that a non-null
-- current_version_id belongs to this resource and is the unique published
-- version, avoiding a recursive RLS query from library_resource back to
-- resource_version.

begin;

drop policy library_resource_lecture on public.library_resource;
create policy library_resource_lecture on public.library_resource
  for select to authenticated using (
    public.app_account_valid()
    and (
      public.app_role() = 'admin'
      or (
        archived_at is null
        and current_version_id is not null
        and (
          access_policy in ('publique', 'inscrits')
          or (
            access_policy in ('groupe_assigne', 'enseignant_seul')
            and exists (
              select 1
                from public.library_resource_groupe lrg
                join public.groupes g on g.id = lrg.groupe_id
               where lrg.resource_id = library_resource.id
                 and (
                   g.teacher_id = auth.uid()
                   or (
                     access_policy = 'groupe_assigne'
                     and exists (
                       select 1
                         from public.groupe_membres m
                        where m.groupe_id = g.id
                          and m.left_at is null
                          and (
                            m.student_id = auth.uid()
                            or public.est_du_foyer(m.student_id)
                          )
                     )
                   )
                 )
            )
          )
        )
      )
    )
  );

drop policy resource_version_lecture on public.resource_version;
create policy resource_version_lecture on public.resource_version
  for select to authenticated using (
    public.app_account_valid()
    and (
      public.app_role() = 'admin'
      or (
        statut = 'publiee'
        and exists (
          select 1
            from public.library_resource r
           where r.id = resource_version.resource_id
             and r.current_version_id = resource_version.id
             and r.archived_at is null
        )
      )
    )
  );

-- download_asset contains raw storage keys. No client role may query it
-- directly; later admin/consumer RPCs must return an allowlisted projection
-- and enforce the specific licensed use before issuing a short-lived URL.
drop policy download_asset_lecture on public.download_asset;
revoke all on table public.download_asset from public, anon, authenticated, service_role, agent_ro;

drop policy library_resource_groupe_lecture on public.library_resource_groupe;
create policy library_resource_groupe_lecture on public.library_resource_groupe
  for select to authenticated using (
    public.app_account_valid()
    and (
      public.app_role() = 'admin'
      or exists (
        select 1
          from public.groupes g
         where g.id = library_resource_groupe.groupe_id
           and (
             g.teacher_id = auth.uid()
             or exists (
               select 1
                 from public.groupe_membres m
                where m.groupe_id = g.id
                  and m.left_at is null
                  and (
                    m.student_id = auth.uid()
                    or public.est_du_foyer(m.student_id)
                  )
             )
           )
      )
    )
  );

do $$
declare
  v_qual text;
begin
  select lower(qual) into v_qual
    from pg_catalog.pg_policies
   where schemaname = 'public'
     and tablename = 'library_resource'
     and policyname = 'library_resource_lecture';
  if v_qual is null
     or position('current_version_id' in v_qual) = 0
     or position('archived_at' in v_qual) = 0
     or position('app_account_valid' in v_qual) = 0 then
    raise exception 'CAP-29: policy ressource ne ferme pas les brouillons/retraits';
  end if;

  select lower(qual) into v_qual
    from pg_catalog.pg_policies
   where schemaname = 'public'
     and tablename = 'resource_version'
     and policyname = 'resource_version_lecture';
  if v_qual is null
     or position('current_version_id' in v_qual) = 0
     or position('archived_at' in v_qual) = 0
     or position('app_account_valid' in v_qual) = 0 then
    raise exception 'CAP-29: policy version ne ferme pas l historique';
  end if;

  if has_table_privilege('anon', 'public.download_asset', 'SELECT')
     or has_table_privilege('authenticated', 'public.download_asset', 'SELECT')
     or has_table_privilege('service_role', 'public.download_asset', 'SELECT')
     or has_table_privilege('agent_ro', 'public.download_asset', 'SELECT') then
    raise exception 'CAP-29: une cle de stockage reste lisible via la Data API';
  end if;

  if (
    select count(*)
      from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relname in ('library_resource', 'resource_version', 'download_asset')
       and c.relrowsecurity
  ) <> 3 then
    raise exception 'CAP-29: RLS des tables catalogue desactivee';
  end if;
end;
$$;

commit;
