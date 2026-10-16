BEGIN;

-- AF L1-05 (P1-1): decider_dossier refuse une seconde decision et, au rejet
-- d'un enseignant (teacher_profiles existe) sans autre piece approuvee, passe
-- son compte a 'disabled'. Le compte 'disabled' est la valeur de
-- public.account_status qui signifie suspendu (0001_fondations.sql).
-- Corps reecrit depuis 20261012100600_f86_kyc_decision_guard.sql ; la signature
-- et les droits restent identiques.
CREATE OR REPLACE FUNCTION public.decider_dossier(
  p_document_id uuid,
  p_approuve boolean,
  p_motif text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_doc public.kyc_documents;
  v_acces_retire boolean;
  v_n integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'seul un administrateur decide d''un dossier';
  END IF;

  IF NOT p_approuve AND coalesce(btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'un refus exige un motif';
  END IF;

  SELECT * INTO v_doc FROM public.read_kyc_documents() k WHERE k.id = p_document_id;
  IF v_doc.id IS NULL THEN
    RAISE EXCEPTION 'dossier introuvable ou hors du perimetre de lecture';
  END IF;

  IF v_doc.status <> 'pending' THEN
    RAISE EXCEPTION 'dossier déjà décidé' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.kyc_documents
  SET status = CASE WHEN p_approuve THEN 'approved'::public.kyc_doc_status
                    ELSE 'rejected'::public.kyc_doc_status END,
      rejection_reason = CASE WHEN p_approuve THEN NULL ELSE btrim(p_motif) END,
      verified_by = auth.uid(),
      verified_at = now()
  WHERE id = p_document_id;

  v_acces_retire := false;
  IF p_approuve THEN
    UPDATE public.profiles
    SET account_status = 'active', updated_at = now()
    WHERE id = v_doc.profile_id AND account_status = 'pending_kyc';
  ELSIF EXISTS (SELECT 1 FROM public.teacher_profiles tp WHERE tp.profile_id = v_doc.profile_id)
    AND NOT EXISTS (
      SELECT 1 FROM public.kyc_documents k
       WHERE k.profile_id = v_doc.profile_id AND k.id <> p_document_id AND k.status = 'approved'
    ) THEN
    UPDATE public.profiles
    SET account_status = 'disabled', updated_at = now()
    WHERE id = v_doc.profile_id AND account_status IN ('active', 'provisional_active');
    GET DIAGNOSTICS v_n = ROW_COUNT;
    v_acces_retire := v_n > 0;
  END IF;

  UPDATE public.teacher_profiles
  SET kyc_status = CASE WHEN p_approuve THEN 'approved' ELSE 'rejected' END
  WHERE profile_id = v_doc.profile_id;

  PERFORM public.log_sensitive_access('kyc_decision', 'kyc_documents', p_document_id::text,
    jsonb_build_object('approuve', p_approuve, 'motif', btrim(coalesce(p_motif, '')),
                       'acces_retire', v_acces_retire));
END;
$function$;
ALTER FUNCTION public.decider_dossier(uuid,boolean,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.decider_dossier(uuid,boolean,text)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.decider_dossier(uuid,boolean,text) TO authenticated;
COMMENT ON FUNCTION public.decider_dossier(uuid,boolean,text) IS
  'F86 candidate allowlist: signature=public.decider_dossier(uuid,boolean,text); md5_functiondef=01e53ff2ca89301b14947ea260c6212a; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17; L1-05: une seule decision, acces retire au rejet d un enseignant sans autre piece approuvee.';

DO $postflight$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_catalog.pg_roles r ON r.oid=p.proowner
  WHERE n.nspname='public' AND p.proname='decider_dossier'
    AND pg_catalog.pg_get_function_identity_arguments(p.oid)='p_document_id uuid, p_approuve boolean, p_motif text'
    AND p.prosecdef AND r.rolname='postgres'
    AND 'search_path=""'=ANY(coalesce(p.proconfig,ARRAY[]::text[]))
    AND NOT pg_catalog.has_function_privilege('anon',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('service_role',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('agent_ro',p.oid,'EXECUTE')
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'NOT COALESCE')>0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'APP_ACCOUNT_VALID')>0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'APP_ROLE')>0
    AND pg_catalog.strpos(p.prosrc,'dossier déjà décidé')>0;
  IF v_count<>1 THEN RAISE EXCEPTION 'F86 KYC guard postflight failed'; END IF;
END;
$postflight$;

COMMIT;
