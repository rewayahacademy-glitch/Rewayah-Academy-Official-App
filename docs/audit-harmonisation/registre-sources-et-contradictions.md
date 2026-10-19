# Registre de conformite - Sources et contradictions

- SHA audite : `4a7aa2b` (branche `claude/nice-darwin-hael93`, identique a `origin/main` pour le code ; le HEAD local `ff01c087` n'ajoute que les registres de `docs/audit-harmonisation/`)
- Date de l'audit : 14/10/2026 (redige le 15/10/2026)
- Auditeur : Claude (agent d'audit, lecture seule)
- Domaine : registre des sources, hierarchie d'autorite et registre des contradictions (document maitre, addenda sections 26, 33.1 et 33.3)
- Aucun test execute : Flutter et Dart ne sont pas installes. Toute mention de test est "test lu, non execute".

## 1. Perimetre, sources lues, sources introuvables

### 1.1 Constat structurant

Le SHA audite `4a7aa2b` est date du 22/09/2026 (`git log -1 --format=%cs 4a7aa2b`). La branche d'integration `origin/ccr-1b1bfa0b-m1kvkk` (tete `d5e45ec8`, 12/10/2026) le contient comme ancetre direct : `git merge-base 4a7aa2b origin/ccr-1b1bfa0b-m1kvkk` = `4a7aa2be`, avec 1 754 commits sur ccr absents du HEAD et 0 commit du HEAD absent de ccr. `git diff --stat` entre les deux : 7 113 fichiers, 629 821 insertions.

Consequence : toutes les sources de niveau 3 de la hierarchie (master lignes 834-848 : `00_LIRE_D_ABORD.md`, decisions de direction actives, gouvernance de design, `COHABITATION.md`) sont absentes du HEAD audite. Sur ccr, la remise a plat du 23/09 (commit `4e9903ca`) archive dans `docs/archive/2026-09-pre-remise-a-plat/` les documents que le `CLAUDE.md` du HEAD designe comme actifs (HANDOFF, PROGRESS, decisions.md, Bible V2, design/*). Le CLAUDE.md de ccr dit : "une regle archivee qui contredit `docs/current/` est caduque". Toutes les PR Codex (#10 a #35 sauf #8 et #7) ont ccr pour base.

L'audit sur `4a7aa2b` mesure donc une version anterieure de trois semaines a la branche ou le travail a continue. C'est l'ecart CTR-SRC-01 et la contre-proposition CP-SRC-01.

### 1.2 Registre des sources

Legende statut d'autorite : active, remplacee, historique, introuvable. "ccr" = `origin/ccr-1b1bfa0b-m1kvkk` a `d5e45ec8`.

| Source nommee (master l.747-770 et l.850-867) | Chemin trouve | Date (dernier commit) | Domaine d'autorite | Disponible sur HEAD | Statut d'autorite | Notes |
|---|---|---|---|---|---|---|
| `CLAUDE.md` racine | `CLAUDE.md` (HEAD) ; `CLAUDE.md` (ccr) | HEAD 20/09 ; ccr 12/10 | Ordre de lecture, regles transverses | oui | HEAD : remplacee par la version ccr ; ccr : active | Les deux versions designent des ensembles de documents actifs differents (CTR-SRC-02) |
| `docs/current/00_LIRE_D_ABORD.md` | ccr `docs/current/00_LIRE_D_ABORD.md` | 23/09 | Autorite, invariants, contradictions resolues | non | active (sur ccr) | Lu en entier via GitHub (5 110 octets) |
| `docs/orchestration/COHABITATION.md` | ccr `docs/orchestration/COHABITATION.md` | 09/10 | Frontiere Claude (ecrans) / Codex (backend), branches, staging | non | active (sur ccr) | Lu en entier. Fait foi sur la feuille de liaison Google Sheets (non lue, MCP Google interdit) |
| `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` | ccr `docs/current/` | 24/09 | Decisions datees, gate C0 | non | active (sur ccr) | Non lu en entier (24 Ko), cite par 00 et CLAUDE.md ccr |
| `01_PRODUIT_ET_PARCOURS.md` | ccr `docs/current/` | 23/09 | Produit, roles, parcours | non | active (sur ccr) | Non lu |
| `02_ARCHITECTURE_ET_SECURITE.md` | ccr `docs/current/` | 23/09 | Schema, RLS, RPC, LiveKit, R2 | non | active (sur ccr) | Non lu |
| `03_DESIGN_SYSTEM_ET_UX.md` | ccr `docs/current/` | 10/10 | Charte UX/UI condensee, etats, hors ligne | non | active (sur ccr) | Lu en entier ; remplace la Bible V2 comme reference operationnelle |
| `04_EXECUTION_GIT_CI_ET_MIGRATION.md` | ccr `docs/current/` | 23/09 | Branches, CI, migration | non | active (sur ccr) | Non lu |
| `05_PROMPT_AGENT_INTEGRATEUR.md` | ccr `docs/archive/2026-09-pre-remise-a-plat/racine/` | 23/09 | Prompt integrateur | non | historique (archive) | Repris en annexe 06 du dossier maitre de la PR #35 |
| `06_SPEC_FONCTIONNELLE_MVP.md` | ccr `docs/current/` | 11/10 | Perimetre MVP, statuts de preuve | non | active (sur ccr) | Non lu |
| `07_MEMOIRE_PEDAGOGIE_FINANCE.md` | ccr `docs/current/` | 23/09 | Pedagogie avancee, finance | non | active (sur ccr) | Non lu |
| `DECISION-OFFRES-GROUPES-2026-10-09.md` | ccr `docs/current/` | 09/10 | Offres vitrines, demandes, creation de classe | non | active (sur ccr) | Lu en entier ; "prevaut sur toute regle anterieure (00, 01, migrations 0043 et 0049)" |
| `DECISION-CLASSES-SIMULTANEES-2026-10-10.md` | ccr `docs/current/` | 10/10 | Classes paralleles, R1 a R20 | non | active (sur ccr) | Lu en entier |
| `DECISION-IMMATRICULATION-2026-10-12.md` | ccr `docs/current/` | 12/10 | Matricule RA | non | active (sur ccr) | Non lu, cite par CLAUDE.md ccr |
| `DESIGN-GOV-2026-09-26.md` | ccr `docs/current/` | 26/09 | Gouvernance design gelee | non | active (sur ccr) | Resume lu dans 03 (section "Regles gelees") |
| `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md` | introuvable sous ce nom ; HEAD `docs/design/00-bible-frontend-v2.md` ; ccr `docs/archive/2026-09-pre-remise-a-plat/design/00-bible-frontend-v2.md` | HEAD 20/09 | Contrat frontend (ADR-019) | oui (autre nom) | HEAD : active selon CLAUDE.md HEAD ; ccr : historique | Copie en annexe 09 du dossier maitre PR #35 |
| `docs/design/README.md`, `08-catalogue-ecrans.md` | HEAD `docs/design/` | 20/09 | Constitution UX, registre des ecrans | oui | HEAD : active ; ccr : historique (archive) | Le catalogue HEAD n'a aucune fiche classe en direct, dock ni bibliotheque (grep vide) |
| `docs/produit/design-tokens.md` | HEAD | 20/09 | Valeurs de jetons | oui | HEAD : active ; ccr : historique | Porte Instrument Sans / Bricolage Grotesque (l.199-243) |
| `docs/produit/parcours-utilisateurs.md` | HEAD | 20/09 | Etats metier | oui | HEAD : active ; ccr : historique | Parle de "Mode enfant" (l.129) |
| `docs/architecture/decisions.md` (ADR-001 a 031) | HEAD | 22/09 | ADR | oui | HEAD : active ; ccr : historique | Derniere ADR : 031 (22/09) |
| `docs/PROGRESS.md`, `docs/HANDOFF.md` | HEAD | 20/09 | Suivi et passation | oui | instantanes dates (derniere entree HANDOFF : 19/09, l.3) ; ccr : historique | Voir section 1.4 |
| `docs/AGENT_HANDOFF.md`, `ECART-SPEC-REALITE.md`, `MISE-EN-SERVICE.md` | HEAD `docs/` | 20/09, 20/09, 21/09 | Passation hors Claude, ecarts, mise en service | oui | historique | Instantanes |
| `CODEX.md`, `CODEX_FRONTEND_BASELINE.md` | HEAD racine | 20/09 | Consignes Codex | oui | remplacee par `COHABITATION.md` (09/10) | `CODEX_FRONTEND_BASELINE.md:50` "Cohabitation : fichiers proteges" |
| `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md`, `FABLE_ONBOARDING_CLASSES_REPORT.md` | HEAD racine | 22/09 | Contrat et rapport du lot offres vitrines (0043) | oui | historique, partiellement remplacee par DECISION-OFFRES 09/10 | Ce lot est le commit `4a7aa2b` |
| `docs/teaching-core/*`, `docs/parallel-reports/*` | HEAD | 20/09 | Rapports d'agents TC et paralleles | oui | historique | Contrats TC_CONTRACT_REQUEST_A a Q |
| `REWAYAH_REFERENTIEL_ACADEMIQUE_V1` | introuvable sous ce nom ; PR #35 `docs/current/sources-directeur-2026-10/REWAYAH_REFERENTIEL_ACADEMIQUE_CONSOLIDE_2026-10-13.md` | 14/10 (branche `claude/keen-ritchie-kdmnfc`) | Doctrine academique RA-CUR-2026.2 | non | active si PR #35 fusionnee ; contenu non relu | Non lu en detail |
| `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1` | introuvable sous ce nom | - | Teaching Core | non | introuvable | Contenu derive present : `docs/teaching-core/`, migrations 0030-0033, `lib/core/tc_*` (registre PR #35 section 7) |
| `REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md` | fichier introuvable ; contenu en annexe 15 du dossier maitre PR #35 (l.6694-7468) | 14/10 | Mandat des lots restants | non | active par recopie (PR non fusionnee) | Non lu en detail |
| `REWAYAH_RECH_02_HANDOFF_FRONT_BACK_INTEGRE_V2.md`, RECH-01, `REWAYAH_COMPLEMENT_RECHERCHE_ET_PLAN_RESTANT_V0_1.md` | introuvables | - | Recherche transverse | non | introuvable | Derives sur ccr : `docs/current/recherche/R0_MATRICE.md`, `RECETTE_RECH-REC.md`, `UX_REVIEW_RECH-2.md` (10/10). HEAD n'a pas `lib/core/recherche/` |
| `REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md` | ccr `docs/orchestration/claude-handoff/` ; PR #24 `docs/backend/blueprints/` | 09/10 | Blueprint backend | non | active cote backend | Non lu |
| `REWAYAH_PLAN_SITE_ET_CONFORMITE_2026-10-07.md` (corrige 09/10), `REWAYAH_PLAN_VISUELS_SITE_2026-10-08.md` | introuvables | - | Site public | non | introuvable | Derives PR #8 `docs/site-public/SITE_00` a `SITE_05` (08/10), anterieurs a la correction du 09/10 |
| PED du 10 et 11/10 (`PED_00_CADRAGE`, `PED_APRES`, `PED_PROGRESSION`) | `PED_00` introuvable ; ccr `docs/current/PED-APRES/PED_APRES_SPEC_VERTICALE_V1.md`, `docs/current/PED-PROGRESSION/PED_PROGRESSION_SPEC_VERTICALE_V1.md` | 11/10 | Pedagogie verticale | non | active (sur ccr) | Non lus en detail |
| `REWAYAH_PED_EVALUATIONS_SPEC_DELTA_V1_2026-10-12.md` et les cinq fichiers evaluations du 12/10 | introuvables | - | Evaluations | non | introuvable | Cites par nom dans l'annexe 15 PR #35 l.7081 |
| `04_ENSEIGNANT(1).md` | introuvable | - | Verticale enseignant | non | introuvable | Decrit dans l'annexe 15 PR #35 l.7016 comme "specification, pas attestation" |
| Maquettes tuteur (Accueil, Profil, Foyer Member, Historique, Classe Details) | introuvables (find sur HEAD vide ; SITE_00 PR #8 : "non trouvees") | - | UI tuteur | non | introuvable | Ne pas deviner leur contenu |
| `REWAYAH_ASSETS_PERSONNES_2026-10-09.zip` | introuvable | - | Site public | non | introuvable | - |
| SVG officiel du logo | ccr `assets/brand/logo/` (10/10) ; PR #8 `site-public/assets/logo-*.svg` | 10/10 | Marque | non (HEAD n'a pas `assets/brand/`) | active (sur ccr) | - |
| `REWAYAH_AUDIT_PREPRODUCTION_2026.md` | introuvable | - | Revue non fonctionnelle | non | introuvable | - |
| Feuille de suivi reelle | ccr `docs/orchestration/tableau-2026-10-09/INDEX.md` (09/10) ; Google Sheets "Liaison Claude ChatGPT" | 09/10 | Suivi | non | active (sur ccr) ; Sheets non lue | - |
| `REGISTRE-RECONCILIATION-2026-10-14.md` | PR #35 `docs/current/` | 14/10 | Reconciliation des decisions du directeur | non | active si PR #35 fusionnee | Lu en entier (172 lignes) ; source la plus recente trouvee |
| Passation Codex du 13/10 | PR #34 `docs/orchestration/PASSATION-FIN-CODEX-2026-10-13.md` | 13/10 | Etat backend | non | instantane date | Non lu |

### 1.3 Sources lues

Prompt de mission l.146-380 ; document maitre l.740-1065 ; `CLAUDE.md` HEAD et ccr ; `docs/PROGRESS.md` l.1-75 ; `docs/HANDOFF.md` par grep (l.1-770 entrees datees) ; `docs/architecture/decisions.md` titres, ADR-002, ADR-004, ADR-028, registre l.1802-1847 ; `00_LIRE_D_ABORD.md`, `COHABITATION.md`, `03_DESIGN_SYSTEM_ET_UX.md`, `DECISION-OFFRES-GROUPES-2026-10-09.md`, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md` (ccr, via GitHub) ; `REGISTRE-RECONCILIATION-2026-10-14.md` (PR #35) ; `docs/site-public/SITE_00_ETAT_ET_CONFLITS.md` (PR #8) ; migrations 0004, 0010, 0033, 0034, 0036, 0043 par plages ; `lib/core/theme/app_typography.dart` l.10-45 ; `lib/core/video/pre_vol.dart` l.7-22 ; `assets/i18n/fr.i18n.json` l.30 et l.180.

### 1.4 Affirmations de livraison datees (instantanes, non preuves du HEAD)

| Affirmation | Emplacement | Date | Classement |
|---|---|---|---|
| "Les etapes 3 et 4 sont terminees, la refonte UX/UI aussi" | `docs/PROGRESS.md:13` | 11-12/09 | instantane date |
| "ENS-05 ... construit localement ... les 729 tests Flutter sont verts ... verifier_jetons vert sur 123 fichiers ... build web 4 418 221 octets" | `docs/PROGRESS.md:32-38`, `docs/HANDOFF.md:2539` | non date, worktree `cbc4ff8` hors depot | instantane, mesure sur un autre SHA |
| "Le verificateur de jetons reste rouge ... six violations" | `docs/PROGRESS.md:37`, `:193` | 19-20/09 | instantane |
| "11 violations, toutes pre-existantes" / "10 violations" | `docs/HANDOFF.md:47`, `:89`, `:291` | 19/09 | instantane, chiffres divergents entre entrees |
| "34 entrees sur 34 se verifient sur la base reelle" | `docs/PROGRESS.md:66`, `docs/HANDOFF.md:678` | 12/09 | instantane sur base distante |
| "`TUT-00` EST EN PRODUCTION" | `docs/HANDOFF.md:168` | 19/09 | instantane |
| "`N2`, `N3`, `N4`, `N5`, `CTR-01`, `TUT-06` est fait" | `docs/HANDOFF.md:297-580` | 12-13/09 | instantanes |
| "0035, 0036, 0037 ne sont PAS appliquees en production" | `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md:1-20` | 21/09 | instantane ; etat actuel de PROD non verifie |
| "Navigation tuteur conforme sur ccr", "polices conformes sur ccr" | PR #35 registre l.86 et section 7 | 14/10 | affirmation sur une autre branche, non verifiee ici sauf polices (voir AUD-SRC-027) |

## 2. Registre par exigence

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-SRC-001 | L'audit porte sur la branche reellement active et ses sources de niveau 3 (master l.834-848, l.888-890) | Tous | Branche Git | CONTRADICTOIRE | `git merge-base 4a7aa2b origin/ccr-1b1bfa0b-m1kvkk` = `4a7aa2be` ; 1 754 commits ccr absents du HEAD ; HEAD date 22/09 | Designer la branche cible (ccr ou successeur) et rejouer l'audit sur son SHA | P0 | gouvernance | aucune tache existante trouvee (PR #2 C0 ouverte sur main) |
| AUD-SRC-002 | `docs/current/00_LIRE_D_ABORD.md` disponible dans la branche auditee (master l.840, l.857) | Tous | Contrat documentaire | BLOQUÉ_DÉPENDANCE | absent du HEAD (`git ls-tree` vide) ; present ccr `d5e45ec8` (23/09) | Depend de AUD-SRC-001 | P0 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-003 | `COHABITATION.md` disponible et applique (master l.840) | Claude, Codex | `docs/orchestration/` | BLOQUÉ_DÉPENDANCE | absent du HEAD ; ccr `docs/orchestration/COHABITATION.md` (09/10) | Depend de AUD-SRC-001 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-004 | Decisions datees `08_DECISIONS...2026-09-23.md` accessibles (master l.756, l.857) | Tous | `docs/current/` | BLOQUÉ_DÉPENDANCE | absent du HEAD ; ccr (24/09) | Depend de AUD-SRC-001 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-005 | `01`, `02`, `04`, `06`, `07` de `docs/current/` disponibles (master l.857) | Tous | `docs/current/` | BLOQUÉ_DÉPENDANCE | absents du HEAD ; ccr (23/09 a 11/10) | Depend de AUD-SRC-001 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-006 | `05_PROMPT_AGENT_INTEGRATEUR.md` (master l.857) | Agent integrateur | archive | NON_APPLICABLE_JUSTIFIÉ | ccr `docs/archive/2026-09-pre-remise-a-plat/racine/05_PROMPT_AGENT_INTEGRATEUR.md` ; remplace par `09_PROMPT_REPRISE_VERTICALE.md` (CLAUDE.md ccr) | Aucun | - | gouvernance | - |
| AUD-SRC-007 | `DECISION-OFFRES-GROUPES-2026-10-09.md` disponible (master l.756) | Famille, admin | Offres vitrines, demandes | BLOQUÉ_DÉPENDANCE | absent du HEAD ; ccr (09/10) | Depend de AUD-SRC-001 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-008 | `DECISION-CLASSES-SIMULTANEES-2026-10-10.md` disponible (master l.756) | Admin, famille, enseignant | Classes paralleles | BLOQUÉ_DÉPENDANCE | absent du HEAD ; ccr (10/10) | Depend de AUD-SRC-001 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-009 | Bible UI/UX V2 et tokens du theme reel identifies comme source active (master l.856) | Tous ecrans | `docs/design/00-bible-frontend-v2.md` | CONTRADICTOIRE | HEAD `CLAUDE.md` tableau "Tout ecran" pointe la Bible V2 ; ccr `CLAUDE.md` : Bible archivee, "une regle archivee qui contredit docs/current est caduque" | Un seul point d'entree design sur la branche cible | P1 | gouvernance | HU-1 (cite par 03 ccr), non retrouvee sur HEAD |
| AUD-SRC-010 | Referentiel academique actif identifie (master l.857, l.1003-1013) | Enseignant, eleve | Contenu academique | BLOQUÉ_DÉPENDANCE | introuvable sur HEAD et ccr ; PR #35 (non fusionnee) `REWAYAH_REFERENTIEL_ACADEMIQUE_CONSOLIDE_2026-10-13.md` | Fusion de PR #35 ou depot de la source | P1 | contenu academique | PED-INTEGR-UX, PED-SUPPORTS (registre PR #35 section 9, non sur HEAD) |
| AUD-SRC-011 | `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1` (master l.857) | Salle | Teaching Core | CONFORME_PARTIEL | fichier introuvable ; contenu derive present : `docs/teaching-core/TC_TEST_PLAN.md`, migrations `0030` a `0033`, `lib/core/tc_*` (HEAD) | Deposer la source pour tracer la provenance | P2 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-012 | `REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md` (master l.858) | Tous | Mandat | BLOQUÉ_DÉPENDANCE | introuvable ; recopie en annexe 15 du dossier maitre PR #35 l.6694 | Fusion PR #35 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-013 | RECH-02, RECH-01 et complement recherche (master l.859, l.947-969) | Tous | Recherche transverse | ABSENT | introuvables sur HEAD, ccr, PR #35 ; HEAD n'a pas `lib/core/recherche/` ; ccr a `docs/current/recherche/R0_MATRICE.md` (10/10) | Deposer RECH-02 ; SEC-R01 a R22 et REC-01 a REC-14 non verifiables sans elle | P1 | gouvernance | R0 (matrice ccr, nom de fichier) |
| AUD-SRC-014 | Blueprint BR-0B V0.2 (master l.765) | Backend | Contrats serveur | BLOQUÉ_DÉPENDANCE | absent du HEAD ; ccr `docs/orchestration/claude-handoff/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md` ; PR #24 | Depend de AUD-SRC-001 | P2 | backend | BR-0B (PR #24) |
| AUD-SRC-015 | Plans site corriges du 09/10 (master l.860-861) | Visiteur | Site public | ABSENT | introuvables ; PR #8 `docs/site-public/SITE_00_ETAT_ET_CONFLITS.md` date du 08/10 | Deposer les plans du 09/10 avant audit du site | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-016 | Specs PED du 10 et 11/10 (master l.759-761, l.862) | Enseignant, famille | Pedagogie | BLOQUÉ_DÉPENDANCE | `PED_00` introuvable ; `PED_APRES` et `PED_PROGRESSION` sur ccr (11/10), absents du HEAD | Depend de AUD-SRC-001 ; deposer `PED_00` | P1 | contenu academique | PED-APRES, PED-PROGRESSION (dossiers ccr) |
| AUD-SRC-017 | Cinq sources evaluations du 12/10 et delta PED (master l.762-763, l.863) | Enseignant, evaluateur | Evaluations | ABSENT | introuvables ; cites par nom seulement (annexe 15 PR #35 l.7081) | Deposer les sources | P1 | contenu academique | aucune tache existante trouvee |
| AUD-SRC-018 | Verticale `04_ENSEIGNANT(1).md` du 12/10 (master l.764, l.864) | Enseignant | Ecrans ENS-01 a ENS-13 | ABSENT | introuvable ; decrite annexe 15 PR #35 l.7016 | Deposer la source | P1 | gouvernance | ENS-xx (HANDOFF HEAD, anterieurs) |
| AUD-SRC-019 | Maquettes tuteur fournies par la direction (master l.865) | Tuteur | Accueil, Profil, Foyer, Historique, Classe | ABSENT | `find -iname "*foyer member*"` vide ; SITE_00 PR #8 : "n'ont pas ete trouvees" | Deposer les images dans le depot | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-020 | Pack `REWAYAH_ASSETS_PERSONNES_2026-10-09.zip` (master l.866) | Visiteur | Site public | ABSENT | introuvable HEAD, ccr, PR #8 | Deposer le pack | P2 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-021 | SVG officiel du logo (master l.866, l.990) | Tous | Marque | BLOQUÉ_DÉPENDANCE | HEAD : pas de `assets/brand/` ; ccr `assets/brand/logo/` (10/10) ; PR #8 `site-public/assets/logo-horizontal.svg` | Depend de AUD-SRC-001 | P2 | frontend | aucune tache existante trouvee |
| AUD-SRC-022 | `REWAYAH_AUDIT_PREPRODUCTION_2026.md` (master l.767) | - | Revue non fonctionnelle | ABSENT | introuvable | Deposer ou retirer de la liste | P2 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-023 | Ordre de lecture unique pour l'agent (master l.838-848) | Agents | `CLAUDE.md` | CONTRADICTOIRE | HEAD `CLAUDE.md` : HANDOFF puis PROGRESS puis decisions.md ; ccr `CLAUDE.md` : `docs/current/00` puis `08`, archive caduque | Aligner le CLAUDE.md de la branche cible | P1 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-024 | Statuts anterieurs traites comme instantanes dates (master l.785, l.902-904) | Audit | PROGRESS, HANDOFF | CONFORME_PARTIEL | Les affirmations de la section 1.4 sont dates ; aucune n'est mesuree sur `4a7aa2b` (729 tests mesures sur `cbc4ff8`, `docs/PROGRESS.md:35`) | Ne pas reprendre ces chiffres comme preuve | P2 | gouvernance | - |
| AUD-SRC-025 | Commandes de verification a jour (CLAUDE.md "Verifier avant de dire que c'est fait") | Agents | CI, scenarios SQL | CONTRADICTOIRE | `CLAUDE.md` HEAD : "0001 puis 0002 a 0005", "34 controles", "37 controles" ; `ls supabase/migrations/*.sql` = 42 fichiers SQL | Lister la sequence reelle ou pointer le workflow CI | P2 | gouvernance | aucune tache existante trouvee |
| AUD-SRC-026 | Hierarchie : une decision de securite n'est pas invalidee par une preference (master l.836) | Tous | - | CONFORME_PARTIEL | Les decisions de securite lues (RLS, `search_path = ''`, revoke anon) sont identiques dans `CLAUDE.md` HEAD et `COHABITATION.md` section 6 | Aucun pour la regle ; voir AUD-SRC-036 pour l'application | - | gouvernance | - |
| AUD-SRC-027 | DM Sans titres, Plus Jakarta Sans texte (master l.1003-1005 ; PR #35 registre section 8 bis) | Tous ecrans | `lib/core/theme/app_typography.dart` | CONTRADICTOIRE | `app_typography.dart:22` `corps = 'InstrumentSans'`, `:25` `titre = 'BricolageGrotesque'` ; `pubspec.yaml:96-115` ; `docs/produit/design-tokens.md:199-243`. ccr : `pubspec.yaml:138` PlusJakartaSans, `:150` DMSans | Resolu par hierarchie en faveur de DM Sans / Plus Jakarta (deja sur ccr) ; HEAD perime | P1 | frontend | P0-05 (ccr `tableau-2026-10-09/INDEX.md:603`) |
| AUD-SRC-028 | "Interface guidee" remplace "mode enfant" (master l.918 ; 00 ccr) | Eleve enfant, adulte | Libelles, docs | CONTRADICTOIRE | 50 occurrences "mode enfant/modeEnfant" dans `lib/**/*.dart` contre 10 "interface guid" ; `docs/produit/parcours-utilisateurs.md:129` "Mode enfant" ; `decisions.md:592` | Vocabulaire visible a aligner ; identifiants internes peuvent rester | P2 | frontend | ALIGN-1410-FRONT (PR #35, non sur HEAD) |
| AUD-SRC-029 | Observation tuteur 2 visites de 120 s, visite interrompue consommee, serveur fait foi (master l.925) | Tuteur | `budget_observation`, `app_config` | IMPLÉMENTÉ_NON_PROUVÉ | `0036_observation...sql:17-19` (2 / 120 / 240), `:191-193`, `:243` ; `LISEZ-MOI-0035-0037-non-appliquees.md` : non appliquee en PROD au 21/09 | Preuve d'application en PROD et scenario SQL nomme | P1 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-030 | Ne pas annoncer un enregistrement reel sans captation active (master l.926) | Tous en salle | `PermanentNotice`, i18n | CONTRADICTOIRE | `assets/i18n/fr.i18n.json:30` "Cours enregistre, visite de controle possible." affiche par `lib/core/widgets/permanent_notice.dart:61` ; `:180` "Chaque cours est enregistre en audio, conserve trente jours" ; `0034_r2_stockage.sql:16-19` "AUCUN producteur ne l'alimente" ; aucun `startRoomCompositeEgress` dans `supabase/functions` | Conditionner ou retirer la mention tant que la captation n'existe pas | P1 | frontend (texte) et gouvernance (ADR-002) | ALIGN-1410-FRONT (PR #35) |
| AUD-SRC-031 | Capacites issues de la decision active : enfant 5, adulte 6, debutants 4, minimum d'ouverture 4 (master l.914 ; PR #35 registre section 3) | Admin, famille | `app_config` | CONFORME_PARTIEL | `0043...sql:532-534` capacite enfant 5, adulte 6, `minimum_lancement` 3 ; aucune capacite "debutant" | Minimum 3 contre 4 ; capacite debutant absente | P1 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-032 | Duree enfant 60 min avec pause 5 min, adulte 90 min (PR #35 registre section 3) | Famille, enseignant | `app_config` | CONFORME_PARTIEL | `0043...sql:538` `pause_minutes_enfant` 6 | Pause 6 contre 5 ; reglage | P2 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-033 | Cohortes 6-9, 10-13, 14-17, 18+ et age minimum 6 (PR #35 registre section 3) | Famille | `0043` cohortes | CONTRADICTOIRE | `0043...sql:108-109` coupure 8-10 / 11-14 calee sur `child_ui_mode_max_age` 10 | Correction par donnees (registre : "par update, sans migration") | P1 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-034 | Classes stables precreees, la famille choisit parmi les horaires publies, pas de matching individuel (master l.910-914) | Famille, enseignant, admin | `/enseignant/creneaux`, `lib/core/matching/` | CONTRADICTOIRE | `routes.dart:112` `enseignantCreneaux` ; `lib/core/matching/service_matching.dart:8-11` "une ligne par creneau compatible" (ENS-06, l'enseignant prend un eleve) ; ADR-031 (22/09) offre vitrine | Statuer si ENS-06 reste une exception ou est retire du parcours courant | P1 | contrat partage | ADM-05, ENS-06 (HANDOFF HEAD) |
| AUD-SRC-035 | Regroupement des demandes et bouton "Creer la classe" (DECISION-OFFRES 09/10 section 3) | Admin | file des regroupements | ABSENT | grep "Creer la classe" et "regroupement" sans resultat d'ecran sur HEAD (decision posterieure au SHA) | Non demontre sur ccr dans cet audit | P1 | contrat partage | F1 (PR #13, #29) |
| AUD-SRC-036 | Le controleur n'accede pas aux pieces d'identite (registre PR #35 section 7, spec 12/10 section 04.3) | Controleur | `read_kyc_documents()`, policy storage `kyc_lecture_admin` | CONTRADICTOIRE | `0004_inscription_kyc_appairage.sql:186-187` `app_role() not in ('admin', 'controller')` ; `:1013-1016` `bucket_id = 'kyc' and app_role() in ('admin', 'controller')` ; non corrige sur ccr (`0044...sql:259` garde identique) | Retirer `controller` des deux gardes | P0 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-037 | Une decision de dossier ne s'ecrase pas en silence (annexe 11 : `already_decided`, `stale_dossier`) | Admin | `decider_dossier()` | CONTRADICTOIRE | `0004...sql:550-556` `update public.kyc_documents ... where id = p_document_id` sans filtre de statut ; aucune autre definition sur HEAD | Garde positive `status = 'pending'` et version attendue | P1 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-038 | Durcissements serveur posterieurs presents dans la branche auditee | Tous | migrations | CONTRADICTOIRE | HEAD : 0001 a 0038 puis 0043 ; ccr ajoute 0039-0042 et 0044-0048 dont `0044_securiser_rpc_admin_et_kyc.sql`, `0048_revoke_public_volatile_function_execute.sql` | Auditer sur la branche portant ces migrations | P0 | backend | B-13 (PR #23, #27, #31), SEC-PROD (PR #22) |
| AUD-SRC-039 | Fenetre d'entree unique T-20, reglage serveur (registre PR #35 section 8 bis) | Eleve, enseignant | `autoriser_jeton_video`, `pre_vol.dart` | CONTRADICTOIRE | serveur : `0033_tc_vues_rpc.sql:1663` `join_window_minutes` defaut 20, `0030_tc_socle.sql:34` = 20 ; client : `lib/core/video/pre_vol.dart:22` `seuilOuvertureSalle = Duration(minutes: 10)` ; `decisions.md:176` ADR-005 "T-10" | Le client lit la valeur serveur au lieu d'une constante | P1 | frontend | ALIGN-1410-FRONT (PR #35) |
| AUD-SRC-040 | Delai apres la fin : un seul reglage, 15 min (registre PR #35 section 8 bis) | Tous | `grace_after_end_minutes` | CONFORME_PARTIEL | `0033...sql:1664` grace defaut 15 ; `0012...sql:334`, `:428` 15 min en dur ; ADR-005 `decisions.md:176` dit 10 | Doc ADR a marquer remplacee ; valeurs en dur dans 0012 | P2 | backend | aucune tache existante trouvee |
| AUD-SRC-041 | Photo publique d'enseignant distincte du KYC (master l.920 ; registre PR #35 "obligatoire") | Famille, enseignant | profil enseignant | CONTRADICTOIRE | `decisions.md:1809` question 2 "Resolue par la negative ... jamais de photo" | Marquer la question 2 remplacee ; contrat photo a poser | P1 | contrat partage | ENS-05 (ADR-027) |
| AUD-SRC-042 | Seuil Interface guidee : par defaut tranche 6-9, choix possible apres 10 ans (registre PR #35 section 8 bis) | Eleve enfant | `child_ui_mode_max_age` | CONTRADICTOIRE | `decisions.md:1812` question 5 : vaut 8 ; `0043...sql:108` : valait 10 le 22/09 | Un seul reglage, valeur alignee | P2 | backend | ALIGN-1410-BACK (PR #35) |
| AUD-SRC-043 | Grille publique 50/60 USD, remises rang 3 = 5, rang 4+ = 7, calcul centralise (master l.1002-1013) | Famille, visiteur | politique tarifaire, simulateur | ABSENT | aucun montant 5000/6000/4500/5500 hors demo dans `lib` et `supabase/migrations` (HEAD) ; ccr : montants seulement dans `lib/features/demo/comptable/` ; PR #8 : aucun montant dans `pages.json` | Source tarifaire unique cote serveur avant tout simulateur | P1 | contrat partage | aucune tache existante trouvee (finance "hors perimetre tant que la direction ne l'ouvre pas", registre PR #35 section 6) |
| AUD-SRC-044 | Simulateur "Simuler mon tarif" / "Estimez le tarif de votre foyer" (master l.1017-1036) | Visiteur | site public | ABSENT | `git grep -i "simuler mon tarif"` vide sur HEAD et ccr | Depend de AUD-SRC-043 | P1 | frontend | aucune tache existante trouvee |
| AUD-SRC-045 | Fond sombre du site exactement `#1A1A25`, sans degrade (master l.987) | Visiteur | `site-public/styles/site.css` (PR #8) | CONTRADICTOIRE | PR #8 `site.css:55-56` `--site-canvas: #111014`, `--site-surface: #1a181f` ; SITE_00 l."CONFLIT A7" | Source du 09/10 introuvable (AUD-SRC-015) | P2 | frontend | aucune tache existante trouvee |
| AUD-SRC-046 | Tout ecran implemente figure au catalogue (CLAUDE.md HEAD, ADR-018) | Salle | `docs/design/08-catalogue-ecrans.md` | CONTRADICTOIRE | `grep -i "biblioth\|classe live\|tc_dock\|tc_classe"` vide dans le catalogue ; ecrans presents : `lib/features/tc_classe_live/`, `lib/features/tc_dock/` | Fiches a ajouter (ou catalogue de ccr) | P1 | frontend | aucune tache existante trouvee |
| AUD-SRC-047 | Remplacement d'ADR-004 par ADR-028 trace (master l.914) | Tous | `decisions.md` | CONFORME_PROUVÉ | `decisions.md:150-154` bandeau "remplacee par ADR-028" ; `decisions.md:1538-1540` tableau de remplacement | Aucun | - | gouvernance | - |
| AUD-SRC-048 | Frontiere Claude/Codex : Claude ne cree pas de migration (COHABITATION section 2) | Claude | `supabase/migrations/0043` | NON_APPLICABLE_JUSTIFIÉ | `0043` est livree par `4a7aa2b` le 22/09, avant la regle du 09/10 | Aucun | - | gouvernance | K-19 (COHABITATION ccr) |
| AUD-SRC-049 | Feuille de liaison Google Sheets lue (COHABITATION l.7-9) | Claude, Codex | Sheets | IMPLÉMENTÉ_NON_PROUVÉ | URL citee dans `COHABITATION.md` ; non lue (MCP Google interdit par la mission) | Lecture a faire hors de cet audit | P2 | gouvernance | B-00 (COHABITATION section 4) |
| AUD-SRC-050 | Une seule source de reconciliation la plus recente versionnee (master l.902-904) | Tous | `REGISTRE-RECONCILIATION-2026-10-14.md` | BLOQUÉ_DÉPENDANCE | PR #35 draft non fusionnee, base ccr | Fusion de PR #35 sur la branche cible | P1 | gouvernance | PED-INTEGR-UX, ALIGN-1410-FRONT, ALIGN-1410-BACK (PR #35 section 9) |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Perimetre | Decision la plus recente applicable | Statut | Consequence |
|---|---|---|---|---|---|---|
| CTR-SRC-01 | `CLAUDE.md` HEAD (20/09) : HANDOFF, PROGRESS, decisions.md, Bible V2 actifs | `CLAUDE.md` ccr (12/10) et `00_LIRE_D_ABORD.md` (23/09) : seuls `docs/current/` actifs, archive caduque | Gouvernance documentaire entiere | ccr, niveau 3 de la hierarchie, et plus recente | ouvert (choix de la branche cible a confirmer par le directeur) | Tout audit sur `4a7aa2b` compare le code a des documents archives ailleurs |
| CTR-SRC-02 | ADR-002 (`decisions.md:71-100`) : audio systematique, indicateur permanent | Decision du 12/10 (registre PR #35 section 5 et 8 bis) : pas de mention sans captation reelle ; 14/10 : revision par lecture preenregistree | Enregistrement, texte de salle | 12/10 et 14/10 (directeur) | resolu en faveur du 12/10 ; code HEAD non aligne (`fr.i18n.json:30`) | Une famille lit "Cours enregistre" alors qu'aucune captation n'existe |
| CTR-SRC-03 | ADR-028 (`decisions.md:1530-1540`) : 5 enfants / 6 adultes | `00_LIRE_D_ABORD.md` (23/09) : ne pas presumer avant arbitrage (5/60 contre 4/45) | Capacites | DECISION-OFFRES 09/10 (5 enfants, 6 adultes, lus dans `app_config`) puis registre PR #35 (debutants 4, minimum 4) | resolu ; code partiel (AUD-SRC-031) | Minimum d'ouverture 3 sur HEAD |
| CTR-SRC-04 | ADR-031 (22/09) : "Rewayah vend une offre horaire vitrine, pas une classe" | Master l.910-914 : Classes stables precreees ; `00` : "le tuteur choisit parmi les classes proposees" | Inscription | DECISION-OFFRES 09/10 : vitrines sans enseignant, demandes, regroupement, "Creer la classe" | resolu (les deux se concilient : vitrine en amont, classe stable en aval) | Ecrans de regroupement non presents sur HEAD |
| CTR-SRC-05 | `docs/produit/design-tokens.md` et `app_typography.dart` HEAD : Instrument Sans / Bricolage Grotesque | Master l.1003 ; V3 30/09 ; P0-05 24/09 : DM Sans / Plus Jakarta Sans | Typographie | DM Sans / Plus Jakarta Sans | resolu ; HEAD obsolete | Toute capture prise sur `4a7aa2b` est hors charte |
| CTR-SRC-06 | `decisions.md:1812` (question 5) et `parcours-utilisateurs.md:129` : "mode enfant", seuil 8 | `00` (23/09), master l.918 : "Interface guidee", y compris adultes ; registre 14/10 : defaut 6-9 | Vocabulaire et seuil | registre PR #35 section 8 bis (14/10) | resolu ; code et docs HEAD non alignes | Libelles visibles a reprendre |
| CTR-SRC-07 | ADR-005 (`decisions.md:176`) et `pre_vol.dart:22` : T-10 | `0030_tc_socle.sql:34` et `0033:1663` : T-20 ; registre 14/10 : T-20 unique | Fenetre d'entree | T-20, reglage serveur | resolu ; client HEAD en contradiction avec son propre serveur | L'ecran peut refuser entre T-20 et T-10 ce que le serveur autorise (non demontre a l'execution) |
| CTR-SRC-08 | `decisions.md:1809` question 2 : jamais de photo d'enseignant | Master l.920 et registre 14/10 : photo publique obligatoire, distincte du KYC | Profil enseignant | registre PR #35 | resolu ; doc HEAD non mise a jour | Risque de reintroduire l'interdiction |
| CTR-SRC-09 | `0004...sql:186-187`, `:1016` : controleur lit les pieces KYC | Annexe 11 et spec 12/10 section 04.3 : interdit | Securite KYC | 12/10 | resolu sur le principe ; code HEAD et ccr non corriges | Alerte securite SEC-SRC-01 |
| CTR-SRC-10 | `0043...sql:534` `minimum_lancement` 3, `:108-109` cohortes 8-10 / 11-14 | Registre PR #35 section 3 : minimum 4, cohortes 6-9 / 10-13 / 14-17 / 18+, age minimum 6 | Classes, ages | 29/09 et 13/10 (directeur) | resolu ; donnees HEAD a corriger | Classes ouvertes sous le minimum decide |
| CTR-SRC-11 | `00_LIRE_D_ABORD.md` : disponibilites servent a proposer des options, pas au matching | HEAD `lib/core/matching/service_matching.dart`, route `/enseignant/creneaux` (ENS-06), ADR-021 | Affectation | `00` (23/09) et DECISION-OFFRES (09/10) | ouvert : aucune source ne dit si ENS-06 reste une exception admise | Deux voies d'affectation concurrentes |
| CTR-SRC-12 | Master l.987 : fond site `#1A1A25` | PR #8 `site.css:55-56` : `#111014` / `#1a181f` ; SITE_00 : conflit A7 note | Site public | plan visuels du 09/10 (introuvable) | ouvert faute de source | Ne pas corriger sans la source |
| CTR-SRC-13 | `CLAUDE.md` HEAD : sequence 0001 a 0005, 34 et 37 controles | `supabase/migrations/` HEAD : 42 fichiers SQL | Procedure de verification | etat du depot | obsolete | Un agent rejoue une recette incomplete |
| CTR-SRC-14 | `docs/HANDOFF.md:47` : 11 violations ; `:291` : 10 ; `PROGRESS.md:37` : 6 | entre elles | Verificateur de jetons | aucune ; instantanes | obsolete | Aucun chiffre utilisable comme preuve du HEAD |

## 4. Devoir de regard - contre-propositions

### CP-SRC-01 - Auditer et livrer sur une seule branche de reference

1. Identifiant : CP-SRC-01.
2. Source : AUD-SRC-001, CTR-SRC-01.
3. Constat : `4a7aa2b` (22/09) est l'ancetre de ccr `d5e45ec8` (12/10), 1 754 commits d'ecart ; toutes les PR Codex visent ccr ; les registres d'audit du 14/10 visent main.
4. Risque : fiabilite et gouvernance ; des ecarts deja corriges sur ccr sont signales, des regressions de ccr ne sont pas vues.
5. Gravite et priorite : elevee, vraisemblance certaine, P0.
6. Regle actuelle : master l.840 ("presents dans la branche reellement auditee") et l.888 ("rafraichir la branche, le SHA").
7. Contre-proposition : figer la branche cible de l'audit a la tete courante de `ccr-1b1bfa0b-m1kvkk` (ou de la branche qui l'a remplacee), rejouer les registres de domaine sur ce SHA en reprenant les lignes deja etablies ici, et noter dans chaque registre le SHA cible.
8. Options : (a) auditer ccr ; (b) fusionner ccr dans main puis auditer main, ce qui declenche le deploiement (`COHABITATION.md` section 4) et exige un GO.
9. Consequences : les registres actuels restent utiles comme base ; cout : un second passage cible.
10. Perimetre : gouvernance.
11. Dependances : PR #35 (registre de reconciliation), PR #2 (C0).
12. Criteres d'acceptation : chaque registre cite le meme SHA ; ce SHA contient `docs/current/00_LIRE_D_ABORD.md`.
13. Tests et preuves : `git merge-base`, `git ls-tree` sur le SHA cible.
14. Decision requise : arbitrage du directeur (choix de branche).

### CP-SRC-02 - Retirer au controleur l'acces aux pieces d'identite

1. Identifiant : CP-SRC-02.
2. Source : AUD-SRC-036, CTR-SRC-09.
3. Constat : `0004_inscription_kyc_appairage.sql:186-187` et `:1013-1016` autorisent `controller` ; la garde est reprise a l'identique dans ccr `0044...sql:259`.
4. Risque : securite, protection des personnes (pieces d'identite d'enseignants et de tuteurs).
5. Gravite et priorite : moyenne a elevee (role interne de confiance mais exposition non necessaire), P0.
6. Regle actuelle : spec 12/10 section 04.3 et annexe 11 (relevees dans le registre PR #35 section 7) : interdit. Situation 1 : decision tranchee, implementation defectueuse.
7. Contre-proposition : migration additive qui redefinit `read_kyc_documents()` et la policy `kyc_lecture_admin` avec `app_role() = 'admin'` en garde positive.
8. Options : aucune utile.
9. Consequences : le controleur perd un acces qu'aucune decision active ne lui donne ; aucun ecran controleur sur HEAD n'a ete trouve qui depende de cette lecture (non demontre de facon exhaustive).
10. Perimetre : backend.
11. Dependances : ALIGN-1410-BACK (PR #35) ; numerotation tenue par Codex (COHABITATION section 2).
12. Criteres d'acceptation : un appel par un profil `controller` leve une exception ; la lecture storage du bucket `kyc` est refusee.
13. Tests et preuves : scenario SQL negatif sur Postgres nu, puis sur STAGING par l'API reelle.
14. Decision requise : aucune (validation technique).

### CP-SRC-03 - Garde de statut sur `decider_dossier`

1. Identifiant : CP-SRC-03.
2. Source : AUD-SRC-037.
3. Constat : `0004...sql:550-556` met a jour sans `where status = 'pending'`.
4. Risque : fiabilite et securite administrative ; deux administrateurs peuvent decider en sens contraire, la seconde decision efface la premiere (le journal garde la trace via `log_sensitive_access`).
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : annexe 11 (`already_decided`, `stale_dossier`), Situation 1.
7. Contre-proposition : ajouter `and status = 'pending'` et un parametre de version attendue ; lever `already_decided` si aucune ligne n'est touchee.
8. Options : verrou `for update` seul, moins explicite pour l'ecran.
9. Consequences : l'ecran ADM-02 doit traiter un nouveau refus.
10. Perimetre : backend puis frontend (message).
11. Dependances : ALIGN-1410-BACK.
12. Criteres d'acceptation : seconde decision refusee avec un code nomme.
13. Tests et preuves : scenario SQL a deux sessions.
14. Decision requise : aucune.

### CP-SRC-04 - Ne plus afficher "Cours enregistre" tant que la captation n'existe pas

1. Identifiant : CP-SRC-04.
2. Source : AUD-SRC-030, CTR-SRC-02.
3. Constat : `fr.i18n.json:30` affiche en permanence "Cours enregistre" (`permanent_notice.dart:61`) ; `0034_r2_stockage.sql:16-19` constate qu'aucun producteur n'alimente `session_recordings`.
4. Risque : coherence institutionnelle et juridique (information fausse aux familles, consentement mal fonde).
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : master l.926 et decision du 12/10 ; ADR-002 n'est pas applique dans les faits.
7. Contre-proposition : remplacer le texte par la seule mention "visite de controle possible" tant qu'un drapeau serveur ne confirme pas la captation de la seance ; afficher l'indicateur d'enregistrement seulement sur ce drapeau.
8. Options : retrait pur du bandeau ; rejete car la visite de controle doit rester annoncee (ADR-011).
9. Consequences : aucun impact sur la salle ; ADR-002 a marquer en attente.
10. Perimetre : frontend (texte, condition), contrat partage (drapeau), gouvernance (ADR-002).
11. Dependances : ALIGN-1410-FRONT.
12. Criteres d'acceptation : aucune chaine visible ne dit "enregistre" sans drapeau serveur vrai.
13. Tests et preuves : test de widget sur `PermanentNotice` avec drapeau faux et vrai.
14. Decision requise : validation du directeur sur la formulation.

### CP-SRC-05 - Deposer les sources introuvables dans le depot

1. Identifiant : CP-SRC-05.
2. Source : AUD-SRC-013, 015, 017, 018, 019, 020, 022.
3. Constat : RECH-02, plans site du 09/10, specs evaluations du 12/10, `04_ENSEIGNANT(1).md`, maquettes tuteur, pack d'assets, audit preproduction : absents de HEAD, ccr et PR lues.
4. Risque : fiabilite des audits ; une exigence ne peut etre ni prouvee ni refutee.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : master l.867 ("noter dans le registre des sources indisponibles, ne pas inventer").
7. Contre-proposition : etendre `docs/current/sources-directeur-2026-10/` (cree par PR #35) a ces fichiers, avec date et statut en tete.
8. Options : stockage hors depot avec lien ; moins tracable.
9. Consequences : poids du depot (images) ; les zip et PNG peuvent aller dans un dossier d'assets.
10. Perimetre : gouvernance, contenu.
11. Dependances : PR #35.
12. Criteres d'acceptation : chaque source de master l.850-866 resolue en chemin.
13. Tests et preuves : `git ls-tree` sur la branche cible.
14. Decision requise : action du directeur (fournir les fichiers).

### CP-SRC-06 - Le client lit la fenetre d'entree du serveur

1. Identifiant : CP-SRC-06.
2. Source : AUD-SRC-039, CTR-SRC-07.
3. Constat : `pre_vol.dart:22` constante 10 min ; serveur `join_window_minutes` 20 (`0030:34`, `0033:1663`).
4. Risque : fiabilite ; parcours d'entree bloque cote client alors que le serveur l'autorise (non demontre a l'execution).
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : registre 14/10 section 8 bis, T-20 reglage serveur unique.
7. Contre-proposition : supprimer la constante client et lire `join_opens_at` deja expose par les vues TC (`0033:455-456`).
8. Options : aucune.
9. Consequences : une seule valeur ; ADR-005 a marquer remplace sur ce point.
10. Perimetre : frontend.
11. Dependances : ALIGN-1410-FRONT.
12. Criteres d'acceptation : aucune constante de fenetre dans `lib/`.
13. Tests et preuves : test unitaire `pre_vol` avec `join_opens_at` a T-20.
14. Decision requise : aucune.

## 5. Etats d'ecran et applicabilite

Ce domaine est documentaire : il ne livre aucun ecran.

| Etat | Applicabilite pour ce domaine | Constat transversal releve |
|---|---|---|
| Chargement, contenu, vide, erreur, hors ligne | NON_APPLICABLE_JUSTIFIÉ (aucun ecran) | La regle des cinq etats est identique dans `CLAUDE.md` HEAD et `CLAUDE.md` ccr ; la regle "hors ligne se dit une seule fois" n'existe que sur ccr (`03_DESIGN_SYSTEM_ET_UX.md`, decision du 04/10) |
| Session expiree, acces refuse, reprise | NON_APPLICABLE_JUSTIFIÉ | Master l.1060 les exige "lorsque applicables" ; aucune source HEAD ne les liste comme obligatoires |
| Donnees revoquees, contenu supprime | NON_APPLICABLE_JUSTIFIÉ | Source : master l.1060 seulement |

## 6. Non verifie et limites de la preuve

- Aucun test Flutter ni scenario SQL execute ; aucun etat de STAGING ou PROD consulte.
- Contenus non lus : `01`, `02`, `04`, `06`, `07`, `08`, `DESIGN-GOV`, `DECISION-IMMATRICULATION`, specs PED, referentiel consolide, dossier maitre de la PR #35 (11 176 lignes, lu par grep seulement), passation Codex PR #34, blueprint BR-0B.
- La feuille Google Sheets "Liaison Claude ChatGPT" n'a pas ete lue.
- Les decisions dites "du 12/10" et "du 14/10" sont rapportees par le registre de la PR #35, non par les sources du directeur elles-memes (introuvables ou non lues).
- L'etat des PR a ete lu le 15/10 ; il peut avoir change.
- Les corrections presumees sur ccr (polices, navigation tuteur) n'ont ete verifiees que pour les polices (`pubspec.yaml` ccr l.138, l.150).
- Les branches PR ont ete recuperees par `git fetch` en references distantes uniquement ; aucune branche locale n'a ete modifiee.
