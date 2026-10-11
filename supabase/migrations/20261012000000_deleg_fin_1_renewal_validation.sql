BEGIN;

-- Keep cash caps structurally valid even when an administrator writes through
-- the RPC. Both amount objects use the public contract {mineur, devise}.
CREATE FUNCTION private.finance_delegation_cap_amount_valid(
  p_amount jsonb, p_general_currency text
) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = ''
AS $function$
  SELECT CASE
    WHEN p_amount IS NULL THEN false
    WHEN p_amount = 'null'::jsonb THEN true
    WHEN pg_catalog.jsonb_typeof(p_amount) <> 'object' THEN false
    WHEN (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(p_amount)) <> 2 THEN false
    WHEN NOT (p_amount ?& ARRAY['mineur','devise']) THEN false
    WHEN p_amount->>'devise' !~ '^[A-Z]{3}$' THEN false
    WHEN p_general_currency IS NULL OR p_amount->>'devise' <> p_general_currency THEN false
    WHEN pg_catalog.jsonb_typeof(p_amount->'mineur') <> 'number' THEN false
    WHEN p_amount->>'mineur' !~ '^(0|[1-9][0-9]*)$' THEN false
    ELSE (p_amount->>'mineur')::numeric <= 9223372036854775807
  END
$function$;

CREATE FUNCTION private.finance_delegation_caps_valid(p_policy jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path = ''
AS $function$
  SELECT CASE
    WHEN p_policy IS NULL THEN false
    WHEN pg_catalog.jsonb_typeof(p_policy) <> 'object' THEN false
    WHEN NOT (p_policy ?& ARRAY['plafond_par_transaction','plafond_par_lot','plafond_par_periode']) THEN false
    WHEN p_policy->'plafond_par_transaction' IS NULL
      OR p_policy->'plafond_par_transaction' = 'null'::jsonb THEN
      private.finance_delegation_cap_amount_valid(p_policy->'plafond_par_lot',NULL)
      AND private.finance_delegation_cap_amount_valid(p_policy->'plafond_par_periode',NULL)
    WHEN pg_catalog.jsonb_typeof(p_policy->'plafond_par_transaction') <> 'object' THEN false
    WHEN (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(
      p_policy->'plafond_par_transaction')) > 1 THEN false
    WHEN EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_policy->'plafond_par_transaction') cap
      WHERE cap.key !~ '^[A-Z]{3}$'
        OR pg_catalog.jsonb_typeof(cap.value) <> 'number'
        OR cap.value::text !~ '^(0|[1-9][0-9]*)$'
        OR cap.value::text::numeric > 9223372036854775807) THEN false
    ELSE
      private.finance_delegation_cap_amount_valid(p_policy->'plafond_par_lot',
        (SELECT cap.key FROM pg_catalog.jsonb_each(p_policy->'plafond_par_transaction') cap LIMIT 1))
      AND private.finance_delegation_cap_amount_valid(p_policy->'plafond_par_periode',
        (SELECT cap.key FROM pg_catalog.jsonb_each(p_policy->'plafond_par_transaction') cap LIMIT 1))
  END
$function$;

ALTER TABLE public.finance_delegation
  ADD CONSTRAINT finance_delegation_amount_caps_valid
  CHECK (private.finance_delegation_caps_valid(politique));

CREATE OR REPLACE FUNCTION public.renouveler_delegation_finance(p_cle uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v public.finance_delegation%ROWTYPE; v_actor uuid:=auth.uid();
  v_expiration timestamptz;
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  IF p_cle IS NULL THEN RAISE EXCEPTION 'cle requise' USING ERRCODE='22023'; END IF;
  SELECT * INTO v FROM public.finance_delegation WHERE cle_globale='global' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'delegation absente' USING ERRCODE='P0002'; END IF;
  IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
    AND j.cle_idempotence=p_cle) THEN
    IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
      AND j.cle_idempotence=p_cle AND j.action='renouvellement') THEN
      RETURN public.lire_delegation_finance();
    END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee' USING ERRCODE='22023';
  END IF;
  v_expiration:=GREATEST(v.expire_le,pg_catalog.clock_timestamp())+interval '90 days';
  UPDATE public.finance_delegation SET expire_le=v_expiration,version=version+1,
    modifiee_par=v_actor,modifiee_le=pg_catalog.clock_timestamp() WHERE id=v.id;
  INSERT INTO public.finance_delegation_journal(delegation_id,acteur_id,cle_idempotence,
    action,payload) VALUES(v.id,v_actor,p_cle,'renouvellement',pg_catalog.jsonb_build_object(
      'ancien_etat',CASE WHEN v.expire_le<=pg_catalog.clock_timestamp() THEN 'expiree' ELSE v.etat END,
      'nouvel_etat',v.etat,'ancienne_expiration',v.expire_le,'nouvelle_expiration',v_expiration));
  RETURN public.lire_delegation_finance();
END;
$function$;
ALTER FUNCTION public.renouveler_delegation_finance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.renouveler_delegation_finance(uuid) FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.renouveler_delegation_finance(uuid) TO authenticated;
COMMENT ON FUNCTION public.renouveler_delegation_finance(uuid) IS
  'F86 candidate allowlist: signature=public.renouveler_delegation_finance(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

COMMIT;
