-- BE-2a-2 (pilote, 16/11/2026) : inviter un associe, une personne sans compte, avec le role `associe`
-- (ajoute par 20261129770000). Cahier : docs/current/BUREAU-EQUIPE/CAHIER-BE-2A-2-ASSOCIE.md. Modele :
-- 20261017160200_bf1_03_invitation_comptable.sql.
--
-- UN SEUL MOT D'EFFACEMENT DANS CE FICHIER : le retrait de la contrainte `profiles_household_required`, section 1,
-- pour la reecrire (seule exception admise, supabase/CLAUDE.md). Constat : cette contrainte exige un foyer a tout
-- profil dont le role n'est pas admin, accountant, controller ou teacher. Un `associe` n'a pas de foyer : sans
-- cette reecriture, la creation de son profil echoue. La contrainte reecrite n'ajoute que `associe` a la liste.
-- Aucune ligne existante ne devient invalide. Un rejeu ne change rien.
--
-- Ce que fait ce fichier :
--   1. la contrainte `profiles_household_required` admet `associe` sans foyer ;
--   2. la table `invitations_associe` (lecture : la direction active ; aucun autre droit) ;
--   3. `inviter_associe(courriel, nom, cle)`, direction active en double verification (aal2), idempotente par
--      cle ; `revoquer_invitation_associe(id, motif, cle)` ; `verifier_invitation_associe(code)` ;
--      `inscrire_associe_invite(code, prenom, nom, genre)` : cree le profil `associe` actif, sans foyer, sans
--      aucun droit ; `invitations_associe_admin()` : la liste pour la direction ;
--   4. `accorder_mission` accepte `associe` et n'accepte plus `controller` (arbitrage du 16/11 : `controller`
--      est ecarte) ; aucun compte `controller` n'existe en production (releve du 16/11).
-- Le crochet de jeton (`custom_access_token_hook`) n'est PAS modifie : il lit le role du profil tel quel et rend
-- toujours l'evenement ; `scenarios_be2a2_associe.sql` prouve que le jeton d'un associe n'est jamais null.
-- Le texte du courriel d'invitation n'est PAS ecrit ici : le code de l'invitation est lu par la direction
-- (`invitations_associe_admin`), comme pour le comptable ; le courriel se demande au pilote (mots-rewayah).
-- Les ecrans sont hors de ce lot (BE-2b).

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_enum e JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
                  WHERE t.typname = 'app_role' AND e.enumlabel = 'associe') THEN
    RAISE EXCEPTION 'BE-2a-2 : installer d''abord 20261129770000_be2a2_role_associe.sql (role associe absent)';
  END IF;
  IF pg_catalog.to_regclass('public.invitations_associe') IS NOT NULL THEN
    RAISE EXCEPTION 'BE-2a-2 : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('public.accorder_mission(uuid,uuid,jsonb,timestamptz,timestamptz,uuid)') IS NULL THEN
    RAISE EXCEPTION 'BE-2a-2 : les missions (BE-2a-1, 20261129420000) doivent etre installees d''abord';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.profiles'::regclass AND c.conname = 'profiles_household_required') THEN
    RAISE EXCEPTION 'BE-2a-2 : la contrainte profiles_household_required est absente';
  END IF;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'BE-2a-2 : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 1. La contrainte du foyer admet `associe`
-- ============================================================
DO $contrainte$
DECLARE
  v_def text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.profiles'::regclass AND c.conname = 'profiles_household_required';
  IF v_def NOT LIKE '%''admin''::app_role%' OR v_def NOT LIKE '%''teacher''::app_role%'
     OR v_def NOT LIKE '%household_id IS NOT NULL%' OR v_def LIKE '%associe%' THEN
    RAISE EXCEPTION 'BE-2a-2 : la contrainte profiles_household_required n''est pas celle attendue : %', v_def;
  END IF;
  ALTER TABLE public.profiles DROP CONSTRAINT profiles_household_required;
  ALTER TABLE public.profiles ADD CONSTRAINT profiles_household_required
    CHECK (role = ANY (ARRAY['admin'::public.app_role, 'accountant'::public.app_role, 'controller'::public.app_role,
                             'teacher'::public.app_role, 'associe'::public.app_role])
           OR household_id IS NOT NULL);
END
$contrainte$;

-- ============================================================
-- 2. La table des invitations
-- ============================================================
CREATE TABLE public.invitations_associe (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$'),
  email text NOT NULL CHECK (email = pg_catalog.lower(pg_catalog.btrim(email))
                             AND pg_catalog.length(email) BETWEEN 3 AND 254),
  nom text NULL CHECK (nom IS NULL OR pg_catalog.length(pg_catalog.btrim(nom)) BETWEEN 1 AND 200),
  cree_par uuid NOT NULL REFERENCES public.profiles(id),
  cle_emission uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL,
  revoquee_le timestamptz,
  revoquee_par uuid REFERENCES public.profiles(id),
  motif_revocation text,
  cle_revocation uuid,
  utilisee_le timestamptz,
  utilisee_par uuid REFERENCES auth.users(id),
  CONSTRAINT invitations_associe_echeance CHECK (expire_le > cree_le),
  CONSTRAINT invitations_associe_revocation CHECK ((revoquee_le IS NULL) = (revoquee_par IS NULL)
                                                   AND (revoquee_le IS NULL) = (motif_revocation IS NULL)),
  CONSTRAINT invitations_associe_utilisation CHECK ((utilisee_le IS NULL) = (utilisee_par IS NULL)),
  CONSTRAINT invitations_associe_exclusif CHECK (revoquee_le IS NULL OR utilisee_le IS NULL),
  CONSTRAINT invitations_associe_cle UNIQUE (cree_par, cle_emission)
);
CREATE INDEX invitations_associe_email_idx
  ON public.invitations_associe (email) WHERE revoquee_le IS NULL AND utilisee_le IS NULL;
CREATE INDEX invitations_associe_recentes_idx ON public.invitations_associe (cree_le DESC);

ALTER TABLE public.invitations_associe ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invitations_associe FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.invitations_associe TO authenticated;
CREATE POLICY invitations_associe_direction_lecture ON public.invitations_associe
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- ============================================================
-- 3. Les portes
-- ============================================================
CREATE FUNCTION app_private.invitation_associe_json(i public.invitations_associe)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', i.id, 'code', i.code, 'email', i.email, 'nom', i.nom, 'expire_le', i.expire_le,
    'etat', CASE WHEN i.utilisee_le IS NOT NULL THEN 'utilisee'
                 WHEN i.revoquee_le IS NOT NULL THEN 'revoquee'
                 WHEN i.expire_le <= pg_catalog.now() THEN 'expiree'
                 ELSE 'active' END,
    'utilisee_le', i.utilisee_le);
$function$;
REVOKE ALL ON FUNCTION app_private.invitation_associe_json(public.invitations_associe)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION app_private.invitation_associe_json(public.invitations_associe) TO authenticated;

CREATE FUNCTION public.invitations_associe_admin()
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
    SELECT pg_catalog.jsonb_agg(app_private.invitation_associe_json(i) ORDER BY i.cree_le DESC, i.id DESC)
    FROM public.invitations_associe i), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.inviter_associe(p_courriel text, p_nom text, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_courriel, '')));
  v_nom text := nullif(pg_catalog.btrim(coalesce(p_nom, '')), '');
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_ligne public.invitations_associe;
  v_octets bytea;
  v_code text;
  v_i integer;
  v_essai integer := 0;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid()
                  AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'invitation d''un associe reservee a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL THEN
    RAISE EXCEPTION 'cle d''idempotence attendue' USING ERRCODE = '22023';
  END IF;
  IF v_nom IS NOT NULL AND pg_catalog.length(v_nom) > 200 THEN
    RAISE EXCEPTION 'nom trop long' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(v_email) NOT BETWEEN 3 AND 254
     OR v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'email_invalide', 'invitation', NULL);
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('invitation-associe:' || v_email, 0));

  -- Le meme geste rejoue (meme cle) : la meme reponse, rien d'ecrit une seconde fois.
  SELECT i.* INTO v_ligne FROM public.invitations_associe i
   WHERE i.cree_par = auth.uid() AND i.cle_emission = p_cle;
  IF v_ligne.id IS NOT NULL THEN
    IF v_ligne.email <> v_email THEN
      RAISE EXCEPTION 'cle d''idempotence deja utilisee pour une autre adresse' USING ERRCODE = '22023';
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'creee', 'rejoue', true,
      'invitation', app_private.invitation_associe_json(v_ligne));
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id = u.id
              WHERE pg_catalog.lower(u.email) = v_email AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'compte_existant', 'invitation', NULL);
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_associe i
   WHERE i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
     AND i.expire_le > pg_catalog.now()
   ORDER BY i.cree_le DESC LIMIT 1;
  IF v_ligne.id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_invite',
      'invitation', app_private.invitation_associe_json(v_ligne));
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
      INSERT INTO public.invitations_associe (code, email, nom, cree_par, cle_emission, expire_le)
      VALUES (v_code, v_email, v_nom, auth.uid(), p_cle,
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

  PERFORM public.log_sensitive_access('invitation_associe_emise', 'invitations_associe',
    v_ligne.id::text, '{}'::jsonb);
  RETURN pg_catalog.jsonb_build_object('statut', 'creee',
    'invitation', app_private.invitation_associe_json(v_ligne));
END;
$function$;

CREATE FUNCTION public.revoquer_invitation_associe(p_id uuid, p_motif text, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_ligne public.invitations_associe;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'revocation reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR p_cle IS NULL OR v_motif = '' OR pg_catalog.length(v_motif) > 2000 THEN
    RAISE EXCEPTION 'parametres de revocation invalides' USING ERRCODE = '22023';
  END IF;
  SELECT i.* INTO v_ligne FROM public.invitations_associe i WHERE i.id = p_id FOR UPDATE;
  IF v_ligne.id IS NULL THEN
    RAISE EXCEPTION 'invitation introuvable' USING ERRCODE = 'P0002';
  END IF;
  -- Rejouee (meme cle) : la meme reponse.
  IF v_ligne.revoquee_le IS NOT NULL THEN
    IF v_ligne.cle_revocation = p_cle THEN
      RETURN pg_catalog.jsonb_build_object('statut', 'revoquee', 'rejoue', true,
        'invitation', app_private.invitation_associe_json(v_ligne));
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_revoquee',
      'invitation', app_private.invitation_associe_json(v_ligne));
  END IF;
  IF v_ligne.utilisee_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('statut', 'deja_utilisee',
      'invitation', app_private.invitation_associe_json(v_ligne));
  END IF;
  UPDATE public.invitations_associe
     SET revoquee_le = pg_catalog.clock_timestamp(), revoquee_par = auth.uid(),
         motif_revocation = v_motif, cle_revocation = p_cle
   WHERE id = p_id
  RETURNING * INTO v_ligne;
  PERFORM public.log_sensitive_access('invitation_associe_revoquee', 'invitations_associe',
    p_id::text, '{}'::jsonb);
  RETURN pg_catalog.jsonb_build_object('statut', 'revoquee',
    'invitation', app_private.invitation_associe_json(v_ligne));
END;
$function$;

CREATE FUNCTION public.verifier_invitation_associe(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text;
  v_ligne public.invitations_associe;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = auth.uid();
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_email IS NOT NULL, false) THEN
    RAISE EXCEPTION 'verification reservee a une session d''inscription' USING ERRCODE = '42501';
  END IF;
  SELECT i.* INTO v_ligne FROM public.invitations_associe i
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

CREATE FUNCTION public.inscrire_associe_invite(
  p_code text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender
) RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_ligne public.invitations_associe;
BEGIN
  SELECT pg_catalog.lower(u.email) INTO v_email FROM auth.users u WHERE u.id = v_uid;
  IF NOT coalesce(
    v_uid IS NOT NULL AND v_email IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid),
    false
  ) THEN
    RAISE EXCEPTION 'inscription d''un associe reservee a une session sans profil' USING ERRCODE = '42501';
  END IF;

  SELECT i.* INTO v_ligne FROM public.invitations_associe i
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
  -- Une mission se porte du cote de la personne (BE-2a-1) : sans genre connu, aucune mission ne peut lui etre
  -- accordee. Le genre est donc requis a l'inscription.
  IF p_gender IS NULL THEN
    RAISE EXCEPTION 'le genre est requis' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
  VALUES (v_uid, NULL, 'associe', NULL,
    pg_catalog.btrim(p_first_name), pg_catalog.btrim(p_last_name), p_gender, 'active');
  PERFORM public.log_sensitive_access('profil_cree', 'profiles', v_uid::text,
    pg_catalog.jsonb_build_object('role', 'associe', 'source', 'invitation'));

  UPDATE public.invitations_associe i
     SET utilisee_le = pg_catalog.clock_timestamp(), utilisee_par = v_uid
   WHERE i.id = v_ligne.id;
  PERFORM public.log_sensitive_access('invitation_associe_consommee', 'invitations_associe',
    v_ligne.id::text, pg_catalog.jsonb_build_object('profile_id', v_uid));
  RETURN pg_catalog.jsonb_build_object('resultat', 'consommee');
END;
$function$;

ALTER FUNCTION public.invitations_associe_admin() OWNER TO postgres;
ALTER FUNCTION public.inviter_associe(text, text, uuid) OWNER TO postgres;
ALTER FUNCTION public.revoquer_invitation_associe(uuid, text, uuid) OWNER TO postgres;
ALTER FUNCTION public.verifier_invitation_associe(text) OWNER TO postgres;
ALTER FUNCTION public.inscrire_associe_invite(text, text, text, public.gender) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.invitations_associe_admin() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.inviter_associe(text, text, uuid) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.revoquer_invitation_associe(uuid, text, uuid) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.verifier_invitation_associe(text) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.inscrire_associe_invite(text, text, text, public.gender)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitations_associe_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.inviter_associe(text, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoquer_invitation_associe(uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verifier_invitation_associe(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.inscrire_associe_invite(text, text, text, public.gender) TO authenticated;

COMMENT ON FUNCTION public.inviter_associe(text, text, uuid) IS
  'BE-2a-2: guard_type=ROLE_POSITIVE_TEMPLATE; garde: direction active en aal2; idempotente par cle. DEFINER: lecture de auth.users et profiles. date=2026-11-17.';
COMMENT ON FUNCTION public.revoquer_invitation_associe(uuid, text, uuid) IS
  'BE-2a-2: guard_type=ROLE_POSITIVE_TEMPLATE; garde: direction active; motif ecrit, idempotente par cle. date=2026-11-17.';
COMMENT ON FUNCTION public.verifier_invitation_associe(text) IS
  'BE-2a-2: guard_type=SESSION_POSITIVE; garde: session auth existante; code lie a l''adresse de la session. date=2026-11-17.';
COMMENT ON FUNCTION public.inscrire_associe_invite(text, text, text, public.gender) IS
  'BE-2a-2: guard_type=SESSION_POSITIVE; garde: session auth avec adresse, sans profil; code lie a l''adresse de la session, usage unique. Cree le profil associe, sans foyer, sans droit. date=2026-11-17.';

-- ============================================================
-- 4. accorder_mission : associe oui, controller non (retouche par ancrage, une ancre)
-- ============================================================
DO $mission$
DECLARE
  v_def text;
BEGIN
  v_def := pg_catalog.pg_get_functiondef('public.accorder_mission(uuid,uuid,jsonb,timestamptz,timestamptz,uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, '''associe''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'p.role IN (''teacher''::public.app_role, ''controller''::public.app_role, ''accountant''::public.app_role)',
      'p.role IN (''teacher''::public.app_role, ''accountant''::public.app_role, ''associe''::public.app_role)',
      'accorder.roles');
    EXECUTE v_def;
  END IF;
END
$mission$;

-- ============================================================
-- 5. Bibliotheque : l'associe ne lit AUCUN document hors `publique` (audit du pilote, 17/11/2026)
--    Cause : la politique library_resource_lecture et private.n4_ressource_lisible donnent
--    `inscrits` a tout compte valide, et private.tranche_autorisee rend true pour tout role autre
--    qu'eleve ou parent. Correctif : `inscrits` n'est lisible que par les six roles qui l'avaient
--    deja ; l'associe garde `publique` seulement. Trois retouches par ancrage (une ancre chacune).
--    autoriser_lecture_version refuse deja l'associe a sa porte de role ; la meme regle y est posee
--    pour que les trois chemins disent la meme chose (son empreinte F86 est rafraichie).
-- ============================================================
DO $biblio$
DECLARE
  v_qual text;
  v_def text;
  v_md5 text;
  v_com text;
BEGIN
  -- a. La politique de lecture de library_resource (USING seulement ; role, commande et WITH CHECK inchanges).
  SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) INTO v_qual
    FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.library_resource'::regclass AND p.polname = 'library_resource_lecture';
  IF v_qual IS NULL THEN
    RAISE EXCEPTION 'BE-2a-2 : politique library_resource_lecture introuvable';
  END IF;
  IF pg_catalog.strpos(v_qual, 'accountant') = 0 THEN
    v_qual := pg_temp.remplacer(v_qual,
      '(access_policy = ANY (ARRAY[''publique''::library_access_policy, ''inscrits''::library_access_policy]))',
      '((access_policy = ''publique''::library_access_policy) OR ((access_policy = ''inscrits''::library_access_policy) AND ((SELECT app_role() AS app_role) = ANY (ARRAY[''admin''::app_role, ''accountant''::app_role, ''controller''::app_role, ''teacher''::app_role, ''guardian''::app_role, ''student''::app_role]))))',
      'bibliotheque.politique');
    EXECUTE pg_catalog.format('ALTER POLICY library_resource_lecture ON public.library_resource USING (%s)', v_qual);
  END IF;

  -- b. private.n4_ressource_lisible.
  v_def := pg_catalog.pg_get_functiondef('private.n4_ressource_lisible(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'accountant') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'r.access_policy IN (''publique'', ''inscrits'')',
      '(r.access_policy = ''publique'' OR (r.access_policy = ''inscrits'' AND public.app_role() IN (''admin'', ''accountant'', ''controller'', ''teacher'', ''guardian'', ''student'')))',
      'bibliotheque.n4');
    EXECUTE v_def;
  END IF;

  -- c. public.autoriser_lecture_version (meme regle ; empreinte F86 rafraichie).
  v_def := pg_catalog.pg_get_functiondef('public.autoriser_lecture_version(uuid)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'BE-2a-2') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'r.access_policy in (''publique'', ''inscrits'')',
      '(r.access_policy = ''publique'' OR (r.access_policy = ''inscrits'' AND v_role IN (''admin'', ''accountant'', ''controller'', ''teacher'', ''guardian'', ''student'')))  -- BE-2a-2',
      'bibliotheque.lecture_version');
    EXECUTE v_def;
    v_md5 := pg_catalog.md5(pg_catalog.pg_get_functiondef('public.autoriser_lecture_version(uuid)'::regprocedure));
    v_com := pg_catalog.obj_description('public.autoriser_lecture_version(uuid)'::regprocedure, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+', 'md5_functiondef=' || v_md5);
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.autoriser_lecture_version(uuid) IS %L', v_com);
    END IF;
  END IF;
END
$biblio$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.inviter_associe(text,text,uuid)'::regprocedure,
    'public.revoquer_invitation_associe(uuid,text,uuid)'::regprocedure,
    'public.verifier_invitation_associe(text)'::regprocedure,
    'public.inscrire_associe_invite(text,text,text,public.gender)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'BE-2a-2 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid = 'public.invitations_associe_admin()'::regprocedure
                AND (p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
                     OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'BE-2a-2 : invitations_associe_admin invalide';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.invitations_associe'::regclass)
     OR pg_catalog.has_table_privilege('anon', 'public.invitations_associe', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.invitations_associe', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.invitations_associe', 'UPDATE') THEN
    RAISE EXCEPTION 'BE-2a-2 : invitations_associe ouverte ou sans RLS';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.accorder_mission(uuid,uuid,jsonb,timestamptz,timestamptz,uuid)'::regprocedure), '''associe''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_constraintdef((SELECT c.oid FROM pg_catalog.pg_constraint c
          WHERE c.conrelid = 'public.profiles'::regclass AND c.conname = 'profiles_household_required')),
          'associe') = 0 THEN
    RAISE EXCEPTION 'BE-2a-2 : retouche absente';
  END IF;
  IF pg_catalog.strpos((SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) FROM pg_catalog.pg_policy p
        WHERE p.polrelid = 'public.library_resource'::regclass AND p.polname = 'library_resource_lecture'), 'accountant') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.n4_ressource_lisible(uuid)'::regprocedure), 'accountant') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.autoriser_lecture_version(uuid)'::regprocedure), 'BE-2a-2') = 0 THEN
    RAISE EXCEPTION 'BE-2a-2 : retouche de la bibliotheque absente';
  END IF;
END
$postflight$;
