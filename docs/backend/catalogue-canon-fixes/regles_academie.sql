CREATE OR REPLACE FUNCTION public.regles_academie()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case
    when public.compte_en_parcours() then jsonb_build_object(
      'capacite_enfant',      public.app_config_int('groupe.capacite_enfant', 5),
      'capacite_adulte',      public.app_config_int('groupe.capacite_adulte', 6),
      'minimum_lancement',    public.app_config_int('groupe.minimum_lancement', 3),
      'seances_par_semaine',  public.app_config_int('groupe.seances_par_semaine', 3),
      'duree_minutes_enfant', public.app_config_int('seance.duree_minutes_enfant', 60),
      'duree_minutes_adulte', public.app_config_int('seance.duree_minutes_adulte', 90),
      'pause_minutes_enfant', public.app_config_int('seance.pause_minutes_enfant', 6),
      'pause_minutes_adulte', public.app_config_int('seance.pause_minutes_adulte', 0)
    )
    else null
  end;
$function$

