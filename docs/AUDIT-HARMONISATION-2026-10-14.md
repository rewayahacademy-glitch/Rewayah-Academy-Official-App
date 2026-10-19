# Audit d'harmonisation - synthèse

**Mission :** prompt « audit d'harmonisation » du 14/10/2026, comparé au document maître de conformité du 14/10/2026 (version 1.1 avec addenda).
**Nature :** audit différentiel en lecture seule. Aucun code applicatif, aucune migration, aucun environnement distant n'a été modifié.
**Code audité :** branche `claude/nice-darwin-hael93`, HEAD `4a7aa2b` (identique à `main`). Les commits d'audit `ff01c08` et `8f974ff` n'ajoutent que de la documentation : le diff hors `docs/` est vide.
**Période :** 14/10 au 16/10/2026, interrompue une fois par la limite hebdomadaire et deux fois par un redémarrage du conteneur, sans perte : chaque résultat d'agent est conservé dans le journal du workflow.
**Détail :** 16 registres dans [`docs/audit-harmonisation/`](audit-harmonisation/). Ce fichier n'en reprend que l'essentiel, les preuves `chemin:ligne` sont dans les registres.

---

## Lecture en trente secondes

1. **Le constat qui conditionne tout le reste : le code audité n'est pas la branche de travail active.** `main` s'arrête à la migration 0043, avec un trou 0039 à 0042. La branche `ccr-1b1bfa0b-m1kvkk` et 17 PR draft de Codex portent les durcissements 0039 à 0048, les polices DM Sans et Plus Jakarta Sans, et une partie des écrans manquants. Plusieurs écarts relevés sur `main` sont peut-être déjà fermés sur `ccr`. Avant d'implémenter quoi que ce soit, le directeur doit désigner la branche de référence (CP-SRC-01, CP-TAB-03).
2. **Le code Flutter est sain là où il existe.** Sur HEAD, mesuré dans une copie : `dart analyze --fatal-infos` sans problème, **1762 tests, 0 échec**, vérificateur de jetons à 0 violation (20 si l'on inclut `features/_dev/`). 72 tables sur 72 ont la RLS, 0 fonction `SECURITY DEFINER` sans `search_path`, 0 secret versionné, 0 tiret cadratin et 0 symbole de section dans les traductions et `web/`.
3. **La faiblesse est côté serveur et intégration.** Il y a 14 alertes de sécurité confirmées par contre-vérification, dont une critique : un inscrit dont le jeton n'a pas de claim de rôle peut écrire ses propres colonnes `role` et `account_status` (AUD-IDS-019).
4. **Les écrans « finis » ne sont pas tous raccordés.** « Mes groupes » sert six classes fictives à de vraies familles en production. Le bandeau « Cours enregistré » s'affiche sans aucune captation. Le tuteur entre dans la salle par une porte qui ne décompte pas ses visites d'observation.
5. **La CI est rouge pour deux raisons distinctes.**
   - **Runner :** GitHub n'attribue aucun runner depuis au moins le 13/10. Les jobs meurent en une seconde, ce qui renvoie à l'abonnement ou à la facturation Actions.
   - **Migrations :** même avec un runner, le rejeu s'arrête à `0030_tc_socle.sql` parce que le stub de test ne crée pas le schéma `storage`. Trois scénarios SQL échouent aussi (etape3, ctr01, agt01).

---

## A. État du projet

| Élément | Constat |
|---|---|
| Dépôt | `rewayahacademy-glitch/Rewayah-Academy-Official-App`, privé |
| Branche auditée | `claude/nice-darwin-hael93` = `main` à `4a7aa2b` |
| Branche active réelle | `ccr-1b1bfa0b-m1kvkk` (non clonée localement, lue par l'API GitHub), base de 17 PR draft |
| Worktrees | un seul, aucune modification non commitée hors audit |
| PR ouvertes | 20 draft : 17 sur `ccr` (backend Codex : B-13, B-20, F1, F2, lot C, SEC-PROD, ledgers), 2 sur `main` (site public #8, CI #7), plus la PR 36 de cet audit |
| Issues GitHub | aucune |
| Tableau de suivi réel | `docs/PROGRESS.md` + `docs/HANDOFF.md`. Les autres supports cités (feuille Google, Project Board) sont inaccessibles depuis cette session |
| Outillage mesuré | Flutter 3.47.7, Dart 3.13.5, PostgreSQL 16.15 local (le CI utilise 17) |
| Sources introuvables dans le dépôt | `docs/current/00_LIRE_D_ABORD.md`, `COHABITATION.md`, plan visuels du site du 09/10, pack d'assets de personnes, SVG officiel du logo, RECH-01 et RECH-02, spécifications PED et Évaluations des 10 au 12/10 (voir `registre-sources-et-contradictions.md`) |

### Registres produits

| Registre | Exigences | P0 | P1 | Alertes sécurité confirmées |
|---|---:|---:|---:|---:|
| identite-securite | 82 | 6 | 36 | 9 |
| offres-classes-calendrier | 79 | 6 | 42 | 6 |
| salle-bibliotheque-teaching-core | 107 | 8 | 50 | 8 |
| eleves-tuteur-foyer | 92 | 7 | 39 | 6 |
| enseignant-pedagogie-evaluations | 92 | 2 | 56 | 4 |
| finance-admin-direction | 80 | 1 | 37 | 9 |
| controleur-communications-recherche | 38 | 1 | 16 | 1 |
| site-public | 40 | 0 | 28 | 0 |
| design-system-transverse | 47 | 0 | 11 | 0 |
| routes-et-gardes | 51 | 4 | 20 | 3 |
| registre-sources-et-contradictions | 50 | 4 | 29 | 2 |
| etat-du-tableau-de-suivi | 60 | 12 | 24 | 5 |
| mesures-sur-head | 25 mesures | 1 | 2 | 0 |
| complement-01-prf (performance) | 35 | 1 | 11 | non vérifié |
| complement-02-gte (gate de publication) | 61 | 11 | 25 | non vérifié |
| complement-03-sys (harmonisation en système) | 43 | 4 | 21 | non vérifié |

Les lignes P0 se recoupent souvent d'un registre à l'autre : le même défaut KYC, par exemple, est vu par IDS, SRC, TAB et GTE. Une fois dédupliqués, il reste une vingtaine de sujets P0 distincts, listés en section B.

### Contre-vérification

176 verdicts indépendants : un sceptique par écart P0 (Sonnet), un sceptique par alerte de sécurité (Opus), et un vérificateur de preuve sur les 5 conformités principales de chaque domaine. **27 constats corrigés**, tous intégrés à cette synthèse :

- **12 « conformes prouvés » ramenés à « partiel » ou « implémenté non prouvé ».** La règle est codée, mais il manque le test, l'écran d'administration ou la preuve de raccordement.
- **15 alertes de sécurité déclassées.** Ce sont des faits exacts sans chemin d'exploitation : déclassées en P2 ou P3, en informatif, ou en contradiction de gouvernance.

Exemple de correction : la policy `verset_admin` laisse tout administrateur écrire le texte canonique du Coran (0007:342-345). La conformité « texte canonique intact » passe donc de PROUVÉ à PARTIEL.

**Plafonds assumés :** un seul sceptique par écart au lieu de deux, et 5 preuves contrôlées par domaine. Les compléments PRF, GTE et SYS sont relus par un sceptique sans contre-vérification complète. Trois compléments (validation contradictoire du protocole 19, accessibilité et RTL mesurés, cohérence morale) étaient encore en cours à la rédaction ; ils seront ajoutés à `docs/audit-harmonisation/` sous le préfixe `complement-04` à `-06`.

---

## B. Registre de conformité - les écarts qui comptent

Les registres détaillés contiennent environ 980 lignes atomiques. Ici, seuls les P0 dédupliqués, confirmés par contre-vérification sauf mention contraire.

### B1. Sécurité serveur (propriétaire : backend, sauf mention)

| Réf. | Écart | Preuve principale | Tâche existante | Prochaine action |
|---|---|---|---|---|
| AUD-IDS-019 | **Critique.** Un jeton sans claim de rôle passe le garde `app_role() <> 'admin'` et peut écrire `role`, `household_id`, `account_status`, `access_until` sur sa propre ligne `profiles` | 0001:541-560, 713-715, 1201 ; 0038:68 | SEC-PROD (PR #22, ne ferme pas les colonnes) | CP-IDS-01 : garde en exigence positive, UPDATE par colonnes, scénario SQL « jeton sans rôle » |
| AUD-FIN-072 | Même motif sur 8 RPC d'administration (`decider_dossier`, `journal_audit`, `poser_regle`...) | voir registre FIN | SEC-PROD | CP-FIN-01 : réécrire chaque garde en `coalesce(app_role() = 'admin' and app_account_valid(), false)` |
| AUD-IDS-016 / SEC-SAL-01 | `record_session_event` exécutable par tout compte authentifié : n'importe qui peut forger des événements de présence | 0001:912-924, 1209-1214 | aucune | CP-IDS-03 : revoke ciblé + liste blanche des fonctions exécutables vérifiée en CI |
| AUD-IDS-040 / SRC-036 / TAB-051 | Le contrôleur lit les pièces d'identité KYC (RPC, R2, stockage), contre la matrice de l'étape 1 | 0004:187, 1014-1018 ; 0034:152 | ADM-02, ALIGN-1410-BACK | CP-IDS-02 après arbitrage sur le personnel habilité |
| AUD-IDS-041 | Le client signe l'URL de la pièce directement : la fonction Edge `piece-identite-acces` (trace par pièce, cloisonnement de genre) n'est jamais appelée | `lib/core/dossier/service_validation.dart:221-223` | ADM-02 | Frontend + backend : passer par la fonction Edge, retirer `kyc_lecture_admin` dans le même lot |
| AUD-TAB-050 / SEC-SRC-02 | `decider_dossier` accepte une seconde décision qui écrase la première ; un rejet ne retire pas l'accès d'un compte déjà actif | 0004:559 | ADM-02 | CP-TAB-01 : garde `already_decided` + version attendue |
| AUD-IDS-054 | Le jeton d'agent porte `sub` = profil observé ; aucune fonction Edge ne refuse `is_agent` | `supabase/functions/agent-session/index.ts:178-190` | B-20 (PR #28, #30), SEC-01 (PR #10) | Revoir et intégrer PR #30, test Deno de refus |
| ALR-ELV-01/02 | Policies de foyer sans test de rôle : un jeton élève modifie `interface_mode`, `camera_policy` et lit les séances de sa fratrie, le portefeuille, les moyens de paiement | voir registre ELV | aucune | CP-ELV-01 : ajouter le rôle ou la capacité dans `using` / `with check` |
| AUD-ELV-075 / ENS-027 | Le cahier de l'enseignant (`lesson_reports`, `makharij_findings`) est lisible brut par toute famille et tout participant de la séance | voir registre ENS | B-08 (PR #29, projection) | CP-ENS-01 : lecture limitée à l'auteur et à l'admin ; la famille lit la projection publiée |
| AUD-COM-008 | Aucun second facteur pour le contrôleur, qui peut observer des mineurs | PROGRESS.md:167 | aucune | Décision du directeur sur le niveau MFA, puis TOTP et garde `aal2` |
| AS-IDS-06 / FIN-073 | Un admin, comptable ou contrôleur suspendu garde ses droits pendant la vie de son jeton (55 policies par rôle seul) | voir registre IDS | B-13 (PR #23, #27, #31) | Intégrer B-13 |
| AUD-FIN-004 | Ledger `wallet_entries` modifiable et supprimable par admin ou comptable via l'API REST | voir registre FIN | aucune | Rendre le ledger append-only (trigger) |

### B2. Faux succès et données de démonstration en production (propriétaire : frontend sauf mention)

| Réf. | Écart | Prochaine action |
|---|---|---|
| AUD-OFR-066 / ELV-077 / RTE-024 / GTE-001 | « Mes groupes » et l'Espace Groupe servent six classes fictives à de vraies familles : le port par défaut est le double de démonstration | Masquer l'entrée hors build de développement, puis brancher l'adaptateur sur `mes_groupes_famille_v` |
| AUD-SAL-090 / TAB-019 / SRC-04 | « Cours enregistré » s'affiche alors qu'aucun Egress LiveKit ne démarre | Retirer ou reformuler le libellé (texte à valider par le directeur) |
| AUD-SAL-084 / ELV-042 | Le tuteur entre par `assister_seance` : ni quota de 2 visites de 2 minutes, ni visite écrite, et son jeton est visible des autres enfants | Basculer le parcours sur `entrer_observation` après application de 0036, 0037, 0040 |
| AUD-ELV-009 / ELV-029 | L'accueil et le suivi d'un enfant affichent les séances de sa fratrie (`mes_seances_v` non filtrée) | Filtre serveur pour le rôle élève + filtre défensif client, test avec deux enfants |
| AUD-ENS-023 | Un cahier en file d'attente promet de partir « sans revenir ici », mais `rejouer` n'est jamais appelé | Appeler `rejouer` à l'ouverture, au retour réseau et au démarrage |

### B3. Parcours incomplets

| Réf. | Écart | Propriétaire |
|---|---|---|
| AUD-OFR-003 | Aucun écran d'administration des offres : les RPC de 0043 ne sont appelées par aucun code Dart | frontend (écran existant sur `ccr` à réemployer) |
| AUD-OFR-014 | Une famille ne peut pas changer d'horaire : `renoncer_intention_horaire` n'est appelée nulle part et l'index unique bloque le rechoix | frontend + backend (RPC atomique) |
| AUD-OFR-030 | Pas de regroupement des demandes ni de « Créer la classe » sur HEAD | intégrer PR #29 puis l'écran de `ccr` |
| AUD-SYS-005 | Retirer un élève d'une Classe ne coupe ni ses séances à venir ni son accès vidéo | backend (non contre-vérifié) |
| AUD-SYS-004 | Deux sources de vérité pour l'enseignant d'une séance (`sessions.teacher_id` contre `session_participants`) | backend (non contre-vérifié) |
| Site public (SIT) | 26 exigences ABSENT sur 40 : le site n'est pas sur `main`, il vit dans la PR #8 non fusionnée. Le simulateur « Simuler mon tarif » n'existe pas. La grille du maître (50 / 60, -5 au 3e membre, -7 au 4e) n'est codée nulle part | arbitrage directeur sur la PR #8, puis frontend |
| Finance (FIN) | 28 exigences ABSENT : pas d'espace Comptable, domaines Finance et Direction présents dans la navigation mais inertes | lot dédié après arbitrage du périmètre MVP-0 |

### B4. Intégration et exploitation (propriétaire : gouvernance puis backend)

| Réf. | Écart |
|---|---|
| AUD-TAB-044 / IDS-004 / SRC-038 | Les migrations 0039 à 0042 sont appliquées en PROD mais absentes de `main`. Les 0044 à 0048 n'existent que sur `ccr` (STAGING seulement). Un schéma reconstruit depuis `main` perd les correctifs de sécurité |
| AUD-TAB-045 / OFR-004 | Le front appelle les RPC de 0043, non appliquée en PROD (le code se dégrade proprement, mais le parcours n'existe pas) |
| AUD-GTE-003 / SEC-GTE-02 | Aucun staging dans le dépôt : un push sur `main` déploie fonctions Edge et Web sur l'unique projet de production, sans garde de tests |
| AUD-GTE-044 / TAB-057 | Aucun des 18 scénarios E2E n'a été joué ; la recette navigateur authentifiée n'a jamais eu lieu |
| AUD-TAB-018 | Chaîne LiveKit réelle bloquée par le compte fournisseur (N2) |
| MES E2 / PRF-026 | Scénarios SQL en échec sur base neuve : `agt01` (permission denied sur `est_du_foyer`, régression qui ferme l'accès), `ctr01` (un 3e élève accepté dans un cours 1-to-1, cause non identifiée), `etape3` (assertion qui compte toute la base) |
| CI | Le stub `supabase/tests/stub_auth.sql` ne crée pas le schéma `storage` : le job « Migrations applicables » échoue à 0030 même quand un runner est attribué |

### B5. Ce qui est conforme et doit être préservé

Sous réserve des plafonds de vérification, ces points sont prouvés et ne doivent pas être réécrits :

- **Socle Flutter :** 1762 tests verts, analyseur propre, jetons respectés, un seul routeur, gardes par préfixe de chemin.
- **RLS et fonctions :** 72 tables sur 72 avec RLS, toutes les `SECURITY DEFINER` fixent `search_path`.
- **Argent côté serveur :** entier en unités mineures (AUD-FIN-001). Côté Dart, aucun montant n'est encore manipulé (AUD-FIN-002, non applicable).
- **Suivi élève (R3) :** routé et testé (`app_router.dart:222-224`, 8 tests).
- **Profil enseignant (ENS-05) :** construit avec ses cinq états.
- **Salle :** un seul moteur LiveKit, aucune seconde Room.
- **Présence :** dérivée d'événements signés, une fois la faille `record_session_event` fermée.
- **Textes visibles :** aucun tiret cadratin ni symbole de section dans les traductions et `web/`. Formules génériques d'IA : 22 motifs cherchés dans `fr.i18n.json`, statut partiel (AUD-DSG-041), le site et `ar.i18n.json` restent à couvrir.

---

## C. Devoir de regard - contre-propositions

Le format complet en 14 champs est dans chaque registre (section 4). Ici, le classement demandé.

### C1. À appliquer dans le périmètre, sans arbitrage

Ce sont des décisions déjà tranchées dont l'implémentation est défectueuse (situation 1 du prompt).

| CP | Objet | Périmètre |
|---|---|---|
| CP-IDS-01 / CP-FIN-01 | Gardes en exigence positive partout, UPDATE par colonnes sur `profiles` | backend |
| CP-IDS-03 / CP-SAL-06 | Revoke `record_session_event`, `next_immutable_id`, `log_sensitive_access` ; liste blanche en CI | backend |
| CP-SRC-03 / CP-TAB-01 | Garde d'état sur `decider_dossier` | backend |
| CP-ELV-01 / CP-ELV-02 / CP-ENS-01 | Rôle dans les policies de foyer ; cahier brut fermé, projection pour les familles | backend |
| CP-RTE-01 / CP-GTE-02 | Retirer « Mes groupes » de démonstration hors build de développement | frontend |
| CP-ENS-02 | Rejouer la file des cahiers | frontend |
| CP-SRC-06 | Le client lit la fenêtre d'entrée T-20 du serveur | frontend |
| CP-TAB-06 | Versionner les preuves de ADM-09 à ADM-17 | qualité |
| Stub CI | Ajouter le schéma `storage` minimal au stub de test (testé localement : 42 migrations passent ensuite) | backend, CI |
| MES E2 | `grant execute` de `est_du_foyer` à `agent_ro` puis rejeu de `agt01` | backend |

### C2. Exigent un arbitrage du directeur

Situations 2 et 3 : risque nouveau ou contradiction réelle entre sources.

| CP | Question posée | Recommandation |
|---|---|---|
| **CP-SRC-01 / CP-TAB-03** | **Quelle branche fait référence ?** `main` ou `ccr-1b1bfa0b-m1kvkk` | Faire de `ccr` (ou de son successeur) la seule base, intégrer les PR draft dans un ordre fixé, puis rejouer cet audit sur ce SHA. Sans cette décision, chaque correction risque d'être faite deux fois |
| CP-TAB-02 / CP-TAB-05 | GO pour intégrer 0039 à 0042 dans la branche de référence et appliquer 0043 à 0048 en PROD | Intégrer à l'identique, rejeu complet sur base neuve puis STAGING, GO écrit avant PROD |
| CP-IDS-02 / CP-TAB-04 | Qui peut voir une pièce d'identité ? | Admin habilité uniquement, via la fonction Edge tracée ; le contrôleur en est retiré |
| CP-COM-01 | Niveau de second facteur pour le contrôleur et l'admin | TOTP obligatoire et garde `aal2` sur l'observation |
| CP-SRC-04 / CP-TAB-08 | Texte du bandeau d'enregistrement tant que l'Egress n'existe pas | Ne rien annoncer qui n'est pas actif |
| CTR-SRC-11 / SYS-007 | Sort de l'affectation 1-à-1 (ENS-06) face aux Classes stables | Arbitrer, puis une seule vue canonique d'appartenance |
| CTR-TAB-08 | Périmètre exact du MVP-0 (Comptable, Direction, site public) | Fixer avant d'ouvrir les lots finance et site |
| CP-SRC-05 | Déposer dans le dépôt les sources introuvables (plan visuels du 09/10, RECH-02, PED, Évaluations, logo SVG, pack de personnes) | Indispensable pour auditer le site et la recherche |
| CI Actions | Aucun runner attribué depuis au moins le 13/10 | Vérifier facturation et quota Actions dans les réglages du compte |

### C3. Points académiques à faire valider par une autorité compétente

- Corpus précis de Ṣalāh et des invocations, et correspondance à l'édition retenue de Nour al-Bayân : ce sont des dépendances ouvertes, à ne pas présenter comme acquises (registre ENS).
- Droit d'écriture des administrateurs sur le texte canonique du Coran (policy `verset_admin`, 0007:342-345) : à restreindre à un import contrôlé. Il faut aussi désigner qui atteste la fidélité de la source.

---

## D. Plan d'exécution par vagues

Les vagues suivent la section 21 du document maître et les dépendances constatées. **Aucune vague ne démarre avant la décision de branche (vague 0).**

| Vague | Contenu | Prérequis | Propriétaire | Critère de clôture |
|---|---|---|---|---|
| **0 - Décisions** | Branche de référence, ordre d'intégration des PR draft, GO migrations, habilitation KYC, MFA, périmètre MVP-0 | aucun | directeur | Décisions écrites dans `decisions.md` (ADR) |
| **1 - Socle CI** | Stub `storage`, correction des scénarios `etape3`, `ctr01`, `agt01`, CI déclenchée aussi sur push, runner rétabli | vague 0, abonnement Actions | backend | Run CI vert sur le SHA de référence, avec son numéro |
| **2 - Sécurité P0** | CP-IDS-01, CP-FIN-01, CP-IDS-03, CP-TAB-01, CP-IDS-02, CP-ELV-01, CP-ENS-01, intégration B-13 et B-20 | vagues 0 et 1 | backend, puis frontend pour la fonction Edge KYC | Un scénario SQL de refus par faille, vert en CI ; rejeu STAGING |
| **3 - Faux succès** | Masquer « Mes groupes » de démo, bandeau d'enregistrement, filtre fratrie, rejeu des cahiers, porte d'observation du tuteur | vague 2 pour la porte d'observation | frontend | Test Dart par écart ; aucun écran de production sur double de démonstration |
| **4 - Parcours inscription** | Écran d'administration des offres, changer d'horaire, regroupement et création de classe | PR #29 intégrée, 0043 en PROD | frontend + backend | Parcours famille et admin joués de bout en bout en STAGING |
| **5 - Salle et après-cours** | Recette LiveKit réelle à quatre rôles, projection du cahier pour la famille, éjection serveur à budget épuisé | compte LiveKit (N2) | backend + frontend | Recette navigateur authentifiée consignée dans `RECETTE_E2E_RESULTATS.md` |
| **6 - Finance, site, recherche** | Selon le périmètre MVP-0 fixé : espace Comptable, ledger append-only, site public (PR #8), simulateur tarifaire centralisé, recherche | vague 0 (périmètre), sources déposées | à fixer | À définir par lot |
| **7 - Gate de publication** | 18 scénarios E2E, matrice d'appareils, rapport de gate par SHA | vagues 1 à 5 | qualité | Critère terminal 22.3 du maître |

Ce qui peut avancer en parallèle sans risque : les vagues 1 et 3 côté frontend (masquage, libellés, filtre défensif) ne touchent pas le serveur.

---

## E. État du tableau de suivi

Aucune tâche n'a été fermée, supprimée ou remise à zéro.

- **Conservées :** toutes les tâches de `PROGRESS.md` et `HANDOFF.md`.
- **Enrichies par cet audit (ajouts datés, voir en tête de `HANDOFF.md`) :**
  - R3 : routé et testé.
  - ENS-05 : construit.
  - ADM-02 : deux sous-tâches de sécurité, KYC du contrôleur et double décision.
  - N2 : bloqué par le compte LiveKit.
  - Les chiffres de tests des entrées anciennes sont marqués périmés : 729 et 684/691 annoncés, 1762 mesurés.
- **Reliées :**
  - Teaching Core aux PR B-14 et B-15.
  - ADM-05 à ADR-028.
  - N4 à la migration 0042.
  - Les écarts P0 aux PR draft qui les ferment : #22, #23, #27, #28, #29, #30, #31.
- **Tâche nouvelle réellement nécessaire :** « tests et scénarios ADM-09 à ADM-17 ». Aucune tâche existante ne la porte.
- **Propositions qui exigent confirmation, non appliquées :**
  - Cocher H R2.
  - Corriger l'identifiant Android dans PROGRESS ligne 146.
  - Passer cinq écrans du catalogue à « construit ».
  - Annoter le LISEZ-MOI 0035-0037.
  - Liste complète : `etat-du-tableau-de-suivi.md`, section 2.C, entrées MAJ-04, 05, 14 à 17.
- **Non réalisé faute d'accès :** feuille Google de suivi, Project Board, artifact de pilotage.

---

## F. Plan de reprise

1. **Décision de branche (directeur), CP-SRC-01.** Tant qu'elle n'est pas prise, toute implémentation est provisoire.
2. **Rétablir les runners GitHub Actions** (réglages de facturation du compte). Sans CI, aucune preuve sur SHA n'est possible.
3. **Vague 1, socle CI**, sur la branche choisie : stub `storage`, trois scénarios SQL, CI sur push. Résultat attendu : un run vert numéroté.
4. **Vague 2, sécurité P0**, en commençant par AUD-IDS-019 (critique), puis `record_session_event`, puis KYC.
5. **En parallèle, côté frontend :** masquer « Mes groupes » de démonstration et le bandeau d'enregistrement. Ce sont deux changements courts qui suppriment des faux succès visibles par les familles.
6. **Après la décision de branche, rejouer cet audit sur le nouveau SHA.** Le script du workflow est conservé ; les registres servent de grille. Seuls les écarts encore ouverts sont à reprendre.

Aucune date de livraison globale n'est annoncée : elle dépend des vagues 0 et 1, qui ne sont pas entre les mains de l'équipe de développement.
