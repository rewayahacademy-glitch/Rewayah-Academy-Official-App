BEGIN;

-- F86: put the account-valid, null-safe role guard before reading caller state.
CREATE OR REPLACE FUNCTION public.annuler_invitation_conjoint()
RETURNS boolean
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid;
  v_foyer uuid;
  v_id uuid;
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'guardian',
    false
  ) THEN
    RAISE EXCEPTION 'annulation indisponible';
  END IF;

  v_user := auth.uid();

  SELECT h.id INTO v_foyer
  FROM public.households h
  WHERE h.primary_guardian_id = v_user
    AND h.status = 'active'
    AND h.deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'annulation indisponible';
  END IF;

  UPDATE public.invitations_foyer
  SET statut = 'annulee', updated_at = now()
  WHERE foyer_id = v_foyer AND statut = 'en_attente'
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    RETURN false;
  END IF;

  UPDATE public.email_outbox_invitation_foyer
  SET statut = 'annule', last_error_code = NULL
  WHERE invitation_id = v_id AND statut = 'en_attente';

  PERFORM public.log_sensitive_access(
    'invitation_conjoint_annulee', 'invitations_foyer', v_id::text,
    jsonb_build_object('foyer_id', v_foyer)
  );
  RETURN true;
END;
$function$;

COMMENT ON FUNCTION public.annuler_invitation_conjoint() IS
  'F86 candidate allowlist: signature=public.annuler_invitation_conjoint(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; must-pass=scenarios_b03_invitations_foyer.sql; reviewer=Claude a relire; date=2026-10-11.';

COMMIT;
