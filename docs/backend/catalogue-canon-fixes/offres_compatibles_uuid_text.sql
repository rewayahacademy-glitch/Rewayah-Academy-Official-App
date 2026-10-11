CREATE OR REPLACE FUNCTION public.offres_compatibles(p_membre_id uuid, p_fuseau_vue text)
 RETURNS TABLE(offre_id uuid, type_public text, langue_code text, langue_nom text, jours_locaux smallint[], heures_locales smallint[], heure_source smallint, fuseau_source text, duree_minutes smallint, rythme text, pause_minutes smallint, capacite smallint, deja_choisie boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with fiche as (
    select sp.langue_cours, sp.level, c.type_public
    from public.student_profiles sp
    join public.cohortes_age c on c.code = sp.cohorte
    where sp.profile_id = p_membre_id
      and sp.deleted_at is null
      and public.peut_decrire_apprenant(p_membre_id)
      and exists (select 1 from pg_catalog.pg_timezone_names where name = p_fuseau_vue)
  )
  select
    o.id,
    o.type_public,
    o.langue_code,
    l.nom_humain,
    v.jours_locaux,
    v.heures_locales,
    o.heure_locale,
    o.fuseau_iana,
    o.duree_minutes,
    o.rythme::text,
    case o.type_public
      when 'adulte' then public.app_config_int('seance.pause_minutes_adulte', 0)::smallint
      else public.app_config_int('seance.pause_minutes_enfant', 6)::smallint
    end,
    case o.type_public
      when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
      else public.app_config_int('groupe.capacite_enfant', 5)::smallint
    end,
    exists (
      select 1 from public.intentions_horaire i
      where i.eleve_id = p_membre_id and i.offre_id = o.id and i.etat <> 'retiree'
    )
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  cross join fiche f
  cross join lateral (
    select
      array_agg(x.jour order by x.rang)::smallint[]  as jours_locaux,
      array_agg(x.heure order by x.rang)::smallint[] as heures_locales
    from (
      select
        j.rang,
        extract(isodow from j.local)::smallint as jour,
        extract(hour   from j.local)::smallint as heure
      from (
        select
          u.rang,
          public.instant_creneau(u.j::int, o.heure_locale::int, o.fuseau_iana)
            at time zone p_fuseau_vue as local
        from unnest(o.jours) with ordinality as u(j, rang)
      ) j
    ) x
  ) v
  where o.etat = 'publiee'
    and o.type_public = f.type_public
    and o.langue_code = f.langue_cours
    and (o.programme_niveau_id is null or o.programme_niveau_id::text = f.level)
  order by 2, 7, 4;
$function$

