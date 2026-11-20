-- PRAXIS-DOSSIER-COMPLET (PX-4, ordre du directeur du 20/11/2026 : « lire tout le contexte d'un dossier [...] trouver les pepites parmi les
-- pepites ; s'il le faut, ouvrir le dialogue avec eux [...] sans harceler ni mettre la pression »).
-- Cahier : docs/current/BUREAU-EQUIPE/PRAXIS/CAHIER-PX-4-DOSSIER-COMPLET.md. Bati sur PX-3 (20261130100000), memes conventions, memes gardes.
--
-- LIVRE ICI :
--   1. LIRE TOUT LE DOSSIER : `praxis_dossier(cle, CAND-...)` : reponses du questionnaire (liste blanche de champs), autres competences,
--      cote, langue, etape, etat, anciennete, historique (types et dates, JAMAIS le motif interne), ce qui manque (private.praxis_dossier_manques,
--      PX-3), l'etat de l'entretien (jamais ses notes), le rangement et l'impression de Praxis, le nombre de messages. 120 lectures par heure.
--   2. NOTER UNE IMPRESSION : table private.praxis_impressions (par ajout, la derniere fait foi), outil `praxis_noter_impression`
--      (cinq criteres de qualite ; un CONTEXTE ouvert : elements {theme, constat, source, effet}, « empathie mesuree », 20/11 ; une
--      SYNTHESE : utile pour, situation, reserves, a voir en video),
--      lecture `direction_praxis_impressions`. Une impression n'est jamais une decision et ne declenche rien.
--   3. OUVRIR LE DIALOGUE : `praxis_boite_candidats` (filtres a_approfondir, sans_nouvelles, a_feliciter, a_interroger) et `praxis_ouvrir`
--      (raison question, relance, felicitations, et l'ENTRETIEN ECRIT : entretien_ecrit, relance_entretien), table private.praxis_ouvertures. Toutes les limites sont ici, dans private.praxis_ouverture_refus.
--      `praxis_ecrire` est RESSERRE pour les seules conversations de candidature (voir plus bas).
--   4. CHERCHER LES MEILLEURS : `praxis_lire` accepte les filtres etiquette, sans_impression, ijaza, riwaya, langue_explication, public et
--      le tri par note de vision ; chaque ligne rend `impression`.
--
-- MOTS D'EFFACEMENT : ZERO. Aucune contrainte reecrite (la pile `pepite` n'est PAS ajoutee aux rangements : l'etiquette suffit).
--
-- FONCTIONS EXISTANTES REMPLACEES (CREATE OR REPLACE a signature identique, droits et proprietaire conserves), apres controle de l'empreinte
-- md5(prosrc). Le corps est celui de la DERNIERE definition, recopie par pg_get_functiondef sur une base rejouee, plus le necessaire (chaque
-- ajout porte le mot PX-4) :
--   * public.praxis_lire(text, text, jsonb, integer)   <- 20261130100000 (PX-3). Appelant : l'outil `lire` du connecteur (praxis-mcp).
--   * public.praxis_ecrire(text, uuid, text, uuid)     <- 20261129910000 (PRAXIS-CANDIDATS). Appelant : l'outil `ecrire`.
--       CHANGEMENT DE COMPORTEMENT, pour les seules conversations de CANDIDATURE : sans `raison`, Praxis n'ecrit que si la personne a ecrit
--       et que la direction n'a pas repondu depuis dans la conversation (sinon `raison_requise`), et 2 messages de suite au plus (3 avant).
--       Les autres types de conversation ne changent pas.
--   * public.praxis_noter_refus(text, text)            <- 20261130100000 (PX-3). Appelant : praxis-mcp (refus de parametre).
--   * public.praxis_etat(text)                         <- 20261129600000 (socle). Appelant : l'outil `etat`. Une cle de plus dans la reponse.
-- Tout le reste est NEUF. Rien n'est allume par cette migration. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regclass('private.praxis_rangements') IS NULL OR pg_catalog.to_regclass('private.praxis_objectifs') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_dossier_manques(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_candidat_derniere_action(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_fil_refus(uuid,public.gender[])') IS NULL
     OR pg_catalog.to_regclass('public.candidature_autres_competences') IS NULL
     OR pg_catalog.to_regclass('public.candidature_dispenses_entretien') IS NULL
     OR pg_catalog.to_regclass('public.entretiens') IS NULL THEN
    RAISE EXCEPTION 'PX-4 : dependances absentes (PX-3, PRAXIS-CANDIDATS, entretiens, autres competences) ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.praxis_impressions') IS NOT NULL OR pg_catalog.to_regclass('private.praxis_ouvertures') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-4 : deja installe ; rien n''est modifie';
  END IF;
  FOR v IN SELECT * FROM (VALUES
      ('public.praxis_lire(text,text,jsonb,integer)', '85ff7182883d73d39d3bb51298b2f75b'),
      ('public.praxis_ecrire(text,uuid,text,uuid)', 'd224d33664646855a7b79a28c6dbddc3'),
      ('public.praxis_noter_refus(text,text)', 'd13a327123e66d50ccc51c617ba8d1ee'),
      ('public.praxis_etat(text)', 'bf52d55ef6b922b12fbf92afa5022529')) AS t(f, md5) LOOP
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v.f::pg_catalog.regprocedure) IS DISTINCT FROM v.md5 THEN
      RAISE EXCEPTION 'PX-4 : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
END
$preflight$;

-- ====================================================================================================================
-- 0. AIDES PRIVEES.
-- ====================================================================================================================

-- Un dossier que Praxis peut OUVRIR en entier : candidature d'enseignant en cours, hors pause, non restreinte, majorite ATTESTEE, du
-- cote de la cle, et dont le compte (s'il existe) n'est pas celui d'un mineur. Tout le reste est ferme, avec la meme reponse.
CREATE FUNCTION private.praxis_dossier_ouvert(c public.candidatures, p_cotes public.gender[])
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce(c.id IS NOT NULL AND c.type_code = 'enseignant' AND c.issue = 'en_cours' AND NOT c.en_pause AND NOT c.restreinte
                  AND c.majorite_declaree IS TRUE AND c.genre = ANY (p_cotes)
                  AND (c.profile_id IS NULL OR NOT private.com_est_mineur(c.profile_id)), false);
$f$;

-- Les dernieres reponses envoyees du questionnaire (une candidature peut en avoir plusieurs versions : la plus recente fait foi).
-- Revue PX-4 : JAMAIS un brouillon (ce que le candidat n'a pas encore envoye), comme le controle d'admission (cand_l2a2).
CREATE FUNCTION private.praxis_reponses(p_candidature uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT r.reponses FROM public.candidature_reponses r WHERE r.candidature_id = p_candidature AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1;
$f$;

-- L'heure qu'il est (0 a 23) dans un fuseau IANA ; NULL si le fuseau est absent ou inconnu de Postgres.
CREATE FUNCTION private.praxis_heure_locale(p_fuseau text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
BEGIN
  IF p_fuseau IS NULL OR pg_catalog.btrim(p_fuseau) = '' THEN RETURN NULL; END IF;
  RETURN EXTRACT(hour FROM pg_catalog.clock_timestamp() AT TIME ZONE p_fuseau)::integer;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$f$;

-- La conversation de candidature d'un dossier (la conversation standard entre le candidat et l'academie), ou NULL.
CREATE FUNCTION private.praxis_fil_candidature(c public.candidatures)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT f.id FROM public.com_fils f
   WHERE f.type_objet = 'candidature' AND f.objet_id = c.id AND f.partie_a_nature = 'profil' AND f.partie_a_id = c.profile_id
     AND f.partie_b_nature = 'equipe';
$f$;

-- La decision POSITIVE de la direction que Praxis peut feliciter : l'admission en salle de verification (geste admettre_verifications,
-- auteur direction) des 72 dernieres heures. L'accueil final (etape confirmee) n'en fait PAS partie : la conversation de candidature est
-- alors fermee (private.praxis_fil_refus, private.com_paires). Jamais un refus, un retrait ni une pause : ces gestes ne sont pas lus ici.
CREATE FUNCTION private.praxis_decision_positive(p_candidature uuid)
RETURNS TABLE (evenement_id bigint, decidee_le timestamptz)
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT e.id, e.cree_le FROM public.candidature_evenements e
   WHERE e.candidature_id = p_candidature AND e.details ->> 'geste' = 'admettre_verifications' AND e.details ->> 'auteur' = 'direction'
     AND e.cree_le > pg_catalog.clock_timestamp() - interval '72 hours'
   ORDER BY e.cree_le DESC, e.id DESC LIMIT 1;
$f$;

-- ====================================================================================================================
-- 1. LES IMPRESSIONS. Par AJOUT : la ligne precedente cesse d'etre courante, rien n'est efface. Sans cle etrangere vers candidatures
-- (comme private.praxis_rangements). Le texte est ECRIT PAR PRAXIS a partir des faits lus (800 signes au plus).
-- ====================================================================================================================
CREATE TABLE private.praxis_impressions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL,
  etiquette text NOT NULL CHECK (etiquette IN ('pepite', 'solide', 'a_creuser', 'reserve')),
  maitrise smallint CHECK (maitrise BETWEEN 1 AND 5),
  pedagogie smallint CHECK (pedagogie BETWEEN 1 AND 5),
  vision smallint CHECK (vision BETWEEN 1 AND 5),
  comportement smallint CHECK (comportement BETWEEN 1 AND 5),
  disponibilite smallint CHECK (disponibilite BETWEEN 1 AND 5),
  -- LE CONTEXTE (directeur, 20/11/2026, « empathie mesuree » : « c'est toi l'IA, creuse les scenarios ») : une liste OUVERTE d'elements
  -- {theme, constat, source, effet}, 12 au plus. Des faits a peser entre candidats de meme valeur, jamais une note de la personne ; ils ne
  -- s'additionnent pas aux cinq criteres. Les themes sont libres ; chaque element cite sa source ; effet : atout, risque, a_verifier.
  contexte jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (pg_catalog.jsonb_typeof(contexte) = 'array' AND pg_catalog.jsonb_array_length(contexte) <= 12),
  -- LA SYNTHESE (entretien ecrit) : utile_pour, situation, reserves, video (a voir en video : oui ou non), video_pourquoi. Facultative.
  synthese jsonb CHECK (synthese IS NULL OR pg_catalog.jsonb_typeof(synthese) = 'object'),
  texte text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(texte)) BETWEEN 1 AND 800 AND pg_catalog.length(texte) <= 800),
  confiance text NOT NULL CHECK (confiance IN ('faible', 'moyenne', 'forte')),
  courant boolean NOT NULL DEFAULT true,
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_idempotence uuid NOT NULL,
  notee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  UNIQUE (cle_id, cle_idempotence)
);
ALTER TABLE private.praxis_impressions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.praxis_impressions FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE UNIQUE INDEX praxis_impressions_courant_idx ON private.praxis_impressions (candidature_id) WHERE courant;
CREATE INDEX praxis_impressions_recents_idx ON private.praxis_impressions (notee_le DESC);
ALTER TABLE private.praxis_impressions OWNER TO postgres;

-- Ce qu'une impression ne doit JAMAIS invoquer (directeur, 20/11/2026 : le contexte de vie est un FAIT a peser, jamais un jugement sur la
-- personne). Le nom d'un pays est ADMIS (un fait de contexte : reseau, versement ; jamais un motif). Restent refuses : les mots qui visent
-- l'ethnie, la couleur, l'apparence, le handicap, la sante, la religion pratiquee (courant, ecole), l'opinion, la situation de couple
-- (la charge de famille dite par la personne est un theme de contexte admis), et toute ACCUSATION (terroriste, criminel, fraudeur, en francais, en anglais et en arabe) : un risque
-- se nomme « conformite du versement a examiner ». Le serveur ne comprend pas un texte : il refuse des MOTS ; une periphrase passe, la
-- regle reste donc d'abord dans la description de l'outil. Rend le premier mot trouve, ou NULL.
CREATE FUNCTION private.praxis_impression_mot_interdit(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $f$
  SELECT coalesce(
    (pg_catalog.regexp_match(pg_catalog.lower(coalesce(p_texte, '')),
      '\m(ethni[a-zé]*|races?|racial[a-z]*|couleur de peau|skin colou?r|apparence[a-z]*|appearance|physique[a-z]*|beaut[a-zé]*|laide?s?'
      || '|handicap[a-zé]*|infirm[a-zé]*|disab[a-z]*|enceinte|grossesse|pregnan[a-z]*|mari[ée]e?s?|married|c[ée]libataires?|divorc[a-zé]*'
      || '|veuf|veuve|maladi[a-z]*|malades?|sant[ée]|health|illness|opinions?|politique[a-z]*|political|salafi[a-z]*|soufi[a-z]*|sufi[a-z]*'
      || '|chiite[a-z]*|shia|sunnite[a-z]*|wahhabi[a-z]*|secte[a-z]*|madhhab|madhab'
      || '|terroris[a-z]*|criminel[a-z]*|criminals?|fraudeu[a-z]*|fraudsters?|escroc[a-z]*|scammers?|d[ée]linquan[a-z]*|extr[ée]mis[a-z]*)\M'))[1],
    (pg_catalog.regexp_match(coalesce(p_texte, ''), '(إرهاب|ارهاب|مجرم|محتال|نصاب|متطرف)'))[1]);
$f$;

CREATE FUNCTION public.praxis_noter_impression(p_cle text, p_candidature text, p_etiquette text, p_notes jsonb, p_contexte jsonb,
                                               p_synthese jsonb, p_texte text, p_confiance text, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_notes jsonb := coalesce(p_notes, '{}'::jsonb);
  v_ctx jsonb := coalesce(p_contexte, '[]'::jsonb);
  v_syn jsonb := p_synthese;
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_c public.candidatures;
  v_existant bigint;
  v_courant private.praxis_impressions%ROWTYPE;
  v_n smallint[];
  v_mot text;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_candidature IS NULL OR p_cle_idempotence IS NULL OR v_texte = ''
     OR p_etiquette IS NULL OR p_etiquette NOT IN ('pepite', 'solide', 'a_creuser', 'reserve')
     OR p_confiance IS NULL OR p_confiance NOT IN ('faible', 'moyenne', 'forte')
     OR pg_catalog.jsonb_typeof(v_notes) IS DISTINCT FROM 'object'
     -- Cinq criteres connus, chacun facultatif, chacun un ENTIER de 1 a 5 ; aucune autre cle.
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(v_notes) e
                 WHERE e.key <> ALL (ARRAY['maitrise', 'pedagogie', 'vision', 'comportement', 'disponibilite'])
                    OR pg_catalog.jsonb_typeof(e.value) <> 'number'
                    OR (e.value #>> '{}') !~ '^[1-5]$')
     -- Le contexte : une liste (12 au plus) d'objets {theme, constat, source, effet}, les quatre cles et elles seules, des textes bornes ;
     -- le theme est LIBRE, l'effet est dans une liste fermee, la source est obligatoire (quelle reponse du dossier, quel message).
     OR pg_catalog.jsonb_typeof(v_ctx) IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_array_length(CASE WHEN pg_catalog.jsonb_typeof(v_ctx) = 'array' THEN v_ctx ELSE '[]'::jsonb END) > 12
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(CASE WHEN pg_catalog.jsonb_typeof(v_ctx) = 'array' THEN v_ctx ELSE '[]'::jsonb END) x(e)
                 WHERE pg_catalog.jsonb_typeof(x.e) <> 'object'
                    OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(CASE WHEN pg_catalog.jsonb_typeof(x.e) = 'object' THEN x.e ELSE '{}'::jsonb END)) <> 4
                    OR pg_catalog.jsonb_typeof(x.e -> 'theme') IS DISTINCT FROM 'string' OR pg_catalog.jsonb_typeof(x.e -> 'constat') IS DISTINCT FROM 'string'
                    OR pg_catalog.jsonb_typeof(x.e -> 'source') IS DISTINCT FROM 'string' OR pg_catalog.jsonb_typeof(x.e -> 'effet') IS DISTINCT FROM 'string'
                    OR pg_catalog.length(pg_catalog.btrim(x.e ->> 'theme')) NOT BETWEEN 1 AND 60
                    OR pg_catalog.length(pg_catalog.btrim(x.e ->> 'constat')) NOT BETWEEN 1 AND 200
                    OR pg_catalog.length(pg_catalog.btrim(x.e ->> 'source')) NOT BETWEEN 1 AND 120
                    OR (x.e ->> 'effet') NOT IN ('atout', 'risque', 'a_verifier'))
     -- La synthese : cinq cles connues, toutes facultatives ; quatre textes de 200 signes au plus, `video` est un booleen.
     OR (v_syn IS NOT NULL AND (pg_catalog.jsonb_typeof(v_syn) <> 'object' OR EXISTS (
           SELECT 1 FROM pg_catalog.jsonb_each(CASE WHEN pg_catalog.jsonb_typeof(v_syn) = 'object' THEN v_syn ELSE '{}'::jsonb END) e
            WHERE NOT ((e.key IN ('utile_pour', 'situation', 'reserves', 'video_pourquoi') AND pg_catalog.jsonb_typeof(e.value) = 'string'
                        AND pg_catalog.length(pg_catalog.btrim(e.value #>> '{}')) BETWEEN 1 AND 200)
                       OR (e.key = 'video' AND pg_catalog.jsonb_typeof(e.value) = 'boolean'))))) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 800 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  IF v_syn = '{}'::jsonb THEN v_syn := NULL; END IF;
  -- Le meme filtre de mots sur le texte, sur chaque element du contexte et sur la synthese.
  v_mot := private.praxis_impression_mot_interdit(v_texte || ' ' || coalesce((SELECT pg_catalog.string_agg(
             (x.e ->> 'theme') || ' ' || (x.e ->> 'constat') || ' ' || (x.e ->> 'source'), ' ') FROM pg_catalog.jsonb_array_elements(v_ctx) x(e)), '')
           || ' ' || coalesce((SELECT pg_catalog.string_agg(e.value #>> '{}', ' ') FROM pg_catalog.jsonb_each(coalesce(v_syn, '{}'::jsonb)) e
                                WHERE e.key <> 'video'), ''));
  IF v_mot IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'texte_interdit', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'texte_interdit', 'mot', v_mot);
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-impressions', 0));
  -- Rejeu : la meme cle d'idempotence, rien d'ecrit.
  SELECT x.id INTO v_existant FROM private.praxis_impressions x WHERE x.cle_id = v_p.cle_id AND x.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'rejoue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'rejoue', true);
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = p_candidature;
  -- Un dossier inconnu, ferme (pause, restriction, refus, retrait, majorite non attestee) OU DE L'AUTRE COTE : la meme reponse.
  IF NOT FOUND OR NOT private.praxis_dossier_ouvert(v_c, v_p.cotes) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'candidature_inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_inconnue');
  END IF;
  v_n := ARRAY[(v_notes ->> 'maitrise')::smallint, (v_notes ->> 'pedagogie')::smallint, (v_notes ->> 'vision')::smallint,
               (v_notes ->> 'comportement')::smallint, (v_notes ->> 'disponibilite')::smallint];
  SELECT x.* INTO v_courant FROM private.praxis_impressions x WHERE x.candidature_id = v_c.id AND x.courant;
  -- La meme impression, mot pour mot : rien a ecrire.
  IF FOUND AND v_courant.etiquette = p_etiquette AND v_courant.confiance = p_confiance AND v_courant.texte = v_texte
     AND v_courant.contexte = v_ctx AND v_courant.synthese IS NOT DISTINCT FROM v_syn
     AND ARRAY[v_courant.maitrise, v_courant.pedagogie, v_courant.vision, v_courant.comportement, v_courant.disponibilite]
         IS NOT DISTINCT FROM v_n THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'inchange', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'inchange', true, 'etiquette', p_etiquette);
  END IF;
  -- Plafond : 120 impressions ecrites par heure glissante, toutes cles confondues.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_impressions x
       WHERE x.notee_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 120 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'plafond_impressions', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_impressions');
  END IF;
  UPDATE private.praxis_impressions SET courant = false WHERE candidature_id = v_c.id AND courant;
  INSERT INTO private.praxis_impressions (candidature_id, etiquette, maitrise, pedagogie, vision, comportement, disponibilite, contexte,
                                          synthese, texte, confiance, cle_id, emise_par, cle_idempotence)
  VALUES (v_c.id, p_etiquette, v_n[1], v_n[2], v_n[3], v_n[4], v_n[5], v_ctx, v_syn, v_texte, p_confiance, v_p.cle_id, v_p.emise_par, p_cle_idempotence);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'noter_impression', 'ok', NULL, ARRAY[v_c.id], v_texte, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'etiquette', p_etiquette, 'etiquette_precedente', v_courant.etiquette);
END;
$f$;

-- La lecture de la direction : les impressions COURANTES des candidatures encore en cours, du cote de la direction qui lit, paginees,
-- triees par etiquette (pepite, solide, a_creuser, reserve) puis par note de vision. Meme garde que direction_praxis_rangements.
CREATE FUNCTION public.direction_praxis_impressions(p_etiquette text DEFAULT NULL, p_limite integer DEFAULT 50, p_decalage integer DEFAULT 0)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_lignes jsonb;
  v_compte jsonb;
  v_total integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF (p_etiquette IS NOT NULL AND p_etiquette NOT IN ('pepite', 'solide', 'a_creuser', 'reserve'))
     OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 OR p_decalage IS NULL OR p_decalage NOT BETWEEN 0 AND 100000 THEN
    RAISE EXCEPTION 'etiquette, limite (1 a 200) ou decalage invalide' USING ERRCODE = '22023';
  END IF;
  WITH visibles AS (
    SELECT x.*, c.reference, c.nom_complet, c.etape, c.etat, c.genre, c.en_pause,
           pg_catalog.array_position(ARRAY['pepite', 'solide', 'a_creuser', 'reserve'], x.etiquette) AS rang_etiquette
      FROM private.praxis_impressions x
      JOIN public.candidatures c ON c.id = x.candidature_id
     WHERE x.courant AND c.type_code = 'enseignant' AND c.issue = 'en_cours'
       AND EXISTS (SELECT 1 FROM private.cand_lecteur() l WHERE l.super_admin OR l.genre = c.genre)
  )
  SELECT (SELECT coalesce(pg_catalog.jsonb_object_agg(k.etiquette, k.n), '{}'::jsonb)
            FROM (SELECT v.etiquette, pg_catalog.count(*)::integer AS n FROM visibles v GROUP BY v.etiquette) k),
         (SELECT pg_catalog.count(*)::integer FROM visibles v WHERE p_etiquette IS NULL OR v.etiquette = p_etiquette),
         (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'reference', y.reference, 'nom', y.nom_complet, 'cote', y.genre, 'etape', y.etape, 'etat', y.etat,
                    'enPause', y.en_pause, 'etiquette', y.etiquette, 'confiance', y.confiance, 'texte', y.texte,
                    'notes', pg_catalog.jsonb_build_object('maitrise', y.maitrise, 'pedagogie', y.pedagogie, 'vision', y.vision,
                                                           'comportement', y.comportement, 'disponibilite', y.disponibilite),
                    -- Le contexte, a cote des notes : a valeur egale, le besoin et les risques se lisent cote a cote.
                    'contexte', y.contexte, 'synthese', y.synthese,
                    'noteeLe', y.notee_le)
                    ORDER BY y.rang_etiquette, y.vision DESC NULLS LAST, y.notee_le DESC, y.id DESC), '[]'::jsonb)
            FROM (SELECT v.* FROM visibles v WHERE p_etiquette IS NULL OR v.etiquette = p_etiquette
                   ORDER BY v.rang_etiquette, v.vision DESC NULLS LAST, v.notee_le DESC, v.id DESC LIMIT p_limite OFFSET p_decalage) y)
    INTO v_compte, v_total, v_lignes;
  RETURN pg_catalog.jsonb_build_object('impressions', v_lignes, 'total', v_total, 'parEtiquette', v_compte);
END;
$f$;

-- ====================================================================================================================
-- 2. LES OUVERTURES. Chaque message que Praxis ecrit LE PREMIER (question, relance, felicitations) laisse une ligne ici : le journal est
-- purge a douze mois et ne peut pas porter « 3 relances en tout ». Par ajout seul, jamais modifiee.
-- ====================================================================================================================
CREATE TABLE private.praxis_ouvertures (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL,
  raison text NOT NULL CHECK (raison IN ('question', 'relance', 'felicitations', 'entretien_ecrit', 'relance_entretien')),
  fil_id uuid NOT NULL,
  message_id uuid NOT NULL,
  -- La decision felicitee (public.candidature_evenements.id) : une seule felicitation par decision.
  evenement_id bigint,
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_idempotence uuid NOT NULL,
  ouverte_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  UNIQUE (cle_id, cle_idempotence),
  CONSTRAINT praxis_ouvertures_evenement CHECK ((raison = 'felicitations') = (evenement_id IS NOT NULL))
);
ALTER TABLE private.praxis_ouvertures ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.praxis_ouvertures FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE INDEX praxis_ouvertures_candidature_idx ON private.praxis_ouvertures (candidature_id, ouverte_le DESC);
CREATE INDEX praxis_ouvertures_recents_idx ON private.praxis_ouvertures (ouverte_le DESC);
CREATE UNIQUE INDEX praxis_ouvertures_une_felicitation_idx ON private.praxis_ouvertures (evenement_id) WHERE evenement_id IS NOT NULL;
ALTER TABLE private.praxis_ouvertures OWNER TO postgres;

-- TOUTES les limites du dialogue ouvert par Praxis, en un seul endroit, lues par `praxis_boite_candidats` (pour dire `permis`) et par
-- `praxis_ouvrir` (pour refuser). Rend le code du refus, ou NULL si l'ouverture est permise MAINTENANT. Dans l'ordre :
--   candidature_inconnue  dossier ferme (private.praxis_dossier_ouvert), sans compte, ou deja a l'etape confirmee
--   <code du fil>         la conversation existe et private.praxis_fil_refus la ferme (hors_essai, donnees_reelles_fermees, mineur, cote...)
--   hors_essai / donnees_reelles_fermees   pas encore de conversation : memes portes
--   heure_tardive         entre 21 h et 8 h a l'heure du candidat, quand son fuseau est connu
--   plafond_fil           deja 2 messages de Praxis de suite sans reponse de la personne
--   question, relance :   direction_recente (la direction a ecrit dans la conversation depuis moins de 48 h),
--                         ouverture_recente (une question ou une relance depuis moins de 7 jours),
--                         relance_sans_objet (rien ne manque au candidat, ou il a agi ou ecrit depuis moins de 3 jours),
--                         plafond_relances (3 relances en tout), plafond_ouvertures (25 questions et relances par 24 heures, au total)
--   entretien_ecrit, relance_entretien : les limites de question et relance (48 h, 7 jours, 25 par jour), plus : entretien_en_cours (une
--                         serie sans reponse), plafond_entretiens (2 series en tout), relance_entretien_sans_objet (pas de serie, moins de
--                         7 jours, ou le candidat a repondu), entretien_deja_relance (une relance par serie)
--   felicitations :       felicitations_sans_objet (aucune admission en verification par la direction depuis 72 h),
--                         deja_felicite (deja fait pour cette decision, ou la direction ou Praxis a ecrit depuis la decision)
--   plafond               le plafond horaire des envois de Praxis (private.praxis_reglages.envois_par_heure), partage avec `ecrire`
CREATE FUNCTION private.praxis_ouverture_refus(c public.candidatures, p_raison text, p_cotes public.gender[])
RETURNS text
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
DECLARE
  v_fil uuid;
  v_refus text;
  v_praxis uuid := private.praxis_profil();
  v_derniere_personne timestamptz;
  v_heure integer;
  v_decision record;
  v_serie timestamptz;
BEGIN
  IF NOT private.praxis_dossier_ouvert(c, p_cotes) OR c.profile_id IS NULL OR c.etape = 'confirmee' THEN
    RETURN 'candidature_inconnue';
  END IF;
  v_fil := private.praxis_fil_candidature(c);
  IF v_fil IS NOT NULL THEN
    v_refus := private.praxis_fil_refus(v_fil, p_cotes);
    IF v_refus IS NOT NULL THEN RETURN v_refus; END IF;
  ELSE
    IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN RETURN 'hors_essai'; END IF;
    IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN RETURN 'donnees_reelles_fermees'; END IF;
  END IF;
  v_heure := private.praxis_heure_locale(coalesce(c.fuseau_iana, private.praxis_reponses(c.id) ->> 'fuseauIana'));
  IF v_heure IS NOT NULL AND (v_heure >= 21 OR v_heure < 8) THEN RETURN 'heure_tardive'; END IF;
  IF v_fil IS NOT NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_personne FROM public.com_messages m
     WHERE m.fil_id = v_fil AND m.auteur_id = c.profile_id;
    IF (SELECT pg_catalog.count(*) FROM public.com_messages m
         WHERE m.fil_id = v_fil AND m.auteur_id = v_praxis
           AND m.envoye_le > coalesce(v_derniere_personne, '-infinity'::timestamptz)) >= 2 THEN
      RETURN 'plafond_fil';
    END IF;
  END IF;
  IF p_raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien') THEN
    IF v_fil IS NOT NULL AND EXISTS (SELECT 1 FROM public.com_messages m
          WHERE m.fil_id = v_fil AND m.envoye_le > pg_catalog.clock_timestamp() - interval '48 hours'
            AND private.praxis_est_equipe(m.auteur_id, v_fil)) THEN
      RETURN 'direction_recente';
    END IF;
    IF EXISTS (SELECT 1 FROM private.praxis_ouvertures o
                WHERE o.candidature_id = c.id AND o.raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien')
                  AND o.ouverte_le > pg_catalog.clock_timestamp() - interval '7 days') THEN
      RETURN 'ouverture_recente';
    END IF;
    IF p_raison = 'relance' THEN
      IF coalesce((private.praxis_dossier_manques(c) ->> 'complet')::boolean, true)
         OR private.praxis_candidat_derniere_action(c) > pg_catalog.clock_timestamp() - interval '3 days' THEN
        RETURN 'relance_sans_objet';
      END IF;
      IF (SELECT pg_catalog.count(*) FROM private.praxis_ouvertures o WHERE o.candidature_id = c.id AND o.raison = 'relance') >= 3 THEN
        RETURN 'plafond_relances';
      END IF;
    END IF;
    -- L'ENTRETIEN ECRIT (directeur, 20/11/2026) : une serie de questions a la place de la video. Une seule serie OUVERTE par candidat (une
    -- serie est ouverte tant que le candidat n'a pas ecrit depuis), 2 series en tout ; UNE relance par serie, 7 jours apres, jamais au-dela.
    IF p_raison IN ('entretien_ecrit', 'relance_entretien') THEN
      SELECT pg_catalog.max(o.ouverte_le) INTO v_serie FROM private.praxis_ouvertures o
       WHERE o.candidature_id = c.id AND o.raison = 'entretien_ecrit';
      IF p_raison = 'entretien_ecrit' THEN
        IF v_serie IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.com_messages m
              WHERE m.fil_id = v_fil AND m.auteur_id = c.profile_id AND m.envoye_le > v_serie) THEN
          RETURN 'entretien_en_cours';
        END IF;
        IF (SELECT pg_catalog.count(*) FROM private.praxis_ouvertures o WHERE o.candidature_id = c.id AND o.raison = 'entretien_ecrit') >= 2 THEN
          RETURN 'plafond_entretiens';
        END IF;
      ELSE
        IF v_serie IS NULL OR v_serie > pg_catalog.clock_timestamp() - interval '7 days'
           OR EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = v_fil AND m.auteur_id = c.profile_id AND m.envoye_le > v_serie) THEN
          RETURN 'relance_entretien_sans_objet';
        END IF;
        IF EXISTS (SELECT 1 FROM private.praxis_ouvertures o
                    WHERE o.candidature_id = c.id AND o.raison = 'relance_entretien' AND o.ouverte_le > v_serie) THEN
          RETURN 'entretien_deja_relance';
        END IF;
      END IF;
    END IF;
    IF (SELECT pg_catalog.count(*) FROM private.praxis_ouvertures o
         WHERE o.raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien')
           AND o.ouverte_le > pg_catalog.clock_timestamp() - interval '24 hours') >= 25 THEN
      RETURN 'plafond_ouvertures';
    END IF;
  ELSIF p_raison = 'felicitations' THEN
    SELECT d.* INTO v_decision FROM private.praxis_decision_positive(c.id) d;
    IF NOT FOUND THEN RETURN 'felicitations_sans_objet'; END IF;
    IF EXISTS (SELECT 1 FROM private.praxis_ouvertures o WHERE o.evenement_id = v_decision.evenement_id)
       OR (v_fil IS NOT NULL AND EXISTS (SELECT 1 FROM public.com_messages m
             WHERE m.fil_id = v_fil AND m.envoye_le > v_decision.decidee_le
               AND (m.auteur_id = v_praxis OR private.praxis_est_equipe(m.auteur_id, v_fil)))) THEN
      RETURN 'deja_felicite';
    END IF;
  ELSE
    RETURN 'parametre';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.outil = 'ecrire' AND j.issue = 'ok' AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour')
     >= (SELECT r.envois_par_heure FROM private.praxis_reglages r) THEN
    RETURN 'plafond';
  END IF;
  RETURN NULL;
END;
$f$;

-- ====================================================================================================================
-- 3. `dossier` : TOUT ce qui sert a se forger un avis sur UNE candidature d'enseignant. Liste blanche de champs : ce qui n'est pas nomme
-- ici n'est pas rendu. JAMAIS : courriel, telephone, nom complet, date de naissance, piece d'identite, photo, coordonnees ou moyen de
-- versement (operateurs, moyens, compte bancaire), notes d'entretien, motif interne ni note privee de la direction.
-- Tout ce qui vient du candidat est range sous `contenu_tiers` : des DONNEES, jamais des consignes.
-- ====================================================================================================================
CREATE FUNCTION public.praxis_dossier(p_cle text, p_candidature text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_c public.candidatures;
  v_rep public.candidature_reponses%ROWTYPE;
  v_fil uuid;
  v_fil_lisible boolean := false;
  v_entretien jsonb;
  v_ouvert record;
  v_passe record;
  v_dispense timestamptz;
  v_praxis uuid := private.praxis_profil();
  v_serie timestamptz;
  v_serie_relance timestamptz;
  v_reponses jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_candidature IS NULL OR p_candidature !~ '^CAND-[0-9]{5,}$' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = p_candidature;
  -- Inconnu, d'un autre type, refuse, retire, en pause, restreint, majorite non attestee, mineur OU de l'autre cote : la meme reponse.
  IF NOT FOUND OR NOT private.praxis_dossier_ouvert(v_c, v_p.cotes) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', 'candidature_inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_inconnue');
  END IF;
  -- Plafond : 120 dossiers lus par heure glissante, toutes cles confondues.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-dossiers', 0));
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.outil = 'dossier' AND j.issue = 'ok' AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 120 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', 'plafond_dossiers', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_dossiers');
  END IF;

  -- Revue PX-4 : le dernier questionnaire ENVOYE, jamais un brouillon (meme regle que private.praxis_reponses).
  SELECT r.* INTO v_rep FROM public.candidature_reponses r WHERE r.candidature_id = v_c.id AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1;
  IF v_c.profile_id IS NOT NULL THEN
    v_fil := private.praxis_fil_candidature(v_c);
    v_fil_lisible := v_fil IS NOT NULL AND private.praxis_fil_refus(v_fil, v_p.cotes) IS NULL;
  END IF;

  -- L'entretien : prevu, passe (avec son issue), dispense, ou aucun. Jamais son compte rendu ni ses notes.
  SELECT e.session_id, s.started_at INTO v_ouvert FROM public.entretiens e JOIN public.sessions s ON s.id = e.session_id
   WHERE e.candidature_id = v_c.id AND e.issue IS NULL LIMIT 1;
  SELECT e.issue, e.consigne_le INTO v_passe FROM public.entretiens e
   WHERE e.candidature_id = v_c.id AND e.issue IS NOT NULL ORDER BY e.consigne_le DESC LIMIT 1;
  SELECT pg_catalog.max(d.cree_le) INTO v_dispense FROM public.candidature_dispenses_entretien d WHERE d.candidature_id = v_c.id;
  v_entretien := CASE
    WHEN v_ouvert.session_id IS NOT NULL THEN pg_catalog.jsonb_build_object('etat', 'prevu', 'le', v_ouvert.started_at)
    WHEN v_dispense IS NOT NULL AND (v_passe.consigne_le IS NULL OR v_dispense > v_passe.consigne_le)
      THEN pg_catalog.jsonb_build_object('etat', 'dispense', 'le', v_dispense)
    WHEN v_passe.issue IS NOT NULL THEN pg_catalog.jsonb_build_object('etat', 'passe', 'issue', v_passe.issue, 'le', v_passe.consigne_le)
    ELSE pg_catalog.jsonb_build_object('etat', 'aucun') END;

  -- L'entretien ECRIT : la derniere serie de questions de Praxis, sa relance, et les reponses du candidat (ses messages depuis la serie,
  -- 10 au plus), rendues sous contenu_tiers. Seulement si la conversation est lisible par Praxis (private.praxis_fil_refus).
  SELECT pg_catalog.max(o.ouverte_le) INTO v_serie FROM private.praxis_ouvertures o WHERE o.candidature_id = v_c.id AND o.raison = 'entretien_ecrit';
  IF v_serie IS NOT NULL THEN
    SELECT pg_catalog.max(o.ouverte_le) INTO v_serie_relance FROM private.praxis_ouvertures o
     WHERE o.candidature_id = v_c.id AND o.raison = 'relance_entretien' AND o.ouverte_le > v_serie;
    IF v_fil_lisible THEN
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('le', y.envoye_le, 'texte', pg_catalog.left(y.texte, 1500)) ORDER BY y.envoye_le)
        INTO v_reponses
        FROM (SELECT m.envoye_le, m.texte FROM public.com_messages m
               WHERE m.fil_id = v_fil AND m.auteur_id = v_c.profile_id AND m.envoye_le > v_serie
                 AND NOT EXISTS (SELECT 1 FROM public.com_message_images i WHERE i.message_id = m.id)
               ORDER BY m.envoye_le LIMIT 10) y;
    END IF;
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'dossier', 'ok', v_fil, ARRAY[v_c.id], NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object(
      'reference', v_c.reference,
      'cote', v_c.genre,
      'langue', v_c.langue,
      'etape', v_c.etape,
      'etat', v_c.etat,
      'source', v_c.source,
      'anciennete_jours', pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - v_c.recue_le) / 86400)::integer,
      'attente_jours', pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - v_c.derniere_activite) / 86400)::integer,
      'jours_sans_activite_candidat',
        pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - private.praxis_candidat_derniere_action(v_c)) / 86400)::integer,
      'a_un_compte', v_c.profile_id IS NOT NULL,
      'pays_residence', v_c.pays_residence,
      'fuseau', v_c.fuseau_iana,
      -- Le versement : le pays declare et « possible ou non », jamais un moyen, un operateur, un compte ni un montant.
      'versement', pg_catalog.jsonb_build_object('pays', v_rep.reponses ->> 'paysVersement', 'possible', v_c.paiement),
      'entretien', v_entretien,
      -- L'entretien ECRIT de Praxis : aucun, en_cours (sans reponse), repondu ; les reponses sont sous contenu_tiers.
      'entretien_ecrit', CASE WHEN v_serie IS NULL THEN pg_catalog.jsonb_build_object('etat', 'aucun')
        ELSE pg_catalog.jsonb_build_object('etat', CASE WHEN v_reponses IS NULL THEN 'en_cours' ELSE 'repondu' END,
                                           'envoye_le', v_serie, 'relance_le', v_serie_relance) END)
    || private.praxis_dossier_manques(v_c)
    || pg_catalog.jsonb_build_object(
      'complement_en_cours', pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(v_c)) > 0,
      'gestes', private.praxis_gestes_ligne(v_c, v_p.cotes),
      -- L'historique : des types et des dates (60 derniers). Jamais le motif interne, jamais une lecture de contact.
      'historique', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
                         'le', h.cree_le, 'type', h.type, 'geste', h.details ->> 'geste', 'auteur', h.details ->> 'auteur',
                         'etape_avant', h.etape_avant, 'etape_apres', h.etape_apres, 'etat_avant', h.etat_avant, 'etat_apres', h.etat_apres,
                         'issue_apres', h.issue_apres)) ORDER BY h.cree_le, h.id)
                       FROM (SELECT e.* FROM public.candidature_evenements e
                              WHERE e.candidature_id = v_c.id AND e.type NOT IN ('lecture_contact', 'lecture_hors_portee')
                              ORDER BY e.cree_le DESC, e.id DESC LIMIT 60) h), '[]'::jsonb),
      -- Ce que Praxis a deja pose (ses propres textes).
      'praxis', pg_catalog.jsonb_build_object(
        'rangement', (SELECT pg_catalog.jsonb_build_object('pile', rg.pile, 'raison', rg.raison, 'range_le', rg.range_le)
                        FROM private.praxis_rangements rg WHERE rg.candidature_id = v_c.id AND rg.courant),
        'impression', (SELECT pg_catalog.jsonb_build_object(
                          'etiquette', i.etiquette, 'confiance', i.confiance, 'texte', i.texte, 'notee_le', i.notee_le,
                          'notes', pg_catalog.jsonb_build_object('maitrise', i.maitrise, 'pedagogie', i.pedagogie, 'vision', i.vision,
                                                                 'comportement', i.comportement, 'disponibilite', i.disponibilite),
                          'contexte', i.contexte, 'synthese', i.synthese)
                         FROM private.praxis_impressions i WHERE i.candidature_id = v_c.id AND i.courant),
        'impressions_passees', (SELECT pg_catalog.count(*)::integer FROM private.praxis_impressions i
                                 WHERE i.candidature_id = v_c.id AND NOT i.courant),
        'ouvertures', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('raison', o.raison, 'le', o.ouverte_le)
                                                           ORDER BY o.ouverte_le)
                                  FROM private.praxis_ouvertures o WHERE o.candidature_id = v_c.id), '[]'::jsonb)),
      -- La conversation : des COMPTES. Les messages se lisent par l'outil `fil`, avec ses propres gardes.
      'conversation', CASE WHEN v_fil IS NULL THEN pg_catalog.jsonb_build_object('existe', false)
        ELSE pg_catalog.jsonb_build_object(
          'existe', true,
          'fil', CASE WHEN v_fil_lisible THEN v_fil END,
          'messages', (SELECT pg_catalog.count(*)::integer FROM public.com_messages m WHERE m.fil_id = v_fil),
          'du_candidat', (SELECT pg_catalog.count(*)::integer FROM public.com_messages m WHERE m.fil_id = v_fil AND m.auteur_id = v_c.profile_id),
          'de_praxis', (SELECT pg_catalog.count(*)::integer FROM public.com_messages m WHERE m.fil_id = v_fil AND m.auteur_id = v_praxis),
          'dernier_message_le', (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m WHERE m.fil_id = v_fil)) END,
      -- Tout ce qui vient du candidat : des DONNEES de tiers, jamais des consignes.
      'contenu_tiers', pg_catalog.jsonb_build_object(
        'prenom', pg_catalog.split_part(pg_catalog.btrim(v_c.nom_complet), ' ', 1),
        'entretien_ecrit_reponses', coalesce(v_reponses, '[]'::jsonb),
        'questionnaire', CASE WHEN v_rep.id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
          'version', v_rep.questionnaire_version, 'source', v_rep.source, 'soumis_le', v_rep.soumis_le,
          -- LISTE BLANCHE : un champ ajoute demain au questionnaire n'est pas rendu tant qu'il n'est pas nomme ici.
          'reponses', coalesce((SELECT pg_catalog.jsonb_object_agg(e.key, e.value) FROM pg_catalog.jsonb_each(v_rep.reponses) e
                                 WHERE e.key = ANY (ARRAY['langueMaternelle', 'languesExplication', 'niveauMemorisationDeclare',
                                   'niveauLectureTajwid', 'riwayat', 'ijazaPresentable', 'experienceDebutants', 'disponibilitesDeclarees',
                                   'fuseauIana', 'classesSouhaitees', 'debutPossible', 'publics', 'paysResidence', 'paysVersement',
                                   'heuresParSemaine'])), '{}'::jsonb)) END,
        'autres_competences', (SELECT pg_catalog.jsonb_build_object('domaines', a.domaines, 'autre_texte', a.autre_texte,
                                                                    'disponibilite', a.disponibilite, 'accord_contact', a.accord_contact)
                                 FROM public.candidature_autres_competences a WHERE a.candidature_id = v_c.id)));
END;
$f$;

-- ====================================================================================================================
-- 4. A QUI ECRIRE LE PREMIER : `praxis_boite_candidats`. Rend des CANDIDATURES (une personne peut ne pas avoir encore de conversation).
--   a_approfondir : etiquette pepite, solide ou a_creuser avec une confiance faible ou moyenne, sans question de Praxis depuis 7 jours.
--   sans_nouvelles : il reste quelque chose a faire au candidat, et il n'a rien fait ni ecrit depuis p_jours (3 au moins).
--   a_feliciter : admission en salle de verification par la direction depuis moins de 72 heures, sans message de Praxis ni de la direction
--                 depuis.
--   a_interroger : l'entretien reste a planifier (etat entretien_a_planifier) et aucun entretien ECRIT ne lui a ete envoye.
-- Chaque ligne dit `permis` (l'ouverture passerait maintenant) ou le `refus` qui l'empeche (private.praxis_ouverture_refus).
-- ====================================================================================================================
CREATE FUNCTION public.praxis_boite_candidats(p_cle text, p_filtre text, p_jours integer DEFAULT 3, p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_raison text;
  v_lignes jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_filtre IS NULL OR p_filtre NOT IN ('a_approfondir', 'sans_nouvelles', 'a_feliciter', 'a_interroger') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50
     OR p_jours IS NULL OR p_jours NOT BETWEEN 3 AND 60 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_raison := CASE p_filtre WHEN 'a_approfondir' THEN 'question' WHEN 'sans_nouvelles' THEN 'relance'
                            WHEN 'a_interroger' THEN 'entretien_ecrit' ELSE 'felicitations' END;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'reference', y.reference, 'cote', y.genre, 'langue', y.langue, 'etape', y.etape, 'etat', y.etat,
           'raison', v_raison,
           'fil', y.fil,
           'permis', y.refus IS NULL,
           'refus', y.refus,
           'jours_sans_activite_candidat', y.jours,
           'contenu_tiers', pg_catalog.jsonb_build_object('prenom', y.prenom))
           || CASE WHEN p_filtre = 'sans_nouvelles' THEN pg_catalog.jsonb_build_object('manquants', y.manquants) ELSE '{}'::jsonb END
           || CASE WHEN p_filtre = 'a_approfondir' THEN pg_catalog.jsonb_build_object('etiquette', y.etiquette, 'confiance', y.confiance)
                   ELSE '{}'::jsonb END
           ORDER BY y.rang), '[]'::jsonb)
    INTO v_lignes
    FROM (SELECT x.reference, x.genre, x.langue, x.etape, x.etat, x.fil, x.jours, x.manquants, x.etiquette, x.confiance,
                 pg_catalog.split_part(pg_catalog.btrim(x.nom_complet), ' ', 1) AS prenom,
                 private.praxis_ouverture_refus(x.c, v_raison, v_p.cotes) AS refus,
                 pg_catalog.row_number() OVER (ORDER BY x.derniere_activite, x.id) AS rang
            FROM (SELECT c.id, c.reference, c.genre, c.langue, c.etape, c.etat, c.nom_complet, c.derniere_activite, c AS c,
                         private.praxis_fil_candidature(c) AS fil,
                         pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - private.praxis_candidat_derniere_action(c)) / 86400)::integer AS jours,
                         CASE WHEN p_filtre = 'sans_nouvelles' THEN private.praxis_dossier_manques(c) -> 'manquants' END AS manquants,
                         i.etiquette, i.confiance
                    FROM public.candidatures c
                    LEFT JOIN private.praxis_impressions i ON i.candidature_id = c.id AND i.courant
                   WHERE private.praxis_dossier_ouvert(c, v_p.cotes) AND c.profile_id IS NOT NULL AND c.etape <> 'confirmee'
                     AND CASE p_filtre
                           WHEN 'a_approfondir' THEN i.etiquette IN ('pepite', 'solide', 'a_creuser') AND i.confiance IN ('faible', 'moyenne')
                             AND NOT EXISTS (SELECT 1 FROM private.praxis_ouvertures o
                                              WHERE o.candidature_id = c.id AND o.raison = 'question'
                                                AND o.ouverte_le > pg_catalog.clock_timestamp() - interval '7 days')
                           WHEN 'sans_nouvelles' THEN
                             private.praxis_candidat_derniere_action(c) <= pg_catalog.clock_timestamp() - pg_catalog.make_interval(days => p_jours)
                             AND NOT coalesce((private.praxis_dossier_manques(c) ->> 'complet')::boolean, true)
                           -- a_interroger : l'entretien reste a planifier et aucune serie de questions ecrites ne lui a ete envoyee.
                           WHEN 'a_interroger' THEN c.etat = 'entretien_a_planifier'
                             AND NOT EXISTS (SELECT 1 FROM private.praxis_ouvertures o WHERE o.candidature_id = c.id AND o.raison = 'entretien_ecrit')
                           ELSE EXISTS (SELECT 1 FROM private.praxis_decision_positive(c.id) d
                                         WHERE NOT EXISTS (SELECT 1 FROM private.praxis_ouvertures o WHERE o.evenement_id = d.evenement_id)
                                           AND NOT EXISTS (SELECT 1 FROM public.com_fils f JOIN public.com_messages m ON m.fil_id = f.id
                                                            WHERE f.id = private.praxis_fil_candidature(c) AND m.envoye_le > d.decidee_le
                                                              AND (m.auteur_id = private.praxis_profil()
                                                                   OR private.praxis_est_equipe(m.auteur_id, f.id))))
                         END
                   ORDER BY c.derniere_activite, c.id LIMIT p_limite) x) y;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('filtre', p_filtre, 'candidats', v_lignes);
END;
$f$;

-- ====================================================================================================================
-- 5. ECRIRE LE PREMIER : `praxis_ouvrir` (l'outil `ecrire` avec une `raison`). La conversation est la conversation STANDARD de
-- candidature (type candidature, le candidat et l'academie) : la meme ligne que celle que cree public.com_ouvrir_conversation pour la
-- direction. Jamais un autre type, jamais un groupe. Journalise sous l'outil `ecrire` (le plafond horaire des envois est donc partage).
-- ====================================================================================================================
CREATE FUNCTION public.praxis_ouvrir(p_cle text, p_candidature text, p_raison text, p_texte text, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_c public.candidatures;
  v_existant private.praxis_ouvertures%ROWTYPE;
  v_refus text;
  v_fil uuid;
  v_praxis uuid := private.praxis_profil();
  v_evenement bigint;
  v_r jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_candidature IS NULL OR p_cle_idempotence IS NULL OR v_texte = '' OR v_praxis IS NULL
     OR p_raison IS NULL OR p_raison NOT IN ('question', 'relance', 'felicitations', 'entretien_ecrit', 'relance_entretien') THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  -- Un entretien ecrit : de 1 a 5 questions par envoi (le serveur compte les points d'interrogation, latins et arabes).
  IF p_raison = 'entretien_ecrit' AND pg_catalog.length(pg_catalog.regexp_replace(v_texte, '[^?؟]', '', 'g')) NOT BETWEEN 1 AND 5 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'trop_de_questions', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'trop_de_questions');
  END IF;
  IF pg_catalog.length(v_texte) > 1500 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- Revue PX-4 : le verrou de la conversation existante AVANT celui des envois, dans l'ordre de `ecrire` (fil, puis envois). L'ordre
  -- inverse fait un interblocage quand deux cles ecrivent en meme temps dans la meme conversation (prouve sur un Postgres local).
  PERFORM 1 FROM public.com_fils f
   WHERE f.id = (SELECT private.praxis_fil_candidature(c) FROM public.candidatures c WHERE c.reference = p_candidature)
     FOR UPDATE;
  -- Le verrou des envois de Praxis (le meme que `ecrire`) : les plafonds se comptent sans course.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-envois', 0));
  -- Rejeu : la meme cle d'idempotence, rien d'ecrit.
  SELECT o.* INTO v_existant FROM private.praxis_ouvertures o WHERE o.cle_id = v_p.cle_id AND o.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'rejoue', v_existant.fil_id, ARRAY[v_existant.message_id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existant.message_id, 'fil', v_existant.fil_id, 'rejoue', true);
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = p_candidature FOR UPDATE;
  IF NOT FOUND THEN
    v_refus := 'candidature_inconnue';
  ELSE
    v_refus := private.praxis_ouverture_refus(v_c, p_raison, v_p.cotes);
  END IF;
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_refus, NULL,
                                 CASE WHEN v_refus <> 'candidature_inconnue' THEN ARRAY[v_c.id] END, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  IF p_raison = 'felicitations' THEN
    SELECT d.evenement_id INTO v_evenement FROM private.praxis_decision_positive(v_c.id) d;
  END IF;
  -- La conversation standard de candidature : la meme ligne que celle que cree la porte humaine d'ouverture d'une conversation (type candidature, candidat et academie).
  INSERT INTO public.com_fils (type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
  VALUES ('candidature', v_c.id, 'profil', v_c.profile_id, 'equipe', NULL)
  ON CONFLICT DO NOTHING;
  v_fil := private.praxis_fil_candidature(v_c);
  -- La conversation vient peut-etre d'etre creee : elle repasse la garde de toute conversation lue ou ecrite par Praxis.
  v_refus := private.praxis_fil_refus(v_fil, v_p.cotes);
  IF v_fil IS NULL OR v_refus IS NOT NULL THEN
    RAISE EXCEPTION 'PX-4 : la conversation de candidature est fermee (%)', coalesce(v_refus, 'absente') USING ERRCODE = '42501';
  END IF;
  v_r := private.com_envoyer_message_interne(v_praxis, 'accountant', NULL, v_fil, v_texte, p_cle_idempotence, false);
  INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, evenement_id, cle_id, emise_par, cle_idempotence)
  VALUES (v_c.id, p_raison, v_fil, (v_r ->> 'id')::uuid, v_evenement, v_p.cle_id, v_p.emise_par, p_cle_idempotence);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'ok', v_fil, ARRAY[(v_r ->> 'id')::uuid], v_texte, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_r -> 'id', 'fil', v_fil, 'envoye_le', v_r -> 'envoye_le', 'raison', p_raison);
END;
$f$;

-- ====================================================================================================================
-- 6. Les quatre fonctions existantes, remplacees (empreintes controlees au preflight). Chaque ajout porte le mot PX-4.
-- ====================================================================================================================
-- 6.1 praxis_lire : filtres de la recherche des meilleurs, tri par vision, `impression` sur chaque ligne.
CREATE OR REPLACE FUNCTION public.praxis_lire(p_cle text, p_vue text, p_filtre jsonb DEFAULT '{}'::jsonb, p_limite integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_inconnues text;
  v_etape text;
  v_etat text;
  v_langue text;
  v_min integer;
  v_nb numeric;
  v_lignes jsonb;
  v_total integer;
  -- PX-4 : les filtres de la recherche des meilleurs.
  v_etiquette text;
  v_sans boolean;
  v_ijaza text;
  v_riwaya text;
  v_lexp text;
  v_public text;
  v_tri text;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
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
   WHERE k.cle <> ALL (ARRAY['etape', 'etat', 'langue', 'attente_min_jours',
                            -- PX-4 : etiquette d'impression, sans impression, ijaza, riwaya, langue d'explication, public, tri.
                            'etiquette', 'sans_impression', 'ijaza', 'riwaya', 'langue_explication', 'public', 'tri']);
  IF v_inconnues IS NOT NULL
     OR coalesce((SELECT pg_catalog.bool_or(pg_catalog.jsonb_typeof(e.value) <>
                         CASE WHEN e.key = 'attente_min_jours' THEN 'number'
                              WHEN e.key = 'sans_impression' THEN 'boolean' -- PX-4
                              ELSE 'string' END)
                    FROM pg_catalog.jsonb_each(v_filtre) e), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_etape := v_filtre ->> 'etape';
  v_etat := v_filtre ->> 'etat';
  v_langue := v_filtre ->> 'langue';
  -- PX-4
  v_etiquette := v_filtre ->> 'etiquette';
  v_sans := (v_filtre ->> 'sans_impression')::boolean;
  v_ijaza := v_filtre ->> 'ijaza';
  v_riwaya := v_filtre ->> 'riwaya';
  v_lexp := v_filtre ->> 'langue_explication';
  v_public := v_filtre ->> 'public';
  v_tri := coalesce(v_filtre ->> 'tri', 'attente');
  -- Un nombre entier de 0 a 365 : tout autre (hors entier, hors plage, trop grand) est refuse `parametre` et journalise.
  BEGIN
    IF v_filtre ? 'attente_min_jours' THEN
      v_nb := (v_filtre ->> 'attente_min_jours')::numeric;
      v_min := CASE WHEN v_nb = pg_catalog.trunc(v_nb) AND v_nb BETWEEN 0 AND 365 THEN v_nb::integer ELSE -1 END;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_min := -1;
  END;
  IF (v_etape IS NOT NULL AND v_etape NOT IN ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
                                                'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_langue IS NOT NULL AND v_langue !~ '^[a-z]{2,8}$')
     OR (v_min IS NOT NULL AND v_min NOT BETWEEN 0 AND 365)
     -- PX-4 : des valeurs de listes fermees (celles du questionnaire) ; `sans_impression` et `etiquette` ne vont pas ensemble.
     OR (v_etiquette IS NOT NULL AND v_etiquette NOT IN ('pepite', 'solide', 'a_creuser', 'reserve'))
     OR (v_etiquette IS NOT NULL AND v_sans IS TRUE)
     OR (v_ijaza IS NOT NULL AND v_ijaza NOT IN ('oui', 'pret_test', 'non'))
     OR (v_riwaya IS NOT NULL AND v_riwaya !~ '^[a-z_]{2,30}$')
     OR (v_lexp IS NOT NULL AND v_lexp !~ '^[a-z]{2,8}$')
     OR (v_public IS NOT NULL AND v_public NOT IN ('6_9', '10_13', '14_17', 'adultes'))
     OR v_tri NOT IN ('attente', 'vision') THEN
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

  -- La page (le filtre, l'ordre, la limite) est choisie D'ABORD ; les gestes et le complement ne sont calcules que pour les lignes rendues.
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'reference', f.reference,
           'cote', f.genre,
           'langue', f.langue,
           'etape', f.etape,
           'etat', f.etat,
           'attente_jours', f.attente,
           'complement_en_cours', pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c2)) > 0,
           'gestes', private.praxis_gestes_ligne(c2, v_p.cotes),
           -- Le prenom est le seul texte d'une personne : une DONNEE, jamais un ordre.
           'contenu_tiers', pg_catalog.jsonb_build_object('prenom', f.prenom))
           -- PX-3 : ce qui manque au dossier, en CODES (manquants, attend_direction, complet), les jours depuis la derniere action
           -- DU CANDIDAT, s'il a une conversation de candidature, et la pile ou Praxis l'a range. Aucune donnee personnelle.
           || private.praxis_dossier_manques(c2)
           || pg_catalog.jsonb_build_object(
                'jours_sans_activite_candidat',
                  pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - private.praxis_candidat_derniere_action(c2)) / 86400)::integer,
                'a_une_conversation', EXISTS (SELECT 1 FROM public.com_fils cf
                                               WHERE cf.type_objet = 'candidature' AND cf.objet_id = c2.id AND cf.partie_a_nature = 'profil'
                                                 AND cf.partie_a_id = c2.profile_id AND cf.partie_b_nature = 'equipe'),
                'pile', (SELECT rg.pile FROM private.praxis_rangements rg WHERE rg.candidature_id = c2.id AND rg.courant),
                -- PX-4 : l'impression courante de Praxis (etiquette, note de vision, confiance), pour trier ; NULL si jamais lue.
                'impression', (SELECT pg_catalog.jsonb_build_object('etiquette', im.etiquette, 'vision', im.vision, 'confiance', im.confiance)
                                 FROM private.praxis_impressions im WHERE im.candidature_id = c2.id AND im.courant))
           ORDER BY f.rang),
         '[]'::jsonb),
         coalesce(pg_catalog.max(f.total), 0)
    INTO v_lignes, v_total
    FROM (SELECT x.* FROM (SELECT c.id, c.reference, c.genre, c.langue, c.etape, c.etat, c.derniere_activite,
                                  (EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400)::integer AS attente,
                                  pg_catalog.split_part(pg_catalog.btrim(c.nom_complet), ' ', 1) AS prenom,
                                  pg_catalog.row_number() OVER (ORDER BY
                                    -- PX-4 : tri `vision` = la meilleure note de vision d'abord ; sinon l'ordre d'avant.
                                    CASE WHEN v_tri = 'vision' THEN (SELECT im.vision FROM private.praxis_impressions im
                                                                      WHERE im.candidature_id = c.id AND im.courant) END DESC NULLS LAST,
                                    c.derniere_activite, c.id) AS rang,
                                  pg_catalog.count(*) OVER ()::integer AS total
                             FROM public.candidatures c
                            WHERE c.type_code = 'enseignant' AND c.issue = 'en_cours' AND c.genre = ANY (v_p.cotes)
                              AND (v_etape IS NULL OR c.etape = v_etape)
                              AND (v_etat IS NULL OR c.etat = v_etat)
                              AND (v_langue IS NULL OR c.langue = v_langue)
                              -- PX-4 : les filtres de la recherche (impression de Praxis, dernieres reponses du questionnaire).
                              AND (v_etiquette IS NULL OR EXISTS (SELECT 1 FROM private.praxis_impressions im
                                                                   WHERE im.candidature_id = c.id AND im.courant AND im.etiquette = v_etiquette))
                              AND (v_sans IS NULL OR v_sans = NOT EXISTS (SELECT 1 FROM private.praxis_impressions im
                                                                           WHERE im.candidature_id = c.id AND im.courant))
                              AND (v_ijaza IS NULL OR private.praxis_reponses(c.id) ->> 'ijazaPresentable' = v_ijaza)
                              AND (v_riwaya IS NULL OR coalesce((private.praxis_reponses(c.id) -> 'riwayat') ? v_riwaya, false))
                              AND (v_lexp IS NULL OR coalesce((private.praxis_reponses(c.id) -> 'languesExplication') ? v_lexp, false))
                              AND (v_public IS NULL OR coalesce((private.praxis_reponses(c.id) -> 'publics') ? v_public, false))
                              AND (v_min IS NULL
                                   OR EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400 >= v_min)) x
           WHERE x.rang <= p_limite) f
    JOIN public.candidatures c2 ON c2.id = f.id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('vue', 'candidatures', 'lignes', v_lignes, 'total', v_total);
END;
$function$;

-- 6.2 praxis_ecrire : dans une conversation de candidature, sans raison, Praxis ne fait que repondre ; 2 messages de suite au plus.
CREATE OR REPLACE FUNCTION public.praxis_ecrire(p_cle text, p_fil uuid, p_texte text, p_cle_idempotence uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_refus text;
  v_f public.com_fils%ROWTYPE;
  v_praxis uuid := private.praxis_profil();
  v_existant record;
  v_derniere_praxis timestamptz;
  v_derniere_autre timestamptz;
  v_plafond integer;
  v_r jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_cle_idempotence IS NULL OR v_texte = '' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 1500 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'longueur', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- Le verrou du fil (comme la porte humaine), puis le verrou des envois de Praxis (les plafonds se lisent au journal).
  SELECT f.* INTO v_f FROM public.com_fils f WHERE f.id = p_fil FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'fil_inconnu', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'fil_inconnu');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-envois', 0));
  -- Rejeu : le meme message, rien d'ecrit.
  SELECT m.id, m.envoye_le INTO v_existant FROM public.com_messages m
   WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis AND m.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'rejoue', p_fil, ARRAY[v_existant.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existant.id, 'envoye_le', v_existant.envoye_le, 'rejoue', true);
  END IF;
  v_refus := private.praxis_fil_refus(p_fil, v_p.cotes);
  -- PRAXIS-CANDIDATS : private.com_paires lit auth.uid() (la session humaine) et ne peut pas servir pour un fil de candidature ; la regle
  -- equivalente est dans private.praxis_fil_refus (candidature vivante, partie A = le candidat, cote). Les autres types gardent le test.
  IF v_refus IS NULL AND v_f.type_objet <> 'candidature' AND NOT EXISTS (
       SELECT 1 FROM private.com_paires(v_f.type_objet, v_f.objet_id) q
        WHERE q.a_nature = v_f.partie_a_nature AND q.a_id = v_f.partie_a_id
          AND q.b_nature = v_f.partie_b_nature AND q.b_id IS NOT DISTINCT FROM v_f.partie_b_id) THEN
    v_refus := 'fil_ferme';
  END IF;
  IF v_refus IS NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_praxis FROM public.com_messages m
     WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis;
    IF v_derniere_praxis IS NOT NULL AND EXISTS (
         SELECT 1 FROM public.com_messages m
          WHERE m.fil_id = p_fil AND private.praxis_est_equipe(m.auteur_id, p_fil)
            AND m.envoye_le > v_derniere_praxis) THEN
      v_refus := 'repris_par_equipe';
    END IF;
  END IF;
  IF v_refus IS NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_autre FROM public.com_messages m
     WHERE m.fil_id = p_fil AND private.praxis_est_partie_a(m.auteur_id, p_fil);
    -- PX-4 (directeur, 20/11/2026 : « sans harceler ni mettre la pression ») : dans une conversation de CANDIDATURE, `ecrire` sans raison
    -- ne sert qu'a REPONDRE : la personne a ecrit, et la direction n'a pas repondu depuis dans la conversation. Ecrire le premier (question,
    -- relance, felicitations) passe par public.praxis_ouvrir, qui porte toutes les limites. Les autres types ne changent pas.
    IF v_f.type_objet = 'candidature' AND (v_derniere_autre IS NULL OR EXISTS (
         SELECT 1 FROM public.com_messages m
          WHERE m.fil_id = p_fil AND m.envoye_le > v_derniere_autre AND private.praxis_est_equipe(m.auteur_id, p_fil))) THEN
      v_refus := 'raison_requise';
    ELSIF (SELECT pg_catalog.count(*) FROM public.com_messages m
         WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis
           AND m.envoye_le > coalesce(v_derniere_autre, '-infinity'::timestamptz))
          -- PX-4 : 2 messages de suite au plus dans une conversation de candidature (3 ailleurs, comme avant).
          >= (CASE WHEN v_f.type_objet = 'candidature' THEN 2 ELSE 3 END) THEN
      v_refus := 'plafond_fil';
    END IF;
  END IF;
  IF v_refus IS NULL THEN
    SELECT r.envois_par_heure INTO v_plafond FROM private.praxis_reglages r;
    IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
         WHERE j.outil = 'ecrire' AND j.issue = 'ok'
           AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= v_plafond THEN
      v_refus := 'plafond';
    END IF;
  END IF;
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  -- Tous les controles sont faits : l'interne n'a plus a rejouer le test humain (p_controle_humain = faux).
  v_r := private.com_envoyer_message_interne(v_praxis, 'accountant', NULL, p_fil, v_texte, p_cle_idempotence, false);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'ok', p_fil, ARRAY[(v_r ->> 'id')::uuid], v_texte,
                               v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_r -> 'id', 'envoye_le', v_r -> 'envoye_le');
END;
$function$;

-- 6.3 praxis_noter_refus : connait `dossier` et `noter_impression`.
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
                                        'calendrier_ajouter', 'rendre_compte', 'lire', 'preparer',
                                        -- PX-3 : les quatre outils neufs.
                                        'ranger', 'objectif_fixer', 'objectif_clore', 'objectifs_lire',
                                        -- PX-4 : les quatre outils neufs du connecteur.
                                        'dossier', 'noter_impression', 'boite_candidats', 'ouvrir') THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  -- Plafond : 60 notes de refus par cle et par heure glissante ; au-dela, rien n'est ecrit.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_p.cle_id::text, 0));
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.cle_id = v_p.cle_id AND j.issue = 'parametre'
         AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 60 THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, p_outil, 'parametre', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$function$;

-- 6.4 praxis_etat : + ouverturesRestantesJour (le plafond des ouvertures de dialogue, lisible par Praxis).
CREATE OR REPLACE FUNCTION public.praxis_etat(p_cle text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_plafond integer;
  v_envoyes integer;
  v_annonces integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL AND v_p.cause IS DISTINCT FROM 'eteint' THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'etat', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  SELECT r.envois_par_heure INTO v_plafond FROM private.praxis_reglages r;
  SELECT pg_catalog.count(*)::integer INTO v_envoyes FROM private.praxis_journal j
   WHERE j.outil = 'ecrire' AND j.issue = 'ok' AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour';
  SELECT pg_catalog.count(*)::integer INTO v_annonces FROM private.praxis_journal j
   WHERE j.outil = 'annoncer' AND j.issue = 'ok' AND j.cree_le > pg_catalog.clock_timestamp() - interval '24 hours';
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'etat', CASE WHEN v_p.cause IS NULL THEN 'ok' ELSE v_p.cause END,
                               NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object(
    'actif', v_p.cause IS NULL,
    'mode', CASE v_p.usage WHEN 'routine' THEN 'autonome' ELSE 'dirige' END,
    'cotes', pg_catalog.to_jsonb(v_p.cotes),
    'plafondRestantHeure', greatest(v_plafond - v_envoyes, 0),
    'annoncesRestantesJour', greatest(2 - v_annonces, 0),
    -- PX-4 : ce qu'il reste des ouvertures de dialogue (questions, relances, entretiens ecrits : 25 par 24 heures, au total) ; les
    -- felicitations ne comptent pas ; chaque ouverture compte aussi dans plafondRestantHeure.
    'ouverturesRestantesJour', greatest(25 - (SELECT pg_catalog.count(*)::integer FROM private.praxis_ouvertures o
                                               WHERE o.raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien')
                                                 AND o.ouverte_le > pg_catalog.clock_timestamp() - interval '24 hours'), 0),
    'interdits', pg_catalog.jsonb_build_array(
      'refuser une personne', 'supprimer', 'deplacer de l''argent', 'changer un droit ou un role',
      'lire une piece d''identite', 'modifier le garde-fou, ses reglages ou ses cles',
      'ecrire a un mineur', 'creer un fil', 'ecrire hors d''un fil de l''academie', 'envoyer un courriel'));
END;
$function$;

-- ====================================================================================================================
-- 7. DROITS. Outils : service_role seul. Lecture de la direction : authenticated (garde d'administrateur dans la fonction). Aides : personne.
-- ====================================================================================================================
ALTER FUNCTION private.praxis_dossier_ouvert(public.candidatures, public.gender[]) OWNER TO postgres;
ALTER FUNCTION private.praxis_reponses(uuid) OWNER TO postgres;
ALTER FUNCTION private.praxis_heure_locale(text) OWNER TO postgres;
ALTER FUNCTION private.praxis_fil_candidature(public.candidatures) OWNER TO postgres;
ALTER FUNCTION private.praxis_decision_positive(uuid) OWNER TO postgres;
ALTER FUNCTION private.praxis_impression_mot_interdit(text) OWNER TO postgres;
ALTER FUNCTION private.praxis_ouverture_refus(public.candidatures, text, public.gender[]) OWNER TO postgres;
ALTER FUNCTION public.praxis_dossier(text, text) OWNER TO postgres;
ALTER FUNCTION public.praxis_noter_impression(text, text, text, jsonb, jsonb, jsonb, text, text, uuid) OWNER TO postgres;
ALTER FUNCTION public.praxis_boite_candidats(text, text, integer, integer) OWNER TO postgres;
ALTER FUNCTION public.praxis_ouvrir(text, text, text, text, uuid) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_impressions(text, integer, integer) OWNER TO postgres;

REVOKE ALL ON FUNCTION private.praxis_dossier_ouvert(public.candidatures, public.gender[]), private.praxis_reponses(uuid),
  private.praxis_heure_locale(text), private.praxis_fil_candidature(public.candidatures), private.praxis_decision_positive(uuid),
  private.praxis_impression_mot_interdit(text), private.praxis_ouverture_refus(public.candidatures, text, public.gender[])
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

REVOKE ALL ON FUNCTION public.praxis_dossier(text, text), public.praxis_noter_impression(text, text, text, jsonb, jsonb, jsonb, text, text, uuid),
  public.praxis_boite_candidats(text, text, integer, integer), public.praxis_ouvrir(text, text, text, text, uuid)
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.praxis_dossier(text, text), public.praxis_noter_impression(text, text, text, jsonb, jsonb, jsonb, text, text, uuid),
  public.praxis_boite_candidats(text, text, integer, integer), public.praxis_ouvrir(text, text, text, text, uuid)
  TO service_role;

REVOKE ALL ON FUNCTION public.direction_praxis_impressions(text, integer, integer) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_impressions(text, integer, integer) TO authenticated;

-- ====================================================================================================================
-- 8. CONTROLE DE SORTIE : tout est la, avec les bons droits, ou la migration echoue (et rien n'est garde).
-- ====================================================================================================================
DO $post$
DECLARE
  v text;
BEGIN
  FOREACH v IN ARRAY ARRAY['public.praxis_dossier(text,text)', 'public.praxis_noter_impression(text,text,text,jsonb,jsonb,jsonb,text,text,uuid)',
                           'public.praxis_boite_candidats(text,text,integer,integer)', 'public.praxis_ouvrir(text,text,text,text,uuid)',
                           'public.praxis_lire(text,text,jsonb,integer)', 'public.praxis_ecrire(text,uuid,text,uuid)',
                           'public.praxis_noter_refus(text,text)', 'public.praxis_etat(text)'] LOOP
    IF NOT pg_catalog.has_function_privilege('service_role', v, 'EXECUTE') OR pg_catalog.has_function_privilege('anon', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] FROM pg_catalog.pg_proc p
                WHERE p.oid = v::pg_catalog.regprocedure) THEN
      RAISE EXCEPTION 'PX-4 : droits ou securite inattendus sur %', v;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_impressions(text,integer,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_impressions(text,integer,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PX-4 : droits inattendus sur direction_praxis_impressions';
  END IF;
  IF (SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_lire(text,text,jsonb,integer)'::pg_catalog.regprocedure) NOT LIKE '%PX-4%'
     OR (SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_ecrire(text,uuid,text,uuid)'::pg_catalog.regprocedure) NOT LIKE '%PX-4%'
     OR (SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = 'public.praxis_noter_refus(text,text)'::pg_catalog.regprocedure) NOT LIKE '%PX-4%' THEN
    RAISE EXCEPTION 'PX-4 : retouche absente';
  END IF;
  IF NOT (SELECT pg_catalog.bool_and(c.relrowsecurity) FROM pg_catalog.pg_class c
           WHERE c.oid IN ('private.praxis_impressions'::pg_catalog.regclass, 'private.praxis_ouvertures'::pg_catalog.regclass))
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_policies pol WHERE pol.schemaname = 'private' AND pol.tablename IN ('praxis_impressions', 'praxis_ouvertures')) THEN
    RAISE EXCEPTION 'PX-4 : RLS absente ou politique inattendue sur les tables neuves';
  END IF;
END
$post$;
