-- X2-15: paginated incident list; caller's RLS remains in force.
create policy groupes_incidents_controller_read on public.groupes
  for select to authenticated using (
    public.app_account_valid()
    and public.app_role() = 'controller'
    and exists (
      select 1 from public.sessions s
      where s.groupe_id = groupes.id
        and s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'
    )
  );

create function public.lister_incidents_seances(
  p_maintenant timestamptz,
  p_limite integer default 100,
  p_offset integer default 0
)
returns table (
  id uuid,
  classe text,
  statut text,
  survenu_le timestamptz,
  enseignant text
)
language sql stable security invoker set search_path = ''
as $$
  select s.id, coalesce(g.libelle, ''), s.status::text, s.updated_at,
         case when public.app_role() = 'admin'
              then nullif(btrim(concat_ws(' ', p.first_name, p.last_name)), '')
              else null end
  from public.sessions s
  left join public.groupes g on g.id = s.groupe_id
  left join public.profiles p on p.id = s.teacher_id
  where public.app_account_valid()
    and public.app_role() in ('admin', 'controller')
    and s.deleted_at is null
    and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
    and s.updated_at > p_maintenant - interval '24 hours'
    and s.updated_at <= p_maintenant
  order by s.updated_at desc, s.id
  limit least(greatest(coalesce(p_limite, 100), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0)
$$;
revoke all on function public.lister_incidents_seances(timestamptz, integer, integer) from public, anon;
grant execute on function public.lister_incidents_seances(timestamptz, integer, integer) to authenticated;
revoke execute on function public.lister_incidents_seances(timestamptz, integer, integer) from service_role;
