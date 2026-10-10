# État d’exécution BR-0B — relevé du 10 octobre 2026

Ce document complète les blueprints V0.1/V0.2 sans réécrire leurs constats historiques. Le V0.2 est un audit statique daté ; ses observations distantes ne doivent pas être prises pour l’état courant.

## Sources et limites

Relevé effectué le 10/10/2026 avec l’API Supabase connectée, via `list_migrations` en lecture seule, et recoupement des onglets Backend et Questions de « Rewayah · Liaison Claude ChatGPT ». Les identifiants ci-dessous désignent les projets, pas des secrets.

- PROD : projet `gggmtelinlpseweouyav` — 50 entrées au ledger, dernière migration visible `0042_etat_presence_fermee_et_jeton_video_verifie_le_compte`.
- STAGING : projet `xldmmlrnxyabdtvxqbyy` — 76 entrées au ledger, dernière migration visible `0073_break_group_rls_recursion`.

Le ledger établit les versions enregistrées, pas l’équivalence des schémas, des données, des politiques effectives, de l’API PostgREST, d’Auth, des sauvegardes ou des déploiements Edge. Ces points nécessitent des contrôles distincts. Le nombre et le nom des migrations locales ne se comparent pas directement aux versions horodatées du ledger.

Pendant ce relevé, aucune mutation PROD ni application de migration distante n’a été exécutée. Le mandat interdit toute migration PROD sans accord écrit du directeur dans « Journal distant ».

## Avancement par lots

| Lot | État attesté | Travail restant / limite |
|---|---|---|
| A — vérité de référence et baseline | Les deux ledgers distants ont été relus ; PROD s’arrête à 0042 et STAGING à 0073 dans ces résultats. | Réconcilier chaque migration locale avec les deux ledgers, puis vérifier schéma, fonctions, RLS, grants, API et données sur les périmètres concernés. |
| B — STAGING | Le ledger STAGING contient les migrations jusqu’à 0073. La ligne STAGING-I6 reste « en_cours » dans Backend. | Rejeu vierge, fixtures positives/négatives et vérifications API/Auth/PostgREST restent nécessaires. Aucun état « prêt » ne découle du seul ledger. |
| C — sécurité commune | La question SEC-PROD-M2-AVIS est ouverte pour la relecture Claude du candidat exact indiqué dans Questions!A64:G64 ; Backend SEC-PROD-GO reste « en_cours ». | Attendre les constats Claude sans suspendre les travaux indépendants ; compléter les cas actifs/suspendus/expirés/révoqués, trigger réel, API et rejeu vierge. Aucune migration PROD. |
| D — identité, appareils et foyer | Des migrations d’identité et de gardes existent dans le ledger STAGING jusqu’à 0073. | Vérifier les contrats et scénarios de bout en bout ; leur présence au ledger ne prouve pas leur couverture complète ni leur sûreté. |
| E — CI, livraison et reprise | La question B13-CI-BASE-BLOCK est ouverte : le scénario dépend de migrations absentes de la branche ccr. | Ne pas ajouter une étape CI qui échoue sur ccr. Le changement .github autorisé porte uniquement sur ci.yml et ne contourne pas cette dépendance. Reprise/backup restent à prouver. |
| F — domaines métier | Claude a inscrit les règles de classes simultanées dans Questions, incluant les corrections R4, R12, R18 et R20 du directeur. | Respecter l’ordre indiqué par Claude : après SEC-PROD-GO et les bloqueurs REVUE-F2-I19. Publier les nouveaux ports dans Contrats avant tout adaptateur, et ne pas supposer les règles précédentes remplacées autrement que celles explicitement corrigées. |

## Règles d’intégration applicables

- Branche documentaire : `codex/backend-blueprint`, créée depuis `ccr-1b1bfa0b-m1kvkk` au SHA `05e87f92936cd4afa2ee95e64db8baf7732a0de8`. La comparaison GitHub confirme 4 commits d’avance et aucun commit en retard au moment de la publication.
- Cible d’intégration : uniquement `ccr-1b1bfa0b-m1kvkk`. Aucun changement ne vise `main`.
- Toute nouvelle preuve doit indiquer séparément code présent, test local, test STAGING et état distant. Un ledger ou un test transactionnel ciblé ne vaut ni validation complète ni autorisation de production.
