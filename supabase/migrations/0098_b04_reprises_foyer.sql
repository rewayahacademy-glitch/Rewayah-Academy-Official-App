-- B-04 : file administrative des reprises de foyer et décision idempotente.
BEGIN;

CREATE TABLE public.reprises_foyer (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES public.households(id),
  demandeur_profile_id uuid NOT NULL REFERENCES public.profiles(id),
  statut text NOT NULL DEFAULT 'a_examiner'
    CHECK (statut IN ('a_examiner', 'refusee_par_titulaire', 'approuvee', 'refusee_admin')),
  deposee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  examen_possible_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  redepot_possible_le timestamptz,
  decidee_par uuid REFERENCES public.profiles(id),
  decidee_le timestamptz,
  cle_decision uuid UNIQUE,
  cle_depot uuid NOT NULL UNIQUE,
  cle_refus uuid UNIQUE,
  titulaire_profile_id uuid NOT NULL REFERENCES public.profiles(id),
  foyer_personnel_id uuid REFERENCES public.households(id),
  CONSTRAINT reprises_foyer_decision_coherente CHECK (
    (statut IN ('approuvee', 'refusee_admin') AND decidee_par IS NOT NULL
      AND decidee_le IS NOT NULL AND cle_decision IS NOT NULL)
    OR (statut IN ('a_examiner', 'refusee_par_titulaire')
      AND decidee_par IS NULL AND decidee_le IS NULL AND cle_decision IS NULL)
  ),
  CONSTRAINT reprises_foyer_foyer_personnel_coherent CHECK (
    (statut = 'approuvee') = (foyer_personnel_id IS NOT NULL)
  )
);
CREATE UNIQUE INDEX reprises_foyer_une_ouverte_par_foyer
  ON public.reprises_foyer (household_id)
  WHERE statut IN ('a_examiner', 'refusee_par_titulaire');
ALTER TABLE public.reprises_foyer ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.reprises_foyer FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.deposer_reprise_foyer(p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_household uuid := public.app_household_id();
  v_primary uuid;
  v_id uuid;
  v_depot timestamptz;
  v_exam timestamptz;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'guardian', false) THEN
    RAISE EXCEPTION 'depot reserve au second adulte du foyer' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR auth.uid() IS NULL OR v_household IS NULL THEN
    RAISE EXCEPTION 'cle ou foyer absent' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('reprise-foyer:' || v_household::text, 0)
  );
  -- Une reprise retry reste idempotente même après que l'approbation a déplacé
  -- le profil vers son foyer personnel.
  SELECT r.id, r.deposee_le, r.examen_possible_le INTO v_id, v_depot, v_exam
  FROM public.reprises_foyer r WHERE r.cle_depot = p_cle
    AND r.demandeur_profile_id = auth.uid();
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'enregistree', 'deposee_le', v_depot,
      'examen_possible_le', v_exam, 'redepot_possible_le', NULL);
  END IF;
  SELECT h.primary_guardian_id INTO v_primary
  FROM public.households h
  WHERE h.id = v_household AND h.status = 'active' AND h.deleted_at IS NULL
  FOR UPDATE;
  IF NOT FOUND OR v_primary IS NULL OR v_primary = auth.uid() OR NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.household_id = v_household
      AND p.role = 'guardian' AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'demandeur non eligible a la reprise' USING ERRCODE = '42501';
  END IF;
  IF EXISTS (SELECT 1 FROM public.reprises_foyer r
      WHERE r.household_id = v_household
        AND r.statut IN ('a_examiner', 'refusee_par_titulaire')) THEN
    RAISE EXCEPTION 'une demande de reprise est deja ouverte' USING ERRCODE = '23505';
  END IF;
  IF EXISTS (SELECT 1 FROM public.reprises_foyer r
      WHERE r.household_id = v_household AND r.statut = 'refusee_admin'
        AND r.redepot_possible_le > pg_catalog.now()) THEN
    RAISE EXCEPTION 'red depot encore differe' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.reprises_foyer(
    household_id, demandeur_profile_id, titulaire_profile_id, cle_depot
  ) VALUES (v_household, auth.uid(), v_primary, p_cle)
  RETURNING id, deposee_le, examen_possible_le INTO v_id, v_depot, v_exam;
  PERFORM public.log_sensitive_access('reprise_foyer_deposee', 'reprises_foyer', v_id::text,
    pg_catalog.jsonb_build_object('household_id', v_household));
  RETURN pg_catalog.jsonb_build_object('statut', 'enregistree', 'deposee_le', v_depot,
    'examen_possible_le', v_exam, 'redepot_possible_le', NULL);
END;
$function$;
ALTER FUNCTION public.deposer_reprise_foyer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.deposer_reprise_foyer(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.deposer_reprise_foyer(uuid) TO authenticated;

CREATE FUNCTION public.refuser_reprise_foyer(p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_reprise public.reprises_foyer%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'guardian', false) THEN
    RAISE EXCEPTION 'refus reserve au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR auth.uid() IS NULL OR public.app_household_id() IS NULL THEN
    RAISE EXCEPTION 'cle ou foyer absent' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('reprise-foyer:' || public.app_household_id()::text, 0)
  );
  SELECT r.* INTO v_reprise FROM public.reprises_foyer r
  WHERE r.household_id = public.app_household_id()
    AND r.statut IN ('a_examiner', 'refusee_par_titulaire')
  ORDER BY r.deposee_le DESC, r.id DESC LIMIT 1 FOR UPDATE;
  IF NOT FOUND OR v_reprise.titulaire_profile_id <> auth.uid() THEN
    RAISE EXCEPTION 'aucune demande a refuser' USING ERRCODE = '42501';
  END IF;
  IF v_reprise.cle_refus = p_cle THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'enregistree');
  END IF;
  IF v_reprise.statut = 'refusee_par_titulaire' THEN
    RAISE EXCEPTION 'demande deja refusee par le titulaire' USING ERRCODE = '23505';
  END IF;
  UPDATE public.reprises_foyer SET statut = 'refusee_par_titulaire', cle_refus = p_cle
    WHERE id = v_reprise.id;
  PERFORM public.log_sensitive_access('reprise_foyer_refusee_titulaire', 'reprises_foyer', v_reprise.id::text,
    pg_catalog.jsonb_build_object('household_id', v_reprise.household_id));
  RETURN pg_catalog.jsonb_build_object('statut', 'enregistree');
END;
$function$;
ALTER FUNCTION public.refuser_reprise_foyer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.refuser_reprise_foyer(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.refuser_reprise_foyer(uuid) TO authenticated;

CREATE FUNCTION public.etat_reprise_foyer()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_reprise public.reprises_foyer%ROWTYPE;
  v_statut text;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'guardian', false) THEN
    RAISE EXCEPTION 'etat de reprise reserve au foyer' USING ERRCODE = '42501';
  END IF;
  SELECT r.* INTO v_reprise FROM public.reprises_foyer r
  WHERE r.demandeur_profile_id = auth.uid()
  ORDER BY r.deposee_le DESC, r.id DESC LIMIT 1;
  IF FOUND THEN
    v_statut := CASE v_reprise.statut
      WHEN 'a_examiner' THEN CASE WHEN v_reprise.examen_possible_le <= pg_catalog.now()
        THEN 'attente_administration' ELSE 'deposee' END
      WHEN 'refusee_par_titulaire' THEN 'refusee_par_titulaire'
      WHEN 'approuvee' THEN 'validee'
      ELSE 'refusee'
    END;
    RETURN pg_catalog.jsonb_build_object(
      'type', 'demande', 'statut', v_statut, 'deposee_le', v_reprise.deposee_le,
      'examen_possible_le', v_reprise.examen_possible_le,
      'redepot_possible_le', v_reprise.redepot_possible_le
    );
  END IF;
  SELECT r.* INTO v_reprise FROM public.reprises_foyer r
  WHERE r.household_id = public.app_household_id()
    AND r.titulaire_profile_id = auth.uid()
    AND r.statut IN ('a_examiner', 'refusee_par_titulaire')
  ORDER BY r.deposee_le DESC, r.id DESC LIMIT 1;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object(
      'type', 'titulaire', 'statut', CASE WHEN v_reprise.statut = 'a_examiner'
        THEN 'a_refuser' ELSE 'refusee_par_vous' END,
      'deposee_le', v_reprise.deposee_le, 'examen_possible_le', v_reprise.examen_possible_le
    );
  END IF;
  RETURN pg_catalog.jsonb_build_object('type', 'aucune');
END;
$function$;
ALTER FUNCTION public.etat_reprise_foyer() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.etat_reprise_foyer() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.etat_reprise_foyer() TO authenticated;

CREATE FUNCTION public.lister_reprises_admin()
RETURNS TABLE (
  id uuid, demandeur_prenom text, demandeur_nom text, foyer_nom text,
  statut text, decidable boolean, deposee_le timestamptz, examen_possible_le timestamptz,
  redepot_possible_le timestamptz
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'liste des reprises reservee a l administration' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT r.id, p.first_name, p.last_name,
         coalesce(owner.first_name || ' ' || owner.last_name, 'Foyer'),
         r.statut,
         (r.statut IN ('a_examiner', 'refusee_par_titulaire')
           AND r.examen_possible_le <= pg_catalog.now()),
         r.deposee_le, r.examen_possible_le, r.redepot_possible_le
  FROM public.reprises_foyer r
  JOIN public.profiles p ON p.id = r.demandeur_profile_id
  JOIN public.households h ON h.id = r.household_id
  LEFT JOIN public.profiles owner ON owner.id = h.primary_guardian_id
  WHERE r.statut IN ('a_examiner', 'refusee_par_titulaire')
  ORDER BY r.deposee_le, r.id;
END;
$function$;
ALTER FUNCTION public.lister_reprises_admin() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lister_reprises_admin() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lister_reprises_admin() TO authenticated;

CREATE FUNCTION public.decider_reprise_foyer(
  p_reprise_id uuid, p_approuver boolean, p_cle uuid
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_reprise public.reprises_foyer%ROWTYPE;
  v_status text;
  v_personal_household_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'decision de reprise reservee a l administration' USING ERRCODE = '42501';
  END IF;
  IF p_reprise_id IS NULL OR p_approuver IS NULL OR p_cle IS NULL THEN
    RAISE EXCEPTION 'parametre de decision absent' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_reprise FROM public.reprises_foyer
  WHERE id = p_reprise_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'reprise introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_reprise.statut IN ('approuvee', 'refusee_admin') THEN
    IF v_reprise.cle_decision = p_cle THEN
      IF (v_reprise.statut = 'approuvee') IS DISTINCT FROM p_approuver THEN
        RAISE EXCEPTION 'cle idempotence reutilisee avec une decision differente'
          USING ERRCODE = '23505';
      END IF;
      RETURN pg_catalog.jsonb_build_object(
        'statut', 'deja_traitee', 'foyer_personnel_cree', v_reprise.foyer_personnel_id IS NOT NULL
      );
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_traitee', 'foyer_personnel_cree', false);
  END IF;
  IF v_reprise.examen_possible_le > pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_traitee', 'foyer_personnel_cree', false);
  END IF;

  IF p_approuver THEN
    INSERT INTO public.households (timezone, primary_guardian_id)
    SELECT h.timezone, v_reprise.demandeur_profile_id
    FROM public.households h WHERE h.id = v_reprise.household_id
    RETURNING id INTO v_personal_household_id;
    UPDATE public.profiles
      SET household_id = v_personal_household_id, updated_at = pg_catalog.now()
    WHERE id = v_reprise.demandeur_profile_id
      AND role = 'guardian' AND household_id = v_reprise.household_id
      AND deleted_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'demandeur absent du foyer ou non titulaire' USING ERRCODE = '42501';
    END IF;
    v_status := 'approuvee';
  ELSE
    v_status := 'refusee_admin';
  END IF;

  UPDATE public.reprises_foyer
  SET statut = v_status,
      decidee_par = auth.uid(), decidee_le = pg_catalog.now(), cle_decision = p_cle,
      foyer_personnel_id = v_personal_household_id,
      redepot_possible_le = CASE WHEN p_approuver THEN NULL
        ELSE pg_catalog.now() + interval '30 days' END
  WHERE id = p_reprise_id;
  PERFORM public.log_sensitive_access(
    'reprise_foyer_decidee', 'reprises_foyer', p_reprise_id::text,
    pg_catalog.jsonb_build_object('statut', v_status, 'demandeur_profile_id', v_reprise.demandeur_profile_id,
      'foyer_personnel_id', v_personal_household_id)
  );
  RETURN pg_catalog.jsonb_build_object(
    'statut', 'decidee', 'foyer_personnel_cree', v_personal_household_id IS NOT NULL
  );
END;
$function$;
ALTER FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid) TO authenticated;

COMMENT ON FUNCTION public.lister_reprises_admin() IS
  'F86 candidate allowlist: signature=public.lister_reprises_admin(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: only active admin can list open requests.';
COMMENT ON FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid) IS
  'F86 candidate allowlist: signature=public.decider_reprise_foyer(uuid, boolean, uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: admin-only, locked idempotent decision, audit and personal household creation.';
COMMENT ON FUNCTION public.deposer_reprise_foyer(uuid) IS
  'F86 candidate allowlist: signature=public.deposer_reprise_foyer(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: active second guardian only, one open request, retry idempotence.';
COMMENT ON FUNCTION public.refuser_reprise_foyer(uuid) IS
  'F86 candidate allowlist: signature=public.refuser_reprise_foyer(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: only captured household holder can refuse before admin decision.';
COMMENT ON FUNCTION public.etat_reprise_foyer() IS
  'F86 candidate allowlist: signature=public.etat_reprise_foyer(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: only active guardian sees own request/household holder state.';

DO $verification$
DECLARE
  v_signature text;
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.reprises_foyer'::regclass)
    OR has_table_privilege('anon', 'public.reprises_foyer', 'SELECT')
    OR has_table_privilege('authenticated', 'public.reprises_foyer', 'SELECT')
    OR has_table_privilege('service_role', 'public.reprises_foyer', 'SELECT')
    OR has_table_privilege('agent_ro', 'public.reprises_foyer', 'INSERT') THEN
    RAISE EXCEPTION 'B-04: RLS ou ACL de reprises_foyer invalide';
  END IF;
  FOREACH v_signature IN ARRAY ARRAY[
    'public.deposer_reprise_foyer(uuid)', 'public.refuser_reprise_foyer(uuid)',
    'public.etat_reprise_foyer()', 'public.lister_reprises_admin()',
    'public.decider_reprise_foyer(uuid, boolean, uuid)'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
      WHERE p.oid = pg_catalog.to_regprocedure(v_signature)
        AND p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
        AND p.proconfig @> ARRAY['search_path=""']
        AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
        AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
    ) THEN
      RAISE EXCEPTION 'B-04: controles SECURITY DEFINER incomplets pour %', v_signature;
    END IF;
  END LOOP;
END
$verification$;

COMMIT;
