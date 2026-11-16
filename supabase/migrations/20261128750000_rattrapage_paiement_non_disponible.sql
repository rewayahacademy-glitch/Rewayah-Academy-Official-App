-- RATTRAPAGE-PAIEMENT (pilote, 16/11/2026, capture CAND-00137) : des candidatures sont restees
-- etat = 'paiement_non_disponible' alors que leur versement est desormais compatible
-- (CAND-00019, CAND-00126, CAND-00137, CAND-00419 en production). Elles ont corrige leur reponse
-- entre 06:55 et 10:47 UTC le 16/11, AVANT l'installation de 20261128500100 (13:11 UTC) : le
-- recalcul de cause 'reponses' ne pouvait pas encore les ramener a a_completer (transition 9).
-- Le correctif existe deja pour l'avenir ; ce fichier rattrape le passe.
--
-- A installer APRES 20261128500100. Ce fichier ne contient aucun mot d'effacement, ni BEGIN ni
-- COMMIT seul sur une ligne. Calque sur 20261128200100_be_versement_recalcul.
--
-- Pour chaque candidature en cours, en prequalification, dont l'etat est paiement_non_disponible
-- ET dont le calcul en direct (private.paiement_etat) est `compatible` : le recalcul du
-- referentiel avec le drapeau de la transition 9. Le drapeau n'est jamais passe pour un dossier
-- qui reste incompatible. Un evenement `transition` (9) porte l'avis paiement_possible, la
-- personne est prevenue comme pour toute bonne nouvelle de versement.
--
-- Rejouable : un second passage ne trouve plus rien. Controle final : si une ligne reste dans ce
-- cas, la migration echoue (rien n'est ecrit, apply_migration est atomique).

DO $rattrapage$
DECLARE
  r record;
  v_res jsonb;
  v_examinees integer := 0;
  v_ramenees integer := 0;
  v_restantes integer;
BEGIN
  FOR r IN
    SELECT c.id
      FROM public.candidatures c
     WHERE c.issue = 'en_cours'
       AND c.profile_id IS NOT NULL
       AND c.etape = 'prequalification'
       AND c.etat = 'paiement_non_disponible'
       AND private.paiement_etat(c.id) = 'compatible'
     ORDER BY c.id
  LOOP
    v_res := private.paiement_recalculer(r.id, 'referentiel', NULL, NULL, NULL, true);
    v_examinees := v_examinees + 1;
    IF v_res ->> 'effet' = 'a_completer' THEN
      v_ramenees := v_ramenees + 1;
    END IF;
  END LOOP;

  SELECT pg_catalog.count(*) INTO v_restantes
    FROM public.candidatures c
   WHERE c.issue = 'en_cours'
     AND c.profile_id IS NOT NULL
     AND c.etape = 'prequalification'
     AND c.etat = 'paiement_non_disponible'
     AND private.paiement_etat(c.id) = 'compatible';
  IF v_restantes > 0 THEN
    RAISE EXCEPTION 'RATTRAPAGE-PAIEMENT : % candidature(s) restent paiement_non_disponible alors que compatibles', v_restantes;
  END IF;
  RAISE NOTICE 'RATTRAPAGE-PAIEMENT : % candidatures examinees, % ramenees a a_completer',
    v_examinees, v_ramenees;
END;
$rattrapage$;
