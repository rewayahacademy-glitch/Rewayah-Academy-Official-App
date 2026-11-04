-- Lot (B), fichier 1 sur 2 (02/11/2026) : une bourse leve tout de suite une
-- suspension pour paiement (ordre du pilote du 02/11 : « levée immédiate dès
-- qu'une bourse ou un paiement est accordé »).
--
-- La table des suspensions n'admettait que deux motifs de retablissement
-- (« paiement », « facture_close », 20261018170000_fac_f, ligne 57). On y
-- ajoute « bourse ».
--
-- ATTENTION, mot DROP present (deux fois) : elargir une contrainte CHECK se fait
-- par DROP CONSTRAINT IF EXISTS puis ADD CONSTRAINT dans la meme transaction,
-- comme en 20261104300000. Aucune donnee n'est supprimee ; les lignes deja
-- presentes ont l'un des deux anciens motifs, admis par la nouvelle regle. Ce
-- fichier est SEUL : le directeur le colle par la page de collage ; le fichier
-- 2 (20261104600000_acces_paye_porte_serveur.sql), sans mot de suppression, est
-- pose par le pilote.
BEGIN;

ALTER TABLE public.acces_suspensions_paiement
  DROP CONSTRAINT IF EXISTS acces_suspensions_paiement_retabli_motif_check;
ALTER TABLE public.acces_suspensions_paiement
  ADD CONSTRAINT acces_suspensions_paiement_retabli_motif_check
  CHECK (retabli_motif IN ('paiement', 'facture_close', 'bourse'));

DO $postflight$
DECLARE
  v_def text;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.acces_suspensions_paiement'::regclass
     AND c.conname = 'acces_suspensions_paiement_retabli_motif_check';
  IF v_def IS NULL OR v_def NOT LIKE '%bourse%' OR v_def NOT LIKE '%paiement%' OR v_def NOT LIKE '%facture_close%' THEN
    RAISE EXCEPTION 'Lot B : contrainte des motifs de retablissement incomplete : %', v_def;
  END IF;
  -- Une seule contrainte sur ce motif : l'ancienne n'a pas survecu sous un autre nom.
  IF (SELECT count(*) FROM pg_catalog.pg_constraint c
       WHERE c.conrelid = 'public.acces_suspensions_paiement'::regclass AND c.contype = 'c'
         AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%retabli_motif = ANY%') <> 1 THEN
    RAISE EXCEPTION 'Lot B : plusieurs contraintes sur retabli_motif';
  END IF;
END;
$postflight$;

COMMIT;
