# PROGRESS — État d'avancement du projet

> Suivi tenu par l'agent de code, une étape à la fois, jamais en bloc.
> C'est le seul fichier à lire pour savoir quoi faire ensuite.

## DÉMARRER ICI — prochaine session (ne rien chercher d'autre)

**L'étape 2 est terminée.** Le socle Flutter existe, compile, et ses tests
passent. La prochaine session attaque l'**étape 3 : Auth, KYC, appairage,
portails d'attente**.

1. **Lire, dans cet ordre, et rien de plus** :
   `docs/architecture/etape-2-journal.md` (ce qui existe déjà, les pièges déjà
   payés, les mesures), puis `docs/produit/parcours-utilisateurs.md` pour les
   écrans à construire, puis `lib/CLAUDE.md`.
2. **Ne rien réécrire de l'étape 2.** Les neuf composants partagés, le thème et
   le routeur sont les seuls points d'entrée de leur fonction. Un écran qui
   réimplémente son bouton ou sa carte est à corriger, pas à fusionner.
   `dart run tool/verifier_jetons.dart` le dira.
3. **Les écrans de l'étape 3** remplacent les placeholders `EcranAConstruire`
   des routes déjà déclarées dans `lib/core/router/routes.dart`. L'arborescence
   ne bouge pas : elle est déjà celle du modèle de navigation.
4. **Mesurer le démarrage à froid** sur `ELV-02` réel, sur un appareil d'entrée
   de gamme. C'est le scénario 7 de l'étape 2, laissé non coché faute d'écran à
   charger. Voir le journal.
5. **Étape D toujours ouverte** (secrets). Non bloquante pour coder, bloquante
   pour déployer. Demander à l'opérateur : `supabase login`, puis
   `supabase link --project-ref gggmtelinlpseweouyav`, puis poser les secrets
   GitHub `SUPABASE_ACCESS_TOKEN` (jeton `sbp_`) et `SUPABASE_DB_URL`.

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

## Étapes de code

| # | Étape | Statut | Où |
| :-- | :--- | :--- | :--- |
| 0 | Socle d'exploitation | partiel | Voir le tableau d'onboarding ci-dessous |
| 1 | Fondations DB, RLS, fonctions, audit | [x] | `supabase/migrations/0001` à `0003` |
| 2 | Core Flutter, thème, cache local, routeur | [x] | `docs/architecture/etape-2-journal.md` |
| 3 | Auth, KYC, appairage, portails d'attente | [ ] | **prochaine** |
| 4 | Dashboards Bento Grid | [ ] | |
| 5 | Visio LiveKit, preuve de présence, Coran | [ ] | |
| 6 | Cahier de transmission | [ ] | |

## Protocole d'onboarding (`docs/agent-onboarding.md`)

| # | Étape | Statut | Notes |
| :-- | :--- | :--- | :--- |
| A | Dépôt Git et branche | [x] | `main`, `.gitignore`, remote GitHub connecté |
| B | Projet Supabase | [x] | `gggmtelinlpseweouyav`, `supabase/` initialisé et lié |
| C | Migrations versionnées | [x] | `0001` à `0003`, appliquées et vérifiées sur Postgres 17 |
| D | Secrets | [ ] | **Ouverte.** Demande `supabase login` interactif, plus les valeurs LiveKit, R2 et Sentry de l'opérateur |
| E | CI/CD | [x] | `ci.yml` corrigé à l'étape 2 : son stub `auth` était incomplet, la migration 0001 n'aurait jamais pu s'y appliquer. `deploy.yml` vert dès que D est posée |
| F | Sentry | [ ] | Nécessite le compte Sentry |
| G | Variantes Flutter `dev` / `staging` / `prod` | [ ] | Un seul identifiant aujourd'hui : `com.rewayahacademy.app` |
| H | Stockage média R2 | [ ] | Nécessite le compte Cloudflare |
| I | LiveKit | [ ] | Nécessite le compte LiveKit |
| J | Config applicative `app_config` | [x] | Faite avec la migration 0001 |
| K | Mémoire graphify | [ ] | À faire |
| L | Ressources front et back | [x] | `pubspec.yaml`, `lib/core`, `lib/features`, `supabase/` conformes à l'étape 2 |
| M | PWA multiappareils | [ ] | Le build Web fonctionne ; manifest, service worker et URL déployée restent à faire |

## Décisions en attente de l'opérateur

| Sujet | Question | Où c'est documenté |
| :--- | :--- | :--- |
| `borderDefault` | La bordure mesure 1,86:1, sous le seuil de 3:1. Décoratif seulement, ou passer à `#8F8080` (3,03:1) pour qu'elle puisse porter du sens ? | `etape-2-journal.md`, section Mesures |
| Poids des polices | `NotoSans-Variable` pèse 2 Mo pour une interface française. Sous-ensembler ? | `etape-2-journal.md`, section Poids |
| `child_ui_mode_max_age` | Seuil d'âge séparant mode enfant et mode standard, toujours « à trancher » | `decisions.md`, registre des questions ouvertes |

## Règle de lecture

- Ce fichier est le miroir de l'avancement. Une session qui arrive sur un `[ ]`
  traite l'étape concernée avant tout autre travail, ou dit pourquoi elle ne le
  fait pas.
- Chaque étape a un critère de sortie vérifiable, défini dans
  `docs/agent-onboarding.md` et dans les plans d'étape.
- **Un contrôle qui n'a jamais tourné n'est pas un contrôle vert.** C'est ce qui
  a masqué le défaut de la CI pendant toute l'étape 1.
