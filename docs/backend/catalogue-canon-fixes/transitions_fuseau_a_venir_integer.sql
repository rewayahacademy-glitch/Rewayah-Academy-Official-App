CREATE OR REPLACE FUNCTION public.transitions_fuseau_a_venir(p_jours integer DEFAULT 30)
 RETURNS TABLE(groupe_id uuid, fuseau text, transition_utc timestamp with time zone, heure_avant text, heure_apres text, jours_restants integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  return query
    with occurrences as (
      select
        g.id as gid,
        g.timezone_iana as tz,
        i,
        public.instant_creneau(g.weekday, g.hour_local, g.timezone_iana, i) as debut
      from public.groupes g
      cross join generate_series(0, 4) as i
      where g.ended_at is null
    ),
    paires as (
      -- Le decalage UTC d'un instant dans un fuseau : la difference entre son
      -- heure murale dans ce fuseau et son heure murale en UTC. `extract
      -- (timezone from ...)` ne s'applique qu'a un `timestamptz`, jamais au
      -- `timestamp` nu que rend `AT TIME ZONE` -- cette soustraction est la
      -- forme correcte.
      select
        o1.gid, o1.tz, o1.debut as debut_semaine, o2.debut as debut_semaine_suivante,
        (o1.debut at time zone o1.tz) - (o1.debut at time zone 'UTC') as decalage_avant,
        (o2.debut at time zone o1.tz) - (o2.debut at time zone 'UTC') as decalage_apres
      from occurrences o1
      join occurrences o2 on o2.gid = o1.gid and o2.i = o1.i + 1
    )
    select
      p.gid,
      p.tz,
      p.debut_semaine_suivante,
      to_char(p.debut_semaine at time zone p.tz, 'HH24:MI'),
      to_char(p.debut_semaine_suivante at time zone p.tz, 'HH24:MI'),
      extract(day from p.debut_semaine_suivante - now())::int
    from paires p
    where p.decalage_avant is distinct from p.decalage_apres
      and p.debut_semaine_suivante <= now() + make_interval(days => p_jours)
      and p.debut_semaine_suivante >= now();
end;
$function$

