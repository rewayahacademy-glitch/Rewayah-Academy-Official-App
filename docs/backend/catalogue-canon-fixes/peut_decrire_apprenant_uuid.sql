CREATE OR REPLACE FUNCTION public.peut_decrire_apprenant(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
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
$function$

