# L3-V - Vérification croisée de la vague 3 (doublons et simplification)

Vague 3. Dernier lot. Agent qui n'a écrit aucun des lots L3-01 à L3-07.

## 1. But et pourquoi

La vague 3 supprime et ferme : une salle, des RPC, du code mort, des libellés, des valeurs littérales. Le risque d'une suppression est de casser un chemin que personne n'a testé. Ce lot vérifie que rien de visible n'a disparu pour l'utilisateur, que les garde-fous sont bien à zéro, et que les mesures du rapport sont remises à jour.

## 2. Critère de réussite

C'est fini quand `docs/audit-final/verifications/L3-V-2026-10.md` contient :

1. SHA, lots fusionnés, rejeu SQL complet nominatif (74 + `af_*`) ;
2. les six commandes Flutter avec totaux ; `verifier_jetons` 0 ; `verifier_revue` 0 au-dessus du socle et le `git diff` du socle (suppressions seules) ;
3. la recette des parcours clés du rapport (section 5.4) sur la préversion, en démonstration : se connecter (adulte, enfant), rejoindre une séance (élève), lire le Coran, remplir le cahier, inscrire un enfant, décider d'un dossier, publier une offre (L2-05) ; nombre de gestes avant et après, captures ;
4. pour L3-01 : `/#/tc/classe/x` donne « introuvable » ; `/tc/groupes` mène à `/salle` ; les capacités D/F/H sont toujours dans `lib/` (`ls lib/core/tc_realtime lib/features/tc_dock`) ;
5. pour L3-02 (si fait) : aucune route, aucun écran, aucun libellé du matching ; le 1-à-1 possible comme Classe de capacité 1 ;
6. pour L3-05 : `dart run tool/doublons_i18n.dart | head -10` ; aucune fusion hors des cinq textes (comparer le diff des JSON) ;
7. pour L3-06 : `has_function_privilege` des huit fonctions ;
8. `docs/audit-final/MESURES-2026-10-16.md` sections 5.1, 5.2, 5.3 mises à jour avec les nouvelles mesures et la date ;
9. défauts et fiches de reprise `L3-xx-reprise.md`.

## 3. Ce qu'il faut lire

Les huit fiches `L3-*.md`, le rapport sections 5 et 6, `MESURES` section 5, `DESIGN-GOV` (pour juger les boutons passés en tonal par L3-07 et L4-03 s'il est fusionné).

## 4. Fichiers autorisés et interdits

Autorisés : `docs/audit-final/verifications/L3-V-2026-10.md`, `docs/audit-final/captures/lots/L3-V_*.png`, `docs/audit-final/MESURES-2026-10-16.md`, fiches de reprise. Interdits : code, migrations, STAGING en écriture, `.github/**`.

## 5. Étapes

1. Rejeu SQL complet. 2. Les six commandes Flutter, journal conservé. 3. Préversion : Playwright, 390 et 1440, clair, sombre, arabe sur trois écrans ; compter les gestes. 4. Les vérifications nominatives des critères 4 à 7. 5. Mettre à jour `MESURES`. 6. Rédiger.

## 6. Vérifications

Aucune affirmation sans commande et sortie ; `git status` : `docs/audit-final/` seulement.

## 7. Pièges connus

- Un écran qui ne montre plus un bouton n'est pas forcément une régression : vérifier la fiche du lot (L3-07 passe des boutons en tonal, L3-02 retire des écrans voulus).
- `verifier_revue` peut être à zéro parce que le socle a été augmenté : vérifier le `git diff` du socle, pas seulement le code de retour.

## 8. Quand s'arrêter et demander

Un parcours clé a perdu un geste nécessaire ou une fonction visible non prévue par une fiche : s'arrêter, nommer le lot.

## 9. Commit

Branche `lots/L3-V-verification`, partie de `claude/backend-reprise`. Message `docs(audit): verification croisee de la vague 3 doublons et simplification (L3-V)`. Jamais `main`.

## 10. Modèle conseillé

Sonnet ou plus ; agent différent des auteurs.

Esprit : vérifier que l'utilisateur n'a rien perdu ; le socle ne monte jamais ; chiffres remis à jour.
