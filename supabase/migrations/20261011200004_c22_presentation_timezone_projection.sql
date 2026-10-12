BEGIN;

-- C-22: derive the household and its timezone from auth.uid(), never from a
-- client supplied household id. Return both the UTC instant and wall time.
CREATE OR REPLACE FUNCTION public.lire_demandes_presentation_en_attente_avec_fuseau()
RETURNS TABLE (
  id uuid,
  eleve_id uuid,
  eleve_prenom text,
  cree_le_utc timestamptz,
  heure_foyer timestamp without time zone,
  fuseau_iana text
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'guardian', false
  ) THEN
    RAISE EXCEPTION 'lecture reservee au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT d.id, d.eleve_id, student.first_name, d.cree_le,
         d.cree_le AT TIME ZONE h.timezone, h.timezone
  FROM public.demandes_presentation d
  JOIN public.profiles guardian ON guardian.id = auth.uid()
  JOIN public.households h ON h.id = guardian.household_id
  JOIN public.profiles student ON student.id = d.eleve_id
  WHERE guardian.role = 'guardian'
    AND guardian.deleted_at IS NULL
    AND h.status = 'active'
    AND h.deleted_at IS NULL
    AND d.foyer_id = guardian.household_id
    AND d.statut = 'en_attente'
    AND student.deleted_at IS NULL
    AND student.household_id = guardian.household_id
  ORDER BY d.cree_le, d.id;
END;
$function$;
ALTER FUNCTION public.lire_demandes_presentation_en_attente_avec_fuseau()
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lire_demandes_presentation_en_attente_avec_fuseau()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_demandes_presentation_en_attente_avec_fuseau()
  TO authenticated;

COMMENT ON FUNCTION public.lire_demandes_presentation_en_attente_avec_fuseau() IS
  'F86 candidate allowlist: signature=public.lire_demandes_presentation_en_attente_avec_fuseau(); md5_functiondef=835b2ae3c64ccb94a1fd0ad20532005b; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: active guardian reads only their household presentation requests with UTC instant and household IANA timezone; other roles and service_role cannot execute.';

-- Keep the pre-C22 RPC safe too: older clients may still call it.
CREATE OR REPLACE FUNCTION public.lire_demandes_presentation_en_attente()
RETURNS TABLE (
  id uuid,
  eleve_id uuid,
  eleve_prenom text,
  cree_le timestamptz
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'guardian', false
  ) THEN
    RAISE EXCEPTION 'lecture reservee au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT d.id, d.eleve_id, student.first_name, d.cree_le
  FROM public.demandes_presentation d
  JOIN public.profiles guardian ON guardian.id = auth.uid()
  JOIN public.households h ON h.id = guardian.household_id
  JOIN public.profiles student ON student.id = d.eleve_id
  WHERE guardian.role = 'guardian'
    AND guardian.deleted_at IS NULL
    AND h.status = 'active'
    AND h.deleted_at IS NULL
    AND d.foyer_id = guardian.household_id
    AND d.statut = 'en_attente'
    AND student.deleted_at IS NULL
    AND student.household_id = guardian.household_id
  ORDER BY d.cree_le, d.id;
END;
$function$;
ALTER FUNCTION public.lire_demandes_presentation_en_attente() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lire_demandes_presentation_en_attente()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_demandes_presentation_en_attente()
  TO authenticated;
COMMENT ON FUNCTION public.lire_demandes_presentation_en_attente() IS
  'F86 candidate allowlist: signature=public.lire_demandes_presentation_en_attente(); md5_functiondef=19bcb857fe79a77a7a0a3461d5472fc7; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: legacy guardian projection excludes requests whose student household has changed.';

DO $verification$
DECLARE
  v_definition text;
  v_legacy_definition text;
BEGIN
  SELECT pg_catalog.pg_get_functiondef(
    'public.lire_demandes_presentation_en_attente_avec_fuseau()'::regprocedure
  ) INTO v_definition;
  SELECT pg_catalog.pg_get_functiondef(
    'public.lire_demandes_presentation_en_attente()'::regprocedure
  ) INTO v_legacy_definition;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.lire_demandes_presentation_en_attente_avec_fuseau()'::regprocedure
         AND p.prosecdef
         AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
         AND p.proconfig @> ARRAY['search_path=""']
     )
     OR v_definition NOT LIKE '%public.app_role() = ''guardian''%'
     OR v_definition NOT LIKE '%public.app_account_valid()%'
     OR NOT has_function_privilege(
       'authenticated', 'public.lire_demandes_presentation_en_attente_avec_fuseau()', 'EXECUTE'
     )
     OR has_function_privilege(
       'anon', 'public.lire_demandes_presentation_en_attente_avec_fuseau()', 'EXECUTE'
     )
     OR has_function_privilege(
       'service_role', 'public.lire_demandes_presentation_en_attente_avec_fuseau()', 'EXECUTE'
     )
     OR has_function_privilege(
       'agent_ro', 'public.lire_demandes_presentation_en_attente_avec_fuseau()', 'EXECUTE'
     )
     OR v_legacy_definition NOT LIKE '%student.household_id = guardian.household_id%'
     OR NOT has_function_privilege(
       'authenticated', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE'
     )
     OR has_function_privilege(
       'anon', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE'
     )
     OR has_function_privilege(
       'service_role', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE'
     )
     OR has_function_privilege(
       'agent_ro', 'public.lire_demandes_presentation_en_attente()', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C-22 projection fuseau, garde ou ACL invalide';
  END IF;
END
$verification$;

COMMIT;
