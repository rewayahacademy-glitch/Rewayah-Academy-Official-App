CREATE OR REPLACE FUNCTION public.programme_versions_admin()
 RETURNS TABLE(version_id uuid, statut text, numero_version integer, cree_par_immutable_id text, cree_par_prenom text, cree_par_nom text, publiee_at timestamp with time zone, nombre_niveaux integer, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    v.id,
    v.statut,
    v.numero_version,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    v.publiee_at,
    (select count(*)::int from public.programme_niveaux n where n.version_id = v.id),
    v.created_at
  from public.programme_versions v
  join public.profiles p on p.id = v.cree_par
  where public.app_role() = 'admin' and public.app_account_valid()
  order by v.numero_version desc;
$function$

