-- F70: keep the signature-completion trigger function unavailable to every API role.
BEGIN;

REVOKE ALL ON FUNCTION public.completer_contract_acceptance()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $postflight$
BEGIN
  IF has_function_privilege(
       'anon', 'public.completer_contract_acceptance()', 'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated', 'public.completer_contract_acceptance()', 'EXECUTE'
     )
     OR has_function_privilege(
       'service_role', 'public.completer_contract_acceptance()', 'EXECUTE'
     )
     OR has_function_privilege(
       'agent_ro', 'public.completer_contract_acceptance()', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'F70: contract trigger function is directly executable';
  END IF;
END;
$postflight$;

COMMIT;
