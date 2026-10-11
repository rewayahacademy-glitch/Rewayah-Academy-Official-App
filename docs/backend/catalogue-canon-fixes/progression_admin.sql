CREATE OR REPLACE FUNCTION public.progression_admin()
 RETURNS TABLE(student_id uuid, student_immutable_id text, student_prenom text, student_nom text, groupe_id uuid, groupe_libelle text, niveau_id uuid, niveau_nom_humain text, niveau_cycle text, niveau_depuis timestamp with time zone, exception_active_id uuid, exception_active_type text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with dernier_mouvement as (
    select distinct on (h.student_id)
      h.student_id, h.niveau_id, h.created_at
    from public.progression_historique h
    order by h.student_id, h.created_at desc
  ),
  exception_active as (
    select distinct on (e.student_id)
      e.student_id, e.id, e.type
    from public.progression_exceptions e
    where e.closed_at is null
    order by e.student_id, e.created_at desc
  )
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    g.id,
    g.libelle,
    n.id,
    n.nom_humain,
    n.cycle,
    dm.created_at,
    xa.id,
    xa.type
  from public.profiles p
  left join dernier_mouvement dm on dm.student_id = p.id
  left join public.programme_niveaux n on n.id = dm.niveau_id
  left join public.groupe_membres m on m.student_id = p.id and m.left_at is null
  left join public.groupes g on g.id = m.groupe_id
  left join exception_active xa on xa.student_id = p.id
  where public.app_role() = 'admin' and public.app_account_valid()
    and p.role = 'student'
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
  order by g.libelle nulls last, p.created_at asc;
$function$

