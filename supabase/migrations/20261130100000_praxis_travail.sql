-- PRAXIS-TRAVAIL (PX-3, ordre du directeur du 20/11/2026 : « il doit commencer a repondre aux gens, classer les dossiers, definir des
-- objectifs journaliers ou hebdomadaires ») : les outils serveur qui manquaient a Praxis pour TRAVAILLER sur les dossiers des candidats
-- enseignants. Cahier : docs/current/BUREAU-EQUIPE/PRAXIS/CAHIER-PX-3-TRAVAIL.md.
--
-- LIVRE ICI (points 1 a 4 de l'ordre) :
--   1. LIRE CE QUI MANQUE : `praxis_lire` (vue candidatures) rend en plus, par ligne, `manquants` (codes du complement), `attend_direction`,
--      `complet`, `jours_sans_activite_candidat`, `a_une_conversation`, `pile`. Calcul : private.praxis_dossier_manques, qui LIT
--      private.candidature_controles_dossier (la fonction de `lire_candidature`, jamais une copie) et private.candidature_complement_en_cours.
--   2. RANGER EN PILES : table private.praxis_rangements, outil `praxis_ranger` (60 par heure), lecture `direction_praxis_rangements`.
--   3. PROPOSER LA DISPENSE D'ENTRETIEN : `praxis_preparer` accepte `dispenser_entretien` ; `direction_praxis_valider` l'execute par la
--      porte publique public.dispenser_entretien (20261129470000), sous l'identite de la direction qui valide.
--   4. OBJECTIFS : table private.praxis_objectifs, outils `praxis_objectif_fixer`, `praxis_objectif_clore`, `praxis_objectifs_lire`,
--      lecture `direction_praxis_objectifs` ; `praxis_rendre_compte` rend aussi `objectifs_ouverts` et `propositions_en_attente`.
-- NON LIVRE ICI : les relances (filtre `sans_nouvelles`) et le mot prive apres une decision (filtre `a_feliciter`) : `praxis_boite`,
-- `praxis_ecrire` et `private.praxis_fil_refus` ne sont PAS touches par ce fichier.
--
-- MOTS D'EFFACEMENT : UN SEUL (section 3, une contrainte), pour REECRIRE LE CHECK private.praxis_propositions.geste (trois gestes
-- deviennent quatre) : la seule exception admise par supabase/CLAUDE.md. Aucune donnee n'est effacee. Aucun autre mot d'effacement.
--
-- FONCTIONS EXISTANTES REMPLACEES (CREATE OR REPLACE a signature identique, droits et proprietaire conserves), apres controle de
-- l'empreinte md5(prosrc) de la definition en vigueur. Le corps est celui de la DERNIERE migration qui les definit, recopie, plus le
-- necessaire (chaque ajout porte le mot PX-3) :
--   * private.praxis_gestes_ligne(candidatures, gender[])   <- 20261129840000. Appelants : praxis_lire, praxis_preparer.
--   * public.praxis_lire(text, text, jsonb, integer)         <- 20261129840000. Appelant : l'outil `lire` du connecteur (praxis-mcp).
--   * public.praxis_preparer(text, text, text, jsonb, text, uuid) <- 20261129840000. Appelant : l'outil `preparer`.
--   * public.direction_praxis_valider(uuid, integer, text, uuid[]) <- 20261129840000. Appelant : l'ecran de la direction (propositions de Praxis).
--   * public.praxis_rendre_compte(text, integer)             <- 20261129650000. Appelant : l'outil `rendre_compte` (la routine horaire).
--   * public.praxis_noter_refus(text, text)                  <- 20261129860000. Appelant : praxis-mcp (refus de parametre, M4).
-- Tout le reste est NEUF. Memes gardes que les outils existants : porte private.praxis_porte (cle, actif, mode, plafond global), mode essai
-- et donnees reelles (pour ce qui touche un dossier), journal private.praxis_noter a chaque appel, idempotence par cle, EXECUTE au seul
-- service_role pour `praxis_*`, a `authenticated` (garde d'administrateur valide dans la fonction) pour `direction_praxis_*`.
-- Rien n'est allume par cette migration. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regclass('private.praxis_propositions') IS NULL OR pg_catalog.to_regclass('private.praxis_questions') IS NULL
     OR pg_catalog.to_regprocedure('public.dispenser_entretien(uuid,text,text,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_controles_dossier(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.candidature_complement_en_cours(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.cand_lecteur()') IS NULL THEN
    RAISE EXCEPTION 'PX-3 : dependances absentes (PX-2, PX-SUIVI, dispense d''entretien, controles du dossier) ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.praxis_rangements') IS NOT NULL OR pg_catalog.to_regclass('private.praxis_objectifs') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-3 : deja installe ; rien n''est modifie';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.geste = 'dispenser_entretien' AND 'direction' = ANY (r.auteurs)) THEN
    RAISE EXCEPTION 'PX-3 : la regle du geste dispenser_entretien est absente ; rien n''est modifie';
  END IF;
  FOR v IN SELECT * FROM (VALUES
      ('private.praxis_gestes_ligne(public.candidatures,public.gender[])', 'acabfd9b92fb878b091dfcafe441384a'),
      ('public.praxis_lire(text,text,jsonb,integer)', '544c9b89b987f29ba3bca9fe47b16748'),
      ('public.praxis_preparer(text,text,text,jsonb,text,uuid)', 'f0b3a65bc044fa44203f439bd35183bf'),
      ('public.direction_praxis_valider(uuid,integer,text,uuid[])', '567af70c9f25f81290f2a20202ac2d23'),
      ('public.praxis_rendre_compte(text,integer)', '6f9b1cb79dddf7146f830d62241237ae'),
      ('public.praxis_noter_refus(text,text)', '067543751b2057b7fa24635cd5705aaa')) AS t(f, md5) LOOP
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v.f::pg_catalog.regprocedure) IS DISTINCT FROM v.md5 THEN
      RAISE EXCEPTION 'PX-3 : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
END
$preflight$;

-- ====================================================================================================================
-- 1. LIRE CE QUI MANQUE A UN DOSSIER. Des CODES seulement (ceux du complement : private.candidature_complement_codes), jamais une valeur,
-- un contact, une piece, un montant ni une note. Deux listes : `manquants` (c'est au CANDIDAT d'agir) et `attend_direction` (c'est a la
-- direction d'agir : une piece deposee a verifier, un versement a examiner). `complet` : le candidat n'a plus rien a faire.
-- Les controles viennent de private.candidature_controles_dossier (celle que lit `lire_candidature` pour `controles`) : elle ne nomme que
-- le PREMIER accord manquant (contrat, puis avis, puis code de conduite) ; les autres apparaissent une fois le premier signe.
-- La photo et l'accord de publication : les memes conditions que public.etat_dossier() et que le refus de l'envoi (20261110330000).
-- ====================================================================================================================
CREATE FUNCTION private.praxis_dossier_manques(c public.candidatures)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
DECLARE
  v_ctl jsonb;
  v_e jsonb;
  v_cause text;
  v_m text[] := ARRAY[]::text[];
  v_d text[] := ARRAY[]::text[];
  v_code text;
BEGIN
  IF c.id IS NULL OR c.type_code IS DISTINCT FROM 'enseignant' THEN
    RETURN pg_catalog.jsonb_build_object('manquants', '[]'::jsonb, 'attend_direction', '[]'::jsonb, 'complet', false);
  END IF;
  IF c.profile_id IS NULL THEN
    -- Pas encore de compte (etapes recue, invitee) : la personne doit d'abord creer son compte.
    RETURN pg_catalog.jsonb_build_object('manquants', pg_catalog.jsonb_build_array('compte'), 'attend_direction', '[]'::jsonb,
                                         'complet', false);
  END IF;
  v_ctl := coalesce(private.candidature_controles_dossier(c), '[]'::jsonb);
  FOR v_e IN SELECT x.e FROM pg_catalog.jsonb_array_elements(v_ctl) WITH ORDINALITY AS x(e, o)
              WHERE NOT coalesce((x.e ->> 'valeur')::boolean, false) ORDER BY x.o LOOP
    v_cause := v_e ->> 'cause';
    CASE v_e ->> 'nom'
      WHEN 'cadre_religieux' THEN
        IF v_cause = 'non_publie' THEN v_d := v_d || 'cadre_religieux'::text; ELSE v_m := v_m || 'cadre_religieux'::text; END IF;
      WHEN 'accords_signes' THEN
        v_m := v_m || CASE v_cause WHEN 'teacher_nda' THEN 'contrat' WHEN 'recording_and_control_notice' THEN 'avis'
                                   WHEN 'teacher_conduct_code' THEN 'code_conduite' ELSE 'compte' END;
      WHEN 'piece_validee' THEN
        IF v_cause = 'piece_a_verifier' THEN v_d := v_d || 'piece_identite'::text; ELSE v_m := v_m || 'piece_identite'::text; END IF;
      WHEN 'questionnaire_complet' THEN
        IF v_cause = 'questionnaire_absent' THEN v_d := v_d || 'questionnaire'::text; ELSE v_m := v_m || 'questionnaire'::text; END IF;
      WHEN 'paiement_compatible' THEN
        -- `inconnu` : la personne n'a rien declare (pays de versement). Sinon c'est a la direction d'examiner. Jamais un montant ni un moyen.
        IF v_cause = 'inconnu' THEN v_m := v_m || 'pays_versement'::text; ELSE v_d := v_d || 'versement'::text; END IF;
      ELSE
        v_d := v_d || 'autre'::text;
    END CASE;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM public.teacher_profiles tp WHERE tp.profile_id = c.profile_id AND tp.photo_storage_key IS NOT NULL) THEN
    v_m := v_m || 'photo'::text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.accords_publication a
                  WHERE a.profile_id = c.profile_id AND a.retire_le IS NULL
                    AND a.version = (SELECT k.value #>> '{}' FROM public.app_config k WHERE k.key = 'enseignants.publication_version')) THEN
    v_m := v_m || 'accord_publication'::text;
  END IF;
  -- Un complement demande par la direction et pas encore rendu : ses codes sont « a reprendre ».
  FOR v_code IN SELECT x.code FROM pg_catalog.jsonb_array_elements_text(private.candidature_complement_en_cours(c)) WITH ORDINALITY AS x(code, o)
                 ORDER BY x.o LOOP
    v_m := v_m || v_code;
  END LOOP;
  RETURN pg_catalog.jsonb_build_object(
    'manquants', coalesce((SELECT pg_catalog.jsonb_agg(y.code ORDER BY y.o)
                             FROM (SELECT x.code, pg_catalog.min(x.o) AS o FROM pg_catalog.unnest(v_m) WITH ORDINALITY AS x(code, o)
                                    GROUP BY x.code) y), '[]'::jsonb),
    'attend_direction', coalesce((SELECT pg_catalog.jsonb_agg(y.code ORDER BY y.o)
                             FROM (SELECT x.code, pg_catalog.min(x.o) AS o FROM pg_catalog.unnest(v_d) WITH ORDINALITY AS x(code, o)
                                    GROUP BY x.code) y), '[]'::jsonb),
    'complet', pg_catalog.cardinality(v_m) = 0);
END;
$f$;

-- La derniere chose que LE CANDIDAT a faite (jamais un geste de la direction, que `candidatures.derniere_activite` compte aussi) : un
-- geste du moteur fait par lui, un message de lui dans sa conversation de candidature, un depot de piece, une signature, un envoi du
-- questionnaire. A defaut : la reception de la candidature.
CREATE FUNCTION private.praxis_candidat_derniere_action(c public.candidatures)
RETURNS timestamptz
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT greatest(
    c.recue_le,
    (SELECT pg_catalog.max(e.cree_le) FROM public.candidature_evenements e
      WHERE e.candidature_id = c.id AND (e.details ->> 'auteur' = 'candidat' OR (c.profile_id IS NOT NULL AND e.auteur_id = c.profile_id))),
    (SELECT pg_catalog.max(m.envoye_le) FROM public.com_fils f JOIN public.com_messages m ON m.fil_id = f.id
      WHERE f.type_objet = 'candidature' AND f.objet_id = c.id AND c.profile_id IS NOT NULL AND m.auteur_id = c.profile_id),
    (SELECT pg_catalog.max(k.created_at) FROM public.kyc_documents k WHERE c.profile_id IS NOT NULL AND k.profile_id = c.profile_id),
    (SELECT pg_catalog.max(a.accepted_at) FROM public.contract_acceptances a WHERE c.profile_id IS NOT NULL AND a.profile_id = c.profile_id),
    (SELECT pg_catalog.max(r.soumis_le) FROM public.candidature_reponses r WHERE r.candidature_id = c.id AND r.source = 'candidat'));
$f$;

-- ====================================================================================================================
-- 2. RANGER EN PILES. Une ligne COURANTE par candidature ; l'historique est garde PAR AJOUT (la ligne precedente cesse d'etre courante,
-- rien n'est efface). Sans cle etrangere vers candidatures (comme private.praxis_propositions). La raison est ECRITE PAR PRAXIS a partir
-- des faits lus (200 signes au plus, sans nom de personne : regle de l'outil, que le serveur ne peut pas verifier).
-- ====================================================================================================================
CREATE TABLE private.praxis_rangements (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL,
  pile text NOT NULL CHECK (pile IN ('pret_a_decider', 'incomplet', 'a_regarder', 'sans_nouvelles')),
  raison text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(raison)) BETWEEN 1 AND 200 AND pg_catalog.length(raison) <= 200),
  courant boolean NOT NULL DEFAULT true,
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_idempotence uuid NOT NULL,
  range_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  UNIQUE (cle_id, cle_idempotence)
);
ALTER TABLE private.praxis_rangements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.praxis_rangements FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE UNIQUE INDEX praxis_rangements_courant_idx ON private.praxis_rangements (candidature_id) WHERE courant;
CREATE INDEX praxis_rangements_recents_idx ON private.praxis_rangements (range_le DESC);
ALTER TABLE private.praxis_rangements OWNER TO postgres;

CREATE FUNCTION public.praxis_ranger(p_cle text, p_candidature text, p_pile text, p_raison text, p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_raison text := pg_catalog.btrim(coalesce(p_raison, ''));
  v_c public.candidatures;
  v_existant bigint;
  v_courant private.praxis_rangements%ROWTYPE;
  v_id bigint;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_candidature IS NULL OR p_cle_idempotence IS NULL OR p_pile IS NULL
     OR p_pile NOT IN ('pret_a_decider', 'incomplet', 'a_regarder', 'sans_nouvelles') OR v_raison = '' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_raison) > 200 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-rangements', 0));
  -- Rejeu : la meme cle d'idempotence, rien d'ecrit.
  SELECT x.id INTO v_existant FROM private.praxis_rangements x WHERE x.cle_id = v_p.cle_id AND x.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'rejoue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'rejoue', true);
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = p_candidature;
  -- Un dossier inconnu, ferme, d'un autre type OU DE L'AUTRE COTE : la meme reponse (aucun indice d'existence), comme praxis_preparer.
  IF NOT FOUND OR v_c.type_code <> 'enseignant' OR v_c.issue <> 'en_cours' OR NOT (v_c.genre = ANY (v_p.cotes)) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'candidature_inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_inconnue');
  END IF;
  SELECT x.* INTO v_courant FROM private.praxis_rangements x WHERE x.candidature_id = v_c.id AND x.courant;
  -- Deja dans cette pile pour la meme raison : rien a ecrire (un passage horaire ne refait pas l'historique a l'identique).
  IF FOUND AND v_courant.pile = p_pile AND v_courant.raison = v_raison THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'inchange', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'inchange', true, 'pile', p_pile);
  END IF;
  -- Plafond : 60 rangements ecrits par heure glissante, toutes cles confondues.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_rangements x
       WHERE x.range_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 60 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'plafond_rangements', NULL, ARRAY[v_c.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_rangements');
  END IF;
  UPDATE private.praxis_rangements SET courant = false WHERE candidature_id = v_c.id AND courant;
  INSERT INTO private.praxis_rangements (candidature_id, pile, raison, cle_id, emise_par, cle_idempotence)
  VALUES (v_c.id, p_pile, v_raison, v_p.cle_id, v_p.emise_par, p_cle_idempotence)
  RETURNING id INTO v_id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ranger', 'ok', NULL, ARRAY[v_c.id], v_raison, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'pile', p_pile, 'pile_precedente', v_courant.pile);
END;
$f$;

-- La lecture de la direction, pour l'ecran a venir : les rangements COURANTS des candidatures encore en cours, du cote de la direction
-- qui lit (comme direction_praxis_propositions), pagines. Meme garde que direction_praxis_propositions et direction_praxis_questions.
CREATE FUNCTION public.direction_praxis_rangements(p_pile text DEFAULT NULL, p_limite integer DEFAULT 50, p_decalage integer DEFAULT 0)
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
  IF (p_pile IS NOT NULL AND p_pile NOT IN ('pret_a_decider', 'incomplet', 'a_regarder', 'sans_nouvelles'))
     OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 OR p_decalage IS NULL OR p_decalage NOT BETWEEN 0 AND 100000 THEN
    RAISE EXCEPTION 'pile, limite (1 a 200) ou decalage invalide' USING ERRCODE = '22023';
  END IF;
  WITH visibles AS (
    SELECT x.pile, x.raison, x.range_le, x.id AS rang_id, c.reference, c.nom_complet, c.etape, c.etat, c.genre, c.en_pause
      FROM private.praxis_rangements x
      JOIN public.candidatures c ON c.id = x.candidature_id
     WHERE x.courant AND c.type_code = 'enseignant' AND c.issue = 'en_cours'
       AND EXISTS (SELECT 1 FROM private.cand_lecteur() l WHERE l.super_admin OR l.genre = c.genre)
  )
  SELECT (SELECT coalesce(pg_catalog.jsonb_object_agg(k.pile, k.n), '{}'::jsonb)
            FROM (SELECT v.pile, pg_catalog.count(*)::integer AS n FROM visibles v GROUP BY v.pile) k),
         (SELECT pg_catalog.count(*)::integer FROM visibles v WHERE p_pile IS NULL OR v.pile = p_pile),
         (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'reference', y.reference, 'nom', y.nom_complet, 'cote', y.genre, 'etape', y.etape, 'etat', y.etat,
                    'enPause', y.en_pause, 'pile', y.pile, 'raison', y.raison, 'rangeLe', y.range_le)
                    ORDER BY y.range_le DESC, y.rang_id DESC), '[]'::jsonb)
            FROM (SELECT v.* FROM visibles v WHERE p_pile IS NULL OR v.pile = p_pile
                   ORDER BY v.range_le DESC, v.rang_id DESC LIMIT p_limite OFFSET p_decalage) y)
    INTO v_compte, v_total, v_lignes;
  RETURN pg_catalog.jsonb_build_object('rangements', v_lignes, 'total', v_total, 'parPile', v_compte);
END;
$f$;

-- ====================================================================================================================
-- 3. PROPOSER LA DISPENSE D'ENTRETIEN. Le CHECK du geste est REECRIT (trois gestes deviennent quatre) : le seul mot d'effacement du
-- fichier, sur une contrainte, sans toucher une ligne. Les fonctions retouchees sont plus bas (section 5).
-- ====================================================================================================================
ALTER TABLE private.praxis_propositions DROP CONSTRAINT praxis_propositions_geste_check;
ALTER TABLE private.praxis_propositions ADD CONSTRAINT praxis_propositions_geste_check
  CHECK (geste IN ('admettre_verifications', 'demander_complement', 'planifier_entretien', 'dispenser_entretien'));

-- ====================================================================================================================
-- 4. OBJECTIFS. Praxis se fixe des objectifs du JOUR ou de la SEMAINE (libelle de 200 signes au plus, SANS NOM DE PERSONNE : regle de
-- l'outil), avec une cible chiffree facultative, puis les clot (atteint ou abandonne) avec une note. Au plus 3 ouverts par jour et 3 par
-- semaine. Aucune donnee de personne : ces outils ne lisent aucun dossier (ils passent la porte ; ils ne dependent ni du mode essai ni
-- des donnees reelles, comme le calendrier).
-- ====================================================================================================================
CREATE TABLE private.praxis_objectifs (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  periode text NOT NULL CHECK (periode IN ('jour', 'semaine')),
  -- Le jour vise, ou le LUNDI de la semaine visee.
  debut date NOT NULL,
  libelle text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(libelle)) BETWEEN 1 AND 200 AND pg_catalog.length(libelle) <= 200),
  cible integer CHECK (cible IS NULL OR cible BETWEEN 1 AND 100000),
  etat text NOT NULL DEFAULT 'ouvert' CHECK (etat IN ('ouvert', 'atteint', 'abandonne')),
  note_cloture text CHECK (note_cloture IS NULL OR pg_catalog.length(note_cloture) <= 300),
  cle_id uuid NOT NULL REFERENCES private.praxis_cles (id),
  emise_par uuid NOT NULL REFERENCES public.profiles (id),
  cle_idempotence uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  clos_le timestamptz,
  UNIQUE (cle_id, cle_idempotence),
  CONSTRAINT praxis_objectifs_cloture_coherente CHECK ((etat = 'ouvert') = (clos_le IS NULL))
);
ALTER TABLE private.praxis_objectifs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.praxis_objectifs FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE INDEX praxis_objectifs_ouverts_idx ON private.praxis_objectifs (periode, debut) WHERE etat = 'ouvert';
CREATE INDEX praxis_objectifs_recents_idx ON private.praxis_objectifs (cree_le DESC, id);
ALTER TABLE private.praxis_objectifs OWNER TO postgres;

CREATE FUNCTION public.praxis_objectif_fixer(p_cle text, p_periode text, p_date date, p_libelle text, p_cible integer,
                                             p_cle_idempotence uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_libelle text := pg_catalog.btrim(coalesce(p_libelle, ''));
  v_jour date;
  v_existant uuid;
  v_id uuid;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_fixer', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_periode IS NULL OR p_periode NOT IN ('jour', 'semaine') OR p_date IS NULL OR p_cle_idempotence IS NULL OR v_libelle = ''
     -- Un jour : de la veille a dans 14 jours. Une semaine : tout jour de la semaine en cours (son lundi peut etre passe) a dans 14 jours.
     OR p_date < current_date - (CASE p_periode WHEN 'semaine' THEN 6 ELSE 1 END) OR p_date > current_date + 14 OR (p_cible IS NOT NULL AND p_cible NOT BETWEEN 1 AND 100000) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_fixer', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_libelle) > 200 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_fixer', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- Une semaine se range sous son lundi.
  v_jour := CASE p_periode WHEN 'semaine' THEN pg_catalog.date_trunc('week', p_date::timestamp)::date ELSE p_date END;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-objectifs', 0));
  SELECT o.id INTO v_existant FROM private.praxis_objectifs o WHERE o.cle_id = v_p.cle_id AND o.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_fixer', 'rejoue', NULL, ARRAY[v_existant], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existant, 'rejoue', true);
  END IF;
  -- Au plus 3 objectifs OUVERTS pour ce jour, et 3 pour cette semaine.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_objectifs o
       WHERE o.etat = 'ouvert' AND o.periode = p_periode AND o.debut = v_jour) >= 3 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_fixer', 'plafond_objectifs', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond_objectifs');
  END IF;
  INSERT INTO private.praxis_objectifs (periode, debut, libelle, cible, cle_id, emise_par, cle_idempotence)
  VALUES (p_periode, v_jour, v_libelle, p_cible, v_p.cle_id, v_p.emise_par, p_cle_idempotence)
  RETURNING id INTO v_id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_fixer', 'ok', NULL, ARRAY[v_id], v_libelle, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_id, 'periode', p_periode, 'debut', v_jour);
END;
$f$;

CREATE FUNCTION public.praxis_objectif_clore(p_cle text, p_objectif uuid, p_etat text, p_note text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_note text := nullif(pg_catalog.btrim(coalesce(p_note, '')), '');
  v_etat text;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_clore', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_objectif IS NULL OR p_etat IS NULL OR p_etat NOT IN ('atteint', 'abandonne') THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_clore', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(coalesce(v_note, '')) > 300 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_clore', 'longueur', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-objectifs', 0));
  UPDATE private.praxis_objectifs o SET etat = p_etat, note_cloture = v_note, clos_le = pg_catalog.clock_timestamp()
   WHERE o.id = p_objectif AND o.etat = 'ouvert';
  IF NOT FOUND THEN
    SELECT o.etat INTO v_etat FROM private.praxis_objectifs o WHERE o.id = p_objectif;
    -- Rejeu : deja clos dans le meme etat, rien d'ecrit.
    IF v_etat = p_etat THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_clore', 'rejoue', NULL, ARRAY[p_objectif], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('ok', true, 'rejoue', true);
    END IF;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_clore', CASE WHEN v_etat IS NULL THEN 'inconnu' ELSE 'deja_clos' END,
                                 NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', CASE WHEN v_etat IS NULL THEN 'inconnu' ELSE 'deja_clos' END);
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectif_clore', 'ok', NULL, ARRAY[p_objectif], v_note, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'etat', p_etat);
END;
$f$;

-- Les objectifs, en json, pour Praxis (ses propres textes) : `echu` dit que la periode est passee et qu'il reste ouvert.
CREATE FUNCTION private.praxis_objectifs_json(p_etat text, p_limite integer)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', o.id, 'periode', o.periode, 'debut', o.debut, 'libelle', o.libelle, 'cible', o.cible, 'etat', o.etat,
           'note_cloture', o.note_cloture, 'clos_le', o.clos_le,
           'echu', o.etat = 'ouvert' AND current_date > o.debut + CASE o.periode WHEN 'semaine' THEN 6 ELSE 0 END)
           ORDER BY o.debut DESC, o.cree_le DESC, o.id), '[]'::jsonb)
    FROM (SELECT x.* FROM private.praxis_objectifs x
           WHERE p_etat = 'tous' OR (p_etat = 'ouvert' AND x.etat = 'ouvert') OR (p_etat = 'clos' AND x.etat <> 'ouvert')
           ORDER BY x.debut DESC, x.cree_le DESC, x.id LIMIT p_limite) o;
$f$;

CREATE FUNCTION public.praxis_objectifs_lire(p_cle text, p_etat text DEFAULT 'ouvert', p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectifs_lire', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_etat IS NULL OR p_etat NOT IN ('ouvert', 'clos', 'tous') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectifs_lire', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'objectifs_lire', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('objectifs', private.praxis_objectifs_json(p_etat, p_limite));
END;
$f$;

CREATE FUNCTION public.direction_praxis_objectifs(p_filtre text DEFAULT 'ouverts', p_limite integer DEFAULT 50, p_decalage integer DEFAULT 0)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_lignes jsonb;
  v_total integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF p_filtre IS NULL OR p_filtre NOT IN ('ouverts', 'tous') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200
     OR p_decalage IS NULL OR p_decalage NOT BETWEEN 0 AND 100000 THEN
    RAISE EXCEPTION 'filtre (ouverts ou tous), limite (1 a 200) ou decalage invalide' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_total FROM private.praxis_objectifs o WHERE p_filtre = 'tous' OR o.etat = 'ouvert';
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', y.id, 'periode', y.periode, 'debut', y.debut, 'libelle', y.libelle, 'cible', y.cible, 'etat', y.etat,
           'noteCloture', y.note_cloture, 'creeLe', y.cree_le, 'closLe', y.clos_le,
           'echu', y.etat = 'ouvert' AND current_date > y.debut + CASE y.periode WHEN 'semaine' THEN 6 ELSE 0 END)
           ORDER BY y.debut DESC, y.cree_le DESC, y.id), '[]'::jsonb)
    INTO v_lignes
    FROM (SELECT o.* FROM private.praxis_objectifs o WHERE p_filtre = 'tous' OR o.etat = 'ouvert'
           ORDER BY o.debut DESC, o.cree_le DESC, o.id LIMIT p_limite OFFSET p_decalage) y;
  RETURN pg_catalog.jsonb_build_object('objectifs', v_lignes, 'total', v_total);
END;
$f$;

-- ====================================================================================================================
-- 5. Les six fonctions existantes, remplacees (empreintes controlees au preflight). Chaque ajout porte le mot PX-3.
-- ====================================================================================================================

-- 5.1 Les gestes que Praxis peut PREPARER : + dispenser_entretien.
CREATE OR REPLACE FUNCTION private.praxis_gestes_ligne(c candidatures, p_cotes gender[])
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  SELECT CASE WHEN c.genre = ANY (p_cotes)
              THEN pg_catalog.to_jsonb(ARRAY(SELECT g FROM pg_catalog.unnest(private.gestes_regles_de_la_ligne(c)) g
                                              -- PX-3 : + dispenser_entretien (20261129470000), propose comme les trois autres, jamais execute par Praxis.
                                              WHERE g IN ('admettre_verifications', 'demander_complement', 'planifier_entretien', 'dispenser_entretien')
                                              ORDER BY g))
              ELSE '[]'::jsonb END;
$function$;

-- 5.2 praxis_lire : la ligne d'une candidature rend aussi ce qui manque, l'inactivite du candidat, la conversation, la pile.
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
                'pile', (SELECT rg.pile FROM private.praxis_rangements rg WHERE rg.candidature_id = c2.id AND rg.courant))
           ORDER BY f.rang),
         '[]'::jsonb),
         coalesce(pg_catalog.max(f.total), 0)
    INTO v_lignes, v_total
    FROM (SELECT x.* FROM (SELECT c.id, c.reference, c.genre, c.langue, c.etape, c.etat, c.derniere_activite,
                                  (EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400)::integer AS attente,
                                  pg_catalog.split_part(pg_catalog.btrim(c.nom_complet), ' ', 1) AS prenom,
                                  pg_catalog.row_number() OVER (ORDER BY c.derniere_activite, c.id) AS rang,
                                  pg_catalog.count(*) OVER ()::integer AS total
                             FROM public.candidatures c
                            WHERE c.type_code = 'enseignant' AND c.issue = 'en_cours' AND c.genre = ANY (v_p.cotes)
                              AND (v_etape IS NULL OR c.etape = v_etape)
                              AND (v_etat IS NULL OR c.etat = v_etat)
                              AND (v_langue IS NULL OR c.langue = v_langue)
                              AND (v_min IS NULL
                                   OR EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400 >= v_min)) x
           WHERE x.rang <= p_limite) f
    JOIN public.candidatures c2 ON c2.id = f.id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('vue', 'candidatures', 'lignes', v_lignes, 'total', v_total);
END;
$function$;

-- 5.3 praxis_preparer : + le geste dispenser_entretien (categorie, motif).
CREATE OR REPLACE FUNCTION public.praxis_preparer(p_cle text, p_geste text, p_candidature text, p_parametres jsonb, p_texte text, p_cle_idempotence uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'essai', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'essai');
  END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'donnees_reelles_fermees', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'donnees_reelles_fermees');
  END IF;
  IF p_geste IS NULL OR p_geste NOT IN ('admettre_verifications', 'demander_complement', 'planifier_entretien', 'dispenser_entretien') -- PX-3
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
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.reference = p_candidature;
  -- Un dossier inconnu, ferme, d'un autre type OU DE L'AUTRE COTE : la meme reponse (aucun indice d'existence).
  IF NOT FOUND OR v_c.type_code <> 'enseignant' OR v_c.issue <> 'en_cours' OR NOT (v_c.genre = ANY (v_p.cotes)) THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'candidature_inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_inconnue');
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
  ELSIF p_geste = 'dispenser_entretien' THEN
    -- PX-3 : la dispense d'entretien (20261129470000). La categorie (fondateur ou autre) et le motif ecrit que le moteur exige ;
    -- rien d'autre. Praxis propose ; la direction valide ou ecarte ; le geste passe alors par public.dispenser_entretien.
    SELECT pg_catalog.string_agg(k.cle, ',') INTO v_inconnues
      FROM pg_catalog.jsonb_object_keys(v_parametres) AS k(cle) WHERE k.cle <> ALL (ARRAY['categorie', 'motif']);
    IF v_inconnues IS NOT NULL OR pg_catalog.jsonb_typeof(v_parametres -> 'categorie') IS DISTINCT FROM 'string'
       OR (v_parametres ->> 'categorie') NOT IN ('fondateur', 'autre')
       OR pg_catalog.jsonb_typeof(v_parametres -> 'motif') IS DISTINCT FROM 'string'
       OR pg_catalog.length(pg_catalog.btrim(v_parametres ->> 'motif')) NOT BETWEEN 1 AND 300 THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'preparer', 'parametre', NULL, ARRAY[v_c.id], NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
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
$function$;

-- 5.4 direction_praxis_valider : execute aussi dispenser_entretien ; un geste inconnu n'execute rien.
CREATE OR REPLACE FUNCTION public.direction_praxis_valider(p_proposition uuid, p_version integer, p_cle text, p_participants uuid[] DEFAULT NULL::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  SELECT x.* INTO v_pr FROM private.praxis_propositions x WHERE x.id = p_proposition;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_inconnue');
  END IF;
  -- Le COTE de la direction qui valide (AR-7 I2), avant tout verrou et avant tout statut : l'autre cote ne sait rien de la proposition.
  IF NOT EXISTS (SELECT 1 FROM private.cand_lecteur() l JOIN public.candidatures c ON c.id = v_pr.candidature_id
                  WHERE l.super_admin OR l.genre = c.genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  PERFORM private.praxis_propositions_expirer();
  SELECT x.* INTO v_pr FROM private.praxis_propositions x WHERE x.id = p_proposition FOR UPDATE;
  IF v_pr.statut = 'proposee' AND v_pr.expire_le <= pg_catalog.clock_timestamp() THEN
    UPDATE private.praxis_propositions SET statut = 'expiree' WHERE id = p_proposition;
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_expiree');
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
  ELSIF v_pr.geste = 'dispenser_entretien' THEN
    -- PX-3 : la porte publique du geste humain (20261129470000), sous l'identite de la direction qui valide : memes gardes
    -- (direction active, regle du moteur, version du dossier, motif ecrit, idempotence).
    v_r := public.dispenser_entretien(v_pr.candidature_id, v_pr.parametres ->> 'categorie', v_pr.parametres ->> 'motif',
             v_pr.version_candidature, p_cle);
  ELSIF v_pr.geste = 'admettre_verifications' THEN
    v_r := public.admettre_salle_verification(v_pr.candidature_id, v_pr.version_candidature, p_cle);
  ELSE
    -- PX-3 : un geste que cette porte ne connait pas n'execute RIEN (avant : toute autre valeur executait l'admission).
    RETURN pg_catalog.jsonb_build_object('erreur', 'geste_inconnu', 'proposition', p_proposition);
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
$function$;

-- 5.5 praxis_rendre_compte : + objectifs_ouverts, + propositions_en_attente.
CREATE OR REPLACE FUNCTION public.praxis_rendre_compte(p_cle text, p_heures integer DEFAULT 24)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_envois jsonb;
  v_refus integer;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_heures IS NULL OR p_heures NOT BETWEEN 1 AND 168 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'outil', j.outil, 'fil', j.fil_id, 'extrait', pg_catalog.left(j.texte_envoye, 300), 'heure', j.cree_le)
           ORDER BY j.cree_le DESC), '[]'::jsonb) INTO v_envois
    FROM (SELECT * FROM private.praxis_journal x
           WHERE x.outil IN ('ecrire', 'annoncer') AND x.issue = 'ok'
             AND (coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0 OR x.fil_id = ANY (private.praxis_essai()))
             AND x.cree_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => p_heures)
           ORDER BY x.cree_le DESC LIMIT 50) j;
  SELECT pg_catalog.count(*)::integer INTO v_refus FROM private.praxis_journal x
   WHERE x.outil IN ('ecrire', 'annoncer') AND x.issue <> 'ok' AND x.issue <> 'rejoue'
     AND x.cree_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => p_heures);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'rendre_compte', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('envoye', v_envois, 'refuses', v_refus,
    -- PX-3 : les objectifs encore ouverts (les textes de Praxis) et le nombre de propositions qui attendent la direction (de ses cotes).
    'objectifs_ouverts', private.praxis_objectifs_json('ouvert', 20),
    'propositions_en_attente', (SELECT pg_catalog.count(*)::integer FROM private.praxis_propositions pp
                                  JOIN public.candidatures pc ON pc.id = pp.candidature_id
                                 WHERE pp.statut = 'proposee' AND pp.expire_le > pg_catalog.clock_timestamp()
                                   AND pc.genre = ANY (v_p.cotes)),
    'laisse_en_attente', (SELECT pg_catalog.count(*)::integer FROM (
        SELECT f.id FROM public.com_fils f
         WHERE f.partie_b_nature = 'equipe' AND f.type_objet = ANY (private.praxis_types_fil())
           AND (coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0 OR f.id = ANY (private.praxis_essai()))
         ORDER BY coalesce(f.dernier_message_le, f.cree_le) DESC, f.id LIMIT 200) r
        WHERE private.praxis_fil_refus(r.id, v_p.cotes) IS NULL
          AND private.praxis_est_partie_a((SELECT m.auteur_id FROM public.com_messages m
                WHERE m.fil_id = r.id ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1), r.id)));
END;
$function$;

-- 5.6 praxis_noter_refus : connait les quatre outils neufs (note d'un refus de parametre, M4).
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
                                        'ranger', 'objectif_fixer', 'objectif_clore', 'objectifs_lire') THEN
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

-- ====================================================================================================================
-- 6. Proprietaire et droits. Les outils `praxis_*` au seul service_role ; les lectures `direction_praxis_*` aux comptes connectes (la
-- fonction exige une direction valide) ; les aides privees a personne. Les six fonctions remplacees gardent leurs droits (CREATE OR
-- REPLACE ne les change pas) : le controle final les reverifie.
-- ====================================================================================================================
ALTER FUNCTION private.praxis_dossier_manques(public.candidatures) OWNER TO postgres;
ALTER FUNCTION private.praxis_candidat_derniere_action(public.candidatures) OWNER TO postgres;
ALTER FUNCTION private.praxis_objectifs_json(text, integer) OWNER TO postgres;
ALTER FUNCTION public.praxis_ranger(text, text, text, text, uuid) OWNER TO postgres;
ALTER FUNCTION public.praxis_objectif_fixer(text, text, date, text, integer, uuid) OWNER TO postgres;
ALTER FUNCTION public.praxis_objectif_clore(text, uuid, text, text) OWNER TO postgres;
ALTER FUNCTION public.praxis_objectifs_lire(text, text, integer) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_rangements(text, integer, integer) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_objectifs(text, integer, integer) OWNER TO postgres;

REVOKE ALL ON FUNCTION private.praxis_dossier_manques(public.candidatures), private.praxis_candidat_derniere_action(public.candidatures),
  private.praxis_objectifs_json(text, integer)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.praxis_ranger(text, text, text, text, uuid), public.praxis_objectif_fixer(text, text, date, text, integer, uuid),
  public.praxis_objectif_clore(text, uuid, text, text), public.praxis_objectifs_lire(text, text, integer),
  public.direction_praxis_rangements(text, integer, integer), public.direction_praxis_objectifs(text, integer, integer)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.praxis_ranger(text, text, text, text, uuid), public.praxis_objectif_fixer(text, text, date, text, integer, uuid),
  public.praxis_objectif_clore(text, uuid, text, text), public.praxis_objectifs_lire(text, text, integer)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.direction_praxis_rangements(text, integer, integer), public.direction_praxis_objectifs(text, integer, integer)
  TO authenticated;

DO $postflight$
DECLARE
  v_f text;
  v_postgres oid := (SELECT r.oid FROM pg_catalog.pg_roles r WHERE r.rolname = 'postgres');
BEGIN
  -- Les outils de Praxis (neufs et remplaces) : service_role seul.
  FOREACH v_f IN ARRAY ARRAY[
    'public.praxis_ranger(text,text,text,text,uuid)', 'public.praxis_objectif_fixer(text,text,date,text,integer,uuid)',
    'public.praxis_objectif_clore(text,uuid,text,text)', 'public.praxis_objectifs_lire(text,text,integer)',
    'public.praxis_lire(text,text,jsonb,integer)', 'public.praxis_preparer(text,text,text,jsonb,text,uuid)',
    'public.praxis_rendre_compte(text,integer)', 'public.praxis_noter_refus(text,text)'] LOOP
    IF NOT pg_catalog.has_function_privilege('service_role', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-3 : droits incorrects sur %', v_f;
    END IF;
  END LOOP;
  -- Les portes de la direction : comptes connectes seuls (la fonction exige la direction).
  FOREACH v_f IN ARRAY ARRAY[
    'public.direction_praxis_rangements(text,integer,integer)', 'public.direction_praxis_objectifs(text,integer,integer)',
    'public.direction_praxis_valider(uuid,integer,text,uuid[])'] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-3 : droits incorrects sur %', v_f;
    END IF;
  END LOOP;
  -- Les aides privees : aucun role client.
  FOREACH v_f IN ARRAY ARRAY[
    'private.praxis_dossier_manques(public.candidatures)', 'private.praxis_candidat_derniere_action(public.candidatures)',
    'private.praxis_objectifs_json(text,integer)', 'private.praxis_gestes_ligne(public.candidatures,public.gender[])'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f, 'EXECUTE') OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-3 : une aide privee est executable par un role client : %', v_f;
    END IF;
  END LOOP;
  -- Les tables : RLS active, aucune politique, aucun droit client, vides.
  FOREACH v_f IN ARRAY ARRAY['private.praxis_rangements', 'private.praxis_objectifs'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = v_f::pg_catalog.regclass)
       OR EXISTS (SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = v_f::pg_catalog.regclass)
       OR pg_catalog.has_table_privilege('anon', v_f, 'SELECT') OR pg_catalog.has_table_privilege('authenticated', v_f, 'SELECT')
       OR pg_catalog.has_table_privilege('service_role', v_f, 'SELECT') OR pg_catalog.has_table_privilege('agent_ro', v_f, 'SELECT') THEN
      RAISE EXCEPTION 'PX-3 : RLS ou droits incorrects sur %', v_f;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM private.praxis_rangements) OR EXISTS (SELECT 1 FROM private.praxis_objectifs) THEN
    RAISE EXCEPTION 'PX-3 : une table neuve n''est pas vide';
  END IF;
  -- Les fonctions remplacees gardent SECURITY DEFINER, leur proprietaire, et portent la retouche.
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid IN ('public.praxis_lire(text,text,jsonb,integer)'::pg_catalog.regprocedure,
                              'public.praxis_preparer(text,text,text,jsonb,text,uuid)'::pg_catalog.regprocedure,
                              'public.direction_praxis_valider(uuid,integer,text,uuid[])'::pg_catalog.regprocedure,
                              'public.praxis_rendre_compte(text,integer)'::pg_catalog.regprocedure,
                              'public.praxis_noter_refus(text,text)'::pg_catalog.regprocedure)
                AND (NOT p.prosecdef OR p.proowner <> v_postgres OR p.prosrc NOT LIKE '%PX-3%'
                     OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""'])) THEN
    RAISE EXCEPTION 'PX-3 : une fonction remplacee a perdu SECURITY DEFINER, son proprietaire, son search_path ou sa retouche';
  END IF;
  IF (SELECT p.prosrc FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.praxis_gestes_ligne(public.candidatures,public.gender[])'::pg_catalog.regprocedure) NOT LIKE '%dispenser_entretien%' THEN
    RAISE EXCEPTION 'PX-3 : praxis_gestes_ligne sans dispenser_entretien';
  END IF;
  -- Rien n'est allume ni ouvert par cette migration : aucun reglage n'est ecrit (controle de presence seulement).
  IF (SELECT pg_catalog.count(*) FROM private.praxis_reglages) <> 1 THEN
    RAISE EXCEPTION 'PX-3 : private.praxis_reglages inattendue';
  END IF;
END
$postflight$;
