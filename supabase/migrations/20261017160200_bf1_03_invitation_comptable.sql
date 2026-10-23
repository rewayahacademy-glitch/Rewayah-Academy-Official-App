-- BF1-03 (17/10/2026) : l'invitation d'un comptable par la direction, et sa
-- consommation a l'inscription. Modele : l'invitation enseignant
-- (20261016100300) et sa consommation (20261017150200, L1-11).
--
-- Constat : le role `accountant` existe (`app_role`, 0001) mais aucune porte
-- ne cree de comptable (l'inscription publique n'ouvre que guardian, et
-- teacher sur invitation). Les droits du comptable sur la finance sont deja
-- poses par les policies existantes (wallets, wallet_entries, payouts,
-- tresorerie_a_reprendre, ...) : cette migration n'en ajoute aucun.
--
-- * Table distincte `invitations_comptable` (meme forme que
--   invitations_enseignant) : un code de comptable ne cree jamais un enseignant,
--   ni l'inverse.
-- * Emettre exige la direction active en double verification (aal2) :
--   l'invitation ouvre l'acces a toute la finance. Lister et revoquer :
--   direction active.
-- * Reponses metier identiques a l'invitation enseignant ('creee',
--   'deja_invite', 'email_invalide', 'compte_existant'), 42501 sinon.
-- * `inscrire_comptable_invite` : session authentifiee avec adresse et sans
--   profil ; code lie a l'adresse de la session, verrouille, usage unique ;
--   cree le profil `accountant` (sans foyer, compte actif : la direction a
--   deja designe la personne) dans la meme transaction que la consommation.
--   Rend {resultat: 'consommee' | 'inconnue' | 'deja_utilisee' | 'expiree'}.
BEGIN;

CREATE TABLE public.invitations_comptable (
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
  CONSTRAINT invitations_comptable_echeance CHECK (expire_le > cree_le),
  CONSTRAINT invitations_comptable_revocation CHECK ((revoquee_le IS NULL) = (revoquee_par IS NULL)),
  CONSTRAINT invitations_comptable_utilisation CHECK ((utilisee_le IS NULL) = (utilisee_par IS NULL)),
  CONSTRAINT invitations_comptable_exclusif CHECK (revoquee_le IS NULL OR utilisee_le IS NULL)
);
CREATE INDEX invitations_comptable_email_idx
  ON public.invitations_comptable (email) WHERE revoquee_le IS NULL AND utilisee_le IS NULL;
CREATE INDEX invitations_comptable_recentes_idx ON public.invitations_comptable (cree_le DESC);

ALTER TABLE public.invitations_comptable ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invitations_comptable FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.invitations_comptable TO authenticated;
CREATE POLICY invitations_comptable_direction_lecture ON public.invitations_comptable
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

CREATE FUNCTION app_private.invitation_comptable_json(i public.invitations_comptable)
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
REVOKE ALL ON FUNCTION app_private.invitation_comptable_json(public.invitations_comptable)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION app_private.invitation_comptable_json(public.invitations_comptable) TO authenticated;

CREATE FUNCTION public.invitations_comptable_admin()
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
    SELECT pg_catalog.jsonb_agg(app_private.invitation_comptable_json(i) ORDER BY i.cree_le DESC, i.id DESC)
    FROM public.invitations_comptable i), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.inviter_comptable(p_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_email, '')));
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_ligne public.invitations_comptable;
  v_octets bytea;
  v_code text;
  v_i integer;
  v_essai integer := 0;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid()
                  AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'invitation comptable reservee a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;

  IF pg_catalog.length(v_email) NOT BETWEEN 3 AND 254
     OR v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'email_invalide', 'invitation', NULL);
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('invitation-comptable:' || v_email, 0));

  IF EXISTS (SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id = u.id
              WHERE pg_catalog.lower(u.email) = v_email AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'compte_existant', 'invitation', NULL);
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_comptable i
   WHERE i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
     AND i.expire_le > pg_catalog.now()
   ORDER BY i.cree_le DESC LIMIT 1;
  IF v_ligne.id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_invite',
      'invitation', app_private.invitation_comptable_json(v_ligne));
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
      INSERT INTO public.invitations_comptable (code, email, cree_par, expire_le)
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

  PERFORM public.log_sensitive_access('invitation_comptable_emise', 'invitations_comptable',
    v_ligne.id::text, '{}'::jsonb);
  RETURN pg_catalog.jsonb_build_object('statut', 'creee',
    'invitation', app_private.invitation_comptable_json(v_ligne));
END;
$function$;

CREATE FUNCTION public.revoquer_invitation_comptable(p_code text)
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
  SELECT i.id INTO v_id FROM public.invitations_comptable i
   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))
   FOR UPDATE;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'invitation introuvable' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.invitations_comptable
     SET revoquee_le = pg_catalog.now(), revoquee_par = auth.uid()
   WHERE id = v_id AND revoquee_le IS NULL AND utilisee_le IS NULL
     AND expire_le > pg_catalog.now();
  IF FOUND THEN
    PERFORM public.log_sensitive_access('invitation_comptable_revoquee', 'invitations_comptable',
      v_id::text, '{}'::jsonb);
  END IF;
END;
$function$;

CREATE FUNCTION public.verifier_invitation_comptable(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text;
  v_ligne public.invitations_comptable;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = auth.uid();
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_email IS NOT NULL, false) THEN
    RAISE EXCEPTION 'verification reservee a une session d''inscription' USING ERRCODE = '42501';
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_comptable i
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

CREATE FUNCTION public.inscrire_comptable_invite(
  p_code text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_ligne public.invitations_comptable;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = v_uid;
  IF NOT coalesce(
    v_uid IS NOT NULL AND v_email IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid),
    false
  ) THEN
    RAISE EXCEPTION 'inscription comptable reservee a une session sans profil' USING ERRCODE = '42501';
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_comptable i
   WHERE i.code = pg_catalog.upper(pg_catalog.btrim(coalesce(p_code, '')))
     AND i.email = v_email AND i.revoquee_le IS NULL
   FOR UPDATE;
  IF v_ligne.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'inconnue');
  END IF;
  IF v_ligne.utilisee_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'deja_utilisee');
  END IF;
  IF v_ligne.expire_le <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'expiree');
  END IF;
  IF coalesce(pg_catalog.btrim(p_first_name), '') = '' OR coalesce(pg_catalog.btrim(p_last_name), '') = '' THEN
    RAISE EXCEPTION 'prenom et nom sont requis' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  VALUES (v_uid, NULL, 'accountant', NULL,
    pg_catalog.btrim(p_first_name), pg_catalog.btrim(p_last_name), p_gender, 'active');
  PERFORM public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    pg_catalog.jsonb_build_object('role', 'accountant', 'source', 'invitation'));

  UPDATE public.invitations_comptable i
     SET utilisee_le = pg_catalog.clock_timestamp(), utilisee_par = v_uid
   WHERE i.id = v_ligne.id;
  PERFORM public.log_sensitive_access('invitation_comptable_consommee', 'invitations_comptable',
    v_ligne.id::text, pg_catalog.jsonb_build_object('profile_id', v_uid));
  RETURN pg_catalog.jsonb_build_object('resultat', 'consommee');
END;
$function$;

ALTER FUNCTION public.invitations_comptable_admin() OWNER TO postgres;
ALTER FUNCTION public.inviter_comptable(text) OWNER TO postgres;
ALTER FUNCTION public.revoquer_invitation_comptable(text) OWNER TO postgres;
ALTER FUNCTION public.verifier_invitation_comptable(text) OWNER TO postgres;
ALTER FUNCTION public.inscrire_comptable_invite(text, text, text, public.gender) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.invitations_comptable_admin() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.inviter_comptable(text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.revoquer_invitation_comptable(text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.verifier_invitation_comptable(text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.inscrire_comptable_invite(text, text, text, public.gender)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitations_comptable_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.inviter_comptable(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoquer_invitation_comptable(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verifier_invitation_comptable(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.inscrire_comptable_invite(text, text, text, public.gender) TO authenticated;

COMMENT ON FUNCTION public.inviter_comptable(text) IS
  'BF1-03: guard_type=ROLE_POSITIVE_TEMPLATE; garde: direction active en aal2. DEFINER: lecture de auth.users et profiles. date=2026-10-17.';
COMMENT ON FUNCTION public.revoquer_invitation_comptable(text) IS
  'BF1-03: guard_type=ROLE_POSITIVE_TEMPLATE; garde: direction active. date=2026-10-17.';
COMMENT ON FUNCTION public.verifier_invitation_comptable(text) IS
  'BF1-03: guard_type=SESSION_POSITIVE; garde: session auth existante; code lie a l''adresse de la session. date=2026-10-17.';
COMMENT ON FUNCTION public.inscrire_comptable_invite(text, text, text, public.gender) IS
  'BF1-03: guard_type=SESSION_POSITIVE; garde: session auth avec adresse, sans profil; code lie a l''adresse de la session, usage unique. Cree le profil accountant. date=2026-10-17.';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.inviter_comptable(text)'::regprocedure,
    'public.revoquer_invitation_comptable(text)'::regprocedure,
    'public.verifier_invitation_comptable(text)'::regprocedure,
    'public.inscrire_comptable_invite(text,text,text,public.gender)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'BF1-03 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid = 'public.invitations_comptable_admin()'::regprocedure
                AND (p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
                     OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'BF1-03 : invitations_comptable_admin invalide';
  END IF;
END;
$postflight$;

COMMIT;
