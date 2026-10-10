# Passation backend Codex — 2026-10-10

État relevé le 10 octobre 2026. Cette passation est un instantané documentaire; elle ne constitue ni un GO de production ni une preuve de déploiement. La branche est issue de `ccr` au SHA `2c340e21d165313462a5c9a9f6c8c93e7a947452`. Seul ce fichier est ajouté par cette passation.

## Branches Codex

Les comparaisons indiquent commits exclusifs respectifs par rapport au ccr au moment du relevé; une branche en avance de zéro a son tip contenu dans ccr. Des commits de branches divergées peuvent toutefois être intégrés partiellement.

| Branche | SHA exact | Δ ccr (ahead/behind) | Contenu |
|---|---|---:|---|
| codex/backend-b13-admin-suspended | d14df7c45c8ecd615f58da9bd1431f2925bc0259 | 3/52 | B13 CI/scénario |
| codex/backend-b13-ccr-8ea7831 | d71397a0054f408c238626d8bf33d7a29cb1f5f6 | 3/19 | B13 réancrée |
| codex/backend-b13-ci-ccr | 022226aa96f7d53b9550bd89b995982981ad15a4 | 5/47 | B13 numéro migration |
| codex/backend-b20-agent-identity | 3c7689da2b8166b7862c08f11b9825059c7b5f8f | 7/46 | Identité agent |
| codex/backend-b20-ccr-8ea7831 | fbbe09a1a2fa8fe588e4695b72bf8f70bd7c99f7 | 2/19 | B20 réancrée, migration 0074 |
| codex/backend-blueprint | ea09327e7e90784dfa8f0ab70ea3529da47d6702 | 5/52 | Blueprint BR-0B |
| codex/backend-catalogue-classes | 5336598a5fc045fbe77b6320095db668486daa0a | 0/572 | Documentation staging |
| codex/backend-f1-ccr-8ea7831 | 42b5993c04741dad4ce9d47b2bdd9e3981b4d3f5 | 2/19 | F1, PR29 |
| codex/backend-f1-ccr-port | 16cf60561086ab54ff12905b415e21ed21ecc6b3 | 20/46 | Stub JWT PG |
| codex/backend-f2-after-c | b6440e9fb284f197cf6743101dcf73dff2469787 | 282/491 | F2, C04, PR21 |
| codex/backend-f2-b13-admin-rls | 00601b4740d942d2b3bae0f066c212ce1a471cb5 | 58/496 | F2 B09–B15, PR17 |
| codex/backend-inventory | 1eb9ff720390cc916d48d78db4114fba4e0fe068 | 0/576 | Inventaire B00/provenance |
| codex/backend-lot-a | 0e31a6072e7acbbc1ce09f02c1d833942c61fb67 | 0/512 | Lot A, B18, scénarios/migrations |
| codex/backend-lot-a-manifest | f35b354475c6078193f61e05e4c1518c61567998 | 4/47 | Manifeste B01, PR25 |
| codex/backend-lot-b | 5336598a5fc045fbe77b6320095db668486daa0a | 0/572 | Même tip que lot F2; docs staging |
| codex/backend-lot-c | 342d05b3e0467844cfcabee3e36fae8ac37a8926 | 14/572 | SEC01 |
| codex/backend-lot-c-staging-api | 2b06984a96cd7bc4f113606f208e601f43902c2b | 115/495 | API staging/tests |
| codex/backend-lot-f1 | 2b11e7112220603c63f993fa83054ee3c8644925 | 98/495 | F1 vertical, migrations jusqu’à 0056 |
| codex/backend-lot-f2 | 5336598a5fc045fbe77b6320095db668486daa0a | 0/572 | Même tip que lot B/catalogue |
| codex/backend-lota-ledger-provenance | 08554efdfcb37afb7f90c2910b1590d352fec4a0 | 3/18 | Preuves ledger PROD 0011, PR32 |
| codex/backend-migrations-historiques | 30936a5f4196b0f485da6ff446738151c38ffae1 | 0/568 | Provenance migrations 0039–0042 |
| codex/backend-notifications | af26dd625b7ff42b086037a9e8ca11b05ebe4db4 | 6/0 | B09 notification 0063/adapters/tests |
| codex/backend-offres-adapters | 93d4b0cef2193fd72d01cc0306e513532418b197 | 7/7 | F1 adapters offres, migration 0075 |
| codex/backend-sec-prod | 747d65baa6f9470603f794af2cc122d79cfcae94 | 29/52 | Candidat SEC-PROD, PR22 |
| codex/backend-sec-prod-m2-fixes | 53db6a9db627ee8d93c445acf3b78402f9fd6682 | 15/14 | Candidat M2 distinct, F79 NON PRÊT |
| codex/backend-security-acl | dc1846cbf77e4c36fc6a5510398e6322e42b368e | 0/587 | Audit ACL |
| codex/backend-security-null-guards | fbf774500b1a08668686710be8104b53960c8a69 | 0/570 | Scénarios négatifs B18 |
| codex/backend-staging-deploy | db59e3584351e1643ac3e211fec194421d655d30 | 14/572 | Workflow/init staging historique |
| codex/backend-staging-preview-secrets | 6b7d0ad9ccc7238e110be893393c151960b759ac | 2/47 | Secrets STAGING preview, PR26 |
| codex/backend-teacher-recruitment | f340a0c124ba37cf39882a1a8271c15ef43c39f3 | 0/18 | Recrutement, décisions/docs |
| codex/r1-adaptive-design-system | 405683abb751eeb47cc53af0a3c1e5d869f64642 | 1/1531 | UI adaptive (hors backend) |
| codex/release-all-20260915 | b02ea98b73b4996912ad43ccf91243210fada4cc | 0/1525 | Branche release |
| codex/site-public-preview-main | 6549d3c21ebf2c4aad962311122d65c6b5772a38 | 1/1415 | Preview site public |

## Intégration et PR

ccr était à `2c340e21d165313462a5c9a9f6c8c93e7a947452`. Les branches avec ahead=0 ci-dessus ont un tip contenu dans ccr; pour les autres, vérifier chaque commit avant toute intégration, car les historiques sont divergents. La PR #33 est close/fusionnée uniquement vers `codex/backend-offres-adapters`, pas vers ccr. PR ouvertes relevées: #17, #21, #22, #24, #25, #26, #29, #30, #31, #32. Elles ne sont pas toutes équivalentes à un état prêt; bases parfois anciennes. Aucune cible main. PR #22 pointe le candidat `codex/backend-sec-prod@747d65ba`; M2 est une autre branche.

## Questions encore ouvertes

Statut évalué depuis l’onglet Questions; les demandes annulées sont exclues. La ligne 56 C-04-SOURCE-SCHEMA est annulée.

| Ligne | Sujet | Reste à faire |
|---:|---|---|
| 9 | REVUE-I8 | Réconcilier les points de revue avec le head ccr courant. |
| 11 | MANDAT-I10 | Poursuivre les lots backend du blueprint, tracer avancement et preuves. |
| 14 | REVUE-F2-I19 | Revue sur branche/head actuel puis corriger les bloqueurs retenus. |
| 16 | REVUE-I11 | Revue et clôture documentée après vérification du head. |
| 21 | OBJECTIF-NUIT-I12 | Confirmer portée, livrables et preuves attendues. |
| 22 | REVUE-I13 | Revue/corrections sur SHA courant. |
| 23 | REVUE-F1-I14 | Revue F1 sur head actuel et suite des bloqueurs. |
| 24 | REVUE-F1-I15 | Revue F1 sur head actuel et clôture. |
| 25 | OFFRES-DIR-I16 | Finaliser arbitrages d’offres et raccordements dépendants. |
| 42 | MANDAT-I10-SECRETS-API | Secrets de preview configurés; comptes STAGING de test manquants, maintenir garde STAGING. |
| 46 | REVUE-F1-I17 | Vérifier revue F1 et lier aux commits actuels. |
| 47 | REVUE-F2-I18 | Vérifier revue F2 et lier aux commits actuels. |
| 54 | AUTH-PREVIEW-RECRUTEMENT | Définir comptes et parcours Auth preview. |
| 55 | RECRUTEMENT-ENSEIGNANTS-BACKEND | Compléter raccordements backend recrutement. |
| 57 | SEC-PROD-GO | GO conditionnel; les prérequis opérationnels listés restent à satisfaire. |
| 58 | SECRETS-API-SANS-DIRECTEUR | Résoudre dépendance d’accès/secrets et documenter contrôle. |
| 59 | REGROUPEMENT-ECHELLE | Décision d’échelle et effet sur lots. |
| 60 | ECHELLE-R1-R19 | Traiter les items R1–R19 après arbitrage. |
| 61 | AUDIT-ECHELLE-1 | Achever l’audit d’échelle avec preuves. |
| 62 | ECHELLE-CORRECTIONS-DIRECTEUR | Attendre/consommer corrections et valider les preuves. |
| 64 | SEC-PROD-M2-AVIS | Avis remplacé par F65; conserver comme historique. |
| 65 | SEC-PROD-M2-SECONDE-OPINION | F65 non prêt sur PR22; corriger contrôles B1/B2, parser M1–M3, préserver hook M4 puis retester. |
| 66 | SEC-API-EXECUTION-STAGING | Comptes de test STAGING/API absents; vérifier le garde-fou avant exécution. |
| 67 | SEC-PROD-M2-SECONDE-OPINION-2 | Résoudre divergences M2 et obtenir avis actualisé. |
| 68 | RECRUTEMENT-PORTS-UI | Valider les ports avec Claude avant changement UI/contrats. |
| 69 | KYC-ADMIN-GENRE | Implémenter contrôle same-gender; exception super-admin selon décision consignée. |
| 70 | SIGNATURE-CONTRAT-LOCALE | Implémenter signature locale et format/hash décidés, puis preuves. |
| 71 | SEC-PROD-M2-REVIEW-3 | Historique NON PRÊT; vérifier qu’aucun point n’est devenu obsolète. |
| 72 | REVUE-F1-PR29 | Demander/relever le SHA courant avant merge, puis traiter remarques. |
| 73 | SEC-PROD-ARBITRAGE-M2 | Arbitrer le candidat M2 et mettre les décisions en cohérence. |
| 74 | OFFRES-C11-GENRE | Appliquer proposition confirmée et valider tests/contrat. |
| 75 | SEC-PROD-M2-REVIEW-4 | F75 NON PRÊT: corriger B2 et conditions M1, retester les rôles. |
| 79 | SEC-PROD-M2-SECOND-OPINION | F79 NON PRÊT: couverture/allowlist et divergences avant toute nouvelle revue. |
| 80 | OFFRES-C10-REVIEW | Obtenir décision de revue et fermer contrat associé. |
| 81 | EA-ROLE-BR-DEGEL | Appliquer le dégel du rôle adulte selon conditions; garder preuves. |
| 82 | OFFRES-B08-REVIEW | Revue B08 et alignement contrat/implémentation. |
| 83 | OFFRES-B03-PORT-TYPES | Finaliser types de ports B03 et vérifications interopérables. |
| 84 | BACKEND-B12-PORT-SEAM | Obtenir/valider contrat de port avant de figer la couture B12. |

## Contrats sans décision finale

28 lignes restent sans décision finale: C-02, C-03, C-04, C-06, C-07, C-08, C-09, C-10, C-11, C-10 bis, C-11 bis, C-04 bis, C-12, C-13, C-14, C-15, C-16, C-17, C-20, C-20 bis, C-21, C-22, C-23, C-24, C-25, C-26, C-27, C-28, C-29. (Les lignes C-10 bis et C-11 bis sont comptées comme une entrée combinée dans le total de lignes ouvertes.)
- C-02 à C-04 et C-04 bis: finaliser sens/portée et compatibilité schéma; C-04 source de titre public est décidée par l’utilisateur: profiles.gender femme → sayyida, homme → sayyid.
- C-06 à C-12: cellules de changement/raison vides ou incomplètes; compléter depuis sources autorisées ou réconcilier/fermer, ne pas inventer les exigences.
- C-13 à C-17: terminer contrats de recrutement/invitation/signature et valider implémentation.
- C-10/C-11 et offres liées: relier les revues Questions 74/80/82, intégrer les décisions confirmées.
- C-20 à C-29 (incluant bis): propositions en attente de confirmation Codex; obtenir arbitrage avant port/changement backend.

C-01 et C-05 sont acceptés. C-05 utilise explicitement le genre du profil pour le titre public: femme = sayyida, homme = sayyid.

## SEC-PROD — B2, M1 et conditions F79

Il existe deux candidats distincts: PR22 / `codex/backend-sec-prod@747d65baa6f9470603f794af2cc122d79cfcae94` et M2 / `codex/backend-sec-prod-m2-fixes@53db6a9db627ee8d93c445acf3b78402f9fd6682`.

- F65 (PR22): NON PRÊT. B1 lance le scan avant les patches; la boucle générique 0074 modifie 15 fonctions puis invalide les hashes. B2 risque de manquer les gardes négatifs de rôles si le détecteur ne comprend que `not`; conserver le détecteur robuste et corpus négatif. M1 parser: gérer correctement les backslashes dans chaînes SQL ordinaires avec standard_conforming_strings=on; M2 ne pas traiter $ dans identifiant comme quote dollar; M3 validation COALESCE structurelle non-spoofable. M4 ne pas révoquer EXECUTE anon de `agent_pre_request()`, hook pre-request Supabase. Tester les 15 vues security_invoker par rôle via API STAGING.
- F75 (M2): NON PRÊT. B2 laisse 20 fonctions SECURITY DEFINER / 22 signatures sans gardes négatifs; scan global: 38 corps signalés, 18 traités, 24 alertes incluant faux positifs déterministes. Patch borné par signature/md5 ou exceptions md5 revues, résultat attendu zéro. `guard_profile_privileged_columns` doit rester INVOKER; postflight vérifie prosecdef=false, search_path vide et trigger actif. Tester rôle sans droit d’exécuter app_role() pour UPDATE profiles. Retirer begin; warning-only.
- F79 (M2 seconde opinion): NON PRÊT. Les 47 corps archivés ne prouvent pas couverture: PROD compte 141 SD, environ 40 archivés par regex; 77/118 fonctions de matrice ont md5 concordant, 41 divergent et environ 23 fonctions SD hors matrice. Avant GO: corriger B2, examiner 41 divergences et ~23 hors matrice; imposer allowlist fail-closed par signature + md5 + classification + revue avant nouvelle migration/CI SD.

Le Journal distant contient une autorisation générale de corriger les failles PROD avec sauvegarde et test (ligne 85), mais les conditions du GO ne sont pas satisfaites. Aucune action PROD n’est autorisée par cette passation.

## État distant et preuves

Lecture directe lors du relevé: STAGING ref `xldmmlrnxyabdtvxqbyy`, ACTIVE_HEALTHY, PostgreSQL 17.11, ledger 77 migrations jusqu’à `0074_agent_identity_account_validity` (version 20261010125040). PROD ref `gggmtelinlpseweouyav`, ACTIVE_HEALTHY, PostgreSQL 17.6, ledger 50 migrations jusqu’à `0042_etat_presence_fermee_et_jeton_video_verifie_le_compte`. Ce sont des états observés, pas la preuve d’un replay ni d’une application autorisée de nouveaux changements.

- B20/PR30: auteur rapporte scénario + migration 0074 testés PG17.11 sous BEGIN/ROLLBACK; lecture distante voit ensuite 0074 appliquée. Le Journal n’a pas d’entrée explicite retraçant cette application; distinguer le ledger vivant et son autorisation/provenance.
- B13/PR31: scénario/migration 0058 rapportés sous rollback; les runs CI 400/414/426 n’ont pas exécuté d’étapes (runner_id 0), donc aucun verdict pass/fail.
- PR22: tests ciblés rapportés sous rollback sur staging PG17.11, identité synthétique; pas de script complet/API Auth/PostgREST.
- Manquent: replay frais PG17 complet 0001–0042 + candidat avec COMMIT/postflight; tests par rôle de toutes les vues security_invoker; appels Auth/PostgREST anon, rôles, suspendu et ancien JWT; CI diagnostiquable et suite complète; procédure sauvegarde/restauration éprouvée.
- API staging: secrets/comptes STAGING_TEST_* pas provisionnés. Garder toute exécution API sous garde STAGING, aucun secret dans les docs/logs.

## Pièges connus

1. PG local 16 et vérification ciblée ne prouvent pas le comportement PG17 ni le replay complet.
2. Une transaction rollback ne prouve pas la migration committée ni le postflight après commit.
3. Ledger distant, code Git, rapport d’auteur et ligne Journal sont quatre preuves différentes; ne pas en inférer l’une depuis l’autre.
4. Branches codex anciennes et très divergentes; vérifier SHA/base et contenu commit par commit, jamais rebase/force push; pas de main.
5. Ne pas confondre PR22 (F65) et branche M2 (F75/F79).
6. Ne pas exécuter d’API staging sans comptes/secrets tests ni garde de projet; ne jamais publier de secret.
7. Le GO de la ligne Journal 85 est conditionnel; sauvegarde, replay, scénarios et revue demeurent requis.
8. Aucun changement de schéma ou migration distante ne doit être appliqué sans GO correspondant explicitement inscrit au Journal.

## Références de travail

- Dépôt: https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App
- Branche source ccr au relevé: `2c340e21d165313462a5c9a9f6c8c93e7a947452`
- Feuille de liaison: https://docs.google.com/spreadsheets/d/1v3uuQD9jHgezbrmNlrKPOvGsRBCpxYXkN_KIq5N72WA
