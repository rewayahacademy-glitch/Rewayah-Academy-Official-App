# R1 - Fichiers Dart de `main` non atteignables depuis `lib/main.dart`

Relevé en **lecture seule** le 24/09/2026 entre 15:20 et 15:55 (+03:00). Aucune écriture dans un dépôt ou un worktree, aucun checkout, aucun `stash`, aucun `fetch`. Commandes Git employées : `rev-parse`, `ls-tree`, `show`, `cat-file --batch`, `log`, `grep`, `branch --contains`. Seules écritures : ce rapport et le dossier `06_registre\outils\` (hors dépôt).

Référence mesurée : **`main` = `origin/main` = `4a7aa2b`** (`4a7aa2befe354ace408d3c75c8ea177fb70544e1`, 22/09 09:02, `git rev-parse main origin/main`).

Légende : **constaté** = mesuré ici, commande citée ; **prétendu** = écrit dans un document ou un commentaire, non revérifié ici ; **INCONNU**.

---

## 0. En clair, pour le directeur

1. **Le chiffre « 45 fichiers » de `08` est exact** (constaté) : 45 fichiers de `lib/` (7 551 lignes, dont 6 764 non vides, exactement le chiffre de la mémoire) ne sont reliés par aucun import à `lib/main.dart`. Même liste sur la branche C0 (`5113656`).
2. **Ces 45 fichiers ne sont pas dans l'application déployée.** Le build de production compile `lib/main.dart` et ce qu'il importe, rien d'autre. Contrôle sur le fichier réellement servi en production : aucune des 10 chaînes propres à ces fichiers ne s'y trouve, alors que les 5 chaînes témoins des écrans voisins y sont (§6).
3. **Ils n'ont jamais été branchés sur `main`**, à aucun des 45 commits de `main` depuis leur arrivée le 20/09 (§5).
4. **Ils contiennent :** le Teaching Dock de l'enseignant (annoter, marquer, masquer pour la récitation, pointer), la synchronisation en direct de la classe et la reprise après reconnexion, l'après-cours de l'enseignant, le micro-avis de l'élève, le signalement vers l'administration, le bloc « Avant le prochain cours », le sélecteur de bibliothèque en classe, la barre « Cours en cours », plus deux petits outils de contrôle.
5. **Même branchés, plusieurs ne fonctionneraient pas encore.** Quatre de leurs fournisseurs de données lèvent volontairement une erreur (« aucune implementation serveur ») et deux autres travaillent en mémoire seulement (§3, colonne « Source de données »).
6. **Ils ont des tests** : 42 des 45 sont exercés par au moins un test (40 directement, 2 via un autre fichier), et 3 n'en ont aucun. **Les tests n'ont pas été lancés ici** : leur réussite reste INCONNUE.

---

## 1. Méthode et preuves

| Étape | Commande / fichier | Résultat constaté |
|---|---|---|
| Inventaire | `git -C "D:\RA _APP\RA -OFFICIAL-APP" ls-tree -r main --name-only` | 530 `.dart` : 346 dans `lib/` (dont 4 `*.g.dart`), 183 dans `test/`, 1 dans `tool/` |
| Graphe | `D:\RA _APP\pilotage-tuteur-v1\06_registre\outils\graphe_imports.ps1 -Ref main` (lit les blobs par `git cat-file --batch`, ne touche pas au dépôt) | 301 fichiers `lib/` atteignables, **45 non atteignables**, 0 `*.g.dart` parmi eux, 0 URI interne non résolue |
| Règles d'analyse | directives `import`, `export`, `part` (pas `part of`), imports conditionnels (les deux cibles comptent) ; URI relatives et `package:rewayah_academy/…` (nom lu dans `main:pubspec.yaml:1`) | BOM UTF-8 retiré avant analyse : **15 fichiers de `main` en ont un** (ex. `lib/features/tc_classe_live/classe_live_page.dart`). Sans ce retrait, leur première directive serait manquée |
| Point d'entrée unique | `git grep -n -E "^\s*(Future<void>\|void)\s+main\s*\(" main -- lib` | un seul : `lib/main.dart:23` |
| Le build de production compile ce point d'entrée | `main:.github/workflows/flutter-deploy.yml:90` : `flutter build web --release …` **sans `-t`**, donc `lib/main.dart` | constaté |
| Contre-vérification indépendante | pour chaque fichier, `git grep` de son nom dans les lignes `import/export/part` de `main:lib` | **0** importeur hors de l'ensemble des 45 : ils ne s'importent qu'entre eux |
| Commentaires de bloc piégeux | `git grep -c "/\*" main -- lib` | 4 lignes dans 3 fichiers, toutes dans des commentaires `//` ou `///` (`app_icons.dart:357`, `service_acceptations.dart:11`, `profil_enseignant_page.dart:504,582`), aucune directive masquée |
| Même mesure sur C0 | `graphe_imports.ps1 -Ref c0/configuration-baseline-2026-09-23` (`5113656`) | liste identique (`Compare-Object` : 0 écart) |

Sorties conservées (hors dépôt) : `outils\r1_non_atteignables_4a7aa2b.tsv` (45 lignes : fichier, lignes, importeurs, tests directs et transitifs), `outils\r1_atteignables_4a7aa2b.txt` (301), `outils\r1_historique_main_premier_parent.txt` (§5), et les équivalents `_5113656` pour C0.

Note : pendant ce relevé, le checkout principal est passé de `3cf3544` à `5113656`, par le commit `5113656` du 24/09 15:25:37 « docs(08): constats de securite releves par l inventaire Tuteur V1 ». Ce commit ne vient pas de cet agent (`git log -4 c0/configuration-baseline-2026-09-23`).

---

## 2. Comparaison au chiffre « 45 fichiers » de `docs/current/08`

| Source | Ce qu'elle dit | Constaté ici |
|---|---|---|
| `08:27` (sur C0 ; `docs/current/` n'existe pas sur `main` : `git ls-tree main docs/current/` est vide) | « Quarante-cinq fichiers Flutter non atteignables depuis `main.dart`, dont dock, état partagé et flux académique ; ce fait prouve une absence de branchement et ne prouve pas l'inutilité fonctionnelle » | **45 exactement**. La réserve finale est juste : des tests existent et le code est substantiel |
| `08:34` | « 45 fichiers non atteignables, lots D/F/H, tests associés » | **Composition inexacte** : D 15 + F 15 + H 11 = **41**. Les 4 autres : 1 du lot **B** (`class_library_picker.dart`), 1 du lot **E** (`barre_cours_en_cours.dart`) et 2 **promus par l'intégration Q** (`duree_academique.dart`, `capacites_observateur.dart`) |
| `08:2` | « constats techniques fondés uniquement sur les deux rapports Claude transmis, non revérifiés sur le dépôt par l'auteur » | le chiffre est maintenant revérifié |
| Mémoire `rewayah_remise_a_plat_2026-09-23.md:95` | « 45 fichiers de `lib/` (6 764 lignes) … lots Teaching Core D, F, H » | 6 764 = **lignes non vides** (7 551 lignes brutes, 4 557 hors lignes vides et commentaires `//`). Même réserve sur « D, F, H » |
| `CLAUDE.md:65-68` (C0) | « Lots D, F, H (`tc_realtime`, `tc_etat_partage`, `tc_outils`, `tc_parcours`, `tc_dock`, `tc_flux_academique`) : présents et testés, non branchés depuis `main`. La branche `core24/fable-frontend` les raccorde dans `tc_classe_live`. » | « non branchés » : **exact**. « présents » : exact. « testés » : des tests existent pour 42 des 45, résultat INCONNU. **« les raccorde » : partiel** : sur `core24/fable-frontend` (`50fae3c`), **26 des 45** deviennent atteignables. **Aucun des 11 du lot H** n'est raccordé, ni la barre E, ni les 2 fichiers Q, ni 4 fichiers D (`compaction_trait`, `couleur_intention`, `couche_annotation`, `puce_intention`), ni `transport_memoire` (§5). Rappel : CORE24 est déclaré NON CONFORME. Ce raccordement n'est donc pas une voie d'intégration |
| `CLAUDE.md` | `tc_parcours` cité en bloc | seuls **7 des 12** fichiers de `lib/core/tc_parcours/` sont non atteignables. `libelles_parcours`, `plage_lisible`, `port_travail_a_venir`, `source_contenu_seance` et `student_concern` sont atteignables |

---

## 3. Par module (dossier)

« Tests » : fichiers de `test/` qui importent le module, directement ou par transitivité (graphe calculé sur `main`). Les nombres de cas comptent les lignes `test(` / `testWidgets(` (`git grep -c`), ce qui est approximatif. Aucun test n'a été exécuté ici.

| Module (non atteignables / total du dossier) | Lignes | Ce qu'il fait (en-têtes lus) | Tests | Arrivée (commit du lot → entrée dans `main`) | Rôle concerné | Source de données sur `main` (preuve) |
|---|---|---|---|---|---|---|
| `lib/core/tc_realtime/` (9/9) | 1 200 | Protocole pédagogique temps réel en deux canaux : éphémère pour les gestes, fiable pour l'état. `ServiceRealtimePedagogique` est indépendant de LiveKit. `AdaptateurTransportLiveKit` passe par le `VideoSessionProvider` existant, sans seconde `Room`. `TransportIndisponible` hors classe, `TransportMemoire` en double de test | `test/teaching_core/f/` : `protocole_canaux_test` (15), `adaptateur_transport_livekit_test` (9), `etat_partage_seance_test` (15), plus les tests D et `q/q04` par transitivité. `providers_tc_realtime.dart` : **aucun test** | `bf01953` (20/09 10:36, lot F) → fusion `e1fef8c` (20/09 20:51) | **Salle** (technique) : enseignant émetteur, élèves et observateurs récepteurs | `providers_tc_realtime.dart:25-26` : transport par défaut = `TransportIndisponible`. Le branchement LiveKit n'est fait par aucun fichier de `main` |
| `lib/core/tc_etat_partage/` (6/8) | 908 | État partagé d'une séance (support présenté, page, focus) : réducteur à révisions, codec JSON et restauration pour un arrivant tardif ou après une reconnexion, sans rejouer l'historique | `f/reducteur_etat_partage_test` (12), `f/codec_etat_partage_test` (10), `f/etat_partage_seance_test` (15). `providers_tc_etat_partage.dart` : **aucun test** | `bf01953` → `e1fef8c` | **Salle** : reprise après coupure, pour tous les participants | `providers_tc_etat_partage.dart:22-23` : persistance = `EtatPartageMemoire` (en mémoire, perdue au redémarrage). La table `session_shared_content` existe dans `main:supabase/migrations/0032_tc_catalogue.sql:404`, appliquée en production **selon** `CONFIGURATION_BASELINE_2026-09-23.md:122` (prétendu) |
| `lib/core/tc_outils/` (9/13) | 1 784 | Logique des outils de l'enseignant : ancrage sémantique des annotations sur le texte (`ancrage_annotation`), simplification des traits (`compaction_trait`), couleur dérivée de l'intention pédagogique, état et contrôleur des outils, événements diffusés (trait, pointeur, marqueur, focus, masquage), masquage et révélation pour la récitation, dépôt d'annotations, contrat de l'hôte du dock | `test/teaching_core/d/` : `ancrage_reflow_test` (11), `annotations_test` (11), `compaction_trait_test` (10), `couche_annotation_test` (10), `dock_widget_test` (18), `intention_couleur_test` (7), `masquage_test` (9) | `151bd41` (20/09 07:48, lot D) → fusion `68d277c` (20/09 20:35). Exception : `libelles_outils.dart` = `0ad2f9f` (20/09 22:23, intégration i18n, commit direct sur `main`) | **Enseignant · Salle · Coran** (masquer pour réciter, marquer un verset). Les observateurs silencieux (tuteur, contrôleur, admin incognito) ne reçoivent aucun outil : `port_dock_hote.dart:177-180` | `port_annotations.dart:211-217` : le fournisseur **lève `UnimplementedError`** (« aucune implementation serveur »). `etat_outils.dart:77-78` : position du dock en mémoire. Table `annotation_layer` : `0032_tc_catalogue.sql:228` (même réserve) |
| `lib/features/tc_dock/` (6/6) | 1 299 | L'interface du **Teaching Dock** : 7 outils flottants (Bibliothèque, Focus, Marquer, Masquer, Stylet, Pointeur, Révision), la barre du stylet, la couche d'annotation (règle stylet = encre, doigt = navigation), la feuille de choix, la puce d'intention | `d/dock_widget_test` (18), `d/couche_annotation_test` (10), `d/intention_couleur_test` (7). `barre_stylet` et `feuille_choix` ne sont testés que par transitivité, via `dock_widget_test` | `151bd41` → `68d277c` | **Enseignant · Salle · Coran** | l'emplacement existe dans la classe atteignable : `classe_live_page.dart:91-92` (`dock` facultatif), `:428-432`, `slots_tc_classe.dart:86-97` (`HoteDock`). Mais aucun fichier atteignable ne peut construire `TeachingDock` |
| `lib/core/tc_parcours/` (7/12) | 1 162 | Après-cours prérempli (`PostCoursVM`, `PostCoursDepuisCahier`, qui réutilise le cahier `ENS-04`), micro-feedback (réponse en 3 choix, rotation des questions, tendance agrégée seule visible de l'enseignant), signalement structuré | `test/teaching_core/h/` : `post_cours_test` (18), `feedback_test` (10), `rotation_feedback_test` (9), `signalement_test` (10), `carte_feedback_test` (3), `panneau_post_cours_test` (4), `feuille_signalement_test` (4) | `535947d` (20/09 11:44, lot H) → fusion `848aabd` (20/09 20:23) | **Enseignant** (après-cours, signalement vers l'administration) ; **élève** (répond au feedback) ; **admin** (reçoit les signalements) | `port_post_cours.dart:299-305`, `port_feedback.dart:99-104` et `port_signalement.dart:141-147` : les trois fournisseurs **lèvent `UnimplementedError`**. Tables `session_feedback` (`0032:508`) et `student_concern` (`0032:572`) (même réserve) |
| `lib/features/tc_flux_academique/` (4/4) | 893 | Écrans du lot H : `BlocAvantProchainCours` (Espace Groupe, au plus 3 actions), `CarteFeedbackSeance` (un tap, n'apparaît qu'une séance sur N), `FeuilleSignalement` (depuis la fiche élève ; note interne et message facultatif pour la famille, jamais transmis automatiquement), `PanneauPostCours` (sous le cahier, cible de 45 s) | `h/bloc_avant_prochain_cours_test` (5), `h/carte_feedback_test` (3), `h/feuille_signalement_test` (4), `h/panneau_post_cours_test` (4) | `535947d` → `848aabd` | **Enseignant** (post-cours, signalement) ; **élève / famille** (feedback, bloc « Avant le prochain cours ») | l'emplacement du bloc existe : `lib/features/tc_espace_groupe/emplacements_groupe.dart:38-50`, avec une coquille `EmplacementAvantProchainCours` et `portBranche = false` par défaut. Le vrai bloc n'y est pas posé |
| `lib/features/tc_catalogue/` (1/8) | 104 | `ClassLibraryPicker` : la Bibliothèque ouverte pendant le cours (panneau sur tablette, feuille sur téléphone), sans aucun accès à la vidéo | `b/class_library_picker_test` (5) | `d5bc5bf` (20/09 06:50, lot B) → fusion `991824f` (20/09 19:48) | **Enseignant · Salle** (choisir le support à présenter) | emplacement prévu : `classe_live_page.dart:94`, `slots_tc_classe.dart:17-18` |
| `lib/features/tc_classe_live/` (1/10) | 87 | `BarreCoursEnCours` : barre compacte « Cours en cours » posée dans la coque de navigation pour revenir à la classe ; ne rend rien sans cours ouvert | **aucun test** (ni direct ni transitif) | `4e65e50` (20/09 10:54, lot E) → fusion `9f28d9d` (20/09 21:07) | **Tous les participants** d'un cours en cours | lit `etatSessionProvider` (`barre_cours_en_cours.dart:38-39`) ; posée nulle part |
| `lib/core/tc_horloge/` (1/5) | 26 | `dureeAcademique()` : durée créditée bornée à `max(entrée, début)`, pendant Dart du bornage SQL d'`etat_presence()` | `q/q02_entree_precoce_presence_test` (10) | `0502b83` (20/09 21:57, intégration Q, commit direct sur `main`) | **Présence / admin** (vérification de règle) | fonction pure, sans source |
| `lib/core/tc_observation/` (1/11) | 88 | `CapacitesObservateur` / `capacitesDe()` : table des capacités par rôle d'observateur (tuteur muet sans caméra, admin incognito, admin visible, contrôleur). L'en-tête le dit : « Ce n'est PAS un type de contrat… Ce double sert à vérifier que la table des rôles est la bonne » (`capacites_observateur.dart:7-11`) | `q/q04_capacites_admin_controleur_test` (8) | `0502b83` (idem) | **Tuteur · Admin · Contrôleur** (observation) | la vérité est côté serveur (`autoriser_jeton_video`, selon l'en-tête). Double de vérification, non destiné à être branché |

Fichiers sans aucun test, même transitif (constaté, colonne `tests_transitifs` vide dans le TSV) : `lib/core/tc_realtime/providers_tc_realtime.dart`, `lib/core/tc_etat_partage/providers_tc_etat_partage.dart`, `lib/features/tc_classe_live/barre_cours_en_cours.dart`.

Auteur Git de tous les commits d'arrivée : `rewayahacademy-glitch`, le compte du dépôt sous lequel les agents ont commité (`git log --format=%an`).

---

## 4. Liste exhaustive des 45 fichiers (`main` @ `4a7aa2b`)

Arrivée : `git log main --diff-filter=A --format="%h|%ci|%s" -- <fichier>` (1 seule ligne pour chacun des 45). « Importé par » : importeurs dans `lib/`, tous eux-mêmes non atteignables.

| # | Fichier | Lignes | Déclarations publiques principales | Importé par (dans `lib/`) | Test direct | Arrivée |
|---|---|---|---|---|---|---|
| 1 | `lib/core/tc_etat_partage/codec_etat_partage.dart` | 259 | fonctions libres de codec de `SharedContentState` | `service_etat_partage` | `f/codec_etat_partage_test`, `f/etat_partage_seance_test` | `bf01953` 20/09 10:36 |
| 2 | `lib/core/tc_etat_partage/etat_partage_memoire.dart` | 48 | `EtatPartageMemoire` | `providers_tc_etat_partage` | `f/etat_partage_seance_test` | `bf01953` |
| 3 | `lib/core/tc_etat_partage/port_etat_partage_persistant.dart` | 88 | `MotifEchecEtatPartage`, `EchecEtatPartage`, `PortEtatPartagePersistant` | 3 fichiers du module | `f/etat_partage_seance_test` | `bf01953` |
| 4 | `lib/core/tc_etat_partage/providers_tc_etat_partage.dart` | 38 | `portEtatPartagePersistantProvider`, `portEtatPartageProvider` | **aucun** (racine) | **aucun** | `bf01953` |
| 5 | `lib/core/tc_etat_partage/reducteur_etat_partage.dart` | 134 | `SuiteRevision`, `ResultatRevision`, `ReducteurEtatPartage` | `service_etat_partage` | `f/reducteur_etat_partage_test` | `bf01953` |
| 6 | `lib/core/tc_etat_partage/service_etat_partage.dart` | 341 | `ServiceEtatPartage` | `providers_tc_etat_partage` | `f/etat_partage_seance_test` | `bf01953` |
| 7 | `lib/core/tc_horloge/duree_academique.dart` | 26 | `dureeAcademique()` | aucun (racine) | `q/q02_entree_precoce_presence_test` | `0502b83` 20/09 21:57 |
| 8 | `lib/core/tc_observation/capacites_observateur.dart` | 88 | `CapacitesObservateur`, `capacitesDe()` | aucun (racine) | `q/q04_capacites_admin_controleur_test` | `0502b83` |
| 9 | `lib/core/tc_outils/ancrage_annotation.dart` | 327 | `RaisonAncrage`, `ResultatAncrage`, `CarteDesBlocs`, `BlocAncre`, `choisirAncrage()` | `port_dock_hote`, `couche_annotation` | `d/ancrage_reflow_test` | `151bd41` 20/09 07:48 |
| 10 | `lib/core/tc_outils/compaction_trait.dart` | 192 | `simplifierTrait()`, `TraitEnCours` | `couche_annotation` | `d/compaction_trait_test` | `151bd41` |
| 11 | `lib/core/tc_outils/couleur_intention.dart` | 85 | `CouleurIntention`, `EncreIntention` | `couche_annotation`, `puce_intention` | `d/intention_couleur_test` | `151bd41` |
| 12 | `lib/core/tc_outils/etat_outils.dart` | 260 | `PositionDock`, `PortPositionDock`, `PositionDockMemoire`, `EtatOutils`, `ControleurOutils`, `etatOutilsProvider` | `barre_stylet`, `couche_annotation`, `teaching_dock` | `d/couche_annotation_test`, `d/dock_widget_test` | `151bd41` |
| 13 | `lib/core/tc_outils/evenements_outils.dart` | 327 | `EvenementOutil` et 7 sous-classes, `DiffusionOutils` | `couche_annotation`, `teaching_dock` | `d/compaction_trait_test`, `d/couche_annotation_test`, `d/dock_widget_test` | `151bd41` |
| 14 | `lib/core/tc_outils/libelles_outils.dart` | 48 | `libelleOutilDock()`, `libelleIntentionPedagogique()`, `libelleOutilTrait()`, `libellePorteeAnnotation()` | 4 fichiers de `tc_dock` | `d/dock_widget_test`, `d/intention_couleur_test` | `0ad2f9f` 20/09 22:23 |
| 15 | `lib/core/tc_outils/masquage.dart` | 110 | `PlanMasquage` | `etat_outils`, `evenements_outils` | `d/masquage_test` | `151bd41` |
| 16 | `lib/core/tc_outils/port_annotations.dart` | 217 | `PortAnnotations`, `AnnotationsMemoire`, `portAnnotationsProvider` | `couche_annotation`, `teaching_dock` | `d/annotations_test`, `d/couche_annotation_test`, `d/dock_widget_test` | `151bd41` |
| 17 | `lib/core/tc_outils/port_dock_hote.dart` | 218 | `OutilDock`, `SupportPresente`, `ContexteDock`, `SelectionSupport`, `PortDockHote`, `outilsDisponibles()` | 4 fichiers | `d/couche_annotation_test`, `d/dock_widget_test` | `151bd41` |
| 18 | `lib/core/tc_parcours/feedback_memoire.dart` | 144 | `ContexteSeanceFeedback`, `FeedbackMemoire` | aucun (racine) | `h/carte_feedback_test`, `h/feedback_test` | `535947d` 20/09 11:44 |
| 19 | `lib/core/tc_parcours/port_feedback.dart` | 121 | `QuestionFeedback`, `PortFeedback`, `EchecFeedback`, `portFeedbackProvider`, `questionFeedbackProvider`, `tendanceFeedbackProvider` | `feedback_memoire`, `rotation_feedback`, `carte_feedback_seance` | `h/carte_feedback_test`, `h/feedback_test`, `h/rotation_feedback_test` | `535947d` |
| 20 | `lib/core/tc_parcours/port_post_cours.dart` | 312 | `PortPostCours`, `PostCoursDepuisCahier`, `SortPostCours`, `EchecPostCours`, `portPostCoursProvider`, `postCoursProvider` | `panneau_post_cours` | `h/panneau_post_cours_test`, `h/post_cours_test` | `535947d` |
| 21 | `lib/core/tc_parcours/port_signalement.dart` | 147 | `PortSignalement`, `SignalementMemoire`, `portSignalementProvider` | `feuille_signalement` | `h/feuille_signalement_test`, `h/signalement_test` | `535947d` |
| 22 | `lib/core/tc_parcours/post_cours_vm.dart` | 130 | `PostCoursVM` | `port_post_cours`, `panneau_post_cours` | `h/post_cours_test` | `535947d` |
| 23 | `lib/core/tc_parcours/rotation_feedback.dart` | 141 | `CatalogueFeedback`, `RotationFeedback` | `feedback_memoire` | `h/rotation_feedback_test` | `535947d` |
| 24 | `lib/core/tc_parcours/session_feedback.dart` | 167 | `ReponseFeedback`, `SessionFeedback`, `TendanceFeedback` | 4 fichiers | `h/carte_feedback_test`, `h/feedback_test`, `h/rotation_feedback_test` | `535947d` |
| 25 | `lib/core/tc_realtime/adaptateur_transport_livekit.dart` | 164 | `AdaptateurTransportLiveKit` | aucun (racine) | `f/adaptateur_transport_livekit_test` | `bf01953` |
| 26 | `lib/core/tc_realtime/codec_message_pedagogique.dart` | 90 | fonctions libres de codec de `MessagePedagogique` | `service_realtime_pedagogique` | `f/etat_partage_seance_test`, `f/protocole_canaux_test` | `bf01953` |
| 27 | `lib/core/tc_realtime/port_realtime_pedagogique.dart` | 159 | `CanalFiabilite`, `CapacitesPedagogiques`, `MessagePedagogique`, `PortRealtimePedagogique` | 11 fichiers | 10 fichiers de test (d, f, q04) | `bf01953` |
| 28 | `lib/core/tc_realtime/port_transport_donnees.dart` | 202 | `DisponibiliteTransport`, `MotifEchecTransport`, `EchecTransport`, `EtatTransport`, `CapacitesTransport`, `PaquetRealtime`, `PortTransportDonnees` | 6 fichiers | `f/adaptateur_…`, `f/etat_partage_seance_test`, `f/protocole_canaux_test` | `bf01953` |
| 29 | `lib/core/tc_realtime/providers_tc_realtime.dart` | 37 | `portTransportDonneesProvider`, `portRealtimePedagogiqueProvider` | `providers_tc_etat_partage` | **aucun** | `bf01953` |
| 30 | `lib/core/tc_realtime/service_realtime_pedagogique.dart` | 205 | `ServiceRealtimePedagogique` | `providers_tc_realtime` | `f/etat_partage_seance_test`, `f/protocole_canaux_test` | `bf01953` |
| 31 | `lib/core/tc_realtime/transport_indisponible.dart` | 57 | `TransportIndisponible` | `providers_tc_realtime` | `f/protocole_canaux_test` | `bf01953` |
| 32 | `lib/core/tc_realtime/transport_memoire.dart` | 138 | `BusMemoire`, `TransportMemoire` (double de test déclaré) | aucun (racine) | `f/etat_partage_seance_test`, `f/protocole_canaux_test` | `bf01953` |
| 33 | `lib/core/tc_realtime/types_message.dart` | 148 | constantes de types de message, `CauseRevision` | `service_etat_partage`, `service_realtime_pedagogique` | `f/etat_partage_seance_test`, `f/protocole_canaux_test` | `bf01953` |
| 34 | `lib/features/tc_catalogue/class_library_picker.dart` | 104 | `ClassLibraryPicker` | aucun (racine) | `b/class_library_picker_test` | `d5bc5bf` 20/09 06:50 |
| 35 | `lib/features/tc_classe_live/barre_cours_en_cours.dart` | 87 | `BarreCoursEnCours` | aucun (racine) | **aucun** | `4e65e50` 20/09 10:54 |
| 36 | `lib/features/tc_dock/barre_stylet.dart` | 104 | `BarreStylet` | `teaching_dock` | transitif seulement (`d/dock_widget_test`) | `151bd41` |
| 37 | `lib/features/tc_dock/bouton_outil.dart` | 100 | `BoutonOutil` | `barre_stylet`, `teaching_dock` | `d/dock_widget_test` | `151bd41` |
| 38 | `lib/features/tc_dock/couche_annotation.dart` | 462 | `PolitiqueSaisie`, `CoucheAnnotation` | aucun (racine) | `d/couche_annotation_test` | `151bd41` |
| 39 | `lib/features/tc_dock/feuille_choix.dart` | 147 | `FeuilleChoix` | `barre_stylet`, `teaching_dock` | transitif seulement (`d/dock_widget_test`) | `151bd41` |
| 40 | `lib/features/tc_dock/puce_intention.dart` | 32 | `PuceIntention` | aucun (racine) | `d/intention_couleur_test` | `151bd41` |
| 41 | `lib/features/tc_dock/teaching_dock.dart` | 454 | `TeachingDock`, `HoteDuDock` | aucun (racine) | `d/dock_widget_test` | `151bd41` |
| 42 | `lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart` | 196 | `BlocAvantProchainCours` | aucun (racine) | `h/bloc_avant_prochain_cours_test` | `535947d` |
| 43 | `lib/features/tc_flux_academique/carte_feedback_seance.dart` | 130 | `CarteFeedbackSeance` | aucun (racine) | `h/carte_feedback_test` | `535947d` |
| 44 | `lib/features/tc_flux_academique/feuille_signalement.dart` | 243 | `FeuilleSignalement` | aucun (racine) | `h/feuille_signalement_test` | `535947d` |
| 45 | `lib/features/tc_flux_academique/panneau_post_cours.dart` | 324 | `PanneauPostCours` | aucun (racine) | `h/panneau_post_cours_test` | `535947d` |

Tous les chemins de test ci-dessus sont sous `test/teaching_core/`. Les **15 racines** (fichiers qu'aucun autre fichier de `lib/` n'importe) sont les points où un branchement devrait se faire.

---

## 5. Ont-ils été branchés un jour ? (historique)

Constaté avec le même script, exécuté sur **chacun des 45 commits premier-parent de `main`** de `848aabd` (première fusion d'un lot, 20/09 20:23) à `4a7aa2b`. Sortie complète : `outils\r1_historique_main_premier_parent.txt`.

- **À aucun de ces 45 commits, un seul des 45 fichiers n'a été atteignable** depuis `lib/main.dart`. Ils sont arrivés non branchés et le sont restés.
- Le 21/09 à 00:58, le commit `0007ff9` « fix(integration): cable les routes Teaching Core (plan etape 7, section 8) » fait passer le total de non-atteignables de 152 à 48, sans rendre atteignable aucun des 45. Les 3 fichiers restants deviennent atteignables le 21/09 avec les commits observation `08d8edb` (`indicateur_observation.dart`) et `96efc5f` (`etat_reglages_observation.dart`, `module_reglages_observation.dart`). Il reste alors exactement ces 45.
- Autres branches (même méthode) : `core24/fable-frontend` @ `50fae3c` en rend **26** atteignables (tout F sauf `transport_memoire`, 11 des 15 fichiers D, le picker B), **0** du lot H. Les branches `integration/core24-classes-v2-remediation` @ `3c0cb1c`, `observation/lot-2026-09-21` @ `0bfc9e4` et `v0/verite-produit` @ `33503fe` en rendent **0** atteignable. Les deux reprises frontend recommandées par C10 §6 (V0 et observation) **ne branchent donc aucun de ces fichiers**.
- Non examiné : les branches `ui/tuteur-v1` et `ui/tuteur-v1-p0d` (chantier actif en cours d'écriture, hors périmètre de cette tâche).

---

## 6. Absence dans l'application réellement servie en production

Constaté le 24/09 à 12:43:38 GMT : `Invoke-WebRequest https://rewayah-academy.vercel.app/main.dart.js`. Le fichier a été copié dans le scratchpad de la session, jamais dans le dépôt. Réponse HTTP 200, 5 313 881 octets, SHA-256 `CA9B877A38CE129D64010CF6A42F86013C90A05749FFBAACC5342C4B85E68571`, `Last-Modified: Mon, 21 Sep 2026 06:17:02 GMT`. Le fichier `version.json` servi indique `0.2.0+1`.

| Chaîne cherchée | Présente uniquement dans (`git grep -l -F … main -- lib`) | Occurrences dans le bundle de production |
|---|---|---|
| `tc.outils.trait_en_cours` | `tc_outils/evenements_outils.dart` | **0** |
| `tc.outils.pointeur` | `tc_outils/evenements_outils.dart` | **0** |
| `tc.outils.masquage` | `evenements_outils.dart`, `tc_realtime/port_realtime_pedagogique.dart` | **0** |
| `tc.etat_partage.revision` | `tc_realtime/types_message.dart` | **0** |
| `tc.realtime.eleve_actif` | `types_message.dart` | **0** |
| `tc.realtime.rappel_discret` | `types_message.dart` | **0** |
| `PortFeedback : aucune implementation serveur` | `tc_parcours/port_feedback.dart` | **0** |
| `PortSignalement : aucune implementation serveur` | `tc_parcours/port_signalement.dart` | **0** |
| `PortAnnotations : aucune implementation serveur` | `tc_outils/port_annotations.dart` | **0** |
| `PortPostCours : composer PostCoursDepuisCahier` | `tc_parcours/port_post_cours.dart` | **0** |
| témoin `/tc/groupes` | fichiers atteignables (`routes.dart`, `redirection.dart`…) | 6 |
| témoin `/tc/bibliotheque` | atteignables | 5 |
| témoin `/tc/classe` | atteignables | 4 |
| témoin `/tc/mushaf` | atteignable (`routes.dart`) | 3 |
| témoin `/salle` | atteignables | 6 |

Portée de cette preuve : elle est **cohérente** avec le graphe, mais pas autonome. Une chaîne absente peut aussi venir de l'élagage du compilateur. La preuve principale reste le graphe d'imports (§1), et le bundle la confirme sur l'artefact réel.

Observation annexe, **non vérifiée** : la date `Last-Modified` (21/09, 09:17 heure locale) est antérieure au dernier commit de `main` (`4a7aa2b`, 22/09 09:02). Le SHA exact de la version déployée est **INCONNU** ici. Cela ne change rien pour ces 45 fichiers : ils n'étaient atteignables à aucun commit de `main` (§5).

---

## 7. Ce qui n'est PAS prouvé ici (limites)

- **Atteignable n'est pas visible.** Ce relevé prouve seulement qu'un fichier est compilé ou non. Un fichier atteignable peut rester sans entrée pour l'utilisateur. Exemple **prétendu** par `CLAUDE.md:69-71` et par le bilan C0 ligne 140 : `/tc/classe` (`features/tc_classe_live`) est compilée mais n'a pas d'entrée effective. Cet angle n'est pas mesuré ici.
- **Tests non exécutés** : leur présence est constatée, leur réussite est INCONNUE (ni `flutter test` lancé, ni journal de CI consulté). `main:.github/workflows/ci.yml:288` lance bien `flutter test` sur tout `test/`. Le chiffre de « 1 762 tests verts » (`08:27`) reste prétendu.
- **Backend** : l'existence en production des tables `annotation_layer`, `session_shared_content`, `session_feedback` et `student_concern` repose sur `CONFIGURATION_BASELINE_2026-09-23.md:122` (migrations `0030`-`0033` « identiques » à la production). Non revérifié, aucune lecture de la base.
- **Rôles** : déduits des en-têtes et des déclarations lus (citations ci-dessus), pas d'une exécution.
- Aucun fichier n'a été supprimé, déplacé ni modifié. Conformément à `08:34`, rien ici ne justifie une suppression : ce relevé établit l'absence de branchement, pas l'inutilité.

---

## 8. Rejouer

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\RA _APP\pilotage-tuteur-v1\06_registre\outils\graphe_imports.ps1" -Ref main
# -> ref=main sha=4a7aa2b… ; lib/ : 346 ; atteignables 301 ; NON atteignables 45 ; lignes 7551
git -C "D:\RA _APP\RA -OFFICIAL-APP" log main --diff-filter=A --format="%h|%ci|%s" -- <fichier>
git -C "D:\RA _APP\RA -OFFICIAL-APP" log --ancestry-path --first-parent --reverse --format="%h|%ci|%s" <commit_du_lot>..main   # entrée dans main
```
