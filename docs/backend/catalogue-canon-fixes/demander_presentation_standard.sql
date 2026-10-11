CREATE OR REPLACE FUNCTION public.demander_presentation_standard()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_eleve uuid := auth.uid();
  v_foyer uuid;
  v_tuteur uuid;
  v_demande uuid;
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() = 'student',
    false
  ) THEN
    RAISE EXCEPTION 'demande reservee a un eleve mineur actif'
      USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(
    v_eleve IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      JOIN public.student_profiles sp ON sp.profile_id = p.id
      JOIN public.households h ON h.id = p.household_id
      WHERE p.id = v_eleve
        AND p.role = 'student'
        AND p.deleted_at IS NULL
        AND p.household_id IS NOT NULL
        AND h.status = 'active'
        AND h.deleted_at IS NULL
        AND sp.student_type = 'minor'
        AND sp.deleted_at IS NULL
        AND h.primary_guardian_id IS NOT NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'demande réservée à un élève mineur actif'
      USING ERRCODE = '42501';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('presentation:' || v_eleve::text, 0)
  );

  SELECT p.household_id, h.primary_guardian_id
    INTO v_foyer, v_tuteur
  FROM public.profiles p
  JOIN public.households h ON h.id = p.household_id
  JOIN public.profiles guardian
    ON guardian.id = h.primary_guardian_id
   AND guardian.role = 'guardian'
   AND guardian.household_id = h.id
   AND guardian.deleted_at IS NULL
   AND guardian.account_status IN ('active', 'provisional_active')
  WHERE p.id = v_eleve
    AND h.status = 'active'
    AND h.deleted_at IS NULL;

  IF NOT FOUND OR v_tuteur IS NULL THEN
    RAISE EXCEPTION 'tuteur du foyer indisponible';
  END IF;

  SELECT d.id INTO v_demande
  FROM public.demandes_presentation d
  WHERE d.eleve_id = v_eleve AND d.statut = 'en_attente';

  IF FOUND THEN
    RETURN;
  END IF;

  INSERT INTO public.demandes_presentation (eleve_id, foyer_id)
  VALUES (v_eleve, v_foyer)
  RETURNING id INTO v_demande;

  INSERT INTO public.notifications
    (destinataire, foyer_id, evenement, params, destination)
  VALUES (
    v_tuteur,
    v_foyer,
    'demande_presentation',
    pg_catalog.jsonb_build_object('demande_id', v_demande),
    '/tuteur/demandes'
  );

  PERFORM public.log_sensitive_access(
    'demande_presentation_creee',
    'demandes_presentation',
    v_demande::text,
    pg_catalog.jsonb_build_object('eleve_id', v_eleve, 'foyer_id', v_foyer)
  );

  RETURN;
END;
$function$

