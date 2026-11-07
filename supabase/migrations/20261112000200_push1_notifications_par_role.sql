-- PUSH-1 (a), decision du 07/11/2026 : chaque evenement qui attend un geste
-- CREE une notification pour la bonne personne, en commencant par la
-- direction ; la finance va au comptable EN PLUS de la direction (arbitrage du
-- pilote, confirme par le garde-cap le 07/11).
--
-- AUCUN mot d'effacement (compte : 0 ; les declencheurs se posent par
-- CREATE OR REPLACE TRIGGER, celui de contrainte par une garde) : le pilote
-- l'installe lui-meme. Sans BEGIN ni COMMIT de premier niveau. A installer
-- APRES la page collee (20261112000000 puis 20261112000100), que le preflight
-- exige : contraintes elargies, journal des echecs (private.push1_journaliser).
--
-- Contenu :
--   1. preflight : contraintes elargies presentes ; empreintes md5(prosrc) de
--      production de private.notification_geste_requis (70ea0f63...) et de
--      private.remplacement_auto_passer (1109cf1b...), releve du pilote du
--      07/11 ; un objet deja retouche (marque « PUSH-1 ») est saute.
--   2. (le journal des echecs, private.notifications_echecs, est pose par
--      20261112000100, pour que la page collee ne depende pas de ce fichier.)
--   3. private.push1_ajouter, private.notifier_direction, private.push1_clore.
--   4. Un declencheur AFTER par source manquante ; chacun garde le geste
--      metier (EXCEPTION -> journal + WARNING, jamais d'echec du geste).
--   5. Le comptable en plus de la direction sur la finance existante
--      (litige_ouvert, litige_clos, remboursement_effectue, paiement_echoue),
--      sans reecrire private.fac_notifier_remboursement.
--   6. private.notification_geste_requis etendue (CREATE OR REPLACE).
--   7. private.remplacement_auto_passer retouchee par ancre : la notification
--      « remplacement_personne_en_salle » a cote du courriel existant.
--   8. postflight : droits (anon, authenticated, service_role sans EXECUTE).
--
-- Ce qui n'est PAS fait ici, dette nommee :
--   - aucun evenement de REFUS des coordonnees de versement : le schema n'en a
--     pas (seulement valide_le / valide_par) ; rien n'est invente ;
--   - cahier_en_retard : type seul (20261112000000), sans emetteur (lot C3) ;
--   - private.c29_clore_mission_controle n'applique pas access_until : hors lot ;
--   - les emetteurs existants ne sont pas reecrits (notifier_classe_remplacements,
--     notifications_clore_gestes, fac_notifier_remboursement) ;
--   - paiement_echoue n'envoie pas de courriel (aucun modele de courriel n'existe ;
--     la notification et le push suffisent a ce lot).

-- ---------------------------------------------------------------------------
-- 1. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_evt text;
  v_src text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_evt FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  IF v_evt IS NULL OR v_evt NOT LIKE '%''cahier_en_retard''%' THEN
    RAISE EXCEPTION 'PUSH-1 : 20261112000000_push1_contraintes_notifications.sql n''est pas installe (page a coller d''abord), arret';
  END IF;
  IF pg_catalog.to_regprocedure('private.push1_journaliser(text,text,text)') IS NULL THEN
    RAISE EXCEPTION 'PUSH-1 : 20261112000100_push1_file_et_abonnements.sql n''est pas installe (page a coller d''abord), arret';
  END IF;

  SELECT p.prosrc INTO v_src FROM pg_catalog.pg_proc p
   WHERE p.oid = 'private.notification_geste_requis(text,jsonb)'::regprocedure;
  IF pg_catalog.strpos(v_src, 'PUSH-1') = 0
     AND pg_catalog.md5(v_src) <> '70ea0f6304a41429ab22c06f3a25c600' THEN
    RAISE EXCEPTION 'PUSH-1 : private.notification_geste_requis a change depuis le releve du 07/11 (md5 %), arret',
      pg_catalog.md5(v_src);
  END IF;

  SELECT p.prosrc INTO v_src FROM pg_catalog.pg_proc p
   WHERE p.oid = 'private.remplacement_auto_passer(timestamptz)'::regprocedure;
  IF pg_catalog.strpos(v_src, 'PUSH-1') = 0
     AND pg_catalog.md5(v_src) <> '1109cf1b8b603ad75a1b1e9f307c525e' THEN
    RAISE EXCEPTION 'PUSH-1 : private.remplacement_auto_passer a change depuis le releve du 07/11 (md5 %), arret',
      pg_catalog.md5(v_src);
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 3. Ecrire, notifier la direction (et le comptable), clore.
-- ---------------------------------------------------------------------------

-- Une ligne pour un destinataire, sauf s'il en a deja une OUVERTE du meme
-- evenement et de la meme source (params.source_id) : un declencheur rejoue
-- ou une boucle chaque minute ne doublent jamais une ligne.
CREATE OR REPLACE FUNCTION private.push1_ajouter(
  p_destinataire uuid, p_evenement text, p_params jsonb, p_destination text, p_source_id text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  INSERT INTO public.notifications (destinataire, evenement, params, destination)
  SELECT p_destinataire, p_evenement,
         coalesce(p_params, '{}'::jsonb) || pg_catalog.jsonb_build_object('source_id', p_source_id),
         p_destination
   WHERE NOT EXISTS (
     SELECT 1 FROM public.notifications n
      WHERE n.destinataire = p_destinataire
        AND n.evenement = p_evenement
        AND n.params ->> 'source_id' = p_source_id
        AND n.geste_fait_le IS NULL
        AND n.ecartee_le IS NULL);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- La direction (portee « direction ») et, quand une destination comptable est
-- donnee, le comptable (portee « comptable »). Filtre complet du compte :
-- role, actif, non supprime, acces non expire.
CREATE OR REPLACE FUNCTION private.notifier_direction(
  p_evenement text, p_params jsonb, p_destination text,
  p_destination_comptable text DEFAULT NULL, p_source_id text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_p record;
  v_n integer := 0;
BEGIN
  FOR v_p IN
    SELECT pr.id, pr.role::text AS role
      FROM public.profiles pr
     WHERE (pr.role = 'admin' OR (pr.role = 'accountant' AND p_destination_comptable IS NOT NULL))
       AND pr.account_status = 'active'
       AND pr.deleted_at IS NULL
       AND (pr.access_until IS NULL OR pr.access_until > pg_catalog.now())
  LOOP
    v_n := v_n + private.push1_ajouter(
      v_p.id, p_evenement,
      coalesce(p_params, '{}'::jsonb) || pg_catalog.jsonb_build_object(
        'portee', CASE WHEN v_p.role = 'admin' THEN 'direction' ELSE 'comptable' END),
      CASE WHEN v_p.role = 'admin' THEN p_destination ELSE p_destination_comptable END,
      p_source_id);
  END LOOP;
  RETURN v_n;
END;
$function$;

-- « Geste fait » pour toutes les lignes ouvertes de ces evenements et de
-- cette source, quel que soit le destinataire (direction ET comptable).
CREATE OR REPLACE FUNCTION private.push1_clore(p_evenements text[], p_source_id text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  UPDATE public.notifications n
     SET geste_fait_le = pg_catalog.now()
   WHERE n.evenement = ANY (p_evenements)
     AND n.params ->> 'source_id' = p_source_id
     AND n.geste_requis
     AND n.geste_fait_le IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Les sources. Aucun nom, aucun montant, aucun motif dans params : le
--    detail se lit dans la page de destination.
-- ---------------------------------------------------------------------------

-- 4.1 Candidatures (familles, eleves adultes, enseignants). Lue au COMMIT
-- (declencheur de contrainte differe) : inscrire_titulaire change le type en
-- eleve_adulte et ajoute les apprenants APRES l'insertion. Notification
-- seulement quand la direction a un geste a faire (garde-cap, 07/11) :
--   - famille ou eleve adulte : la demande est « a traiter » (etape recue,
--     issue en cours), le compteur de lister_demandes_admission ;
--   - enseignant : le candidat a envoye ses reponses (prequalification,
--     en_examen), la salle d'examen.
-- Un import en masse (source « import ») ne cree rien.
CREATE OR REPLACE FUNCTION private.push1_depuis_candidature()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.candidatures;
  v_n integer;
BEGIN
  BEGIN
    SELECT * INTO v FROM public.candidatures c WHERE c.id = NEW.id;
    IF NOT FOUND THEN
      RETURN NULL;
    END IF;
    IF v.type_code IN ('famille', 'eleve_adulte') THEN
      IF v.issue = 'en_cours' AND v.etape = 'recue' AND v.source <> 'import' THEN
        SELECT pg_catalog.count(*)::integer INTO v_n
          FROM public.candidature_apprenants a WHERE a.candidature_id = v.id;
        PERFORM private.notifier_direction('admission_recue',
          pg_catalog.jsonb_build_object('candidature_id', v.id, 'type', v.type_code, 'apprenants', v_n),
          '/admin/personnes/demandes', NULL, v.id::text);
      ELSE
        PERFORM private.push1_clore(ARRAY['admission_recue'], v.id::text);
      END IF;
    ELSIF v.type_code = 'enseignant' THEN
      IF v.issue = 'en_cours' AND v.etape = 'prequalification' AND v.etat = 'en_examen' THEN
        PERFORM private.notifier_direction('candidature_enseignant_a_examiner',
          pg_catalog.jsonb_build_object('candidature_id', v.id),
          '/admin/personnes/candidatures', NULL, v.id::text);
      ELSE
        PERFORM private.push1_clore(ARRAY['candidature_enseignant_a_examiner'], v.id::text);
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('candidature', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

DO $declencheur$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.candidatures'::regclass
                    AND t.tgname = 'push1_candidature') THEN
    CREATE CONSTRAINT TRIGGER push1_candidature
      AFTER INSERT OR UPDATE OF etape, etat, issue, type_code ON public.candidatures
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_candidature();
  END IF;
END;
$declencheur$;

-- 4.2 Demandes d'horaire des familles : « envoyee » attend la direction.
CREATE OR REPLACE FUNCTION private.push1_depuis_demande_horaire()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF NEW.etat = 'envoyee' THEN
      IF TG_OP = 'INSERT' THEN
        PERFORM private.notifier_direction('demande_horaire_recue',
          pg_catalog.jsonb_build_object('demande_id', NEW.id),
          '/admin/operations/demandes', NULL, NEW.id::text);
      END IF;
    ELSE
      PERFORM private.push1_clore(ARRAY['demande_horaire_recue'], NEW.id::text);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('demande_horaire_recue', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.3 Pieces d'identite (familles et candidats enseignants : une seule table).
CREATE OR REPLACE FUNCTION private.push1_depuis_piece()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF NEW.status = 'pending' AND NEW.deleted_at IS NULL THEN
      IF TG_OP = 'INSERT' THEN
        PERFORM private.notifier_direction('piece_identite_deposee',
          pg_catalog.jsonb_build_object('piece_id', NEW.id),
          '/admin/personnes/dossiers', NULL, NEW.id::text);
      END IF;
    ELSE
      PERFORM private.push1_clore(ARRAY['piece_identite_deposee'], NEW.id::text);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('piece_identite_deposee', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.4 Signalement d'un enseignant sur un eleve (student_concern) : ouvert ou
-- en examen attend la direction ; transmis ou clos, c'est fait.
CREATE OR REPLACE FUNCTION private.push1_depuis_signalement()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF TG_OP = 'INSERT' AND NEW.statut = 'ouvert' THEN
      PERFORM private.notifier_direction('signalement_eleve_recu',
        pg_catalog.jsonb_build_object('signalement_id', NEW.id),
        '/admin/alertes', NULL, NEW.id::text);
    ELSIF NEW.statut IN ('transmis', 'clos') THEN
      PERFORM private.push1_clore(ARRAY['signalement_eleve_recu'], NEW.id::text);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('signalement_eleve_recu', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.5 Demande de suppression d'un compte.
CREATE OR REPLACE FUNCTION private.push1_depuis_suppression()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF NEW.statut = 'en_attente' THEN
      IF TG_OP = 'INSERT' THEN
        PERFORM private.notifier_direction('suppression_compte_demandee',
          pg_catalog.jsonb_build_object('demande_id', NEW.id),
          '/admin/personnes/suppressions', NULL, NEW.id::text);
      END IF;
    ELSE
      PERFORM private.push1_clore(ARRAY['suppression_compte_demandee'], NEW.id::text);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('suppression_compte_demandee', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.6 Creneau personnalise demande : information (le quota decide seul).
CREATE OR REPLACE FUNCTION private.push1_depuis_creneau_personnalise()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    PERFORM private.notifier_direction('creneau_personnalise_demande',
      pg_catalog.jsonb_build_object('demande_id', NEW.id),
      '/admin/operations/demandes', NULL, NEW.id::text);
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('creneau_personnalise_demande', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.7 Paiement echoue (commande de recharge passee a « failed ») : le foyer
-- (titulaire et tuteurs, jamais un enfant : private.fac_destinataires_paiement)
-- et la direction par private.fac_notifier_remboursement, reutilisee telle
-- quelle ; le comptable par la copie de la section 5.
CREATE OR REPLACE FUNCTION private.push1_depuis_commande()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF NEW.etat = 'failed' AND OLD.etat IS DISTINCT FROM 'failed' THEN
      PERFORM private.fac_notifier_remboursement(NEW.id, 'paiement_echoue',
        pg_catalog.jsonb_build_object('source_id', NEW.id::text));
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('paiement_echoue', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.8 Coordonnees de versement d'un enseignant : a valider (direction et
-- comptable) ; validees (l'enseignant, et la demande est close).
CREATE OR REPLACE FUNCTION private.push1_depuis_coordonnees()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF NEW.active AND NEW.valide_le IS NULL AND NEW.retire_le IS NULL THEN
      IF TG_OP = 'INSERT' OR OLD.active IS DISTINCT FROM true OR OLD.valide_le IS NOT NULL THEN
        PERFORM private.notifier_direction('versement_coordonnees_a_valider',
          pg_catalog.jsonb_build_object('coordonnees_id', NEW.id),
          '/admin/finance/paiements', '/comptable/paiements/beneficiaires', NEW.id::text);
      END IF;
    ELSE
      PERFORM private.push1_clore(ARRAY['versement_coordonnees_a_valider'], NEW.id::text);
      IF TG_OP = 'UPDATE' AND OLD.valide_le IS NULL AND NEW.valide_le IS NOT NULL
         AND EXISTS (SELECT 1 FROM public.profiles pr
                      WHERE pr.id = NEW.profile_id
                        AND pr.deleted_at IS NULL
                        AND (pr.access_until IS NULL OR pr.access_until > pg_catalog.now())) THEN
        PERFORM private.push1_ajouter(NEW.profile_id, 'versement_coordonnees_validees',
          pg_catalog.jsonb_build_object('coordonnees_id', NEW.id, 'portee', 'soi'),
          '/compte/paiements-recus', NEW.id::text);
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('versement_coordonnees', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 4.9 Remboursements : demande (information), echec (geste), et l'echec se
-- clot quand le remboursement repart ou aboutit.
CREATE OR REPLACE FUNCTION private.push1_depuis_remboursement()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF TG_OP = 'INSERT' THEN
      PERFORM private.notifier_direction('remboursement_demande',
        pg_catalog.jsonb_build_object('remboursement_id', NEW.id, 'commande_id', NEW.commande_id),
        '/admin/finance', '/comptable/tresorerie/paiements-familles', NEW.id::text);
    ELSIF NEW.etat = 'echec' AND OLD.etat IS DISTINCT FROM 'echec' THEN
      PERFORM private.notifier_direction('remboursement_echec',
        pg_catalog.jsonb_build_object('remboursement_id', NEW.id, 'commande_id', NEW.commande_id),
        '/admin/finance', '/comptable/tresorerie/paiements-familles', NEW.id::text);
    ELSIF NEW.etat IN ('envoyee', 'remboursee') THEN
      PERFORM private.push1_clore(ARRAY['remboursement_echec'], NEW.id::text);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('remboursement', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE TRIGGER push1_demande_horaire
  AFTER INSERT OR UPDATE OF etat ON public.demandes_horaires_famille
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_demande_horaire();

CREATE OR REPLACE TRIGGER push1_piece
  AFTER INSERT OR UPDATE OF status, deleted_at ON public.kyc_documents
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_piece();

CREATE OR REPLACE TRIGGER push1_signalement
  AFTER INSERT OR UPDATE OF statut ON public.student_concern
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_signalement();

CREATE OR REPLACE TRIGGER push1_suppression
  AFTER INSERT OR UPDATE OF statut ON public.demandes_suppression_compte
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_suppression();

CREATE OR REPLACE TRIGGER push1_creneau_personnalise
  AFTER INSERT ON public.demandes_creneau_personnalise
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_creneau_personnalise();

CREATE OR REPLACE TRIGGER push1_commande
  AFTER UPDATE OF etat ON public.commandes_recharge
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_commande();

CREATE OR REPLACE TRIGGER push1_coordonnees
  AFTER INSERT OR UPDATE OF valide_le, active, retire_le ON public.versement_coordonnees
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_coordonnees();

CREATE OR REPLACE TRIGGER push1_remboursement
  AFTER INSERT OR UPDATE OF etat ON public.remboursements_demandes
  FOR EACH ROW EXECUTE FUNCTION private.push1_depuis_remboursement();

-- ---------------------------------------------------------------------------
-- 5. Le comptable en plus de la direction sur la finance deja ecrite par
--    d'autres emetteurs, et la cloture de paiement_echoue.
--    Une ligne « direction » de ces evenements donne une ligne « comptable »
--    par comptable actif, une seule fois par lot d'ecriture (la source est
--    la commande et l'heure de la transaction, communes aux lignes d'un meme
--    appel de fac_notifier_remboursement).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.push1_apres_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_source text;
  v_c record;
BEGIN
  BEGIN
    IF NEW.evenement IN ('litige_ouvert', 'litige_clos', 'remboursement_effectue', 'paiement_echoue')
       AND coalesce(NEW.params ->> 'portee', '') = 'direction' THEN
      v_source := coalesce(NEW.params ->> 'commande_id', NEW.params ->> 'source_id', NEW.id::text)
                  || ':' || pg_catalog.date_part('epoch', NEW.cree_le)::text;
      FOR v_c IN
        SELECT pr.id FROM public.profiles pr
         WHERE pr.role = 'accountant' AND pr.account_status = 'active' AND pr.deleted_at IS NULL
           AND (pr.access_until IS NULL OR pr.access_until > pg_catalog.now())
      LOOP
        PERFORM private.push1_ajouter(v_c.id, NEW.evenement,
          (NEW.params - 'source_id') || pg_catalog.jsonb_build_object('portee', 'comptable'),
          '/comptable/tresorerie/paiements-familles', v_source);
        -- Le litige clos clot le litige ouvert du comptable (meme commande).
        IF NEW.evenement = 'litige_clos' AND NEW.params ? 'commande_id' THEN
          UPDATE public.notifications n
             SET geste_fait_le = pg_catalog.now()
           WHERE n.destinataire = v_c.id
             AND n.evenement = 'litige_ouvert'
             AND n.params ->> 'portee' = 'comptable'
             AND n.params ->> 'commande_id' = NEW.params ->> 'commande_id'
             AND n.geste_requis AND n.geste_fait_le IS NULL;
        END IF;
      END LOOP;
    ELSIF NEW.evenement = 'paiement_recu' THEN
      -- Un paiement recu clot les paiements echoues du meme destinataire.
      UPDATE public.notifications n
         SET geste_fait_le = pg_catalog.now()
       WHERE n.destinataire = NEW.destinataire
         AND n.evenement = 'paiement_echoue'
         AND n.geste_requis AND n.geste_fait_le IS NULL;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser(NEW.evenement, NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE TRIGGER push1_apres_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  WHEN (NEW.evenement IN ('litige_ouvert', 'litige_clos', 'remboursement_effectue',
                          'paiement_echoue', 'paiement_recu'))
  EXECUTE FUNCTION private.push1_apres_notification();

-- ---------------------------------------------------------------------------
-- 6. Quels evenements demandent un geste. Base : 20261104700000 (md5 de
--    prosrc 70ea0f63..., verifie en preflight), rien n'en est retire.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.notification_geste_requis(p_evenement text, p_params jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  -- PUSH-1 (07/11/2026) : ajouts marques ci-dessous.
  SELECT p_evenement IN (
           'paiement_relance',
           'acces_suspendu_paiement',
           'remplacement_propose',
           'remplacement_pre_alerte',
           'demande_presentation',
           'controle_mission_attribuee',
           -- PUSH-1 : ce qui attend un geste, par role.
           'remplacement_avertissement',
           'admission_recue',
           'candidature_enseignant_a_examiner',
           'demande_horaire_recue',
           'piece_identite_deposee',
           'signalement_eleve_recu',
           'suppression_compte_demandee',
           'remplacement_personne_en_salle',
           'paiement_echoue',
           'versement_coordonnees_a_valider',
           'remboursement_echec',
           'cahier_en_retard')
      -- La famille est seulement informee d'une contestation ; la direction
      -- et le comptable doivent la traiter.
      OR (p_evenement = 'litige_ouvert'
          AND coalesce(p_params ->> 'portee', '') IN ('direction', 'comptable'))
      -- PUSH-1 : la direction doit trouver un remplacant ; la classe, deja
      -- dans la salle, est seulement informee.
      OR (p_evenement = 'titulaire_en_retard'
          AND coalesce(p_params ->> 'portee', '') = 'direction');
$function$;

-- ---------------------------------------------------------------------------
-- 7. private.remplacement_auto_passer : la notification a cote du courriel
--    « personne n'est dans la salle », par ancre (pg_temp.remplacer, regle B4),
--    dans son propre bloc : son echec n'annule ni le courriel ni l'alerte.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

DO $retouches$
DECLARE
  v_f CONSTANT pg_catalog.regprocedure := 'private.remplacement_auto_passer(timestamptz)'::regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), 'PUSH-1') > 0 THEN
    RAISE NOTICE 'PUSH-1 : remplacement_auto_passer deja retouchee, rien n''est reapplique';
    RETURN;
  END IF;
  PERFORM pg_temp.remplacer(v_f,
    $a$             'a3bis-alerte:' || v_s.id::text || ':' || v_dir.id::text) IS NOT NULL THEN
          v_alertes := v_alertes + 1;
        END IF;$a$,
    $b$             'a3bis-alerte:' || v_s.id::text || ':' || v_dir.id::text) IS NOT NULL THEN
          v_alertes := v_alertes + 1;
        END IF;
        -- PUSH-1 (07/11/2026) : la meme alerte dans l'application (et en
        -- push), une fois par seance et par personne.
        BEGIN
          PERFORM private.push1_ajouter(v_dir.id, 'remplacement_personne_en_salle',
            pg_catalog.jsonb_build_object('session_id', v_s.id, 'portee', 'direction'),
            '/admin/operations/planning', v_s.id::text);
        EXCEPTION WHEN OTHERS THEN
          PERFORM private.push1_journaliser('remplacement_personne_en_salle', v_s.id::text, SQLSTATE);
        END;$b$, 1);
END;
$retouches$;

-- ---------------------------------------------------------------------------
-- 8. Droits et postflight
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.push1_ajouter(uuid,text,jsonb,text,text)'::regprocedure,
    'private.notifier_direction(text,jsonb,text,text,text)'::regprocedure,
    'private.push1_clore(text[],text)'::regprocedure,
    'private.push1_depuis_candidature()'::regprocedure,
    'private.push1_depuis_demande_horaire()'::regprocedure,
    'private.push1_depuis_piece()'::regprocedure,
    'private.push1_depuis_signalement()'::regprocedure,
    'private.push1_depuis_suppression()'::regprocedure,
    'private.push1_depuis_creneau_personnalise()'::regprocedure,
    'private.push1_depuis_commande()'::regprocedure,
    'private.push1_depuis_coordonnees()'::regprocedure,
    'private.push1_depuis_remboursement()'::regprocedure,
    'private.push1_apres_notification()'::regprocedure,
    'private.notification_geste_requis(text,jsonb)'::regprocedure,
    'private.remplacement_auto_passer(timestamptz)'::regprocedure]
  LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.push1_ajouter(uuid,text,jsonb,text,text)'::regprocedure,
    'private.notifier_direction(text,jsonb,text,text,text)'::regprocedure,
    'private.push1_clore(text[],text)'::regprocedure,
    'private.notification_geste_requis(text,jsonb)'::regprocedure,
    'private.remplacement_auto_passer(timestamptz)'::regprocedure]
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'PUSH-1 : % peut executer %', v_role, v_oid;
      END IF;
    END LOOP;
  END LOOP;
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                         WHERE p.oid = 'private.remplacement_auto_passer(timestamptz)'::regprocedure),
                       'remplacement_personne_en_salle'', ') = 0
     OR NOT private.notification_geste_requis('admission_recue', '{}'::jsonb)
     OR NOT private.notification_geste_requis('titulaire_en_retard', '{"portee":"direction"}'::jsonb)
     OR private.notification_geste_requis('titulaire_en_retard', '{"portee":"classe"}'::jsonb)
     OR NOT private.notification_geste_requis('paiement_relance', '{}'::jsonb) THEN
    RAISE EXCEPTION 'PUSH-1 : retouches absentes ou incompletes';
  END IF;
END;
$postflight$;
