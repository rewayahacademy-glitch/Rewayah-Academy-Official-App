CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  claims jsonb;
  user_id uuid := (event ->> 'user_id')::uuid;
  v_profile public.profiles;
  v_student_type public.student_type;
  v_tranche_age text := 'inconnu';
BEGIN
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE public.profiles.id = user_id
    AND public.profiles.deleted_at IS NULL;

  claims := coalesce(event -> 'claims', '{}'::jsonb);

  IF v_profile.id IS NOT NULL THEN
    IF coalesce(jsonb_typeof(claims -> 'app_metadata'), 'absent') <> 'object' THEN
      claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb);
    END IF;

    claims := jsonb_set(
      claims,
      '{app_metadata, role}',
      coalesce(to_jsonb(v_profile.role::text), 'null'::jsonb)
    );
    claims := jsonb_set(
      claims,
      '{app_metadata, household_id}',
      coalesce(to_jsonb(v_profile.household_id::text), 'null'::jsonb)
    );

    SELECT sp.student_type INTO v_student_type
    FROM public.student_profiles sp
    WHERE sp.profile_id = user_id
      AND sp.deleted_at IS NULL;

    v_tranche_age := CASE v_student_type
      WHEN 'minor' THEN 'enfant'
      WHEN 'autonomous' THEN 'adulte'
      ELSE 'inconnu'
    END;
  END IF;

  -- Claim de présentation uniquement : aucune décision d'accès ne s'appuie
  -- sur lui. Il ne contient jamais de date de naissance.
  claims := jsonb_set(claims, '{tranche_age}', to_jsonb(v_tranche_age), true);

  RETURN coalesce(jsonb_set(event, '{claims}', claims), event);
END;
$function$

