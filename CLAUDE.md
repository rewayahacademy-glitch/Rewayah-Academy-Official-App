# Rewayah Academy — App (Flutter · Supabase · LiveKit)

Application MVP de gestion des cours de Coran en visio pour Rewayah Academy.
Cible multi-plateforme : **Windows (desktop/Web)**, **Android**, **iOS/iPadOS** — l'accès le plus tôt possible passe par le mode **PWA** tant que le natif n'est pas publié.

## Ce que tu es

Tu es l'agent de code de ce projet. Ta mission : **transformer les spécifications livrées en implémentation pure**, sans jamais retomber dans de la configuration dispersée. Toute config, une fois faite, est codée dans le dépôt (`supabase/`, `.github/`, `web/`, etc.). Tu ne reconfigures rien au fil de l'eau.

## Classement des documents — à lire dans cet ordre (jamais tous d'un coup)

| Si tu touches | Lis d'abord | Rôle |
| :--- | :--- | :--- |
| Tout le projet, au démarrage | `docs/architecture/decisions.md` | Le registre ADR (questions déjà tranchées) |
| Le schéma, RLS, fonctions, migrations | `docs/architecture/etape-0-1-fondations.md` | Dictionnaire de données, contraintes, tests d'acceptation |
| Le backend Supabase | `supabase/CLAUDE.md` | Rappels non négociables du dossier |
| Un écran, un composant Flutter | `docs/produit/parcours-utilisateurs.md` | États, direction artistique, raisons des choix |
| Le thème, les composants partagés, le routeur | `docs/architecture/etape-2-core-flutter.md` | Les 9 composants partagés et le routeur unique |
| Le front-end Flutter | `lib/CLAUDE.md` | Rappels non négociables du dossier |

### Historique (ne les ouvre que sur demande explicite)

`docs/historique/couverture-specs.md` et `docs/historique/etat-des-lieux.md` ont servi à cadrer le projet avant le code. Leur contenu utile est repris dans `decisions.md`. Ne les lis pas par défaut.

## Première exécution sur ce dépôt — PRIMO OBLIGATOIRE

**La première fois que tu es lancé dans ce dépôt, et avant toute autre tâche**, tu dois détecter si le fichier `docs/PROGRESS.md` existe.

- **S'il n'existe PAS** : le projet n'a jamais été initialisé. Tu passes en **mode onboarding** et tu exécutes intégralement le protocole `docs/agent-onboarding.md` (github, CI/CD, Supabase staging+prod, secrets, cache, mémoire graphify, ressources frontend/backend, PWA). Tu ne fais AUCUNE autre tâche avant de l'avoir terminé. À la fin, tu crées `docs/PROGRESS.md` qui coche chaque étape et tu fais un commit.
- **S'il EXISTE** : le projet est initialisé. Tu lis la dernière section de `PROGRESS.md`, tu reprends là où le lead précédent s'est arrêté, et tu appliques les consignes de `docs/agent-onboarding.md` si une étape y est encore non cochée.

## Règles transverses (à respecter sans exception)

- Aucun secret versionné. `git-secrets` / `.gitignore` toujours vérifiés. Les clés (Supabase service_role, LiveKit, R2) ne vivent que dans les secrets Supabase / GitHub, jamais en dur.
- L'argent est un entier en unités mineures. Jamais de float sur de l'argent.
- RLS activée sur toutes les tables, sans exception.
- Toute fonction `SECURITY DEFINER` fixe `search_path = ''` et qualifie chaque objet.
- Toute config est codée dans le dépôt : `supabase/migrations/`, `supabase/functions/`, `.github/workflows/`, `lib/core/`.
- Un seul routeur pour toutes les plateformes, aucune branche par plateforme. Le mode enfant/standard change l'affichage, jamais l'arborescence.
- Tant que le natif n'est pas publié, tout doit fonctionner en PWA (Windows, Android, iPad) pour que l'opérateur suive l'évolution tôt. Le Web est ouvert à tous les rôles (ADR-008).

## Rappels des références mappées

| Fichier source (docs de lancement) | Emplacement dans ce dépôt |
| :--- | :--- |
| `AUDIT_ARCHITECTURE_REWAYAH_APP.md` | `docs/architecture/audit-initial.md` |
| `DECISIONS_ARCHITECTURE_MVP0.md` | `docs/architecture/decisions.md` |
| `PLAN_ETAPE_0_ET_1.md` | `docs/architecture/etape-0-1-fondations.md` |
| `PLAN_ETAPE_2.md` | `docs/architecture/etape-2-core-flutter.md` |
| `PARCOURS_UTILISATEURS_MVP0.md` | `docs/produit/parcours-utilisateurs.md` |
| `COUVERTURE_SPECS_ORIGINALES.md` | `docs/historique/couverture-specs.md` |
| `ETAT_DES_LIEUX_AVANT_CODAGE.md` | `docs/historique/etat-des-lieux.md` |
| `supabase_CLAUDE.md` | `supabase/CLAUDE.md` |
| `lib_CLAUDE.md` | `lib/CLAUDE.md` |

## Ordre d'exécution du code (déjà cadré par les specs)

1. **Étape 0** — Socle d'exploitation (git, Supabase staging+prod, migrations versionnées, PITR, Sentry, CI/CD, variantes Flutter, R2, LiveKit, `app_config`).
2. **Étape 1** — Fondations DB, RLS, fonctions, triggers, audit (aucune interface).
3. **Étape 2** — Core Flutter, thème, cache local, routeur unique.
4. **Étape 3** — Auth, KYC, appairage, portails d'attente.
5. **Étape 4** — Dashboards Bento Grid.
6. **Étape 5** — Visio LiveKit, preuve de présence, Coran.
7. **Étape 6** — Cahier de transmission.

Voir `docs/architecture/etape-0-1-fondations.md` pour les critères d'acceptation et les scénarios de test de chaque étape.
