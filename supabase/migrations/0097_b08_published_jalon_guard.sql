BEGIN;

-- A teacher may publish a family milestone only from the published program
-- version and level assigned to that student. Drafts remain valid while the
-- summary itself is unpublished.
CREATE OR REPLACE FUNCTION public.guard_resume_jalon_publie()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.publie_le IS NOT NULL
     AND NEW.jalon_atteint IS NOT NULL
     AND NOT EXISTS (
       SELECT 1
       FROM public.programme_niveaux n
       JOIN public.programme_versions v ON v.id = n.version_id
       JOIN public.student_profiles sp ON sp.profile_id = NEW.student_id
       WHERE n.id = NEW.jalon_atteint
         AND v.statut = 'publiee'
         AND n.code_technique = sp.level
         AND sp.deleted_at IS NULL
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'jalon_programme_non_publie_ou_incoherent';
  END IF;
  RETURN NEW;
END;
$function$;

ALTER FUNCTION public.guard_resume_jalon_publie() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.guard_resume_jalon_publie()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DROP TRIGGER IF EXISTS seance_resume_jalon_publie_guard
  ON public.seance_resumes;
CREATE TRIGGER seance_resume_jalon_publie_guard
BEFORE INSERT OR UPDATE OF student_id, jalon_atteint, publie_le
ON public.seance_resumes
FOR EACH ROW
EXECUTE FUNCTION public.guard_resume_jalon_publie();

DO $verification$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_trigger t
    JOIN pg_catalog.pg_proc p ON p.oid = t.tgfoid
    WHERE t.tgrelid = 'public.seance_resumes'::regclass
      AND t.tgname = 'seance_resume_jalon_publie_guard'
      AND NOT t.tgisinternal
      AND NOT p.prosecdef
      AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
      AND p.proconfig @> ARRAY['search_path=""']
  ) OR has_function_privilege(
    'authenticated', 'public.guard_resume_jalon_publie()', 'EXECUTE'
  ) OR has_function_privilege(
    'anon', 'public.guard_resume_jalon_publie()', 'EXECUTE'
  ) OR has_function_privilege(
    'service_role', 'public.guard_resume_jalon_publie()', 'EXECUTE'
  ) THEN
    RAISE EXCEPTION '0097 B-08 jalon trigger postflight failed';
  END IF;
END;
$verification$;

COMMIT;
