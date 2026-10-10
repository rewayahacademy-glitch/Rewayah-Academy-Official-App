-- 0070 — regrouper les offres par offre et les demandes libres par horaire UTC.
begin;

create or replace function public.creneaux_normalises_utc(
  p_jours smallint[],
  p_heures smallint[],
  p_fuseau text
) returns table (jour_iso smallint, heure_locale smallint)
language plpgsql
stable
set search_path = ''
as $function$
declare
  v_ancre date;
  v_local timestamp without time zone;
  v_utc timestamp without time zone;
  v_i integer;
begin
  if p_jours is null or p_heures is null
     or cardinality(p_jours) = 0
     or cardinality(p_jours) <> cardinality(p_heures)
     or p_fuseau is null
     or not exists (
       select 1 from pg_catalog.pg_timezone_names where name = p_fuseau
     ) then
    raise exception 'créneaux ou fuseau invalides';
  end if;

  v_ancre := pg_catalog.date_trunc(
    'week', pg_catalog.now() at time zone 'UTC'
  )::date;
  for v_i in 1..cardinality(p_jours) loop
    if p_jours[v_i] not between 1 and 7
       or p_heures[v_i] not between 0 and 23 then
      raise exception 'jour ou heure locale invalide';
    end if;
    v_local := v_ancre + (p_jours[v_i] - 1)
      + pg_catalog.make_interval(hours => p_heures[v_i]);
    v_utc := (v_local at time zone p_fuseau) at time zone 'UTC';
    jour_iso := extract(isodow from v_utc)::smallint;
    heure_locale := extract(hour from v_utc)::smallint;
    return next;
  end loop;
end;
$function$;

create or replace function public.cle_horaire_utc(
  p_jours smallint[],
  p_heures smallint[],
  p_fuseau text
) returns text
language sql
stable
set search_path = ''
as $function$
  select pg_catalog.string_agg(
    pg_catalog.lpad(n.jour_iso::text, 2, '0') || ':' ||
      pg_catalog.lpad(n.heure_locale::text, 2, '0'),
    ',' order by n.jour_iso, n.heure_locale
  )
  from public.creneaux_normalises_utc(p_jours, p_heures, p_fuseau) n;
$function$;

revoke all on function public.creneaux_normalises_utc(smallint[], smallint[], text)
  from public, anon, agent_ro;
grant execute on function public.creneaux_normalises_utc(smallint[], smallint[], text)
  to authenticated, service_role;
revoke all on function public.cle_horaire_utc(smallint[], smallint[], text)
  from public, anon, agent_ro;
grant execute on function public.cle_horaire_utc(smallint[], smallint[], text)
  to authenticated, service_role;

create or replace function public.regroupements_demandes_horaires_admin()
returns table (
  regroupement_id text,
  type_public text,
  langue_code text,
  fuseau_iana text,
  jours smallint[],
  heures_locales smallint[],
  nombre_eleves integer,
  quota integer,
  pret boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'acces reserve a l''administration';
  end if;

  return query
  with preparation as (
    select
      d.*,
      o.fuseau_iana as fuseau_offre,
      o.jours as jours_offre,
      o.heure_locale as heure_offre,
      u.jours_utc,
      u.heures_utc,
      p.deleted_at as profil_supprime,
      p.account_status,
      p.access_until,
      h.status as foyer_status,
      h.deleted_at as foyer_supprime,
      sp.deleted_at as apprentissage_supprime,
      c.actif as cohorte_active,
      l.actif as langue_active,
      not exists (
        select 1 from public.groupe_membres gm
        where gm.student_id = d.eleve_id and gm.left_at is null
      ) as sans_classe_active
    from public.demandes_horaires_famille d
    join public.profiles p on p.id = d.eleve_id
    left join public.households h on h.id = p.household_id
    left join public.student_profiles sp on sp.profile_id = d.eleve_id
    left join public.cohortes_age c on c.code = sp.cohorte
      and c.type_public = d.type_public
    left join public.langues_cours l on l.code = sp.langue_cours
      and l.code = d.langue_code
    left join public.offres_horaires o on o.id = d.offre_id
    left join lateral (
      select
        pg_catalog.array_agg(n.jour_iso order by n.jour_iso, n.heure_locale) as jours_utc,
        pg_catalog.array_agg(n.heure_locale order by n.jour_iso, n.heure_locale) as heures_utc
      from public.creneaux_normalises_utc(d.jours, d.heures_locales, d.fuseau_iana) n
    ) u on d.source = 'personnalisee'
    where d.etat = 'envoyee'
  ),
  horaires as (
    select
      p.*,
      case when p.source = 'offre' then 'o:' || p.offre_id::text
           else 'p:' || pg_catalog.md5(
             p.type_public || '|' || p.langue_code || '|' ||
             public.cle_horaire_utc(p.jours, p.heures_locales, p.fuseau_iana)
           )
      end as cle,
      case when p.source = 'offre' then p.fuseau_offre else 'UTC' end as fuseau_groupe,
      case when p.source = 'offre' then p.jours_offre else p.jours_utc end as jours_groupe,
      case when p.source = 'offre'
           then pg_catalog.array_fill(p.heure_offre, array[cardinality(p.jours_offre)])
           else p.heures_utc
      end as heures_groupe,
      (p.profil_supprime is null
       and p.account_status in ('active', 'provisional_active')
       and (p.access_until is null or p.access_until > pg_catalog.now())
       and p.foyer_status = 'active' and p.foyer_supprime is null
       and p.apprentissage_supprime is null
       and p.cohorte_active and p.langue_active
       and p.sans_classe_active) as eligible
    from preparation p
  ),
  quotas as (
    select
      h.cle,
      h.type_public,
      h.langue_code,
      h.fuseau_groupe,
      h.jours_groupe,
      h.heures_groupe,
      count(*) filter (where h.eligible)::integer as nombre,
      case h.type_public
        when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)
        else public.app_config_int('groupe.capacite_enfant', 5)
      end as capacite
    from horaires h
    group by h.cle, h.type_public, h.langue_code,
             h.fuseau_groupe, h.jours_groupe, h.heures_groupe
  )
  select
    q.cle, q.type_public, q.langue_code, q.fuseau_groupe,
    q.jours_groupe, q.heures_groupe, q.nombre, q.capacite,
    q.nombre >= q.capacite
  from quotas q
  order by q.type_public, q.langue_code, q.cle;
end;
$function$;
revoke all on function public.regroupements_demandes_horaires_admin()
  from public, anon, agent_ro;
grant execute on function public.regroupements_demandes_horaires_admin()
  to authenticated, service_role;

do $migration$
declare
  v_oid oid := 'public.creer_classe_depuis_regroupement(text, uuid, text)'::regprocedure;
  v_definition text;
  v_cleanup text;
  v_filtered text;
  v_old text;
  v_new text;
begin
  v_definition := pg_catalog.pg_get_functiondef(v_oid);

  v_old := $pattern$AND d.type_public = v_type AND d.langue_code = v_langue
     AND d.fuseau_iana = v_fuseau AND d.jours = v_jours
     AND d.heures_locales = v_heures$pattern$;
  v_new := $replacement$AND d.type_public = v_type AND d.langue_code = v_langue
     AND (
       (d.source = 'offre' AND 'o:' || d.offre_id::text = p_regroupement_id)
       OR (d.source = 'personnalisee'
         AND 'p:' || pg_catalog.md5(
           d.type_public || '|' || d.langue_code || '|' ||
           public.cle_horaire_utc(d.jours, d.heures_locales, d.fuseau_iana)
         ) = p_regroupement_id)
     )$replacement$;

  v_cleanup := pg_catalog.replace(v_definition, v_old, v_new);
  if v_cleanup = v_definition then
    raise exception 'M3 : filtre UTC du nettoyage M2 absent';
  end if;

  v_old := $pattern$AND d.type_public = v_type AND d.langue_code = v_langue
      AND d.fuseau_iana = v_fuseau AND d.jours = v_jours
      AND d.heures_locales = v_heures$pattern$;
  v_new := $replacement$AND d.type_public = v_type AND d.langue_code = v_langue
      AND (
        (d.source = 'offre' AND 'o:' || d.offre_id::text = p_regroupement_id)
        OR (d.source = 'personnalisee'
          AND 'p:' || pg_catalog.md5(
            d.type_public || '|' || d.langue_code || '|' ||
            public.cle_horaire_utc(d.jours, d.heures_locales, d.fuseau_iana)
          ) = p_regroupement_id)
      )$replacement$;
  v_filtered := pg_catalog.replace(v_cleanup, v_old, v_new);
  if v_filtered = v_cleanup then
    raise exception 'M3 : filtre UTC des membres absents';
  end if;

  execute v_filtered;
end
$migration$;

commit;
