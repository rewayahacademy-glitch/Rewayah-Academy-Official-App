-- 0073 — casser la recursion des policies de groupes et membres.
begin;

-- Ce schema n'est pas expose par PostgREST (config.toml expose public et
-- graphql_public). Le predicat SECURITY DEFINER ne devient donc pas une RPC
-- appelable par un client, tout en restant utilisable depuis les policies.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, agent_ro;
grant usage on schema app_private to authenticated;

create or replace function app_private.peut_lire_groupe(
  p_groupe_id uuid,
  p_student_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_groupe_id is null or auth.uid() is null then
    return false;
  end if;

  if coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    return true;
  end if;

  if p_student_id is null then
    return exists (
      select 1
      from public.groupes g
      where g.id = p_groupe_id
        and g.teacher_id = auth.uid()
    ) or exists (
      select 1
      from public.groupe_membres gm
      join public.profiles p on p.id = gm.student_id
      where gm.groupe_id = p_groupe_id
        and gm.left_at is null
        and (
          p.id = auth.uid()
          or p.household_id = public.app_household_id()
        )
    );
  end if;

  -- Pour la ligne d'un membre, garder la projection historique : le membre
  -- lui-meme/son foyer, l'enseignant du groupe, ou l'administration.
  return exists (
    select 1
    from public.groupes g
    where g.id = p_groupe_id
      and g.teacher_id = auth.uid()
  ) or exists (
    select 1
    from public.profiles p
    where p.id = p_student_id
      and (
        p.id = auth.uid()
        or p.household_id = public.app_household_id()
      )
  );
end;
$function$;

revoke all on function app_private.peut_lire_groupe(uuid, uuid)
  from public, anon, agent_ro;
grant execute on function app_private.peut_lire_groupe(uuid, uuid)
  to authenticated;

drop policy if exists groupes_lecture on public.groupes;
create policy groupes_lecture
  on public.groupes
  for select to authenticated
  using (app_private.peut_lire_groupe(id, null));

drop policy if exists groupe_membres_lecture on public.groupe_membres;
create policy groupe_membres_lecture
  on public.groupe_membres
  for select to authenticated
  using (app_private.peut_lire_groupe(groupe_id, student_id));

commit;
