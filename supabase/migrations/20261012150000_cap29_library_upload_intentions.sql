BEGIN;

CREATE TABLE private.library_upload_intentions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  resource_version_id uuid NOT NULL REFERENCES public.resource_version(id) ON DELETE RESTRICT,
  requested_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  finalite text NOT NULL CHECK (finalite IN ('support', 'preuve')),
  nom_fichier text NOT NULL CHECK (pg_catalog.length(nom_fichier) BETWEEN 1 AND 200),
  mime_annonce text NOT NULL,
  taille_annonce bigint NOT NULL CHECK (taille_annonce > 0),
  sha256_annonce text NOT NULL CHECK (sha256_annonce ~ '^[0-9a-f]{64}$'),
  cle_temporaire text NOT NULL UNIQUE,
  cle_finale text NOT NULL UNIQUE,
  cible_id uuid NOT NULL UNIQUE,
  expire_le timestamptz NOT NULL,
  etat text NOT NULL DEFAULT 'attente'
    CHECK (etat IN ('attente', 'confirmee', 'annulee')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  confirmee_le timestamptz,
  UNIQUE (id, resource_version_id)
);
ALTER TABLE private.library_upload_intentions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.library_upload_intentions
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE OR REPLACE FUNCTION public.demander_upload_bibliotheque(
  p_resource_id uuid,
  p_finalite text,
  p_nom_fichier text,
  p_mime text,
  p_taille bigint,
  p_sha256 text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_version public.resource_version%ROWTYPE;
  v_intention_id uuid := pg_catalog.gen_random_uuid();
  v_cible_id uuid := pg_catalog.gen_random_uuid();
  v_expire_le timestamptz := pg_catalog.clock_timestamp() + interval '15 minutes';
  v_nom text := pg_catalog.btrim(p_nom_fichier);
  v_mime text := pg_catalog.lower(pg_catalog.btrim(p_mime));
  v_limite bigint;
  v_cle_finale text;
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL OR p_finalite IS NULL
     OR p_finalite NOT IN ('support', 'preuve') OR p_nom_fichier IS NULL
     OR pg_catalog.length(v_nom) NOT BETWEEN 1 AND 200
     OR pg_catalog.strpos(v_nom, '/') > 0
     OR pg_catalog.strpos(v_nom, pg_catalog.chr(92)) > 0
     OR v_nom ~ '[[:cntrl:]]'
     OR (p_finalite = 'support' AND v_nom !~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')
     OR p_mime IS NULL OR v_mime = ''
     OR p_sha256 IS NULL OR p_sha256 !~ '^[0-9a-f]{64}$'
     OR p_taille IS NULL OR p_taille <= 0 THEN
    RAISE EXCEPTION 'BibliothequeUploadParametresInvalides' USING ERRCODE = '22023';
  END IF;
  v_limite := CASE
    WHEN v_mime IN ('image/png', 'image/jpeg', 'image/webp') THEN 10 * 1024 * 1024
    WHEN v_mime = 'application/pdf' THEN 50 * 1024 * 1024
    WHEN v_mime IN ('audio/mpeg', 'audio/mp4', 'audio/ogg') THEN 100 * 1024 * 1024
    ELSE 0
  END;
  IF p_taille > v_limite THEN
    RAISE EXCEPTION 'BibliothequeUploadTypeOuTailleInvalide' USING ERRCODE = '22023';
  END IF;
  IF p_finalite = 'preuve' AND v_mime NOT IN ('image/png', 'image/jpeg', 'image/webp', 'application/pdf') THEN
    RAISE EXCEPTION 'BibliothequeUploadTypeOuTailleInvalide' USING ERRCODE = '22023';
  END IF;

  SELECT v.* INTO v_version
    FROM public.resource_version v
    JOIN public.library_resource r ON r.id = v.resource_id
   WHERE v.resource_id = p_resource_id
     AND v.statut = 'brouillon' AND r.archived_at IS NULL
   ORDER BY v.numero_version DESC
   LIMIT 1 FOR UPDATE OF v;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeBrouillonIntrouvable' USING ERRCODE = '42501';
  END IF;
  IF p_finalite = 'support' AND v_version.download_asset_id IS NOT NULL THEN
    RAISE EXCEPTION 'BibliothequeVersionDejaUnFichier' USING ERRCODE = '23514';
  END IF;

  v_cle_finale := CASE WHEN p_finalite = 'support'
    THEN 'supports/' || v_cible_id::text || '/' || v_version.numero_version::text || '/' || v_nom
    ELSE 'private/libraryproof/' || v_cible_id::text END;
  INSERT INTO private.library_upload_intentions (
    id, resource_version_id, requested_by, finalite, nom_fichier, mime_annonce,
    taille_annonce, sha256_annonce, cle_temporaire, cle_finale, cible_id, expire_le
  ) VALUES (
    v_intention_id, v_version.id, auth.uid(), p_finalite, v_nom, v_mime,
    p_taille, p_sha256, 'private/libraryupload/' || v_intention_id::text,
    v_cle_finale, v_cible_id, v_expire_le
  );
  RETURN pg_catalog.jsonb_build_object(
    'id', v_intention_id,
    'cle_temporaire', 'private/libraryupload/' || v_intention_id::text,
    'cle_finale', v_cle_finale, 'cible_id', v_cible_id,
    'resource_version_id', v_version.id, 'numero_version', v_version.numero_version,
    'finalite', p_finalite, 'mime', v_mime, 'taille', p_taille,
    'expire_le', v_expire_le
  );
END;
$function$;
COMMENT ON FUNCTION public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text)
  IS 'F86 A_CALCULER; crée une intention R2 limitée à un brouillon administrable.';
REVOKE ALL ON FUNCTION public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.lire_upload_bibliotheque(p_intention_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_intention private.library_upload_intentions%ROWTYPE;
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_intention FROM private.library_upload_intentions
   WHERE id = p_intention_id AND requested_by = auth.uid();
  IF NOT FOUND OR v_intention.etat <> 'attente'
     OR v_intention.expire_le <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'BibliothequeUploadIntentionIndisponible' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'id', v_intention.id, 'resource_version_id', v_intention.resource_version_id,
    'finalite', v_intention.finalite, 'mime', v_intention.mime_annonce,
    'taille', v_intention.taille_annonce, 'sha256', v_intention.sha256_annonce,
    'cle_temporaire', v_intention.cle_temporaire, 'cle_finale', v_intention.cle_finale,
    'cible_id', v_intention.cible_id, 'expire_le', v_intention.expire_le
  );
END;
$function$;
COMMENT ON FUNCTION public.lire_upload_bibliotheque(uuid)
  IS 'F86 A_CALCULER; lit les métadonnées serveur de sa propre intention en attente.';
REVOKE ALL ON FUNCTION public.lire_upload_bibliotheque(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_upload_bibliotheque(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.confirmer_upload_bibliotheque(
  p_intention_id uuid,
  p_mime_reel text,
  p_taille_reelle bigint,
  p_sha256_reel text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_intention private.library_upload_intentions%ROWTYPE;
  v_format public.format_artefact;
  v_empreinte text := pg_catalog.lower(pg_catalog.btrim(p_sha256_reel));
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_intention FROM private.library_upload_intentions
   WHERE id = p_intention_id AND requested_by = auth.uid() FOR UPDATE;
  IF NOT FOUND OR v_intention.etat <> 'attente'
     OR v_intention.expire_le <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'BibliothequeUploadIntentionIndisponible' USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.lower(pg_catalog.btrim(p_mime_reel)) <> v_intention.mime_annonce
     OR p_taille_reelle <> v_intention.taille_annonce
     OR v_empreinte <> v_intention.sha256_annonce
     OR v_empreinte !~ '^[0-9a-f]{64}$' THEN
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
COMMENT ON FUNCTION public.confirmer_upload_bibliotheque(uuid,text,bigint,text)
  IS 'F86 A_CALCULER; rattache uniquement les métadonnées confirmées par l’Edge à un brouillon.';
REVOKE ALL ON FUNCTION public.confirmer_upload_bibliotheque(uuid,text,bigint,text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.confirmer_upload_bibliotheque(uuid,text,bigint,text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.annuler_upload_bibliotheque(p_intention_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF COALESCE(public.app_account_valid() AND public.app_role() = 'admin', false) IS NOT TRUE THEN
    RAISE EXCEPTION 'BibliothequeUploadNonAutorise' USING ERRCODE = '42501';
  END IF;
  UPDATE private.library_upload_intentions SET etat = 'annulee'
   WHERE id = p_intention_id AND requested_by = auth.uid() AND etat = 'attente';
  RETURN FOUND;
END;
$function$;
COMMENT ON FUNCTION public.annuler_upload_bibliotheque(uuid)
  IS 'F86 A_CALCULER; annule une intention de depot en attente.';
REVOKE ALL ON FUNCTION public.annuler_upload_bibliotheque(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.annuler_upload_bibliotheque(uuid) TO authenticated;

COMMIT;
