BEGIN;

CREATE TABLE private.library_upload_confirmation_secrets (
  singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
  secret text NOT NULL CHECK (pg_catalog.length(secret) >= 32),
  changed_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
ALTER TABLE private.library_upload_confirmation_secrets ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.library_upload_confirmation_secrets FORCE ROW LEVEL SECURITY;
ALTER TABLE private.library_upload_confirmation_secrets OWNER TO postgres;
REVOKE ALL ON TABLE private.library_upload_confirmation_secrets
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE private.library_upload_confirmation_secrets IS
  'Provision the same random secret as Edge secret LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY through a privileged operator; never seed a real secret in a migration.';

DROP FUNCTION public.confirmer_upload_bibliotheque(uuid, text, bigint, text);

CREATE FUNCTION public.confirmer_upload_bibliotheque(
  p_intention_id uuid,
  p_mime_reel text,
  p_taille_reelle bigint,
  p_sha256_reel text,
  p_confirmation_signature text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_intention private.library_upload_intentions%ROWTYPE;
  v_format public.format_artefact;
  v_empreinte text := pg_catalog.lower(pg_catalog.btrim(p_sha256_reel));
  v_secret text;
  v_signature text := pg_catalog.lower(pg_catalog.btrim(p_confirmation_signature));
  v_attendue text;
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;

  SELECT secret INTO v_secret
    FROM private.library_upload_confirmation_secrets
   WHERE singleton
   FOR SHARE;
  IF v_secret IS NULL OR pg_catalog.length(v_secret) < 32
     OR p_confirmation_signature IS NULL
     OR v_signature !~ '^[0-9a-f]{64}$'
     OR p_taille_reelle IS NULL
     OR p_taille_reelle <= 0
     OR p_sha256_reel IS NULL
     OR v_empreinte !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'BibliothequeUploadConfirmationNonAutorisee' USING ERRCODE = '42501';
  END IF;

  v_attendue := pg_catalog.encode(
    extensions.hmac(
      pg_catalog.convert_to(
        p_intention_id::text || E'\n' || v_empreinte || E'\n' || p_taille_reelle::text,
        'UTF8'
      ),
      pg_catalog.convert_to(v_secret, 'UTF8'),
      'sha256'
    ),
    'hex'
  );
  IF v_signature IS DISTINCT FROM v_attendue THEN
    RAISE EXCEPTION 'BibliothequeUploadConfirmationNonAutorisee' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_intention FROM private.library_upload_intentions
   WHERE id = p_intention_id AND requested_by = auth.uid() FOR UPDATE;
  IF NOT FOUND OR v_intention.etat <> 'attente'
     OR v_intention.expire_le <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'BibliothequeUploadIntentionIndisponible' USING ERRCODE = '42501';
  END IF;
  IF p_mime_reel IS NULL
     OR pg_catalog.lower(pg_catalog.btrim(p_mime_reel)) <> v_intention.mime_annonce
     OR p_taille_reelle <> v_intention.taille_annonce
     OR v_empreinte <> v_intention.sha256_annonce THEN
    RAISE EXCEPTION 'BibliothequeUploadContenuInvalide' USING ERRCODE = '22023';
  END IF;

  IF v_intention.finalite = 'support' THEN
    v_format := CASE
      WHEN v_intention.mime_annonce = 'application/pdf' THEN 'pdf'::public.format_artefact
      WHEN v_intention.mime_annonce LIKE 'image/%' THEN 'image'::public.format_artefact
      ELSE 'audio'::public.format_artefact
    END;
    INSERT INTO public.download_asset (
      id, resource_version_id, format, cle_stockage, taille_octets, empreinte, origine
    ) VALUES (
      v_intention.cible_id, v_intention.resource_version_id, v_format,
      v_intention.cle_finale, v_intention.taille_annonce, v_empreinte,
      'importe_tel_quel'::public.origine_artefact
    );
    UPDATE public.resource_version
       SET download_asset_id = v_intention.cible_id, empreinte = v_empreinte
     WHERE id = v_intention.resource_version_id AND statut = 'brouillon';
    IF NOT FOUND THEN
      RAISE EXCEPTION 'BibliothequeBrouillonIntrouvable' USING ERRCODE = '42501';
    END IF;
  ELSE
    INSERT INTO private.library_rights_proofs (
      id, resource_id, resource_version_id, cle_stockage, sha256, mime, taille,
      deposee_par, statut
    ) SELECT v_intention.cible_id, v.resource_id, v.id, v_intention.cle_finale,
             v_empreinte, v_intention.mime_annonce, v_intention.taille_annonce,
             auth.uid(), 'confirmee'
      FROM public.resource_version v
     WHERE v.id = v_intention.resource_version_id AND v.statut = 'brouillon';
    IF NOT FOUND THEN
      RAISE EXCEPTION 'BibliothequeBrouillonIntrouvable' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.library_version_rights(resource_version_id)
      VALUES (v_intention.resource_version_id) ON CONFLICT DO NOTHING;
    UPDATE public.library_version_rights
       SET preuve_id = v_intention.cible_id, approuve = false, revu_par = NULL, revu_le = NULL
     WHERE resource_version_id = v_intention.resource_version_id;
  END IF;

  UPDATE private.library_upload_intentions
     SET etat = 'confirmee', confirmee_le = pg_catalog.clock_timestamp()
   WHERE id = v_intention.id;
  RETURN pg_catalog.jsonb_build_object('etat', 'pret', 'resource_version_id', v_intention.resource_version_id);
END;
$function$;
ALTER FUNCTION public.confirmer_upload_bibliotheque(uuid, text, bigint, text, text)
  OWNER TO postgres;
COMMENT ON FUNCTION public.confirmer_upload_bibliotheque(uuid, text, bigint, text, text)
  IS 'F86 A_CALCULER; verifies the Edge HMAC over intent id, SHA-256 and byte size before attaching server-confirmed metadata.';
REVOKE ALL ON FUNCTION public.confirmer_upload_bibliotheque(uuid, text, bigint, text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.confirmer_upload_bibliotheque(uuid, text, bigint, text, text)
  TO authenticated;

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure(
    'public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text)'
  );
BEGIN
  IF v_oid IS NULL
     OR pg_catalog.to_regprocedure(
       'public.confirmer_upload_bibliotheque(uuid,text,bigint,text)'
     ) IS NOT NULL
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = v_oid
          AND p.prosecdef
          AND p.proowner = 'postgres'::regrole
          AND p.proconfig @> ARRAY['search_path=""']
     )
     OR has_function_privilege(
       'anon', 'public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text)', 'EXECUTE'
     )
     OR has_function_privilege(
       'service_role', 'public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text)', 'EXECUTE'
     )
     OR NOT has_function_privilege(
       'authenticated', 'public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text)', 'EXECUTE'
     )
     OR has_table_privilege('anon', 'private.library_upload_confirmation_secrets', 'SELECT')
     OR has_table_privilege('authenticated', 'private.library_upload_confirmation_secrets', 'SELECT')
     OR has_table_privilege('service_role', 'private.library_upload_confirmation_secrets', 'SELECT') THEN
    RAISE EXCEPTION 'CAP29 upload HMAC: unsafe function or secret ACL';
  END IF;
END;
$postflight$;

COMMIT;
