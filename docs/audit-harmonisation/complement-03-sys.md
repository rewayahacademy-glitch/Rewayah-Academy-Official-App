# Registre de conformité - Harmonisation en système : carte des objets métier et chasse aux doubles sources de vérité

- SHA audité : `4a7aa2b` (branche `claude/nice-darwin-hael93`, HEAD local `ff01c087` qui n'ajoute que des registres de `docs/audit-harmonisation/`)
- Date de l'audit : 14/10/2026
- Auditeur : Claude (agent d'audit, lecture seule)
- Domaine : SYS, harmonisation en système (document maître 01.1 à 01.4, lignes 69-104 ; 27.2, lignes 888-907 ; prompt de mission section 7, lignes 334-372)
- Aucun test exécuté : Flutter, Dart et une base Postgres ne sont pas disponibles. Toute mention de test est "test lu, non exécuté". Aucune base distante n'a été interrogée : les constats de comportement serveur sont des constats de lecture du SQL versionné.
- Méthode : ce registre ne reprend pas les lignes des autres registres. Il les cite par identifiant (AUD-OFR, AUD-ENS, AUD-SAL, AUD-FIN, AUD-IDS, CTR-SRC) et ne produit que ce qu'aucun silo ne voit : la carte producteurs / consommateurs / état faisant autorité, et les endroits où deux producteurs écrivent la même vérité ou où un consommateur lit la mauvaise.

## 1. Périmètre, sources lues, sources introuvables

### 1.1 Sources lues

- Document maître : lignes 69-104 (01.1 à 01.4) et 888-907 (27.2). Le principe unificateur (01.1) dit "un même écran ou une même fonction a un emplacement canonique par domaine". C'est la règle contre laquelle chaque ligne est mesurée.
- Prompt de mission : lignes 334-372 (section 7, harmonisation globale), dont les huit transversales à examiner et la liste de recherche (fonctions implémentées plusieurs fois, règles divergentes selon l'écran, transitions d'état incompatibles, raccourcis qui contournent une validation).
- Registres existants, lus pour ne pas les dupliquer : `offres-classes-calendrier.md` (lignes AUD-OFR-001 à 060 et CTR-OFR-12), `enseignant-pedagogie-evaluations.md` (extraits AUD-ENS-016 à 081), `salle-bibliotheque-teaching-core.md` (extraits AUD-SAL-040 à 088), `finance-admin-direction.md` (AUD-FIN-001 à 036), `identite-securite.md` (AUD-IDS-014 à 034), `registre-sources-et-contradictions.md` (en-tête et CTR-SRC-01).
- Migrations lues sur HEAD : `0001_fondations.sql` (sessions, session_participants, wallets, payouts, availability_slots, recurrence_rules, enums), `0005_dashboards_affectation_regles.sql` (teacher_student_assignments, weekly_availability, rule_overrides, prendre_eleve, materialisation 1-à-1, indicateurs), `0007_coran_structure_position_presence.sql` (presence_state, etat_presence, session_presence_override), `0014_acces_agent.sql` (mes_seances_v, mes_affectations_v, eleves_en_attente_v), `0015_administration_voit_les_personnes.sql` (indicateurs_admin), `0017_groupes_pedagogiques.sql` et `0019_groupes_durcissement.sql` (groupes, groupe_membres, retirer_eleve_groupe, cloturer_groupe), `0025_role_enseignant.sql` (sessions.groupe_id, mes_seances_enseignant_v), `0033_tc_vues_rpc.sql` (materialiser_seances_groupe, presence_seance_v, teacher_roster_v, autoriser_jeton_video, etat_presence), `0043_offres_horaires_et_intentions.sql` (offres, intentions, groupe_creneaux, app_config des offres, publier_groupe_depuis_offre).
- Code Dart : `lib/main.dart:118-132`, `lib/core/tc_groupe/port_groupes.dart`, `lib/core/tc_horloge/port_horloge_seance.dart`, les providers de `lib/core/tc_*`, `lib/core/presence/service_presence.dart`, `lib/core/suivi/service_suivi.dart`, `lib/core/tc_classe/roster_enseignant.dart`, `lib/core/planning/service_planning.dart`, `lib/features/accueil_famille/accueil_famille_page.dart`, `lib/core/domain/enums.dart`, `lib/core/session/session_state.dart`, `lib/features/dossier/signature_page.dart`, `lib/core/preferences/preferences_locales.dart`, `lib/features/compte/compte_page.dart`.
- Edge Functions : `supabase/functions/create-room-token/index.ts`.
- Tests lus, non exécutés : `supabase/tests/scenarios_n2.sql`, `scenarios_ctr01.sql`, `scenarios_adm04.sql`, `scenarios_adm05.sql`, `scenarios_etape4.sql`, `test/presence/vue_presence_test.dart`.
- Branches de PR draft lues en lecture : `origin/codex/backend-lot-f1` (migration 0055, qui réécrit `materialiser_seances_groupe`), `origin/ccr-1b1bfa0b-m1kvkk` (migration 0042 et absence de correctif de retrait de groupe).

### 1.2 Sources introuvables ou non lues

- `docs/current/*` et `docs/orchestration/COHABITATION.md` : absents de HEAD (voir CTR-SRC-01 du registre des sources). Les décisions DECISION-OFFRES-GROUPES-2026-10-09 et DECISION-CLASSES-SIMULTANEES-2026-10-10 ne sont donc connues ici que par les registres OFR.
- Le corps des PR draft #13, #21, #29, #31, #30 n'a pas été lu via l'API GitHub ; seules les branches correspondantes ont été lues par `git show` et `git grep`. Les numéros de PR cités viennent du prompt de mission.
- `docs/HANDOFF.md` (3669 lignes) : lu par grep ciblé uniquement.
- Feuille de liaison Google Sheets et toute base distante : interdits par la mission.
- Les sections du document maître hors plages 69-104, 888-907 et addenda 779-1065 : non relues ici, déjà portées par les autres registres.

## 2. Registre par exigence

### 2.1 Carte des objets métier : producteur, consommateurs, état faisant autorité

Légende de l'autorité : "unique" si une seule table ou fonction décide et que tous les consommateurs lues la suivent ; "double" si deux représentations vivent et qu'au moins un consommateur lit la mauvaise ; "démo" si le consommateur Dart n'a, à HEAD, qu'un double de démonstration.

| Objet métier | Producteur(s) à HEAD | Consommateurs lus | Autorité à HEAD | Ligne de registre |
|---|---|---|---|---|
| Compte, personne, matricule | `profiles` (hook JWT, voir AUD-IDS-023) ; matricule RA absent | `SessionState`, `ClaimsJwt`, toutes les RLS | unique pour le compte ; matricule non implanté (identifiant `immutable_id`) | SYS-001, 002 |
| Appartenance enseignant-élève | `prendre_eleve` et `attribuer_eleve` (table `teacher_student_assignments`) ; `creer_groupe`, `ajouter_eleve_groupe`, `publier_groupe_depuis_offre` (tables `groupes`, `groupe_membres`) | Accueil famille, ADM-01, ENS-06 (assignments) ; mes_groupes_v, roster, observation (groupes) | double | SYS-007 à 011 |
| Séance | `prendre_eleve`/`materialiser` 1-à-1 (0005) et `materialiser_seances_groupe` (0033) | `mes_seances_v`, `mes_seances_enseignant_v`, jeton vidéo, présence | double sur l'enseignant (`sessions.teacher_id` contre `session_participants`) | SYS-004 à 006, 012, 013 |
| Présence | `etat_presence()` dérivée de `session_events` + `session_presence_override` | trois lecteurs Dart de `presence_seance_v` | unique | SYS-016, 017 |
| Règle de durée, de pause, de plafond | `app_config`, `rule_overrides`, clés `seance.*` et `groupe.*` | `regle_brute` (1-à-1), `app_config_int` (groupes, offres), Dart `CleRegle` | triple | SYS-013 à 015 |
| Disponibilité enseignant | `weekly_availability` (utilisée) ; `availability_slots` et `recurrence_rules` (sans consommateur) | `eleves_en_attente_v`, `prendre_eleve`, écran disponibilités | double (une représentation morte) | SYS-018 |
| Niveau, progression | `student_profiles.level` (texte libre), `progression_historique` (écrite par fonctions administratives) | `teacher_roster_v`, suivi | double sur le niveau affiché | SYS-026, 027 |
| Position de lecture | `student_reading_position`, `library_reading_position`, `session_shared_content` | NavigationCoran, bibliothèque | séparées par conception | SYS-028 |
| Teaching Core côté Dart | ports `lib/core/tc_*` | écrans `tc_*` | démo ou `UnimplementedError` hors roster et observation | SYS-020 à 024 |
| Notification | aucun producteur serveur ; préférences locales | `compte_page.dart` | absent | SYS-031 |
| Recherche | aucun moteur serveur ; filtre local du catalogue | bibliothèque | absent hors catalogue local | SYS-032 |
| Finance (solde, obligation, payout) | `wallets` par foyer, écrivain absent | aucun consommateur Dart | absent / contradictoire | SYS-033, 034 |
| Évaluation, décision, certification | `evaluations`, fonctions réservées à l'administration | `service_evaluations.dart` | partiel, certification absente | SYS-030 |

### 2.2 Registre

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Écart minimal | Priorité | Responsable | Tâche existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-SYS-001 | Compte/auth, personne, matricule RA, profil élève, foyer sont des objets distincts (DM 01.3, ligne 98) | Tous, identité | tables `profiles`, `student_profiles`, `households` ; `immutable_id` | CONFORME_PARTIEL | Trois tables distinctes `0001_fondations.sql:62,100` ; identifiant public `p.immutable_id` lu par `0033_tc_vues_rpc.sql:189-190` ; aucune occurrence de "matricule" dans `supabase/migrations` (recherche) | Le matricule RA n'existe pas ; `immutable_id` en tient lieu sans que la source de vérité de la règle d'immatriculation soit sur HEAD (décision citée par CTR-SRC-01) | P1 | backend, gouvernance | Branches `claude/immatriculation-ra`, `codex2/imm-back-1` (non fusionnées) ; aucune tâche existante trouvée sur HEAD |
| AUD-SYS-002 | Un seul vocabulaire de rôles entre base et client (DM 01.4, ligne 104) | Tous | enum SQL `app_role` ; Dart `AppRole` | CONFORME_PARTIEL | SQL : `0001_fondations.sql:26-27` six valeurs ; Dart : `enums.dart:9-26` six valeurs identiques | Parité lue des deux côtés, aucun test de parité (recherche `AppRole.values` dans `test/` : aucun) | P2 | frontend | Aucune tâche existante trouvée |
| AUD-SYS-003 | Un widget lit une capacité, jamais un rôle (CLAUDE.md racine, règles transverses) | Tous | `SessionState`, `signature_page.dart` | CONFORME_PARTIEL | `session_state.dart:119-130` ne porte que `peutEcrire` et `peutVoirDirection` (constant `false`) ; `signature_page.dart:53,66` branche sur `AppRole.teacher` pour choisir les points du contrat ; `cahier_page.dart:588` documente la règle | Le modèle de capacités n'a que deux entrées, donc les écrans retombent sur le rôle (AUD-ENS-037 et AUD-ENS-071 le confirment pour l'évaluation) | P2 | frontend | AUD-ENS-037, AUD-ENS-071 |
| AUD-SYS-004 | Un seul état fait autorité pour "qui enseigne cette séance" (DM 01.1, ligne 73 ; prompt ligne 346) | Enseignant, élève, tuteur, salle | `sessions.teacher_id` contre `session_participants.role='teacher'` ; `autoriser_jeton_video` | CONTRADICTOIRE | `materialiser_seances_groupe` n'insère que des `'student'` : `0033_tc_vues_rpc.sql:350,367` (identique sur `origin/codex/backend-lot-f1` migration 0055 lignes 87,105). Le chemin 1-à-1 insère l'enseignant : `0005_dashboards_affectation_regles.sql:1003`. `autoriser_jeton_video` exige une ligne `session_participants` et refuse sinon : `0033:1676-1682`. Les vues de séance lisent `sessions.teacher_id` : `0014_acces_agent.sql:907-910`, `0025_role_enseignant.sql:62-90`. Tous les scénarios SQL insèrent l'enseignant à la main : `scenarios_n2.sql:102-110`. Aucun scénario n'appelle `creer_groupe` ni `materialiser` (recherche dans `supabase/tests` : aucun résultat) | Une séance de groupe affiche l'enseignant partout mais, à la lecture du SQL, il ne peut pas obtenir de jeton vidéo (non démontré en exécution) ; la présence de l'enseignant n'est pas dérivable (ligne absente de `presence_seance_v`) | P0 | backend | PR #13 (lot F1) réécrit la fonction sans corriger le point ; aucune tâche existante trouvée |
| AUD-SYS-005 | Retirer un élève d'une Classe coupe ses droits sur les séances à venir (DM 01.1 ; ADR-021 motif tracé) | Admin, élève mineur, tuteur | RPC `retirer_eleve_groupe` ; `session_participants` ; jeton vidéo | ABSENT | La fonction ne met à jour que `groupe_membres` : `0019_groupes_durcissement.sql:177-206`. Le jeton vidéo se décide sur `session_participants` : `0033:1676-1682`, sans contrôle de `groupe_membres.left_at`. Aucun déclencheur sur `groupe_membres` hors insertion : `0033:415-418`. Aucun correctif sur `origin/ccr-1b1bfa0b-m1kvkk` (recherche `update public.session_participants` : aucun résultat) | L'élève retiré reste participant des séances déjà matérialisées (horizon quatre semaines, `matching_horizon_weeks`), les voit dans `mes_seances_v` (`0014:906-909`) et peut demander un jeton tant que la fenêtre est ouverte (non démontré en exécution) | P0 | backend | aucune tâche existante trouvée ; AUD-OFR-048 couvre fusion et transfert, pas ce point |
| AUD-SYS-006 | Clôturer une Classe annule ou retire ses séances à venir (DM 01.1 ; AUD-OFR-042 pour le déplacement) | Admin, enseignant, familles | RPC `cloturer_groupe` ; `sessions.status` | ABSENT | La fonction ferme `groupe_membres` et `groupes` seulement : `0019:209-238`. Les séances restent `planned` et sans `deleted_at` ; la garde de jeton ne regarde ni `groupes.ended_at` ni le statut de la Classe : `0033:1655-1672` | Séances fantômes d'une Classe close, visibles de l'enseignant et des familles, joignables | P1 | backend | aucune tâche existante trouvée |
| AUD-SYS-007 | Une seule notion d'affectation enseignant-élève consommée par tous les écrans (DM 01.1, ligne 73) | Famille, admin, enseignant | `teacher_student_assignments` contre `groupe_membres` | CONTRADICTOIRE | Les groupes n'écrivent jamais dans les affectations : écrivains `0005:1067`, `0008:288` contre `0017:270`, `0019:167`. Le pivot est documenté comme coexistence provisoire : `0017_groupes_pedagogiques.sql:9-14`. Consommateurs Dart des affectations seules : `service_planning.dart:311`, `service_matching.dart:194`. Aucun appel Dart n'écrit `prendre_eleve` dans le parcours d'un groupe | Deux modèles d'appartenance vivent, leurs consommateurs ne se parlent pas ; la règle de bascule n'est écrite nulle part sur HEAD | P0 | gouvernance, backend, frontend | PR #13 et #29 (F1) ; AUD-OFR-059, AUD-OFR-060 |
| AUD-SYS-008 | L'accueil famille dit la vérité sur l'affectation d'un enfant en Classe (DM 01.2, entrée familiale) | Tuteur, élève enfant | `accueil_famille_page.dart`, `phaseEnfant` | CONTRADICTOIRE | `affecte` vient de `affectationsProvider` : `accueil_famille_page.dart:256-258` ; la phase "en recherche d'un enseignant" s'affiche si aucune séance à venir et aucune affectation 1-à-1 : `accueil_famille_page.dart:82-86`. Un enfant membre d'un groupe n'a aucune ligne d'affectation | Enfant en Classe, sans séance à venir (fin d'horizon de quatre semaines, AUD-OFR-041), affiché "en recherche" à tort ; non démontré en exécution | P1 | frontend | AUD-OFR-041 (ordonnanceur absent) ; aucune tâche existante trouvée sur l'écran |
| AUD-SYS-009 | Les indicateurs d'administration comptent les mêmes objets que les écrans (DM 01.2, 27.2) | Admin | RPC `indicateurs_admin`, ADM-01 | CONTRADICTOIRE | `foyers_sans_enseignant` compte les élèves actifs sans affectation 1-à-1 : `0015_administration_voit_les_personnes.sql:231-237` ; un élève membre d'un groupe n'a pas d'affectation et est donc compté "sans enseignant" | Le compteur de direction surestime les foyers en attente dès que la voie groupe est utilisée | P1 | backend | aucune tâche existante trouvée |
| AUD-SYS-010 | La liste "élèves à prendre" ne propose pas un élève déjà en Classe (DM 01.2) | Enseignant | `eleves_en_attente_v`, ENS-06 | CONTRADICTOIRE | La vue n'exclut que les affectations 1-à-1 actives : `0014_acces_agent.sql:974-977` ; `uidx` distincts sur chaque table : `0005:177` et `0017:79` | Un élève peut être à la fois membre d'un groupe et pris en 1-à-1 ; seul `guard_session_overlap` bornerait le chevauchement horaire (AUD-OFR-057) | P1 | backend | AUD-OFR-057 |
| AUD-SYS-011 | La Classe est l'unité durable ; l'attribution individuelle n'est pas un second parcours (DM 01.1 ; 00_LIRE_D_ABORD ccr) | Admin, enseignant | `/enseignant/creneaux`, `/admin/operations/attributions`, `/admin/operations/groupes` | À_ARBITRER | Trois écrivains d'appartenance branchés à l'interface : `service_matching.dart:212` (`prendre_eleve`), `service_attribution.dart:261` (`attribuer_eleve`), `service_groupes.dart:256,290` (groupes). Voir AUD-OFR-059 et AUD-OFR-060 | Décision de gouvernance à écrire : date et règle de retrait de l'affectation 1-à-1 ; je ne tranche pas | P1 | gouvernance | AUD-OFR-059, AUD-OFR-060 |
| AUD-SYS-012 | Les créneaux d'une Classe sont lus d'une seule représentation par tous les producteurs de séances (DM 01.2) | Famille, enseignant | `groupes.weekday` et `groupe_creneaux` ; `materialiser_seances_groupe` | CONTRADICTOIRE | Le déclencheur recopie l'ancre dans `groupe_creneaux` : `0043:465-500` ; `publier_groupe_depuis_offre` ajoute les autres jours : `0043:1278-1285` ; `materialiser_seances_groupe` ne lit que `v_g.weekday` : `0033:337-345`. Voir AUD-OFR-038 | Le producteur de séances ignore la représentation que le producteur de Classe enrichit | P1 | backend | AUD-OFR-038 ; PR #13 (0055) |
| AUD-SYS-013 | Une seule règle effective de durée, lue par tous les producteurs de séances (prompt ligne 346 ; DM 27.2) | Famille, enseignant, direction | `regle_effective`, `app_config` | CONTRADICTOIRE | Trois lectures : `regle_brute` par élève dans le chemin 1-à-1 `0005:974` ; `app_config_int('session_duration_minutes', 60)` dans la matérialisation de groupe `0033:338` ; clés `seance.duree_minutes_adulte` (90) et `_enfant` (60) pour l'offre `0043:536-537,1090-1091`. Dart `CleRegle.dureeSeance` : `enums.dart:341` | Un groupe adulte annoncé 90 minutes est matérialisé en 60, et la dérogation par profil (`rule_overrides`) est ignorée pour les groupes | P1 | backend, gouvernance | AUD-OFR-039 ; AUD-OFR-028 |
| AUD-SYS-014 | Le plafond d'élèves d'un enseignant borne toutes ses formes d'enseignement (ADR-017 ; DM 01.1) | Admin, enseignant | `guard_assignment_cap`, `guard_groupe_membre_cap`, `max_students_per_teacher` | CONTRADICTOIRE | Le plafond enseignant ne compte que `teacher_student_assignments` : `0005:208-212` ; le plafond de groupe est `groupes.seuil_max` : `0017:28-29` | Un enseignant peut cumuler un plafond complet en 1-à-1 et plusieurs Classes ; ce cumul est-il voulu ? À valider | P2 | gouvernance, backend | AUD-OFR-053 |
| AUD-SYS-015 | Le mot "pause" désigne une seule règle (DM 01.1 ; AUD-OFR-029) | Enseignant, famille | `break_minutes_between_sessions` contre `seance.pause_minutes_*` | À_ARBITRER | 30 minutes entre cours : `0005:35`, lue par `journee_page.dart:180` ; pause de séance 6 et 0 : `0043:538-539`. La clé de 30 minutes n'est appliquée par aucune garde serveur (recherche : définitions et `poser_regle` seulement) | Deux notions homonymes ; la première n'est qu'affichée. Choix de vocabulaire et d'application à valider | P2 | gouvernance | AUD-OFR-029 |
| AUD-SYS-016 | La présence se dérive d'une seule fonction et son vocabulaire est identique en base et au client (DM 01.2 ; prompt ligne 346) | Enseignant, tuteur, élève, contrôleur | `etat_presence` ; `presence_seance_v` ; `EtatPresence` | CONFORME_PROUVÉ | Fonction unique `0033:1535-1620` ; quatorze états SQL `0007:117-132` contre quatorze `valeurSql` Dart `service_presence.dart:23-70` ; trois lecteurs Dart de la même vue : `service_presence.dart:232`, `service_suivi.dart:75`, `roster_enseignant.dart:199` ; test lu, non exécuté `vue_presence_test.dart:59` ("les quatorze états de la base se lisent tous") ; scénarios serveur `scenarios_n4.sql` | Aucun pour la dérivation. La corrélation avec la présence de l'enseignant échoue pour les séances de groupe (voir SYS-004) | - | backend, frontend | AUD-TAB-031 (état du tableau) |
| AUD-SYS-017 | Une seule trace d'entrée en salle (DM 01.2, chaîne cours en visio) | Enseignant, contrôleur | `session_participants.entered_at/exited_at` contre `session_events` | PRÉSENT_MAIS_NON_RACCORDÉ | Colonnes `entered_at`, `exited_at` : `0001:183-185` ; aucun écrivain dans `supabase/migrations` ni `supabase/functions` (recherche d'écritures : aucun résultat) ; la présence se dérive de `session_events` : `0033:56-62` | Colonnes mortes qui laissent croire à une seconde source ; à retirer ou à documenter | P2 | backend | aucune tâche existante trouvée |
| AUD-SYS-018 | Une seule représentation de la disponibilité de l'enseignant (DM 01.2, entrée enseignant) | Enseignant, admin | `weekly_availability` contre `availability_slots` et `recurrence_rules` | PRÉSENT_MAIS_NON_RACCORDÉ | `weekly_availability` : `0005:380-393`, lue par `service_planning.dart:265-292`, `0005:1036`, `0014:962` ; `availability_slots` et `recurrence_rules` : `0001:141,151`, seulement des policies, aucun consommateur dans `lib/` ni dans les fonctions | Tables mortes ; `creer_groupe` ne lit aucune des deux (AUD-OFR-034) | P2 | backend | AUD-OFR-034 |
| AUD-SYS-019 | Le vocabulaire des statuts de séance est identique en base et au client (DM 01.2) | Tous | enum `session_status` ; `StatutSeance` | CONFORME_PARTIEL | Neuf valeurs `0001:42-45` contre neuf `enums.dart:224-250` ; transitions et états de préflight non produits : AUD-OFR-045 | Parité lue sans test de parité ; machine à états incomplète | P2 | backend, frontend | AUD-OFR-045 |
| AUD-SYS-020 | La page "Mes Classes" et l'horloge de séance lisent les Classes réelles (DM 01.2, 01.4) | Élève, tuteur, enseignant | `/tc/groupes`, `portGroupesProvider`, `portHorlogeSeanceProvider` | PRÉSENT_MAIS_NON_RACCORDÉ | Défaut = double de démonstration : `port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55` ; route déclarée `routes_tc_a.dart:36` incluse par `app_router.dart:596` ; aucun `override` de port dans `main.dart:125-129` | L'écran existe et est routé mais ne montre que des données de démonstration en production ; la vue serveur équivalente existe (`mes_groupes_v`, `0025:102`, lue par `service_enseignant.dart:91` seulement) | P1 | frontend | TC_CONTRACT_REQUEST_A (sections 1 à 6) ; AUD-SAL-040 |
| AUD-SYS-021 | Le Dock d'enseignement (annotations, travail assigné) écrit dans la base (DM 01.4, Teaching Core) | Enseignant en salle | `teaching_dock.dart`, `couche_annotation.dart` | PRÉSENT_MAIS_NON_RACCORDÉ | `portAnnotationsProvider` et `portAssignationsProvider` lèvent `UnimplementedError` par défaut : `port_annotations.dart:211-213`, `port_assignations.dart:175-177` ; lectures `teaching_dock.dart:237,280,306,322` ; aucun override dans `main.dart` | Tout appel du Dock en production lève une exception si l'hôte ne remplace pas le port ; tables serveur existantes (`annotation_layer`, `learning_assignment`) | P1 | frontend | TC_CONTRACT_REQUEST_D ; AUD-ENS-030 |
| AUD-SYS-022 | Le flux académique (post-cours, signalement, micro-feedback) est branché (DM 01.2 ; AUD-ENS-064) | Enseignant, élève | `panneau_post_cours.dart`, `feuille_signalement.dart`, `carte_feedback_seance.dart` | PRÉSENT_MAIS_NON_RACCORDÉ | `UnimplementedError` par défaut : `port_post_cours.dart:299-300`, `port_signalement.dart:141-143`, `port_feedback.dart:99-100` ; lectures `panneau_post_cours.dart:162`, `feuille_signalement.dart:217`, `carte_feedback_seance.dart:107` | Même constat que SYS-021 ; voir AUD-ENS-064 et AUD-ENS-065 | P1 | frontend | AUD-ENS-064, AUD-ENS-065 |
| AUD-SYS-023 | L'état partagé de classe et le transport de données survivent à une reconnexion et passent par le réseau (DM 01.4, LiveKit) | Enseignant, élève | `providers_tc_etat_partage.dart`, `providers_tc_realtime.dart` | PRÉSENT_MAIS_NON_RACCORDÉ | Persistance en mémoire : `providers_tc_etat_partage.dart:22-23` (`EtatPartageMemoire`) ; transport `TransportIndisponible` : `providers_tc_realtime.dart:25-26` ; adaptateur LiveKit présent `adaptateur_transport_livekit.dart` mais non injecté dans `main.dart` | L'état d'écran partagé ne quitte pas l'appareil ; la table `session_shared_content` n'est lue par aucun adaptateur | P1 | frontend | AUD-SAL (série Teaching Core) |
| AUD-SYS-024 | Le catalogue de ressources lit la base, pas un jeu local (DM 01.4, Bibliothèque) | Élève, tuteur, enseignant | `portCatalogueProvider` | PRÉSENT_MAIS_NON_RACCORDÉ | `donnees_catalogue.dart:32-34` (`CatalogueLocal`), `:37-38` (`VersionsLocales`) | Voir AUD-SAL-049 et AUD-SAL-056 ; non repris | P1 | frontend | AUD-SAL-049, AUD-SAL-056 |
| AUD-SYS-025 | Un même objet n'a pas quatre modèles Dart concurrents (prompt ligne 346 : mêmes données représentées différemment) | Frontend | `GroupeAdmin`, `GroupeEnseignant`, `GroupSummaryVM` ; `Seance`, `SeanceEnseignant`, `OccurrenceSeance`, `ResumeSeance` | CONFORME_PARTIEL | `service_groupes.dart:37`, `modeles_enseignant.dart:211`, `group_summary_vm.dart` ; `service_planning.dart:74`, `modeles_enseignant.dart:32`, `group_summary_vm.dart:151`, `teacher_student_projection.dart:81` ; cinq sources différentes (RPC `groupes_admin`, vue `mes_groupes_v`, port de démonstration) | Les modèles découpent par rôle, ce qui est une projection voulue (DM 01.4), mais leurs champs communs (fuseau, durée, identifiant) divergent déjà : AUD-OFR-037 | P2 | frontend | AUD-OFR-037 |
| AUD-SYS-026 | Le niveau d'un élève a une seule définition affichée (DM 01.3) | Enseignant, tuteur | `student_profiles.level`, `progression_historique`, `teacher_roster_v` | CONFORME_PARTIEL | La vue sert à la fois `sp.level` (libre) et `prog.nom_humain` : `0033:189-196,203-209` ; le niveau auto-déclaré a sa colonne séparée : `0043:28-34` | Deux niveaux sur la même ligne de roster ; l'écran doit les nommer différemment ; voir AUD-ENS-053 | P2 | frontend, contenu académique | AUD-ENS-053, AUD-ENS-055 |
| AUD-SYS-027 | La progression n'est écrite que par des fonctions réservées et n'est jamais déduite d'un paiement ou d'une présence (DM 01.2, évaluation) | Admin, enseignant | `progression_historique` | CONFORME_PARTIEL | Registre ENS : AUD-ENS-049 (CONFORME_PROUVÉ chez son auteur) ; `0021_diagnostics_placement.sql:19` table en ajout seul | Non revérifié ici ligne à ligne ; je cite sans reprendre le statut | - | backend | AUD-ENS-049, AUD-ENS-073 |
| AUD-SYS-028 | Trois positions de lecture ne s'écrasent pas entre elles (DM 01.3, Mushaf et Bibliothèque) | Élève, enseignant | `student_reading_position`, `library_reading_position`, `session_shared_content` | CONFORME_PARTIEL | Tables distinctes `0007:98`, `0032_tc_catalogue.sql:184`, `0030_tc_socle.sql` ; l'enseignant n'écrit pas la position de l'élève (AUD-SAL-070) ; `library_reading_position` sans consommateur (AUD-SAL-056) | La séparation est voulue ; la carte d'autorité "qui reprend où" n'est écrite nulle part | P2 | contenu académique, frontend | AUD-SAL-056, AUD-SAL-070 |
| AUD-SYS-029 | Un cahier par séance ; le cahier brut n'est ni résumé ni décision (DM 01.2 ; AUD-ENS-041) | Enseignant, famille | `lesson_reports`, `seance_resumes` | CONTRADICTOIRE | Voir AUD-ENS-024 (pas d'index unique par séance), AUD-ENS-027 (lecture du brut), AUD-ENS-041 (cinq objets distincts) ; `indicateurs_admin.rapports_manquants` compte les séances `ended` sans cahier : `0015:238-243` | Le consommateur "rapports manquants" suppose un cahier par séance que la base ne garantit pas ; non repris | P1 | backend | AUD-ENS-024, AUD-ENS-027, AUD-ENS-041 |
| AUD-SYS-030 | Évaluation, décision, promotion, certification sont quatre objets distincts, chacun avec son producteur (DM 01.2 évaluation ; 27.2) | Admin, direction, élève | `evaluations`, `progression_promouvoir`, certification | ABSENT | Aucune table de certification (AUD-ENS-080) ; `enregistrer_resultat_evaluation` ne promeut pas (AUD-ENS-078 : contradiction relevée) ; machine d'état proposition, occurrence, jury absente (AUD-ENS-067) | Le consommateur "résultat" n'a ni producteur de certificat ni état d'occurrence | P1 | backend, contenu académique | AUD-ENS-067, AUD-ENS-078, AUD-ENS-080 |
| AUD-SYS-031 | Les notifications sont des projections d'événements métier, sans autorité sur l'état (DM 01.4, dernière ligne) | Tous | préférences `compte_page.dart:301-306` ; `device_tokens` | PRÉSENT_MAIS_NON_RACCORDÉ | Interrupteurs locaux `preferences_locales.dart:30-31,45-49` sans autre consommateur dans `lib/` (recherche) ; table `device_tokens` : aucun producteur ni lecteur dans `lib/` ni `supabase/functions` (recherche) ; aucune table d'événements de notification dans `supabase/migrations` | L'utilisateur règle des notifications qu'aucun producteur n'émet ; les branches `origin/codex/backend-b09-notifications*` existent hors HEAD (non lues) | P1 | backend, frontend | AUD-OFR-018 ; branches `codex/backend-b09-notifications` (non fusionnées) |
| AUD-SYS-032 | Recherche transverse sur PostgreSQL avec le même modèle de révocation que la lecture (DM 01.4) | Tous | `recherche_catalogue.dart` | ABSENT | Seul un filtre local pur existe : `recherche_catalogue.dart:1-20` ; aucune RPC de recherche dans la liste des appels `rpc` de `lib/core` | Pas de recherche serveur ; le filtre local ne peut pas respecter une révocation de droit (AUD-SAL-049) | P2 | backend | AUD-SAL-049 ; branches `codex/backend-recherche-classes`, `codex2/rech-back-*` (non fusionnées) |
| AUD-SYS-033 | Solde, obligation et avance par profil, jamais caisse commune (DM 01.2 finance ; AUD-FIN-005) | Tuteur, adulte autonome, comptable | `wallets`, `wallet_entries`, `payouts` | CONTRADICTOIRE | `wallets.household_id unique` `0001:246-251` ; `wallet_entries` sans `profile_id` `0001:253-260` ; aucun consommateur Dart (AUD-FIN-002) | L'adulte autonome n'a pas de solde propre ; voir AUD-FIN-003 (devise EUR par défaut) et AUD-FIN-005 | P1 | backend, gouvernance | AUD-FIN-003, AUD-FIN-005 |
| AUD-SYS-034 | Cahier validé, dette enseignant, payout : chaîne continue (DM 01.2 finance) | Comptable, enseignant | `lesson_reports` vers `payouts` | ABSENT | `sessions.credit_amount_minor` n'est référencé que par `0001:171` (recherche) ; aucune fonction ne lie `lesson_reports` à `wallet_entries` ou `payouts` ; `payouts.status` modifiable directement (AUD-FIN-036) | Aucun producteur d'obligation ; la paie enseignant (AUD-ENS-039) n'a pas d'objet à consommer | P1 | backend | AUD-ENS-039, AUD-FIN-036, AUD-FIN-019 |
| AUD-SYS-035 | Un seul décideur de capacité vidéo (DM 01.4, média ; prompt ligne 346) | Tous en salle | `create-room-token` ; `autoriser_jeton_video` | CONFORME_PROUVÉ | La fonction Edge appelle la RPC puis ne décide aucune capacité : `create-room-token/index.ts:13,64-80` ; capacités décidées côté base : `0033:1710-1735` ; test lu, non exécuté `scenarios_n2.sql:125-135` et `scenarios_ctr01.sql` | Aucun pour l'unicité du décideur. Restent : SYS-004 (ligne enseignant) et SYS-036 (garde de compte) | - | backend | AUD-IDS-023 (hook JWT) |
| AUD-SYS-036 | Le jeton vidéo et la lecture d'état de présence revalident le compte et l'appartenance de l'appelant (DM 171 ; AUD-IDS-029) | Tous | `autoriser_jeton_video` ; `etat_presence` | CONTRADICTOIRE | `0033:1643-1740` n'appelle pas `app_account_valid()` (recherche : zéro occurrence dans la fonction) ; `etat_presence` ne contrôle pas l'appelant : `0033:1535-1620`, droit `0007:420` ; la migration 0042 de `ccr` décrit et corrige les deux points, elle n'est pas sur HEAD (migrations 0039-0042 absentes, AUD-OFR-004) | Un compte suspendu garde un jeton tant que sa ligne `session_participants` existe (non démontré en exécution) ; voir alerte ALR-SYS-02 | P0 | backend | AUD-IDS-029 ; PR #23, #31 (B-13) ; migration 0042 de `ccr` |
| AUD-SYS-037 | Une seule source d'écriture des audits, chaînée et vérifiable (DM 01.4, journalisation) | Admin, contrôleur | `log_sensitive_access` ; ADM-04 | CONFORME_PROUVÉ | Toutes les fonctions de groupe appellent la même fonction : `0019:196-199,231-232` ; route `/admin/securite-audit/journal` `routes.dart:242` ; chaîne vérifiable testée `scenarios_adm04.sql:394,535` (test lu, non exécuté, rejoué par la CI : `.github/workflows/ci.yml:180`) | Aucun pour l'unicité du chemin d'écriture. Contenu des motifs : AUD-ENS-059 | - | backend | AUD-TAB (ADM-04) |
| AUD-SYS-038 | Aucune écriture directe par le client sur les tables d'appartenance (DM 01.4, "RPC pour les écritures sensibles") | Tous | `groupes`, `groupe_membres`, `teacher_student_assignments` | CONFORME_PROUVÉ | `revoke insert, update, delete` : `0017:56,93` ; `0005:228-229` ; écrivains uniquement par fonctions `security definer` | Aucun | - | backend | aucune tâche existante trouvée |
| AUD-SYS-039 | Un élève n'a qu'une appartenance de Classe active et qu'un enseignant 1-à-1 actif ; une séance n'a qu'un enseignant participant (DM 01.1) | Admin | index uniques | CONFORME_PROUVÉ | `groupe_membres_actif_uidx` `0017:79-80` ; `assignments_one_active_teacher_uidx` `0005:177` ; `session_participants_one_teacher_uidx` `0001:192-193` ; contraintes SQL | Les trois bornes sont locales à leur table : leur cumul est SYS-010 | - | backend | AUD-OFR-054 |
| AUD-SYS-040 | La chaîne offre, intention, Classe, séances, participants, jeton, présence est testée de bout en bout (DM 01.2 ; AUD-OFR-040) | Admin, famille, enseignant | scénarios SQL | ABSENT | Aucun fichier de `supabase/tests` n'appelle `creer_groupe`, `ajouter_eleve_groupe`, `publier_groupe_depuis_offre`, `materialiser_seances_groupe` ni `retirer_eleve_groupe` (recherche : aucun résultat) ; les scénarios créent leurs séances et participants à la main (`scenarios_n2.sql:98-110`) | C'est cette absence qui laisse passer SYS-004, 005 et 006 | P1 | backend | AUD-OFR-040, AUD-OFR-042 ; PR #13 |
| AUD-SYS-041 | Une seule voie de bascule de jeton de démo vers adaptateur réel, vérifiable au démarrage (prompt ligne 346 : raccourcis qui contournent une validation) | Frontend | `lib/main.dart` | ABSENT | `main.dart:125-129` n'injecte que `sourceSessionProvider` ; onze ports `lib/core/tc_*` ont un défaut de démonstration, en mémoire ou levant `UnimplementedError` (voir SYS-020 à 024) ; aucun test de démarrage ne liste les ports non câblés | Aucun garde-fou n'empêche un port de démonstration de partir en production | P1 | frontend | aucune tâche existante trouvée |
| AUD-SYS-042 | Les anciennes conventions retirées ne laissent pas de code actif (prompt ligne 346) | Frontend | doubles de démonstration dans `lib/core` | CONFORME_PARTIEL | `demonstration_groupes.dart`, `demonstration_horloge.dart` vivent dans `lib/core/tc_*`, hors `lib/features/_dev` ; le rangement `_dev` existe et est séparé (`lib/features/_dev/galerie`, `playground`) | Les doubles de production-par-défaut devraient vivre sous `_dev` ou derrière un drapeau | P2 | frontend | aucune tâche existante trouvée |
| AUD-SYS-043 | Les sources actives de l'audit sont celles de HEAD (DM addenda, hiérarchie) | Gouvernance | `CLAUDE.md` | CONTRADICTOIRE | Voir CTR-SRC-01 et CTR-SRC-02 du registre des sources | Les harmonisations ci-dessus se mesurent sur un HEAD en retard de trois semaines sur `ccr` ; certaines (SYS-036) sont déjà corrigées là-bas | P1 | gouvernance | CTR-SRC-01 |

### 2.3 Lecture de synthèse

- Cinq lignes P0 ou P1 sont des défauts d'implémentation d'une décision déjà tranchée (SYS-004, 005, 006, 008, 009).
- Une ligne relève d'une contradiction réelle entre sources actives (SYS-007, 011) : elle demande un arbitrage de gouvernance.
- Les lignes SYS-020 à 024 et 041 sont un même défaut systémique : les écrans du Teaching Core sont routés et testés avec des doubles, sans adaptateur de production.

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Périmètre | Décision la plus récente applicable | Statut | Conséquence |
|---|---|---|---|---|---|---|
| CTR-SYS-01 | DM 01.1 (ligne 73) : "la Classe est l'unité durable d'enseignement" | `0017_groupes_pedagogiques.sql:9-14` : les deux modèles (1-à-1 et groupe) "coexistent le temps d'un lot dédié qui rebranchera les dépendants" ; `prendre_eleve`, `attribuer_eleve` et l'écran ENS-06 restent actifs | Appartenance enseignant-élève | DM 01.1 et addenda : la Classe prime. Le lot de rebranchement annoncé n'existe pas sur HEAD | ouvert | Compteurs, accueil famille et liste d'attente lisent le modèle 1-à-1 (SYS-007 à 010) |
| CTR-SYS-02 | `0043_offres_horaires_et_intentions.sql:19-22` : "les deux (ancre et créneaux) ne peuvent pas diverger" | `0033_tc_vues_rpc.sql:337-345` : la matérialisation ne lit que l'ancre | Calendrier de Classe | `0043` est postérieure à `0033` mais n'a pas réécrit la fonction ; PR #13 migration 0055 la réécrit sans changer ce point | ouvert | Une Classe de trois jours produit des séances d'un seul jour (SYS-012, AUD-OFR-038) |
| CTR-SYS-03 | `0025_role_enseignant.sql:46-52` : `sessions.groupe_id` désigne "la réunion hebdomadaire" du groupe, sans mention d'une ligne participant pour l'enseignant | `0033:1676-1682` : l'accès se décide sur une ligne `session_participants` y compris pour l'enseignant | Jeton vidéo des séances de groupe | Aucune décision écrite ; les tests insèrent l'enseignant à la main (`scenarios_n2.sql:102`) | ouvert | SYS-004 |
| CTR-SYS-04 | `0033:296-306` (commentaire "limite connue") : horizon de quatre semaines, pas d'ordonnanceur | DM 01.2 : séances planifiées jusqu'au suivi complet de la Classe | Prolongation du calendrier | DM 01.2 | ouvert | L'accueil famille affiche "en recherche" quand l'horizon est épuisé (SYS-008, AUD-OFR-041) |
| CTR-SYS-05 | `CLAUDE.md` racine : "aucune couleur, aucun écran hors catalogue" et un seul routeur | `app_router.dart:596` : routes Teaching Core déclarées dont les ports n'ont pas d'adaptateur | Routes atteignables mais non raccordées | CLAUDE.md : un écran n'est fini qu'avec ses cinq états et ses vraies données | ouvert | "Route déclarée" ne vaut pas "parcours réussi" (SYS-020 à 024) |
| CTR-SYS-06 | `enums.dart:341` : clés Dart `session_duration_minutes` et `break_minutes_between_sessions` seules | `0043:531-565` : douze clés `seance.*` et `groupe.*` lues par `regles_academie` | Configuration | Aucune règle écrite de précédence entre `rule_overrides`, `app_config` et clés d'offre | ouvert | SYS-013, 015 |

## 4. Devoir de regard - contre-propositions

Les trois situations du prompt sont distinguées pour chaque contre-proposition : (1) décision tranchée et implémentation défectueuse, (2) décision tranchée et risque nouveau, (3) contradiction réelle entre sources actives. Aucune contre-proposition ne devient une décision métier sans validation.

### CP-SYS-01 - Propager le retrait d'un élève ou la clôture d'une Classe aux séances à venir

1. Identifiant : CP-SYS-01.
2. Source : DM 01.1 (ligne 73) ; `0019_groupes_durcissement.sql:177-238`.
3. Constat vérifiable : `retirer_eleve_groupe` et `cloturer_groupe` ne modifient ni `session_participants` ni `sessions` (`0019:177-238`) ; le jeton vidéo se décide sur `session_participants` (`0033:1676-1682`).
4. Risque : un élève mineur retiré d'une Classe garde l'accès aux séances déjà matérialisées ; une Classe close garde des séances `planned`. Domaine : sécurité, pédagogie, coherence des listes.
5. Gravité et priorité : P0 pour le retrait, P1 pour la clôture.
6. Règle actuelle : le retrait est tracé au journal, mais n'agit que sur le roster futur.
7. Contre-proposition précise : à la fermeture d'un `groupe_membres` (colonne `left_at`) ou d'un `groupes` (`ended_at`), marquer `deleted_at` sur les lignes `session_participants` des séances futures non commencées, et passer en `canceled` les séances futures d'une Classe close, dans la même transaction que le retrait.
8. Options : (a) corriger dans les deux fonctions ; (b) déclencheur sur `groupe_membres` et `groupes` ; (c) faire décider `autoriser_jeton_video` aussi sur `groupe_membres.left_at` (défense en profondeur). Je recommande (a) plus (c).
9. Conséquences : les séances passées et l'historique de présence sont conservés ; les familles voient disparaître les séances futures de l'élève retiré.
10. Périmètre technique : backend uniquement (migrations, RPC). Le frontend ne change pas.
11. Dépendances : aucune ; recoupe AUD-OFR-048 (fusion et transfert).
12. Critères d'acceptation : après retrait, `mes_seances_v` de l'élève ne liste aucune séance future du groupe ; `autoriser_jeton_video` lève "non inscrit" ; après clôture, plus aucune séance `planned` future pour la Classe.
13. Tests et preuves : scénario SQL nouveau dans `supabase/tests` rejoué par la CI ; test négatif "élève retiré".
14. Décision requise : validation backend (Codex) ; aucune décision métier.
Situation : 1 (décision tranchée, implémentation défectueuse).

### CP-SYS-02 - Inscrire l'enseignant comme participant des séances de groupe

1. Identifiant : CP-SYS-02.
2. Source : DM 01.1 ; `0001_fondations.sql:192-193` (un enseignant par séance).
3. Constat : la matérialisation de groupe n'insère que des élèves (`0033:350,367`), le chemin 1-à-1 insère l'enseignant (`0005:1003`), la garde de jeton exige la ligne (`0033:1676-1682`).
4. Risque : l'enseignant ne peut pas entrer en salle (non démontré en exécution), sa présence n'est pas dérivée. Domaine : fiabilité, parcours critique.
5. Gravité et priorité : P0.
6. Règle actuelle : double source (`sessions.teacher_id` pour les vues, `session_participants` pour le jeton).
7. Contre-proposition : insérer la ligne `'teacher'` dans `materialiser_seances_groupe` et la maintenir si `groupes.teacher_id` change ; ajouter un contrôle de cohérence `sessions.teacher_id = participant teacher`.
8. Options : (a) insérer à la matérialisation (recommandé) ; (b) faire dériver le jeton de `sessions.teacher_id` pour le rôle enseignant.
9. Conséquences : la présence de l'enseignant devient dérivable ; le rapport "retard enseignant" devient possible.
10. Périmètre : backend.
11. Dépendances : PR #13 (0055) réécrit la même fonction : coordonner pour ne pas produire deux versions.
12. Critères : une Classe créée puis matérialisée donne, pour chaque séance, exactement un `participant` enseignant ; l'enseignant obtient un jeton dans la fenêtre.
13. Tests : scénario SQL qui appelle `creer_groupe` puis `autoriser_jeton_video` pour l'enseignant, sans insertion manuelle.
14. Décision requise : validation backend ; si le constat est infirmé en exécution, clore sans changement.
Situation : 1.

### CP-SYS-03 - Une vue canonique d'affectation pour les consommateurs famille, admin, enseignant

1. Identifiant : CP-SYS-03.
2. Source : DM 01.1, 27.2 ; prompt ligne 346.
3. Constat : accueil famille (`accueil_famille_page.dart:256-258`), `indicateurs_admin` (`0015:231-237`) et `eleves_en_attente_v` (`0014:974-977`) lisent uniquement `teacher_student_assignments`.
4. Risque : affichage "en recherche" à tort, compteur de direction faux, élève proposé à la prise alors qu'il est en Classe.
5. Gravité : P1.
6. Règle actuelle : le 1-à-1 est l'état faisant autorité pour trois consommateurs, le groupe pour d'autres.
7. Contre-proposition : une vue `affectation_effective_v` (élève, enseignant, Classe ou lien 1-à-1, actif) alimentée par les deux sources, lue par les trois consommateurs, en attendant la décision de gouvernance de CTR-SYS-01.
8. Options : (a) vue d'union ; (b) migration des affectations 1-à-1 en Classes d'un élève ; (c) retrait du 1-à-1. (b) et (c) sont des décisions métier.
9. Conséquences : aucune rupture de contrat côté Dart si les colonnes de `mes_affectations_v` sont conservées.
10. Périmètre : contrat partagé (vue), backend, frontend (changer la lecture).
11. Dépendances : décision de gouvernance sur le sort du 1-à-1.
12. Critères : un enfant membre d'une Classe n'est ni compté "sans enseignant" ni affiché "en recherche" ; ENS-06 ne le propose pas.
13. Tests : scénarios SQL des trois consommateurs avec un élève en Classe ; test de widget `phaseEnfant` avec lien de Classe.
14. Décision requise : gouvernance (sort du 1-à-1) ; l'option (a) n'en demande pas.
Situation : 3 pour le choix de fond, 1 pour les trois consommateurs.

### CP-SYS-04 - Une règle effective unique pour durée, pause et plafond, étendue aux Classes

1. Identifiant : CP-SYS-04.
2. Source : DM 01.1 ; AUD-OFR-028, AUD-OFR-039 ; `0005:974`, `0033:338`, `0043:536-539`.
3. Constat : trois lectures différentes de la durée ; le plafond enseignant ne compte pas les Classes.
4. Risque : une séance adulte annoncée 90 minutes dure 60 minutes dans le calendrier.
5. Gravité : P1.
6. Règle actuelle : voir SYS-013 à 015.
7. Contre-proposition : une fonction `regle_effective_classe(groupe, cle)` qui définit la précédence (dérogation de profil, clé d'offre, `app_config`) et que matérialisation, jeton et vitrine appellent toutes.
8. Options : (a) fonction unique ; (b) durée portée par la Classe (`groupes.duree_minutes`), copiée de l'offre à la publication.
9. Conséquences : le catalogue et le calendrier disent la même durée.
10. Périmètre : backend, contrat (`regles_academie`).
11. Dépendances : décision de gouvernance sur la précédence ; valeur de la pause (5 ou 6, AUD-OFR-029).
12. Critères : la durée d'une séance d'une Classe adulte égale la durée de l'offre qui l'a produite.
13. Tests : scénario SQL offre adulte, publication, durée de séance.
14. Décision requise : gouvernance pour la précédence et le plafond cumulé ; je ne tranche pas la valeur.
Situation : 3.

### CP-SYS-05 - Un registre de câblage des ports et un test de démarrage

1. Identifiant : CP-SYS-05.
2. Source : prompt ligne 346 ; CLAUDE.md ("un écran n'est fini qu'avec ses cinq états").
3. Constat : onze ports de `lib/core/tc_*` ont un défaut de démonstration, en mémoire ou `UnimplementedError`, sans override dans `main.dart:125-129` (SYS-020 à 024).
4. Risque : un écran routé affiche des données de démonstration ou lève une exception en production. Domaine : fiabilité, cohérence morale (information fausse montrée à une famille).
5. Gravité : P1.
6. Règle actuelle : chaque port documente en commentaire qu'un "Agent Z" le remplacera.
7. Contre-proposition : un fichier unique `lib/core/ports_production.dart` qui liste les overrides de production, et un test qui échoue si un port reste sur un double de démonstration en mode non-dev.
8. Options : (a) test de liste ; (b) provider de défaut qui lève en `release`.
9. Conséquences : les ports non câblés deviennent visibles au lieu d'être silencieux ; la route correspondante peut être masquée par drapeau en attendant.
10. Périmètre : frontend uniquement.
11. Dépendances : les adaptateurs réels (TC_CONTRACT_REQUEST_A à D).
12. Critères : le test liste zéro port de démonstration pour les écrans exposés ; chaque écran masqué est nommé.
13. Tests : test Dart "ports de production" (non exécutable ici).
14. Décision requise : aucune décision métier ; priorisation des adaptateurs à faire par l'opérateur.
Situation : 1.

### CP-SYS-06 - Notifications comme projection d'événements, jamais comme état

1. Identifiant : CP-SYS-06.
2. Source : DM 01.4 ; AUD-OFR-018.
3. Constat : réglages locaux sans producteur (`preferences_locales.dart:30-31`), `device_tokens` sans lecteur ni producteur.
4. Risque : promesse "nous vous préviendrons" (AUD-OFR-018) sans événement.
5. Gravité : P1 pour les messages promettant une alerte, P2 sinon.
6. Règle actuelle : absente.
7. Contre-proposition : une table d'événements métier append-only (type, objet, destinataire, lien contextuel), alimentée par les fonctions existantes (décision de demande, séance annulée, cahier validé), lue par un canal ; les préférences locales ne filtrent que l'affichage.
8. Options : (a) reprendre la branche `codex/backend-b09-notifications*` après relecture ; (b) construire sur HEAD.
9. Conséquences : aucune autorité d'état transférée à la notification.
10. Périmètre : backend, contrat, frontend.
11. Dépendances : décision sur les canaux (push, e-mail) ; RGPD pour mineurs.
12. Critères : chaque texte "vous serez prévenu" a un événement producteur nommé.
13. Tests : scénario SQL par type d'événement.
14. Décision requise : opérateur (canaux et contenu pour un parent d'enfant mineur).
Situation : 2.

### CP-SYS-07 - Scénarios SQL de chaîne complète Classe, séance, participants, jeton, présence

1. Identifiant : CP-SYS-07.
2. Source : AUD-OFR-040 à 042 ; SYS-040.
3. Constat : aucun fichier de `supabase/tests` n'appelle les fonctions de groupe ; les séances de test sont fabriquées à la main.
4. Risque : SYS-004 à 006 passent la CI.
5. Gravité : P1.
6. Règle actuelle : la CI rejoue treize fichiers de scénarios (`.github/workflows/ci.yml:36-180`) qui n'exercent pas cette chaîne.
7. Contre-proposition : un fichier `scenarios_chaine_classe.sql` : offre, intentions, `publier_groupe_depuis_offre`, matérialisation, jeton enseignant et élève, retrait, clôture, présence dérivée.
8. Options : fichier unique ou ajout aux scénarios N2.
9. Conséquences : tout écart futur sur la chaîne casse la CI.
10. Périmètre : backend (tests).
11. Dépendances : correctifs CP-SYS-01 et CP-SYS-02 pour passer au vert.
12. Critères : le fichier échoue sur HEAD pour SYS-004 et 005, passe après correctifs.
13. Tests : lui-même, rejoué sur base neuve.
14. Décision requise : aucune.
Situation : 1.

### Alertes de sécurité

- ALR-SYS-01 (gravité haute, SYS-005) : accès conservé aux séances d'une Classe après retrait de l'élève. Exposition : élèves mineurs retirés, séances futures à l'horizon de quatre semaines. Vraisemblance : certaine à la lecture du SQL, non démontrée en exécution. Mesure de réduction : CP-SYS-01 ; en attendant, retirer l'élève des séances par une opération administrative manuelle à chaque retrait.
- ALR-SYS-02 (gravité moyenne à haute, SYS-036) : `autoriser_jeton_video` sans `app_account_valid()` et `etat_presence` sans contrôle de l'appelant sur HEAD ; le correctif est la migration 0042 de la branche `ccr`, absente de HEAD. Exposition : compte suspendu avec jeton non expiré ; lecture de l'état de présence d'un tiers si l'exécution est ouverte à `anon` par héritage de `PUBLIC` (AUD-IDS-015 le décrit pour les migrations 0014). Vraisemblance : moyenne, non démontrée sur la base de production. Mesure : appliquer 0039 à 0042 après relecture, ou révoquer `anon` sur `etat_presence`.

## 5. États d'écran et applicabilité

Ce registre ne porte pas d'écran. Les états sont donc évalués sur les écrans transversaux touchés.

| État | Présent | Absent | Non applicable |
|---|---|---|---|
| Chargement | accueil famille (`chargementInitial`, `accueil_famille_page.dart:214-217`) | Teaching Core sur ports de démonstration : le chargement est instantané, donc non représentatif | Registre de données (tables, RPC) |
| Contenu | accueil famille, présence, suivi | Mes Classes, horloge de séance : contenu de démonstration seulement (SYS-020) | - |
| Vide | accueil famille ("rien aujourd'hui") | Mes Classes : le vide réel n'est pas atteignable avec le double | - |
| Erreur | accueil famille (`enErreur`, ligne 212-215) | Dock et flux académique : l'état d'erreur est une exception non rattrapée (`UnimplementedError`, SYS-021, 022) | - |
| Hors ligne | cahier (file locale, AUD-ENS-022) | Teaching Core : état partagé en mémoire seulement (SYS-023) | - |
| Session expirée | revalidation de session partielle (AUD-IDS-027) | Jeton vidéo : aucun contrôle de compte (SYS-036) | - |
| Accès refusé | refus RLS et garde de jeton côté serveur | Retrait d'élève : aucun refus tant que la ligne participant existe (SYS-005) | - |
| Reprise | position de lecture élève (AUD-SAL-070) | Reprise après clôture de Classe : séances fantômes (SYS-006) | - |

## 6. Non vérifié et limites de la preuve

- Aucun test n'a été exécuté. Les affirmations de comportement serveur (SYS-004, 005, 006, 008, 036) sont des lectures de SQL ; elles n'ont pas été rejouées sur une base. Elles doivent être confirmées par le scénario de CP-SYS-07 avant toute décision.
- SYS-004 : le constat "l'enseignant ne peut pas obtenir de jeton" suppose qu'aucune autre voie n'insère la ligne enseignant. Ni `supabase/functions`, ni les triggers de `sessions` lus, ni la migration 0055 de `origin/codex/backend-lot-f1` ne le font. Une insertion manuelle d'exploitation sur la base de production n'est pas exclue et n'est pas observable depuis le dépôt.
- SYS-008 : le défaut d'affichage dépend d'un enfant sans séance à venir ; non reproduit à l'écran.
- SYS-016 et SYS-035 : "CONFORME_PROUVÉ" s'appuie sur des tests lus et sur la chaîne de code, pas sur une exécution.
- AUD-SYS-027 cite AUD-ENS-049 sans reprise de son statut.
- La corrélation entre le corps des PR #13, #21, #29, #30, #31 et les constats n'a été faite que par lecture des branches `origin/codex/backend-lot-f1`, `origin/ccr-1b1bfa0b-m1kvkk` ; les autres PR n'ont pas été relues.
- Le contenu de `docs/current/` (sur `ccr`) n'a pas été relu ici ; les décisions DECISION-OFFRES-GROUPES et DECISION-CLASSES-SIMULTANEES sont reprises des registres OFR.
- La performance des vues de projection (jointures lateral de `teacher_roster_v`, appel de `etat_presence` par ligne) n'est pas mesurée.
