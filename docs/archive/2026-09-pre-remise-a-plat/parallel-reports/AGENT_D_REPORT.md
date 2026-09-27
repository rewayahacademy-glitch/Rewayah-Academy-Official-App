# AGENT_D_REPORT — `ENS-06` Disponibilités et matching

Agent D, 20 septembre 2026. Périmètre : `lib/features/creneaux/**`,
`test/features/creneaux_test.dart`, `docs/parallel-reports/*_D.*`.

---

## 1. Ce qui a été construit

`ENS-06` **existait** et était le plus avancé du rôle Enseignant : un écran, deux
vues locales, onglets sur mobile uniquement, tri par ancienneté, concurrence
tranchée en base, plafond respecté. Ce lot n'a donc pas construit l'écran : il a
**bouché ses trous d'états** et **fermé la boucle de concurrence**.

L'API publique est **inchangée** :
`class CreneauxPage extends StatelessWidget` / `const CreneauxPage({super.key})`.
L'Agent Z n'a rien à rebrancher.

### Les cinq défauts corrigés

| # | Défaut mesuré avant | Ce qui est livré |
| :--- | :--- | :--- |
| 1 | **Un refus de concurrence laissait la carte à l'écran**, bouton actif : les invalidations ne vivaient que dans le chemin de succès. Un second tap redonnait la même erreur. | Le feed est relu dans les **deux** chemins (`finally`). La ligne de l'élève pris disparaît, rien n'est bricolé en mémoire. |
| 2 | **Aucun état `loading` ni `error` sur le feed.** `hasError` n'était jamais lu : une lecture en échec était indiscernable d'une file vide, et n'affichait même pas l'`EmptyState`. | `Skeleton.carteEleve` pendant la lecture, `EmptyState` + « Réessayer » en échec, `EmptyState` sans bouton quand la file est vide. |
| 3 | **Aucun état `offline`.** `horsLigneProvider` n'était lu par aucun écran de la zone. Le CTA « Prendre » et les cases de la grille restaient pressables et échouaient **après** le geste. | Hors ligne : le CTA n'est **pas rendu**, la grille devient inerte (`enCours`), et **les deux le disent**. La file et les heures restent consultables. |
| 4 | **`'Europe/Paris'` codé en dur** dans la grille : un enseignant de Conakry lisait ses heures en heure de Paris, puis les voyait changer. | Le septième repli est **supprimé** : aucune heure n'est affichée avant que `monFuseauProvider` ait répondu. Mesuré. |
| 5 | **Aucun état de sauvegarde, aucun conflit visible.** `enCours` figeait la grille entière sans dire quelle case passait ; une case portant un élève était indiscernable d'une case libre. | `LocalFeedback` nomme la case enregistrée ou retirée. Les heures engagées sont énumérées en registre `inkWarning`, et un retrait sur une heure engagée dit ce qu'il ne fait pas. |

### Deux changements de fond, en plus des états

- **le plafond se lit par `valeurRegleProvider`**, comme le contrat le demande,
  et non plus par `reglesProfilProvider` filtré à la main. Le contrat le dit :
  `valeurRegleProvider` passe par `regle_effective()`, la vue non ;
- **aucun bouton « Prendre » n'est rendu avant que le plafond soit connu.** La
  gate de chargement du panneau exige `feed.hasValue && affectations.hasValue &&
  plafondLu.hasValue`. Sans cela, un enseignant au plafond voyait un bouton
  apparaître puis disparaître.

### Le refus de la base, nommé plutôt que recopié

`_message()` découpait la phrase Postgres sur le premier `': '` et l'affichait :
un libellé d'interface dépendait d'une chaîne SQL non traduite. Il y a
maintenant un `enum _Refus` privé, une reconnaissance par sous-chaîne, cinq clés
slang, et un **repli** qui recopie le message brut pour tout refus non prévu.

Les cinq phrases ont été **relues dans la migration `0005`** (lignes 1030, 1044,
1056, 1063, 1075 et 214) plutôt que devinées.

`ponytail:` c'est un pis-aller. Plafond nommé : une reformulation d'un
`raise exception` en base fait retomber l'écran sur le repli brut, et aucun test
SQL ne relie les deux. Chemin de reprise : `CONTRACT_REQUEST_D.md` §1.

---

## 2. Fichiers touchés — la liste exhaustive

| Fichier | Nature |
| :--- | :--- |
| `lib/features/creneaux/creneaux_page.dart` | modifié (565 → 788 lignes) |
| `test/features/creneaux_test.dart` | modifié (379 → 675 lignes, 8 → 25 tests) |
| `docs/parallel-reports/i18n_D.json` | créé (20 clés) |
| `docs/parallel-reports/CONTRACT_REQUEST_D.md` | créé |
| `docs/parallel-reports/AGENT_D_REPORT.md` | créé (ce fichier) |

**Hors périmètre : rien.** `git status` le confirme — les 20 autres fichiers
modifiés de l'arbre appartiennent aux agents A, B, C, E et Z, et je n'ai touché
aucun. `lib/features/disponibilites/grille_semaine.dart` est **importé tel quel**,
sans un paramètre de plus : l'écran du tuteur `TUT-04` est intact.

Aucune dépendance ajoutée. Aucune migration écrite. Aucune table `AppDatabase`.
Aucun fichier dans `lib/core/widgets/`. `assets/i18n/*.json` jamais ouvert.

---

## 3. Les états rendus, et où ils se voient

### Vue « Mes disponibilités »

| État | Rendu | Test |
| :--- | :--- | :--- |
| `loading` | `Skeleton.liste(lignes: 6)` tant que `sessionProvider.profileId`, `monFuseauProvider` ou `disponibilitesProvider` n'ont pas répondu. **Aucune heure affichée.** | `loading : aucune heure avant que le fuseau ait repondu` |
| `content` | grille + compteur d'heures + conséquence | tous les tests de grille |
| `empty` | `enseignant.creneaux.aucuneHeure` : dit la conséquence (« aucune famille ne peut vous être proposée »), pas seulement le vide | `empty : aucune heure posee se dit` |
| `error` | `EmptyState` + « Réessayer » qui invalide les deux providers | `error : la grille dit son echec` |
| `offline` | grille consultable et inerte + phrase | `offline : la grille reste lisible mais n accepte rien` |
| `sauvegardé` | `LocalFeedback` nommant la case : « mardi 17 h enregistré » | `sauvegarde : la case enregistree est NOMMEE` |
| `conflit` | énumération des heures engagées, et confirmation dédiée au retrait d'une heure engagée | `conflit : une heure qui porte un eleve se VOIT` |

### Vue « Créneaux disponibles »

| État | Rendu | Test |
| :--- | :--- | :--- |
| `loading` | `Skeleton.carteEleve(lignes: 3)` | `loading : un squelette, jamais un feed vide` |
| `content` | une ligne par créneau compatible, ancienneté d'abord | 4 tests |
| `empty` | `EmptyState` **sans bouton** | `empty : le constat, et aucun bouton` |
| `error` | `EmptyState` + « Réessayer » | `error : un message et une relecture` |
| `offline` | pas de CTA, phrase, cartes conservées | `offline : la file reste lisible` |
| `conflit` / `créneau déjà pris` | phrase nommée **+ disparition de la ligne** | `pris par un autre pendant l affichage` |
| `plafond atteint` | pas de CTA, phrase, accès à la demande | `au plafond, le bouton n existe pas` |

**Le message de refus est rendu au-dessus de la gate de chargement**, et pas
dans le seul chemin « contenu » : sinon il disparaîtrait pendant la relecture du
feed qu'il vient lui-même de déclencher, pour revenir ensuite.

---

## 4. La concurrence, mesurée

Quatre tests contre `FauxServiceMatching`, dans le groupe
« la base tranche la concurrence, l'écran la raconte ».

1. **un créneau pris par un autre pendant l'affichage.** La fixture met
   `erreurPrise` **et** vide `matching.feed` après le rendu de la carte, puis
   l'écran tape. On mesure les quatre choses à la fois : le conflit est nommé,
   la carte **disparaît**, `matching.prises` est **vide** (aucune incohérence
   locale), et la file vide s'affiche comme une file vide ;
2. **tout échec d'une prise relit le feed** — l'invariant de non-régression
   demandé par l'audit de zone. La base refuse pour une **autre** raison et la
   file rend désormais un **autre** élève : si le feed n'était pas relu, l'écran
   resterait sur le premier ;
3. **un refus imprévu se recopie** plutôt que de s'avaler dans une phrase
   générique fausse ;
4. **le plafond refusé en base se nomme aussi** : le trigger peut refuser alors
   que l'écran se croyait sous la limite.

**Aucun verrou local ne décide du gagnant**, et aucune contrainte backend n'a
été touchée. L'index unique partiel `assignments_one_active_teacher_uidx` est
vérifié présent sur le serveur (lecture seule, ci-dessous).

---

## 5. Confidentialité — vérifié, et dit

**Aucune coordonnée privée de famille n'atteint cet écran.** Ce que la carte rend,
et rien d'autre : **prénom**, **identifiant immuable**, niveau déclaré, jour et
heure du créneau, ancienneté d'attente.

Trois raisons, dans l'ordre de solidité :

1. **le modèle n'en porte aucune.** `EleveEnAttente` a sept champs
   (`eleveId`, `prenom`, `identifiantImmuable`, `creneau`, `depuis`, `mode`,
   `niveau`) : il n'y a pas de nom de famille, de courriel, de téléphone ni
   d'identifiant de foyer à oublier de masquer ;
2. **la vue non plus.** `eleves_en_attente_v` est `security_barrier`, n'existe
   que pour `app_role() = 'teacher'`, et la migration `0014` remplace le prénom
   par l'identifiant immuable en session d'agent masquant ;
3. **un test le mesure quand même** (`aucune coordonnee de famille n atteint
   l ecran`) : il énumère les champs attendus, puis balaie **tous** les `Text`
   rendus et échoue sur un `@` ou sur une suite de six chiffres ou plus.

---

## 6. Mobile d'abord — 390 × 844

Tous les tests de widget montent sur `Size(390, 844)`,
`devicePixelRatio = 1`, via `_telephone(tester)`. Un test est dédié au
débordement : huit familles dans la file, puis
`expect(tester.takeException(), isNull)`.

Les cases de la grille sont tapées **par leur libellé parlé**
(`find.bySemanticsLabel`), après `ensureVisible` : c'est la technique de
`disponibilites_test.dart`, et elle mesure au passage l'exigence
d'accessibilité de la fiche (« label parlé "Lundi 17 heures, disponible" »).

La cible tactile vient de `metriques.cibleTactile` dans `GrilleSemaine` et de
`ActionPrincipale` : je n'ai posé aucune dimension.

---

## 7. Ce que j'ai vérifié sur la base, en lecture seule

L'opérateur a autorisé explicitement la migration. **Le lot Enseignant n'en avait
pas besoin, et ma zone encore moins** — voici pourquoi, plutôt qu'une affirmation.

Projet `gggmtelinlpseweouyav` (vérifié par `get_project_url` d'abord : la mémoire
projet signale que le MCP a déjà visé PISI).

- **la migration que le lot attendait est déjà appliquée** :
  `role_enseignant` (`20260919224503`) et `durcissement_execute_enseignant`
  (`20260919224844`), qui correspondent aux fichiers `0025` et `0026` de l'arbre.
  `TEACHER_SHARED_CONTRACTS.md` §13 (« la migration `0025` n'est pas
  appliquée ») est donc **périmé** → signalé en `CONTRACT_REQUEST_D.md` §10 ;
- **tout ce dont `ENS-06` dépend existe** : `weekly_availability` (table),
  `teacher_student_assignments` (table),
  `assignments_one_active_teacher_uidx` (index), `eleves_en_attente_v`,
  `mes_affectations_v` (vues) ;
- **`0021`–`0024` (Pédagogie) ne sont pas appliquées** : la dernière version
  Pédagogie du serveur est `0020_programme_pedagogique`. Hors de ma zone, mais
  c'est un fait qui décide de ce qui s'affiche.

**Je n'ai écrit aucune migration et exécuté aucun DDL.** Deux raisons, pas une :
`supabase/**` appartient à l'Agent Z, et quatre autres agents écrivent dans le
même arbre au même instant — une écriture de schéma depuis un agent métier
serait une collision, pas un déblocage. Si l'opérateur veut malgré tout qu'une
migration soit poussée, elle se pose en un geste chez l'Agent Z, qui possède le
fichier.

---

## 8. Dettes et incertitudes — ce qu'un relecteur doit regarder en premier

1. **`t.enseignant.creneaux.*` n'existe pas encore.** Mes 20 clés sont déclarées
   dans `i18n_D.json` et employées dans le code : **l'analyse de mon fichier
   échouera jusqu'à ce que l'Agent Z fusionne et relance `dart run slang`.**
   C'est le protocole (« déclarer d'abord, employer ensuite »), pas un oubli ;
2. **je n'ai lancé aucune commande** `flutter analyze`, `flutter test`,
   `dart run slang`, `build_runner`. **Rien dans ce rapport n'est une mesure
   d'exécution.** Les 25 tests sont écrits, ils ne sont pas prouvés verts. C'est
   la consigne, et c'est la principale incertitude de ce lot ;
3. **un écran, deux namespaces de chaînes** : 19 clés sous `t.creneaux.*`
   (existantes, lues par les tests) et 20 sous `t.enseignant.creneaux.*`
   (nouvelles, convention du lot). Dette assumée, tranchée par Agent Z
   → `CONTRACT_REQUEST_D.md` §8 ;
4. **le conflit se voit à côté de la case, pas sur la case.** Impossible de
   faire mieux sans ajouter un paramètre à `GrilleSemaine`, ce qui changerait
   `TUT-04`. → `CONTRACT_REQUEST_D.md` §3 ;
5. **si `affectationsProvider` échoue, la liste des heures engagées disparaît
   silencieusement** et un retrait ne dira plus rien. J'ai choisi de ne pas en
   faire un état : la garde est **informative**, retirer une disponibilité
   n'annule aucun cours en base. À relire si quelqu'un croit le contraire ;
6. **le niveau est affiché brut** (`'debutant'`). Vérifié : `selecteur_niveau.dart`
   ne fournit rien d'utilisable ici, il parle du niveau **du programme**.
   Inventer un libellé serait pire → `CONTRACT_REQUEST_D.md` §6 ;
7. **`find.bySemanticsLabel` sans `ensureSemantics()`** : c'est ce que fait
   `disponibilites_test.dart`, qui passe. Si la suite échoue là, la correction
   est une poignée `tester.ensureSemantics()` dans `_taperCase` ;
8. **le double tri (base + client) est intact**, le `TabBar` sans `TabBarView`
   est intact, le `SectionHeader` par panneau dès la tablette est intact : ce
   sont trois correctifs payés, et je n'ai défait aucun. Le test des titres de
   panneaux à 768 et 1440 les garde ;
9. **`ENS-06` reste sur le modèle 1-à-1.** `prendre_eleve()` crée une affectation,
   pas une place dans un groupe, et aucune RPC groupe n'est ouverte à
   l'enseignant (vérifié). Ce lot **consolide** donc le modèle que le pivot du
   19/09 doit remplacer. Ce n'était pas à moi de trancher
   → `CONTRACT_REQUEST_D.md` §9 ;
10. **une décision produit m'a manqué** : faut-il refuser le retrait d'une heure
    engagée ? J'avais d'abord bloqué le geste, puis j'ai retiré le blocage —
    aucun document ne le pose, et refuser empêcherait un enseignant de cesser de
    proposer une heure tout en finissant un cours. → `CONTRACT_REQUEST_D.md` §4.

---

## 9. Ce que l'audit a corrigé dans l'énoncé, et qui est confirmé

Le protocole demandait de ne pas créer « deux destinations globales » entre
Créneaux et Disponibilités. **Ce défaut n'existe pas**, et je le confirme par
lecture : `nav_shell.dart:84-88` place « Disponibilités » dans la liste du
**tuteur**, `:106-110` place « Créneaux » dans celle de l'**enseignant**, et le
routeur les met dans deux `StatefulShellRoute` distinctes. Un enseignant ne voit
jamais deux entrées. Il n'y avait rien à fusionner.

Ce qui reste vrai, et qui est tenu : `ENS-06` garde ses **deux vues locales**,
et n'en fait pas deux destinations.
