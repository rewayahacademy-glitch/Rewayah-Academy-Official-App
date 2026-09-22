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
| COMMITS | `53eb702 fix(classes): reconcile data model and security` |

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
| POSTGRES FRESH REPLAY | FAIL | Le CLI Supabase échoue avant le replay avec `LegacyLocalDbRunningError` lors de l'inspection de `supabase_db_gggmtelinlpseweouyav`; le contexte Docker `desktop-linux` ne répond pas. |
| DISPATCH CONCURRENCY | NOT RUN | Bloqué par la gate A. |
| RLS | NOT VERIFIABLE | Scénarios statiques ajoutés, aucun replay PostgreSQL frais. |
| FLUTTER ANALYZE | NOT RUN | Hors périmètre du lot A et aucun fichier Dart modifié. |
| FULL TEST SUITE | NOT RUN | Les lots dépendants et la recette globale ne sont pas ouverts. |
| READY_FOR_INTEGRATION | NO | La preuve PostgreSQL/RLS manque. |

## Sécurité de livraison

- PRODUCTION MODIFIED: NO
- REMOTE MIGRATION: NO
- DEPLOYMENT: NO
- `main` non modifiée ; la remédiation est isolée dans son worktree.
- Les modifications préexistantes du worktree audité (`windows/flutter/generated_*`
  et son audit non suivi) n'ont pas été écrasées.

## Gaps restants

1. Rétablir un moteur Docker/Supabase local répondant, puis rejouer toutes les
   migrations et les scénarios du lot A.
2. Ne commencer le lot B qu'après une gate A PASS : dispatch transactionnel,
   scénarios 7/8/12/13, concurrence, idempotence et absence de double
   affectation.
3. Lots C à E non traités : diagnostic/onboarding complet, titulaire et
   remplacement, câblage Admin/vertical slice et interface guidée.
4. Produire `CORE24_CLASSES_COMPLIANCE_AUDIT_FINAL.md` uniquement après la
   remédiation complète et les preuves correspondantes.
