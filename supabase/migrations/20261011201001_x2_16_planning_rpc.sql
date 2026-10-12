-- X2-16: the RPC checks account and role itself; bypasses recursive groupes
-- policies while projecting only authorized planning data.
create function public.lister_planning_direction(
  p_lundi timestamptz,
  p_limite integer default 100,
  p_offset integer default 0
)
returns table (id uuid, classe text, debut timestamptz, duree_minutes integer, statut text, enseignant text)
language sql stable security definer set search_path = ''
as $$
  select s.id, coalesce(g.libelle, ''), s.started_at,
         greatest(1, floor(extract(epoch from (s.ended_at - s.started_at)) / 60)::integer),
         s.status::text,
         case when public.app_role() = 'admin'
              then nullif(btrim(concat_ws(' ', p.first_name, p.last_name)), '') else null end
  from public.sessions s
  left join public.groupes g on g.id = s.groupe_id
  left join public.profiles p on p.id = s.teacher_id
  where public.app_account_valid()
    and public.app_role() in ('admin', 'controller')
    and s.deleted_at is null
    and s.started_at >= p_lundi
    and s.started_at < p_lundi + interval '7 days'
  order by s.started_at, s.id
  limit least(greatest(coalesce(p_limite, 100), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0)
$$;
revoke all on function public.lister_planning_direction(timestamptz, integer, integer) from public, anon;
grant execute on function public.lister_planning_direction(timestamptz, integer, integer) to authenticated;
revoke execute on function public.lister_planning_direction(timestamptz, integer, integer) from service_role;
