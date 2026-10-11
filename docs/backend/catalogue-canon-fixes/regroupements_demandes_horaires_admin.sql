CREATE OR REPLACE FUNCTION public.regroupements_demandes_horaires_admin()
 RETURNS TABLE(regroupement_id text, type_public text, langue_code text, fuseau_iana text, jours smallint[], heures_locales smallint[], nombre_eleves integer, quota integer, pret boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
      case when p.source = 'offre' then p.fuseau_offre else p.fuseau_iana end as fuseau_groupe,
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
      pg_catalog.mode() WITHIN GROUP (ORDER BY h.fuseau_groupe) as fuseau_groupe,
      h.jours_groupe,
      h.heures_groupe,
      count(*) filter (where h.eligible)::integer as nombre,
      case h.type_public
        when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)
        else public.app_config_int('groupe.capacite_enfant', 5)
      end as capacite
    from horaires h
    group by h.cle, h.type_public, h.langue_code,
             h.jours_groupe, h.heures_groupe
  )
  select
    q.cle, q.type_public, q.langue_code, q.fuseau_groupe,
    q.jours_groupe, q.heures_groupe, q.nombre, q.capacite,
    q.nombre >= q.capacite
  from quotas q
  order by q.type_public, q.langue_code, q.cle;
end;
$function$

