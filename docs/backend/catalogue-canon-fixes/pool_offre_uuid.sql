CREATE OR REPLACE FUNCTION public.pool_offre(p_offre_id uuid)
 RETURNS TABLE(eleve_id uuid, immutable_id text, prenom text, nom text, niveau_declare text, niveau_officiel text, diagnostic_statut text, intention_etat text, intention_depuis timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    i.eleve_id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    sp.niveau_declare,
    sp.level,
    sp.diagnostic_statut,
    i.etat,
    i.created_at
  from public.intentions_horaire i
  join public.profiles p on p.id = i.eleve_id
  join public.student_profiles sp on sp.profile_id = i.eleve_id
  where coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
    and i.offre_id = p_offre_id
    and i.etat in ('enregistree', 'diagnostic_planifie', 'en_formation')
  order by i.created_at asc;
$function$

