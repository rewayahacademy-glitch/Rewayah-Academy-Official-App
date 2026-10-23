-- 0064 — privilèges minimaux et RLS non récursive pour les outils pédagogiques.
-- Les policies bornent les lignes; les privilèges limitent aussi les opérations.
begin;

revoke all on public.learning_assignment from public, anon, authenticated, agent_ro;
grant select, insert on public.learning_assignment to authenticated;
grant update (status) on public.learning_assignment to authenticated;

-- L'adaptateur crée/relit les couches et ajoute/retire des traits.
revoke all on public.annotation_layer from public, anon, authenticated, agent_ro;
grant select, insert on public.annotation_layer to authenticated;

revoke all on public.annotation_trait from public, anon, authenticated, agent_ro;
grant select, insert, delete on public.annotation_trait to authenticated;

-- La pose d'un marqueur reste atomique via RPC; retrait explicite permis à son auteur.
revoke all on public.annotation_marqueur from public, anon, authenticated, agent_ro;
grant select, delete on public.annotation_marqueur to authenticated;

-- Evite de réentrer dans les policies de sessions/groupes depuis celle des couches.
create or replace function private.tc_annotation_teacher_owns_session(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    public.app_account_valid()
    and public.app_role() = 'teacher'
    and exists (
      select 1
        from public.sessions s
       where s.id = p_session_id
         and s.teacher_id = auth.uid()
         and s.deleted_at is null
    ),
    false
  );
$function$;

-- Ne permet de tester que la participation de l'appelant courant.
create or replace function private.tc_annotation_current_participant(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(
    public.app_account_valid()
    and exists (
      select 1
        from public.session_participants sp
       where sp.session_id = p_session_id
         and sp.profile_id = auth.uid()
         and sp.deleted_at is null
    ),
    false
  );
$function$;

revoke all on function private.tc_annotation_teacher_owns_session(uuid)
  from public, anon, agent_ro;
grant execute on function private.tc_annotation_teacher_owns_session(uuid)
  to authenticated;
revoke all on function private.tc_annotation_current_participant(uuid)
  from public, anon, agent_ro;
grant execute on function private.tc_annotation_current_participant(uuid)
  to authenticated;

drop policy if exists annotation_layer_auteur on public.annotation_layer;
create policy annotation_layer_auteur on public.annotation_layer
  for all to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and auteur_profile_id = auth.uid(),
      false
    )
  )
  with check (
    coalesce(
      public.app_account_valid()
      and auteur_profile_id = auth.uid()
      and portee <> 'temporaire'
      and (
        session_id is null
        or private.tc_annotation_teacher_owns_session(session_id)
      )
      and (
        resource_version_id is null
        or private.tc_assignment_resource_version_matches(
          annotation_layer.resource_version_id,
          annotation_layer.resource_id
        )
      ),
      false
    )
  );

drop policy if exists annotation_layer_participants_seance on public.annotation_layer;
create policy annotation_layer_participants_seance on public.annotation_layer
  for select to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and portee = 'seance'
      and session_id is not null
      and private.tc_annotation_current_participant(session_id),
      false
    )
  );

-- Les ancres incompatibles sont des violations de contrainte, avec SQLSTATE stable.
create or replace function public.tc_annotation_valider_trait()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_resource_id uuid;
begin
  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = new.layer_id
   for update;
  if v_resource_id is null
     or pg_catalog.jsonb_typeof(new.ancrage) <> 'object'
     or new.ancrage ->> 'resource_id' is distinct from v_resource_id::text
     or pg_catalog.jsonb_typeof(new.points) <> 'array' then
    raise exception 'trait incompatible avec la couche'
      using errcode = '23514';
  end if;
  return new;
end;
$function$;

create or replace function public.tc_annotation_valider_marqueur()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_resource_id uuid;
begin
  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = new.layer_id;
  if v_resource_id is null
     or pg_catalog.jsonb_typeof(new.plage) <> 'object'
     or new.plage ->> 'resource_id' is distinct from v_resource_id::text then
    raise exception 'marqueur incompatible avec la couche'
      using errcode = '23514';
  end if;
  return new;
end;
$function$;

revoke all on function public.tc_annotation_valider_trait()
  from public, anon, authenticated, agent_ro;
revoke all on function public.tc_annotation_valider_marqueur()
  from public, anon, authenticated, agent_ro;

commit;
