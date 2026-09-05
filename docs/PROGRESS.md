# PROGRESS — État d'initialisation du projet

> Document de suivi du protocole `docs/agent-onboarding.md`.
> Cohé par l'agent de code, une étape à la fois, jamais en bloc.
> Quand le fichier n'existait pas encore, une nouvelle session doit partir du **mode onboarding** (voir `CLAUDE.md`).

## État courant — PARTIELLEMENT INITIALISÉ (bootstrap fait)

Le socle de dépôt est en place. Les étapes qui ont pu être automatisées le sont ; les étapes restantes exigent une authentification interactive (compte) et/ou des ressources externes. Une nouvelle session d'agent de code doit reprendre le protocole `docs/agent-onboarding.md` **à la première étape non cochée** ci-dessous, dans l'ordre.

## Journal des étapes

| # | Étape | Livrable | Statut | Notes |
| :-- | :--- | :--- | :--- | :--- |
| A | Dépôt Git et branche | Dépôt `main`, `.gitignore`, remote `origin` | [x] | Repo local init, branche `main`, `.gitignore`, remote GitHub `Rewayah-Academy-Official-App` connecté, README distant tiré en local |
| B | Projets Supabase | Projet distant lié | [x] | Pas de nouveau projet : réutilise `gggmtelinlpseweouyav` (Rewayah Academy ltd's Project, eu-west-1, vide, prêt). `supabase/` init, `config.toml` pointé dessus |
| C | Migrations versionnées | CLI Supabase fonctionnelle, migration 0001 | [x] | CLI réparée (2.116.0, binaire Windows direct, shim `supabase.cmd`). Migration `0001_fondations.sql` écrite et **validée verte** sur Postgres 17 (harness Docker : schéma, RLS, état machine sessions, besoin d'appareils C11, chaîne d'audit, `next_immutable_id`). `seed.sql` ajouté (seeds embarqués dans la migration) |
| D | Secrets | Secrets GitHub / Supabase, zéro clé en dur | [ ] | Nécessite `supabase login` interactif + valeurs LiveKit/R2/Sentry à fournir par l'opérateur |
| E | CI/CD | `.github/workflows/` (ci, deploy) | [x] | `ci.yml` (lint TyposSQL sur les migrations + job Flutter Web/Android/Windows activé dès que `pubspec.yaml` existe) et `deploy.yml` (migrations + Edge Functions vers `gggmtelinlpseweouyav` sur `main`/tag `v*`). Vert dès que les secrets de l'étape D sont posés (`SUPABASE_DB_URL`, `SUPABASE_ACCESS_TOKEN`) |
| F | Sentry | Projets Flutter + Edge, DSN branchés | [ ] | Nécessite le compte Sentry |
| G | Variantes Flutter | `dev`, `staging`, `prod` | [ ] | Trois identifiants distincts |
| H | Stockage média R2 | Bucket privé, cycle de vie 30 j | [ ] | Nécessite le compte Cloudflare |
| I | LiveKit | Projet Cloud, secrets, webhook | [ ] | Nécessite le compte LiveKit |
| J | Config applicative | Table `app_config` + lecture | [ ] | Fait avec la migration 0001 de l'étape C |
| K | Mémoire graphify | Graphe indexé + `GRAPH_REPORT.md` | [ ] | À faire |
| L | Ressources front/back | `pubspec.yaml`, structure `lib/`, `supabase/` | [ ] | À vérifier |
| M | PWA multiappareils | Manifest, service worker, URL déployée | [ ] | Windows, Android, iPad |

## Règle de lecture

- Le protocole `docs/agent-onboarding.md` est le maître. Ce tableau est son miroir.
- Chaque étape a un critère de sortie vérifiable, défini dans le protocole et/ou dans `docs/architecture/etape-0-1-fondations.md`.
- Une session qui arrive sur un `[ ]` continue l'étape concernée avant tout autre travail.