CREATE OR REPLACE FUNCTION public.politique_observation_effective(p_groupe_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_g public.groupes;
  v_source text;
  v_activee boolean;
  v_max_visites int;
  v_max_secondes int;
  v_max_secondes_visite int;
  v_policy_version text;
begin
  select * into v_g from public.groupes where id = p_groupe_id;
  if not found then
    raise exception 'groupe introuvable' using errcode = 'no_data_found';
  end if;

  v_source := v_g.observation_source;

  -- L'interrupteur academie (app_config.observation.activee) prime sur tout :
  -- une desactivation globale n'est pas contournable groupe par groupe.
  if not coalesce((public.get_config('observation.activee', 'true'::jsonb))::boolean, true)
     or v_source = 'desactivee' then
    v_activee := false;
    v_max_visites := 0;
    v_max_secondes := 0;
    v_max_secondes_visite := null;
    v_policy_version := 'desactivee';
  elsif v_source = 'groupe' then
    v_activee := true;
    v_max_visites := v_g.observation_max_visites;
    v_max_secondes := v_g.observation_max_secondes;
    v_max_secondes_visite := v_g.observation_max_secondes_par_visite;
    v_policy_version := 'groupe:' || v_g.observation_revision::text;
  else
    v_activee := true;
    v_max_visites := public.app_config_int('observation.max_visits_per_session', 1);
    v_max_secondes := public.app_config_int('observation.max_total_seconds', 120);
    v_max_secondes_visite := nullif(public.get_config('observation.max_seconds_per_visit', 'null'::jsonb)::text, 'null')::int;
    v_policy_version := coalesce(public.get_config('observation.policy_version', '"a1"'::jsonb) #>> '{}', 'a1');
  end if;

  return jsonb_build_object(
    'policy_version', v_policy_version,
    'source', v_source,
    'observation_activee', v_activee,
    'max_visits_per_session', v_max_visites,
    'max_total_observation_seconds', v_max_secondes,
    'max_seconds_per_visit', v_max_secondes_visite
  );
end;
$function$

