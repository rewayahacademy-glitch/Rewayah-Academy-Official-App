BEGIN;

-- C-21: the verdict is an authenticated application capability, never a
-- service-role entry point. Revoke explicitly even if no inherited grant is
-- currently present, then assert the effective privileges.
REVOKE ALL ON FUNCTION public.verdict_acces_dossier_kyc(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.verdict_acces_dossier_kyc(uuid)
  TO authenticated;

DO $verification$
BEGIN
  IF NOT has_function_privilege(
       'authenticated', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
     )
     OR has_function_privilege(
       'anon', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
     )
     OR has_function_privilege(
       'service_role', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
     )
     OR has_function_privilege(
       'agent_ro', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C-21 ACL du verdict invalide';
  END IF;
END
$verification$;

COMMIT;
