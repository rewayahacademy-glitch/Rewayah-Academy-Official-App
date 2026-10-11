BEGIN;

-- Restrictive policies narrow authenticated access without replacing existing
-- permissive policies. Active administrators keep their existing policy paths;
-- service_role is unaffected because these guards target authenticated only.
-- The predicate also applies to every authenticated policy branch, including
-- household and self-read paths that previously exposed disabled accounts.

CREATE POLICY codex_disabled_account_select_guard
  ON public.contract_texts AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.devices AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.groupe_creneaux AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.groupe_membres AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.groupes AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.households AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.intentions_horaire AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.library_resource_groupe AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.matching_requests AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.prayer_settings AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.profiles AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.rule_overrides AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.student_profiles AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.student_reading_position AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.teacher_student_assignments AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_select_guard
  ON public.weekly_availability AS RESTRICTIVE FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid(), false));

-- INSERT/UPDATE/DELETE policies on KYC are all intersected with account
-- validity. Existing role, household, and service-role behavior remains intact.
CREATE POLICY codex_disabled_account_insert_guard
  ON public.kyc_documents AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_update_guard
  ON public.kyc_documents AS RESTRICTIVE FOR UPDATE TO authenticated
  USING (coalesce(public.app_account_valid(), false))
  WITH CHECK (coalesce(public.app_account_valid(), false));
CREATE POLICY codex_disabled_account_delete_guard
  ON public.kyc_documents AS RESTRICTIVE FOR DELETE TO authenticated
  USING (coalesce(public.app_account_valid(), false));

DO $postflight$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'contract_texts', 'devices', 'groupe_creneaux', 'groupe_membres',
    'groupes', 'households', 'intentions_horaire', 'library_resource_groupe',
    'matching_requests', 'prayer_settings', 'profiles', 'rule_overrides',
    'student_profiles', 'student_reading_position',
    'teacher_student_assignments', 'weekly_availability'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_policy p
      JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = v_table
        AND c.relrowsecurity
        AND p.polname = 'codex_disabled_account_select_guard'
        AND NOT p.polpermissive
        AND p.polcmd = 'r'
        AND p.polroles = ARRAY['authenticated'::pg_catalog.regrole::oid]
    ) THEN
      RAISE EXCEPTION 'disabled-account SELECT guard missing on public.%', v_table;
    END IF;
  END LOOP;

  IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_policy p
      WHERE p.polrelid = 'public.kyc_documents'::pg_catalog.regclass
        AND p.polname = 'codex_disabled_account_insert_guard'
        AND NOT p.polpermissive
        AND p.polcmd = 'a'
        AND p.polroles = ARRAY['authenticated'::pg_catalog.regrole::oid]
    ) OR NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_policy p
      WHERE p.polrelid = 'public.kyc_documents'::pg_catalog.regclass
        AND p.polname = 'codex_disabled_account_update_guard'
        AND NOT p.polpermissive
        AND p.polcmd = 'w'
        AND p.polroles = ARRAY['authenticated'::pg_catalog.regrole::oid]
    ) OR NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_policy p
      WHERE p.polrelid = 'public.kyc_documents'::pg_catalog.regclass
        AND p.polname = 'codex_disabled_account_delete_guard'
        AND NOT p.polpermissive
        AND p.polcmd = 'd'
        AND p.polroles @> ARRAY['authenticated'::pg_catalog.regrole::oid]
    ) THEN
    RAISE EXCEPTION 'disabled-account KYC write guards missing';
  END IF;
END;
$postflight$;

COMMIT;
