-- PRAXIS PX-5 (20/11/2026) : Praxis sait OU EN EST la personne qui lui ecrit, pagine ses lectures, ferme ses propres questions, et ouvre
-- plus de conversations (directeur, 20/11/2026 : « releve le plafond a 100 toutes les 5h »).
-- Cahier : docs/current/BUREAU-EQUIPE/PRAXIS/CAHIER-PX-5.md. Bati sur PX-4 (20261130200000, installe en production le 20/11/2026),
-- memes conventions, memes gardes.
--
-- LE PROBLEME (constate en production dans la nuit du 20/11/2026) : Praxis a repondu a une candidate « nous etudions les candidatures dans
-- l'ordre » alors que son dossier avait ete admis a l'etape suivante trois jours plus tot. Les outils `boite` et `fil`, qui servent a
-- repondre, ne rendaient RIEN du dossier auquel la conversation appartient.
--
-- LIVRE ICI :
--   1. `boite` et `fil` rendent, pour une conversation de CANDIDATURE, un objet `dossier` : reference, etape, etat, issue, complet,
--      manquants, attend_direction (memes aides que `lire` : private.praxis_dossier_manques, rien de recopie), informe_de_l_etape (un
--      membre humain de l'equipe ou Praxis a ecrit dans la conversation APRES la derniere transition d'etape), etape_depuis_jours.
--      null si le dossier est ferme a Praxis (memes exclusions que `dossier` : essai, donnees reelles fermees, refuse, retire, en pause,
--      restreint, majorite non attestee, mineur, autre cote). Aucun nom, courriel, telephone ni autre donnee de personne.
--   2. `lire` : un `decalage` (dans le filtre, entier de 0 a 5000) pour paginer ; chaque ligne rend `fil` (la conversation de
--      candidature quand elle existe et que Praxis peut la lire) ; `total` est juste meme quand la page est vide ; `decalage` et `reste`.
--   3. Deux outils neufs : `questions_ouvertes` (praxis_questions_ouvertes) et `retirer_question` (praxis_retirer_question). Deux
--      colonnes neuves dans private.praxis_questions (retiree_le, retiree_motif) ; une question retiree n'est plus ouverte pour
--      `demander_equipe`, `questions_ouvertes` et la liste de la direction. Jamais d'effacement.
--   4. Le plafond des ouvertures de dialogue (`ouvrir`) : 100 par fenetre GLISSANTE de 5 heures, au total (au lieu de 25 par 24 heures),
--      REGLABLE : deux colonnes neuves de private.praxis_reglages (ouvertures_par_fenetre, ouvertures_fenetre_heures), une porte neuve
--      de la direction (direction_praxis_regler_ouvertures, aal2, journalisee). `etat` rend ouverturesRestantesFenetre.
--
-- MOTS D'EFFACEMENT : ZERO. Aucune contrainte existante reecrite, aucun index retire.
--
-- FONCTIONS EXISTANTES REMPLACEES (CREATE OR REPLACE a signature identique, droits et proprietaire conserves), apres controle de
-- l'empreinte md5(prosrc). Le corps est celui de la DERNIERE definition, recopie par pg_get_functiondef sur une base rejouee jusqu'a PX-4,
-- plus le necessaire (chaque ajout porte le mot PX-5) :
--   * public.praxis_boite(text, text, integer)           <- 20261129650000 (mode essai). Appelant : l'outil `boite`.
--   * public.praxis_fil(text, uuid, integer)             <- 20261129600000 (socle). Appelant : l'outil `fil`.
--   * public.praxis_lire(text, text, jsonb, integer)     <- 20261130200000 (PX-4). Appelant : l'outil `lire`.
--   * public.praxis_demander_equipe(text, uuid, text)    <- 20261129930000 (PX-SUIVI). Appelant : l'outil `demander_equipe`.
--   * public.praxis_reponses_equipe(text, integer)       <- 20261129930000 (PX-SUIVI). Appelant : l'outil `reponses_equipe`.
--   * public.direction_praxis_questions(integer)         <- 20261129930000 (PX-SUIVI). Appelant : lib/core/agent/questions_praxis.dart.
--   * public.praxis_noter_refus(text, text)              <- 20261130200000 (PX-4). Appelant : praxis-mcp (refus de parametre).
--   * private.praxis_ouverture_refus(candidatures, text, gender[]) <- 20261130200000 (PX-4). Appelants : praxis_ouvrir, praxis_boite_candidats.
--   * public.praxis_etat(text)                           <- 20261130200000 (PX-4). Appelant : l'outil `etat`.
-- `praxis_rendre_compte` ne lit pas private.praxis_questions (verifie : aucune fonction hors des cinq ci-dessus ne la lit) : non touchee.
-- `praxis_question_traitee` ne touche que des questions REPONDUES : non touchee. `direction_praxis_repondre` non touchee (voir le cahier).
-- Rien n'est allume par cette migration. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regclass('private.praxis_questions') IS NULL OR pg_catalog.to_regclass('private.praxis_reglages') IS NULL
     OR pg_catalog.to_regclass('private.praxis_ouvertures') IS NULL OR pg_catalog.to_regclass('private.praxis_impressions') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_dossier_ouvert(public.candidatures,public.gender[])') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_fil_candidature(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_dossier_manques(public.candidatures)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_fil_refus(uuid,public.gender[])') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_est_equipe(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL THEN
    RAISE EXCEPTION 'PX-5 : dependances absentes (PX-4, PX-SUIVI, socle) ; rien n''est modifie';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a WHERE a.attrelid = 'private.praxis_questions'::pg_catalog.regclass
              AND a.attname IN ('retiree_le', 'retiree_motif') AND NOT a.attisdropped)
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a WHERE a.attrelid = 'private.praxis_reglages'::pg_catalog.regclass
                 AND a.attname IN ('ouvertures_par_fenetre', 'ouvertures_fenetre_heures') AND NOT a.attisdropped)
     OR pg_catalog.to_regprocedure('public.praxis_questions_ouvertes(text,integer)') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-5 : deja installe ; rien n''est modifie';
  END IF;
  FOR v IN SELECT * FROM (VALUES
      ('public.praxis_boite(text,text,integer)', '5e1ceb568ce2807ccd7032c4639b14e0'),
      ('public.praxis_fil(text,uuid,integer)', '194769e309d65656b1a83ba9c7030a01'),
      ('public.praxis_lire(text,text,jsonb,integer)', '1ccdd89e67ac1e0b431866f944477473'),
      ('public.praxis_demander_equipe(text,uuid,text)', '8885e3e89621ffeade260ef8fed35d49'),
      ('public.praxis_reponses_equipe(text,integer)', '4f6ba9024bfadbe123575543742e461f'),
      ('public.direction_praxis_questions(integer)', '4c0f489e078d60b10eb99c58872730c0'),
      ('public.praxis_noter_refus(text,text)', '580fef3b5c94c797ee3d1ba18c1bb0bd'),
      ('private.praxis_ouverture_refus(public.candidatures,text,public.gender[])', 'ec4efc90af75d189a269ca7d8fa05e8c'),
      ('public.praxis_etat(text)', 'f5eff392d5eaccf1e225546cfea60cef')) AS t(f, md5) LOOP
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v.f::pg_catalog.regprocedure) IS DISTINCT FROM v.md5 THEN
      RAISE EXCEPTION 'PX-5 : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
  -- Aucune autre fonction ne lit la table des questions (sinon elle compterait encore une question retiree comme ouverte).
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.prosrc ~ 'private\.praxis_questions\M'
                AND p.oid NOT IN ('public.praxis_demander_equipe(text,uuid,text)'::pg_catalog.regprocedure,
                  'public.praxis_reponses_equipe(text,integer)'::pg_catalog.regprocedure, 'public.praxis_question_traitee(text,uuid)'::pg_catalog.regprocedure,
                  'public.direction_praxis_questions(integer)'::pg_catalog.regprocedure, 'public.direction_praxis_repondre(uuid,text)'::pg_catalog.regprocedure)) THEN
    RAISE EXCEPTION 'PX-5 : une fonction inattendue lit private.praxis_questions ; rien n''est modifie';
  END IF;
END
$preflight$;

-- ====================================================================================================================
-- 1. COLONNES NEUVES. Rien d'existant n'est touche : deux colonnes par table, avec leurs CHECK propres.
-- ====================================================================================================================

-- 1.1 Le retrait d'une question par Praxis (il a repondu seul a la personne, ou la question n'a plus d'objet). Les deux colonnes vont
-- ensemble ; le motif est une liste fermee (aucun texte libre).
ALTER TABLE private.praxis_questions
  ADD COLUMN retiree_le timestamptz,
  ADD COLUMN retiree_motif text,
  ADD CONSTRAINT praxis_questions_retrait_coherent CHECK ((retiree_le IS NULL) = (retiree_motif IS NULL)),
  ADD CONSTRAINT praxis_questions_retrait_motif CHECK (retiree_motif IS NULL OR retiree_motif IN ('repondu_par_praxis', 'sans_objet'));
CREATE INDEX praxis_questions_ouvertes_idx ON private.praxis_questions (posee_le, id) WHERE repondue_le IS NULL AND retiree_le IS NULL;

-- 1.2 Le plafond des ouvertures de dialogue : 100 par fenetre glissante de 5 heures (directeur, 20/11/2026). Bornes : 1 a 500 ouvertures,
-- fenetre de 1 a 48 heures.
ALTER TABLE private.praxis_reglages
  ADD COLUMN ouvertures_par_fenetre integer NOT NULL DEFAULT 100 CHECK (ouvertures_par_fenetre BETWEEN 1 AND 500),
  ADD COLUMN ouvertures_fenetre_heures integer NOT NULL DEFAULT 5 CHECK (ouvertures_fenetre_heures BETWEEN 1 AND 48);

-- ====================================================================================================================
-- 2. AIDE PRIVEE : ou en est le dossier d'une conversation de candidature. NULL des que le dossier est ferme a Praxis.
-- ====================================================================================================================
-- « La derniere transition d'etape » : le dernier evenement du moteur qui fait ENTRER le dossier dans son etape actuelle (etape_apres =
-- etape courante, etape_avant differente). A defaut (aucun evenement), la reception du dossier. « Informe » : un message de Praxis ou d'un
-- membre HUMAIN de l'equipe de la conversation (private.praxis_est_equipe, qui exclut le compte officiel de l'academie) envoye apres.
CREATE FUNCTION private.praxis_dossier_resume(p_fil uuid, p_cotes public.gender[])
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $f$
DECLARE
  v_type text;
  v_objet uuid;
  v_c public.candidatures;
  v_transition timestamptz;
  v_praxis uuid := private.praxis_profil();
BEGIN
  IF p_fil IS NULL THEN RETURN NULL; END IF;
  -- Memes portes que praxis_dossier : ni en mode essai, ni tant que les donnees reelles sont fermees.
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0 THEN RETURN NULL; END IF;
  IF NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN RETURN NULL; END IF;
  SELECT f.type_objet, f.objet_id INTO v_type, v_objet FROM public.com_fils f WHERE f.id = p_fil;
  IF v_type IS DISTINCT FROM 'candidature' THEN RETURN NULL; END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_objet;
  -- Ferme (refuse, retire, en pause, restreint, majorite non attestee, mineur, autre cote, autre type) : rien.
  IF NOT FOUND OR NOT private.praxis_dossier_ouvert(v_c, p_cotes) OR private.praxis_fil_candidature(v_c) IS DISTINCT FROM p_fil THEN
    RETURN NULL;
  END IF;
  SELECT pg_catalog.max(e.cree_le) INTO v_transition FROM public.candidature_evenements e
   WHERE e.candidature_id = v_c.id AND e.etape_apres = v_c.etape AND e.etape_avant IS DISTINCT FROM e.etape_apres;
  v_transition := coalesce(v_transition, v_c.recue_le);
  RETURN pg_catalog.jsonb_build_object(
      'reference', v_c.reference,
      'etape', v_c.etape,
      'etat', v_c.etat,
      'issue', v_c.issue,
      'etape_depuis_jours', pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - v_transition) / 86400)::integer,
      'informe_de_l_etape', EXISTS (SELECT 1 FROM public.com_messages m
                                     WHERE m.fil_id = p_fil AND m.envoye_le > v_transition
                                       AND (m.auteur_id = v_praxis OR private.praxis_est_equipe(m.auteur_id, p_fil))))
    -- manquants, attend_direction, complet : les CODES de PX-3, par la meme aide que `lire` et `dossier`.
    || private.praxis_dossier_manques(v_c);
END;
$f$;

-- ====================================================================================================================
-- 3. OUTILS NEUFS : les questions ouvertes, et le retrait d'une question par Praxis.
-- ====================================================================================================================

-- 3.1 `questions_ouvertes` : les questions posees a la direction, sans reponse et non retirees, des conversations encore ouvertes a Praxis
-- (les autres restent a l'equipe). La question est celle que Praxis a lui-meme resumee (300 signes au plus).
CREATE FUNCTION public.praxis_questions_ouvertes(p_cle text, p_limite integer DEFAULT 20)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_liste jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'questions_ouvertes', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'questions_ouvertes', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(x.j ORDER BY x.le, x.id), '[]'::jsonb) INTO v_liste
    FROM (SELECT r.posee_le AS le, r.id,
                 pg_catalog.jsonb_build_object('id', r.id, 'fil', r.fil_id, 'question', r.question, 'posee_le', r.posee_le,
                   'age_heures', pg_catalog.floor(EXTRACT(epoch FROM pg_catalog.clock_timestamp() - r.posee_le) / 3600)::integer) AS j
            FROM (SELECT q.* FROM private.praxis_questions q
                   WHERE q.repondue_le IS NULL AND q.retiree_le IS NULL
                   ORDER BY q.posee_le, q.id LIMIT 200) r
           WHERE private.praxis_fil_refus(r.fil_id, v_p.cotes) IS NULL
           ORDER BY r.posee_le, r.id LIMIT p_limite) x;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'questions_ouvertes', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('questions', v_liste);
END;
$f$;

-- 3.2 `retirer_question` : Praxis ferme SA question (sans reponse, non retiree) quand il a repondu seul a la personne
-- (`repondu_par_praxis`) ou qu'elle n'a plus d'objet (`sans_objet`). Seulement si la conversation lui est encore ouverte. Une fois.
-- La ligne est GARDEE (deux colonnes remplies), jamais effacee ; la question reste lisible par la direction, marquee retiree.
CREATE FUNCTION public.praxis_retirer_question(p_cle text, p_question uuid, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_fil uuid;
  v_etat text;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'retirer_question', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_question IS NULL OR p_motif IS NULL OR p_motif NOT IN ('repondu_par_praxis', 'sans_objet') THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'retirer_question', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  -- La ligne est verrouillee : une reponse de la direction et un retrait ne peuvent pas se croiser.
  SELECT q.fil_id, CASE WHEN q.repondue_le IS NOT NULL THEN 'deja_repondue' WHEN q.retiree_le IS NOT NULL THEN 'deja_retiree' END
    INTO v_fil, v_etat
    FROM private.praxis_questions q WHERE q.id = p_question FOR UPDATE;
  -- Inconnue, ou d'une conversation qui n'est plus ouverte a Praxis (cote, mineur, type ferme, essai...) : la meme reponse.
  IF NOT FOUND OR private.praxis_fil_refus(v_fil, v_p.cotes) IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'retirer_question', 'inconnue', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'inconnue');
  END IF;
  IF v_etat IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'retirer_question', v_etat, v_fil, ARRAY[p_question], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_etat);
  END IF;
  UPDATE private.praxis_questions q SET retiree_le = pg_catalog.clock_timestamp(), retiree_motif = p_motif
   WHERE q.id = p_question AND q.repondue_le IS NULL AND q.retiree_le IS NULL;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'retirer_question', 'ok', v_fil, ARRAY[p_question], p_motif, v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$f$;

-- 3.3 La direction regle le plafond des ouvertures (aal2, journalise), comme direction_praxis_regler_plafond.
CREATE FUNCTION public.direction_praxis_regler_ouvertures(p_par_fenetre integer, p_fenetre_heures integer)
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
  IF p_par_fenetre IS NULL OR p_par_fenetre NOT BETWEEN 1 AND 500 OR p_fenetre_heures IS NULL OR p_fenetre_heures NOT BETWEEN 1 AND 48 THEN
    RAISE EXCEPTION 'plafond des ouvertures invalide : 1 a 500 ouvertures, fenetre de 1 a 48 heures' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_reglages
     SET ouvertures_par_fenetre = p_par_fenetre, ouvertures_fenetre_heures = p_fenetre_heures,
         modifie_par = auth.uid(), modifie_le = pg_catalog.clock_timestamp()
   WHERE id;
  PERFORM public.log_sensitive_access('praxis_regle_ouvertures', 'private.praxis_reglages', 'praxis',
    pg_catalog.jsonb_build_object('ouverturesParFenetre', p_par_fenetre, 'ouverturesFenetreHeures', p_fenetre_heures));
  RETURN pg_catalog.jsonb_build_object('ouverturesParFenetre', p_par_fenetre, 'ouverturesFenetreHeures', p_fenetre_heures);
END;
$f$;

-- ====================================================================================================================
-- 4. FONCTIONS EXISTANTES REMPLACEES (empreintes controlees plus haut).
-- ====================================================================================================================

-- 4.1 public.praxis_boite(text,text,integer) (corps de la derniere definition, ajouts marques PX-5).
CREATE OR REPLACE FUNCTION public.praxis_boite(p_cle text, p_filtre text DEFAULT 'attend'::text, p_limite integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_fils jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_filtre IS NULL OR p_filtre NOT IN ('attend', 'non_lu', 'tout') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  WITH recents AS (
    SELECT f.* FROM public.com_fils f
     WHERE f.partie_b_nature = 'equipe' AND f.type_objet = ANY (private.praxis_types_fil())
       AND (coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0 OR f.id = ANY (private.praxis_essai()))
     ORDER BY coalesce(f.dernier_message_le, f.cree_le) DESC, f.id
     LIMIT 200
  ), base AS (
    SELECT f.id, f.type_objet, f.partie_a_nature, f.partie_a_id,
           d.auteur_id AS dernier_auteur, d.texte AS dernier_texte, d.envoye_le AS dernier_le,
           (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m
             WHERE m.fil_id = f.id AND (m.auteur_id = private.praxis_profil() OR private.praxis_est_equipe(m.auteur_id, f.id))) AS derniere_academie
      FROM recents f
      JOIN LATERAL (SELECT m.auteur_id, m.texte, m.envoye_le FROM public.com_messages m
                     WHERE m.fil_id = f.id ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1) d ON true
     WHERE private.praxis_fil_refus(f.id, v_p.cotes) IS NULL
  ), calc AS (
    SELECT b.*,
           private.praxis_est_partie_a(b.dernier_auteur, b.id) AS attend,
           (SELECT pg_catalog.count(*) FROM public.com_messages m
             WHERE m.fil_id = b.id AND private.praxis_est_partie_a(m.auteur_id, b.id)
               AND m.envoye_le > coalesce(b.derniere_academie, '-infinity'::timestamptz))::integer AS sans_reponse
      FROM base b
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', c.id, 'type', c.type_objet,
           'interlocuteur', CASE c.partie_a_nature
              WHEN 'profil' THEN private.praxis_auteur_json(c.partie_a_id, c.id)
              ELSE pg_catalog.jsonb_build_object('role', 'famille') END,
           'dernier_auteur', private.praxis_auteur_json(c.dernier_auteur, c.id),
           -- Tout texte qui n'est pas de Praxis (prenoms compris, messages de l'equipe compris) est une DONNEE de tiers.
           'contenu_tiers', CASE WHEN c.dernier_auteur = private.praxis_profil() THEN NULL
              ELSE pg_catalog.jsonb_build_object(
                'prenoms', CASE c.partie_a_nature
                  WHEN 'profil' THEN (SELECT pg_catalog.jsonb_build_array(p.first_name) FROM public.profiles p WHERE p.id = c.partie_a_id)
                  ELSE coalesce((SELECT pg_catalog.jsonb_agg(g.first_name ORDER BY g.first_name, g.id) FROM public.profiles g
                                  WHERE g.household_id = c.partie_a_id AND g.role = 'guardian'::public.app_role
                                    AND g.deleted_at IS NULL), '[]'::jsonb) END,
                'dernier_message', pg_catalog.left(c.dernier_texte, 300)) END,
           'attente_heures', CASE WHEN c.attend
              THEN (EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.dernier_le) / 3600)::integer END,
           'sans_reponse', c.sans_reponse,
           'repris_par_equipe', EXISTS (SELECT 1 FROM public.com_messages m
             WHERE m.fil_id = c.id AND private.praxis_est_equipe(m.auteur_id, c.id)
               AND m.envoye_le > coalesce((SELECT pg_catalog.max(x.envoye_le) FROM public.com_messages x
                                            WHERE x.fil_id = c.id AND x.auteur_id = private.praxis_profil()),
                                          'infinity'::timestamptz)),
           -- PX-5 : ou en est le DOSSIER de la personne (conversation de candidature seulement ; null si le dossier est ferme a Praxis).
           'dossier', CASE WHEN c.type_objet = 'candidature' THEN private.praxis_dossier_resume(c.id, v_p.cotes) END
         ) ORDER BY c.dernier_le DESC), '[]'::jsonb)
    INTO v_fils
    FROM (SELECT * FROM calc c2
           WHERE p_filtre = 'tout' OR (p_filtre = 'attend' AND c2.attend) OR (p_filtre = 'non_lu' AND c2.sans_reponse > 0)
           ORDER BY c2.dernier_le DESC LIMIT p_limite) c;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('fils', v_fils);
END;
$function$;

-- 4.2 public.praxis_fil(text,uuid,integer) (corps de la derniere definition, ajouts marques PX-5).
CREATE OR REPLACE FUNCTION public.praxis_fil(p_cle text, p_fil uuid, p_limite integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_refus text;
  v_msgs jsonb;
  v_dernier uuid;
  v_derniere_praxis timestamptz;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  v_refus := private.praxis_fil_refus(p_fil, v_p.cotes);
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_praxis FROM public.com_messages m
   WHERE m.fil_id = p_fil AND m.auteur_id = private.praxis_profil();
  SELECT m.auteur_id INTO v_dernier FROM public.com_messages m WHERE m.fil_id = p_fil
   ORDER BY m.envoye_le DESC, m.id DESC LIMIT 1;
  SELECT coalesce(pg_catalog.jsonb_agg(x.j ORDER BY x.le), '[]'::jsonb) INTO v_msgs
    FROM (SELECT m.envoye_le AS le, pg_catalog.jsonb_build_object(
                   'auteur', private.praxis_auteur_json(m.auteur_id, p_fil),
                   'est_praxis', m.auteur_id = private.praxis_profil(),
                   'envoye_le', m.envoye_le)
                 || CASE
                      WHEN EXISTS (SELECT 1 FROM public.com_message_images i WHERE i.message_id = m.id)
                        THEN pg_catalog.jsonb_build_object('image', true)
                      WHEN m.auteur_id = private.praxis_profil()
                        THEN pg_catalog.jsonb_build_object('texte', pg_catalog.left(m.texte, 1500))
                      -- AR-7 I6 : tout texte qui n'est pas de Praxis (message de la personne OU de l'equipe, prenom) est une donnee.
                      ELSE pg_catalog.jsonb_build_object('contenu_tiers', pg_catalog.jsonb_build_object(
                             'prenom', (SELECT p.first_name FROM public.profiles p WHERE p.id = m.auteur_id),
                             'texte', pg_catalog.left(m.texte, 1500))) END AS j
            FROM public.com_messages m WHERE m.fil_id = p_fil
           ORDER BY m.envoye_le DESC, m.id DESC LIMIT p_limite) x;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'fil', 'ok', p_fil, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object(
    'fil', p_fil,
    -- PX-5 : ou en est le dossier de la personne (null hors candidature ou si le dossier est ferme a Praxis).
    'dossier', private.praxis_dossier_resume(p_fil, v_p.cotes),
    'messages', v_msgs,
    'dernier_auteur', private.praxis_auteur_json(v_dernier, p_fil),
    'repris_par_equipe', v_derniere_praxis IS NOT NULL AND EXISTS (
       SELECT 1 FROM public.com_messages m
        WHERE m.fil_id = p_fil AND private.praxis_est_equipe(m.auteur_id, p_fil) AND m.envoye_le > v_derniere_praxis));
END;
$function$;

-- 4.3 public.praxis_lire(text,text,jsonb,integer) (corps de la derniere definition, ajouts marques PX-5).
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
  -- PX-5 : la pagination.
  v_decalage integer := 0;
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
                            'etiquette', 'sans_impression', 'ijaza', 'riwaya', 'langue_explication', 'public', 'tri',
                            -- PX-5 : le decalage de la page (entier de 0 a 5000).
                            'decalage']);
  IF v_inconnues IS NOT NULL
     OR coalesce((SELECT pg_catalog.bool_or(pg_catalog.jsonb_typeof(e.value) <>
                         CASE WHEN e.key IN ('attente_min_jours', 'decalage') THEN 'number' -- PX-5 : decalage
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
  -- PX-5 : le decalage, un entier de 0 a 5000 ; tout autre est refuse `parametre` et journalise.
  BEGIN
    IF v_filtre ? 'decalage' THEN
      v_nb := (v_filtre ->> 'decalage')::numeric;
      v_decalage := CASE WHEN v_nb = pg_catalog.trunc(v_nb) AND v_nb BETWEEN 0 AND 5000 THEN v_nb::integer ELSE -1 END;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_decalage := -1;
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
     OR v_tri NOT IN ('attente', 'vision')
     OR v_decalage NOT BETWEEN 0 AND 5000 THEN -- PX-5
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
  -- PX-5 : la page commence apres `decalage` lignes (ordre total : le tri, puis derniere_activite, puis id : ni doublon ni trou entre
  -- deux pages tant que les dossiers ne bougent pas) ; `total` est le nombre de lignes du filtre, meme quand la page est vide.
  WITH x AS (SELECT c.id, c.reference, c.genre, c.langue, c.etape, c.etat, c.derniere_activite,
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
                                   OR EXTRACT(epoch FROM pg_catalog.clock_timestamp() - c.derniere_activite) / 86400 >= v_min))
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
                -- PX-5 : l'identifiant de la conversation de candidature, quand elle existe ET que Praxis peut la lire ; sinon null.
                'fil', (SELECT fc.id FROM (SELECT private.praxis_fil_candidature(c2) AS id) fc
                         WHERE fc.id IS NOT NULL AND private.praxis_fil_refus(fc.id, v_p.cotes) IS NULL),
                'pile', (SELECT rg.pile FROM private.praxis_rangements rg WHERE rg.candidature_id = c2.id AND rg.courant),
                -- PX-4 : l'impression courante de Praxis (etiquette, note de vision, confiance), pour trier ; NULL si jamais lue.
                'impression', (SELECT pg_catalog.jsonb_build_object('etiquette', im.etiquette, 'vision', im.vision, 'confiance', im.confiance)
                                 FROM private.praxis_impressions im WHERE im.candidature_id = c2.id AND im.courant))
           ORDER BY f.rang),
         '[]'::jsonb),
         (SELECT coalesce(pg_catalog.max(xt.total), 0) FROM x xt)
    INTO v_lignes, v_total
    FROM (SELECT x.* FROM x
           WHERE x.rang > v_decalage AND x.rang <= v_decalage + p_limite) f
    JOIN public.candidatures c2 ON c2.id = f.id;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'lire', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('vue', 'candidatures', 'lignes', v_lignes, 'total', v_total,
    -- PX-5 : la page rendue et ce qu'il reste apres elle.
    'decalage', v_decalage, 'reste', greatest(v_total - v_decalage - pg_catalog.jsonb_array_length(v_lignes), 0));
END;
$function$;

-- 4.4 public.praxis_demander_equipe(text,uuid,text) (corps de la derniere definition, ajouts marques PX-5).
CREATE OR REPLACE FUNCTION public.praxis_demander_equipe(p_cle text, p_fil uuid, p_question text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_refus text;
  v_id uuid;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_question IS NULL OR pg_catalog.length(pg_catalog.btrim(p_question)) NOT BETWEEN 1 AND 300
     OR pg_catalog.length(p_question) > 300 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  -- La conversation doit etre ouverte a Praxis par la porte existante (inconnue, hors academie, type ferme, mineur, cote, essai...).
  v_refus := private.praxis_fil_refus(p_fil, v_p.cotes);
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  -- Plafonds : 20 questions par cle et par heure, 100 questions ouvertes au plus.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_questions q
       WHERE q.cle_id = v_p.cle_id AND q.posee_le > pg_catalog.clock_timestamp() - interval '1 hour') >= 20 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'plafond', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'plafond');
  END IF;
  -- PX-5 : une question RETIREE par Praxis n'est plus ouverte.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_questions q WHERE q.repondue_le IS NULL AND q.retiree_le IS NULL) >= 100 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'trop_ouvertes', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'trop_ouvertes');
  END IF;
  BEGIN
    INSERT INTO private.praxis_questions (fil_id, cle_id, question)
    VALUES (p_fil, v_p.cle_id, pg_catalog.btrim(p_question))
    RETURNING id INTO v_id;
  EXCEPTION WHEN unique_violation THEN
    -- PX-5 : l'index « une question sans reponse par conversation » compte encore une question RETIREE (il ne se reecrit pas sans
    -- effacement). La place se libere quand la direction y repond. Le refus le dit : `question_retiree`, pas `question_ouverte`.
    IF EXISTS (SELECT 1 FROM private.praxis_questions q WHERE q.fil_id = p_fil AND q.repondue_le IS NULL AND q.retiree_le IS NOT NULL) THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'question_retiree', p_fil, NULL, NULL, v_debut);
      RETURN pg_catalog.jsonb_build_object('erreur', 'question_retiree');
    END IF;
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'question_ouverte', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'question_ouverte');
  END;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'demander_equipe', 'ok', p_fil, ARRAY[v_id], pg_catalog.btrim(p_question), v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_id);
END;
$function$;

-- 4.5 public.praxis_reponses_equipe(text,integer) (corps de la derniere definition, ajouts marques PX-5).
CREATE OR REPLACE FUNCTION public.praxis_reponses_equipe(p_cle text, p_limite integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_liste jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'reponses_equipe', v_p.cause_interne, NULL, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'reponses_equipe', 'parametre', NULL, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(x.j ORDER BY x.le), '[]'::jsonb) INTO v_liste
    FROM (SELECT r.repondue_le AS le,
                 pg_catalog.jsonb_build_object('id', r.id, 'fil', r.fil_id, 'question', r.question,
                   'reponse_de_la_direction', r.reponse, 'repondue_le', r.repondue_le,
                   -- PX-5 : vrai si Praxis avait RETIRE la question (il a deja repondu seul) avant que la direction reponde : ne
                   -- transmettre que ce qui corrige ou complete ce qu'il a deja dit.
                   'question_retiree', r.retiree_le IS NOT NULL) AS j
            FROM (SELECT q.* FROM private.praxis_questions q
                   WHERE q.repondue_le IS NOT NULL AND q.utilisee_le IS NULL
                   ORDER BY q.repondue_le, q.id LIMIT 200) r
           WHERE private.praxis_fil_refus(r.fil_id, v_p.cotes) IS NULL
           ORDER BY r.repondue_le, r.id LIMIT p_limite) x;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'reponses_equipe', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('reponses', v_liste);
END;
$function$;

-- 4.6 public.direction_praxis_questions(integer) (corps de la derniere definition, ajouts marques PX-5).
CREATE OR REPLACE FUNCTION public.direction_praxis_questions(p_limite integer DEFAULT 100)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_liste jsonb;
  v_total integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'limite invalide' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_total FROM private.praxis_questions;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', x.id, 'filId', x.fil_id, 'question', x.question, 'poseeLe', x.posee_le,
           'reponse', x.reponse, 'repondueLe', x.repondue_le,
           'repondueParPrenom', (SELECT p.first_name FROM public.profiles p WHERE p.id = x.repondue_par),
           'utiliseeLe', x.utilisee_le,
           -- PX-5 : la question retiree par Praxis (il a repondu seul) : la direction n'a plus a y repondre.
           'retireeLe', x.retiree_le, 'retireeMotif', x.retiree_motif)
         ORDER BY (x.repondue_le IS NOT NULL), (x.retiree_le IS NOT NULL), CASE WHEN x.repondue_le IS NULL THEN x.posee_le END,
                  x.repondue_le DESC, x.id), '[]'::jsonb)
    INTO v_liste
    FROM (SELECT * FROM private.praxis_questions q
           -- PX-5 : les ouvertes d'abord, puis les retirees sans reponse, puis les repondues.
           ORDER BY (q.repondue_le IS NOT NULL), (q.retiree_le IS NOT NULL), CASE WHEN q.repondue_le IS NULL THEN q.posee_le END,
                    q.repondue_le DESC, q.id
           LIMIT p_limite) x;
  RETURN pg_catalog.jsonb_build_object('questions', v_liste, 'total', v_total);
END;
$function$;

-- 4.7 public.praxis_noter_refus(text,text) (corps de la derniere definition, ajouts marques PX-5).
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
                                        'dossier', 'noter_impression', 'boite_candidats', 'ouvrir',
                                        -- PX-5 : les deux outils neufs, et les quatre outils que la liste oubliait (constat du cahier PX-3).
                                        'questions_ouvertes', 'retirer_question',
                                        'demander_equipe', 'reponses_equipe', 'question_traitee', 'terminer') THEN
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

-- 4.8 private.praxis_ouverture_refus(public.candidatures,text,public.gender[]) (corps de la derniere definition, ajouts marques PX-5).
CREATE OR REPLACE FUNCTION private.praxis_ouverture_refus(c candidatures, p_raison text, p_cotes gender[])
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
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
    -- PX-5 (directeur, 20/11/2026 : « releve le plafond a 100 toutes les 5h ») : le plafond est lu dans private.praxis_reglages
    -- (ouvertures_par_fenetre, 100 ; ouvertures_fenetre_heures, 5), sur une fenetre GLISSANTE, au total. Il n'est plus de 25 par 24 h.
    IF (SELECT pg_catalog.count(*) FROM private.praxis_ouvertures o
         WHERE o.raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien')
           AND o.ouverte_le > pg_catalog.clock_timestamp()
                              - pg_catalog.make_interval(hours => (SELECT r.ouvertures_fenetre_heures FROM private.praxis_reglages r)))
       >= (SELECT r.ouvertures_par_fenetre FROM private.praxis_reglages r) THEN
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
$function$;

-- 4.9 public.praxis_etat(text) (corps de la derniere definition, ajouts marques PX-5).
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
  -- PX-5 : le plafond des ouvertures, lu dans les reglages.
  v_ouv_plafond integer;
  v_ouv_heures integer;
  v_ouv_restantes integer;
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
  SELECT r.ouvertures_par_fenetre, r.ouvertures_fenetre_heures INTO v_ouv_plafond, v_ouv_heures FROM private.praxis_reglages r;
  v_ouv_restantes := greatest(v_ouv_plafond - (SELECT pg_catalog.count(*)::integer FROM private.praxis_ouvertures o
                                                WHERE o.raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien')
                                                  AND o.ouverte_le > pg_catalog.clock_timestamp() - pg_catalog.make_interval(hours => v_ouv_heures)), 0);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'etat', CASE WHEN v_p.cause IS NULL THEN 'ok' ELSE v_p.cause END,
                               NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object(
    'actif', v_p.cause IS NULL,
    'mode', CASE v_p.usage WHEN 'routine' THEN 'autonome' ELSE 'dirige' END,
    'cotes', pg_catalog.to_jsonb(v_p.cotes),
    'plafondRestantHeure', greatest(v_plafond - v_envoyes, 0),
    'annoncesRestantesJour', greatest(2 - v_annonces, 0),
    -- PX-5 : ce qu'il reste des ouvertures de dialogue (questions, relances, entretiens ecrits) dans la fenetre GLISSANTE reglee
    -- (private.praxis_reglages : 100 par 5 heures a l'installation), au total ; les felicitations ne comptent pas ; chaque ouverture
    -- compte aussi dans plafondRestantHeure. `ouverturesRestantesJour` est GARDEE pour les lecteurs d'avant (scenario PX-4, routine) :
    -- elle vaut desormais la meme chose que `ouverturesRestantesFenetre` (il n'y a plus de plafond par jour).
    'ouverturesRestantesFenetre', v_ouv_restantes,
    'ouverturesParFenetre', v_ouv_plafond,
    'ouverturesFenetreHeures', v_ouv_heures,
    'ouverturesRestantesJour', v_ouv_restantes,
    'interdits', pg_catalog.jsonb_build_array(
      'refuser une personne', 'supprimer', 'deplacer de l''argent', 'changer un droit ou un role',
      'lire une piece d''identite', 'modifier le garde-fou, ses reglages ou ses cles',
      'ecrire a un mineur', 'creer un fil', 'ecrire hors d''un fil de l''academie', 'envoyer un courriel'));
END;
$function$;

-- ====================================================================================================================
-- 5. DROITS. Outils neufs : service_role seul. Porte de la direction : authenticated (garde d'administrateur aal2 dans la fonction).
-- Aide privee : personne. Les fonctions remplacees gardent leurs droits (CREATE OR REPLACE) ; le controle final le verifie.
-- ====================================================================================================================
ALTER FUNCTION private.praxis_dossier_resume(uuid, public.gender[]) OWNER TO postgres;
ALTER FUNCTION public.praxis_questions_ouvertes(text, integer) OWNER TO postgres;
ALTER FUNCTION public.praxis_retirer_question(text, uuid, text) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_regler_ouvertures(integer, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.praxis_dossier_resume(uuid, public.gender[]), public.praxis_questions_ouvertes(text, integer),
  public.praxis_retirer_question(text, uuid, text), public.direction_praxis_regler_ouvertures(integer, integer)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.praxis_questions_ouvertes(text, integer), public.praxis_retirer_question(text, uuid, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.direction_praxis_regler_ouvertures(integer, integer) TO authenticated;

-- ====================================================================================================================
-- 6. CONTROLE FINAL. Toute erreur annule l'installation entiere.
-- ====================================================================================================================
DO $postflight$
DECLARE
  v text;
BEGIN
  -- Les outils (neufs et remplaces) : service_role seul, SECURITY DEFINER, search_path vide, proprietaire postgres.
  FOREACH v IN ARRAY ARRAY['public.praxis_questions_ouvertes(text,integer)', 'public.praxis_retirer_question(text,uuid,text)',
      'public.praxis_boite(text,text,integer)', 'public.praxis_fil(text,uuid,integer)', 'public.praxis_lire(text,text,jsonb,integer)',
      'public.praxis_demander_equipe(text,uuid,text)', 'public.praxis_reponses_equipe(text,integer)', 'public.praxis_noter_refus(text,text)',
      'public.praxis_etat(text)'] LOOP
    IF NOT pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
      RAISE EXCEPTION 'PX-5 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  -- Les portes de la direction : authenticated seul.
  FOREACH v IN ARRAY ARRAY['public.direction_praxis_regler_ouvertures(integer,integer)', 'public.direction_praxis_questions(integer)'] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
      RAISE EXCEPTION 'PX-5 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  -- Les aides privees : personne.
  FOREACH v IN ARRAY ARRAY['private.praxis_dossier_resume(uuid,public.gender[])',
      'private.praxis_ouverture_refus(public.candidatures,text,public.gender[])'] LOOP
    IF pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v, 'EXECUTE') OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
      RAISE EXCEPTION 'PX-5 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  -- Les deux tables : RLS toujours active, aucun droit client.
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.praxis_questions'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.praxis_reglages'::pg_catalog.regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'private.praxis_questions', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_questions', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'private.praxis_reglages', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_reglages', 'SELECT') THEN
    RAISE EXCEPTION 'PX-5 : RLS ou droits des tables inattendus';
  END IF;
  -- Les reglages : une seule ligne, aux valeurs par defaut ; aucune question n'est retiree a l'installation.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_reglages) <> 1
     OR (SELECT r.ouvertures_par_fenetre FROM private.praxis_reglages r) <> 100
     OR (SELECT r.ouvertures_fenetre_heures FROM private.praxis_reglages r) <> 5
     OR EXISTS (SELECT 1 FROM private.praxis_questions q WHERE q.retiree_le IS NOT NULL) THEN
    RAISE EXCEPTION 'PX-5 : etat inattendu apres installation';
  END IF;
END
$postflight$;
