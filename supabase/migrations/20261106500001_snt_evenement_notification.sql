-- SNT (03/11/2026) : l'evenement « seance_reportee » dans les notifications.
--
-- FICHIER A MOTS D'EFFACEMENT (B5) : il ne contient que le remplacement de la
-- contrainte notifications_evenement_check (DROP puis ADD, dans la meme
-- transaction). Le directeur le colle dans l'editeur SQL, AVANT
-- 20261106500000_snt_seance_non_tenue.sql (qui le verifie en postflight et
-- previent s'il manque) ; la CI les applique dans l'ordre des noms, ce qui
-- est sans effet : 20261106500000 ne pose aucune notification a
-- l'installation.
--
-- La liste : celle de la derniere definition du depot
-- (20261104300000_notifications_remboursements.sql, aucune migration
-- posterieure ne la change, relu le 03/11 sur main cafe1a6a), identique a la
-- definition en base apres toutes les migrations sur Postgres 17 nu, plus
-- 'seance_reportee'. La seule contrainte retouchee est celle des evenements ;
-- celle des destinations ne change pas (notifier_classe ecrit des
-- destinations deja admises).
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
  'remboursement_effectue', 'litige_ouvert', 'litige_clos',
  -- SNT (03/11/2026) : la seance non tenue est reportee.
  'seance_reportee'));

DO $postflight$
DECLARE
  v_def text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL OR v_def NOT LIKE '%''seance_reportee''%'
     OR v_def NOT LIKE '%''litige_clos''%' OR v_def NOT LIKE '%''seance_terminee''%'
     OR v_def NOT LIKE '%''remplacant_arrive''%' OR v_def NOT LIKE '%''demande_recue''%' THEN
    RAISE EXCEPTION 'SNT : contrainte des evenements incomplete : %', v_def;
  END IF;
END;
$postflight$;

COMMIT;
