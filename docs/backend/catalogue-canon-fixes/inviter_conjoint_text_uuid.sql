CREATE OR REPLACE FUNCTION public.inviter_conjoint(p_email text, p_cle uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_foyer uuid;
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_existing public.invitations_foyer%ROWTYPE;
  v_id uuid;
  v_queued boolean := false;
BEGIN
  IF v_user IS NULL OR p_cle IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
     OR v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'invitation indisponible';
  END IF;

  SELECT h.id INTO v_foyer
  FROM public.households h
  JOIN public.profiles p ON p.id = h.primary_guardian_id
  WHERE h.primary_guardian_id = v_user
    AND p.id = v_user
    AND p.role = 'guardian'
    AND p.household_id = h.id
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > now())
    AND h.status = 'active'
    AND h.deleted_at IS NULL
  FOR UPDATE OF h;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invitation indisponible';
  END IF;

  SELECT * INTO v_existing
  FROM public.invitations_foyer i
  WHERE i.invite_par = v_user AND i.cle_envoi = p_cle;

  IF FOUND THEN
    IF v_existing.email_invite <> v_email THEN
      RAISE EXCEPTION 'clé d''envoi déjà utilisée';
    END IF;
    RETURN jsonb_build_object(
      'queued', v_existing.statut = 'en_attente',
      'invitation_id', v_existing.id,
      'message', 'Si cette adresse est valide, une invitation lui a été envoyée.'
    );
  END IF;

  IF EXISTS (
    SELECT 1 FROM auth.users u
    WHERE u.id = v_user AND lower(u.email) = v_email
  ) THEN
    RETURN jsonb_build_object(
      'queued', false,
      'message', 'Si cette adresse est valide, une invitation lui a été envoyée.'
    );
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.invitations_foyer i
    WHERE i.foyer_id = v_foyer AND i.statut = 'en_attente'
  ) OR EXISTS (
    SELECT 1 FROM public.invitations_foyer i
    WHERE i.email_invite = v_email AND i.statut = 'en_attente'
  ) THEN
    RETURN jsonb_build_object(
      'queued', false,
      'message', 'Si cette adresse est valide, une invitation lui a été envoyée.'
    );
  END IF;

  BEGIN
    INSERT INTO public.invitations_foyer (foyer_id, email_invite, invite_par, cle_envoi)
    VALUES (v_foyer, v_email, v_user, p_cle)
    RETURNING id INTO v_id;

    INSERT INTO public.email_outbox_invitation_foyer (invitation_id, recipient_email)
    VALUES (v_id, v_email);

    PERFORM public.log_sensitive_access(
      'invitation_conjoint_creee', 'invitations_foyer', v_id::text,
      jsonb_build_object('foyer_id', v_foyer)
    );
    v_queued := true;
  EXCEPTION WHEN unique_violation THEN
    -- Une invitation concurrente pour ce foyer ou cette adresse reste privée.
    v_queued := false;
  END;

  RETURN jsonb_build_object(
    'queued', v_queued,
    'invitation_id', v_id,
    'message', 'Si cette adresse est valide, une invitation lui a été envoyée.'
  );
END;
$function$

