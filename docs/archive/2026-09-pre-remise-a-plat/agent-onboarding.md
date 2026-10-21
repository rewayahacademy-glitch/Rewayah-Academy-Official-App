# Protocole d'onboarding — Première exécution sur ce dépôt

Ce document est le **protocole obligatoire** exécuté par l'agent de code à sa toute première session dans ce dépôt. Il met en place **toutes** les configurations une fois pour toutes, pour que le reste du travail ne soit que de l'implémentation pure.

Le protocole met à jour `docs/PROGRESS.md` qui coche chaque étape. **L'agent de code** est le seul à modifier ce fichier au fil de l'eau ; la présence d'étapes non cochées signifie que l'onboarding n'est pas terminé et qu'il faut la reprendre là où elle s'arrête.

---

## Avant de commencer

- Vérifier que Git, le CLI Supabase fonctionnel, Node.js et Flutter sont installés.
- Vérifier l'authentification à GitHub (`gh auth status`) et à Supabase (CLI ou jeton `sbp_`).
- Vérifier que l'on est bien dans `D:\RA _APP\RA -OFFICIAL-APP`.

Si un outil manque, **l'installer d'abord**, puis reprendre le protocole là où l'on s'est arrêté.

---

## Étape A — Dépôt Git et branche

1. Vérifier `git status`. Si le dépôt n'est pas initialisé, `git init`, puis `git branch -m main`.
2. Créer le fichier `.gitignore` racine couvrant au minimum : `.env*`, `*.env`, `supabase/.temp/`, `supabase/.branches/`, `node_modules/`, `build/`, `.dart_tool/`, `*.keystore`, `keys/`, `secrets/`, `.idea/`, `.vscode/` (aménagé pour garder les fichiers de workspace), `*.log`, `Thumbs.db`, `.DS_Store`.
3. S'assurer que la branche par défaut est `main`.

## Étape B — Projet Supabase (déjà créé par l'opérateur)

**Ne pas créer de nouveau projet.** L'opérateur dispose déjà d'un projet dédié : `gggmtelinlpseweouyav` (Rewayah Academy ltd's Project, eu-west-1). C'est lui qui doit servir de cible pour staging et production — en single-project, les environnements se distinguent par branche (staging = branche de dev/PR, prod = branche `main` ou tag `v*`), pas par un projet séparé.

1. S'assurer que `supabase login` est fait (jeton d'accès présent).
2. Vérifier que `supabase link --project-ref gggmtelinlpseweouyav` est effectif (le fichier `supabase/.temp/project-ref` doit contenir `gggmtelinlpseweouyav`).
3. Vérifier que les deux projets répondent et noter l'URL d'API et l'`anon_key` **dans les secrets GitHub**, jamais dans le dépôt.
4. Activer le PITR si l'opérateur le souhaite (optionnel en single-project MVP).

## Étape C — Migrations versionnées

1. S'assurer que le CLI Supabase est fonctionnel sur Windows.
2. Créer la structure `supabase/` avec `migrations/`, `functions/`, `config.toml`, `seed.sql`.
3. Les migrations sont numérotées `NNNN_nom.sql` et s'appliquent dans l'ordre. Une base vide doit pouvoir être reconstruite intégralement par la seule application des migrations, sans intervention manuelle (critère d'acceptation 0.3 d'`etape-0-1-fondations.md`).
4. Créer la première migration de socle (table `app_config` au minimum, voir section 8 d'`etape-0-1-fondations.md`).

## Étape D — Secrets (jamais en dur)

Les clés suivantes vivent **uniquement** dans les secrets GitHub et les secrets Supabase :

| Secret | Usage |
| :--- | :--- |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | Client (staging et prod selon branche) |
| `SUPABASE_SERVICE_ROLE` | Edge Functions uniquement |
| `LIVEKIT_WS_URL` / `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` | Visio (ADR-001) |
| `R2_*` | Stockage média (ADR-002) |
| `SENTRY_DSN_FLUTTER` / `SENTRY_DSN_EDGE` | Supervision (0.6) |

Recherche de toute clé dans le dépôt : **zéro résultat**.

## Étape E — CI/CD (GitHub Actions)

Créer `.github/workflows/` avec au minimum :

1. `ci.yml` — analyse statique (lints Dart/TyposSQL), tests, build Flutter pour Windows, Android et Web sur chaque PR vers `main`.
2. `deploy.yml` — application des migrations Supabase et déploiement des Edge Functions vers le projet `gggmtelinlpseweouyav` (branche staging → pré-prod, `main` ou tag `v*` → prod).

Le critère : **la CI échoue sur une erreur d'analyse volontairement introduite** (test de non-régression de la CI elle-même).

## Étape F — Supervisions (Sentry)

1. Créer un projet Sentry pour Flutter et un pour les Edge Functions (s'ils n'existent pas).
2. Brancher les DSN.
3. Vérifier qu'une erreur volontaire remonte dans le tableau de bord (critère 0.6).

## Étape G — Variantes Flutter (`dev`, `staging`, `prod`)

1. Ajouter les fichiers de variantes (`--dart-define` ou `flutter_flavors`).
2. Trois identifiants d'application distincts, installables côte à côte (Android Application ID, bundle ID iOS, URI Web).
3. Configurer le **mode Web/PWA** pour permettre l'accès depuis Windows, Android et iPad sans attendre la publication native.

## Étape H — Stockage média (R2)

1. Créer un bucket R2 **privé** avec une règle de cycle de vie à 30 jours (ADR-002).
2. Vérifier qu'un objet de test disparaît après expiration simulée.

## Étape I — LiveKit

1. Créer un projet LiveKit Cloud.
2. Stocker les clés dans les secrets Supabase (jamais dans Flutter — ADR-001).
3. Déclarer l'endpoint webhook.
4. Vérifier qu'un événement de test atteint l'endpoint et est vérifié en signature.

## Étape J — Configuration applicative (`app_config`)

1. Créer la table `app_config` et son mécanisme de lecture.
2. Une clé modifiée en base change le comportement sans redéploiement (critère 0.11).

## Étape K — Mémoire "graphify"

1. Initialiser un graphe de connaissances (`graphify`) indexant les documents de `docs/` et la structure du dépôt, pour retrouver rapidement les décisions (ADR), les règles métier et la localisation des fichiers.
2. Créer la fiche `GRAPH_REPORT.md` à la racine ou dans `docs/`.

## Étape L — Ressources frontend/backend nécessaires

1. Vérifier la liste des packages Flutter dans `pubspec.yaml` : l'essentiel pour le MVP-0 (supabase_flutter, go_router, drift, flutter_secure_storage, flutter_cache_manager, livekit_client, etc.). N'installer que ce qui est réellement nécessaire à l'implémentation.
2. Vérifier la structure `lib/` (core, features) conforme à l'Étape 2.
3. Vérifier la structure `supabase/` conforme à l'Étape 1.

## Étape M — PWA multiappareils

Le critère de cette étape : **un accès fonctionnel le plus tôt possible depuis Windows, Android et iPad**, en PWA tant que le natif n'est pas publié.

1. Activer et configurer le manifest Web (nom, icône, couleur de thème).
2. Activer les service workers pour le mode hors ligne.
3. Vérifier que l'URL Web déployée (Netlify, Cloudflare Pages, Vercel, ou autre) ouvre l'app et qu'elle est installable en PWA sur Android et iPad.

---

## Fin de protocole

Quand toutes les étapes A à M sont cochées, créer `docs/PROGRESS.md` avec la liste de toutes les étapes et leur statut `[x]`, puis faire un commit initial. Ensuite seulement, le projet est "initialisé" et l'on peut reprendre à l'étape de code correspondante.

---

## Règles : à ne jamais faire pendant l'onboarding

- Ne jamais créer un projet Supabase **sans demander confirmation du coût** à l'opérateur (les projets ne sont pas gratuits au-delà du tier gratuit).
- Ne jamais pousser de clé en dur, même dans un commit "de travail".
- Ne jamais sauter une étape pour "aller plus vite" : chaque étape a un critère de sortie et c'est ce qui rend le dépôt autonome.
- Ne jamais créer plus d'un fichier de config dispersé : chaque config a un seul endroit canonique.
