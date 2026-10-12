-- 0056 — B-07 : lecture serveur minimale de l'existence du profil apprenant titulaire.
BEGIN;

CREATE OR REPLACE FUNCTION public.profil_eleve_titulaire_existe()
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
BEGIN
  IF v_user IS NULL
     OR NOT coalesce(
       public.app_role() = 'guardian' AND public.app_account_valid(),
       false
     )
     OR NOT EXISTS (
       SELECT 1 FROM public.profiles p
       WHERE p.id = v_user
         AND p.role = 'guardian'
         AND p.deleted_at IS NULL
         AND p.account_status IN ('active', 'provisional_active')
         AND (p.access_until IS NULL OR p.access_until > now())
     ) THEN
    RAISE EXCEPTION 'consultation réservée au titulaire connecté'
      USING errcode = 'insufficient_privilege';
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.student_profiles sp
    WHERE sp.profile_id = v_user
      AND sp.titulaire_profile_id = v_user
      AND sp.deleted_at IS NULL
  );
END;
$function$;

ALTER FUNCTION public.profil_eleve_titulaire_existe() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.profil_eleve_titulaire_existe()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.profil_eleve_titulaire_existe()
  TO authenticated;

COMMIT;
