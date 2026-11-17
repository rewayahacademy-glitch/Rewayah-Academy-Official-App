-- PX-2 / AR-8 (pilote, 16/11/2026) : l'annuaire de l'agent d'observation (agent_ro) n'expose pas les comptes officiels (Praxis).
-- Fait : la politique profiles_agent_select lit `public.profiles` directement ; elle ne connaissait pas private.comptes_officiels, donc la
-- ligne de Praxis (prenom, immutable_id RA-OFFICIEL-PRAXIS, role accountant, statut disabled) y apparaissait pour un agent de parcours
-- `admin`. Correctif : la politique ajoute `AND NOT app_private.compte_est_officiel(id)`.
-- NON modifie, par arbitrage AR-8 : profiles_admin_all (la direction voit le compte, voulu) et toute politique RESTRICTIVE sur `profiles`
-- (pas avant l'inventaire des jointures en SECURITY INVOKER).
-- La fonction est SECURITY DEFINER (l'agent n'a aucun droit sur le schema private) et n'est executable que par agent_ro, comme
-- app_private.compte_candidat_hors_portee. La nouvelle clause est AJOUTEE a l'expression actuelle de la politique, relue telle quelle.
-- FICHIER SANS EFFACEMENT. Additif. Sans BEGIN/COMMIT de premier niveau.

CREATE FUNCTION app_private.compte_est_officiel(p_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
  SELECT EXISTS (SELECT 1 FROM private.comptes_officiels o WHERE o.profile_id = p_id);
$f$;

REVOKE ALL ON FUNCTION app_private.compte_est_officiel(uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION app_private.compte_est_officiel(uuid) TO agent_ro;

DO $politique$
DECLARE
  v_qual text;
BEGIN
  SELECT pg_catalog.pg_get_expr(po.polqual, po.polrelid) INTO v_qual
    FROM pg_catalog.pg_policy po
   WHERE po.polrelid = 'public.profiles'::regclass AND po.polname = 'profiles_agent_select';
  IF v_qual IS NULL THEN
    RAISE EXCEPTION 'PRAXIS-ANNUAIRE : la politique profiles_agent_select est absente';
  END IF;
  IF pg_catalog.strpos(v_qual, 'compte_est_officiel') = 0 THEN
    EXECUTE pg_catalog.format(
      'ALTER POLICY profiles_agent_select ON public.profiles USING ((%s) AND NOT app_private.compte_est_officiel(id))', v_qual);
  END IF;
END;
$politique$;

DO $postflight$
BEGIN
  IF coalesce((SELECT pg_catalog.strpos(pg_catalog.pg_get_expr(po.polqual, po.polrelid), 'compte_est_officiel')
                 FROM pg_catalog.pg_policy po
                WHERE po.polrelid = 'public.profiles'::regclass AND po.polname = 'profiles_agent_select'), 0) = 0
     OR NOT pg_catalog.has_function_privilege('agent_ro', 'app_private.compte_est_officiel(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'app_private.compte_est_officiel(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'app_private.compte_est_officiel(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'app_private.compte_est_officiel(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS-ANNUAIRE : politique ou droits incorrects apres installation';
  END IF;
END
$postflight$;
