CREATE OR REPLACE FUNCTION public.evaluations_admin()
 RETURNS TABLE(evaluation_id uuid, student_id uuid, student_immutable_id text, student_prenom text, student_nom text, niveau_id uuid, niveau_nom_humain text, type text, statut text, date_prevue date, date_realisee date, resultat text, notes text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    e.id,
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    n.id,
    n.nom_humain,
    e.type,
    e.statut,
    e.date_prevue,
    e.date_realisee,
    e.resultat,
    e.notes
  from public.evaluations e
  join public.profiles p on p.id = e.student_id
  join public.programme_niveaux n on n.id = e.niveau_id
  where public.app_role() = 'admin' and public.app_account_valid()
  order by (e.statut = 'planifiee') desc, e.date_prevue desc;
$function$

