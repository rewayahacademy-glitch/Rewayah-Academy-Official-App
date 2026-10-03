# BENTO-1b-R : revue croisée de BENTO-1b (grille Bento selon la largeur par colonne)

- Session de revue : c3316e32 (n'a pas écrit le code ; auteur b0cfa272). 03/10/2026, ~06 h 50.
- Relu : `corrections/c2-bento1b` @ `30e762a` (52918b9, 5f79925, 7079b79, 30e762a), dans un worktree à part `D:\RA_TUTEUR\r-bento1b`, détaché, rien commité.

## Verdict

**Accepté. 0 bloquant, 0 moyen, 2 mineurs.**

## Ce qui a été vérifié, avec preuve

1. **Le défaut d'origine est corrigé dans la vraie application.** Vraie coquille admin (barre latérale de 288 px), vrai routeur, démonstration admin : à 1440 px et texte × 2, la grille fait 1088 px de large et garde **4 colonnes** aux tailles variées (`reel_1440x2.png`). Avant : 5 bandes pleine largeur.
2. **Mesure sur 36 cas** (6 largeurs × 6 échelles, `mesures.txt`, test `mesure_test.dart.txt`) : 1440 et 1280 gardent 4 colonnes jusqu'à × 1,75 ; 1280 × 2 et 1024 × 2 passent à 2 ; 390 × 1,75 et 360 × 1,5 passent à 1 colonne. Jamais 3 colonnes, jamais de débordement.
3. **Tests de la branche relancés par le verrou** : `grille_bento_test`, `tableau_de_bord_test`, `cartes_collees_test`, `rtl_echelle_texte_ecrans_test` : **114 réussis, 0 échec**. `dart analyze` des fichiers touchés : 0 remarque.
4. **Code** : `colonnesPour` divise 4 → 2 → 1 tant que la colonne fait moins de 112 px × échelle ; `hauteurLignePour` agrandit les lignes avec le texte ; `_TuileCompteur` suit la même hauteur. Les deux libellés `admin.tableau.dossiersDetail` et `demandesDetail` sont bien déclarés dans `tool/libelles_sources.json` avec le statut « à faire valider ».
5. Les captures de l'auteur (harnais sans barre latérale, 1134 px de large) disent « 4 colonnes à 1440 × 2 » : c'est aussi vrai dans l'application réelle (point 1).

## Mineurs

- **m1 → BENTO-1c.** Entre deux paliers, une tuile peut être réduite de 3 à 7 % par son `FittedBox` au lieu d'afficher le texte à la taille demandée : 768 × 1,3 → 1,21 effectif ; 360 × 1,15 → 1,08 ; 390 × 1,3 → 1,26 ; 360 × 1,3 → 1,26 ; 1024 × 1,75 → 1,68 (`mesures.txt`, `reel_768x1_3.png`). Rien n'est coupé. Piste : relever un peu `largeurMinCellule` aux échelles intermédiaires, ou vérifier la hauteur utile réelle avant de garder la colonne.
- **m2 → COUPE-MOTS-1 (hors grille).** À 1440 × 2, le nom en bas de la barre latérale admin est coupé au milieu du mot : « Administrat / eur » (`reel_1440x2.png`).

## Note de méthode

Les captures réelles signalent une `MissingPluginException` (`path_provider`, base locale drift) propre au harnais de test : aucune exception de mise en page.
