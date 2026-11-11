-- SEC-GARDE-5, point b (11/11/2026, arbitrage du garde-cap relaye par le
-- pilote). L'interrupteur de l'exception KYC du super-administrateur
-- (app_config.kyc_exception_super_admin, 0088) ne se modifie plus que par
-- postgres, et chaque tentative comme chaque changement laisse une trace dans
-- audit_logs. LA VALEUR NE CHANGE PAS : la question est posee au directeur.
--
-- Le defaut : la politique app_config_admin_update laisse tout admin actif
-- modifier n'importe quelle cle, donc basculer cette exception (lue par 0088,
-- 0090 et 20261108000001) sans autre trace que app_config_history.
--
-- Ce que fait ce fichier, et rien d'autre :
--   private.kyc_exception_proteger(), declencheur BEFORE INSERT OR UPDATE
--   sur public.app_config, qui n'agit que sur la cle
--   kyc_exception_super_admin (ancienne ou nouvelle). L'effacement n'est pas
--   couvert : app_config n'a aucune politique d'effacement, aucun client ne
--   peut retirer la cle (et ce fichier reste sans mot d'effacement) :
--   - permis seulement a postgres lui-meme : session ouverte par postgres (ou
--     supabase_admin, celui des migrations de la plateforme), aucun SET ROLE
--     vers un role d'API, et aucun utilisateur connecte (auth.uid() nul). Un
--     admin, service_role, ou une RPC DEFINER appelee par un utilisateur
--     (current_user = postgres mais session authenticator) sont refuses ;
--   - une tentative refusee est ANNULEE SANS ERREUR (RETURN NULL : la ligne
--     n'est pas ecrite) ; c'est voulu : une exception annulerait aussi
--     l'entree d'audit de la tentative ; ainsi la trace reste ;
--   - un changement permis est ecrit et trace (ancienne et nouvelle valeur).
--   Trace par public.log_sensitive_access (chaine de hachage existante).
--   La fonction est DEFINER pour ecrire l'audit ; elle juge l'appelant par
--   session_user et le reglage role, que DEFINER ne change pas.
--
-- PREFLIGHT : la cle existe, la fonction d'audit existe. Sans BEGIN ni
-- COMMIT de premier niveau. Aucun mot d'effacement : applicable par
-- apply_migration.

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'kyc_exception_super_admin') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 b : cle kyc_exception_super_admin absente, rien n''est change';
  END IF;
  IF to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'SEC-GARDE-5 b : public.log_sensitive_access absente';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION private.kyc_exception_proteger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  -- SEC-GARDE-5 (11/11/2026) : seul postgres modifie l'interrupteur.
  v_cle constant text := 'kyc_exception_super_admin';
  v_concerne boolean;
  v_permis boolean;
  v_avant jsonb;
  v_apres jsonb;
BEGIN
  v_concerne := (TG_OP = 'UPDATE' AND OLD.key = v_cle) OR NEW.key = v_cle;
  IF NOT v_concerne THEN
    RETURN NEW;
  END IF;

  v_permis := session_user::text IN ('postgres', 'supabase_admin')
          AND coalesce(nullif(pg_catalog.current_setting('role', true), ''), 'none')
              IN ('none', 'postgres', 'supabase_admin')
          AND auth.uid() IS NULL;
  v_avant := CASE WHEN TG_OP = 'UPDATE' THEN pg_catalog.to_jsonb(OLD.value) END;
  v_apres := pg_catalog.to_jsonb(NEW.value);

  IF NOT v_permis THEN
    PERFORM public.log_sensitive_access(
      'kyc_exception_tentative_refusee', 'app_config', v_cle,
      pg_catalog.jsonb_build_object(
        'operation', TG_OP, 'valeur_actuelle', v_avant, 'valeur_demandee', v_apres,
        'session', session_user::text,
        'role', pg_catalog.current_setting('role', true)));
    RETURN NULL;
  END IF;

  IF v_avant IS DISTINCT FROM v_apres THEN
    PERFORM public.log_sensitive_access(
      'kyc_exception_modifiee', 'app_config', v_cle,
      pg_catalog.jsonb_build_object('operation', TG_OP, 'avant', v_avant, 'apres', v_apres));
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.kyc_exception_proteger()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $declencheur$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
                  WHERE tgrelid = 'public.app_config'::regclass
                    AND tgname = 'app_config_aa_kyc_exception') THEN
    -- « aa » : les declencheurs BEFORE d'une table passent par ordre de nom ;
    -- celui-ci passe le premier, une tentative refusee n'atteint pas les
    -- autres.
    CREATE TRIGGER app_config_aa_kyc_exception
      BEFORE INSERT OR UPDATE ON public.app_config
      FOR EACH ROW EXECUTE FUNCTION private.kyc_exception_proteger();
  END IF;
END
$declencheur$;

-- POSTFLIGHT : declencheur en place, valeur inchangee.
DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger
                  WHERE tgrelid = 'public.app_config'::regclass
                    AND tgname = 'app_config_aa_kyc_exception' AND tgenabled = 'O') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 b : declencheur absent ou desactive';
  END IF;
  IF has_function_privilege('authenticated', 'private.kyc_exception_proteger()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SEC-GARDE-5 b : authenticated peut executer la fonction du declencheur';
  END IF;
END
$postflight$;
