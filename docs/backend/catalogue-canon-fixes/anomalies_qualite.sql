CREATE OR REPLACE FUNCTION public.anomalies_qualite()
 RETURNS TABLE(type_anomalie text, ref_id uuid, student_id uuid, student_prenom text, student_nom text, teacher_id uuid, teacher_prenom text, teacher_nom text, depuis timestamp with time zone, controle_statut text, controle_note text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with brutes as (
    -- 1. Rapport manquant : seance tenue ('ended'), aucun lesson_report.
    select
      'rapport_manquant'::text as type_anomalie,
      s.id as ref_id,
      null::uuid as student_id,
      s.teacher_id as teacher_id,
      s.started_at as depuis
    from public.sessions s
    where s.status = 'ended'
      and s.deleted_at is null
      and not exists (
        select 1 from public.lesson_reports lr
        where lr.session_id = s.id and lr.deleted_at is null
      )

    union all

    -- 2. Blocage actif depuis plus de 7 jours sans cloture.
    select
      'blocage_sans_suivi'::text,
      e.id,
      e.student_id,
      null::uuid,
      e.created_at
    from public.progression_exceptions e
    where e.type = 'blocage'
      and e.closed_at is null
      and e.created_at < now() - interval '7 days'

    union all

    -- 3. Evaluation encore planifiee alors que sa date prevue est passee.
    select
      'evaluation_en_retard'::text,
      ev.id,
      ev.student_id,
      null::uuid,
      ev.date_prevue::timestamptz
    from public.evaluations ev
    where ev.statut = 'planifiee'
      and ev.date_prevue < current_date
  )
  select
    b.type_anomalie,
    b.ref_id,
    sp.id,
    case when public.agent_identite_masquee() then null else sp.first_name end,
    case when public.agent_identite_masquee() then null else sp.last_name end,
    tp.id,
    case when public.agent_identite_masquee() then null else tp.first_name end,
    case when public.agent_identite_masquee() then null else tp.last_name end,
    b.depuis,
    coalesce(c.statut, 'ouvert'),
    c.note
  from brutes b
  left join public.profiles sp on sp.id = b.student_id
  left join public.profiles tp on tp.id = b.teacher_id
  left join public.controles_qualite c on c.type_anomalie = b.type_anomalie and c.ref_id = b.ref_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by b.depuis asc;
$function$

