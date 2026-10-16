BEGIN;

-- F86: these two read RPCs expose the manual-assignment queue and remain
-- limited to an authenticated, valid admin account.
CREATE OR REPLACE FUNCTION public.eleves_sans_enseignant()
RETURNS TABLE (
  student_id uuid,
  first_name text,
  immutable_id text,
  household_id uuid,
  level text,
  interface_mode public.interface_mode,
  depuis timestamptz,
  creneaux jsonb
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'attribution manuelle reservee a l''administration';
  END IF;

  RETURN QUERY
  SELECT e.id, e.first_name, e.immutable_id, e.household_id,
         sp.level, sp.interface_mode, creneau.depuis,
         coalesce(creneau.cases, '[]'::jsonb)
  FROM public.profiles e
  JOIN public.student_profiles sp
    ON sp.profile_id = e.id AND sp.deleted_at IS NULL
  LEFT JOIN LATERAL (
    SELECT min(w.created_at) AS depuis,
           jsonb_agg(jsonb_build_object(
             'weekday', w.weekday,
             'hour_local', w.hour_local,
             'timezone_iana', w.timezone_iana,
             'created_at', w.created_at
           ) ORDER BY w.weekday, w.hour_local) AS cases
    FROM public.weekly_availability w
    WHERE w.profile_id = e.id
  ) creneau ON true
  WHERE e.role = 'student'
    AND e.deleted_at IS NULL
    AND e.account_status IN ('active', 'provisional_active')
    AND NOT EXISTS (
      SELECT 1 FROM public.teacher_student_assignments a
      WHERE a.student_id = e.id AND a.ended_at IS NULL
    )
  ORDER BY creneau.depuis ASC NULLS LAST, e.first_name ASC;
END;
$function$;
ALTER FUNCTION public.eleves_sans_enseignant() OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.eleves_sans_enseignant() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.eleves_sans_enseignant() TO authenticated;
COMMENT ON FUNCTION public.eleves_sans_enseignant() IS
  'F86 candidate allowlist: signature=public.eleves_sans_enseignant(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.enseignants_pour(p_student_profile_id uuid)
RETURNS TABLE (
  teacher_id uuid,
  first_name text,
  last_name text,
  immutable_id text,
  country text,
  eleves_actifs int,
  plafond int,
  creneaux_communs jsonb
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'attribution manuelle reservee a l''administration';
  END IF;

  RETURN QUERY
  SELECT ens.id, ens.first_name, ens.last_name, ens.immutable_id,
         tp.country, charge.actifs::int,
         public.regle_brute(ens.id, 'max_students_per_teacher'),
         coalesce(communs.cases, '[]'::jsonb)
  FROM public.profiles ens
  JOIN public.teacher_profiles tp
    ON tp.profile_id = ens.id AND tp.deleted_at IS NULL
  JOIN LATERAL (
    SELECT count(*) AS actifs
    FROM public.teacher_student_assignments a
    WHERE a.teacher_id = ens.id AND a.ended_at IS NULL
  ) charge ON true
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(jsonb_build_object(
      'weekday', we.weekday,
      'hour_local', we.hour_local,
      'timezone_iana', we.timezone_iana
    ) ORDER BY we.weekday, we.hour_local) AS cases
    FROM public.weekly_availability we
    JOIN public.weekly_availability wt ON wt.profile_id = ens.id
      AND public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana)
        = public.instant_creneau(we.weekday, we.hour_local, we.timezone_iana)
    WHERE we.profile_id = p_student_profile_id
  ) communs ON true
  WHERE ens.role = 'teacher'
    AND ens.deleted_at IS NULL
    AND ens.account_status IN ('active', 'provisional_active')
  ORDER BY (coalesce(jsonb_array_length(communs.cases), 0) > 0) DESC,
           charge.actifs ASC, ens.first_name ASC;
END;
$function$;
ALTER FUNCTION public.enseignants_pour(uuid) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.enseignants_pour(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.enseignants_pour(uuid) TO authenticated;
COMMENT ON FUNCTION public.enseignants_pour(uuid) IS
  'F86 candidate allowlist: signature=public.enseignants_pour(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE
  v_signature text;
  v_oid oid;
  v_definition text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.eleves_sans_enseignant()',
    'public.enseignants_pour(uuid)'
  ] LOOP
    v_oid := pg_catalog.to_regprocedure(v_signature);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'F86: fonction absente: %', v_signature;
    END IF;
    SELECT pg_catalog.pg_get_functiondef(v_oid) INTO v_definition;
    IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
            FROM pg_catalog.pg_proc p WHERE p.oid = v_oid)
       OR pg_catalog.strpos(
            pg_catalog.lower(v_definition),
            'if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'
          ) = 0
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR coalesce(pg_catalog.obj_description(v_oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=A_CALCULER%' THEN
      RAISE EXCEPTION 'F86: postflight de garde, search_path, ACL ou métadonnée échoué: %', v_signature;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
