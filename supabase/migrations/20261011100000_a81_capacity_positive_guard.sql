BEGIN;

-- A81/F86: the autonomous student's own capability remains available to the
-- student session, but the SECURITY DEFINER entry point requires a positive
-- role and a currently valid account before reading the private profile row.
CREATE OR REPLACE FUNCTION public.ma_capacite_eleve()
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'student',
    false
  ) THEN
    RAISE EXCEPTION 'acces capacite eleve refuse' USING errcode = '42501';
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.student_profiles sp
    WHERE sp.profile_id = auth.uid()
      AND sp.student_type = 'autonomous'
      AND sp.deleted_at IS NULL
  );
END;
$function$;
ALTER FUNCTION public.ma_capacite_eleve() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.ma_capacite_eleve()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_capacite_eleve() TO authenticated;

COMMENT ON FUNCTION public.ma_capacite_eleve() IS
  'F86 candidate allowlist: signature=public.ma_capacite_eleve(); md5_prosrc=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: active student can read only their own autonomous capability; other roles are denied.';

DO $verification$
DECLARE
  v_definition text;
BEGIN
  SELECT pg_catalog.pg_get_functiondef(
    'public.ma_capacite_eleve()'::regprocedure
  ) INTO v_definition;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.ma_capacite_eleve()'::regprocedure
      AND p.prosecdef
      AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
      AND p.proconfig @> ARRAY['search_path=""']
  ) OR v_definition NOT LIKE '%public.app_role() = ''student''%'
    OR v_definition NOT LIKE '%public.app_account_valid()%'
    OR has_function_privilege('anon', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR has_function_privilege('service_role', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR NOT has_function_privilege('authenticated', 'public.ma_capacite_eleve()', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'A81/F86 garde, proprietaire, search_path ou ACL invalide';
  END IF;
END;
$verification$;

COMMIT;
