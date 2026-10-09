# Revue ACL des fonctions SECURITY DEFINER — PROD

Date : 2026-10-09  
Projet : `gggmtelinlpseweouyav` — Rewayah PROD (Real Users)  
Méthode : requêtes SQL de catalogue en lecture seule via Supabase MCP. Aucune fonction d’application appelée; aucune migration, mutation ou modification de configuration.

## Résultat du relevé ACL

Sur les fonctions `SECURITY DEFINER` du schéma `public`, hors fonctions trigger :

| Mesure observée | Nombre |
| --- | ---: |
| Fonctions recensées | 122 |
| Exécutables par `anon` selon `has_function_privilege` | 14 |
| Exécutables par `agent_ro` | 48 |
| Fonctions volatiles exécutables par `agent_ro` | 11 |
| ACL ayant un droit `EXECUTE` explicite pour `PUBLIC` | 3 |
| Fonctions avec `search_path` fixé dans `proconfig` | 122 |

Les trois ACL `PUBLIC` explicites observées concernent `comptes_admin()`, `creer_groupe(...)` et `modifier_groupe(...)`. Les 14 droits `anon` incluent ces trois fonctions ainsi que des helpers de rôle/session. Le droit PostgreSQL seul ne prouve pas que chaque appel est exposé par PostgREST, qu’il divulgue des lignes ou qu’il réussit ses gardes.

Parmi les 11 fonctions volatiles accessibles à `agent_ro`, les noms observés sont `creer_groupe`, `demandes_en_attente`, `dossiers_en_attente`, `eleves_sans_enseignant`, `enseignants_pour`, `indicateurs_admin`, `journal_audit`, `journal_audit_filtres`, `modifier_groupe`, `read_kyc_documents` et `verifier_chaine_audit`. « Volatile » est une propriété PostgreSQL, pas une preuve de mutation.

## Vérification limitée de corps de fonctions

Les définitions PROD consultées ont toutes `search_path = ''` pour l’échantillon retourné. Plusieurs gardes utilisent toutefois des comparaisons dont le résultat peut être SQL `NULL` (ex. `app_role() <> 'admin'` dans `creer_groupe` / `modifier_groupe`, `app_role() NOT IN (...)` dans `read_kyc_documents`). Selon le contrat de `supabase/CLAUDE.md`, elles doivent être revues en exigence positive et éprouvées avec des claims absents. Les corps montrent aussi des contrôles complémentaires; ce relevé ne démontre donc pas un contournement effectif.

Un cas trigger, `completer_kyc_document()`, est `SECURITY DEFINER` et possède un EXECUTE `anon` observé, mais retourne `trigger`; il n’est pas compté parmi les 122 fonctions RPC ci-dessus et n’a pas été appelé.

## Conclusion et suite

C’est un point de revue prioritaire, pas un constat d’exploitation confirmée. Avant de raccorder les appels KYC ou administratifs :

1. classer les ACL explicites, droits hérités de `PUBLIC`, fonctions RPC et triggers;
2. lire les 11 corps volatils accessibles à `agent_ro` et établir lesquels peuvent écrire;
3. exécuter les scénarios négatifs (claims absents, `anon`, `authenticated`, `agent_ro`) sur un PostgreSQL isolé conforme au workflow, sans appeler de mutation en PROD;
4. proposer uniquement des correctifs additifs, avec révocation de `PUBLIC` et `anon` lorsque justifiée, puis obtenir le GO journalisé avant toute application distante.

Aucun de ces tests négatifs n’a été exécuté dans ce lot. Les nombres ci-dessus sont des observations de catalogue à cet instant; ils doivent être relus après tout changement de schéma.
