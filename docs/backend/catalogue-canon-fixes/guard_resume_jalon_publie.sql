CREATE OR REPLACE FUNCTION public.guard_resume_jalon_publie()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
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
$function$

