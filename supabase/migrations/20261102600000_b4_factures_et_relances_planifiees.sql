-- B4 (31/10/2026) : planifier l'emission des factures du mois et reposer les
-- relances quotidiennes (PLAN-LOTS-BOUCLES-2-4-2026-10-30, lot B4).
--
-- Constat du pilote en production (lecture seule, 31/10) : `cron.job` ne
-- contient que `courriels-envoi`, `seances_cloche` et `ses_cloture_auto`.
-- * `fac-relances-quotidiennes` (20261018170000, FAC-F-01) n'est pas posee :
--   elle ne l'etait que si pg_cron existait au moment de la migration. Les
--   relances J-7, J-3, J-1 et la suspension du 4 ne tournent donc pas.
-- * Aucune emission automatique : `public.emettre_factures_mois` (FAC-B-01)
--   exige une direction ou une comptabilite connectee (auth.uid()), donc un
--   job pg_cron ne peut pas l'appeler.
--
-- Ce que fait ce fichier, sans dupliquer de logique :
-- 1. La boucle d'emission de `emettre_factures_mois` passe telle quelle dans
--    `private.fac_emettre_factures_du_mois(mois, par)` ; la fonction publique
--    garde sa porte (role, compte valide, mois courant ou suivant, politique)
--    et appelle la privee. Corps de la boucle identique a FAC-B-01 : meme
--    ordre (foyer, creation, id), meme `fac_emettre_facture` (idempotente :
--    verrou par foyer et mois, et index unique `factures_mensuelles_une_par_mois`),
--    meme financement, meme journal. Les montants sont lus dans la politique
--    du mois par `fac_mensualite` ; Flutter n'en calcule aucun.
-- 2. `private.fac_emission_planifiee(jour)` decide QUEL mois emettre ce jour :
--    * le mois courant pendant les jours de grace (du 1er jusqu'a la veille du
--      `jour_suspension` de la politique du mois, le 1er seul si elle n'en a
--      pas) : le 1er est le jour du renouvellement (DECISION-TARIFS :
--      « Renouvellement le 1er ») ; les jours 2 et 3 rattrapent un passage
--      manque ou une migration posee apres le 1er. Jamais au-dela : une
--      facture emise apres le jour de suspension suspendrait l'eleve le jour
--      meme, sans grace ;
--    * le mois suivant des que l'on entre dans la plus grande avance de
--      relance de SA politique (`jours_relance`, 7 pour v2.0.0) : sans cela,
--      la relance J-7 d'une facture dont l'echeance est le 1er ne trouverait
--      aucune facture (elles naitraient le 1er) et ne partirait jamais. Une
--      politique sans `jours_relance` n'est emise que le 1er.
--    Les deux appels sont idempotents : un second passage le meme jour, ou le
--    lendemain, n'emet rien de plus.
-- 3. Planifications pg_cron, gardees par la presence de l'extension, sur le
--    modele de 20261024180000 (EXECUTE cron.schedule ; un nom existant est mis
--    a jour, jamais double ; sans effet sur un Postgres sans pg_cron, comme la
--    CI) :
--    * `fac-emission-factures`  : tous les jours a 04:45 UTC ;
--    * `fac-relances-quotidiennes` : tous les jours a 05:15 UTC (meme nom, meme
--      heure et meme commande que FAC-F-01).
--
-- Fuseaux horaires : l'HEURE de passage est en UTC (pg_cron de Supabase
-- planifie en GMT), le JOUR est decide dans le fuseau comptable
-- (`private.fac_aujourdhui()`, Europe/Paris par defaut), comme toute la
-- facturation : mois de la facture (`fac_mois_courant`), echeance, relances,
-- suspension, conservation de la place. Decider le jour en UTC ferait
-- diverger ce job de `emettre_factures_mois`, qui refuse tout autre mois que
-- le courant ou le suivant du fuseau comptable. 04:45 UTC tombe le meme jour
-- civil a Paris (05:45 en hiver, 06:45 en ete) et passe avant les relances de
-- 05:15 UTC, pour que la relance J-7 voie la facture emise le meme jour. Un
-- job quotidien plutot que « le 1er » en cron : l'expression cron, en UTC, ne
-- dit pas le 1er du fuseau comptable, et un passage manque se rattrape.
--
-- Aucune suppression ni retrait de tache planifiee.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La boucle d'emission, appelable sans session (job) : corps de FAC-B-01.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.fac_emettre_factures_du_mois(p_mois date, p_par uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profil uuid;
  v_emises integer := 0;
  v_financees integer := 0;
BEGIN
  IF p_mois IS NULL OR p_mois <> pg_catalog.date_trunc('month', p_mois)::date THEN
    RAISE EXCEPTION 'mois absent ou qui n''est pas un premier du mois' USING ERRCODE = '22023';
  END IF;
  IF (private.fac_politique_au(p_mois)).version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur ce mois' USING ERRCODE = 'P0002';
  END IF;
  FOR v_profil IN
    SELECT pr.id FROM public.profiles pr
      JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
     WHERE pr.deleted_at IS NULL AND pr.household_id IS NOT NULL
     ORDER BY pr.household_id, pr.created_at, pr.id
  LOOP
    IF private.fac_emettre_facture(v_profil, p_mois, p_par) THEN
      v_emises := v_emises + 1;
    END IF;
    v_financees := v_financees + private.fac_financer_profil(v_profil);
  END LOOP;
  PERFORM public.log_sensitive_access('factures_mois_emises', 'factures_mensuelles', p_mois::text,
    pg_catalog.jsonb_build_object('emises', v_emises, 'financees', v_financees));
  RETURN pg_catalog.jsonb_build_object('mois', pg_catalog.to_char(p_mois, 'YYYY-MM-DD'),
    'emises', v_emises, 'financees', v_financees);
END;
$function$;

-- La porte publique ne change pas ; seule la boucle part dans la privee.
CREATE OR REPLACE FUNCTION public.emettre_factures_mois(p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_courant date := private.fac_mois_courant();
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() IN ('admin', 'accountant')
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'emission des factures reservee a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  IF p_mois IS NULL OR p_mois <> pg_catalog.date_trunc('month', p_mois)::date
     OR p_mois NOT IN (v_courant, (v_courant + interval '1 month')::date) THEN
    RAISE EXCEPTION 'seuls le mois courant et le suivant se facturent' USING ERRCODE = '22023';
  END IF;
  IF (private.fac_politique_au(p_mois)).version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur ce mois' USING ERRCODE = 'P0002';
  END IF;
  RETURN private.fac_emettre_factures_du_mois(p_mois, auth.uid());
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Le passage du jour : quel mois emettre, decide dans le fuseau comptable.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.fac_emission_planifiee(p_jour date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_courant date;
  v_suivant date;
  v_p_courant public.politiques_commerciales;
  v_p_suivant public.politiques_commerciales;
  v_avance integer;
  v_res jsonb := '[]'::jsonb;
BEGIN
  IF p_jour IS NULL THEN
    RAISE EXCEPTION 'jour absent' USING ERRCODE = '22023';
  END IF;
  v_courant := pg_catalog.date_trunc('month', p_jour)::date;
  v_suivant := (v_courant + interval '1 month')::date;
  v_p_courant := private.fac_politique_au(v_courant);
  v_p_suivant := private.fac_politique_au(v_suivant);

  -- Le mois courant : le 1er, et les jours de grace qui precedent la suspension.
  IF v_p_courant.version IS NOT NULL
     AND p_jour < v_courant + greatest(coalesce(v_p_courant.jour_suspension, 2), 2) - 1 THEN
    v_res := v_res || pg_catalog.jsonb_build_array(
      private.fac_emettre_factures_du_mois(v_courant, NULL));
  END IF;

  -- Le mois suivant : des la plus grande avance de relance de sa politique.
  IF v_p_suivant.version IS NOT NULL THEN
    SELECT max(j) INTO v_avance FROM pg_catalog.unnest(v_p_suivant.jours_relance) AS j;
    IF v_avance IS NOT NULL AND v_avance > 0 AND p_jour >= v_suivant - v_avance THEN
      v_res := v_res || pg_catalog.jsonb_build_array(
        private.fac_emettre_factures_du_mois(v_suivant, NULL));
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object('jour', pg_catalog.to_char(p_jour, 'YYYY-MM-DD'),
    'emissions', v_res);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Droits : les deux privees n'ont aucun droit client ; la publique garde ses
-- droits de FAC-B-01 (authenticated seulement) et sa ligne F86 est refaite
-- sur son nouveau corps.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_emettre_factures_du_mois(date,uuid)'::regprocedure,
    'private.fac_emission_planifiee(date)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;

  v_oid := 'public.emettre_factures_mois(date)'::regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_OR_ACCOUNTANT; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-31. FAC-B-01, B4 : emission idempotente du mois courant ou suivant ; la boucle est dans private.fac_emettre_factures_du_mois, partagee avec le job quotidien.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_emettre_factures_du_mois(date,uuid)'::regprocedure,
    'private.fac_emission_planifiee(date)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                      AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'B4 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  v_oid := 'public.emettre_factures_mois(date)'::regprocedure;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'B4 : DEFINER ou ACL invalide pour emettre_factures_mois';
  END IF;
END;
$postflight$;

-- ---------------------------------------------------------------------------
-- 3. Planifications, seulement si pg_cron existe (idempotentes par le nom).
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('fac-emission-factures', '45 4 * * *',
      'SELECT private.fac_emission_planifiee(private.fac_aujourdhui())')$cron$;
    EXECUTE $cron$SELECT cron.schedule('fac-relances-quotidiennes', '15 5 * * *',
      'SELECT private.fac_traiter_relances(private.fac_aujourdhui())')$cron$;
  ELSE
    RAISE NOTICE 'B4 : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

COMMIT;
