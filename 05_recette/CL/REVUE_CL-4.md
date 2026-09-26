# REVUE_CL-4 : revue croisée adversariale de l'entrée en classe (CL-4.R)

Rédigée le 26/09/2026 par une session qui n'a rien construit dans le lot.

- **Code** : `C:\RA\classe`, branche `ui/classe-v1`.
- **Diff du lot** : `git diff 56541ce..eb97496`, soit 9 commits, de CL-4.2 à CL-4.7, et 32 fichiers dans le diff net.
- **Références** :
  - `10_classe/V/entree/00_MAQUETTES_ENTREE.md` et `01_HARMONISATION.md` ;
  - `10_classe/UX_REVIEW_CL-4.md` ;
  - `ressources/memoire/CLASSE-ENTREE-2026-09-26.md`, règles R1 à R21 ;
  - `DESIGN-GOV-2026-09-26` §4 bis ;
  - consignes K-40 et K-41.

Rien n'a été corrigé par cette revue.

## Verrou

| Commande | Résultat |
|---|---|
| `flutter analyze` | **No issues found**, code 0 |
| `flutter test test/features test/router test/core test/teaching_core test/video` | **All tests passed!** +2658, ~781 ignorés (dont les groupes de captures `sautSansCapture`), 441 s, code 0 |

## Bilan

**2 majeurs, 8 mineurs, 10 notes.** Recommandation : l'étape ne passe pas à « vérifié » avant la correction des deux majeurs. Les deux corrections sont courtes.

## Majeurs

### M1. « Tester la caméra » est un faux contrôle en production (R10, heuristique n° 1 de Nielsen)

Ce que le code fait :
- `lib/features/salle/preparation_enseignant.dart:264-266` : le bouton « Tester la caméra » s'affiche dès que `resultat.cameraDisponible` est vrai. Son `onPress` est toujours `_testerCamera`.
- `preparation_enseignant.dart:141-144` : `_testerCamera` appelle `widget.onTesterCamera?.call()` puis écrit `_testCameraFait = true`, **que le rappel existe ou non**.
- `lib/features/salle/salle_page.dart:1689-1703` : dans le vrai chemin (`_PreparationBranchee`), `PreparationEnseignant` est construit **sans `onTesterCamera`**.

Conséquence : en production, l'enseignant appuie sur « Tester la caméra ». Aucun test n'a lieu, puis l'écran annonce en région live « Test local terminé. La caméra reste coupée à l'entrée. » (`assets/i18n/fr.i18n.json:148`).

C'est exactement le « faux contrôle inerte » que R10 interdit, avec en plus un message faux. Le test `test/features/classe_enseignant/preparation_enseignant_test.dart:175` valide ce comportement au lieu de le détecter.

**Attendu** : pas de bouton tant que `onTesterCamera` est nul (même règle que `onOuvrirReglages` et `onModifierPeripheriques`). Le message « Test terminé » ne doit s'afficher qu'après un vrai test.

### M2. Genre en dur dans une chaîne visible par l'élève (K-41)

- Chaîne : `assets/i18n/fr.i18n.json:196`, clé `salle.preparation.eleve.microInaccessibleDetail` : « **Le professeur** ne pourra pas vous entendre tant que l'accès au micro reste bloqué. »
- Affichage : chez l'élève, en PRE-ERR-01 (`lib/features/salle/preparation_eleve.dart:349`).
- La Classe peut être tenue par une Sayyida. K-41 : « genre jamais en dur ». Le reste du lot passe bien par `LibellesGroupe.enseignantNomme`, par exemple dans `carte_session.dart` pour « Chez Sayyida {prénom} ».

**Attendu** : une tournure sans genre (par exemple « Personne ne pourra vous entendre… » ou « La Classe ne pourra pas vous entendre… »), ou bien le titre et le nom réels de l'enseignant. **Aucune clé nouvelle dans `ar.i18n.json`** (K-41).

## Mineurs

| N° | Constat | Preuve | Attendu |
|---|---|---|---|
| m1 | La région live de l'emplacement d'entrée est posée sur un `SizedBox.shrink()` de taille nulle. Un nœud de sémantique à rectangle vide peut être jugé invisible et ne rien annoncer, surtout sur le web. Les tests de widget ne prouvent pas l'annonce réelle. La revue UX n° 16 d demandait un contrôle au vrai lecteur d'écran web en CL-4.7. | `lib/features/tc_espace_groupe/carte_session.dart:388-392` | Contrôle TalkBack et NVDA web consigné ; sinon, poser `liveRegion` sur la ligne d'état visible (sans le décompte). |
| m2 | Préparation enseignant : « Entrer dans la classe » est **grisé pendant la vérification** (`resultat == null` ou `reseau == null`), sans raison écrite. La revue UX n° 12 d n'autorise le bouton désactivé qu'avec une raison écrite juste au-dessus (micro manquant). | `lib/features/salle/preparation_enseignant.dart:250-254, 362, 369` | Pendant la vérification : aucun bouton, ou une raison « Vérification en cours » au-dessus. |
| m3 | Fenêtre ouverte sans `sessionId` matérialisé. Côté enseignant, `onRejoindre` vaut `null` et le bouton « Préparer l'entrée » s'affiche **grisé** (R4 : jamais de bouton grisé). Côté élève, le bouton est actif mais `_preparer` ne fait rien, en silence. | `lib/features/fiche_groupe/fiche_groupe_page.dart:358-360` ; `lib/features/tc_mes_groupes/routes_tc_a.dart:62-66` ; `carte_session.dart:332-343` | Dans ce cas, une ligne d'état (« indisponible ») plutôt qu'un bouton. |
| m4 | Interface guidée : le lien dit « Retour à l'accueil », mais il mène à l'Espace Classe (`CheminsTcA.espaceGroupe`) quand `groupeId` est connu. Le libellé ment sur la destination. | `lib/features/salle/preparation_eleve.dart:188-190` ; `lib/features/salle/salle_page.dart:391-394` | En guidé, aller à l'accueil du rôle, ou bien garder le libellé « Retour à la Classe ». |
| m5 | « Autoriser le micro » ouvre la feuille CL-7, mais `onOuvrirReglages` n'est jamais branché. La feuille n'offre alors que « Continuer sans micro » : le bouton principal promet une action qui n'existe pas. | `lib/features/salle/salle_page.dart:1728-1742` (aucun `onOuvrirReglages`) ; `preparation_eleve.dart:119-138, 277-284` | Tant qu'aucune action d'autorisation n'existe (BR-1), le libellé doit dire ce qui se passe réellement, par exemple « Comment autoriser le micro ». Sinon, noter l'écart dans `CL-4-BR.md`. |
| m6 | R17 est tronqué **à l'écran** (`.take(3)`, deux fois), alors que `bloc_avant_prochain_cours.dart` pose que le plafond est tenu en amont et qu'« un widget qui tronquerait masquerait un défaut de contrat ». De plus, `?? const []` confond « non branché » (`null`) et « rien à préparer ». | `lib/features/tc_espace_groupe/espace_groupe_page.dart:190-197` ; `lib/features/tc_espace_groupe/emplacements_groupe.dart:87` ; `lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart:20-36` | Plafond dans le port (ou `assert`), et distinction entre `null` et liste vide gardée jusqu'à l'écran. |
| m7 | Tests existants affaiblis dans `test/features/fiche_groupe_test.dart`. Les assertions supprimées portent sur le type de groupe (`t.admin.groupes.typeEnfant` et `typeAdulte`), le texte `complet` et le nombre de places libres. Le type Enfant ou Adulte ne s'affiche plus du tout sur la fiche enseignant. « Complet » n'est plus porté que par le **ton** de la pastille, le texte restant « n élèves sur n places ». Aucune ligne des rectifications ne cite la suppression du type de groupe. | Diff `56541ce..eb97496 -- test/features/fiche_groupe_test.dart` (assertions `-expect(find.text(t.admin.groupes.typeEnfant)…)`, `-…typeAdulte…`, `-…ficheGroupe.complet…`) | Soit la décision est tracée (CL-4.4b, maquette P3), soit le type de groupe revient, avec son test. |
| m8 | Tests manquants sur deux changements de chemin. (a) `routes_tc_a.dart:48-51` : l'élève va maintenant vers `/salle` avec une préparation, et non plus vers `/tc/classe`, mais `test/teaching_core/a/routes_tc_a_test.dart` ne touche pas ce branchement. (b) Les rôles autres qu'élève et tuteur (admin, contrôleur) qui arriveraient avec `preparation: true` tombent sur la préparation **enseignant** (`salle_page.dart:398`, branche par défaut). | `lib/features/tc_mes_groupes/routes_tc_a.dart:48-51` ; `lib/features/salle/salle_page.dart:380-414` | Un test de route pour l'élève, et une branche explicite `AppRole.teacher` pour la préparation enseignant. |

## Notes

1. **Rôle effectif.**
   - Élève : `GroupHomeVM.pourRole` n'ouvre le roster qu'à l'enseignant et à l'admin (`lib/core/tc_groupe/group_home_vm.dart:129-132`, `assert`). La pastille « Photo à fournir » est coupée côté famille (`espace_groupe_page.dart`, `repliInitiales: espace.estCoteFamille`). « Avant le prochain cours » lit le groupe (`studentId: null`), et non les autres familles.
   - Enseignant, R15 : `ProjectionEleve` ne porte que `pageReprise` et `dernierPoint` (`lib/features/fiche_groupe/preparation_seance.dart:40-50`). La ligne élève affiche prénom, identifiant, niveau, reprise et dernier point (`fiche_groupe_page.dart:581-610`). Rien de ce que R15 interdit.
   - Tuteur : aucune préparation, que ce soit à l'`initState` ou au `build` (`salle_page.dart:157-164, 373-378`). Son emplacement reste une ligne (`carte_session.dart:163`).
   - Guidé : une seule action principale par phase ; « Continuer sans micro » passe en tertiaire (`preparation_eleve.dart:369-421, 403`).
2. **R4.**
   - Avant l'ouverture, l'état est `FormeEntree.ligne` (`emplacement_entree.dart:119-129`), rendu par `_LigneEtat` en `MergeSemantics` sans `Focus` (`carte_session.dart:401-435`), avec la hauteur 52 réservée.
   - Le décompte n'entre pas dans la région live (`annonceDepuis`, `emplacement_entree.dart:225-226`). La carte ne porte aucune pastille de décompte : les seules `StatusPill` sont la capacité et la photo.
   - Réserve : voir m3.
3. **R5 à R7.**
   - `EmplacementEntree` est pur : aucun `DateTime.now()`. Le temps vient de `SessionClockVM.restant`, calculé sur `calculeeAUtc`.
   - `DateTime.now()` n'apparaît qu'aux frontières d'émission du billet : `routes_tc_a.dart:71`, `fiche_groupe_page.dart:375`, et le code existant de `salle_page.dart`. `BilletSalle.duree` (20 min) est antérieur au lot.
   - `_positif` borne les négatifs (`emplacement_entree.dart:267-268`). La prolongation affiche « Temps prévu écoulé » (`:165-176`).
   - Les durées de `classe_demo.dart:235-242` sont des horodatages de démonstration, pas une logique.
4. **R8 et R11.**
   - L'aperçu enseignant est toujours « Caméra coupée » (`preparation_enseignant.dart:379-420`). L'élève lit « Vous entrerez avec le micro coupé ». Aucune ouverture de média avant « Entrer dans la classe » : `_entrer()` n'est pas appelé tant que la préparation est à l'écran (`salle_page.dart:161-164`).
   - Aucun terme technique brut dans les chaînes ajoutées (ICE, SDP, TURN, Mbps : aucune occurrence).
5. **Contrat C.** Aucun fork. Les nouveaux écrans utilisent `ActionPrincipale`, `AppCard`, `GroupeReglages`, `LigneRubrique`, `Skeleton`, `AppBottomSheet.ouvrir` et `LienFleche`. Le diff ne contient aucun `BoxDecoration`, `BorderRadius`, bouton Material brut, shimmer, spinner ni couleur littérale.
6. **Contrat B.** Le CTA est trailing et à sa largeur naturelle sur bureau (`carte_session.dart:342, 351` ; `preparation_eleve.dart:256-259` ; `preparation_enseignant.dart:356-370`). Il est en pleine largeur sur mobile. Il y a un seul CTA dominant par état.
7. **Démo.**
   - `routesDemoClasse` rend une liste vide en production (`lib/features/demo/demo_classe_page.dart:48-49`, `environnementAutoriseDemo`). La porte de `redirection.dart:50-55` n'est ouverte que sous la même condition.
   - C'est couvert par `test/features/demo/demo_classe_page_test.dart:20-45`.
8. **Zones interdites, diff net.** Aucun fichier touché sous `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, `tc_mushaf`, `lib/core/theme/` ni dans les couleurs. Les 55 fichiers reformatés par erreur ont été rétablis par `ca841ef` : le diff net compte 32 fichiers.
9. **i18n et K-41.**
   - `git diff 1691284 eb97496 -- assets/i18n/ar.i18n.json` est vide : aucune clé arabe ajoutée après CL-4.4b. Les 45 lignes ajoutées en CL-4.5 ont été retirées par `a89c333`.
   - Aucune chaîne visible en dur dans les widgets de production du lot. Les littéraux restants (« Classe An-Nour », « Page 24 », « Dans 8 min »…) sont des données de démonstration de `classe_demo.dart` et `demo_classe_page.dart:374-375, 508-510`, qui ne sont pas compilées en route de production.
10. **Régressions.**
    - `/tc/classe` ne change pas pour l'enseignant, l'admin et le tuteur (`routes_tc_a.dart:48-51`). L'élève passe désormais par `/salle` et sa préparation, comme le prévoit `01_HARMONISATION.md` §1 (« surface focalisée devant la salle canonique `/salle` »).
    - `/salle` sans `preparation` garde l'entrée directe (`salle_page.dart:157-164`). `_sansMicro` n'est posé que par l'élève (`:385-391`).
    - Remarque de conception : l'état `_enPreparation` est modifié dans `build` pour le tuteur (`salle_page.dart:373-378`), hors `setState`. Cela fonctionne, mais c'est fragile.
