# TC_TEST_PLAN.md — plan de test du Teaching Core

> Agent Q · worktree `D:\RA_TC\q` · branche `teaching-core/q-qa` · baseline `0071557`.
> **104 tests, tous verts dans ce worktree**, contre des doubles de contrat et des fixtures
> appartenant à Agent Q. Aucune ligne de `lib/` n'a été écrite.

---

## 1. Le principe qui commande tout le reste

Les huit autres agents écrivent **en ce moment** dans leurs propres worktrees. Leur code n'existe donc
pas ici. Agent Q ne teste pas leur implémentation : il teste **les contrats**, c'est-à-dire ce que leur
implémentation devra respecter.

Concrètement, chaque type de `TEACHING_CORE_CONTRACTS.md` a été recopié **à l'identique** dans
`test/teaching_core/fixtures/contrats/`, avec l'en-tête `// TC-DOUBLE-CONTRAT:` qui nomme son chemin
canonique et son producteur. Les tests importent ces doubles. À l'intégration, Agent Z remplace un
import par un autre : les noms de classes, de champs et de constructeurs sont **strictement les mêmes**.

Deux exceptions, assumées et documentées :

- `ContentPosition` et `ContentRange` ont été copiés **depuis le fichier publié par Agent B**
  (`D:\RA_TC\b\lib\core\tc_bibliotheque\`), comme l'AMENDEMENT 1 des contrats l'exige : les §7 et §8 du
  document ne compilent pas, la forme du producteur fait foi.
- Les constructeurs qui portent un `DateTime` ont perdu leur `const`. Un `assert(x.isUtc)` n'est pas
  évaluable à la compilation, et un `DateTime` n'est de toute façon jamais constant : le `const` était
  décoratif, l'assertion ne l'est pas. **C'est le seul écart de forme entre les doubles et le document.**

---

## 2. Ce qui est couvert

### 2.1 Les douze tests contractuels demandés

| # | Fichier | Invariant | Tests |
|---|---|---|---|
| Q-01 | `q01_pii_projection_enseignant_test.dart` | Aucune PII dans la projection enseignant | 7 |
| Q-02 | `q02_entree_precoce_presence_test.dart` | Une entrée à T-20 ne fausse pas la présence | 10 |
| Q-03 | `q03_quota_observation_tuteur_test.dart` | Quota tuteur, timer client inopérant | 10 |
| Q-04 | `q04_capacites_admin_controleur_test.dart` | Capacités Admin / Contrôleur | 8 |
| Q-05 | `q05_etat_partage_restauration_test.dart` | Restauration late joiner, révisions | 9 |
| Q-06 | `q06_annotation_source_immuable_test.dart` | Une annotation n'altère pas la source | 7 |
| Q-07 | `q07_bibliotheque_sans_disconnect_test.dart` | Le picker ne déconnecte pas | 6 |
| Q-08 | `q08_coran_page_golden_test.dart` | Golden page / double page du Coran | 14 |
| Q-09 | `q09_interface_guidee_cibles_test.dart` | Cibles tactiles de l'Interface guidée | 6 |
| Q-10 | `q10_enseignant_photo_titre_test.dart` | Photo + titre Sayyid / Sayyida | 12 |
| Q-11 | `q11_telechargement_pdf_test.dart` | Le PDF ne se régénère pas | 9 |
| Q-12 | `q12_navigation_session_persistante_test.dart` | Navigation sans disconnect | 6 |

### 2.2 Les fixtures

`test/teaching_core/fixtures/`

| Fichier | Contenu |
|---|---|
| `fixtures_groupes.dart` | Groupe plein 5/5 et 6/6, partiel 4/5, partiel **3/4**, sans photo d'enseignant, groupe clos. `libelleEffectif()` dérive toujours de `seuilMax`. |
| `fixtures_horloge.dart` | Les six moments T-30 / T-20 / attente connectée / T0 / en direct / dépassement / terminée. Trois fuseaux (Paris, Conakry, Riyad). **Scénario DST complet.** Les fonctions pures `phaseDe`, `restantDe`, `dureeAcademique`. |
| `fixtures_ressources.dart` | Les cinq types : Quran, PDF, texte structuré, image, leçon. Versions publiée / brouillon. Artefacts généré / importé. |
| `fixtures_etat_partage.dart` | Six paquets dont **un hors ordre et un dupliqué**. Le réducteur `appliquerRevision`. |
| `fixtures_observation.dart` | Politiques héritée / personnalisée / désactivée / quota de temps court / plafond incohérent. Budgets intact et épuisé. Table `capacitesDe(role)`. |
| `fixtures_projection.dart` | `TeacherStudentProjection` sans PII, la **ligne serveur empoisonnée**, le vocabulaire `motsInterditsPii`, `aplatirPourAudit()`. |
| `goldens_coran.dart` | Dix pages échantillonnées, extraites de `0013_corpus_coranique.sql`. |

### 2.3 Les doubles réutilisables par Agent Z

`test/teaching_core/q/faux/`

- `faux_moteur_salle.dart` — `FauxMoteurSalle` implémente le vrai `VideoSessionProvider` du dépôt et
  **compte** connexions, déconnexions et libérations. Plus `FauxSessionPersistante`, qui enregistre
  l'**ordre** annonce → déconnexion (décision D-24).
- `faux_serveur_observation.dart` — la borne de quota **côté serveur**, qui ferme elle-même
  l'intervalle et plafonne la durée créditée.
- `faux_etat_partage.dart` — un magasin backend et un canal temps réel **sans mémoire**, séparés
  exprès pour que la restauration ne puisse pas tricher.
- `faux_telechargement.dart` — trois compteurs distincts : générations, lectures, signatures d'URL.
- `faux_annotations.dart` — deux magasins séparés, dont un qui **expose** la faute (`remplacer()`)
  pour que le test puisse constater qu'on ne la commet pas.

### 2.4 Trois choix de méthode qui méritent d'être connus

**(a) Les tests de lecture de source.** Certains invariants portent sur une **absence** : « ce type ne
porte aucun champ de nom de famille », « aucune couche d'annotation ne porte d'octets », « la position
partagée ne porte pas le zoom ». Aucun test d'exécution ne voit un champ qui n'existe pas encore : il
ne peut interroger que ce qui est là. `support/lecture_sources.dart` lit donc le texte du fichier et
refuse l'ajout **le jour où quelqu'un l'écrit**. Les lignes de commentaire sont ignorées, pour qu'un
commentaire qui *nomme* l'interdiction ne soit pas puni.

**(b) Les doubles rendent la faute possible.** Un double incapable de mal se comporter ne prouve rien.
`FauxDepotVersions` expose `remplacer()` et compte les écritures. `EcranQuiPossedeLaRoom` reproduit
l'anti-patron de `salle_page.dart:122`, et **un test l'exerce** pour montrer que le compteur de
déconnexions sait détecter une vraie coupure. Sans lui, les « zéro déconnexion » de Q-07 et Q-12
seraient invérifiables.

**(c) Le golden du Coran est un golden de DONNÉES.** Les dix pages ont été extraites par script de
`supabase/migrations/0013_corpus_coranique.sql` — 6236 lignes `(sourate, verset, texte, page)`, dont
l'import échoue si le compte n'est pas 114 / 30 / 604 / 6236. **Aucun texte coranique n'est recopié**,
seulement des numéros : le bloc de licence Tanzil n'a donc pas à être reproduit. Un golden d'image
aurait exigé une police glyphe-par-page que le dépôt n'a pas, et aurait photographié l'approximation
que la décision D-23 interdit précisément.

---

## 3. Ce qui ne PEUT PAS être couvert avant l'intégration, et pourquoi

| Sujet | Pourquoi c'est impossible ici | Qui lève le blocage |
|---|---|---|
| **La protection PII réelle** | Elle est tenue par la vue serveur `teacher_roster_v` et par l'absence de policy `select` sur `profiles`. Un test Dart ne l'atteint pas. Q-01 garde la **seconde** ligne, pas la première. | Agent Z + un test SQL sur le modèle de `supabase/tests/scenarios_n4.sql` |
| **La borne serveur du quota tuteur** | `FauxServeurObservation` est un double. La vraie borne doit être posée **avant le token**, dans `autoriser_jeton_video`. Un test client ne peut pas la prouver. | Agent G (demande SQL) + Agent Z |
| **Les capacités réelles d'un rôle** | Elles viennent du jeton signé (`_shared/livekit.ts`). Q-04 vérifie que la **table** dit la bonne chose, pas que le serveur l'applique. | Agent Z, confrontation table ↔ SQL |
| **La fidélité du rendu Mushaf** | `verset.ligne` est NULL sur les 6236 lignes, aucun asset de layout n'existe, aucune police QCF n'est embarquée (D-23). Q-08 vérifie qu'on répond `indisponible`, pas qu'on sait rendre. | Agent C (CONTRACT_REQUEST) |
| **La reconnexion et le passage en arrière-plan** | Aucun `WidgetsBindingObserver` ni `AppLifecycleState` n'existe dans le domaine vidéo, et `flutter_test` ne simule pas une suspension d'OS. Q-12 couvre la navigation, **pas** le cycle de vie. | Agent E + un test d'intégration réel |
| **Le rendu visuel (goldens d'image)** | Les goldens d'image exigent des polices embarquées et sont plateforme-dépendants. Hors budget et hors valeur ici. | Agent Z, si décidé |
| **Le pipeline i18n slang** | Aucun agent ne touche `fr.i18n.json` (D-03). Les libellés testés ici sont des constantes locales. | Agent Z, après fusion des neuf JSON |
| **Le responsive (phase 7)** | Il demande les vrais écrans, qui n'existent pas dans ce worktree. `AppGabarit` (seuils 600/840/1200) est le seul mécanisme, et il est READ-ONLY. | Agent Z, phase 7 |
| **Le DST réel** | Ni `timezone`, ni `tz`, ni `intl` dans `pubspec.yaml` : aucune conversion IANA n'est calculable côté client. Q-02/fixtures posent les heures **rendues** et vérifient que l'arithmétique UTC est juste. | Agent A (conversion serveur) ou D-11 (dépendance) |

---

## 4. Le scénario DST, en clair

C'est le point le plus contre-intuitif du chantier, et il est encodé dans `fixtures_horloge.dart`.

Une séance du lundi à **18h00 heure de Paris** :

| | Instant UTC | Paris | Conakry | Riyad |
|---|---|---|---|---|
| Lundi 19 octobre 2026 (CEST, UTC+2) | `2026-10-19T16:00Z` | 18:00 | 16:00 | 19:00 |
| Lundi 26 octobre 2026 (CET, UTC+1) | `2026-10-26T17:00Z` | **18:00** | **17:00** | **20:00** |

Trois conséquences, toutes testables :

1. L'écart entre les deux occurrences vaut **169 heures, pas 168**. Un `debut.add(Duration(days: 7))`
   se tromperait d'une heure. C'est exactement le bug que `instant_creneau()` corrigé en `0006` évite
   déjà — et que recoder rejouerait.
2. **L'heure institutionnelle du groupe ne bouge pas** : Paris lit 18:00 les deux semaines. Ce sont les
   contreparties qui se déplacent. La notice DST s'adresse donc à la famille de Conakry, pas à Paris.
3. `restant` est de l'arithmétique UTC pure : le changement d'heure ne le touche jamais.

---

## 5. La liste ordonnée des tests qu'Agent Z devra rejouer

L'ordre suit `D-28` (contrats → B → C → A → H → D → F → E → G → Q). Après chaque intégration,
`flutter analyze` puis la ligne correspondante.

| Ordre | Après l'intégration de | Rejouer | Substitution à faire d'abord |
|---|---|---|---|
| 1 | Contrats partagés | `test/teaching_core/q` en entier | aucune |
| 2 | **B** Library | Q-07, Q-11 | `contrats_b_ressources.dart`, `content_position.dart`, `content_range.dart` → chemins canoniques d'Agent B |
| 3 | **C** Quran | Q-08 | brancher `PortCorpusCoran` sur le golden ; vérifier que `disponibilite()` rend `indisponible` |
| 4 | **A** Group Space | Q-02, Q-10 | `contrats_a_groupe.dart`, `contrats_a_horloge.dart` → Agent A. **Vérifier que `fenetreAcces` vient bien du port.** |
| 5 | **H** Academic Flow | Q-01 (assignations), Q-06 | `LearningAssignment` réel dans la projection |
| 6 | **D** Teaching Tools | Q-06 | `contrats_d_outils.dart` → Agent D ; le test « la couche canonique » cesse d'être dormant |
| 7 | **F** Realtime | Q-05 | `contrats_f_etat_partage.dart` → Agent F ; brancher `PortEtatPartage.restaurer()` sur le vrai backend |
| 8 | **E** Classroom Shell | Q-01, Q-07, Q-12 | `contrats_e_classe.dart` → Agent E. **Q-01 devient le test qui mord** : il relit le fichier publié. |
| 9 | **G** Observation | Q-03, Q-04 | `contrats_g_observation.dart` → Agent G ; remplacer `FauxServeurObservation` par un test SQL de la RPC |
| 10 | Tout | Q-09 + la suite complète | brancher sur les vrais écrans |

### 5.1 Les quatre tests « armés mais dormants »

Ils passent aujourd'hui **sans rien vérifier**, parce que le fichier de production n'existe pas encore.
Ils mordent dès qu'il apparaît, sans qu'une ligne change. Agent Z doit **vérifier qu'ils ne dorment
plus** après l'intégration, sinon le chemin canonique est mal orthographié.

| Test | Fichier attendu |
|---|---|
| Q-01 « le contrat canonique subit le même examen » | `lib/core/tc_classe/teacher_student_projection.dart` |
| Q-06 « la couche canonique subit le même examen » | `lib/core/tc_outils/annotation_layer.dart` |
| (réservé) | `lib/core/tc_bibliotheque/resource_version.dart` |
| (réservé) | `lib/core/tc_groupe/group_summary_vm.dart` |

Les chemins sont centralisés dans `test/teaching_core/q/support/lecture_sources.dart`,
classe `CheminsCanoniques` : **un seul endroit à corriger** si un producteur change de nom de fichier.

### 5.2 Le test qui doit devenir rouge

`q02 › caractérisation du défaut latent de VuePresence` mesure le comportement **actuel** de
`lib/core/presence/vue_presence.dart` : une entrée à T-20 dans un cours commencé depuis 18 minutes
affiche **38 minutes**. Le défaut est nommé par la décision D-13 et n'est **pas** corrigé ici (fichier
hors périmètre).

**Ce test doit échouer le jour où la correction arrive.** C'est sa fonction : rendre impossible une
correction silencieuse. Agent Z, en le voyant rouge, met à jour la valeur attendue et raye la ligne
correspondante du CONTRACT_REQUEST A.

---

## 6. Ce qu'Agent Q n'a pas fait, et l'assume

- **Aucun test d'un autre agent n'a été réparé ni lu en vue d'être réparé.** Aucun n'existe encore
  dans ce worktree.
- **Aucun test SQL.** `supabase/tests/` n'est pas dans l'ownership d'Agent Q, et D-12 interdit toute
  migration. Les demandes SQL correspondantes sont dans `TC_CONTRACT_REQUEST_Q.md`.
- **Aucun golden d'image.**
- **Aucun test de performance.**
- **Aucun test de bout en bout.** La phase 5 de la spec appartient à Agent Z.
