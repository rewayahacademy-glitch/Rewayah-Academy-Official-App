CREATE OR REPLACE FUNCTION public.annuler_invitation_conjoint()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_foyer uuid;
  v_id uuid;
BEGIN
  IF v_user IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'annulation indisponible';
  END IF;

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
$function$

