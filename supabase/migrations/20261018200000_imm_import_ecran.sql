-- IMM-ACCUEIL-FRONT (18/10/2026) : l'ecran « Importer les inscriptions » de la
-- direction (docs/current/DECISION-IMMATRICULATION-2026-10-12.md, section 5).
--
-- Les RPC d'import existent deja (essai a blanc `previsualiser_import_inscriptions`,
-- confirmation idempotente par personne `confirmer_import_inscriptions`). Elles
-- ne sont PAS redefinies ici : leurs empreintes F86 (20261012210807) restent
-- valides. Cette migration ajoute seulement la capacite que l'ecran lit :
-- l'import n'est offert qu'a la direction active en double verification (aal2),
-- jamais deduit d'un role cote Flutter. Elle rend aussi les bornes d'age des
-- tranches du serveur (cohortes_age), pour signaler un age hors tranche a
-- l'apercu sans valeur en dur. Lecture seule, aucune donnee personnelle.
BEGIN;

CREATE FUNCTION public.capacites_import_inscriptions()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin boolean;
  v_aal2 boolean;
  v_age_min integer;
  v_age_adulte integer;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL, false) THEN
    RAISE EXCEPTION 'Acces refuse' USING ERRCODE = '42501';
  END IF;
  v_admin := coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
  v_aal2 := coalesce(public.app_aal() = 'aal2', false);
  -- Les bornes d'age viennent des tranches d'age du serveur, jamais de l'ecran.
  SELECT min(c.age_min), min(c.age_min) FILTER (WHERE c.type_public = 'adulte')
    INTO v_age_min, v_age_adulte
    FROM public.cohortes_age c WHERE c.actif;
  RETURN pg_catalog.jsonb_build_object(
    'peutImporter', v_admin AND v_aal2,
    'doubleVerificationRequise', v_admin AND NOT v_aal2,
    'ageMinimum', CASE WHEN v_admin THEN v_age_min END,
    'ageAdulte', CASE WHEN v_admin THEN v_age_adulte END);
END;
$function$;

ALTER FUNCTION public.capacites_import_inscriptions() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.capacites_import_inscriptions() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.capacites_import_inscriptions() TO authenticated;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.capacites_import_inscriptions()'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_AAL2; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. IMM-ACCUEIL-FRONT. Lecture seule : dit si l''appelant peut importer (direction active, aal2).',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.capacites_import_inscriptions()'::regprocedure;
  v_p pg_catalog.pg_proc%ROWTYPE;
BEGIN
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_oid::oid;
  IF NOT v_p.prosecdef OR v_p.provolatile <> 's'
     OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
     OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'IMM-ACCUEIL-FRONT : droits de capacites_import_inscriptions invalides';
  END IF;
END;
$postflight$;

COMMIT;
