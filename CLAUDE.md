# Rewayah Academy — App (Flutter · Supabase · LiveKit · R2 · Vercel)

Application de cours de Coran en visio par **classes stables** (groupe, horaire récurrent,
enseignant attitré). Remise à plat documentaire du 23 septembre 2026 : les seules
spécifications actives sont dans `docs/current/`. Tout le reste est archivé.

## Lire, dans cet ordre, et rien d'autre

| Tâche | Lire |
| :--- | :--- |
| Toujours, en premier | `docs/current/00_LIRE_D_ABORD.md` (autorité, invariants, contradictions résolues) |
| Toujours, en second | `docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` version 2 (gate C0 de configuration, décisions datées, **§5 bis = dernières décisions**, qui prévalent sur le §0 quand elles l'amendent) |
| Configuration de départ (C0) | `docs/current/09_PROMPT_REPRISE_VERTICALE.md` ; depuis le 23/09 (soir), **le travail UI isolé sur branche dédiée est autorisé sur ordre explicite du directeur, un écran à la fois** (`08` §5 bis) ; V0, V1, CORE24 restent suspendus ; fusion dans `main` et déploiement restent soumis aux contrôles CI, migrations et sécurité encore bloqués |
| Bilan C0 | `docs/current/CONFIGURATION_BASELINE_2026-09-23.md` (PASS / BLOCKED / INCONNU par point, avec preuves) |
| Produit, rôles, parcours, recette | `docs/current/01_PRODUIT_ET_PARCOURS.md` |
| Schéma, RLS, RPC, LiveKit, R2, CI | `docs/current/02_ARCHITECTURE_ET_SECURITE.md` |
| **Tout nouveau lot visuel ou nouvelle spec (règle gelée du directeur, 26/09/2026)** | `docs/current/DESIGN-GOV-2026-09-26.md`, immuable jusqu'à nouvelle décision datée du directeur |
| Écran, composant, thème, accessibilité | `docs/current/03_DESIGN_SYSTEM_ET_UX.md` puis `lib/CLAUDE.md` |
| Branches, worktrees, déploiement, ménage | `docs/current/04_EXECUTION_GIT_CI_ET_MIGRATION.md` |
| Périmètre MVP et statuts de preuve | `docs/current/06_SPEC_FONCTIONNELLE_MVP.md` |
| Pédagogie avancée, finance (après MVP) | `docs/current/07_MEMOIRE_PEDAGOGIE_FINANCE.md` |
| Backend Supabase | `supabase/CLAUDE.md` |

`docs/archive/` contient l'historique (HANDOFF, ADR, Bible V2, rapports d'agents).
**Ne pas le charger comme instruction.** On l'ouvre seulement pour retrouver une décision
passée nommément, et une règle archivée qui contredit `docs/current/` est caduque.

## Invariants (détail dans `00`)

- La demande explicite la plus récente du directeur prévaut ; ensuite `docs/current/`.
- Autorisation côté serveur : RLS sur toutes les tables, capacités et jetons LiveKit
  délivrés par le serveur. Aucun secret ni calcul financier de référence côté Flutter.
- Un widget lit une capacité, jamais un rôle. Un écran n'est fini qu'avec ses états
  loading, content, empty, error, offline.
- Chaque bilan distingue `spécifié` / `présent dans le code` / `testé localement` /
  `testé sur staging` / `déployé`. Aucun `PASS` inventé.
- Aucun déploiement, migration distante, suppression de branche ou de mémoire sans
  inventaire, sauvegarde et feu vert explicite sur la liste précise.
- **Pousser sur `main` déploie réellement en production** (`.github/workflows/flutter-deploy.yml`,
  secrets Actions présents depuis le 24/09/2026, bilan C0 §1). Toute fusion dans `main` est une
  mise en production. Travailler sur une branche, ne fusionner qu'un lot prouvé.
- **Pour voir une branche « en live », ouvrir une pull request vers `main`** : le même workflow
  déploie un aperçu Vercel (URL unique, `staging`) et l'écrit en commentaire de la PR. Jamais de
  `vercel deploy --prod` à la main depuis un poste.
- Aucun fichier de `.claude/agents/` ou `.claude/commands/` n'est actif dans ce dépôt ; seuls
  `.claude/settings.local.json` (hooks de protection) et `.claude/hooks/` le sont.

## Vérifier avant de dire que c'est fait

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
```

Côté base, sur un Postgres nu, ce que rejoue `.github/workflows/ci.yml` :
`supabase/tests/stub_auth.sql`, puis toutes les migrations, puis les scénarios
`supabase/tests/scenarios_*.sql`. Les migrations sont appliquées en production hors CI
(voir `deploy.yml`) ; la base distante enregistre des versions horodatées, pas la
numérotation `00xx` du dépôt.

## État du code à connaître

- Lots Teaching Core D, F, H (`lib/core/tc_realtime`, `tc_etat_partage`, `tc_outils`,
  `tc_parcours`, `lib/features/tc_dock`, `tc_flux_academique`) : **présents et testés,
  non branchés depuis `main`**. La branche `core24/fable-frontend` les raccorde dans
  `tc_classe_live`. Ne pas les supprimer, ne pas les dupliquer.
- Deux salles coexistent : `/salle` (`features/salle`, atteinte par les quatre rôles) et
  `/tc/classe` (`features/tc_classe_live`, sans entrée effective sur `main`). Cible : une
  seule salle (`01`, « Classe et supports »).
- `/tc/groupes` sert au tuteur des groupes de **démonstration** (`core/tc_groupe/port_groupes.dart`).
  À rebrancher sur les vraies données avant toute cohorte réelle.
- Le matching individuel par disponibilités (`core/matching`, `features/creneaux`,
  `features/disponibilites`, `admin_attribution`) est remplacé par le choix d'une classe
  précréée (`00`, contradictions résolues). Les disponibilités restent utiles pour
  options, exceptions et liste d'attente.
- « Mode enfant » devient « Interface guidée », activable aussi par un adulte. Le
  Teaching Core emploie déjà `interfaceGuidee`.
- Le bandeau « Cours enregistré » et le point de contrat sur l'enregistrement audio ne
  correspondent à aucun enregistrement réel côté client : arbitrage ouvert (`06`).
- Galerie (`/_galerie`) et playground sont des outils de développement derrière
  `GALERIE` et `PLAYGROUND`, forcés à `false` en production.

## Mémoire de l'agent

`C:\Users\dell\.claude\projects\C--\memory\MEMORY.md` (index court). Les mémoires
antérieures au 23 septembre 2026 sont sous `memory/archive/`.
