-- CONTRATS-MANQUANTS (5/6) : le support actif d'une seance (CAP29-G).
--
-- Contrat : lib/core/tc_bibliotheque/port_support_actif.dart
-- (PortSupportActif : capacites, activer, suivre).
--
-- * Aucune table nouvelle : le support actif est la ligne de
--   session_shared_content de la seance (etat partage existant, 0030-0033) ;
--   l'idempotence reprend pedagogie_partage_idempotence (operation
--   'presenter_support').
-- * support_actif_capacites : peut_presenter vaut vrai pour l'enseignant de
--   la seance (ou la direction) tant que la seance n'est pas terminee.
-- * presenter_support : recontrole les droits A CHAQUE activation :
--   'retire' (ressource archivee ou sans version publiee), 'droits_echus'
--   (droits de la version courante non approuves, sans usage 'classe' ou
--   echus), 'non_attribue' (ressource non attribuee a la classe de la
--   seance). Controle optimiste : revision attendue = revision courante (0
--   sans support), sinon 'conflit'. La meme cle rend la meme reponse.
-- * support_actif : la lecture de la classe, qui recontrole aussi les droits
--   et rend retire = vrai quand ils sont tombes en cours de seance. Aucune URL
--   signee ni cle de stockage. Le suivi en continu passe par Realtime sur
--   session_shared_content (policies de lecture existantes), puis relit
--   support_actif.
-- * DEFINER : l'ecriture de session_shared_content n'est ouverte a aucun
--   client, et la lecture du titre ne doit pas dependre de la policy du
--   catalogue pour l'eleve.
BEGIN;

-- L'etat de la ressource pour une classe : NULL quand elle est presentable,
-- sinon le motif. INTERNE : INVOKER sans EXECUTE client, appelee seulement
-- depuis presenter_support et support_actif (DEFINER), apres leur garde.
CREATE FUNCTION app_private.support_refus(p_resource_id uuid, p_groupe_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN r.id IS NULL OR r.archived_at IS NOT NULL OR r.current_version_id IS NULL THEN 'retire'
    WHEN NOT EXISTS (
      SELECT 1 FROM public.library_version_rights d
       WHERE d.resource_version_id = r.current_version_id
         AND d.approuve AND 'classe' = ANY (d.usages)
         AND (d.expire_le IS NULL OR d.expire_le > pg_catalog.now())) THEN 'droits_echus'
    WHEN p_groupe_id IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.library_resource_groupe lrg
       WHERE lrg.resource_id = r.id AND lrg.groupe_id = p_groupe_id) THEN 'non_attribue'
    ELSE NULL END
  FROM (SELECT 1) un
  LEFT JOIN public.library_resource r ON r.id = p_resource_id;
$function$;
REVOKE ALL ON FUNCTION app_private.support_refus(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le support actif tel que la classe le recoit, ou NULL.
CREATE FUNCTION app_private.support_actif_json(p_seance_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'resource_id', c.resource_id, 'titre', r.title, 'type', r.resource_type,
    'revision', c.revision, 'numero_version', v.numero_version,
    'position', c.content_position,
    'retire', app_private.support_refus(c.resource_id, s.groupe_id) IS NOT NULL)
  FROM public.session_shared_content c
  JOIN public.sessions s ON s.id = c.session_id
  JOIN public.library_resource r ON r.id = c.resource_id
  LEFT JOIN public.resource_version v ON v.id = c.resource_version_id
  WHERE c.session_id = p_seance_id;
$function$;
REVOKE ALL ON FUNCTION app_private.support_actif_json(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Ce que la personne peut faire dans la seance : {peut_presenter}.
CREATE FUNCTION public.support_actif_capacites(p_seance_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'capacites reservees a un compte actif' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object('peut_presenter', coalesce(
    (public.app_role() = 'admin'
     OR (public.app_role() = 'teacher' AND public.session_belongs_to_teacher(p_seance_id, auth.uid())))
    AND EXISTS (SELECT 1 FROM public.sessions s
                 WHERE s.id = p_seance_id AND s.deleted_at IS NULL
                   AND s.status IN ('planned', 'preflight', 'in_progress')),
    false));
END;
$function$;

-- Presenter un support a la classe.
-- Rend {statut: 'faite', actif: {...}} | {statut: 'refusee', raison:
-- 'retire' | 'droits_echus' | 'non_attribue'} | {statut: 'conflit'}.
CREATE FUNCTION public.presenter_support(
  p_seance_id uuid, p_resource_id uuid, p_revision_attendue integer, p_cle text,
  p_position jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_acteur uuid := auth.uid();
  v_deja jsonb;
  v_seance public.sessions;
  v_courante integer;
  v_refus text;
  v_version uuid;
  v_position jsonb;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid()
       AND (public.app_role() = 'admin'
            OR (public.app_role() = 'teacher' AND public.session_belongs_to_teacher(p_seance_id, v_acteur))), false) THEN
    RAISE EXCEPTION 'presentation reservee a l''enseignant de la seance' USING ERRCODE = '42501';
  END IF;
  IF p_seance_id IS NULL OR p_resource_id IS NULL OR p_revision_attendue IS NULL
     OR p_revision_attendue < 0
     OR coalesce(pg_catalog.length(pg_catalog.btrim(p_cle)), 0) NOT BETWEEN 1 AND 200
     OR (p_position IS NOT NULL AND (pg_catalog.jsonb_typeof(p_position) <> 'object'
         OR p_position ->> 'resource_id' IS DISTINCT FROM p_resource_id::text)) THEN
    RAISE EXCEPTION 'presentation invalide' USING ERRCODE = '22023';
  END IF;

  SELECT i.resultat INTO v_deja FROM public.pedagogie_partage_idempotence i
   WHERE i.actor_id = v_acteur AND i.cle_idempotence = p_cle AND i.operation = 'presenter_support';
  IF v_deja IS NOT NULL THEN
    RETURN v_deja;
  END IF;

  SELECT s.* INTO v_seance FROM public.sessions s
   WHERE s.id = p_seance_id AND s.deleted_at IS NULL FOR UPDATE;
  IF v_seance.id IS NULL OR v_seance.status NOT IN ('planned', 'preflight', 'in_progress') THEN
    RAISE EXCEPTION 'seance terminee ou introuvable' USING ERRCODE = '22023';
  END IF;

  v_refus := app_private.support_refus(p_resource_id, v_seance.groupe_id);
  IF v_refus IS NOT NULL THEN
    v_resultat := pg_catalog.jsonb_build_object('statut', 'refusee', 'raison', v_refus);
  ELSE
    SELECT c.revision INTO v_courante FROM public.session_shared_content c
     WHERE c.session_id = p_seance_id FOR UPDATE;
    IF coalesce(v_courante, 0) <> p_revision_attendue THEN
      v_resultat := pg_catalog.jsonb_build_object('statut', 'conflit');
    ELSE
      SELECT r.current_version_id INTO v_version FROM public.library_resource r WHERE r.id = p_resource_id;
      v_position := coalesce(p_position, pg_catalog.jsonb_build_object(
                      'resource_id', p_resource_id, 'type_ancrage', 'page', 'page', 1))
                    || pg_catalog.jsonb_build_object('resource_id', p_resource_id,
                                                     'resource_version_id', v_version);
      INSERT INTO public.session_shared_content AS c (
        session_id, resource_id, resource_version_id, content_position, content_range,
        display_mode, hidden_ranges, semantic_markers, group_resume_position,
        revision, updated_by, updated_at)
      VALUES (p_seance_id, p_resource_id, v_version, v_position, NULL,
              'page', '[]'::jsonb, '[]'::jsonb, NULL,
              coalesce(v_courante, 0) + 1, v_acteur, pg_catalog.now())
      ON CONFLICT (session_id) DO UPDATE
        SET resource_id = excluded.resource_id,
            resource_version_id = excluded.resource_version_id,
            content_position = excluded.content_position,
            content_range = NULL, display_mode = 'page',
            hidden_ranges = '[]'::jsonb, semantic_markers = '[]'::jsonb,
            revision = excluded.revision, updated_by = excluded.updated_by,
            updated_at = excluded.updated_at;
      v_resultat := pg_catalog.jsonb_build_object('statut', 'faite',
                      'actif', app_private.support_actif_json(p_seance_id));
    END IF;
  END IF;

  INSERT INTO public.pedagogie_partage_idempotence (actor_id, cle_idempotence, operation, requete, resultat)
  VALUES (v_acteur, p_cle, 'presenter_support',
          pg_catalog.jsonb_build_object('seance_id', p_seance_id, 'resource_id', p_resource_id,
                                        'revision_attendue', p_revision_attendue),
          v_resultat);
  RETURN v_resultat;
END;
$function$;

-- Le support actif de la seance, ou NULL (aucun support presente).
CREATE FUNCTION public.support_actif(p_seance_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid()
       AND (public.app_role() = 'admin'
            OR public.session_belongs_to_teacher(p_seance_id, auth.uid())
            OR EXISTS (SELECT 1 FROM public.session_participants sp
                        WHERE sp.session_id = p_seance_id AND sp.profile_id = auth.uid()
                          AND sp.deleted_at IS NULL)), false) THEN
    RAISE EXCEPTION 'support actif reserve aux participants de la seance' USING ERRCODE = '42501';
  END IF;
  RETURN app_private.support_actif_json(p_seance_id);
END;
$function$;

REVOKE ALL ON FUNCTION public.support_actif_capacites(uuid) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.presenter_support(uuid, uuid, integer, text, jsonb) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.support_actif(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.support_actif_capacites(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.presenter_support(uuid, uuid, integer, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.support_actif(uuid) TO authenticated;

-- @@F86_DEBUT_SUPPORT@@
COMMENT ON FUNCTION public.presenter_support(uuid, uuid, integer, text, jsonb) IS
  'F86: signature=public.presenter_support(uuid,uuid,integer,text,jsonb); md5_functiondef=cd2b95a389ae401bbc78d920a6e3340f; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: enseignant de la seance ou direction, compte actif.';
COMMENT ON FUNCTION public.support_actif(uuid) IS
  'F86: signature=public.support_actif(uuid); md5_functiondef=0764f157433de7c9dce7800ea62c12e0; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: participant, enseignant de la seance ou direction, compte actif.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.presenter_support(uuid,uuid,integer,text,jsonb)'::regprocedure, 'cd2b95a389ae401bbc78d920a6e3340f', true),
      ('public.support_actif(uuid)'::regprocedure, '0764f157433de7c9dce7800ea62c12e0', true)
    ) AS e(oid, attendu, client)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE') <> e.client
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.support_actif_capacites(uuid)'::regprocedure
      AND (p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
           OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'CONTRATS support actif : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_SUPPORT@@

COMMIT;
