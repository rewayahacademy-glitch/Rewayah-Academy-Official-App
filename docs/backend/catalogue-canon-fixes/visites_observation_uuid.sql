CREATE OR REPLACE FUNCTION public.visites_observation(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', v.id,
    'role', v.role,
    'entered_at', v.entered_at,
    'left_at', v.left_at,
    'duration_seconds', v.duration_seconds,
    'visit_number', v.visit_number,
    'fin_de_visite', v.fin_de_visite
  ) order by v.entered_at), '[]'::jsonb)
  from public.guardian_session_visit v
  where v.session_id = p_session_id
    and (v.observateur_profile_id = auth.uid() or public.app_role() = 'admin');
$function$

