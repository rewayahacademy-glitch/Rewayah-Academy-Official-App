# Reprise du lot « classe » en minuscule (07/11/2026)

Lot rendu par le lot 7 (FINITION) à la session qui le reprend, sur ordre du directeur (23:49 UTC,
06/11). Branche `claude/classe-minuscule`, base `main` 7b3a3f05.

## Ce qui est faux ou non prouvé, en premier

- **Aucune suite complète** sur l'état final (`4b582061`) : la dernière suite complète a tourné sur la
  première version (155 lignes) et a montré 5 rouges ; les 4 textes de démonstration sont corrigés,
  le cinquième a conduit à exclure le parcours du candidat. Les fichiers touchés et `test/features/candidature`
  sont verts (642 tests).
- La branche part de main 7b3a3f05 : elle se **refait sur un main frais** (rebase ou nouvelle passe du
  script), en dernier, au train C, sur ordre du pilote. Le lot 7 a déjà mis en minuscule les 10
  « cette Classe » (FINITION 22 b) : le script ne les voit plus, ce n'est pas un écart.

## La règle (garde-cap, 06/11/2026)

« classe(s) » en minuscule au milieu d'une phrase, y compris « la classe An-Nour ». La majuscule reste :

1. en début de phrase et de titre ;
2. dans « Espace Classe » (nom d'écran) ;
3. dans `juridique.*` et `contrat.politique.*` (un texte juridique change avec une nouvelle version
   et une nouvelle acceptation) ;
4. dans `recrutement.parcours.*` et `recrutement.questionnaire.*` (28 clés) : réponse du directeur du
   22/10/2026, « Combien de Classes voulez-vous tenir ? », verrouillée par
   `test/features/candidature/libelles_parcours_test.dart` (« « Classe » prend sa majuscule partout
   dans le parcours du candidat »), **qui reste tel quel**.

Français seulement (`assets/i18n/fr.i18n.json`).

## La méthode, sur main frais

```
python3 tool/classe_minuscule.py            # liste ce qui changerait (rien n'est écrit)
python3 tool/classe_minuscule.py --ecrire   # écrit fr.i18n.json, sans reformater
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

Sur main 7b3a3f05 : 128 lignes, 136 remplacements. Puis :

- **Tests qui citent ces phrases mot pour mot** (déjà corrigés sur cette branche, à reporter s'ils ont
  bougé) : `test/core/communications/n1_branchement_test.dart`,
  `test/features/com_studio/aujourdhui_anti_doublon_test.dart`,
  `test/features/com_studio/studio_page_test.dart` (l. 624),
  `test/features/fiche_groupe_pause/bloc_pause_classe_test.dart`,
  `test/features/journee/absence_remplacement_test.dart`,
  `test/features/salle_seance/guidee_fin_test.dart`,
  `test/features/salle_seance/vue_seance_secours_test.dart`,
  `test/features/salle_seance/salle_secours_t_s5_test.dart`.
- **Les 4 textes de démonstration cités dans les tests** :
  `test/features/com_messages/com_rc_tour7_m_test.dart` (« Visite de contrôle, classe An »),
  `test/features/com_messages/modeles_et_demo_test.dart` (« Visite de contrôle, classe An-Nour »),
  `test/features/admin_configuration/regles_page_test.dart` (« ne retire aucune classe »),
  `test/features/classe_tuteur/com_rc7_lot_l_test.dart` (l'annonce nomme la classe : comparaison
  sans casse, le nom propre reste « Classe An-Nour »).
- **Socle de revue** : `tool/revue_socle.txt`, la ligne `erreur-sans-action` de
  `enseignant.revue.erreurDetail` suit le nouveau texte (« Cette classe n'est… »). Sans elle,
  `verifier_revue` compte une violation de plus que main.
- Contrôles : `dart analyze --fatal-infos`, `verifier_revue` (égal à main), **suite complète**.
