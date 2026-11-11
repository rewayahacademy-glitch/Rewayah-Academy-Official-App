-- CAHIER-C3 : activation de la paie par seance et de la liste par seance.
-- Decision du directeur du 11/11/2026 (« tout de suite » : il est le seul enseignant),
-- relayee par le garde-cap. Le geste prevu depuis 20261113000000 : la SEULE ligne qui
-- remplace `private.cahier_c3_coupure()` par la date reelle. La paie et la liste basculent
-- ENSEMBLE, puisqu'elles lisent cette meme fonction.
--
-- La coupure passe de 2100-01-01 a 2026-11-12 00:00 UTC. Une seance commencee a partir de
-- cette date sans son propre cahier passe « en attente » dans le releve de paie ; la liste de
-- l'enseignant montre une ligne par seance non couverte. Les seances d'avant gardent la regle
-- d'hier (regle de stabilite 2) : rien n'est recalcule dans le passe.
--
-- ATTRIBUT : la fonction reste STABLE (20261113000000, retouche 1 du garde-cap : une fonction
-- IMMUTABLE peut etre evaluee une fois pour toutes dans un plan garde par une connexion du
-- pool, qui garderait 2100 apres la bascule). Le preflight refuse de s'installer si elle ne
-- l'est pas, et le postflight le verifie.
--
-- Fichier sans transaction de premier niveau et sans mot d'effacement.

-- Preflight ---------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.cahier_c3_coupure()') IS NULL THEN
    RAISE EXCEPTION 'CAHIER-C3-COUPURE : private.cahier_c3_coupure() absente';
  END IF;
  IF private.cahier_c3_coupure() IS DISTINCT FROM '2100-01-01 00:00:00+00'::timestamptz THEN
    RAISE EXCEPTION 'CAHIER-C3-COUPURE : la coupure ne vaut pas 2100-01-01 (valeur lue : %), arret',
      private.cahier_c3_coupure();
  END IF;
  IF (SELECT p.provolatile FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.cahier_c3_coupure()'::pg_catalog.regprocedure) <> 's' THEN
    RAISE EXCEPTION 'CAHIER-C3-COUPURE : la fonction n''est pas STABLE : installer 20261113000000 d''abord';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION private.cahier_c3_coupure()
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT '2026-11-12 00:00:00+00'::timestamptz
$function$;

COMMENT ON FUNCTION private.cahier_c3_coupure() IS
  'CAHIER-C3 : debut de la paie par seance et de la liste par seance, active le 2026-11-12 '
  '00:00 UTC (decision du directeur du 11/11/2026). Les seances d''avant gardent la regle de la '
  'semaine. STABLE : aucun plan ne garde l''ancienne date.';

REVOKE ALL ON FUNCTION private.cahier_c3_coupure()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Postflight --------------------------------------------------------------------
DO $postflight$
BEGIN
  IF private.cahier_c3_coupure() IS DISTINCT FROM '2026-11-12 00:00:00+00'::timestamptz THEN
    RAISE EXCEPTION 'CAHIER-C3-COUPURE : la coupure ne vaut pas la nouvelle date (%)', private.cahier_c3_coupure();
  END IF;
  IF NOT (SELECT p.prosecdef AND p.provolatile = 's' FROM pg_catalog.pg_proc p
           WHERE p.oid = 'private.cahier_c3_coupure()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'CAHIER-C3-COUPURE : la fonction doit rester SECURITY DEFINER et STABLE';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.cahier_c3_coupure()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.cahier_c3_coupure()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAHIER-C3-COUPURE : droits inattendus';
  END IF;
END
$postflight$;
