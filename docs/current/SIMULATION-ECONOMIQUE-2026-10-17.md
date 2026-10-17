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
| Objectif | 2 000 $ net par mois | `07` §27 |
| Familles | Europe et Amérique du Nord | directeur, 17/10 |

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
absences, les séances annulées, les plaintes et les départs. Une place libérée
est reprise un mois plus tard.

Rapport complet : [`simulation/RAPPORT-216-SCENARIOS.md`](simulation/RAPPORT-216-SCENARIOS.md).
Tableau interactif : `tool/simulation/simulateur.html`, publié en artifact.

```
node --test tool/simulation/modele_academie.test.mjs     # 13 tests
node tool/simulation/simuler.mjs --sortie docs/current/simulation/RAPPORT-216-SCENARIOS.md   # ~70 s
```

## Résultats (mois type, médiane)

| | Pire | Médian | Meilleur |
| :--- | ---: | ---: | ---: |
| Encaissé | 4 550 $ | 5 179 $ | 5 637 $ |
| Résultat, enseignants à 4 $ / h | 2 969 $ | 3 506 $ | 3 883 $ |
| Résultat, enseignants à 7 $ / h | 2 074 $ | 2 551 $ | 2 889 $ |
| Taux enseignant max pour 30 % de marge, 9 mois sur 10 | 8,13 $ | 9,43 $ | 11,04 $ |
| Classes / enseignants | 17 / 9 | 20 / 10 | 21 / 11 |

**Avant taxes et avant paie de l'administration**, l'objectif de 2 000 $ est
atteint dans les 216 scénarios, même au plafond de 7 $ / h.

## Ce qui pèse vraiment

1. **Le comportement de paiement est le premier facteur.** Entre idéal et
   pessimiste, l'écart est de 510 $ par mois en moyenne.
2. **Séparer les enfants coûte des élèves sans classe.** Avec des classes
   d'enfants séparées, en moyenne 4 élèves (jusqu'à 7) n'entrent dans aucune
   classe de 4 ou 5, et ne paient pas. Séparer dès 10 ans en laisse 2,3. Les
   classes mixtes n'en laissent aucun. Séparer les adultes ne coûte presque rien,
   27 $ par mois.
3. **L'origine des familles change peu** : 32 $ par mois entre 70 % Europe et
   70 % Amérique du Nord. Les frais de carte pèsent environ 4,5 % de l'encaissé
   quelle que soit l'origine. Facturer en dollars sur un compte en euros coûte à
   lui seul 2 %.
4. **Une classe pleine rapporte un quart de plus par heure.** Elle rapporte
   19,23 $ par heure, contre 15,38 $ à 4 enfants ou à 5 adultes.

## Quel prix publier

Le scénario de référence est le suivant : comportement réaliste, adultes séparés,
enfants mixtes, 50/50 Europe/Amérique du Nord, 45 % d'enfants, enseignants à
4 $ / h. Le tableau donne le résultat médian par mois.

| Enfant ↓ / Adulte → | 50 $ | 55 $ | 60 $ | 65 $ | 70 $ |
| --- | ---: | ---: | ---: | ---: | ---: |
| **40 $** | 2 602 $ | 2 849 $ | 3 100 $ | 3 348 $ | 3 597 $ |
| **45 $** | 2 808 $ | 3 056 $ | 3 303 $ | 3 554 $ | 3 802 $ |
| **50 $** | 3 014 $ | 3 261 $ | **3 509 $** | 3 758 $ | 4 007 $ |
| **55 $** | 3 216 $ | 3 468 $ | 3 715 $ | 3 963 $ | 4 212 $ |
| **60 $** | 3 420 $ | 3 671 $ | 3 923 $ | 4 169 $ | 4 418 $ |

Chaque dollar de plus sur l'enfant rapporte environ 41 $ par mois. Chaque dollar
de plus sur l'adulte en rapporte environ 50 $.

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

- **Taxes, TVA, cotisations** : 0 par défaut, structure juridique non connue. Un
  prélèvement de 20 % sur l'encaissé retirerait environ 1 000 $ par mois.
- **Paie de l'équipe d'administration** (3 à 4 personnes) : 0 par défaut.
- Sauvegarde PITR Supabase (~100 $), comptes Apple (99 $ / an) et Google Play (25 $).
- Les fratries réparties dans des classes différentes (R4) : le modèle classe par
  tranche d'âge sans les séparer.

Les deux curseurs « Taxes » et « Équipe d'administration » du tableau interactif
les ajoutent dès qu'on les connaît.
