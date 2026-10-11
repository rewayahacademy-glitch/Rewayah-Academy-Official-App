CREATE OR REPLACE FUNCTION public.completer_contract_acceptance()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
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
$function$

