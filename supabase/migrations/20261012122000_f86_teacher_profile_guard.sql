BEGIN;

CREATE OR REPLACE FUNCTION public.maj_profil_enseignant(
  p_country text DEFAULT NULL,
  p_languages text[] DEFAULT NULL,
  p_timezone text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF NOT coalesce(
    public.app_role() = 'teacher' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'profil enseignant indisponible'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_timezone IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_timezone
     ) THEN
    RAISE EXCEPTION 'fuseau inconnu';
  END IF;

  UPDATE public.teacher_profiles t
  SET country = coalesce(p_country, t.country),
      languages = coalesce(p_languages, t.languages),
      timezone_iana = coalesce(p_timezone, t.timezone_iana)
  WHERE t.profile_id = v_uid
    AND t.deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucun profil enseignant';
  END IF;
END;
$function$;

ALTER FUNCTION public.maj_profil_enseignant(text, text[], text) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.maj_profil_enseignant(text, text[], text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.maj_profil_enseignant(text, text[], text) TO authenticated;
COMMENT ON FUNCTION public.maj_profil_enseignant(text, text[], text) IS
  'F86 candidate allowlist: signature=public.maj_profil_enseignant(text,text[],text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.maj_profil_enseignant(text,text[],text)');
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_roles r ON r.oid = p.proowner
  WHERE p.oid = v_oid
    AND p.prosecdef
    AND r.rolname = 'postgres'
    AND 'search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[]))
    AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'NOT COALESCE') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ACCOUNT_VALID') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ROLE') > 0;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'F86 teacher profile postflight failed: % of 1', v_count;
  END IF;
END;
$postflight$;

COMMIT;
