-- PX-2 PRAXIS niveau B (pilote, CAHIER-PX-2-PREPARER.md, 17/11/2026) : Praxis LIT les dossiers de candidature et PREPARE des
-- propositions ; il n'execute jamais un geste. Cette migration est livree par etapes (un commit chacune) :
--   A. le reglage `donnees_reelles` (faux a l'installation, ouvert par le directeur seul, aal2, apres la publication de la politique de
--      confidentialite) et la lecture `praxis_lire` (vues fermees `candidatures` et `demandes`, sans contact, piece, photo, note, motif ni
--      montant ; le prenom dans `contenu_tiers` ; les cotes de la personne qui a emis la cle) ;
--   B. la table des propositions et `praxis_preparer` ;
--   C. les portes de la direction (lire les propositions, valider, ecarter) ;
-- Tant que `donnees_reelles` est faux : tous les outils de PX-2 refusent (`donnees_reelles_fermees`) ; les outils de PX-1 restent limites
-- au mode essai (praxis_fil_refus refuse tout fil hors liste d'essai ; praxis_annoncer refuse). Une liste d'essai non vide continue de
-- gouverner : elle borne meme quand les donnees reelles sont ouvertes.
-- AUCUNE COPIE DE LOGIQUE : la requete des gestes permis par le moteur est EXTRAITE de private.gestes_de_la_ligne dans
-- private.gestes_regles_de_la_ligne (ancre unique, empreinte verifiee) ; la liste de la direction et Praxis lisent la meme.
-- Doit suivre 20261129650000 (mode essai) ET 20261129740000 (private.gestes_de_la_ligne) : numero 20261129840000 (le 20261129660000 reserve par le
-- pilote sortirait AVANT 20261129740000 et le preflight echouerait sur une base neuve).
-- FICHIER SANS EFFACEMENT. Additif. Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM private.praxis_reglages) THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : private.praxis_reglages est vide';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                  WHERE a.attrelid = 'private.praxis_reglages'::pg_catalog.regclass AND a.attname = 'essai_fils' AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : la migration 20261129650000 (mode essai) doit etre installee avant';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'private.praxis_fil_refus(uuid,public.gender[])'::pg_catalog.regprocedure) IS DISTINCT FROM 'f1a6fc36c365bcaa908cb380c93342c6' THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : la definition de private.praxis_fil_refus n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_annoncer(text,text[],text,text,uuid)'::pg_catalog.regprocedure) IS DISTINCT FROM '4ac3531f54c5e78b396f04ade118d746' THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : la definition de public.praxis_annoncer n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'private.gestes_de_la_ligne(public.candidatures)'::pg_catalog.regprocedure) IS DISTINCT FROM 'ca5f643cdb0a1dca111f76e2311bc6db' THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : la definition de private.gestes_de_la_ligne n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_noter_refus(text,text)'::pg_catalog.regprocedure) IS DISTINCT FROM '6ab414eb52bb5b11f23829d0d8a0b858' THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : la definition de public.praxis_noter_refus n''est pas celle attendue ; rien n''est modifie';
  END IF;
END
$preflight$;

-- A.1 Le reglage.
ALTER TABLE private.praxis_reglages ADD COLUMN donnees_reelles boolean NOT NULL DEFAULT false;

CREATE FUNCTION public.direction_praxis_regler_donnees_reelles(p_ouvert boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_ouvert IS NULL THEN
    RAISE EXCEPTION 'reglage invalide : vrai ou faux' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_reglages SET donnees_reelles = p_ouvert, modifie_par = auth.uid(), modifie_le = pg_catalog.clock_timestamp()
   WHERE id;
  PERFORM public.log_sensitive_access('praxis_regle_donnees_reelles', 'private.praxis_reglages', 'praxis',
    pg_catalog.jsonb_build_object('donneesReelles', p_ouvert));
  RETURN pg_catalog.jsonb_build_object('donneesReelles', p_ouvert);
END;
$f$;

-- A.2 L'extraction des gestes du moteur, puis les trois fonctions retouchees (empreintes verifiees plus haut).
CREATE FUNCTION private.gestes_regles_de_la_ligne(c public.candidatures)
RETURNS text[]
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  -- Les gestes que la regle du moteur permet depuis l'etat de la ligne, pour l'auteur « direction » (extrait de
  -- private.gestes_de_la_ligne, PX-2 : une seule logique pour la liste de la direction et pour Praxis, jamais une copie).
  SELECT coalesce(pg_catalog.array_agg(g.geste ORDER BY g.geste), ARRAY[]::text[])
    FROM (SELECT DISTINCT r.geste
            FROM private.candidature_gestes_regles r
           WHERE 'direction' = ANY (r.auteurs)
             -- Prefiltre sur deux conditions que la regle exige toujours (etape et issue) : le moteur ne
             -- decide que pour les regles restantes ; la decision reste la sienne.
             AND c.etape = ANY (r.etapes) AND c.issue = ANY (r.issues)
             AND (private.candidature_regle(c, r.geste, 'direction', NULL, false)).geste IS NOT NULL) g;
$f$;

CREATE OR REPLACE FUNCTION private.gestes_de_la_ligne(c candidatures)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_direction boolean;
  v_cote boolean;
  v_noms text[];
BEGIN
  SELECT true,
         coalesce(l.genre IS NOT NULL AND (l.super_admin OR c.genre = l.genre OR c.type_code IN ('famille', 'eleve_adulte')),
                  false)
    INTO v_direction, v_cote
    FROM private.cand_lecteur() l
   LIMIT 1;
  v_direction := coalesce(v_direction, false);
  IF v_direction AND NOT v_cote THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Les gestes que la regle du moteur permet depuis l'etat de la ligne.
  v_noms := private.gestes_regles_de_la_ligne(c);

  -- Un porteur de mission : seulement les gestes COCHES de sa mission, dans son perimetre.
  IF NOT v_direction THEN
    SELECT coalesce(pg_catalog.array_agg(n ORDER BY n), ARRAY[]::text[])
      INTO v_noms
      FROM pg_catalog.unnest(v_noms) n
     WHERE private.mission_droit_dossier(c.id, n);
  END IF;

  -- « clore_complement » : la variante 2 de demander_complement (Salle de verification) quand un complement court.
  IF (private.candidature_regle(c, 'demander_complement', 'direction', 2::smallint, false)).geste IS NOT NULL
     AND pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0
     AND (v_direction OR private.mission_droit_dossier(c.id, 'demander_complement')) THEN
    v_noms := v_noms || 'clore_complement'::text;
  END IF;

  RETURN pg_catalog.to_jsonb(ARRAY(SELECT n FROM pg_catalog.unnest(v_noms) n ORDER BY n));
END;
$function$;

CREATE OR REPLACE FUNCTION private.praxis_fil_refus(p_fil uuid, p_cotes gender[])
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  f public.com_fils%ROWTYPE;
BEGIN
  -- MODE ESSAI (PX-4) : quand le directeur a nomme des conversations d'essai, TOUT autre fil, existant ou non, est refuse avant meme
  -- d'etre lu (aucune fuite d'existence). Vide = pas de mode essai.
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0
     AND NOT coalesce(p_fil = ANY (private.praxis_essai()), false) THEN
    RETURN 'hors_essai';
  END IF;
  -- PX-2 : sans liste d'essai, Praxis ne lit un fil reel que si le directeur a ouvert les donnees reelles (apres la publication de la
  -- politique de confidentialite). Faux a l'installation.
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0
     AND NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    RETURN 'donnees_reelles_fermees';
  END IF;
  SELECT x.* INTO f FROM public.com_fils x WHERE x.id = p_fil;
  IF NOT FOUND THEN RETURN 'fil_inconnu'; END IF;
  IF f.partie_b_nature IS DISTINCT FROM 'equipe' THEN RETURN 'hors_academie'; END IF;
  IF NOT (f.type_objet = ANY (private.praxis_types_fil()))
     OR (f.type_objet = 'dossier' AND f.partie_a_nature IS DISTINCT FROM 'foyer') THEN
    RETURN 'type_ferme';
  END IF;
  IF f.partie_a_nature = 'profil' AND private.com_est_mineur(f.partie_a_id) THEN RETURN 'mineur'; END IF;
  IF f.partie_a_nature = 'foyer' AND EXISTS (
       SELECT 1 FROM public.profiles g
        WHERE g.household_id = f.partie_a_id AND g.role = 'guardian'::public.app_role AND g.deleted_at IS NULL
          AND private.com_est_mineur(g.id)) THEN
    RETURN 'mineur';
  END IF;
  IF EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = f.id AND private.com_est_mineur(m.auteur_id)) THEN
    RETURN 'mineur';
  END IF;
  IF NOT private.praxis_fil_dans_cotes(f.id, p_cotes) THEN RETURN 'cote'; END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.praxis_annoncer(p_cle text, p_publics text[], p_titre text, p_texte text, p_cle_idempotence uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_titre text := pg_catalog.btrim(coalesce(p_titre, ''));
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_publics text[];
  v_cotes public.gender[];
  v_praxis uuid := private.praxis_profil();
  v_existante record;
  v_r jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_cle_idempotence IS NULL OR p_publics IS NULL OR pg_catalog.cardinality(p_publics) NOT BETWEEN 1 AND 10
     OR v_texte = '' OR pg_catalog.length(v_titre) > 120 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 3000 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- MODE ESSAI (PX-4) : tant que des conversations d'essai sont nommees, aucune annonce (elle touche des personnes reelles).
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  v_cotes := v_p.cotes;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-envois', 0));
  SELECT a.id INTO v_existante FROM public.com_annonces a
   WHERE a.auteur_id = v_praxis AND a.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'rejoue', NULL, ARRAY[v_existante.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existante.id, 'rejoue', true);
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.outil = 'annoncer' AND j.issue = 'ok'
         AND j.cree_le > pg_catalog.clock_timestamp() - interval '24 hours') >= 2 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'plafond_annonces', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_annonces');
  END IF;
  BEGIN
    v_publics := private.com_annonce_publics_valides(p_publics);
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'public', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'public');
  END;
  -- §3.4 : aucun public qui contient des mineurs. Le public `eleves` s'adresse aux eleves (dont des mineurs) : refuse,
  -- Praxis s'adresse aux familles (`familles`). Les destinataires calcules par la messagerie excluent deja tout mineur ou
  -- age inconnu (com_est_mineur) : le controle suivant est une garde de plus, jamais vrai aujourd'hui.
  IF 'eleves' = ANY (v_publics) OR EXISTS (SELECT 1 FROM private.com_annonce_personnes(v_publics, v_cotes) x
              WHERE private.com_est_mineur(x.profile_id)) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'mineur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'mineur');
  END IF;
  BEGIN
    v_r := private.com_annonce_envoyer_interne(v_praxis, v_cotes, v_publics, v_titre, v_texte, NULL, false,
                                               p_cle_idempotence);
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'refusee', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'refusee');
  END;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'annoncer', 'ok', NULL, ARRAY[(v_r ->> 'id')::uuid],
                               pg_catalog.left(v_titre || pg_catalog.chr(10) || v_texte, 3000), v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_r -> 'id', 'destinataires', v_r -> 'destinataires');
END;
$function$;

-- A.2 bis : praxis_noter_refus connait les deux outils de plus (la note d'un refus de parametre, M4).
CREATE OR REPLACE FUNCTION public.praxis_noter_refus(p_cle text, p_outil text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cle_id IS NULL OR v_p.cause_interne IN ('cle_revoquee', 'cle_expiree', 'emetteur_invalide', 'emetteur_sans_cote') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  IF p_outil IS NULL OR p_outil NOT IN ('etat', 'boite', 'fil', 'ecrire', 'annoncer', 'calendrier_lire',
                                        'calendrier_ajouter', 'rendre_compte', 'lire', 'preparer') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, p_outil, 'parametre', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$function$;

-- A.3 Les gestes que Praxis peut PREPARER pour une ligne : ceux que le moteur permet (la meme liste que celle de la direction), dans les
-- trois gestes de la liste fermee de Praxis, et seulement dans les COTES de la personne qui a emis la cle (AR-7 I2).
CREATE FUNCTION private.praxis_gestes_ligne(c public.candidatures, p_cotes public.gender[])
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT CASE WHEN c.genre = ANY (p_cotes)
              THEN pg_catalog.to_jsonb(ARRAY(SELECT g FROM pg_catalog.unnest(private.gestes_regles_de_la_ligne(c)) g
                                              WHERE g IN ('admettre_verifications', 'demander_complement', 'planifier_entretien')
                                              ORDER BY g))
              ELSE '[]'::jsonb END;
$f$;

-- A.4 praxis_lire : une vue prise dans une liste FERMEE (`candidatures`, `demandes`), des filtres fermes, 50 lignes au plus. Aucune requete
-- libre. Jamais de courriel, de telephone, de piece, de photo, de note d'entretien, de motif de refus ni de montant (R5). Le prenom, seul
-- texte de tiers, sort dans `contenu_tiers`. `demandes` : des COMPTEURS par population et par etape, sans une ligne (les demandes
-- d'admission d'enfants ne rendent que des compteurs, SECURITE-PRAXIS §3.6).
CREATE FUNCTION public.praxis_lire(p_cle text, p_vue text, p_filtre jsonb DEFAULT '{}'::jsonb, p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_inconnues text;
  v_etape text;
  v_etat text;
  v_langue text;
  v_min integer;
  v_lignes jsonb;
  v_total integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_vue IS NULL OR p_vue NOT IN ('candidatures', 'demandes') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50
     OR pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ',') INTO v_inconnues
    FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
   WHERE k.cle <> ALL (ARRAY['etape', 'etat', 'langue', 'attente_min_jours']);
  IF v_inconnues IS NOT NULL
     OR coalesce((SELECT pg_catalog.bool_or(pg_catalog.jsonb_typeof(e.value) <>
                         CASE WHEN e.key = 'attente_min_jours' THEN 'number' ELSE 'string' END)
                    FROM pg_catalog.jsonb_each(v_filtre) e), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_etape := v_filtre ->> 'etape';
  v_etat := v_filtre ->> 'etat';
  v_langue := v_filtre ->> 'langue';
  v_min := (v_filtre ->> 'attente_min_jours')::numeric::integer;
  IF (v_etape IS NOT NULL AND v_etape NOT IN ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
                                                'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_langue IS NOT NULL AND v_langue !~ '^[a-z]{2,8}$')
     OR (v_min IS NOT NULL AND v_min NOT BETWEEN 0 AND 365) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;

  IF p_vue = 'demandes' THEN
    SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('population', x.type_code, 'etape', x.etape, 'nombre', x.n)
                                         ORDER BY x.type_code, x.etape), '[]'::jsonb)
      INTO v_lignes
      FROM (SELECT c.type_code, c.etape, pg_catalog.count(*)::integer AS n
              FROM public.candidatures c
             WHERE c.type_code IN ('famille', 'eleve_adulte') AND c.issue = 'en_cours'
               AND (v_etape IS NULL OR c.etape = v_etape)
             GROUP BY c.type_code, c.etape) x;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'ok', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('vue', 'demandes', 'compteurs', v_lignes);
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'reference', f.reference,
           'cote', f.genre,
           'langue', f.langue,
           'etape', f.etape,
           'etat', f.etat,
           'attente_jours', f.attente,
           'complement_en_cours', f.complement,
           'gestes', f.gestes,
           -- Le prenom est le seul texte d'une personne : une DONNEE, jamais un ordre.
           'contenu_tiers', pg_catalog.jsonb_build_object('prenom', f.prenom)) ORDER BY f.rang),
         '[]'::jsonb),
         coalesce(pg_catalog.max(f.total), 0)
    INTO v_lignes, v_total
    FROM (SELECT x.*, pg_catalog.row_number() OVER (ORDER BY x.derniere_activite, x.id) AS rang
            FROM (SELECT c.id, c.reference, c.genre, c.langue, c.etape, c.etat, c.derniere_activite,
                         (EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400)::integer AS attente,
                         pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0 AS complement,
                         private.praxis_gestes_ligne(c, v_p.cotes) AS gestes,
                         pg_catalog.split_part(pg_catalog.btrim(c.nom_complet), ' ', 1) AS prenom,
                         pg_catalog.count(*) OVER ()::integer AS total
                    FROM public.candidatures c
                   WHERE c.type_code = 'enseignant' AND c.issue = 'en_cours' AND c.genre = ANY (v_p.cotes)
                     AND (v_etape IS NULL OR c.etape = v_etape)
                     AND (v_etat IS NULL OR c.etat = v_etat)
                     AND (v_langue IS NULL OR c.langue = v_langue)
                     AND (v_min IS NULL
                          OR EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400 >= v_min)) x) f
   WHERE f.rang <= p_limite;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('vue', 'candidatures', 'lignes', v_lignes, 'total', v_total);
END;
$f$;

REVOKE ALL ON FUNCTION private.gestes_regles_de_la_ligne(public.candidatures), private.praxis_gestes_ligne(public.candidatures, public.gender[])
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.direction_praxis_regler_donnees_reelles(boolean), public.praxis_lire(text, text, jsonb, integer)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_regler_donnees_reelles(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.praxis_lire(text, text, jsonb, integer) TO service_role;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_regler_donnees_reelles(boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_regler_donnees_reelles(boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_regler_donnees_reelles(boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.direction_praxis_regler_donnees_reelles(boolean)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_lire(text,text,jsonb,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_lire(text,text,jsonb,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_lire(text,text,jsonb,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.praxis_lire(text,text,jsonb,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.gestes_regles_de_la_ligne(public.candidatures)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.praxis_gestes_ligne(public.candidatures,public.gender[])', 'EXECUTE')
     OR (SELECT r.donnees_reelles FROM private.praxis_reglages r) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'PRAXIS-PX2 : droits ou etat incorrects apres installation';
  END IF;
END
$postflight$;

-- ====================================================================================================================
-- B. Les propositions et praxis_preparer.
-- Praxis n'ecrit QU'UNE PROPOSITION (geste, dossier, parametres, texte pour l'humain qui valide). Il n'execute jamais le geste, n'ecrit dans
-- AUCUNE table de candidature. Le geste doit etre servi pour la ligne (la liste du moteur, dans les cotes de l'emetteur), sinon
-- `geste_non_servi`. Plafond : 50 propositions ouvertes ; une seule ouverte par (dossier, geste) ; expiration a 72 heures ; cle d'idempotence.
-- ====================================================================================================================
CREATE TABLE private.praxis_propositions (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  geste text NOT NULL CHECK (geste IN ('admettre_verifications', 'demander_complement', 'planifier_entretien')),
  -- Sans cle etrangere (aucun mot d'effacement dans ce fichier) : une proposition dont le dossier a disparu ne peut plus etre validee
  -- (la validation relit le dossier) et expire seule.
  candidature_id uuid NOT NULL,
  version_candidature integer NOT NULL,
  parametres jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(parametres) = 'object' AND pg_catalog.length(parametres::text) <= 2000),
  texte text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(texte)) BETWEEN 1 AND 1000),
  statut text NOT NULL DEFAULT 'proposee' CHECK (statut IN ('proposee', 'validee', 'ecartee', 'expiree')),
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_idempotence uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL,
  traitee_le timestamptz,
  traitee_par uuid REFERENCES public.profiles (id),
  motif_ecart text CHECK (motif_ecart IS NULL OR pg_catalog.length(motif_ecart) <= 300),
  resultat jsonb,
  UNIQUE (cle_id, cle_idempotence)
);
ALTER TABLE private.praxis_propositions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.praxis_propositions FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE UNIQUE INDEX praxis_propositions_ouverte_idx ON private.praxis_propositions (candidature_id, geste) WHERE statut = 'proposee';
CREATE INDEX praxis_propositions_statut_idx ON private.praxis_propositions (statut, expire_le);

-- Les propositions dont l'echeance est passee deviennent `expiree` (elles ne font rien sur le dossier).
CREATE FUNCTION private.praxis_propositions_expirer()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $f$
  UPDATE private.praxis_propositions SET statut = 'expiree' WHERE statut = 'proposee' AND expire_le <= pg_catalog.clock_timestamp();
$f$;

CREATE FUNCTION public.praxis_preparer(p_cle text, p_geste text, p_candidature text, p_parametres jsonb, p_texte text,
                                       p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_parametres jsonb := coalesce(p_parametres, '{}'::jsonb);
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_c public.candidatures;
  v_existante uuid;
  v_id uuid;
  v_codes text[];
  v_elements text[];
  v_inconnues text;
  v_debut_rdv timestamptz;
  v_duree integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_geste IS NULL OR p_geste NOT IN ('admettre_verifications', 'demander_complement', 'planifier_entretien')
     OR p_candidature IS NULL OR p_cle_idempotence IS NULL OR v_texte = ''
     OR pg_catalog.jsonb_typeof(v_parametres) IS DISTINCT FROM 'object' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 1000 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-propositions', 0));
  PERFORM private.praxis_propositions_expirer();
  -- Rejeu : la meme cle d'idempotence, rien d'ecrit.
  SELECT x.id INTO v_existante FROM private.praxis_propositions x
   WHERE x.cle_id = v_p.cle_id AND x.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'rejoue', NULL, ARRAY[v_existante], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existante, 'rejoue', true);
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = p_candidature FOR SHARE;
  IF NOT FOUND OR v_c.type_code <> 'enseignant' OR v_c.issue <> 'en_cours' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'candidature_inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_inconnue');
  END IF;
  IF NOT (v_c.genre = ANY (v_p.cotes)) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'cote', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'cote');
  END IF;
  IF NOT (p_geste = ANY (ARRAY(SELECT pg_catalog.jsonb_array_elements_text(private.praxis_gestes_ligne(v_c, v_p.cotes))))) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'geste_non_servi', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'geste_non_servi');
  END IF;
  -- Les parametres de chaque geste : des cles connues, des valeurs bornees, jamais un champ libre de plus.
  IF p_geste = 'admettre_verifications' THEN
    IF v_parametres <> '{}'::jsonb THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'parametre', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
    END IF;
  ELSIF p_geste = 'demander_complement' THEN
    SELECT pg_catalog.string_agg(k.cle, ',') INTO v_inconnues
      FROM pg_catalog.jsonb_object_keys(v_parametres) AS k(cle) WHERE k.cle <> ALL (ARRAY['elements', 'motif']);
    IF v_inconnues IS NOT NULL OR pg_catalog.jsonb_typeof(v_parametres -> 'elements') IS DISTINCT FROM 'array'
       OR pg_catalog.jsonb_array_length(v_parametres -> 'elements') NOT BETWEEN 1 AND 20
       OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_parametres -> 'elements') e
                   WHERE pg_catalog.jsonb_typeof(e.value) <> 'string')
       -- Le moteur exige un motif pour demander un complement : il est dit au candidat, Praxis l'ecrit, l'humain le relit.
       OR pg_catalog.jsonb_typeof(v_parametres -> 'motif') IS DISTINCT FROM 'string'
       OR pg_catalog.length(pg_catalog.btrim(v_parametres ->> 'motif')) NOT BETWEEN 1 AND 300 THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'parametre', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
    END IF;
    -- Les pieces nommees sont dans la liste fermee du moteur pour ce dossier.
    SELECT pg_catalog.array_agg(e.value #>> '{}' ORDER BY e.o) INTO v_elements
      FROM pg_catalog.jsonb_array_elements(v_parametres -> 'elements') WITH ORDINALITY AS e(value, o);
    v_codes := private.candidature_complement_codes(v_c.etape, v_c.type_code);
    IF EXISTS (SELECT 1 FROM pg_catalog.unnest(v_elements) x WHERE NOT (x = ANY (v_codes))) THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'elements_invalides', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'elements_invalides', 'permis', pg_catalog.to_jsonb(v_codes));
    END IF;
  ELSE
    SELECT pg_catalog.string_agg(k.cle, ',') INTO v_inconnues
      FROM pg_catalog.jsonb_object_keys(v_parametres) AS k(cle) WHERE k.cle <> ALL (ARRAY['debut', 'duree_minutes']);
    IF v_inconnues IS NOT NULL OR pg_catalog.jsonb_typeof(v_parametres -> 'debut') IS DISTINCT FROM 'string'
       OR pg_catalog.jsonb_typeof(v_parametres -> 'duree_minutes') IS DISTINCT FROM 'number' THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'parametre', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
    END IF;
    BEGIN
      v_debut_rdv := (v_parametres ->> 'debut')::timestamptz;
      v_duree := (v_parametres ->> 'duree_minutes')::numeric::integer;
    EXCEPTION WHEN OTHERS THEN
      v_debut_rdv := NULL;
    END;
    -- Les memes bornes que la porte publique (debut dans 5 minutes a 90 jours, duree de 15 a 120 minutes) ; les participants ne sont
    -- PAS choisis par Praxis (il ne voit aucun identifiant de personnel) : celui qui valide les nomme.
    IF v_debut_rdv IS NULL OR v_duree IS NULL OR v_duree NOT BETWEEN 15 AND 120
       OR v_debut_rdv < pg_catalog.clock_timestamp() + interval '5 minutes'
       OR v_debut_rdv > pg_catalog.clock_timestamp() + interval '90 days' THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'parametre', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
    END IF;
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_propositions x WHERE x.statut = 'proposee') >= 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'plafond_propositions', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_propositions');
  END IF;
  IF EXISTS (SELECT 1 FROM private.praxis_propositions x
              WHERE x.candidature_id = v_c.id AND x.geste = p_geste AND x.statut = 'proposee') THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'deja_proposee', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'deja_proposee');
  END IF;
  INSERT INTO private.praxis_propositions (geste, candidature_id, version_candidature, parametres, texte, cle_id, emise_par,
                                           cle_idempotence, expire_le)
  VALUES (p_geste, v_c.id, v_c.version, v_parametres, v_texte, v_p.cle_id, v_p.emise_par, p_cle_idempotence,
          pg_catalog.clock_timestamp() + interval '72 hours')
  RETURNING id INTO v_id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'ok', NULL, ARRAY[v_id], v_texte, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_id, 'expire_dans_heures', 72);
END;
$f$;

REVOKE ALL ON FUNCTION private.praxis_propositions_expirer(), public.praxis_preparer(text, text, text, jsonb, text, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.praxis_preparer(text, text, text, jsonb, text, uuid) TO service_role;

DO $postflight_b$
BEGIN
  IF NOT pg_catalog.has_function_privilege('service_role', 'public.praxis_preparer(text,text,text,jsonb,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.praxis_preparer(text,text,text,jsonb,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.praxis_preparer(text,text,text,jsonb,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.praxis_preparer(text,text,text,jsonb,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'private.praxis_propositions_expirer()', 'EXECUTE')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.praxis_propositions'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'PRAXIS-PX2 (B) : droits ou RLS incorrects apres installation';
  END IF;
END
$postflight_b$;

-- ====================================================================================================================
-- C. Les portes de la direction : lire les propositions, valider, ecarter.
-- VALIDER execute le geste par la PORTE PUBLIQUE existante, sous l'identite de la personne qui valide (auth.uid() est la sienne, jamais
-- celle de Praxis) : le moteur decide comme pour un geste fait a la main, avec la version du dossier que Praxis a vue ; un dossier qui a
-- change depuis est refuse par le moteur, avec sa phrase. Un geste refuse laisse la proposition ouverte (on peut l'ecarter). Ecarter, ou
-- laisser expirer, ne fait rien sur le dossier. Les deux portes d'ecriture exigent la double verification (aal2) ; la lecture non.
-- ====================================================================================================================
CREATE FUNCTION public.direction_praxis_propositions(p_filtre text DEFAULT 'ouvertes')
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF p_filtre IS NULL OR p_filtre NOT IN ('ouvertes', 'toutes') THEN
    RAISE EXCEPTION 'filtre invalide : ouvertes ou toutes' USING ERRCODE = '22023';
  END IF;
  RETURN (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', x.id, 'geste', x.geste, 'reference', c.reference, 'nom', c.nom_complet,
      'versionProposee', x.version_candidature, 'versionActuelle', c.version,
      'parametres', x.parametres, 'texte', x.texte,
      'statut', CASE WHEN x.statut = 'proposee' AND x.expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE x.statut END,
      'creeLe', x.cree_le, 'expireLe', x.expire_le, 'traiteeLe', x.traitee_le, 'motifEcart', x.motif_ecart)
      ORDER BY x.cree_le DESC, x.id), '[]'::jsonb)
    FROM (SELECT y.* FROM private.praxis_propositions y
           WHERE p_filtre = 'toutes' OR (y.statut = 'proposee' AND y.expire_le > pg_catalog.clock_timestamp())
           ORDER BY y.cree_le DESC, y.id LIMIT 100) x
    JOIN public.candidatures c ON c.id = x.candidature_id
   WHERE EXISTS (SELECT 1 FROM private.cand_lecteur() l WHERE l.super_admin OR l.genre = c.genre));
END;
$f$;

CREATE FUNCTION public.direction_praxis_valider(p_proposition uuid, p_version integer, p_cle text,
                                                p_participants uuid[] DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_pr private.praxis_propositions%ROWTYPE;
  v_r jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_proposition IS NULL OR p_version IS NULL OR p_cle IS NULL OR pg_catalog.length(p_cle) NOT BETWEEN 8 AND 100 THEN
    RAISE EXCEPTION 'validation invalide : proposition, version et cle attendues' USING ERRCODE = '22023';
  END IF;
  PERFORM private.praxis_propositions_expirer();
  SELECT x.* INTO v_pr FROM private.praxis_propositions x WHERE x.id = p_proposition FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_inconnue');
  END IF;
  IF v_pr.statut = 'validee' AND v_pr.resultat ->> 'cle' = p_cle THEN
    RETURN pg_catalog.jsonb_build_object('ok', true, 'rejoue', true, 'resultat', v_pr.resultat -> 'reponse');
  END IF;
  IF v_pr.statut <> 'proposee' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_' || v_pr.statut);
  END IF;
  IF p_version <> v_pr.version_candidature THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_perimee');
  END IF;
  IF v_pr.geste = 'demander_complement' THEN
    v_r := public.demander_complement_candidat(v_pr.candidature_id,
             ARRAY(SELECT e.value #>> '{}' FROM pg_catalog.jsonb_array_elements(v_pr.parametres -> 'elements') WITH ORDINALITY AS e(value, o)
                    ORDER BY e.o),
             v_pr.parametres ->> 'motif', v_pr.version_candidature, p_cle);
  ELSIF v_pr.geste = 'planifier_entretien' THEN
    v_r := public.planifier_entretien(v_pr.candidature_id, (v_pr.parametres ->> 'debut')::timestamptz,
             (v_pr.parametres ->> 'duree_minutes')::numeric::integer, coalesce(p_participants, '{}'::uuid[]),
             v_pr.version_candidature, p_cle);
  ELSE
    v_r := public.admettre_salle_verification(v_pr.candidature_id, v_pr.version_candidature, p_cle);
  END IF;
  -- Le moteur a refuse : la proposition reste ouverte, le dossier n'a pas bouge, la phrase du moteur est rendue telle quelle.
  IF v_r ? 'erreur' THEN
    RETURN v_r || pg_catalog.jsonb_build_object('proposition', p_proposition);
  END IF;
  UPDATE private.praxis_propositions
     SET statut = 'validee', traitee_le = pg_catalog.clock_timestamp(), traitee_par = auth.uid(),
         resultat = pg_catalog.jsonb_build_object('cle', p_cle, 'reponse', v_r)
   WHERE id = p_proposition;
  PERFORM public.log_sensitive_access('praxis_proposition_validee', 'private.praxis_propositions', 'praxis',
    pg_catalog.jsonb_build_object('proposition', p_proposition, 'geste', v_pr.geste));
  RETURN pg_catalog.jsonb_build_object('ok', true, 'resultat', v_r);
END;
$f$;

CREATE FUNCTION public.direction_praxis_ecarter(p_proposition uuid, p_motif text, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_pr private.praxis_propositions%ROWTYPE;
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_proposition IS NULL OR p_cle IS NULL OR pg_catalog.length(v_motif) > 300 THEN
    RAISE EXCEPTION 'ecart invalide : proposition et cle attendues, motif de 300 signes au plus' USING ERRCODE = '22023';
  END IF;
  PERFORM private.praxis_propositions_expirer();
  SELECT x.* INTO v_pr FROM private.praxis_propositions x WHERE x.id = p_proposition FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_inconnue');
  END IF;
  IF v_pr.statut = 'ecartee' THEN
    RETURN pg_catalog.jsonb_build_object('ok', true, 'rejoue', true);
  END IF;
  IF v_pr.statut <> 'proposee' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_' || v_pr.statut);
  END IF;
  UPDATE private.praxis_propositions
     SET statut = 'ecartee', traitee_le = pg_catalog.clock_timestamp(), traitee_par = auth.uid(), motif_ecart = nullif(v_motif, '')
   WHERE id = p_proposition;
  PERFORM public.log_sensitive_access('praxis_proposition_ecartee', 'private.praxis_propositions', 'praxis',
    pg_catalog.jsonb_build_object('proposition', p_proposition, 'geste', v_pr.geste));
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$f$;

REVOKE ALL ON FUNCTION public.direction_praxis_propositions(text), public.direction_praxis_valider(uuid, integer, text, uuid[]),
  public.direction_praxis_ecarter(uuid, text, uuid) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_propositions(text), public.direction_praxis_valider(uuid, integer, text, uuid[]),
  public.direction_praxis_ecarter(uuid, text, uuid) TO authenticated;

DO $postflight_c$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_propositions(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_valider(uuid,integer,text,uuid[])', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_ecarter(uuid,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_propositions(text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_valider(uuid,integer,text,uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_ecarter(uuid,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_valider(uuid,integer,text,uuid[])', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.direction_praxis_valider(uuid,integer,text,uuid[])', 'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS-PX2 (C) : droits incorrects apres installation';
  END IF;
END
$postflight_c$;
