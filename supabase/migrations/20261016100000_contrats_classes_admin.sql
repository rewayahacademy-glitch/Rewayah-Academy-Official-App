-- CONTRATS-MANQUANTS (1/6) : la liste paginee des classes de la direction.
--
-- Contrat : lib/core/admin/port_classes_admin.dart (PortClassesAdmin.page),
-- decision DECISION-CLASSES-SIMULTANEES-2026-10-10.md, regles R1, R7, R16, R17.
--
-- * La cle de famille de classes paralleles (section 1 de la decision) :
--   l'instant UTC de chaque creneau compare a quatre semaines de reference
--   (hiver, mi-mars, ete, fin octobre : les changements d'heure europeens et
--   nord-americains ne tombent pas les memes semaines), puis le public, le
--   genre, la langue et le niveau. Paris 18 h et Londres 17 h ont la meme
--   cle ; New York 12 h non.
-- * Le numero dans la famille (R16) : rang de creation dans la famille,
--   clotures comprises, pour qu'un numero ne change jamais quand une classe
--   voisine se cloture. Aucun code court n'est attribue (code_court nul).
-- * Une classe sans enseignant est rendue (R7), contrairement a
--   groupes_admin() qui la perdait dans sa jointure.
-- * Pagination, filtres et compteurs cote serveur (R17), dans le meme ordre
--   que paginerClasses() : libelle, numero, identifiant.
-- * DEFINER, comme groupes_admin() : les colonnes lues (enseignant, plafond,
--   genre) et la table groupe_membres ne sont accordees a aucun client ; la
--   garde positive exige la direction active. Les deux aides de app_private
--   sont INVOKER, sans EXECUTE client, appelees depuis les RPC DEFINER.
BEGIN;

-- ------------------------------------------------------------------
-- L'instant hebdomadaire UTC d'un creneau local, aux quatre semaines de
-- reference. Rend par exemple « 1:17/1:17/1:16/1:17 ».
-- ------------------------------------------------------------------
CREATE FUNCTION app_private.instant_hebdo_utc(p_jour integer, p_heure integer, p_fuseau text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.string_agg(
    pg_catalog.to_char(
      ((r.lundi + (p_jour - 1)) + pg_catalog.make_interval(hours => p_heure))
        AT TIME ZONE p_fuseau AT TIME ZONE 'UTC',
      'ID:HH24'),
    '/' ORDER BY r.lundi)
  FROM (VALUES (date '2026-01-12'), (date '2026-03-16'),
               (date '2026-07-13'), (date '2026-10-26')) AS r(lundi);
$function$;

-- ------------------------------------------------------------------
-- Chaque classe, sa cle de famille et son numero dans la famille.
-- INTERNE : INVOKER sans EXECUTE client (appelee depuis les RPC DEFINER).
-- ------------------------------------------------------------------
CREATE FUNCTION app_private.classes_numerotees()
RETURNS TABLE (groupe_id uuid, cle text, creneaux text, numero integer)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT k.id,
         k.creneaux || '|' || k.type_public || '|' || k.genre || '|'
           || k.langue || '|' || k.niveau,
         k.creneaux,
         (pg_catalog.row_number() OVER (
            PARTITION BY k.creneaux, k.type_public, k.genre, k.langue, k.niveau
            ORDER BY k.created_at, k.id))::integer
  FROM (
    SELECT g.id, g.created_at, g.type_public,
           coalesce(g.genre_public, 'indetermine') AS genre,
           coalesce(g.langue_code, '') AS langue,
           coalesce(g.niveau, '') AS niveau,
           (SELECT pg_catalog.string_agg(s.instant, ',' ORDER BY s.instant)
              FROM (
                SELECT app_private.instant_hebdo_utc(g.weekday, g.hour_local, g.timezone_iana) AS instant
                UNION
                SELECT app_private.instant_hebdo_utc(gc.weekday, gc.hour_local, g.timezone_iana)
                  FROM public.groupe_creneaux gc
                 WHERE gc.groupe_id = g.id
              ) s) AS creneaux
      FROM public.groupes g
  ) k;
$function$;

REVOKE ALL ON FUNCTION app_private.instant_hebdo_utc(integer, integer, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION app_private.classes_numerotees()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ------------------------------------------------------------------
-- La page de classes (PortClassesAdmin.page).
--
-- Filtres (nul = tous) : p_texte (nom, numero, enseignant ; insensible a la
-- casse et aux accents courants), p_type ('enfant' | 'adulte'), p_etat
-- ('active' | 'attente_enseignant' | 'cloturee'), p_jour (1-7), p_heure
-- (0-23), p_fuseau, p_genre ('hommes' | 'femmes' | 'indetermine'),
-- p_enseignant_id, p_sans_enseignant (vrai : seulement les classes sans
-- enseignant ; FiltreClasses.sansEnseignant), p_remplissage ('pleine' |
-- 'avec_places').
--
-- Rend un objet : lignes, total, page (bornee a [1, pages]), taille,
-- compteurs {active, attente_enseignant, cloturee} (les autres axes
-- appliques), jours, heures, fuseaux, enseignants [{id, libelle}], genres
-- (toutes les classes), total_sans_filtre.
-- ------------------------------------------------------------------
CREATE FUNCTION public.classes_admin_page(
  p_page integer DEFAULT 1,
  p_taille integer DEFAULT 25,
  p_texte text DEFAULT NULL,
  p_type text DEFAULT NULL,
  p_etat text DEFAULT NULL,
  p_jour integer DEFAULT NULL,
  p_heure integer DEFAULT NULL,
  p_fuseau text DEFAULT NULL,
  p_genre text DEFAULT NULL,
  p_enseignant_id uuid DEFAULT NULL,
  p_sans_enseignant boolean DEFAULT false,
  p_remplissage text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_texte text;
  v_masque boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'liste des classes reservee a la direction active'
      USING ERRCODE = '42501';
  END IF;

  IF p_page IS NULL OR p_page < 1 OR p_taille IS NULL OR p_taille NOT BETWEEN 1 AND 100
     OR (p_type IS NOT NULL AND p_type NOT IN ('enfant', 'adulte'))
     OR (p_etat IS NOT NULL AND p_etat NOT IN ('active', 'attente_enseignant', 'cloturee'))
     OR (p_jour IS NOT NULL AND p_jour NOT BETWEEN 1 AND 7)
     OR (p_heure IS NOT NULL AND p_heure NOT BETWEEN 0 AND 23)
     OR (p_genre IS NOT NULL AND p_genre NOT IN ('hommes', 'femmes', 'indetermine'))
     OR (p_remplissage IS NOT NULL AND p_remplissage NOT IN ('pleine', 'avec_places'))
     OR (coalesce(p_sans_enseignant, false) AND p_enseignant_id IS NOT NULL) THEN
    RAISE EXCEPTION 'filtre de classes invalide' USING ERRCODE = '22023';
  END IF;

  v_texte := pg_catalog.translate(pg_catalog.lower(pg_catalog.btrim(coalesce(p_texte, ''))),
    'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ', 'aaaaaaceeeeiiiinooooouuuuyy');
  v_masque := coalesce(public.agent_identite_masquee(), false);

  RETURN (
    WITH toutes AS MATERIALIZED (
      SELECT g.id AS groupe_id, g.libelle, g.type_public, g.seuil_max, g.teacher_id,
             p.immutable_id AS teacher_immutable_id,
             CASE WHEN v_masque THEN NULL ELSE p.first_name END AS teacher_prenom,
             CASE WHEN v_masque THEN NULL ELSE p.last_name END AS teacher_nom,
             g.weekday, g.hour_local, g.timezone_iana,
             (SELECT count(*)::integer FROM public.groupe_membres m
               WHERE m.groupe_id = g.id AND m.left_at IS NULL) AS nombre_membres,
             g.ended_at IS NULL AS actif,
             coalesce(g.genre_public, 'indetermine') AS genre,
             n.numero
      FROM public.groupes g
      JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
      LEFT JOIN public.profiles p ON p.id = g.teacher_id
    ),
    qualifiees AS MATERIALIZED (
      SELECT t.*,
             CASE WHEN NOT t.actif THEN 'cloturee'
                  WHEN t.teacher_id IS NULL THEN 'attente_enseignant'
                  ELSE 'active' END AS etat_liste,
             CASE WHEN t.seuil_max > 0 AND t.nombre_membres >= t.seuil_max THEN 'pleine'
                  ELSE 'avec_places' END AS remplissage
      FROM toutes t
    ),
    autres_axes AS MATERIALIZED (
      SELECT q.* FROM qualifiees q
      WHERE (p_type IS NULL OR q.type_public = p_type)
        AND (p_jour IS NULL OR q.weekday = p_jour)
        AND (p_heure IS NULL OR q.hour_local = p_heure)
        AND (p_fuseau IS NULL OR q.timezone_iana = p_fuseau)
        AND (p_genre IS NULL OR q.genre = p_genre)
        AND (p_remplissage IS NULL OR q.remplissage = p_remplissage)
        AND (NOT coalesce(p_sans_enseignant, false) OR q.teacher_id IS NULL)
        AND (p_enseignant_id IS NULL OR q.teacher_id = p_enseignant_id)
        AND (v_texte = '' OR pg_catalog.strpos(
              pg_catalog.translate(pg_catalog.lower(
                q.libelle || ' ' || q.numero::text || ' n° ' || q.numero::text || ' '
                || coalesce(q.teacher_prenom, '') || ' ' || coalesce(q.teacher_nom, '')),
                'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ', 'aaaaaaceeeeiiiinooooouuuuyy'),
              v_texte) > 0)
    ),
    retenues AS MATERIALIZED (
      SELECT a.* FROM autres_axes a WHERE p_etat IS NULL OR a.etat_liste = p_etat
    ),
    pagination AS (
      SELECT count(*)::integer AS total,
             least(p_page, greatest(1, ((count(*)::integer + p_taille - 1) / p_taille))) AS page
      FROM retenues
    ),
    page_lignes AS (
      SELECT r.* FROM retenues r
      ORDER BY r.libelle, r.numero, r.groupe_id
      OFFSET ((SELECT page FROM pagination) - 1) * p_taille LIMIT p_taille
    )
    SELECT pg_catalog.jsonb_build_object(
      'lignes', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'groupe_id', l.groupe_id, 'libelle', l.libelle, 'type_public', l.type_public,
                 'seuil_max', l.seuil_max, 'teacher_id', l.teacher_id,
                 'teacher_immutable_id', l.teacher_immutable_id,
                 'teacher_prenom', l.teacher_prenom, 'teacher_nom', l.teacher_nom,
                 'weekday', l.weekday, 'hour_local', l.hour_local,
                 'timezone_iana', l.timezone_iana, 'nombre_membres', l.nombre_membres,
                 'actif', l.actif, 'numero_dans_famille', l.numero, 'code_court', NULL,
                 'genre', l.genre, 'sans_enseignant', l.teacher_id IS NULL,
                 'peut_affecter_enseignant', l.actif AND l.teacher_id IS NULL,
                 'peut_fusionner', l.actif AND l.nombre_membres > 0,
                 'peut_transferer', l.actif AND l.nombre_membres > 0)
               ORDER BY l.libelle, l.numero, l.groupe_id)
        FROM page_lignes l), '[]'::jsonb),
      'total', (SELECT total FROM pagination),
      'page', (SELECT page FROM pagination),
      'taille', p_taille,
      'compteurs', (
        SELECT pg_catalog.jsonb_build_object(
                 'active', count(*) FILTER (WHERE a.etat_liste = 'active'),
                 'attente_enseignant', count(*) FILTER (WHERE a.etat_liste = 'attente_enseignant'),
                 'cloturee', count(*) FILTER (WHERE a.etat_liste = 'cloturee'))
        FROM autres_axes a),
      'jours', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT t.weekday ORDER BY t.weekday) FROM toutes t), '[]'::jsonb),
      'heures', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT t.hour_local ORDER BY t.hour_local) FROM toutes t), '[]'::jsonb),
      'fuseaux', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT t.timezone_iana ORDER BY t.timezone_iana) FROM toutes t), '[]'::jsonb),
      'genres', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT t.genre ORDER BY t.genre) FROM toutes t), '[]'::jsonb),
      'enseignants', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('id', e.teacher_id, 'libelle', e.libelle)
                                    ORDER BY e.libelle, e.teacher_id)
        FROM (SELECT DISTINCT t.teacher_id,
                     pg_catalog.btrim(coalesce(t.teacher_prenom, '') || ' ' || coalesce(t.teacher_nom, '')) AS libelle
                FROM toutes t WHERE t.teacher_id IS NOT NULL) e), '[]'::jsonb),
      'total_sans_filtre', (SELECT count(*) FROM toutes)
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.classes_admin_page(integer, integer, text, text, text, integer, integer, text, text, uuid, boolean, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.classes_admin_page(integer, integer, text, text, text, integer, integer, text, text, uuid, boolean, text)
  TO authenticated;
COMMENT ON FUNCTION public.classes_admin_page(integer, integer, text, text, text, integer, integer, text, text, uuid, boolean, text) IS
  'F86: signature=public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text); md5_functiondef=524b54ff3e68e1099a3416f67ae71c6f; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortClassesAdmin.page. Garde: direction active (R16, R17).';

-- Index des colonnes filtrees (R17) : l'enseignant et l'etat existent deja ;
-- l'horaire et le public n'en avaient pas.
CREATE INDEX groupes_horaire_public_idx
  ON public.groupes (weekday, hour_local, timezone_iana, type_public);

DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.classes_admin_page(integer,integer,text,text,text,integer,integer,text,text,uuid,boolean,text)'::regprocedure, '524b54ff3e68e1099a3416f67ae71c6f')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) OR EXISTS (
    SELECT 1 FROM (VALUES
      ('app_private.classes_numerotees()'::regprocedure),
      ('app_private.instant_hebdo_utc(integer,integer,text)'::regprocedure)
    ) AS e(oid)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CONTRATS classes admin : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;

COMMIT;
