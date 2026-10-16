# Plan de correction réparti - index des lots

Rapport : `docs/AUDIT-FINAL-2026-10.md` (section 8). Chaque lot a sa fiche `docs/audit-final/lots/<ID>.md`, autonome, avec dans l'ordre : but et pourquoi, critère de réussite, ce qu'il faut lire, fichiers autorisés et interdits, étapes, vérifications, pièges connus, quand s'arrêter, commit, modèle conseillé.

Règles communes à tous les lots :

- Une branche par lot, `lots/<ID>-<mot>`, partie de `claude/backend-reprise`. Un worktree par lot. PR brouillon vers `claude/backend-reprise`. Jamais de push sur `main`, jamais de PR vers `main`, jamais de fusion par l'agent. STAGING en lecture seule pour les agents ; les migrations sont appliquées par celui qui en a le droit, après le lot de vérification de la vague.
- Zones : `supabase/**`, services et adaptateurs `*_supabase.dart` sont la zone de ChatGPT (Codex) selon `docs/orchestration/COHABITATION.md` ; le garde-fou `.claude/hooks/garde.py` refuse à une session Claude d'y écrire. Les écrans, ports, doubles de démonstration, tests d'écran et i18n sont la zone de Claude. Une fiche qui a les deux parties le dit. Note du 16/10 : la fiche « Maintenant » du tableau Suivi Rewayah (version 128) dit que le directeur a levé les zones ChatGPT et que Claude écrit aussi `supabase/` et les adaptateurs ; le garde-fou versionné n'a pas été modifié dans ce sens sur `claude/backend-reprise`. Tant que les deux ne disent pas la même chose, les fiches gardent « Codex » pour le backend et le directeur tranche l'exécutant au lancement de chaque lot ; la fiche n'a pas à changer, seul l'exécutant change.
- Aucun jeton du thème (`lib/core/theme/`) ne change sans décision datée du directeur. Aucun fichier de `.github/`.
- Un statut ne change qu'avec une preuve : scénario SQL rejoué, test Dart, capture nommée.
- Vérifications avant de dire que c'est fait : `dart run slang` ; `dart run build_runner build --delete-conflicting-outputs` ; `dart analyze --fatal-infos` ; `flutter test` (ciblé puis complet) ; `dart run tool/verifier_jetons.dart` sans augmentation ; `dart run tool/verifier_revue.dart` sans augmentation du socle ; rejeu SQL complet pour toute migration ; capture pour tout changement visible.
- Esprit (Cherny, Karpathy) : critère de réussite écrit avant tout ; un moyen de vérifier soi-même ; le plus simple qui marche ; changement chirurgical ; petit diff ; chaque erreur payée devient une ligne de « Pièges connus ».

« Taille » : S moins d'une demi-journée, M une journée, L plus. « Ensemble » : les lots qui peuvent tourner en parallèle (fichiers disjoints).

## Vague 1 - Sécurité P0 et P1 (avant toute famille réelle)

| ID | Lot | Dépend de | Exécutant, modèle | Taille | Fichiers principaux | Ensemble |
|---|---|---|---|---|---|---|
| L1-09 | Stub de CI aux privilèges Supabase, liste blanche des fonctions volatiles, texte des changements `.github` pour le directeur | aucun | Codex, Haiku | M | `supabase/tests/stub_auth.sql`, `scenarios_af_liste_blanche_volatiles.sql`, `docs/audit-final/ci/ci.yml.propose.md` | seul, en premier |
| L1-01 | `record_session_event`, `log_sensitive_access`, `materialiser_seances` réservées au serveur (P0-1, P1-2, P1-3) | L1-09 | Codex, Haiku | S | `20261017100100_af_l1_01_*.sql`, `scenarios_af_l1_01_*.sql` | A |
| L1-02 | Policies de foyer avec rôle tuteur, l'adulte garde la main (P0-2 finances, caméra) | L1-09 | Codex, Sonnet | M | `20261017100200_af_l1_02_*.sql`, scénario | A |
| L1-03 | Cahier brut : auteur, administration, contrôleur en mission (P0-2 cahier, P2-1) | L1-09 | Codex, Sonnet | M | `20261017100300_af_l1_03_*.sql`, scénario | A |
| L1-04 | `mes_seances_v` par rôle (P0-2 fratrie) | L1-09 | Codex, Haiku | S | `20261017100400_af_l1_04_*.sql`, scénario | A |
| L1-05 | `decider_dossier` une seule fois, rejet retire l'accès (P1-1) | L1-09 | Codex, Haiku | S | `20261017100500_af_l1_05_*.sql`, scénario | A |
| L1-06 | `wallet_entries` immuable (P1-4) | L1-09 | Codex, Haiku | S | `20261017100600_af_l1_06_*.sql`, scénario | A |
| L1-07 | `profiles.gender` colonne privilégiée (P1-5) | L1-09 | Codex, Haiku | S | `20261017100700_af_l1_07_*.sql`, scénario | A |
| L1-08 | 44 policies par rôle exigent un compte valide, journal réservé à l'administration (P1-6, P2-1) | L1-09, L1-06 | Codex, Haiku | M | `20261017100800_af_l1_08_*.sql`, scénario | après A |
| L1-V | Vérification croisée de la vague 1 | L1-01 à L1-09 | agent tiers, Sonnet ou plus | M | `docs/audit-final/verifications/L1-V-2026-10.md` | seul, en dernier |
| L1-10 | MFA du contrôleur (TOTP, `aal2`) : conditionnel à A-02 | A-02, L1-09 | Codex puis Claude Sonnet | L | `supabase/config.toml`, migration, écran d'enrôlement | hors ensemble |
| L1-11 | Inscription enseignant sur invitation seulement : conditionnel à A-07 | A-07, L1-09 | Codex Haiku puis Claude Haiku | S | migration, scénario, `lib/features/inscription/` | hors ensemble |

Ensemble A : L1-01 à L1-07 en parallèle (une migration et un scénario chacun, noms distincts). L1-08 après L1-06. L1-V après tout.

## Vague 2 - Raccordements manquants

| ID | Lot | Dépend de | Exécutant, modèle | Taille | Fichiers principaux | Ensemble |
|---|---|---|---|---|---|---|
| L2-01 | Jeton vidéo pour l'enseignant effectif, retrait d'élève coupe ses séances, `b09` vert (P2-2) | L1-V | Codex, Sonnet | M | `20261017110100_af_l2_01_*.sql`, `scenarios_b09_remplacements.sql`, scénario | B |
| L2-02 | Aperçu KYC par la fonction Edge `piece-identite-acces` (P2-4) | L1-V | Codex (service) ou Claude sur exception, Haiku | S | `lib/core/dossier/service_validation.dart`, `admin_dossiers/detail_dossier.dart`, test | B |
| L2-03 | La file des cahiers se rejoue à l'ouverture et au retour du réseau | L1-V | Claude, Haiku | S | `lib/features/journee/`, i18n, test | B |
| L2-04 | Le client demande les séances d'un élève précis (défense en profondeur) | L1-V | Codex (services), Haiku | S | `service_suivi.dart`, `service_planning.dart`, tests | B |
| L2-05 | Écran d'administration des offres vitrine : créer, publier, retirer | L1-V | Claude Sonnet (écran) et Codex Haiku (adaptateur) | L | `lib/features/admin_offres/`, `port_offres_admin.dart`, `offres_admin_supabase.dart`, `app_router.dart`, `main.dart`, i18n, tests | B (écran) ; adaptateur après le contrat |
| L2-06 | Drapeau d'observation réelle ouvert en staging : après A-09 | L1-V, A-09 | Claude, Haiku | S | `lib/core/config/env.dart`, test | B |
| L2-07 | Matricule affiché, rôle à côté, copie (étape `IMM-FRONT-1`) | L1-V, contrat du port | Claude Haiku (écran), Codex (adaptateur, RPC si besoin) | M | `lib/core/identite/`, `lib/features/compte/`, `lib/features/foyer/`, i18n, tests | B |
| L2-08 | Réglages serveur alignés sur les décisions du 29/09 au 14/10 (étape `ALIGN-1410-BACK`) | L1-V | Codex, Sonnet | M | `20261017110800_af_l2_08_*.sql`, scénario | B |
| L2-09 | Policies Storage : supports par la porte, avatars de classe, photos d'enseignant (P2-3, P3-3) | L1-V | Codex, Haiku | S | `20261017110900_af_l2_09_*.sql`, scénario | B |
| L2-10 | Annonce de l'académie une seule fois, test R-COM-12 vert | L1-V | Codex (adaptateur) et Claude (test d'écran), Haiku | S | adaptateur des annonces, `test/features/com_annonces/` | B |
| L2-V | Vérification croisée de la vague 2 (préversion, STAGING en lecture, recette réelle si comptes fournis) | L2-01 à L2-10 | agent tiers, Sonnet ou plus | M | `docs/audit-final/verifications/L2-V-2026-10.md`, `MESURES` 5.3 | seul, en dernier |

Ensemble B : tout en parallèle sauf conflits sur `fr.i18n.json` et `ar.i18n.json` (L2-03, L2-05, L2-07 ajoutent des clés : fusionner l'un après l'autre, rebase simple) et sur `lib/main.dart` (L2-05 adaptateur, L2-07 adaptateur : une ligne chacun).

## Vague 3 - Doublons et simplification

| ID | Lot | Dépend de | Exécutant, modèle | Taille | Fichiers principaux | Ensemble |
|---|---|---|---|---|---|---|
| L3-01 | Débrancher la seconde salle `/tc/classe` : après A-05 | L2-V, A-05 | Claude, Haiku | S | `app_router.dart` (une ligne), `tc_mes_groupes/routes_tc_a.dart`, tests | C |
| L3-02 | Retirer le matching individuel : après A-06 | L2-V, A-06 | Codex Haiku (serveur), Claude Sonnet (écrans) | L | migration revoke, `lib/core/matching/`, `admin_attribution/`, `creneaux/`, routeur, `main.dart`, i18n | C, mais large : à faire quand C est calme |
| L3-03 | `mouvement.dart` alias des jetons `AppMouvement` (8 violations de moins) | L2-V | Claude, Haiku | S | `lib/core/mouvement/mouvement.dart`, tests | C |
| L3-04 | Code mort : `assisterEnTuteur`, adaptateur orphelin, `estCertificationReussie` | L2-V | Claude et Codex, Haiku | S | `lib/core/video/`, `lib/core/offres/demandes_horaires_supabase.dart`, `service_evaluations.dart` | C |
| L3-05 | Libellés : formats et états génériques en clés communes, outil `doublons_i18n` | L2-V, après les lots qui ajoutent des clés | Claude, Haiku | M | `tool/doublons_i18n.dart`, `fr.i18n.json`, `ar.i18n.json`, appelants | seul sur i18n |
| L3-06 | RPC en double fermées (surcharges courtes, `affecter_enseignant_classe`, `publier_groupe_depuis_offre`) | L2-V | Codex, Haiku | S | `20261017120600_af_l3_06_*.sql`, `b18`, liste blanche, `service_groupes.dart` si besoin | C |
| L3-07 | Garde-fous : `verifier_jetons` à zéro, socle de revue réduit, suite complète mesurée, test de non-régression des outils | L3-03, lots de vague 2 | Claude, Sonnet | M | fichiers signalés, `tool/revue_socle.txt` (baisse seule), `test/tool/`, `MESURES` 5 | après C |
| L3-V | Vérification croisée de la vague 3 (parcours clés, gestes, mesures) | L3-01 à L3-07 | agent tiers, Sonnet ou plus | M | `docs/audit-final/verifications/L3-V-2026-10.md`, `MESURES` | seul, en dernier |

Ensemble C : L3-01, L3-03, L3-04, L3-06 en parallèle. L3-02 large, après décision. L3-05 seul sur les JSON. L3-07 après L3-03 et avant L3-V.

## Vague 4 - Finition visuelle

| ID | Lot | Dépend de | Exécutant, modèle | Taille | Fichiers principaux | Ensemble |
|---|---|---|---|---|---|---|
| L4-01 | Connexion : libellés qui suivent le chemin, démonstration en arabe | L3-V | Claude, Haiku | S | `lib/features/connexion/connexion_page.dart`, i18n, tests | D |
| L4-02 | Mon compte : la carte indisponible dit quoi, pourquoi, quoi faire (K-59) | L3-V | Claude, Haiku | S | `lib/features/compte/`, i18n, tests | D |
| L4-03 | Classes à ouvrir : un seul bouton plein (contrat B) | L3-V | Claude, Haiku | S | `admin_regroupements/regroupements_page.dart`, tests, socle (baisse) | D |
| L4-04 | Tirage : fréquence en une rangée de puces (K-58) | L3-V | Claude, Haiku ou Sonnet | S | `admin_tirage/tirage_page.dart`, i18n, tests | D |
| L4-05 | Démonstration du tuteur : données cohérentes, alerte unique, option expliquée, phrase sous condition, parcours avec élève | L3-V | Claude, Haiku et Sonnet | M | `features/demo/`, `accueil_famille/`, `foyer/formulaire_profil_eleve.dart`, i18n, tests | D |
| L4-06 | Pédagogie : chargement expliqué à 8 s, récupérable à 20 s (DESIGN-GOV 4 bis.6) | L3-V | Claude, Sonnet ou Haiku | M | `admin_pedagogie_*/`, `lib/core/widgets/chargement_avec_delais.dart`, tests | D |
| L4-V | Vérification croisée de la vague 4, matrice et synthèse mises à jour | L4-01 à L4-06 | agent tiers, Sonnet ou plus | M | `docs/audit-final/verifications/L4-V-2026-10.md`, `MATRICE-CONFORMITE.md`, note en tête du rapport | seul, en dernier |

Ensemble D : tout en parallèle ; conflits possibles sur les JSON i18n (L4-01, L4-02, L4-04, L4-05) : fusion l'un après l'autre.

## Compte

| Vague | Lots de code | Lots de vérification | Conditionnels | Haiku suffisant |
|---|---:|---:|---:|---:|
| 1 | 9 | 1 | 2 (L1-10, L1-11) | 7 sur 9 |
| 2 | 10 | 1 | 1 (L2-06 après A-09) | 7 sur 10 (L2-01, L2-05 écran, L2-08 : Sonnet) |
| 3 | 7 | 1 | 2 (L3-01 après A-05, L3-02 après A-06) | 5 sur 7 (L3-02 écrans, L3-07 : Sonnet) |
| 4 | 6 | 1 | 0 | 4 sur 6 (L4-05 partie, L4-06 : Sonnet) |
| Total | 32 | 4 | 5 | 23 sur 32 |

Le rapport (section 1) annonce 29 lots dont 26 exécutables par un Haiku : il comptait les lots sans les deux conditionnels de la vague 1 et sans L3-02, et classait Haiku tout lot où Haiku suffit pour au moins une partie. Ce tableau est la référence.

## Arbitrages qui conditionnent un lot

| Arbitrage | Lots |
|---|---|
| A-02 MFA | L1-10 |
| A-05 seconde salle | L3-01 |
| A-06 matching | L3-02 |
| A-07 invitation enseignant | L1-11 |
| A-09 observation en staging | L2-06 |
| A-10 CI (`.github`) | aucun lot : L1-09 prépare le texte, le directeur pose les fichiers |

Les autres arbitrages (A-01 enregistrement, A-03 nom de l'interface, A-04 navigation enseignant, A-08 site et tarifs) ne conditionnent aucun lot de ce plan : ils ouvriront des lots nouveaux quand ils seront tranchés.
