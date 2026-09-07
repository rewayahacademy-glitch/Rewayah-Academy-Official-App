# Journal d'exécution - Étape 4

> Ce fichier dit **où en est le code** de l'étape 4, ce que valent les mesures,
> et quels pièges ont déjà coûté du temps.
> `docs/architecture/etape-4-dashboards.md` reste la spécification ; ce journal
> est son compte rendu. Mis à jour à la fin de chaque lot, jamais en bloc.

## État : L9 fait, l'administration voit ce qui bloque et tranche

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | Spécification `etape-4-dashboards.md`, ADR-017, ce journal | x |
| L1 | Migration `0005` et `supabase/tests/scenarios_etape4.sql` | x |
| L2 | Services Dart : règles, planning, affectations, disponibilités | x |
| L3 | Grille de semaine partagée, `TUT-04` | x |
| L4 | `ENS-06` élèves en attente, prise atomique, plafond | x |
| L5 | Prières : réglages, calcul, ajustements, entrées de planning | x |
| L6 | `ENS-02` la journée | x |
| L7 | `ELV-02` et ses six états | x |
| L8 | `TUT-01`, `TUT-05`, demandes des parties | x |
| L9 | `ADM-01`, `ADM-06` | x |
| L10 | Vérifications de fin d'étape et documentation | |

## Point de départ, mesuré le 6 septembre 2026

Avant la première ligne de l'étape 4, sur le dépôt tel que l'étape 3 l'a laissé :

| Contrôle | Résultat |
| :--- | :--- |
| `flutter test` | 156 tests, tous verts |

C'est la ligne de base : toute régression de cette étape se mesure contre elle.

## Mesures du lot L1, sur Postgres 17.11

| Contrôle | Résultat |
| :--- | :--- |
| `0001` à `0005` sur une base nue | appliquées, aucune erreur |
| `scenarios_etape3.sql` après `0005` | 34 contrôles, tous verts. L'étape 3 ne régresse pas |
| `scenarios_etape4.sql` | 36 contrôles, tous verts |
| Prise concurrente du même élève, deux transactions réelles | une seule passe |

Le harnais est le même qu'à l'étape 3 : conteneur `postgres:17-alpine` neuf,
`stub_auth.sql`, les cinq migrations, puis les deux fichiers de scénarios dans
l'ordre de la CI, qui les rejoue tous les deux à chaque pull request.

`0005` a gagné, après ce relevé, le fuseau d'un enseignant et `mon_fuseau()` :
un foyer porte son fuseau depuis l'étape 1, un enseignant n'en portait aucun, et
la grille de `ENS-06` ne pouvait donc pas savoir dans quelle heure locale elle
écrit. La migration a été **corrigée sur place**, comme `0004` à l'étape 3 et
pour la même raison : elle n'a jamais été appliquée nulle part, l'étape D restant
ouverte. Le compte de contrôles passe alors à 37.

## Mesures du lot L2

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 164 tests, tous verts, dont 8 nouveaux sur les modèles |
| `dart run tool/verifier_jetons.dart` | 61 fichiers, aucune violation |

## Les dix-sept scénarios d'acceptation

Voir la section 7 de la spécification. Aucun n'est coché tant qu'il n'est pas
mesuré, règle constante depuis l'étape 1.

| # | Scénario | État | Où c'est vérifié |
| :-- | :--- | :--- | :--- |
| 1 | Tuteur et enseignant écrivent dans la même table de disponibilités | vert | `scenarios_etape4.sql`, S1a à S1d |
| 2 | Un élève ne peut pas avoir deux enseignants actifs | vert | S2a, S2b |
| 3 | Le sixième élève est refusé par la base | vert | S3a, plus S3b sur le plafond surchargé |
| 4 | Deux prises simultanées : une seule passe | vert | Mesuré hors fichier, en deux transactions réelles. Voir plus bas |
| 5 | Un enseignant ne se retire pas un élève sans décision | vert | S5 |
| 6 | Le tuteur change la caméra de son enfant, et rien d'autre | vert | S6a, S6b |
| 7 | Deux séances du même enseignant qui se recoupent sont refusées | vert | S7a, plus S7b sur l'adjacence |
| 8 | Un tuteur ne lit plus les disponibilités des enseignants étrangers à son foyer | vert | S8a, S8b |
| 9 | Élève et enseignant affichent la même minute de prière | vert | `test/priere/horaires_priere_test.dart`, plus les contrôles de lecture en base |
| 10 | Un ajustement d'une minute déplace l'entrée des deux côtés | vert | Même fichier, dans les deux sens, et sans déplacer les quatre autres prières |
| 11 | Les compteurs de `ADM-01` affichent zéro sans disparaître | vert | `test/features/tableau_de_bord_test.dart`, plus la mesure inverse et le cas de la lecture en échec |
| 12 | `ENS-06` ne rend pas « Prendre » au plafond | vert | `test/features/creneaux_test.dart`, plus le contrôle inverse avec un plafond surchargé |
| 13 | `ELV-02` affiche ses six états | vert | `test/features/accueil_eleve_test.dart`, un test par état, plus deux mesures inverses |
| 14 | Démarrage à froid mesuré sur `ELV-02` réel | **non mesurable ici** | L7 a livré l'écran ; aucune cible de mesure sur ce poste. Voir plus bas, « Le démarrage à froid n'a pas pu être mesuré » |
| 15 | Une règle posée pour un élève ne change rien pour les autres | vert | S15a à S15c |
| 16 | Une surcharge close reste lisible, aucune ne se supprime | vert | S16a à S16c |
| 17 | Une demande de chacune des quatre parties atteint `ADM-06` | vert | S17a à S17e, plus les demandes du tuteur mesurées à l'écran en L8 |

### Le scénario 4 se mesure hors du fichier, et c'est volontaire

Un script `psql` s'exécute dans une seule session : il ne peut pas mettre deux
transactions en concurrence, seulement vérifier le mécanisme qui les départage.
Le fichier vérifie donc l'index unique partiel ; la concurrence réelle a été
jouée à part, deux `psql` simultanés prenant le même élève après une seconde
d'attente :

```
Aissatou : 2c391397-089e-45ec-9c24-f048233aa201
Omar     : ERROR: cet eleve vient d'etre pris par un autre enseignant
```

Une seule affectation active en base après coup. Le perdant reçoit une phrase,
pas un code d'erreur : c'est ce que `ENS-06` affichera.

## Mesures du lot L3

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 169 tests, tous verts, dont 5 sur `TUT-04` |
| `dart run tool/verifier_jetons.dart` | 63 fichiers, aucune violation |

La grille est **un seul composant pour les deux écrans**, dans
`lib/features/disponibilites/`, et non un onzième composant partagé : elle sert
`TUT-04` et l'onglet de `ENS-06`, pas le reste de l'application. La liste des
dix composants de l'étape 2 reste donc exacte.

## Mesures du lot L4

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 174 tests, tous verts, dont 5 sur `ENS-06` |
| `dart run tool/verifier_jetons.dart` | 64 fichiers, aucune violation |

Le scénario 12 est vert : au plafond, `ENS-06` ne rend pas le bouton « Prendre »,
il affiche la limite et le chemin pour la lever. Le test le mesure **dans les
deux sens** : le même écran, la même situation, avec la règle de cet enseignant
portée à six, rend le bouton. C'est la démonstration de l'ADR-017 côté écran, et
non plus seulement en base.

## Mesures du lot L5

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 196 tests, tous verts, dont 22 sur les prières et les entrées de journée |
| `dart run tool/verifier_jetons.dart` | 69 fichiers, aucune violation |
| `0001` à `0005` sur une base nue | appliquées, aucune erreur |
| `scenarios_etape3.sql` puis `scenarios_etape4.sql` | 34 puis 37 contrôles, tous verts |

`0005` a gagné, avant ce relevé, `prayer_settings.alert_lead_minutes`. Le
préavis de l'alerte ne pouvait pas rester dans le code : porté par chaque
application, il aurait prévenu l'enseignant dix minutes avant et l'élève cinq,
ce qui rouvre exactement le litige que l'ADR-017 ferme. Il vit donc à côté de
`pause_minutes`, dans la ligne que les trois rôles lisent, et le contrôle SQL
vérifie que le foyer lit bien les mêmes deux valeurs que l'enseignant a posées.
La migration a été corrigée sur place, pour la troisième fois de la même
manière et pour la même raison : elle n'est appliquée nulle part, l'étape D
restant ouverte.

Le calcul lui-même n'est mesuré que côté Dart, et c'est volontaire : la base ne
calcule aucune heure de prière, elle n'en porte que les entrées. C'est
précisément ce qui rend l'invariant I8 vérifiable.

## Mesures du lot L6

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **211 tests**, tous verts, dont 15 nouveaux : 10 sur `ENS-02`, 5 sur le bloc dominant |
| `dart run tool/verifier_jetons.dart` | **70 fichiers**, aucune violation |
| `0001` à `0005` sur une base nue | appliquées, aucune erreur |
| `scenarios_etape3.sql` puis `scenarios_etape4.sql` | 34 puis 37 contrôles, tous verts |

`ENS-02` remplace le dernier `EcranAConstruire` de l'enseignant. Aucune ligne de
`0005` n'a bougé : ce lot est le premier de l'étape qui ne touche pas à la base.

La colonne, les entrées de journée et les horaires de prière viennent tous de
L5. Ce lot n'a écrit qu'un écran, un provider et une fonction de sélection,
`prochainCours`, posée dans `lib/core/planning/journee.dart` et non dans
l'écran : `ELV-02` et `TUT-01` ont besoin du même « quel cours vient ensuite »,
et deux réponses différentes à cette question se verraient tout de suite.

### Ce que L6 ne rend pas, et ce n'est pas un oubli

- **Aucun bouton de lancement.** Le pre-flight est l'étape 5. Une phrase occupe
  sa place, comme le plafond de `ENS-06` en occupe une en L4.
- **Aucun rappel de rapport en retard.** La fiche produit de `ENS-02` en prévoit
  un, mais le cahier de transmission est l'étape 6 : rien ne peut encore être
  en retard.
- **Aucune mention de fuseau**, contrairement à la grille de `ENS-06`. Voir
  plus bas : ce serait la seule ligne fausse de l'écran.

## Mesures du lot L7

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **227 tests**, tous verts, dont 16 nouveaux sur `ELV-02` |
| `dart run tool/verifier_jetons.dart` | **72 fichiers**, aucune violation |
| `0001` à `0005` sur une base nue | appliquées, aucune erreur |
| `scenarios_etape3.sql` puis `scenarios_etape4.sql` | 34 puis 37 contrôles, tous verts |

`ELV-02` remplace le dernier `EcranAConstruire` de l'élève, hors Coran et suivi.
Aucune ligne de `0005` n'a bougé : deuxième lot de l'étape à ne pas toucher la
base, après L6.

Les 16 tests se répartissent en trois groupes : les six états du bloc principal
et leurs deux mesures inverses, les deux blocs et leur seule navigation, les
interruptions de prière dans les deux modes. Quatre tests de plus mesurent la
décision d'état **sans monter d'écran**, comme `deciderRedirection` à l'étape 2 :
la fonction `etatAccueilEleve` est pure et reçoit son instant.

### Le démarrage à froid n'a pas pu être mesuré, et voici sur quoi ça bute

Le scénario 14 attendait `ELV-02` depuis deux étapes : il existe enfin, et la
mesure reste impossible **sur ce poste**. Les trois portes ont été essayées, pas
supposées :

| Cible | Ce qui a été tenté | Résultat |
| :--- | :--- | :--- |
| Windows | `flutter build windows --profile` | Échec après 222 s : `atlstr.h` introuvable, dans `flutter_secure_storage_windows`. Le composant ATL de Visual Studio est absent, piège de poste connu depuis l'étape 2 |
| Android | `flutter devices`, `flutter emulators`, `adb devices` | Aucun appareil branché, aucun AVD. La plateforme du SDK reste mal nommée, `android-37.0` au lieu d'`android-37` |
| Web | `flutter devices` | Chrome et Edge sont disponibles, et ne sont pas « un appareil d'entrée de gamme » |

Le scénario 7 de l'étape 2 dit **« sous 1,5 seconde sur un appareil d'entrée de
gamme »**. Une mesure dans un navigateur de bureau ne mesure ni le même
démarrage, ni la même machine : elle donnerait un chiffre, pas une réponse, et
un chiffre qui coche une case qu'il ne remplit pas coûte plus cher que la case
vide. Il reste donc **non coché**, comme il l'est depuis l'étape 2, mais pour la
première fois la raison n'est plus « aucun écran à charger ».

Ce qu'il faut pour le fermer, au choix, et rien de plus :

- un téléphone Android d'entrée de gamme branché en USB, plus le dossier
  `platforms/android-37.0` du SDK renommé `android-37`, puis
  `flutter run --profile --trace-startup -d <appareil>` et la lecture de
  `build/start_up_info.json` ;
- ou le composant **ATL** ajouté à l'installation de Visual Studio, qui rouvre
  la cible Windows pour une mesure de bureau, laquelle ne remplace pas la
  précédente mais vaut mieux que rien.

C'est une question d'équipement, pas de code : elle est portée dans
`docs/PROGRESS.md`, à la main de l'opérateur.

### Ce que L7 ne rend pas, et ce n'est pas un oubli

- **Aucune barre de navigation.** La fiche produit dit « deux blocs, rien
  d'autre » : un test compte les tuiles et échouerait à la troisième.
- **Aucun son.** Les clés audio sont posées, `assets/audio/fr/` reste vide :
  la clé se pose, le son viendra. Le texte reste affiché à côté du
  haut-parleur, donc l'écran ne dépend pas d'un fichier absent.
- **Aucune semaine à venir ni historique.** Le mode standard les gagne d'après
  la fiche, mais l'un est l'étape 6 et l'autre n'a rien à afficher : les deux
  modes rendent donc les mêmes deux blocs, seul le détail des prières change.

## Mesures du lot L8

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **253 tests**, tous verts, dont 26 nouveaux : 15 sur `TUT-01`, 11 sur `TUT-05` |
| `dart run tool/verifier_jetons.dart` | **75 fichiers**, aucune violation |
| `0001` à `0005` sur une base nue | appliquées, aucune erreur |
| `scenarios_etape3.sql` puis `scenarios_etape4.sql` | 34 puis **39** contrôles, tous verts |

Deux contrôles de plus qu'à L7, et une correction de `0005`. Les deux sont
détaillés plus bas : le premier mesure ce que le foyer lit de ses enfants, le
second un défaut de calcul de semaine qui **existait depuis L1 et n'était pas
visible**.

`TUT-01` et `TUT-05` ferment le parcours 3 du tableau de la section 1 de la
spécification. Il ne reste aucun `EcranAConstruire` chez le tuteur, hors `TUT-06`
qui est l'étape 6.

### `TUT-01` n'avait aucune route, et la racine du tuteur tombait sur `TUT-02`

La spécification annonçait que l'étape 4 n'ajouterait qu'une route, celle de
`ADM-06`. Elle en ajoute une seconde, et ce n'est pas un oubli de cadrage :
**aucun chemin ne menait à `TUT-01`.** `Routes.racinePour(guardian)` rendait
`/tuteur/foyer`, c'est-à-dire l'écran de gestion des appareils. Un parent validé
arrivait donc sur l'administration de son foyer plutôt que sur son suivi, et le
tableau de bord que toutes les specs nomment `TUT-01` n'existait nulle part dans
l'arborescence.

`/tuteur` est donc déclarée, et devient la racine du rôle. `prefixePour` la
désignait déjà en dur sous la forme `'/tuteur'` : les deux lisent maintenant la
même constante.

### Ce que L8 ne rend pas, et ce n'est pas un oubli

- **Aucun motif d'annulation en texte libre.** La fiche de `TUT-01` demande le
  motif d'une séance annulée. Aucune colonne ne le porte : `sessions` n'a que son
  `status`, et la salle qui le remplirait est l'étape 5. Le motif affiché est
  donc ce statut dit en clair, « Séance annulée » ou « annulée peu avant
  l'heure », et rien de plus. Inventer une colonne ici aurait produit une phrase
  que personne n'a écrite.
- **Aucune notification de changement de règle.** Une demande déposée par le
  tuteur atteint la file de `ADM-06`, qui est L9. Tant qu'elle n'existe pas,
  l'écran dit que l'administration tranchera, ce qui est exact, et ne promet pas
  de réponse dans un délai.
- **Aucun aperçu de la photo avant envoi.** La photo choisie part telle quelle,
  avec son refus de taille avant l'envoi. Un recadrage est un écran à lui seul.

## Mesures du lot L9

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | **277 tests**, tous verts, dont 24 nouveaux : 9 sur `ADM-01`, 13 sur `ADM-06`, 2 sur le tri du feed de `ENS-06` |
| `dart run tool/verifier_jetons.dart` | **77 fichiers**, aucune violation |
| `0001` à `0006` sur une base nue | appliquées, aucune erreur |
| `scenarios_etape3.sql` puis `scenarios_etape4.sql` | 34 puis 39 contrôles, tous verts |

Troisième lot de l'étape à ne pas toucher la base, après L6 et L7 : tout ce dont
`ADM-01` et `ADM-06` avaient besoin était écrit en L1 et L2, y compris
`ServiceAdmin.decider`, `ServiceRegles.poser` et `.clore`, qui n'avaient
jusqu'ici **aucun appelant**. Une seule lecture manquait, l'historique des
surcharges closes, détaillée plus bas.

`0006` est désormais rejouée par le harnais, à la suite de `0005` : elle est
faite de deux `create or replace`, donc sans effet sur une base neuve, et le
compte de contrôles reste identique. C'est ce qui prouve qu'elle est sans
danger là où elle sert vraiment, la base réelle, qui ne l'a **toujours pas
jouée**.

L'étape ferme ainsi le parcours 6 du tableau de la section 1 de la
spécification, et rend visibles les demandes que `ENS-06` et `TUT-05`
déposaient depuis L4 et L8 sans que personne puisse les lire.

### Le tri du feed de `ENS-06` était l'exact inverse de sa règle

Défaut de L4, trouvé en écrivant la liste « à traiter en premier » de `ADM-01`,
qui repose sur la même grandeur : l'ancienneté.

`elevesEnAttente()` lisait `.order('depuis')`, sous un commentaire qui dit
« Ancienneté d'abord : sans ce tri, un élève peut rester invisible en bas de
liste indéfiniment ». **`order()` de postgrest trie en descendant quand on ne
dit rien** : `ascending` vaut `false` par défaut. Le feed rendait donc la
famille qui attend depuis le moins longtemps en premier, et enfonçait au bas de
la liste celle qui attend depuis le plus longtemps, c'est-à-dire exactement
celle que le tri existe pour faire remonter. La vue ne trie rien de son côté,
il n'y avait donc aucun garde-fou derrière.

Le défaut ne se voyait pas : la liste était bien triée, et rien ne dit à l'œil
dans quel sens elle devrait l'être. Il fallait deux familles d'ancienneté
différente et savoir laquelle devait être en haut.

Deux corrections, pas une :

1. La requête écrit son sens, `ascending: true`, et la lecture de l'historique
   des règles écrit le sien, `ascending: false`, alors même que c'est le défaut.
   **Un sens de tri se lit ; il ne se déduit pas de la documentation d'un
   paquet.**
2. Surtout, **l'ordre a changé de place** : il vit maintenant dans
   `parAnciennete()`, fonction pure appelée par `ENS-06`, et non plus dans un
   paramètre de requête. C'est ce qui le rend mesurable : le faux service ne
   passe par aucun client Postgrest, donc aucun test ne pouvait attraper ce
   défaut tant qu'il vivait dans la requête. Le test donne maintenant un feed
   volontairement en désordre et mesure l'ordre à l'écran.

Les quatre autres `.order()` du dépôt ont été relus : `seances()`,
`affectations()`, la grille de disponibilités et les appareils appairés. Toutes
sont en descendant elles aussi, et **aucune n'est un défaut** : chaque
consommateur retrie en Dart (`prochainCours`, `seanceAnnuleeDuJour`,
`construireJournee`) ou lit la liste par `where` et `any`, sans dépendre de son
ordre. Elles n'ont donc pas été touchées : ce lot corrige un défaut, il ne
refactorise pas ce qui marche.

### Une lecture manquait, et une seule

L'historique des surcharges closes. `regles_profil_v` ne joint que la surcharge
**active**, parce que c'est elle seule qui décide de la valeur effective ; la
migration le dit dans son propre commentaire. Un écran qui aurait cherché les
surcharges closes dans cette vue n'aurait rien trouvé, sans erreur : même
famille de piège qu'à L6, où la pause lue dans cette vue rendait zéro.

`ServiceRegles.historique()` lit donc la table `rule_overrides`, où la RLS
`rule_overrides_parties_read` borne la lecture aux mêmes parties que la vue.

### `ADM-01` ne rend que deux des six compteurs en lignes, et c'est mesuré

La liste « à traiter en premier » mêle deux sources, les dossiers et les
demandes, ordonnées par la seule ancienneté : un dossier déposé le 1er passe
devant une demande du 4, qui passe devant un dossier du 7. La nature de la ligne
n'entre jamais dans le tri.

Les quatre autres compteurs n'ont **aucune ligne**, et ce n'est pas un oubli :
un foyer sans enseignant, un cahier manquant, un incident et un accès échu se
comptent en base, mais aucune fonction ne rend la ligne correspondante.
`ADM-05`, l'attribution manuelle, et le journal d'audit sont hors de l'étape 4.
Une ligne qui ne mènerait nulle part vaut moins qu'un compteur qui dit combien,
et l'écran le dit en toutes lettres sous la liste.

### La file des dossiers peut échouer sans emporter les compteurs

`read_kyc_documents()` refuse la lecture quand le genre du lecteur est inconnu,
et `ADM-01` lit cette file pour ses lignes de dossiers. Les six compteurs, eux,
viennent d'`indicateurs_admin()` : les perdre en même temps ferait croire à une
panne générale là où il manque une information que l'administrateur peut
fournir. Les deux lectures sont donc séparées à l'écran, et un test le mesure.

Le cas inverse compte autant : une lecture des compteurs en échec **ne rend pas
six zéros**. Six zéros sur une lecture ratée seraient un mensonge tranquille,
l'écran annonçant « rien à faire » alors qu'il n'a rien lu. C'est la même règle
qu'à l'étape 3 : une absence n'est pas un échec, et un échec n'est pas une
absence.

### Ce que L9 ne rend pas, et ce n'est pas un oubli

- **Aucun choix libre d'élève sur `ADM-06`.** La feuille de règles s'ouvre sur
  le sujet de la demande en cours. Ouvrir celle d'un élève quelconque
  demanderait une liste d'élèves côté administration, et **aucune fonction n'en
  rend une** : `eleves_en_attente_v` est bornée à l'enseignant qui regarde,
  `profils_du_foyer_v` au foyer, et `ADM-05` est hors étape. La consigne de
  l'ADR-017 est honorée là où elle se joue : depuis la feuille, l'administration
  change **n'importe laquelle** des règles de l'élève, y compris celles que la
  demande ne vise pas, et sans qu'aucune demande existe pour elles. Un test le
  mesure en montant la feuille seule, sans aucune demande.
- **Aucune notification à la partie qui a demandé.** Le canal n'existe pas,
  `device_tokens` est vide et l'étape D reste ouverte. L'écran ne promet donc
  aucun délai de réponse.
- **Aucun historique des demandes tranchées.** `demandes_en_attente()` ne rend
  que les demandes en attente, ce qui est ce dont la file a besoin. Les
  décisions passées se lisent au journal d'audit, qui est un écran à part.

## Pièges du lot L8

### La semaine d'un créneau se datait dans le fuseau de celui qui la demandait

Défaut de `0005`, écrit en L1, **trouvé en mesurant** : le contrôle « Feed » de
`scenarios_etape4.sql`, vert le 6 septembre, est rouge le 7 à 00h23 locales.
L'enseignante de Conakry ne voyait plus le créneau posé en heure de Paris.

`instant_creneau()` ancrait sa semaine sur
`date_trunc('week', now() at time zone p_tz)`. Chaque fuseau datait donc sa
propre semaine, et les deux minuits du lundi ne tombent pas au même instant :
entre lundi 00h00 à Paris et lundi 00h00 à Conakry, Paris est en semaine N et
Conakry encore en semaine N-1. Mesure, à 22h23 UTC : « lundi 17h Paris » rendait
`2026-09-07 15:00+00`, « lundi 15h Conakry » `2026-08-31 15:00+00`. Sept jours
d'écart pour le même rendez-vous.

Conséquence en production, et c'est elle qui compte : **deux heures par semaine,
le feed de `ENS-06` se vidait de toute famille d'un autre fuseau.** Sans erreur,
sans ligne de journal, et deux heures plus tard tout revenait. C'est exactement
la panne qu'on ne reproduit jamais quand on la cherche.

L'ancre est donc en UTC, la même pour tous les appels. **Leçon : un calcul
partagé entre plusieurs fuseaux s'ancre sur une référence commune**, et se
convertit à l'affichage seulement. Même règle qu'à L5 pour `PrayerTimes.utc` et
qu'à L7 pour `joursCivilsEntre`, appliquée cette fois à la semaine.

Le contrôle qui le mesure ne compare à aucune valeur écrite en dur, qui serait
vraie en été et fausse en hiver : deux fuseaux séparés de quelques heures ne
peuvent pas rendre un jour entier d'écart pour le même jour et la même heure
nominale. Il vaut donc à n'importe quelle heure, n'importe quel jour de l'année,
ce qui est précisément ce qui manquait au contrôle « Feed » : celui-là mesurait
juste, mais seulement les jours où il avait raison.

### Une vue de cache ne portait pas ce que l'écran devait afficher

`TUT-01` affiche, en MVP-0 et à la place d'un portefeuille, la date de fin
d'accès de chaque enfant. Elle vit dans `profiles.access_until`, que le tuteur
lit déjà, mais `profils_du_foyer_v` ne la portait pas : l'écran aurait lu une
seconde source pour une colonne de la même ligne, et les deux auraient fini par
diverger. La vue est donc recréée dans `0005`, avec sa colonne.

C'est la quatrième correction sur place de cette migration, et pour la même
raison que les trois précédentes : elle n'est appliquée nulle part, l'étape D
restant ouverte.

### Une écriture manquait, et une seule

Le tableau de passation de L7 disait vrai : tout était en place côté données sauf
l'écriture des trois réglages de `student_profiles`. `ServiceAppairage` a gagné
`majReglages`, bornée aux trois colonnes que le `GRANT UPDATE (colonnes)` de
`0005` autorise, et **qui n'envoie que ce qui change**. Envoyer les trois à
chaque geste aurait écrasé ce qu'un autre appareil du foyer venait de poser, ce
qui est le cas d'usage normal d'un foyer à deux parents.

### `demander()` avait déjà un appelant, contrairement à ce qu'annonçait la passation

`ENS-06` l'appelle depuis L4 pour l'augmentation de plafond. Ce qui manquait,
c'étaient les demandes du **tuteur** : réaffectation, durée de séance et minimum
payable. Elles partent de `TUT-05`, là où le parent constate la règle, et non
d'un écran de demandes qui n'existe pas.

La réaffectation n'est proposée **que si un enseignant suit l'enfant** : sinon la
base refuse « cet élève n'a pas d'enseignant à changer » après le geste, et un
bouton qui échoue après le geste coûte plus cher qu'un bouton absent. Les deux
demandes de règle, elles, restent proposées dans tous les cas.

### La photo avait son seau depuis l'étape 3, et aucun code pour y écrire

Le seau `avatars` et ses quatre policies existent depuis `0004`. `ServiceAvatar`
n'ouvre donc aucune porte nouvelle, il emprunte celle qui attendait son écran. Le
chemin de dépôt porte l'identifiant de **l'enfant** en premier segment, et non
celui du tuteur : c'est lui que `profil_de_mon_foyer()` compare dans la policy de
stockage, contrairement au dépôt KYC où le premier segment est celui du déposant.

Le refus de taille se dit **avant** l'envoi. Le seau refuserait aussi, mais après
avoir fait monter quatre mégaoctets sur une connexion de téléphone.

## Pièges du lot L7

### Deux sources pour un même fait finissent par se contredire

`OfflineBanner` s'abonnait lui-même à `connectivity_plus`. Le sixième état de
`ELV-02` se lit sur le même fait, et un second abonnement aurait suffi à mettre
un bandeau « pas de réseau » au-dessus d'un bouton d'entrée en séance resté
actif, ou l'inverse, pendant le temps où les deux abonnements divergent.

Il y avait plus gênant : **cet état n'était pas mesurable**. Aucun test ne coupe
le réseau de la machine qui l'exécute. Le fait vit désormais dans un service,
comme les autres, avec son faux en mémoire, et le bandeau le lit comme l'écran.

### Le retour tactile est déjà une animation d'échelle

Le test qui vérifie que le bloc imminent pulse cherchait un `ScaleTransition`.
Il en trouvait plusieurs, et aurait été **vert sans aucune pulsation** :
`Pressable` en pose un par zone tactile, pour son propre retour au doigt.

La pulsation porte donc une clé nommée, et le test la désigne. Même famille que
le piège de L6 : un test qui trouve ce qu'il cherche à côté de ce qu'il croit
mesurer. **Chercher un type de widget ne prouve rien quand un composant partagé
emploie le même type pour autre chose.**

### Un composant partagé qui ne sait pas sur quoi il écrit

`AudioLabel` dessinait son haut-parleur à l'encre d'accent et son texte à la
couleur du thème. Posé tel quel sur le bloc violet des états imminent et en
direct, il aurait écrit du violet foncé sur du violet et du noir sur du violet.

C'est le piège de paire de L6 pris par un troisième bout : ni l'écran ni le
thème n'étaient en tort, c'est l'**API du composant** qui ne demandait pas sur
quoi elle s'écrivait. Il accepte maintenant une paire, comme `BentoTile` et
`ActionPrincipale` le font depuis l'étape 2. La correction vaut pour tous les
écrans à venir qui poseront un libellé parlé sur autre chose que le fond
général.

### Un écran dont l'état se compte en minutes ne lit pas l'horloge

Les six états se distinguent par des minutes : cinq avant le début, le début, la
fin. Les premières fixtures se calaient sur `DateTime.now()`, et deux tests
devenaient faux dans le dernier quart d'heure avant minuit, où « dans 25
minutes » cesse d'être aujourd'hui. Environ deux exécutions sur cent, c'est-à-dire
un échec inexplicable tous les quelques jours.

L'écran reçoit donc son horloge, comme `deciderRedirection` reçoit son
`maintenant` depuis l'étape 2. En production c'est `DateTime.now`, en test c'est
un mardi de septembre à dix-sept heures. Les marges de trente secondes des tests
de `ENS-02` n'ont plus lieu d'être ici.

### Le test du changement d'heure mesurait le fuseau de la machine

Le prochain cours s'exprime en jours. Un premier `joursCivilsEntre` posait deux
minuits **locaux** et divisait : correct, mais son test ne prouvait rien. Ce
poste est à UTC+3 sans heure d'été et la CI tourne en UTC ; dans ces deux
fuseaux, la nuit de mars dure vingt-quatre heures comme les autres, et le test
serait resté vert même avec un calcul faux.

Les deux dates civiles sont donc reposées **en UTC**, où un jour dure toujours
vingt-quatre heures : le calendrier est conservé, le fuseau neutralisé, et le
compte est le même partout. Le test vaut alors sur n'importe quelle machine, au
lieu de valoir sur celles qui n'ont pas d'heure d'été. Même règle qu'à L5 pour
`PrayerTimes.utc`, appliquée au calendrier plutôt qu'au soleil.

### Un bouton grisé, alors que la règle dit de ne pas le rendre

Depuis l'étape 3, un bouton qui ne peut pas aboutir n'est pas rendu : une phrase
prend sa place. Hors ligne, `ELV-02` fait pourtant l'inverse et garde
« Rejoindre » en place, inerte, avec le pictogramme de réseau.

Ce n'est pas une entorse mais l'autre moitié de la même règle. Ce qu'un bouton
absent explique, c'est une **limite** : le plafond de `ENS-06` ne tombera pas
tout seul, et le chemin pour le lever est ailleurs. Une panne de réseau n'est
pas une limite, c'est un état passager de l'appareil, et pour un enfant de six
ans un bouton disparu voudrait dire que son cours n'existe plus. L'inertie se
signale par un changement de **paire**, jamais par de la transparence, qui
ferait tomber le libellé sous le seuil de contraste.

## Pièges du lot L6

### La vue des règles ne rend pas la même chose que la fonction

`ENS-06` lit le plafond dans `regles_profil_v`, et cela marche. La même méthode
appliquée à la pause entre deux cours rend **zéro**, sans erreur : la vue joint
à chaque profil les seules clés qui ont un sens pour son rôle, et à un
enseignant elle ne rend que `max_students_per_teacher`.

Zéro se lit « aucun trou n'est une pause ». La colonne de `ENS-02` n'aurait
jamais affiché une seule pause, et rien ne l'aurait signalé : ni exception, ni
ligne vide, ni test rouge. `regle_effective()` ne borne pas par rôle, elle borne
par périmètre de lecture, et rend bien la valeur de plateforme à l'enseignant
qui la demande pour lui-même.

**Leçon : une vue de commodité et la fonction qu'elle enveloppe ne couvrent pas
le même périmètre.** Le nouveau `valeurRegleProvider` passe par la fonction, et
son commentaire dit pourquoi. Le test le mesure dans les deux sens, comme le
plafond en L4 : la même journée, avec et sans la règle, rend la pause ou ne la
rend pas.

### Compter les lignes d'un feed, ce n'est pas compter les familles

`eleves_en_attente_v` rend **une ligne par créneau compatible** : un élève qui
propose quatre heures que cet enseignant peut tenir y figure quatre fois. C'est
voulu pour `ENS-06`, dont chaque carte porte un bouton « Prendre mardi à 17 h ».

Le bloc secondaire de `ENS-02`, lui, annonce un nombre de familles. Compter les
lignes aurait annoncé quatre élèves en attente là où un seul attendait, et le
chiffre aurait grossi chaque fois qu'une famille ajoute un créneau, c'est-à-dire
exactement quand elle facilite le travail de l'enseignant.

### Une paire dit sur quoi elle s'écrit, y compris dans un bloc dominant

`BentoTile` pose bien l'encre de sa surface par défaut, mais un style pris dans
le thème porte déjà sa couleur et l'écrase. Le bloc dominant en cours est sur
la surface d'accent, violette : les styles du thème y auraient écrit en noir.

Le bloc n'a donc qu'un seul chemin, la paire est lue dans une variable et chaque
style la traverse par `applyTo`. C'est le même défaut qu'à l'étape 3 dans
`PinPad`, pris par l'autre bout.

### Une journée civile ne dure pas toujours vingt-quatre heures

Les bornes de la colonne s'écrivent `DateTime(annee, mois, jour + 1)` et non
`debutDuJour.add(const Duration(days: 1))`. Deux fois par an, la seconde forme
perd ou double une heure de cours, et la colonne serait fausse le jour où
personne ne pense à regarder.

Même famille que le piège de L5 sur `PrayerTimes.utc` : ce qui se calcule en
instants se convertit à l'affichage, et une date civile se manipule en
composantes de date.

### Pourquoi cet écran ne mentionne aucun fuseau

`ENS-06` affiche « heures affichées en Europe/Paris », et c'est exact : sa
grille est un motif hebdomadaire, posé dans le fuseau que `mon_fuseau()`
déclare. `ENS-02` n'affiche que des instants absolus, rendus dans l'heure de
l'appareil. Reprendre la même mention aurait annoncé Paris à un enseignant qui
lit son écran depuis Conakry, avec des heures qui, elles, seraient bien celles
de Conakry.

**Une mention de fuseau ne se recopie pas d'un écran à l'autre : elle dit d'où
vient l'heure affichée, et les deux écrans ne la tiennent pas du même endroit.**

### Le test mesurait la hauteur du viewport

Deux prières sur cinq manquaient à la colonne sous test. La colonne était juste :
un `ListView` ne construit pas ce qui n'est pas à l'écran, et les lignes du bas
n'existaient pas dans l'arbre. Le test a gagné une fenêtre haute, avec la raison
écrite à côté.

C'est le pendant du piège de L1, « le test mesurait le harnais » : ici il
mesurait la surface d'affichage. **Un `findsNothing` sur une liste longue ne
prouve rien tant que la fenêtre n'est pas assez haute pour la contenir.**

## Ce que l'étape reprend de l'existant

À dire ici pour qu'aucun lot ne le réécrive :

- Les dix composants partagés de l'étape 2, `BentoTile` en tête, qui donne son
  nom à cette étape.
- Le routeur unique et ses portes d'accès, complétés à l'étape 3. L'étape 4
  remplace des `EcranAConstruire` derrière des routes **déjà déclarées** ; elle
  n'en ajoute qu'une, celle de `ADM-06`.
- Les services de dossier et d'appairage, et leur forme : une interface
  abstraite, une implémentation Supabase, un faux en mémoire pour les tests.

## Pièges rencontrés, à ne pas repayer

Les pièges de poste des étapes 2 et 3 restent valables : magasin de racines qui
ne fait pas confiance à `github.com`, composant ATL absent de Visual Studio,
plateforme Android mal nommée. Voir les journaux précédents.

### Un plafond qui n'en était pas un

Le scénario 3 refusait la deuxième prise sur cinq créneaux consécutifs, puis la
quatrième : trois passaient, deux échouaient. Cela ressemblait à un plafond mal
compté. C'était `guard_session_overlap`, qui compare les séances en **bornes
fermées** : un cours de 10h à 11h et le suivant de 11h à 12h partagent l'instant
11h00 et se recoupent donc, au sens de `tstzrange(..., '[]')`.

Le défaut existait depuis l'étape 1 et ne pouvait pas se voir : aucun écran ne
créait de séance. Il aurait rendu `ENS-02` faux pour son cas d'usage principal,
l'enseignant qui enchaîne cinq cours.

**Leçon : un garde-fou de planning se lit sur ses bornes.** Un intervalle de
temps se ferme à gauche et s'ouvre à droite ; la fin d'une séance est le début de
la suivante, elle ne lui appartient pas. Les deux garde-fous de l'étape, le
déclencheur et la contrainte `EXCLUDE`, emploient désormais la même convention.

### Le test mesurait le harnais, pas la migration

Deux refus attendus ne se produisaient pas. Cause : le fichier de scénarios
commence par les grants que Supabase applique par défaut, `grant all on all
tables`, qui **annulaient** la restriction de colonnes et les révocations posées
par la migration. En production l'ordre est inverse, la migration passant après
les droits par défaut.

Les révocations sont donc rejouées dans le harnais, avec la raison écrite à côté.
Sans cela, le scénario 6 aurait mesuré le harnais et déclaré verte une
protection absente.

### Qui est partie à un dossier, exactement

Première écriture de `partie_concernee()` : l'élève, son foyer, son enseignant,
le personnel. Le tuteur ne pouvait donc lire ni les disponibilités ni les
réglages de prière de l'enseignant **de son enfant**, faute de lien direct entre
lui et cet enseignant.

La transparence de l'ADR-017 se serait arrêtée à l'enfant lui-même, qui a six
ans et ne lit pas encore. Le foyer est partie au dossier de l'enseignant de son
enfant : c'est une branche de plus, et elle est la raison d'être de la fonction.

### Riverpod cache encore un type dans `misc.dart`

`FutureProviderFamily` n'est pas exporté par l'entrée principale de Riverpod 3,
exactement comme `Override` à l'étape 3. Il vit dans
`package:flutter_riverpod/misc.dart`. Le projet annote tous ses providers, donc
le type est nécessaire, et l'erreur est une classe indéfinie plutôt qu'un
import manquant, ce qui envoie chercher au mauvais endroit.

### La porte par défaut du paquet de prières rend l'heure de l'appareil

`PrayerTimes(coordonnees, date, parametres)` est le constructeur naturel du
paquet `adhan`, celui de tous ses exemples. Il termine par `.toLocal()` : il
rend donc les heures **du fuseau de l'appareil qui calcule**, pas celles du lieu
de référence de l'enseignant.

Sur un produit à un seul pays, cela ne se serait jamais vu. Ici, l'enseignante
de Conakry et le foyer parisien auraient obtenu deux journées décalées d'une
heure pour la même prière du même cours, chacun avec la même certitude. C'est
mot pour mot le litige que l'ADR-017 cherche à éteindre, reconstitué par une
ligne de code.

La porte employée est donc `PrayerTimes.utc`, qui prend une date civile en UTC
et rend des instants absolus. Chacun les affiche ensuite dans son heure locale :
deux heures différentes à l'écran, **le même instant**, ce qui est exactement ce
que dit l'invariant I8.

**Leçon : un calcul partagé entre plusieurs fuseaux se fait en instants, et se
convertit à l'affichage seulement.** Même règle que `instant_creneau` en base
depuis L1, et le croisement d'une prière avec une séance suit la même : les
horaires des trois jours civils qui entourent la fenêtre sont calculés, puis
filtrés par instant. Un croisement par heure locale se tromperait de journée
deux fois par an, au changement d'heure.

### Le test qui accuse le code à tort

Deux échecs de scénario venaient du test, pas de la migration : un tuteur
« étranger » qui avait en fait un enfant suivi par l'enseignant observé, et un
élève « incompatible » dont le créneau figurait bien chez l'enseignant. Les
fixtures ont gagné un troisième foyer, sans aucune affectation, dont c'est le
seul rôle.

**Un test qui échoue ne prouve pas que le code a tort.** Avant de corriger une
migration, relire ce que le test suppose.
