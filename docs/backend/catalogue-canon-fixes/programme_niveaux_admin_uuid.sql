CREATE OR REPLACE FUNCTION public.programme_niveaux_admin(p_version_id uuid)
 RETURNS TABLE(niveau_id uuid, code_technique text, nom_humain text, cycle text, ordre integer, description text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select n.id, n.code_technique, n.nom_humain, n.cycle, n.ordre, n.description
  from public.programme_niveaux n
  where public.app_role() = 'admin' and public.app_account_valid()
    and n.version_id = p_version_id
  order by n.ordre asc;
$function$

