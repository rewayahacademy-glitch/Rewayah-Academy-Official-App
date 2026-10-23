-- CAP-29: use the existing caller-scoped group projections in library RLS.
-- Reading groupe_membres from these policies recurses through its own policy.

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
               where lrg.resource_id = library_resource.id
                 and (
                   (
                     public.app_role() = 'teacher'
                     and exists (
                       select 1 from public.mes_groupes_v mg
                        where mg.groupe_id = lrg.groupe_id
                     )
                   )
                   or (
                     public.app_role() in ('guardian', 'student')
                     and access_policy = 'groupe_assigne'
                     and exists (
                       select 1 from public.mes_groupes_famille_v mg
                        where mg.groupe_id = lrg.groupe_id
                     )
                   )
                 )
            )
          )
        )
      )
    )
  );

drop policy library_resource_groupe_lecture on public.library_resource_groupe;
create policy library_resource_groupe_lecture on public.library_resource_groupe
  for select to authenticated using (
    public.app_account_valid()
    and (
      public.app_role() = 'admin'
      or (
        public.app_role() = 'teacher'
        and exists (
          select 1 from public.mes_groupes_v mg
           where mg.groupe_id = library_resource_groupe.groupe_id
        )
      )
      or (
        public.app_role() in ('guardian', 'student')
        and exists (
          select 1 from public.mes_groupes_famille_v mg
           where mg.groupe_id = library_resource_groupe.groupe_id
        )
      )
    )
  );

do $$
declare
  v_resource_policy text;
  v_group_policy text;
begin
  select lower(qual) into v_resource_policy
    from pg_catalog.pg_policies
   where schemaname = 'public' and tablename = 'library_resource'
     and policyname = 'library_resource_lecture';
  select lower(qual) into v_group_policy
    from pg_catalog.pg_policies
   where schemaname = 'public' and tablename = 'library_resource_groupe'
     and policyname = 'library_resource_groupe_lecture';

  if v_resource_policy is null
     or position('app_account_valid' in v_resource_policy) = 0
     or position('mes_groupes_v' in v_resource_policy) = 0
     or position('mes_groupes_famille_v' in v_resource_policy) = 0
     or position('groupe_membres' in v_resource_policy) > 0
     or v_group_policy is null
     or position('app_account_valid' in v_group_policy) = 0
     or position('mes_groupes_v' in v_group_policy) = 0
     or position('mes_groupes_famille_v' in v_group_policy) = 0
     or position('groupe_membres' in v_group_policy) > 0 then
    raise exception 'CAP29: library group scopes must use existing scoped views';
  end if;
end;
$$;

commit;
