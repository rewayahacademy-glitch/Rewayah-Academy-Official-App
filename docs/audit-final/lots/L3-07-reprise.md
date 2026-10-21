# L3-07-reprise - un seul message hors ligne dans la préparation, garde-fous qui ne passent pas au vert sur une panne

Reprise issue de L3-V (défauts E-1 et E-2). Petit lot.

## 1. But et pourquoi

E-1. L3-07 a passé la préparation de la salle (`_PreparationBranchee`, `_PreparationEleveBranchee`, `lib/features/salle/salle_page.dart`) dans `PageShell`. `PageShell` pose par défaut `OfflineBanner` : hors ligne, l'élève et l'enseignant voient maintenant deux messages, le bandeau générique « Pas de réseau. Ce qui est déjà affiché reste consultable. » au-dessus du message propre de la préparation (« Vous êtes hors ligne. La séance nécessite une connexion. », ou la phrase de l'Interface guidée). Le bandeau générique est faux ici (rien n'est consultable, la séance exige le réseau). Sonde L3-V (test hors dépôt, `PageShell` contre `Scaffold`) : bandeau générique 0 avant, 1 après, en standard comme en Interface guidée.

E-2. `test/tool/garde_fous_test.dart` reste vert quand `verifier_jetons` plante : il ne lit que les lignes de violation de la sortie et ne regarde ni le code de retour ni la ligne de total. Essai L3-V sur une copie : outil remplacé par `throw StateError`, plus une `Duration(milliseconds: 1)` ajoutée dans `lib/` : `All tests passed!`.

## 2. Critère de réussite

1. Les deux préparations passent `bandeauHorsLigne: const SizedBox.shrink()` à `PageShell` (même voie que les Communications, D-FUS-3) ; un test widget : hors ligne, `t.reseau.horsLigne` absent, le message propre de la préparation présent, en standard et en Interface guidée.
2. `garde_fous_test.dart`, test des jetons : exige un code de retour 0 ou 1 et la présence de la ligne « N violation(s) » ou « aucune violation » ; rouge si l'outil plante (essai à refaire et à écrire dans le commit).
3. `verifier_jetons` toujours 2 (A-13), `verifier_revue` sans compte en hausse.

## 3. Ce qu'il faut lire

`lib/core/widgets/page_shell.dart` (paramètre `bandeauHorsLigne`), `lib/features/salle/salle_page.dart` vers les lignes 2443 et 2485, `test/tool/garde_fous_test.dart`, `tool/verifier_jetons.dart` (format de sortie).

## 4. Fichiers autorisés et interdits

Autorisés : `lib/features/salle/salle_page.dart` (les deux `PageShell` seulement), `test/tool/garde_fous_test.dart`, un test sous `test/features/classe_eleve/`. Interdits : `lib/core/**`, `tool/**`, `supabase/**`.

## 5. Étapes

1. Ajouter `bandeauHorsLigne: const SizedBox.shrink()` aux deux appels.
2. Écrire le test hors ligne.
3. Durcir le test des jetons, prouver qu'il rougit sur un outil qui plante, annuler l'essai.

## 6. Vérifications

Les six commandes ; `flutter test test/features/classe_eleve test/tool`.

## 7. Pièges connus

- Ne pas retirer `PageShell` : c'est lui qui a fait passer `verifier_jetons` de 12 à 2.
- `garde_fous_test` lance `dart run` : `dart` doit être dans le `PATH` de la suite.

## 8. Quand s'arrêter et demander

Si une capture de la préparation (`test/capture/ctrl_prevol1_capture_test.dart`) change ailleurs que sur le bandeau : s'arrêter et le dire.

## 9. Commit

- Branche : `lots/L3-07R-preparation-hors-ligne`, partie de `lots/V34-candidate`.
- Message : `fix(salle): un seul message hors ligne dans la preparation, garde-fou des jetons rouge sur panne (L3-07-reprise)`.

## 10. Modèle conseillé

Haiku suffit.
