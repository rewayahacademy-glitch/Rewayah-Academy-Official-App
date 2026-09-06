# PROGRESS — État d'avancement du projet

> Suivi tenu par l'agent de code, une étape à la fois, jamais en bloc.
> C'est le seul fichier à lire pour savoir quoi faire ensuite.

## DÉMARRER ICI — prochaine session (ne rien chercher d'autre)

**Lire `docs/HANDOFF.md` en premier, avant toute action.** Il dit quel est le
dépôt actif, où le travail s'est arrêté, quel lot reprendre, et avec quelles
commandes. Le reste de ce fichier est le tableau d'avancement, pas la consigne
de reprise.

**L'étape 3 est terminée, l'étape 4 est en cours** : les lots L0 à L8 sont
faits, le prochain est **L9, `ADM-01` et `ADM-06`**.

1. **Lire, dans cet ordre, et rien de plus** : `docs/HANDOFF.md`, puis
   `docs/architecture/etape-4-journal.md` (où en est l'étape, lot par lot), puis
   `docs/architecture/etape-4-dashboards.md` (la spécification, ses neuf défauts
   corrigés et ses douze invariants), puis `lib/CLAUDE.md`.
2. **Ne rien réécrire des étapes 2 et 3.** Les dix composants partagés, le
   thème, le routeur et les services de dossier sont les seuls points d'entrée
   de leur fonction. `dart run tool/verifier_jetons.dart` le dira.
3. **Ne rien réécrire des lots L2 à L8.** Les services de planning, de règles,
   de matching, d'administration, de prières, de réseau, d'appairage et de
   photos existent, avec leurs faux dans `test/support/harnais.dart`. Le tableau
   du handoff dit lequel sert à quoi.
4. **Le démarrage à froid a désormais où se mesurer.** L'application est en
   ligne depuis le 7 septembre : installer la PWA sur un vrai téléphone d'entrée
   de gamme donne enfin une mesure du scénario 14. Elle sera pessimiste, un
   bundle web pesant plus qu'un APK. Les cibles natives, elles, restent fermées
   sur ce poste : `atlstr.h` pour Windows, le magasin de certificats pour
   l'APK — et **pas** la plateforme du SDK, contrairement à ce qui était écrit.
5. **L'application est en service.** Base réelle peuplée, fonctions Edge
   déployées, PWA en ligne. **Lire `docs/MISE-EN-SERVICE.md`** avant de toucher
   au SQL ou au déploiement : `0005` ne se corrige plus sur place, et deux
   commandes de configuration restent à la main de l'opérateur.

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
psql -f supabase/tests/scenarios_etape4.sql              # 39 contrôles
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
| C | Migrations versionnées | [x] | `0001` à `0005`, **appliquées au projet réel le 7 septembre 2026** et inscrites dans `supabase_migrations`. Le risque `pgcrypto` du journal de l'étape 3 était réel, et il est corrigé. **Corollaire : `0005` ne se corrige plus sur place**, tout changement structurel passe par `0006`. Voir `docs/MISE-EN-SERVICE.md` |
| D | Secrets | [~] | Aux trois quarts fermée : projet lié, `dart_define.json` écrit, fonctions Edge `creer-profil-enfant` et `session-enfant` **déployées et `ACTIVE`**. Restent **deux commandes à la main de l'opérateur**, le hook de jeton et `STUDENT_EMAIL_DOMAIN`, détaillées dans `docs/MISE-EN-SERVICE.md` section 3. Sans le hook, toutes les RLS refusent et l'application n'affiche que du vide, sans la moindre erreur |
| E | CI/CD | [x] | `ci.yml` rejoue les 73 contrôles SQL de `supabase/tests/` à chaque pull request, 34 pour les étapes 1 et 3, 39 pour l'étape 4 |
| F | Sentry | [ ] | Nécessite le compte Sentry |
| G | Variantes Flutter `dev` / `staging` / `prod` | [ ] | Un seul identifiant aujourd'hui : `com.rewayahacademy.app` |
| H | Stockage média R2 | [ ] | Nécessite le compte Cloudflare. Les seaux `kyc` et `avatars` de Supabase Storage, eux, sont créés par la migration 0004 |
| I | LiveKit | [ ] | Nécessite le compte LiveKit |
| J | Config applicative `app_config` | [x] | Étendue à l'étape 3 : `kyc_retention_days`, `pairing_code_ttl_minutes` |
| K | Mémoire graphify | [ ] | À faire |
| L | Ressources front et back | [x] | Conformes aux étapes 2 et 3 |
| M | PWA multiappareils | [x] | En ligne sur <https://rewayah-academy.vercel.app>, chargée sans erreur console. Manifeste, `index.html` et `vercel.json` portent le nom, la palette, la balise `viewport` qui manquait et la réécriture SPA. Service worker généré par Flutter. Reste à décider : le plan Vercel Hobby exclut l'usage commercial |

## Décisions en attente de l'opérateur

| Sujet | Question | Où c'est documenté |
| :--- | :--- | :--- |
| `borderDefault` | La bordure mesure 1,86:1, sous le seuil de 3:1. Décoratif seulement, ou passer à `#8F8080` (3,03:1) pour qu'elle puisse porter du sens ? | `etape-2-journal.md`, section Mesures |
| Poids des polices | `NotoSans-Variable` pèse 2 Mo pour une interface française. Sous-ensembler ? | `etape-2-journal.md`, section Poids |
| `child_ui_mode_max_age` | Posé à **8** et employé tel quel par l'étape 3. Modifiable en une ligne d'`app_config`, sans redéploiement. À confirmer ou corriger | `decisions.md`, ADR-016 |
| Lecture du QR par la caméra | Reportée : le paquet réclame une configuration de permissions par plateforme. Le chemin par le code fonctionne partout. À rouvrir si le QR devient nécessaire | `etape-3-auth-kyc.md` section 9 |
| Compression serveur des photos | **Devenue concrète au lot L8** : `TUT-05` dépose désormais vraiment la photo dans le seau `avatars`, avec un refus au-delà de 4 Mo côté client et rien de plus. Aucune compression serveur n'existe, donc le cache local ne peut pas borner sa taille comme l'étape 2 le prévoyait, et c'est l'original du téléphone qui est servi aux appareils du foyer | `decisions.md`, question 17 |
| Litige sur le temps effectif | L'étape 4 pose le minimum payable et sa trace, l'étape 5 mesurera la présence réelle. Les deux doivent se rejoindre avant la première paie | `decisions.md`, question 16 |
| Composant ATL de Visual Studio | Le build Windows échoue sur `atlstr.h` absent, réclamé par `flutter_secure_storage_windows`. Installer « C++ ATL for latest v143 build tools » dans Visual Studio Build Tools | `etape-3-journal.md` |
| Magasin de certificats du poste | **Remplace la ligne « Plateforme Android 37 », qui était fausse** : `sdkmanager "platforms;android-37"` répond `Failed to find package`, ce paquet n'existe pas, Google publie `android-37.0` et il est déjà installé. Le build APK échoue en réalité parce que le hook de `package:sqlite3` ne peut pas joindre `github.com` en TLS — et `Invoke-WebRequest` échoue pareillement, donc c'est le poste, pas Flutter. À réparer côté racines Windows ou antivirus, jamais en désactivant la vérification | `MISE-EN-SERVICE.md` section 4.1 |
| Deux commandes de configuration Supabase | Le hook de jeton et `STUDENT_EMAIL_DOMAIN`. Elles ont été refusées à l'agent par la barrière de sécurité du poste, qui bloque toute écriture de configuration Auth distante et tout secret. **Sans le hook, l'application se connecte et n'affiche que des écrans vides, sans erreur** | `MISE-EN-SERVICE.md` section 3 |
| Plan d'hébergement | La PWA est sur Vercel Hobby, gratuit, dont les conditions **excluent l'usage commercial**. À trancher avant l'ouverture payante : plan payant, ou un hébergeur statique gratuit qui autorise le commerce | `MISE-EN-SERVICE.md` section 4 |
| Appareil de mesure du démarrage à froid | Le scénario 7 de l'étape 2 demande **moins de 1,5 seconde sur un appareil d'entrée de gamme**. L'écran existe depuis L7 et l'application est en ligne depuis le 7 septembre : la mesure est désormais possible en installant la PWA sur un vrai téléphone d'entrée de gamme. Elle sera pessimiste, un bundle web pesant plus qu'un APK, donc un échec ne condamnerait pas le produit mais une réussite compterait | `etape-4-journal.md`, section L7 |

## Règle de lecture

- Ce fichier est le miroir de l'avancement. Une session qui arrive sur un `[ ]`
  traite l'étape concernée avant tout autre travail, ou dit pourquoi elle ne le
  fait pas.
- Chaque étape a un critère de sortie vérifiable, défini dans
  `docs/agent-onboarding.md` et dans les plans d'étape.
- **Un contrôle qui n'a jamais tourné n'est pas un contrôle vert.** C'est ce qui
  a masqué le défaut de la CI pendant toute l'étape 1.
