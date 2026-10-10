-- 0080 — tranche d'âge signée et demandes de présentation MA-9.
BEGIN;

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
$function$;

COMMENT ON FUNCTION public.custom_access_token_hook(jsonb) IS
  'Pose app_metadata.role/household_id et tranche_age (enfant/adulte/inconnu) sans DOB. tranche_age est une donnée de présentation, jamais une autorisation. Le hook ne rend jamais NULL.';

REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb)
  FROM anon, authenticated, public;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb)
  TO supabase_auth_admin;

ALTER TABLE public.notifications
  DROP CONSTRAINT notifications_evenement_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
    'demande_recue',
    'classe_validee',
    'enseignant_affecte',
    'demande_close',
    'remplacement_propose',
    'remplacement_pris',
    'demande_presentation'
  ));

CREATE TABLE public.demandes_presentation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  eleve_id uuid NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  foyer_id uuid NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'acceptee', 'refusee')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  repondu_le timestamptz,
  repondu_par uuid REFERENCES public.profiles(id),
  CONSTRAINT demandes_presentation_reponse_coherente CHECK (
    (statut = 'en_attente' AND repondu_le IS NULL AND repondu_par IS NULL)
    OR
    (statut IN ('acceptee', 'refusee') AND repondu_le IS NOT NULL AND repondu_par IS NOT NULL)
  )
);

CREATE UNIQUE INDEX demandes_presentation_une_en_attente_par_eleve
  ON public.demandes_presentation (eleve_id)
  WHERE statut = 'en_attente';
CREATE INDEX demandes_presentation_foyer_statut_cree
  ON public.demandes_presentation (foyer_id, statut, cree_le DESC);

ALTER TABLE public.demandes_presentation ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.demandes_presentation FROM PUBLIC, anon, authenticated, agent_ro;

CREATE OR REPLACE FUNCTION public.demander_presentation_standard()
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_eleve uuid := auth.uid();
  v_foyer uuid;
  v_tuteur uuid;
  v_demande uuid;
BEGIN
  IF NOT coalesce(
    v_eleve IS NOT NULL
    AND public.app_role() = 'student'
    AND public.app_account_valid()
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      JOIN public.student_profiles sp ON sp.profile_id = p.id
      JOIN public.households h ON h.id = p.household_id
      WHERE p.id = v_eleve
        AND p.role = 'student'
        AND p.deleted_at IS NULL
        AND p.household_id IS NOT NULL
        AND h.status = 'active'
        AND h.deleted_at IS NULL
        AND sp.student_type = 'minor'
        AND sp.deleted_at IS NULL
        AND h.primary_guardian_id IS NOT NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'demande réservée à un élève mineur actif'
      USING ERRCODE = '42501';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('presentation:' || v_eleve::text, 0)
  );

  SELECT p.household_id, h.primary_guardian_id
    INTO v_foyer, v_tuteur
  FROM public.profiles p
  JOIN public.households h ON h.id = p.household_id
  JOIN public.profiles guardian
    ON guardian.id = h.primary_guardian_id
   AND guardian.role = 'guardian'
   AND guardian.household_id = h.id
   AND guardian.deleted_at IS NULL
   AND guardian.account_status IN ('active', 'provisional_active')
  WHERE p.id = v_eleve
    AND h.status = 'active'
    AND h.deleted_at IS NULL;

  IF NOT FOUND OR v_tuteur IS NULL THEN
    RAISE EXCEPTION 'tuteur du foyer indisponible';
  END IF;

  SELECT d.id INTO v_demande
  FROM public.demandes_presentation d
  WHERE d.eleve_id = v_eleve AND d.statut = 'en_attente';

  IF FOUND THEN
    RETURN;
  END IF;

  INSERT INTO public.demandes_presentation (eleve_id, foyer_id)
  VALUES (v_eleve, v_foyer)
  RETURNING id INTO v_demande;

  INSERT INTO public.notifications
    (destinataire, foyer_id, evenement, params, destination)
  VALUES (
    v_tuteur,
    v_foyer,
    'demande_presentation',
    pg_catalog.jsonb_build_object('demande_id', v_demande),
    '/tuteur/demandes'
  );

  PERFORM public.log_sensitive_access(
    'demande_presentation_creee',
    'demandes_presentation',
    v_demande::text,
    pg_catalog.jsonb_build_object('eleve_id', v_eleve, 'foyer_id', v_foyer)
  );

  RETURN;
END;
$function$;

CREATE OR REPLACE FUNCTION public.lire_demandes_presentation_en_attente()
RETURNS TABLE (
  id uuid,
  eleve_id uuid,
  eleve_prenom text,
  cree_le timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    auth.uid() IS NOT NULL
    AND public.app_role() = 'guardian'
    AND public.app_account_valid()
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.households h ON h.id = p.household_id
      WHERE p.id = auth.uid()
        AND p.role = 'guardian'
        AND p.deleted_at IS NULL
        AND h.status = 'active'
        AND h.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'lecture réservée au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT d.id, d.eleve_id, student.first_name, d.cree_le
  FROM public.demandes_presentation d
  JOIN public.profiles guardian ON guardian.id = auth.uid()
  JOIN public.profiles student ON student.id = d.eleve_id
  WHERE d.foyer_id = guardian.household_id
    AND d.statut = 'en_attente'
    AND student.deleted_at IS NULL
  ORDER BY d.cree_le;
END;
$function$;

CREATE OR REPLACE FUNCTION public.repondre_demande_presentation(
  p_demande_id uuid,
  p_statut text
)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_demande public.demandes_presentation%ROWTYPE;
  v_foyer uuid;
BEGIN
  IF NOT coalesce(
    p_demande_id IS NOT NULL
    AND p_statut IN ('acceptee', 'refusee')
    AND auth.uid() IS NOT NULL
    AND public.app_role() = 'guardian'
    AND public.app_account_valid()
    AND EXISTS (
      SELECT 1 FROM public.profiles guardian
      JOIN public.households h ON h.id = guardian.household_id
      WHERE guardian.id = auth.uid()
        AND guardian.role = 'guardian'
        AND guardian.deleted_at IS NULL
        AND h.status = 'active'
        AND h.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'réponse réservée au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_demande
  FROM public.demandes_presentation d
  WHERE d.id = p_demande_id
    AND d.foyer_id = public.app_household_id()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'demande de présentation inaccessible'
      USING ERRCODE = '42501';
  END IF;

  IF v_demande.statut = p_statut THEN
    RETURN v_demande.statut;
  END IF;
  IF v_demande.statut <> 'en_attente' THEN
    RAISE EXCEPTION 'demande déjà tranchée';
  END IF;

  UPDATE public.demandes_presentation
  SET statut = p_statut,
      repondu_le = pg_catalog.now(),
      repondu_par = auth.uid()
  WHERE id = v_demande.id
    AND foyer_id = public.app_household_id()
    AND statut = 'en_attente'
  RETURNING foyer_id INTO v_foyer;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'demande déjà tranchée';
  END IF;

  PERFORM public.log_sensitive_access(
    'demande_presentation_' || p_statut,
    'demandes_presentation',
    v_demande.id::text,
    pg_catalog.jsonb_build_object('foyer_id', v_foyer)
  );

  RETURN p_statut;
END;
$function$;

CREATE OR REPLACE FUNCTION public.accepter_demande_presentation(p_demande_id uuid)
RETURNS text
LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT public.repondre_demande_presentation(p_demande_id, 'acceptee');
$function$;

CREATE OR REPLACE FUNCTION public.refuser_demande_presentation(p_demande_id uuid)
RETURNS text
LANGUAGE sql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT public.repondre_demande_presentation(p_demande_id, 'refusee');
$function$;

REVOKE ALL ON FUNCTION public.demander_presentation_standard()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_presentation_standard() TO authenticated;
REVOKE ALL ON FUNCTION public.lire_demandes_presentation_en_attente()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_demandes_presentation_en_attente() TO authenticated;
REVOKE ALL ON FUNCTION public.repondre_demande_presentation(uuid, text)
  FROM PUBLIC, anon, authenticated, agent_ro;
REVOKE ALL ON FUNCTION public.accepter_demande_presentation(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.accepter_demande_presentation(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.refuser_demande_presentation(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.refuser_demande_presentation(uuid) TO authenticated;

-- Contrôle ACL à l'application du schéma, avant les scénarios historiques qui
-- accordent temporairement des privilèges larges à authenticated.
DO $acl$
BEGIN
  IF pg_catalog.has_table_privilege('anon', 'public.demandes_presentation', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.demandes_presentation', 'SELECT')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.demandes_presentation', 'SELECT')
     OR pg_catalog.has_function_privilege(
          'anon', 'public.demander_presentation_standard()', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
          'anon', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
          'anon', 'public.accepter_demande_presentation(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
          'agent_ro', 'public.repondre_demande_presentation(uuid,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege(
          'authenticated', 'public.demander_presentation_standard()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege(
          'authenticated', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege(
          'authenticated', 'public.accepter_demande_presentation(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege(
          'authenticated', 'public.refuser_demande_presentation(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'B-17 ACL de schéma invalide';
  END IF;
END;
$acl$;

COMMIT;
