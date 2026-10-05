> # ⛔ DOCUMENT PÉRIMÉ — NE PAS SUIVRE SA MATRICE DE PROPRIÉTÉ
>
> **Périmé depuis le 20 septembre 2026.** Ce fichier a été écrit le
> **14 septembre 2026** et sa carte de propriété de fichiers **n'a plus cours**.
>
> **La matrice qui fait loi est
> `docs/architecture/TEACHER_FILE_OWNERSHIP.md`**, complétée par le gel
> `docs/architecture/TEACHER_PARALLEL_BASELINE.md`. Si les deux documents se
> contredisent sur qui possède un fichier, c'est `TEACHER_FILE_OWNERSHIP.md` qui
> gagne, sans discussion.
>
> Ce qui est faux ici, et qui ferait travailler un agent contre le lot en cours :
>
> - la **propriété** de `lib/core/router/app_router.dart`, de l'i18n
>   (`assets/i18n/*.json`, `lib/core/i18n/strings*.g.dart`), de
>   `ligne_presence.dart` et de `docs/design/08-catalogue-ecrans.md` est attribuée
>   ici à d'autres propriétaires que ceux du lot en cours ;
> - les **migrations `0014` à `0016` sont réservées** par les sections
>   ci-dessous, alors que le dépôt en est à `0025` et que `0014`, `0015` et
>   `0016` sont écrites et poussées depuis le 18 septembre 2026 ;
> - le **commit de base** annoncé (`cbc4ff8...`) n'est plus le point de départ :
>   le lot en cours gèle `BASELINE_SHA = 550e6059654843274e5039e203ad296c565a08b6` ;
> - le **modèle de coexistence** a changé : le lot en cours travaille dans un
>   **arbre unique** avec propriété exclusive des fichiers, et non dans cinq
>   worktrees (`TEACHER_PARALLEL_BASELINE.md` §4, avec les trois raisons
>   mesurées).
>
> **Le contenu n'est pas supprimé.** C'est un document historique, et le dépôt
> garde son historique : il reste la seule trace écrite de l'état des worktrees
> au 14 septembre 2026, et sa section 2 est encore utile pour savoir **ce qui
> dort dans quel worktree** — y compris une seconde implémentation de `ENS-05`
> (lignes 93 et 117), vérifiée toujours présente le 20 septembre 2026 et
> documentée dans
> `docs/parallel-reports/SOCLE_CATALOGUE_REPORT.md`.
>
> Lisez-le comme un relevé daté, jamais comme une consigne.

---

# Baseline de coordination des worktrees

Date d'inspection : 2026-09-14 22:18:32 +03:00

Ce rapport est un état de référence pour les lots parallèles. Il ne constitue
ni une validation fonctionnelle, ni une validation de production. L'audit n'a
exécuté ni test, ni analyse, ni build, ni migration et n'a effectué aucun
staging.

## 1. Commit de base et état Git

Le checkout Rewayah réel est :

`D:\RA _APP\RA -OFFICIAL-APP`

Le dossier de coordination courant
`C:\Users\dell\AppData\Local\Programs\WindowsTerminal` ne contient pas de
marqueur `.git` et ne doit pas être utilisé comme dépôt Rewayah.

| Élément | Valeur inspectée |
| :--- | :--- |
| Branche de référence | `main` |
| Commit de base | `cbc4ff8dca794762a57ce25ae44ddebd48c4cf56` |
| Commit distant | `origin/main` pointe également sur `cbc4ff8...` |
| Sujet du commit | `HANDOFF : TUT-06 est fait, il ne reste que deux écrans au MVP-0` |
| Index | Vide au moment de l'inspection |
| État de l'arbre | 19 chemins suivis modifiés, 8 chemins non suivis préexistants |

Le commit `cbc4ff8...` est le snapshot commun à utiliser pour tout nouveau
worktree. Le checkout `main` est sale : aucun agent ne doit le traiter comme un
checkout propre ou le nettoyer implicitement.

### Fichiers suivis modifiés dans `main`

```text
assets/i18n/ar.i18n.json
assets/i18n/fr.i18n.json
dart_define.example.json
docs/AGENT_HANDOFF.md
docs/HANDOFF.md
docs/PROGRESS.md
lib/app.dart
lib/core/cache/db/app_database.g.dart
lib/core/config/env.dart
lib/core/i18n/strings.g.dart
lib/core/i18n/strings_ar.g.dart
lib/core/i18n/strings_fr.g.dart
lib/core/router/app_router.dart
lib/core/router/routes.dart
lib/core/router/redirection.dart
lib/core/profil/
lib/core/preferences/
lib/features/profil_enseignant/
lib/features/compte/
test/features/profil_enseignant_test.dart
test/features/compte_test.dart
lib/core/widgets/ligne_presence.dart
lib/main.dart
pubspec.lock
pubspec.yaml
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugins.cmake
```

`lib/core/cache/db/app_database.g.dart` est signalé par Git, mais sa
comparaison avec `git diff --ignore-space-at-eol` ne montre pas de changement
sémantique : c'est un changement de fins de ligne.

### Chemins non suivis présents avant ce rapport

```text
CODEX.md
lib/core/observabilite/
lib/features/_dev/playground/
lib/features/suivi_eleve/
test/config/supabase_key_validation_test.dart
test/features/suivi_eleve_test.dart
test/observabilite/
```

Le présent fichier devient lui-même un nouveau chemin non suivi jusqu'à son
intégration explicite. Pendant l'audit, un autre agent a aussi créé
`docs/parallel-reports/01-decisions.md` ; ce fichier est un rapport produit
distinct, au statut `BLOCKED`, et ne fait pas partie de ce lot. Il ne faut pas
déduire la propriété d'un chemin non suivi depuis sa seule présence.

## 2. Worktrees et attribution actuelle

| Worktree | HEAD / branche | État | Attribution et règle |
| :--- | :--- | :--- | :--- |
| `D:\RA _APP\RA -OFFICIAL-APP` | `cbc4ff8...` / `main` | Sale | Checkout de coordination. R3 non commité et changements concurrents. Aucun nouveau lot ne doit y coder directement. |
| `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-r1` | `405683abb751...` / `codex/r1-adaptive-design-system` | Propre | Codex UI, R1. Commit de design system prêt à comparer à `main`. |
| `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-r2` | `1fc15c68ef66...` / `codex/r2-adaptive-shell` | Sale | Codex UI, R2, avec le lot ENS-05 profil enseignant et Compte/préférences non commité. Les commits propres incluent une série R1/R2 ; 21 modifications et 8 chemins non suivis restent à attribuer avant réutilisation. |
| `D:\ra-pwa-build` | `e76a14ec4f61...` / détaché | Sale, 62 modifiés et 22 non suivis | Worktree historique de N2 et de mesure/build. Interdit pour un nouveau lot et interdit pour un déploiement. |
| `D:\ra-pwa-ctr` | `f1855de5c76f...` / détaché | Sale, 59 modifiés et 12 non suivis | Worktree historique N4 / CTR-01 avec état concurrent ultérieur. Ne pas nettoyer ni réutiliser. |
| `D:\ra-pwa-fix` | `090ae6f6f2dc...` / détaché | Sale, 3 modifiés | Worktree historique N5 / correctif de build ; les seuls changements observés sont des fichiers Windows générés. À conserver comme état historique, pas comme base de nouveau code. |
| `D:\ra-pwa-secure-deploy` | `cbc4ff8...` / détaché | Sale, 4 modifiés et 1 non suivi | Worktree ENS-05 sécurité/configuration et promotion. Il porte `env.dart`, des fichiers Windows générés et le test de clé ; ne pas y coder un écran. |

R3 ne possède pas de worktree dédié : son code de suivi élève est dans le
checkout `main` sale. Cette absence est un risque et doit être résolue par le
propriétaire de R3 avant commit, sans copier tout le dépôt par-dessus un autre
worktree.

La branche R2 est basée sur `main` et contient déjà une série R1/R2 différente
de la branche R1 (`6e85aec`, `da34f9c`, `1fc15c6`). Il faut choisir une seule
chaîne d'intégration : soit R1 puis les commits shell R2, soit la chaîne propre
R2 complète. Ne pas fusionner les deux séries R1 en bloc.

### Attribution des lots suivants

| Lot | Worktree attribué | État de l'attribution |
| :--- | :--- | :--- |
| R1 design system | `rewayah-r1` | Attribué, checkout propre |
| R2 shell adaptatif | `rewayah-r2` | Attribué, mais checkout sale à isoler avant toute reprise |
| R3 suivi élève | `main` temporairement | Présent, non commité ; créer ou réutiliser un worktree dédié avant modification |
| ENS-04 transmission + synchronisation | Aucun | Nouveau worktree requis |
| ENS-05 profil enseignant | `rewayah-r2` | Présent en non-suivi avec son test et son raccord routeur ; revue ciblée obligatoire. Le worktree secure-deploy reste réservé à la configuration. |
| N6 Coran partagé | Aucun | Nouveau worktree requis après décision du canal |
| Présence corrigeable | Aucun | Nouveau worktree requis après contrat métier |
| Recette et déploiement | Aucun | Un seul worktree propre depuis `main` à jour, après intégration |

Les worktrees détachés N2, N4/CTR-01, N5 et secure-deploy ne sont pas des
réserves disponibles pour ces lots.

## 3. Changements R3 déjà présents

Le lot R3 actuel est le suivi élève, non commité. Son périmètre observé est :

```text
lib/features/suivi_eleve/suivi_eleve_page.dart
test/features/suivi_eleve_test.dart
lib/core/router/app_router.dart
lib/core/widgets/ligne_presence.dart
assets/i18n/fr.i18n.json
assets/i18n/ar.i18n.json
lib/core/i18n/strings.g.dart
lib/core/i18n/strings_fr.g.dart
lib/core/i18n/strings_ar.g.dart
```

Le code branche la route existante `Routes.eleveSuivi` (`/eleve/suivi`) sur
`SuiviElevePage`, réutilise les services/projections de suivi et n'ajoute pas
de migration SQL ni de service backend. `LignePresence` reçoit un paramètre de
présentation `afficherConsolide`; l'appel R3 le désactive pour ne pas exposer
une décision administrative dans le suivi personnel.

Point d'intégration non résolu :
`docs/design/08-catalogue-ecrans.md` marque encore « Suivi élève » comme « à
construire », alors que le routeur et le fichier de feature sont déjà présents.
La mise à jour du catalogue appartient à la fermeture R3, pas à une intégration
silencieuse par un autre agent.

Le commit `122b8e8` est le lot antérieur TUT-06, « suivi du foyer ». Il ne doit
pas être confondu avec le R3 suivi élève actuellement non commité.

## 4. Propriétaires des fichiers d'intégration partagés

| Surface partagée | Propriétaire temporaire | Protection |
| :--- | :--- | :--- |
| `lib/core/router/app_router.dart` | R3 pour la route `/eleve/suivi`, puis intégration coordonnée | Lecture seule pour les autres lots jusqu'à extraction du diff R3. R2 devra être raccordé par patch ciblé. |
| `lib/core/router/routes.dart`, `redirection.dart` | R2 dans son worktree sale | Les changements de route ENS-05 sont non commis ; ne pas les reprendre sans attribution explicite. |
| `lib/app.dart`, `lib/main.dart` | OpenCode historique / travail concurrent conservé | Fichiers protégés. `main.dart` importe le playground et la supervision ; `app.dart` porte des paramètres de preview. |
| `lib/core/config/env.dart` | Chevauchement OpenCode et ENS-05 | Fichier protégé. Ne pas choisir une version globale ; comparer les deux intentions avant intégration. |
| `lib/core/theme/**` | R1, puis intégration UI | Le commit R1 est isolé dans `rewayah-r1`. R2 le consomme ; aucune réécriture locale dans `main`. |
| `lib/core/profil/**`, `lib/core/preferences/**`, `lib/features/profil_enseignant/**`, `lib/features/compte/**` | R2 / ENS-05 et Compte | Chemins non commis du worktree R2. Revue et attribution avant intégration ; aucun autre lot ne les modifie. |
| `lib/core/widgets/ligne_presence.dart` | R3 pour l'ajout `afficherConsolide`, composant partagé N4 | Préserver les appelants N4/N5 et intégrer la modification par diff ciblé. |
| `assets/i18n/*.i18n.json` et `lib/core/i18n/strings*.g.dart` | R3 pour les clés du suivi | Les sources ARB/JSON sont la vérité ; les fichiers générés ne se fusionnent pas globalement. Régénérer uniquement après comparaison. |
| `pubspec.yaml`, `pubspec.lock` | OpenCode / supervision Sentry | Protégés. La dépendance `sentry_flutter` et ses transitive packages sont hors R3. |
| `lib/core/cache/db/app_database.dart` et `app_database.g.dart` | Propriétaire data/Drift, lot métier | Aucun lot UI ne modifie le schéma. Le `.g.dart` est généré et actuellement marqué pour EOL seulement. |
| `windows/flutter/generated_plugin_registrant.*`, `generated_plugins.cmake` | Génération liée au manifeste | Protégés des commits UI ; ne pas régénérer pour un simple écran. |
| `docs/AGENT_HANDOFF.md`, `docs/HANDOFF.md`, `docs/PROGRESS.md` | Coordination / opérateur | Partagés et modifiés dans l'arbre courant. Ce prompt interdit toute modification de `HANDOFF.md` et `PROGRESS.md`. |
| `docs/parallel-reports/01-decisions.md` | Agent du Prompt 01 / décisions produit | Créé pendant cet audit, non suivi et distinct du présent baseline. Lecture seule pour les autres lots. |
| `docs/design/08-catalogue-ecrans.md` | R3 pour la mise en cohérence du suivi | Ne pas l'éditer dans un autre lot avant fermeture R3. |

## 5. Fichiers interdits aux autres agents

Jusqu'à intégration explicite de leur propriétaire, les autres agents ne
doivent ni modifier, ni formater, ni régénérer, ni stager :

```text
lib/app.dart
lib/main.dart
lib/core/config/env.dart
lib/features/_dev/playground/
lib/core/observabilite/
test/observabilite/
test/config/supabase_key_validation_test.dart
pubspec.yaml
pubspec.lock
dart_define.example.json
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugins.cmake
lib/core/cache/db/app_database.g.dart
docs/AGENT_HANDOFF.md
docs/HANDOFF.md
docs/PROGRESS.md
docs/parallel-reports/01-decisions.md
lib/core/router/app_router.dart
lib/core/widgets/ligne_presence.dart
assets/i18n/ar.i18n.json
assets/i18n/fr.i18n.json
lib/core/i18n/strings.g.dart
lib/core/i18n/strings_ar.g.dart
lib/core/i18n/strings_fr.g.dart
docs/design/08-catalogue-ecrans.md
```

Cette protection ne signifie pas que tous ces fichiers appartiennent au même
lot. Elle signifie qu'aucun agent non propriétaire ne peut les embarquer par
accident dans son commit. Les contrôles doivent utiliser des diffs ciblés et
`git diff --cached --name-only` avant tout commit.

## 6. Migrations SQL existantes et réservations

### État observé

Les treize migrations suivantes existent dans
`supabase/migrations/` et sont suivies par Git :

```text
0001_fondations.sql
0002_statut_attente_kyc.sql
0003_profil_defaut_attente.sql
0004_inscription_kyc_appairage.sql
0005_dashboards_affectation_regles.sql
0006_rattrapage_semaine_utc_et_foyer.sql
0007_coran_structure_position_presence.sql
0008_attribution_manuelle.sql
0009_journal_audit.sql
0010_video_jeton_presence.sql
0011_presence_bornee.sql
0012_observation_controleur.sql
0013_corpus_coranique.sql
```

Aucun fichier sous `supabase/migrations/` n'est modifié ou non suivi dans le
checkout `main` au moment de l'audit. Les documents de handoff indiquent que
`0001` à `0005` sont appliquées au projet réel, que `0006` est un rattrapage
commité encore à jouer, et que les lots N1/N2/N4/CTR-01/N5 ont posé `0007` à
`0013`. Ces affirmations restent documentaires ici : aucune base n'a été
rejouée pendant cet audit.

### Réservations de coordination

Avant ce baseline, aucune réservation `0014+` n'était écrite. Pour éviter deux
lots concurrents portant le même numéro, les réservations suivantes sont
créées par ce rapport uniquement ; elles ne créent aucune migration :

| Numéro réservé | Lot | Périmètre prévu | Fichier attendu maintenant |
| :--- | :--- | :--- | :--- |
| `0014` | ENS-04 + synchronisation du cahier | Tables/file locale ou contrat serveur, fonction d'envoi, RLS et idempotence selon le contrat final | Aucun |
| `0015` | N6 Coran partagé | Canal et persistance de l'état partagé, uniquement après décision du canal | Aucun |
| `0016` | Présence corrigeable | Décision manuelle, motif, journalisation et policies selon contrat métier | Aucun |

`0017+` reste non attribué. R3, le profil ENS-05 et la refonte loading ne
réservent pas de migration à ce stade. Une réservation peut être déplacée
uniquement par le coordinateur, avec mise à jour d'un futur rapport de
coordination ; les migrations `0001` à `0013` ne doivent jamais être réécrites
pour ces lots.

## 7. Ordre d'intégration recommandé

1. Geler le snapshot `cbc4ff8...` et laisser tous les arbres sales intacts.
2. Isoler puis relire R3 depuis `main` : uniquement ses neuf chemins listés en
   section 3, puis mettre le catalogue en cohérence dans le lot R3. Ne pas
   prendre `app.dart`, `main.dart`, `env.dart`, le playground, Sentry ou les
   fichiers Windows générés.
3. Intégrer le design system R1 depuis son commit propre, puis le shell R2
   avec un diff comparé à la nouvelle tête. Choisir une seule série R1/R2 comme
   indiqué en section 2.
4. Raccorder les points partagés par petits patches : routeur, thème, i18n et
   `LignePresence`. Chaque patch doit conserver les routes et API existantes.
5. Faire le lot métier ENS-04 et sa migration réservée `0014` dans un worktree
   dédié, puis raccorder l'écran après validation de la commande serveur.
6. Faire ENS-05 profil sans migration, puis N6 après décision et contrat du
   canal partagé (`0015`). La correction de présence vient dans son lot dédié
   (`0016`), jamais dans une refonte visuelle.
7. Construire un checkout de recette propre depuis `main` intégré. Les tests,
   l'analyse SQL et le déploiement ne se font pas depuis un arbre signalé
   `gitDirty` ni depuis les worktrees historiques.

## 8. Risques de conflit à surveiller

| Risque | Preuve observée | Mesure de prévention |
| :--- | :--- | :--- |
| Intégration globale d'un arbre sale | `main` a 19 modifications et 8 chemins non suivis ; R2 et plusieurs worktrees détachés sont également sales | Stage par liste blanche et vérifier l'index avant commit. |
| OpenCode / Sentry mélangé à R3 | `main.dart`, `app.dart`, `env.dart`, playground, observabilité et `pubspec` sont reliés ; le handoff identifie OpenCode comme abandonné mais à préserver | Aucun agent ne touche ces chemins ; ne jamais les inclure dans le commit R3. |
| Routeur touché par plusieurs lots | R3 modifie `app_router.dart`; R2 a aussi `routes.dart`, `redirection.dart` et des changements de shell | Comparer la nouvelle tête et appliquer un raccord ciblé après R3. |
| R1 dupliqué dans R2 | R2 porte déjà `6e85aec` et les commits shell, tandis que R1 porte `405683a` | Ne pas fusionner les deux historiques en bloc. |
| Génération i18n accidentelle | R3 modifie les sources et trois fichiers générés ; ces fichiers sont partagés | Modifier les sources dans le lot propriétaire puis vérifier le diff généré. |
| Pollution Drift par EOL | `app_database.g.dart` est marqué modifié, mais aucune différence sémantique n'apparaît en ignorant les fins de ligne | Ne pas régénérer ou formater Drift dans un lot UI. |
| Numéro SQL réutilisé | `0001` à `0013` existent ; les documents demandent l'ordre strict et `scenarios_adm04.sql` en dernier | Respecter les réservations `0014` à `0016` et ne jamais corriger une ancienne migration. |
| Documentation contradictoire | `HANDOFF.md` contient des sections historiques et le catalogue est en retard sur le code R3 | Lire la section la plus récente, qualifier les faits comme documentaires et corriger le document dans le lot propriétaire. |
| Déploiement d'un contenu non commité | Le handoff signale `gitDirty=1` pour une livraison CLI passée | Déployer uniquement depuis un worktree propre de recette, après intégration et contrôles. |
| Build concurrent dans le même dossier | Les instructions locales signalent que deux builds Flutter dans un même worktree se détruisent | Un worktree de build par agent ; aucun build dans `main` sale. |
| Création concurrente de rapports | `01-decisions.md` est apparu pendant cet audit dans le même dossier de rapports | Ne pas le modifier, le stager ou l'attribuer à ce baseline ; chaque prompt garde son fichier. |

## 9. Preuves et limites de cet audit

Commandes de lecture utilisées : `git status --short --branch`,
`git rev-parse`, `git worktree list --porcelain`, `git diff --name-status`,
`git diff --stat`, `git diff --ignore-space-at-eol`, `git log`, `rg` sur les
instructions, le routeur, les fichiers d'intégration et les migrations.

Non exécuté volontairement : `flutter pub get`, génération slang/Drift,
`dart analyze`, `flutter test`, vérificateur de jetons, Docker/Postgres,
builds et déploiement. Ce baseline ne certifie donc aucun comportement runtime
et ne transforme pas les affirmations du handoff en preuve nouvelle.
