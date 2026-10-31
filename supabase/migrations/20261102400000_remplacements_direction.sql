-- Remplacements cote direction (finir REMPL-1, 31/10/2026).
--
-- Existant reutilise : remplacements_seance, remplacement_enseignant_compatible,
-- designer_remplacant_admin (20261011185954_b09_remplacements_seance.sql),
-- private.c29_enseignant_effectif_session (20261011200002), le declencheur de
-- notifications des enseignants (inchange).
--
-- Ce que cette migration ajoute, et rien d'autre :
--
-- 1. R12 (DECISION-CLASSES-SIMULTANEES-2026-10-10.md, corrige le 10/10) :
--    * le remplacant doit etre libre a l'instant exact de la seance : regle
--      stricte, absente de designer_remplacant_admin jusqu'ici ;
--    * le genre est souple : la direction peut choisir un enseignant de
--      l'autre genre, par un choix explicite (p_hors_genre) et trace
--      (colonne choix_hors_genre de l'evenement, et journal d'acces).
--    designer_remplacant_admin(uuid,uuid,uuid,boolean) porte la regle ; la
--    forme a trois arguments, appelee par aucun ecran, devient son alias sans
--    choix hors genre (meme contrat qu'avant, plus la liberte a l'heure).
-- 2. remplacants_possibles_seance(uuid) : les enseignants libres a l'heure
--    exacte, chacun avec genre_compatible. Lecture de la direction seule.
-- 3. remplacements_direction(timestamptz, timestamptz) : sur une periode,
--    l'agregat par titulaire et par classe, et l'etat de chaque seance
--    concernee. Aucun seuil : la decision reste a la direction.
--
-- Aucune suppression. Pas de BEGIN/COMMIT : le fichier s'applique en une
-- transaction par l'outil de migration.

ALTER TABLE public.remplacements_seance
  ADD COLUMN IF NOT EXISTS choix_hors_genre boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.remplacements_seance.choix_hors_genre IS
  'R12 : vrai quand la direction a designe explicitement un enseignant hors du genre de la classe.';

-- ---------------------------------------------------------------------------
-- Liberte a l'heure exacte : aucune autre seance non annulee dont il est
-- l'enseignant effectif (titulaire non remplace, ou remplacant) ne chevauche
-- la seance.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.remplacant_libre_a_l_heure(
  p_session_id uuid, p_teacher_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (SELECT 1 FROM public.sessions s WHERE s.id = p_session_id)
     AND NOT EXISTS (
    SELECT 1
      FROM public.sessions s
      JOIN public.sessions autre
        ON autre.id <> s.id
       AND autre.deleted_at IS NULL
       AND autre.status NOT IN ('canceled', 'canceled_late')
       AND autre.started_at < s.ended_at
       AND autre.ended_at > s.started_at
     WHERE s.id = p_session_id
       AND private.c29_enseignant_effectif_session(autre.id) = p_teacher_id
  );
$function$;
ALTER FUNCTION private.remplacant_libre_a_l_heure(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacant_libre_a_l_heure(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Eligibilite hors genre : la meme que remplacement_enseignant_compatible,
-- sans la condition de genre (compte actif, KYC approuve, classe active).
CREATE FUNCTION private.remplacant_eligible_sans_genre(
  p_session_id uuid, p_teacher_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id
      JOIN public.profiles p ON p.id = p_teacher_id
      JOIN public.teacher_profiles tp ON tp.profile_id = p.id
     WHERE s.id = p_session_id
       AND s.deleted_at IS NULL
       AND g.ended_at IS NULL
       AND p.role = 'teacher'
       AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
       AND tp.deleted_at IS NULL
       AND tp.kyc_status = 'approved'
  );
$function$;
ALTER FUNCTION private.remplacant_eligible_sans_genre(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacant_eligible_sans_genre(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 1. La designation par la direction.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.designer_remplacant_admin(
  p_session_id uuid, p_remplacant_id uuid, p_cle_idempotence uuid,
  p_hors_genre boolean
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_session public.sessions%ROWTYPE;
  v_existing public.remplacements_seance%ROWTYPE;
  v_compatible boolean;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL OR p_remplacant_id IS NULL OR p_cle_idempotence IS NULL
     OR p_hors_genre IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE acteur_id = auth.uid() AND cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_existing.session_id <> p_session_id OR v_existing.evenement <> 'remplacement_designe_admin'
       OR v_existing.enseignant_remplacant_id <> p_remplacant_id THEN
      RAISE EXCEPTION 'CleIdempotenceDejaUtilisee' USING ERRCODE = '23505';
    END IF;
    RETURN pg_catalog.jsonb_build_object('etat', 'designe', 'sessionId', p_session_id);
  END IF;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  IF NOT FOUND OR v_session.deleted_at IS NOT NULL OR v_session.status <> 'planned'
     OR v_session.started_at <= pg_catalog.now() OR v_session.groupe_id IS NULL THEN
    RAISE EXCEPTION 'SeanceIndisponible' USING ERRCODE = 'P0002';
  END IF;
  IF p_remplacant_id = v_session.teacher_id THEN
    RAISE EXCEPTION 'RemplacantIncompatible' USING ERRCODE = '22023';
  END IF;
  v_compatible := public.remplacement_enseignant_compatible(p_session_id, p_remplacant_id);
  IF NOT v_compatible
     AND NOT (p_hors_genre AND private.remplacant_eligible_sans_genre(p_session_id, p_remplacant_id)) THEN
    RAISE EXCEPTION 'RemplacantIncompatible' USING ERRCODE = '22023';
  END IF;
  -- R12, regle stricte : libre a l'instant exact de la seance.
  IF NOT private.remplacant_libre_a_l_heure(p_session_id, p_remplacant_id) THEN
    RAISE EXCEPTION 'RemplacantOccupe' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
  IF FOUND AND v_existing.evenement IN ('remplacement_pris', 'remplacement_designe_admin') THEN
    RAISE EXCEPTION 'RemplacementDejaPris' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence, choix_hors_genre)
  VALUES (p_session_id, 'remplacement_designe_admin', v_session.teacher_id,
          p_remplacant_id, auth.uid(), p_cle_idempotence, NOT v_compatible);
  PERFORM public.log_sensitive_access('replacement_admin_assigned', 'remplacements_seance',
    p_session_id::text,
    pg_catalog.jsonb_build_object('session_id', p_session_id,
      'replacement_teacher_id', p_remplacant_id, 'choix_hors_genre', NOT v_compatible));
  RETURN pg_catalog.jsonb_build_object('etat', 'designe', 'sessionId', p_session_id);
END;
$function$;
ALTER FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid, boolean)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid, boolean)
  TO authenticated;

-- La forme a trois arguments : meme garde, sans choix hors genre.
CREATE OR REPLACE FUNCTION public.designer_remplacant_admin(
  p_session_id uuid, p_remplacant_id uuid, p_cle_idempotence uuid
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  RETURN public.designer_remplacant_admin(p_session_id, p_remplacant_id, p_cle_idempotence, false);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Les remplacants possibles d'une seance.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.remplacants_possibles_seance(p_session_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_titulaire uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT s.teacher_id INTO v_titulaire FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL AND s.status = 'planned'
     AND s.started_at > pg_catalog.now() AND s.groupe_id IS NOT NULL;
  IF NOT FOUND THEN
    RETURN '[]'::jsonb;
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'enseignant_id', c.id, 'nom', c.nom, 'identifiant', c.immutable_id,
             'genre_compatible', c.compatible)
           ORDER BY c.compatible DESC, c.nom, c.id)
      FROM (
        SELECT p.id, p.immutable_id,
               pg_catalog.btrim(pg_catalog.concat_ws(' ', p.first_name, p.last_name)) AS nom,
               public.remplacement_enseignant_compatible(p_session_id, p.id) AS compatible
          FROM public.profiles p
         WHERE p.role = 'teacher'
           AND p.id <> v_titulaire
           AND private.remplacant_eligible_sans_genre(p_session_id, p.id)
           AND private.remplacant_libre_a_l_heure(p_session_id, p.id)
         LIMIT 200
      ) c), '[]'::jsonb);
END;
$function$;
ALTER FUNCTION public.remplacants_possibles_seance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remplacants_possibles_seance(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.remplacants_possibles_seance(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Les remplacements par enseignant et par classe, sur une periode.
--    Periode bornee a 93 jours. Une seance compte une fois : son dernier
--    evenement dit si elle a ete remplacee ou reste sans remplacant.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.remplacements_direction(p_debut timestamptz, p_fin timestamptz)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_debut IS NULL OR p_fin IS NULL OR p_fin <= p_debut
     OR p_fin - p_debut > interval '93 days' THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  RETURN (
    WITH seances AS (
      SELECT s.id AS seance_id, s.groupe_id, s.started_at, s.status,
             d.enseignant_titulaire_id AS titulaire_id,
             d.evenement, d.enseignant_remplacant_id AS remplacant_id,
             d.choix_hors_genre
        FROM public.sessions s
        CROSS JOIN LATERAL (
          SELECT r.evenement, r.enseignant_titulaire_id, r.enseignant_remplacant_id,
                 r.choix_hors_genre
            FROM public.remplacements_seance r
           WHERE r.session_id = s.id
           ORDER BY r.cree_le DESC, r.id DESC LIMIT 1
        ) d
       WHERE s.deleted_at IS NULL
         AND s.started_at >= p_debut AND s.started_at < p_fin
    )
    SELECT pg_catalog.jsonb_build_object(
      'par_enseignant', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'titulaire_id', a.titulaire_id, 'titulaire', a.titulaire,
                 'groupe_id', a.groupe_id, 'classe', a.classe,
                 'numero_dans_famille', a.numero,
                 'seances', a.seances, 'remplacees', a.remplacees,
                 'sans_remplacant', a.sans_remplacant,
                 'hors_genre', a.hors_genre, 'derniere', a.derniere)
               ORDER BY a.seances DESC, a.titulaire, a.classe)
          FROM (
            SELECT x.titulaire_id, x.groupe_id,
                   pg_catalog.btrim(pg_catalog.concat_ws(' ', p.first_name, p.last_name)) AS titulaire,
                   coalesce(g.libelle, '') AS classe, n.numero,
                   pg_catalog.count(*)::integer AS seances,
                   pg_catalog.count(*) FILTER (WHERE x.evenement <> 'absence_declaree')::integer AS remplacees,
                   pg_catalog.count(*) FILTER (WHERE x.evenement = 'absence_declaree')::integer AS sans_remplacant,
                   pg_catalog.count(*) FILTER (WHERE x.choix_hors_genre)::integer AS hors_genre,
                   pg_catalog.max(x.started_at) AS derniere
              FROM seances x
              JOIN public.profiles p ON p.id = x.titulaire_id
              LEFT JOIN public.groupes g ON g.id = x.groupe_id
              LEFT JOIN app_private.classes_numerotees() n ON n.groupe_id = x.groupe_id
             GROUP BY x.titulaire_id, x.groupe_id, p.first_name, p.last_name, g.libelle, n.numero
          ) a), '[]'::jsonb),
      'seances', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'seance_id', x.seance_id,
                 'etat', CASE WHEN x.evenement = 'absence_declaree' THEN 'absence_declaree'
                              ELSE 'remplacee' END,
                 'remplacant', CASE WHEN x.remplacant_id IS NULL THEN NULL ELSE
                   pg_catalog.btrim(pg_catalog.concat_ws(' ', r.first_name, r.last_name)) END,
                 'hors_genre', x.choix_hors_genre)
               ORDER BY x.started_at, x.seance_id)
          FROM seances x
          LEFT JOIN public.profiles r ON r.id = x.remplacant_id), '[]'::jsonb)
    )
  );
END;
$function$;
ALTER FUNCTION public.remplacements_direction(timestamptz, timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remplacements_direction(timestamptz, timestamptz)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.remplacements_direction(timestamptz, timestamptz)
  TO authenticated;

COMMENT ON FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid, boolean) IS
  'R12 (31/10/2026) : direction active ; remplacant libre a l''heure exacte (strict), genre souple sur choix explicite trace (choix_hors_genre). guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path="".';
COMMENT ON FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid) IS
  'Alias (31/10/2026) de designer_remplacant_admin(uuid,uuid,uuid,boolean) sans choix hors genre ; garde direction active repetee. Remplace le commentaire F86 du 11/10, dont l''empreinte ne vaut plus.';
COMMENT ON FUNCTION public.remplacants_possibles_seance(uuid) IS
  'R12 (31/10/2026) : enseignants libres a l''heure exacte d''une seance a venir, avec genre_compatible. Direction active seule. STABLE.';
COMMENT ON FUNCTION public.remplacements_direction(timestamptz, timestamptz) IS
  'Remplacements par titulaire et par classe sur une periode (93 jours au plus), et etat de chaque seance. Direction active seule. STABLE, aucun seuil.';

DO $postflight$
DECLARE f record;
BEGIN
  FOR f IN SELECT p.oid, p.oid::regprocedure AS sig, p.prosecdef, p.proconfig, p.proowner
             FROM pg_catalog.pg_proc p
            WHERE p.oid IN (
              'public.designer_remplacant_admin(uuid,uuid,uuid,boolean)'::regprocedure,
              'public.designer_remplacant_admin(uuid,uuid,uuid)'::regprocedure,
              'public.remplacants_possibles_seance(uuid)'::regprocedure,
              'public.remplacements_direction(timestamptz,timestamptz)'::regprocedure)
  LOOP
    IF NOT f.prosecdef OR pg_catalog.pg_get_userbyid(f.proowner) <> 'postgres'
       OR f.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[]
       OR pg_catalog.has_function_privilege('anon', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f.oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Remplacements direction : DEFINER, search_path ou droits invalides pour %', f.sig;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.remplacant_libre_a_l_heure(uuid,uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'private.remplacant_eligible_sans_genre(uuid,uuid)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'Remplacements direction : aide privee exposee';
  END IF;
END;
$postflight$;
