# Registre de conformite - Tableau de suivi, PR et branches

- SHA audite : `4a7aa2b` (commit `4a7aa2be`, dernier commit de `origin/main`). Le HEAD de la copie de travail est `ff01c087`, qui n'ajoute que six fichiers sous `docs/audit-harmonisation/` (git show --stat ff01c087). Toutes les preuves de code ci-dessous sont lues sur cette copie, identique a `4a7aa2b` hors de ce dossier.
- Date : 14/10/2026 (copie de travail datee du 15/10/2026).
- Auditeur : Claude (Sonnet 5.5), audit differentiel en lecture seule.
- Domaine : etat du tableau de suivi (PROGRESS.md, HANDOFF.md, catalogue des ecrans), PR ouvertes, branches, chronologie des migrations, agents actifs.
- Limites techniques : Flutter et Dart ne sont pas installes ici, aucun test n'a ete execute. "test lu, non execute" vaut pour toute mention de test. Le depot local est un clone superficiel (shallow) : les comptes de commits entre branches (ex. "1754 commits d'avance" pour `ccr-1b1bfa0b-m1kvkk`) sont des artefacts de l'historique tronque et ne mesurent pas une vraie divergence.

## 1. Perimetre, sources lues, sources introuvables

### 1.1 Sources lues

| Source | Plage lue | Usage |
| :-- | :-- | :-- |
| `docs/PROGRESS.md` | 1 a 240 (entier) | Tableau declare des etapes, onboarding A a M, decisions en attente |
| `docs/HANDOFF.md` (3669 lignes) | 1 a 167, 2605 a 2870, grep des titres et des identifiants | Entrees datees de tete, inventaire de cloture section 10 |
| `docs/ECART-SPEC-REALITE.md` | 1 a 40, 96 a 230, 300 a 319 | Releve du 18/09 |
| `docs/AGENT_HANDOFF.md`, `CODEX.md`, `FABLE_*.md` (en-tetes) | entiers ou 1 a 25 | Agents actifs |
| `docs/architecture/TEACHER_FILE_OWNERSHIP.md`, `TEACHER_INTEGRATION_REPORT.md` | 1 a 60 | Propriete des fichiers, bilan du lot Enseignant |
| `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md` | entier | Etat 21/09 des migrations |
| `docs/design/08-catalogue-ecrans.md` | lignes 40 a 95 (colonne statut) | Statuts d'ecrans |
| `docs/architecture/decisions.md` | ADR-026, ADR-028 (en-tetes) | Decisions recentes |
| Prompt de mission | lignes 81 a 103, 146 a 175, 433 a 545 (titres) | Regle du tableau existant, format E |
| Document maitre | lignes 779 a 830, 895 a 925 (addenda) | Statuts, hierarchie, reconciliation |
| Branche `origin/ccr-1b1bfa0b-m1kvkk` (git show) | `docs/current/CONFIGURATION_BASELINE_2026-09-23.md`, `docs/backend/RECONCILIATION_MIGRATIONS_BR0B_2026-10-09.md`, `docs/backend/RESTAURATION_MIGRATIONS_0039_0042.md`, liste des migrations | Ledger PROD et STAGING, ecarts main contre ccr |
| Branche `origin/claude/beautiful-ptolemy-xmhiki` (git show) | `docs/orchestration/PASSATION-FIN-CODEX-2026-10-13.md` entier | Passation de fin de Codex, tableau reel utilise par le backend |
| Branche `origin/claude/keen-ritchie-kdmnfc` (git show) | `docs/current/REGISTRE-RECONCILIATION-2026-10-14.md` lignes 103 a 172 | Deux defauts de securite KYC, arbitrages ouverts |
| GitHub (outils de lecture) | `list_pull_requests` (36 PR), `pull_request_read get` sur 21 PR, `get_files` sur #29 et #17, `list_issues` | Section 2.D |
| Code et tests HEAD | app_router.dart, env.dart, services, tests cites en preuve | Rapprochement des taches terminees |

### 1.2 Sources introuvables ou inaccessibles

- Project Board GitHub : aucun outil de lecture de projets disponible parmi les outils MCP GitHub autorises. Etat : non accessible.
- Issues GitHub : `list_issues` etat OPEN renvoie `totalCount: 0`. Les issues ne servent donc pas de tableau.
- Feuille de suivi Google (identifiant cite par la passation, section 6) avec ses onglets "Codex1 - en cours", "Codex2 - en cours", "Contrats", "Questions", "Journal distant", "Backend" : appels MCP Google interdits par la mission. Non lue. Les deux sessions Codex n'y ont plus acces (jeton expire, passation section 6).
- Artifact "Tableau des etapes" cite par la passation (section 6) : non lu (appel distant hors du perimetre autorise).
- Branches `ui/tuteur-v1` (PR #3), `c0/configuration-baseline-2026-09-23` (PR #2), `claude/confident-mayer-m2fqsl` (PR #5), `claude/modest-hopper-hj96t5` (PR #7), `codex/backend-*` (PR #10 a #31), `refactor-ui-lavender-3628477128789856989` (PR #1) : non recuperees localement. Seules cinq branches distantes sont presentes. Les PR ont ete lues par leur description et, pour #29 et #17, par la liste de fichiers.
- Le contenu de `docs/current/` de la branche ccr n'a ete lu que pour les trois documents nommes plus haut.

## 2. Registre par exigence

Legende des responsables : frontend, backend, contrat partage, contenu academique, gouvernance. Statuts : liste fermee de la mission.

### 2.A Registre atomique (une exigence par ligne)

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-TAB-001 | Identifier le tableau de suivi reellement utilise (prompt de mission, lignes 81-90) | Pilotage | PROGRESS.md + HANDOFF.md en depot ; feuille Google et artifact hors depot | CONFORME_PARTIEL | PROGRESS.md:1-6 ; HANDOFF.md:1 ; passation PR #34 section 6 (feuille et artifact) | Tableau en depot lu en entier ; tableau externe actif du backend non lu | P1 | gouvernance | aucune tache existante trouvee (c'est le tableau lui-meme) |
| AUD-TAB-002 | Inventorier les issues GitHub | Pilotage | GitHub Issues | NON_APPLICABLE_JUSTIFIÉ | list_issues OPEN : totalCount 0 | Aucun ecart : les issues ne servent pas de suivi | - | gouvernance | - |
| AUD-TAB-003 | Inventorier le Project Board GitHub | Pilotage | GitHub Projects | BLOQUÉ_DÉPENDANCE | Aucun outil de lecture des projets dans les outils autorises | Non demontre : existence d'un board non verifiee | P2 | gouvernance | aucune tache existante trouvee |
| AUD-TAB-004 | Lire le tableau actif du backend (feuille Google, onglets Codex1, Codex2, Contrats, Questions) | Pilotage backend | Feuille Google, artifact "Tableau des etapes" | BLOQUÉ_DÉPENDANCE | Passation PR #34 section 6 : "Les deux sessions Codex n'y ont plus acces" ; MCP Google interdit par la mission | Statuts CONFIRME et CHANGES des lots backend non verifiables ici ; a lire par une session autorisee | P1 | gouvernance | lots nommes dans la passation : F86, C-29, RECH-BACK-4, IMM-BACK-2, COM-BACK-1, CAP29-BACK-1 |
| AUD-TAB-005 | Le tableau PROGRESS.md reflete l'etat du HEAD (regle de lecture PROGRESS.md:176-179) | Pilotage | PROGRESS.md | CONTRADICTOIRE | PROGRESS.md:23-24 (profil enseignant et espace comptable "a construire") contre app_router.dart:326-328 (`ProfilEnseignantPage`) ; PROGRESS.md:34 (R3 "avant commit") contre `git ls-files lib/features/suivi_eleve` (fichier suivi) et app_router.dart:222-224 ; PROGRESS.md:131 et 134 (etapes 5 et 6 "[ ]") contre CahierPage, SallePage, MushafPage routes ; dernier jalon date : 14/09 | Ajouts dates en tete de section DEMARRER ICI, sans reecriture (section 2.C) | P1 | gouvernance | R3, ENS-05, ENS-04, N3 a N5 |
| AUD-TAB-006 | HANDOFF.md couvre le travail posterieur au 19/09 | Pilotage | HANDOFF.md entrees datees | ABSENT | Plus recente entree : HANDOFF.md:3 (19/09). grep sur HANDOFF.md et PROGRESS.md : "Teaching Core" 0, "0034" 0, "0038" 0, "0043" 0, "ccr-1b1bfa0b" 0, "FABLE" 0, "21 septembre" 0 | Trace manquante pour : integration Teaching Core (commits du 20/09), observation du 21/09, R2 (5a78726), hook 0038, onboarding 0043 (22/09), PR de la branche ccr | P1 | gouvernance | aucune tache existante trouvee pour la trace ; les travaux sont documentes ailleurs : TEACHER_INTEGRATION_REPORT.md, R2_STORAGE_IMPLEMENTATION.md, FABLE_ONBOARDING_CLASSES_REPORT.md |
| AUD-TAB-007 | Le catalogue des ecrans porte le statut reel | Pilotage | 08-catalogue-ecrans.md | CONTRADICTOIRE | 08-catalogue-ecrans.md:63 (ENS-04), :64 (ENS-08), :52 (ENS-07), :88 (ENS-05) "a construire" contre app_router.dart:355, :365, :360, :328 ; ligne :66 se declare elle-meme "etat perime" | Mettre a jour quatre statuts et la ligne Suivi eleve | P2 | gouvernance | ENS-04, ENS-05, ENS-07, ENS-08 |
| AUD-TAB-008 | Documents de pilotage de la branche ccr (bilan C0, registre de reconciliation) disponibles sur la branche de travail | Pilotage | `docs/current/` sur ccr, PR #2 et #35 | BLOQUÉ_DÉPENDANCE | Absents de HEAD (ls docs : pas de `docs/current`) ; presents sur `origin/ccr-1b1bfa0b-m1kvkk` (git ls-tree) | Les decisions du 09 au 14/10 (offres, immatriculation, reconciliation) ne sont pas visibles depuis main | P1 | gouvernance | PR #2, #35, ALIGN-1410-FRONT, ALIGN-1410-BACK, PED-INTEGR-UX, PED-INTEGR-BACK, PED-SUPPORTS (cites par REGISTRE-RECONCILIATION section 9) |
| AUD-TAB-009 | Mesures de reference citees sont coherentes entre sources | Pilotage | PROGRESS.md, HANDOFF.md, TEACHER_INTEGRATION_REPORT.md | CONTRADICTOIRE | Tests : PROGRESS.md:192 (743/743, 14/09), HANDOFF.md:50-60 (684/691, 19/09), TEACHER_INTEGRATION_REPORT.md section 1 (872 dont 1 rouge, 20/09), commit 9632ac98 (21/09, "dernier test rouge") ; jetons : 6 (PROGRESS.md:193), 11 (HANDOFF), 10 (rapport Enseignant) | Valeur courante non mesurable ici ; ne pas citer 743/743 comme etat actuel | P2 | gouvernance | recette MVP-0 (PROGRESS.md:184-209) |
| AUD-TAB-010 | Les PR ouvertes sont suivies dans le tableau | Pilotage | PR #1 a #36 | ABSENT | grep "ccr-1b1bfa0b" et "PR #" : 0 occurrence dans HANDOFF.md et PROGRESS.md ; 25 PR ouvertes (section 2.D) | Ajouter un tableau des PR ouvertes avec decision attendue | P1 | gouvernance | aucune tache existante trouvee |
| AUD-TAB-011 | Etape 1 : fondations DB, RLS, audit (PROGRESS.md:126) | Backend | migrations 0001 a 0004, scenarios_etape3.sql | CONFORME_PARTIEL | supabase/migrations/0001_fondations.sql:221-230 (`lesson_reports_idempotency_unique`) ; ci.yml:48 ; baseline C0 : texte de 0001 a 0005 "non comparable" en PROD | Existence prouvee ; parite des corps avec PROD non demontree ; branche ccr a modifie 0001, 0004 a 0013 (git diff --name-status HEAD ccr : M) | P1 | backend | B-01 (PR #25, #32) |
| AUD-TAB-012 | Etape 2 : theme, composants, routeur, cache (PROGRESS.md:127) | Frontend | lib/core/theme, lib/core/cache, tool/verifier_jetons.dart | CONFORME_PARTIEL | Dossiers presents ; test/theme (5 fichiers), test/cache (2), test/widgets (8) lus, non executes | Verificateur de jetons declare rouge (PROGRESS.md:193) ; non rejoue | P2 | frontend | T, C, T2, T3 |
| AUD-TAB-013 | Etape 3 : auth, KYC, appairage, portails (PROGRESS.md:128) | Tuteur, enseignant | app_router.dart:113-148 ; services dossier | CONFORME_PARTIEL | scenarios_etape3.sql ; ci.yml:48 ; 0004_inscription_kyc_appairage.sql:187 et :559-570 | Deux defauts de securite KYC ouverts (AUD-TAB-050, 051) | P0 | backend | ADM-02 |
| AUD-TAB-014 | Etape 4 : dashboards L0 a L10 (PROGRESS.md:129) | Quatre roles | app_router.dart:200-330 | CONFORME_PARTIEL | scenarios_etape4.sql ; ci.yml:57 ; tests `accueil_eleve_test`, `accueil_famille_test`, `journee_test`, `disponibilites_test` presents | Nombre de controles : 39 (PROGRESS.md:116) contre 37 (CLAUDE.md racine) ; non recompte | P2 | gouvernance | L0 a L10 |
| AUD-TAB-015 | Etape 4 bis : refonte UX (T, C, R0 a R4, B0, T2, T3, A1) | Frontend | docs/design, test/accessibilite | CONFORME_PARTIEL | test/accessibilite/clavier_test.dart (4 tests), rtl_echelle_texte_ecrans_test.dart (3) lus ; PROGRESS.md:193 jetons rouges | Rouge declare ; Skeleton partiel (HANDOFF.md:2625 "Refonte loading") | P2 | frontend | R0 a R4, A1, Prompt 2 de HANDOFF section 10.6 |
| AUD-TAB-016 | N1 : structure Coran, position, presence derivee (0007) | Eleve | migration 0007 ; scenarios_etape5.sql | CONFORME_PROUVÉ | 0007:161-170 (table `session_presence_override`, check sur l'etat) ; scenarios_etape5.sql : 15 `raise notice 'OK` comptes ; ci.yml:68 | - | - | backend | N1 |
| AUD-TAB-017 | N2 : aiguillage fournisseur video, jeton, webhooks idempotents | Quatre roles | create-room-token, livekit-webhook, 0010 | CONFORME_PARTIEL | supabase/functions/create-room-token/index.ts, livekit-webhook/index.ts ; scenarios_n2.sql ; ci.yml:86 ; test/video (2 fichiers) lus | Connexion reelle a une salle non prouvee (PROGRESS.md:131) | P0 | backend | N2, ligne I d'onboarding |
| AUD-TAB-018 | Chaine LiveKit reelle : compte, trois secrets, webhook (onboarding I) | Quatre roles | secrets Edge | BLOQUÉ_DÉPENDANCE | PROGRESS.md:148 ; baseline C0 section 2 : secrets LiveKit "INCONNU" ; ECART-SPEC-REALITE.md:100 | Compte fournisseur a confirmer par le directeur | P0 | gouvernance | N2, I, HANDOFF section 10.2 ligne "Chaine LiveKit reelle" |
| AUD-TAB-019 | Enregistrement audio systematique des seances (ADR-002) | Safeguarding | Egress, R2 | PRÉSENT_MAIS_NON_RACCORDÉ | livekit-webhook/index.ts:99-110 ingere `egress_ended` ; `grep -rn "startEgress ou EgressClient" supabase/functions lib` : aucune occurrence ; fr.i18n.json:30 affiche "Cours enregistre" | Le demarrage de l'Egress n'existe pas : le bandeau annonce un enregistrement non declenche | P0 | backend | HANDOFF.md:2632 (ligne "Enregistrement safeguarding") |
| AUD-TAB-020 | ADM-05 attribution manuelle | Admin | app_router.dart:411-414 ; service_attribution.dart:230 ; 0008:219 `attribuer_eleve` | CONFORME_PROUVÉ | scenarios_adm05.sql (scenarios A1 a A9, entetes lus) ; ci.yml:78 ; test/features/attribution_admin_test.dart | - | - | frontend | ADM-05 |
| AUD-TAB-021 | ADM-05 et ENS-06 survivent a ADR-028 (cours de groupe) et au modele des Classes stables (document maitre section 28.1) | Admin, enseignant | `AttributionPage`, matching individuel | À_ARBITRER | decisions.md:1526-1545 (ADR-028) ; document maitre 28.1 "ne pas reintroduire le matching individuel" ; app_router.dart:317-319 (creneaux) et :414 encore routes | Decider si ADM-05 et ENS-06 sont conserves, reduits ou remplaces ; ne pas les fermer par similarite | P1 | gouvernance | ADM-05, ENS-06, TUT-04, ADM-09 |
| AUD-TAB-022 | ADM-04 journal d'audit et chaine de hachage | Admin | app_router.dart:532-535 ; service_journal.dart:269 ; 0009:68 | CONFORME_PROUVÉ | scenarios_adm04.sql J1 a J7 (falsification detectee) ; ci.yml:180 ; test/features/journal_admin_test.dart | - | - | backend | ADM-04 |
| AUD-TAB-023 | TUT-06 suivi du foyer | Tuteur | app_router.dart:270-272 ; service_suivi.dart:59,75 ; `presence_seance_v` | CONFORME_PROUVÉ | scenarios_n4.sql ; ci.yml:95 ; test/features/suivi_foyer_test.dart ; test/suivi/vue_suivi_foyer_test.dart | - | - | frontend | TUT-06 |
| AUD-TAB-024 | R3 suivi eleve (PROGRESS.md:27-37) | Eleve | app_router.dart:222-224 ; service_suivi.dart:96 `seancesDuSuiviProvider` ; vue `mes_seances_v` 0005:734 | CONFORME_PROUVÉ | suivi_eleve_test.dart:70,95,117,133,152,172,182,202 ; scenarios_n4.sql ; fichiers suivis par git | Hors ligne non teste dans ce fichier (section 5) | - | frontend | R3 |
| AUD-TAB-025 | ENS-04 cahier de transmission, idempotent, file hors ligne | Enseignant | app_router.dart:355 ; service_enseignant.dart:151 ; cache/sync/file_rapports.dart | CONFORME_PROUVÉ | 0001:230 contrainte `lesson_reports_idempotency_unique` ; cahier_test.dart:315 (file hors ligne), :354 (rejeu, une cle) ; test/cache/file_rapports_test.dart | Statut catalogue et HANDOFF.md:2626 perimes | - | frontend | ENS-04 |
| AUD-TAB-026 | Edge Function `submit-lesson-report` annoncee (HANDOFF.md:2627) | Enseignant | supabase/functions | À_ARBITRER | `ls supabase/functions` : aucune telle fonction ; ecriture directe `lesson_reports.insert` avec RLS (0025:436) | Objectif atteint par contrainte d'unicite ; decider si la fonction reste exigee | P2 | backend | ENS-04, "Synchronisation du cahier" |
| AUD-TAB-027 | ENS-05 profil enseignant sans paie (ADR-027) | Enseignant | app_router.dart:326-328 ; service_declaration.dart:33 -> `maj_profil_enseignant` (0027) | CONFORME_PARTIEL | profil_enseignant_test.dart:313,323,356,369,379 (loading, content, empty, error, offline) ; plus de vingt tests dans ce fichier | Aucun scenario SQL pour `maj_profil_enseignant` (grep supabase/tests : 0) | P1 | backend | ENS-05 |
| AUD-TAB-028 | Presence corrigeable : geste humain pour excusee et corrigee_manuel | Enseignant, admin | `PresenceCorrectionPage` | PRÉSENT_MAIS_NON_RACCORDÉ | cahier_page.dart:593-596 (`peutCorriger: true` constant, adaptateur local `_consigner`) ; 0007:161 table sans ecrivain : aucun `insert into public.session_presence_override` dans les migrations | Capacites codees en dur cote client et aucune RPC d'ecriture ; decision humaine non branchee | P1 | contrat partage | HANDOFF.md:2630 ; decision operateur 4 (HANDOFF.md:2679-2685) |
| AUD-TAB-029 | N6 Coran partage (pousser une page) | Enseignant, eleve | providers_tc_realtime.dart:25-26 `TransportIndisponible` ; providers_tc_etat_partage.dart:22-23 `EtatPartageMemoire` | PRÉSENT_MAIS_NON_RACCORDÉ | decisions.md:1331-1336 (ADR-026 tranche le canal LiveKit) ; 0033:868 `publier_etat_partage` sans appelant Dart (grep lib : 0) | Adaptateur reel a poser ; HANDOFF.md:2684 ("canal non tranche") est obsolete | P1 | frontend | N6 |
| AUD-TAB-030 | N3 salle (coquille video) | Quatre roles | app_router.dart:610-611 `SallePage` | IMPLÉMENTÉ_NON_PROUVÉ | test/features/salle_test.dart ; test/video/vue_salle_test.dart | Aucun parcours reel de salle (ECART-SPEC-REALITE.md:100 ; PROGRESS.md:196-203) | P0 | frontend | N3, recette navigateur |
| AUD-TAB-031 | N4 presence bornee, controleur invisible | Quatre roles | 0011, 0012, `presence_seance_v` | CONFORME_PARTIEL | scenarios_n4.sql ; ci.yml:95 ; test/presence/vue_presence_test.dart | `etat_presence` jamais revoquee a PUBLIC dans HEAD (0007:420 ; aucun revoke) : 0042 existe seulement sur ccr (section 2.F) | P0 | backend | N4, CP-TAB-02 |
| AUD-TAB-032 | N5 Coran personnel (mushaf, position) | Eleve | app_router.dart:209-215 ; service_coran.dart:290-402 | CONFORME_PARTIEL | scenarios_n5.sql ; ci.yml:109 ; test/coran (2 fichiers) | Decoupage en 15 lignes reporte (HANDOFF.md:2661) | P2 | frontend | N5 |
| AUD-TAB-033 | CTR-01 planning global controleur | Controleur | app_router.dart:372-374 ; service_controle.dart:53 | CONFORME_PROUVÉ | scenarios_ctr01.sql ; ci.yml:120 ; test/features/planning_controleur_test.dart ; test/controle/vue_planning_test.dart | - | - | frontend | CTR-01 |
| AUD-TAB-034 | CTR-02 observation invisible | Controleur, tuteur, enseignant | 0012, 0016, 0035 a 0037 | CONFORME_PARTIEL | observation_groupe_admin_test.dart ; test/teaching_core/g (7 fichiers) | 0039 a 0041 (invisibilite complete) absents de HEAD ; PR #22 attend des revues | P0 | backend | CTR-01, TC-G, B-20 |
| AUD-TAB-035 | AGT-01 acces des agents IA | Admin | app_router.dart:540-543 ; agent-session ; 0014 | CONFORME_PARTIEL | scenarios_agt01.sql ; ci.yml:133 ; test/agent/acces_agent_test.dart | Aucun test de widget pour `AccesAgentsPage` (grep test : 0) ; correctif B-20 dans PR #28, #30, #20, #10 | P1 | backend | AGT-01, B-20 |
| AUD-TAB-036 | ADM-01, ADM-02, ADM-06, ADM-08 (centre de commande, dossiers, demandes, comptes) | Admin | app_router.dart:389, 436, 424, 448 | CONFORME_PARTIEL | tableau_de_bord_test (2 fichiers), dossiers_admin_test (3), demandes_admin_test (2), comptes_test (1) lus | ADM-02 : defauts KYC ouverts (AUD-TAB-050/051) | P1 | frontend | ADM-01, ADM-02, ADM-06, ADM-08 |
| AUD-TAB-037 | ADM-09 groupes (0017 a 0019) | Admin | app_router.dart:404-407 ; service_groupes.dart | IMPLÉMENTÉ_NON_PROUVÉ | Tests de widget : 4 fichiers referencent `GroupesPage` ; scenarios SQL : aucun fichier ne cite creer_groupe ou groupes_pedagogiques | Preuve serveur manuelle seulement | P1 | backend | ADM-09 |
| AUD-TAB-038 | ADM-10 a ADM-14 pedagogie (0020 a 0024) | Admin | app_router.dart:462-493 | IMPLÉMENTÉ_NON_PROUVÉ | `grep -rl "ProgrammesPage ou QualitePage ou DiagnosticsPage ou EvaluationsPage ou ProgressionPage" test` : 0 ; HANDOFF.md:116-122 : preuves "SMOKE" manuelles, non versionnees | Aucun test widget ni scenario SQL versionne | P1 | frontend | ADM-10 a ADM-14 |
| AUD-TAB-039 | ADM-15 a ADM-17 configuration (CFG-01) | Admin | app_router.dart:506-523 | IMPLÉMENTÉ_NON_PROUVÉ | 0 test cite `ReglesPage`, `FonctionnalitesPage` ; HANDOFF.md:92-96 reconnait que CFG-01 n'avait pas ete trace | Tests et scenarios a ecrire | P1 | frontend | CFG-01, ADM-15 a ADM-17 |
| AUD-TAB-040 | Teaching Core lots A a H et Q integres | Quatre roles | routes_tc_*.dart ; ports par defaut | PRÉSENT_MAIS_NON_RACCORDÉ | port_groupes.dart:37-39 `GroupesDemonstrationLocale` ; port_horloge_seance.dart:54-55 ; providers_tc_etat_partage.dart:22-23 ; aucun override reel dans main.dart:125-130 ; 71 fichiers de test sous test/teaching_core | Adaptateurs reels des ports a poser ; groupes fictifs servis au tuteur sur /tc/groupes (baseline C0 section 4) | P1 | contrat partage | TC-A a TC-H, TC-Q, B-14, B-15 |
| AUD-TAB-041 | R2 : quatre seaux, archives, URL signee 60 s (0034) | Safeguarding | archive-seance-acces ; _shared/r2 | CONFORME_PROUVÉ | scenarios_r2.sql ; ci.yml:169 ; supabase/functions/_shared/r2/ingestion_archive_test.ts ; ledger PROD (baseline C0 section 5) | Ligne H d'onboarding (PROGRESS.md:147) encore "[ ]" | - | backend | H, R2 |
| AUD-TAB-042 | Hook de jeton 0038 (profil sans foyer) | Enseignant, controleur | 0038 ; scenarios_hook_jeton.sql | CONFORME_PROUVÉ | ci.yml:151 ; ledger PROD 20260921043316 (baseline C0 section 5) | Se reconnecter pour que le correctif prenne effet (LISEZ-MOI, fin) | - | backend | 0038 |
| AUD-TAB-043 | Observation 0035 a 0037 appliquees en PROD | Admin, enseignant | 0035-0037 | CONFORME_PARTIEL | baseline C0 section 5 : "identiques (4/4)" ; LISEZ-MOI-0035-0037 (21/09) dit "non appliquees" | Le LISEZ-MOI est obsolete mais toujours present | P2 | backend | CTR-TAB-04 |
| AUD-TAB-044 | Migrations 0039 a 0042 presentes dans le depot principal | Backend | supabase/migrations | CONTRADICTOIRE | HEAD : fichiers absents (ls) ; ccr : presents ; ledger PROD : appliquees (baseline C0 section 5 ; RESTAURATION_MIGRATIONS_0039_0042.md) | Un rejeu depuis main ne reconstruit pas la PROD ; sources a fusionner depuis ccr | P0 | backend | B-01, PR #25, PR #32 |
| AUD-TAB-045 | 0043 offres horaires appliquee en PROD alors que le front l'appelle | Tuteur | service_offres.dart:99-187 (RPC) ; app_router.dart:297 | BLOQUÉ_DÉPENDANCE | FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md:7-9 ; RECONCILIATION_MIGRATIONS_BR0B : 0043 "absente de PROD" ; application PROD sans GO directeur interdite | Ecran des horaires en erreur en PROD tant que 0043 n'est pas appliquee | P0 | backend | onboarding offres (22/09) |
| AUD-TAB-046 | Numerotation des migrations sans collision | Backend | supabase/migrations | À_ARBITRER | Paires 0030/0032/0033 doublees ; deux fichiers 0043 selon baseline C0 ; PR #23 et #21 portent chacune un 0049 divergent ; PR #27/#31 (B-13) et PR #17 (B-15) portent chacune un 0058 | Plan de renumerotation a trancher avant toute fusion ; ne rien renommer | P1 | backend | B-01, B-13, B-15 |
| AUD-TAB-047 | CI qui rejoue les migrations et les scenarios | Gouvernance | ci.yml:25-180 | IMPLÉMENTÉ_NON_PROUVÉ | Passation PR #34 section 5 : "GitHub Actions est hors service" ; PR #27 : runs sans etapes | Aucun run exploitable lu ; ne pas citer les controles comme verts | P1 | gouvernance | E, PR #26 |
| AUD-TAB-048 | Sentry (onboarding F) | Operations | lib/core/observabilite/supervision.dart:52 | CONFORME_PARTIEL | supervision_test.dart ; DSN : baseline C0 "INCONNU" | Compte et DSN a confirmer | P2 | gouvernance | F |
| AUD-TAB-049 | Variantes dev, staging, prod (onboarding G) | Operations | android/app/build.gradle.kts:19 | ABSENT | Un seul applicationId `com.rewayahacademy.rewayah_academy`, different de `com.rewayahacademy.app` ecrit en PROGRESS.md:146 ; baseline C0 : aucun environnement staging dans l'app | Variantes non creees ; identifiant a corriger dans le tableau | P2 | frontend | G |
| AUD-TAB-050 | decider_dossier refuse un dossier deja decide (annexe 11 du dossier maitre cite par REGISTRE-RECONCILIATION section 7) | Admin | 0004:523-571 | ABSENT | 0004:559-562 : `update ... where id = p_document_id` sans condition sur `status = 'pending'` ; aucune migration ulterieure ne redefinit la fonction | Une seconde decision ecrase la premiere ; version attendue et motif `already_decided` absents | P0 | backend | ADM-02 ; PR #22 (autres gardes) ne couvre pas cet etat |
| AUD-TAB-051 | Le controleur n'accede pas aux pieces d'identite (spec du 12/10 section 04.3 citee par REGISTRE-RECONCILIATION section 7) | Controleur | 0004:187 ; 0004:1016 | CONTRADICTOIRE | 0004:187 `app_role() not in ('admin','controller')` ; 0004:1016 politique de stockage `kyc` pour `controller` | Retirer `controller` des deux points apres arbitrage | P0 | backend | ADM-02, PR #22 |
| AUD-TAB-052 | Audio parle pour les 6-8 ans (`AudioLabel`) | Eleve enfant | assets/audio/fr | ABSENT | `ls assets/audio/fr` : `.gitkeep` seul | Enregistrer les libelles | P1 | contenu academique | HANDOFF.md:2640 |
| AUD-TAB-053 | Interface en arabe | Tous | assets/i18n/ar.i18n.json | CONFORME_PARTIEL | 20 feuilles contre 1870 pour fr.i18n.json (decompte par script de lecture) | Couverture 1,1 pour cent ; B-09 AR dans PR #17 (hors interface) | P1 | contenu academique | HANDOFF.md:2642 |
| AUD-TAB-054 | Notifications push (KYC, attribution, fin de seance) | Tuteur, enseignant | `device_tokens` | ABSENT | 0001:348 table seule ; aucun client de push dans lib ; B-09 backend : PR #17 et passation (a8c7a6a5, CONFIRME) | Canal et secrets non livres | P1 | backend | B-09, HANDOFF.md:2637 |
| AUD-TAB-055 | ADM-03 exports et CTR-03 grille d'audit : MVP-0 ou V1 | Admin, controleur | aucun fichier | À_ARBITRER | HANDOFF.md:2674-2677 et :2679-2685 ; ADM-03 absent de PROGRESS.md | Decision directeur requise ; ne rien implementer avant | P1 | gouvernance | ADM-03, CTR-03, Prompt 7 |
| AUD-TAB-056 | CPT-01 espace comptable | Comptable | app_router.dart:586-587 (route vers `ComptePage`) | À_ARBITRER | 08-catalogue-ecrans.md:89 "hors MVP-0 (ADR-003)" ; document maitre : finance dans les domaines a auditer | Statut a confirmer face a la priorite du 14/10 (finance apres classes) | P2 | gouvernance | CPT-01, F70 |
| AUD-TAB-057 | Recette navigateur authentifiee quatre roles | Quatre roles | aucun test d'integration | BLOQUÉ_DÉPENDANCE | PROGRESS.md:196-203 ; ECART-SPEC-REALITE.md:187-199 | Comptes autorises, OTP, LiveKit manquants | P0 | gouvernance | HANDOFF.md:2633, Prompt 6 |
| AUD-TAB-058 | Retrait du mode DEMO_AUTH de main (passation section 8) | Securite | lib/core/auth/service_auth.dart:14,22 ; connexion_page.dart:64 | ABSENT | Le code garde `DEMO_AUTH` (inactif sans define) ; patch `rewayah-prod-release.patch` sur archive/pc-2026-10-13/patchs | Petit lot de nettoyage a rejouer | P2 | frontend | aucune tache existante trouvee |
| AUD-TAB-059 | Agents actifs et propriete des fichiers a jour | Gouvernance | CODEX.md, AGENT_HANDOFF.md, TEACHER_FILE_OWNERSHIP.md | CONTRADICTOIRE | AGENT_HANDOFF.md:16-22 (OpenCode abandonne 14/09) ; passation PR #34 section 0 (fin de Codex 13/10) ; CODEX.md toujours present ; TEACHER_FILE_OWNERSHIP.md:1-8 limite a la phase du 19/09 | Marquer ces fichiers comme historiques ; seul Claude Code est actif | P2 | gouvernance | aucune tache existante trouvee |
| AUD-TAB-060 | Fonction Edge `r2-selftest` en PROD sans source | Securite | Supabase Edge | CONTRADICTOIRE | baseline C0 section 4 : fonction v49, `verify_jwt: true`, absente de `supabase/functions` (ls) | Versionner ou retirer, sur decision | P1 | backend | R2 |

### 2.B Reconciliation tache par tache (tache annoncee, preuve, statut reel propose)

Colonnes : Tache | Statut declare | Source | Preuve trouvee dans le code | Statut reel propose | Action.

| Tache | Statut declare | Source | Preuve trouvee dans le code | Statut reel propose | Action |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Etape 1 fondations | termine | PROGRESS.md:126 | 0001 a 0004 presents ; AUD-TAB-011 | termine, parite PROD non demontree | Ajouter la mention B-01 |
| Etape 2 socle Flutter | termine | PROGRESS.md:127 | AUD-TAB-012 | termine, non rejoue | Aucune |
| Etape 3 auth, KYC | termine | PROGRESS.md:128 | AUD-TAB-013, 050, 051 | termine avec deux defauts ouverts | Rattacher les defauts a ADM-02 |
| Etape 4 dashboards L0 a L10 | termine | PROGRESS.md:129 | AUD-TAB-014 | termine | Corriger le nombre de controles |
| Etape 4 bis refonte T, C, R0 a R4, B0, T2, T3, A1 | termine | PROGRESS.md:130 | AUD-TAB-015 | termine, Skeleton partiel | Rattacher a Prompt 2 |
| Etape 5 salle, Coran, presence | "[ ]" | PROGRESS.md:131 | N1 a N5 presents et routes (AUD-TAB-016, 017, 030 a 032) | en cours : N1, N4, N5 faits, N2 partiel, N3 non prouve, N6 non raccorde | Remplacer "[ ]" par le detail dates |
| N1 | termine | PROGRESS.md:131 | AUD-TAB-016 | termine, prouve | Aucune |
| N2 | termine, "connexion reelle non prouvee" | PROGRESS.md:131 | AUD-TAB-017 | termine cote code, bloque cote compte | Lier a la ligne I |
| N3 salle | termine | HANDOFF.md:534 | AUD-TAB-030 | statut non prouve | Recette navigateur |
| N4 presence | termine | HANDOFF.md:483 | AUD-TAB-031 | termine, fuite anon a fermer | Rattacher a 0042 |
| N5 Coran | termine | HANDOFF.md:372 | AUD-TAB-032 | termine | Aucune |
| N6 Coran partage | ouvert | HANDOFF.md:2629 | AUD-TAB-029 | ouvert, canal tranche (ADR-026) | Retirer "canal non tranche" |
| ADM-05 attribution | termine | PROGRESS.md:132 | AUD-TAB-020, 021 | termine, pertinence a arbitrer | Arbitrage ADR-028 |
| ADM-04 journal | termine | PROGRESS.md:133 | AUD-TAB-022 | termine, prouve | Aucune |
| R3 suivi eleve | non committe, a relire | PROGRESS.md:34 ; HANDOFF.md:2624 | AUD-TAB-024 | termine, commite | Clore la reprise |
| TUT-06 suivi foyer | termine | HANDOFF.md:297 | AUD-TAB-023 | termine, prouve | Aucune |
| ENS-04 cahier | ouvert (P0) | HANDOFF.md:2626-2627 | AUD-TAB-025, 026 | termine cote ecran, fonction Edge a arbitrer | Clore ENS-04, garder le point Edge |
| ENS-05 profil enseignant | ouvert (P0) | PROGRESS.md:23 ; HANDOFF.md:2628 | AUD-TAB-027 | termine, scenario SQL manquant | Ajouter scenario |
| Presence corrigeable | ouvert (P0) | HANDOFF.md:2630 | AUD-TAB-028 | ouvert, non raccorde | Conserver |
| Chaine LiveKit reelle | ouvert | HANDOFF.md:2631 | AUD-TAB-018 | bloque (compte) | Conserver |
| Enregistrement safeguarding | ouvert | HANDOFF.md:2632 | AUD-TAB-019 | ouvert : ingestion faite, demarrage absent | Preciser le reliquat |
| Recette navigateur | ouvert | PROGRESS.md:205 | AUD-TAB-057 | bloque | Conserver |
| Refonte loading | ouvert (P0) | HANDOFF.md:2625 | AUD-TAB-015 | statut non prouve | Mesurer par ecran |
| CTR-01 planning | termine | HANDOFF.md:424 | AUD-TAB-033 | termine, prouve | Aucune |
| CTR-02 observation | termine | HANDOFF.md:424 | AUD-TAB-034 | termine, complement 0039-0042 sur ccr | Lier a AUD-TAB-044 |
| AGT-01 | bloque (section 13) | HANDOFF.md:3304 | AUD-TAB-035 | partiel | Lier a B-20 |
| ADM-01, 02, 06, 08 | termine | catalogue 08:73-78 | AUD-TAB-036 | termine, ADM-02 avec defauts | Lier aux defauts |
| ADM-09 groupes | termine | catalogue 08:79 | AUD-TAB-037 | statut non prouve (serveur) | Scenario SQL |
| ADM-10 a ADM-14 | termine | HANDOFF.md:104 | AUD-TAB-038 | statut non prouve | Tests |
| ADM-15 a ADM-17 | termine | HANDOFF.md:60-62 | AUD-TAB-039 | statut non prouve | Tests |
| Teaching Core A a H, Q | absent du tableau | commits du 20/09 | AUD-TAB-040 | integre, ports non raccordes | Creer l'entree de suivi (section 2.C) |
| Lot Enseignant (ENS-01 a 08) | absent du tableau | TEACHER_INTEGRATION_REPORT.md | routes app_router.dart:308-365 ; tests listes | integre | Reporter dans HANDOFF |
| Onboarding A, B, C, D, E, J, L | termine | PROGRESS.md:140-151 | ci.yml ; functions ; migrations | termine | Aucune |
| Onboarding F Sentry | ouvert | PROGRESS.md:145 | AUD-TAB-048 | partiel | Preciser |
| Onboarding G variantes | ouvert | PROGRESS.md:146 | AUD-TAB-049 | ouvert, identifiant a corriger | Corriger l'identifiant |
| Onboarding H R2 | ouvert | PROGRESS.md:147 | AUD-TAB-041 | termine cote serveur | Cocher avec la date du 21/09 |
| Onboarding I LiveKit | ouvert | PROGRESS.md:148 | AUD-TAB-018 | bloque | Conserver |
| Onboarding K graphify | ouvert | PROGRESS.md:150 | grep : aucune trace hors docs | ouvert | Conserver |
| Onboarding M PWA | termine | PROGRESS.md:152 | build externe, `gitDirty=1` (PROGRESS.md:226) | statut non prouve (deploiement) | Mesurer le bundle servi |
| ENS-05 securite Env.configuree | termine | PROGRESS.md:39-46 | env.dart:65 ; supabase_key_validation_test.dart:7 | termine, prouve | Aucune |
| Hook 0038 | termine | LISEZ-MOI | AUD-TAB-042 | termine | Aucune |
| R2 integration | termine | commit 5a78726 | AUD-TAB-041 | termine, prouve | Aucune |
| Onboarding offres 0043 | livre dans le depot | FABLE_ONBOARDING_CLASSES_REPORT.md | AUD-TAB-045 | bloque (application PROD) | Lier au GO directeur |

### 2.C Mises a jour proposees pour PROGRESS.md et HANDOFF.md (rien n'a ete modifie)

Nature : S = sans risque (ajout date, aucune ligne existante modifiee) ; C = exige confirmation.

| N | Fichier et endroit | Tache existante | Changement propose | Preuve | Nature |
| :-- | :-- | :-- | :-- | :-- | :-- |
| MAJ-01 | PROGRESS.md, tete de DEMARRER ICI | R3 | Ajouter "15/10/2026 : R3 est commite et routee (app_router.dart:222-224, 8 tests)". Ne pas supprimer le paragraphe du 14/09 | AUD-TAB-024 | S |
| MAJ-02 | PROGRESS.md, meme endroit | ENS-05 | Ajouter "ENS-05 est construit (app_router.dart:326-328, plus de vingt tests dont les cinq etats)". Laisser en l'etat la phrase historique | AUD-TAB-027 | S |
| MAJ-03 | PROGRESS.md, tableau des etapes, lignes 131 et 134 | Etape 5, etape 6 | Ajouter une colonne ou une note datee : N1, N4, N5 faits ; N3 non prouve ; N6 non raccorde ; ENS-04 (cahier) fait | AUD-TAB-016 a 032 | S |
| MAJ-04 | PROGRESS.md ligne 147 | H R2 | Ajouter "21/09/2026 : 0034 appliquee en PROD, quatre seaux, scenarios_r2.sql" ; la case reste a la decision du directeur | AUD-TAB-041 | C (cocher la case) |
| MAJ-05 | PROGRESS.md ligne 146 | G | Corriger l'identifiant `com.rewayahacademy.app` en `com.rewayahacademy.rewayah_academy` | android/app/build.gradle.kts:19 | C |
| MAJ-06 | PROGRESS.md | tests et jetons | Ajouter une note "743/743 date du 14/09 ; non mesure depuis le 21/09" | AUD-TAB-009 | S |
| MAJ-07 | HANDOFF.md, nouvelle entree datee en tete | Teaching Core, Enseignant, R2, hook, observation, onboarding | Entree du 20 au 22/09 renvoyant vers TEACHER_INTEGRATION_REPORT.md, R2_STORAGE_IMPLEMENTATION.md, FABLE_ONBOARDING_CLASSES_REPORT.md, LISEZ-MOI | AUD-TAB-006 | S |
| MAJ-08 | HANDOFF.md section 10.2, ligne "Finaliser R3" | R3 | Ajouter "fait, voir MAJ-01" | AUD-TAB-024 | S |
| MAJ-09 | HANDOFF.md section 10.2, ligne ENS-04 | ENS-04 | Ajouter "ecran fait ; reste : fonction Edge a arbitrer" | AUD-TAB-025, 026 | S |
| MAJ-10 | HANDOFF.md section 10.2, ligne ENS-05 | ENS-05 | Ajouter "ecran fait ; reste : scenario SQL de `maj_profil_enseignant`" | AUD-TAB-027 | S |
| MAJ-11 | HANDOFF.md section 10.2, ligne N6 et 10.5 point 3 | N6 | Ajouter "canal tranche par ADR-026 (20/09)" | decisions.md:1331 | S |
| MAJ-12 | HANDOFF.md, nouvelle entree | PR ouvertes | Ajouter le tableau 2.D (numero, decision attendue) | AUD-TAB-010 | S |
| MAJ-13 | HANDOFF.md, nouvelle entree | Migrations | Ajouter la chronologie 2.F avec la mention "PROD a 0042, 0043 non appliquee" | RECONCILIATION_MIGRATIONS_BR0B | S |
| MAJ-14 | 08-catalogue-ecrans.md lignes 52, 63, 64, 66, 88 | ENS-04, 05, 07, 08, suivi eleve | Passer le statut a "construit" avec date | AUD-TAB-007 | C |
| MAJ-15 | Tableau (nouvelle ligne) | ADM-09 a ADM-17 | Ajouter la tache "tests et scenarios de ADM-09 a ADM-17" rattachee aux taches existantes | AUD-TAB-037 a 039 | C |
| MAJ-16 | supabase/migrations/LISEZ-MOI-0035-0037 | 0035 a 0037 | Annoter "appliquees selon baseline C0" ; suppression du fichier a decider par son auteur | AUD-TAB-043 | C |
| MAJ-17 | Tableau | ADM-02 | Ajouter deux sous-taches de securite (AUD-TAB-050, 051) rattachees a ADM-02 | 0004:559, :187 | C |

Etat du tableau (format E du prompt, 11) :
- Taches conservees : toutes (aucune fermeture, aucune suppression).
- Taches enrichies (proposition) : R3, ENS-04, ENS-05, N6, H, G, ADM-02.
- Taches a relier : Teaching Core a B-14 et B-15 ; ADM-05 a ADR-028 ; N4 a 0042.
- Taches nouvelles reellement necessaires : une seule, "tests et scenarios ADM-09 a ADM-17" (aucune tache existante ne la porte) ; plus, sous reserve de confirmation, le suivi des PR ouvertes.
- Operations non realisees faute d'acces : lecture de la feuille Google, de l'artifact et du Project Board ; modification de tout tableau (interdite par la mission).

### 2.D Analyse des PR ouvertes

Toutes les PR backend ciblent `ccr-1b1bfa0b-m1kvkk`, pas `main`. Le "risque de conflit avec HEAD" est donc evalue par rapport a la divergence ccr contre main (migrations 0039 a 0042 et 0044 a 0048 presentes seulement sur ccr, et `git diff --shortstat HEAD origin/ccr-1b1bfa0b-m1kvkk` : 7119 fichiers, valeur gonflee par le clone superficiel). Les PR ne sont pas fusionnables dans `main` sans un plan d'integration de la branche ccr (CP-TAB-03). Recommandations : "a integrer", "a rebaser", "a clore apres arbitrage", "a laisser". Aucune fermeture n'a ete faite.

| PR | Base <- tete | Taille et etat | Contenu principal | Apporte ce que HEAD n'a pas | Conflit avec HEAD | Recommandation |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| #36 | main <- claude/nice-darwin-hael93 | draft | Registres de cet audit | Registres de conformite | Aucun (docs/audit-harmonisation) | a laisser jusqu'a lecture |
| #35 | ccr <- claude/keen-ritchie-kdmnfc | +14352, 11 fichiers, 5 commits, draft | Competence programme-rewayah, sources du directeur du 14/10, registre de reconciliation (deux defauts KYC) ; modifie aussi CLAUDE.md et AGENTS.md | Decisions du 09 au 14/10 | CLAUDE.md : modifie des deux cotes (a verifier) | a integrer apres arbitrage des deux defauts et des questions de la section 9 du registre |
| #34 | ccr <- claude/beautiful-ptolemy-xmhiki | +543, 4 fichiers, draft | Passation de fin de Codex (13/10) | Etat des lots backend, tableau reel | Aucun (docs/orchestration) | a integrer (documentation) |
| #32 | ccr <- codex/backend-lota-ledger-provenance | +42, 1 fichier, draft | Preuve que le corps PROD 0011 correspond au fichier ccr | Provenance B-01 | Aucun | a integrer (documentation) |
| #31 | ccr <- codex/backend-b13-ccr-8ea7831 | +115, 3 fichiers, draft | B-13 : migration 0058, scenario admin actif/suspendu, etape CI | Garde `app_account_valid` sur `guardian_visit_admin` | 0058 en collision avec PR #17 ; ci.yml modifie | a rebaser (numerotation) puis integrer ; remplace #27 et #23 |
| #30 | ccr <- codex/backend-b20-ccr-8ea7831 | +372/-17, 6 fichiers, draft | B-20 identite agent opaque, migration 0074 deja appliquee a STAGING | SEC-01 | 0057 et 0074 absentes de HEAD | a integrer apres revue ; remplace #28 |
| #29 | ccr <- codex/backend-f1-ccr-8ea7831 | +3658/-7, 20 fichiers, draft | F1 : migrations 0049 a 0056, adaptateurs foyer et offres, scenarios B-03, B-07, B-08 | Foyer, profils titulaires, demandes horaires | 0049 en collision avec #23 et #21 ; 0043 de HEAD a verifier | a rebaser puis integrer ; remplace #13 |
| #28 | ccr <- codex/backend-b20-agent-identity | +372/-17, draft | B-20 sur l'ancien ccr 8751bca | Meme contenu que #30 | Base obsolete | a clore apres arbitrage (remplacee par #30) |
| #27 | ccr <- codex/backend-b13-ci-ccr | +116, 3 fichiers, draft | B-13 sur ccr 858dcc6 | Meme contenu que #31 | Base obsolete, 0058 | a clore apres arbitrage (remplacee par #31) |
| #26 | ccr <- codex/backend-staging-preview-secrets | +64/-17, 1 fichier (CI), draft | Apercus Flutter sur Supabase STAGING | Isolation des previews | Modifie flutter-deploy.yml, que HEAD a corrige en ae61eb6c | a rebaser puis integrer |
| #25 | ccr <- codex/backend-lot-a-manifest | +129, 1 fichier, draft | Ledger des migrations (PROD 50 entrees jusqu'a 0042, STAGING 76 jusqu'a 0073) | Chronologie B-01 | Aucun | a integrer (documentation) |
| #24 | ccr <- codex/backend-blueprint | +2585, 5 fichiers, draft | Sources BR-0B et addendum d'etat | Blueprint backend | Aucun | a integrer (documentation) |
| #23 | ccr <- codex/backend-b13-admin-suspended | +118, 3 fichiers, draft | B-13 en migration 0049 | Meme fix que #31 | 0049 en collision avec #21 | a clore apres arbitrage (remplacee par #31) |
| #22 | ccr <- codex/backend-sec-prod | +4256, 2 fichiers, 29 commits, draft | Snapshot securite PROD et script SEC-PROD non valide | Garde de compte sur 15 fonctions, retrait EXECUTE direct de `log_sensitive_access` | Script hors migrations | a laisser jusqu'a revue independante et rejeu PostgreSQL 17 |
| #21 | ccr <- codex/backend-f2-after-c | +17091/-334, 98 fichiers, 282 commits, draft | F2, 0084, C-04, scripts de securite | Large, mergeable false selon la PR | 0049 divergente, 98 fichiers | a rebaser par lots ou a clore apres arbitrage ; le contenu utile est repris par #29, #17, #22 |
| #20 | ccr <- codex/backend-lot-c-staging-api | +5506/-31, 26 fichiers, 115 commits, draft | Lot C identite agent plus F1 en dependance | SEC-01 | Base ancienne be1c421 | a clore apres arbitrage (remplacee par #30) |
| #17 | ccr <- codex/backend-f2-b13-admin-rls | +3149, 20 fichiers, 58 commits, draft | B-09 notifications, B-10 support, B-11, B-13, B-14, B-15 (0058, 0061) | Notifications, support, etat partage, annotations | 0058 en collision avec #31 | a rebaser puis integrer ; CI #201 verte selon la PR (non verifiable) |
| #13 | ccr <- codex/backend-lot-f1 | +5261, 22 fichiers, 98 commits, draft | Branche d'integration F1 | F1 ancien | mergeable clean selon la PR, base ancienne | a clore apres arbitrage (remplacee par #29) |
| #10 | ccr <- codex/backend-lot-c | +209/-7, 7 fichiers, draft | Scenario TDD SEC-01 | Test rouge avant correctif | Obsolete apres #30 | a clore apres arbitrage |
| #8 | main <- codex/site-public-preview-main | +2519/-19, 25 fichiers, 1 commit, draft | Site public francais statique sous `/fr/` | Site public ; version plus recente sur `codex/site-public-local-2026-10-13` | vercel.json et workflows : a verifier | a laisser (publication bloquee par la PR elle-meme) |
| #7 | main <- claude/modest-hopper-hj96t5 | +1394/-1, 3 fichiers, draft | CI : PR vers `ui/**`, verifier_revue | Controle des branches ui | ci.yml modifie, HEAD l'a modifie depuis | a rebaser |
| #5 | integration/essai-fusion <- claude/confident-mayer-m2fqsl | draft | Repetition de fusion | Rapport | Branche de base non presente | a laisser (non lue) |
| #3 | main <- ui/tuteur-v1 | draft, 26/09 | "Demo RA app" | Non lu | Non evalue | a laisser (non lue) |
| #2 | main <- c0/configuration-baseline-2026-09-23 | draft, 23/09 | Bilan C0 (documentation) | Bilan des environnements et des branches | Documentation seule | a integrer apres validation des suppressions de la section 3 du bilan |
| #1 | specs <- refactor-ui-lavender-... | ouverte non draft, 09/09 | Refonte UI Lavender | AGENT_HANDOFF.md:59 : "l'ignorer" | Base `specs` sans ancetre commun | a clore apres arbitrage (decision documentee d'ignorer) |

PR fermees recentes (non reouvertes) : #33, #19, #18, #16, #15, #14, #12, #11, #9 (fusions intermediaires du lot A et F1 vers des branches `codex/*`), #6 (essai CI), #4 (controleur).

### 2.E Branches, worktrees, travail non commite, agents

| Element | Constat | Preuve |
| :-- | :-- | :-- |
| Branche courante | `claude/nice-darwin-hael93`, un commit devant `origin/main` (docs seulement) | git rev-list --count origin/main..HEAD : 1 |
| Retard sur main | 0 | git rev-list --count HEAD..origin/main : 0 |
| Worktrees | un seul (le depot courant) | git worktree list |
| Travail non commite | quatre fichiers non suivis dans `docs/audit-harmonisation/` (produits par d'autres registres de cet audit), aucun fichier suivi modifie | git status --short |
| Branches distantes presentes | 7 : main, ccr-1b1bfa0b-m1kvkk (12/10), claude/beautiful-ptolemy-xmhiki (13/10), claude/keen-ritchie-kdmnfc (14/10), claude/nice-darwin-hael93, codex/backend-blueprint (10/10), codex/site-public-preview-main (08/10) | git for-each-ref refs/remotes |
| Branches citees mais non presentes ici | `observation/lot-2026-09-21`, `codex/backend-canon-fixes`, `codex/journal`, `codex/site-public-local-2026-10-13`, `archive/pc-2026-10-13/*`, `ui/*`, `core24/*` | Non recuperables : non demontre |
| Agents actifs | Claude Code seul. Codex 1 et 2 termines le 13/10 (passation section 0). OpenCode abandonne le 14/09 (AGENT_HANDOFF.md:16). Jules (branche lavender) a ignorer. FABLE : brief nomme mais execute par Claude Code (FABLE_ONBOARDING_CLASSES_REPORT.md:5-7) | Fichiers cites |
| Propriete des fichiers | TEACHER_FILE_OWNERSHIP.md couvre la phase parallele du 19/09, close par TEACHER_INTEGRATION_REPORT.md (20/09). Aucune matrice de propriete a jour pour la phase actuelle | TEACHER_FILE_OWNERSHIP.md:1-8 |
| Nettoyage Git propose | 15 branches mergees, worktrees et clones listes par le bilan C0 (section 3.3), refus du classificateur, suppression non executee | baseline C0 section 3 |

### 2.F Chronologie des migrations

Sources : liste de `supabase/migrations/` sur HEAD et sur ccr (git ls-tree), RECONCILIATION_MIGRATIONS_BR0B_2026-10-09.md, CONFIGURATION_BASELINE_2026-09-23.md section 5, LISEZ-MOI-0035-0037, PR #25, #32. Aucun ledger n'a ete relu directement : les etats PROD et STAGING sont ceux rapportes par ces documents (dates du 23/09 et du 09 au 10/10).

| Migration | Depot HEAD (main) | Depot ccr | PROD | STAGING | Remarque |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 0001 a 0005 | oui | oui, fichiers modifies | oui (versions courtes) | oui | Texte PROD non comparable (statements vides) |
| 0006 a 0013 | oui | oui, fichiers modifies | oui (versions horodatees du 12 et 13/09) | oui | 0011 appliquee deux fois, 0013 structure seule, corpus charge par un autre canal |
| 0014, 0015 | oui | oui | oui | oui | Ecarts de 27 et 51 caracteres non expliques (baseline C0) |
| 0016 a 0029 | oui | oui | oui | oui | Identiques selon baseline C0 |
| 0030 a 0033 (deux fichiers chacun sauf 0031) | oui | oui | oui | oui | Paires distinctes, ne rien fusionner |
| 0034 | oui | oui | oui (21/09) | oui | Horodatee cote PROD |
| 0035 a 0037 | oui | oui | oui selon baseline C0 | oui | LISEZ-MOI dit "non appliquees" (obsolete) |
| 0038 | oui | oui | oui (avant 0034) | oui | |
| 0039 a 0042 | non | oui (restaurees de `observation/lot-2026-09-21`) | oui | oui | Ecart critique, AUD-TAB-044 |
| 0043 offres horaires | oui | oui | non | oui | AUD-TAB-045 |
| 0043 jeton video (archive) | non | non | non | non | Fichier jamais commite (baseline C0) |
| 0044 a 0048 | non | oui | non | 0044 oui ; 0045 et 0046 horodatees | |
| 0049 a 0056 | non | non | non | oui (F1) | PR #29 |
| 0057, 0058, 0061, 0074 | non | non | non | 0057 oui, 0074 appliquee 10/10 | PR #30, #31, #17 ; collisions de numeros |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Perimetre | Decision la plus recente applicable | Statut | Consequence |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| CTR-TAB-01 | PROGRESS.md:34 et HANDOFF.md:2624 : R3 non commite | app_router.dart:222-224, fichiers suivis par git, suivi_eleve_test.dart | R3 | Le code a HEAD (verifiable) | resolu par le code ; tableau a corriger | Reprise inutile d'une revue deja faite |
| CTR-TAB-02 | PROGRESS.md:23-24 : profil enseignant reste `EcranAConstruire` | app_router.dart:326-328 ; TEACHER_INTEGRATION_REPORT.md section 2 ; catalogue 08:88 "a construire" | ENS-05 | Rapport d'integration du 20/09 et le code | resolu | Deux documents a mettre a jour |
| CTR-TAB-03 | HANDOFF.md:2626-2627 : ENS-04 absent, file locale a livrer | cahier_page.dart:212, file_rapports.dart, cahier_test.dart:315 | ENS-04 | Le code a HEAD | resolu | Lot P0 deja livre ; reste la fonction Edge (AUD-TAB-026) |
| CTR-TAB-04 | LISEZ-MOI-0035-0037 (21/09) : non appliquees | Baseline C0 section 5 (23/09) : identiques en PROD | 0035 a 0037 | Baseline C0 (plus recente, ledger relu) | obsolete | Retirer ou annoter le LISEZ-MOI |
| CTR-TAB-05 | PROGRESS.md:147 : R2 "[ ]" (compte Cloudflare) | Commit 5a78726, 0034 appliquee, scenarios_r2.sql, baseline C0 | Onboarding H | Commit et baseline | resolu | Cocher avec date |
| CTR-TAB-06 | HANDOFF.md:2684 (10.5, point 3) : canal Coran partage non tranche | decisions.md:1331-1336 ADR-026 (20/09) | N6 | ADR-026 | resolu | Retirer le blocage de decision |
| CTR-TAB-07 | PROGRESS.md:192 : 743/743 tests | HANDOFF.md:50-60 : 684/691 ; rapport Enseignant : 872 dont 1 rouge | Mesures | Aucune mesure rejouee | ouvert | Ne pas citer de chiffre courant |
| CTR-TAB-08 | HANDOFF.md:2674-2677 : ADM-03 et CTR-03 reportes en V1 | Sources d'origine : ADM-03 au MVP-0 | Perimetre MVP-0 | Aucune decision datee ; document maitre ne tranche pas | ouvert (À_ARBITRER) | Aucun code avant decision du directeur |
| CTR-TAB-09 | Depot principal (HEAD) : migrations jusqu'a 0043, sans 0039 a 0042 | Ledger PROD : 0039 a 0042 appliquees ; ccr : fichiers presents | Backend | Ledger PROD et restauration sur ccr (09/10) | ouvert | Rejeu de main != PROD (AUD-TAB-044) |
| CTR-TAB-10 | ADR-028 : groupe jusqu'a 5 enfants ou 6 adultes | REGISTRE-RECONCILIATION section 3 (14/10) : capacites et minimum d'ouverture reconcilies par decision datee | G-01, classes | Registre du 14/10 si adopte ; non lu en entier | ouvert | Valeurs de capacite a ne pas figer dans le tableau |
| CTR-TAB-11 | ADR-005 : 10 minutes apres la fin du cours | Migrations : 15 minutes (REGISTRE-RECONCILIATION section 7) | Salle | Aucune decision recente | ouvert | A aligner sur un reglage unique |
| CTR-TAB-12 | PROGRESS.md:146 : identifiant `com.rewayahacademy.app` | android/app/build.gradle.kts:19 : `com.rewayahacademy.rewayah_academy` | Onboarding G | Le code | resolu | Corriger le tableau |
| CTR-TAB-13 | PROGRESS.md:185 : "Le perimetre QA a ete execute", rouge declare des jetons | HANDOFF.md:50-60 et rapport Enseignant : 11 puis 10 violations | Jetons | Aucune mesure rejouee | ouvert | Voir CTR-TAB-07 |
| CTR-TAB-14 | CODEX.md (Codex assiste Claude, actif) | Passation PR #34 : Codex termine le 13/10 | Agents | Passation du 13/10 | resolu | CODEX.md a marquer historique |

## 4. Devoir de regard - contre-propositions

Les trois situations du prompt sont distinguees : (a) decision tranchee et implementation defectueuse ; (b) decision tranchee et risque nouveau ; (c) contradiction reelle entre sources actives. Aucune recommandation n'est presentee comme une decision metier. Aucun point religieux ou scientifique n'est tranche ici.

### CP-TAB-01 - Defaut de decision sur un dossier deja traite (situation a)
1. Identifiant : CP-TAB-01.
2. Source : REGISTRE-RECONCILIATION-2026-10-14.md section 7 (annexe 11) ; 0004_inscription_kyc_appairage.sql:523-571.
3. Constat : la mise a jour de `decider_dossier` n'a pas de condition sur le statut `pending` (0004:559-562) ; aucune migration ulterieure ne redefinit la fonction (grep des migrations).
4. Risque : un second administrateur ou un double clic ecrase une decision d'identite ; compte active ou refuse a tort.
5. Gravite et priorite : elevee, P0.
6. Regle actuelle : seule la restriction au role admin et au perimetre de genre.
7. Contre-proposition : ajouter la condition `status = 'pending'`, rendre `already_decided` en erreur explicite, accepter une version attendue (`stale_dossier`).
8. Options : (A) migration corrective additive ; (B) garde dans une RPC wrapper. A est la plus simple.
9. Consequences : l'ecran ADM-02 doit afficher le refus ; aucune donnee existante modifiee.
10. Perimetre : backend (migration, scenario) puis frontend (message).
11. Dependances : numerotation des migrations (CP-TAB-02) ; PR #22 touche d'autres gardes de la meme fonction.
12. Criteres d'acceptation : deux decisions successives, la seconde refusee ; scenario negatif avec mutant.
13. Tests et preuves : scenario SQL dedie ajoute a ci.yml ; test widget du message.
14. Decision requise : confirmation du directeur sur la regle de version attendue.

### CP-TAB-02 - Le depot principal ne reconstruit pas la PROD (situation b)
1. Identifiant : CP-TAB-02.
2. Source : CONFIGURATION_BASELINE_2026-09-23.md section 5 ; RESTAURATION_MIGRATIONS_0039_0042.md ; RECONCILIATION_MIGRATIONS_BR0B_2026-10-09.md.
3. Constat : `ls supabase/migrations` sur HEAD n'a pas 0039 a 0042 ; elles sont appliquees en PROD et presentes sur ccr. Sur HEAD, `etat_presence` n'est pas revoquee a PUBLIC (0007:420, aucun revoke) alors que 0042 la corrige.
4. Risque : un environnement reconstruit depuis main (secours, staging neuf) retrouve des fuites deja corrigees en PROD (presence lisible hors compte, surfaces d'invisibilite du controleur).
5. Gravite et priorite : elevee, P0.
6. Regle actuelle : `main` porte la production (flutter-deploy.yml) mais pas toutes ses migrations.
7. Contre-proposition : integrer dans la branche de production les quatre fichiers restaures a l'identique (blobs notes dans RESTAURATION_MIGRATIONS_0039_0042.md), sans renommer ni reappliquer.
8. Options : (A) cherry-pick des quatre fichiers ; (B) integrer ccr en entier apres plan (CP-TAB-03). A est minimal.
9. Consequences : le rejeu CI s'allonge de quatre fichiers ; les scenarios etape3 et etape4 changent d'oracle (la PR #9 les a deja realignes).
10. Perimetre : backend.
11. Dependances : validation de rejeu PostgreSQL 17 neuf ; decision sur 0043 en double.
12. Criteres : le rejeu complet de main aboutit au meme schema que le ledger PROD.
13. Tests : rejeu des scenarios, comparaison des empreintes `pg_get_functiondef`.
14. Decision requise : feu vert du directeur pour toute application en PROD (aucune n'est demandee ici).

### CP-TAB-03 - Plan d'integration de la branche ccr dans main (situation c)
1. Identifiant : CP-TAB-03.
2. Source : 24 PR ouvertes ciblant ccr ; passation PR #34 section 0.
3. Constat : 17 PR backend ciblent ccr, deux PR seulement ciblent main (#8, #7) ; aucune ligne du tableau en depot ne les mentionne (AUD-TAB-010).
4. Risque : travail accumule hors de la branche de production, collisions de migrations (0049, 0058) et perte de decisions.
5. Gravite : moyenne, P1.
6. Regle actuelle : "jamais de PR vers main" pour les lots backend (passation).
7. Contre-proposition : etablir un ordre d'integration ecrit : documentation (#34, #32, #25, #24, #35), puis SEC-01 (#30), B-13 (#31), F1 (#29), F2 (#17), puis SEC-PROD (#22) apres revue ; clore par arbitrage les PR remplacees (#28, #27, #23, #20, #13, #10).
8. Options : integrer par lots dans ccr puis une PR unique vers main, ou cherry-pick par lot vers main.
9. Consequences : renumerotation a arbitrer (AUD-TAB-046).
10. Perimetre : gouvernance, backend.
11. Dependances : revue independante exigee par les PR #22, #29, #30, #31.
12. Criteres : chaque PR ouverte a une decision datee dans le tableau.
13. Tests : CI verte exploitable (aujourd'hui non demontree).
14. Decision requise : ordre d'integration et fermeture des PR remplacees, par le directeur.

### CP-TAB-04 - Acces du controleur aux pieces d'identite (situation c)
1. Identifiant : CP-TAB-04.
2. Source : REGISTRE-RECONCILIATION section 7 ; 0004:187 et :1016.
3. Constat : `read_kyc_documents()` admet `controller` ; la politique de stockage `kyc_lecture_admin` aussi.
4. Risque : un role de supervision lit des documents d'identite que la specification du 12/10 lui interdit.
5. Gravite : elevee, P0.
6. Regle actuelle : admin et controleur.
7. Contre-proposition : retirer `controller` de la fonction et de la politique, apres confirmation que la spec du 12/10 prevaut.
8. Options : retrait total ou acces par capacite explicite, tracee.
9. Consequences : l'ecran du controleur ne lit plus ces donnees (a verifier : lib/features/controleur ne les lit pas selon la recherche, non demontre).
10. Perimetre : backend, contrat partage.
11. Dependances : PR #22 (retrait de grants voisins).
12. Criteres : appel par un controleur refuse.
13. Tests : scenario negatif.
14. Decision requise : confirmation de la regle par le directeur.

### CP-TAB-05 - Application PROD de 0043 avant la prochaine mise en ligne (situation b)
1. Identifiant : CP-TAB-05.
2. Source : FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md:7-9 ; RECONCILIATION_MIGRATIONS_BR0B.
3. Constat : le front de HEAD appelle les RPC de 0043 (service_offres.dart:99-187) ; 0043 n'est pas dans le ledger PROD.
4. Risque : ecran d'inscription des horaires en erreur pour les familles.
5. Gravite : elevee pour le parcours d'inscription, P0.
6. Regle actuelle : aucune application PROD sans GO.
7. Contre-proposition : planifier l'application de 0043 avec son scenario, ou desactiver l'entree d'ecran tant qu'elle manque.
8. Options : appliquer ; masquer la route ; differer la mise en ligne du front.
9. Consequences : voir CP-TAB-02 (ordre des fichiers).
10. Perimetre : backend, gouvernance.
11. Dependances : GO du directeur.
12. Criteres : le parcours horaire repond en PROD.
13. Tests : recette navigateur (AUD-TAB-057).
14. Decision requise : GO du directeur.

### CP-TAB-06 - Preuves manuelles non versionnees pour ADM-09 a ADM-17 (situation b)
1. Identifiant : CP-TAB-06.
2. Source : HANDOFF.md:104-122 ; recherche dans test/ et supabase/tests/.
3. Constat : aucun test widget ne cite les neuf pages (grep : 0 pour sept d'entre elles) ; aucun scenario SQL ne couvre 0017 a 0027.
4. Risque : regressions silencieuses sur le coeur de l'administration.
5. Gravite : moyenne, P1.
6. Regle actuelle : "SMOKE" manuels.
7. Contre-proposition : une tache de tests rattachee aux taches existantes ; reprendre les scripts manuels en scenarios versionnes.
8. Options : par domaine (pedagogie, configuration, groupes).
9. Consequences : allongement de la CI.
10. Perimetre : frontend, backend.
11. Dependances : CI exploitable.
12. Criteres : un scenario nomme par RPC d'ecriture ; un test des cinq etats par ecran.
13. Tests : ceux-ci.
14. Decision requise : aucune (periodicite a fixer par le directeur).

### CP-TAB-07 - Tableau de suivi unique et lisible (situation c)
1. Identifiant : CP-TAB-07.
2. Source : prompt de mission section 3 ; passation PR #34 section 6.
3. Constat : le tableau actif du backend est une feuille Google inaccessible aux sessions Claude et sans lien dans PROGRESS.md ; le tableau en depot a 38 jours de retard sur le code (AUD-TAB-005).
4. Risque : decisions en double, statuts contradictoires, perte d'historique.
5. Gravite : moyenne, P1.
6. Regle actuelle : deux tableaux paralleles.
7. Contre-proposition : garder la feuille pour le backend, mais ajouter dans HANDOFF.md un renvoi date et un miroir minimal des lots CONFIRME et CHANGES ; ne pas creer de troisieme tableau.
8. Options : miroir manuel periodique ; export de la feuille par une session autorisee.
9. Consequences : une section de plus a tenir.
10. Perimetre : gouvernance.
11. Dependances : acces a la feuille.
12. Criteres : chaque lot de la passation a une ligne dans le depot.
13. Tests : relecture par une session distincte.
14. Decision requise : choix du miroir par le directeur.

### CP-TAB-08 - Parcours enregistre non declenche (situation b)
1. Identifiant : CP-TAB-08.
2. Source : fr.i18n.json:30 ; livekit-webhook/index.ts:99-110 ; ADR-002.
3. Constat : l'interface affiche "Cours enregistre" mais aucun demarrage d'Egress n'existe dans le code.
4. Risque : promesse de securite des enfants non tenue, affirmation fausse aux familles.
5. Gravite : elevee, P0 (confiance et protection).
6. Regle actuelle : enregistrement systematique (ADR-002).
7. Contre-proposition : retirer l'affirmation tant que l'Egress n'est pas demarre, ou livrer l'Egress.
8. Options : message conditionnel a l'etat reel de la seance.
9. Consequences : texte et contrat d'information a revoir.
10. Perimetre : frontend (texte), backend (Egress).
11. Dependances : compte LiveKit (AUD-TAB-018), R2.
12. Criteres : le bandeau reflete l'etat d'une archive reellement creee.
13. Tests : scenario avec `session_recordings`.
14. Decision requise : valider le texte du bandeau et la regle d'information des familles (point de gouvernance, pas de regle religieuse).

## 5. Etats d'ecran et applicabilite

Le domaine est un tableau de suivi documentaire : les cinq etats (chargement, contenu, vide, erreur, hors ligne) et les etats de session ne s'appliquent pas au tableau lui-meme. Ils sont evalues ici par echantillonnage sur les ecrans cites comme termines.

| Ecran | Chargement | Contenu | Vide | Erreur | Hors ligne | Session expiree, acces refuse | Reprise | Preuve |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Tableau PROGRESS.md, HANDOFF.md | non applicable | non applicable | non applicable | non applicable | non applicable | non applicable | non applicable | Documents |
| ENS-04 cahier | present | present | present | present | present | non demontre | present (rejeu) | cahier_test.dart:419,89,474,446,315 |
| ENS-05 profil | present | present | present | present | present | non demontre | non demontre | profil_enseignant_test.dart:313,323,356,369,379 |
| R3 suivi eleve | present | present | present | present | absent du fichier de test | non demontre | non demontre | suivi_eleve_test.dart:152,70,172,182 |
| TUT-06 suivi du foyer | non demontre (fichier non liste) | present | non demontre | non demontre | non demontre | non demontre | non demontre | suivi_foyer_test.dart non detaille |
| ADM-10 a ADM-17 | absent (aucun test) | absent | absent | absent | absent | absent | absent | grep test : 0 |
| Presence corrigeable | non demontre | present | non demontre | present | present | non demontre | present | presence_correction_test.dart:141,170,193 |
| Teaching Core (ports) | non demontre | demonstration | non demontre | non demontre | non demontre | non demontre | non demontre | port_groupes.dart:37-39 |

## 6. Non verifie et limites de la preuve

- Aucun test, aucune analyse, aucune compilation executes. Tous les chiffres de tests des documents sont rapportes, non rejoues.
- La feuille de suivi Google, l'artifact "Tableau des etapes" et le Project Board n'ont pas ete lus. Les statuts CONFIRME et CHANGES des lots backend ne sont connus que par la passation du 13/10.
- Les ledgers PROD et STAGING n'ont pas ete relus (appels distants interdits) ; ils sont rapportes par les documents de la branche ccr (09/10 et 23/09). L'etat PROD apres le 10/10 est inconnu.
- Les PR n'ont pas ete lues dans leur diff : seules leurs descriptions, tailles et, pour #29 et #17, listes de fichiers. Les affirmations de validation (CI, STAGING) sont celles de leurs auteurs.
- Le clone est superficiel : les distances entre branches ne sont pas fiables.
- Les nombres de controles SQL declares (34, 39, 15, 9, 10, 9) n'ont pas ete recomptes ; seul le total de 15 notices `OK` de `scenarios_etape5.sql` a ete dénombre.
- Le contenu complet du prompt de mission (lignes 175 a 430) et du document maitre (hors addenda et grep) n'a pas ete relu : les controles de la lettre A (securite) ont ete appliques, les lettres B a H seulement sur ce qui touche le tableau.
- Deploiement Vercel, bundle servi et marqueurs `gitDirty` : non verifies.
- Les affirmations de securite du script SEC-PROD (PR #22) sont celles de Codex et n'ont pas ete revalidees.
- Aucun secret, identifiant d'utilisateur reel ou document d'identite n'est reproduit dans ce registre. Les identifiants de projets Supabase et de feuille cites dans les sources ont ete volontairement omis ou limites a des references de section.
