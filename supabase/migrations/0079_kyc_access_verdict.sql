-- C-21 : verdict de portee KYC sans lecture de la piece ni effet d'audit.
-- L'ouverture reste exclusivement dans autoriser_lecture_piece_identite().
BEGIN;

CREATE OR REPLACE FUNCTION public.verdict_acces_dossier_kyc(p_profile_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_gender public.gender;
  v_piece_gender public.gender;
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

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  SELECT k.gender INTO v_piece_gender
  FROM public.kyc_documents k
  WHERE k.profile_id = p_profile_id AND k.deleted_at IS NULL
  ORDER BY k.created_at DESC, k.id
  LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  v_exception := public.kyc_super_admin_exception_active();
  IF v_gender IS NOT NULL AND v_gender = v_piece_gender THEN
    RETURN jsonb_build_object('type', 'memeGenre');
  END IF;
  IF v_exception THEN
    RETURN jsonb_build_object('type', 'exceptionSuperAdmin');
  END IF;
  IF v_gender IS NULL THEN
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

COMMENT ON FUNCTION public.verdict_acces_dossier_kyc(uuid) IS
  'F79 candidate allowlist: signature=public.verdict_acces_dossier_kyc(uuid); '
  'md5_prosrc=2b467cd3363c49316932828981a826f9; '
  'guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; '
  'reviewer=Claude à relire; date=2026-10-11. Must-pass: controller denied; '
  'same gender; missing reader gender denied unless enabled super-admin '
  'exception; cross-gender exception verdict; missing/deleted dossier denied; '
  'no object key or document fields returned. Audit only on open.';

DO $verification$
BEGIN
  IF NOT has_function_privilege(
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
       JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'public'
         AND p.proname = 'verdict_acces_dossier_kyc'
         AND p.prosecdef
         AND p.proowner = 'postgres'::regrole
         AND p.proconfig @> ARRAY['search_path=""']
     )
  THEN RAISE EXCEPTION '0079 controles verdict KYC incomplets'; END IF;
END
$verification$;

COMMIT;
