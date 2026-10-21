-- RACCORDEMENT 16/10 (C) : modifier la fiche d'un support de la Bibliotheque
-- (PortBibliothequeAdmin.mettreAJour, ModificationSupport).
--
-- Constat : l'adaptateur levait BibliothequeNonAutorisee, faute de colonnes
-- (organisme, description, conditions d'attribution) et de RPC ; la fiche
-- rendait peutModifier a faux (20261016100700).
--
-- * Trois colonnes nullables sur library_resource ; aucune donnee existante
--   n'est touchee.
-- * library_mettre_a_jour(p_resource_id, p_modification, p_revision_attendue) :
--   DEFINER comme les autres ecritures CAP29 (tables non accordees aux
--   clients), search_path vide, objets qualifies ; porte positive direction
--   active. Cles admises : titre, titreCourt, edition, organisme,
--   description, conditionsAttribution, visibilite, politiqueHorsLigne.
--   Une cle absente ne change rien ; une chaine vide efface un champ
--   facultatif (le titre court retombe sur les 60 premiers signes du titre).
--   Reponse {resultat: 'EcritureFaite' | 'EcritureEnConflit', revision}.
--   Erreurs : 42501, P0002, 22023 (saisie invalide ou support retire).
-- * library_get_detail rend les trois champs et peutModifier = support non
--   retire (le reste du corps est inchange).
BEGIN;

ALTER TABLE public.library_resource
  ADD COLUMN organisme text CHECK (organisme IS NULL OR pg_catalog.length(organisme) <= 200),
  ADD COLUMN description text CHECK (description IS NULL OR pg_catalog.length(description) <= 4000),
  ADD COLUMN conditions_attribution text
    CHECK (conditions_attribution IS NULL OR pg_catalog.length(conditions_attribution) <= 2000);

CREATE FUNCTION public.library_mettre_a_jour(
  p_resource_id uuid, p_modification jsonb, p_revision_attendue integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_titre text;
  v_court text;
  v_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_modification IS NULL OR pg_catalog.jsonb_typeof(p_modification) <> 'object'
     OR (p_modification - ARRAY['titre', 'titreCourt', 'edition', 'organisme', 'description',
                                'conditionsAttribution', 'visibilite', 'politiqueHorsLigne']) <> '{}'::jsonb
     OR p_revision_attendue IS NULL THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_modification) e
              WHERE pg_catalog.jsonb_typeof(e.value) NOT IN ('string', 'null')) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_resource FROM public.library_resource r WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.archived_at IS NOT NULL THEN
    RAISE EXCEPTION 'BibliothequeRetiree' USING ERRCODE = '22023';
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureEnConflit', 'revision', v_resource.revision);
  END IF;

  v_titre := CASE WHEN p_modification ? 'titre'
                  THEN pg_catalog.btrim(coalesce(p_modification ->> 'titre', ''))
                  ELSE v_resource.title END;
  IF pg_catalog.length(v_titre) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  v_court := CASE WHEN p_modification ? 'titreCourt'
                  THEN coalesce(nullif(pg_catalog.btrim(coalesce(p_modification ->> 'titreCourt', '')), ''),
                                pg_catalog.left(v_titre, 60))
                  ELSE v_resource.short_title END;
  IF pg_catalog.length(v_court) > 60 THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;
  IF (p_modification ? 'visibilite' AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_enum e
        JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public' AND t.typname = 'library_access_policy'
          AND e.enumlabel = p_modification ->> 'visibilite'))
     OR (p_modification ? 'politiqueHorsLigne' AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_enum e
        JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public' AND t.typname = 'library_offline_policy'
          AND e.enumlabel = p_modification ->> 'politiqueHorsLigne')) THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END IF;

  BEGIN
    UPDATE public.library_resource r SET
      title = v_titre,
      short_title = v_court,
      edition = CASE WHEN p_modification ? 'edition'
                     THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'edition', '')), '')
                     ELSE r.edition END,
      organisme = CASE WHEN p_modification ? 'organisme'
                       THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'organisme', '')), '')
                       ELSE r.organisme END,
      description = CASE WHEN p_modification ? 'description'
                         THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'description', '')), '')
                         ELSE r.description END,
      conditions_attribution = CASE WHEN p_modification ? 'conditionsAttribution'
                         THEN nullif(pg_catalog.btrim(coalesce(p_modification ->> 'conditionsAttribution', '')), '')
                         ELSE r.conditions_attribution END,
      access_policy = CASE WHEN p_modification ? 'visibilite'
                           THEN (p_modification ->> 'visibilite')::public.library_access_policy
                           ELSE r.access_policy END,
      offline_policy = CASE WHEN p_modification ? 'politiqueHorsLigne'
                            THEN (p_modification ->> 'politiqueHorsLigne')::public.library_offline_policy
                            ELSE r.offline_policy END
     WHERE r.id = p_resource_id
    RETURNING r.revision INTO v_revision;
  EXCEPTION WHEN check_violation OR string_data_right_truncation THEN
    RAISE EXCEPTION 'BibliothequeSaisieInvalide' USING ERRCODE = '22023';
  END;

  PERFORM public.log_sensitive_access('library_resource_draft_updated', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('champs', (SELECT pg_catalog.array_agg(k.cle ORDER BY k.cle)
                                               FROM pg_catalog.jsonb_object_keys(p_modification) AS k(cle))));
  RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_revision);
END;
$function$;

-- La fiche : les trois champs et peutModifier (le reste du corps est inchange).
CREATE OR REPLACE FUNCTION public.library_get_detail(p_resource_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_versions jsonb;
  v_rights jsonb;
  v_history jsonb;
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin', false
  ) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT r.* INTO v_resource
    FROM public.library_resource r
   WHERE r.id = p_resource_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', v.id,
    'numeroVersion', v.numero_version,
    'statut', v.statut::text,
    'publieeLeUtc', v.publiee_le,
    'empreinte', v.empreinte,
    'droits', CASE WHEN d.resource_version_id IS NULL THEN NULL ELSE
      pg_catalog.jsonb_build_object(
        'sourceTitre', d.source_titre,
        'titulaire', d.titulaire,
        'preuveFournie', d.preuve_id IS NOT NULL,
        'preuveStatut', p.statut,
        'preuveMime', p.mime,
        'preuveTaille', p.taille,
        'preuveSha256', p.sha256,
        'usages', d.usages,
        'attribution', d.attribution,
        'expireLeUtc', d.expire_le,
        'approuve', d.approuve,
        'revuLeUtc', d.revu_le
      ) END
  ) ORDER BY v.numero_version DESC), '[]'::jsonb),
  coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'versionId', d.resource_version_id,
    'sourceTitre', d.source_titre,
    'titulaire', d.titulaire,
    'preuveFournie', d.preuve_id IS NOT NULL,
    'preuveStatut', p.statut,
    'preuveMime', p.mime,
    'preuveTaille', p.taille,
    'preuveSha256', p.sha256,
    'usages', d.usages,
    'attribution', d.attribution,
    'expireLeUtc', d.expire_le,
    'approuve', d.approuve,
    'revuLeUtc', d.revu_le
  ) ORDER BY v.numero_version DESC) FILTER (WHERE d.resource_version_id IS NOT NULL), '[]'::jsonb)
  INTO v_versions, v_rights
  FROM public.resource_version v
  LEFT JOIN public.library_version_rights d ON d.resource_version_id = v.id
  LEFT JOIN private.library_rights_proofs p
    ON p.id = d.preuve_id AND p.resource_version_id = v.id
  WHERE v.resource_id = p_resource_id;

  SELECT coalesce(pg_catalog.jsonb_agg(x.entree ORDER BY x.created_at DESC), '[]'::jsonb)
    INTO v_history
    FROM (
      SELECT pg_catalog.jsonb_build_object(
        'action', a.action,
        'creeLeUtc', a.created_at
      ) AS entree, a.created_at
        FROM public.audit_logs a
       WHERE a.table_name = 'library_resource'
         AND a.row_id = p_resource_id::text
         AND a.action IN (
           'library_resource_draft_created', 'library_resource_draft_updated',
           'library_rights_review', 'library_version_published',
           'library_resource_withdrawn', 'library_groups_assigned'
         )
       ORDER BY a.created_at DESC, a.id DESC
       LIMIT 100
    ) x;

  PERFORM public.log_sensitive_access(
    'library_resource_detail_read', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('resource_id', p_resource_id)
  );

  RETURN pg_catalog.jsonb_build_object(
    'support', pg_catalog.jsonb_build_object(
      'id', v_resource.id,
      'titre', v_resource.title,
      'titreCourt', v_resource.short_title,
      'type', v_resource.resource_type::text,
      'edition', v_resource.edition,
      'langue', v_resource.language,
      'categorie', v_resource.category,
      'niveaux', v_resource.level_scope,
      'politiqueAcces', v_resource.access_policy::text,
      'politiqueHorsLigne', v_resource.offline_policy::text,
      'capacitesContenu', v_resource.capabilities,
      'retire', v_resource.archived_at IS NOT NULL,
      'retireLeUtc', v_resource.archived_at,
      'versionCouranteId', v_resource.current_version_id,
      'modifieLeUtc', v_resource.updated_at,
      'organisme', v_resource.organisme,
      'description', v_resource.description,
      'conditionsAttribution', v_resource.conditions_attribution
    ),
    'revision', v_resource.revision,
    'versions', v_versions,
    'droits', v_rights,
    'historique', v_history,
    'capacites', pg_catalog.jsonb_build_object(
      'peutModifier', v_resource.archived_at IS NULL,
      'peutPublier', v_resource.archived_at IS NULL,
      'peutAttribuer', v_resource.archived_at IS NULL AND v_resource.current_version_id IS NOT NULL,
      'peutRetirer', v_resource.archived_at IS NULL
    )
  );
END;
$function$;

ALTER FUNCTION public.library_mettre_a_jour(uuid, jsonb, integer) OWNER TO postgres;
ALTER FUNCTION public.library_get_detail(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.library_mettre_a_jour(uuid, jsonb, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_mettre_a_jour(uuid, jsonb, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.library_get_detail(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_get_detail(uuid) TO authenticated;

-- @@F86_DEBUT_BIBLIOTHEQUE_MAJ@@
COMMENT ON FUNCTION public.library_mettre_a_jour(uuid, jsonb, integer) IS
  'F86: signature=public.library_mettre_a_jour(uuid,jsonb,integer); md5_functiondef=06b72c348d1af5f36d77cb311137914a; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin.mettreAJour. Garde: direction active.';
COMMENT ON FUNCTION public.library_get_detail(uuid) IS
  'F86: signature=public.library_get_detail(uuid); md5_functiondef=f3f63af2e5b8d72469869cfb4ea3aae1; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortBibliothequeAdmin. Garde: direction active.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.library_mettre_a_jour(uuid,jsonb,integer)'::regprocedure, '06b72c348d1af5f36d77cb311137914a'),
      ('public.library_get_detail(uuid)'::regprocedure, 'f3f63af2e5b8d72469869cfb4ea3aae1')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'RACCORDEMENT-1016 C : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_BIBLIOTHEQUE_MAJ@@

COMMIT;
