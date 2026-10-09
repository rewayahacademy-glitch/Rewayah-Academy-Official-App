-- 0052 — B-07 : profil d'apprenant adulte sur le même compte titulaire.
-- Le compte conserve profiles.role = guardian ; aucune seconde identité Auth.
BEGIN;

ALTER TABLE public.student_profiles
  ADD COLUMN IF NOT EXISTS titulaire_profile_id uuid
    REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS student_profiles_titulaire_unique
  ON public.student_profiles (titulaire_profile_id)
  WHERE titulaire_profile_id IS NOT NULL AND deleted_at IS NULL;

DO $constraint$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint
    WHERE conrelid = 'public.student_profiles'::regclass
      AND conname = 'student_profiles_titulaire_meme_profil'
  ) THEN
    ALTER TABLE public.student_profiles
      ADD CONSTRAINT student_profiles_titulaire_meme_profil
      CHECK (titulaire_profile_id IS NULL OR titulaire_profile_id = profile_id);
  END IF;
END
$constraint$;

COMMENT ON COLUMN public.student_profiles.titulaire_profile_id IS
  'Pour l''apprenant adulte titulaire : référence le même profiles.id ; jamais un second compte ni un rôle remplacé.';

CREATE OR REPLACE FUNCTION public.peut_decrire_apprenant(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce(
    public.compte_en_parcours()
    AND (
      (
        public.app_role() = 'guardian'
        AND EXISTS (
          SELECT 1
          FROM public.profiles p
          WHERE p.id = p_profile_id
            AND p.role = 'student'
            AND p.household_id IS NOT NULL
            AND p.household_id = public.app_household_id()
            AND p.deleted_at IS NULL
        )
      )
      OR (
        p_profile_id = auth.uid()
        AND EXISTS (
          SELECT 1
          FROM public.student_profiles sp
          WHERE sp.profile_id = auth.uid()
            AND sp.student_type = 'autonomous'
            AND sp.deleted_at IS NULL
            AND (
              sp.titulaire_profile_id = auth.uid()
              OR public.app_role() = 'student'
            )
        )
      )
    ),
    false
  );
$function$;

ALTER FUNCTION public.peut_decrire_apprenant(uuid) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.peut_decrire_apprenant(uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.peut_decrire_apprenant(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.creer_profil_eleve_titulaire()
RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_profile public.profiles%ROWTYPE;
  v_student public.student_profiles%ROWTYPE;
BEGIN
  IF v_user IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'création réservée au titulaire connecté';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles p
  WHERE p.id = v_user
    AND p.role = 'guardian'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > now())
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'profil titulaire indisponible';
  END IF;

  SELECT * INTO v_student
  FROM public.student_profiles sp
  WHERE sp.titulaire_profile_id = v_user
    AND sp.profile_id = v_user
    AND sp.deleted_at IS NULL;

  IF FOUND THEN
    RETURN v_user;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.student_profiles sp
    WHERE sp.profile_id = v_user
      AND sp.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'une fiche d''apprentissage existe déjà pour ce profil';
  END IF;

  INSERT INTO public.student_profiles
    (profile_id, titulaire_profile_id, student_type, interface_mode, camera_policy, cohorte)
  VALUES
    (v_user, v_user, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');

  PERFORM public.log_sensitive_access(
    'profil_eleve_titulaire_cree', 'student_profiles', v_user::text,
    jsonb_build_object('student_type', 'autonomous', 'cohorte', 'adulte_18_plus')
  );

  RETURN v_user;
END;
$function$;

ALTER FUNCTION public.creer_profil_eleve_titulaire() OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.creer_profil_eleve_titulaire() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_profil_eleve_titulaire() TO authenticated;

DO $verification$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'student_profiles'
      AND column_name = 'titulaire_profile_id'
  ) OR to_regprocedure('public.creer_profil_eleve_titulaire()') IS NULL
    OR NOT has_function_privilege('authenticated',
                                  'public.creer_profil_eleve_titulaire()', 'EXECUTE')
    OR has_function_privilege('anon',
                              'public.creer_profil_eleve_titulaire()', 'EXECUTE')
    OR has_function_privilege('agent_ro',
                              'public.creer_profil_eleve_titulaire()', 'EXECUTE')
  THEN
    RAISE EXCEPTION '0052 incomplete: titular profile contract or ACL invalid';
  END IF;
END
$verification$;

COMMIT;
