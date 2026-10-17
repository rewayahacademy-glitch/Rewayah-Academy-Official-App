# Simulation économique — 216 scénarios

216 combinaisons × 300 tirages × 12 mois, graine 20261017, modèle v2. Chiffres d'un mois type (mois 3 à 12, médiane). Enseignants payés 4,00 $ / h, administration 5 × 300 $, impôt britannique sur les sociétés sur le bénéfice, cartes Stripe Royaume-Uni. Objectif 2 000 $ net par mois après tout cela.

« Prudent » veut dire tenu 9 mois sur 10 : un mois sur 10 seulement fait moins bien.

## Vue d’ensemble

|  | Pire scénario | 1 sur 10 | Médian | 9 sur 10 | Meilleur |
| --- | ---: | ---: | ---: | ---: | ---: |
| Encaissé par mois | 4 525 $ | 4 702 $ | 5 139 $ | 5 444 $ | 5 637 $ |
| Impôt sur les sociétés | 274 $ | 293 $ | 370 $ | 416 $ | 447 $ |
| Net à 4,00 $ / h | 1 167 $ | 1 251 $ | 1 578 $ | 1 773 $ | 1 908 $ |
| Net au plafond 7,00 $ / h | 441 $ | 477 $ | 803 $ | 971 $ | 1 102 $ |
| Mois où l'objectif 2 000 $ est atteint | 0 % | 0 % | 1 % | 4 % | 13 % |
| Mois sans perte | 100 % | 100 % | 100 % | 100 % | 100 % |
| Taux max pour ne pas perdre d’argent (prudent) | 7,29 $ | 7,39 $ | 9,14 $ | 10,61 $ | 11,35 $ |
| Taux max pour garder 2 000 $ (prudent) | 0,00 $ | 0,00 $ | 1,35 $ | 3,05 $ | 3,65 $ |
| Taux max pour 30 % de marge (prudent) | 2,28 $ | 2,47 $ | 3,52 $ | 4,48 $ | 4,80 $ |
| Encaissement qu’on peut perdre sans perte (prudent) | 1 044 $ | 1 130 $ | 1 717 $ | 2 277 $ | 2 479 $ |
| Remise max sur tous, sans perte (prudent) | 26 % | 27 % | 36 % | 42 % | 44 % |
| Élèves sans classe | 0 | 0 | 0 | 7 | 7 |
| Classes | 17 | 18 | 20 | 21 | 21 |

L'objectif de 2 000 $ net est atteint dans au moins 9 mois sur 10 pour 0 scénarios sur 216. L'académie ne perd pas d'argent 9 mois sur 10 dans 216 scénarios sur 216.

## Ce que change chaque choix

Moyenne sur tous les scénarios qui partagent ce choix.

| Dimension | Choix | Encaissé | Net à 4,00 $ / h | Objectif atteint | Taux max sans perte | Sans classe | Classes |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| paiement | Idéal | 5 371 $ | 1 732 $ | 0 % | 10,63 $ | 2.1 | 19.4 |
| paiement | Optimiste | 5 202 $ | 1 632 $ | 3 % | 9,42 $ | 2.1 | 19.4 |
| paiement | Réaliste | 5 053 $ | 1 518 $ | 2 % | 8,79 $ | 2.1 | 19.4 |
| paiement | Pessimiste | 4 755 $ | 1 289 $ | 0 % | 7,58 $ | 2.1 | 19.4 |
| mixiteAdultes | Adultes séparés | 5 096 $ | 1 533 $ | 1 % | 9,01 $ | 2.1 | 19.6 |
| mixiteAdultes | Adultes mixtes | 5 094 $ | 1 553 $ | 2 % | 9,20 $ | 2.1 | 19.2 |
| mixiteEnfants | Enfants mixtes | 5 188 $ | 1 595 $ | 2 % | 9,21 $ | 0.0 | 19.8 |
| mixiteEnfants | Enfants séparés dès 10 ans | 5 086 $ | 1 531 $ | 1 % | 9,03 $ | 2.3 | 19.5 |
| mixiteEnfants | Enfants séparés | 5 011 $ | 1 503 $ | 1 % | 9,07 $ | 4.0 | 18.8 |
| origine | 70 % Europe | 5 095 $ | 1 550 $ | 2 % | 9,13 $ | 2.1 | 19.4 |
| origine | 50 / 50 | 5 095 $ | 1 542 $ | 1 % | 9,10 $ | 2.1 | 19.4 |
| origine | 70 % Amérique du Nord | 5 095 $ | 1 536 $ | 1 % | 9,08 $ | 2.1 | 19.4 |
| partEnfants | 30 % d’enfants | 5 229 $ | 1 623 $ | 3 % | 9,34 $ | 2.7 | 18.5 |
| partEnfants | 45 % d’enfants | 5 023 $ | 1 502 $ | 1 % | 9,01 $ | 3.7 | 19.0 |
| partEnfants | 60 % d’enfants | 5 034 $ | 1 504 $ | 1 % | 8,96 $ | 0.0 | 20.7 |

## Et si des familles ne paient pas ?

Scénario de référence : comportement réaliste, adultes séparés, enfants mixtes, 50 % Europe / 50 % Amérique du Nord, 45 % d’enfants, enseignants à 4,00 $ / h. Un seul levier bouge à la fois.

Chaque mois, une part des familles ne paie pas du tout et une autre paie avec un mois de retard. Elles restent inscrites. Chaque case : net par mois, puis l’argent qui manque en caisse à la fin du mois à cause des retards (il arrive le mois suivant).

| Ne paient pas ↓ / En retard d’un mois → | 0 % | 20 % | 40 % | 60 % |
| --- | ---: | ---: | ---: | ---: |
| **0 %** | 1 702 $ · caisse −0 $ | 1 700 $ · caisse −1 045 $ | 1 697 $ · caisse −2 119 $ | 1 704 $ · caisse −3 174 $ |
| **5 %** | 1 512 $ · caisse −0 $ | 1 495 $ · caisse −1 048 $ | 1 499 $ · caisse −2 110 $ | 1 499 $ · caisse −3 178 $ |
| **10 %** | 1 306 $ · caisse −0 $ | 1 291 $ · caisse −1 045 $ | 1 287 $ · caisse −2 120 $ | 1 289 $ · caisse −3 195 $ |
| **15 %** | 1 102 $ · caisse −0 $ | 1 093 $ · caisse −1 050 $ | 1 089 $ · caisse −2 118 $ | 1 085 $ · caisse −3 196 $ |
| **20 %** | 892 $ · caisse −0 $ | 884 $ · caisse −1 055 $ | 890 $ · caisse −2 114 $ | 878 $ · caisse −3 208 $ |
| **30 %** | 483 $ · caisse −0 $ | 473 $ · caisse −1 046 $ | 471 $ · caisse −2 137 $ | 468 $ · caisse −3 211 $ |
| **40 %** | 75 $ · caisse −0 $ | 63 $ · caisse −1 050 $ | 63 $ · caisse −2 138 $ | 72 $ · caisse −3 215 $ |
| **50 %** | -413 $ · caisse −0 $ | -429 $ · caisse −1 060 $ | -434 $ · caisse −2 143 $ | — |

L’objectif de 2 000 $ n’est pas atteint même sans aucun impayé. L’académie perd de l’argent dès 50 % de familles qui ne paient pas.
Le retard seul ne fait presque rien perdre sur l’année : il vide la caisse en fin de mois. Il faut donc une réserve au moins égale à la colonne « caisse ».

## Et si on perd des élèves ?

Scénario de référence : comportement réaliste, adultes séparés, enfants mixtes, 50 % Europe / 50 % Amérique du Nord, 45 % d’enfants, enseignants à 4,00 $ / h. Un seul levier bouge à la fois.

Les élèves perdus ne sont pas remplacés. « Places vides » : les classes restent telles quelles, les enseignants sont payés pareil. « Classes regroupées » : l’administration refait les classes avec ceux qui restent, il y a moins d’heures à payer.

| Élèves perdus | enfants, places vides | enfants, classes regroupées | adultes, places vides | adultes, classes regroupées |
| --- | ---: | ---: | ---: | ---: |
| **0** | 1 566 $ · 20 classes | 1 566 $ · 20 classes | 1 566 $ · 20 classes | 1 566 $ · 20 classes |
| **5** | 1 400 $ · 20 classes | 1 406 $ · 18 classes | 1 352 $ · 20 classes | 1 419 $ · 19 classes |
| **10** | 1 228 $ · 20 classes | 1 284 $ · 17 classes | 1 139 $ · 20 classes | 1 221 $ · 19 classes |
| **15** | 1 061 $ · 20 classes | 1 147 $ · 17 classes | 930 $ · 20 classes | 1 047 $ · 17 classes |
| **20** | 890 $ · 20 classes | 1 030 $ · 15 classes | 721 $ · 20 classes | 968 $ · 16 classes |
| **30** | 593 $ · 20 classes | 746 $ · 13 classes | 317 $ · 20 classes | 636 $ · 14 classes |

## Et si ça bouge trop ?

Scénario de référence : comportement réaliste, adultes séparés, enfants mixtes, 50 % Europe / 50 % Amérique du Nord, 45 % d’enfants, enseignants à 4,00 $ / h. Un seul levier bouge à la fois.

Un élève qui change de classe ou de créneau libère sa place : elle reste vide jusqu’à ce qu’une nouvelle famille la prenne. S’il n’y a aucune place libre dans une autre classe de son âge, la demande est refusée et 3 élèves sur 10 partent alors. Les heures d’administration sont une estimation (relance 10 min, plainte 15 min, changement 30 min, départ 20 min, arrivée 45 min).

| Stabilité | Ce que ça veut dire | Élèves présents | Départs / mois | Changements / mois | Refusés | Heures d’administration / mois | Net / mois |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Calme** | départs ÷ 2, 1 % demandent à changer, place reprise en 1 mois | 97 | 2 | 1 | 0 | 12 | 1 628 $ |
| **Normal (référence)** | départs du scénario, 2 % demandent à changer, 1 mois | 95 | 3 | 2 | 0 | 14 | 1 566 $ |
| **Agité** | départs × 2, 6 % demandent à changer, 1 mois | 91 | 5 | 5 | 1 | 16 | 1 421 $ |
| **Très agité** | départs × 3, 10 % demandent à changer, place reprise en 2 mois | 80 | 6 | 7 | 0 | 17 | 953 $ |
| **Personne ne remplace** | départs du scénario, aucune nouvelle inscription | 78 | 2 | 1 | 0 | 9 | 901 $ |

## Ce qu’on peut se permettre, scénario par scénario

Toutes les valeurs sont prudentes (tenues 9 mois sur 10), enseignants à 4,00 $ / h.

- **Perte max sans perte** : encaissement mensuel qu’on peut perdre (impayés, départs, bourses, remises) avant que l’académie perde de l’argent.
- **Enfants / adultes perdus ou boursiers max** : même montant, compté en mensualités d’enfant (50 $) ou d’adulte (60 $). Une bourse complète coûte exactement comme un élève perdu dont la place reste vide ; deux demi-bourses comptent pour une.
- **Remise max** : remise en pourcentage qu’on peut faire sur toutes les mensualités. Elle donne le prix plancher : prix × (1 − remise). « Aucune » : la cible est déjà manquée, du montant indiqué.

### Les 10 pires scénarios

| Scénario | Encaissé | Net à 4,00 $ / h | Net 1 mois sur 10 | Objectif | Taux max sans perte | Perte max sans perte | Enfants / adultes perdus ou boursiers max | Remise max sans perte | Remise max pour 2 000 $ |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 525 $ | 1 167 $ | 800 $ | 0 % | 7,30 $ | 1 044 $ | 20 / 17 | 26 % | aucune (manque 1 564 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 536 $ | 1 170 $ | 801 $ | 0 % | 7,29 $ | 1 044 $ | 20 / 17 | 26 % | aucune (manque 1 565 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 525 $ | 1 173 $ | 808 $ | 0 % | 7,34 $ | 1 052 $ | 21 / 17 | 26 % | aucune (manque 1 551 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 536 $ | 1 176 $ | 807 $ | 0 % | 7,31 $ | 1 050 $ | 21 / 17 | 26 % | aucune (manque 1 553 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 525 $ | 1 181 $ | 811 $ | 0 % | 7,35 $ | 1 055 $ | 21 / 17 | 26 % | aucune (manque 1 545 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 536 $ | 1 184 $ | 814 $ | 0 % | 7,35 $ | 1 057 $ | 21 / 17 | 26 % | aucune (manque 1 539 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 4 648 $ | 1 213 $ | 854 $ | 0 % | 7,35 $ | 1 113 $ | 22 / 18 | 27 % | aucune (manque 1 495 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 4 651 $ | 1 218 $ | 833 $ | 0 % | 7,29 $ | 1 086 $ | 21 / 18 | 26 % | aucune (manque 1 522 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 4 648 $ | 1 221 $ | 860 $ | 0 % | 7,39 $ | 1 119 $ | 22 / 18 | 27 % | aucune (manque 1 483 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 4 651 $ | 1 225 $ | 841 $ | 0 % | 7,32 $ | 1 093 $ | 21 / 18 | 26 % | aucune (manque 1 509 $) |

### Les 10 meilleurs scénarios

| Scénario | Encaissé | Net à 4,00 $ / h | Net 1 mois sur 10 | Objectif | Taux max sans perte | Perte max sans perte | Enfants / adultes perdus ou boursiers max | Remise max sans perte | Remise max pour 2 000 $ |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 637 $ | 1 908 $ | 1 908 $ | 0 % | 11,10 $ | 2 479 $ | 49 / 41 | 44 % | aucune (manque 120 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 637 $ | 1 900 $ | 1 900 $ | 0 % | 11,07 $ | 2 473 $ | 49 / 41 | 44 % | aucune (manque 131 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 637 $ | 1 894 $ | 1 894 $ | 0 % | 11,05 $ | 2 469 $ | 49 / 41 | 44 % | aucune (manque 138 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 504 $ | 1 850 $ | 1 850 $ | 0 % | 11,17 $ | 2 404 $ | 48 / 40 | 44 % | aucune (manque 194 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 637 $ | 1 843 $ | 1 843 $ | 0 % | 10,47 $ | 2 394 $ | 47 / 39 | 42 % | aucune (manque 205 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 504 $ | 1 842 $ | 1 842 $ | 0 % | 11,14 $ | 2 399 $ | 47 / 39 | 44 % | aucune (manque 205 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 504 $ | 1 838 $ | 1 838 $ | 0 % | 11,12 $ | 2 395 $ | 47 / 39 | 44 % | aucune (manque 212 $) |
| Idéal · Adultes séparés · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 637 $ | 1 835 $ | 1 835 $ | 0 % | 10,44 $ | 2 388 $ | 47 / 39 | 42 % | aucune (manque 215 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 637 $ | 1 829 $ | 1 829 $ | 0 % | 10,42 $ | 2 384 $ | 47 / 39 | 42 % | aucune (manque 222 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 404 $ | 1 817 $ | 1 817 $ | 0 % | 11,35 $ | 2 362 $ | 47 / 39 | 44 % | aucune (manque 237 $) |

## Quel prix fixer

Scénario de référence : comportement réaliste, adultes séparés, enfants mixtes, 50 % Europe / 50 % Amérique du Nord, 45 % d’enfants, enseignants à 4,00 $ / h. Chaque case : net médian, puis part des mois qui atteignent 2 000 $.

| Enfant ↓ / Adulte → | 50 $ | 55 $ | 60 $ | 65 $ | 70 $ |
| --- | ---: | ---: | ---: | ---: | ---: |
| **40 $** | 843 $ · 0 % | 1 041 $ · 0 % | 1 241 $ · 0 % | 1 441 $ · 1 % | 1 641 $ · 6 % |
| **45 $** | 1 006 $ · 0 % | 1 205 $ · 0 % | 1 403 $ · 0 % | 1 602 $ · 4 % | 1 803 $ · 20 % |
| **50 $** | 1 170 $ · 0 % | 1 367 $ · 0 % | 1 566 $ · 3 % | 1 765 $ · 16 % | 1 964 $ · 44 % |
| **55 $** | 1 331 $ · 0 % | 1 531 $ · 2 % | 1 730 $ · 13 % | 1 927 $ · 39 % | 2 127 $ · 70 % |
| **60 $** | 1 494 $ · 1 % | 1 692 $ · 10 % | 1 894 $ · 33 % | 2 091 $ · 65 % | 2 289 $ · 87 % |

Taux enseignant maximal (prudent) pour ne pas perdre d’argent, puis pour garder 2 000 $ :

| Enfant ↓ / Adulte → | 50 $ | 55 $ | 60 $ | 65 $ | 70 $ |
| --- | ---: | ---: | ---: | ---: | ---: |
| **40 $** | 6,31 $ · impossible | 7,01 $ · impossible | 7,71 $ · 0,12 $ | 8,41 $ · 0,83 $ | 9,12 $ · 1,53 $ |
| **45 $** | 6,89 $ · impossible | 7,59 $ · 0,01 $ | 8,28 $ · 0,70 $ | 8,99 $ · 1,40 $ | 9,68 $ · 2,10 $ |
| **50 $** | 7,44 $ · impossible | 8,16 $ · 0,57 $ | 8,87 $ · 1,28 $ | 9,55 $ · 1,98 $ | 10,26 $ · 2,68 $ |
| **55 $** | 8,01 $ · 0,42 $ | 8,72 $ · 1,14 $ | 9,44 $ · 1,84 $ | 10,14 $ · 2,55 $ | 10,83 $ · 3,25 $ |
| **60 $** | 8,58 $ · 0,98 $ | 9,28 $ · 1,70 $ | 10,00 $ · 2,41 $ | 10,71 $ · 3,11 $ | 11,41 $ · 3,82 $ |

## Les 216 scénarios

| Scénario | Encaissé | Net à 4,00 $ / h | Net 1 mois sur 10 | Objectif | Taux max sans perte | Perte max sans perte | Enfants / adultes perdus ou boursiers max | Remise max sans perte | Remise max pour 2 000 $ |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 637 $ | 1 908 $ | 1 908 $ | 0 % | 11,10 $ | 2 479 $ | 49 / 41 | 44 % | aucune (manque 120 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 637 $ | 1 900 $ | 1 900 $ | 0 % | 11,07 $ | 2 473 $ | 49 / 41 | 44 % | aucune (manque 131 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 637 $ | 1 894 $ | 1 894 $ | 0 % | 11,05 $ | 2 469 $ | 49 / 41 | 44 % | aucune (manque 138 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 504 $ | 1 850 $ | 1 850 $ | 0 % | 11,17 $ | 2 404 $ | 48 / 40 | 44 % | aucune (manque 194 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 637 $ | 1 843 $ | 1 843 $ | 0 % | 10,47 $ | 2 394 $ | 47 / 39 | 42 % | aucune (manque 205 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 504 $ | 1 842 $ | 1 842 $ | 0 % | 11,14 $ | 2 399 $ | 47 / 39 | 44 % | aucune (manque 205 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 504 $ | 1 838 $ | 1 838 $ | 0 % | 11,12 $ | 2 395 $ | 47 / 39 | 44 % | aucune (manque 212 $) |
| Idéal · Adultes séparés · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 637 $ | 1 835 $ | 1 835 $ | 0 % | 10,44 $ | 2 388 $ | 47 / 39 | 42 % | aucune (manque 215 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 637 $ | 1 829 $ | 1 829 $ | 0 % | 10,42 $ | 2 384 $ | 47 / 39 | 42 % | aucune (manque 222 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 404 $ | 1 817 $ | 1 817 $ | 0 % | 11,35 $ | 2 362 $ | 47 / 39 | 44 % | aucune (manque 237 $) |
| Idéal · Adultes mixtes · Enfants séparés · 50 / 50 · 30 % d’enfants | 5 404 $ | 1 809 $ | 1 809 $ | 0 % | 11,32 $ | 2 356 $ | 47 / 39 | 44 % | aucune (manque 248 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 5 404 $ | 1 805 $ | 1 805 $ | 0 % | 11,30 $ | 2 352 $ | 47 / 39 | 44 % | aucune (manque 255 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 446 $ | 1 792 $ | 1 552 $ | 13 % | 9,89 $ | 2 017 $ | 40 / 33 | 39 % | aucune (manque 583 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Europe · 45 % d’enfants | 5 472 $ | 1 789 $ | 1 789 $ | 0 % | 10,66 $ | 2 321 $ | 46 / 38 | 42 % | aucune (manque 274 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Europe · 45 % d’enfants | 5 472 $ | 1 789 $ | 1 789 $ | 0 % | 10,66 $ | 2 321 $ | 46 / 38 | 42 % | aucune (manque 274 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 504 $ | 1 785 $ | 1 785 $ | 0 % | 10,51 $ | 2 319 $ | 46 / 38 | 42 % | aucune (manque 280 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 446 $ | 1 784 $ | 1 544 $ | 12 % | 9,86 $ | 2 011 $ | 40 / 33 | 39 % | aucune (manque 593 $) |
| Idéal · Adultes séparés · Enfants mixtes · 50 / 50 · 45 % d’enfants | 5 472 $ | 1 779 $ | 1 779 $ | 0 % | 10,62 $ | 2 314 $ | 46 / 38 | 42 % | aucune (manque 287 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 50 / 50 · 45 % d’enfants | 5 472 $ | 1 779 $ | 1 779 $ | 0 % | 10,62 $ | 2 314 $ | 46 / 38 | 42 % | aucune (manque 287 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 446 $ | 1 779 $ | 1 539 $ | 12 % | 9,84 $ | 2 007 $ | 40 / 33 | 39 % | aucune (manque 601 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 504 $ | 1 777 $ | 1 777 $ | 0 % | 10,48 $ | 2 313 $ | 46 / 38 | 42 % | aucune (manque 291 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 5 472 $ | 1 773 $ | 1 773 $ | 0 % | 10,60 $ | 2 310 $ | 46 / 38 | 42 % | aucune (manque 295 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 5 472 $ | 1 773 $ | 1 773 $ | 0 % | 10,60 $ | 2 310 $ | 46 / 38 | 42 % | aucune (manque 295 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 504 $ | 1 772 $ | 1 772 $ | 0 % | 10,46 $ | 2 309 $ | 46 / 38 | 42 % | aucune (manque 298 $) |
| Idéal · Adultes séparés · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 404 $ | 1 752 $ | 1 752 $ | 0 % | 10,65 $ | 2 277 $ | 45 / 37 | 42 % | aucune (manque 322 $) |
| Idéal · Adultes séparés · Enfants séparés · 50 / 50 · 30 % d’enfants | 5 404 $ | 1 744 $ | 1 744 $ | 0 % | 10,62 $ | 2 271 $ | 45 / 37 | 42 % | aucune (manque 333 $) |
| Idéal · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 5 404 $ | 1 740 $ | 1 740 $ | 0 % | 10,61 $ | 2 268 $ | 45 / 37 | 42 % | aucune (manque 339 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 314 $ | 1 734 $ | 1 499 $ | 8 % | 9,92 $ | 1 948 $ | 38 / 32 | 39 % | aucune (manque 652 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 444 $ | 1 727 $ | 1 494 $ | 8 % | 9,34 $ | 1 942 $ | 38 / 32 | 38 % | aucune (manque 658 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 314 $ | 1 727 $ | 1 491 $ | 7 % | 9,89 $ | 1 942 $ | 38 / 32 | 39 % | aucune (manque 662 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Europe · 60 % d’enfants | 5 298 $ | 1 722 $ | 1 722 $ | 0 % | 10,82 $ | 2 235 $ | 44 / 37 | 42 % | aucune (manque 360 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Europe · 60 % d’enfants | 5 298 $ | 1 722 $ | 1 722 $ | 0 % | 10,82 $ | 2 235 $ | 44 / 37 | 42 % | aucune (manque 360 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 314 $ | 1 721 $ | 1 486 $ | 6 % | 9,86 $ | 1 937 $ | 38 / 32 | 39 % | aucune (manque 670 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 444 $ | 1 719 $ | 1 487 $ | 7 % | 9,32 $ | 1 937 $ | 38 / 32 | 38 % | aucune (manque 667 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 444 $ | 1 714 $ | 1 480 $ | 7 % | 9,30 $ | 1 930 $ | 38 / 32 | 38 % | aucune (manque 677 $) |
| Idéal · Adultes séparés · Enfants mixtes · 50 / 50 · 60 % d’enfants | 5 298 $ | 1 712 $ | 1 712 $ | 0 % | 10,78 $ | 2 228 $ | 44 / 37 | 42 % | aucune (manque 375 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 50 / 50 · 60 % d’enfants | 5 298 $ | 1 712 $ | 1 712 $ | 0 % | 10,78 $ | 2 228 $ | 44 / 37 | 42 % | aucune (manque 375 $) |
| Idéal · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 5 298 $ | 1 709 $ | 1 709 $ | 0 % | 10,76 $ | 2 225 $ | 44 / 37 | 42 % | aucune (manque 380 $) |
| Idéal · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 5 298 $ | 1 709 $ | 1 709 $ | 0 % | 10,76 $ | 2 225 $ | 44 / 37 | 42 % | aucune (manque 380 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 220 $ | 1 705 $ | 1 471 $ | 5 % | 10,07 $ | 1 912 $ | 38 / 31 | 39 % | aucune (manque 687 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 30 % d’enfants | 5 220 $ | 1 696 $ | 1 465 $ | 4 % | 10,04 $ | 1 907 $ | 38 / 31 | 39 % | aucune (manque 697 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 5 289 $ | 1 692 $ | 1 692 $ | 0 % | 10,56 $ | 2 196 $ | 43 / 36 | 42 % | aucune (manque 400 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 5 289 $ | 1 692 $ | 1 692 $ | 0 % | 10,56 $ | 2 196 $ | 43 / 36 | 42 % | aucune (manque 400 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 5 220 $ | 1 691 $ | 1 458 $ | 4 % | 10,02 $ | 1 902 $ | 38 / 31 | 39 % | aucune (manque 706 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 70 % Europe · 45 % d’enfants | 5 306 $ | 1 689 $ | 1 453 $ | 4 % | 9,52 $ | 1 886 $ | 37 / 31 | 38 % | aucune (manque 710 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 5 289 $ | 1 683 $ | 1 683 $ | 0 % | 10,53 $ | 2 190 $ | 43 / 36 | 41 % | aucune (manque 412 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 5 289 $ | 1 683 $ | 1 683 $ | 0 % | 10,53 $ | 2 190 $ | 43 / 36 | 41 % | aucune (manque 412 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 70 % Europe · 45 % d’enfants | 5 294 $ | 1 681 $ | 1 447 $ | 5 % | 9,49 $ | 1 879 $ | 37 / 31 | 38 % | aucune (manque 718 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 50 / 50 · 45 % d’enfants | 5 306 $ | 1 680 $ | 1 444 $ | 4 % | 9,49 $ | 1 879 $ | 37 / 31 | 38 % | aucune (manque 723 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 5 298 $ | 1 678 $ | 1 678 $ | 0 % | 10,37 $ | 2 178 $ | 43 / 36 | 41 % | aucune (manque 418 $) |
| Idéal · Adultes séparés · Enfants séparés · 70 % Europe · 60 % d’enfants | 5 298 $ | 1 678 $ | 1 678 $ | 0 % | 10,37 $ | 2 178 $ | 43 / 36 | 41 % | aucune (manque 418 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 5 298 $ | 1 678 $ | 1 678 $ | 0 % | 10,37 $ | 2 178 $ | 43 / 36 | 41 % | aucune (manque 418 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Europe · 60 % d’enfants | 5 298 $ | 1 678 $ | 1 678 $ | 0 % | 10,37 $ | 2 178 $ | 43 / 36 | 41 % | aucune (manque 418 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 5 289 $ | 1 677 $ | 1 677 $ | 0 % | 10,50 $ | 2 185 $ | 43 / 36 | 41 % | aucune (manque 421 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 5 289 $ | 1 677 $ | 1 677 $ | 0 % | 10,50 $ | 2 185 $ | 43 / 36 | 41 % | aucune (manque 421 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 5 306 $ | 1 674 $ | 1 438 $ | 4 % | 9,46 $ | 1 874 $ | 37 / 31 | 38 % | aucune (manque 732 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 317 $ | 1 673 $ | 1 430 $ | 4 % | 9,31 $ | 1 858 $ | 37 / 30 | 37 % | aucune (manque 741 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 50 / 50 · 45 % d’enfants | 5 294 $ | 1 672 $ | 1 438 $ | 4 % | 9,46 $ | 1 872 $ | 37 / 31 | 37 % | aucune (manque 731 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 285 $ | 1 669 $ | 1 374 $ | 8 % | 9,21 $ | 1 786 $ | 35 / 29 | 36 % | aucune (manque 813 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 5 298 $ | 1 668 $ | 1 668 $ | 0 % | 10,33 $ | 2 170 $ | 43 / 36 | 41 % | aucune (manque 432 $) |
| Idéal · Adultes séparés · Enfants séparés · 50 / 50 · 60 % d’enfants | 5 298 $ | 1 668 $ | 1 668 $ | 0 % | 10,33 $ | 2 170 $ | 43 / 36 | 41 % | aucune (manque 432 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 5 298 $ | 1 668 $ | 1 668 $ | 0 % | 10,33 $ | 2 170 $ | 43 / 36 | 41 % | aucune (manque 432 $) |
| Idéal · Adultes mixtes · Enfants séparés · 50 / 50 · 60 % d’enfants | 5 298 $ | 1 668 $ | 1 668 $ | 0 % | 10,33 $ | 2 170 $ | 43 / 36 | 41 % | aucune (manque 432 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 5 294 $ | 1 666 $ | 1 432 $ | 4 % | 9,43 $ | 1 867 $ | 37 / 31 | 37 % | aucune (manque 739 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 317 $ | 1 666 $ | 1 422 $ | 3 % | 9,28 $ | 1 851 $ | 37 / 30 | 37 % | aucune (manque 753 $) |
| Idéal · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 5 298 $ | 1 664 $ | 1 664 $ | 0 % | 10,32 $ | 2 167 $ | 43 / 36 | 41 % | aucune (manque 437 $) |
| Idéal · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 5 298 $ | 1 664 $ | 1 664 $ | 0 % | 10,32 $ | 2 167 $ | 43 / 36 | 41 % | aucune (manque 437 $) |
| Idéal · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 5 298 $ | 1 664 $ | 1 664 $ | 0 % | 10,32 $ | 2 167 $ | 43 / 36 | 41 % | aucune (manque 437 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 5 298 $ | 1 664 $ | 1 664 $ | 0 % | 10,32 $ | 2 167 $ | 43 / 36 | 41 % | aucune (manque 437 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 285 $ | 1 661 $ | 1 367 $ | 7 % | 9,18 $ | 1 780 $ | 35 / 29 | 36 % | aucune (manque 824 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 317 $ | 1 660 $ | 1 416 $ | 3 % | 9,26 $ | 1 848 $ | 36 / 30 | 37 % | aucune (manque 761 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 285 $ | 1 656 $ | 1 362 $ | 7 % | 9,16 $ | 1 776 $ | 35 / 29 | 36 % | aucune (manque 832 $) |
| Optimiste · Adultes séparés · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 229 $ | 1 650 $ | 1 412 $ | 2 % | 9,46 $ | 1 835 $ | 36 / 30 | 37 % | aucune (manque 765 $) |
| Optimiste · Adultes séparés · Enfants séparés · 50 / 50 · 30 % d’enfants | 5 229 $ | 1 642 $ | 1 404 $ | 2 % | 9,43 $ | 1 829 $ | 36 / 30 | 37 % | aucune (manque 776 $) |
| Optimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 5 229 $ | 1 637 $ | 1 400 $ | 2 % | 9,42 $ | 1 825 $ | 36 / 30 | 37 % | aucune (manque 783 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 70 % Europe · 60 % d’enfants | 5 142 $ | 1 630 $ | 1 374 $ | 3 % | 9,55 $ | 1 784 $ | 35 / 29 | 37 % | aucune (manque 813 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 70 % Europe · 60 % d’enfants | 5 138 $ | 1 627 $ | 1 375 $ | 3 % | 9,55 $ | 1 785 $ | 35 / 29 | 37 % | aucune (manque 812 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 172 $ | 1 626 $ | 1 340 $ | 4 % | 9,30 $ | 1 742 $ | 34 / 29 | 36 % | aucune (manque 857 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Europe · 45 % d’enfants | 5 139 $ | 1 621 $ | 1 621 $ | 0 % | 10,56 $ | 2 105 $ | 42 / 35 | 41 % | aucune (manque 492 $) |
| Idéal · Adultes séparés · Enfants séparés · 70 % Europe · 45 % d’enfants | 5 139 $ | 1 621 $ | 1 621 $ | 0 % | 10,55 $ | 2 104 $ | 42 / 35 | 41 % | aucune (manque 493 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 50 / 50 · 60 % d’enfants | 5 142 $ | 1 620 $ | 1 365 $ | 3 % | 9,51 $ | 1 776 $ | 35 / 29 | 37 % | aucune (manque 826 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 172 $ | 1 618 $ | 1 333 $ | 4 % | 9,27 $ | 1 736 $ | 34 / 28 | 36 % | aucune (manque 870 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 50 / 50 · 60 % d’enfants | 5 138 $ | 1 617 $ | 1 366 $ | 3 % | 9,52 $ | 1 779 $ | 35 / 29 | 37 % | aucune (manque 825 $) |
| Optimiste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 5 142 $ | 1 616 $ | 1 361 $ | 3 % | 9,49 $ | 1 773 $ | 35 / 29 | 37 % | aucune (manque 832 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 172 $ | 1 613 $ | 1 327 $ | 4 % | 9,25 $ | 1 732 $ | 34 / 28 | 36 % | aucune (manque 877 $) |
| Idéal · Adultes mixtes · Enfants séparés · 50 / 50 · 45 % d’enfants | 5 139 $ | 1 613 $ | 1 613 $ | 0 % | 10,53 $ | 2 098 $ | 41 / 34 | 41 % | aucune (manque 503 $) |
| Optimiste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 5 138 $ | 1 613 $ | 1 362 $ | 3 % | 9,50 $ | 1 776 $ | 35 / 29 | 37 % | aucune (manque 831 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 292 $ | 1 612 $ | 1 327 $ | 4 % | 8,75 $ | 1 724 $ | 34 / 28 | 35 % | aucune (manque 875 $) |
| Idéal · Adultes séparés · Enfants séparés · 50 / 50 · 45 % d’enfants | 5 139 $ | 1 612 $ | 1 612 $ | 0 % | 10,52 $ | 2 097 $ | 41 / 34 | 41 % | aucune (manque 504 $) |
| Idéal · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 5 139 $ | 1 607 $ | 1 607 $ | 0 % | 10,50 $ | 2 094 $ | 41 / 34 | 41 % | aucune (manque 512 $) |
| Idéal · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 5 139 $ | 1 607 $ | 1 607 $ | 0 % | 10,50 $ | 2 093 $ | 41 / 34 | 41 % | aucune (manque 513 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 292 $ | 1 605 $ | 1 319 $ | 4 % | 8,73 $ | 1 717 $ | 34 / 28 | 35 % | aucune (manque 887 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 292 $ | 1 599 $ | 1 315 $ | 3 % | 8,71 $ | 1 714 $ | 34 / 28 | 35 % | aucune (manque 894 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 073 $ | 1 593 $ | 1 307 $ | 3 % | 9,40 $ | 1 698 $ | 33 / 28 | 36 % | aucune (manque 901 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 5 123 $ | 1 592 $ | 1 366 $ | 2 % | 9,41 $ | 1 774 $ | 35 / 29 | 37 % | aucune (manque 823 $) |
| Optimiste · Adultes séparés · Enfants séparés · 70 % Europe · 60 % d’enfants | 5 148 $ | 1 590 $ | 1 331 $ | 3 % | 9,14 $ | 1 727 $ | 34 / 28 | 36 % | aucune (manque 869 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 60 % d’enfants | 5 148 $ | 1 590 $ | 1 336 $ | 2 % | 9,16 $ | 1 734 $ | 34 / 28 | 36 % | aucune (manque 863 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 5 146 $ | 1 590 $ | 1 332 $ | 2 % | 9,16 $ | 1 729 $ | 34 / 28 | 36 % | aucune (manque 867 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 5 118 $ | 1 588 $ | 1 354 $ | 1 % | 9,34 $ | 1 758 $ | 35 / 29 | 36 % | aucune (manque 839 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 5 140 $ | 1 586 $ | 1 329 $ | 2 % | 9,14 $ | 1 724 $ | 34 / 28 | 36 % | aucune (manque 871 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 50 / 50 · 30 % d’enfants | 5 073 $ | 1 586 $ | 1 300 $ | 3 % | 9,37 $ | 1 692 $ | 33 / 28 | 36 % | aucune (manque 911 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 5 123 $ | 1 585 $ | 1 358 $ | 2 % | 9,38 $ | 1 767 $ | 35 / 29 | 37 % | aucune (manque 835 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 60 % d’enfants | 5 148 $ | 1 581 $ | 1 326 $ | 2 % | 9,13 $ | 1 726 $ | 34 / 28 | 36 % | aucune (manque 877 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 5 073 $ | 1 580 $ | 1 295 $ | 2 % | 9,35 $ | 1 689 $ | 33 / 28 | 36 % | aucune (manque 919 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 5 146 $ | 1 580 $ | 1 322 $ | 2 % | 9,12 $ | 1 721 $ | 34 / 28 | 36 % | aucune (manque 882 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 5 118 $ | 1 580 $ | 1 346 $ | 1 % | 9,31 $ | 1 752 $ | 35 / 29 | 36 % | aucune (manque 850 $) |
| Optimiste · Adultes séparés · Enfants séparés · 50 / 50 · 60 % d’enfants | 5 148 $ | 1 580 $ | 1 321 $ | 2 % | 9,10 $ | 1 720 $ | 34 / 28 | 36 % | aucune (manque 884 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 5 123 $ | 1 578 $ | 1 351 $ | 2 % | 9,35 $ | 1 761 $ | 35 / 29 | 37 % | aucune (manque 845 $) |
| Optimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 5 146 $ | 1 578 $ | 1 320 $ | 2 % | 9,11 $ | 1 719 $ | 34 / 28 | 36 % | aucune (manque 885 $) |
| Optimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 5 148 $ | 1 577 $ | 1 317 $ | 2 % | 9,09 $ | 1 717 $ | 34 / 28 | 36 % | aucune (manque 890 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 5 148 $ | 1 576 $ | 1 322 $ | 1 % | 9,11 $ | 1 723 $ | 34 / 28 | 36 % | aucune (manque 883 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 5 140 $ | 1 576 $ | 1 319 $ | 2 % | 9,10 $ | 1 717 $ | 34 / 28 | 36 % | aucune (manque 887 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 70 % Europe · 45 % d’enfants | 5 154 $ | 1 575 $ | 1 291 $ | 3 % | 8,89 $ | 1 677 $ | 33 / 27 | 35 % | aucune (manque 919 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 5 118 $ | 1 575 $ | 1 342 $ | 1 % | 9,28 $ | 1 748 $ | 34 / 29 | 36 % | aucune (manque 859 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 70 % Europe · 45 % d’enfants | 5 153 $ | 1 572 $ | 1 281 $ | 3 % | 8,86 $ | 1 663 $ | 33 / 27 | 35 % | aucune (manque 933 $) |
| Optimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 5 140 $ | 1 572 $ | 1 316 $ | 1 % | 9,09 $ | 1 714 $ | 34 / 28 | 36 % | aucune (manque 891 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 50 / 50 · 45 % d’enfants | 5 154 $ | 1 566 $ | 1 284 $ | 3 % | 8,87 $ | 1 670 $ | 33 / 27 | 35 % | aucune (manque 932 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 50 / 50 · 45 % d’enfants | 5 153 $ | 1 564 $ | 1 272 $ | 2 % | 8,83 $ | 1 655 $ | 33 / 27 | 35 % | aucune (manque 947 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 5 154 $ | 1 559 $ | 1 278 $ | 3 % | 8,84 $ | 1 665 $ | 33 / 27 | 35 % | aucune (manque 942 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 5 170 $ | 1 559 $ | 1 273 $ | 2 % | 8,72 $ | 1 654 $ | 33 / 27 | 34 % | aucune (manque 946 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 5 153 $ | 1 557 $ | 1 266 $ | 2 % | 8,81 $ | 1 650 $ | 33 / 27 | 35 % | aucune (manque 958 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 5 170 $ | 1 552 $ | 1 264 $ | 2 % | 8,69 $ | 1 646 $ | 32 / 27 | 34 % | aucune (manque 958 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 5 170 $ | 1 547 $ | 1 259 $ | 2 % | 8,67 $ | 1 641 $ | 32 / 27 | 34 % | aucune (manque 966 $) |
| Réaliste · Adultes séparés · Enfants séparés · 70 % Europe · 30 % d’enfants | 5 088 $ | 1 538 $ | 1 243 $ | 1 % | 8,81 $ | 1 615 $ | 32 / 26 | 34 % | aucune (manque 984 $) |
| Optimiste · Adultes séparés · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 989 $ | 1 532 $ | 1 288 $ | 0 % | 9,31 $ | 1 673 $ | 33 / 27 | 36 % | aucune (manque 925 $) |
| Réaliste · Adultes séparés · Enfants séparés · 50 / 50 · 30 % d’enfants | 5 088 $ | 1 531 $ | 1 235 $ | 1 % | 8,79 $ | 1 607 $ | 32 / 26 | 34 % | aucune (manque 997 $) |
| Réaliste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 5 088 $ | 1 527 $ | 1 230 $ | 1 % | 8,77 $ | 1 604 $ | 32 / 26 | 34 % | aucune (manque 1 004 $) |
| Optimiste · Adultes séparés · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 989 $ | 1 525 $ | 1 282 $ | 0 % | 9,28 $ | 1 668 $ | 33 / 27 | 36 % | aucune (manque 934 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 976 $ | 1 524 $ | 1 291 $ | 1 % | 9,32 $ | 1 676 $ | 33 / 27 | 36 % | aucune (manque 921 $) |
| Optimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 989 $ | 1 519 $ | 1 276 $ | 0 % | 9,26 $ | 1 664 $ | 33 / 27 | 36 % | aucune (manque 944 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 976 $ | 1 516 $ | 1 284 $ | 1 % | 9,29 $ | 1 670 $ | 33 / 27 | 36 % | aucune (manque 932 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 70 % Europe · 60 % d’enfants | 4 989 $ | 1 514 $ | 1 214 $ | 1 % | 8,90 $ | 1 577 $ | 31 / 26 | 34 % | aucune (manque 1 020 $) |
| Optimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 976 $ | 1 510 $ | 1 277 $ | 1 % | 9,26 $ | 1 665 $ | 33 / 27 | 36 % | aucune (manque 942 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 70 % Europe · 60 % d’enfants | 4 981 $ | 1 508 $ | 1 230 $ | 1 % | 8,96 $ | 1 597 $ | 31 / 26 | 35 % | aucune (manque 998 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 50 / 50 · 60 % d’enfants | 4 989 $ | 1 504 $ | 1 205 $ | 1 % | 8,86 $ | 1 568 $ | 31 / 26 | 34 % | aucune (manque 1 034 $) |
| Réaliste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 4 989 $ | 1 499 $ | 1 201 $ | 1 % | 8,84 $ | 1 565 $ | 31 / 26 | 34 % | aucune (manque 1 042 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 50 / 50 · 60 % d’enfants | 4 981 $ | 1 498 $ | 1 222 $ | 1 % | 8,93 $ | 1 590 $ | 31 / 26 | 34 % | aucune (manque 1 013 $) |
| Réaliste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 4 981 $ | 1 494 $ | 1 219 $ | 1 % | 8,91 $ | 1 587 $ | 31 / 26 | 34 % | aucune (manque 1 018 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 4 980 $ | 1 483 $ | 1 192 $ | 1 % | 8,71 $ | 1 549 $ | 30 / 25 | 34 % | aucune (manque 1 048 $) |
| Réaliste · Adultes séparés · Enfants séparés · 70 % Europe · 60 % d’enfants | 5 003 $ | 1 482 $ | 1 182 $ | 0 % | 8,58 $ | 1 535 $ | 30 / 25 | 33 % | aucune (manque 1 061 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 4 976 $ | 1 480 $ | 1 188 $ | 1 % | 8,69 $ | 1 542 $ | 30 / 25 | 34 % | aucune (manque 1 055 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 4 997 $ | 1 478 $ | 1 168 $ | 1 % | 8,52 $ | 1 516 $ | 30 / 25 | 33 % | aucune (manque 1 080 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 4 980 $ | 1 475 $ | 1 186 $ | 1 % | 8,68 $ | 1 543 $ | 30 / 25 | 34 % | aucune (manque 1 059 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 70 % Europe · 60 % d’enfants | 4 988 $ | 1 473 $ | 1 172 $ | 1 % | 8,54 $ | 1 522 $ | 30 / 25 | 33 % | aucune (manque 1 074 $) |
| Réaliste · Adultes séparés · Enfants séparés · 50 / 50 · 60 % d’enfants | 5 003 $ | 1 473 $ | 1 175 $ | 0 % | 8,54 $ | 1 528 $ | 30 / 25 | 33 % | aucune (manque 1 073 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 4 976 $ | 1 472 $ | 1 180 $ | 1 % | 8,66 $ | 1 535 $ | 30 / 25 | 33 % | aucune (manque 1 067 $) |
| Réaliste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 5 003 $ | 1 468 $ | 1 170 $ | 0 % | 8,52 $ | 1 525 $ | 30 / 25 | 33 % | aucune (manque 1 081 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 4 980 $ | 1 468 $ | 1 179 $ | 1 % | 8,66 $ | 1 538 $ | 30 / 25 | 33 % | aucune (manque 1 070 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 4 997 $ | 1 467 $ | 1 159 $ | 1 % | 8,48 $ | 1 508 $ | 30 / 25 | 33 % | aucune (manque 1 095 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 4 984 $ | 1 466 $ | 1 171 $ | 1 % | 8,53 $ | 1 520 $ | 30 / 25 | 33 % | aucune (manque 1 076 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 4 976 $ | 1 466 $ | 1 173 $ | 1 % | 8,63 $ | 1 529 $ | 30 / 25 | 33 % | aucune (manque 1 078 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 50 / 50 · 60 % d’enfants | 4 988 $ | 1 462 $ | 1 164 $ | 1 % | 8,50 $ | 1 515 $ | 30 / 25 | 33 % | aucune (manque 1 088 $) |
| Réaliste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 4 997 $ | 1 462 $ | 1 155 $ | 1 % | 8,47 $ | 1 504 $ | 30 / 25 | 33 % | aucune (manque 1 101 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 015 $ | 1 460 $ | 1 086 $ | 2 % | 8,13 $ | 1 412 $ | 28 / 23 | 31 % | aucune (manque 1 188 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 4 988 $ | 1 458 $ | 1 160 $ | 1 % | 8,49 $ | 1 511 $ | 30 / 25 | 33 % | aucune (manque 1 095 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 4 984 $ | 1 455 $ | 1 161 $ | 1 % | 8,49 $ | 1 511 $ | 30 / 25 | 33 % | aucune (manque 1 092 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 015 $ | 1 454 $ | 1 080 $ | 1 % | 8,11 $ | 1 407 $ | 28 / 23 | 31 % | aucune (manque 1 198 $) |
| Réaliste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 4 984 $ | 1 452 $ | 1 156 $ | 0 % | 8,48 $ | 1 507 $ | 30 / 25 | 33 % | aucune (manque 1 099 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 015 $ | 1 447 $ | 1 075 $ | 1 % | 8,08 $ | 1 402 $ | 28 / 23 | 31 % | aucune (manque 1 206 $) |
| Réaliste · Adultes séparés · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 835 $ | 1 417 $ | 1 139 $ | 0 % | 8,69 $ | 1 480 $ | 29 / 24 | 33 % | aucune (manque 1 118 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 833 $ | 1 413 $ | 1 126 $ | 0 % | 8,65 $ | 1 462 $ | 29 / 24 | 33 % | aucune (manque 1 135 $) |
| Réaliste · Adultes séparés · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 835 $ | 1 409 $ | 1 132 $ | 0 % | 8,66 $ | 1 474 $ | 29 / 24 | 33 % | aucune (manque 1 130 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 833 $ | 1 405 $ | 1 118 $ | 0 % | 8,62 $ | 1 456 $ | 29 / 24 | 33 % | aucune (manque 1 148 $) |
| Réaliste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 835 $ | 1 403 $ | 1 127 $ | 0 % | 8,64 $ | 1 469 $ | 29 / 24 | 33 % | aucune (manque 1 138 $) |
| Réaliste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 833 $ | 1 400 $ | 1 114 $ | 0 % | 8,60 $ | 1 452 $ | 29 / 24 | 33 % | aucune (manque 1 154 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 4 870 $ | 1 395 $ | 1 034 $ | 1 % | 8,08 $ | 1 345 $ | 26 / 22 | 31 % | aucune (manque 1 256 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 70 % Europe · 30 % d’enfants | 5 005 $ | 1 389 $ | 1 024 $ | 1 % | 7,66 $ | 1 332 $ | 26 / 22 | 29 % | aucune (manque 1 270 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 4 870 $ | 1 387 $ | 1 029 $ | 1 % | 8,05 $ | 1 340 $ | 26 / 22 | 30 % | aucune (manque 1 266 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 50 / 50 · 30 % d’enfants | 5 005 $ | 1 384 $ | 1 018 $ | 1 % | 7,65 $ | 1 327 $ | 26 / 22 | 29 % | aucune (manque 1 280 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 4 870 $ | 1 381 $ | 1 023 $ | 1 % | 8,03 $ | 1 335 $ | 26 / 22 | 30 % | aucune (manque 1 275 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 30 % d’enfants | 4 798 $ | 1 380 $ | 1 026 $ | 1 % | 8,22 $ | 1 334 $ | 26 / 22 | 31 % | aucune (manque 1 266 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 30 % d’enfants | 5 005 $ | 1 378 $ | 1 012 $ | 1 % | 7,62 $ | 1 321 $ | 26 / 22 | 29 % | aucune (manque 1 289 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 30 % d’enfants | 4 798 $ | 1 374 $ | 1 019 $ | 1 % | 8,20 $ | 1 328 $ | 26 / 22 | 31 % | aucune (manque 1 278 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 4 798 $ | 1 368 $ | 1 014 $ | 0 % | 8,18 $ | 1 323 $ | 26 / 22 | 31 % | aucune (manque 1 286 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 30 % d’enfants | 4 870 $ | 1 332 $ | 976 $ | 0 % | 7,64 $ | 1 269 $ | 25 / 21 | 29 % | aucune (manque 1 331 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 70 % Europe · 45 % d’enfants | 4 828 $ | 1 327 $ | 933 $ | 0 % | 7,54 $ | 1 212 $ | 24 / 20 | 28 % | aucune (manque 1 384 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 30 % d’enfants | 4 870 $ | 1 325 $ | 971 $ | 0 % | 7,61 $ | 1 265 $ | 25 / 21 | 29 % | aucune (manque 1 339 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 70 % Europe · 45 % d’enfants | 4 825 $ | 1 323 $ | 934 $ | 1 % | 7,55 $ | 1 212 $ | 24 / 20 | 28 % | aucune (manque 1 383 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 30 % d’enfants | 4 870 $ | 1 320 $ | 966 $ | 0 % | 7,59 $ | 1 259 $ | 25 / 20 | 29 % | aucune (manque 1 349 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Europe · 30 % d’enfants | 4 795 $ | 1 318 $ | 955 $ | 0 % | 7,70 $ | 1 241 $ | 24 / 20 | 29 % | aucune (manque 1 358 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 50 / 50 · 45 % d’enfants | 4 828 $ | 1 318 $ | 926 $ | 0 % | 7,51 $ | 1 204 $ | 24 / 20 | 28 % | aucune (manque 1 398 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 50 / 50 · 45 % d’enfants | 4 825 $ | 1 314 $ | 927 $ | 1 % | 7,53 $ | 1 205 $ | 24 / 20 | 28 % | aucune (manque 1 396 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 4 828 $ | 1 312 $ | 919 $ | 0 % | 7,48 $ | 1 199 $ | 23 / 19 | 28 % | aucune (manque 1 408 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 50 / 50 · 30 % d’enfants | 4 795 $ | 1 310 $ | 950 $ | 0 % | 7,67 $ | 1 237 $ | 24 / 20 | 29 % | aucune (manque 1 368 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 45 % d’enfants | 4 825 $ | 1 307 $ | 919 $ | 1 % | 7,50 $ | 1 198 $ | 23 / 19 | 28 % | aucune (manque 1 410 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 30 % d’enfants | 4 795 $ | 1 305 $ | 944 $ | 0 % | 7,64 $ | 1 231 $ | 24 / 20 | 28 % | aucune (manque 1 378 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 70 % Europe · 60 % d’enfants | 4 702 $ | 1 295 $ | 917 $ | 0 % | 7,70 $ | 1 191 $ | 23 / 19 | 28 % | aucune (manque 1 406 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 70 % Europe · 60 % d’enfants | 4 698 $ | 1 290 $ | 921 $ | 0 % | 7,70 $ | 1 196 $ | 23 / 19 | 28 % | aucune (manque 1 400 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 50 / 50 · 60 % d’enfants | 4 702 $ | 1 284 $ | 908 $ | 0 % | 7,66 $ | 1 181 $ | 23 / 19 | 28 % | aucune (manque 1 422 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 50 / 50 · 60 % d’enfants | 4 698 $ | 1 282 $ | 914 $ | 0 % | 7,67 $ | 1 189 $ | 23 / 19 | 28 % | aucune (manque 1 414 $) |
| Pessimiste · Adultes séparés · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 4 702 $ | 1 280 $ | 903 $ | 0 % | 7,65 $ | 1 177 $ | 23 / 19 | 28 % | aucune (manque 1 430 $) |
| Pessimiste · Adultes mixtes · Enfants mixtes · 70 % Amérique du Nord · 60 % d’enfants | 4 698 $ | 1 277 $ | 909 $ | 0 % | 7,66 $ | 1 185 $ | 23 / 19 | 28 % | aucune (manque 1 421 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 60 % d’enfants | 4 708 $ | 1 254 $ | 870 $ | 0 % | 7,37 $ | 1 130 $ | 22 / 18 | 27 % | aucune (manque 1 468 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 4 704 $ | 1 251 $ | 862 $ | 0 % | 7,34 $ | 1 120 $ | 22 / 18 | 27 % | aucune (manque 1 477 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 60 % d’enfants | 4 702 $ | 1 247 $ | 871 $ | 0 % | 7,38 $ | 1 131 $ | 22 / 18 | 27 % | aucune (manque 1 467 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Europe · 60 % d’enfants | 4 701 $ | 1 247 $ | 863 $ | 0 % | 7,35 $ | 1 120 $ | 22 / 18 | 27 % | aucune (manque 1 477 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 60 % d’enfants | 4 708 $ | 1 245 $ | 862 $ | 0 % | 7,34 $ | 1 122 $ | 22 / 18 | 27 % | aucune (manque 1 481 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 4 704 $ | 1 241 $ | 854 $ | 0 % | 7,31 $ | 1 112 $ | 22 / 18 | 26 % | aucune (manque 1 492 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 4 708 $ | 1 239 $ | 858 $ | 0 % | 7,32 $ | 1 119 $ | 22 / 18 | 27 % | aucune (manque 1 489 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 60 % d’enfants | 4 702 $ | 1 238 $ | 861 $ | 0 % | 7,34 $ | 1 122 $ | 22 / 18 | 27 % | aucune (manque 1 483 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 50 / 50 · 60 % d’enfants | 4 701 $ | 1 238 $ | 854 $ | 0 % | 7,31 $ | 1 111 $ | 22 / 18 | 27 % | aucune (manque 1 492 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 4 704 $ | 1 237 $ | 850 $ | 0 % | 7,30 $ | 1 108 $ | 22 / 18 | 26 % | aucune (manque 1 499 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 60 % d’enfants | 4 702 $ | 1 234 $ | 856 $ | 0 % | 7,33 $ | 1 117 $ | 22 / 18 | 27 % | aucune (manque 1 491 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 60 % d’enfants | 4 701 $ | 1 233 $ | 850 $ | 0 % | 7,30 $ | 1 108 $ | 22 / 18 | 26 % | aucune (manque 1 499 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 4 651 $ | 1 232 $ | 847 $ | 0 % | 7,35 $ | 1 100 $ | 21 / 18 | 27 % | aucune (manque 1 497 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Europe · 45 % d’enfants | 4 648 $ | 1 228 $ | 867 $ | 0 % | 7,41 $ | 1 126 $ | 22 / 18 | 27 % | aucune (manque 1 472 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 4 651 $ | 1 225 $ | 841 $ | 0 % | 7,32 $ | 1 093 $ | 21 / 18 | 26 % | aucune (manque 1 509 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 50 / 50 · 45 % d’enfants | 4 648 $ | 1 221 $ | 860 $ | 0 % | 7,39 $ | 1 119 $ | 22 / 18 | 27 % | aucune (manque 1 483 $) |
| Pessimiste · Adultes mixtes · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 4 651 $ | 1 218 $ | 833 $ | 0 % | 7,29 $ | 1 086 $ | 21 / 18 | 26 % | aucune (manque 1 522 $) |
| Pessimiste · Adultes séparés · Enfants séparés dès 10 ans · 70 % Amérique du Nord · 45 % d’enfants | 4 648 $ | 1 213 $ | 854 $ | 0 % | 7,35 $ | 1 113 $ | 22 / 18 | 27 % | aucune (manque 1 495 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 536 $ | 1 184 $ | 814 $ | 0 % | 7,35 $ | 1 057 $ | 21 / 17 | 26 % | aucune (manque 1 539 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Europe · 45 % d’enfants | 4 525 $ | 1 181 $ | 811 $ | 0 % | 7,35 $ | 1 055 $ | 21 / 17 | 26 % | aucune (manque 1 545 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 536 $ | 1 176 $ | 807 $ | 0 % | 7,31 $ | 1 050 $ | 21 / 17 | 26 % | aucune (manque 1 553 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 50 / 50 · 45 % d’enfants | 4 525 $ | 1 173 $ | 808 $ | 0 % | 7,34 $ | 1 052 $ | 21 / 17 | 26 % | aucune (manque 1 551 $) |
| Pessimiste · Adultes séparés · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 536 $ | 1 170 $ | 801 $ | 0 % | 7,29 $ | 1 044 $ | 20 / 17 | 26 % | aucune (manque 1 565 $) |
| Pessimiste · Adultes mixtes · Enfants séparés · 70 % Amérique du Nord · 45 % d’enfants | 4 525 $ | 1 167 $ | 800 $ | 0 % | 7,30 $ | 1 044 $ | 20 / 17 | 26 % | aucune (manque 1 564 $) |
