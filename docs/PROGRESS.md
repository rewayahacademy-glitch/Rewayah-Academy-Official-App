# PROGRESS — État d'avancement du projet

> Suivi tenu par l'agent de code, une étape à la fois, jamais en bloc.
> C'est le seul fichier à lire pour savoir quoi faire ensuite.

## DÉMARRER ICI — prochaine session (ne rien chercher d'autre)

**L'étape 3 est terminée.** Un tuteur ou un enseignant peut s'inscrire, déposer
son dossier et attendre ; l'administration peut valider ou refuser ; un tuteur
peut créer ses enfants et appairer leurs appareils ; un enfant peut entrer avec
un code puis son code personnel. La prochaine session attaque l'**étape 4 :
dashboards Bento Grid**.

1. **Lire, dans cet ordre, et rien de plus** :
   `docs/architecture/etape-3-journal.md` (ce qui existe, ce qui est mesuré, les
   pièges déjà payés), puis `docs/architecture/etape-3-auth-kyc.md` pour le
   modèle de portes et d'invariants, puis
   `docs/produit/parcours-utilisateurs.md` pour les écrans à construire, puis
   `lib/CLAUDE.md`.
2. **Ne rien réécrire des étapes 2 et 3.** Les dix composants partagés, le
   thème, le routeur et les services de dossier sont les seuls points d'entrée
   de leur fonction. `dart run tool/verifier_jetons.dart` le dira.
3. **Les écrans de l'étape 4** sont `TUT-01`, `ELV-02`, `ENS-02`, `ADM-01`, plus
   `TUT-04`, `TUT-05` et `ENS-06`. Ils remplacent les derniers placeholders
   `EcranAConstruire` des routes déjà déclarées.
4. **Mesurer le démarrage à froid** sur `ELV-02` réel, sur un appareil d'entrée
   de gamme. C'est le scénario 7 de l'étape 2, toujours non coché faute d'écran
   métier à charger. L'étape 3 n'a pas d'écran de ce type non plus : le premier
   candidat est `ELV-02`.
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

Les scénarios SQL se rejouent sur un Postgres nu, comme en CI :

```
psql -f supabase/tests/stub_auth.sql
psql -f supabase/migrations/0001_fondations.sql          # puis 0002, 0003, 0004
psql -f supabase/tests/scenarios_etape3.sql
```

## Étapes de code

| # | Étape | Statut | Où |
| :-- | :--- | :--- | :--- |
| 0 | Socle d'exploitation | partiel | Voir le tableau d'onboarding ci-dessous |
| 1 | Fondations DB, RLS, fonctions, audit | [x] | `supabase/migrations/0001` à `0004` |
| 2 | Core Flutter, thème, cache local, routeur | [x] | `docs/architecture/etape-2-journal.md` |
| 3 | Auth, KYC, appairage, portails d'attente | [x] | `docs/architecture/etape-3-journal.md` |
| 4 | Dashboards Bento Grid | [ ] | **prochaine** |
| 5 | Visio LiveKit, preuve de présence, Coran | [ ] | |
| 6 | Cahier de transmission | [ ] | |

## Protocole d'onboarding (`docs/agent-onboarding.md`)

| # | Étape | Statut | Notes |
| :-- | :--- | :--- | :--- |
| A | Dépôt Git et branche | [x] | `main`, `.gitignore`, remote GitHub connecté |
| B | Projet Supabase | [x] | `gggmtelinlpseweouyav`, `supabase/` initialisé et lié |
| C | Migrations versionnées | [x] | `0001` à `0004`, appliquées et vérifiées sur Postgres 17. **Jamais appliquées au projet réel** : voir le risque `pgcrypto` du journal de l'étape 3 |
| D | Secrets | [ ] | **Ouverte, et désormais bloquante pour l'usage.** Sans elle, les fonctions Edge `creer-profil-enfant` et `session-enfant` ne sont pas déployées, donc aucun enfant ne peut ouvrir de session. Demande `supabase login`, `supabase link --project-ref gggmtelinlpseweouyav`, les secrets GitHub `SUPABASE_ACCESS_TOKEN` et `SUPABASE_DB_URL`, plus un secret de fonction `STUDENT_EMAIL_DOMAIN` |
| E | CI/CD | [x] | `ci.yml` rejoue les 36 contrôles SQL de `supabase/tests/` à chaque pull request |
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
| Composant ATL de Visual Studio | Le build Windows échoue sur `atlstr.h` absent, réclamé par `flutter_secure_storage_windows`. Installer « C++ ATL for latest v143 build tools » dans Visual Studio Build Tools | `etape-3-journal.md` |

## Règle de lecture

- Ce fichier est le miroir de l'avancement. Une session qui arrive sur un `[ ]`
  traite l'étape concernée avant tout autre travail, ou dit pourquoi elle ne le
  fait pas.
- Chaque étape a un critère de sortie vérifiable, défini dans
  `docs/agent-onboarding.md` et dans les plans d'étape.
- **Un contrôle qui n'a jamais tourné n'est pas un contrôle vert.** C'est ce qui
  a masqué le défaut de la CI pendant toute l'étape 1.
