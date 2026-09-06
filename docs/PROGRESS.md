# PROGRESS — État d'avancement du projet

> Suivi tenu par l'agent de code, une étape à la fois, jamais en bloc.
> C'est le seul fichier à lire pour savoir quoi faire ensuite.

## DÉMARRER ICI — prochaine session (ne rien chercher d'autre)

**Lire `docs/HANDOFF.md` en premier, avant toute action.** Il dit quel est le
dépôt actif, où le travail s'est arrêté, quel lot reprendre, et avec quelles
commandes. Le reste de ce fichier est le tableau d'avancement, pas la consigne
de reprise.

**L'étape 3 est terminée, l'étape 4 est en cours** : les lots L0 à L5 sont
faits, le prochain est **L6, `ENS-02`**.

1. **Lire, dans cet ordre, et rien de plus** : `docs/HANDOFF.md`, puis
   `docs/architecture/etape-4-journal.md` (où en est l'étape, lot par lot), puis
   `docs/architecture/etape-4-dashboards.md` (la spécification, ses neuf défauts
   corrigés et ses douze invariants), puis `lib/CLAUDE.md`.
2. **Ne rien réécrire des étapes 2 et 3.** Les dix composants partagés, le
   thème, le routeur et les services de dossier sont les seuls points d'entrée
   de leur fonction. `dart run tool/verifier_jetons.dart` le dira.
3. **Ne rien réécrire des lots L2 à L5.** Les services de planning, de règles,
   de matching, d'administration et de prières existent, avec leurs faux dans
   `test/support/harnais.dart`. Le tableau du handoff dit lequel sert à quoi.
4. **Mesurer le démarrage à froid** sur `ELV-02` réel, sur un appareil d'entrée
   de gamme. C'est le scénario 7 de l'étape 2, toujours non coché faute d'écran
   métier à charger : le premier candidat est `ELV-02`, au lot L7.
5. **Étape D toujours ouverte** (secrets), et elle bloque désormais plus qu'avant
   : les deux fonctions Edge de l'étape 3 ne peuvent pas être déployées sans
   elle, donc aucun enfant ne peut ouvrir de session tant qu'elle n'est pas
   posée. Voir le tableau d'onboarding.

### Commandes du projet

Depuis `D:\RA _APP\RA -OFFICIAL-APP` :

```
flutter pub get
dart run slang                                          # AVANT build_runner
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
flutter run --dart-define-from-file=dart_define.json     # voir l'exemple versionné
flutter build web --dart-define=GALERIE=true             # galerie des composants sur /_galerie
```

Les scénarios SQL se rejouent sur un Postgres **nu**, comme en CI. Un fichier de
scénarios ne se rejoue pas deux fois sur la même base : il insère ses fixtures.
Les commandes exactes, avec le conteneur, sont dans `docs/HANDOFF.md`.

```
psql -f supabase/tests/stub_auth.sql
psql -f supabase/migrations/0001_fondations.sql          # puis 0002 à 0005
psql -f supabase/tests/scenarios_etape3.sql              # 34 contrôles
psql -f supabase/tests/scenarios_etape4.sql              # 37 contrôles
```

## Étapes de code

| # | Étape | Statut | Où |
| :-- | :--- | :--- | :--- |
| 0 | Socle d'exploitation | partiel | Voir le tableau d'onboarding ci-dessous |
| 1 | Fondations DB, RLS, fonctions, audit | [x] | `supabase/migrations/0001` à `0004` |
| 2 | Core Flutter, thème, cache local, routeur | [x] | `docs/architecture/etape-2-journal.md` |
| 3 | Auth, KYC, appairage, portails d'attente | [x] | `docs/architecture/etape-3-journal.md` |
| 4 | Dashboards Bento Grid, affectation durable, prières | [ ] | **en cours**, `docs/architecture/etape-4-journal.md` |
| 5 | Visio LiveKit, preuve de présence, Coran | [ ] | |
| 6 | Cahier de transmission | [ ] | |

## Protocole d'onboarding (`docs/agent-onboarding.md`)

| # | Étape | Statut | Notes |
| :-- | :--- | :--- | :--- |
| A | Dépôt Git et branche | [x] | `main`, `.gitignore`, remote GitHub connecté |
| B | Projet Supabase | [x] | `gggmtelinlpseweouyav`, `supabase/` initialisé et lié |
| C | Migrations versionnées | [x] | `0001` à `0005`, appliquées et vérifiées sur Postgres 17. **Jamais appliquées au projet réel** : voir le risque `pgcrypto` du journal de l'étape 3 |
| D | Secrets | [ ] | **Ouverte, et désormais bloquante pour l'usage.** Sans elle, les fonctions Edge `creer-profil-enfant` et `session-enfant` ne sont pas déployées, donc aucun enfant ne peut ouvrir de session. Demande `supabase login`, `supabase link --project-ref gggmtelinlpseweouyav`, les secrets GitHub `SUPABASE_ACCESS_TOKEN` et `SUPABASE_DB_URL`, plus un secret de fonction `STUDENT_EMAIL_DOMAIN` |
| E | CI/CD | [x] | `ci.yml` rejoue les 71 contrôles SQL de `supabase/tests/` à chaque pull request, 34 pour les étapes 1 et 3, 37 pour l'étape 4 |
| F | Sentry | [ ] | Nécessite le compte Sentry |
| G | Variantes Flutter `dev` / `staging` / `prod` | [ ] | Un seul identifiant aujourd'hui : `com.rewayahacademy.app` |
| H | Stockage média R2 | [ ] | Nécessite le compte Cloudflare. Les seaux `kyc` et `avatars` de Supabase Storage, eux, sont créés par la migration 0004 |
| I | LiveKit | [ ] | Nécessite le compte LiveKit |
| J | Config applicative `app_config` | [x] | Étendue à l'étape 3 : `kyc_retention_days`, `pairing_code_ttl_minutes` |
| K | Mémoire graphify | [ ] | À faire |
| L | Ressources front et back | [x] | Conformes aux étapes 2 et 3 |
| M | PWA multiappareils | [ ] | Le build Web fonctionne ; manifest, service worker et URL déployée restent à faire |

## Décisions en attente de l'opérateur

| Sujet | Question | Où c'est documenté |
| :--- | :--- | :--- |
| `borderDefault` | La bordure mesure 1,86:1, sous le seuil de 3:1. Décoratif seulement, ou passer à `#8F8080` (3,03:1) pour qu'elle puisse porter du sens ? | `etape-2-journal.md`, section Mesures |
| Poids des polices | `NotoSans-Variable` pèse 2 Mo pour une interface française. Sous-ensembler ? | `etape-2-journal.md`, section Poids |
| `child_ui_mode_max_age` | Posé à **8** et employé tel quel par l'étape 3. Modifiable en une ligne d'`app_config`, sans redéploiement. À confirmer ou corriger | `decisions.md`, ADR-016 |
| Lecture du QR par la caméra | Reportée : le paquet réclame une configuration de permissions par plateforme. Le chemin par le code fonctionne partout. À rouvrir si le QR devient nécessaire | `etape-3-auth-kyc.md` section 9 |
| Compression serveur des photos | `TUT-05` laisse le tuteur remplacer la photo de son enfant, mais aucune compression serveur n'existe : le cache local ne peut pas borner sa taille comme l'étape 2 le prévoyait | `decisions.md`, question 17 |
| Litige sur le temps effectif | L'étape 4 pose le minimum payable et sa trace, l'étape 5 mesurera la présence réelle. Les deux doivent se rejoindre avant la première paie | `decisions.md`, question 16 |
| Composant ATL de Visual Studio | Le build Windows échoue sur `atlstr.h` absent, réclamé par `flutter_secure_storage_windows`. Installer « C++ ATL for latest v143 build tools » dans Visual Studio Build Tools | `etape-3-journal.md` |
| Plateforme Android 37 | Le build APK échoue : le SDK a installé `platforms\android-37.0`, Gradle cherche `android-37`. Lancer `sdkmanager "platforms;android-37"`. Ne pas épingler `compileSdk` pour contourner un seul poste | `etape-3-journal.md` |

## Règle de lecture

- Ce fichier est le miroir de l'avancement. Une session qui arrive sur un `[ ]`
  traite l'étape concernée avant tout autre travail, ou dit pourquoi elle ne le
  fait pas.
- Chaque étape a un critère de sortie vérifiable, défini dans
  `docs/agent-onboarding.md` et dans les plans d'étape.
- **Un contrôle qui n'a jamais tourné n'est pas un contrôle vert.** C'est ce qui
  a masqué le défaut de la CI pendant toute l'étape 1.
