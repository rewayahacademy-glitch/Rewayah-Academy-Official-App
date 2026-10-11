CREATE OR REPLACE FUNCTION public.offres_admin()
 RETURNS TABLE(offre_id uuid, type_public text, langue_code text, langue_nom text, jours smallint[], heure_locale smallint, fuseau_iana text, duree_minutes smallint, etat text, capacite smallint, minimum_lancement smallint, vivier integer, non_affectes integer, groupes_publies integer, lancable boolean, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    o.id, o.type_public, o.langue_code, l.nom_humain, o.jours, o.heure_locale,
    o.fuseau_iana, o.duree_minutes, o.etat,
    case o.type_public
      when 'adulte' then public.app_config_int('groupe.capacite_adulte', 6)::smallint
      else public.app_config_int('groupe.capacite_enfant', 5)::smallint
    end,
    public.app_config_int('groupe.minimum_lancement', 3)::smallint,
    v.vivier,
    v.non_affectes,
    (select count(*)::int from public.groupes g
      where g.offre_id = o.id and g.ended_at is null),
    v.non_affectes >= public.app_config_int('groupe.minimum_lancement', 3),
    o.created_at
  from public.offres_horaires o
  join public.langues_cours l on l.code = o.langue_code
  cross join lateral (
    select
      count(*) filter (where i.etat <> 'retiree')::int as vivier,
      count(*) filter (where i.etat in ('enregistree', 'diagnostic_planifie', 'en_formation'))::int
        as non_affectes
    from public.intentions_horaire i where i.offre_id = o.id
  ) v
  where coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
  order by (o.etat <> 'publiee'), o.type_public, o.heure_locale;
$function$

