-- F74: server-derived dimensions form distinct group families.
DO $scenario$
DECLARE
  v_hommes uuid;
  v_femmes uuid;
  v_autre_niveau uuid;
  v_autre_public uuid;
  v_function oid;
  v_niveau text;
  v_niveaux text[] := ARRAY[
    'debut_lettres', 'lettres_avec_aide', 'lecture_lente',
    'lecture_courante', 'memorisation_partielle'
  ];
  v_niveau_ids uuid[] := '{}'::uuid[];
BEGIN
  v_hommes := public.c11bis_id_regroupement(
    public.c11bis_cle_regroupement(
      'enfant', 'ar', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
      'Europe/Paris', 'hommes', 'debut_lettres'
    )
  );
  v_femmes := public.c11bis_id_regroupement(
    public.c11bis_cle_regroupement(
      'enfant', 'ar', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
      'Europe/Paris', 'femmes', 'debut_lettres'
    )
  );
  v_autre_niveau := public.c11bis_id_regroupement(
    public.c11bis_cle_regroupement(
      'enfant', 'ar', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
      'Europe/Paris', 'hommes', 'lecture_lente'
    )
  );
  v_autre_public := public.c11bis_id_regroupement(
    public.c11bis_cle_regroupement(
      'adulte', 'ar', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
      'Europe/Paris', 'hommes', 'debut_lettres'
    )
  );

  IF v_hommes = v_femmes
     OR v_hommes = v_autre_niveau
     OR v_hommes = v_autre_public THEN
    RAISE EXCEPTION 'F74: gender, level, and audience must partition group IDs';
  END IF;

  FOREACH v_niveau IN ARRAY v_niveaux LOOP
    v_niveau_ids := pg_catalog.array_append(v_niveau_ids,
      public.c11bis_id_regroupement(public.c11bis_cle_regroupement(
        'enfant', 'ar', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
        'Europe/Paris', 'hommes', v_niveau
      ))
    );
  END LOOP;
  IF pg_catalog.cardinality(v_niveau_ids) <> 5
     OR (SELECT pg_catalog.count(DISTINCT x) FROM pg_catalog.unnest(v_niveau_ids) x) <> 5 THEN
    RAISE EXCEPTION 'F74: the five declared levels must partition group IDs';
  END IF;

  IF v_hommes IS DISTINCT FROM public.c11bis_id_regroupement(
       public.c11bis_cle_regroupement(
         'enfant', 'ar', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
         'Europe/Paris', 'hommes', 'debut_lettres'
       )
     ) THEN
    RAISE EXCEPTION 'F74: identical canonical dimensions must be idempotent';
  END IF;

  IF pg_catalog.has_function_privilege(
       'authenticated', 'public.regroupements_demandes_horaires_admin()', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'anon', 'public.regroupements_c11bis_admin()', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role', 'public.regroupements_c11bis_admin()', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.regroupements_c11bis_admin()', 'EXECUTE'
     )
     OR NOT pg_catalog.has_function_privilege(
       'authenticated', 'public.regroupements_c11bis_admin()', 'EXECUTE'
     )
     OR pg_catalog.to_regprocedure(
       'public.creer_classe_depuis_regroupement(text, uuid, text)'
     ) IS NOT NULL
     OR pg_catalog.to_regprocedure(
       'public.creer_classe_depuis_regroupement_c11bis(text, uuid, text, text)'
     ) IS NOT NULL
     OR pg_catalog.has_function_privilege(
       'anon', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'anon', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
     )
     OR NOT pg_catalog.has_function_privilege(
       'authenticated', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'F74: legacy RPC or replacement ACL is incorrect';
  END IF;

  SELECT p.oid INTO v_function
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.creer_classe_depuis_regroupement(uuid, uuid, text)'::regprocedure;
  IF pg_catalog.pg_get_function_arguments(v_function) <>
     'p_regroupement_id uuid, p_cle_idempotence uuid, p_libelle text' THEN
    RAISE EXCEPTION 'F74: public creation signature must not accept gender or level';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.regroupements_c11bis_admin()'::regprocedure
       AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%genre_inconnu%'
       AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%niveau_inconnu%'
       AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%a_completer%'
       AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%FROM inconnus i%'
  ) THEN
    RAISE EXCEPTION 'F74: incomplete requests must be isolated and visible';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.completer_niveau_demande_horaire(uuid)'::regprocedure
       AND p.prosecdef
       AND p.proconfig @> ARRAY['search_path=""']
       AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%public.peut_decrire_apprenant%'
       AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%d.niveau_declare IS NULL%'
  ) THEN
    RAISE EXCEPTION 'F74: incomplete level can only be completed from the server profile';
  END IF;
END;
$scenario$;
