-- IMAGES-MESSAGERIE (16/11/2026), partie serveur, 2/5 : les RPC du depot et de
-- la lecture d'une image. Appelees par les fonctions Edge `message-image-depot`
-- et `message-images-lecture` AU NOM de la personne (son jeton).
--
-- Codes de refus (le NOM de l'exception, lu par la fonction Edge) :
--   ImageNonAutorise        42501  compte non valide, fil non lisible ou en lecture seule
--   ImageMineurRefuse       42501  un compte eleve de moins de 18 ans ne depose pas d'image
--   ImageMessageIntrouvable 42501  le message n'existe pas ou n'est pas le sien
--   ImageParametresInvalides 22023 type, taille, dimensions ou couleur hors des bornes
--   ImageDejaPourMessage    23505  une image existe deja pour ce message (une seule)
--   ImageLimiteHoraire      54000  20 images par heure et par personne
--   ImageIntentionIndisponible 42501 depot inconnu, deja confirme ou expire
--   ImageConfirmationNonAutorisee 42501 signature de confirmation refusee
--
-- La confirmation reutilise le secret deja en base pour la bibliotheque
-- (private.library_upload_confirmation_secrets) et le secret Edge
-- LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY : aucun secret nouveau. Le message signe
-- porte son propre prefixe (« message-image-v1 »), qu'aucune autre signature du
-- depot n'a : une signature de bibliotheque ne confirme pas une image.
--
-- FICHIER SANS MOT D'EFFACEMENT, sans BEGIN ni COMMIT de premier niveau.
-- S'installe apres 20261128200000.

-- 1. Demander un depot -----------------------------------------------------------
CREATE OR REPLACE FUNCTION public.message_image_demander(
  p_message_id uuid,
  p_mime text,
  p_octets bigint,
  p_mime_miniature text,
  p_octets_miniature bigint,
  p_largeur integer,
  p_hauteur integer,
  p_couleur_moyenne text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_mime text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_mime, '')));
  v_mime_min text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_mime_miniature, '')));
  v_couleur text;
  v_fil uuid;
  v_auteur uuid;
  v_droits record;
  v_ligne public.com_message_images%ROWTYPE;
  v_id uuid;
  v_base text;
  v_ext text;
  v_ext_min text;
BEGIN
  -- Compte valide d'abord : un appel sans compte n'apprend rien, pas meme « mineur ».
  IF coalesce(public.app_account_valid(), false) IS NOT TRUE OR v_moi IS NULL THEN
    RAISE EXCEPTION 'ImageNonAutorise' USING ERRCODE = '42501';
  END IF;
  -- Un compte eleve de moins de 18 ans ne depose pas d'image (il peut en recevoir).
  -- Meme lecture de l'age que la messagerie : student_type = 'minor'.
  IF private.com_est_mineur(v_moi) THEN
    RAISE EXCEPTION 'ImageMineurRefuse' USING ERRCODE = '42501';
  END IF;

  IF p_message_id IS NULL
     OR v_mime NOT IN ('image/jpeg', 'image/png', 'image/webp')
     OR v_mime_min NOT IN ('image/jpeg', 'image/png', 'image/webp')
     OR p_octets IS NULL OR p_octets < 1 OR p_octets > 2097152
     OR p_octets_miniature IS NULL OR p_octets_miniature < 1 OR p_octets_miniature > 102400
     OR p_largeur IS NULL OR p_largeur < 1 OR p_largeur > 20000
     OR p_hauteur IS NULL OR p_hauteur < 1 OR p_hauteur > 20000
     OR (p_couleur_moyenne IS NOT NULL
         AND pg_catalog.btrim(p_couleur_moyenne) !~ '^#?[0-9a-fA-F]{6}$') THEN
    RAISE EXCEPTION 'ImageParametresInvalides' USING ERRCODE = '22023';
  END IF;
  v_couleur := CASE WHEN p_couleur_moyenne IS NULL THEN NULL
    ELSE '#' || pg_catalog.lower(pg_catalog.ltrim(pg_catalog.btrim(p_couleur_moyenne), '#')) END;

  -- Un seul depot a la fois par personne : le compte de l'heure est exact.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('message_image:' || v_moi::text, 0));

  SELECT m.fil_id, m.auteur_id INTO v_fil, v_auteur
    FROM public.com_messages m WHERE m.id = p_message_id;
  IF v_fil IS NULL OR v_auteur IS DISTINCT FROM v_moi THEN
    RAISE EXCEPTION 'ImageMessageIntrouvable' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_droits FROM private.com_image_droits(v_fil);
  IF v_droits.p_ecrire IS NOT TRUE THEN
    RAISE EXCEPTION 'ImageNonAutorise' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_ligne FROM public.com_message_images i
   WHERE i.message_id = p_message_id FOR UPDATE;
  IF FOUND THEN
    -- Une seule image par message. Un depot reste « en attente » tant qu'il n'est
    -- pas confirme : le meme depot (memes types) peut etre redemande, par exemple
    -- si le lien signe a expire avant l'envoi. Les cles ne changent pas.
    IF v_ligne.etat <> 'en_attente' OR v_ligne.mime <> v_mime
       OR v_ligne.mime_miniature <> v_mime_min
       OR v_ligne.cree_le < pg_catalog.clock_timestamp() - interval '1 day' THEN
      RAISE EXCEPTION 'ImageDejaPourMessage' USING ERRCODE = '23505';
    END IF;
    UPDATE public.com_message_images i
       SET octets = p_octets, octets_miniature = p_octets_miniature,
           largeur = p_largeur, hauteur = p_hauteur, couleur_moyenne = v_couleur
     WHERE i.id = v_ligne.id
     RETURNING * INTO v_ligne;
  ELSE
    IF (SELECT pg_catalog.count(*) FROM public.com_message_images i
         WHERE i.auteur = v_moi
           AND i.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 20 THEN
      RAISE EXCEPTION 'ImageLimiteHoraire' USING ERRCODE = '54000';
    END IF;
    v_id := extensions.gen_random_uuid();
    v_ext := CASE v_mime WHEN 'image/jpeg' THEN 'jpg' WHEN 'image/png' THEN 'png' ELSE 'webp' END;
    v_ext_min := CASE v_mime_min WHEN 'image/jpeg' THEN 'jpg' WHEN 'image/png' THEN 'png' ELSE 'webp' END;
    v_base := 'fils/' || v_fil::text || '/' || v_id::text;
    INSERT INTO public.com_message_images (
      id, message_id, fil_id, auteur, cle_r2, cle_miniature, mime, mime_miniature,
      largeur, hauteur, octets, octets_miniature, couleur_moyenne)
    VALUES (
      v_id, p_message_id, v_fil, v_moi, v_base || '.' || v_ext, v_base || '-min.' || v_ext_min,
      v_mime, v_mime_min, p_largeur, p_hauteur, p_octets, p_octets_miniature, v_couleur)
    RETURNING * INTO v_ligne;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'image_id', v_ligne.id, 'fil_id', v_ligne.fil_id,
    'cle_r2', v_ligne.cle_r2, 'cle_miniature', v_ligne.cle_miniature,
    'mime', v_ligne.mime, 'mime_miniature', v_ligne.mime_miniature,
    'octets', v_ligne.octets, 'octets_miniature', v_ligne.octets_miniature,
    'expire_le', v_ligne.expire_le);
END;
$function$;

-- 2. Relire son depot avant de le confirmer --------------------------------------
CREATE OR REPLACE FUNCTION public.message_image_lire_depot(p_image_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_ligne public.com_message_images%ROWTYPE;
BEGIN
  IF coalesce(public.app_account_valid(), false) IS NOT TRUE OR auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ImageNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_ligne FROM public.com_message_images i
   WHERE i.id = p_image_id AND i.auteur = auth.uid() AND i.etat = 'en_attente';
  IF NOT FOUND OR v_ligne.cree_le < pg_catalog.clock_timestamp() - interval '1 day' THEN
    RAISE EXCEPTION 'ImageIntentionIndisponible' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'image_id', v_ligne.id, 'fil_id', v_ligne.fil_id,
    'cle_r2', v_ligne.cle_r2, 'cle_miniature', v_ligne.cle_miniature,
    'mime', v_ligne.mime, 'mime_miniature', v_ligne.mime_miniature,
    'octets', v_ligne.octets, 'octets_miniature', v_ligne.octets_miniature);
END;
$function$;

-- 3. Confirmer : la fonction Edge a lu les premiers octets et signe --------------
CREATE OR REPLACE FUNCTION public.message_image_confirmer(
  p_image_id uuid,
  p_tete_sha256 text,
  p_mime_reel text,
  p_mime_miniature_reel text,
  p_confirmation_signature text
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_ligne public.com_message_images%ROWTYPE;
  v_sha text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_tete_sha256, '')));
  v_signature text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_confirmation_signature, '')));
  v_secret text;
  v_attendue text;
  v_qui uuid;
BEGIN
  IF coalesce(public.app_account_valid(), false) IS NOT TRUE OR auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ImageNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT s.secret INTO v_secret
    FROM private.library_upload_confirmation_secrets s
   WHERE s.singleton
   FOR SHARE;
  IF v_secret IS NULL OR pg_catalog.length(v_secret) < 32
     OR v_signature !~ '^[0-9a-f]{64}$' OR v_sha !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'ImageConfirmationNonAutorisee' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_ligne FROM public.com_message_images i
   WHERE i.id = p_image_id AND i.auteur = auth.uid() FOR UPDATE;
  IF NOT FOUND OR v_ligne.etat <> 'en_attente'
     OR v_ligne.cree_le < pg_catalog.clock_timestamp() - interval '1 day' THEN
    RAISE EXCEPTION 'ImageIntentionIndisponible' USING ERRCODE = '42501';
  END IF;

  v_attendue := pg_catalog.encode(
    extensions.hmac(
      pg_catalog.convert_to(
        'message-image-v1' || E'\n' || p_image_id::text || E'\n' || v_sha || E'\n' || v_ligne.octets::text,
        'UTF8'),
      pg_catalog.convert_to(v_secret, 'UTF8'),
      'sha256'),
    'hex');
  IF v_signature IS DISTINCT FROM v_attendue THEN
    RAISE EXCEPTION 'ImageConfirmationNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.lower(pg_catalog.btrim(coalesce(p_mime_reel, ''))) <> v_ligne.mime
     OR pg_catalog.lower(pg_catalog.btrim(coalesce(p_mime_miniature_reel, ''))) <> v_ligne.mime_miniature THEN
    RAISE EXCEPTION 'ImageParametresInvalides' USING ERRCODE = '22023';
  END IF;

  UPDATE public.com_message_images i SET etat = 'confirmee' WHERE i.id = v_ligne.id;

  -- Les autres parties du fil rechargent le message : l'image existe maintenant.
  BEGIN
    FOR v_qui IN SELECT d FROM private.com_destinataires_signal(v_ligne.fil_id, v_ligne.auteur) AS d LOOP
      PERFORM private.com_signal_poser(v_qui, v_ligne.fil_id, 'message');
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'images messagerie : signal non pose (%)', SQLSTATE;
  END;
  RETURN pg_catalog.jsonb_build_object('image_id', v_ligne.id, 'etat', 'confirmee');
END;
$function$;

-- 4. Annuler un depot refuse (contenu qui n'est pas l'image annoncee) ------------
CREATE OR REPLACE FUNCTION public.message_image_annuler(p_image_id uuid)
RETURNS boolean
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_n integer;
BEGIN
  IF coalesce(public.app_account_valid(), false) IS NOT TRUE OR auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ImageNonAutorise' USING ERRCODE = '42501';
  END IF;
  UPDATE public.com_message_images i
     SET etat = 'supprimee', supprimee_le = pg_catalog.clock_timestamp()
   WHERE i.id = p_image_id AND i.auteur = auth.uid() AND i.etat = 'en_attente';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END;
$function$;

-- 5. Lire : les cles a signer, EN UNE FOIS pour tout un fil ----------------------
-- Sans [p_image_id] : les miniatures du fil (200 images au plus, les plus
-- recentes). Avec [p_image_id] : la cle de l'image complete. Une image expiree
-- ou retiree rend un etat « supprimee » et AUCUNE cle, meme si la tache de
-- purge n'est pas encore passee.
CREATE OR REPLACE FUNCTION public.message_images_a_signer(
  p_fil_id uuid, p_image_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_droits record;
BEGIN
  SELECT * INTO v_droits FROM private.com_image_droits(p_fil_id);
  IF v_droits.p_lire IS NOT TRUE THEN
    RAISE EXCEPTION 'ImageNonAutorise' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(x.o ORDER BY x.cree_le DESC, x.id DESC)
    FROM (
      SELECT i.id, i.cree_le,
        pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
          'id', i.id,
          'message_id', i.message_id,
          'etat', e.etat,
          'cle', CASE WHEN e.etat <> 'confirmee' THEN NULL
                      WHEN p_image_id IS NULL THEN i.cle_miniature
                      ELSE i.cle_r2 END,
          'mime', CASE WHEN e.etat <> 'confirmee' THEN NULL
                       WHEN p_image_id IS NULL THEN i.mime_miniature
                       ELSE i.mime END)) AS o
      FROM public.com_message_images i
      CROSS JOIN LATERAL (SELECT CASE
        WHEN i.etat = 'confirmee' AND i.expire_le <= pg_catalog.clock_timestamp() THEN 'supprimee'
        ELSE i.etat END AS etat) e
      WHERE i.fil_id = p_fil_id
        AND (p_image_id IS NULL OR i.id = p_image_id)
        AND (i.etat <> 'en_attente' OR i.auteur = v_droits.p_moi)
      ORDER BY i.cree_le DESC, i.id DESC
      LIMIT 200
    ) x), '[]'::jsonb);
END;
$function$;

-- 6. Droits --------------------------------------------------------------------
DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.message_image_demander(uuid,text,bigint,text,bigint,integer,integer,text)',
    'public.message_image_lire_depot(uuid)',
    'public.message_image_confirmer(uuid,text,text,text,text)',
    'public.message_image_annuler(uuid)',
    'public.message_images_a_signer(uuid,uuid)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', f);
    END IF;
  END LOOP;
END
$acl$;
