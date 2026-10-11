CREATE OR REPLACE FUNCTION public.progression_famille(p_student_id uuid, p_limit integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_level text;
  v_niveau_humain text;
  v_jalon_humain text;
  v_jalons jsonb;
  v_seances jsonb;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
BEGIN
  IF v_user IS NULL
     OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'progression indisponible';
  END IF;

  SELECT sp.level INTO v_level
  FROM public.profiles p
  JOIN public.student_profiles sp ON sp.profile_id = p.id
  WHERE p.id = p_student_id
    AND p.deleted_at IS NULL
    AND sp.deleted_at IS NULL
    AND (
      (
        p.role = 'student'
        AND p.household_id IS NOT NULL
        AND p.household_id = public.app_household_id()
      )
      OR (
        p.id = v_user
        AND sp.titulaire_profile_id = v_user
      )
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'progression indisponible';
  END IF;

  SELECT CASE
           WHEN count(DISTINCT n.nom_humain) = 1 THEN min(n.nom_humain)
           ELSE NULL
         END
  INTO v_niveau_humain
  FROM public.programme_niveaux n
  WHERE n.code_technique = v_level;

  SELECT n.nom_humain INTO v_jalon_humain
  FROM public.seance_resumes r
  JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
  WHERE r.student_id = p_student_id
    AND r.publie_le IS NOT NULL
    AND r.jalon_atteint IS NOT NULL
  ORDER BY r.publie_le DESC
  LIMIT 1;

  SELECT coalesce(
    jsonb_agg(q.nom_humain ORDER BY q.derniere_publication DESC),
    '[]'::jsonb
  )
  INTO v_jalons
  FROM (
    SELECT n.nom_humain, max(r.publie_le) AS derniere_publication
    FROM public.seance_resumes r
    JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
    WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
    GROUP BY n.nom_humain
  ) q;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'session_id', q.session_id,
        'texte_famille', q.texte_famille,
        'publie_le', q.publie_le,
        'jalon_humain', q.jalon_humain
      ) ORDER BY q.publie_le DESC
    ),
    '[]'::jsonb
  )
  INTO v_seances
  FROM (
    SELECT r.session_id, r.texte_famille, r.publie_le, n.nom_humain AS jalon_humain
    FROM public.seance_resumes r
    LEFT JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
    WHERE r.student_id = p_student_id
      AND r.publie_le IS NOT NULL
    ORDER BY r.publie_le DESC
    LIMIT v_limit
  ) q;

  RETURN jsonb_build_object(
    'niveau_humain', v_niveau_humain,
    'jalon_humain', v_jalon_humain,
    'jalons', v_jalons,
    'seances', v_seances
  );
END;
$function$

