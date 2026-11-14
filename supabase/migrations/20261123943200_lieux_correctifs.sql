-- HORLOGE-ET-LIEU : correctifs de la partie B, demandes par l'architecte
-- pedagogique apres la revue independante de la tete d85f9ac0c (13/11/2026).
--
-- 1. BLOQUANT. Le candidat enseignant (compte `teacher` en `pending_kyc`) ne
--    pouvait plus enregistrer sa ville : `enregistrer_ma_ville` exigeait un compte
--    actif. Arbitrage de l'architecte : on accepte `pending_kyc` pour le SEUL role
--    `teacher`, sur son PROPRE lieu seulement ; rien d'autre n'est ouvert (un
--    tuteur en attente, un compte desactive ou supprime restent refuses). L'adulte
--    « pour moi » est un compte `guardian` avec son foyer d'une personne (0052) :
--    il passe par la branche du tuteur, deja ouverte.
-- 2. Suppression de compte : `private.cpt_anonymiser` efface le lieu du profil (un
--    enseignant) et la ligne du foyer quand le dernier tuteur actif est efface
--    (donnee personnelle), ainsi que le rappel de report de la ville.
--
-- 3. Le lieu de priere d'un enseignant suit sa ville (relais vers PRIERE-2).
--
-- Deux fonctions remplacees par leur copie complete (CREATE OR REPLACE), une
-- fonction et un declencheur crees ; aucun objet retire. Les DELETE de cpt_anonymiser sont dans la fonction, pas dans la
-- migration.

BEGIN;

DO $preflight$
DECLARE
  v_attendu constant jsonb := pg_catalog.jsonb_build_object(
    'public.enregistrer_ma_ville(bigint)', 'd663566927e60e4636f2d5f9c9156ad3',
    'private.cpt_anonymiser(uuid)',        'f70666beefcaad5cb4cfbab5124352f7');
  v_f text;
  v_empreinte text;
BEGIN
  FOR v_f IN SELECT k FROM pg_catalog.jsonb_object_keys(v_attendu) AS k LOOP
    SELECT pg_catalog.md5(p.prosrc) INTO v_empreinte
      FROM pg_catalog.pg_proc p WHERE p.oid = v_f::pg_catalog.regprocedure;
    IF v_empreinte IS DISTINCT FROM (v_attendu ->> v_f) THEN
      RAISE EXCEPTION 'HORLOGE-ET-LIEU : % a change depuis le releve (empreinte %), migration refusee',
        v_f, v_empreinte;
    END IF;
  END LOOP;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Choisir sa ville : le candidat enseignant y a droit
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enregistrer_ma_ville(p_ville_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_role text;
  v_foyer uuid;
  v_v public.villes_ref%ROWTYPE;
  v_ancien text;
  v_id uuid;
  v_relire boolean := false;
  v_valide boolean;
  v_candidat boolean := false;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'ville non autorisee' USING ERRCODE = '42501';
  END IF;
  v_valide := coalesce(public.app_account_valid(), false);
  -- Revue du 13/11/2026 : le candidat enseignant (compte `teacher` en
  -- `pending_kyc`, invite par la direction) choisit sa ville pendant sa
  -- candidature. Seul ce cas est ouvert, et seulement pour SON propre lieu :
  -- ni un tuteur, ni un autre statut, ni un compte supprime.
  IF NOT v_valide THEN
    v_candidat := public.app_role() = 'teacher'
      AND EXISTS (SELECT 1 FROM public.profiles p
                   WHERE p.id = v_uid AND p.role = 'teacher'::public.app_role
                     AND p.account_status = 'pending_kyc'::public.account_status
                     AND p.deleted_at IS NULL);
  END IF;
  IF NOT (v_valide OR v_candidat) THEN
    RAISE EXCEPTION 'ville non autorisee' USING ERRCODE = '42501';
  END IF;
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NULL OR (v_candidat AND v_role IS DISTINCT FROM 'teacher') THEN
    RAISE EXCEPTION 'la ville se choisit par un tuteur ou un enseignant' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_v FROM public.villes_ref WHERE id = p_ville_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ville inconnue' USING ERRCODE = '22023';
  END IF;

  IF v_role = 'guardian' THEN
    SELECT h.timezone INTO v_ancien FROM public.households h WHERE h.id = v_foyer AND h.deleted_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'foyer introuvable' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.lieux (foyer_id, ville_id, ville, pays_code, fuseau_iana, latitude, longitude, saisi_par)
    VALUES (v_foyer, v_v.id, v_v.nom, v_v.pays_code, v_v.fuseau_iana, v_v.latitude, v_v.longitude, v_uid)
    ON CONFLICT (foyer_id) DO UPDATE
      SET ville_id = EXCLUDED.ville_id, ville = EXCLUDED.ville, pays_code = EXCLUDED.pays_code,
          fuseau_iana = EXCLUDED.fuseau_iana, latitude = EXCLUDED.latitude,
          longitude = EXCLUDED.longitude, saisi_par = EXCLUDED.saisi_par,
          maj_le = pg_catalog.now(), verifie_par = NULL, verifie_le = NULL
    RETURNING id INTO v_id;
    UPDATE public.households SET timezone = v_v.fuseau_iana WHERE id = v_foyer;
  ELSE
    SELECT tp.timezone_iana INTO v_ancien FROM public.teacher_profiles tp
     WHERE tp.profile_id = v_uid AND tp.deleted_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'profil enseignant introuvable' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.lieux (profil_id, ville_id, ville, pays_code, fuseau_iana, latitude, longitude, saisi_par)
    VALUES (v_uid, v_v.id, v_v.nom, v_v.pays_code, v_v.fuseau_iana, v_v.latitude, v_v.longitude, v_uid)
    ON CONFLICT (profil_id) DO UPDATE
      SET ville_id = EXCLUDED.ville_id, ville = EXCLUDED.ville, pays_code = EXCLUDED.pays_code,
          fuseau_iana = EXCLUDED.fuseau_iana, latitude = EXCLUDED.latitude,
          longitude = EXCLUDED.longitude, saisi_par = EXCLUDED.saisi_par,
          maj_le = pg_catalog.now(), verifie_par = NULL, verifie_le = NULL
    RETURNING id INTO v_id;
    UPDATE public.teacher_profiles
       SET timezone_iana = v_v.fuseau_iana, country = v_v.pays_code
     WHERE profile_id = v_uid;
    -- Les disponibilites gardent leurs instants (chaque ligne porte son fuseau) :
    -- rien n'est converti ; l'enseignant doit les relire.
    v_relire := v_ancien IS DISTINCT FROM v_v.fuseau_iana
      AND EXISTS (SELECT 1 FROM public.weekly_availability w WHERE w.profile_id = v_uid);
  END IF;

  -- Le journal ne porte ni coordonnees ni nom de ville : l'identifiant et le pays.
  PERFORM public.log_sensitive_access(
    'lieu_enregistre', 'lieux', v_id::text,
    pg_catalog.jsonb_build_object('role', v_role, 'ville_id', v_v.id, 'pays', v_v.pays_code));

  RETURN pg_catalog.jsonb_build_object(
    'ville', v_v.nom, 'pays_code', v_v.pays_code, 'fuseau_iana', v_v.fuseau_iana,
    'disponibilites_a_relire', v_relire);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. L'anonymisation efface aussi le lieu
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.cpt_anonymiser(p uuid)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_colonnes text[];
  v_sets text[] := ARRAY[]::text[];
  v_foyer uuid;
BEGIN
  SELECT pr.household_id INTO v_foyer FROM public.profiles pr
   WHERE pr.id = p AND pr.role = 'guardian'::public.app_role;
  UPDATE public.profiles
     SET first_name = 'Compte', last_name = 'supprimé', gender = NULL,
         account_status = 'disabled', access_until = pg_catalog.clock_timestamp()
   WHERE id = p;
  UPDATE public.student_profiles
     SET avatar_storage_key = NULL, objectif = NULL
   WHERE profile_id = p;
  UPDATE public.teacher_profiles
     SET photo_storage_key = NULL, country = NULL, titre = NULL
   WHERE profile_id = p;
  DELETE FROM public.prayer_settings WHERE teacher_id = p;
  DELETE FROM public.weekly_availability WHERE profile_id = p;
  DELETE FROM public.device_tokens WHERE profile_id = p;
  -- HORLOGE-ET-LIEU (revue du 13/11/2026) : la ville est une donnee personnelle.
  -- Celle d'un enseignant part avec lui ; celle du foyer part avec le foyer, c'est
  -- a dire quand il ne reste aucun tuteur actif (celui qu'on efface etait le
  -- dernier). Le rappel de report de la ville part avec le profil.
  DELETE FROM public.lieux WHERE profil_id = p;
  DELETE FROM private.lieux_reports WHERE profil_id = p;
  IF v_foyer IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.profiles t
        WHERE t.household_id = v_foyer AND t.id <> p
          AND t.role = 'guardian'::public.app_role AND t.deleted_at IS NULL
          AND t.account_status <> 'disabled'::public.account_status) THEN
    DELETE FROM public.lieux WHERE foyer_id = v_foyer;
  END IF;
  UPDATE public.devices
     SET label = NULL, revoked_at = coalesce(revoked_at, pg_catalog.clock_timestamp())
   WHERE profile_id = p;
  -- La piece d'identite deposee part a la prochaine purge (`purge_at` echu).
  UPDATE public.kyc_documents
     SET purge_at = least(coalesce(purge_at, pg_catalog.clock_timestamp()), pg_catalog.clock_timestamp())
   WHERE profile_id = p AND deleted_at IS NULL;
  UPDATE public.payout_methods
     SET details = '{}'::jsonb, deleted_at = coalesce(deleted_at, pg_catalog.clock_timestamp())
   WHERE profile_id = p;
  -- Les adresses de tiers invites par la personne.
  UPDATE public.invitations_foyer
     SET email_invite = 'efface-' || id::text || '@invalide.rewayah.invalid'
   WHERE invite_par = p;

  -- Le compte de connexion : courriel, telephone, identite du fournisseur, sessions.
  -- Colonnes et tables lues au catalogue : le schema `auth` est celui de Supabase.
  SELECT pg_catalog.array_agg(c.column_name::text) INTO v_colonnes
    FROM information_schema.columns c
   WHERE c.table_schema = 'auth' AND c.table_name = 'users'
     AND c.column_name IN ('email', 'phone', 'raw_user_meta_data', 'banned_until');
  IF v_colonnes @> ARRAY['email'] THEN
    v_sets := v_sets || ARRAY['email = ' || pg_catalog.quote_literal('efface-' || p::text || '@invalide.rewayah.invalid')];
  END IF;
  IF v_colonnes @> ARRAY['phone'] THEN
    v_sets := v_sets || ARRAY['phone = NULL'];
  END IF;
  IF v_colonnes @> ARRAY['raw_user_meta_data'] THEN
    v_sets := v_sets || ARRAY['raw_user_meta_data = ''{}''::jsonb'];
  END IF;
  IF v_colonnes @> ARRAY['banned_until'] THEN
    v_sets := v_sets || ARRAY['banned_until = ''infinity''::timestamptz'];
  END IF;
  IF pg_catalog.cardinality(v_sets) > 0 THEN
    EXECUTE pg_catalog.format('UPDATE auth.users SET %s WHERE id = %L',
      pg_catalog.array_to_string(v_sets, ', '), p);
  END IF;
  IF pg_catalog.to_regclass('auth.identities') IS NOT NULL THEN
    EXECUTE pg_catalog.format('DELETE FROM auth.identities WHERE user_id = %L', p);
  END IF;
  IF pg_catalog.to_regclass('auth.sessions') IS NOT NULL THEN
    EXECUTE pg_catalog.format('DELETE FROM auth.sessions WHERE user_id = %L', p);
  END IF;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Le lieu de priere suit la ville de l'enseignant (decision du directeur du
--    13/11/2026 : aucune saisie a la main des lieux de priere ; contrat de
--    PRIERE-2 : `private.priere_lieu_auto(enseignant, nom, lat, lng, fuseau)`).
--    Le declencheur appelle cette fonction SI ELLE EXISTE, pour les seuls profils
--    enseignants ; rien sinon. Une erreur ici n'empeche JAMAIS l'enregistrement de
--    la ville. Il ne touche ni `prayer_settings` ni `lib/core/priere` : il ne fait
--    que passer le relais. PRIERE-2 pose le meme declencheur (`lieux_priere_auto`) :
--    celui qui arrive le premier reste, l'autre ne fait rien.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.lieux_priere_auto_relais()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_f pg_catalog.regprocedure;
BEGIN
  BEGIN
    IF NEW.profil_id IS NULL THEN
      RETURN NULL;
    END IF;
    IF TG_OP = 'UPDATE'
       AND OLD.ville_id IS NOT DISTINCT FROM NEW.ville_id
       AND OLD.ville IS NOT DISTINCT FROM NEW.ville
       AND OLD.latitude IS NOT DISTINCT FROM NEW.latitude
       AND OLD.longitude IS NOT DISTINCT FROM NEW.longitude
       AND OLD.fuseau_iana IS NOT DISTINCT FROM NEW.fuseau_iana THEN
      RETURN NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.profiles p
                    WHERE p.id = NEW.profil_id AND p.role = 'teacher'::public.app_role) THEN
      RETURN NULL;
    END IF;
    v_f := pg_catalog.to_regprocedure('private.priere_lieu_auto(uuid,text,numeric,numeric,text)');
    IF v_f IS NULL THEN
      RETURN NULL;
    END IF;
    EXECUTE pg_catalog.format(
      'SELECT private.priere_lieu_auto(%L::uuid, %L::text, %L::numeric, %L::numeric, %L::text)',
      NEW.profil_id, NEW.ville, NEW.latitude, NEW.longitude, NEW.fuseau_iana);
  EXCEPTION WHEN OTHERS THEN
    -- Jamais d'echec de l'enregistrement de la ville pour un lieu de priere.
    RAISE WARNING 'lieux_priere_auto : lieu de priere non mis a jour (%)', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;
REVOKE ALL ON FUNCTION private.lieux_priere_auto_relais() FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.lieux_priere_auto_relais() IS
  'HORLOGE-ET-LIEU (13/11/2026) : relais vers private.priere_lieu_auto (PRIERE-2) quand un enseignant enregistre ou change sa ville ; ne fait rien si la fonction n''existe pas ; ne fait jamais echouer l''enregistrement. DEFINER, search_path vide, aucun EXECUTE client.';

-- Idempotent, sans effacement : le declencheur n'est cree que s'il n'existe pas.
DO $declencheur$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.lieux'::pg_catalog.regclass
                    AND t.tgname = 'lieux_priere_auto' AND NOT t.tgisinternal) THEN
    CREATE TRIGGER lieux_priere_auto
      AFTER INSERT OR UPDATE ON public.lieux
      FOR EACH ROW EXECUTE FUNCTION private.lieux_priere_auto_relais();
  END IF;
END
$declencheur$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.enregistrer_ma_ville(bigint)'::pg_catalog.regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.enregistrer_ma_ville(bigint)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits de enregistrer_ma_ville';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.lieux'::pg_catalog.regclass AND t.tgname = 'lieux_priere_auto')
     OR pg_catalog.has_function_privilege('authenticated', 'private.lieux_priere_auto_relais()'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.lieux_priere_auto_relais()'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : declencheur ou droits du relais de priere';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.cpt_anonymiser(uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cpt_anonymiser(uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits de cpt_anonymiser';
  END IF;
END
$postflight$;

COMMIT;
