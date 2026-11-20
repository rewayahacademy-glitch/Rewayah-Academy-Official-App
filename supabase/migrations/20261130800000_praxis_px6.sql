-- PRAXIS PX-6 (20/11/2026) : Praxis ne repond plus a la place de la direction, et les entretiens ecrits sont suspendus.
-- Bati sur PX-5 (20261130300000, installe en production le 20/11/2026), memes conventions, memes gardes.
--
-- LE PROBLEME (mesure en production, lecture seule, 20/11/2026) : sur 54 reponses de Praxis, 20 s'adressaient a une personne qui repondait a
-- un message de la direction (le plus souvent un simple remerciement apres une information donnee par le directeur) ; sur 100 entretiens
-- ecrits ouverts par Praxis, 27 ont ete postes juste apres un message de la direction. Le directeur, 20/11/2026 : « il faut qu'il apprenne a ne
-- repondre qu'aux messages et non aux annonces. S'il trouve une annonce avec erreur que la direction a faite ou un message alors il le dit en
-- prive entre lui et la direction. » Cause : `boite` disait qu'une conversation « attend » des que le dernier message etait de la personne,
-- sans regarder a qui elle repondait ; `ecrire` ne refusait pas une conversation que la direction tient ; `direction_recente` ne valait que
-- pour certaines raisons de `ouvrir`, sur 48 heures.
--
-- LIVRE ICI (la regle est tenue par le serveur, pas seulement par la consigne de Praxis) :
--   1. UNE definition, UNE fonction privee : private.praxis_tenue_par_direction(fil). Une conversation est TENUE PAR LA DIRECTION quand le
--      dernier message ecrit du cote de l'academie (Praxis, ou un membre de l'equipe au sens de private.praxis_est_equipe) est d'un membre de
--      l'equipe, et date de moins de N jours. N = private.praxis_reglages.direction_tient_jours (colonne neuve, 7 par defaut, de 1 a 60).
--   2. `boite` (praxis_boite) : chaque conversation rend `tenue_par_la_direction` ; le filtre `attend` n'inclut plus une conversation tenue
--      par la direction ; un filtre neuf `direction` rend seulement celles-la quand le dernier message est de la personne (avec
--      attente_heures), pour que Praxis le signale EN PRIVE a la direction (demander_equipe). `non_lu` et `tout` ne filtrent pas : ils
--      rendent le champ, et `ecrire` refuse de toute facon.
--   3. `fil` (praxis_fil) : rend `tenue_par_la_direction`, et pour chaque message un champ `de` (praxis, direction, interlocuteur, autre).
--      Avant PX-6, seul auteur.role ('equipe') distinguait un message de la direction, dont le texte etait range sous contenu_tiers
--      exactement comme celui de la personne : le champ `de` le dit en un mot. Rien d'existant n'est retire.
--   4. `ecrire` (praxis_ecrire) : refuse `fil_de_la_direction` quand la conversation est tenue par la direction. Exception UNIQUE : une
--      question de Praxis sur CETTE conversation, repondue par la direction (canal prive, private.praxis_questions), pas encore marquee
--      utilisee (question_traitee), et la direction n'a rien ecrit dans la conversation depuis sa reponse. Les refus existants
--      (repris_par_equipe, raison_requise, plafond_fil, plafond) passent avant ou apres sans changement.
--   5. `ouvrir` (praxis_ouvrir, via private.praxis_ouverture_refus) : `direction_recente` vaut pour TOUTES les raisons (felicitations
--      comprises) et suit le meme reglage de N jours (au lieu de 48 heures) : la direction a ecrit dans la conversation depuis moins de N jours.
--   6. Les ENTRETIENS ECRITS sont SUSPENDUS : les raisons entretien_ecrit et relance_entretien de `ouvrir` sont refusees
--      `entretiens_suspendus` tant que private.praxis_reglages.entretiens_ecrits_ouverts (colonne neuve, FAUX par defaut) n'est pas vrai ;
--      `boite_candidats` rend donc permis = faux, refus = entretiens_suspendus pour le filtre a_interroger (meme aide, fonction non touchee) ;
--      `etat` rend entretiensEcritsSuspendus et directionTientJours. Aucune ligne existante n'est supprimee ni modifiee.
--   7. Une porte neuve de la direction, seule a changer ces deux reglages : public.direction_praxis_regler_conversations(jours, entretiens),
--      administrateur en aal2, journalisee (comme direction_praxis_regler_ouvertures). NULL = inchange.
--   8. UN ENTRETIEN RETIRE N'EST PLUS EN COURS (relecture du 20/11/2026) : la migration 20261130700000 retire de public.com_messages les
--      entretiens ecrits de Praxis restes sans reponse, sans toucher private.praxis_ouvertures (message_id sans cle etrangere). Toute
--      lecture de private.praxis_ouvertures qui dit « un entretien est ouvert, en cours, a relancer » ou qui presente une ouverture a Praxis
--      ignore desormais une ouverture dont le message n'existe plus dans public.com_messages (sans dependre d'une table de retraits) :
--      private.praxis_ouverture_refus (entretien_en_cours, relance_entretien_sans_objet), public.praxis_dossier (entretien_ecrit, et la liste
--      praxis.ouvertures), public.praxis_boite_candidats (a_interroger). Les LIMITES comptent toujours toutes les ouvertures (la personne a
--      bien ete contactee) : ouverture_recente, plafond_ouvertures, plafond_entretiens, entretien_deja_relance, plafond_relances, et les
--      compteurs de `etat`. private.praxis_dossier_resume ne lit pas private.praxis_ouvertures : non touchee.
--   Les descriptions d'outils lues par Praxis vivent dans supabase/functions/_shared/praxis/outils.ts (fonction Edge praxis-mcp) : elles
--   sont mises a jour dans la meme pull request, et la fonction Edge doit etre REDEPLOYEE (le filtre `direction` est refuse par sa
--   validation tant qu'elle ne l'est pas).
--
-- MOTS D'EFFACEMENT : ZERO. Aucune contrainte existante reecrite, aucun index retire, aucune ligne ecrite hors de la ligne unique des
-- reglages (deux colonnes neuves a leur valeur par defaut).
--
-- FONCTIONS EXISTANTES REMPLACEES (CREATE OR REPLACE a signature identique, droits et proprietaire conserves), apres controle de
-- l'empreinte md5(prosrc). Le corps est celui de la DERNIERE definition, recopie par pg_get_functiondef sur une base rejouee jusqu'a PX-5,
-- plus le necessaire (chaque ajout porte le mot PX-6) :
--   * public.praxis_boite(text, text, integer)            <- 20261130300000 (PX-5). Appelant : l'outil `boite`.
--   * public.praxis_fil(text, uuid, integer)              <- 20261130300000 (PX-5). Appelant : l'outil `fil`.
--   * public.praxis_ecrire(text, uuid, text, uuid)        <- 20261130200000 (PX-4). Appelant : l'outil `ecrire`.
--   * private.praxis_ouverture_refus(candidatures, text, gender[]) <- 20261130300000 (PX-5). Appelants : praxis_ouvrir (NON touchee :
--     elle herite des refus), praxis_boite_candidats.
--   * public.praxis_dossier(text, text)                   <- 20261130200000 (PX-4). Appelant : l'outil `dossier` (point 8 seulement).
--   * public.praxis_boite_candidats(text, text, integer, integer) <- 20261130200000 (PX-4). Appelant : l'outil `boite_candidats` (point 8).
--   * public.praxis_etat(text)                            <- 20261130300000 (PX-5). Appelant : l'outil `etat`.
-- Rien n'est allume par cette migration (actif, autonome, donnees_reelles ne changent pas). Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regclass('private.praxis_reglages') IS NULL OR pg_catalog.to_regclass('private.praxis_questions') IS NULL
     OR pg_catalog.to_regclass('private.praxis_ouvertures') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_est_equipe(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_est_partie_a(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_profil()') IS NULL
     OR pg_catalog.to_regprocedure('private.praxis_dossier_resume(uuid,public.gender[])') IS NULL
     OR pg_catalog.to_regprocedure('public.praxis_ouvrir(text,text,text,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.praxis_boite_candidats(text,text,integer,integer)') IS NULL
     OR pg_catalog.to_regprocedure('public.direction_praxis_regler_ouvertures(integer,integer)') IS NULL
     OR pg_catalog.to_regprocedure('public.log_sensitive_access(text,text,text,jsonb)') IS NULL
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a WHERE a.attrelid = 'private.praxis_questions'::pg_catalog.regclass
                     AND a.attname = 'utilisee_le' AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'PX-6 : dependances absentes (PX-5, PX-4, PX-SUIVI, socle) ; rien n''est modifie';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a WHERE a.attrelid = 'private.praxis_reglages'::pg_catalog.regclass
              AND a.attname IN ('direction_tient_jours', 'entretiens_ecrits_ouverts') AND NOT a.attisdropped)
     OR pg_catalog.to_regprocedure('private.praxis_tenue_par_direction(uuid)') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.direction_praxis_regler_conversations(integer,boolean)') IS NOT NULL THEN
    RAISE EXCEPTION 'PX-6 : deja installe ; rien n''est modifie';
  END IF;
  FOR v IN SELECT * FROM (VALUES
      ('public.praxis_boite(text,text,integer)', '2d3fa1d3b22a6ad7f6dc829d2c1fa303'),
      ('public.praxis_fil(text,uuid,integer)', 'ad9ff137196ef2f7cc8c5b1c2cd352b0'),
      ('public.praxis_ecrire(text,uuid,text,uuid)', 'b68e4bb4f72511b90a4eb4f6171a5827'),
      ('private.praxis_ouverture_refus(public.candidatures,text,public.gender[])', '2dcf31b5880269cc7b5e0821a68d3320'),
      ('public.praxis_etat(text)', '41563b247222c6ff5dec260ef244bc8a'),
      ('public.praxis_dossier(text,text)', 'ff5c331ef2eb2b124db31f70377e990f'),
      ('public.praxis_boite_candidats(text,text,integer,integer)', '6506de3129e7cf0c41984061ce6c3690'),
      -- Non remplacees, mais leur comportement en depend.
      ('public.praxis_ouvrir(text,text,text,text,uuid)', '9400c10b892383999a9a020a7f1395db'),
      ('public.praxis_question_traitee(text,uuid)', 'c82fa9d7658120f1fbce9608e552fe65'),
      ('private.praxis_est_equipe(uuid,uuid)', '35dc52fea5840c71a81873f640efcd1a')) AS t(f, md5) LOOP
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v.f::pg_catalog.regprocedure) IS DISTINCT FROM v.md5 THEN
      RAISE EXCEPTION 'PX-6 : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
  -- Le reglage n'a qu'une ligne (les controles le supposent).
  IF (SELECT pg_catalog.count(*) FROM private.praxis_reglages) <> 1 THEN
    RAISE EXCEPTION 'PX-6 : private.praxis_reglages n''a pas exactement une ligne ; rien n''est modifie';
  END IF;
END
$preflight$;

-- ====================================================================================================================
-- 1. REGLAGES NEUFS. Deux colonnes, avec leurs CHECK propres ; rien d'existant n'est touche.
-- ====================================================================================================================
-- direction_tient_jours : N jours pendant lesquels une conversation dont le dernier message de l'academie est de la direction reste a la
-- direction (7, directeur, 20/11/2026). entretiens_ecrits_ouverts : faux = entretiens ecrits suspendus (directeur, 20/11/2026).
ALTER TABLE private.praxis_reglages
  ADD COLUMN direction_tient_jours integer NOT NULL DEFAULT 7 CHECK (direction_tient_jours BETWEEN 1 AND 60),
  ADD COLUMN entretiens_ecrits_ouverts boolean NOT NULL DEFAULT false;

-- ====================================================================================================================
-- 2. LA DEFINITION UNIQUE : une conversation tenue par la direction.
-- ====================================================================================================================
-- Le dernier message ecrit du cote de l'academie (Praxis, ou un membre humain de l'equipe de cette conversation au sens de
-- private.praxis_est_equipe, qui exclut les comptes officiels) est d'un membre de l'equipe, et il date de moins de N jours. Une conversation
-- sans message de l'academie, ou dont le dernier message de l'academie est de Praxis, n'est pas tenue par la direction. Ordre des messages :
-- celui de toutes les lectures de Praxis (envoye_le, puis id).
CREATE FUNCTION private.praxis_tenue_par_direction(p_fil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $f$
  SELECT coalesce((
    SELECT d.de_la_direction
           AND d.envoye_le > pg_catalog.clock_timestamp()
                             - pg_catalog.make_interval(days => coalesce((SELECT r.direction_tient_jours FROM private.praxis_reglages r), 7))
      FROM (SELECT m.envoye_le, private.praxis_est_equipe(m.auteur_id, p_fil) AS de_la_direction
              FROM public.com_messages m
             WHERE m.fil_id = p_fil
               AND (m.auteur_id = private.praxis_profil() OR private.praxis_est_equipe(m.auteur_id, p_fil))
             ORDER BY m.envoye_le DESC, m.id DESC
             LIMIT 1) d), false);
$f$;

-- ====================================================================================================================
-- 3. LA PORTE DE LA DIRECTION : les deux reglages (aal2, journalisee), comme direction_praxis_regler_ouvertures. NULL = inchange.
-- ====================================================================================================================
CREATE FUNCTION public.direction_praxis_regler_conversations(p_direction_tient_jours integer, p_entretiens_ecrits_ouverts boolean)
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
  IF (p_direction_tient_jours IS NULL AND p_entretiens_ecrits_ouverts IS NULL)
     OR (p_direction_tient_jours IS NOT NULL AND p_direction_tient_jours NOT BETWEEN 1 AND 60) THEN
    RAISE EXCEPTION 'reglage des conversations invalide : de 1 a 60 jours, ou entretiens ouverts vrai ou faux' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_reglages
     SET direction_tient_jours = coalesce(p_direction_tient_jours, direction_tient_jours),
         entretiens_ecrits_ouverts = coalesce(p_entretiens_ecrits_ouverts, entretiens_ecrits_ouverts),
         modifie_par = auth.uid(), modifie_le = pg_catalog.clock_timestamp()
   WHERE id;
  PERFORM public.log_sensitive_access('praxis_regle_conversations', 'private.praxis_reglages', 'praxis',
    pg_catalog.jsonb_build_object('directionTientJours', p_direction_tient_jours, 'entretiensEcritsOuverts', p_entretiens_ecrits_ouverts));
  RETURN (SELECT pg_catalog.jsonb_build_object('directionTientJours', r.direction_tient_jours,
                                               'entretiensEcritsOuverts', r.entretiens_ecrits_ouverts)
            FROM private.praxis_reglages r);
END;
$f$;

-- ====================================================================================================================
-- 4. FONCTIONS EXISTANTES REMPLACEES (empreintes controlees plus haut).
-- ====================================================================================================================

-- 4.1 public.praxis_boite(text,text,integer) (corps de la derniere definition, ajouts marques PX-6).
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
  IF p_filtre IS NULL OR p_filtre NOT IN ('attend', 'non_lu', 'tout', 'direction') OR p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 50 THEN
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
           -- PX-6 : la conversation est TENUE PAR LA DIRECTION (definition unique : private.praxis_tenue_par_direction).
           private.praxis_tenue_par_direction(b.id) AS tenue,
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
           -- PX-6 : vrai si le dernier message de l'academie est de la direction et date de moins de N jours (reglage) : Praxis n'y
           -- repond pas (`ecrire` refuse fil_de_la_direction) ; il signale en prive a la direction (demander_equipe).
           'tenue_par_la_direction', c.tenue,
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
           -- PX-6 : `attend` n'inclut plus une conversation tenue par la direction ; `direction` rend seulement celles-la, quand le dernier
           -- message est de la personne (un message reste sans reponse de la direction, a lui signaler en prive).
           WHERE p_filtre = 'tout' OR (p_filtre = 'attend' AND c2.attend AND NOT c2.tenue)
              OR (p_filtre = 'direction' AND c2.attend AND c2.tenue) OR (p_filtre = 'non_lu' AND c2.sans_reponse > 0)
           ORDER BY c2.dernier_le DESC LIMIT p_limite) c;
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'boite', 'ok', NULL, NULL, NULL, v_debut);
  RETURN pg_catalog.jsonb_build_object('fils', v_fils);
END;
$function$;

-- 4.2 public.praxis_fil(text,uuid,integer) (corps de la derniere definition, ajouts marques PX-6).
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
                   -- PX-6 : DE QUI est le message, en un mot : praxis (toi), direction (un membre de l'equipe de l'academie),
                   -- interlocuteur (la personne ou la famille de la conversation), autre. Un message de la direction n'est JAMAIS celui
                   -- de la personne, meme si son texte est aussi sous contenu_tiers.
                   'de', CASE WHEN m.auteur_id = private.praxis_profil() THEN 'praxis'
                              WHEN private.praxis_est_equipe(m.auteur_id, p_fil) THEN 'direction'
                              WHEN private.praxis_est_partie_a(m.auteur_id, p_fil) THEN 'interlocuteur'
                              ELSE 'autre' END,
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
    -- PX-6 : la conversation est tenue par la direction (meme definition que `boite`) : n'y reponds pas, signale en prive.
    'tenue_par_la_direction', private.praxis_tenue_par_direction(p_fil),
    'repris_par_equipe', v_derniere_praxis IS NOT NULL AND EXISTS (
       SELECT 1 FROM public.com_messages m
        WHERE m.fil_id = p_fil AND private.praxis_est_equipe(m.auteur_id, p_fil) AND m.envoye_le > v_derniere_praxis));
END;
$function$;

-- 4.3 public.praxis_ecrire(text,uuid,text,uuid) (corps de la derniere definition, ajouts marques PX-6).
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
  -- PX-6 (directeur, 20/11/2026 : « ne repondre qu'aux messages et non aux annonces ») : une conversation TENUE PAR LA DIRECTION (le
  -- dernier message de l'academie est d'un membre de la direction et date de moins de N jours, private.praxis_tenue_par_direction) est
  -- refusee, quel que soit son type. Exception UNIQUE : Praxis transmet une reponse que la direction lui a donnee par le canal prive des
  -- questions pour CETTE conversation (private.praxis_questions : repondue, pas encore marquee utilisee par question_traitee, et la
  -- direction n'a rien ecrit dans la conversation depuis sa reponse).
  IF v_refus IS NULL AND private.praxis_tenue_par_direction(p_fil) AND NOT EXISTS (
       SELECT 1 FROM private.praxis_questions q
        WHERE q.fil_id = p_fil AND q.repondue_le IS NOT NULL AND q.utilisee_le IS NULL
          AND NOT EXISTS (SELECT 1 FROM public.com_messages m
                           WHERE m.fil_id = p_fil AND m.envoye_le > q.repondue_le AND private.praxis_est_equipe(m.auteur_id, p_fil))) THEN
    v_refus := 'fil_de_la_direction';
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

-- 4.4 private.praxis_ouverture_refus(public.candidatures,text,public.gender[]) (corps de la derniere definition, ajouts marques PX-6).
CREATE OR REPLACE FUNCTION private.praxis_ouverture_refus(c public.candidatures, p_raison text, p_cotes public.gender[])
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
  -- PX-6 (directeur, 20/11/2026) : les entretiens ecrits sont SUSPENDUS tant que la direction ne les rouvre pas
  -- (private.praxis_reglages.entretiens_ecrits_ouverts, faux par defaut ; porte direction_praxis_regler_conversations).
  IF p_raison IN ('entretien_ecrit', 'relance_entretien')
     AND NOT coalesce((SELECT r.entretiens_ecrits_ouverts FROM private.praxis_reglages r), false) THEN
    RETURN 'entretiens_suspendus';
  END IF;
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
  -- PX-6 : `direction_recente` vaut pour TOUTES les raisons (felicitations comprises) : la direction a ecrit dans la conversation
  -- depuis moins de N jours (private.praxis_reglages.direction_tient_jours, 7 par defaut ; 48 heures avant PX-6, et pas pour les
  -- felicitations). Plus large que « tenue par la direction » : un message de Praxis apres celui de la direction ne leve pas ce refus.
  IF v_fil IS NOT NULL AND EXISTS (SELECT 1 FROM public.com_messages m
        WHERE m.fil_id = v_fil
          AND m.envoye_le > pg_catalog.clock_timestamp()
                            - pg_catalog.make_interval(days => coalesce((SELECT r.direction_tient_jours FROM private.praxis_reglages r), 7))
          AND private.praxis_est_equipe(m.auteur_id, v_fil)) THEN
    RETURN 'direction_recente';
  END IF;
  IF p_raison IN ('question', 'relance', 'entretien_ecrit', 'relance_entretien') THEN
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
      -- PX-6 (point 8) : la serie en cours est la derniere dont le message existe encore dans la conversation (un entretien retire
      -- n'est plus vu par la personne : il n'est ni en cours, ni a relancer). Les plafonds (plafond_entretiens, entretien_deja_relance,
      -- ouverture_recente, plafond_ouvertures) comptent TOUTES les ouvertures : la personne a bien ete contactee.
      SELECT pg_catalog.max(o.ouverte_le) INTO v_serie FROM private.praxis_ouvertures o
       WHERE o.candidature_id = c.id AND o.raison = 'entretien_ecrit' AND EXISTS (SELECT 1 FROM public.com_messages mv WHERE mv.id = o.message_id);
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

-- 4.5 public.praxis_etat(text) (corps de la derniere definition, ajouts marques PX-6).
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
  -- PX-6 : les deux reglages des conversations.
  v_tient_jours integer;
  v_entretiens boolean;
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
  SELECT r.direction_tient_jours, r.entretiens_ecrits_ouverts INTO v_tient_jours, v_entretiens FROM private.praxis_reglages r;
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
    -- PX-6 : une conversation dont le dernier message de l'academie est de la direction, depuis moins de directionTientJours jours, est
    -- TENUE PAR LA DIRECTION (`ecrire` refuse fil_de_la_direction, `ouvrir` refuse direction_recente) ; les entretiens ecrits sont
    -- suspendus (`ouvrir` refuse entretiens_suspendus) tant que la direction ne les rouvre pas.
    'directionTientJours', v_tient_jours,
    'entretiensEcritsSuspendus', NOT coalesce(v_entretiens, false),
    'interdits', pg_catalog.jsonb_build_array(
      'refuser une personne', 'supprimer', 'deplacer de l''argent', 'changer un droit ou un role',
      'lire une piece d''identite', 'modifier le garde-fou, ses reglages ou ses cles',
      'ecrire a un mineur', 'creer un fil', 'ecrire hors d''un fil de l''academie', 'envoyer un courriel'));
END;
$function$;

-- 4.6 public.praxis_dossier(text,text) (corps de la derniere definition, ajouts marques PX-6).
CREATE OR REPLACE FUNCTION public.praxis_dossier(p_cle text, p_candidature text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  -- PX-6 (point 8) : une serie (ou une relance) dont le message n'existe plus (entretien retire) n'est plus annoncee a Praxis.
  SELECT pg_catalog.max(o.ouverte_le) INTO v_serie FROM private.praxis_ouvertures o WHERE o.candidature_id = v_c.id AND o.raison = 'entretien_ecrit'
     AND EXISTS (SELECT 1 FROM public.com_messages mv WHERE mv.id = o.message_id);
  IF v_serie IS NOT NULL THEN
    SELECT pg_catalog.max(o.ouverte_le) INTO v_serie_relance FROM private.praxis_ouvertures o
     WHERE o.candidature_id = v_c.id AND o.raison = 'relance_entretien' AND o.ouverte_le > v_serie AND EXISTS (SELECT 1 FROM public.com_messages mv WHERE mv.id = o.message_id);
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
                                  -- PX-6 (point 8) : une ouverture dont le message n'existe plus (retire) n'est plus presentee.
                                  FROM private.praxis_ouvertures o WHERE o.candidature_id = v_c.id AND EXISTS (SELECT 1 FROM public.com_messages mv WHERE mv.id = o.message_id)), '[]'::jsonb)),
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
$function$;

-- 4.7 public.praxis_boite_candidats(text,text,integer,integer) (corps de la derniere definition, ajouts marques PX-6).
CREATE OR REPLACE FUNCTION public.praxis_boite_candidats(p_cle text, p_filtre text, p_jours integer DEFAULT 3, p_limite integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
                             -- PX-6 (point 8) : une serie dont le message n'existe plus (retiree) ne compte plus comme envoyee.
                             AND NOT EXISTS (SELECT 1 FROM private.praxis_ouvertures o WHERE o.candidature_id = c.id AND o.raison = 'entretien_ecrit'
                                               AND EXISTS (SELECT 1 FROM public.com_messages mv WHERE mv.id = o.message_id))
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
$function$;

-- ====================================================================================================================
-- 5. DROITS. Porte de la direction : authenticated (garde d'administrateur aal2 dans la fonction). Aide privee : personne. Les fonctions
-- remplacees gardent leurs droits (CREATE OR REPLACE) ; le controle final le verifie.
-- ====================================================================================================================
ALTER FUNCTION private.praxis_tenue_par_direction(uuid) OWNER TO postgres;
ALTER FUNCTION public.direction_praxis_regler_conversations(integer, boolean) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.praxis_tenue_par_direction(uuid), public.direction_praxis_regler_conversations(integer, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_regler_conversations(integer, boolean) TO authenticated;

-- ====================================================================================================================
-- 6. CONTROLE FINAL. Toute erreur annule l'installation entiere.
-- ====================================================================================================================
DO $postflight$
DECLARE
  v text;
BEGIN
  -- Les outils remplaces : service_role seul, SECURITY DEFINER, search_path vide, proprietaire postgres, et le corps porte PX-6.
  FOREACH v IN ARRAY ARRAY['public.praxis_boite(text,text,integer)', 'public.praxis_fil(text,uuid,integer)',
      'public.praxis_ecrire(text,uuid,text,uuid)', 'public.praxis_etat(text)', 'public.praxis_dossier(text,text)',
      'public.praxis_boite_candidats(text,text,integer,integer)'] LOOP
    IF NOT pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole
                        AND pg_catalog.strpos(p.prosrc, 'PX-6') > 0) THEN
      RAISE EXCEPTION 'PX-6 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  -- Les outils qui heritent des refus (non remplaces) : inchanges, service_role seul.
  FOREACH v IN ARRAY ARRAY['public.praxis_ouvrir(text,text,text,text,uuid)'] LOOP
    IF NOT pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE') THEN
      RAISE EXCEPTION 'PX-6 : droits inattendus pour %', v;
    END IF;
  END LOOP;
  -- La porte de la direction : authenticated seul.
  v := 'public.direction_praxis_regler_conversations(integer,boolean)';
  IF NOT pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND p.prosecdef
                      AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
    RAISE EXCEPTION 'PX-6 : droits ou definition inattendus pour %', v;
  END IF;
  -- Les aides privees : personne.
  FOREACH v IN ARRAY ARRAY['private.praxis_tenue_par_direction(uuid)',
      'private.praxis_ouverture_refus(public.candidatures,text,public.gender[])'] LOOP
    IF pg_catalog.has_function_privilege('anon', v, 'EXECUTE') OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v, 'EXECUTE') OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND NOT p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
      RAISE EXCEPTION 'PX-6 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  -- La table des reglages : RLS toujours active, aucun droit client ; une seule ligne, entretiens suspendus, 7 jours.
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.praxis_reglages'::pg_catalog.regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'private.praxis_reglages', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.praxis_reglages', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.praxis_reglages', 'SELECT') THEN
    RAISE EXCEPTION 'PX-6 : RLS ou droits de private.praxis_reglages inattendus';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.praxis_reglages) <> 1
     OR (SELECT r.direction_tient_jours FROM private.praxis_reglages r) <> 7
     OR (SELECT r.entretiens_ecrits_ouverts FROM private.praxis_reglages r) THEN
    RAISE EXCEPTION 'PX-6 : etat inattendu des reglages apres installation';
  END IF;
END
$postflight$;
