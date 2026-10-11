CREATE OR REPLACE FUNCTION public.mon_invitation_en_cours()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_email text;
  v_confirmed timestamptz;
  v_profile public.profiles%ROWTYPE;
  v_invitation public.invitations_foyer%ROWTYPE;
  v_inviter public.profiles%ROWTYPE;
  v_state text;
BEGIN
  SELECT lower(u.email), u.email_confirmed_at
  INTO v_email, v_confirmed
  FROM auth.users u WHERE u.id = v_user;

  IF v_user IS NULL OR v_confirmed IS NULL OR v_email IS NULL THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  SELECT * INTO v_profile FROM public.profiles p
  WHERE p.id = v_user AND p.role = 'guardian' AND p.deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  SELECT * INTO v_invitation
  FROM public.invitations_foyer i
  WHERE i.email_invite = v_email
    AND i.statut IN ('en_attente', 'acceptee', 'refusee', 'annulee', 'expiree')
  ORDER BY i.created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  IF v_invitation.statut = 'en_attente' AND v_invitation.expire_le <= now() THEN
    UPDATE public.invitations_foyer
    SET statut = 'expiree', updated_at = now()
    WHERE id = v_invitation.id AND statut = 'en_attente';
    UPDATE public.email_outbox_invitation_foyer
    SET statut = 'annule'
    WHERE invitation_id = v_invitation.id AND statut = 'en_attente';
    v_invitation.statut := 'expiree';
  END IF;

  IF v_invitation.statut = 'annulee' OR v_invitation.statut = 'expiree' THEN
    RETURN jsonb_build_object('etat', 'perimee');
  ELSIF v_invitation.statut = 'acceptee' THEN
    RETURN jsonb_build_object(
      'etat', 'acceptee',
      'prenom_titulaire', (SELECT p.first_name FROM public.profiles p WHERE p.id = v_invitation.invite_par),
      'enregistree_le', v_invitation.repondu_le
    );
  ELSIF v_invitation.statut = 'refusee' THEN
    RETURN jsonb_build_object('etat', 'refusee', 'enregistree_le', v_invitation.repondu_le);
  END IF;

  SELECT * INTO v_inviter FROM public.profiles p
  WHERE p.id = v_invitation.invite_par AND p.deleted_at IS NULL;

  IF NOT FOUND
     OR NOT EXISTS (
       SELECT 1 FROM public.households h
       WHERE h.id = v_invitation.foyer_id
         AND h.primary_guardian_id = v_invitation.invite_par
         AND h.status = 'active' AND h.deleted_at IS NULL
     ) THEN
    RETURN jsonb_build_object('etat', 'perimee');
  END IF;

  RETURN jsonb_build_object(
    'etat', 'a_repondre',
    'prenom_titulaire', v_inviter.first_name,
    'titulaire_feminin', v_inviter.gender::text = 'female',
    'validation_requise', false,
    'duree_conservation', NULL
  );
END;
$function$

