# Revue adverse DASH-ELV-ERR-b : `origin/corrections/c2-elv-err-b` (`4737840b`)

Je n'ai rien écrit sur cette branche et je l'ai relue en lecture seule. J'ai travaillé dans deux worktrees jetables :
- le premier, détaché sur `4737840b` (la branche) ;
- le second, détaché sur `origin/corrections/revue-directeur-2026-10` (`3df81930`, la base).

Les deux ont été retirés à la fin. Je n'ai rien commité ni poussé.

## Verdict

**ACCEPTÉE AVEC RÉSERVES.** Les quatre réserves m1 à m4 et le point i1 de la revue DASH-ELV-ERR-R sont traités. Chaque correction est prouvée par un test qui échoue quand on l'annule. Il ne reste aucun défaut bloquant ni majeur.

Les deux réserves restantes sont mineures :
- les libellés doivent être validés par le directeur (DASH-LIB) ;
- il n'y a pas de capture RTL. Le sens RTL est couvert par un test.

## Périmètre

- Deux commits par rapport à la base : `74a41f7d` et `4737840b`.
- 16 fichiers modifiés.

Fichiers de code :
- `lib/core/planning/service_planning.dart` : `retry: (int retryCount, Object error) => null` sur `seancesProvider` ;
- `lib/features/accueil_eleve/accueil_eleve_page.dart` :
  - `echec = hasError && !hasValue` est évalué avant le squelette ;
  - le squelette de blocs est désactivé si `echec` ;
  - la nature passe à `horsLigne` hors ligne, avec un titre tutoyé ;
  - `actionEnCours: seances.isLoading` ;
- `assets/i18n/fr.i18n.json` et les fichiers générés par slang ;
- `tool/libelles_sources.json` ;
- `test/features/accueil_eleve_test.dart` : +4 tests et 2 tests paramétrés (LTR et RTL) ;
- 8 PNG et leur script.

Fichiers interdits : aucun n'est touché (supabase/, .github/, vercel.json, pubspec, thème, rendu du Coran). Les commits sont en français et finissent par les deux lignes exactes. Aucun autre identifiant de modèle n'apparaît.

## Appelants de `seancesProvider` (régressions)

`grep` sur `lib/` : le seul lecteur est `accueil_eleve_page.dart`. La suppression des 10 relances Riverpod ne touche donc aucun autre écran. `test/features/profil_enseignant_test.dart` ne le cite qu'en commentaire.

Les autres appelants d'`EtatSysteme` ne sont pas modifiés : le composant n'a pas changé, et `titre` comme `actionEnCours` existaient déjà. Le bouton « en cours » réutilise le paramètre `enCours`, déjà employé par 7 appelants. Ce n'est pas un bouton grisé.

## Commandes et mesures

| Contrôle | Résultat |
|---|---|
| `dart run slang` | Aucun écart avec les fichiers commités (`git status` vide) |
| `dart analyze --fatal-infos` | No issues found |
| `dart format --set-exit-if-changed` (3 fichiers .dart) | 0 changé |
| `verifier_revue --detail` | 1606 sur la branche et 1606 sur la base, sorties **identiques ligne à ligne** (`diff` vide). La clé `erreurCoursHorsLigneTitre` n'est pas signalée |
| `verifier_jetons` | Sorties branche et base **identiques** (`diff` vide) |
| `libelles_sources.json` | JSON valide, les deux clés sont présentes |
| `flutter test --concurrency=2 test/features/accueil_eleve_test.dart` | **54/0** |
| `flutter test --concurrency=2 test/core test/router test/widgets` | **1237 réussis, 0 échec** |
| `flutter test --concurrency=2 test/features` | **2752 réussis, 2068 sautés, 0 échec**, comme annoncé |

## Contre-épreuve sur l'ancien code

J'ai remis la page et `service_planning.dart` de la base sous les nouveaux tests. Trois groupes de tests échouent :
- « une panne reseau (Exception) se dit sans attente… » ;
- « hors ligne, l echec porte la nature hors ligne » ;
- « … aucun mot coupe ». Avec une Exception, l'ancien code reste en squelette.

Comme annoncé, « valeur puis échec » (m3) passe sur l'ancien code : le comportement était déjà en place.

## Mutations (8 sur 8 tuées)

| Mutation | Test qui échoue |
|---|---|
| M1 : `retry` retiré | panne réseau (Exception) |
| M2 : squelette remis avant l'erreur | panne réseau (relecture) |
| M3 : `enChargement` sans `!echec` | panne réseau (relecture) |
| M4 : nature toujours `echecServeur` | hors ligne |
| M5 : titre hors ligne à `null` | hors ligne |
| M6 : `echec = hasError` seul | valeur puis échec (m3) |
| M7 : `actionEnCours: false` | panne réseau |
| M8 : retry à 200 ms, 3 fois | panne réseau (`lectures == 1` après 60 s) |

Le fichier a été restauré après chaque mutation, et `git status` est resté propre.

## Pourquoi les tests sont justes

Le test m1 lève une vraie `Exception`, pas une `StateError`. Il n'appelle jamais `pumpAndSettle` avant l'affichage de l'erreur. Il vérifie que :
- une seule lecture a lieu, et toujours une seule après `pump(60 s)` ;
- l'erreur s'affiche immédiatement, sans squelette ;
- pendant la relecture, il n'y a ni squelette ni « aucun cours », le message et le Coran restent et `actionEnCours` est vrai.

L'override `overrideWith` garde bien le `retry` du fournisseur : la mutation M1 le prouve.

## Captures (m4)

J'ai régénéré les 8 captures depuis `dash_elv_err_b_capture_test.dart.txt` avec `CAPTURE_DIR` : elles sont **identiques octet pour octet** aux PNG commités.

J'en ai ouvert six moi-même : `elv_err_1440_sombre`, `elv_err_320x2_clair`, `elv_err_320x2_sombre`, `elv_err_390_sombre`, `elv_err_hors_ligne_320x2_sombre` et `elv_err_hors_ligne_390_clair`. Sur chacune :
- la carte d'erreur avec la nouvelle phrase et le bouton « Réessayer » ;
- puis la carte « Le Coran / À lire quand tu veux » ;
- aucun « Pas de cours aujourd'hui » ;
- aucun mot coupé, aucun débordement à 320 px ×2.

Hors ligne, on voit le bandeau « Pas de réseau… », puis le bloc « Tu es hors ligne » avec l'icône hors ligne et le ton avertissement.

La capture 1440 sombre demandée par m4 est présente.

Interface guidée : elle n'est pas concernée. Le Mode Accessibilité n'est pas touché (i5, hors périmètre).

## Réserves

1. **Mineur, DASH-LIB.** Deux libellés attendent la validation du directeur :
   - `eleve.accueil.erreurCours` : « Tes cours n'ont pas pu être lus : la connexion ou le serveur n'a pas répondu. Réessaie dans un instant. » ;
   - `eleve.accueil.erreurCoursHorsLigneTitre` : « Tu es hors ligne ». Ce titre est un ajout de l'agent, non demandé par la revue mais cohérent avec le tutoiement.

   Les deux sont bien déclarés dans `libelles_sources.json`.
2. **Mineur.** Aucune capture RTL. Le sens RTL est prouvé seulement par le test sans mot coupé à 320 px, texte ×2, rtl, qui passe.

## Info (aucune action à cette étape)

- Préexistants, déjà en i2 et i4 de la revue précédente :
  - en 1440, les éléments de la carte Coran sont groupés sur environ 400 px dans une carte large ;
  - la carte d'erreur est bornée à la largeur de lecture ;
  - le titre `echecServeur` commun reste « Impossible de charger ces informations » ;
  - l'arabe retombe sur le français.
- Incident de processus déclaré par le rédacteur : un `pkill` a été lancé sur la machine partagée. À ne pas refaire.

## Pour fusionner

La branche peut être fusionnée dans `corrections/revue-directeur-2026-10` : elle en part directement (`3df81930`). Les deux libellés sont à joindre au lot DASH-LIB.
