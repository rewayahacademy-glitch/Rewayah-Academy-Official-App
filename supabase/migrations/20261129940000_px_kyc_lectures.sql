-- PX-KYC-1 (pilote, 17/11/2026, feu vert apres PLAN-KYC.md, PR 623) : la lecture automatique des pieces d'identite,
-- COTE SERVEUR SEULEMENT. Aucun ecran, aucun appel a un fournisseur d'IA n'est dans ce fichier : la fonction Edge
-- `piece-identite-lecture` lit, la base garde, decide de la proposition et borne le lot.
--
-- Arbitrages du pilote (juriste par delegation du directeur) : D4 article 6.1.b + interet legitime (prevention de la
-- fraude) ; D5 echantillon d'ouverture OUI, 10 % de chaque lot tires au hasard, au moins 3, a ouvrir AVANT que la
-- validation en lot soit permise ; D6 expiration a moins de 3 mois = « a verifier » ; D7 le modele est un REGLAGE
-- serveur, jamais en dur ; D3 un reglage « genres envoyes », VIDE par defaut : rien n'est envoye tant que le directeur
-- n'a pas decide.
--
-- Ce que le fichier pose :
--   1. private.kyc_lecture_reglages : une ligne, `actif` FAUX par defaut, modele nul, genres_envoyes vide ;
--   2. private.kyc_lectures : une lecture par piece et par version de consigne (champs structures, jamais l'image) ;
--      la PROPOSITION est calculee ICI (private.kyc_proposition), seule source de la regle ;
--   3. private.kyc_lots : un lot de validation, son echantillon, son resultat (idempotence) ;
--   4. portes de la direction (authenticated) : etat, lancer (aal2), regler (aal2), lire une lecture, liste des pieces
--      pretes, preparer un lot (aal2), valider un lot (aal2) ;
--   5. portes du serveur (service_role seul) : la file des pieces a lire, l'ecriture d'une lecture ;
--   6. l'effacement des DONNEES de lecture (nom, date, champs) quand la piece est echue, effacee ou absente, par une
--      tache quotidienne (UPDATE : la lecture est une donnee personnelle qui ne survit pas a la piece).
--
-- Ce que le fichier ne fait pas : decider seul, refuser en lot, lire une piece en dehors du perimetre de genre, donner
-- quoi que ce soit a Praxis (aucune fonction praxis_* ne cite ces objets ; le scenario le prouve).
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.kyc_documents') IS NULL
     OR pg_catalog.to_regprocedure('public.read_kyc_documents()') IS NULL
     OR pg_catalog.to_regprocedure('public.decider_dossier(uuid,boolean,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL
     OR pg_catalog.to_regprocedure('public.autoriser_lecture_piece_identite(uuid)') IS NULL
     OR pg_catalog.to_regclass('public.candidatures') IS NULL THEN
    RAISE EXCEPTION 'PX-KYC-1 : une dependance est absente (kyc_documents, read_kyc_documents, decider_dossier, journal, candidatures)';
  END IF;
  IF pg_catalog.to_regclass('private.kyc_lectures') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-KYC-1 : deja installe';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les reglages : tout est ferme tant que le directeur n'a rien decide.
-- ---------------------------------------------------------------------------
CREATE TABLE private.kyc_lecture_reglages (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  actif boolean NOT NULL DEFAULT false,
  modele text CHECK (modele IS NULL OR modele ~ '^claude-[a-z0-9.-]{3,60}$'),
  genres_envoyes text[] NOT NULL DEFAULT '{}'::text[] CHECK (genres_envoyes <@ ARRAY['male', 'female']::text[]),
  marge_expiration_mois smallint NOT NULL DEFAULT 3 CHECK (marge_expiration_mois BETWEEN 0 AND 24),
  lot_max smallint NOT NULL DEFAULT 50 CHECK (lot_max BETWEEN 1 AND 50),
  echantillon_pct smallint NOT NULL DEFAULT 10 CHECK (echantillon_pct BETWEEN 1 AND 100),
  echantillon_min smallint NOT NULL DEFAULT 3 CHECK (echantillon_min BETWEEN 1 AND 50),
  modifie_le timestamptz,
  modifie_par uuid
);
INSERT INTO private.kyc_lecture_reglages DEFAULT VALUES;
ALTER TABLE private.kyc_lecture_reglages ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE private.kyc_lecture_reglages IS
  'PX-KYC-1 : reglages de la lecture automatique des pieces. FERME par defaut (actif faux, modele nul, aucun genre envoye). Ecrit par direction_kyc_lecture_regler seule.';

-- ---------------------------------------------------------------------------
-- 2. Les lectures : une par piece et par version de consigne.
-- ---------------------------------------------------------------------------
CREATE TABLE private.kyc_lectures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL,
  version_consigne smallint NOT NULL CHECK (version_consigne > 0),
  modele text NOT NULL,
  etat text NOT NULL CHECK (etat IN ('lue', 'non_lue')),
  cause text CHECK (cause IN ('format_non_lu', 'trop_grand', 'refus_fournisseur', 'reponse_invalide', 'panne', 'piece_introuvable')),
  type_piece text CHECK (type_piece IN ('carte_identite', 'passeport', 'titre_sejour', 'permis', 'autre', 'illisible')),
  nom_ecrit text CHECK (nom_ecrit IS NULL OR pg_catalog.length(nom_ecrit) <= 80),
  nom_concordance text CHECK (nom_concordance IN ('oui', 'non', 'doute')),
  date_expiration date,
  lisible boolean,
  photo_presente text CHECK (photo_presente IN ('oui', 'non', 'indetermine')),
  retouche text CHECK (retouche IN ('aucun', 'possibles', 'probables')),
  causes_retouche text[] NOT NULL DEFAULT '{}'::text[]
    CHECK (causes_retouche <@ ARRAY['police_incoherente', 'bords_de_decoupe', 'zone_floue', 'capture_decran', 'autre']::text[]),
  mrz text CHECK (mrz IN ('valide', 'invalide', 'sans_objet')),
  proposition text NOT NULL CHECK (proposition IN ('conforme', 'a_verifier', 'non_conforme')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  donnees_effacees_le timestamptz,
  -- Une lecture « lue » porte tous ses champs ; une lecture « non lue » porte une cause et aucun champ lu.
  CONSTRAINT kyc_lectures_forme CHECK (
    (etat = 'lue' AND cause IS NULL AND type_piece IS NOT NULL AND lisible IS NOT NULL AND photo_presente IS NOT NULL
       AND retouche IS NOT NULL AND mrz IS NOT NULL AND nom_concordance IS NOT NULL)
    OR (etat = 'non_lue' AND cause IS NOT NULL AND proposition = 'a_verifier'
       AND nom_ecrit IS NULL AND date_expiration IS NULL)
    OR donnees_effacees_le IS NOT NULL),
  CONSTRAINT kyc_lectures_unique UNIQUE (document_id, version_consigne)
);
CREATE INDEX kyc_lectures_document_idx ON private.kyc_lectures (document_id, version_consigne DESC);
ALTER TABLE private.kyc_lectures ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE private.kyc_lectures IS
  'PX-KYC-1 : ce qu un modele de vision a LU d une piece (champs structures, jamais l image) et la proposition calculee par private.kyc_proposition. Donnee personnelle : les champs sont effaces avec la piece (private.kyc_lectures_effacer_donnees). Aucun droit pour aucun role client ; lue par les seules portes de la direction. Jamais lue par Praxis.';

-- ---------------------------------------------------------------------------
-- 3. Les lots de validation.
-- ---------------------------------------------------------------------------
CREATE TABLE private.kyc_lots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  acteur uuid NOT NULL,
  documents uuid[] NOT NULL CHECK (pg_catalog.cardinality(documents) BETWEEN 1 AND 50),
  echantillon uuid[] NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  expire_le timestamptz NOT NULL DEFAULT pg_catalog.now() + interval '30 minutes',
  valide_le timestamptz,
  resultat jsonb
);
ALTER TABLE private.kyc_lots ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE private.kyc_lots IS
  'PX-KYC-1 : un lot de validation sur proposition (50 pieces au plus), son echantillon d ouverture tire au hasard par le serveur, son resultat. Rejouer la validation rend le resultat deja ecrit.';

DO $droits_tables$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON TABLE private.kyc_lecture_reglages, private.kyc_lectures, private.kyc_lots FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits_tables$;
REVOKE ALL ON TABLE private.kyc_lecture_reglages, private.kyc_lectures, private.kyc_lots FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- 4. La regle de la proposition : UNE source. Le plus prudent l'emporte.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.kyc_proposition(
  p_etat text, p_type text, p_lisible boolean, p_photo text, p_retouche text,
  p_nom text, p_mrz text, p_expiration date, p_marge smallint)
RETURNS text
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
BEGIN
  -- Une piece non lue n'est jamais « non conforme » : une panne ne refuse personne.
  IF p_etat IS DISTINCT FROM 'lue' THEN
    RETURN 'a_verifier';
  END IF;
  -- Les signes nets : expiree, illisible, retouche probable.
  IF p_lisible IS NOT TRUE OR p_type = 'illisible' OR p_retouche = 'probables'
     OR (p_expiration IS NOT NULL AND p_expiration < current_date) THEN
    RETURN 'non_conforme';
  END IF;
  -- Conforme : TOUTES les conditions. Une date absente, un doute de nom, une somme MRZ fausse, une expiration
  -- proche, une retouche possible, une photo non confirmee : a verifier.
  IF p_type IN ('carte_identite', 'passeport', 'titre_sejour', 'permis')
     AND p_photo = 'oui' AND p_retouche = 'aucun' AND p_nom = 'oui'
     AND p_mrz IN ('valide', 'sans_objet')
     AND p_expiration IS NOT NULL
     AND p_expiration >= current_date + pg_catalog.make_interval(months => p_marge::integer) THEN
    RETURN 'conforme';
  END IF;
  RETURN 'a_verifier';
END;
$function$;
ALTER FUNCTION private.kyc_proposition(text, text, boolean, text, text, text, text, date, smallint) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.kyc_proposition(text, text, boolean, text, text, text, text, date, smallint) FROM PUBLIC;
COMMENT ON FUNCTION private.kyc_proposition(text, text, boolean, text, text, text, text, date, smallint) IS
  'PX-KYC-1: guard_type=INTERNAL_PURE; la regle unique de la proposition (conforme / a_verifier / non_conforme) ; le plus prudent l emporte ; une piece non lue est toujours a_verifier. date=2026-11-17.';

-- Une piece qui doit passer par le geste « Valider la piece » de la salle 3 (sept controles) n'entre jamais dans un lot :
-- decider_dossier seul ne remplace pas ces controles.
CREATE FUNCTION private.kyc_piece_hors_lot(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.candidatures c
                  WHERE c.profile_id = p_profil AND c.issue = 'en_cours' AND c.etape = 'confirmee');
$function$;
ALTER FUNCTION private.kyc_piece_hors_lot(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.kyc_piece_hors_lot(uuid) FROM PUBLIC;
COMMENT ON FUNCTION private.kyc_piece_hors_lot(uuid) IS
  'PX-KYC-1: guard_type=INTERNAL_PURE; vrai pour un candidat en salle 3 (etape confirmee, en cours) : sa piece se valide par valider_piece_candidat, jamais en lot. date=2026-11-17.';

-- La lecture courante d'une piece : celle de la version la plus haute.
CREATE FUNCTION private.kyc_lecture_courante(p_document uuid)
RETURNS private.kyc_lectures
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT l.* FROM private.kyc_lectures l
   WHERE l.document_id = p_document
   ORDER BY l.version_consigne DESC LIMIT 1;
$function$;
ALTER FUNCTION private.kyc_lecture_courante(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.kyc_lecture_courante(uuid) FROM PUBLIC;
COMMENT ON FUNCTION private.kyc_lecture_courante(uuid) IS
  'PX-KYC-1: guard_type=INTERNAL_PURE; la lecture de version la plus haute d une piece. date=2026-11-17.';

DO $droits_internes$
DECLARE
  v_role text;
  v_f text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      FOREACH v_f IN ARRAY ARRAY[
        'private.kyc_proposition(text, text, boolean, text, text, text, text, date, smallint)',
        'private.kyc_piece_hors_lot(uuid)', 'private.kyc_lecture_courante(uuid)'] LOOP
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_f, v_role);
      END LOOP;
    END IF;
  END LOOP;
END;
$droits_internes$;

-- ---------------------------------------------------------------------------
-- 5. Les portes de la direction.
-- ---------------------------------------------------------------------------

-- 5.1 L'etat : des compteurs, dans le perimetre de genre du lecteur. Aucune personne.
CREATE FUNCTION public.direction_kyc_lecture_etat()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r private.kyc_lecture_reglages;
  v_attente integer;
  v_lues integer;
  v_pretes integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT r.* INTO v_r FROM private.kyc_lecture_reglages r WHERE r.id;
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE (private.kyc_lecture_courante(k.id)).id IS NOT NULL)::integer,
         pg_catalog.count(*) FILTER (WHERE (private.kyc_lecture_courante(k.id)).proposition = 'conforme'
                                       AND NOT private.kyc_piece_hors_lot(k.profile_id))::integer
    INTO v_attente, v_lues, v_pretes
    FROM public.read_kyc_documents() k
   WHERE k.status = 'pending'::public.kyc_doc_status AND k.deleted_at IS NULL;
  RETURN pg_catalog.jsonb_build_object(
    'actif', v_r.actif, 'modele', v_r.modele, 'genresEnvoyes', pg_catalog.to_jsonb(v_r.genres_envoyes),
    'margeExpirationMois', v_r.marge_expiration_mois, 'lotMax', v_r.lot_max,
    'enAttente', v_attente, 'lues', v_lues, 'pretes', v_pretes);
END;
$function$;

-- 5.2 Lancer une lecture : la porte de la fonction Edge. aal2, car des pieces vont chez un tiers.
CREATE FUNCTION public.direction_kyc_lecture_lancer()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r private.kyc_lecture_reglages;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  SELECT r.* INTO v_r FROM private.kyc_lecture_reglages r WHERE r.id;
  IF NOT v_r.actif OR v_r.modele IS NULL OR pg_catalog.cardinality(v_r.genres_envoyes) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'cause', 'ferme');
  END IF;
  PERFORM public.log_sensitive_access('kyc_lecture_lancee', 'kyc_lecture_reglages', 'unique',
    pg_catalog.jsonb_build_object('modele', v_r.modele, 'genres', pg_catalog.to_jsonb(v_r.genres_envoyes)));
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$function$;

-- 5.3 Regler : le directeur (aal2). Rien ne s'ouvre sans modele ni genre.
CREATE FUNCTION public.direction_kyc_lecture_regler(p_actif boolean, p_modele text, p_genres text[])
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genres text[];
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_actif IS NULL OR p_genres IS NULL OR pg_catalog.array_position(p_genres, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'reglage invalide' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(DISTINCT g ORDER BY g), '{}'::text[]) INTO v_genres
    FROM pg_catalog.unnest(p_genres) g;
  IF NOT (v_genres <@ ARRAY['male', 'female']::text[]) THEN
    RAISE EXCEPTION 'genre inconnu' USING ERRCODE = '22023';
  END IF;
  IF p_actif AND (p_modele IS NULL OR pg_catalog.cardinality(v_genres) = 0) THEN
    RAISE EXCEPTION 'ouvrir la lecture exige un modele et au moins un genre' USING ERRCODE = '22023';
  END IF;
  UPDATE private.kyc_lecture_reglages
     SET actif = p_actif, modele = p_modele, genres_envoyes = v_genres,
         modifie_le = pg_catalog.now(), modifie_par = auth.uid()
   WHERE id;
  PERFORM public.log_sensitive_access('kyc_lecture_reglee', 'kyc_lecture_reglages', 'unique',
    pg_catalog.jsonb_build_object('actif', p_actif, 'modele', p_modele, 'genres', pg_catalog.to_jsonb(v_genres)));
  RETURN pg_catalog.jsonb_build_object('actif', p_actif, 'modele', p_modele, 'genresEnvoyes', pg_catalog.to_jsonb(v_genres));
END;
$function$;

-- 5.4 Lire la lecture d'une piece, sur la fiche. Meme perimetre que la piece ; journalise.
CREATE FUNCTION public.kyc_lecture_dossier(p_document uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_k public.kyc_documents;
  v_l private.kyc_lectures;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT k.* INTO v_k FROM public.read_kyc_documents() k WHERE k.id = p_document;
  IF v_k.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  v_l := private.kyc_lecture_courante(p_document);
  IF v_l.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('lecture', NULL);
  END IF;
  PERFORM public.log_sensitive_access('kyc_lecture_ouverte', 'kyc_documents', p_document::text,
    pg_catalog.jsonb_build_object('version', v_l.version_consigne));
  RETURN pg_catalog.jsonb_build_object('lecture', pg_catalog.jsonb_build_object(
    'proposition', v_l.proposition, 'etat', v_l.etat, 'cause', v_l.cause, 'typePiece', v_l.type_piece,
    'nomEcrit', v_l.nom_ecrit, 'nomConcordance', v_l.nom_concordance, 'dateExpiration', v_l.date_expiration,
    'lisible', v_l.lisible, 'photoPresente', v_l.photo_presente, 'retouche', v_l.retouche,
    'causesRetouche', pg_catalog.to_jsonb(v_l.causes_retouche), 'mrz', v_l.mrz, 'modele', v_l.modele,
    'version', v_l.version_consigne, 'lueLe', v_l.cree_le,
    'horsLot', private.kyc_piece_hors_lot(v_k.profile_id)));
END;
$function$;

-- 5.5 Les pieces pretes : conformes, en attente, dans le perimetre, hors salle 3. Une ligne chacune, sans nom.
CREATE FUNCTION public.kyc_lectures_pretes()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'documentId', t.id, 'docType', t.doc_type, 'typePiece', t.type_piece,
             'dateExpiration', t.date_expiration, 'deposeLe', t.created_at) ORDER BY t.created_at, t.id)
      FROM (SELECT k.id, k.doc_type, k.created_at, k.profile_id,
                   (private.kyc_lecture_courante(k.id)).type_piece AS type_piece,
                   (private.kyc_lecture_courante(k.id)).date_expiration AS date_expiration,
                   (private.kyc_lecture_courante(k.id)).proposition AS proposition
              FROM public.read_kyc_documents() k
             WHERE k.status = 'pending'::public.kyc_doc_status AND k.deleted_at IS NULL
             ORDER BY k.created_at, k.id) t
     WHERE t.proposition = 'conforme' AND NOT private.kyc_piece_hors_lot(t.profile_id)
     LIMIT 200), '[]'::jsonb);
END;
$function$;

-- 5.6 Preparer un lot : le serveur tire l'echantillon a ouvrir. aal2.
CREATE FUNCTION public.direction_kyc_lot_preparer(p_documents uuid[])
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r private.kyc_lecture_reglages;
  v_docs uuid[];
  v_n integer;
  v_ok integer;
  v_taille integer;
  v_echantillon uuid[];
  v_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  SELECT r.* INTO v_r FROM private.kyc_lecture_reglages r WHERE r.id;
  IF p_documents IS NULL OR pg_catalog.array_position(p_documents, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'lot invalide' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(DISTINCT d ORDER BY d), '{}'::uuid[]) INTO v_docs FROM pg_catalog.unnest(p_documents) d;
  v_n := pg_catalog.cardinality(v_docs);
  IF v_n = 0 OR v_n > v_r.lot_max THEN
    RAISE EXCEPTION 'un lot compte de 1 a % pieces', v_r.lot_max USING ERRCODE = '22023';
  END IF;
  -- Chaque piece : dans le perimetre, en attente, non effacee, lue « conforme » par la version courante, hors salle 3.
  SELECT pg_catalog.count(*)::integer INTO v_ok
    FROM public.read_kyc_documents() k
   WHERE k.id = ANY (v_docs) AND k.status = 'pending'::public.kyc_doc_status AND k.deleted_at IS NULL
     AND (private.kyc_lecture_courante(k.id)).proposition = 'conforme'
     AND NOT private.kyc_piece_hors_lot(k.profile_id);
  IF v_ok <> v_n THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'piece_non_eligible');
  END IF;
  v_taille := least(v_n, greatest(v_r.echantillon_min::integer,
                                  pg_catalog.ceil(v_n * v_r.echantillon_pct::numeric / 100)::integer));
  SELECT pg_catalog.array_agg(x.d) INTO v_echantillon
    FROM (SELECT d FROM pg_catalog.unnest(v_docs) d ORDER BY pg_catalog.random() LIMIT v_taille) x;
  INSERT INTO private.kyc_lots (acteur, documents, echantillon)
  VALUES (auth.uid(), v_docs, v_echantillon) RETURNING id INTO v_id;
  RETURN pg_catalog.jsonb_build_object('lotId', v_id, 'documents', pg_catalog.to_jsonb(v_docs),
                                       'echantillon', pg_catalog.to_jsonb(v_echantillon),
                                       'expireLe', (SELECT l.expire_le FROM private.kyc_lots l WHERE l.id = v_id));
END;
$function$;

-- 5.7 Valider un lot : seulement apres l'ouverture REELLE de l'echantillon (lue dans le journal d'audit, pas dite par
-- le client). Rejouable : un lot deja valide rend son resultat. aal2.
CREATE FUNCTION public.direction_kyc_lot_valider(p_lot uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lot private.kyc_lots;
  v_manquantes integer;
  v_doc uuid;
  v_k public.kyc_documents;
  v_valides uuid[] := '{}';
  v_refuses jsonb := '[]'::jsonb;
  v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  SELECT l.* INTO v_lot FROM private.kyc_lots l WHERE l.id = p_lot FOR UPDATE;
  IF v_lot.id IS NULL OR v_lot.acteur IS DISTINCT FROM v_uid THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'lot_inconnu');
  END IF;
  IF v_lot.valide_le IS NOT NULL THEN
    RETURN v_lot.resultat;
  END IF;
  IF v_lot.expire_le < pg_catalog.clock_timestamp() THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'lot_expire');
  END IF;
  -- L'echantillon : chaque piece tiree doit avoir ete OUVERTE par cette personne depuis la creation du lot.
  SELECT pg_catalog.count(*)::integer INTO v_manquantes
    FROM pg_catalog.unnest(v_lot.echantillon) e
   WHERE NOT EXISTS (SELECT 1 FROM public.audit_logs a
                      WHERE a.action = 'kyc_document_open' AND a.table_name = 'kyc_documents'
                        AND a.row_id = e::text AND a.actor = v_uid AND a.created_at >= v_lot.cree_le);
  IF v_manquantes > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'echantillon_non_ouvert', 'restantes', v_manquantes);
  END IF;
  FOREACH v_doc IN ARRAY v_lot.documents LOOP
    BEGIN
      SELECT k.* INTO v_k FROM public.read_kyc_documents() k WHERE k.id = v_doc;
      IF v_k.id IS NULL OR v_k.status <> 'pending'::public.kyc_doc_status OR v_k.deleted_at IS NOT NULL
         OR (private.kyc_lecture_courante(v_doc)).proposition IS DISTINCT FROM 'conforme'
         OR private.kyc_piece_hors_lot(v_k.profile_id) THEN
        v_refuses := v_refuses || pg_catalog.jsonb_build_array(
          pg_catalog.jsonb_build_object('documentId', v_doc, 'cause', 'plus_eligible'));
      ELSE
        PERFORM public.decider_dossier(v_doc, true, NULL);
        v_valides := v_valides || v_doc;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_refuses := v_refuses || pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object('documentId', v_doc, 'cause', 'echec'));
    END;
  END LOOP;
  v_resultat := pg_catalog.jsonb_build_object('lotId', p_lot, 'valides', pg_catalog.to_jsonb(v_valides),
                                              'refuses', v_refuses);
  UPDATE private.kyc_lots SET valide_le = pg_catalog.clock_timestamp(), resultat = v_resultat WHERE id = p_lot;
  PERFORM public.log_sensitive_access('kyc_lot_valide', 'kyc_lots', p_lot::text,
    pg_catalog.jsonb_build_object('valides', pg_catalog.cardinality(v_valides),
                                  'refuses', pg_catalog.jsonb_array_length(v_refuses),
                                  'echantillon', pg_catalog.cardinality(v_lot.echantillon),
                                  'sur_proposition', true));
  RETURN v_resultat;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Les portes du serveur (service_role seul) : la file et l'ecriture.
-- ---------------------------------------------------------------------------

-- 6.1 La file : les pieces en attente, des genres que le directeur a decides, sans lecture de cette version.
CREATE FUNCTION public.kyc_lecture_file(p_version smallint, p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r private.kyc_lecture_reglages;
BEGIN
  SELECT r.* INTO v_r FROM private.kyc_lecture_reglages r WHERE r.id;
  IF NOT v_r.actif OR v_r.modele IS NULL OR pg_catalog.cardinality(v_r.genres_envoyes) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('actif', false, 'items', '[]'::jsonb);
  END IF;
  RETURN pg_catalog.jsonb_build_object('actif', true, 'modele', v_r.modele,
    'margeExpirationMois', v_r.marge_expiration_mois,
    'items', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'documentId', t.id, 'objectKey', t.object_key, 'stockage', t.storage_backend, 'docType', t.doc_type,
               'nomDossier', t.nom) ORDER BY t.created_at, t.id)
        FROM (SELECT k.id, k.object_key, k.storage_backend, k.doc_type, k.created_at,
                     pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) AS nom
                FROM public.kyc_documents k
                JOIN public.profiles p ON p.id = k.profile_id
               WHERE k.status = 'pending'::public.kyc_doc_status AND k.deleted_at IS NULL
                 AND (k.purge_at IS NULL OR k.purge_at > pg_catalog.now())
                 AND k.gender::text = ANY (v_r.genres_envoyes)
                 AND NOT EXISTS (SELECT 1 FROM private.kyc_lectures l
                                  WHERE l.document_id = k.id AND l.version_consigne = p_version)
               ORDER BY k.created_at, k.id
               LIMIT least(greatest(coalesce(p_limite, 20), 1), 50)) t), '[]'::jsonb));
END;
$function$;

-- 6.2 L'ecriture d'une lecture. La proposition est calculee ICI, jamais recue.
CREATE FUNCTION public.kyc_lecture_ecrire(p_document uuid, p_version smallint, p_modele text, p_resultat jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r private.kyc_lecture_reglages;
  v_k public.kyc_documents;
  v_etat text := p_resultat ->> 'etat';
  v_prop text;
  v_id uuid;
  v_causes text[];
BEGIN
  SELECT r.* INTO v_r FROM private.kyc_lecture_reglages r WHERE r.id;
  IF NOT v_r.actif THEN
    RAISE EXCEPTION 'lecture fermee' USING ERRCODE = '42501';
  END IF;
  IF p_document IS NULL OR p_version IS NULL OR p_modele IS NULL OR p_resultat IS NULL
     OR pg_catalog.jsonb_typeof(p_resultat) IS DISTINCT FROM 'object' OR v_etat NOT IN ('lue', 'non_lue') THEN
    RAISE EXCEPTION 'lecture invalide' USING ERRCODE = '22023';
  END IF;
  SELECT k.* INTO v_k FROM public.kyc_documents k WHERE k.id = p_document;
  IF v_k.id IS NULL OR v_k.deleted_at IS NOT NULL OR v_k.gender::text <> ALL (v_r.genres_envoyes) THEN
    RAISE EXCEPTION 'piece hors de la lecture decidee' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(pg_catalog.array_agg(c), '{}'::text[]) INTO v_causes
    FROM pg_catalog.jsonb_array_elements_text(coalesce(p_resultat -> 'causesRetouche', '[]'::jsonb)) c;
  v_prop := private.kyc_proposition(v_etat, p_resultat ->> 'typePiece', (p_resultat ->> 'lisible')::boolean,
              p_resultat ->> 'photoPresente', p_resultat ->> 'retouche', p_resultat ->> 'nomConcordance',
              p_resultat ->> 'mrz', (p_resultat ->> 'dateExpiration')::date, v_r.marge_expiration_mois);
  INSERT INTO private.kyc_lectures (document_id, version_consigne, modele, etat, cause, type_piece, nom_ecrit,
      nom_concordance, date_expiration, lisible, photo_presente, retouche, causes_retouche, mrz, proposition)
  VALUES (p_document, p_version, p_modele, v_etat, p_resultat ->> 'cause', p_resultat ->> 'typePiece',
      left(p_resultat ->> 'nomEcrit', 80), p_resultat ->> 'nomConcordance', (p_resultat ->> 'dateExpiration')::date,
      (p_resultat ->> 'lisible')::boolean, p_resultat ->> 'photoPresente', p_resultat ->> 'retouche', v_causes,
      p_resultat ->> 'mrz', v_prop)
  ON CONFLICT ON CONSTRAINT kyc_lectures_unique DO NOTHING
  RETURNING id INTO v_id;
  IF v_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('ecrite', false, 'cause', 'deja_lue');
  END IF;
  RETURN pg_catalog.jsonb_build_object('ecrite', true, 'proposition', v_prop);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. La lecture est une donnee personnelle : elle part avec la piece.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.kyc_lectures_effacer_donnees()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  UPDATE private.kyc_lectures l
     SET nom_ecrit = NULL, date_expiration = NULL, type_piece = NULL, lisible = NULL, photo_presente = NULL,
         retouche = NULL, causes_retouche = '{}'::text[], mrz = NULL, nom_concordance = NULL,
         proposition = 'a_verifier', donnees_effacees_le = pg_catalog.clock_timestamp()
   WHERE l.donnees_effacees_le IS NULL
     AND NOT EXISTS (SELECT 1 FROM public.kyc_documents k
                      WHERE k.id = l.document_id AND k.deleted_at IS NULL
                        AND (k.purge_at IS NULL OR k.purge_at > pg_catalog.clock_timestamp()));
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 8. Proprietaire, droits, empreintes, planification.
-- ---------------------------------------------------------------------------
ALTER FUNCTION public.direction_kyc_lecture_etat() OWNER TO postgres;
ALTER FUNCTION public.direction_kyc_lecture_lancer() OWNER TO postgres;
ALTER FUNCTION public.direction_kyc_lecture_regler(boolean, text, text[]) OWNER TO postgres;
ALTER FUNCTION public.kyc_lecture_dossier(uuid) OWNER TO postgres;
ALTER FUNCTION public.kyc_lectures_pretes() OWNER TO postgres;
ALTER FUNCTION public.direction_kyc_lot_preparer(uuid[]) OWNER TO postgres;
ALTER FUNCTION public.direction_kyc_lot_valider(uuid) OWNER TO postgres;
ALTER FUNCTION public.kyc_lecture_file(smallint, integer) OWNER TO postgres;
ALTER FUNCTION public.kyc_lecture_ecrire(uuid, smallint, text, jsonb) OWNER TO postgres;
ALTER FUNCTION private.kyc_lectures_effacer_donnees() OWNER TO postgres;

DO $droits$
DECLARE
  v_portes_direction text[] := ARRAY[
    'public.direction_kyc_lecture_etat()', 'public.direction_kyc_lecture_lancer()',
    'public.direction_kyc_lecture_regler(boolean, text, text[])', 'public.kyc_lecture_dossier(uuid)',
    'public.kyc_lectures_pretes()', 'public.direction_kyc_lot_preparer(uuid[])', 'public.direction_kyc_lot_valider(uuid)'];
  v_portes_serveur text[] := ARRAY[
    'public.kyc_lecture_file(smallint, integer)', 'public.kyc_lecture_ecrire(uuid, smallint, text, jsonb)'];
  v_f text;
  v_role text;
BEGIN
  FOREACH v_f IN ARRAY v_portes_direction || v_portes_serveur LOOP
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_f);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_f, v_role);
      END IF;
    END LOOP;
  END LOOP;
  FOREACH v_f IN ARRAY v_portes_direction LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_f);
  END LOOP;
  FOREACH v_f IN ARRAY v_portes_serveur LOOP
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', v_f);
  END LOOP;
  REVOKE ALL ON FUNCTION private.kyc_lectures_effacer_donnees() FROM PUBLIC;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION private.kyc_lectures_effacer_donnees() FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;

DO $empreintes$
DECLARE
  v_def text[][] := ARRAY[
    ARRAY['public.direction_kyc_lecture_etat()', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ',
          'PX-KYC-1 : compteurs de la lecture automatique dans le perimetre de genre du lecteur ; aucune personne.'],
    ARRAY['public.direction_kyc_lecture_lancer()', 'ROLE_POSITIVE_ADMIN',
          'PX-KYC-1 : porte de la fonction Edge de lecture ; direction active en aal2 ; refuse tant que la lecture est fermee.'],
    ARRAY['public.direction_kyc_lecture_regler(boolean, text, text[])', 'ROLE_POSITIVE_ADMIN',
          'PX-KYC-1 : ouvre ou ferme la lecture, choisit le modele et les genres envoyes ; direction active en aal2 ; rien ne s ouvre sans modele ni genre.'],
    ARRAY['public.kyc_lecture_dossier(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ',
          'PX-KYC-1 : la lecture automatique d une piece, meme perimetre que la piece ; journalisee.'],
    ARRAY['public.kyc_lectures_pretes()', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ',
          'PX-KYC-1 : les pieces lues conformes, en attente, dans le perimetre, hors salle 3 ; sans nom.'],
    ARRAY['public.direction_kyc_lot_preparer(uuid[])', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ',
          'PX-KYC-1 : prepare un lot de 50 pieces au plus et tire l echantillon a ouvrir ; direction active en aal2.'],
    ARRAY['public.direction_kyc_lot_valider(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
          'PX-KYC-1 : valide un lot par decider_dossier, seulement apres l ouverture reelle de l echantillon (lue dans audit_logs) ; direction active en aal2 ; rejouable.'],
    ARRAY['public.kyc_lecture_file(smallint, integer)', 'SERVICE_ROLE_ONLY_EDGE',
          'PX-KYC-1 : la file des pieces a lire, des seuls genres decides ; fonction Edge piece-identite-lecture.'],
    ARRAY['public.kyc_lecture_ecrire(uuid, smallint, text, jsonb)', 'SERVICE_ROLE_ONLY_EDGE',
          'PX-KYC-1 : ecrit une lecture ; la proposition est calculee ici, jamais recue ; fonction Edge piece-identite-lecture.']];
  i integer;
  f regprocedure;
BEGIN
  FOR i IN 1 .. pg_catalog.array_length(v_def, 1) LOOP
    f := v_def[i][1]::regprocedure;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
      'F86 candidate allowlist: signature=' || v_def[i][1] || '; md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
      || '; guard_type=' || v_def[i][2] || '; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-17. '
      || v_def[i][3] || ' Must-pass: supabase/tests/scenarios_px_kyc_lectures.sql.');
  END LOOP;
END;
$empreintes$;
COMMENT ON FUNCTION private.kyc_lectures_effacer_donnees() IS
  'PX-KYC-1: guard_type=SCHEDULED_ONLY; aucun droit client ; efface les DONNEES (nom, date, champs) des lectures dont la piece est echue, effacee ou absente ; rend le nombre de lectures videes. date=2026-11-17.';

DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('kyc-lectures-effacer', '47 3 * * *',
      'SELECT private.kyc_lectures_effacer_donnees()')$cron$;
  ELSE
    RAISE NOTICE 'PX-KYC-1 : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;

DO $postflight$
DECLARE
  v_f regprocedure;
  v_r private.kyc_lecture_reglages;
BEGIN
  SELECT r.* INTO v_r FROM private.kyc_lecture_reglages r WHERE r.id;
  IF v_r.actif OR v_r.modele IS NOT NULL OR pg_catalog.cardinality(v_r.genres_envoyes) <> 0 THEN
    RAISE EXCEPTION 'PX-KYC-1 : les reglages doivent etre FERMES a l installation';
  END IF;
  FOREACH v_f IN ARRAY ARRAY[
    'public.direction_kyc_lecture_etat()'::regprocedure, 'public.direction_kyc_lecture_lancer()'::regprocedure,
    'public.direction_kyc_lecture_regler(boolean, text, text[])'::regprocedure, 'public.kyc_lecture_dossier(uuid)'::regprocedure,
    'public.kyc_lectures_pretes()'::regprocedure, 'public.direction_kyc_lot_preparer(uuid[])'::regprocedure,
    'public.direction_kyc_lot_valider(uuid)'::regprocedure, 'public.kyc_lecture_file(smallint, integer)'::regprocedure,
    'public.kyc_lecture_ecrire(uuid, smallint, text, jsonb)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_f AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-KYC-1 : DEFINER, proprietaire ou ACL invalide pour %', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'public.kyc_lecture_file(smallint, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.kyc_lecture_ecrire(uuid, smallint, text, jsonb)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.kyc_lecture_file(smallint, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_kyc_lot_valider(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_kyc_lot_valider(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PX-KYC-1 : droits d execution inattendus';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'private.kyc_lectures', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.kyc_lectures', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.kyc_lecture_reglages', 'SELECT') THEN
    RAISE EXCEPTION 'PX-KYC-1 : une table de lecture est lisible par un role client';
  END IF;
END
$postflight$;
