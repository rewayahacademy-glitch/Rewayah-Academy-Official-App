-- CONTRATS-MANQUANTS (3/6) : le tableau de pilotage de la direction, par
-- horaire et par categorie (R7, R9, R17, R19).
--
-- Contrat : lib/core/admin/port_pilotage.dart (PortPilotage.page).
--
-- Une ligne = un public et un horaire local (jour ISO, heure, fuseau) qui
-- porte au moins une classe active ou une demande en attente ('envoyee' ;
-- une demande a plusieurs jours compte sur son premier creneau, jour puis
-- heure).
--
-- * classes, effectif, capacite : les classes actives de l'horaire.
-- * classes_sous_minimum (R9) : effectif < groupe.minimum_lancement.
-- * classes_attente_enseignant (R7) : classe active sans enseignant.
-- * Enseignants libres d'un genre (R7, genre compris) : enseignant valide
--   (compte actif, KYC approuve, genre connu) qui a declare une disponibilite
--   au meme instant UTC (app_private.instant_hebdo_utc, quatre semaines de
--   reference) et n'enseigne pas deja une classe active qui croise cet
--   instant sur l'une de ces semaines (app_private.instants_se_croisent).
--   Les hommes couvrent les classes 'hommes', les femmes les classes
--   'femmes'.
-- * Manquants : classes en attente du genre moins libres du genre ; pour les
--   demandes (genre encore inconnu, 'indetermine'), les classes a ouvrir
--   pour les demandes qui ne tiennent pas dans les places restantes
--   (ceil / groupe.capacite_<public>), moins les libres non employes.
-- * Tri et pagination comme paginerPilotage() : penurie d'abord, puis le plus
--   de manquants, puis le plus de classes en attente, puis jour, heure, id.
-- DEFINER, garde positive direction active : groupe_membres, weekly_availability
-- et demandes_horaires_famille ne sont lisibles par aucun client.
BEGIN;

-- Deux instants hebdomadaires (app_private.instant_hebdo_utc) se croisent
-- quand ils tombent au meme instant UTC sur au moins une des semaines de
-- reference : un enseignant de New York a 12 h est occupe pour Paris 18 h
-- les semaines ou les deux coincident.
CREATE FUNCTION app_private.instants_se_croisent(p_a text, p_b text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM pg_catalog.generate_series(1, 4) AS i(n)
    WHERE pg_catalog.split_part(p_a, '/', i.n) <> ''
      AND pg_catalog.split_part(p_a, '/', i.n) = pg_catalog.split_part(p_b, '/', i.n));
$function$;
REVOKE ALL ON FUNCTION app_private.instants_se_croisent(text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.pilotage_admin_page(
  p_page integer DEFAULT 1,
  p_taille integer DEFAULT 25,
  p_type text DEFAULT NULL,
  p_jour integer DEFAULT NULL,
  p_heure integer DEFAULT NULL,
  p_fuseau text DEFAULT NULL,
  p_signal text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_minimum integer;
  v_cap_enfant integer;
  v_cap_adulte integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pilotage reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_page IS NULL OR p_page < 1 OR p_taille IS NULL OR p_taille NOT BETWEEN 1 AND 100
     OR (p_type IS NOT NULL AND p_type NOT IN ('enfant', 'adulte'))
     OR (p_jour IS NOT NULL AND p_jour NOT BETWEEN 1 AND 7)
     OR (p_heure IS NOT NULL AND p_heure NOT BETWEEN 0 AND 23)
     OR (p_signal IS NOT NULL AND p_signal NOT IN ('penurie', 'sous_minimum', 'attente_enseignant')) THEN
    RAISE EXCEPTION 'filtre de pilotage invalide' USING ERRCODE = '22023';
  END IF;

  v_minimum := public.app_config_int('groupe.minimum_lancement', 3);
  v_cap_enfant := greatest(1, public.app_config_int('groupe.capacite_enfant', 5));
  v_cap_adulte := greatest(1, public.app_config_int('groupe.capacite_adulte', 6));

  RETURN (
    WITH classes AS MATERIALIZED (
      SELECT g.type_public AS type, g.weekday::integer AS jour, g.hour_local::integer AS heure,
             g.timezone_iana AS fuseau, coalesce(g.genre_public, 'indetermine') AS genre,
             g.seuil_max::integer AS capacite, g.teacher_id,
             (SELECT count(*)::integer FROM public.groupe_membres m
               WHERE m.groupe_id = g.id AND m.left_at IS NULL) AS membres
      FROM public.groupes g
      WHERE g.ended_at IS NULL
    ),
    demandes AS MATERIALIZED (
      SELECT d.type_public AS type, premier.jour, premier.heure, d.fuseau_iana AS fuseau
      FROM public.demandes_horaires_famille d
      CROSS JOIN LATERAL (
        SELECT u.j::integer AS jour, u.h::integer AS heure
        FROM unnest(d.jours, d.heures_locales) AS u(j, h)
        ORDER BY u.j, u.h LIMIT 1
      ) premier
      WHERE d.etat = 'envoyee'
    ),
    cles AS MATERIALIZED (
      SELECT k.*, app_private.instant_hebdo_utc(k.jour, k.heure, k.fuseau) AS instant
      FROM (SELECT type, jour, heure, fuseau FROM classes
            UNION SELECT type, jour, heure, fuseau FROM demandes) k
    ),
    enseignants AS MATERIALIZED (
      SELECT DISTINCT p.id, CASE p.gender WHEN 'male' THEN 'hommes' ELSE 'femmes' END AS genre,
             app_private.instant_hebdo_utc(wa.weekday, wa.hour_local, wa.timezone_iana) AS instant
      FROM public.profiles p
      JOIN public.teacher_profiles tp ON tp.profile_id = p.id
      JOIN public.weekly_availability wa ON wa.profile_id = p.id
      WHERE p.role = 'teacher' AND p.deleted_at IS NULL
        AND p.account_status IN ('active', 'provisional_active')
        AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
        AND p.gender IS NOT NULL
        AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
    ),
    occupes AS MATERIALIZED (
      SELECT DISTINCT g.teacher_id AS id,
             app_private.instant_hebdo_utc(s.weekday, s.hour_local, g.timezone_iana) AS instant
      FROM public.groupes g
      CROSS JOIN LATERAL (
        SELECT g.weekday, g.hour_local
        UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
      ) s
      WHERE g.ended_at IS NULL AND g.teacher_id IS NOT NULL AND g.etat = 'active'
    ),
    lignes AS MATERIALIZED (
      SELECT c.*,
             c.attente_h + c.attente_f + c.attente_i AS attente,
             greatest(0, c.attente_h - c.libres_h) AS manquants_h,
             greatest(0, c.attente_f - c.libres_f) AS manquants_f,
             greatest(0, c.attente_i
               + ((greatest(0, c.demandes - greatest(0, c.capacite - c.effectif))
                   + c.cap_type - 1) / c.cap_type)
               - greatest(0, c.libres_h - c.attente_h)
               - greatest(0, c.libres_f - c.attente_f)) AS manquants_i,
             c.attente_i
               + ((greatest(0, c.demandes - greatest(0, c.capacite - c.effectif))
                   + c.cap_type - 1) / c.cap_type) AS besoin_i
      FROM (
        SELECT k.type, k.jour, k.heure, k.fuseau,
               CASE k.type WHEN 'enfant' THEN v_cap_enfant ELSE v_cap_adulte END AS cap_type,
               (SELECT count(*)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau)) AS classes,
               (SELECT coalesce(sum(c.membres), 0)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau)) AS effectif,
               (SELECT coalesce(sum(c.capacite), 0)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau)) AS capacite,
               (SELECT count(*)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau) AND c.membres < v_minimum) AS sous_minimum,
               (SELECT count(*)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau) AND c.teacher_id IS NULL AND c.genre = 'hommes') AS attente_h,
               (SELECT count(*)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau) AND c.teacher_id IS NULL AND c.genre = 'femmes') AS attente_f,
               (SELECT count(*)::integer FROM classes c WHERE (c.type, c.jour, c.heure, c.fuseau) = (k.type, k.jour, k.heure, k.fuseau) AND c.teacher_id IS NULL AND c.genre = 'indetermine') AS attente_i,
               (SELECT count(*)::integer FROM demandes d WHERE (d.type, d.jour, d.heure, d.fuseau) = (k.type, k.jour, k.heure, k.fuseau)) AS demandes,
               (SELECT count(*)::integer FROM enseignants e WHERE e.instant = k.instant AND e.genre = 'hommes'
                  AND NOT EXISTS (SELECT 1 FROM occupes o WHERE o.id = e.id
                                    AND app_private.instants_se_croisent(o.instant, k.instant))) AS libres_h,
               (SELECT count(*)::integer FROM enseignants e WHERE e.instant = k.instant AND e.genre = 'femmes'
                  AND NOT EXISTS (SELECT 1 FROM occupes o WHERE o.id = e.id
                                    AND app_private.instants_se_croisent(o.instant, k.instant))) AS libres_f
        FROM cles k
      ) c
    ),
    signalees AS MATERIALIZED (
      SELECT l.*,
             l.manquants_h + l.manquants_f + l.manquants_i AS manquants,
             (l.manquants_h + l.manquants_f + l.manquants_i) > 0 AS penurie,
             l.type || '|' || l.jour || '|' || l.heure || '|' || l.fuseau AS id
      FROM lignes l
    ),
    autres_axes AS MATERIALIZED (
      SELECT s.* FROM signalees s
      WHERE (p_type IS NULL OR s.type = p_type)
        AND (p_jour IS NULL OR s.jour = p_jour)
        AND (p_heure IS NULL OR s.heure = p_heure)
        AND (p_fuseau IS NULL OR s.fuseau = p_fuseau)
    ),
    retenues AS MATERIALIZED (
      SELECT a.* FROM autres_axes a
      WHERE p_signal IS NULL
         OR (p_signal = 'penurie' AND a.penurie)
         OR (p_signal = 'sous_minimum' AND a.sous_minimum > 0)
         OR (p_signal = 'attente_enseignant' AND a.attente > 0)
    ),
    pagination AS (
      SELECT count(*)::integer AS total,
             least(p_page, greatest(1, ((count(*)::integer + p_taille - 1) / p_taille))) AS page
      FROM retenues
    ),
    page_lignes AS (
      SELECT r.*, pg_catalog.row_number() OVER (
               ORDER BY r.penurie DESC, r.manquants DESC, r.attente DESC, r.jour, r.heure, r.id) AS rang
      FROM retenues r
      ORDER BY r.penurie DESC, r.manquants DESC, r.attente DESC, r.jour, r.heure, r.id
      OFFSET ((SELECT page FROM pagination) - 1) * p_taille LIMIT p_taille
    )
    SELECT pg_catalog.jsonb_build_object(
      'lignes', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'id', l.id, 'jour', l.jour, 'heure', l.heure, 'fuseau', l.fuseau,
                 'type', l.type, 'classes', l.classes, 'effectif', l.effectif,
                 'capacite', l.capacite, 'classes_sous_minimum', l.sous_minimum,
                 'classes_attente_enseignant', l.attente,
                 'demandes_en_attente', l.demandes,
                 'par_genre',
                   pg_catalog.jsonb_build_array(
                     pg_catalog.jsonb_build_object('genre', 'hommes', 'libres', l.libres_h, 'manquants', l.manquants_h),
                     pg_catalog.jsonb_build_object('genre', 'femmes', 'libres', l.libres_f, 'manquants', l.manquants_f))
                   || CASE WHEN l.besoin_i > 0 THEN pg_catalog.jsonb_build_array(
                        pg_catalog.jsonb_build_object('genre', 'indetermine', 'libres', 0, 'manquants', l.manquants_i))
                      ELSE '[]'::jsonb END)
               ORDER BY l.rang)
        FROM page_lignes l), '[]'::jsonb),
      'total', (SELECT total FROM pagination),
      'page', (SELECT page FROM pagination),
      'taille', p_taille,
      'resume', (
        SELECT pg_catalog.jsonb_build_object(
                 'classes', coalesce(sum(r.classes), 0),
                 'classes_attente_enseignant', coalesce(sum(r.attente), 0),
                 'classes_sous_minimum', coalesce(sum(r.sous_minimum), 0),
                 'demandes_en_attente', coalesce(sum(r.demandes), 0),
                 'enseignants_libres', coalesce(sum(r.libres_h + r.libres_f), 0),
                 'enseignants_manquants', coalesce(sum(r.manquants), 0))
        FROM retenues r),
      'compteurs', (
        SELECT pg_catalog.jsonb_build_object(
                 'penurie', count(*) FILTER (WHERE a.penurie),
                 'sous_minimum', count(*) FILTER (WHERE a.sous_minimum > 0),
                 'attente_enseignant', count(*) FILTER (WHERE a.attente > 0))
        FROM autres_axes a),
      'jours', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT s.jour ORDER BY s.jour) FROM signalees s), '[]'::jsonb),
      'heures', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT s.heure ORDER BY s.heure) FROM signalees s), '[]'::jsonb),
      'fuseaux', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT s.fuseau ORDER BY s.fuseau) FROM signalees s), '[]'::jsonb),
      'total_sans_filtre', (SELECT count(*) FROM signalees)
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.pilotage_admin_page(integer, integer, text, integer, integer, text, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.pilotage_admin_page(integer, integer, text, integer, integer, text, text)
  TO authenticated;
COMMENT ON FUNCTION public.pilotage_admin_page(integer, integer, text, integer, integer, text, text) IS
  'F86: signature=public.pilotage_admin_page(integer,integer,text,integer,integer,text,text); md5_functiondef=5d631602fc15721ec7f3500feb574cc4; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortPilotage.page. Garde: direction active (R7, R9, R17, R19).';

DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.pilotage_admin_page(integer,integer,text,integer,integer,text,text)'::regprocedure, '5d631602fc15721ec7f3500feb574cc4')
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
      ('app_private.instants_se_croisent(text,text)'::regprocedure)
    ) AS e(oid)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CONTRATS pilotage : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;

COMMIT;
