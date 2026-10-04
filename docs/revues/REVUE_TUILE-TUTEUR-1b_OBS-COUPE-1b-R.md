## Verdict : ACCEPTÉE AVEC RÉSERVES

Lot relu : `corrections/c2-obs-coupe-b` (a597217d), sur `origin/corrections/c2-obs-coupe`, étapes TUILE-TUTEUR-1b et OBS-COUPE-1b.

J'ai refait chaque preuve des deux rapports refusés sur la nouvelle tête. Les quatre défauts majeurs sont levés :
- OBS-COUPE-1, majeurs 1 et 2 ;
- TUILE-TUTEUR-1, majeurs 1 et 2.

Les nouveaux tests sont discriminants. Il ne reste que des mineurs, hors du diff ou au-delà de l'exigence de 200 %.

## Comment j'ai travaillé

- **Worktree :** détaché sur a597217d, dans le scratchpad. J'ai lancé `flutter pub get` et `dart run slang`.
- **Nettoyage :** worktree retiré à la fin, branche intacte, rien de poussé.
- **Périmètre :** 2 commits.
  - Fichiers Dart : `barre_commandes_observation.dart`, `panneau_observation_tuteur.dart` et 3 tests.
  - 16 PNG et 2 copies `.dart.txt` du script de capture.
  - Rien dans `supabase/`, `.github/`, `pubspec`, le thème ou le rendu du Coran.
- **Commits :** les deux lignes de fin sont exactes.

## Contrôles

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_revue` | 1627 violations, comme la base |
| `verifier_jetons` | 39 violations, comme la base |
| `dart format` sur les 5 fichiers Dart | 0 changement |
| `flutter test --concurrency=2 test/teaching_core` | +1063 réussis, ~69 sautés, 0 échec |
| Autres tests qui touchent la salle d'observation (accessibilité tuteur, `classe_tuteur`, `salle_test`, observation de groupe admin) | +106 réussis, 0 échec |
| Captures régénérées avec CAPTURE_DIR | 16 sur 16 identiques octet pour octet aux PNG commités (`cmp`) |

## OBS-COUPE-1

**Majeurs 1 et 2 : levés.** J'ai repris le harnais des relecteurs : gouttière de 16 px, `motsCoupes`. Je l'ai élargi en balayage jetable :
- largeurs de 300 à 480 px tous les 4 px, plus 320, 340, 360, 375, 390, 412, 414 et 428 ;
- 13 échelles : 0,85 ; 1 ; 1,05 ; 1,1 ; 1,15 ; 1,2 ; 1,25 ; 1,29 ; 1,3 ; 1,31 ; 1,5 ; 2 ; 3 ;
- LTR et RTL, son reçu et interrompu, agrandi vrai et faux.

Résultats :
- **Tête :** 5616 cas, 0 mot coupé. La maquette M4 (une seule rangée) tient partout à partir de 390 px à x1 ou moins.
- **Ancien fichier lib remis :** 410 fautes au balayage, et 16 échecs au test du lot. Ce sont les cas relevés par les relecteurs.

**Mutations :**
- Largeur de Quitter remplacée par 0 : des dizaines d'échecs au test du lot, donc détectée.
- Garde d'arrondi retirée : le test du lot passe, mon balayage trouve 2 fautes. C'est la réserve 3.

**Mineurs 3 et 4 : levés.**
- La matrice compte 144 cas.
- Les captures à 320@2, 360@3 et 375@3 existent dans les trois états. Je les ai ouvertes : aucun mot coupé, « Réduire » entier, deux rangées à 320 px.

**Mineur 5 :**
- La carte du support n'est plus rognée. Une mutation qui remet `SizedBox` est détectée par le test.
- Le bas de barre à 200 % reste rogné au premier affichage. J'ai vérifié par une sonde que le défilement le rattrape : bas de barre à 818 avant, 794 après, pour une limite à 810. Le rédacteur l'impute à `PageShell` et l'a consigné. C'est la réserve 1.

## TUILE-TUTEUR-1

**Majeur 1 : levé.** La capture `o2_sans_image_texte200_320x844@2` montre maintenant les deux vignettes : cercles A et M, noms dessous, ondes dans le coin de Mariam. Le test vérifie que le cercle est dans la fenêtre et que le nœud n'est pas `isHidden`.

**Majeur 2 : levé.** J'ai monté l'écran entier et cherché les mots coupés sur tous les `Scaffold`, dans 64 combinaisons :
- 320@2 x1 et x2, 390@3 x1, 390@2 x2, 360@3 x1,3, 1440 x1 et x2, 768 x2 ;
- clair et sombre, LTR et RTL, avec et sans image.

Résultat : 0 mot coupé. L'en-tête passe à la ligne entre les mots, comme on le voit sur la capture `son_interrompu` 320@2.

**Mineurs : levés, chacun avec sa contre-épreuve détectée.**
- **Sémantique :** un seul nœud « Mariam, Caméra fermée ». Avec `excludeSemantics: false`, le test échoue. Le cadre n'a aucun enfant interactif, donc exclure la sémantique ne masque rien.
- **Ondes :** avec `coin: null`, les tests des ondes échouent en LTR et en RTL.
- **Panneau remis à la base :** plusieurs échecs.
- **Droite-à-gauche :** cas RTL et capture RTL présents.

## Captures ouvertes

- **TUILE-TUTEUR-1b :**
  - 320@2 à 200 % ;
  - 390 RTL ;
  - 390 sombre, conforme.
- **OBS-COUPE-1b :**
  - `son_interrompu` 320@2 ;
  - `agrandi` 320@2 ;
  - `salle` 375@3 : une rangée, « Son / reçu » passe à la ligne entre les mots ;
  - `texte200` 390@2 : barre sur deux rangées sans mot coupé, bas rogné (réserve 1).

## Réserves (mineures)

1. **Bas de barre sous la zone sûre à 200 % sur mobile.** Il faut défiler pour voir la barre entière. La cause est dans `PageShell._Bascule`, hors du lot, et demande une étape dédiée.
2. **Tablette de 600 à 700 px à 300 % :** « Quitter » est coupé dans le mode large. Ce chemin est hors du diff, et l'exigence est de 200 %.
3. **Garde d'arrondi non couverte par le test du lot :** ajouter un cas limite, ou un balayage dense, pour la verrouiller.
4. **Observation :** la capture RTL affiche des textes français en sens arabe, d'où des signes et des nombres réordonnés. Il faudra une vraie preuve en arabe plus tard.

**Verdict : ACCEPTEE_AVEC_RESERVES.**