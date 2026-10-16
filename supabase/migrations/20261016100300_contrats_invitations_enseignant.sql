-- CONTRATS-MANQUANTS (4/6) : l'invitation d'un enseignant, a usage unique et
-- a duree limitee (contrats C-13 et C-14, RECRUT-ECRANS).
--
-- Contrat : lib/core/recrutement/port_invitations_enseignant.dart
-- (PortInvitationsEnseignant : inviter, lister, revoquer ;
--  PortVerificationInvitation : verifierInvitation).
--
-- * Seule la direction active emet, liste et revoque.
-- * Code de 12 signes (alphabet sans 0, O, 1, I, L) groupes par quatre ;
--   echeance = maintenant + recrutement.invitation_duree_jours (14 par
--   defaut, app_config).
-- * inviter : refus metier rendus, jamais leves : 'email_invalide',
--   'compte_existant' (un profil existe deja pour une identite qui porte
--   l'adresse ; une identite sans profil est une inscription en cours),
--   'deja_invite'
--   (une invitation active existe : elle est rendue). NonAutorise = 42501.
-- * L'etat ('active', 'utilisee', 'expiree', 'revoquee') est calcule par le
--   serveur, jamais par l'horloge de l'appareil.
-- * verifier : le candidat a une session (etape d'inscription, avant tout
--   profil) ; quatre issues : 'valide', 'expiree', 'deja_utilisee',
--   'inconnue'. Un code revoque, ou emis pour une autre adresse que celle de
--   la session, rend 'inconnue' : aucune fuite. Le resultat ne sert qu'a
--   l'affichage ; la consommation atomique a l'inscription reste a brancher
--   dans la creation du profil enseignant (colonnes utilisee_le/par pretes).
BEGIN;

CREATE TABLE public.invitations_enseignant (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$'),
  email text NOT NULL CHECK (email = pg_catalog.lower(pg_catalog.btrim(email))
                             AND pg_catalog.length(email) BETWEEN 3 AND 254),
  cree_par uuid NOT NULL REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL,
  revoquee_le timestamptz,
  revoquee_par uuid REFERENCES public.profiles(id),
  utilisee_le timestamptz,
  utilisee_par uuid REFERENCES auth.users(id),
  CONSTRAINT invitations_enseignant_echeance CHECK (expire_le > cree_le),
  CONSTRAINT invitations_enseignant_revocation CHECK ((revoquee_le IS NULL) = (revoquee_par IS NULL)),
  CONSTRAINT invitations_enseignant_utilisation CHECK ((utilisee_le IS NULL) = (utilisee_par IS NULL)),
  CONSTRAINT invitations_enseignant_exclusif CHECK (revoquee_le IS NULL OR utilisee_le IS NULL)
);
CREATE INDEX invitations_enseignant_email_idx
  ON public.invitations_enseignant (email) WHERE revoquee_le IS NULL AND utilisee_le IS NULL;
CREATE INDEX invitations_enseignant_recentes_idx ON public.invitations_enseignant (cree_le DESC);

ALTER TABLE public.invitations_enseignant ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invitations_enseignant FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.invitations_enseignant TO authenticated;
CREATE POLICY invitations_enseignant_direction_lecture ON public.invitations_enseignant
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- La forme rendue au client (Invitation).
CREATE FUNCTION app_private.invitation_enseignant_json(i public.invitations_enseignant)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'code', i.code, 'email', i.email, 'expire_le', i.expire_le,
    'etat', CASE WHEN i.utilisee_le IS NOT NULL THEN 'utilisee'
                 WHEN i.revoquee_le IS NOT NULL THEN 'revoquee'
                 WHEN i.expire_le <= pg_catalog.now() THEN 'expiree'
                 ELSE 'active' END,
    'utilisee_le', i.utilisee_le);
$function$;
REVOKE ALL ON FUNCTION app_private.invitation_enseignant_json(public.invitations_enseignant)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION app_private.invitation_enseignant_json(public.invitations_enseignant) TO authenticated;

-- Les invitations, la plus recente d'abord (INVOKER, RLS direction).
CREATE FUNCTION public.invitations_enseignant_admin()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitations reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(app_private.invitation_enseignant_json(i) ORDER BY i.cree_le DESC, i.id DESC)
    FROM public.invitations_enseignant i), '[]'::jsonb);
END;
$function$;

-- Emettre (DEFINER : l'existence d'un compte se lit dans auth.users).
-- Rend {statut: 'creee' | 'deja_invite' | 'email_invalide' | 'compte_existant',
--       invitation: {...} | nul}.
CREATE FUNCTION public.inviter_enseignant(p_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_email, '')));
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_ligne public.invitations_enseignant;
  v_octets bytea;
  v_code text;
  v_i integer;
  v_essai integer := 0;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'invitation reservee a la direction active' USING ERRCODE = '42501';
  END IF;

  IF pg_catalog.length(v_email) NOT BETWEEN 3 AND 254
     OR v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'email_invalide', 'invitation', NULL);
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('invitation-enseignant:' || v_email, 0));

  IF EXISTS (SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id = u.id
              WHERE pg_catalog.lower(u.email) = v_email AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'compte_existant', 'invitation', NULL);
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_enseignant i
   WHERE i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
     AND i.expire_le > pg_catalog.now()
   ORDER BY i.cree_le DESC LIMIT 1;
  IF v_ligne.id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_invite',
      'invitation', app_private.invitation_enseignant_json(v_ligne));
  END IF;

  LOOP
    v_essai := v_essai + 1;
    v_octets := extensions.gen_random_bytes(12);
    v_code := '';
    FOR v_i IN 0..11 LOOP
      v_code := v_code || pg_catalog.substr(v_alphabet, (pg_catalog.get_byte(v_octets, v_i) % 31) + 1, 1);
      IF v_i IN (3, 7) THEN
        v_code := v_code || '-';
      END IF;
    END LOOP;
    BEGIN
      INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le)
      VALUES (v_code, v_email, auth.uid(),
              pg_catalog.now() + pg_catalog.make_interval(days =>
                greatest(1, public.app_config_int('recrutement.invitation_duree_jours', 14))))
      RETURNING * INTO v_ligne;
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      IF v_essai >= 5 THEN
        RAISE;
      END IF;
    END;
  END LOOP;

  PERFORM public.log_sensitive_access('invitation_enseignant_emise', 'invitations_enseignant',
    v_ligne.id::text, '{}'::jsonb);
  RETURN pg_catalog.jsonb_build_object('statut', 'creee',
    'invitation', app_private.invitation_enseignant_json(v_ligne));
END;
$function$;

-- Revoquer : sans effet sur une invitation utilisee, expiree ou deja
-- revoquee ; un code inconnu leve P0002.
CREATE FUNCTION public.revoquer_invitation_enseignant(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'revocation reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT i.id INTO v_id FROM public.invitations_enseignant i
   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))
   FOR UPDATE;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'invitation introuvable' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.invitations_enseignant
     SET revoquee_le = pg_catalog.now(), revoquee_par = auth.uid()
   WHERE id = v_id AND revoquee_le IS NULL AND utilisee_le IS NULL
     AND expire_le > pg_catalog.now();
  IF FOUND THEN
    PERFORM public.log_sensitive_access('invitation_enseignant_revoquee', 'invitations_enseignant',
      v_id::text, '{}'::jsonb);
  END IF;
END;
$function$;

-- Verifier un code (le candidat, session d'inscription).
-- Rend {resultat: 'valide' | 'expiree' | 'deja_utilisee' | 'inconnue',
--       expire_le: horodatage | nul}.
CREATE FUNCTION public.verifier_invitation_enseignant(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text;
  v_ligne public.invitations_enseignant;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = auth.uid();
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_email IS NOT NULL, false) THEN
    RAISE EXCEPTION 'verification reservee a une session d''inscription' USING ERRCODE = '42501';
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_enseignant i
   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))
     AND i.email = v_email AND i.revoquee_le IS NULL;
  IF v_ligne.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'inconnue', 'expire_le', NULL);
  END IF;
  IF v_ligne.utilisee_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'deja_utilisee', 'expire_le', NULL);
  END IF;
  IF v_ligne.expire_le <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'expiree', 'expire_le', v_ligne.expire_le);
  END IF;
  RETURN pg_catalog.jsonb_build_object('resultat', 'valide', 'expire_le', v_ligne.expire_le);
END;
$function$;

REVOKE ALL ON FUNCTION public.invitations_enseignant_admin() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.inviter_enseignant(text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.revoquer_invitation_enseignant(text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.verifier_invitation_enseignant(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitations_enseignant_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.inviter_enseignant(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoquer_invitation_enseignant(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verifier_invitation_enseignant(text) TO authenticated;

-- @@F86_DEBUT_INVITATIONS@@
COMMENT ON FUNCTION public.inviter_enseignant(text) IS
  'F86: signature=public.inviter_enseignant(text); md5_functiondef=120b80f463135f5110cc26bfe9ff2999; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active. DEFINER: lecture de auth.users et profiles (compte existant).';
COMMENT ON FUNCTION public.revoquer_invitation_enseignant(text) IS
  'F86: signature=public.revoquer_invitation_enseignant(text); md5_functiondef=0b884579cd7f0a1ba018e386f9c2b8f0; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active.';
COMMENT ON FUNCTION public.verifier_invitation_enseignant(text) IS
  'F86: signature=public.verifier_invitation_enseignant(text); md5_functiondef=a03dd68a4961499faa48bfbf7e82ba68; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; date=2026-10-16. Garde: session auth existante; code lie a l''adresse de la session.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.inviter_enseignant(text)'::regprocedure, '120b80f463135f5110cc26bfe9ff2999'),
      ('public.revoquer_invitation_enseignant(text)'::regprocedure, '0b884579cd7f0a1ba018e386f9c2b8f0'),
      ('public.verifier_invitation_enseignant(text)'::regprocedure, 'a03dd68a4961499faa48bfbf7e82ba68')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.invitations_enseignant_admin()'::regprocedure
      AND (p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
           OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'CONTRATS invitations : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_INVITATIONS@@

COMMIT;
