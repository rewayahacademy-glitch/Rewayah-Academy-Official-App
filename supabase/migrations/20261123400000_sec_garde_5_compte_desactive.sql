-- SEC-GARDE-5, point a (11/11/2026, arbitrage du garde-cap relaye par le
-- pilote ; plage 20261123400000-20261123499999, une migration par point).
-- Un compte DESACTIVE (account_status = 'disabled') ne lit plus les donnees
-- des autres. Seulement « disabled », JAMAIS app_account_valid() : un compte
-- pending_kyc, ou dont access_until est passe, garde ses lectures (portail
-- d'attente, depot de piece, inscription).
--
-- Ce que fait ce fichier, et rien d'autre :
--   1. app_private.compte_non_desactive() : STABLE, DEFINER, search_path
--      vide, sur auth.uid(). Vrai sauf si le profil de l'appelant est
--      'disabled' (un appelant sans profil n'est pas desactive). Dans
--      app_private et non private : une politique s'evalue avec les droits
--      de l'appelant, et authenticated n'a pas USAGE sur private (il l'a sur
--      app_private, comme pour peut_lire_groupe). EXECUTE a authenticated
--      seul.
--   2. Une politique RESTRICTIVE de lecture (FOR SELECT TO authenticated)
--      sur chaque table dont une lecture des autres est nommee par
--      l'arbitrage : profiles (profiles_family_select), households
--      (households_guardian_select), student_profiles
--      (student_profiles_family), teacher_student_assignments
--      (assignments_parties_read), groupes (groupes_lecture), devices
--      (devices_*). Une RESTRICTIVE s'ajoute en ET a toutes les politiques
--      de lecture de la table : la ligne de SOI reste lisible sur profiles
--      (profiles_self_select reste ouverte), student_profiles et devices.
--   3. custom_access_token_hook : pour un compte 'disabled', un jeton sans
--      role ni foyer (app_metadata.role et household_id a null) et la claim
--      app_metadata.account_status = 'disabled'. Tout autre compte recoit
--      exactement le jeton d'avant (pending_kyc et access_until inchanges).
--      Le hook ne rend jamais null (jsonb_set sur des valeurs non nulles,
--      coalesce final conserve).
--
-- Effet attendu en production : preflight du pilote le 11/11 vers 12:40 UTC,
-- 5 comptes 'disabled', tous des eleves (suppressions ou essais). Ecrivains
-- de 'disabled' : accepter_admission, annuler_admission, decider_dossier,
-- suppr_retirer, cpt_anonymiser, photos_effacer_si_anonymise. Un jeton deja
-- emis garde son role jusqu'a son expiration ; les politiques RESTRICTIVES,
-- elles, lisent l'etat en base tout de suite.
--
-- PREFLIGHT : md5(pg_get_functiondef) du hook relu sur une base rejouee
-- depuis le depot (PostgreSQL 16, main du 11/11) ; a recalibrer en
-- production par le pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef(
--            'public.custom_access_token_hook(jsonb)'::regprocedure));
-- Une definition differente, sans le marqueur SEC-GARDE-5, arrete le fichier.
-- Les politiques sont creees seulement si elles n'existent pas (rejouable).
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.

DO $preflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.custom_access_token_hook(jsonb)'::regprocedure);
BEGIN
  IF pg_catalog.md5(v_def) <> '16aa6b2b88014af53095624d473572a8'
     AND pg_catalog.strpos(v_def, 'SEC-GARDE-5') = 0 THEN
    RAISE EXCEPTION 'SEC-GARDE-5 a : custom_access_token_hook a change (md5 %), rien n''est change',
      pg_catalog.md5(v_def);
  END IF;
  IF to_regnamespace('app_private') IS NULL THEN
    RAISE EXCEPTION 'SEC-GARDE-5 a : schema app_private absent';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. L'aide
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.compte_non_desactive()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  -- SEC-GARDE-5 (11/11/2026) : faux seulement pour un profil 'disabled'.
  SELECT NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = auth.uid()
       AND p.account_status = 'disabled'
  );
$function$;

COMMENT ON FUNCTION app_private.compte_non_desactive() IS
  'SEC-GARDE-5 (11/11/2026) : faux seulement si le profil de l''appelant est disabled. '
  'Aide des politiques RESTRICTIVES de lecture ; jamais app_account_valid().';

REVOKE ALL ON FUNCTION app_private.compte_non_desactive() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION app_private.compte_non_desactive() TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. Les politiques RESTRICTIVES de lecture
-- ---------------------------------------------------------------------------
DO $politiques$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'profiles'
                    AND policyname = 'profiles_compte_non_desactive') THEN
    -- La ligne de soi reste lisible : profiles_self_select reste ouverte.
    CREATE POLICY profiles_compte_non_desactive ON public.profiles
      AS RESTRICTIVE FOR SELECT TO authenticated
      USING (id = (SELECT auth.uid()) OR (SELECT app_private.compte_non_desactive()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'student_profiles'
                    AND policyname = 'student_profiles_compte_non_desactive') THEN
    CREATE POLICY student_profiles_compte_non_desactive ON public.student_profiles
      AS RESTRICTIVE FOR SELECT TO authenticated
      USING (profile_id = (SELECT auth.uid()) OR (SELECT app_private.compte_non_desactive()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'devices'
                    AND policyname = 'devices_compte_non_desactive') THEN
    CREATE POLICY devices_compte_non_desactive ON public.devices
      AS RESTRICTIVE FOR SELECT TO authenticated
      USING (profile_id = (SELECT auth.uid()) OR (SELECT app_private.compte_non_desactive()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'households'
                    AND policyname = 'households_compte_non_desactive') THEN
    CREATE POLICY households_compte_non_desactive ON public.households
      AS RESTRICTIVE FOR SELECT TO authenticated
      USING ((SELECT app_private.compte_non_desactive()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'teacher_student_assignments'
                    AND policyname = 'assignments_compte_non_desactive') THEN
    CREATE POLICY assignments_compte_non_desactive ON public.teacher_student_assignments
      AS RESTRICTIVE FOR SELECT TO authenticated
      USING ((SELECT app_private.compte_non_desactive()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'groupes'
                    AND policyname = 'groupes_compte_non_desactive') THEN
    CREATE POLICY groupes_compte_non_desactive ON public.groupes
      AS RESTRICTIVE FOR SELECT TO authenticated
      USING ((SELECT app_private.compte_non_desactive()));
  END IF;
END
$politiques$;

-- ---------------------------------------------------------------------------
-- 3. Le hook de jeton
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  claims jsonb;
  user_id uuid := (event ->> 'user_id')::uuid;
  v_profile public.profiles;
  v_student_type public.student_type;
  v_tranche_age text := 'inconnu';
BEGIN
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE public.profiles.id = user_id
    AND public.profiles.deleted_at IS NULL;

  claims := coalesce(event -> 'claims', '{}'::jsonb);

  IF v_profile.id IS NOT NULL THEN
    IF coalesce(jsonb_typeof(claims -> 'app_metadata'), 'absent') <> 'object' THEN
      claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb);
    END IF;

    IF v_profile.account_status = 'disabled' THEN
      -- SEC-GARDE-5 (11/11/2026) : un compte desactive recoit un jeton sans
      -- role ni foyer, et l'etat du compte pour l'ecran « Compte suspendu ».
      claims := jsonb_set(claims, '{app_metadata, role}', 'null'::jsonb);
      claims := jsonb_set(claims, '{app_metadata, household_id}', 'null'::jsonb);
      claims := jsonb_set(claims, '{app_metadata, account_status}', '"disabled"'::jsonb, true);
    ELSE
      claims := jsonb_set(
        claims,
        '{app_metadata, role}',
        coalesce(to_jsonb(v_profile.role::text), 'null'::jsonb)
      );
      claims := jsonb_set(
        claims,
        '{app_metadata, household_id}',
        coalesce(to_jsonb(v_profile.household_id::text), 'null'::jsonb)
      );
    END IF;

    claims := jsonb_set(
      claims,
      '{app_metadata, authorization_version}',
      to_jsonb(v_profile.authorization_version),
      true
    );

    SELECT sp.student_type INTO v_student_type
    FROM public.student_profiles sp
    WHERE sp.profile_id = user_id
      AND sp.deleted_at IS NULL;

    v_tranche_age := CASE v_student_type
      WHEN 'minor' THEN 'enfant'
      WHEN 'autonomous' THEN 'adulte'
      ELSE 'inconnu'
    END;
  END IF;

  -- Claim de présentation uniquement : aucune décision d'accès ne s'appuie
  -- sur lui. Il ne contient jamais de date de naissance.
  claims := jsonb_set(claims, '{tranche_age}', to_jsonb(v_tranche_age), true);

  RETURN coalesce(jsonb_set(event, '{claims}', claims), event);
END;
$function$;

-- POSTFLIGHT
DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.custom_access_token_hook(jsonb)'::regprocedure);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, 'SEC-GARDE-5') = 0 THEN
    RAISE EXCEPTION 'SEC-GARDE-5 a : hook sans la branche disabled';
  END IF;
  IF has_function_privilege('anon', 'app_private.compte_non_desactive()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'app_private.compte_non_desactive()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 a : droits de compte_non_desactive inattendus';
  END IF;
  SELECT count(*) INTO v_n FROM pg_catalog.pg_policies
   WHERE schemaname = 'public' AND permissive = 'RESTRICTIVE' AND cmd = 'SELECT'
     AND policyname IN ('profiles_compte_non_desactive', 'student_profiles_compte_non_desactive',
                        'devices_compte_non_desactive', 'households_compte_non_desactive',
                        'assignments_compte_non_desactive', 'groupes_compte_non_desactive');
  IF v_n <> 6 THEN
    RAISE EXCEPTION 'SEC-GARDE-5 a : % politiques RESTRICTIVES sur 6', v_n;
  END IF;
END
$postflight$;
