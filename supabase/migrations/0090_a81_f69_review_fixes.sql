BEGIN;

-- A81: une capacite personnelle n'est visible qu'a un compte dont l'acces est
-- encore valide. L'identite reste auth.uid(); aucun identifiant client n'entre.
CREATE OR REPLACE FUNCTION public.ma_capacite_eleve()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce(public.app_account_valid(), false) AND EXISTS (
    SELECT 1 FROM public.student_profiles sp
    WHERE sp.profile_id = auth.uid()
      AND sp.student_type = 'autonomous'
      AND sp.deleted_at IS NULL
  );
$function$;
ALTER FUNCTION public.ma_capacite_eleve() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.ma_capacite_eleve()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_capacite_eleve() TO authenticated;

-- F69: l'indicateur de l'exception est consultable par l'administration
-- connectee uniquement. Les utilisateurs ne peuvent pas verifier l'etat d'un
-- autre administrateur.
CREATE OR REPLACE FUNCTION public.ma_exception_kyc_active()
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'acces KYC refuse' USING errcode = '42501';
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM private.super_admin_kyc s
    WHERE s.profile_id = auth.uid()
  ) AND EXISTS (
    SELECT 1 FROM public.app_config c
    WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb
  );
END;
$function$;
ALTER FUNCTION public.ma_exception_kyc_active() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.ma_exception_kyc_active()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_exception_kyc_active() TO authenticated;

-- F69: un appel a la liste produit un evenement d'audit, quel que soit le
-- nombre de documents retournes. L'ouverture d'une piece garde son audit
-- detaille dans autoriser_lecture_piece_identite().
CREATE OR REPLACE FUNCTION public.read_kyc_documents()
RETURNS SETOF public.kyc_documents
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_gender public.gender;
  v_exception boolean;
  v_count integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'acces KYC refuse' USING errcode = '42501';
  END IF;

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  v_exception := public.kyc_super_admin_exception_active();
  IF v_gender IS NULL AND NOT v_exception THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier'
      USING errcode = '42501';
  END IF;

  SELECT count(*)::integer INTO v_count
  FROM public.kyc_documents k
  WHERE k.deleted_at IS NULL AND (v_exception OR k.gender = v_gender);

  PERFORM public.log_sensitive_access(
    'kyc_read', 'kyc_documents', NULL,
    jsonb_build_object(
      'reader_gender', v_gender,
      'exception_active', v_exception,
      'document_count', v_count
    )
  );

  RETURN QUERY
    SELECT k.* FROM public.kyc_documents k
    WHERE k.deleted_at IS NULL AND (v_exception OR k.gender = v_gender);
END;
$function$;
ALTER FUNCTION public.read_kyc_documents() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.read_kyc_documents()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.read_kyc_documents() TO authenticated;

-- F79 candidate entries; MD5 is over the function source in this migration.
-- Confirm against pg_proc.prosrc on the disposable PG17 replay before review.
-- public.ma_exception_kyc_active() | f43db4cade433fce1c42f31c798c0b61 | ROLE_POSITIVE_TEMPLATE | postgres | search_path='' | Claude à relire | 2026-10-11
-- public.read_kyc_documents()      | 3cb899d0effdce4ff10256db9b5e576c | ROLE_POSITIVE_TEMPLATE | postgres | search_path='' | Claude à relire | 2026-10-11
-- public.ma_capacite_eleve()       | fe3930f28344f8730505cecd475c471f | NO_GUARD_HELPER: returns only auth.uid() capability, gated by app_account_valid() | postgres | search_path='' | Claude à relire | 2026-10-11

DO $verification$
DECLARE
  v_signature text;
BEGIN
  IF to_regprocedure('public.ma_capacite_eleve()') IS NULL
    OR to_regprocedure('public.ma_exception_kyc_active()') IS NULL
    OR has_function_privilege('anon', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR has_function_privilege('anon', 'public.ma_exception_kyc_active()', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.ma_exception_kyc_active()', 'EXECUTE')
    OR has_function_privilege('anon', 'public.read_kyc_documents()', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'EXECUTE')
    OR NOT has_function_privilege('authenticated', 'public.ma_capacite_eleve()', 'EXECUTE')
    OR NOT has_function_privilege('authenticated', 'public.ma_exception_kyc_active()', 'EXECUTE')
    OR NOT has_function_privilege('authenticated', 'public.read_kyc_documents()', 'EXECUTE')
  THEN
    RAISE EXCEPTION '0088 ACL ou fonctions A81/F69 incompletes';
  END IF;
  FOREACH v_signature IN ARRAY ARRAY[
    'public.ma_capacite_eleve()',
    'public.ma_exception_kyc_active()',
    'public.read_kyc_documents()'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_proc p
      WHERE p.oid = to_regprocedure(v_signature)
        AND p.prosecdef
        AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
        AND p.proconfig @> ARRAY['search_path=""']
    ) THEN
      RAISE EXCEPTION '0088 proprietaire, SECURITY DEFINER ou search_path invalide: %', v_signature;
    END IF;
  END LOOP;
END;
$verification$;

COMMIT;
