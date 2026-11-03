-- Lot N4, partie serveur (03/11/2026) : ce que les lecteurs non direction
-- peuvent lire de la Bibliotheque, et les evaluations publiees d'une famille.
--
-- FICHIER SANS MOT D'EFFACEMENT (B5) : le pilote l'installe. Additif (B6) :
-- six fonctions nouvelles (deux privees, quatre publiques) ; aucune table,
-- aucune fonction existante touchee.
-- Aucune transaction de premier niveau : l'installateur l'enveloppe.
--
-- Preflight en production (lecture seule, 03/11) : library_resource,
-- library_resource_groupe, resource_version et library_reading_position ont
-- leur RLS ; ressources_du_groupe porte deja la garde app_account_valid
-- (correctif 0035 en place) ; evaluation_publiee_lignes existe ; aucune des
-- fonctions ci-dessous n'existe.
--
-- 1. La Bibliotheque hors direction (NON-BRANCHE S1). library_get_catalogue
--    est reservee a la direction (20261016100600) ; les colonnes level_scope,
--    access_policy et updated_at ne sont accordees a aucun client, donc la RLS
--    seule ne permet pas de lire le manifeste. Trois lectures DEFINER, qui
--    rendent EXACTEMENT ce que la policy library_resource_lecture laisse voir
--    a l'appelant (transcription litterale de 20261011113000, comme 0035 pour
--    ressources_du_groupe : une seule regle pour la meme donnee) :
--      - private.n4_ressource_lisible(uuid) : la policy, transcrite, porte de
--        l'acces paye comprise (20261104600000) ;
--      - public.bibliotheque_catalogue_lecteur(p_filtre, p_limite) : « Tous »
--        et la recherche, filtres types, langue, categorie, niveau, recherche,
--        id (une ressource precise : « parId ») ;
--      - public.bibliotheque_recents_lecteur(p_limite) : les ressources
--        ouvertes par l'appelant (library_reading_position), plus recentes
--        d'abord ;
--      - public.bibliotheque_reprise_lecteur() : « Continuer » : la derniere
--        ressource ouverte et sa position.
--    Le manifeste rendu a les cles de LibraryResource.depuisJson ; aucune cle
--    de stockage, aucune URL (la lecture d'un fichier reste
--    autoriser_lecture_version et la fonction Edge bibliotheque-lecture).
--    Tout compte valide recoit ce que la policy lui ouvre, rien de plus : la
--    policy ouvre « publique » et « inscrits » a tout role valide, « groupe
--    assigne » aux familles de la Classe, « enseignant seul » a son
--    enseignant, tout a la direction. Aucune exception n'est ajoutee ici.
-- 2. Les evaluations publiees d'une famille (NON-BRANCHE D5).
--    evaluation_publications n'est lisible que par la direction : une famille
--    ne peut pas savoir quelles publications la concernent, donc ne peut pas
--    appeler evaluation_publiee_lignes. public.mes_evaluations_publiees()
--    rend, pour l'eleve connecte ou les enfants du foyer du tuteur, chaque
--    publication qui les concerne : identifiant, titre, Classe, date, eleve
--    (prenom) et son code EV. Jamais les codes des autres eleves.

-- ---------------------------------------------------------------------------
-- 1. La Bibliotheque hors direction
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.n4_ressource_lisible(p_resource_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  -- Transcription litterale de la policy library_resource_lecture telle
  -- qu'elle est en vigueur : celle de 20261011113000 (portee par les vues
  -- mes_groupes_v et mes_groupes_famille_v), puis la porte de l'acces paye
  -- ajoutee par 20261104600000 (AND private.acces_paye_appelant()). La
  -- sous-requete sur library_resource_groupe passe, dans la policy, par la
  -- RLS de cette table, qui ajoute private.acces_paye_groupe(groupe_id) : elle
  -- est transcrite aussi. library_resource renomme r. Le scenario
  -- scenarios_n4_lectures.sql compare ce resultat a la RLS reelle.
  SELECT coalesce((
    SELECT public.app_account_valid()
       AND (
         public.app_role() = 'admin'
         OR (
           r.archived_at IS NULL
           AND r.current_version_id IS NOT NULL
           AND (
             r.access_policy IN ('publique', 'inscrits')
             OR (
               r.access_policy IN ('groupe_assigne', 'enseignant_seul')
               AND EXISTS (
                 SELECT 1
                   FROM public.library_resource_groupe lrg
                  WHERE lrg.resource_id = r.id
                    AND private.acces_paye_groupe(lrg.groupe_id)
                    AND (
                      (
                        public.app_role() = 'teacher'
                        AND EXISTS (
                          SELECT 1 FROM public.mes_groupes_v mg
                           WHERE mg.groupe_id = lrg.groupe_id
                        )
                      )
                      OR (
                        public.app_role() IN ('guardian', 'student')
                        AND r.access_policy = 'groupe_assigne'
                        AND EXISTS (
                          SELECT 1 FROM public.mes_groupes_famille_v mg
                           WHERE mg.groupe_id = lrg.groupe_id
                        )
                      )
                    )
               )
             )
           )
         )
       )
       AND private.acces_paye_appelant()
      FROM public.library_resource r
     WHERE r.id = p_resource_id
  ), false);
$function$;
ALTER FUNCTION private.n4_ressource_lisible(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.n4_ressource_lisible(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION private.n4_manifeste(p_resource_id uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', r.id, 'title', r.title, 'short_title', r.short_title,
    'cover_asset', r.cover_asset, 'resource_type', r.resource_type::text,
    'edition', r.edition, 'language', r.language, 'category', r.category,
    'level_scope', pg_catalog.to_jsonb(r.level_scope),
    'access_policy', r.access_policy::text, 'offline_policy', r.offline_policy::text,
    'current_version_id', r.current_version_id,
    'capabilities', pg_catalog.to_jsonb(r.capabilities))
    FROM public.library_resource r WHERE r.id = p_resource_id;
$function$;
ALTER FUNCTION private.n4_manifeste(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.n4_manifeste(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.bibliotheque_catalogue_lecteur(
  p_filtre jsonb DEFAULT '{}'::jsonb, p_limite integer DEFAULT 100
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_types text[];
  v_langue text := p_filtre ->> 'langue';
  v_categorie text := p_filtre ->> 'categorie';
  v_niveau text := p_filtre ->> 'niveau';
  v_recherche text := nullif(pg_catalog.btrim(p_filtre ->> 'recherche'), '');
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_filtre IS NULL OR pg_catalog.jsonb_typeof(p_filtre) <> 'object'
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p_filtre) k(cle)
                 WHERE k.cle NOT IN ('types', 'langue', 'categorie', 'niveau', 'recherche', 'id'))
     OR (p_filtre ? 'types' AND pg_catalog.jsonb_typeof(p_filtre -> 'types') <> 'array')
     OR coalesce(pg_catalog.length(v_langue), 0) > 16
     OR coalesce(pg_catalog.length(v_categorie), 0) > 80
     OR coalesce(pg_catalog.length(v_niveau), 0) > 80
     OR coalesce(pg_catalog.length(v_recherche), 0) > 120
     OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
  END IF;
  IF p_filtre ? 'types' THEN
    SELECT pg_catalog.array_agg(t) INTO v_types
      FROM pg_catalog.jsonb_array_elements_text(p_filtre -> 'types') t;
  END IF;
  IF p_filtre ? 'id' THEN
    BEGIN
      v_id := (p_filtre ->> 'id')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'BibliothequeFiltreInvalide' USING ERRCODE = '22023';
    END;
  END IF;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(private.n4_manifeste(x.id) ORDER BY x.title, x.id)
      FROM (
        SELECT r.id, r.title
          FROM public.library_resource r
         WHERE private.n4_ressource_lisible(r.id)
           AND (v_id IS NULL OR r.id = v_id)
           AND (v_types IS NULL OR cardinality(v_types) = 0 OR r.resource_type::text = ANY (v_types))
           AND (v_langue IS NULL OR r.language = v_langue)
           AND (v_categorie IS NULL OR r.category = v_categorie)
           AND (v_niveau IS NULL OR r.level_scope @> ARRAY[v_niveau])
           AND (v_recherche IS NULL OR pg_catalog.concat_ws(' ', pg_catalog.lower(r.title),
                  pg_catalog.lower(r.short_title), pg_catalog.lower(coalesce(r.edition, '')),
                  pg_catalog.lower(r.category))
                LIKE '%' || pg_catalog.lower(v_recherche) || '%')
         ORDER BY r.title, r.id
         LIMIT p_limite
      ) x
  ), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.bibliotheque_recents_lecteur(p_limite integer DEFAULT 10)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    RAISE EXCEPTION 'BibliothequeLimiteInvalide' USING ERRCODE = '22023';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(private.n4_manifeste(x.resource_id) ORDER BY x.vue_le DESC, x.resource_id)
      FROM (
        SELECT lp.resource_id, lp.vue_le
          FROM public.library_reading_position lp
         WHERE lp.profile_id = auth.uid()
           AND private.n4_ressource_lisible(lp.resource_id)
         ORDER BY lp.vue_le DESC, lp.resource_id
         LIMIT p_limite
      ) x
  ), '[]'::jsonb);
END;
$function$;

CREATE FUNCTION public.bibliotheque_reprise_lecteur()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  RETURN (
    SELECT pg_catalog.jsonb_build_object(
      'ressource', private.n4_manifeste(lp.resource_id),
      'position', pg_catalog.jsonb_build_object(
        'type_ancrage', lp.type_ancrage::text, 'resource_version_id', lp.resource_version_id,
        'page', lp.page, 'sourate', lp.sourate, 'ayah', lp.ayah,
        'section_id', lp.section_id, 'fraction', lp.fraction),
      'vue_le', lp.vue_le)
      FROM public.library_reading_position lp
     WHERE lp.profile_id = auth.uid()
       AND private.n4_ressource_lisible(lp.resource_id)
     ORDER BY lp.vue_le DESC, lp.resource_id
     LIMIT 1
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Les evaluations publiees d'une famille
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.mes_evaluations_publiees()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL
     OR NOT coalesce(public.app_account_valid()
                     AND public.app_role() IN ('student', 'guardian'), false) THEN
    RAISE EXCEPTION 'EvaluationsNonAutorisees' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'publication_id', e.id, 'titre', e.titre, 'classe', g.libelle,
      'publiee_le', e.published_at, 'eleve_id', c.student_id,
      'eleve_prenom', p.first_name, 'code', c.code)
      ORDER BY e.published_at DESC, e.id, c.student_id)
      FROM private.evaluation_codes c
      JOIN public.evaluation_publications e ON e.id = c.publication_id
      JOIN public.groupes g ON g.id = e.groupe_id
      JOIN public.profiles p ON p.id = c.student_id
     WHERE c.student_id = auth.uid()
        OR (public.app_role() = 'guardian'
            AND p.household_id IS NOT NULL
            AND p.household_id = public.app_household_id())
  ), '[]'::jsonb);
END;
$function$;

-- Droits : authenticated seulement (jamais anon, service_role ni agent_ro).
DO $droits$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.bibliotheque_catalogue_lecteur(jsonb,integer)',
    'public.bibliotheque_recents_lecteur(integer)',
    'public.bibliotheque_reprise_lecteur()',
    'public.mes_evaluations_publiees()'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$droits$;

-- Postflight.
DO $postflight$
DECLARE f regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.bibliotheque_catalogue_lecteur(jsonb,integer)'::regprocedure,
    'public.bibliotheque_recents_lecteur(integer)'::regprocedure,
    'public.bibliotheque_reprise_lecteur()'::regprocedure,
    'public.mes_evaluations_publiees()'::regprocedure] LOOP
    IF NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE')
       OR NOT (SELECT p.prosecdef AND 'search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[]))
                 AND p.provolatile = 's'
                 AND pg_catalog.strpos(p.prosrc, 'app_account_valid()') > 0
                 FROM pg_catalog.pg_proc p WHERE p.oid = f) THEN
      RAISE EXCEPTION 'N4 postflight : % mal gardee ou mal exposee', f;
    END IF;
  END LOOP;
  IF has_function_privilege('authenticated', 'private.n4_ressource_lisible(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.n4_manifeste(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'N4 postflight : fonction privee exposee';
  END IF;
END;
$postflight$;
