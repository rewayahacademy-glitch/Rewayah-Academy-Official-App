BEGIN;

-- Normalize only the two line terminators introduced by the dollar-quoted SQL
-- wrapper. The stored text hash must cover the exact approved UTF-8 body.
UPDATE public.contract_texts
   SET body = pg_catalog.btrim(
         pg_catalog.replace(body, E'\r\n', E'\n'),
         E'\n'
       ),
       sha256 = pg_catalog.encode(
         extensions.digest(
           pg_catalog.convert_to(
             pg_catalog.btrim(
               pg_catalog.replace(body, E'\r\n', E'\n'),
               E'\n'
             ),
             'UTF8'
           ),
           'sha256'
         ),
         'hex'
       )
 WHERE contract_kind = 'teacher_nda'
   AND version = '2026-10-jur'
   AND locale = 'fr';

DO $verification$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.contract_texts
    WHERE contract_kind = 'teacher_nda'
      AND version = '2026-10-jur'
      AND locale = 'fr'
      AND is_current
      AND sha256 = '5114057583bd85a0988876867b752b63ff5f621c9e4784e61e7cb93168bb27df'
      AND sha256 = pg_catalog.encode(
        extensions.digest(pg_catalog.convert_to(body, 'UTF8'), 'sha256'),
        'hex'
      )
  ) THEN
    RAISE EXCEPTION 'F70: normalized contract body does not match approved SHA-256';
  END IF;
END;
$verification$;

-- Direct table inserts must obey the same identity and active-account guard as
-- the signing RPC. This also prevents guardians/admins from signing as a teacher.
DROP POLICY contract_acceptances_self_insert ON public.contract_acceptances;
CREATE POLICY contract_acceptances_self_insert
  ON public.contract_acceptances
  FOR INSERT TO authenticated
  WITH CHECK (
    profile_id = auth.uid()
    AND (
      contract_kind <> 'teacher_nda'
      OR (
        public.app_role() = 'teacher'::public.app_role
        AND public.app_account_valid()
        AND EXISTS (
          SELECT 1
          FROM public.contract_texts t
          WHERE t.contract_kind = 'teacher_nda'
            AND t.version = contract_acceptances.version
            AND t.locale = 'fr'
            AND t.is_current
        )
      )
    )
  );

CREATE OR REPLACE FUNCTION public.completer_contract_acceptance()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE
  v_texte public.contract_texts%rowtype;
BEGIN
  IF NEW.contract_kind <> 'teacher_nda' THEN
    NEW.signer_name := NULL;
    NEW.signed_sha256 := NULL;
    RETURN NEW;
  END IF;

  IF NOT coalesce(
    auth.uid() IS NOT NULL
    AND NEW.profile_id = auth.uid()
    AND public.app_role() = 'teacher'::public.app_role
    AND public.app_account_valid(),
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

DO $verification$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.completer_contract_acceptance()'::regprocedure
      AND p.prosecdef
  ) OR NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_trigger t
    WHERE t.tgrelid = 'public.contract_acceptances'::regclass
      AND t.tgname = 'contract_acceptances_complete_signature'
      AND NOT t.tgisinternal
  ) OR NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_policies p
    WHERE p.schemaname = 'public'
      AND p.tablename = 'contract_acceptances'
      AND p.policyname = 'contract_acceptances_self_insert'
      AND p.with_check LIKE '%app_role%'
      AND p.with_check LIKE '%app_account_valid%'
  ) THEN
    RAISE EXCEPTION 'F70: signature guard trigger postflight failed';
  END IF;
END;
$verification$;

COMMIT;
