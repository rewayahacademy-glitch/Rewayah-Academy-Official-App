# Revue adverse : DUREE-INSECABLE-1 (corrections/c2-duree, 91aec131)

**Verdict : REFUSÉE**

Le cœur de la demande est rempli et prouvé : à 320 px texte x2, en LTR comme en RTL, une durée ne se scinde plus, et « Aucune séance » n'est plus rogné. Mais la correction du sélecteur de profils introduit une régression visible au réglage par défaut. Je la classe majeure : à 390 px et à 1440 px en texte x1, « Dans 3 h 28 » et « Aucune séance » passent maintenant à la ligne alors qu'ils tenaient sur une ligne avant.

## Méthode
- Deux worktrees jetables, détachés : l'un sur origin/corrections/c2-duree, l'autre réservé aux mutations. Les deux sont retirés à la fin, rien n'a été poussé.
- J'ai lu tout le diff de `lib` (6 fichiers) et des tests, et ouvert les 8 captures du rédacteur.
- J'ai pris 10 captures de mon côté : famille en 390x1 sombre, 1440x1 clair et 320x2 sombre, et Historique en 320x2, chaque fois en LTR et RTL. J'ai aussi pris des captures de la base en 390x1 et 1440x1 pour comparer.

## Contrôles
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucune remarque |
| `tool/verifier_revue.dart` | 1606, égal à la base |
| `tool/verifier_jetons.dart` | 39 lignes, liste identique ligne à ligne à la base (diff vide) |
| `flutter test --concurrency=2` sur tous les dossiers sauf capture, fixtures et support | **+5851, ~2137 sautés, 0 échec** |
| Tests ciblés (`duree_insecable_test.dart`, `accueil_famille_test.dart`) | 89 verts |

## Mutations
1. `insecable` neutralisé (renvoie le texte tel quel) : **17 échecs**. Échouent les 7 tests de formatage, les 6 tests en vraies polices de 120 à 320 px (LTR et RTL), les 2 tests Accueil Accessibilité + CarteSession et les 2 tests DUREE-INSECABLE-1 de l'Accueil famille. La contre-épreuve est donc réelle.
2. `selecteur_profils.dart` remis à l'état de la base : 2 échecs. « Aucune séance » déborde, bord à 331,5 px en LTR et -11,5 px en RTL, ce qui confirme le compte rendu.
3. Modification de `texte_sans_coupure.dart` retirée : **aucun échec**. Ce changement n'est couvert par aucun test (défaut mineur).

## Captures
- 320x2, famille, LTR et RTL : avant, on lit « Cours dans 3 h / 28 » et « Aucune séan » rogné. Après, on lit « Cours dans / 3 h 28 » et « Aucune / séance ». Conforme à la demande.
- 320x2, Accessibilité : « Cours dans / 3 h 28 », « 45 min » sur une ligne. Conforme. Le fichier `accueil_accessibilite.dart` n'a pas été touché.
- 320x2, Historique (autre appelant de SelecteurProfils) : correct.
- **390x1 sombre et 1440x1 : régression.** Sur la base, « Dans 3 h 28 » et « Aucune séance » tiennent sur une ligne. Sur la branche, ils passent à « Dans / 3 h 28 » et « Aucune / séance ». L'item est plafonné à max(couronne, prénom, mot le plus long de l'état) même quand l'état entier tient. La demande voulait qu'on passe à la ligne au lieu d'être rogné, pas qu'on passe à la ligne systématiquement.
- RTL : « min 45 » et « Paris 21:28 », un défaut de sens d'écriture (bidi) déjà présent avant la branche et signalé honnêtement par le rédacteur.

## Défauts
1. **Majeur**, sélecteur de profils : retour à la ligne forcé à 390 et à 1440 en texte x1, sur l'Accueil famille et l'Historique. Pistes de correction : plafonner à max(couronne, prénom, min(largeur de l'état entier sur une ligne, borne)), ou ne contraindre l'item que s'il dépasse. Ajouter un test qui vérifie que l'état tient sur une ligne à 390x1 et 1440x1.
2. Mineur : aucun test ne couvre le changement de `TexteSansCoupure`.
3. Mineur : d'autres durées restent sécables (historique, timeline enseignant, en-tête de classe « Reste », contrôleur, observation). Le rédacteur le déclare ; ces écrans sont hors de ceux cités.
4. Préexistant : « min 45 » en RTL.

## Ce qui est acquis
- `LibellesGroupe.insecable` : les expressions régulières sont correctes et ne touchent que les espaces liés aux durées.
- Il est appliqué au compte à rebours, au temps restant, à la durée prévue, au `_dans` du bloc de séance, au minuteur de l'enseignant et au compte à rebours de l'élève.
- Le nouveau détecteur `mesurerDurees` / `verifierDureesSurUneLigne` est pertinent : il détecte la coupure entre deux mots que `motsCoupes` ne voyait pas.
- Les tests existants ont été alignés proprement, et rien n'est modifié dans les zones interdites.

## Pour accepter
Corriger le défaut 1 avec un test à 390x1 et 1440x1 qui échoue sur 91aec131. Le défaut 2 est recommandé.
