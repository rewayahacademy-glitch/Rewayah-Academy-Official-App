-- B-04 follow-up: a titulaire refusal closes the request; only an admin may
-- decide requests that remain unanswered. Both refusal paths start 30 days.
BEGIN;

DROP INDEX public.reprises_foyer_une_ouverte_par_foyer;
CREATE UNIQUE INDEX reprises_foyer_une_ouverte_par_foyer
  ON public.reprises_foyer (household_id)
  WHERE statut = 'a_examiner';

CREATE OR REPLACE FUNCTION public.deposer_reprise_foyer(p_cle uuid)
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
      WHERE r.household_id = v_household AND r.statut = 'a_examiner') THEN
    RAISE EXCEPTION 'une demande de reprise est deja ouverte' USING ERRCODE = '23505';
  END IF;
  IF EXISTS (SELECT 1 FROM public.reprises_foyer r
      WHERE r.household_id = v_household
        AND r.statut IN ('refusee_par_titulaire', 'refusee_admin')
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

CREATE OR REPLACE FUNCTION public.refuser_reprise_foyer(p_cle uuid)
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
  IF v_reprise.statut = 'refusee_par_titulaire' THEN
    IF v_reprise.cle_refus = p_cle THEN
      RETURN pg_catalog.jsonb_build_object('statut', 'enregistree');
    END IF;
    RAISE EXCEPTION 'demande deja refusee par le titulaire' USING ERRCODE = '23505';
  END IF;
  UPDATE public.reprises_foyer
  SET statut = 'refusee_par_titulaire', cle_refus = p_cle,
      redepot_possible_le = pg_catalog.now() + interval '30 days'
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

CREATE OR REPLACE FUNCTION public.lister_reprises_admin()
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
         (r.statut = 'a_examiner' AND r.examen_possible_le <= pg_catalog.now()),
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

CREATE OR REPLACE FUNCTION public.decider_reprise_foyer(
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
    IF v_reprise.cle_decision = p_cle
      AND (v_reprise.statut = 'approuvee') IS DISTINCT FROM p_approuver THEN
      RAISE EXCEPTION 'cle idempotence reutilisee avec une decision differente'
        USING ERRCODE = '23505';
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_traitee',
      'foyer_personnel_cree', v_reprise.foyer_personnel_id IS NOT NULL);
  END IF;
  IF v_reprise.statut <> 'a_examiner'
    OR v_reprise.examen_possible_le > pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_traitee', 'foyer_personnel_cree', false);
  END IF;
  IF p_approuver THEN
    INSERT INTO public.households (timezone, primary_guardian_id)
    SELECT h.timezone, v_reprise.demandeur_profile_id
    FROM public.households h WHERE h.id = v_reprise.household_id
    RETURNING id INTO v_personal_household_id;
    UPDATE public.profiles
      SET household_id = v_personal_household_id, updated_at = pg_catalog.now()
    WHERE id = v_reprise.demandeur_profile_id AND role = 'guardian'
      AND household_id = v_reprise.household_id AND deleted_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'demandeur absent du foyer ou non guardian' USING ERRCODE = '42501';
    END IF;
    v_status := 'approuvee';
  ELSE
    v_status := 'refusee_admin';
  END IF;
  UPDATE public.reprises_foyer
  SET statut = v_status, decidee_par = auth.uid(), decidee_le = pg_catalog.now(),
      cle_decision = p_cle, foyer_personnel_id = v_personal_household_id,
      redepot_possible_le = CASE WHEN p_approuver THEN NULL
        ELSE pg_catalog.now() + interval '30 days' END
  WHERE id = p_reprise_id;
  PERFORM public.log_sensitive_access('reprise_foyer_decidee', 'reprises_foyer', p_reprise_id::text,
    pg_catalog.jsonb_build_object('statut', v_status,
      'demandeur_profile_id', v_reprise.demandeur_profile_id,
      'foyer_personnel_id', v_personal_household_id));
  RETURN pg_catalog.jsonb_build_object('statut', 'decidee',
    'foyer_personnel_cree', v_personal_household_id IS NOT NULL);
END;
$function$;
ALTER FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid) TO authenticated;

COMMENT ON FUNCTION public.deposer_reprise_foyer(uuid) IS
  'F86 allowlist: signature=public.deposer_reprise_foyer(uuid); md5=A_CALCULER; classification=ROLE_POSITIVE_TEMPLATE; must-pass=single open request and 30-day wait after either refusal.';
COMMENT ON FUNCTION public.refuser_reprise_foyer(uuid) IS
  'F86 allowlist: signature=public.refuser_reprise_foyer(uuid); md5=A_CALCULER; classification=ROLE_POSITIVE_TEMPLATE; must-pass=holder refusal closes request and starts 30-day wait.';
COMMENT ON FUNCTION public.lister_reprises_admin() IS
  'F86 allowlist: signature=public.lister_reprises_admin(); md5=A_CALCULER; classification=ROLE_POSITIVE_TEMPLATE; must-pass=admin-only; holder-refused rows are non-decidable.';
COMMENT ON FUNCTION public.decider_reprise_foyer(uuid, boolean, uuid) IS
  'F86 allowlist: signature=public.decider_reprise_foyer(uuid, boolean, uuid); md5=A_CALCULER; classification=ROLE_POSITIVE_TEMPLATE; must-pass=only unanswered requests can be decided; locked idempotent decision and audit.';

COMMIT;
