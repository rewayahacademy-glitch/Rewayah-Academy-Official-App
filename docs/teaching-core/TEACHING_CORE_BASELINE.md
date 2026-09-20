# TEACHING_CORE_BASELINE.md

> Document normatif produit par **Agent 0 (coordinateur)** le 20/09/2026.
> Tout agent Teaching Core lit ce document **en entier** avant sa première action.
> Emplacement canonique des six documents : `D:\RA_TC\shared\` (hors dépôt).
> Agent Z les commitera dans `docs/teaching-core/` au moment de l'intégration.

---

## 1. Le gel

```
TEACHING_BASELINE_SHA = 550e605
```

Commit complet : `550e6059654843274e5039e203ad296c565a08b6`
Message : `audit(admin): controle final de placement UX, correction bottom sheet Demandes`
Dépôt canonique : `D:\RA _APP\RA -OFFICIAL-APP` (branche `main`)

Les trois commits qui précèdent, pour situer :

| SHA | Objet |
|---|---|
| `550e605` | audit(admin) : contrôle final de placement UX (**baseline**) |
| `4e22273` | docs(admin) : addendum Sécurité/Direction/Accueil |
| `6a323b5` | feat(admin) : lot CFG-01, domaine Configuration |

---

## 2. INTERDICTION ABSOLUE — le worktree du chantier enseignant

Un **autre chantier multi-agents**, dit *chantier ENSEIGNANT*, travaille **en ce moment même** dans
`D:\RA _APP\RA -OFFICIAL-APP`, avec **74 fichiers modifiés ou créés non commités**.

Aucun agent Teaching Core ne doit, sous aucun prétexte :

- écrire, créer ou supprimer un fichier dans `D:\RA _APP\RA -OFFICIAL-APP` ;
- y exécuter `git add`, `git stash`, `git reset`, `git checkout`, `git clean`, `flutter pub get`, `dart run` ;
- y poser son répertoire courant (`cd`, `Set-Location`), même pour une lecture ;
- lire un fichier de ce worktree **dans l'intention de l'écrire ailleurs à l'identique**.

La cartographie du travail enseignant en cours est figée dans
`D:\RA_TC\PROTECTED_FILES_SNAPSHOT.md` et reprise dans `TEACHING_CORE_PROTECTED_FILES.md`.
C'est la **seule** source autorisée sur l'état de ce chantier.

**Conséquence structurante :** le travail enseignant n'est **pas commité**. Les worktrees Teaching Core,
détachés sur `550e605`, ne le contiennent donc pas, **et c'est voulu**. Les répertoires
`lib/features/fiche_groupe/`, `lib/features/revue_groupe/`, `lib/features/salle_enseignant/`,
`lib/features/cahier/`, `lib/features/bienvenue_enseignant/`, `lib/core/enseignant/` et les migrations
`0025` à `0029` **existent chez eux et sont invisibles chez nous**. Un agent qui « ne les voit pas »
ne doit surtout pas en conclure qu'ils sont libres.

---

## 3. Les dix worktrees Teaching Core

Tous détachés de `550e605`, tous déjà créés et vérifiés.

| Agent | Worktree | Branche |
|---|---|---|
| 0 — Coordinateur | `D:\RA_TC\0` | `teaching-core/0-coordinateur` |
| A — Group Space | `D:\RA_TC\a` | `teaching-core/a-group-space` |
| B — Library Core | `D:\RA_TC\b` | `teaching-core/b-library` |
| C — Quran Engine | `D:\RA_TC\c` | `teaching-core/c-quran` |
| D — Teaching Tools | `D:\RA_TC\d` | `teaching-core/d-teaching-tools` |
| E — Classroom Shell | `D:\RA_TC\e` | `teaching-core/e-classroom` |
| F — Realtime Protocol | `D:\RA_TC\f` | `teaching-core/f-realtime` |
| G — Observation & Policies | `D:\RA_TC\g` | `teaching-core/g-observation` |
| H — Academic Flow | `D:\RA_TC\h` | `teaching-core/h-academic` |
| Q — QA | `D:\RA_TC\q` | `teaching-core/q-qa` |

### Règle d'isolation

1. Un agent ne travaille **que** dans son worktree, désigné par sa lettre.
2. Un agent ne fait **jamais** `git checkout`, `git merge`, `git rebase` ni `git cherry-pick` depuis la
   branche d'un autre agent. Aucun agent ne rebase sur une branche feature.
3. Aucun agent ne pousse ni ne merge vers `main`. Le merge appartient à Agent Z, après le contrôle pré-merge.
4. `D:\RA_TC\0` est le worktree de lecture de référence d'Agent 0. Les autres agents peuvent l'ouvrir
   en **lecture seule** pour vérifier un chemin de la baseline, jamais pour y écrire.
5. Les six documents partagés vivent dans `D:\RA_TC\shared\`. Ils sont **lecture seule** pour A…H et Q.
   Seul Agent 0 les amende, et seulement sur demande explicite de l'opérateur.

---

## 4. État Flutter et outillage

```
Flutter 3.47.2 • channel stable
Framework • revision d3b14c8769 • 2026-08-26
Engine    • hash 1cf1c4773fb941c4c74a7f8bb144a8837596c0f4 (revision a804b26164)
Tools     • Dart 3.13.2 • DevTools 2.60.0
```

Dépendances déjà présentes et utilisables sans rien ajouter (`pubspec.yaml`, **gelé**) :
`flutter_riverpod ^3.4.3`, `go_router ^18.0.1`, `supabase_flutter ^2.17.2`, `drift ^2.34.4`,
`drift_flutter ^0.3.1`, `flutter_cache_manager ^3.4.2`, `file_picker ^12.2.0`, `just_audio ^0.10.6`,
`crypto ^3.0.7`, `connectivity_plus ^7.3.1`, `slang ^4.19.1`, `livekit_client ^2.12.0`,
`qr_flutter`, `adhan`, `sentry_flutter` (épinglé en 8.x).

**Absents et non ajoutables en phase parallèle** : aucun moteur PDF (`pdfx`, `syncfusion_flutter_pdfviewer`,
`flutter_pdfview`, `pdfrx`, `printing`), pas de `flutter_markdown`, pas de `share_plus`,
**pas de `timezone`, pas de `tz`, pas de `flutter_timezone`, pas de `intl`**.

> ⚠ `pubspec.yaml` porte un commentaire normatif : `sentry_flutter` est bloqué en 8.x pour ne pas
> rétrograder `path_provider_android`, qui porte le répertoire du cache Drift, « donc le mode hors ligne,
> qui est un invariant produit ». Toute demande de dépendance se pèse contre ce commentaire.

### Bruit de worktree à ne pas commiter

`D:\RA_TC\0` présente trois fichiers modifiés par un `flutter pub get` local :
`windows/flutter/generated_plugin_registrant.cc`, `generated_plugin_registrant.h`, `generated_plugins.cmake`.
Le même bruit apparaîtra dans chaque worktree. **Aucun agent ne les commite.** Ils sont listés PROTECTED.

### Le gendarme local

`tool/verifier_jetons.dart` (27,8 Ko) s'exécute en local **et en CI**. Il fait échouer le build sur :
un second `GoRouter` construit hors de `lib/core/router/app_router.dart` ; une couleur littérale hors de
`lib/core/theme/app_palette.dart` ; un `IconData` ou un `Icons.` hors de `lib/core/icons/app_icons.dart` ;
un espacement hors échelle ; un `BorderRadius.circular(n)` littéral ; une `BoxShadow` ; un `letterSpacing` ;
une `Duration(milliseconds:)` ou une `Curves.` d'interface ; un `Scaffold` nu ; un `EdgeInsets.fromLTRB` ;
un `Alignment` non directionnel ; un tiret cadratin.

**À lire avant d'écrire une ligne**, avec `lib/CLAUDE.md` (89 lignes, les règles non négociables du front).

---

## 5. Ce qui existe déjà et qui est solide

Le détail chemin par chemin est dans `TEACHING_CORE_EXISTING_MAPPING.md`. En une page :

| Domaine | Verdict |
|---|---|
| **Groupes** | Modèle complet côté administration : `groupes` + `groupe_membres` (0017, durcies 0019), plafond en base, 5 RPC d'écriture, 2 RPC de lecture, `ServiceGroupes`, écran `/admin/operations/groupes`. |
| **Coran** | Corpus complet et vérifié : 114 sourates, 30 juz, 604 pages, 6236 versets (Tanzil Uthmani v1.1, CC-BY 3.0, migrations 0007 + 0013). Service, vue pure, écran ELV-04, route, i18n, police arabe embarquée. |
| **LiveKit** | Chaîne entière : contrat abstrait, implémentation unique, pré-vol matériel, écran salle 4 rôles, fonctions Edge `create-room-token` / `livekit-webhook`, migration 0010 (jeton, capacités, webhook idempotent). |
| **Présence** | 14 états dérivés en base par `etat_presence()`, vue bornée `presence_seance_v`, service Dart, composant `LignePresence`, 15 libellés FR. Mûr. |
| **Observation** | Contrôleur incognito **complet** de bout en bout (0012 : `rejoindre_observation`, invisibilité sur 4 surfaces) ; tuteur observateur **existant** (`assister_seance`), muet et sans caméra par dérivation du rôle. |
| **Audit** | `audit_logs` partitionnée et chaînée par hachage (0001), `journal_audit()` / `verifier_chaine_audit()` (0009), écran ADM-04. |
| **Socle** | Un seul routeur, dix fichiers de jetons de design, 38 widgets partagés, catalogue d'icônes unique, enums miroirs du SQL, session lue du JWT. Très complet, très normatif. |
| **Cache/offline** | Drift (4 tables), `flutter_cache_manager` encapsulé, file de synchro idempotente, `horsLigneProvider`, `OfflineBanner`. Socle présent, à moitié câblé. |

---

## 6. Manques bloquants — à ne pas masquer, à ne pas contourner

Ces constats sont **mesurés**, pas supposés. Chacun désigne l'agent qui doit produire un
`TC_CONTRACT_REQUEST` plutôt qu'inventer.

### 6.1 BLOQUANT — Fidélité Mushaf 604 pages : les données ne la permettent pas → **Agent C**

Trois manques cumulés, chacun suffisant :

1. **`verset.ligne` est NULL sur les 6236 lignes.** La colonne existe (0007), l'index `verset_page_idx
   (mushaf_id, page_numero, ligne)` la prévoit, mais les `insert` de `0013_corpus_coranique.sql`
   ne listent que `(mushaf_id, sourate_numero, numero, texte, page_numero)`. La migration l'assume et
   l'explique : le layout QPC v2 compte 83 668 mots contre 77 881 pour Tanzil, et elle refuse de deviner
   une correspondance sur un texte sacré.
2. **Aucune granularité sub-verset.** Pas de table `mot`, pas de segment. Or `verset.page_numero` désigne
   la page où le verset **commence**. Un verset à cheval sur deux pages est entièrement attribué à une
   seule. Les limites de page réelles ne sont donc pas reproductibles.
3. **Aucune police glyphe-par-page ni asset de layout.** `assets/fonts/UthmanTahaNaskh-Regular.otf`
   (164 684 octets) est une police naskh de texte courant : la largeur des lignes dépend du moteur de
   texte, pas de l'édition. Le jeu type QCF (une police par page, 604 fichiers) est absent, et
   `pubspec.yaml` est gelé. `docs/architecture/etape-5-salle-coran-presence.md` lignes 89-93 laisse
   d'ailleurs la question explicitement ouverte.

**Conduite imposée à Agent C** — la spec §7.2 est formelle : « si les données disponibles ne permettent
pas une fidélité suffisante, l'agent doit STOP et documenter le manque. Il ne doit pas improviser une
composition. » Agent C **ne fabrique pas une fausse page**. Il :
- construit le moteur avec une **source de layout enfichable** (`PortLayoutMushaf`) et une implémentation
  `LayoutIndisponible` qui rend un état explicite, jamais un rendu approximatif ;
- livre pleinement les deux modes **faisables** aujourd'hui : mode verset reflowable responsive, et mode
  focus/classe ;
- produit `docs/teaching-core/TC_CONTRACT_REQUEST_C.md` chiffrant les trois manques et les options
  (peupler `verset.ligne` par migration ; acquérir un jeu de polices QCF avec sa licence ; ou embarquer
  un fichier de coordonnées de layout).

Point juridique à signaler dans le même document : `assets/fonts/` contient un fichier de licence pour
Bricolage, InstrumentSans et Phosphor, **mais aucun pour UthmanTahaNaskh ni pour NotoSansArabic**. Une
police du Complexe du Roi Fahd redistribuée sans notice est un risque à nommer.

### 6.2 BLOQUANT — Le Groupe et la Séance ne sont reliés par rien → **Agents A, E, H**

`public.sessions` (0001) n'a **aucune colonne `groupe_id`**, et aucune table de jonction n'existe
(vérifié sur les 24 migrations). Le seul matérialisateur d'occurrences, `materialiser_seances(p_assignment_id)`
(0005), lit `teacher_student_assignments`, le modèle 1-à-1 d'avant le pivot, et ignore `groupes`.

Conséquence mesurée : **un groupe créé par `creer_groupe()` ne produit aujourd'hui aucune séance**, donc
aucune prochaine séance, aucun countdown, aucun accès salle. L'invariant produit « la Classe Live est un
état temporaire du Groupe » n'a **aucun support en base**.

Conduite imposée : A, E et H travaillent **contre les ports et des fixtures**, jamais contre une requête
réelle. La demande de matérialisation par groupe va dans `TC_CONTRACT_REQUEST_A.md`.

### 6.3 BLOQUANT — Fenêtre de connexion : T-10 en dur, la spec veut T-20 configurable → **Agent A**

La valeur est **dupliquée trois fois** et n'est nulle part configurable :

| Endroit | Valeur |
|---|---|
| `autoriser_jeton_video()` (0010) | refus avant `started_at - 10 min`, refus après `ended_at + 15 min` |
| `etat_presence()` (0010) | T-10 pour distinguer `planifiee` de `en_attente` |
| `lib/features/journee/journee_page.dart` | `seuilOuvertureSalle = Duration(minutes: 10)` — **PROTECTED** |
| `lib/core/controle/service_controle.dart` | `graceApresFin = Duration(minutes: 15)` |

Elle n'est **pas** dans `app_config`, contrairement aux trois seuils de présence. Passer à T-20 est une
migration **plus** une édition d'un fichier PROTECTED. Agent A ne pose **pas** une quatrième constante :
il lit `join_opens_at` depuis `SessionClockVM`, alimenté par un port, et demande la remontée vers
`app_config` dans `TC_CONTRACT_REQUEST_A.md`.

### 6.4 BLOQUANT — Aucun temps académique, aucun `attendance_records` → **Agents A, G, Q**

`etat_presence()` rend un **état instantané**, jamais une durée créditée. Il n'existe ni table
`attendance_records`, ni cumul de minutes, ni reconstruction d'intervalles.
`session_participants.entered_at` / `exited_at` existent depuis 0001 mais **ne sont jamais écrites**
(deux seules occurrences dans le dépôt : leur déclaration).

Pire, deux défauts latents se déclencheront le jour où la fenêtre passera à T-20 :
`etat_presence()` rend `presente` dès le premier `joined` **sans jamais comparer à `started_at`**, et
`VuePresence.depuis` calcule la durée affichée depuis `entre_le` brut. Un élève entré à T-20 verrait
« en salle depuis 38 min » pour un cours commencé il y a 18 min.

Conduite : la correction de `VuePresence` (`lib/core/presence/vue_presence.dart`, **non protégé**) est
un point de contrat, pas une initiative d'agent. Elle va dans `TC_CONTRACT_REQUEST_A.md`.

### 6.5 BLOQUANT — La Bibliothèque n'existe à aucun niveau → **Agent B**

Aucune notion de ressource générique, ni Dart ni SQL. Inventaire complet des `create table` de 0001 à
0024 vérifié : aucune table `library_resource`, `resource_version`, `download_asset`, `resource_cover`,
`resource_assignment`. Les **deux seuls** buckets Storage sont `kyc` et `avatars` (0004). Aucun moteur PDF
dans `pubspec.yaml`. `assets/` ne contient que des polices et deux JSON i18n ; `assets/audio/fr/` ne
contient qu'un `.gitkeep`.

Agent B part de zéro **côté modèle**, mais **pas côté briques** : cache média, file de synchro idempotente,
sélecteur de fichiers, URL signée Storage et versionnement immuable existent déjà (voir MAPPING §DOUBLONS).

> Lecture obligatoire avant toute conception : `docs/produit/bibliotheque-contenu.md`, cahier des charges
> opérateur **déjà écrit** pour ce domaine exact (modules Coran / Hisn al-Muslim / tajwid Markdown /
> alphabet, budget 20 Mo, « zéro PDF comme outil principal de texte », micro-paquets JSON de synchro).
> Il laisse trois questions ouvertes. Le confronter à la spec **avant** d'en rédiger un nouveau.

### 6.6 BLOQUANT — Aucune politique d'observation, aucune table de visite → **Agent G**

Rien n'existe pour `GuardianObservationPolicy` : pas de `max_visits_per_session`, pas de
`max_total_observation_seconds`, pas d'héritage Académie → Groupe. `groupes` n'a aucune colonne de
politique et `rule_overrides` (0005) est scopé **profil**, jamais groupe. La chaîne `policy_version`
n'apparaît **nulle part** dans le dépôt.

Rien n'existe non plus pour `GuardianSessionVisit` : `session_events` ne porte que `joined`/`left` avec
`server_ts`, sans `duration_seconds`, sans `visit_number`, sans `policy_version`. Aucun contrôle de quota
**avant** l'émission du jeton, aucune durée bornée propre au tuteur (son TTL est celui de tout le monde),
aucune révocation serveur à la limite. Et l'**Admin ne peut pas entrer** : `rejoindre_observation()` lève
`insufficient_privilege` pour tout rôle autre que `controller`, et l'enum `participant_role` n'a que
quatre valeurs.

### 6.7 BLOQUANT — Aucun canal de données temps réel côté Flutter → **Agent F**

Zéro occurrence de `publishData`, `DataReceived`, `DataPacket`, `setMetadata` dans tout le dépôt.
Bonne nouvelle : **le droit est déjà accordé de bout en bout** — `autoriser_jeton_video()` calcule
`v_publier_data := (role = 'teacher')`, `_shared/livekit.ts` le pose en `canPublishData`, et
`CapacitesSalle.peutPublierDonnees` l'expose en Dart. Rien à demander au serveur pour émettre.
En revanche `VideoSessionProvider` n'expose **aucune primitive d'envoi** : séparer *reliable* et *lossy*
exige une extension du contrat core → `TC_CONTRACT_REQUEST_F.md`.
Par ailleurs, **Realtime Supabase n'est utilisé nulle part** dans `lib/` (zéro `.channel`, zéro
`onPostgresChanges`) : la présence est un polling de 20 s. Aucune infrastructure Realtime n'existe.

### 6.8 BLOQUANT — La session LiveKit meurt avec l'écran → **Agent E**

Le moteur est bien un Provider **racine** (`moteurSalleProvider`, `livekit_session_provider.dart:418`),
donc unique pour toute l'application. Mais `_SallePageEtat.initState()` appelle `_entrer()` et
`dispose()` appelle inconditionnellement `_moteur.quitter()` (`salle_page.dart:111` et `:122`). En
pratique **le lifecycle de la room est attaché à la page**, et `/salle` n'est dans aucune `ShellRoute` :
naviguer ailleurs démonte `SallePage` et coupe LiveKit. C'est exactement ce que la spec §9.4 interdit.
Le socle est bon, **le contrôleur applicatif de session manque**, et `salle_page.dart` est PROTECTED.

### 6.9 Contrainte transverse — aucune migration en phase parallèle

Dernière migration de la baseline : `0024`. Le chantier enseignant occupe déjà **`0025` à `0029`**
(non commitées). Toute migration Teaching Core partirait donc de `0030+`.
**C'est interdit.** Voir `TEACHING_CORE_DECISIONS.md`, décision D-12.

### 6.10 Contradiction à arbitrer — « Amina B. »

La maquette de la spec §10.1 affiche `Amina B.`, donc une initiale de nom de famille, alors que
`0005_dashboards_affectation_regles.sql` (lignes 699-722) a **explicitement retiré** `last_name` de
`teacher_roster_v` au nom d'ADR-008. **Arbitrage tranché ici** : voir `TEACHING_CORE_DECISIONS.md`,
décision D-08. Personne ne réintroduit `last_name`.

---

## 7. Condition de démarrage — STOP

Les agents A, B, C, D, E, F, G, H et Q **ne démarrent pas** tant que les six documents suivants
n'existent pas dans `D:\RA_TC\shared\` et que l'ownership n'a aucun chevauchement :

- `TEACHING_CORE_BASELINE.md` (ce fichier)
- `TEACHING_CORE_EXISTING_MAPPING.md`
- `TEACHING_CORE_PROTECTED_FILES.md`
- `TEACHING_CORE_FILE_OWNERSHIP.md`
- `TEACHING_CORE_CONTRACTS.md`
- `TEACHING_CORE_DECISIONS.md`

La preuve de non-chevauchement est la section **PREUVE DE DISJONCTION** de
`TEACHING_CORE_FILE_OWNERSHIP.md`.
