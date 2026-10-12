BEGIN;
SET LOCAL search_path = '';

COMMENT ON FUNCTION public.previsualiser_import_inscriptions(text,text) IS
  'F86 candidate allowlist: signature=public.previsualiser_import_inscriptions(text,text); md5_functiondef=355d5f55d43ad3ee8b6541bbec0ff0d6; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';

COMMENT ON FUNCTION public.confirmer_import_inscriptions(text,text,jsonb) IS
  'F86 candidate allowlist: signature=public.confirmer_import_inscriptions(text,text,jsonb); md5_functiondef=741639b411b59c6fbeb88d93e47115e0; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';

COMMENT ON FUNCTION public.reclamer_preinscription_apres_preuve() IS
  'F86 candidate allowlist: signature=public.reclamer_preinscription_apres_preuve(); md5_functiondef=6e9dee18f99b1f35ad1019eb9615853c; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-13.';

DO $f86_postflight$
DECLARE
  v_signature text;
  v_expected_hash text;
  v_oid pg_catalog.regprocedure;
  v_hash text;
  v_owner text;
  v_config text[];
BEGIN
  FOR v_signature, v_expected_hash IN
    SELECT * FROM (VALUES
      ('public.previsualiser_import_inscriptions(text,text)', '355d5f55d43ad3ee8b6541bbec0ff0d6'),
      ('public.confirmer_import_inscriptions(text,text,jsonb)', '741639b411b59c6fbeb88d93e47115e0'),
      ('public.reclamer_preinscription_apres_preuve()', '6e9dee18f99b1f35ad1019eb9615853c')
    ) AS fingerprints(signature, expected_hash)
  LOOP
    v_oid := v_signature::pg_catalog.regprocedure;
    SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)),
           pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
      INTO v_hash, v_owner, v_config
      FROM pg_catalog.pg_proc p
     WHERE p.oid = v_oid::oid AND p.prosecdef;

    IF v_hash IS DISTINCT FROM v_expected_hash
       OR v_owner IS DISTINCT FROM 'postgres'
       OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR coalesce(pg_catalog.strpos(
         pg_catalog.obj_description(v_oid::oid, 'pg_proc'),
         'md5_functiondef=' || v_expected_hash || ';'
       ), 0) = 0 THEN
      RAISE EXCEPTION 'F86 IMM-ACCUEIL postflight invalide pour %', v_signature;
    END IF;
  END LOOP;
END
$f86_postflight$;

COMMIT;
