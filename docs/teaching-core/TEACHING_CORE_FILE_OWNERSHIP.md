# TEACHING_CORE_FILE_OWNERSHIP.md

> **Le document le plus important du chantier.** Il attribue chaque chemin modifiable à **un seul agent**.
> Zéro chevauchement. Si deux agents ont besoin du même fichier, **l'un le possède et l'autre passe par
> un port**. C'est la condition STOP du protocole : les agents A…H et Q ne démarrent pas tant que la
> section **PREUVE DE DISJONCTION** n'est pas vérifiée.
>
> Baseline : `550e605`. Tous les répertoires existants cités ont été vérifiés dans `D:\RA_TC\0`.
> Tous les répertoires neufs portent le préfixe `tc_` / `teaching-core` / `teaching_core` et
> **aucun ne réutilise un nom pris par le chantier enseignant**.

---

## 1. Principe : tout ce qui est neuf est préfixé

Le dépôt existant est **intégralement en lecture seule** pour les agents A…H et Q. Toute ligne de code
écrite par un agent vit dans un répertoire **neuf**, préfixé, et attribué à lui seul.

| Zone | Convention |
|---|---|
| Domaine / logique | `lib/core/tc_<domaine>/` |
| Écrans | `lib/features/tc_<ecran>/` |
| Tests | `test/teaching_core/<lettre>/` |
| Documents | `docs/teaching-core/TC_*.md` et `docs/teaching-core/i18n/tc_i18n_<X>.json` |

Trois noms sont **bannis** parce que le chantier enseignant les a déjà pris (et qu'ils sont invisibles
depuis notre baseline) : `lib/core/enseignant/`, et dans `lib/features/` les noms `fiche_groupe`,
`revue_groupe`, `salle_enseignant`, `cahier`, `bienvenue_enseignant`. **Aucun agent ne les recrée, même
avec un contenu différent.**

---

## 2. Matrice d'ownership

### Agent A — Group Space

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\a` — `teaching-core/a-group-space` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_groupe/`<br>`lib/core/tc_horloge/`<br>`lib/features/tc_mes_groupes/`<br>`lib/features/tc_espace_groupe/`<br>`test/teaching_core/a/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_A_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_A.md`<br>`docs/teaching-core/i18n/tc_i18n_A.json` |
| **Sous-arbre i18n** | `tc.groupe.*` |
| **Contrats produits** | `GroupSummaryVM`, `GroupHomeVM`, `SessionClockVM` |
| **Ports produits** | `PortGroupes`, `PortHorlogeSeance` |
| **Ports consommés** | `PortCatalogue` (B) pour le slot Bibliothèque · `PortRosterEnseignant` (E) · `PortTravailAVenir` (H) |
| **Fichiers interdits spécifiques** | `lib/features/journee/journee_page.dart` **[P]** — ne pas poser une 4ᵉ constante de fenêtre d'accès.<br>`lib/core/presence/vue_presence.dart` — le bug de durée T-20 est un CONTRACT_REQUEST, pas une édition.<br>`lib/core/planning/service_planning.dart` — à **consommer** (`Creneau`, `Seance`, `prochainCours()`), jamais à modifier ni dupliquer.<br>`lib/core/admin/service_groupes.dart` — chemin ADMIN, à lire comme modèle de `GroupSummaryVM`, jamais à éditer.<br>`lib/features/disponibilites/grille_semaine.dart` — à **réutiliser**, jamais à redessiner. |
| **Interdictions de fond** | Ne code ni le moteur countdown serveur, ni les tables DB, ni la Bibliothèque, ni LiveKit. Ne calcule **aucune** règle de fuseau dans un widget : la notice DST vient de `SessionClockVM`. Ne hardcode **jamais** une capacité (« 5 »), ni un offset UTC. |

### Agent B — Library Core

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\b` — `teaching-core/b-library` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_bibliotheque/`<br>`lib/core/tc_telechargement/`<br>`lib/features/tc_catalogue/`<br>`test/teaching_core/b/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_B_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_B.md`<br>`docs/teaching-core/i18n/tc_i18n_B.json` |
| **Sous-arbre i18n** | `tc.bibliotheque.*` |
| **Contrats produits** | `LibraryResource`, `ResourceVersion`, `DownloadAsset`, **`ContentPosition`**, **`ContentRange`** |
| **Ports produits** | `PortCatalogue`, `PortVersionsRessource`, `PortTelechargement`, `PortEnregistrementFichier`, `PortEtatOffline` + la surface réutilisable `ClassLibraryPicker` |
| **Ports consommés** | aucun (B est le premier intégré) |
| **Fichiers interdits spécifiques** | `lib/core/cache/db/app_database.dart` — 4 tables, commentaire normatif : toute table supplémentaire exige une justification de spec **et** une migration Drift 1→2 absente. CONTRACT_REQUEST.<br>`lib/core/cache/media/cache_media.dart` — à **étendre via un port**, jamais à éditer.<br>`lib/core/dossier/selecteur_fichier.dart` — même règle ; `file_picker 12.2.0` expose déjà `saveFile()`.<br>`lib/core/reseau/service_reseau.dart`, `lib/core/widgets/offline_banner.dart` — **consommer `horsLigneProvider`**, ne jamais ouvrir un second abonnement `Connectivity`.<br>`lib/core/admin/service_programme.dart` — patron `ResourceVersion` à **copier**, pas à éditer.<br>`lib/features/coran/`, `lib/core/coran/` — périmètre d'Agent C. |
| **Interdictions de fond** | **Une seule Bibliothèque** : ne jamais créer `LibraryOutsideClass` et `LibraryInsideClass`. Ne jamais générer un PDF à chaque clic. Ne jamais bricoler un chemin `/sdcard`. Aucune dépendance nouvelle (ni moteur PDF, ni `share_plus`, ni `path_provider`) : si un renderer manque, `TC_CONTRACT_REQUEST_B.md`. |

### Agent C — Quran Engine

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\c` — `teaching-core/c-quran` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_coran/`<br>`lib/features/tc_mushaf/`<br>`test/teaching_core/c/` (goldens dans `test/teaching_core/c/goldens/`) |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_C_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_C.md`<br>`docs/teaching-core/i18n/tc_i18n_C.json` |
| **Sous-arbre i18n** | `tc.coran.*` |
| **Contrats produits** | `PageMushafVM`, `SectionLigne`, `ModeRenduCoran` (interne au moteur) |
| **Ports produits** | `PortCorpusCoran` (adaptateur **lecture seule** au-dessus de `ServiceCoran`), `PortLayoutMushaf`, `PortNavigationCoran` |
| **Ports consommés** | `ContentPosition`, `ContentRange` (B) · `PortEtatPartage` (F) pour le mode classe/focus |
| **Fichiers interdits spécifiques** | **`lib/core/coran/service_coran.dart` [P] — INTERDICTION NOMMÉE.** Agent C ne le modifie sous aucun prétexte : il est en cours de modification par le chantier enseignant. Agent C **crée un nouveau namespace** (`lib/core/tc_coran/`) et n'utilise l'existant qu'en **lecture, derrière un adaptateur**.<br>`lib/features/coran/coran_page.dart` — l'écran actuel reste en place. Agent C construit à côté, sans le supprimer ni le déplacer : c'est Agent Z qui arbitrera le remplacement.<br>`lib/core/coran/vue_lecteur.dart` — **NON protégé mais à réutiliser tel quel** : le moteur se pose au-dessus de `SectionSourate`, il ne le remplace pas.<br>`lib/core/widgets/rosace_verset.dart` — à **réutiliser tel quel**.<br>`lib/core/widgets/page_immersive.dart` — à **réutiliser tel quel**.<br>`assets/fonts/`, `pubspec.yaml` — gelés : embarquer un jeu de polices QCF est un CONTRACT_REQUEST. |
| **Interdictions de fond** | Ne modifie **jamais** le texte canonique. Pas de PDF comme source interactive. Pas de screenshot ni d'image envoyée comme substitut au renderer. **STOP obligatoire sur la fidélité Mushaf** : voir BASELINE §6.1. Agent C ne fabrique **pas** une fausse page ; il livre un `PortLayoutMushaf` enfichable, une implémentation `LayoutIndisponible` explicite, les deux modes faisables (verset reflowable, focus), et `TC_CONTRACT_REQUEST_C.md` chiffrant les trois manques. |

### Agent D — Teaching Tools

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\d` — `teaching-core/d-teaching-tools` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_outils/`<br>`lib/features/tc_dock/`<br>`test/teaching_core/d/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_D_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_D.md`<br>`docs/teaching-core/i18n/tc_i18n_D.json` |
| **Sous-arbre i18n** | `tc.outils.*` |
| **Contrats produits** | `AnnotationLayer`, `LearningAssignment`, `MarqueurSemantique`, `IntentionPedagogique` |
| **Ports produits** | `PortAnnotations`, `PortAssignations`, `PortDockHote` (le contrat par lequel un écran accueille le dock) |
| **Ports consommés** | `ContentPosition`, `ContentRange`, `LibraryResource` (B) · `PortRealtimePedagogique` (F) pour l'émission des strokes · `PortNavigationCoran` (C) pour l'ancrage sémantique |
| **Fichiers interdits spécifiques** | `lib/core/video/` **[P]** — Agent D **ne transporte pas lui-même** les strokes : il expose les événements attendus par Agent F.<br>`lib/core/coran/` — source du Coran, hors périmètre.<br>`lib/features/tc_mushaf/` — périmètre d'Agent C : le dock s'y insère par `PortDockHote`, il n'y écrit pas.<br>`lib/core/theme/`, `lib/core/icons/app_icons.dart` — couleurs sémantiques composées avec les jetons existants ; icône manquante → CONTRACT_REQUEST. |
| **Interdictions de fond** | **La source est immuable** : une annotation ne crée **jamais** une copie du support. Données vectorielles normalisées. La couleur est **dérivée de l'intention**, jamais l'inverse. Pas de palette graphique complexe. Aucune commande vocale. |

### Agent E — Classroom Shell

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\e` — `teaching-core/e-classroom` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_classe/`<br>`lib/features/tc_classe_live/`<br>`test/teaching_core/e/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_E_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_E.md`<br>`docs/teaching-core/i18n/tc_i18n_E.json` |
| **Sous-arbre i18n** | `tc.classe.*` |
| **Contrats produits** | `TeacherStudentProjection`, `RosterClasseVM`, `SessionLiveVM` |
| **Ports produits** | `PortRosterEnseignant`, `PortSessionPersistante`, `PortRappelDiscret` |
| **Ports consommés** | `SessionClockVM` (A) · `ClassLibraryPicker` (B) · `PortDockHote` (D) · `PortRealtimePedagogique` (F) · `PortAnnonceObservation` (G) |
| **Fichiers interdits spécifiques** | **`lib/features/salle/salle_page.dart` et `lib/features/salle/vue_salle.dart` [P] — INTERDICTION NOMMÉE.** Agent E ne les modifie sous aucun prétexte : ils sont en cours de modification par le chantier enseignant. Agent E **crée un nouveau namespace** (`lib/features/tc_classe_live/`) et **consomme** `VueSalle.depuis()` en lecture sans la recopier.<br>`lib/features/salle_enseignant/` — **nom réservé par le chantier enseignant, invisible ici.** Ne jamais créer.<br>`lib/features/fiche_groupe/` — idem. La fiche pédagogique d'Agent E vit dans `lib/features/tc_classe_live/`.<br>`lib/core/video/` **[P]** — LiveKit core. Agent E consomme `moteurSalleProvider`, `serviceVideoProvider`, `preVolProvider`, **jamais une seconde `Room`**.<br>`lib/core/presence/` — à **consommer** (`presenceSeanceProvider`, `LignePresence`), jamais à doubler.<br>`lib/features/profil_enseignant/` **[P]** — ne pas doubler le compteur d'élèves. |
| **Interdictions de fond** | Ne réimplémente pas LiveKit, ni les permissions serveur, ni la projection backend. **Le shell ne possède pas le lifecycle de la room** : revenir au Groupe / Accueil / Bibliothèque ne doit jamais appeler `disconnect`. Le roster affiche **uniquement** `TeacherStudentProjection`. Aucun accusé de réception bavard sur le rappel discret. |

### Agent F — Realtime Protocol

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\f` — `teaching-core/f-realtime` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_realtime/`<br>`lib/core/tc_etat_partage/`<br>`test/teaching_core/f/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_F_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_F.md`<br>`docs/teaching-core/i18n/tc_i18n_F.json` |
| **Sous-arbre i18n** | `tc.realtime.*` (probablement vide : protocole sans UI) |
| **Contrats produits** | `SharedContentState`, `MessagePedagogique`, `CanalFiabilite` |
| **Ports produits** | `PortRealtimePedagogique`, `PortEtatPartage`, `PortEtatPartagePersistant` |
| **Ports consommés** | `ContentPosition`, `ContentRange`, `LibraryResource` (B) |
| **Fichiers interdits spécifiques** | `lib/core/video/video_session_provider.dart` **[P]** — Agent F **étend par adapter**, jamais en éditant le contrat. Le droit `can_publish_data` est **déjà accordé** côté serveur : rien à demander pour émettre. En revanche le contrat n'expose **aucune primitive d'envoi** : la séparation *reliable* / *lossy* exige une extension du core → `TC_CONTRACT_REQUEST_F.md` avec la signature précise attendue.<br>`lib/core/video/livekit_session_provider.dart` **[P]**, `pre_vol.dart` **[P]**, `service_video.dart` — READ-ONLY.<br>`supabase/functions/` — gelé.<br>`lib/core/presence/` — interdiction explicite de la spec : **pas de nouveau système de présence concurrent**. |
| **Interdictions de fond** | Pas de nouveau provider WebRTC. Pas de migration. **Pas de metadata sensible dans LiveKit** : ni téléphone, ni email, ni famille dans `participant metadata`. LiveKit n'est **jamais** une base de données : l'état durable minimal passe par un port backend. Un late joiner doit pouvoir récupérer l'état courant **sans dépendre de l'historique des messages**. Commencer par relire `docs/parallel-reports/02-livekit-audit.md` plutôt que produire un troisième audit. |

### Agent G — Observation & Policies

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\g` — `teaching-core/g-observation` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_observation/`<br>`lib/features/tc_observation_ui/`<br>`test/teaching_core/g/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_G_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_G.md`<br>`docs/teaching-core/i18n/tc_i18n_G.json` |
| **Sous-arbre i18n** | `tc.observation.*` |
| **Contrats produits** | `GuardianObservationPolicy`, `GuardianSessionVisit`, `ModeEntreeAdmin` |
| **Ports produits** | `PortPolitiqueObservation`, `PortVisiteObservation`, `PortAnnonceObservation` |
| **Ports consommés** | `SessionLiveVM` (E) pour l'annonce dans le shell · `SessionClockVM` (A) pour le compte à rebours de budget |
| **Fichiers interdits spécifiques** | `lib/core/admin/admin_domaine.dart` — **gel d'architecture à 8 domaines, règle absolue.** Le module de réglages est un **composant isolé non routé** ; Agent Z le branchera dans `Groupe > Réglages`.<br>`lib/core/widgets/admin_shell.dart`, `sous_navigation_domaine.dart` — READ-ONLY.<br>`lib/core/router/` **[P]** — **ne pas insérer le module dans le routeur.** Consigne explicite du PROMPT G.<br>`lib/features/controleur/` — CTR-01 existe déjà et fonctionne : à **consommer**, pas à refaire.<br>`lib/features/accueil_famille/accueil_famille_page.dart` — seul point d'entrée tuteur actuel : lecture seule.<br>`lib/core/video/service_video.dart` — READ-ONLY ; l'entrée Admin est un CONTRACT_REQUEST.<br>`lib/core/journal/`, `lib/features/admin_journal/` — le journal d'audit **existe et est chaîné** : ne pas en créer un second.<br>`lib/core/agent/` — `jetons_agent` sert aux **agents IA**, pas à l'observation de classe. Ne ni l'étendre ni l'imiter. |
| **Interdictions de fond** | **Ne crée jamais une règle seulement côté client.** Un compte à rebours Dart est un affichage, **jamais** l'application de la limite : la borne est serveur (spec §11.4). Ne modifie ni auth core ni token issuer. Le Contrôleur reste **incognito uniquement**, sans option visible. L'incognito est invisible aux participants mais **jamais invisible à l'audit**. |

### Agent H — Academic Flow

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\h` — `teaching-core/h-academic` |
| **Répertoires possédés (exclusifs)** | `lib/core/tc_parcours/`<br>`lib/features/tc_flux_academique/`<br>`test/teaching_core/h/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_H_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_H.md`<br>`docs/teaching-core/i18n/tc_i18n_H.json` |
| **Sous-arbre i18n** | `tc.parcours.*` |
| **Contrats produits** | `SessionFeedback`, `StudentConcern`, `PostCoursVM` |
| **Ports produits** | `PortFeedback`, `PortSignalement`, `PortPostCours`, `PortTravailAVenir` |
| **Ports consommés** | `GroupHomeVM` (A) pour le slot « Avant le prochain cours » · `LearningAssignment` (D) · `TeacherStudentProjection` (E) · `LibraryResource`, `ContentRange` (B) |
| **Fichiers interdits spécifiques** | `lib/features/cahier/` — **nom réservé par le chantier enseignant, invisible ici.** Ne jamais créer.<br>`lib/features/tc_espace_groupe/`, `lib/features/tc_mes_groupes/` — **périmètre d'Agent A.** Agent H ne modifie pas la structure du Group Shell : il remplit des slots par port.<br>`lib/core/suivi/service_suivi.dart`, `lib/features/suivi_foyer/vue_suivi_foyer.dart` — à **réutiliser tels quels** (`SortDuCours` en particulier), jamais à éditer.<br>`lib/core/admin/`, `lib/features/admin_*` — ne touche pas au panneau Admin courant.<br>`lib/features/presence_correction/` — l'écran existe, l'adaptateur manque : c'est un CONTRACT_REQUEST, pas une réécriture. |
| **Interdictions de fond** | Ne modifie **pas** le cœur `lesson_reports` si une abstraction suffit. Pas de formulaire narratif. Post-cours **prérempli**, exceptions seulement, cible < 45 s. Feedback **occasionnel**, un tap, aucun commentaire obligatoire, aucun leaderboard, aucun score brut utilisé seul. **Une note interne ne part jamais automatiquement à la famille.** |

### Agent Q — QA

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\q` — `teaching-core/q-qa` |
| **Répertoires possédés (exclusifs)** | `test/teaching_core/q/`<br>`test/teaching_core/fixtures/` |
| **Fichiers documentaires possédés** | `docs/teaching-core/TC_AGENT_Q_REPORT.md`<br>`docs/teaching-core/TC_CONTRACT_REQUEST_Q.md`<br>`docs/teaching-core/TC_TEST_PLAN.md` |
| **Sous-arbre i18n** | aucun |
| **Contrats produits** | fixtures et doubles conformes à `TEACHING_CORE_CONTRACTS.md` |
| **Ports produits** | aucun |
| **Ports consommés** | **tous**, en lecture seule |
| **Fichiers interdits spécifiques** | **Tout `lib/` est READ-ONLY pour Agent Q, sans exception.** Aucun code de production.<br>`test/support/` **[P]**, et tous les répertoires `test/*` existants. |
| **Interdictions de fond** | Si une interface de production n'existe pas encore, Agent Q utilise une fixture ou un double **sans modifier les features**. Agent Q ne « répare » jamais un test d'un autre agent : il le signale dans son rapport. |

### Agent 0 — Coordinateur (moi)

| | |
|---|---|
| **Worktree / branche** | `D:\RA_TC\0` — `teaching-core/0-coordinateur` |
| **Répertoires possédés** | `D:\RA_TC\shared\` (hors dépôt) |
| **Interdiction** | Aucun écran métier, aucun code de production. |

### Agent Z — Intégrateur (après la phase parallèle)

Seul autorisé à modifier, et **uniquement à l'intégration** : le routeur global, la DI / composition root,
`pubspec.yaml`, les exports partagés, les DTO/interfaces partagés, les migrations coordonnées, le token
issuer et les capacités serveur, le wiring LiveKit core, la route d'intégration `Groupe > Réglages`,
`assets/i18n/fr.i18n.json` + la régénération slang, `lib/core/icons/app_icons.dart`,
`test/support/harnais.dart`, `lib/features/_dev/galerie/catalogue_galerie.dart`, et le thème partagé
**seulement si nécessaire et documenté**.

---

## 3. Le mécanisme de port — comment deux agents compilent séparément

Un port est une **classe abstraite Dart** déclarée par son agent **producteur**, au chemin canonique fixé
par `TEACHING_CORE_CONTRACTS.md`. Le consommateur écrit contre **cette signature exacte**.

Pendant la phase parallèle, le fichier du producteur n'existe pas encore dans le worktree du
consommateur. Le consommateur déclare alors un **stub local**, dans son propre répertoire possédé :

```
lib/core/tc_<son_domaine>/ports_externes/<nom_du_port>.dart
```

avec, en première ligne du fichier :

```dart
// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/port_catalogue.dart (Agent B)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 4.2.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
```

Règles du stub :

1. Il contient **uniquement** la classe abstraite et les types de valeur nécessaires, **copiés à
   l'identique** depuis `TEACHING_CORE_CONTRACTS.md`. Jamais une implémentation.
2. Il vit **dans un répertoire possédé par le consommateur** : la disjonction est donc préservée.
3. Toute divergence entre un stub et le contrat canonique est un **BLOCKER** au contrôle pré-merge.
4. Un agent qui a besoin d'une méthode **absente du contrat** ne l'ajoute pas à son stub : il écrit
   `TC_CONTRACT_REQUEST_<X>.md` et Agent 0 ou Agent Z amende le contrat.

---

## 4. Routes — comment poser un écran sans toucher au routeur

`lib/core/router/routes.dart` et `app_router.dart` sont PROTECTED, et `tool/verifier_jetons.dart`
refuse un second `GoRouter` dans `lib/`.

Chaque agent qui produit un écran écrit, dans son répertoire de features :

```
lib/features/tc_<ecran>/routes_tc_<lettre>.dart
```

contenant :

- des constantes de chemin sous le préfixe réservé `/tc/…` (par exemple `/tc/groupes`, `/tc/bibliotheque`) ;
- **une fonction** `List<RouteBase> routesTc<Lettre>()` qui **retourne** des `GoRoute`/`ShellRoute`.

**Cette fonction ne construit jamais un `GoRouter`.** Elle retourne des routes. Agent Z l'appelle depuis
`app_router.dart`, promeut les constantes dans `routes.dart`, et ajuste `redirection.dart` (sans quoi
toute route hors préfixe de rôle est redirigée vers la racine du rôle).

Pour développer et tester sans routeur global, l'agent construit son propre `GoRouter` **dans
`test/teaching_core/<lettre>/support/`** : c'est hors de `lib/`, donc la règle CI ne s'applique pas.

---

## 5. PREUVE DE DISJONCTION

### 5.1 Les vingt-huit préfixes possédés

```
A   lib/core/tc_groupe/
A   lib/core/tc_horloge/
A   lib/features/tc_mes_groupes/
A   lib/features/tc_espace_groupe/
A   test/teaching_core/a/
A   docs/teaching-core/TC_AGENT_A_REPORT.md
A   docs/teaching-core/TC_CONTRACT_REQUEST_A.md
A   docs/teaching-core/i18n/tc_i18n_A.json

B   lib/core/tc_bibliotheque/
B   lib/core/tc_telechargement/
B   lib/features/tc_catalogue/
B   test/teaching_core/b/
B   docs/teaching-core/TC_AGENT_B_REPORT.md
B   docs/teaching-core/TC_CONTRACT_REQUEST_B.md
B   docs/teaching-core/i18n/tc_i18n_B.json

C   lib/core/tc_coran/
C   lib/features/tc_mushaf/
C   test/teaching_core/c/
C   docs/teaching-core/TC_AGENT_C_REPORT.md
C   docs/teaching-core/TC_CONTRACT_REQUEST_C.md
C   docs/teaching-core/i18n/tc_i18n_C.json

D   lib/core/tc_outils/
D   lib/features/tc_dock/
D   test/teaching_core/d/
D   docs/teaching-core/TC_AGENT_D_REPORT.md
D   docs/teaching-core/TC_CONTRACT_REQUEST_D.md
D   docs/teaching-core/i18n/tc_i18n_D.json

E   lib/core/tc_classe/
E   lib/features/tc_classe_live/
E   test/teaching_core/e/
E   docs/teaching-core/TC_AGENT_E_REPORT.md
E   docs/teaching-core/TC_CONTRACT_REQUEST_E.md
E   docs/teaching-core/i18n/tc_i18n_E.json

F   lib/core/tc_realtime/
F   lib/core/tc_etat_partage/
F   test/teaching_core/f/
F   docs/teaching-core/TC_AGENT_F_REPORT.md
F   docs/teaching-core/TC_CONTRACT_REQUEST_F.md
F   docs/teaching-core/i18n/tc_i18n_F.json

G   lib/core/tc_observation/
G   lib/features/tc_observation_ui/
G   test/teaching_core/g/
G   docs/teaching-core/TC_AGENT_G_REPORT.md
G   docs/teaching-core/TC_CONTRACT_REQUEST_G.md
G   docs/teaching-core/i18n/tc_i18n_G.json

H   lib/core/tc_parcours/
H   lib/features/tc_flux_academique/
H   test/teaching_core/h/
H   docs/teaching-core/TC_AGENT_H_REPORT.md
H   docs/teaching-core/TC_CONTRACT_REQUEST_H.md
H   docs/teaching-core/i18n/tc_i18n_H.json

Q   test/teaching_core/q/
Q   test/teaching_core/fixtures/
Q   docs/teaching-core/TC_AGENT_Q_REPORT.md
Q   docs/teaching-core/TC_CONTRACT_REQUEST_Q.md
Q   docs/teaching-core/TC_TEST_PLAN.md
```

### 5.2 Vérification par parent — aucun nom n'est préfixe d'un autre

**Sous `lib/core/` — 11 noms, tous distincts et deux à deux non préfixes :**

| Nom | Propriétaire | Premier caractère qui le sépare de tous les autres |
|---|---|---|
| `tc_bibliotheque` | B | `tc_b…` unique |
| `tc_classe` | E | `tc_c` partagé avec `tc_coran`, divergence à l'index 4 : `l` ≠ `o` |
| `tc_coran` | C | `tc_c` partagé avec `tc_classe`, divergence à l'index 4 : `o` ≠ `l` |
| `tc_etat_partage` | F | `tc_e…` unique |
| `tc_groupe` | A | `tc_g…` unique |
| `tc_horloge` | A | `tc_h…` unique |
| `tc_observation` | G | `tc_o` partagé avec `tc_outils`, divergence à l'index 4 : `b` ≠ `u` |
| `tc_outils` | D | `tc_o` partagé avec `tc_observation`, divergence à l'index 4 : `u` ≠ `b` |
| `tc_parcours` | H | `tc_p…` unique |
| `tc_realtime` | F | `tc_r…` unique |
| `tc_telechargement` | B | `tc_t…` unique |

**Sous `lib/features/` — 8 noms, tous distincts et deux à deux non préfixes :**

| Nom | Propriétaire | Divergence |
|---|---|---|
| `tc_catalogue` | B | `tc_c` partagé avec `tc_classe_live`, divergence à l'index 4 : `a` ≠ `l` |
| `tc_classe_live` | E | `tc_c` partagé avec `tc_catalogue`, divergence à l'index 4 : `l` ≠ `a` |
| `tc_dock` | D | `tc_d…` unique |
| `tc_espace_groupe` | A | `tc_e…` unique |
| `tc_flux_academique` | H | `tc_f…` unique |
| `tc_mes_groupes` | A | `tc_m` partagé avec `tc_mushaf`, divergence à l'index 4 : `e` ≠ `u` |
| `tc_mushaf` | C | `tc_m` partagé avec `tc_mes_groupes`, divergence à l'index 4 : `u` ≠ `e` |
| `tc_observation_ui` | G | `tc_o…` unique dans `features/` |

**Sous `test/teaching_core/` — 10 noms :** `a`, `b`, `c`, `d`, `e`, `f`, `g`, `h`, `q`, `fixtures`.
Les neuf lettres sont de longueur 1 et deux à deux différentes, donc aucune n'est préfixe d'une autre.
`fixtures` commence par `f`… mais **`f` et `fixtures` sont deux segments de chemin distincts** :
`test/teaching_core/f/` et `test/teaching_core/fixtures/` diffèrent dès le séparateur qui suit `f`.
La comparaison se fait **segment par segment**, jamais caractère par caractère sur la chaîne entière.

**Sous `docs/teaching-core/` :** un fichier nommé par agent, jamais un répertoire partagé en écriture.
`TC_AGENT_A_REPORT.md` … `TC_AGENT_Q_REPORT.md`, `TC_CONTRACT_REQUEST_A.md` …
`TC_CONTRACT_REQUEST_Q.md`, `TC_TEST_PLAN.md`, et `docs/teaching-core/i18n/tc_i18n_<X>.json`.
Neuf lettres distinctes ⇒ neuf noms distincts, aucun n'étant préfixe d'un autre puisqu'ils ont tous la
même longueur au sein de leur famille et se terminent par `.md` / `.json`.

### 5.3 Vérification croisée avec le chantier enseignant

Aucun des 28 préfixes ci-dessus n'apparaît dans `D:\RA_TC\PROTECTED_FILES_SNAPSHOT.md`, ni comme fichier
modifié, ni comme fichier créé. Les six noms que le chantier enseignant a pris
(`lib/core/enseignant/`, `lib/features/fiche_groupe/`, `revue_groupe/`, `salle_enseignant/`, `cahier/`,
`bienvenue_enseignant/`) ne portent **aucun** préfixe `tc_`, donc aucune collision n'est possible.
Le répertoire `docs/parallel-reports/` qu'il occupe est **disjoint** de `docs/teaching-core/`.
Le répertoire `test/features/` qu'il modifie est **disjoint** de `test/teaching_core/`.

### 5.4 Conclusion

**Aucun chemin n'est attribué à deux agents. Aucun préfixe possédé n'est préfixe d'un autre préfixe
possédé. Aucun préfixe possédé ne recoupe un chemin du chantier enseignant.**

La condition STOP de la spec (§ PROMPT 0, « les agents A-H/Q ne démarrent pas tant que […] l'ownership
n'a aucun chevauchement ») est **levée**.

---

## 6. Ce qui reste partagé, et par qui il passe

Sept besoins sont, par nature, communs à plusieurs agents. Aucun n'est confié à un agent de feature.

| Besoin commun | Passe par | Mécanisme |
|---|---|---|
| Une route et une entrée de navigation | Agent Z | `routesTc<X>()` + CONTRACT_REQUEST pour `nav_shell.dart` |
| Un libellé | Agent Z | `tc_i18n_<X>.json` + façade `// TC-I18N:` (PROTECTED §4) |
| Une icône | Agent Z | Section « ICÔNES DEMANDÉES » du CONTRACT_REQUEST, placeholder `// TC-ICONE:` en attendant |
| Un jeton de design | Agent Z | CONTRACT_REQUEST, documenté |
| Une table, une vue, une RPC, une policy | Agent Z | Section « DEMANDE SQL » du CONTRACT_REQUEST (PROTECTED §3) |
| Une dépendance `pubspec.yaml` | Agent Z | CONTRACT_REQUEST, pesé contre le commentaire `sentry_flutter`/`path_provider` |
| Un faux de test réellement partagé | Agent Z | `test/teaching_core/<agent>/faux/` d'abord, consolidation ensuite |
