CREATE OR REPLACE FUNCTION public.mes_rapports_en_attente()
 RETURNS TABLE(session_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, groupe_id uuid, groupe_libelle text, nb_participants integer, heures_de_retard integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    s.groupe_id,
    g.libelle,
    count(distinct sp.profile_id) filter (
      where sp.role = 'student' and sp.deleted_at is null
    )::int,
    greatest(0, (extract(epoch from (now() - s.ended_at)) / 3600)::int)
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
    left join public.session_participants sp on sp.session_id = s.id
  where s.deleted_at is null
    and s.teacher_id = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid()
    -- Une seance annulee, ou l'enseignant ne s'est pas presente, ne doit aucun
    -- cahier : il n'y a rien a transmettre.
    and s.status in ('ended', 'student_absent', 'tech_failure')
    and s.ended_at < now()
    and not exists (
      select 1 from public.lesson_reports lr
       where lr.session_id = s.id and lr.deleted_at is null
    )
  group by s.id, s.started_at, s.ended_at, s.groupe_id, g.libelle
  order by s.ended_at asc;
$function$

