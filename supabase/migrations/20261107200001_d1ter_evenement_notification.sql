-- D1-ter (03/11/2026) : l'evenement « message_academie_eleve » et ses deux
-- destinations dans les contraintes des notifications.
--
-- FICHIER A MOTS D'EFFACEMENT (B5) : il ne contient que le remplacement de deux
-- contraintes, notifications_evenement_check et notifications_destination_check
-- (pour chacune, DROP CONSTRAINT IF EXISTS puis ADD), et un postflight. Sans
-- BEGIN ni COMMIT de premier niveau (consigne du pilote, 03/11). Le directeur
-- le colle dans l'editeur SQL, AVANT 20261107200000_d1ter_famille_lit_transmis.sql
-- (qui le verifie en postflight et previent s'il manque) ; la CI les applique
-- dans l'ordre des noms, ce qui est sans effet : 20261107200000 n'insere
-- aucune notification a l'installation.
--
-- Les listes : celles de la derniere definition du depot pour chacune
-- (evenements : 20261106500001_snt_evenement_notification.sql, seance_reportee
-- comprise ; destinations : 20261104300000_notifications_remboursements.sql ;
-- aucune migration posterieure ne les change, relu le 03/11 sur main
-- 203acc07), identiques a la definition en base apres toutes les migrations
-- sur Postgres 17 nu, plus :
--   - evenement 'message_academie_eleve' ;
--   - destinations '/tuteur/suivi' (l'Historique du tuteur, ou se lit la carte)
--     et '/eleve/suivi' (le Suivi de l'eleve adulte).

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
  'message_academie_eleve'));

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
    '/tuteur/suivi', '/eleve/suivi')
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
     OR v_evt NOT LIKE '%''seance_reportee''%' OR v_evt NOT LIKE '%''litige_clos''%'
     OR v_evt NOT LIKE '%''demande_recue''%' THEN
    RAISE EXCEPTION 'D1-ter : contrainte des evenements incomplete : %', v_evt;
  END IF;
  IF v_dest IS NULL OR v_dest NOT LIKE '%''/tuteur/suivi''%' OR v_dest NOT LIKE '%''/eleve/suivi''%'
     OR v_dest NOT LIKE '%''/admin/finance''%' OR v_dest NOT LIKE '%/tuteur/classes/%' THEN
    RAISE EXCEPTION 'D1-ter : contrainte des destinations incomplete : %', v_dest;
  END IF;
END;
$postflight$;
