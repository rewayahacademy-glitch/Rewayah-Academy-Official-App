-- BE-VERSEMENT : recalcul unique des candidatures en cours dont le versement est
-- `a_verifier` ou `incompatible`, avec la nouvelle regle (20261128200000).
--
-- A installer APRES 20261128200000 seulement. Ce fichier ne contient aucun mot d'effacement,
-- ni BEGIN ni COMMIT seul sur une ligne.
--
-- Chaque candidature passe par private.paiement_recalculer(id, 'referentiel'), comme le fait
-- le declencheur du referentiel : un evenement `controle` est journalise quand la valeur
-- change, avec sa cause, sans auteur (le systeme).
--
-- * Un simple changement de valeur (une candidature en examen, a completer, en salle 2 ou 3)
--   n'ecrit que `paiement` et `version` : ni etape, ni etat, ni issue, aucun `aNotifier`, donc
--   aucun courriel et aucun push.
-- * Une candidature dont l'etat est paiement_non_disponible ET dont le nouveau calcul est
--   `compatible` revient a `a_completer` par la transition 9 (p_ligne_confirmee = true) : c'est
--   une bonne nouvelle pour la personne, et l'evenement porte `aNotifier: paiement_possible`
--   (l'avis existant). Le drapeau n'est JAMAIS passe a true pour un dossier qui reste
--   `incompatible` : la transition 9 ne verifie pas elle-meme le resultat du calcul.
--
-- Rejouable : un second passage ne change plus rien (aucun evenement, aucune version).
-- Rend en NOTICE le nombre de candidatures examinees, changees et ramenees a a_completer.

DO $recalcul$
DECLARE
  r record;
  v_res jsonb;
  v_ramene boolean;
  v_examinees integer := 0;
  v_changees integer := 0;
  v_ramenees integer := 0;
BEGIN
  FOR r IN
    SELECT c.id, c.etat
      FROM public.candidatures c
     WHERE c.issue = 'en_cours'
       AND c.profile_id IS NOT NULL
       AND c.etape IN ('prequalification', 'verifications', 'confirmee')
       AND c.paiement IN ('a_verifier', 'incompatible')
     ORDER BY c.id
  LOOP
    v_ramene := r.etat = 'paiement_non_disponible' AND private.paiement_etat(r.id) = 'compatible';
    v_res := private.paiement_recalculer(r.id, 'referentiel', NULL, NULL, NULL, v_ramene);
    v_examinees := v_examinees + 1;
    IF v_res ->> 'paiementAvant' IS DISTINCT FROM v_res ->> 'paiementApres' THEN
      v_changees := v_changees + 1;
    END IF;
    IF v_res ->> 'effet' = 'a_completer' THEN
      v_ramenees := v_ramenees + 1;
    END IF;
  END LOOP;
  RAISE NOTICE 'BE-VERSEMENT : % candidatures examinees, % changees, % ramenees a a_completer',
    v_examinees, v_changees, v_ramenees;
END;
$recalcul$;
