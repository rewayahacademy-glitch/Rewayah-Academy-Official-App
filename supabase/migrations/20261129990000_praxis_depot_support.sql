-- PX-BD-SUPPORT, etage 2 (pilote, arbitrage option C du 17/11/2026 : un texte Markdown FERME, lu par un lecteur dans l'application) :
-- le SERVEUR du depot d'un support que Praxis a redige avec la direction dans le chat.
--
-- CE QUE CE FICHIER FAIT
--   1. le format d'artefact `texte` (le type `format_artefact` n'avait que pdf, epub, audio, image) ;
--   2. `demander_upload_bibliotheque` accepte `text/markdown` (100 000 octets au plus, un SUPPORT seulement, jamais une preuve de droits) ;
--      `confirmer_upload_bibliotheque` range ce fichier sous le format `texte` ; les deux gardent leur signature, leur proprietaire, leurs droits
--      et leur porte (direction active) ; le reste de leur corps est CELUI de 20261012150000 et 20261012184000, mot pour mot ;
--   3. DEUX actes internes du catalogue de Praxis, de niveau A, ouverts seulement par la cle de CHAT et sous l'identite de la direction
--      emettrice, via le pont de PX-BD-0 :
--        * depot_support_preparer  : cree le BROUILLON (library_creer_brouillon, type structured_text, visibilite reservee a la direction) et
--                                    l'intention de depot (demander_upload_bibliotheque), en UNE transaction ;
--        * depot_support_confirmer : confirme le depot (confirmer_upload_bibliotheque) ; la base reverifie la signature HMAC de l'Edge, que
--                                    seule la fonction Edge sait fabriquer : le modele ne peut donc pas confirmer un depot qu'il n'a pas fait.
--      Ils ne sont appeles que par l'outil `support_deposer` de la fonction Edge `praxis-mcp`, qui analyse le Markdown, ecrit l'objet dans le
--      coffre R2 puis confirme. Aucun acte « publier » : le support reste un BROUILLON reserve a la direction, que la direction publie
--      elle-meme dans la Bibliotheque (decision du pilote, deviations validees de #630).
--
-- PREFLIGHT : les deux fonctions de depot, la fonction de creation d'un brouillon, le pont (avec les quatre branches de PX-BD-BIBLIOTHEQUE
-- et l'ancre ACTES-ANCRE) sont presents ; les deux actes ne sont pas deja au catalogue. FICHIER SANS EFFACEMENT : aucun des trois mots
-- d'effacement. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v_def text;
  v_ancre constant text := '    -- ACTES-ANCRE : une branche ELSIF par acte, ajoutee par la migration du lot qui cree l''acte';
BEGIN
  IF pg_catalog.to_regprocedure('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)') IS NULL
     OR pg_catalog.to_regclass('private.praxis_actes') IS NULL
     OR pg_catalog.to_regprocedure('public.library_creer_brouillon(jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text)') IS NULL
     OR pg_catalog.to_regtype('public.format_artefact') IS NULL THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : une dependance est absente (le pont de PX-BD-0, ou les fonctions de la Bibliotheque)';
  END IF;
  v_def := pg_catalog.pg_get_functiondef('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'private.praxis_acte_support_retirer') = 0 THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : le pont n''a pas encore les branches de PX-BD-BIBLIOTHEQUE (20261129970000 doit etre installee avant)';
  END IF;
  IF pg_catalog.strpos(v_def, 'depot_support_preparer') = 0
     AND (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, ''))) / pg_catalog.length(v_ancre) <> 1 THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : l''ancre du pont est absente ou en double';
  END IF;
  IF EXISTS (SELECT 1 FROM private.praxis_actes a WHERE a.acte LIKE 'depot\_support\_%' ESCAPE '\') THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : deja installe';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le format `texte`. Une valeur d'enumeration ajoutee ne s'emploie qu'apres la fin de cette transaction : aucune ligne ne l'emploie ici,
--    les corps de fonctions ci-dessous ne la lisent qu'a l'appel.
-- ---------------------------------------------------------------------------
ALTER TYPE public.format_artefact ADD VALUE IF NOT EXISTS 'texte';

-- ---------------------------------------------------------------------------
-- 2. Les deux fonctions de depot : le type `text/markdown`, rien d'autre ne change.
-- ---------------------------------------------------------------------------
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
    -- PX-BD-SUPPORT : un texte Markdown ferme, 100 000 octets au plus (le meme plafond que l'analyseur), pour un support seulement.
    WHEN v_mime = 'text/markdown' AND p_finalite = 'support' THEN 100000
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

CREATE OR REPLACE FUNCTION public.confirmer_upload_bibliotheque(
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
      WHEN v_intention.mime_annonce = 'text/markdown' THEN 'texte'::public.format_artefact
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

ALTER FUNCTION public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text) OWNER TO postgres;
ALTER FUNCTION public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text) TO authenticated;
REVOKE ALL ON FUNCTION public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Le catalogue : deux actes internes de niveau A.
-- ---------------------------------------------------------------------------
INSERT INTO private.praxis_actes (acte, niveau, description, lot_max) VALUES
  ('depot_support_preparer', 'A',
   'INTERNE : ne l appelle jamais toi-meme, utilise l outil support_deposer. Cree le brouillon d un support texte et son intention de depot.', 1),
  ('depot_support_confirmer', 'A',
   'INTERNE : ne l appelle jamais toi-meme, utilise l outil support_deposer. Confirme un depot que la fonction Edge a ecrit et signe.', 1);

-- ---------------------------------------------------------------------------
-- 4. Les adaptateurs. Cles connues seulement, valeurs bornees, resume a sec, fonctions de la direction appelees telles quelles.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.praxis_acte_depot_support_preparer(p jsonb, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_titre text := pg_catalog.btrim(coalesce(p ->> 'titre', ''));
  v_langue text := p ->> 'langue';
  v_rayon text := coalesce(p ->> 'rayon', 'cours');
  v_description text := nullif(pg_catalog.btrim(coalesce(p ->> 'description', '')), '');
  v_octets bigint;
  v_sha text := p ->> 'sha256';
  v_saisie jsonb;
  v_cree jsonb;
  v_intention jsonb;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k
              WHERE k <> ALL (ARRAY['titre', 'langue', 'rayon', 'description', 'octets', 'sha256']))
     OR (p ? 'titre' AND pg_catalog.jsonb_typeof(p -> 'titre') <> 'string')
     OR pg_catalog.length(v_titre) NOT BETWEEN 1 AND 200
     OR (p ? 'langue' AND pg_catalog.jsonb_typeof(p -> 'langue') <> 'string')
     OR v_langue IS NULL OR v_langue !~ '^[a-z]{2,3}$'
     OR (p ? 'rayon' AND (pg_catalog.jsonb_typeof(p -> 'rayon') <> 'string' OR v_rayon NOT IN ('cours', 'plus_loin')))
     OR (p ? 'description' AND pg_catalog.jsonb_typeof(p -> 'description') NOT IN ('string', 'null'))
     OR coalesce(pg_catalog.length(v_description), 0) > 1000
     OR pg_catalog.jsonb_typeof(p -> 'octets') IS DISTINCT FROM 'number'
     OR (p ->> 'octets') !~ '^[0-9]{1,6}$'
     OR v_sha IS NULL OR pg_catalog.jsonb_typeof(p -> 'sha256') <> 'string' OR v_sha !~ '^[0-9a-f]{64}$' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_octets := (p ->> 'octets')::bigint;
  IF v_octets NOT BETWEEN 1 AND 100000 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', 'Creer le brouillon du support « ' || v_titre || ' » (' || v_octets::text || ' octets)');
  END IF;
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  v_saisie := pg_catalog.jsonb_build_object('titre', v_titre, 'type', 'structured_text', 'langue', v_langue,
                                            'categorie', '', 'rayon', v_rayon)
              || CASE WHEN v_description IS NULL THEN '{}'::jsonb
                      ELSE pg_catalog.jsonb_build_object('description', v_description) END;
  v_cree := public.library_creer_brouillon(v_saisie);
  v_intention := public.demander_upload_bibliotheque((v_cree ->> 'id')::uuid, 'support', 'document.md', 'text/markdown', v_octets, v_sha);
  RETURN pg_catalog.jsonb_build_object(
    'id', v_cree ->> 'id', 'version_id', v_cree ->> 'version_id', 'revision', (v_cree ->> 'revision')::integer,
    'upload_id', v_intention ->> 'id', 'cle_finale', v_intention ->> 'cle_finale',
    'expire_le', v_intention ->> 'expire_le', 'etat', 'brouillon');
END;
$f$;

CREATE FUNCTION private.praxis_acte_depot_support_confirmer(p jsonb, p_a_sec boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_upload text := p ->> 'upload_id';
  v_sha text := p ->> 'sha256';
  v_signature text := p ->> 'signature';
  v_res jsonb;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k
              WHERE k <> ALL (ARRAY['upload_id', 'sha256', 'octets', 'signature']))
     OR v_upload IS NULL OR pg_catalog.jsonb_typeof(p -> 'upload_id') <> 'string'
     OR v_upload !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     OR v_sha IS NULL OR pg_catalog.jsonb_typeof(p -> 'sha256') <> 'string' OR v_sha !~ '^[0-9a-f]{64}$'
     OR v_signature IS NULL OR pg_catalog.jsonb_typeof(p -> 'signature') <> 'string' OR v_signature !~ '^[0-9a-f]{64}$'
     OR pg_catalog.jsonb_typeof(p -> 'octets') IS DISTINCT FROM 'number'
     OR (p ->> 'octets') !~ '^[0-9]{1,6}$' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', 'Confirmer le depot d un support texte');
  END IF;
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  v_res := public.confirmer_upload_bibliotheque(v_upload::uuid, 'text/markdown', (p ->> 'octets')::bigint, v_sha, v_signature);
  RETURN pg_catalog.jsonb_build_object('etat', 'brouillon', 'version_id', v_res ->> 'resource_version_id');
END;
$f$;

-- ---------------------------------------------------------------------------
-- 5. Le pont : deux branches a l'ancre.
-- ---------------------------------------------------------------------------
DO $pont$
DECLARE
  v_f constant regprocedure := 'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '    -- ACTES-ANCRE : une branche ELSIF par acte, ajoutee par la migration du lot qui cree l''acte';
BEGIN
  IF pg_catalog.strpos(v_def, 'depot_support_preparer') = 0 THEN
    EXECUTE pg_catalog.replace(v_def, v_ancre,
      '    ELSIF p_acte = ''depot_support_preparer'' THEN v_res := private.praxis_acte_depot_support_preparer(p_params, p_a_sec);' || pg_catalog.chr(10) ||
      '    ELSIF p_acte = ''depot_support_confirmer'' THEN v_res := private.praxis_acte_depot_support_confirmer(p_params, p_a_sec);' || pg_catalog.chr(10) || v_ancre);
  END IF;
END;
$pont$;

-- ---------------------------------------------------------------------------
-- 6. Proprietaire, droits, empreintes.
-- ---------------------------------------------------------------------------
ALTER FUNCTION private.praxis_acte_depot_support_preparer(jsonb, boolean) OWNER TO postgres;
ALTER FUNCTION private.praxis_acte_depot_support_confirmer(jsonb, boolean) OWNER TO postgres;

DO $droits$
DECLARE
  v_f text;
  v_role text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['private.praxis_acte_depot_support_preparer(jsonb, boolean)',
                             'private.praxis_acte_depot_support_confirmer(jsonb, boolean)'] LOOP
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_f);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_f, v_role);
      END IF;
    END LOOP;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.praxis_acte_depot_support_preparer(jsonb, boolean) IS
  'PX-BD-SUPPORT: guard_type=INTERNAL_ACTE; acte A interne du chat : cree le brouillon d un support texte et son intention de depot (library_creer_brouillon, demander_upload_bibliotheque) ; appele par le pont seul. date=2026-11-17.';
COMMENT ON FUNCTION private.praxis_acte_depot_support_confirmer(jsonb, boolean) IS
  'PX-BD-SUPPORT: guard_type=INTERNAL_ACTE; acte A interne du chat : confirme le depot par confirmer_upload_bibliotheque (signature HMAC de l Edge reverifiee) ; appele par le pont seul. date=2026-11-17.';

DO $postflight$
DECLARE
  v_f regprocedure;
BEGIN
  IF (SELECT pg_catalog.count(*) FROM private.praxis_actes a WHERE a.acte LIKE 'depot\_support\_%' ESCAPE '\') <> 2 THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : le catalogue doit contenir exactement deux actes depot_support_*';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_enum e JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
                  WHERE t.typname = 'format_artefact' AND e.enumlabel = 'texte') THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : le format texte est absent';
  END IF;
  FOREACH v_f IN ARRAY ARRAY['private.praxis_acte_depot_support_preparer(jsonb, boolean)'::regprocedure,
                             'private.praxis_acte_depot_support_confirmer(jsonb, boolean)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_f AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f, 'EXECUTE') OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-BD-SUPPORT : DEFINER, proprietaire ou ACL invalide pour %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure),
                       'private.praxis_acte_depot_support_confirmer') = 0 THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : le pont n''a pas recu les deux branches';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text)'::regprocedure), 'text/markdown') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.confirmer_upload_bibliotheque(uuid,text,bigint,text,text)'::regprocedure), 'text/markdown') = 0 THEN
    RAISE EXCEPTION 'PX-BD-SUPPORT : les fonctions de depot ne connaissent pas text/markdown';
  END IF;
END
$postflight$;
