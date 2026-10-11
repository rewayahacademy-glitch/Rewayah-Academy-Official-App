CREATE OR REPLACE FUNCTION public.annonces_observation(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance public.sessions%rowtype;
  v_pol    jsonb;
begin
  select * into v_seance from public.sessions s where s.id = p_session_id and s.deleted_at is null;
  if not found or v_seance.teacher_id <> auth.uid() then
    raise exception 'reserve a l''enseignant de la seance' using errcode = 'insufficient_privilege';
  end if;

  v_pol := public.politique_observation_effective(v_seance.groupe_id);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'enfant_prenom', case when public.agent_identite_masquee() then p.immutable_id else p.first_name end,
      'enfant_profile_id', v.enfant_profile_id,
      'restant_secondes', greatest(0, (
        case when v_pol->>'max_seconds_per_visit' is not null
             then (v_pol->>'max_seconds_per_visit')::int
             else (v_pol->>'max_total_observation_seconds')::int
        end
      ) - extract(epoch from (now() - v.entered_at))::int)
    ))
    from public.guardian_session_visit v
      left join public.profiles p on p.id = v.enfant_profile_id
    where v.session_id = p_session_id
      and v.role = 'guardian_observer'
      and v.left_at is null
  ), '[]'::jsonb);
end;
$function$

