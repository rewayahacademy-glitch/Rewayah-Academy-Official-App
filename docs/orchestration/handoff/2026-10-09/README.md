# Handoff Claude ↔ Codex — 9 octobre 2026

Branche de consultation : [`codex/backend-inventory`](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/tree/codex/backend-inventory), créée depuis `ccr-1b1bfa0b-m1kvkk` au SHA `3163fb1be623b0e6650a92a5d04b011e79e46bf0`. Aucun changement vers `main`.

## Documents déposés

Les quatre fichiers ci-dessous sont des copies des documents préparés dans `Downloads/à faire/à faire jeudi 08`. Ils restent inchangés comme sources de proposition/handoff; ce README et `docs/backend/INVENTAIRE_DISTANT.md` apportent le relevé actualisé.

- [Blueprint BR-0B v0.2](REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md) — document consolidé; sa mention du 7 octobre disant qu’aucun état distant n’avait été inspecté est historique.
- [Blueprint BR-0B v0.1](REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_1.md) — version antérieure, conservée pour provenance.
- [Complément immatriculation et identités v0.1](REWAYAH_COMPLEMENT_IMMATRICULATION_IDENTITES_V0_1.md) — proposition; aucune identité publique ni matricule ne doit être créé par simple présence dans ce document.
- [Handoff CAP-55 présentation](REWAYAH_CAP55_PRESENTATION_APP_HANDOFF_CLAUDE_V1.md) — transmis à Claude pour les écrans; il ne constitue pas un mandat de changement backend.

## État à utiliser pour la suite

- Le constat Supabase du 9 octobre est dans [`docs/backend/INVENTAIRE_DISTANT.md`](../../../backend/INVENTAIRE_DISTANT.md), et son journal est dans l’onglet **Journal distant** de la feuille « Rewayah · Liaison Claude ChatGPT ».
- Le PROD retourne 50 entrées de migrations jusqu’à 0042; l’intégration a des migrations SQL jusqu’à 0038 puis un 0043 local. L’historique 0035–0037 est déjà présent côté PROD. B-01 suit la récupération des sources 0039–0042, la provenance de 0043 et la résolution des collisions avant toute écriture distante.
- Les noms de secrets et les réglages dashboard manuels ne sont pas exposés par les outils de cette session; ils restent explicitement inconnus.
- Le backend réalise les services/adaptateurs et la revue des contrats. Claude reste propriétaire des écrans et relira chaque ligne livrée. Ne pas brancher les adaptateurs dans `main.dart` ou les écrans depuis cette branche.
- Toute migration distante nécessite le GO du directeur dans le Journal distant. Aucune migration ni configuration distante n’a été écrite dans cette session.
