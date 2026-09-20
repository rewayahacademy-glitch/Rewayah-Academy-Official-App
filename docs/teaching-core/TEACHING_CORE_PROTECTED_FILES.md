# TEACHING_CORE_PROTECTED_FILES.md

> Liste exhaustive des fichiers que **aucun agent Teaching Core (A…H, Q) ne peut modifier**.
> Trois sources : (1) le snapshot du chantier enseignant en cours, (2) le socle partagé gelé par la
> spec §16.2, (3) les artefacts générés ou de plateforme.
>
> **Règle unique et sans exception** : un fichier de ce document est **READ-ONLY**. Un agent qui en a
> besoin **ne le modifie pas** : il écrit sa demande, signature précise à l'appui, dans
> `docs/teaching-core/TC_CONTRACT_REQUEST_<X>.md` et **continue son travail derrière un port local**.
> Toute modification d'un fichier de ce document est un **BLOCKER** au contrôle pré-merge.

---

## 0. Comment lire ce document

| Colonne | Sens |
|---|---|
| **Propriétaire** | Qui a le droit de toucher le fichier : `ENSEIGNANT` (autre chantier), `Z` (Agent Z à l'intégration), `PLATEFORME` (généré, personne ne l'édite à la main). |
| **Raison** | Pourquoi c'est gelé. |
| **À faire à la place** | La conduite exacte de l'agent qui en a besoin. |

---

## 1. Fichiers réservés par le chantier ENSEIGNANT — zone de collision

Source : `D:\RA_TC\PROTECTED_FILES_SNAPSHOT.md`, worktree `D:\RA _APP\RA -OFFICIAL-APP`, HEAD `550e605`,
74 entrées non commitées.

### 1.1 Modifiés (` M `)

| Chemin | Propriétaire | Raison | À faire à la place |
|---|---|---|---|
| `assets/i18n/fr.i18n.json` | ENSEIGNANT | Source unique des 617 libellés, déjà éditée là-bas. | **§4 de ce document** (mécanisme i18n). |
| `lib/core/i18n/strings.g.dart` | PLATEFORME | Généré par slang, versionné. | Ne jamais l'ouvrir. Régénération par Agent Z. |
| `lib/core/i18n/strings_fr.g.dart` | PLATEFORME | 244 Ko générés, **non fusionnables à la main**. | Idem. |
| `lib/core/router/app_router.dart` | ENSEIGNANT + Z | Seul `GoRouter` du produit (règle CI). | Exposer `List<RouteBase> routesTc<X>()` — décision **D-04**. |
| `lib/core/router/routes.dart` | ENSEIGNANT + Z | Table des constantes de chemin. | Déclarer ses chemins en constantes **dans son propre namespace**, préfixe `/tc/…` réservé. Agent Z les promeut. |
| `lib/core/widgets/nav_shell.dart` | ENSEIGNANT + Z | Navigation de premier niveau, **plafond dur de 4 destinations tenu par assertion**. | Demander la destination dans son CONTRACT_REQUEST. **C'est un arbitrage produit.** Sans elle l'écran n'existe pas (cf. `feedback_brancher_l_entree_pas_la_route`). |
| `lib/core/coran/service_coran.dart` | ENSEIGNANT | Modèle et service du corpus. | **Agent C** : adaptateur en lecture dans `lib/core/tc_coran/`. Ne jamais éditer, ne jamais dupliquer. |
| `lib/core/video/video_session_provider.dart` | ENSEIGNANT + Z | Contrat vidéo abstrait (ADR-001). | **Agent F** : adapter au-dessus. Une primitive d'envoi manque → `TC_CONTRACT_REQUEST_F.md`. |
| `lib/core/video/livekit_session_provider.dart` | ENSEIGNANT + Z | Seule implémentation LiveKit. | Jamais une seconde `Room`. |
| `lib/core/video/pre_vol.dart` | ENSEIGNANT | Preflight matériel. | **Agent E** : consommer `preVolProvider` tel quel. |
| `lib/features/salle/salle_page.dart` | ENSEIGNANT | Écran salle des 4 rôles. | **Agent E** : nouveau namespace `lib/features/tc_classe_live/`. Interdit d'éditer. |
| `lib/features/salle/vue_salle.dart` | ENSEIGNANT | Logique pure de la salle (`PhaseSalle`, `CauseImpasse`, `RoleSalle`). | **Agent E** : la **consommer** en lecture, ne pas la recopier. |
| `lib/features/journee/journee_page.dart` | ENSEIGNANT | ENS-02, porte `seuilOuvertureSalle = 10 min`. | **Agent A** : ne pas poser une quatrième constante de fenêtre. `TC_CONTRACT_REQUEST_A.md`. |
| `lib/features/creneaux/creneaux_page.dart` | ENSEIGNANT | ENS-06. | Lecture seule. |
| `lib/features/profil_enseignant/profil_enseignant_page.dart` | ENSEIGNANT | ENS-05, seul embryon de roster enseignant. | **Agent E** : ne pas le doubler. Quand le roster de groupe existera, la ligne `seances.map(eleveId).toSet()` devra être **remplacée par Agent Z**, pas doublée. |
| `lib/features/dossier/depot_piece_page.dart` | ENSEIGNANT | KYC. | Hors périmètre Teaching Core. |
| `docs/architecture/decisions.md` | ENSEIGNANT + Z | Registre ADR (ADR-001, 004, 005, 008, 009, 010, 011, 017, 023, 024, 025). | **Aucun agent n'écrit d'ADR.** Une décision nouvelle va dans son CONTRACT_REQUEST ; Agent Z rédige l'ADR. |
| `docs/design/08-catalogue-ecrans.md` | ENSEIGNANT + Z | Catalogue des écrans. | Idem : l'agent décrit ses écrans dans `TC_AGENT_<X>_REPORT.md`. |
| `docs/parallel-reports/00-baseline.md` | ENSEIGNANT | Baseline du chantier enseignant. | **Lecture seule.** Ne pas confondre avec notre baseline. |
| `test/support/harnais.dart` | ENSEIGNANT + Z | Harnais unique, 40,5 Ko, ~25 faux. | **§5 de ce document.** |
| `test/features/creneaux_test.dart` | ENSEIGNANT | — | Tests Teaching Core dans `test/teaching_core/<agent>/`. |
| `test/features/dossier_test.dart` | ENSEIGNANT | — | Idem. |
| `test/features/inscription_test.dart` | ENSEIGNANT | — | Idem. |
| `test/features/journee_test.dart` | ENSEIGNANT | — | Idem. |
| `test/features/profil_enseignant_test.dart` | ENSEIGNANT | — | Idem. |
| `test/features/salle_test.dart` | ENSEIGNANT | 25 cas, **patron d'override à reproduire**. | **Lire pour apprendre le patron**, écrire ailleurs. |
| `test/router/navigation_test.dart` | ENSEIGNANT | — | Idem. |
| `test/router/redirection_test.dart` | ENSEIGNANT | — | Idem. |
| `test/video/modeles_video_test.dart` | ENSEIGNANT | — | Idem. |
| `test/video/vue_salle_test.dart` | ENSEIGNANT | 23 cas sur `VueSalle.depuis`. | Idem. |
| `windows/flutter/generated_plugin_registrant.cc` | PLATEFORME | Généré par `pub get`. | **Ne jamais commiter**, même modifié localement. |
| `windows/flutter/generated_plugins.cmake` | PLATEFORME | Idem. | Idem. |
| `windows/flutter/generated_plugin_registrant.h` | PLATEFORME | Idem (bruit constaté dans `D:\RA_TC\0`). | Idem. |

### 1.2 Créés par le chantier enseignant (`??`) — **invisibles depuis notre baseline**

> ⚠ Ces chemins **n'existent pas** dans les worktrees Teaching Core. Un agent qui constate leur absence
> ne doit surtout pas en conclure qu'ils sont libres. **Les réutiliser provoquerait une collision
> garantie à l'intégration.**

| Chemin | Nature | Interdiction |
|---|---|---|
| `lib/core/enseignant/` | Répertoire | **Nom réservé.** Ne jamais créer ce répertoire. |
| `lib/features/bienvenue_enseignant/` | Répertoire | Idem. |
| `lib/features/cahier/` | Répertoire | Idem. **Collision directe avec `lesson_reports`** — Agent H coordonne via Agent Z. |
| `lib/features/fiche_groupe/` | Répertoire | Idem. **Collision directe avec le roster de groupe** — Agent E coordonne via Agent Z. |
| `lib/features/revue_groupe/` | Répertoire | Idem. |
| `lib/features/salle_enseignant/` | Répertoire | Idem. **Une salle enseignant est déjà en construction là-bas** — Agent E coordonne via Agent Z. |
| `lib/features/profil_enseignant/service_acceptations.dart` | Fichier | Nom réservé. |
| `lib/features/profil_enseignant/service_declaration.dart` | Fichier | Nom réservé. |
| `supabase/migrations/0025_role_enseignant.sql` | Migration | **Numéros 0025-0029 pris.** |
| `supabase/migrations/0026_durcissement_execute_enseignant.sql` | Migration | Idem. |
| `supabase/migrations/0027_maj_profil_enseignant.sql` | Migration | Idem. |
| `supabase/migrations/0028_maj_profil_enseignant_revoke_anon.sql` | Migration | Idem. |
| `supabase/migrations/0029_fermeture_dossiers_en_attente_anon.sql` | Migration | Idem. |
| `test/coran/service_coran_test.dart` | Test | Nom réservé. **N'existe pas chez nous** (`test/coran/` ne contient que `vue_lecteur_test.dart`). |
| `test/features/bienvenue_enseignant_test.dart` | Test | Nom réservé. |
| `test/features/cahier_test.dart` | Test | Nom réservé. |
| `test/features/fiche_groupe_test.dart` | Test | Nom réservé. |
| `test/features/revue_groupe_test.dart` | Test | Nom réservé. |
| `test/features/salle_enseignant_test.dart` | Test | Nom réservé. |
| `docs/architecture/TEACHER_DUPLICATES_AUDIT.md` | Doc | Nom réservé. |
| `docs/architecture/TEACHER_FILE_OWNERSHIP.md` | Doc | Nom réservé. |
| `docs/architecture/TEACHER_PARALLEL_BASELINE.md` | Doc | Nom réservé. |
| `docs/architecture/TEACHER_SHARED_CONTRACTS.md` | Doc | Nom réservé. |
| `docs/parallel-reports/AGENT_A_REPORT.md` … `AGENT_E_REPORT.md` | Docs | **COLLISION DE NOMS GARANTIE.** → §6. |
| `docs/parallel-reports/CONTRACT_REQUEST_A.md` … `CONTRACT_REQUEST_E.md` | Docs | **COLLISION DE NOMS GARANTIE.** → §6. |
| `docs/parallel-reports/SOCLE_CATALOGUE_REPORT.md`, `SOCLE_SALLE_REPORT.md` | Docs | Noms réservés. |
| `docs/parallel-reports/i18n_A.json` … `i18n_E.json`, `i18n_Z_salle.json` | Docs | **COLLISION DE NOMS GARANTIE.** → §4. |
| `.claude/` | Config | Ne jamais créer ni éditer. |

### 1.3 Le répertoire `docs/parallel-reports/` est INTERDIT EN ÉCRITURE

Il contient déjà, dans notre baseline, `00-baseline.md`, `01-decisions.md`, `02-livekit-audit.md`
(lecture recommandée), et le chantier enseignant y écrit ses 13 fichiers non commités.

**Aucun agent Teaching Core n'y écrit quoi que ce soit.** Voir §6.

---

## 2. Socle partagé gelé (spec §16.2) — propriétaire : Agent Z

| Chemin | Raison | À faire à la place |
|---|---|---|
| `lib/core/router/app_router.dart` | Routeur global unique, règle CI `routeur-unique` et `routeur-absent`. | Décision **D-04** : `List<RouteBase> routesTc<X>()`. **Ne jamais construire un `GoRouter` dans `lib/`.** |
| `lib/core/router/routes.dart` | Constantes de chemin. | Constantes locales, préfixe `/tc/…`. |
| `lib/core/router/redirection.dart` | Fonction pure de garde d'accès. Non listée par le snapshot mais **son test l'est**. | **READ-ONLY.** Toute route hors préfixe de rôle sera **redirigée vers la racine du rôle** tant qu'on ne touche pas ce fichier : c'est un point de CONTRACT_REQUEST pour tout agent posant une route. |
| `lib/core/router/billet_salle.dart` | Droit d'entrée éphémère (ADR-005). | **READ-ONLY, à consommer.** Toute entrée en Classe Live passe par `BilletSalle`, jamais par une route paramétrée. |
| `lib/core/theme/` (10 fichiers) | Thème global et jetons de design. `app_palette.dart` est le **seul** fichier autorisé à poser une couleur littérale. | Composer avec les jetons. Jeton manquant → CONTRACT_REQUEST vers Z, **qui documente**. |
| `lib/core/icons/app_icons.dart` | Catalogue unique, ~46 icônes. La CI refuse tout `IconData` ou `Icons.` ailleurs. | Décision **D-05**. |
| `lib/core/widgets/` (38 fichiers) | Composants partagés, dix déclarés **points d'entrée uniques** par `lib/CLAUDE.md`. | **Consommer**, jamais éditer ni dupliquer. Un composant réellement nouveau se crée **dans le namespace de l'agent**. |
| `lib/core/auth/service_auth.dart` | Auth core. | READ-ONLY. |
| `lib/core/session/` (`session_state.dart`, `session_controleur.dart`, `source_session.dart`, `source_session_agent.dart`, `claims_jwt.dart`) | Session, porte d'accès, capacités, lecture du JWT. | READ-ONLY. Un widget lit une **capacité**, jamais un rôle. `peutVoirDirection` est câblé à `false` : une capacité infra-rôle **n'a aucun support** → CONTRACT_REQUEST. |
| `lib/core/domain/enums.dart` | Miroirs Dart des enums SQL. | READ-ONLY. Un miroir parallèle ferait diverger client et SQL **en silence**. |
| `lib/core/config/env.dart` | `String.fromEnvironment`, garde `Env.configuree`. | READ-ONLY. Un drapeau de fonctionnalité Teaching Core passe par Agent Z. |
| `lib/main.dart`, `lib/app.dart` | Bootstrap, `ProviderScope`, `MaterialApp.router`, `BandeauObservation`. | READ-ONLY. |
| `lib/core/video/service_video.dart` | **Non listé par le snapshot**, mais c'est du LiveKit core au sens de la spec (lignes 776 / 1168). | **READ-ONLY, à consommer.** C'est néanmoins le point d'extension Dart privilégié : les demandes d'Agent G (entrée admin) et F y atterrissent via CONTRACT_REQUEST. |
| `lib/core/presence/service_presence.dart`, `vue_presence.dart` | Non listés par le snapshot, mais la spec interdit tout système de présence concurrent (ligne 1204) et le dépôt tient 14 états (invariant J4). | **READ-ONLY, à consommer.** La correction du calcul de durée pour T-20 est un CONTRACT_REQUEST (Agent A), pas une initiative. |
| `lib/core/coran/service_coran.dart` | LiveKit-équivalent pour le Coran : source canonique. **Déjà PROTECTED par le snapshot.** | Adaptateur en lecture. |
| `lib/core/admin/admin_domaine.dart` | **Gel d'architecture : 8 domaines, déclaré règle absolue.** | Un module de politique est un **onglet** de `ongletsConfiguration()`, jamais un neuvième domaine — et Agent Z le branche, pas l'agent. |
| `lib/core/widgets/admin_shell.dart`, `sous_navigation_domaine.dart` | Coquille admin. | READ-ONLY. |
| `pubspec.yaml` | **Gelé** (spec §16.4). | Décision **D-11**. |
| `pubspec.lock` | Verrou de résolution. | Idem. |
| `slang.yaml`, `build.yaml` | Pipeline i18n et ordre de génération. | Décision **D-03**. |
| `analysis_options.yaml` | Règles d'analyse. | READ-ONLY. |
| `tool/verifier_jetons.dart` | **Le gendarme.** | **READ-ONLY, à lire avant d'écrire une ligne.** Un agent ne désarme jamais une règle pour se débloquer. |
| `lib/CLAUDE.md`, `CLAUDE.md` | Règles non négociables du front. | READ-ONLY. |

---

## 3. Base de données et backend — gel total en phase parallèle

| Chemin / objet | Propriétaire | Raison |
|---|---|---|
| `supabase/migrations/0001…0024*.sql` | Z | Migrations **appliquées**. Ne jamais éditer une migration appliquée. |
| `supabase/migrations/0025…0029*.sql` | ENSEIGNANT | **Numéros pris**, fichiers invisibles chez nous. |
| `supabase/migrations/0030+` | **PERSONNE** | **Aucune migration Teaching Core en phase parallèle.** Décision **D-12**. |
| `supabase/functions/create-room-token/`, `livekit-webhook/`, `_shared/livekit.ts`, `_shared/clients.ts`, `agent-session/` | Z | Émission de jeton et webhooks. **Aucune capacité ne se décide en TypeScript.** |
| `supabase/tests/scenarios_*.sql` | Z | Harnais SQL existants (`scenarios_n2`, `n4`, `ctr01`, `adm04`, `agt01`). À **rejouer**, pas à modifier. |
| `supabase/config.toml` | Z | ⚠ Mémoire projet : `config push` écrase Auth et SMTP. **Ne jamais y toucher.** |

**Conséquence directe** : tout `CREATE TABLE`, `ALTER TABLE`, `CREATE VIEW`, `CREATE FUNCTION`,
`GRANT`, `POLICY` dont un agent a besoin devient une section **« DEMANDE SQL »** de son
`TC_CONTRACT_REQUEST_<X>.md`, rédigée avec :
le nom exact de l'objet, ses colonnes et types, la RLS attendue, le rôle appelant, et **la table
existante qu'il étend** (jamais une table neuve si un équivalent existe — voir MAPPING §9).

> Rappel de sécurité du dépôt, à respecter dans chaque demande SQL :
> **jamais `grant execute` à `agent_ro` sur une RPC volatile ou d'écriture.** `get_advisors` ne le
> détecte pas. Et toute nouvelle vue d'exposition répète le **filtre d'appelant** et le masquage
> `agent_identite_masquee()` colonne par colonne : une surface oubliée est une fuite.

---

## 4. Pipeline i18n slang — **DÉCISION SANS AMBIGUÏTÉ**

### 4.1 Le constat

Le pipeline est **mono-fichier**. `slang.yaml` n'active **pas** `namespaces` (vérifié dans
`D:\RA_TC\0\slang.yaml`). Il y a donc **une** source, `assets/i18n/fr.i18n.json` (68 Ko, 617 clés,
34 espaces de noms racine), et **une** sortie générée **et versionnée**,
`lib/core/i18n/strings_fr.g.dart` (244 Ko). `build.yaml` désactive le builder slang : l'ordre est
`dart run slang` puis `dart run build_runner build --delete-conflicting-outputs`, et la CI refuse tout
diff après régénération.

Les trois fichiers sont déjà modifiés par le chantier enseignant. Neuf agents parallèles produiraient
neuf conflits sur le JSON **et** neuf conflits sur 244 Ko de code généré **qu'on ne fusionne pas à la
main**.

### 4.2 La règle — impérative

1. **Aucun agent Teaching Core ne modifie `assets/i18n/fr.i18n.json`.**
2. **Aucun agent Teaching Core ne modifie `lib/core/i18n/strings.g.dart` ni `strings_fr.g.dart`.**
3. **Aucun agent Teaching Core ne modifie `slang.yaml` ni `build.yaml`.** (L'activation de
   `namespaces` est la bonne cible à terme, mais pas pendant que le chantier enseignant est en vol.)
4. **Aucun agent n'écrit dans `docs/parallel-reports/i18n_*.json`** : ces noms sont pris.

Chaque agent dépose ses libellés dans **un seul fichier**, qui lui appartient :

```
docs/teaching-core/i18n/tc_i18n_<AGENT>.json
```

soit `tc_i18n_A.json`, `tc_i18n_B.json`, `tc_i18n_C.json`, `tc_i18n_D.json`, `tc_i18n_E.json`,
`tc_i18n_F.json`, `tc_i18n_G.json`, `tc_i18n_H.json`, `tc_i18n_Q.json`.

Format : le **même** que `fr.i18n.json` (JSON imbriqué, interpolation en accolades `{prenom}`),
mais **borné à la racine `tc`** et à un seul sous-arbre par agent :

| Agent | Sous-arbre exclusif |
|---|---|
| A | `tc.groupe.*` |
| B | `tc.bibliotheque.*` |
| C | `tc.coran.*` |
| D | `tc.outils.*` |
| E | `tc.classe.*` |
| F | `tc.realtime.*` |
| G | `tc.observation.*` |
| H | `tc.parcours.*` |
| Q | aucun (Q ne produit pas de libellé) |

Convention de clé : `tc.<domaine>.<ecran>.<element>`, en points, cohérente avec la convention du dépôt
(`role.ecran.element`). Aucun de ces huit sous-arbres n'est préfixe d'un autre, et la racine `tc` n'entre
en collision avec aucun des 34 espaces de noms existants.

### 4.3 Comment le code compile quand même

Un agent ne peut pas appeler `t.tc.groupe.…` tant que le JSON n'est pas fusionné et régénéré.
Il écrit donc, **dans son propre namespace**, une façade de libellés :

```
lib/core/tc_<domaine>/libelles_tc_<agent>.dart
```

contenant uniquement des `static const String` et des fonctions d'interpolation, chacune annotée :

```dart
// TC-I18N: tc.groupe.carte.rejoindre
static const String rejoindre = 'Rejoindre';
```

**Chaque constante de cette façade a une entrée correspondante dans `tc_i18n_<AGENT>.json`, à la clé
exacte du commentaire `// TC-I18N:`.** C'est ce couple qui rend le travail d'Agent Z mécanique :
il fusionne les neuf JSON dans `fr.i18n.json`, régénère, puis remplace chaque constante par son
`t.tc.…`, et supprime la façade.

**Aucune chaîne visible en dur ailleurs que dans cette façade.** `lib/CLAUDE.md` l'interdit et Agent Z
n'a aucun moyen de retrouver une chaîne noyée dans un widget.

### 4.4 Arabe

`assets/i18n/ar.i18n.json` fait 974 octets et `fallback_strategy: base_locale` masque toute clé absente.
**Aucun agent ne produit de traduction arabe.** Exception unique et non négociable : les titres
enseignants **سيد / سيدة** (décision D-02) sont fournis comme valeurs littérales dans le sous-arbre `tc`
français de l'agent concerné, puisqu'ils sont affichés tels quels dans le contexte cours.

---

## 5. Harnais de test — **DÉCISION SANS AMBIGUÏTÉ**

`test/support/harnais.dart` est **PROTECTED** : fichier unique de 40,5 Ko, ~25 faux
(`FauxServiceVideo`, `FauxMoteurSalle`, `FauxServicePresence`, `FauxServicePlanning`, `FauxServiceSuivi`,
`FauxServicePreVol`, `FausseSourceSession`, …), déjà modifié par le chantier enseignant.

**Règle :**

1. Aucun agent ne modifie `test/support/harnais.dart` ni aucun fichier de `test/support/`.
2. Chaque agent écrit ses propres faux dans `test/teaching_core/<agent>/faux/`.
3. Chaque agent écrit son propre hôte de test (y compris un `GoRouter` de test, **autorisé car hors de
   `lib/`**) dans `test/teaching_core/<agent>/support/`.
4. Aucun agent n'écrit dans `test/features/`, `test/router/`, `test/video/`, `test/coran/`,
   `test/presence/`, `test/controle/`, `test/planning/`, `test/suivi/`, `test/agent/`, `test/cache/`,
   `test/widgets/`, `test/theme/`, `test/icons/`, `test/i18n/`, `test/config/`, `test/accessibilite/`,
   `test/appairage/`, `test/observabilite/`, `test/priere/`.
   **Tous les tests Teaching Core vivent sous `test/teaching_core/`.**
5. Agent Z consolidera les faux réellement partagés dans `harnais.dart` à l'intégration, pas avant.

---

## 6. Rapports et demandes — **DÉCISION SANS AMBIGUÏTÉ**

`docs/parallel-reports/` est **occupé** par le chantier enseignant, avec des noms strictement
identiques à ceux que la spec nous prescrit (`AGENT_A_REPORT.md` … `AGENT_E_REPORT.md`,
`CONTRACT_REQUEST_A.md` … `CONTRACT_REQUEST_E.md`, `i18n_A.json` … `i18n_E.json`).
**La collision serait totale sur A, B, C, D et E.**

**Règle :** tous les livrables documentaires Teaching Core vivent sous `docs/teaching-core/`,
avec le préfixe `TC_`.

| Livrable | Chemin imposé |
|---|---|
| Rapport de fin d'agent | `docs/teaching-core/TC_AGENT_<X>_REPORT.md` |
| Demande de contrat | `docs/teaching-core/TC_CONTRACT_REQUEST_<X>.md` |
| Libellés | `docs/teaching-core/i18n/tc_i18n_<X>.json` |
| Plan de test (Agent Q) | `docs/teaching-core/TC_TEST_PLAN.md` |
| Documents d'Agent 0 | `docs/teaching-core/` (commités par Agent Z depuis `D:\RA_TC\shared\`) |
| Rapport pré-merge | `docs/teaching-core/TC_PREMERGE_REPORT.md` |
| Plan de contrats d'intégration | `docs/teaching-core/TC_INTEGRATION_CONTRACT_PLAN.md` |
| Rapport final | `docs/teaching-core/TC_INTEGRATION_REPORT.md` |

`<X>` ∈ {A, B, C, D, E, F, G, H, Q}. Aucun autre fichier n'est créé dans `docs/` par un agent A…H/Q.

---

## 7. Récapitulatif — les cinq réflexes

1. **Je ne touche jamais** `D:\RA _APP\RA -OFFICIAL-APP`.
2. **Je ne modifie jamais** un fichier listé ici, même d'une ligne, même « juste pour tester ».
3. **Je ne crée jamais** de migration, ni de dépendance, ni de `GoRouter`, ni d'icône, ni de jeton de design.
4. **J'écris ma demande** dans `docs/teaching-core/TC_CONTRACT_REQUEST_<X>.md` avec la signature exacte
   attendue, et **je continue derrière un port local**.
5. **Je ne recrée jamais** une fonction existante : je relis `TEACHING_CORE_EXISTING_MAPPING.md` §9 avant
   d'écrire un composant, un service ou une table.
