# Journal d'exécution - Étape 4

> Ce fichier dit **où en est le code** de l'étape 4, ce que valent les mesures,
> et quels pièges ont déjà coûté du temps.
> `docs/architecture/etape-4-dashboards.md` reste la spécification ; ce journal
> est son compte rendu. Mis à jour à la fin de chaque lot, jamais en bloc.

## État : L1 fait, la base porte l'étape 4

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | Spécification `etape-4-dashboards.md`, ADR-017, ce journal | x |
| L1 | Migration `0005` et `supabase/tests/scenarios_etape4.sql` | x |
| L2 | Services Dart : règles, planning, affectations, disponibilités | x |
| L3 | Grille de semaine partagée, `TUT-04` | x |
| L4 | `ENS-06` élèves en attente, prise atomique, plafond | |
| L5 | Prières : réglages, calcul, ajustements, entrées de planning | |
| L6 | `ENS-02` la journée | |
| L7 | `ELV-02` et la mesure du démarrage à froid | |
| L8 | `TUT-01`, `TUT-05`, demandes des parties | |
| L9 | `ADM-01`, `ADM-06` | |
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
| 9 | Élève et enseignant affichent la même minute de prière | à mesurer | L5 |
| 10 | Un ajustement d'une minute déplace l'entrée des deux côtés | à mesurer | L5. Les réglages, eux, sont vérifiés en base |
| 11 | Les compteurs de `ADM-01` affichent zéro sans disparaître | à mesurer | L9. L'exactitude des six compteurs est déjà vérifiée en SQL |
| 12 | `ENS-06` ne rend pas « Prendre » au plafond | à mesurer | L4 |
| 13 | `ELV-02` affiche ses six états | à mesurer | L7 |
| 14 | Démarrage à froid mesuré sur `ELV-02` réel | à mesurer | L7 |
| 15 | Une règle posée pour un élève ne change rien pour les autres | vert | S15a à S15c |
| 16 | Une surcharge close reste lisible, aucune ne se supprime | vert | S16a à S16c |
| 17 | Une demande de chacune des quatre parties atteint `ADM-06` | vert | S17a à S17e |

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

### Le test qui accuse le code à tort

Deux échecs de scénario venaient du test, pas de la migration : un tuteur
« étranger » qui avait en fait un enfant suivi par l'enseignant observé, et un
élève « incompatible » dont le créneau figurait bien chez l'enseignant. Les
fixtures ont gagné un troisième foyer, sans aucune affectation, dont c'est le
seul rôle.

**Un test qui échoue ne prouve pas que le code a tort.** Avant de corriger une
migration, relire ce que le test suppose.
