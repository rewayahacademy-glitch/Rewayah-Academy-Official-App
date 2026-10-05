# Revue adverse de BLOC-BIB-1b : verdict ACCEPTÉE

J'ai relu en lecture seule le worktree jetable, détaché sur `origin/corrections/c2-bloc-bib-b` @ `db6885ef`. La base est `29a4fc83`, les commits relus sont `ae4dbe4e` et `db6885ef`. Le worktree est retiré et rien n'a été poussé.

Statut du lot : présent dans le code et testé localement. Il n'est ni testé sur staging, ni déployé.

## Périmètre du diff

- `lib/features/tc_espace_groupe/emplacements_groupe.dart` : seul le commentaire change, sur 8 lignes, sans aucun changement de code.
- `test/features/tc_espace_groupe/bloc_bibliotheque_titre_test.dart` : 4 cas ajoutés.
- `docs/current/captures/BLOC-BIB-1b/` : 33 PNG et le script archivé en `.txt`. Il ne reste aucun fichier de capture dans `test/capture`.
- Rien n'est touché dans les zones interdites (supabase, .github, pubspec, thème, rendu du Coran).
- Les deux commits finissent exactement par les lignes d'attribution demandées.

## Réserve 1 : un test garde Ma classe de l'élève adulte

**Remplie.** Les 4 nouveaux cas couvrent 320 et 390 px, texte ×2, en LTR et en RTL. Chacun vérifie quatre points :
- la taille rendue de « Ressources de la classe » est égale à celle de « Participants » ;
- le titre tient sur plus d'une ligne ;
- `verifierAucunMotCoupe` passe ;
- le bouton « Voir tout » est sous le titre et part du bord de début du bloc.

J'ai refait moi-même trois mutations :

| Mutation | Résultat |
| :--- | :--- |
| Ancien `emplacements_groupe.dart` (b41b8d62~1) | 12 cas sur 12 en échec. Ma classe adulte mesure 25,6 et 31,8 px au lieu de 44. |
| « Voir tout » aligné `centerEnd` | 4 cas Ma classe sur 4 en échec |
| « Voir tout » placé au-dessus du titre | 4 cas Ma classe sur 4 en échec |

Une fois le code restauré, le fichier passe 12 cas sur 12.

## Réserve 2 : les captures

**Remplie.** J'ai ouvert les planches maclasse 320×2 clair, maclasse 390×2 sombre RTL, maclasse 1440×2, maclasse 390×2 sombre RTL en Interface guidée, espaceclasse_ens 320×2 guidée, adulte 390×2 sombre RTL et espacegroupe 1440×2 guidée, ainsi que la capture entière maclasse 320×2 sombre.

- Après le lot, le titre a la taille des autres sections et passe à la ligne entre les mots, sans mot coupé ni débordement.
- « Voir tout » est sous le titre, au bord de début (à droite en RTL).
- Le sombre est lisible.
- J'ai comparé au pixel les deux moitiés des 8 planches 1440 avec PIL : aucune différence. Cela confirme la déclaration du rédacteur.
- Les vues demandées sont toutes là pour les 4 écrans : 1440×2, 390×2 sombre RTL et Interface guidée (320 / 390 sombre RTL / 1440).

## Réserve 3 : le commentaire au-dessus de `if (empile)`

**Remplie.** Le commentaire décrit maintenant les deux dispositions, conformément au code : en texte agrandi, le lien est dessous au bord de début ; sinon, il est dans une rangée au bord de fin.

## Contrôles

- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1573 violations, autant que sur la base 29a4fc83.
- `verifier_jetons` : 39 lignes signalées, autant que sur la base.
- `dart format` : aucun changement.
- Tests lancés avec `--concurrency=2` sur les appelants de `BlocBibliotheque` et les dossiers touchés :
  - `tc_espace_groupe`, `accueil_adulte`, `classe_eleve`, `fiche_groupe_test`, `ma_classe_adulte`, `teaching_core/a` et `demo` : +388, aucun échec réel. Le seul « -1 » vient d'un chemin inexistant que j'avais passé moi-même (`test/features/accueil_eleve`).
  - Relance avec les bons fichiers (`accueil_eleve_test.dart`, `accueil_ma_prod_test.dart`, `test/accessibilite`) : +443, tous réussis.

## Observations, sans effet sur le verdict

1. Il n'y a pas de capture de Ma classe à 1440 ×2 en RTL. La demande ne l'exigeait pas explicitement.
2. Défaut préexistant hors périmètre : sur l'Espace Classe enseignant, en Interface guidée à 320 ×2, le mot « Chapit / re 1 » est coupé. Cela contredit la règle « aucun mot coupé » et appelle une étape dédiée. Le rédacteur l'a déclaré.
3. Défauts préexistants : texte français inversé en RTL, et « 8,1 Mo » sans espace insécable. Le rédacteur les a déclarés.

Je n'ai trouvé aucun défaut majeur ni mineur dans le périmètre du lot. Les trois réserves de BLOC-BIB-1-R sont levées preuves à l'appui.
