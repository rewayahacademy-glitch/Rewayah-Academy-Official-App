CREATE OR REPLACE FUNCTION public.tc_groupes_observation_bump_revision()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if (new.observation_source, new.observation_max_visites, new.observation_max_secondes,
      new.observation_max_secondes_par_visite)
     is distinct from
     (old.observation_source, old.observation_max_visites, old.observation_max_secondes,
      old.observation_max_secondes_par_visite)
  then
    new.observation_revision := old.observation_revision + 1;
  end if;
  return new;
end;
$function$

