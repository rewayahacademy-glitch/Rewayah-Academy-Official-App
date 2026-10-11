CREATE OR REPLACE FUNCTION public.affecter_enseignant_classe(p_groupe_id uuid, p_teacher_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false)
     OR p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN
    RAISE EXCEPTION 'affectation reservee a l''administration';
  END IF;

  SELECT * INTO v_groupe FROM public.groupes
  WHERE id = p_groupe_id FOR UPDATE;
  IF NOT FOUND OR v_groupe.teacher_id IS NOT NULL
     OR v_groupe.etat <> 'en_attente_enseignant'
     OR v_groupe.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'deja_affecte ou classe indisponible';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    JOIN public.teacher_profiles tp ON tp.profile_id = p.id
    WHERE p.id = p_teacher_profile_id
      AND p.role = 'teacher' AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > now())
      AND tp.deleted_at IS NULL
      AND tp.kyc_status = 'approved'
      AND v_groupe.langue_code = ANY(tp.languages)
  ) THEN
    RAISE EXCEPTION 'enseignant indisponible';
  END IF;

  -- C-04/C-07: the same eligibility/collision check is enforced at the
  -- authorization boundary, not on arbitrary group creation or edits.
  PERFORM public.tc_verifier_affectation_enseignant(
    p_groupe_id, p_teacher_profile_id
  );

  UPDATE public.groupes
     SET teacher_id = p_teacher_profile_id, etat = 'active'
   WHERE id = p_groupe_id;

  PERFORM public.log_sensitive_access(
    'enseignant_affecte_classe', 'groupes', p_groupe_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id)
  );
  IF pg_catalog.to_regclass('public.notifications') IS NOT NULL THEN
    EXECUTE $sql$
      INSERT INTO public.notifications
        (destinataire, foyer_id, evenement, params, destination)
      SELECT DISTINCT h.primary_guardian_id, h.id, 'enseignant_affecte',
             jsonb_build_object(
               'groupe_id', $1,
               'debut_local', to_char(s.started_at AT TIME ZONE g.timezone_iana,
                                      'YYYY-MM-DD"T"HH24:MI:SS')
             ),
             '/tuteur/demandes'
      FROM public.groupe_membres gm
      JOIN public.profiles p ON p.id = gm.student_id
      JOIN public.households h ON h.id = p.household_id
      JOIN public.groupes g ON g.id = gm.groupe_id
      JOIN public.sessions s ON s.groupe_id = g.id AND s.deleted_at IS NULL
      WHERE gm.groupe_id = $1 AND gm.left_at IS NULL
        AND h.primary_guardian_id IS NOT NULL
        AND s.started_at = (
          SELECT min(s2.started_at) FROM public.sessions s2
          WHERE s2.groupe_id = g.id AND s2.deleted_at IS NULL
        )
    $sql$ USING p_groupe_id;
  END IF;
END;
$function$

