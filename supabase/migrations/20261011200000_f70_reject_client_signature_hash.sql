BEGIN;

-- A client may request a signature, but its hash is always computed from the
-- current server-side contract text. Reject attempts to provide that hash.
CREATE OR REPLACE FUNCTION public.completer_contract_acceptance()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_texte public.contract_texts%rowtype;
BEGIN
  IF NEW.signed_sha256 IS NOT NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'empreinte_signature_fournie_par_client_interdite';
  END IF;

  IF NEW.contract_kind <> 'teacher_nda' THEN
    NEW.signer_name := NULL;
    NEW.signed_sha256 := NULL;
    RETURN NEW;
  END IF;

  IF NOT coalesce(
    auth.uid() IS NOT NULL
    AND NEW.profile_id = auth.uid()
    AND public.app_role() = 'teacher'::public.app_role
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'teacher'::public.app_role
        AND p.deleted_at IS NULL
        AND p.account_status IN (
          'pending_kyc'::public.account_status,
          'provisional_active'::public.account_status,
          'active'::public.account_status
        )
    ),
    false
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'acces_signature_refusee';
  END IF;

  IF NEW.signer_name IS NULL OR length(btrim(NEW.signer_name)) = 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'nom_vide';
  END IF;
  IF char_length(btrim(NEW.signer_name)) > 120 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'nom_trop_long';
  END IF;

  SELECT t.* INTO v_texte
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda'
    AND t.version = NEW.version
    AND t.locale = 'fr'
    AND t.is_current;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'contrat_version_non_courante';
  END IF;

  NEW.signer_name := btrim(NEW.signer_name);
  NEW.signed_sha256 := v_texte.sha256;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.completer_contract_acceptance()
  FROM PUBLIC, anon, authenticated, agent_ro;

DROP TRIGGER IF EXISTS contract_acceptances_complete_signature
  ON public.contract_acceptances;
CREATE TRIGGER contract_acceptances_complete_signature
BEFORE INSERT ON public.contract_acceptances
FOR EACH ROW
EXECUTE FUNCTION public.completer_contract_acceptance();

DO $verification$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.completer_contract_acceptance()'::regprocedure
      AND (p.prosecdef OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[])
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
    WHERE t.tgrelid = 'public.contract_acceptances'::regclass
      AND t.tgname = 'contract_acceptances_complete_signature'
      AND t.tgenabled <> 'D'
      AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'F70: signature hash rejection trigger postflight failed';
  END IF;
END;
$verification$;

COMMIT;
