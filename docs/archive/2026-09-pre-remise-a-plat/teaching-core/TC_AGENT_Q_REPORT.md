# TC_AGENT_Q_REPORT.md — rapport d'Agent Q (QA)

> Worktree `D:\RA_TC\q` · branche `teaching-core/q-qa` · baseline `0071557`.
> **104 tests, tous verts. `flutter analyze lib test` : `No issues found!`.**
> Aucune ligne de `lib/` écrite. Aucun fichier hors ownership modifié.

---

## 1. Les commandes, et leur sortie exacte

Un contrôleur adversarial relancera ces trois-là. Elles ont été exécutées depuis `D:\RA_TC\q`.

```
flutter analyze lib test
  -> No issues found! (ran in 42.5s)

flutter test test/teaching_core/q
  -> 00:39 +104: All tests passed!

git status --porcelain
  -> ?? docs/teaching-core/
     ?? test/teaching_core/
```

**Un point d'honnêteté sur la troisième.** Après `flutter analyze`, l'outil Flutter réécrit
`windows/flutter/generated_plugin_registrant.cc`, `.h` et `generated_plugins.cmake` en changeant leurs
fins de ligne. `git diff` sur ces trois fichiers rend un diff **vide** : seul le CRLF change. Ils ont été
restaurés par `git checkout -- windows/` avant le commit. Si un contrôleur relance `flutter analyze`,
il les reverra apparaître : **ce n'est pas une modification d'Agent Q**, c'est un effet de bord de
l'outil sous Windows.

---

## 2. Fichiers créés — 38, tous dans l'ownership d'Agent Q

### 2.1 Doubles de contrat — `test/teaching_core/fixtures/contrats/` (9)

| Fichier | Contrats doublés | Producteur |
|---|---|---|
| `content_position.dart` | `ContentPosition`, `TypeAncrage` | B |
| `content_range.dart` | `ContentRange` | B |
| `contrats_b_ressources.dart` | `LibraryResource`, `ResourceVersion`, `DownloadAsset`, 6 énumérations | B |
| `contrats_a_groupe.dart` | `GroupSummaryVM`, `EnseignantVM`, `TitreEnseignant`, `JetonCouleurGroupe`, `OccurrenceSeance` | A |
| `contrats_a_horloge.dart` | `SessionClockVM`, `HorlogeAffichee`, `PhaseSeance`, `NoticeDst` | A |
| `contrats_d_outils.dart` | `AnnotationLayer`, `TraitVectoriel`, `MarqueurSemantique`, `LearningAssignment`, `IntentionPedagogique` | D |
| `contrats_e_classe.dart` | `TeacherStudentProjection`, `ResumeSeance`, `AssiduiteRecente`, `EtatPresenceProjete` | E |
| `contrats_f_etat_partage.dart` | `SharedContentState`, `CapacitesPedagogiques`, `CanalFiabilite` | F |
| `contrats_g_observation.dart` | `GuardianObservationPolicy`, `BudgetObservation`, `GuardianSessionVisit`, `ResultatEntreeObservation`, `AnnonceObservation` | G |

Chacun porte en tête `// TC-DOUBLE-CONTRAT:` avec son chemin canonique et son agent.

### 2.2 Fixtures — `test/teaching_core/fixtures/` (7)

`fixtures_groupes.dart` · `fixtures_horloge.dart` · `fixtures_ressources.dart` ·
`fixtures_etat_partage.dart` · `fixtures_observation.dart` · `fixtures_projection.dart` ·
`goldens_coran.dart`

### 2.3 Doubles de comportement — `test/teaching_core/q/faux/` (5)

`faux_moteur_salle.dart` · `faux_serveur_observation.dart` · `faux_etat_partage.dart` ·
`faux_telechargement.dart` · `faux_annotations.dart`

### 2.4 Support — `test/teaching_core/q/support/` (2)

`lecture_sources.dart` · `hote_navigation.dart`

### 2.5 Tests — `test/teaching_core/q/` (12 fichiers, 104 tests)

| Fichier | Tests |
|---|---|
| `q01_pii_projection_enseignant_test.dart` | 7 |
| `q02_entree_precoce_presence_test.dart` | 10 |
| `q03_quota_observation_tuteur_test.dart` | 10 |
| `q04_capacites_admin_controleur_test.dart` | 8 |
| `q05_etat_partage_restauration_test.dart` | 9 |
| `q06_annotation_source_immuable_test.dart` | 7 |
| `q07_bibliotheque_sans_disconnect_test.dart` | 6 |
| `q08_coran_page_golden_test.dart` | 14 |
| `q09_interface_guidee_cibles_test.dart` | 6 |
| `q10_enseignant_photo_titre_test.dart` | 12 |
| `q11_telechargement_pdf_test.dart` | 9 |
| `q12_navigation_session_persistante_test.dart` | 6 |

### 2.6 Documents — `docs/teaching-core/` (3)

`TC_TEST_PLAN.md` · `TC_AGENT_Q_REPORT.md` · `TC_CONTRACT_REQUEST_Q.md` ·
`i18n/tc_i18n_Q.json` (vide, voir §6)

---

## 3. Ce qui marche vraiment

### 3.1 Les tests qui mordent dès aujourd'hui

**Q-01, la PII.** Écrit comme un refus, pas comme un constat. Une **ligne serveur empoisonnée** — celle
qu'une vue qui fuirait renverrait, avec `last_name`, `email`, `phone`, `adresse`, `latitude`,
`household_id`, `guardian_first_name`, `iban`, `solde_minor`, `device_id` — traverse la projection, et
le test cherche ensuite les **valeurs** telles quelles dans la sortie aplatie (imbrication comprise).
Un second test relit le fichier de contrat caractère par caractère : `lastName`, même sous forme
d'initiale, y devient impossible à ajouter en silence.

**Q-02, le T-20.** Le chiffre de la décision D-13 est encodé tel quel : entré à T-20, dix-huit minutes
après T0, la durée créditée vaut **18 minutes, pas 38**. Et la fenêtre d'accès est prouvée
**configurable** : passer de 20 à 30 minutes déplace `joinOpensAtUtc` d'autant et ouvre le bouton à
T-30. Si elle était codée en dur côté client, ce test ne bougerait pas.

**Q-03, le quota.** Le compte à rebours client est un objet à part, trafiqué à une heure en plein test,
et il n'est **jamais passé au serveur** — si un jour une signature de port le prenait en paramètre, ce
fichier ne compilerait plus. Le serveur double plafonne la durée créditée lui-même, ferme l'intervalle
lui-même, et distingue `tempsEpuise` de `quotaVisitesAtteint`, qui ne se disent pas de la même façon à
une famille.

**Q-08, le golden du Coran.** Dix pages, extraites **par script** de
`supabase/migrations/0013_corpus_coranique.sql` (6236 lignes, 604 pages, 114 sourates — comptage
vérifié). Le choix des dix n'est pas décoratif : la page 48 ne porte **qu'un seul verset** (2:282, le
verset de la dette), et la sourate 100 **traverse** la coupure entre les pages 599 et 600. Une interface
qui supposerait « une page = plusieurs versets » ou « une page = une unité de sens » casse sur ces deux
cas-là. Aucun texte coranique n'est recopié, seulement des numéros : le bloc de licence Tanzil n'a donc
pas à être reproduit.

**Q-12, la session persistante.** Le montage contient l'**anti-patron** du dépôt : un écran qui appelle
`moteur.quitter()` dans son `dispose`, exactement comme `_SallePageEtat` (salle_page.dart:122). Un test
l'exerce et constate la coupure. Sans lui, les « zéro déconnexion » des autres tests pourraient tout
aussi bien venir d'un double incapable d'en compter une. L'ordre **annonce → déconnexion** de la
décision D-24 est vérifié comme une séquence, pas comme un résultat.

### 3.2 Les fixtures utilisables telles quelles par les huit autres agents

Le scénario DST est celui qui vaut le déplacement. Une séance du lundi 18h00 heure de Paris tombe à
`2026-10-19T16:00Z` puis à `2026-10-26T17:00Z` : **169 heures d'écart, pas 168**. Un
`debut.add(Duration(days: 7))` se tromperait d'une heure — c'est le bug que `instant_creneau()` corrigé
en `0006` évite déjà. Et l'heure institutionnelle du groupe ne bouge pas : Paris lit 18:00 les deux
semaines, ce sont Conakry (16:00 → 17:00) et Riyad (19:00 → 20:00) qui se déplacent.

---

## 4. Ce qui est mocké, et à quel point

| Ce qui est doublé | Degré de fidélité | Ce que le double NE prouve pas |
|---|---|---|
| Les 16 contrats | **Copie littérale** des signatures, un fichier par producteur | Rien sur l'implémentation réelle : les producteurs peuvent encore diverger |
| `VideoSessionProvider` | Implémente la **vraie** interface de `lib/core/video/` | Aucun comportement LiveKit réel : pas de room, pas de piste, pas de reconnexion |
| Le serveur d'observation | Logique de quota complète et cohérente | **La borne réelle est SQL.** Un double Dart ne prouve pas qu'`autoriser_jeton_video` la respecte |
| Le backend d'état partagé | Magasin + canal sans mémoire, séparés exprès | Aucune persistance réelle : la table `shared_content_state` n'existe pas |
| Le dépôt de téléchargement | Trois compteurs distincts | Aucun PDF n'est réellement produit ; aucun Storage n'est touché |
| `ClassLibraryPicker` | Un `showModalBottomSheet` qui en tient le rôle | La surface réelle d'Agent B peut différer ; seul le **contrat d'hôte** est testé |
| Le routeur | `GoRouter` de test, 4 routes `/tc/…` | `redirection.dart` n'est pas exercé : une route hors préfixe de rôle serait redirigée en vrai |
| `capacitesDe(role)` | Table écrite d'après D-14/D-15/D-16 | Elle **décrit** ce que le jeton devrait accorder ; elle ne l'applique pas |

---

## 5. Limites honnêtes

1. **Ces tests valent contre des doubles, pas contre du code de production.** C'est la nature de la
   mission (« teste contre les contrats »), pas un raccourci — mais il faut le dire net : un test vert
   ici ne prouve pas qu'Agent E a bien écrit sa projection. Il prouve que **si** Agent E écrit la
   signature du contrat, l'invariant tient. La substitution d'import par Agent Z est ce qui transforme
   ces tests en tests de régression réels. La marche à suivre, agent par agent, est en §5 du
   `TC_TEST_PLAN.md`.

2. **Quatre tests sont « armés mais dormants ».** Ils vérifient un fichier de production qui n'existe
   pas encore et **retournent sans rien assertir** quand il est absent. Aujourd'hui, ils passent sans
   rien prouver. Agent Z doit vérifier qu'ils ne dorment plus après l'intégration — sinon le chemin
   canonique est mal orthographié dans `CheminsCanoniques`. Ils sont listés en §5.1 du TEST_PLAN.

3. **Un test doit devenir rouge.** `q02 › caractérisation du défaut latent de VuePresence` mesure le
   comportement actuel du dépôt : 38 minutes affichées pour un cours commencé depuis 18. Le défaut est
   nommé par D-13, il n'est pas corrigé ici (fichier hors périmètre), et ce test existe pour qu'une
   correction ne puisse pas passer inaperçue. Un contrôleur qui le verrait rouge après l'intégration
   doit lire cette ligne avant de conclure à une régression.

4. **Les constructeurs des doubles qui portent un `DateTime` ont perdu leur `const`.** Un
   `assert(x.isUtc)` n'est pas évaluable à la compilation. Comme un `DateTime` n'est de toute façon
   jamais constant, le `const` était décoratif et l'assertion ne l'est pas. C'est le **seul écart de
   forme** entre les doubles et `TEACHING_CORE_CONTRACTS.md`, et il est sans effet sur les signatures.

5. **`ContentPosition` et `ContentRange` ont été copiés depuis le worktree d'Agent B**, en lecture
   seule, comme l'AMENDEMENT 1 l'exige. Si Agent B les modifie encore avant l'intégration, les doubles
   divergeront sans que rien ne le signale ici.

6. **Aucun test SQL, aucun test de bout en bout, aucun golden d'image, aucun test de performance, aucun
   test de responsive.** Les raisons sont détaillées en §3 du TEST_PLAN. Les deux premiers appartiennent
   à Agent Z.

7. **Le cycle de vie applicatif n'est pas testé.** Q-12 couvre la navigation, pas la suspension d'OS.
   Aucun `WidgetsBindingObserver` n'existe dans le domaine vidéo du dépôt, et `flutter_test` ne simule
   pas une mise en arrière-plan réelle.

8. **Aucun test d'un autre agent n'a été lu ni réparé.** Aucun n'existe dans ce worktree. La règle
   « ne jamais réparer le test d'un autre » n'a donc pas eu à s'appliquer.

---

## 6. Note d'ownership — un écart déclaré

`TEACHING_CORE_FILE_OWNERSHIP.md` §2 attribue à Agent Q le sous-arbre i18n « **aucun** », et la preuve
de disjonction §5.1 ne liste pas `docs/teaching-core/i18n/tc_i18n_Q.json` parmi ses fichiers possédés.
La mission reçue par Agent Q, elle, le nomme explicitement parmi ses livrables documentaires.

Le fichier a été écrit, **vide de libellés**, avec une note qui explique pourquoi. Il n'entre en
collision avec aucun autre agent : la §5.1 ne l'attribue à personne. L'écart est déclaré ici plutôt que
résolu en silence, et Agent Z tranche — le garder est inoffensif, le supprimer aussi.

Tous les autres chemins touchés sont dans l'ownership d'Agent Q :
`test/teaching_core/q/`, `test/teaching_core/fixtures/`, `docs/teaching-core/TC_AGENT_Q_REPORT.md`,
`docs/teaching-core/TC_CONTRACT_REQUEST_Q.md`, `docs/teaching-core/TC_TEST_PLAN.md`.

---

## 7. Défauts pré-existants croisés — signalés, non corrigés

Conformément au protocole, ils sont nommés et laissés intacts.

1. **`VuePresence.depuis` ne borne pas la durée au début de séance** (`lib/core/presence/vue_presence.dart`).
   Latent tant que la fenêtre vaut T-10, visible à T-20. Décision D-13, demande relayée en §3 du
   `TC_CONTRACT_REQUEST_Q.md`, et caractérisé par `q02`.

2. **`supabase/migrations/0029` est écrite mais pas appliquée en base** (défaut nommé par
   `BASELINE_ADDENDUM.md`). En l'état, `dossiers_en_attente()` livre nom et prénom de toute personne en
   attente de KYC à un appelant anonyme. **Hors mission d'Agent Q, et non touché** — mais c'est une fuite
   de PII bien plus grave que tout ce que Q-01 garde, et elle mérite d'être la première chose qu'Agent Z
   regarde.

3. **`test/.../catalogue_galerie_test` est rouge dans la baseline** (idem). Agent Q ne l'a pas exécuté
   et n'a créé aucun composant dans `lib/core/widgets/`.

4. **`policy lesson_reports_teacher_write` ne vérifie pas l'appartenance de `session_id`**
   (`0001:1064-1069`, constat déjà inscrit dans `TEACHING_CORE_EXISTING_MAPPING.md` §6). Non corrigé,
   non testé : il appartient à `TC_CONTRACT_REQUEST_H.md`.

---

## 8. Ce qu'Agent Z devra brancher

| # | Geste | Effet |
|---|---|---|
| 1 | Remplacer les 9 imports `fixtures/contrats/*` par les chemins canoniques, agent par agent, dans l'ordre D-28 | Les 104 tests deviennent des tests de régression réels |
| 2 | Vérifier que les 4 tests dormants **mordent** | Sinon `CheminsCanoniques` pointe à côté |
| 3 | Lire `q02 › caractérisation` quand il devient rouge | La correction D-13 a eu lieu : mettre à jour la valeur |
| 4 | Confronter `capacitesDe(role)` à `autoriser_jeton_video` | La table est une spécification, le SQL est la loi |
| 5 | Confronter `plafondEffectifDeVisite` à la RPC d'observation | Même logique, côté quota |
| 6 | Déplacer `dureeAcademique` des fixtures vers `lib/core/tc_horloge/` | La suite de tests de `q02` suit sans modification |
| 7 | Écrire `supabase/tests/scenarios_tc_pii.sql` | La première ligne de défense PII n'est testée par personne |
| 8 | Décider du sort de `tc_i18n_Q.json` | Voir §6 |
| 9 | Reprendre `FauxMoteurSalle` et `FauxSessionPersistante` pour les tests d'Agent E | Ils implémentent la vraie interface, ils ne sont pas jetables |
