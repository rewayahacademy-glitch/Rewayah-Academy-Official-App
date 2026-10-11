CREATE OR REPLACE FUNCTION public.repondre_invitation_conjoint(p_decision text, p_cle uuid)
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
  v_old_household public.households%ROWTYPE;
  v_household public.households%ROWTYPE;
  v_has_children boolean;
  v_old_found boolean;
  v_titulaire text;
  v_original_claims jsonb;
  v_household_updated boolean;
BEGIN
  IF p_decision IS NULL OR p_decision NOT IN ('accepter', 'refuser') OR p_cle IS NULL THEN
    RAISE EXCEPTION 'réponse invalide';
  END IF;

  SELECT lower(u.email), u.email_confirmed_at
  INTO v_email, v_confirmed
  FROM auth.users u WHERE u.id = v_user;

  IF v_user IS NULL OR v_confirmed IS NULL OR v_email IS NULL THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  SELECT * INTO v_invitation
  FROM public.invitations_foyer i
  WHERE i.email_invite = v_email
    AND i.statut IN ('en_attente', 'acceptee', 'refusee', 'annulee', 'expiree')
  ORDER BY i.created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  IF v_invitation.statut = 'acceptee' AND v_invitation.repondu_par = v_user THEN
    RETURN jsonb_build_object('etat', 'acceptee', 'enregistree_le', v_invitation.repondu_le);
  ELSIF v_invitation.statut = 'refusee' AND v_invitation.repondu_par = v_user THEN
    RETURN jsonb_build_object('etat', 'refusee', 'enregistree_le', v_invitation.repondu_le);
  ELSIF v_invitation.statut IN ('annulee', 'expiree') THEN
    RETURN jsonb_build_object('etat', 'perimee');
  ELSIF v_invitation.statut <> 'en_attente' THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  IF v_invitation.expire_le <= now() THEN
    UPDATE public.invitations_foyer
    SET statut = 'expiree', updated_at = now()
    WHERE id = v_invitation.id;
    UPDATE public.email_outbox_invitation_foyer
    SET statut = 'annule'
    WHERE invitation_id = v_invitation.id AND statut = 'en_attente';
    RETURN jsonb_build_object('etat', 'perimee');
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles p
  WHERE p.id = v_user AND p.role = 'guardian'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > now())
  FOR UPDATE;

  IF NOT FOUND OR NOT coalesce(public.app_role() = 'guardian'
                               AND public.app_account_valid(), false) THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  SELECT * INTO v_household FROM public.households h
  WHERE h.id = v_invitation.foyer_id
    AND h.primary_guardian_id = v_invitation.invite_par
    AND h.status = 'active' AND h.deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND OR v_profile.household_id = v_invitation.foyer_id THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  IF p_decision = 'refuser' THEN
    UPDATE public.invitations_foyer
    SET statut = 'refusee', repondu_par = v_user, repondu_le = now(),
        cle_reponse = p_cle, updated_at = now()
    WHERE id = v_invitation.id AND statut = 'en_attente';

    PERFORM public.log_sensitive_access(
      'invitation_conjoint_refusee', 'invitations_foyer', v_invitation.id::text,
      jsonb_build_object('foyer_id', v_invitation.foyer_id)
    );
    RETURN jsonb_build_object('etat', 'refusee', 'enregistree_le', now());
  END IF;

  IF v_profile.household_id IS NOT NULL THEN
    SELECT * INTO v_old_household FROM public.households h
    WHERE h.id = v_profile.household_id AND h.deleted_at IS NULL
    FOR UPDATE;
    v_old_found := FOUND;

    SELECT EXISTS (
      SELECT 1 FROM public.profiles child
      WHERE child.household_id = v_profile.household_id
        AND child.role = 'student' AND child.deleted_at IS NULL
    ) INTO v_has_children;

    IF NOT v_old_found
       OR v_old_household.status <> 'active'
       OR v_old_household.primary_guardian_id IS DISTINCT FROM v_user
       OR v_has_children THEN
      PERFORM public.log_sensitive_access(
        'invitation_conjoint_refus_foyer_existant', 'invitations_foyer',
        v_invitation.id::text,
        jsonb_build_object('foyer_id_cible', v_invitation.foyer_id)
      );
      RETURN jsonb_build_object('etat', 'non_acceptable');
    END IF;
  END IF;

  -- Le trigger commun protège household_id aux appels directs. Après les
  -- contrôles ci-dessus, cette RPC autorise uniquement cette liaison d'invitation.
  -- Relever l'acteur interne le temps de l'UPDATE, puis restaurer les claims.
  v_original_claims := auth.jwt();
  PERFORM pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.jsonb_set(
      coalesce(v_original_claims, '{}'::jsonb),
      '{app_metadata}',
      coalesce(v_original_claims->'app_metadata', '{}'::jsonb)
        || pg_catalog.jsonb_build_object('role', 'admin'),
      true
    )::text,
    true
  );
  UPDATE public.profiles
  SET household_id = v_invitation.foyer_id, updated_at = now()
  WHERE id = v_user AND role = 'guardian';
  v_household_updated := FOUND;
  PERFORM pg_catalog.set_config(
    'request.jwt.claims', coalesce(v_original_claims, '{}'::jsonb)::text, true
  );

  IF NOT v_household_updated THEN
    RETURN jsonb_build_object('etat', 'non_acceptable');
  END IF;

  UPDATE public.invitations_foyer
  SET statut = 'acceptee', repondu_par = v_user, repondu_le = now(),
      cle_reponse = p_cle, updated_at = now()
  WHERE id = v_invitation.id AND statut = 'en_attente';

  SELECT p.first_name INTO v_titulaire
  FROM public.profiles p WHERE p.id = v_invitation.invite_par;

  PERFORM public.log_sensitive_access(
    'invitation_conjoint_acceptee', 'invitations_foyer', v_invitation.id::text,
    jsonb_build_object('foyer_id', v_invitation.foyer_id)
  );

  RETURN jsonb_build_object(
    'etat', 'acceptee',
    'prenom_titulaire', v_titulaire,
    'enregistree_le', now()
  );
END;
$function$

