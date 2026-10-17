# Simulation économique avant fixation des prix publics — 17/10/2026

Demande du directeur : avant d'afficher les prix sur le site public, calculer avec
des scénarios réalistes combien l'académie encaisse chaque mois avec 100 élèves,
ce que coûtent les services et les paiements, et combien elle peut payer ses
enseignants en gardant une marge. **Tous** les scénarios sont testés.

L'application ne gère pas l'argent : ce modèle est un outil de décision, hors de
l'application, dans `tool/simulation/`.

## Ce qui est fixé

| Point | Valeur | Source |
| :--- | :--- | :--- |
| Mensualité | enfant 50 $, adulte 60 $ | directeur, 17/10 |
| Remise famille | 1re et 2e personne : 0 ; 3e : 5 $ ; chaque personne dès la 4e : 7 $ | directeur, 17/10 |
| Rythme | enfant 1 h × 3 par semaine, adulte 1 h 30 × 3 par semaine (13 séances par mois) | directeur, 17/10 |
| Classes | 5 enfants (parfois 4), 6 adultes (parfois 5) ; un enseignant pour deux classes | directeur, 17/10 |
| Tranches d'âge | 6-9, 10-13, 14-17, 18+ | `af_l2_08` |
| Enseignant | 4 $ / h (référence, configurable), plafond 7 $ / h ; même sexe que la classe séparée | `07` §26, `0082` |
| Objectif | 2 000 $ net par mois, après administration et impôt | `07` §27 |
| Familles | Europe et Amérique du Nord | directeur, 17/10 |
| Administration | 5 personnes à 300 $ par mois (1 500 $), pour le calcul | directeur, 17/10 |
| Structure | société enregistrée au Royaume-Uni ; impôt sur les bénéfices seulement ; prix publiés hors taxes, chaque famille ajoute les siennes | directeur, 17/10 |
| Impôt sur les sociétés | 19 % jusqu'à 50 000 £ de bénéfice annuel, 25 % au-delà de 250 000 £, allègement dégressif entre les deux (barème 2026-27) | HMRC |
| Cartes | Stripe Royaume-Uni : 1,5 % carte britannique, 2,5 % carte européenne, 3,25 % carte américaine ou canadienne, + 20 p, + 2 % de conversion dollar → livre | Stripe |

## Les 216 scénarios

Chaque dimension est croisée avec toutes les autres :

- **Comportement** (4) : idéal, optimiste, réaliste, pessimiste. Ce choix fixe la
  part de familles qui paient en avance, à l'heure, en retard ou jamais, ainsi que
  la part d'élèves occupés (plus d'absences) et la part d'élèves qui se plaignent
  (plus de départs).
- **Mixité des adultes** (2) : séparés, mixtes.
- **Mixité des enfants** (3) : mixtes, séparés dès 10 ans, séparés.
- **Origine des familles** (3) : 70 % Europe, 50/50, 70 % Amérique du Nord.
- **Part d'enfants** (3) : 30 %, 45 %, 60 %.

Chaque scénario rejoue 300 fois douze mois. On y trouve les paiements, les
retards, les impayés et la suspension après deux mois. On y trouve aussi les
absences, les séances annulées, les plaintes, les départs et les demandes de
changement de classe ou de créneau (2 % des élèves par mois ; sans place libre
dans une autre classe de leur âge, la demande est refusée et 3 sur 10 partent).
Une place libérée est reprise un mois plus tard.

Modèle v2 (17/10, soir) : administration, impôt britannique et grille Stripe
Royaume-Uni ajoutés ; « et si… » sur les impayés, les élèves perdus et
l'instabilité ; marge de manœuvre de chaque scénario.

Rapport complet : [`simulation/RAPPORT-216-SCENARIOS.md`](simulation/RAPPORT-216-SCENARIOS.md).
Tableau interactif : `tool/simulation/simulateur.html`, publié en artifact.

```
node --test tool/simulation/modele_academie.test.mjs     # 18 tests
node tool/simulation/simuler.mjs --sortie docs/current/simulation/RAPPORT-216-SCENARIOS.md   # ~2 min
```

## Résultats (mois type, médiane, modèle v2)

Enseignants à 4 $ / h, administration 1 500 $, impôt compris.

| | Pire | Médian | Meilleur |
| :--- | ---: | ---: | ---: |
| Encaissé | 4 525 $ | 5 139 $ | 5 637 $ |
| Impôt sur les sociétés | 274 $ | 370 $ | 447 $ |
| **Net, enseignants à 4 $ / h** | **1 167 $** | **1 578 $** | **1 908 $** |
| Net, enseignants à 7 $ / h | 441 $ | 803 $ | 1 102 $ |
| Taux enseignant max pour ne pas perdre d'argent, 9 mois sur 10 | 7,29 $ | 9,14 $ | 11,35 $ |
| Taux enseignant max pour garder 2 000 $, 9 mois sur 10 | impossible | 1,35 $ | 3,65 $ |
| Classes / enseignants | 17 / 9 | 20 / 10 | 21 / 11 |

**Avec l'administration et l'impôt, l'objectif de 2 000 $ net n'est plus tenu
9 mois sur 10 dans aucun des 216 scénarios** aux prix de 50 $ et 60 $, même
quand toutes les familles paient (idéal : 1 779 $). L'académie ne perd
d'argent dans aucun scénario.

Mois type du scénario réaliste : 5 154 $ encaissés, moins 263 $ de frais de
carte, 82 $ de LiveKit, 66 $ d'autres services, 1 500 $ d'administration,
1 309 $ d'enseignants (319 h) et 367 $ d'impôt : il reste 1 566 $.

## Ce qu'on peut se permettre

Valeurs prudentes (tenues 9 mois sur 10), enseignants à 4 $ / h, prix 50 $ et
60 $. Une bourse complète coûte autant qu'un élève perdu dont la place reste
vide ; deux demi-bourses en valent une. La remise s'applique à toutes les
mensualités ; elle donne le prix plancher.

| Comportement | Perte max avant de perdre de l'argent | Soit enfants ou adultes perdus ou boursiers | Remise max sur tous | Prix plancher enfant / adulte | Pour garder 2 000 $ |
| :--- | ---: | ---: | ---: | ---: | :--- |
| Idéal | 2 314 $ | 46 ou 38 | 42 % | 29 $ / 35 $ | manque 287 $ : aucune bourse, aucune remise |
| Optimiste | 1 879 $ | 37 ou 31 | 37 % | 32 $ / 38 $ | manque 723 $ |
| Réaliste | 1 670 $ | 33 ou 27 | 34 % | 33 $ / 40 $ | manque 932 $ |
| Pessimiste | 1 204 $ | 24 ou 20 | 27 % | 37 $ / 44 $ | manque 1 398 $ |

Le rapport donne ces colonnes pour chacun des 216 scénarios.

## Et si…

Scénario réaliste, un seul levier à la fois (tables complètes dans le rapport).

- **Des familles ne paient pas.** Chaque tranche de 5 % de familles qui ne
  paient pas retire environ 200 $ de net par mois. À 40 %, il reste 75 $ ; à
  50 %, l'académie perd 413 $ par mois.
- **Des familles paient en retard.** Sur l'année, cela ne coûte presque rien.
  Mais la caisse se vide : il manque environ 1 050 $ en fin de mois quand
  20 % des familles paient en retard, et environ 3 200 $ quand 60 % le font. Il
  faut une réserve au moins de ce montant.
- **On perd des élèves.** Sans regrouper les classes, chaque enfant perdu coûte
  environ 33 $ de net par mois et chaque adulte environ 43 $. Avec 30 adultes
  perdus, il reste 317 $. Refaire les classes avec ceux qui restent en limite
  le coût (636 $ au lieu de 317 $).
- **Ça bouge trop.** En régime normal, il y a 3 départs, 2 changements et
  14 h d'administration par mois. En régime très agité (départs × 3, 10 %
  demandent à changer, place reprise en 2 mois), il reste 80 élèves et 953 $.
  Si personne ne remplace les départs, il reste 78 élèves et 901 $ au bout de
  l'année.

## Ce qui pèse vraiment

1. **Le comportement de paiement est le premier facteur.** Entre idéal et
   pessimiste, l'écart est de 443 $ net par mois en moyenne.
2. **Séparer les enfants coûte des élèves sans classe.** Avec des classes
   d'enfants séparées, en moyenne 4 élèves (jusqu'à 7) n'entrent dans aucune
   classe de 4 ou 5, et ne paient pas. Séparer dès 10 ans en laisse 2,3. Les
   classes mixtes n'en laissent aucun. Séparer les adultes ne coûte presque rien,
   20 $ par mois.
3. **L'origine des familles change peu** : 14 $ par mois entre 70 % Europe et
   70 % Amérique du Nord. Les frais de carte pèsent environ 5 % de l'encaissé
   quelle que soit l'origine. Facturer en dollars sur un compte en livres coûte à
   lui seul 2 %.
4. **Une classe pleine rapporte un quart de plus par heure.** Elle rapporte
   19,23 $ par heure, contre 15,38 $ à 4 enfants ou à 5 adultes.

## Quel prix publier

Le scénario de référence est le suivant : comportement réaliste, adultes
séparés, enfants mixtes, 50/50 Europe/Amérique du Nord, 45 % d'enfants,
enseignants à 4 $ / h. Le tableau donne le net médian par mois, après
administration et impôt, puis la part des mois qui atteignent 2 000 $.

| Enfant ↓ / Adulte → | 50 $ | 55 $ | 60 $ | 65 $ | 70 $ |
| --- | ---: | ---: | ---: | ---: | ---: |
| **40 $** | 843 $ · 0 % | 1 041 $ · 0 % | 1 241 $ · 0 % | 1 441 $ · 1 % | 1 641 $ · 6 % |
| **45 $** | 1 006 $ · 0 % | 1 205 $ · 0 % | 1 403 $ · 0 % | 1 602 $ · 4 % | 1 803 $ · 20 % |
| **50 $** | 1 170 $ · 0 % | 1 367 $ · 0 % | **1 566 $ · 3 %** | 1 765 $ · 16 % | 1 964 $ · 44 % |
| **55 $** | 1 331 $ · 0 % | 1 531 $ · 2 % | 1 730 $ · 13 % | 1 927 $ · 39 % | 2 127 $ · 70 % |
| **60 $** | 1 494 $ · 1 % | 1 692 $ · 10 % | 1 894 $ · 33 % | 2 091 $ · 65 % | 2 289 $ · 87 % |

Chaque dollar de plus sur l'enfant rapporte environ 33 $ net par mois. Chaque
dollar de plus sur l'adulte en rapporte environ 40 $. Pour atteindre 2 000 $
plus d'un mois sur deux, il faut au moins 55 $ et 70 $, ou 60 $ et 65 $.

## Population de test sur le STAGING

Les mêmes 100 élèves existent comme profils réels sur le projet STAGING
(`xldmmlrnxyabdtvxqbyy`, jamais la production). Il y a 67 familles sans compte
tuteur, 20 classes, 10 enseignants et 4 personnes en administration.

- Chaque élève a sa tranche d'âge, son niveau déclaré, son objectif et sa langue.
  La langue est le français pour les familles européennes, l'anglais pour les
  familles d'Amérique du Nord et du Royaume-Uni.
- La date d'accès payé suit le profil de paiement de la famille. Les familles en
  retard lourd ou défaillantes apparaissent donc comme comptes échus côté
  administration.
- Les comptes n'ont pas de mot de passe. Les adresses sont en `@sim.rewayah.invalid`.
  Les identifiants commencent par `e51` (élèves), `e52` (enseignants),
  `e53` (administration), `e54` (familles) et `e55` (classes).
- Générateur : `node tool/simulation/generer_population_staging.mjs`. Il écrit les
  étapes `supabase/seed/staging_population_test/NN_*.sql`, le retrait
  `supabase/seed/staging_population_test_nettoyage.sql` et les personas
  `tool/simulation/population_staging.json` (paiement, disponibilité, plaintes).
- Chaque étape fait quelques kilo-octets au plus. Au-delà, l'outil MCP
  d'application dépasse son délai de 60 s sans que la requête n'atteigne la base.
  Les étapes n'emploient pas de table temporaire : un `DROP` fait demander une
  confirmation à l'outil.
- Appliqué sur le STAGING le 17/10, puis vérifié par lecture : 100 élèves avec
  leur fiche, 20 classes, 60 créneaux, 100 inscriptions, 240 séances générées.
  Aucun enseignant ni élève dans une classe de l'autre sexe. Les accès de
  25 élèves sont échus, ceux des familles en retard lourd ou défaillantes.

**Défaut trouvé en passant.** Les 5 comptes de test `rewayahacademy+…` portent
les matricules `RA-26-9001` à `9005`, qui ne sont pas réservés dans
`private.person_registrations`. Le tirage au hasard d'un matricule peut donc
retomber sur l'un d'eux, et l'inscription échoue alors sur
`profiles_immutable_id_unique`. C'est arrivé une fois pendant ce chargement
(`RA-26-9004`). Correctif à prévoir : réserver ces 5 matricules dans le registre.

## Ce que le modèle ne compte pas encore

- **TVA.** Prix publiés hors taxes : la TVA s'ajoute au prix et ne change pas
  le bénéfice. À vérifier avec un comptable : une société britannique qui vend
  des cours en ligne à des particuliers de l'Union européenne peut devoir
  déclarer la TVA du pays de chaque famille dès le premier euro (guichet OSS
  hors Union), même sous le seuil britannique de 90 000 £.
- Comptable et frais Companies House (souvent 50 à 150 £ par mois).
- Sauvegarde PITR Supabase (~100 $), comptes Apple (99 $ / an) et Google Play (25 $).
- Les fratries réparties dans des classes différentes (R4) : le modèle classe par
  tranche d'âge sans les séparer.
- Le cours de la livre (1 £ = 1,33 $) ne sert qu'aux seuils de l'impôt et aux 20 p
  de Stripe.
