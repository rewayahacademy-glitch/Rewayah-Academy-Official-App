BEGIN;
SET LOCAL search_path = '';

DO $f86_patch$
DECLARE
  v_definition text;
  v_before text;
  v_after text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(
    'public.affecter_enseignant_classe(uuid,uuid)'::pg_catalog.regprocedure
  );
  v_before := 'IF NOT coalesce(public.app_role() = ''admin'' AND public.app_account_valid(), false)' || E'\n'
    || '     OR p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN' || E'\n'
    || '    RAISE EXCEPTION ''affectation reservee a l''administration'';' || E'\n'
    || '  END IF;';
  v_after := 'IF NOT coalesce(public.app_account_valid() AND public.app_role() = ''admin'', false) THEN' || E'\n'
    || '    RAISE EXCEPTION ''affectation reservee a l''administration'';' || E'\n'
    || '  END IF;' || E'\n'
    || '  IF p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN' || E'\n'
    || '    RAISE EXCEPTION ''affectation reservee a l''administration'';' || E'\n'
    || '  END IF;';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected affecter_enseignant_classe definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;

  v_definition := pg_catalog.pg_get_functiondef(
    'public.affecter_enseignant_classe_c11bis(uuid,uuid)'::pg_catalog.regprocedure
  );
  v_before := 'IF NOT coalesce(' || E'\n'
    || '       public.app_role() = ''admin'' AND public.app_account_valid(),' || E'\n'
    || '       false' || E'\n'
    || '     )' || E'\n'
    || '     OR p_groupe_id IS NULL' || E'\n'
    || '     OR p_teacher_profile_id IS NULL THEN' || E'\n'
    || '    RAISE EXCEPTION ''affectation reservee a l''administration''' || E'\n'
    || '      USING ERRCODE = ''42501'';' || E'\n'
    || '  END IF;';
  v_after := 'IF NOT coalesce(' || E'\n'
    || '       public.app_account_valid() AND public.app_role() = ''admin'',' || E'\n'
    || '       false' || E'\n'
    || '     ) THEN' || E'\n'
    || '    RAISE EXCEPTION ''affectation reservee a l''administration''' || E'\n'
    || '      USING ERRCODE = ''42501'';' || E'\n'
    || '  END IF;' || E'\n'
    || '  IF p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN' || E'\n'
    || '    RAISE EXCEPTION ''affectation reservee a l''administration''' || E'\n'
    || '      USING ERRCODE = ''42501'';' || E'\n'
    || '  END IF;';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected affecter_enseignant_classe_c11bis definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;
END
$f86_patch$;

REVOKE ALL ON FUNCTION public.affecter_enseignant_classe(uuid,uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.affecter_enseignant_classe(uuid,uuid)
  TO authenticated;
REVOKE ALL ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid,uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid,uuid)
  TO authenticated;

COMMENT ON FUNCTION public.affecter_enseignant_classe(uuid,uuid) IS
  'F86 candidate allowlist: signature=public.affecter_enseignant_classe(uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: active admin may assign only eligible teachers; non-admin, inactive admin, and missing-profile JWT are denied before mutation.';
COMMENT ON FUNCTION public.affecter_enseignant_classe_c11bis(uuid,uuid) IS
  'F86 candidate allowlist: signature=public.affecter_enseignant_classe_c11bis(uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: active admin reaches the fail-closed compatibility check; non-admin, inactive admin, and missing-profile JWT are denied by the first guard.';

DO $f86_postflight$
DECLARE
  v_signature text;
  v_definition text;
  v_owner text;
  v_config text[];
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.affecter_enseignant_classe(uuid,uuid)',
    'public.affecter_enseignant_classe_c11bis(uuid,uuid)'
  ] LOOP
    SELECT pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
      INTO v_owner, v_config
      FROM pg_catalog.pg_proc p
     WHERE p.oid = pg_catalog.to_regprocedure(v_signature)::oid;
    v_definition := pg_catalog.pg_get_functiondef(v_signature::pg_catalog.regprocedure);
    IF v_owner IS DISTINCT FROM 'postgres'
       OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
       OR pg_catalog.strpos(v_definition, 'public.app_account_valid() AND public.app_role() = ''admin''') = 0
       OR pg_catalog.strpos(v_definition, 'affectation reservee a l''administration') = 0
       OR pg_catalog.has_function_privilege('anon', v_signature, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_signature, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_signature, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_signature, 'EXECUTE')
       OR coalesce(pg_catalog.strpos(
         pg_catalog.obj_description(pg_catalog.to_regprocedure(v_signature)::oid, 'pg_proc'),
         'md5_functiondef=A_CALCULER;'
       ), 0) = 0 THEN
      RAISE EXCEPTION 'F86 postflight: guard/ACL/owner/search_path/allowlist invalid for %', v_signature;
    END IF;
  END LOOP;
END
$f86_postflight$;

COMMIT;
