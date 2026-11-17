-- BE-2b (pilote, 17/11/2026) : les lectures que l'ecran « Equipe » exige et que les portes de BE-2a-1 ne rendent pas.
-- Constat (lecture de 20261129420000) :
--   * `lister_attributions` rend l'identifiant du compte (`profil`), SANS nom ni role : une ligne « Karim, associe » ne
--     peut pas s'ecrire ; le nom, le role et le cote sont ajoutes (retouche par ancrage, rien d'autre ne change) ;
--   * rien ne dit qui peut recevoir une mission : `lister_personnes_mission()` rend les comptes actifs des roles que
--     `accorder_mission` admet (teacher, accountant, associe) dont le genre est connu ;
--   * rien n'expose `private.mission_gestes_ouverts()` : `lister_gestes_mission()` en rend la liste fermee, pour que
--     l'ecran ne propose que les gestes que le serveur admet.
-- Lectures seules, direction active (comme lister_missions), STABLE, SECURITY DEFINER, search_path vide. Aucun droit pour
-- anon, service_role ni agent_ro. FICHIER SANS EFFACEMENT. Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.lister_attributions(jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('private.mission_gestes_ouverts()') IS NULL THEN
    RAISE EXCEPTION 'BE-2b : les missions (BE-2a-1, 20261129420000) doivent etre installees d''abord';
  END IF;
  IF pg_catalog.to_regprocedure('public.lister_personnes_mission()') IS NOT NULL THEN
    RAISE EXCEPTION 'BE-2b : deja installee';
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
    RAISE EXCEPTION 'BE-2b : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- 1. lister_attributions : le nom, le role et le cote de la personne.
DO $attributions$
DECLARE
  v_def text;
  v_f regprocedure := 'public.lister_attributions(jsonb)'::regprocedure;
  v_com text;
BEGIN
  v_def := pg_catalog.pg_get_functiondef(v_f);
  IF pg_catalog.strpos(v_def, '''roleProfil''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '''id'', a.id, ''missionId'', a.mission_id, ''mission'', m.nom, ''profil'', a.profile_id,',
      '''id'', a.id, ''missionId'', a.mission_id, ''mission'', m.nom, ''profil'', a.profile_id,
             ''nomProfil'', pg_catalog.btrim(coalesce(pr.first_name, '''') || '' '' || coalesce(pr.last_name, '''')),
             ''roleProfil'', pr.role::text, ''coteProfil'', pr.gender::text,',
      'attributions.colonnes');
    v_def := pg_temp.remplacer(v_def,
      'FROM private.mission_attributions a JOIN private.missions m ON m.id = a.mission_id',
      'FROM private.mission_attributions a JOIN private.missions m ON m.id = a.mission_id
      JOIN public.profiles pr ON pr.id = a.profile_id',
      'attributions.jointure');
    EXECUTE v_def;
    v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
    END IF;
  END IF;
END
$attributions$;

-- 2. Qui peut recevoir une mission.
CREATE FUNCTION public.lister_personnes_mission()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', p.id,
             'nom', pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')),
             'role', p.role::text, 'cote', p.gender::text)
           ORDER BY p.last_name, p.first_name, p.id)
      FROM public.profiles p
     WHERE p.deleted_at IS NULL AND p.account_status = 'active'::public.account_status
       AND p.role IN ('teacher'::public.app_role, 'accountant'::public.app_role, 'associe'::public.app_role)
       AND p.gender IS NOT NULL), '[]'::jsonb);
END;
$function$;

-- 3. Les gestes que le serveur admet dans une mission (liste fermee).
CREATE FUNCTION public.lister_gestes_mission()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.to_jsonb(private.mission_gestes_ouverts());
END;
$function$;

ALTER FUNCTION public.lister_personnes_mission() OWNER TO postgres;
ALTER FUNCTION public.lister_gestes_mission() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lister_personnes_mission(), public.lister_gestes_mission()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lister_personnes_mission(), public.lister_gestes_mission() TO authenticated;
COMMENT ON FUNCTION public.lister_personnes_mission() IS
  'BE-2b: guard_type=ROLE_POSITIVE_TEMPLATE; garde: direction active. Lecture seule : comptes actifs teacher, accountant, associe de genre connu. date=2026-11-17.';
COMMENT ON FUNCTION public.lister_gestes_mission() IS
  'BE-2b: guard_type=ROLE_POSITIVE_TEMPLATE; garde: direction active. Lecture seule : la liste fermee private.mission_gestes_ouverts(). date=2026-11-17.';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY['public.lister_personnes_mission()'::regprocedure,
                               'public.lister_gestes_mission()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'BE-2b : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lister_attributions(jsonb)'::regprocedure),
                       '''roleProfil''') = 0 THEN
    RAISE EXCEPTION 'BE-2b : retouche de lister_attributions absente';
  END IF;
END
$postflight$;
