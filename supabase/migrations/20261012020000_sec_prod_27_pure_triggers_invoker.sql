-- SEC-PROD-27: these trigger functions only validate OLD/NEW and must not
-- execute with the function owner's privileges.
ALTER FUNCTION public.guard_audit_logs_immutable() SECURITY INVOKER;
ALTER FUNCTION public.guard_contract_acceptances_immutable() SECURITY INVOKER;
ALTER FUNCTION public.guard_profile_immutable_id() SECURITY INVOKER;
ALTER FUNCTION public.guard_session_state_transition() SECURITY INVOKER;
ALTER FUNCTION public.guard_rule_override_immutable() SECURITY INVOKER;
ALTER FUNCTION public.guard_prayer_adjustments() SECURITY INVOKER;

DO $postflight$
DECLARE
  v_name text;
  v_proc record;
  v_expected text[] := ARRAY[
    'guard_audit_logs_immutable',
    'guard_contract_acceptances_immutable',
    'guard_profile_immutable_id',
    'guard_session_state_transition',
    'guard_rule_override_immutable',
    'guard_prayer_adjustments'
  ];
BEGIN
  FOREACH v_name IN ARRAY v_expected LOOP
    SELECT p.prosecdef, p.prorettype, p.prokind
    INTO v_proc
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = v_name
      AND p.pronargs = 0;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'SEC-PROD-27: signature absente: public.%()', v_name;
    END IF;
    IF v_proc.prosecdef THEN
      RAISE EXCEPTION 'SEC-PROD-27: SECURITY DEFINER persiste: public.%()', v_name;
    END IF;
    IF v_proc.prorettype <> 'trigger'::pg_catalog.regtype OR v_proc.prokind <> 'f' THEN
      RAISE EXCEPTION 'SEC-PROD-27: fonction trigger inattendue: public.%()', v_name;
    END IF;
  END LOOP;
END
$postflight$;
