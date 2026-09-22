# Core24 Classes V2 — rapport de remédiation interrompu

Ce rapport couvre uniquement le premier incrément du lot A. Le prompt de
mission impose de ne pas ouvrir les lots suivants tant que la gate PostgreSQL
du lot A n'est pas verte.

## État

| Champ | Valeur |
|---|---|
| AUDIT SOURCE | FOUND |
| AUDIT PATH | `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-classes-v2\CORE24_CLASSES_COMPLIANCE_AUDIT.md` |
| PROMPT SOURCE | `D:\RA _APP\init_prompt.txt` |
| BASE BRANCH | `integration/core24-classes-v2` |
| BASE HEAD | `e8beeb7a2b8ae8d15bab1aca621b594909675c93` |
| REMEDIATION BRANCH | `integration/core24-classes-v2-remediation` |
| COMMITS AVANT REPRISE | `53eb702 fix(classes): reconcile data model and security` ; `ef4dfd5 docs(classes): record lot a gate blocker` |

## Avant / après

Les comptes de l'audit retrouvé restent la référence avant remédiation :

- IMPLEMENTED BEFORE: 14
- PARTIAL BEFORE: 46
- MISSING BEFORE: 1
- CONTRADICTED BEFORE: 4
- NOT_VERIFIABLE BEFORE: 18

Les comptes globaux après remédiation ne sont pas recalculés : les lots B à E
n'ont pas été ouverts et l'audit final n'a pas été exécuté.

## Lot A livré localement

- verrouillage de `cohorte`, `date_naissance`, `placement_basis`,
  `diagnostic_statut` et `level` contre les écritures directes du client ;
- cohorte dérivée de la date de naissance, avec bornes testées 5, 9, 10, 13,
  14 et 17 ans ;
- état/provenance du diagnostic mis à jour par la porte Admin canonique ;
- file Admin des diagnostics filtrée sur les états réellement à traiter ;
- scénarios SQL ajoutés pour le profil legacy sans DOB, les privilèges et le
  placement officiel.

## Gates

| Gate | Résultat | Preuve / limite |
|---|---|---|
| POSTGRES FRESH REPLAY | BLOCKED_INFRA | Le CLI Supabase échouait avant le replay avec `LegacyLocalDbRunningError` ; le contexte Docker `desktop-linux` ne répondait pas. |
| DISPATCH CONCURRENCY | NOT_RUN | Hors Gate A. |
| RLS | NOT_RUN | Scénarios statiques ajoutés, aucun replay PostgreSQL frais. |
| FLUTTER ANALYZE | NOT_RUN | Hors périmètre Gate A ; aucun fichier Dart modifié. |
| FULL TEST SUITE | NOT_RUN | Hors périmètre Gate A. |
| READY_FOR_INTEGRATION | NOT_RUN | La preuve PostgreSQL/RLS manque. |

## Reprise du 23 septembre : diagnostic du replay local

- Docker Desktop 29.7.2 et Supabase CLI 2.116.0 sont installés. Le projet
  Supabase local `gggmtelinlpseweouyav` possède déjà des conteneurs et des
  ports 54321/54322/54324 ; aucun reset de ce projet n'a été fait.
- L'API Docker Linux a répondu par intermittence avec HTTP 500, y compris sur
  `_ping` et l'inspection des conteneurs. Docker Desktop et la distribution
  WSL `docker-desktop` ont été relancés localement ; le moteur est redevenu
  utilisable temporairement. Aucune action distante n'a été effectuée.
- Un conteneur PostgreSQL 17 distinct a chargé `stub_auth.sql` et les migrations
  `0001` à `0029` dans l'ordre. Le replay a échoué dans
  `0030_tc_socle.sql:209` : `storage.buckets` n'existait pas.
- Cause trouvée dans le dépôt : `.github/workflows/ci.yml` appelle
  `supabase/tests/stub_storage.sql` avant les migrations, mais ce fichier
  n'était pas versionné. Un stub Storage minimal a été ajouté pour ce harnais
  PostgreSQL nu. Il reste à le valider sur une base neuve.
- Le conteneur de test et son volume anonyme contenant le replay partiel ont
  été supprimés. Ils ne sont pas récupérables. La tentative de recréation
  suivante a été interrompue après blocage de l'API Docker ; une vérification
  ciblée a confirmé qu'aucun conteneur de test de ce nom n'est resté créé.
- `git diff --check` : PASS pour les changements de cette reprise.

La gate A reste **BLOCKED_INFRA** : le replay corrigé, les scénarios d'âge et les tests
RLS n'ont pas passé sur une base neuve. Les lots B à E restent fermés.

## Sécurité de livraison

- PRODUCTION MODIFIED: NO
- REMOTE MIGRATION: NO
- DEPLOYMENT: NO
- `main` non modifiée ; la remédiation est isolée dans son worktree.
- Les modifications préexistantes du worktree audité (`windows/flutter/generated_*`
  et son audit non suivi) n'ont pas été écrasées.

## Gaps restants

1. Rétablir un moteur Docker stable, puis rejouer `stub_auth.sql`,
   `stub_storage.sql`, toutes les migrations et
   les scénarios du lot A sur une base neuve.
2. Ne commencer le lot B qu'après une gate A PASS : dispatch transactionnel,
   scénarios 7/8/12/13, concurrence, idempotence et absence de double
   affectation.
3. Lots C à E non traités : diagnostic/onboarding complet, titulaire et
   remplacement, câblage Admin/vertical slice et interface guidée.
4. Produire `CORE24_CLASSES_COMPLIANCE_AUDIT_FINAL.md` uniquement après la
   remédiation complète et les preuves correspondantes.

## Reprise de la Gate A — 23 septembre 2026

### A. Docker, Supabase local et cause

Le worktree `integration/core24-classes-v2-remediation` était propre au HEAD
`4be8a106c64b1b3e580878111a575ba51587978e` au départ. Les processus
Docker Desktop et `com.docker.backend` existent ; `WSLService` est démarré,
`com.docker.service` et `LxssManager` sont arrêtés (démarrage manuel).
`docker version` et `docker ps -a` renvoient `permission denied` sur
`npipe:////./pipe/dockerDesktopLinuxEngine`. `wsl --list --verbose` renvoie
`Wsl/EnumerateDistros/Service/E_ACCESSDENIED`. Avec accès étendu,
`docker info` ne répond toujours pas après 30 secondes et a été interrompu.
Le CLI Supabase échoue sur l'écriture de son fichier de télémétrie sous
`C:\Users\dell\.supabase` (`EPERM`) avant de donner une version.

Les pipes Docker existent, mais la liste des conteneurs Supabase, leur santé,
leurs logs, volumes, ressources et éventuels orphelins sont **BLOCKED_INFRA**.
La recherche de connexions locales sur 54321/54322/54324 n'a rien retourné
dans cette session ; elle ne prouve pas l'absence de conteneurs. Les compteurs
CIM mémoire/disque ont renvoyé `Accès refusé`. Le run précédent avait observé
des HTTP 500 intermittents de l'API Docker, même sur `_ping` ; la cause
profonde de cette instabilité n'est pas établie. La cause immédiate de ce run
est l'impossibilité d'accéder au moteur/à WSL. Aucun service, conteneur ou
volume partagé n'a été réinitialisé.

### B. `stub_storage.sql`

**TEST_ONLY.** Le commit `28c9fe8` ajoute seulement
`supabase/tests/stub_storage.sql`. La CI le charge, après `stub_auth.sql`,
dans PostgreSQL 17 nu avant les migrations. Ce fixture crée le minimum de
`storage.buckets`, `storage.objects` et `storage.foldername`. Il ne fait pas
partie des migrations staging/production. Les migrations `0030` et `0032`
attendent le vrai schéma Supabase Storage lorsqu'elles ciblent Supabase ;
le fixture compense son absence propre au harnais PostgreSQL nu. Le run
précédent s'est arrêté à `0030_tc_socle.sql:209`, sur
`insert into storage.buckets` (relation inexistante), avant l'ajout du
fixture. Aucun replay corrigé n'a encore confirmé ce choix.

### C-D. Fresh replays et migrations

| Essai | Statut | Preuve |
|---|---|---|
| Fresh replay #1 de ce run | BLOCKED_INFRA | Aucune base fraîche créée ; moteur inaccessible. |
| Fresh replay #2 de ce run | NOT_RUN | Le premier replay n'a pas abouti. |

Les 50 fichiers SQL de `supabase/migrations/*.sql` sont présents, de
`0001_fondations.sql` à `20260923000600_core24_lot_a_contracts.sql`.
**Aucune migration exécutée dans ce run.** Le replay partiel ancien de
`0001` à `0029` suivi de l'échec à `0030` ne compte ni pour #1 ni pour #2.

### E. Invariants DB

**NOT_RUN** : contraintes structurelles, clés étrangères, uniques, CHECK,
triggers, RPC CORE24, invariants de classes, contraintes d'âge et transitions
DB. La lecture des SQL ne remplace pas leur exécution.

### F. Scénarios d'âge

L'arbitrage canonique exige les cohortes actives `6-9`, `10-13`, `14-17`,
`18+`, une date de naissance canonique pour les mineurs, un enfant de moins
de 6 ans hors dispatch standard et aucune date inventée pour un legacy.
`scenarios_core24_classes_reconciliation.sql` couvre les anniversaires
5/9/10/13/14/17 ans, la persistance de cohorte, le legacy sans date et
le refus de forcer une cohorte adulte pour un mineur. Chaque scénario est
**NOT_RUN** dans ce run.

### G. Matrice RLS réellement exécutée

Aucune cellule exécutée. Les futures requêtes utilisateur doivent utiliser
le rôle/JWT pertinent, jamais `service_role` comme preuve d'accès utilisateur.

| Rôle | Lecture autorisée | Accès transversal interdit | Écriture interdite | Suppression/soft-delete et isolement foyer/classe |
|---|---|---|---|---|
| admin | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| enseignant | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| tuteur | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| élève | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| contrôleur, si concerné | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| anonymous/authenticated, selon surface | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |

### H-I. Commandes et preuves

Exécutés : `git status --short --branch`, `git rev-parse HEAD`,
`git worktree list --porcelain`, `git show 28c9fe8`, lectures des migrations,
tests, CI et arbitrages ; `docker version`, `docker ps -a`, `docker info`,
`wsl --list --verbose`, `wsl --status`, `Get-Process`, `Get-Service`,
`Get-NetTCPConnection`, `Get-CimInstance`, `supabase --version`.
Résultats et limites sont indiqués ci-dessus. **Aucun `psql`, test SQL, RLS,
ni scénario d'âge exécuté.**

### Specs remplacées

Google Meet est historique/remplacé ; LiveKit est canonique (ADR-001).
Les anciens HEX ne constituent pas automatiquement des violations : la
Bible Frontend V2 interdit `Color(0x...)`/HEX codés dans les widgets métier,
autorise les primitives dans foundations/theme/design tokens et demande
aux écrans les rôles sémantiques/tokens. Aucune refonte UI effectuée.

### J-L. Git et livraison

Seul ce rapport a été modifié dans ce run ; `main`, les autres worktrees et
la production sont inchangés. Commits de remédiation préexistants :
`53eb702`, `ef4dfd5`, `28c9fe8`, `4be8a10`. Le commit documentaire final
est visible par `git log -1` après livraison. `git diff --check` et le
statut Git final sont relevés au moment du commit.

GATE A: BLOCKED_INFRA
FRESH REPLAY #1: BLOCKED_INFRA
FRESH REPLAY #2: NOT_RUN
RLS: NOT_RUN
AGE SCENARIOS: NOT_RUN
STUB_STORAGE: TEST_ONLY
PRODUCTION: UNCHANGED
SAFE_TO_OPEN_GATE_B: NO
