-- B-03 — invitation par adresse neutre, rapprochement Auth vérifié et rattachement sûr.
-- Les courriels restent dans l'outbox; aucune intégration fournisseur n'est simulée.
BEGIN;

INSERT INTO auth.users (id, email, email_confirmed_at)
VALUES
  ('b0300000-0000-0000-0000-000000000001', 'b03-titulaire@example.test', now()),
  ('b0300000-0000-0000-0000-000000000002', 'b03-invite@example.test', now()),
  ('b0300000-0000-0000-0000-000000000003', 'b03-unverified@example.test', NULL),
  ('b0300000-0000-0000-0000-000000000004', 'b03-owner-other@example.test', now()),
  ('b0300000-0000-0000-0000-000000000005', 'b03-parent-with-child@example.test', now()),
  ('b0300000-0000-0000-0000-000000000006', 'b03-child@example.test', now()),
  ('b0300000-0000-0000-0000-000000000007', 'b03-expired@example.test', now());

INSERT INTO public.households (id, timezone, status)
VALUES
  ('b0300000-0000-0000-0000-000000000101', 'Europe/Paris', 'active'),
  ('b0300000-0000-0000-0000-000000000102', 'Europe/Paris', 'active'),
  ('b0300000-0000-0000-0000-000000000103', 'Europe/Paris', 'active'),
  ('b0300000-0000-0000-0000-000000000104', 'Europe/Paris', 'active'),
  ('b0300000-0000-0000-0000-000000000105', 'Europe/Paris', 'active');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('b0300000-0000-0000-0000-000000000001', 'B03-INVITER', 'guardian',
   'b0300000-0000-0000-0000-000000000101', 'Nour', 'Inviteur',
   'active'::public.account_status, 'female'),
  ('b0300000-0000-0000-0000-000000000002', 'B03-INVITEE', 'guardian',
   'b0300000-0000-0000-0000-000000000102', 'Samir', 'Invité',
   'active'::public.account_status, 'male'),
  ('b0300000-0000-0000-0000-000000000003', 'B03-UNVERIFIED', 'guardian',
   'b0300000-0000-0000-0000-000000000103', 'Email', 'Non vérifié',
   'active'::public.account_status, 'male'),
  ('b0300000-0000-0000-0000-000000000004', 'B03-OTHER-OWNER', 'guardian',
   'b0300000-0000-0000-0000-000000000104', 'Autre', 'Titulaire',
   'active'::public.account_status, 'male'),
  ('b0300000-0000-0000-0000-000000000005', 'B03-PARENT-CHILD', 'guardian',
   'b0300000-0000-0000-0000-000000000104', 'Parent', 'Avec enfant',
   'active'::public.account_status, 'female'),
  ('b0300000-0000-0000-0000-000000000006', 'B03-CHILD', 'student',
   'b0300000-0000-0000-0000-000000000104', 'Enfant', 'Existant',
   'active'::public.account_status, 'female'),
  ('b0300000-0000-0000-0000-000000000007', 'B03-EXPIRED', 'guardian',
   'b0300000-0000-0000-0000-000000000105', 'Compte', 'Expiré',
   'active'::public.account_status, 'male');

UPDATE public.households SET primary_guardian_id = 'b0300000-0000-0000-0000-000000000001'
WHERE id = 'b0300000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id = 'b0300000-0000-0000-0000-000000000002'
WHERE id = 'b0300000-0000-0000-0000-000000000102';
UPDATE public.households SET primary_guardian_id = 'b0300000-0000-0000-0000-000000000003'
WHERE id = 'b0300000-0000-0000-0000-000000000103';
UPDATE public.households SET primary_guardian_id = 'b0300000-0000-0000-0000-000000000005'
WHERE id = 'b0300000-0000-0000-0000-000000000104';
UPDATE public.households SET primary_guardian_id = 'b0300000-0000-0000-0000-000000000007'
WHERE id = 'b0300000-0000-0000-0000-000000000105';

DO $scenario$
DECLARE
  v_inviter uuid := 'b0300000-0000-0000-0000-000000000001';
  v_invitee uuid := 'b0300000-0000-0000-0000-000000000002';
  v_child_parent uuid := 'b0300000-0000-0000-0000-000000000005';
  v_invitation uuid;
  v_first jsonb;
  v_repeat jsonb;
  v_state jsonb;
  v_count integer;
  v_guard_error text;
  v_cancelled boolean;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_inviter::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000101'))::text, true);

  v_first := public.inviter_conjoint(
    'B03-Invite@Example.test',
    'b0300000-0000-0000-0000-000000000201'
  );
  IF v_first->>'message' <> 'Si cette adresse est valide, une invitation lui a été envoyée.' THEN
    RAISE EXCEPTION 'B-03: la réponse d''envoi n''est pas neutre';
  END IF;
  IF coalesce((v_first->>'queued')::boolean, false) IS NOT TRUE THEN
    RAISE EXCEPTION 'B-03: l''invitation valable n''a pas été placée en outbox';
  END IF;

  v_repeat := public.inviter_conjoint(
    'b03-invite@example.test',
    'b0300000-0000-0000-0000-000000000201'
  );
  IF v_repeat->>'invitation_id' IS DISTINCT FROM v_first->>'invitation_id' THEN
    RAISE EXCEPTION 'B-03: la clé d''idempotence a créé une seconde invitation';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.email_outbox_invitation_foyer o
  WHERE o.invitation_id = (v_first->>'invitation_id')::uuid
    AND o.statut = 'en_attente';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-03: attendu un seul courriel en outbox, reçu %', v_count;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_invitee::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000102'))::text, true);
  v_state := public.mon_invitation_en_cours();
  IF v_state->>'etat' <> 'a_repondre'
     OR v_state->>'prenom_titulaire' <> 'Nour'
     OR coalesce((v_state->>'titulaire_feminin')::boolean, false) IS NOT TRUE THEN
    RAISE EXCEPTION 'B-03: la session vérifiée ne reçoit pas la projection attendue';
  END IF;

  v_state := public.repondre_invitation_conjoint(
    'accepter',
    'b0300000-0000-0000-0000-000000000202'
  );
  IF v_state->>'etat' <> 'acceptee' THEN
    RAISE EXCEPTION 'B-03: le rattachement du compte isolé a été refusé';
  END IF;
  IF (SELECT p.household_id FROM public.profiles p WHERE p.id = v_invitee)
     <> 'b0300000-0000-0000-0000-000000000101'::uuid THEN
    RAISE EXCEPTION 'B-03: le compte accepté n''a pas rejoint le foyer invité';
  END IF;
  IF (SELECT p.role FROM public.profiles p WHERE p.id = v_invitee) <> 'guardian' THEN
    RAISE EXCEPTION 'B-03: le rôle du compte invité a changé';
  END IF;

  v_state := public.repondre_invitation_conjoint(
    'accepter',
    'b0300000-0000-0000-0000-000000000202'
  );
  IF v_state->>'etat' <> 'acceptee' THEN
    RAISE EXCEPTION 'B-03: une acceptation répétée n''est pas idempotente';
  END IF;

  -- Une adresse Auth non vérifiée ne peut pas consommer l'invitation.
  PERFORM set_config('request.jwt.claim.sub', v_inviter::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000101'))::text, true);
  PERFORM public.inviter_conjoint(
    'b03-unverified@example.test',
    'b0300000-0000-0000-0000-000000000205'
  );
  PERFORM set_config('request.jwt.claim.sub', 'b0300000-0000-0000-0000-000000000003', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000103'))::text, true);
  v_state := public.mon_invitation_en_cours();
  IF v_state->>'etat' <> 'non_acceptable' THEN
    RAISE EXCEPTION 'B-03: une adresse non vérifiée a vu ou accepté l''invitation';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_inviter::text, true);

  -- F86 must-pass: an active account with the wrong JWT role is rejected
  -- before the cancellation can change an invitation or its outbox row.
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student',
      'household_id', 'b0300000-0000-0000-0000-000000000101'))::text, true);
  BEGIN
    PERFORM public.annuler_invitation_conjoint();
    RAISE EXCEPTION 'B-03 F86: a non-guardian cancelled a household invitation';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    GET STACKED DIAGNOSTICS v_guard_error = MESSAGE_TEXT;
    IF v_guard_error <> 'annulation indisponible' THEN
      RAISE;
    END IF;
  END;

  -- F86 null-safety: a missing JWT role is rejected too.
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'household_id', 'b0300000-0000-0000-0000-000000000101'))::text, true);
  BEGIN
    PERFORM public.annuler_invitation_conjoint();
    RAISE EXCEPTION 'B-03 F86: a JWT without a role cancelled an invitation';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    GET STACKED DIAGNOSTICS v_guard_error = MESSAGE_TEXT;
    IF v_guard_error <> 'annulation indisponible' THEN
      RAISE;
    END IF;
  END;

  SELECT count(*) INTO v_count
  FROM public.invitations_foyer
  WHERE invite_par = v_inviter
    AND email_invite = 'b03-unverified@example.test'
    AND statut = 'en_attente';
  IF v_count <> 1 OR NOT EXISTS (
    SELECT 1
    FROM public.email_outbox_invitation_foyer o
    JOIN public.invitations_foyer i ON i.id = o.invitation_id
    WHERE i.invite_par = v_inviter
      AND i.email_invite = 'b03-unverified@example.test'
      AND o.statut = 'en_attente'
  ) THEN
    RAISE EXCEPTION 'B-03 F86: a denied cancellation changed invitation state';
  END IF;

  -- Restore the valid role and prove the permitted cancellation still works.
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000101'))::text, true);
  v_cancelled := public.annuler_invitation_conjoint();
  IF v_cancelled IS NOT TRUE THEN
    RAISE EXCEPTION 'B-03 F86: a valid guardian could not cancel their invitation';
  END IF;
  PERFORM public.inviter_conjoint(
    'b03-expired@example.test',
    'b0300000-0000-0000-0000-000000000206'
  );
  UPDATE public.invitations_foyer
  SET expire_le = now() - interval '1 second'
  WHERE email_invite = 'b03-expired@example.test' AND statut = 'en_attente';
  PERFORM set_config('request.jwt.claim.sub', 'b0300000-0000-0000-0000-000000000007', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000105'))::text, true);
  v_state := public.mon_invitation_en_cours();
  IF v_state->>'etat' <> 'perimee' THEN
    RAISE EXCEPTION 'B-03: une invitation expirée reste active';
  END IF;

  -- Un compte déjà titulaire d'un foyer avec un enfant reste dans son foyer.
  PERFORM set_config('request.jwt.claim.sub', v_inviter::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000101'))::text, true);
  v_first := public.inviter_conjoint(
    'b03-parent-with-child@example.test',
    'b0300000-0000-0000-0000-000000000203'
  );
  PERFORM set_config('request.jwt.claim.sub', v_child_parent::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian',
      'household_id', 'b0300000-0000-0000-0000-000000000104'))::text, true);
  v_state := public.repondre_invitation_conjoint(
    'accepter',
    'b0300000-0000-0000-0000-000000000204'
  );
  IF v_state->>'etat' <> 'non_acceptable'
     OR (SELECT p.household_id FROM public.profiles p WHERE p.id = v_child_parent)
        <> 'b0300000-0000-0000-0000-000000000104'::uuid THEN
    RAISE EXCEPTION 'B-03: un titulaire avec enfant a été fusionné dans un autre foyer';
  END IF;
END
$scenario$;

ROLLBACK;
