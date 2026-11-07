-- PUSH-1 (a), decision du 07/11/2026 (directeur : « le vrai user a besoin des
-- notifications » ; garde-cap : chaque evenement qui attend un geste cree une
-- notification pour la bonne personne). Les evenements et les destinations
-- nouveaux dans les contraintes des notifications.
--
-- FICHIER A MOTS D'EFFACEMENT (deux DROP CONSTRAINT IF EXISTS, aucun autre) :
-- il ne contient que le remplacement de notifications_evenement_check et de
-- notifications_destination_check (DROP puis ADD), un preflight et un
-- postflight. Sans BEGIN ni COMMIT de premier niveau. Le directeur le colle
-- dans l'editeur SQL (page privee de tool/page_migrations), puis, dans la
-- meme page, 20261112000100_push1_file_et_abonnements.sql ; les deux
-- suivants le verifient en preflight et s'arretent s'il manque. Les noms gardent l'ordre d'installation pour la CI.
--
-- Listes de base : la derniere definition du depot pour chacune,
-- 20261107200001_d1ter_evenement_notification.sql (relue le 07/11 sur main
-- 9b4f763a ; aucune migration posterieure ne la change), identique a la
-- production par empreinte (releve du pilote du 07/11) :
--   md5(pg_get_constraintdef) evenements   = 95780c830c90d5250320e6f9e12d4d29
--   md5(pg_get_constraintdef) destinations = 6744be44fd564a62c57926c264e3778a
-- Le fichier est rejouable : deja applique, le preflight le dit et ne fait rien.
--
-- Ajouts, evenements (14) :
--   admission_recue, candidature_enseignant_a_examiner, demande_horaire_recue,
--   creneau_personnalise_demande, piece_identite_deposee,
--   signalement_eleve_recu, suppression_compte_demandee,
--   remplacement_personne_en_salle, paiement_echoue,
--   versement_coordonnees_a_valider, versement_coordonnees_validees,
--   remboursement_demande, remboursement_echec, cahier_en_retard (type seul :
--   aucun emetteur dans ce lot, le lot C3 le cree). Pas d'evenement propre
--   aux apprenants d'une candidature : ils sont lus avec l'admission, au
--   COMMIT (garde-cap, 07/11 : une notification seulement quand un geste de
--   la direction est attendu).
-- Ajouts, destinations (10), chacune lue dans lib/core/router/routes.dart :
--   '/admin/personnes/candidatures'            routes.dart:791-792 (candidatures d'enseignement)
--   '/admin/personnes/demandes'                routes.dart:821 (admissions des familles et des eleves adultes)
--   '/admin/operations/demandes'               routes.dart:714
--   '/admin/personnes/dossiers'                routes.dart:827 (app_router.dart:2081)
--   '/admin/alertes'                           routes.dart:693 (signalements : alertes_page.dart:19-20)
--   '/admin/personnes/suppressions'            routes.dart:817
--   '/admin/finance/paiements'                 routes.dart:1064
--   '/comptable/tresorerie/paiements-familles' routes.dart:1032
--   '/comptable/paiements/beneficiaires'       routes.dart:1009
--   '/compte/paiements-recus'                  routes.dart:1049 (l'enseignant)

DO $preflight$
DECLARE
  v_evt text;
  v_dest text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_evt FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_dest FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_destination_check';
  IF v_evt LIKE '%''versement_coordonnees_validees''%' AND v_dest LIKE '%''/compte/paiements-recus''%' THEN
    RAISE NOTICE 'PUSH-1 : contraintes deja elargies, le fichier est rejoue sans effet';
    RETURN;
  END IF;
  IF pg_catalog.md5(v_evt) <> '95780c830c90d5250320e6f9e12d4d29' THEN
    RAISE EXCEPTION 'PUSH-1 : notifications_evenement_check a change depuis le releve du 07/11 (md5 %), arret',
      pg_catalog.md5(v_evt);
  END IF;
  IF pg_catalog.md5(v_dest) <> '6744be44fd564a62c57926c264e3778a' THEN
    RAISE EXCEPTION 'PUSH-1 : notifications_destination_check a change depuis le releve du 07/11 (md5 %), arret',
      pg_catalog.md5(v_dest);
  END IF;
END;
$preflight$;

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
  'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation',
  'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
  'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
  'classe_supprimee',
  'remplacement_avertissement', 'remplacement_pre_alerte', 'remplacement_inutile',
  'titulaire_en_retard', 'remplacant_arrive',
  'paiement_recu',
  'seance_terminee',
  -- FN-115b (02/11/2026).
  'remboursement_effectue', 'litige_ouvert', 'litige_clos',
  -- SNT (03/11/2026) : la seance non tenue est reportee.
  'seance_reportee',
  -- D1-ter (03/11/2026) : la direction a transmis un message sur l'eleve.
  'message_academie_eleve',
  -- PUSH-1 (07/11/2026) : ce qui attend un geste, par role.
  'admission_recue', 'candidature_enseignant_a_examiner', 'demande_horaire_recue',
  'creneau_personnalise_demande', 'piece_identite_deposee', 'signalement_eleve_recu',
  'suppression_compte_demandee', 'remplacement_personne_en_salle', 'paiement_echoue',
  'versement_coordonnees_a_valider', 'versement_coordonnees_validees',
  'remboursement_demande', 'remboursement_echec', 'cahier_en_retard'));

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_destination_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK (
  destination IN (
    '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
    '/admin/securite-audit/tirages', '/tuteur/foyer/recharge',
    '/eleve', '/tuteur', '/enseignant/classes', '/enseignant/journee',
    '/admin/operations/planning',
    -- FN-115b (02/11/2026) : la finance de la direction.
    '/admin/finance',
    -- D1-ter (03/11/2026) : l'Historique du tuteur, le Suivi de l'eleve adulte.
    '/tuteur/suivi', '/eleve/suivi',
    -- PUSH-1 (07/11/2026) : la direction, le comptable, l'enseignant.
    '/admin/personnes/candidatures', '/admin/personnes/demandes', '/admin/operations/demandes',
    '/admin/personnes/dossiers', '/admin/alertes', '/admin/personnes/suppressions',
    '/admin/finance/paiements', '/comptable/tresorerie/paiements-familles',
    '/comptable/paiements/beneficiaires', '/compte/paiements-recus')
  OR destination ~ '^/tuteur/classes/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/planning)?$');

DO $postflight$
DECLARE
  v_evt text;
  v_dest text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_evt FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_dest FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_destination_check';
  IF v_evt IS NULL OR v_evt NOT LIKE '%''message_academie_eleve''%'
     OR v_evt NOT LIKE '%''admission_recue''%' OR v_evt NOT LIKE '%''cahier_en_retard''%'
     OR v_evt NOT LIKE '%''paiement_echoue''%' OR v_evt NOT LIKE '%''demande_recue''%' THEN
    RAISE EXCEPTION 'PUSH-1 : contrainte des evenements incomplete : %', v_evt;
  END IF;
  IF v_dest IS NULL OR v_dest NOT LIKE '%''/compte/paiements-recus''%'
     OR v_dest NOT LIKE '%''/admin/alertes''%' OR v_dest NOT LIKE '%''/eleve/suivi''%'
     OR v_dest NOT LIKE '%/tuteur/classes/%' THEN
    RAISE EXCEPTION 'PUSH-1 : contrainte des destinations incomplete : %', v_dest;
  END IF;
END;
$postflight$;
