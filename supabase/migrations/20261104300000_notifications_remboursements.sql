-- FN-115b, fichier 1 sur 2 (02/11/2026) : trois evenements de notification et
-- la destination de la direction pour les remboursements et contestations.
--
-- Decision du directeur du 01/11/2026 (« oui pour les 7 points ») : la famille
-- est prevenue par e-mail et dans l'application, la direction dans
-- l'application, l'enseignant jamais. DECISION-TARIFS-2026-10-18.md, section
-- du 01/11/2026.
--
-- ATTENTION, mot DROP present (deux fois) : elargir les contraintes CHECK de
-- public.notifications se fait comme en 20261103600000 et 20261102500000, par
-- DROP CONSTRAINT IF EXISTS puis ADD CONSTRAINT dans la meme transaction.
-- Aucune donnee n'est supprimee. Ce fichier est SEUL (consigne du pilote,
-- 02/11) : le directeur le colle par la page de tool/page_migrations/generer.py ;
-- le fichier 2 (20261104400000_remboursements_litiges_stripe.sql), sans aucun
-- mot de suppression, est pose par le pilote.
--
-- 1. Evenements : les 29 de 20261103600000 (verifies en production par le
--    pilote) plus remboursement_effectue, litige_ouvert, litige_clos.
-- 2. Destinations : celles de 20261102500000 plus « /admin/finance », ou la
--    direction lit les remboursements et contestations.
BEGIN;

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
  'remboursement_effectue', 'litige_ouvert', 'litige_clos'));

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_destination_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK (
  destination IN (
    '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
    '/admin/securite-audit/tirages', '/tuteur/foyer/recharge',
    '/eleve', '/tuteur', '/enseignant/classes', '/enseignant/journee',
    '/admin/operations/planning',
    -- FN-115b (02/11/2026) : la finance de la direction.
    '/admin/finance')
  OR destination ~ '^/tuteur/classes/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/planning)?$');

DO $postflight$
DECLARE
  v_def text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL OR v_def NOT LIKE '%remboursement_effectue%' OR v_def NOT LIKE '%litige_ouvert%'
     OR v_def NOT LIKE '%litige_clos%' OR v_def NOT LIKE '%seance_terminee%' OR v_def NOT LIKE '%paiement_recu%' THEN
    RAISE EXCEPTION 'FN-115b : contrainte des evenements incomplete : %', v_def;
  END IF;
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_destination_check';
  IF v_def IS NULL OR v_def NOT LIKE '%/admin/finance%' OR v_def NOT LIKE '%/admin/operations/planning%' THEN
    RAISE EXCEPTION 'FN-115b : contrainte des destinations incomplete : %', v_def;
  END IF;
END;
$postflight$;

COMMIT;
