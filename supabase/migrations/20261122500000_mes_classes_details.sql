-- MES-CLASSES-ETAPE (08/11/2026) : « ou en est la Classe », pour l'enseignant, dans « Mes classes ».
--
-- Constat : `mes_groupes_v` ne porte ni l'etape du programme ni la langue d'une Classe ; l'ecran
-- n'avait aucune source pour les dire. Cette fonction les rend, EN LECTURE SEULE, pour les Classes
-- actives dont l'appelant est TITULAIRE (les memes que `mes_groupes_v`). Aucune table, aucune
-- politique, aucune fonction existante n'est touchee. Sans mot d'effacement.
--
-- L'etape vient de la version PUBLIEE du programme : si la Classe pointe une etape d'une version
-- brouillon ou archivee, ou n'en pointe aucune, `etape_ordre` et `etape_nom` valent NULL (jamais
-- l'etape d'un brouillon, rien d'invente). La langue est le nom lisible de `langues_cours`.
-- `remplacement` n'est PAS rendu : la liste ne contient que des Classes dont l'enseignant est
-- titulaire.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.mes_classes_details()') IS NOT NULL THEN
    RAISE EXCEPTION 'MES-CLASSES-ETAPE : deja installee';
  END IF;
  -- Les deux fonctions appelees sont celles relues en production (md5 de leur definition).
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.app_role()'::pg_catalog.regprocedure))
       <> 'b20471b9c758fed68602f39e075717c1'
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.app_account_valid()'::pg_catalog.regprocedure))
       <> '25ef4708ed7b2d0b81a58f3c13675f95' THEN
    RAISE EXCEPTION 'MES-CLASSES-ETAPE : app_role ou app_account_valid a change depuis la relecture, migration a revoir';
  END IF;
  -- Les colonnes lues existent.
  IF (SELECT pg_catalog.count(*) FROM information_schema.columns
       WHERE table_schema = 'public'
         AND (table_name, column_name) IN (
           ('groupes', 'programme_niveau_id'), ('groupes', 'langue_code'), ('groupes', 'ended_at'),
           ('groupes', 'teacher_id'),
           ('programme_niveaux', 'id'), ('programme_niveaux', 'ordre'), ('programme_niveaux', 'nom_humain'),
           ('programme_niveaux', 'version_id'),
           ('programme_versions', 'id'), ('programme_versions', 'statut'),
           ('langues_cours', 'code'), ('langues_cours', 'nom_humain'))) <> 12 THEN
    RAISE EXCEPTION 'MES-CLASSES-ETAPE : une colonne lue est absente';
  END IF;
END
$preflight$;

CREATE FUNCTION public.mes_classes_details()
RETURNS TABLE (
  groupe_id uuid,
  etape_ordre integer,
  etape_nom text,
  langue text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT g.id,
         n.ordre,
         n.nom_humain,
         l.nom_humain
    FROM public.groupes g
    LEFT JOIN (public.programme_niveaux n
               JOIN public.programme_versions v ON v.id = n.version_id AND v.statut = 'publiee')
           ON n.id = g.programme_niveau_id
    LEFT JOIN public.langues_cours l ON l.code = g.langue_code
   WHERE g.teacher_id = auth.uid()
     AND g.ended_at IS NULL
     AND public.app_role() = 'teacher'
     AND public.app_account_valid()
$function$;
ALTER FUNCTION public.mes_classes_details() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.mes_classes_details() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.mes_classes_details() TO authenticated;

COMMENT ON FUNCTION public.mes_classes_details() IS
  'MES-CLASSES-ETAPE (08/11/2026) : pour chaque Classe active dont l''appelant est titulaire, l''etape '
  'du programme (version publiee seulement, NULL sinon) et la langue. Lecture seule.';

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.mes_classes_details()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mes_classes_details()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.mes_classes_details()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.mes_classes_details()', 'EXECUTE') THEN
    RAISE EXCEPTION 'MES-CLASSES-ETAPE : droits d''execution inattendus';
  END IF;
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.mes_classes_details()'::pg_catalog.regprocedure))
       <> '1169e7940f81f95dc42c568c5ab691c0' THEN
    RAISE EXCEPTION 'MES-CLASSES-ETAPE : l''empreinte de la fonction installee n''est pas celle attendue';
  END IF;
END
$postflight$;
