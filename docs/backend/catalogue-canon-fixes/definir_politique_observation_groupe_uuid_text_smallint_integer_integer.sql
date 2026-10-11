CREATE OR REPLACE FUNCTION public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_par_visite integer;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  if p_source not in ('academie', 'groupe', 'desactivee') then
    raise exception 'source de politique inconnue : %', p_source using errcode = 'invalid_parameter_value';
  end if;

  -- La revision est bumpee par le declencheur existant
  -- (tc_groupes_observation_bump_revision, 0030) : rien a faire ici. Ce
  -- declencheur surveille deja observation_max_secondes_par_visite, donc un
  -- changement du seul plafond de visite fait bouger policy_version.
  update public.groupes
     set observation_source = p_source,
         observation_max_visites = p_max_visites,
         observation_max_secondes = p_max_secondes,
         -- Nul en entree = retomber sur ce que le groupe porte deja, puis sur
         -- le defaut d'Academie. Jamais nul en sortie : « illimite par visite »
         -- n'est pas un reglage. Le `least` rejoue l'invariant de
         -- plafondDeVisite et satisfait groupes_observation_plafond_visite.
         observation_max_secondes_par_visite = least(
           coalesce(
             p_max_secondes_par_visite,
             groupes.observation_max_secondes_par_visite,
             public.app_config_int('observation.max_seconds_per_visit', 120)
           ),
           p_max_secondes
         )
   where id = p_groupe_id and ended_at is null
   returning observation_max_secondes_par_visite into v_par_visite;

  if not found then
    raise exception 'groupe introuvable ou deja cloture' using errcode = 'no_data_found';
  end if;

  -- La valeur journalisee est celle REELLEMENT ecrite, pas celle demandee :
  -- avec un parametre nul, les deux different.
  perform public.log_sensitive_access(
    'observation_politique_groupe_modifiee', 'groupes', p_groupe_id::text,
    jsonb_build_object('source', p_source, 'max_visites', p_max_visites,
                       'max_secondes', p_max_secondes,
                       'max_secondes_par_visite', v_par_visite)
  );

  return public.politique_observation_effective(p_groupe_id);
end;
$function$

