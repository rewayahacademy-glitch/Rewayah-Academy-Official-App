BEGIN;

-- Version requise pour le recu de traitement audio/visites. Le contrat
-- enseignant lui-meme prend sa version courante dans contract_texts.
CREATE TABLE public.contract_required_versions (
  contract_kind text PRIMARY KEY CHECK (
    contract_kind = 'recording_and_control_notice'
  ),
  version text NOT NULL CHECK (length(version) BETWEEN 1 AND 80),
  changed_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.contract_required_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY contract_required_versions_admin_read
  ON public.contract_required_versions FOR SELECT TO authenticated
  USING (public.app_role() = 'admin'::public.app_role);
GRANT SELECT ON TABLE public.contract_required_versions TO authenticated;
REVOKE ALL ON TABLE public.contract_required_versions
  FROM PUBLIC, anon, service_role, agent_ro;
INSERT INTO public.contract_required_versions (contract_kind, version)
VALUES ('recording_and_control_notice', '2026-10-jur');

-- Garde centralisee sur toute transition d'un compte enseignant vers active,
-- quelle que soit la voie d'administration qui effectue la transition.
CREATE FUNCTION public.guard_teacher_activation_signatures()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE
  v_teacher_version text;
  v_teacher_hash text;
  v_notice_version text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.role = 'teacher'::public.app_role
     AND OLD.account_status = 'active'::public.account_status THEN
    RETURN NEW;
  END IF;
  IF NEW.role <> 'teacher'::public.app_role
     OR NEW.account_status <> 'active'::public.account_status THEN
    RETURN NEW;
  END IF;

  SELECT t.version, t.sha256 INTO v_teacher_version, v_teacher_hash
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda'
    AND t.locale = 'fr'
    AND t.is_current;
  IF v_teacher_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'teacher_nda'
      AND c.version = v_teacher_version
      AND c.signed_sha256 = v_teacher_hash
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:teacher_nda';
  END IF;

  SELECT r.version INTO v_notice_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'recording_and_control_notice';
  IF v_notice_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'recording_and_control_notice'
      AND c.version = v_notice_version
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:recording_and_control_notice';
  END IF;

  RETURN NEW;
END;
$function$;
ALTER FUNCTION public.guard_teacher_activation_signatures() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.guard_teacher_activation_signatures()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER profiles_guard_teacher_activation_signatures
BEFORE INSERT OR UPDATE OF role, account_status ON public.profiles
FOR EACH ROW
WHEN (NEW.account_status = 'active'::public.account_status)
EXECUTE FUNCTION public.guard_teacher_activation_signatures();

-- Statuts destines a l'administration. Les versions sont calculees ici,
-- jamais comparees a une constante cote client. Les politiques RLS existantes
-- autorisent les lectures necessaires a l'administrateur; la fonction reste
-- invoker conformement au gate F79.
CREATE FUNCTION public.teacher_signature_statuses(p_profile_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE
  v_teacher_version text;
  v_teacher_signed text;
  v_notice_version text;
  v_notice_signed text;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin'::public.app_role
      AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'admin_required';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id AND p.role = 'teacher'::public.app_role
      AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'teacher_profile_not_found';
  END IF;

  SELECT t.version INTO v_teacher_version
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current;
  SELECT c.version INTO v_teacher_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id AND c.contract_kind = 'teacher_nda'
  ORDER BY c.accepted_at DESC LIMIT 1;

  SELECT r.version INTO v_notice_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'recording_and_control_notice';
  SELECT c.version INTO v_notice_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id
    AND c.contract_kind = 'recording_and_control_notice'
  ORDER BY c.accepted_at DESC LIMIT 1;

  RETURN jsonb_build_object(
    'contrat', jsonb_build_object(
      'status', CASE
        WHEN v_teacher_signed IS NULL THEN 'non_signe'
        WHEN v_teacher_version IS NOT NULL AND v_teacher_signed = v_teacher_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_teacher_signed,
      'version_courante', v_teacher_version
    ),
    'accuse', jsonb_build_object(
      'status', CASE
        WHEN v_notice_signed IS NULL THEN 'non_signe'
        WHEN v_notice_version IS NOT NULL AND v_notice_signed = v_notice_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_notice_signed,
      'version_courante', v_notice_version
    )
  );
END;
$function$;
ALTER FUNCTION public.teacher_signature_statuses(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.teacher_signature_statuses(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.teacher_signature_statuses(uuid) TO authenticated;

DO $verification$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
    WHERE t.tgrelid = 'public.profiles'::regclass
      AND t.tgname = 'profiles_guard_teacher_activation_signatures'
      AND NOT t.tgisinternal
      AND (t.tgtype & 20) = 20
  ) OR has_function_privilege(
    'anon', 'public.teacher_signature_statuses(uuid)', 'EXECUTE'
  ) OR has_function_privilege(
    'agent_ro', 'public.teacher_signature_statuses(uuid)', 'EXECUTE'
  ) OR NOT has_function_privilege(
    'authenticated', 'public.teacher_signature_statuses(uuid)', 'EXECUTE'
  ) OR NOT has_table_privilege(
    'authenticated', 'public.contract_required_versions', 'SELECT'
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid IN (
      'public.guard_teacher_activation_signatures()'::regprocedure,
      'public.teacher_signature_statuses(uuid)'::regprocedure
    ) AND p.prosecdef
  ) OR EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_roles r ON r.oid = p.proowner
    WHERE p.oid IN (
      'public.guard_teacher_activation_signatures()'::regprocedure,
      'public.teacher_signature_statuses(uuid)'::regprocedure
    ) AND (
      r.rolname <> 'postgres'
      OR NOT (COALESCE(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""'])
    )
  ) THEN
    RAISE EXCEPTION '0079 teacher contract activation guard postflight failed';
  END IF;
END;
$verification$;

COMMIT;
