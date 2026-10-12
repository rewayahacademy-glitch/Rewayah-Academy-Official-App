BEGIN;

-- L'intention appartient au compte connecté. La fiche adulte est créée dans
-- la même transaction que le profil guardian, sans changer son rôle.
DROP FUNCTION IF EXISTS public.creer_profil_inscription(
  text, text, text, public.gender, text
);

CREATE OR REPLACE FUNCTION public.creer_profil_inscription(
  p_role text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_parent_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_role public.app_role;
  v_household uuid;
  v_profile public.profiles;
  v_initiales text;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  IF p_role NOT IN ('guardian', 'teacher') THEN
    RAISE EXCEPTION 'role non ouvert a l''inscription publique : %', p_role;
  END IF;
  v_role := p_role::public.app_role;
  IF v_role <> 'guardian' AND coalesce(p_parent_suit_des_cours, false) THEN
    RAISE EXCEPTION 'profil apprenant personnel reserve au titulaire';
  END IF;
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid) THEN
    RAISE EXCEPTION 'ce compte a deja un profil';
  END IF;
  IF coalesce(btrim(p_first_name), '') = '' OR coalesce(btrim(p_last_name), '') = '' THEN
    RAISE EXCEPTION 'prenom et nom sont requis';
  END IF;

  IF v_role = 'guardian' THEN
    INSERT INTO public.households (timezone)
    VALUES (coalesce(nullif(btrim(p_timezone), ''), 'Europe/Paris'))
    RETURNING id INTO v_household;
  END IF;
  v_initiales := upper(left(btrim(p_first_name), 1) || left(btrim(p_last_name), 1));
  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  VALUES (v_uid, public.next_immutable_id(v_role, v_initiales), v_role,
    v_household, btrim(p_first_name), btrim(p_last_name), p_gender, 'pending_kyc')
  RETURNING * INTO v_profile;

  IF v_role = 'guardian' THEN
    UPDATE public.households SET primary_guardian_id = v_uid WHERE id = v_household;
    IF coalesce(p_parent_suit_des_cours, false) THEN
      INSERT INTO public.student_profiles
        (profile_id, titulaire_profile_id, student_type, interface_mode,
         camera_policy, cohorte)
      VALUES (v_uid, v_uid, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');
      PERFORM public.log_sensitive_access(
        'profil_eleve_titulaire_cree', 'student_profiles', v_uid::text,
        jsonb_build_object('student_type', 'autonomous', 'source', 'inscription')
      );
    END IF;
  ELSE
    INSERT INTO public.teacher_profiles (profile_id) VALUES (v_uid);
  END IF;
  PERFORM public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    jsonb_build_object('role', v_role::text));
  RETURN v_profile;
END;
$function$;

ALTER FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) TO authenticated;

CREATE OR REPLACE FUNCTION public.ma_capacite_eleve()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.student_profiles sp
    WHERE sp.profile_id = auth.uid()
      AND sp.student_type = 'autonomous'
      AND sp.deleted_at IS NULL
  );
$function$;

ALTER FUNCTION public.ma_capacite_eleve() OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.ma_capacite_eleve() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_capacite_eleve() TO authenticated;

DO $verification$
BEGIN
  IF to_regprocedure('public.creer_profil_inscription(text,text,text,public.gender,text,boolean)') IS NULL
    OR to_regprocedure('public.ma_capacite_eleve()') IS NULL
    OR has_function_privilege('anon', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.ma_capacite_eleve()', 'EXECUTE')
  THEN RAISE EXCEPTION '0077 ACL ou fonctions incompletes'; END IF;
END
$verification$;

COMMIT;
