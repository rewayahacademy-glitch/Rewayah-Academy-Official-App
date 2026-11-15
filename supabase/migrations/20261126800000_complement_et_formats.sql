-- COMPLEMENT-ET-FORMATS (directeur, 14/11/2026).
--
-- A. « cette page [Demander un complement] manque d'elements qu'on peut
--    demander a completer ». En salle 1 (Salle d'examen), la direction ne
--    pouvait redemander que les cartes du questionnaire et le cadre religieux
--    (private.candidature_complement_codes, CAND-L2A2) ; or le candidat y
--    fournit aussi le contrat, l'avis « Ce que vous devez savoir », le code de
--    conduite, la piece d'identite, la photo et l'accord de publication
--    (SALLE-1-TOUT-ICI). Ces six codes s'ajoutent a la liste de la salle 1,
--    apres le cadre, dans l'ordre du parcours du candidat. La salle 2 ne
--    change pas.
--
--    Pour que le portail du candidat sache si la piece redemandee a deja ete
--    deposee de nouveau, l'etat du candidat (private.candidature_etat_candidat,
--    lu par etat_dossier().candidature) rend aussi complementDemandeLe : la
--    date de la demande en cours, nulle sans demande.
--
-- B. « certains dossiers ne s'affichent pas […] je veux savoir les formats
--    admis et comment empecher les gens de deposer sauf au format demande ».
--    La visionneuse de la direction n'affiche que JPEG, PNG et WebP ; le seau
--    kyc acceptait aussi HEIC et PDF (20261108400000), d'ou 1 HEIC et 3 PDF
--    illisibles dans le dossier (production, 14/11/2026). Les seaux sont
--    ramenes a la liste que la direction sait afficher, la meme que celle de
--    l'application (lib/core/fichiers/formats_admis.dart) :
--      kyc                 image/jpeg, image/png              8 Mio au plus
--      photos_enseignants  image/jpeg, image/png, image/webp  4 Mio au plus
--    Les fichiers deja deposes ne sont ni touches ni effaces : la regle d'un
--    seau ne vaut que pour les envois suivants. Une photo HEIC est convertie
--    en JPEG sur l'appareil avant l'envoi.
--
-- Remplacement par ANCRES sur les definitions en place ; chaque ancre doit se
-- trouver une seule fois, sinon arret. Rejouable : une fonction qui porte deja
-- la marque n'est pas retouchee, les seaux sont poses a l'identique. Sur un
-- Postgres nu (CI), storage.buckets n'a pas les colonnes de reglage : la
-- partie B ne fait rien. Aucun mot d'effacement. Sans BEGIN ni COMMIT de
-- premier niveau.

-- ---------------------------------------------------------------------------
-- A1. Les elements de complement de la salle 1.
-- ---------------------------------------------------------------------------
DO $codes$
DECLARE
  v_oid regprocedure := 'private.candidature_complement_codes(text,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_avant constant text := E'|| ARRAY[''cadre_religieux'']::text[]';
  v_apres constant text := E'|| ARRAY[''cadre_religieux'', ''contrat'', ''avis'', ''code_conduite'', '
    || E'''piece_identite'', ''photo'', ''accord_publication'']::text[] -- COMPLEMENT-ET-FORMATS';
  v_n integer;
  v_commentaire text;
BEGIN
  IF pg_catalog.strpos(v_def, 'COMPLEMENT-ET-FORMATS') > 0 THEN
    RAISE NOTICE 'COMPLEMENT-ET-FORMATS : candidature_complement_codes deja etendue, rien a faire';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : ancre de candidature_complement_codes trouvee % fois au lieu de 1', v_n;
  END IF;
  v_commentaire := pg_catalog.obj_description(v_oid::oid, 'pg_proc');
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  IF v_commentaire IS NOT NULL AND v_commentaire LIKE '%md5_functiondef=%' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid,
      pg_catalog.regexp_replace(v_commentaire, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END IF;
END;
$codes$;

-- ---------------------------------------------------------------------------
-- A2. L'etat du candidat : la date de la demande de complement en cours.
-- ---------------------------------------------------------------------------
DO $etat$
DECLARE
  v_oid regprocedure := 'private.candidature_etat_candidat()'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_avant constant text := E'''complementDemande'', v_complement,';
  v_apres constant text := E'''complementDemande'', v_complement,\n'
    || E'    -- COMPLEMENT-ET-FORMATS : la date de la demande en cours, nulle sans demande.\n'
    || E'    ''complementDemandeLe'', CASE WHEN pg_catalog.jsonb_array_length(v_complement) > 0\n'
    || E'      THEN private.cand_instant(v_demande.cree_le) END,';
  v_n integer;
  v_commentaire text;
BEGIN
  IF pg_catalog.strpos(v_def, 'COMPLEMENT-ET-FORMATS') > 0 THEN
    RAISE NOTICE 'COMPLEMENT-ET-FORMATS : candidature_etat_candidat rend deja la date, rien a faire';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : ancre de candidature_etat_candidat trouvee % fois au lieu de 1', v_n;
  END IF;
  v_commentaire := pg_catalog.obj_description(v_oid::oid, 'pg_proc');
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  IF v_commentaire IS NOT NULL AND v_commentaire LIKE '%md5_functiondef=%' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid,
      pg_catalog.regexp_replace(v_commentaire, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END IF;
END;
$etat$;

-- ---------------------------------------------------------------------------
-- B. Les formats admis par les seaux.
-- ---------------------------------------------------------------------------
DO $seaux$
BEGIN
  IF (SELECT pg_catalog.count(*)
        FROM pg_catalog.pg_attribute a
       WHERE a.attrelid = pg_catalog.to_regclass('storage.buckets')
         AND a.attname IN ('allowed_mime_types', 'file_size_limit')
         AND NOT a.attisdropped) <> 2 THEN
    RAISE NOTICE 'COMPLEMENT-ET-FORMATS : storage.buckets sans reglage (Postgres nu), seaux non regles';
    RETURN;
  END IF;
  EXECUTE $u$
    UPDATE storage.buckets
       SET allowed_mime_types = ARRAY['image/jpeg', 'image/png'],
           file_size_limit = 8388608
     WHERE id = 'kyc'
  $u$;
  EXECUTE $u$
    UPDATE storage.buckets
       SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'],
           file_size_limit = 4194304
     WHERE id = 'photos_enseignants'
  $u$;
END;
$seaux$;

-- ---------------------------------------------------------------------------
-- Verification.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_ok boolean;
  v_codes text[] := private.candidature_complement_codes('prequalification', 'enseignant');
BEGIN
  -- Apres les cartes du questionnaire (variables), le cadre puis les six.
  IF v_codes[pg_catalog.array_position(v_codes, 'cadre_religieux') : pg_catalog.cardinality(v_codes)]
     IS DISTINCT FROM ARRAY['cadre_religieux', 'contrat', 'avis', 'code_conduite', 'piece_identite',
                            'photo', 'accord_publication']::text[] THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : liste de la salle 1 inattendue';
  END IF;
  IF private.candidature_complement_codes('verifications', 'enseignant')
     IS DISTINCT FROM ARRAY['piece_identite', 'cadre_religieux', 'contrat', 'avis']::text[] THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : la liste de la salle 2 a change';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.candidature_etat_candidat()'::regprocedure),
                       'complementDemandeLe') = 0 THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : candidature_etat_candidat non remplacee';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.candidature_complement_codes(text,text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.candidature_etat_candidat()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : aide interne executable par anon';
  END IF;
  IF (SELECT pg_catalog.count(*)
        FROM pg_catalog.pg_attribute a
       WHERE a.attrelid = pg_catalog.to_regclass('storage.buckets')
         AND a.attname IN ('allowed_mime_types', 'file_size_limit')
         AND NOT a.attisdropped) = 2 THEN
    EXECUTE $q$
      SELECT NOT EXISTS (
        SELECT 1 FROM storage.buckets b
         WHERE (b.id = 'kyc'
                AND (b.file_size_limit IS DISTINCT FROM 8388608
                     OR b.allowed_mime_types IS DISTINCT FROM ARRAY['image/jpeg', 'image/png']))
            OR (b.id = 'photos_enseignants'
                AND (b.file_size_limit IS DISTINCT FROM 4194304
                     OR b.allowed_mime_types IS DISTINCT FROM ARRAY['image/jpeg', 'image/png', 'image/webp'])))
    $q$ INTO v_ok;
    IF NOT v_ok THEN
      RAISE EXCEPTION 'COMPLEMENT-ET-FORMATS : reglage des seaux non pose';
    END IF;
  END IF;
END;
$postflight$;
