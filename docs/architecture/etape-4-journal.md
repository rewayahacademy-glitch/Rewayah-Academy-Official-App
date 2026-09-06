# Journal d'exécution - Étape 4

> Ce fichier dit **où en est le code** de l'étape 4, ce que valent les mesures,
> et quels pièges ont déjà coûté du temps.
> `docs/architecture/etape-4-dashboards.md` reste la spécification ; ce journal
> est son compte rendu. Mis à jour à la fin de chaque lot, jamais en bloc.

## État : L0 fait, l'étape commence

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | Spécification `etape-4-dashboards.md`, ADR-017, ce journal | x |
| L1 | Migration `0005` et `supabase/tests/scenarios_etape4.sql` | |
| L2 | Services Dart : règles, planning, affectations, disponibilités | |
| L3 | Grille de semaine partagée, `TUT-04`, onglet de `ENS-06` | |
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

## Les dix-sept scénarios d'acceptation

Voir la section 7 de la spécification. Aucun n'est coché tant qu'il n'est pas
mesuré, règle constante depuis l'étape 1.

| # | Scénario | État |
| :-- | :--- | :--- |
| 1 | Tuteur et enseignant écrivent dans la même table de disponibilités | à mesurer |
| 2 | Un élève ne peut pas avoir deux enseignants actifs | à mesurer |
| 3 | Le sixième élève est refusé par la base | à mesurer |
| 4 | Deux prises simultanées : une seule passe | à mesurer |
| 5 | Un enseignant ne se retire pas un élève sans décision | à mesurer |
| 6 | Le tuteur change la caméra de son enfant, et rien d'autre | à mesurer |
| 7 | Deux séances du même enseignant qui se recoupent sont refusées | à mesurer |
| 8 | Un tuteur ne lit plus les disponibilités des enseignants étrangers à son foyer | à mesurer |
| 9 | Élève et enseignant affichent la même minute de prière | à mesurer |
| 10 | Un ajustement d'une minute déplace l'entrée des deux côtés | à mesurer |
| 11 | Les compteurs de `ADM-01` affichent zéro sans disparaître | à mesurer |
| 12 | `ENS-06` ne rend pas « Prendre » au plafond | à mesurer |
| 13 | `ELV-02` affiche ses six états | à mesurer |
| 14 | Démarrage à froid mesuré sur `ELV-02` réel | à mesurer |
| 15 | Une règle posée pour un élève ne change rien pour les autres | à mesurer |
| 16 | Une surcharge close reste lisible, aucune ne se supprime | à mesurer |
| 17 | Une demande de chacune des quatre parties atteint `ADM-06` | à mesurer |

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

Cette section se remplit lot par lot.
