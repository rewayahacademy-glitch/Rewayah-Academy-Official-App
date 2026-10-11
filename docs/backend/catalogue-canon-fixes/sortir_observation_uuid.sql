CREATE OR REPLACE FUNCTION public.sortir_observation(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_visite public.guardian_session_visit;
begin
  -- `duration_seconds` n'est PAS ecrite : elle est generee a partir de
  -- `left_at` et `entered_at` (0032), et `returning *` la rend donc deja
  -- calculee pour la journalisation ci-dessous.
  update public.guardian_session_visit v
     set left_at = now(),
         fin_de_visite = 'sortie_volontaire'
   where v.id = (
     select id from public.guardian_session_visit
      where session_id = p_session_id and observateur_profile_id = auth.uid() and left_at is null
      order by entered_at desc limit 1
   )
  returning * into v_visite;

  if not found then
    return jsonb_build_object('ferme', false);
  end if;

  perform public.log_sensitive_access(
    'observation_sortie', 'guardian_session_visit', v_visite.id::text,
    jsonb_build_object('session_id', p_session_id, 'duration_seconds', v_visite.duration_seconds)
  );

  return jsonb_build_object('ferme', true, 'duration_seconds', v_visite.duration_seconds);
end;
$function$

