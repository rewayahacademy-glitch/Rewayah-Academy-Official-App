CREATE OR REPLACE FUNCTION public.horloge_seance(p_session_id uuid)
 RETURNS TABLE(session_id uuid, debut_utc timestamp with time zone, fin_prevue_utc timestamp with time zone, join_opens_at_utc timestamp with time zone, fenetre_minutes integer, grace_minutes integer, maintenant_utc timestamp with time zone, tz_utilisateur text, heure_utilisateur text, jour_iso_utilisateur integer, date_utilisateur date, tz_groupe text, heure_groupe text, jour_iso_groupe integer, date_groupe date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    coalesce(s.join_opens_at,
             s.started_at - make_interval(mins => public.app_config_int('join_window_minutes', 20))),
    public.app_config_int('join_window_minutes', 20),
    public.app_config_int('grace_after_end_minutes', 15),
    now(),
    public.mon_fuseau(),
    to_char(s.started_at at time zone public.mon_fuseau(), 'HH24:MI'),
    extract(isodow from s.started_at at time zone public.mon_fuseau())::int,
    (s.started_at at time zone public.mon_fuseau())::date,
    coalesce(g.timezone_iana, public.mon_fuseau()),
    to_char(s.started_at at time zone coalesce(g.timezone_iana, public.mon_fuseau()), 'HH24:MI'),
    extract(isodow from s.started_at at time zone coalesce(g.timezone_iana, public.mon_fuseau()))::int,
    (s.started_at at time zone coalesce(g.timezone_iana, public.mon_fuseau()))::date
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
  where s.id = p_session_id
    and s.deleted_at is null
    and public.app_account_valid()
    and (
      public.app_role() = 'admin'
      or s.teacher_id = auth.uid()
      or exists (
        select 1 from public.session_participants sp
         where sp.session_id = s.id and sp.profile_id = auth.uid() and sp.deleted_at is null
      )
      or (g.id is not null and exists (
        select 1 from public.groupe_membres m
         where m.groupe_id = g.id and m.left_at is null
           and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
      ))
    );
$function$

