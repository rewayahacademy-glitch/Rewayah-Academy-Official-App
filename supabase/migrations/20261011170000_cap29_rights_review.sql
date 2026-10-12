BEGIN;

CREATE FUNCTION public.admin_library_review_rights(
  p_resource_id uuid,
  p_resource_version_id uuid,
  p_saisie jsonb,
  p_revision_attendue integer
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_proof_id uuid;
  v_usages text[];
  v_approve boolean;
  v_proof_given boolean;
  v_expire timestamptz;
  v_new_revision integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL OR p_resource_version_id IS NULL
     OR p_revision_attendue IS NULL OR p_revision_attendue < 1
     OR p_saisie IS NULL OR pg_catalog.jsonb_typeof(p_saisie) <> 'object'
     OR (p_saisie - ARRAY[
       'sourceTitre','titulaire','preuveFournie','usages','attribution','expireLeUtc','approuver'
     ]) <> '{}'::jsonb
     OR pg_catalog.jsonb_typeof(p_saisie->'preuveFournie') IS DISTINCT FROM 'boolean'
     OR pg_catalog.jsonb_typeof(p_saisie->'approuver') IS DISTINCT FROM 'boolean'
     OR pg_catalog.jsonb_typeof(p_saisie->'usages') IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_typeof(p_saisie->'sourceTitre') IS DISTINCT FROM 'string'
     OR pg_catalog.jsonb_typeof(p_saisie->'titulaire') IS DISTINCT FROM 'string'
     OR pg_catalog.jsonb_typeof(p_saisie->'attribution') IS DISTINCT FROM 'string' THEN
    RAISE EXCEPTION 'BibliothequeSaisieDroitsInvalide' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_resource FROM public.library_resource r
   WHERE r.id = p_resource_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_resource.revision <> p_revision_attendue THEN
    RETURN pg_catalog.jsonb_build_object(
      'resultat', 'EcritureEnConflit', 'revision', v_resource.revision
    );
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.resource_version v
     WHERE v.id = p_resource_version_id AND v.resource_id = p_resource_id
  ) THEN
    RAISE EXCEPTION 'BibliothequeVersionIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT coalesce(pg_catalog.array_agg(DISTINCT CASE x.value
           WHEN 'horsLigne' THEN 'hors_ligne' ELSE x.value END), '{}'::text[])
    INTO v_usages
    FROM pg_catalog.jsonb_array_elements_text(p_saisie->'usages') AS x(value);
  IF pg_catalog.cardinality(v_usages) <> pg_catalog.jsonb_array_length(p_saisie->'usages')
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_usages) u(value)
                 WHERE u.value NOT IN ('application','classe','telechargement','hors_ligne')) THEN
    RAISE EXCEPTION 'BibliothequeUsagesInvalides' USING ERRCODE = '22023';
  END IF;
  v_proof_given := (p_saisie->>'preuveFournie')::boolean;
  v_approve := (p_saisie->>'approuver')::boolean;
  IF p_saisie->'expireLeUtc' IS NOT NULL AND p_saisie->'expireLeUtc' <> 'null'::jsonb THEN
    v_expire := (p_saisie->>'expireLeUtc')::timestamptz;
  END IF;
  IF v_approve AND (
       pg_catalog.btrim(p_saisie->>'sourceTitre') = ''
       OR pg_catalog.btrim(p_saisie->>'titulaire') = ''
       OR pg_catalog.btrim(p_saisie->>'attribution') = ''
       OR pg_catalog.cardinality(v_usages) = 0
       OR (v_expire IS NOT NULL AND v_expire <= pg_catalog.now())
     ) THEN
    RAISE EXCEPTION 'BibliothequeDroitsIncomplets' USING ERRCODE = '23514';
  END IF;

  IF v_proof_given THEN
    SELECT p.id INTO v_proof_id
      FROM private.library_rights_proofs p
     WHERE p.resource_id = p_resource_id
       AND p.resource_version_id = p_resource_version_id
       AND p.statut IN ('en_attente','confirmee')
     ORDER BY p.deposee_le DESC, p.id DESC LIMIT 1;
    IF v_proof_id IS NULL THEN
      RAISE EXCEPTION 'BibliothequePreuveIntrouvable' USING ERRCODE = 'P0002';
    END IF;
  END IF;

  INSERT INTO public.library_version_rights
    (resource_version_id, source_titre, titulaire, preuve_id, usages,
     attribution, expire_le, approuve, revu_par, revu_le)
  VALUES
    (p_resource_version_id, pg_catalog.btrim(p_saisie->>'sourceTitre'),
     pg_catalog.btrim(p_saisie->>'titulaire'), v_proof_id, v_usages,
     pg_catalog.btrim(p_saisie->>'attribution'), v_expire, v_approve,
     CASE WHEN v_approve THEN auth.uid() ELSE NULL END,
     CASE WHEN v_approve THEN pg_catalog.clock_timestamp() ELSE NULL END)
  ON CONFLICT (resource_version_id) DO UPDATE
    SET source_titre = EXCLUDED.source_titre,
        titulaire = EXCLUDED.titulaire,
        preuve_id = EXCLUDED.preuve_id,
        usages = EXCLUDED.usages,
        attribution = EXCLUDED.attribution,
        expire_le = EXCLUDED.expire_le,
        approuve = EXCLUDED.approuve,
        revu_par = EXCLUDED.revu_par,
        revu_le = EXCLUDED.revu_le;

  IF v_approve AND v_proof_id IS NOT NULL THEN
    UPDATE private.library_rights_proofs SET statut = 'confirmee' WHERE id = v_proof_id;
  END IF;
  UPDATE public.library_resource r SET title = r.title WHERE r.id = p_resource_id;
  v_new_revision := v_resource.revision + 1;
  PERFORM public.log_sensitive_access(
    'library_rights_review', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object(
      'resource_id', p_resource_id, 'resource_version_id', p_resource_version_id,
      'revision', v_new_revision, 'approved', v_approve,
      'proof_attached', v_proof_given
    )
  );
  RETURN pg_catalog.jsonb_build_object('resultat', 'EcritureFaite', 'revision', v_new_revision);
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_library_review_rights(uuid, uuid, jsonb, integer)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.admin_library_review_rights(uuid, uuid, jsonb, integer)
  TO authenticated;
ALTER FUNCTION public.admin_library_review_rights(uuid, uuid, jsonb, integer) OWNER TO postgres;
COMMENT ON FUNCTION public.admin_library_review_rights(uuid, uuid, jsonb, integer) IS
  'F86 candidate allowlist: signature=public.admin_library_review_rights(uuid,uuid,jsonb,integer); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: admin actif actualise une seule version avec controle de revision, preuve privee et audit; non-admin refuse; revision depassee ne modifie rien.';

DO $postflight$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.admin_library_review_rights(uuid,uuid,jsonb,integer)'::regprocedure
       AND p.prosecdef
       AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=""']
       AND p.prosrc ILIKE '%app_account_valid()%'
       AND p.prosrc ILIKE '%app_role() = ''admin''%'
       AND p.prosrc ILIKE '%FOR UPDATE%'
       AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE
         '%F86 candidate allowlist:%signature=public.admin_library_review_rights(uuid,uuid,jsonb,integer); md5_functiondef=A_CALCULER;%'
       AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
       AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CAP29: garde, verrou, F86 ou ACL de revue des droits invalide';
  END IF;
END;
$postflight$;

COMMIT;
