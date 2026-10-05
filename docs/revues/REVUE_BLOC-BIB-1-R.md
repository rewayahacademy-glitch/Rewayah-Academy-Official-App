# Revue adverse BLOC-BIB-1 (branche `corrections/c2-bloc-bib`, `e012907f`)

**Verdict : ACCEPTÉE AVEC RÉSERVES (mineures, la fusion n'est pas bloquée).**

J'ai travaillé en lecture seule dans un worktree détaché jetable, retiré à la fin. Je n'ai rien poussé.

## Ce qui était demandé
D'après la revue BENTO-3b-R (C5 et m2) :
- le titre « Ressources de la classe » doit avoir le même style que les autres titres de section ;
- il doit passer à la ligne au lieu d'être réduit, sans mot coupé ;
- « Voir tout » doit être placé comme dans les autres en-têtes ;
- des tests à 320 et 390 ×2 ;
- des captures avant/après sur l'accueil adulte et l'Espace Groupe ;
- `grille_bento.dart` ne doit pas être touché.

## Ce que fait la correction
Le diff de `lib/` ne touche qu'un fichier, `emplacements_groupe.dart` : le `FittedBox(scaleDown)` + `IntrinsicWidth` est remplacé par `entete` seul. Le rendu devient le même que celui d'`EnteteVoirTout`. Les autres points vérifiés :
- `grille_bento.dart`, `pubspec.yaml`, `supabase/`, `.github/`, le thème et `tool/` ne sont pas modifiés ;
- aucun libellé n'est ajouté ;
- les deux commits se terminent par les deux lignes exigées, et aucun identifiant de modèle n'apparaît ailleurs.

## Preuves

### Mutations
Toutes sont lancées sur `bloc_bibliotheque_titre_test.dart`, qui contient 8 cas.

| Mutation | Résultat |
|---|---|
| Ancien `emplacements_groupe.dart` (HEAD~2) | **0 passent, 8 échouent** (tuée) |
| `FittedBox` remis autour du titre seul | 8 échecs (tuée) |
| « Voir tout » au bord de fin (`centerEnd`) | 4 passent, 4 échouent : les cas LTR de l'accueil (tuée) |
| « Voir tout » placé avant le titre | échecs (tuée) |
| Code de la branche | 8 sur 8 passent |

### Mesures complémentaires
Je les ai faites avec un test temporaire, supprimé ensuite, sur 4 écrans, 4 largeurs (320, 390, 768, 1440 ×2), en LTR et en RTL, en mode standard et en Interface guidée.

**Mode standard.** Le titre de la bibliothèque a partout la même taille que le titre de section voisin :
- Accueil adulte : 44 px, comme « Dernières séances ».
- Ma classe adulte : 44 px, comme « Participants ».
- Espace Classe enseignant : comme « Progression de la Classe ».

Le titre tient sur 2 lignes à 320 et 390, sur 1 ligne à 768 et 1440. « Voir tout » est à la même place que celui des « Dernières séances » : 20 px sous le titre, même bord de début, à 0,5 px près, en LTR comme en RTL. `verifierAucunMotCoupe` passe sur les quatre écrans.

**Interface guidée.** À 390, 768 et 1440 ×2, toutes les tailles sont égales (56 px). À 320×2, chaque titre se resserre sur son mot le plus long : c'est le comportement prévu de `SectionHeader`. Aucun mot n'est coupé.

### Captures
J'ai ouvert les 12 captures avant/après commitées. J'en ai régénéré 32 autres hors dépôt (avant et après) : 4 écrans (accueil, Espace Groupe, Ma classe, Espace Classe enseignant) × standard et guidé × 320×2 clair, 390×2 sombre RTL, 1440×2 clair et 1440×2 sombre RTL.

- **320×2 et 390×2** : « Ressources de la classe » passe de la petite taille sur une ligne à la grande taille sur deux lignes. Les mots restent entiers. « Voir tout » est dessous, aligné comme celui des « Dernières séances ». Le sombre est lisible, le RTL est aligné à droite.
- **1440×2** : en LTR, avant et après sont identiques au pixel. En RTL, seul un léger décalage du titre apparaît. Le point m2 (« Voir tout » sur sa propre ligne) reste en l'état, ce qui suit la consigne « placé comme les autres en-têtes » : celui des « Dernières séances » est au même endroit.
- **Espace Groupe de l'élève** : le titre « Bibliothèque » tient en un mot, donc avant et après sont identiques en LTR, comme le rédacteur l'a déclaré.

### Outils et suites de tests
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_revue` | 1606, égal à la base HEAD~2 |
| `verifier_jetons` | 39, égal à la base |
| `dart format` sur les 2 fichiers | 0 changement |
| tc_espace_groupe, accueil_adulte, ma_classe_adulte, demo, accessibilite, widgets | +794, 0 échec |
| teaching_core, classe_enseignant, router | +1399, 0 échec |
| fiche_groupe_test, accueil_famille_test, enseignant_classes, enseignant_recette | +120, 0 échec |

Toutes les suites ont tourné avec `--concurrency=2`.

## Réserves (aucune ne bloque la fusion)
1. **Ma classe adulte n'est pas couverte.** Cet écran utilise aussi `BlocBibliotheque` avec le titre « Ressources de la classe ». Il est corrigé (vérifié), mais aucun test ni aucune capture commitée ne le couvre. Il faudrait l'ajouter au test.
2. **Captures manquantes dans le dépôt.** Le dossier commité n'a pas les vues à 1440×2, à 390×2 en sombre RTL ni en Interface guidée. Je les ai vues moi-même et elles sont conformes.
3. **Information.** En Interface guidée à 320×2, les tailles des titres diffèrent de quelques pixels parce que `SectionHeader` resserre un mot trop large. C'est le comportement voulu du composant partagé, non modifié ici.
4. **Information.** Le commentaire des lignes 154 à 157 de `emplacements_groupe.dart`, antérieur à ce lot, ne décrit plus le mode empilé.

La demande est remplie : je n'ai trouvé aucun défaut majeur prouvé. Rien n'est déployé.
