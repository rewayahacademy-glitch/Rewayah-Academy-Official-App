BEGIN;

CREATE OR REPLACE FUNCTION public.comptes_rendus_classe(
  p_classe_id uuid,
  p_page integer DEFAULT 1,
  p_filtre_etat text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  -- Keep page * 50 inside the positive int32 range used by row_number().
  v_page integer := least(greatest(coalesce(p_page, 1), 1), 42949672);
  v_etat text := nullif(p_filtre_etat, '');
  v_lignes jsonb;
  v_total integer;
BEGIN
  IF auth.uid() IS NULL OR p_classe_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture administrative refusee';
  END IF;
  IF v_etat IS NOT NULL AND v_etat NOT IN (
    'nonValide', 'confirmeNonPartage', 'partageAuto', 'partageManuel', 'revoque',
    'corrigeApresPartageManuel'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'filtre de diffusion invalide';
  END IF;

  WITH cahiers_bruts AS (
    SELECT DISTINCT ON (s.id, p.id)
      s.id AS session_id, p.id AS student_id, p.first_name, s.ended_at,
      CASE
        WHEN coalesce((e.value ->> 'confirme')::boolean, false) IS NOT TRUE THEN 'nonValide'
        WHEN r.revoque_le IS NOT NULL THEN 'revoque'
        WHEN r.publication_manuelle AND r.publie_le IS NOT NULL THEN 'partageManuel'
        WHEN r.publie_le IS NOT NULL THEN 'partageAuto'
        ELSE 'confirmeNonPartage'
      END AS etat,
      lr.updated_at
    FROM public.sessions s
    JOIN public.lesson_reports lr ON lr.session_id = s.id AND lr.deleted_at IS NULL
    CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(
      CASE WHEN jsonb_typeof(lr.content -> 'eleves') = 'array'
        THEN lr.content -> 'eleves' ELSE '[]'::jsonb END
    ) e(value)
    JOIN public.profiles p ON p.id = (e.value ->> 'student_id')::uuid
      AND p.deleted_at IS NULL
    JOIN public.groupe_membres m ON m.groupe_id = s.groupe_id AND m.student_id = p.id
      AND m.joined_at <= s.ended_at
      AND (m.left_at IS NULL OR m.left_at >= s.started_at)
    LEFT JOIN public.seance_resumes r ON r.session_id = s.id AND r.student_id = p.id
    WHERE s.groupe_id = p_classe_id AND s.deleted_at IS NULL
    ORDER BY s.id, p.id, lr.updated_at DESC, lr.id DESC
  ), filtres AS (
    SELECT * FROM cahiers_bruts WHERE v_etat IS NULL OR etat = v_etat
  )
  SELECT count(*)::integer,
    coalesce(jsonb_agg(jsonb_build_object(
      'seance_id', q.session_id, 'eleve_id', q.student_id,
      'eleve_prenom', q.first_name, 'seance_le', q.ended_at, 'etat', q.etat
    ) ORDER BY q.ended_at DESC, q.student_id)
    FILTER (WHERE q.rang BETWEEN ((v_page - 1) * 50 + 1) AND (v_page * 50)), '[]'::jsonb)
  INTO v_total, v_lignes
  FROM (
    SELECT f.*, row_number() OVER (ORDER BY f.ended_at DESC, f.student_id) AS rang
    FROM filtres f
  ) q;

  RETURN jsonb_build_object('lignes', v_lignes, 'total', v_total, 'page', v_page);
END;
$function$;

ALTER FUNCTION public.comptes_rendus_classe(uuid, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.comptes_rendus_classe(uuid, integer, text) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.comptes_rendus_classe(uuid, integer, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.lire_cahier_admin(
  p_seance_id uuid,
  p_eleve_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_cahier jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_seance_id IS NULL OR p_eleve_id IS NULL
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture administrative refusee';
  END IF;

  SELECT jsonb_build_object(
    'seance_id', s.id,
    'eleve_id', p.id,
    'eleve_prenom', p.first_name,
    'classe_libelle', g.libelle,
    'seance_le', s.ended_at,
    'confirme', coalesce((e.value ->> 'confirme')::boolean, false),
    'enseignant', tp.first_name,
    'evaluation', e.value - 'student_id' - 'confirme' - 'motif_exception',
    'details_internes', CASE
      WHEN nullif(btrim(e.value ->> 'motif_exception'), '') IS NULL THEN '[]'::jsonb
      ELSE jsonb_build_array(jsonb_build_object(
        'libelle', 'Motif d’exception', 'texte', e.value ->> 'motif_exception'
      )) END,
    'corrige_le', CASE WHEN lr.updated_at > lr.created_at THEN lr.updated_at ELSE NULL END
  ) INTO v_cahier
  FROM public.sessions s
  JOIN public.groupes g ON g.id = s.groupe_id
  JOIN public.lesson_reports lr ON lr.session_id = s.id AND lr.deleted_at IS NULL
  CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(
    CASE WHEN jsonb_typeof(lr.content -> 'eleves') = 'array'
      THEN lr.content -> 'eleves' ELSE '[]'::jsonb END
  ) e(value)
  JOIN public.profiles p ON p.id = p_eleve_id AND p.id = (e.value ->> 'student_id')::uuid
    AND p.deleted_at IS NULL
  JOIN public.profiles tp ON tp.id = s.teacher_id AND tp.deleted_at IS NULL
  WHERE s.id = p_seance_id AND s.deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.groupe_membres m
      WHERE m.groupe_id = s.groupe_id AND m.student_id = p_eleve_id
        AND m.joined_at <= s.ended_at
        AND (m.left_at IS NULL OR m.left_at >= s.started_at)
    );
  IF v_cahier IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'cahier introuvable';
  END IF;

  PERFORM public.log_sensitive_access(
    'cahier_admin_lu', 'lesson_reports', p_seance_id::text || ':' || p_eleve_id::text,
    jsonb_build_object('session_id', p_seance_id, 'student_id', p_eleve_id)
  );
  RETURN v_cahier;
END;
$function$;

ALTER FUNCTION public.lire_cahier_admin(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lire_cahier_admin(uuid, uuid) FROM PUBLIC, anon, agent_ro, service_role;
GRANT EXECUTE ON FUNCTION public.lire_cahier_admin(uuid, uuid) TO authenticated;

DO $acl$
BEGIN
  IF has_function_privilege('anon', 'public.comptes_rendus_classe(uuid,integer,text)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.comptes_rendus_classe(uuid,integer,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.lire_cahier_admin(uuid,uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.lire_cahier_admin(uuid,uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.comptes_rendus_classe(uuid,integer,text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.lire_cahier_admin(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ADM-CAHIER-LECTURE: ACL inattendue';
  END IF;
END;
$acl$;

COMMIT;
