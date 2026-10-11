BEGIN;

-- C-21 returns one closed access verdict for auth.uid() and the requested
-- profile. It never returns KYC rows, storage keys, or signed URLs.
CREATE OR REPLACE FUNCTION public.verdict_acces_dossier_kyc(p_profile_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_reader_gender public.gender;
  v_document_gender public.gender;
  v_exception boolean;
BEGIN
  IF NOT coalesce(
       public.app_role() = 'admin' AND public.app_account_valid(), false
     ) THEN
    RAISE EXCEPTION 'verdict KYC reserve a l''administration'
      USING errcode = '42501';
  END IF;

  IF p_profile_id IS NULL THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  SELECT p.gender INTO v_reader_gender
  FROM public.profiles p
  WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  SELECT k.gender INTO v_document_gender
  FROM public.kyc_documents k
  WHERE k.profile_id = p_profile_id AND k.deleted_at IS NULL
  ORDER BY k.created_at DESC, k.id
  LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  IF v_reader_gender IS NOT NULL AND v_reader_gender = v_document_gender THEN
    RETURN jsonb_build_object('type', 'memeGenre');
  END IF;

  v_exception := public.ma_exception_kyc_active();
  IF v_exception THEN
    RETURN jsonb_build_object('type', 'exceptionSuperAdmin');
  END IF;
  IF v_reader_gender IS NULL THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'adminSansGenre');
  END IF;
  RETURN jsonb_build_object('type', 'refus', 'raison', 'genreDifferent');
END;
$function$;
ALTER FUNCTION public.verdict_acces_dossier_kyc(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.verdict_acces_dossier_kyc(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.verdict_acces_dossier_kyc(uuid)
  TO authenticated;

-- F79 candidate; verify the MD5 against pg_proc.prosrc during PG17 replay.
COMMENT ON FUNCTION public.verdict_acces_dossier_kyc(uuid) IS
  'F79 candidate allowlist: signature=public.verdict_acces_dossier_kyc(uuid); '
  'md5_prosrc=4b82f7bec87839e2f60d6983fb23085d; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; '
  'search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: '
  'only valid admins; same-gender verdict; null-gender admin denied unless '
  'enabled super-admin; cross-gender verdict only for enabled super-admin; '
  'missing/deleted dossier returns only profilNonAutorise; no document metadata '
  'or audit side effect; controller cannot execute the verdict.';

DO $verification$
BEGIN
  IF to_regprocedure('public.verdict_acces_dossier_kyc(uuid)') IS NULL
    OR NOT has_function_privilege(
      'authenticated', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
    )
    OR has_function_privilege(
      'anon', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
    )
    OR has_function_privilege(
      'agent_ro', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
    )
    OR NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
      WHERE p.oid = to_regprocedure('public.verdict_acces_dossier_kyc(uuid)')
        AND p.prosecdef
        AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
        AND p.proconfig @> ARRAY['search_path=""']
    )
  THEN
    RAISE EXCEPTION '0089 controle du verdict KYC incomplet';
  END IF;
END
$verification$;

COMMIT;
