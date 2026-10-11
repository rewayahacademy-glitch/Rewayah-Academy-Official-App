CREATE OR REPLACE FUNCTION public.tc_notification_etape_adulte_autonome()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_foyer uuid;
  v_tuteur uuid;
  v_autonome boolean;
  v_evenement text;
  v_params jsonb;
BEGIN
  IF TG_OP <> 'UPDATE'
     OR OLD.etat IS NOT DISTINCT FROM NEW.etat
     OR NEW.etat NOT IN ('classe_validee', 'enseignant_affecte')
     OR NEW.type_public <> 'adulte' THEN
    RETURN NEW;
  END IF;

  SELECT p.household_id, h.primary_guardian_id,
         coalesce(sp.student_type = 'autonomous', false)
    INTO v_foyer, v_tuteur, v_autonome
  FROM public.profiles p
  JOIN public.households h ON h.id = p.household_id
  JOIN public.student_profiles sp ON sp.profile_id = p.id
  WHERE p.id = NEW.eleve_id
    AND p.role = 'student'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND h.status = 'active'
    AND h.deleted_at IS NULL;

  IF NOT coalesce(v_autonome, false)
     OR v_foyer IS NULL
     OR v_tuteur = NEW.eleve_id THEN
    RETURN NEW;
  END IF;

  v_evenement := CASE NEW.etat
    WHEN 'classe_validee' THEN 'classe_validee'
    ELSE 'enseignant_affecte'
  END;
  v_params := jsonb_build_object('groupe_id', NEW.groupe_id);
  IF NEW.etat = 'enseignant_affecte' THEN
    v_params := v_params || jsonb_build_object(
      'debut_local',
      (
        SELECT pg_catalog.to_char(
          min(
            public.instant_creneau(
              gc.weekday, gc.hour_local, g.timezone_iana, 0
            ) AT TIME ZONE h.timezone
          ),
          'YYYY-MM-DD"T"HH24:MI:SS'
        )
        FROM public.groupes g
        JOIN public.groupe_creneaux gc ON gc.groupe_id = g.id
        JOIN public.households h ON h.id = v_foyer
        WHERE g.id = NEW.groupe_id
          AND g.teacher_id IS NOT NULL
          AND g.etat = 'active'
      )
    );
  END IF;

  INSERT INTO public.notifications
    (destinataire, foyer_id, evenement, params, destination)
  VALUES (
    NEW.eleve_id,
    v_foyer,
    v_evenement,
    v_params,
    '/tuteur/demandes'
  );
  RETURN NEW;
END;
$function$

