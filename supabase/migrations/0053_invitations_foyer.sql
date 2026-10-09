-- 0053 — invitations privées entre adultes du foyer.
-- L'envoi externe n'est pas simulé : le RPC écrit une outbox protégée.
BEGIN;

CREATE TABLE public.invitations_foyer (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  foyer_id uuid NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  email_invite text NOT NULL CHECK (
    email_invite = lower(btrim(email_invite))
    AND email_invite ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
  ),
  invite_par uuid NOT NULL REFERENCES public.profiles(id),
  cle_envoi uuid NOT NULL,
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'acceptee', 'refusee', 'annulee', 'expiree')),
  expire_le timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  repondu_par uuid REFERENCES public.profiles(id),
  repondu_le timestamptz,
  cle_reponse uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT invitation_reponse_coherente CHECK (
    (statut IN ('acceptee', 'refusee') AND repondu_par IS NOT NULL AND repondu_le IS NOT NULL)
    OR (statut NOT IN ('acceptee', 'refusee') AND repondu_par IS NULL AND repondu_le IS NULL)
  )
);

CREATE UNIQUE INDEX invitations_foyer_active_unique
  ON public.invitations_foyer(foyer_id) WHERE statut = 'en_attente';
CREATE UNIQUE INDEX invitations_email_active_unique
  ON public.invitations_foyer(email_invite) WHERE statut = 'en_attente';
CREATE UNIQUE INDEX invitations_idempotency_unique
  ON public.invitations_foyer(invite_par, cle_envoi);

ALTER TABLE public.invitations_foyer ENABLE ROW LEVEL SECURITY;
CREATE POLICY invitations_foyer_titulaire_lecture
  ON public.invitations_foyer
  FOR SELECT TO authenticated
  USING (
    invite_par = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.households h
      WHERE h.id = invitations_foyer.foyer_id
        AND h.primary_guardian_id = auth.uid()
        AND h.status = 'active'
        AND h.deleted_at IS NULL
    )
    AND public.app_role() = 'guardian'
    AND public.app_account_valid()
  );

REVOKE ALL ON public.invitations_foyer FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT ON public.invitations_foyer TO authenticated;

CREATE TABLE public.email_outbox_invitation_foyer (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invitation_id uuid NOT NULL UNIQUE
    REFERENCES public.invitations_foyer(id) ON DELETE CASCADE,
  recipient_email text NOT NULL,
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'envoye', 'echec', 'annule')),
  tentatives integer NOT NULL DEFAULT 0 CHECK (tentatives >= 0),
  prochaine_tentative timestamptz NOT NULL DEFAULT now(),
  last_error_code text,
  created_at timestamptz NOT NULL DEFAULT now(),
  envoye_le timestamptz
);

ALTER TABLE public.email_outbox_invitation_foyer ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.email_outbox_invitation_foyer FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT, UPDATE ON public.email_outbox_invitation_foyer TO service_role;

CREATE OR REPLACE FUNCTION public.inviter_conjoint(p_email text, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
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
$function$;

REVOKE EXECUTE ON FUNCTION public.inviter_conjoint(text, uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.inviter_conjoint(text, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.annuler_invitation_conjoint()
RETURNS boolean
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
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
$function$;

REVOKE EXECUTE ON FUNCTION public.annuler_invitation_conjoint() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.annuler_invitation_conjoint() TO authenticated;

CREATE OR REPLACE FUNCTION public.mon_invitation_en_cours()
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
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
$function$;

REVOKE EXECUTE ON FUNCTION public.mon_invitation_en_cours() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.mon_invitation_en_cours() TO authenticated;

CREATE OR REPLACE FUNCTION public.repondre_invitation_conjoint(
  p_decision text,
  p_cle uuid
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
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

  UPDATE public.profiles
  SET household_id = v_invitation.foyer_id, updated_at = now()
  WHERE id = v_user AND role = 'guardian';

  IF NOT FOUND THEN
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
$function$;

REVOKE EXECUTE ON FUNCTION public.repondre_invitation_conjoint(text, uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.repondre_invitation_conjoint(text, uuid) TO authenticated;

DO $verification$
BEGIN
  IF NOT has_function_privilege('authenticated', 'public.inviter_conjoint(text,uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.inviter_conjoint(text,uuid)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.inviter_conjoint(text,uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.repondre_invitation_conjoint(text,uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.repondre_invitation_conjoint(text,uuid)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.repondre_invitation_conjoint(text,uuid)', 'EXECUTE')
     OR to_regclass('public.email_outbox_invitation_foyer') IS NULL THEN
    RAISE EXCEPTION '0053 incomplete: invitation ACL or outbox invalid';
  END IF;
END
$verification$;

COMMIT;
