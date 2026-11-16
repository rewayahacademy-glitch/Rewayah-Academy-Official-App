-- BE-VERSEMENT : recalcul unique des candidatures en cours dont le versement est
-- `a_verifier` ou `incompatible`, avec la nouvelle regle (20261128200000).
--
-- A installer APRES 20261128200000 seulement. Ce fichier ne contient aucun mot d'effacement,
-- ni BEGIN ni COMMIT seul sur une ligne.
--
-- Chaque candidature passe par private.paiement_recalculer(id, 'referentiel'), comme le fait
-- le declencheur du referentiel : un evenement `controle` est journalise quand la valeur
-- change, avec sa cause. Sans auteur (le systeme). Aucun courriel : la branche suivie pour un
-- simple changement de valeur n'ecrit que `paiement` et `version`, n'ecrit pas `aNotifier`
-- et ne touche ni l'etape, ni l'etat, ni l'issue (le push part sur ces colonnes seules). Une
-- candidature dont l'etat est paiement_non_disponible n'est PAS ramenee a a_completer : cela
-- demande la transition 9 (ligne passee `confirme` a l'instant), qui previent la personne ;
-- ce n'est pas l'objet de ce recalcul.
--
-- Rejouable : un second passage ne change plus rien (aucun evenement, aucune version).
-- Le nombre de candidatures examinees et changees est rendu en NOTICE.

DO $recalcul$
DECLARE
  r record;
  v_res jsonb;
  v_examinees integer := 0;
  v_changees integer := 0;
BEGIN
  FOR r IN
    SELECT c.id
      FROM public.candidatures c
     WHERE c.issue = 'en_cours'
       AND c.profile_id IS NOT NULL
       AND c.etape IN ('prequalification', 'verifications', 'confirmee')
       AND c.paiement IN ('a_verifier', 'incompatible')
     ORDER BY c.id
  LOOP
    v_res := private.paiement_recalculer(r.id, 'referentiel');
    v_examinees := v_examinees + 1;
    IF v_res ->> 'paiementAvant' IS DISTINCT FROM v_res ->> 'paiementApres' THEN
      v_changees := v_changees + 1;
    END IF;
  END LOOP;
  RAISE NOTICE 'BE-VERSEMENT : % candidatures examinees, % changees', v_examinees, v_changees;
END;
$recalcul$;
