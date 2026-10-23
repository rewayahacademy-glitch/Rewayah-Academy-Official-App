# Registre de conformite - Identite, habilitations, securite des donnees, migrations et RLS

- SHA audite : 4a7aa2b (branche claude/nice-darwin-hael93, identique a origin/main au 14/10/2026)
- Date : 14/10/2026
- Auditeur : Claude, agent d'audit en lecture seule (aucun test execute, Flutter et Dart absents de l'environnement)
- Domaine : IDS - Identite, habilitations, securite des donnees, migrations et RLS (lettre A du devoir de regard : securite et protection des personnes)
- Nature : audit differentiel. Ce qui est utile et tient est conserve ; aucune reecriture n'est proposee par defaut.

Abreviations de sources utilisees dans les tableaux :

- DM : REWAYAH_DOCUMENT_MAITRE_ULTIME_AUDIT_CONFORMITE_2026-10-14.md (lignes citees).
- PM : prompt de mission audite_dharmonisation_global_14-10-2026.txt (lignes citees).
- PROD-SNAP : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md, lu sur la branche codex/backend-sec-prod (PR #22, non fusionnee).
- SEC-PROD-SQL : docs/backend/SEC_PROD_REMEDIATION.sql, meme PR #22 ; son en-tete dit "ne pas executer en l'etat".
- LEDGER-25 : docs/backend/RECONCILIATION_MIGRATIONS_BR0B_2026-10-10.md, PR #25 (non fusionnee).
- REG-35 : docs/current/REGISTRE-RECONCILIATION-2026-10-14.md, PR #35 (non fusionnee).
- ccr : branche d'integration ccr-1b1bfa0b-m1kvkk, lue via get_file_contents.
- "test lu, non execute" : le fichier de test a ete lu (nom, assertions) mais rien n'a ete rejoue.

## 1. Perimetre, sources lues, sources introuvables

### 1.1 Etat du depot audite

- HEAD 4a7aa2b est le commit du 22/09/2026 "offres horaires vitrines" ; main n'a pas bouge depuis. La branche d'integration ccr (dernier commit d5e45ec du 12/10) porte 20 jours de travail absents de HEAD, dont les migrations 0039 a 0042 et 0044 a 0048.
- Consequence de cadrage : ce registre atteste ce que HEAD contient. Ce que les PR ouvertes ou ccr apportent est signale dans la colonne "Ecart minimal" avec le numero de PR, sans valoir statut conforme.
- supabase/migrations de HEAD : 42 fichiers SQL (dont le corpus coranique 0013, 1,48 Mo) et une note LISEZ-MOI, soit 43 entrees ; ccr en compte 51 SQL (42 + 0039 a 0042 + 0044 a 0048, coherent avec LEDGER-25). 71 tables creees, 148 policies vivantes (derniere version apres les drop), 196 definitions de fonctions hors 0013 dont 188 SECURITY DEFINER (lecture par script, voir 1.2).

### 1.2 Sources lues

Document maitre : lignes 10-70 (mandat, lignes rouges, etat de preuve), 128-180 (G00 et G01), 779-1068 (addenda : statuts, hierarchie, non-regression, decisions reconciliees, lignes 920-929 roles et profils). Prompt de mission : lignes 140-384.

Depot (HEAD) :

- CLAUDE.md racine, lib/CLAUDE.md, supabase/CLAUDE.md, docs/PROGRESS.md (lignes 1-120), docs/MISE-EN-SERVICE.md (1-80), docs/architecture/decisions.md (ADR-009, ADR-014, ADR-025, lignes 1570-1580 et 1809), docs/architecture/etape-0-1-fondations.md (matrice d'acces, lignes 118-145), docs/architecture/ADMIN_SECURITE_DIRECTION.md (1-80), docs/HANDOFF.md (recherche par mots-cles, plages 3081-3125 et 3304 suivantes en index), docs/design/08-catalogue-ecrans.md (index des fiches par recherche, pas de lecture integrale).
- supabase/migrations : lecture directe des 0003, 0030_durcissement, 0038 ; extraits cibles de 0001 (60-125, 388-625, 700-800, 900-930, 1146-1262), 0004 (20-60, 120-222, 340-425, 495-770, 790-1030), 0014 (1-225, 273-352, 505-555, 640-800), 0015, 0016, 0023, 0029, 0032 (600-693), 0033 (556-700), 0034 (1-330), 0043 (78-320). Les autres fichiers (hors 0013) ont ete balayes par script de lecture (tables, RLS, fonctions SECURITY DEFINER, search_path, policies, grants, vues). 0013 (donnees coraniques) exclu des balayages.
- supabase/tests : noms de controles par recherche sur etape3, hook_jeton, r2, agt01, adm04 ; blocs lus : etape3 (270-292, 548-672), hook_jeton (286-320), r2 (236-333), agt01 (360-392).
- supabase/functions : session-enfant, agent-session, creer-profil-enfant, create-room-token (lus en entier), piece-identite-acces (1-100), livekit-webhook (1-60), _shared/clients.ts, _shared/r2/client_appelant.ts. supabase/config.toml (150-200, 286-330, 396-418).
- .github/workflows : ci.yml, deploy.yml en entier ; flutter-deploy.yml (1-35, 90-132).
- lib : core/router/redirection.dart, routes.dart (348-367), session_state.dart, claims_jwt.dart, session_controleur.dart, source_session.dart, service_auth.dart, config/env.dart, cache/media/cache_media.dart, cache/db/app_database.dart (1-160), appairage/profils_locaux.dart, service_enfant.dart, code_local.dart, cache/secure/stockage_securise.dart, enseignant/depot_cahiers.dart, cache/sync/file_rapports.dart, dossier/service_validation.dart, service_dossier.dart, agent/session_agent.dart, observabilite/supervision.dart ; features connexion, eleve_connexion, agent_entree, inscription, compte, dossiers (extraits), tc_observation_ui/options_entree_observation.dart.
- test (Dart) : noms de groupes de redirection_test.dart (24-80), supabase_key_validation_test.dart ; liste des repertoires de tests.
- Secrets : 13 motifs de cles recherches par git grep sur les 822 fichiers suivis, plus git log -G sur 76 commits locaux.

GitHub (lecture seule) : liste des PR ouvertes ; fichiers de #10, #17, #22, #23, #25 (rapport complet), #27, #29 (extraits 0052 et 0053), #30, #31, #35 (registre) ; arbre supabase/migrations de ccr avec empreintes ; 0006, 0044 et 0048 de ccr ; PROD-SNAP et SEC-PROD-SQL ; historique des commits de main et de ccr ; liste des runs du workflow CI.

### 1.3 Sources introuvables

Absentes de HEAD (recherche par find sur noms et par ls) : docs/current/00_LIRE_D_ABORD.md et la serie 01 a 08 ; docs/orchestration/COHABITATION.md (le repertoire docs/orchestration n'existe pas) ; DESIGN-GOV-2026-09-26.md ; REWAYAH_RECH_02 et RECH-01 ; referentiel academique RA-CUR-2026.1 ; 00_INVENTAIRE_ET_GATES.md ; ledger des migrations de docs/. Seules copies partielles : REG-35 (PR #35) et LEDGER-25 (PR #25), non fusionnees. Le contenu de ces sources n'a pas ete reconstitue de memoire.

## 2. Registre par exigence

Statuts : un par exigence atomique. Priorites : P0 securite ou parcours critique, P1 completude, P2 finition. Responsables : frontend, backend, contrat partage, contenu academique, gouvernance.

### 2.1 Bloc A - Migrations, ledger et integration (G00)

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-001 | Rejouer de zero toutes les migrations ordonnees sur PostgreSQL propre, avec fixtures, RLS et scenarios (DM 138-139) | Backend, integration | .github/workflows/ci.yml job migrate-check ; supabase/tests/stub_auth.sql | IMPLÉMENTÉ_NON_PROUVÉ | ci.yml:9-45 (boucle sur supabase/migrations/*.sql), ci.yml:46-180 (12 fichiers de scenarios), ci.yml:3-6 (declencheurs : PR vers main et lancement manuel). Dix derniers runs CI listes (n°433 a 442) tous en echec, sur d'autres SHA, plusieurs en 3 a 4 secondes (cause non diagnostiquee) ; aucun run sur 4a7aa2b | Rejeu non demontre sur HEAD. Le message du commit 1355669 documente quatre echecs SQL de base (etape3:287, etape4:1041, ctr01:209, agt01:389) sans fermeture lue. Pas de run sur push main | P1 | Backend | B-01 (cite par PR #25, non fusionnee) ; aucune tache d'identifiant trouvee dans docs/PROGRESS.md ni docs/HANDOFF.md de HEAD |
| AUD-IDS-002 | Cartographier chaque migration : nom, hash, contenu, dependances, version locale, entree du ledger distant (DM 138) | Backend, exploitation | docs/ de HEAD | ABSENT | Recherche "ledger" dans docs/ de HEAD : seulement docs/HANDOFF.md:2849 et docs/architecture/decisions.md:128 (sens financier). Seule note : supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md:1-85 | Aucun registre de provenance dans la branche auditee. LEDGER-25 (PR #25) et la PR #32 (provenance du corps de 0011) le portent, non fusionnees | P1 | Backend | B-01 (PR #25), PR #32 |
| AUD-IDS-003 | Expliquer le trou de numerotation 0039 a 0042 (consigne de mission : comparer au ledger) | Backend | supabase/migrations/ | CONTRADICTOIRE | ls supabase/migrations : 0038 puis 0043 ; git ls-tree HEAD identique. Presentes sur ccr (empreintes 1e50a938, c4a67775, 34152262, c634a7e5). PROD-SNAP ligne 3 : ledger PROD de 50 entrees "jusqu'a 0042_etat_presence_fermee_et_jeton_video_verifie_le_compte". LEDGER-25 (addendum) : corps des quatre egaux en PROD, STAGING et ccr | Les quatre migrations deja appliquees en PROD n'existent pas dans l'arbre de HEAD : HEAD ne rejoue pas le schema PROD (observation du tuteur, presence fermee, jeton video qui verifie le compte). LEDGER-25 les dit presentes dans "main" : non reproduit sur HEAD (voir CTR-IDS-02) | P1 | Backend, gouvernance | B-01 (PR #25) |
| AUD-IDS-004 | Expliquer le trou 0044 a 0048 apres 0043 et appliquer les fermetures de securite correspondantes (DM 139, 143) | Backend, direction | supabase/migrations/ ; ccr | BLOQUÉ_DÉPENDANCE | Sur ccr uniquement : 0044_securiser_rpc_admin_et_kyc (533a3901), 0045, 0046_agent_ro_household_predicate, 0047_mask_agent_peer_names, 0048_revoke_public_volatile_function_execute (9359ac27). LEDGER-25 : 0043 a 0048 presentes en STAGING, absentes du ledger PROD ; "GO explicite" requis avant PROD (DM 28-30 : seule la direction ouvre un perimetre de production) | HEAD ne contient aucune des fermetures de 0044 (comptes_admin, creer_groupe, modifier_groupe, read_kyc_documents), 0046-0047 (agent_ro, noms de pairs) ni 0048 (EXECUTE public des fonctions volatiles). Dependance reelle et prouvee : decision de migration PROD par la direction | P0 | Gouvernance (direction) puis backend | B-01 (PR #25, point 2 de la decision) |
| AUD-IDS-005 | Numeros partages 0030, 0032, 0033 (deux fichiers chacun) : ni fusion ni renommage de ce qui est applique (DM 138) | Backend | six fichiers | CONFORME_PARTIEL | git ls-tree HEAD : 0030_tc_socle et 0030_tc_socle_durcissement_search_path, 0032 x2, 0033 x2, contenu additif (0030_tc_socle_durcissement_search_path.sql:9-25). LEDGER-25 section "Doublons numeriques" : entrees distinctes en PROD et STAGING, corps egaux (addendum). deploy.yml:1-39 : db push desactive | Les six sont des migrations separees et correctes. Mais deux fichiers de meme prefixe ne se portent pas par supabase db push (version = prefixe), et l'ordre depend du tri octet par octet du conteneur alpine (CI) ; non demontre sous une autre locale. Ordre PROD reel : 0038 avant 0034 (LEDGER-25) | P2 | Backend | B-01 |
| AUD-IDS-006 | Journal distant horodate contre fichiers numerotes : aucune reparation opportuniste du ledger (DM 138-139) | Backend, exploitation | .github/workflows/deploy.yml | CONFORME_PARTIEL | deploy.yml:1-39 (cause mesuree le 21/09), deploy.yml:87-107 (job migrations manuel, case a cocher, supabase db push --db-url). LEDGER-25 : huit entrees PROD sans source locale fiable (0006, 0007, 0008 a nom vide ; 0006_init, 0007_init, 0008_init, record_0006_0007_0008_versions, 0011_presence_bornee_controleur_invisible) | La poussee automatique est bien coupee. Huit entrees de ledger restent sans SQL source apparie ; le rejeu complet n'a pas de parite prouvee | P1 | Backend | B-01 (PR #25) ; PR #32 |
| AUD-IDS-007 | Etat de 0035, 0036, 0037 connu et note tenue a jour (LISEZ-MOI du 21/09) | Backend | supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md | CONFORME_PARTIEL | LISEZ-MOI:13-19 (tableau : non appliquees au 21/09), :49-58 (question sans ligne REPONSE). LEDGER-25, liste des neuf fichiers sans homonyme en PROD : 0035 a 0037 n'y figurent pas, donc elles ont un homonyme dans le ledger PROD (inference par exclusion, corps non compares) | La note de HEAD est obsolete et laisse croire que des defauts d'observation (plafond par visite, 0036) vivent en production. Etat reel non prouve par une source de HEAD | P2 | Backend (auteur des trois fichiers) | Aucune tache existante trouvee ; B-01 couvre le ledger |
| AUD-IDS-008 | Appliquer 0043 (offres horaires, intentions) avant d'en dependre | Backend, direction | supabase/migrations/0043_offres_horaires_et_intentions.sql | BLOQUÉ_DÉPENDANCE | Message du commit 4a7aa2b : "la migration 0043 n'est PAS appliquee en production" ; empreinte identique a ccr (a58a0d04) ; LEDGER-25 : 0043 hors ledger PROD. 0043 n'appelle aucun objet de 0039-0042 (liste des fonctions appelees lue) | Parcours d'onboarding invisible en PROD jusqu'a application ; GO direction requis | P1 | Gouvernance puis backend | B-01 ; PR #29 (F1) s'appuie sur 0043 |
| AUD-IDS-009 | Les migrations deja appliquees gardent des octets identiques entre HEAD et la branche d'integration (DM 138 : ne jamais modifier retroactivement) | Backend | 14 fichiers | CONTRADICTOIRE | Empreintes git de HEAD contre get_file_contents(ccr) : 0001, 0004 a 0013, 0022, 0024, 0025 different (+34 octets par reference, +68 pour 0008, 0009, 0010). 0006 compare ligne a ligne : seul le chemin du document cite change (docs/MISE-EN-SERVICE.md devient docs/archive/2026-09-pre-remise-a-plat/MISE-EN-SERVICE.md) | Derive de commentaires uniquement (0006 verifie ; les 13 autres par taille, non lus ligne a ligne). Tout controle par hash de fichier echoue sans normalisation ; le ledger PROD ne stocke pas de hash de fichier | P2 | Backend | B-01 |
| AUD-IDS-010 | Numerotation stable des migrations en cours de revue | Backend, gouvernance | PR ouvertes | À_ARBITRER | #23 : 0049_guardian_visit_admin_active_account ; #29 : 0049 a 0056 ; #17 : 0055 a 0061 ; #27 et #31 : 0058 ; #30 : 0057 et 0074 ; #10 : 20261009180731_agent_identity_subject (horodatee) ; STAGING (LEDGER-25) : 0049 a 0073 sous d'autres noms | Quatre PR revendiquent les numeros 0049, 0055 a 0058 pour des contenus differents. Le schema de version (sequentiel ou horodate) n'est pas tranche. Aucune fusion possible sans collision | P1 | Gouvernance (arbitrage) puis backend | B-01 |

### 2.2 Bloc B - RLS, fonctions, grants, journal

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-011 | RLS activee sur toutes les tables, sans exception (CLAUDE.md racine ; supabase/CLAUDE.md:11 ; DM 140) | Tous | 71 tables du schema public | CONFORME_PROUVÉ | 71 create table hors partitions contre 72 enable row level security (71 + audit_logs_default, 0004:945), recoupe par script. Controle SQL nomme : supabase/tests/scenarios_etape3.sql:640-653 ("RLS ok : aucune table publique sans RLS"), rejoue par ci.yml (test lu, non execute) | Aucun. Six tables sans policy, fermees par conception : device_tokens, id_sequences, livekit_webhook_deliveries, rate_limits, session_video_route, video_config | - | Backend | - |
| AUD-IDS-012 | Toute fonction SECURITY DEFINER fixe un search_path (supabase/CLAUDE.md:12) | Tous | 188 definitions SECURITY DEFINER | CONFORME_PROUVÉ | Lecture de 207 occurrences "security definer" hors 0013 : toutes avec set search_path = '' (ou to ''). Controle SQL : scenarios_etape3.sql:655-672. Le seul cas initialement sans search_path (trigger de 0030, non SECURITY DEFINER) est corrige par 0030_tc_socle_durcissement_search_path.sql:9-25 | Aucun | - | Backend | - |
| AUD-IDS-013 | Chaque objet est qualifie dans les fonctions SECURITY DEFINER (CLAUDE.md racine) | Backend | idem | CONFORME_PARTIEL | Recherche de from/join/into/update sur 12 tables cles sans prefixe public. : zero resultat. Le test d'etape 3 (:655-672) n'exige que la presence de search_path=%, pas sa valeur ni la qualification | Qualification exhaustive non demontree (balayage partiel). Valeur vide non verifiee par test | P2 | Backend | lot G-02 (audit RLS complet, cite par 0029:49 et decisions.md:1576) |
| AUD-IDS-014 | Portes en exigence positive : aucun refus ecrit "<>" qui laisse passer NULL (migration 0029:1-60) | Backend | fonctions SECURITY DEFINER | CONFORME_PARTIEL | 0029 ferme dossiers_en_attente ; 0029:49 : trente autres fonctions protegees par leur seul revoke, dette inscrite au lot G-02 ; PROD-SNAP : 39 fonctions SECURITY DEFINER avec garde negative. Exemples a HEAD : decider_dossier 0004:523-531, guard_profile_privileged_columns 0001:541-556, creer_groupe 8 arguments 0033:564-585 (ferme par accident via "or not app_account_valid()") | Reste de gardes negatives ; la plus grave est AUD-IDS-019. SEC-PROD-SQL (PR #22, ligne 1485) en reecrit une partie ; STAGING porte 0067_positive_role_guards (LEDGER-25), hors depot | P1 | Backend | lot G-02 ; SEC-PROD (PR #22) |
| AUD-IDS-015 | Fonctions SECURITY DEFINER non executables par anon (DM 142 : validation des grants ; PM 160-175) | Anonyme | RPC publiques | CONFORME_PARTIEL | 0014:686-727 (8.a) reaccorde EXECUTE a anon sur toute fonction alors PUBLIC. Sans revoke anon dans les sources de HEAD : comptes_admin (0015:340), personnes_observables (0016:470-478), profil_de_mon_foyer (0004:322), groupes_admin (0033:731-732), creer_groupe 8 arguments (0033:564), modifier_groupe 7 arguments (0033:633). PROD-SNAP : 27 fonctions SECURITY DEFINER executables par anon | Corps fermes par filtre positif (comptes_admin, 0015:126-185) ou par accident ; defense en profondeur absente. Fermees par 0044 (ccr) et SEC-PROD-SQL (PR #22), non appliquees | P1 | Backend | lot G-02 ; SEC-PROD (PR #22) |
| AUD-IDS-016 | Fonctions reservees au serveur non executables par un compte authentifie ; "aucun role n'ecrit dans audit_logs ni session_events" (etape-0-1-fondations.md:142) | Authentifie, presence | record_session_event, next_immutable_id | CONTRADICTOIRE | record_session_event : SECURITY DEFINER sans garde (0001:912-924), revoke anon et public seulement (0001:1209-1214), annoncee "service_role seul" (docs/architecture/TEACHER_DUPLICATES_AUDIT.md:185) ; aucun appelant ni test dans le depot (git grep). PROD-SNAP lignes 99 et 119 : EXECUTE authenticated = true. session_events alimente etat_presence (0007:19). Contre-exemple dans le meme depot : 0010:662-666 revoque les fonctions video de anon, authenticated et public (le bon motif). Non reproduit a l'execution | Un compte authentifie peut ecrire des evenements de presence (source "livekit_webhook" admise par 0007:138-140). SEC-PROD-SQL (PR #22) les redonne a authenticated (lignes 922 et 942) | P0 | Backend | Aucune tache existante trouvee ; PR #22 ne la ferme pas |
| AUD-IDS-017 | Le journal n'est ecrit que par des fonctions serveur (etape-0-1-fondations.md:142) | Authentifie | log_sensitive_access | CONTRADICTOIRE | 0001:594-625 (action, table, payload libres ; acteur = auth.uid() ; verrou de table ligne 606) ; grant authenticated 0001:1216-1217 ; PROD-SNAP : authenticated = true. Le test "aucune ligne de journal ne se forge" (scenarios_etape3.sql:625-636) ne teste que l'INSERT direct | Un compte authentifie forge des lignes d'audit a son nom ou sature le journal et son verrou. SEC-PROD-SQL (PR #22, ligne 1326) revoque l'EXECUTE authenticated ; non applique | P1 | Backend | SEC-PROD (PR #22) |
| AUD-IDS-018 | Vues d'exposition sans acces anon (CLAUDE.md ; PM 160-175) | Anonyme | quatre vues | CONFORME_PARTIEL | Revoke anon present pour dix vues (0001:1193, 0005:794-798 et 1437, 0025:95 et 126, 0033:172, 263, 281). Absent pour mes_codes_appairage_v (0004:298), mes_appareils_v (0004:773), profils_du_foyer_v (0004:910), presence_seance_v (0007:281, 0011:70). PROD-SNAP section ACL : anon avec tous droits sur ces quatre vues ; vues security_barrier sans security_invoker | Lecture anon vide par predicat (auth.uid() ou app_household_id() NULL), non execute | P2 | Backend | lot G-02 |
| AUD-IDS-019 | Seul un administrateur modifie role, foyer, statut de compte et acces (ADR-014 ; 0003:15-17 ; commentaire 0001:549) | Tout compte en cours d'inscription | profiles, guard_profile_privileged_columns | CONTRADICTOIRE | 0001:541-560 : if app_role() <> 'admin' and (colonnes privilegiees changent) ; 0001:713-715 profiles_self_update (id = auth.uid()) ; 0001:1201 grant update sur toutes les tables a authenticated, aucun revoke ulterieur (git grep) ; 0038:68 : sans profil, le hook ne pose aucune revendication ; lib/core/session/source_session.dart:20-25 le reconnait ("le jeton emis avant la creation ne les porte pas encore") ; config.toml:168 jwt_expiry = 3600 ; config.toml:179 enable_signup = true. Aucun test ne couvre un jeton sans role (git grep des tests) | Chaine lue de bout en bout, non executee : un jeton emis avant la creation du profil a app_role() NULL ; NULL <> 'admin' vaut NULL ; la condition du garde ne se declenche pas ; le titulaire peut ecrire role, household_id, account_status, access_until de sa ligne pendant la vie du jeton. SEC-PROD-SQL (PR #22, ligne 1485) reecrit le garde ; non applique, colonnes toujours ouvertes en UPDATE | P0 | Backend | SEC-PROD (PR #22) ; aucune tache existante trouvee pour le test de jeton sans role |
| AUD-IDS-020 | Le genre qui borne la lecture des dossiers d'identite ne se choisit pas librement (0004:20-31 ; etape-0-1 matrice "filtre genre") | Tout compte, personnel | profiles.gender | CONTRADICTOIRE | 0004:26 (colonne ajoutee, "seul usage : cloisonnement") ; 0004:129-152 et 0004:185-213 (genre lu sur profiles) ; garde 0001:546-550 ne liste pas gender ; profiles_self_update 0001:713-715 | Un membre du personnel modifie son propre genre puis lit la partition de l'autre genre ; un deposant modifie son genre avant depot et choisit qui verra sa piece. Non execute | P1 | Backend | Aucune tache existante trouvee |
| AUD-IDS-021 | Journal d'audit append-only, chaine, falsification visible (supabase/CLAUDE.md:15) | Admin | audit_logs, verifier_chaine_audit ; /admin/securite-audit/journal | CONFORME_PROUVÉ | Triggers 0001:567-583 et revoke update/delete 0001:584 ; verifier_chaine_audit 0009:243-305 ; RLS de la partition 0004:945 ; tests scenarios_etape3.sql:619-636, scenarios_adm04.sql:292 (J4), 328 (J5 : modification visible), 387 (J6 : suppression visible) ; route Routes.adminSecuriteAuditJournal (app_router.dart) ; tests lus, non executes | Aucun sur l'immuabilite. L'ecriture libre par un compte est traitee en AUD-IDS-017 | - | Backend | ADM-04 |
| AUD-IDS-022 | Lecture du journal limitee a l'administration (etape-0-1 matrice : audit_logs L pour admin et controleur) | Controleur | audit_logs | CONFORME_PARTIEL | Policy audit_logs_read 0001:1149-1152 (admin et controleur, sans app_account_valid) conforme a la matrice ; RPC journal_audit reservees a admin (scenarios_adm04.sql:89 J1) ; commentaire 0034:60-61 "reserve a l'administration" inexact | Le controleur lit la table directement, sans passer par les RPC. Texte de 0034 a corriger ; decision de matrice a confirmer (CTR-IDS-06) | P2 | Backend, gouvernance | Aucune tache existante trouvee |

### 2.3 Bloc C - Authentification, jeton, sessions

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-023 | Le hook de jeton pose role et foyer sans jamais rendre NULL ; role et foyer lus du JWT (supabase/CLAUDE.md:13 ; DM 171) | Tous | custom_access_token_hook ; ClaimsJwt | CONFORME_PROUVÉ | 0038:50-120 (coalesce, garde app_metadata, dernier filet) ; bloc de verification de sortie 0038:130-167 (execute a l'application) ; config.toml:292-294 (hook active, uri pg-functions) ; app_role() lit le JWT 0001:391-396 ; lecture cote client lib/core/session/claims_jwt.dart:59-85 ; tests scenarios_hook_jeton.sql:72 (H1), 116 (H2), 259 (H6), 290-317 (H7), 369 (H9), lus non executes | Aucun dans le depot. Activation reelle du hook en PROD affirmee par docs/HANDOFF.md, non verifiee par l'audit | - | Backend | Correctif du 21/09 (commit 1355669) |
| AUD-IDS-024 | L'inscription publique n'ouvre que tuteur et enseignant, en pending_kyc, ecrit en dur (ADR-014 ; decisions.md:545-551) | Visiteur | creer_profil_inscription ; /inscription | CONFORME_PROUVÉ | 0004:347-420 (refus de tout autre role ligne 370, statut en dur ligne 405) ; tests scenarios_etape3.sql:45 (S3a), 64 (S3b), 76 (S3c), 94 (S3d), 591 (ADR-014) ; route Routes.inscription (app_router.dart:122) ; porte PorteAcces.inscription (session_state.dart:25) ; redirection_test.dart:304-381 | Aucun sur la fonction. L'escalade apres creation est AUD-IDS-019 | - | Backend | ADR-014 |
| AUD-IDS-025 | Un compte pending_kyc ou desactive n'atteint aucune route protegee et ne lit rien cote serveur (etape-3-auth-kyc, scenario 3 ; DM 171) | Compte en attente ou suspendu | deciderRedirection ; /attente et sous-routes ; app_account_valid | CONFORME_PROUVÉ | redirection.dart:64-69 ; test nomme "Scenario 3" dans test/router/redirection_test.dart:24-111 (26 routes protegees x pending_kyc et disabled) ; serveur : app_account_valid 0001:412-423 (n'accepte que active et provisional_active) ; 0003:5-17 ; scenarios_etape3.sql:547 ("Etat ok : le portail d'attente") ; tests lus, non executes | Aucun pour les roles tuteur, enseignant, eleve. Les roles a policies "role seul" sont traites en AUD-IDS-030 | - | Frontend, backend | TUT-00b |
| AUD-IDS-026 | Chaque role reste dans son espace ; le routeur n'est pas une barriere (lib/CLAUDE.md "Ce que le routeur n'est pas") | Tous | redirection.dart ; Routes.prefixePour | CONFORME_PROUVÉ | redirection.dart:17-101 ; routes.dart:348-366 ; redirection_test.dart:115-180 (une route d'un autre role renvoie chez soi) ; garde cote serveur par RLS, voir blocs B et D | Aucun sur la commodite de navigation | - | Frontend | ENS-05 |
| AUD-IDS-027 | Le statut de compte est revalide pendant la session (DM 171 : compte suspendu, revocation) | Tous | SourceSessionSupabase | CONFORME_PARTIEL | source_session.dart:36-60 : la lecture de profiles n'a lieu qu'a la resolution initiale et a chaque evenement onAuthStateChange (rafraichissement de jeton, soit au plus toutes les 3600 s, config.toml:168) ; aucun abonnement realtime au statut | Un compte desactive garde l'acces d'interface jusqu'au prochain evenement d'authentification. La barriere reelle est app_account_valid() cote serveur, sauf AUD-IDS-030 | P1 | Frontend, backend | Aucune tache existante trouvee |
| AUD-IDS-028 | Suspension d'un compte : geste d'administration trace (DM 171) | Admin | comptes, profiles_admin_all | ABSENT | Aucun RPC ni ecran n'ecrit account_status = 'disabled' (git grep "set account_status" : seul 0004:559-561 pour approuver) ; ecran Comptes en lecture seule (lib/features/admin_comptes/comptes_page.dart) ; seule voie : UPDATE direct sous profiles_admin_all 0001:704, hors journal | La suspension, pourtant supposee par les controles de redirection (52 cas dans redirection_test.dart:24-111), n'a pas de geste trace | P1 | Backend puis frontend | Aucune tache existante trouvee |
| AUD-IDS-029 | Les droits des roles privilegies cessent des que le compte est suspendu (B-13 ; DM 171) | Admin, comptable, controleur suspendus | policies admin, comptable, controleur | CONTRADICTOIRE | Lecture des 148 policies vivantes : 55 citent le role admin sans app_account_valid (certaines ajoutent comptable ou controleur), 20 l'exigent. Exemples : profiles_admin_all 0001:704, kyc_admin_all 0001:735, devices_admin_all 0001:780, audit_logs_read 0001:1149, wallets_admin_accountant_all et payouts_admin_accountant_all (0001), storage kyc_lecture_admin 0004:1014. Comptage heuristique, quelques faux positifs possibles | Un administrateur suspendu garde son role dans son jeton (3600 s) et conserve la lecture et l'ecriture sur ces tables. Les PR #23, #27, #31 et #17 ne corrigent qu'une seule policy (guardian_visit_admin) | P1 | Backend | B-13 (PR #23, #27, #31, #17) ; lot G-02 |
| AUD-IDS-030 | Controleur : authentification a deux facteurs obligatoire (DM 171 : "Controleur : MFA imperatif") | Controleur | Auth, config | ABSENT | config.toml:304-317 (totp et phone enroll_enabled = false, verify_enabled = false, commentaire "plan Pro") ; git grep mfa, aal2, totp dans lib et migrations : zero resultat ; docs/MISE-EN-SERVICE.md:15 (plan gratuit au 07/09, ancien) | Ni enrolement, ni exigence aal2 dans une policy ou un ecran. Dependance de plan non prouvee (mention de plan dans un modele de config et un document ancien) | P1 | Backend, frontend, gouvernance | Aucune tache existante trouvee |
| AUD-IDS-031 | Parametres Auth versionnes et conformes (session, signup, redirections) | Exploitation | supabase/config.toml | IMPLÉMENTÉ_NON_PROUVÉ | config.toml:168 (jwt_expiry 3600), 174 (rotation des refresh tokens), 179 (signup ouvert), 162-166 (redirections autorisees dont http://localhost:3000 et 127.0.0.1), 185 (mot de passe minimum 6) | Reglage distant non lu ; localhost dans la liste de redirections et signup ouvert a confirmer contre le projet reel | P2 | Gouvernance, backend | ENS-05 |
| AUD-IDS-032 | Deconnexion et changement de compte purgent ce qui est local (DM 171 : cache apres revocation ; DM 175) | Tous | compte_page ; ServiceAuth.deconnexion | CONFORME_PARTIEL | compte_page.dart:108 puis service_auth.dart:67 (signOut seul) ; source_session.dart:38 seul abonne a onAuthStateChange ; aucun deleteAll ni clear sur la base Drift (git grep) ; tables locales app_database.dart:11-150 | Aucune purge de la base locale a la deconnexion ni au changement de compte | P1 | Frontend | Aucune tache existante trouvee |
| AUD-IDS-033 | Les donnees locales sont attachees au compte qui les a creees (DM 175 : une ancienne reponse cache ne devoile pas B) | Enseignant, foyer sur appareil partage | RapportsEnAttente, ProfilsFoyer, SessionsAVenir | CONFORME_PARTIEL | app_database.dart:118-150 (RapportsEnAttente sans colonne proprietaire, contenu du cahier en clair) ; depot_cahiers.dart:130 et 141 (la file rejoue sous la session courante) ; file_rapports.dart:110-130 ; ProfilsFoyer sans identifiant de compte (app_database.dart:11-42) | Sur un navigateur ou une tablette partagee, un second compte herite de la file du premier ; le refus serveur est probable mais non demontre | P1 | Frontend | Aucune tache existante trouvee |
| AUD-IDS-034 | Purge locale des photos d'enfants sur evenement serveur (ADR-012) | Foyer | PurgePhotos | PRÉSENT_MAIS_NON_RACCORDÉ | cache_media.dart:57-100 (classe) ; test/cache/purge_photos_test.dart (lu) ; git grep PurgePhotos dans lib : definition seule, aucun appelant | La regle de purge existe et est testee, mais personne ne la declenche | P2 | Frontend | ADR-012 |
| AUD-IDS-035 | Pas de succes fictif en production : le mode demonstration n'existe que par drapeau de compilation (DM 147) | Tous | ouvrirDemo ; Env | CONFORME_PARTIEL | session_controleur.dart:10-14 et 76-85 ; env.dart:39-41 (faux par defaut) ; flutter-deploy.yml:96-98 (GALERIE, PLAYGROUND, AUTH_PAR_MOT_DE_PASSE a false) ; env.dart:55-117 (refus des cles factices) ; test/config/supabase_key_validation_test.dart (lu) | Le chemin de demonstration reste compile dans le binaire ; la production le coupe par le drapeau. HANDOFF.md:3083-3097 signale des tests de connexion rouges sur ce mode (etat du 18/09, non rejoue) | P2 | Frontend | ENS-05 |
| AUD-IDS-036 | Ouverture par lien profond puis reprise apres connexion (DM 171) | Tous | deciderRedirection | CONFORME_PARTIEL | redirection.dart:37-47 : un visiteur sans session est renvoye sur /connexion sans memoriser la destination ; apres connexion, redirection vers la racine du role (redirection.dart:75-90) | Pas de reprise de la destination demandee. Aucune fuite ; confort de reprise seulement | P2 | Frontend | Aucune tache existante trouvee |
| AUD-IDS-037 | Tests de securite des sessions : compte suspendu, revocation de capacite, remplacement expire, delegation retiree, session concurrente, reconnexion reseau, cache apres revocation (DM 171) | Tous | supabase/tests ; test/ | ABSENT | git grep concurren, reconnexion, remplacement dans test/ et supabase/tests : seulement des cas LiveKit et salle (test/teaching_core), aucun cas d'authentification ; seul cas suspendu : redirection_test.dart:24-111 | Sept des huit cas demandes n'ont aucun test | P1 | Backend, frontend | Aucune tache existante trouvee |

### 2.4 Bloc D - Dossiers d'identite (KYC) et pieces

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-038 | Seuls tuteur (pour son foyer), enseignant et controleur (pour eux-memes) et administration deposent une piece ; un eleve n'en depose aucune (DM 167) | Tuteur, enseignant | /attente/piece ; DepotPiecePage ; kyc_documents | CONFORME_PROUVÉ | Policies kyc_admin_all 0001:735, kyc_guardian_insert 0001:737-742, kyc_staff_self_insert 0004:169 ; porte peut_deposer_piece_identite 0034:274-310 ; service_dossier.dart:125-151 ; route Routes.attentePiece (app_router.dart:147) ; tests scenarios_etape3.sql:113 (S4), 162 (S4b), scenarios_r2.sql:435 (R6 ter) ; lus, non executes | Aucun sur le depot de la ligne. Taille et type : AUD-IDS-050 | - | Frontend, backend | TUT-00c |
| AUD-IDS-039 | Le genre du dossier est celui du profil, jamais celui du client (etape-0-1 scenario 11) | Deposant | completer_kyc_document | CONFORME_PROUVÉ | 0004:129-152 (genre ecrase, depot refuse si inconnu) ; tests scenarios_etape3.sql:124 (S4a), 146 (S4d) ; lib/CLAUDE.md "Ce qui decide d'un droit se pose en base" | Aucun. La modifiabilite du genre du profil est AUD-IDS-020 | - | Backend | - |
| AUD-IDS-040 | Accès aux pieces d'identite limite au personnel explicitement habilite, pas au controleur par simple role (DM 167 ; etape-0-1 matrice : controleur "-" sur kyc_documents) | Controleur | read_kyc_documents ; autoriser_lecture_piece_identite ; storage kyc | CONTRADICTOIRE | 0004:187 (not in ('admin','controller')), 0034:152 (in ('admin','controller')), 0004:1014-1018 (policy kyc_lecture_admin : admin et controleur) ; R3 (scenarios_r2.sql:236-266) teste guardian, teacher, student, jamais controller. REG-35 (PR #35, section 7) releve le meme defaut. SEC-PROD-SQL (PR #22, ligne 1052-1065) reserve read_kyc_documents a admin et compte valide | Le controleur lit les pieces par role seul ; aucune notion de "personnel habilite" dans le schema | P0 | Backend (decision d'habilitation : gouvernance) | ALIGN-1410-BACK (cite par PR #35) ; SEC-PROD (PR #22) |
| AUD-IDS-041 | L'ouverture d'une piece passe par la porte serveur qui autorise, journalise puis signe (ADR-002 ; 0034 section 2) | Admin | piece-identite-acces ; ServiceValidation.apercu | PRÉSENT_MAIS_NON_RACCORDÉ | Porte et fonction Edge presentes : 0034:141-221, supabase/functions/piece-identite-acces/index.ts:57-84, tests scenarios_r2.sql:271-333 (R4, R5). Cote Flutter : service_validation.dart:221-223 signe l'URL directement par createSignedUrl sur le seau kyc ; git grep piece-identite dans lib : zero appel ; 0034:23-26 reconnait ce contournement | L'apercu reel ne passe ni par l'autorisation en base ni par la trace kyc_document_open. SEC-PROD-SQL (PR #22, lignes 1160-1168) supprime la policy de lecture directe : fusionner cela sans changer service_validation.dart casserait ADM-02 | P0 | Frontend et backend (contrat partage) | ADM-02 ; SEC-PROD (PR #22) |
| AUD-IDS-042 | Un membre du personnel d'un genre ne lit aucune piece de l'autre genre, jusque dans l'ouverture d'une piece (etape-0-1 matrice ; DM 167) | Admin | read_kyc_documents ; storage | CONFORME_PARTIEL | Partition par RPC : 0004:180-215 ; tests scenarios_etape3.sql:208-264 (S5a a S5d), scenarios_r2.sql:271 (R4). Contournements : policy storage sans filtre de genre 0004:1014-1018 (un client administrateur liste le seau et signe n'importe quelle cle), genre modifiable AUD-IDS-020 | La partition ne tient que sur le chemin RPC | P1 | Backend | SEC-PROD (PR #22) |
| AUD-IDS-043 | Toute lecture sensible de pieces est tracee (DM 167) | Admin, controleur | log_sensitive_access | CONFORME_PARTIEL | read_kyc_documents journalise kyc_read 0004:207-210 (test S5d, scenarios_etape3.sql:264) ; autoriser_lecture_piece_identite journalise kyc_document_open 0034:190-205 (R5). Mais l'apercu reel (AUD-IDS-041) ne passe par aucune des deux traces de piece individuelle | La lecture d'une piece individuelle n'est pas tracee sur le chemin utilise par l'application | P1 | Frontend, backend | ADM-02 |
| AUD-IDS-044 | Une decision de dossier exige un dossier encore en attente et une version attendue ; une seconde decision ne l'ecrase pas (annexe 11 citee par REG-35 section 7) | Admin | decider_dossier ; /admin/personnes/dossiers | CONTRADICTOIRE | 0004:523-585 : aucun controle de l'etat actuel ; 0004:543-548 reecrit status, verified_by, verified_at ; 0004:555-561 n'active le compte que s'il est pending_kyc mais ne le desactive jamais ; test scenarios_etape3.sql:286-317 (ADM-02a a c) ne couvre pas la double decision | Une piece approuvee peut etre rejetee (ou l'inverse) sans refus, et le compte reste actif. Chaque decision est tracee (kyc_decision) mais rien ne la refuse | P1 | Backend | ALIGN-1410-BACK (PR #35) |
| AUD-IDS-045 | Le serveur calcule can_validate et lit les accords signes avant validation ; confirmation avant d'approuver (REG-35 section 7) | Admin | DossiersPage | PRÉSENT_MAIS_NON_RACCORDÉ | dossiers_page.dart:270-300 : verifications en cases locales (_Case, onCocher), decision envoyee par ServiceValidation.decider (service_validation.dart:226-236) sans lecture des contrats ; contract_acceptances non consultee pour decider | La checklist est decorative : le serveur ne l'exige pas | P2 | Frontend et backend | ALIGN-1410-FRONT (PR #35) |
| AUD-IDS-046 | Un administrateur sans genre connu peut le renseigner (fail closed documente) | Admin | GenreLecteurInconnu | CONFORME_PARTIEL | 0004:202-204 (refus franc) ; service_validation.dart:184-186 et 203-215 (exception dediee, message) ; aucun ecran de saisie du genre du personnel (git grep) ; REG-35 section 7 : "bloque sans moyen de corriger" | L'issue passe aujourd'hui par un UPDATE direct, qui est aussi le contournement d'AUD-IDS-020 | P2 | Frontend, backend | ALIGN-1410-FRONT (PR #35) |
| AUD-IDS-047 | Conservation des pieces : effacement effectif a l'echeance legale (DM 167 : verifier, ne pas deviner) | Tous | purge_at ; kyc_retention_days | ABSENT | purge_at pose par 0004:136-138 (90 jours par defaut, 0004:117) ; 0034:40-42 : aucune purge ecrite, pg_cron "installee nulle part" ; git grep cron.schedule : zero resultat | La date de purge est declarative, rien n'efface. Duree legale a valider (point juridique, hors regle religieuse) | P1 | Backend, gouvernance (duree) | ADR-002 (cite par 0034) ; aucune tache d'execution trouvee |
| AUD-IDS-048 | Piece KYC et photo publique de l'enseignant : deux fichiers, deux autorisations (DM 167, 928) | Enseignant | seaux kyc et photos_enseignants | CONFORME_PARTIEL | Seaux et policies distincts : 0004:998-1018 (kyc) contre 0032:629-650 (photos_enseignants) ; decisions.md:1809 : photo publique resolue par la negative avant le premier cours ; REG-35 : photo obligatoire et distincte, "facultatif en base" | Separation technique presente ; la regle d'obligation de la photo n'est pas portee par la base (CTR-IDS-09) | P2 | Backend, gouvernance | Aucune tache existante trouvee |
| AUD-IDS-049 | Photo d'identite de l'enfant avant sa premiere visio, si le contrat courant l'exige (DM 167) | Tuteur | avatars | À_ARBITRER | ADR-012 (decisions.md:379-409) : photo ajoutee par le tuteur, jamais imposee ; policies avatar_* 0004:1019-1050 ; aucune condition d'entree en salle sur la photo (autoriser_jeton_video lu en grep) | Le "contrat courant" n'est pas fourni (source introuvable) ; ne pas inventer une obligation | P2 | Gouvernance | Aucune tache existante trouvee |
| AUD-IDS-050 | Limites serveur de taille et de type sur les seaux de pieces et d'avatars | Deposants | storage.buckets | ABSENT | 0004:996-1000 (insert des seaux sans file_size_limit ni allowed_mime_types) ; git grep file_size_limit dans migrations : zero ; limite cliente seule : service_dossier.dart:76 (8 Mio), selecteur_fichier.dart:27 | Un client modifie envoie n'importe quel fichier sous son dossier (kyc_depot_self, 0004:1007-1012) | P2 | Backend | Aucune tache existante trouvee |

### 2.5 Bloc E - Acces des agents IA (ADR-025)

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-051 | Emission de jeton d'observation reservee a l'administration active, duree plafonnee a 24 h, portee figee, secret jamais stocke | Admin | creer_jeton_agent ; /admin/securite-audit/acces-agents ; AccesAgentsPage | CONFORME_PROUVÉ | 0014:273-352 (garde admin et compte valide ligne 290, plafond 1 a 24 h ligne 300, empreinte sha256 ligne 329) ; contrainte jetons_agent_duree_plafonnee 0014:140 ; trigger guard_jeton_agent_immuable 0014:170-202 ; route app_router.dart:540-543 atteinte depuis tableau_de_bord_page.dart:233 ; tests scenarios_agt01.sql:110 (A1), 149 (A2), 175 (A3), 203 (A4), 244 (A5) ; lus, non executes | Aucun | - | Backend, frontend | AGT-01, ADM-07 |
| AUD-IDS-052 | La revocation d'un jeton coupe l'acces a la requete suivante | Admin, agent | agent_pre_request ; revoquer_jeton_agent | CONFORME_PROUVÉ | 0014:527-552 (lecture de revoque_le et expire_le a chaque requete) ; agent-session/index.ts:45 (session signee de 15 minutes, sans refresh token) ; test scenarios_agt01.sql:505 (A11) ; lu, non execute | Aucun sur la revocation. La revalidation du profil observe est AUD-IDS-053 | - | Backend | AGT-01 |
| AUD-IDS-053 | Chaque requete d'agent revalide le profil observe (statut, access_until, role egal au parcours) | Agent | agent_pre_request | ABSENT | 0014:527-552 ne lit que jetons_agent ; la PR #30 ajoute cette validation (0057_agent_identity_subject.sql, 0074_agent_identity_account_validity.sql, tests scenarios_agent_identity.sql) | Un profil observe desactive ou dont le role change reste lisible jusqu'a l'expiration du jeton, pour les policies sans app_account_valid | P1 | Backend | B-20 (PR #28, #30) ; lot C (PR #10, #20) |
| AUD-IDS-054 | L'identite signee d'un agent est distincte du profil observe (SEC-01) | Agent | agent-session | CONTRADICTOIRE | agent-session/index.ts:178-190 : sub = remise.profil_observe, aud authenticated, signe avec le secret du projet (index.ts:97-107) ; _shared/clients.ts:46-61 et _shared/r2/client_appelant.ts:44-61 acceptent tout jeton valide via auth.getUser() ; aucun refus de is_agent ni de agent_token_id dans les fonctions Edge (git grep) ; ADR-025 (0014:33-36, regle 4) choisit explicitement sub = personne observee | Chaine lue, non executee : un jeton d'agent, valide pour auth.getUser() s'il est accepte sans session_id, ferait agir create-room-token et creer-profil-enfant (cle de service) comme la personne observee. La lecture seule d'agent_ro ne couvre pas ces fonctions. La PR #30 passe sub a l'identifiant opaque du jeton (supprime aussi ce vecteur) | P0 | Backend | B-20 (PR #28, #30) ; SEC-01 (PR #10) ; lot C (PR #20) |
| AUD-IDS-055 | L'agent ne peut rien ecrire : tables et fonctions (ADR-025) | Agent | agent_ro | CONFORME_PARTIEL | Tables : 0014:659-668, test scenarios_agt01.sql:289 (A6). Fonctions : 0014:686-760 (8.a et 8.b) ne couvre que celles existant a l'application ; scenarios_agt01.sql:546 (A12) ; PROD-SNAP : 48 fonctions SECURITY DEFINER executables par agent_ro dont read_kyc_documents ; 0048 (ccr) ferme les fonctions volatiles | Fonctions creees apres 0014 heritent de PUBLIC ; non reproduit a l'execution. Contournement par Edge : AUD-IDS-054 | P1 | Backend | AGT-01 ; 0048 (ccr) ; SEC-PROD (PR #22) |
| AUD-IDS-056 | Le secret d'un agent ne traine pas dans des historiques ou traces (PM 166 : acces indirects par URL, historiques) | Agent | agent_entree ; amorce_agent | CONFORME_PARTIEL | agent_entree_page.dart:29-31 et 91-95 : le jeton vit dans la query ?jeton= de l'URL, choix documente ; core/agent/amorce_agent.dart:6-21 ; supervision.dart:89-105 (nettoyer ne traite que les miettes, pas request.url) | URL d'historique, journaux d'hebergeur et eventuel rapport Sentry peuvent contenir le secret ; borne par 24 h et la revocation. Fragment plutot que query a evaluer | P2 | Frontend | AGT-00, ADR-025 |
| AUD-IDS-057 | Secret de signature des sessions d'agent isole, sans repli (agent-session) | Exploitation | ISSUPABASE_JWT_SECRET | CONFORME_PARTIEL | agent-session/index.ts:97-107 (erreur si absent ou plus court que 32 caracteres, aucun repli) ; c'est le secret HS256 du projet : sa fuite permet de forger tout role | Concentration du risque sur une fonction ; JWT asymetriques a evaluer par la gouvernance | P2 | Backend, gouvernance | Aucune tache existante trouvee |

### 2.6 Bloc F - Appareils, sessions enfant, appairage

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-058 | Code d'appairage : hache, un seul vivant par eleve, usage unique, expiration, plafond d'appareils verifie a l'arrivee | Tuteur, enfant | /tuteur/foyer/appairer/:eleveId ; creer_code_appairage ; consommer_code_appairage ; session-enfant | CONFORME_PROUVÉ | 0004:560-640 (creation) ; 0004:651-718 (consommation, for update, consumed_at) ; route app_router.dart:287 ; tests scenarios_etape3.sql:372 (S6), 381 (I4), 397 (S7a), 418 (S7b), 436 (S8a), 456 (S8b), 468 (S8c) ; lus, non executes | Aucun sur la logique en base | - | Backend, frontend | TUT-02/b |
| AUD-IDS-059 | Le code d'appairage resiste a l'essai massif et ses refus ne renseignent pas un attaquant | Anonyme, enfant | session-enfant ; consommer_code_appairage | CONFORME_PARTIEL | session-enfant/index.ts:13-20 (aucune limitation de debit, calcul de couverture de 0,06 pour cent par code) et :54 (renvoie error.message) ; 0004:671-679 (messages distincts : code inconnu, deja utilise, expire) ; _shared/clients.ts:26-30 annonce l'inverse ; table rate_limits (0001:342) sans usage | Debit non borne sur un point d'entree sans session ; l'espace est grand mais la couverture se multiplie par le nombre de codes vivants. Les messages distincts alimentent un oracle | P1 | Backend | Aucune tache existante trouvee |
| AUD-IDS-060 | Un tuteur ne revoque que les appareils de son foyer ; le jeton d'appareil est efface | Tuteur | /tuteur/foyer ; revoquer_appareil | CONFORME_PROUVÉ | 0004:731-766 (filtre foyer ligne 750, token_hash = null ligne 758) ; appareils_page.dart:84-85 ; tests scenarios_etape3.sql:491 et 508 ; lus, non executes | Aucun sur le jeton d'appareil. La session deja emise est AUD-IDS-061 | - | Backend, frontend | TUT-02 |
| AUD-IDS-061 | La revocation d'un appareil coupe la session qu'il tient | Tuteur, enfant | revoquer_appareil ; session-enfant | ABSENT | Aucun appel de auth.admin.signOut ni suppression de sessions dans supabase/functions (git grep : seulement getUserById, generateLink, createUser, deleteUser) ; 0004:757-759 n'efface que devices.token_hash ; les policies ne lisent pas devices | Le compte Auth de l'enfant garde son refresh token : un appareil perdu et revoque reste connecte tant qu'il se rafraichit. Un compte Auth est partage par les deux appareils d'un enfant : la coupure doit etre globale puis rouverte par jeton d'appareil | P1 | Backend (Edge) | Aucune tache existante trouvee |
| AUD-IDS-062 | La reouverture par jeton d'appareil verifie l'etat du compte | Enfant | profil_du_jeton_appareil | CONFORME_PARTIEL | 0004:794-814 : verifie revoked_at et deleted_at du jeton, pas account_status ni access_until du profil ni l'etat du foyer ; creer_profil_enfant copie le statut du tuteur a la creation seulement (0004:856 et 888) ; aucune propagation de suspension (git grep) | Le foyer suspendu ou un acces expire n'empeche pas la reouverture d'une session Auth ; les policies avec app_account_valid refusent ensuite la lecture | P1 | Backend | Aucune tache existante trouvee |
| AUD-IDS-063 | Un seul appareil en seance a la fois (ADR-010 niveau 1) | Eleve | autoriser_jeton_video ; create-room-token | ABSENT | decisions.md:318-330 ; git grep "autre appareil", "deja en seance", device_fingerprint dans 0010, 0033 et create-room-token : zero resultat | Aucun refus de second jeton pour un meme profil ; seule la contrainte C2 interdit deux seances qui se recouvrent | P1 | Backend | Aucune tache existante trouvee |
| AUD-IDS-064 | Le code personnel de l'eleve ne quitte pas l'appareil ; son verrouillage est proportionne | Enfant | CodeLocal ; PinPad | CONFORME_PARTIEL | code_local.dart:1-60 (empreinte salee, comparaison a duree constante, limite assumee dans le commentaire : dix mille combinaisons) ; test/appairage/code_local_test.dart (lu) ; eleve_connexion_page.dart:214-230 : aucune temporisation apres echec | Protege du frere ou de la soeur, pas d'un acces au coffre ; absence de delai apres erreurs repetees | P2 | Frontend | ADR-005, TUT-00 |
| AUD-IDS-065 | Le jeton d'appareil est range dans un coffre adapte a chaque plateforme | Enfant | StockageSecurise | IMPLÉMENTÉ_NON_PROUVÉ | stockage_securise.dart:44-100 (flutter_secure_storage) ; plateforme web de production (flutter-deploy.yml) : mecanisme reel du navigateur non lu | Sur le Web, le niveau de protection effectif n'est pas demontre | P2 | Frontend | Aucune tache existante trouvee |

### 2.7 Bloc G - Profils, roles, capacites, matricules

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-066 | Evaluateur et jure : capacites temporaires limitees par scope, jamais des roles globaux (DM 17, 925) | Evaluateur, jure | modele de capacites | ABSENT | enum app_role a six valeurs (0001:26-27) ; evaluations.evaluateur_id simple cle etrangere (0023:31), ecriture reservee a admin (0023:56-60) ; aucune table, fonction ni claim de capacite ; git grep evaluateur, jure, jury dans lib : zero | Aucune capacite scopee ni expirante. Le lot Evaluations du 12/10 est specifie "frontend only" (DM 25) mais son socle d'habilitation n'existe pas a HEAD | P1 | Contrat partage, backend | Lot Evaluations du 12/10 (DM 25) ; aucun identifiant dans docs/PROGRESS.md |
| AUD-IDS-067 | Aucun role global d'evaluateur ou de jure n'est cree par commodite (DM 17, 925) | Gouvernance | enum app_role | CONFORME_PROUVÉ | 0001:26-27 (admin, accountant, controller, teacher, guardian, student) ; creer_profil_inscription refuse tout role hors guardian et teacher (0004:370) ; test scenarios_etape3.sql:45 (S3a) ; RoleSalle et AppRole sans valeur evaluateur (lib/core/domain/enums.dart) | Aucun | - | Backend | - |
| AUD-IDS-068 | Un widget lit une capacite, jamais un role (CLAUDE.md racine, regle transverse) | Tous | ecrans | CONFORME_PARTIEL | Capacites : session_state.dart:119 (peutEcrire) ; mais peutVoirDirection est fixe a false (session_state.dart:130) ; lectures de role dans des ecrans : compte_page.dart:201 et 635-640, dossier/signature_page.dart:53 et 66, tc_observation_ui/options_entree_observation.dart:34-52 | Quatre ecrans decident d'un affichage d'apres le role ; aucune faille (le serveur decide) mais la regle n'est pas tenue | P2 | Frontend | Aucune tache existante trouvee |
| AUD-IDS-069 | L'adulte apprenant est autonome : son propre profil eleve, pas de faux tuteur ni de foyer cree pour lui (DM 163, 922) | Adulte apprenant | /inscription ; creer_profil_inscription | À_ARBITRER | inscription_page.dart:35-41 (eleveAdulte = AppRole.guardian) ; decisions.md:267-300 (ADR-009 : foyer d'une personne, tuteur de lui-meme) et 545-551 ; 0004:385-389 (un foyer est cree pour tout tuteur) ; student_profiles jamais cree pour lui (git grep insert into student_profiles : 0004:892 seul, student_type 'minor') ; PR #29 : 0052_profil_eleve_titulaire (B-07) garde role guardian et ajoute student_profiles.titulaire_profile_id | ADR-009 et DM 04.2/28.2 divergent ; DM 163 tolere "une ancienne structure nommee guardian" a condition d'un profil eleve propre, ce que la PR #29 apporte. Arbitrage de maintien du foyer d'une personne (CTR-IDS-01) | P1 | Gouvernance puis backend | B-07 (PR #29, F1) |
| AUD-IDS-070 | Les branches RLS de l'adulte autonome sont atteignables | Adulte apprenant | peut_decrire_apprenant ; peut_poser_disponibilite | PRÉSENT_MAIS_NON_RACCORDÉ | 0043:197-228 et 0005:436-449 testent student_type = 'autonomous' ; aucun producteur : creer_profil_enfant ecrit toujours 'minor' (0004:892-893), et 0043:118 n'est qu'une cohorte | Branches de securite mortes : l'adulte ne peut ni decrire son parcours ni poser de disponibilite comme eleve | P1 | Backend | B-07 (PR #29) |
| AUD-IDS-071 | Le second adulte du foyer ne recoit que les droits explicitement delegues (DM 164, 924, 175) | Second adulte | foyer | ABSENT | Un seul tuteur par foyer (households.primary_guardian_id 0001:62-69) ; creer_profil_inscription cree un nouveau foyer a chaque tuteur (0004:385-389) ; aucune table d'invitation ni de delegation dans migrations ; PR #29 : 0053_invitations_foyer (B-03), scenarios_b03_invitations_foyer.sql | HEAD n'a ni second adulte ni delegation. La PR #29 apporte l'invitation (7 jours, outbox) ; les droits delegues ne sont pas demontres dans l'extrait lu | P1 | Backend, frontend | B-03 (PR #29, F1) |
| AUD-IDS-072 | Frontieres d'age 9 vers 10, 13 vers 14, 17 vers 18 et date de naissance manquante testees (DM 163) | Mineurs, adultes | cohortes_age ; creer_profil_enfant | CONTRADICTOIRE | 0043:108-118 : cohortes 5-7, 8-10, 11-14, 15-17, 18+ ; 0043:83-88 : aucune date de naissance stockee, par decision ; creer_profil_enfant derive le mode d'un age saisi sans le conserver (0004:874) ; REG-35 (decision du 13/10) : cohortes 6-9, 10-13, 14-17, 18+ | Les bornes de HEAD ne sont pas celles des sources recentes ; sans date ni age conserve, le passage de frontiere n'est pas calculable. Aucun test de frontiere | P1 | Gouvernance (regle), backend | ALIGN-1410-BACK (PR #35) |
| AUD-IDS-073 | Matricule genere par le serveur, unique, resistant a la concurrence, conserve apres suspension (DM 159) | Tous | next_immutable_id ; profiles.immutable_id | CONFORME_PROUVÉ | 0001:501-520 (UPDATE ... RETURNING atomique sur id_sequences) ; contrainte profiles_immutable_id_unique 0001:83 ; trigger d'immuabilite 0001:523-537 ; suppression logique seulement (deleted_at) | Aucun sur ces trois proprietes. L'EXECUTE par authenticated est AUD-IDS-016 | - | Backend | - |
| AUD-IDS-074 | Matricule non predictible quand il revele une classe d'individus ; format valide du 12/10 (DM 159) | Tous | next_immutable_id | CONTRADICTOIRE | 0001:518 : ROLE-INITIALES-NNNNNN (compteur sequentiel par role, initiales du nom) ; commit b041932 sur ccr : format RA-26-4817 valide le 12/10 ; REG-35 | Le format de HEAD revele le role, les initiales et le rang d'inscription, et s'enumere | P1 | Backend, gouvernance | Aucune tache existante trouvee |
| AUD-IDS-075 | Recherche exacte par matricule soumise aux droits de l'appelant ; un code EV n'est pas un jeton d'acces (DM 159, 29.2) | Tous | recherche | ABSENT | git grep matricule, code_ev, recherche par immutable_id dans lib et migrations : aucune recherche par matricule ; la recherche transverse RECH-02 n'est pas dans le depot | Rien a exposer a HEAD ; l'exigence reste a construire sous contrainte de droits | P2 | Contrat partage | Aucune tache existante trouvee |

### 2.8 Bloc H - Secrets, configuration, deploiement, Edge

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-076 | Aucun secret versionne dans le depot, les journaux, les captures (CLAUDE.md racine ; DM 147) | Tous | depot entier | CONFORME_PROUVÉ | git grep sur 822 fichiers suivis, 13 motifs (JWT, sb_secret_, cles privees, AKIA, sk_live, URL postgres avec mot de passe, jetons GitHub et Slack, cle Google, rag_, secrets LiveKit et service role, whsec_) : zero secret ; deux correspondances triviales (gabarit <MOT_DE_PASSE_DB> dans deploy.yml:106, cle factice de test) ; git log -G sur 76 commits locaux : zero ; .gitignore (dart_define.json, .env, *.pem, *.key) ; garde CI nommee "Aucun secret R2 versionne" (ci.yml:228) | Aucun. Historique des branches distantes non fetchees non lu | - | Gouvernance, backend | ENS-05 |
| AUD-IDS-077 | Aucune cle de service dans Flutter ; la cle cliente est publiable ou anon (DM 147) | Tous | Env | CONFORME_PARTIEL | git grep service_role dans lib et test : zero ; env.dart:55-117 n'accepte que sb_publishable_ ou un JWT HS256 de role anon ; supabase_key_validation_test.dart (3 tests, lus) | Aucun test n'affirme le rejet d'une cle service_role | P2 | Frontend | ENS-05 |
| AUD-IDS-078 | Pas d'apercu compile avec les credentials PROD ; staging isole (DM 140, 147) | Exploitation | flutter-deploy.yml | CONFORME_PARTIEL | flutter-deploy.yml:1-35 (seule voie de production, push main) ; vercel.json:3-5 desactive les deploiements Git ; aucun environnement staging dans les workflows de HEAD ; PR #26 apporte la separation des apercus | Pas de canal staging a HEAD. Le deploiement part de main sans dependre de la CI (ci.yml ne tourne pas sur push) | P1 | Backend, gouvernance | PR #26 (CI apercus staging) |
| AUD-IDS-079 | Supervision sans donnee personnelle ni capture d'ecran de mineur (DM 166) | Tous | Supervision | CONFORME_PARTIEL | supervision.dart:52-72 (sendDefaultPii false, attachScreenshot false, attachViewHierarchy false, tracesSampleRate 0) ; test/observabilite/supervision_test.dart (lu) ; supervision.dart:89-105 ne nettoie que les URL des miettes | request.url et messages d'exception ne sont pas assainis ; non demontre sur Web | P2 | Frontend | Aucune tache existante trouvee |
| AUD-IDS-080 | Fonctions Edge : jeton exige par defaut, exceptions declarees et justifiees | Exploitation | supabase/config.toml ; supabase/functions | CONFORME_PARTIEL | config.toml:406-417 (seul livekit-webhook en verify_jwt = false, signature verifiee par la fonction) ; deploy.yml:48-58 ; commentaires contradictoires : config.toml:406 "sept fonctions" pour huit, livekit-webhook/index.ts:28-29 dit que session-enfant est aussi ouverte ; CORS a * dans clients.ts:13 et agent-session/index.ts:48 | Configuration saine ; commentaires inexacts ; CORS large acceptable avec jeton en en-tete mais a justifier | P2 | Backend | ENS-05 |

### 2.9 Bloc I - Ecrans d'identite routes et atteignables

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-IDS-081 | Les ecrans d'identite du catalogue sont routes et atteignables depuis un point d'entree reel (DM 25.1 point 7) | Tous | TUT-00, TUT-00b, TUT-00c et ses trois pages, ELV-01, TUT-02, ADM-02, ADM-08, ADM-07, AGT-00 | CONFORME_PARTIEL | app_router.dart:113-175 (connexion, connexion eleve, inscription, agent, attente et trois sous-pages, compte x4), 279-287 (foyer, ajout, appairage), 430-446 (dossiers, comptes), 540-543 (acces agents) ; fiches du catalogue 08-catalogue-ecrans.md:789, 891, 959, 1020, 1188, 1248, 1628, 2483, 2551, 2610 ; HANDOFF.md:3083-3088 : sept echecs de tests UI preexistants au 18/09 (dossiers_admin 1, dossier 3, inscription 2, salle 1), non rejoues | Routage et raccordement a de vrais RPC lus ; preuve de parcours et tests verts non demontres | P1 | Frontend | TUT-00, ADM-02, ADM-07, ADM-08 |
| AUD-IDS-082 | Donnees d'identite alimentees par les vrais contrats, sans double de demonstration (DM 56) | Admin, tuteur | ServiceValidation, ServiceComptes, ServiceAgent, ServiceAppairage | CONFORME_PARTIEL | service_validation.dart:203-240 (rpc dossiers_en_attente, decider_dossier), service_comptes.dart:170 (comptes_admin), service_agent.dart:228-284 (RPC agents), service_dossier.dart:100-200 (profil, contrat, depot) ; faux dans test/support/harnais.dart pour les tests uniquement | Raccordement reel pour ces cinq services. Apercu de piece non conforme : AUD-IDS-041 | P1 | Frontend | ADM-02 |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Perimetre | Decision la plus recente applicable | Statut | Consequence |
|---|---|---|---|---|---|---|
| CTR-IDS-01 | decisions.md:267-300 et 545-551 (ADR-009) ; inscription_page.dart:35-41 : l'adulte apprenant est un foyer d'une personne dont il est le tuteur | DM 163 et 922 : profil eleve propre, pas de faux tuteur ni de foyer cree pour l'acces ; PR #29 (0052, B-07) | Adulte apprenant | DM 163 tolere le role technique guardian a condition d'un profil eleve propre : la PR #29 le realise sans retirer le foyer. La direction n'a pas tranche le maintien du foyer d'une personne | Ouvert | Tant que #29 n'est pas fusionnee, les branches RLS de l'adulte autonome sont mortes (AUD-IDS-070) |
| CTR-IDS-02 | LEDGER-25 (addendum) : 0039 a 0042 presentes "dans ccr, main et le commit historique 0bfc9e46" | Arbre de HEAD (git ls-tree) : aucune de ces quatre migrations ; HEAD = origin/main | Provenance des migrations | L'arbre de HEAD fait foi pour ce que HEAD contient ; ccr contient bien les quatre | Ouvert | La phrase du rapport vise un autre etat de "main" ou un autre ref ; ne pas s'en servir pour dire que HEAD rejoue PROD |
| CTR-IDS-03 | HEAD : 0043 apres 0038 ; ccr : 0039 a 0048 | STAGING (LEDGER-25) : 0049 a 0073 ; PR : 0049 a 0061, 0057, 0058, 0074, horodate | Numerotation et ledger | Aucune decision de schema de version | Ouvert | Collisions certaines si plusieurs PR sont fusionnees ; blocage de B-01 |
| CTR-IDS-04 | etape-0-1-fondations.md:130 (matrice : controleur sans acces a kyc_documents) ; DM 167 | 0004:187, 0034:152, 0004:1014-1018 : controleur autorise | Pieces d'identite | Matrice et DM 167 : le controleur n'a pas acces | Ouvert (implementation a corriger, situation 1) | AUD-IDS-040 |
| CTR-IDS-05 | TEACHER_DUPLICATES_AUDIT.md:185 et 0001:1209-1214 : record_session_event "service_role seul" | PROD-SNAP lignes 99 et 119 : EXECUTE authenticated | Presence | La matrice (etape-0-1:142) exige des tables alimentees par des fonctions serveur | Ouvert | AUD-IDS-016 |
| CTR-IDS-06 | etape-0-1-fondations.md:142 et 0001:1148 : audit_logs lu par admin et controleur | 0034:60-61 : audit_logs "reserve a l'administration" ; 0009 (RPC admin) | Journal | Matrice de l'etape 1 (decision plus ancienne mais explicite) ; le commentaire de 0034 est inexact | Obsolete (documentaire) | Corriger le commentaire ; confirmer la matrice avant d'elargir (AUD-IDS-022) |
| CTR-IDS-07 | config.toml:406 ("sept fonctions") et livekit-webhook/index.ts:28-29 (session-enfant aussi ouverte) | config.toml:416-417 (seul livekit-webhook en verify_jwt = false) ; 9 repertoires dans supabase/functions | Fonctions Edge | config.toml fait foi | Resolu | Commentaires a corriger (AUD-IDS-080) |
| CTR-IDS-08 | 0043:108-118 : cohortes 5-7, 8-10, 11-14, 15-17, 18+ | DM 163 (9 vers 10, 13 vers 14, 17 vers 18) ; REG-35 (13/10 : 6-9, 10-13, 14-17, 18+) | Age et autonomie | REG-35 et DM 163 concordent ; HEAD est obsolete | Obsolete cote HEAD | AUD-IDS-072 |
| CTR-IDS-09 | decisions.md:1809 : pas de photo publique d'enseignant avant le premier cours | DM 167 et 928 : photo publique d'enseignant distincte du KYC ; REG-35 : obligatoire | Photo enseignant | DM 928 plus recent | Ouvert (ADR a reviser) | AUD-IDS-048 |
| CTR-IDS-10 | 0014:33-36 (regle 4) et agent-session/index.ts:190 : sub = personne observee (ADR-025) | PR #10, #20, #28, #30 (SEC-01, B-20) : sub = identifiant opaque du jeton, substitution apres validation | Identite de l'agent | SEC-01 du 09-10/10 plus recent, non fusionne ; ADR-025 non revise | Ouvert (situation 2 : risque nouveau sur decision tranchee) | AUD-IDS-054, AUD-IDS-053 |
| CTR-IDS-11 | DM 171 : controleur avec MFA obligatoire | config.toml:304-317 (MFA coupe, mention d'un plan Pro) ; MISE-EN-SERVICE.md:15 (plan gratuit, 07/09) | Controleur | DM 171 est la cible ; la dependance de plan n'est pas prouvee | Ouvert | AUD-IDS-030 |

## 4. Devoir de regard - contre-propositions (lettre A)

Chaque fiche suit les 14 champs. Situation 1 : decision tranchee, implementation defectueuse. Situation 2 : decision tranchee, risque nouveau. Situation 3 : contradiction reelle entre sources actives.

### CP-IDS-01 - Verrouiller les colonnes privilegiees et le genre de profiles (situation 1)

1. Identifiant : CP-IDS-01.
2. Source : AUD-IDS-019, AUD-IDS-020 ; 0001:541-560, 0001:713-715, 0001:1201, 0004:26.
3. Constat verifiable : le garde utilise "app_role() <> 'admin'" ; sans revendication de role la condition vaut NULL et ne leve rien ; profiles_self_update et le grant UPDATE complet laissent le titulaire ecrire role, household_id, account_status, access_until ; gender n'est pas protege. Aucun test ne couvre un jeton sans role. Chaine lue, non executee.
4. Risque : securite (prise de controle d'un compte administrateur par un inscrit, saut de foyer, contournement du cloisonnement par genre).
5. Gravite et priorite : impact critique, vraisemblance elevee tant que l'inscription est ouverte (config.toml:179), urgence immediate. P0.
6. Regle actuelle : seul un administrateur modifie role, foyer, statut et acces (ADR-014, 0003:15-17) ; le genre ne sert qu'au cloisonnement (0004:28-31).
7. Contre-proposition : (a) reecrire le garde en exigence positive, par exemple "si non (admin valide) et une colonne privilegiee ou gender change, lever" ; (b) revoquer UPDATE sur public.profiles pour authenticated et n'accorder que les colonnes ordinaires (first_name, last_name) ; (c) rendre gender immuable une fois renseigne sauf par un administrateur valide ; (d) ajouter un scenario SQL avec un jeton sans role, qui doit echouer.
8. Options alternatives : retirer profiles_self_update et passer par une RPC de mise a jour de profil (plus propre, plus de code frontend) ; garder la policy et se contenter de (a)+(c) (moins couteux, defense en une couche).
9. Consequences : ferme l'escalade ; aucun changement visible pour les roles reguliers ; les ecrans qui modifient le profil doivent n'ecrire que des colonnes ordinaires (a verifier : compte_page, profil_enseignant, appairage).
10. Perimetre : backend (migration), contrat partage (liste des colonnes ecrivables), frontend (verification des ecritures).
11. Dependances : SEC-PROD (PR #22, ligne 1485 reecrit le garde, sans revoquer UPDATE) ; arbitrage de numerotation (AUD-IDS-010).
12. Criteres d'acceptation : un jeton sans role ne modifie aucune colonne privilegiee ni gender ; un administrateur valide le peut ; un tuteur et un eleve gardent la modification de leur prenom.
13. Tests et preuves : nouveau scenario SQL "jeton sans role" ; rejeu de scenarios_etape3 ; preuve a l'execution sur base jetable puis STAGING.
14. Decision requise : aucune sur le principe (decision deja prise) ; autorisation de migration PROD par la direction.

### CP-IDS-02 - Fermer l'acces aux pieces d'identite au controleur et brancher la porte serveur (situation 1)

1. Identifiant : CP-IDS-02.
2. Source : AUD-IDS-040 a AUD-IDS-043 ; 0004:187, 0004:1014-1018, 0034:141-221, service_validation.dart:221-223.
3. Constat : trois portes (RPC, autorisation R2, policy de stockage) admettent controleur par role seul ; l'apercu reel signe l'URL depuis le client avec la policy de stockage ; la porte serveur et les trois fonctions Edge existent sans appelant Flutter.
4. Risque : securite et vie privee (pieces d'identite), journalisation incomplete, cloisonnement par genre contournable via le seau.
5. Gravite et priorite : impact eleve, vraisemblance moyenne (necessite un compte controleur ou administrateur), P0.
6. Regle actuelle : matrice etape 1 (controleur "-") et DM 167.
7. Contre-proposition : (a) retirer controller des trois portes et exiger app_account_valid ; (b) supprimer la policy kyc_lecture_admin ; (c) faire appeler par ServiceValidation la fonction Edge piece-identite-acces (le client ne signe plus rien) ; (d) introduire une habilitation explicite de "personnel habilite" (flag ou table scopee) si la direction veut un second lecteur ; (e) ajouter controller au test R3.
8. Options : conserver la policy de stockage mais filtree par une fonction qui rejoue le genre et trace (plus fragile, deux chemins).
9. Consequences : ADM-02 perd son apercu tant que (c) n'est pas livre : (b) et (c) doivent partir ensemble ; benefice : trace unique par piece, cloisonnement entier.
10. Perimetre : backend (migration, Edge), frontend (service d'apercu), contrat partage (reponse de piece-identite-acces), gouvernance (qui est habilite).
11. Dependances : SEC-PROD (PR #22, lignes 1052-1065 et 1160-1168) ; fonctions piece-identite-* deployees ; R2 configure.
12. Criteres : un controleur obtient un refus sur les trois portes ; un administrateur d'un genre ne signe aucune piece de l'autre ; chaque ouverture ecrit kyc_document_open avec l'acteur.
13. Tests : R3 etendu, nouveau scenario de lecture directe du seau par un administrateur, test Dart de ServiceValidation sur la fonction Edge.
14. Decision requise : arbitrage du directeur sur la liste du personnel habilite.

### CP-IDS-03 - Reduire les fonctions executables par un compte authentifie (situation 1)

1. Identifiant : CP-IDS-03.
2. Source : AUD-IDS-015 a AUD-IDS-018 ; 0001:912-924, 0001:594-625, 0001:1209-1217, 0014:686-727, PROD-SNAP.
3. Constat : record_session_event (ecrit des evenements de presence), next_immutable_id et log_sensitive_access sont executables par authenticated en PROD d'apres le releve du 10/10 ; 27 fonctions SECURITY DEFINER le sont par anon ; quatre vues gardent des droits anon.
4. Risque : integrite (presence, absences, rapports), journal falsifiable ou sature, surface anonyme.
5. Gravite : P0 pour record_session_event, P1 pour le reste.
6. Regle : les tables de presence et de journal ne sont alimentees que par des fonctions serveur (etape-0-1:142).
7. Contre-proposition : revoquer explicitement EXECUTE de authenticated, anon et PUBLIC sur les fonctions service-only (liste blanche issue de PROD-SNAP) ; poser un test d'inventaire qui echoue si une fonction SECURITY DEFINER est executable par anon ou par authenticated hors liste blanche ; revoquer anon sur les quatre vues.
8. Options : deplacer les fonctions internes dans un schema non expose (plus durable, plus de migration).
9. Consequences : aucune regression attendue pour les appelants reels (service_role et fonctions DEFINER) ; a verifier fonction par fonction.
10. Perimetre : backend.
11. Dependances : PR #22 (candidat qui ne ferme pas record_session_event ni next_immutable_id) ; 0044 et 0048 (ccr).
12. Criteres : la liste des fonctions executables par authenticated est egale a la liste blanche ; aucune par anon hors helpers de claims.
13. Tests : scenario d'inventaire has_function_privilege sur pg_proc ; rejeu STAGING.
14. Decision requise : validation technique de la liste blanche ; autorisation PROD par la direction.

### CP-IDS-04 - Identite opaque de l'agent et refus des jetons d'agent par les fonctions Edge (situation 2)

1. Identifiant : CP-IDS-04.
2. Source : AUD-IDS-053, AUD-IDS-054, AUD-IDS-055 ; agent-session/index.ts:178-190, _shared/clients.ts:46-61.
3. Constat : le jeton signe porte sub = profil observe ; les fonctions Edge qui utilisent la cle de service identifient l'appelant par auth.getUser() et n'ecartent jamais un jeton d'agent ; la lecture seule d'agent_ro ne couvre pas ces fonctions.
4. Risque : securite (usurpation de la personne observee dans la salle video ou pour creer un profil enfant) ; chaine non executee, acceptation de getUser sans session_id non demontree.
5. Gravite : impact eleve, vraisemblance moyenne (jeton emis par un administrateur, 24 h), P0.
6. Regle : ADR-025, "l'agent ne peut rien ecrire".
7. Contre-proposition : fusionner la correction SEC-01 (sub = identifiant opaque, substitution transactionnelle apres validation, revalidation du statut et de access_until) et, en meme temps, faire rejeter par appelant() et appelantR2() tout jeton portant is_agent ou agent_token_id.
8. Options : ne rien fusionner et ajouter seulement le rejet dans appelant() (couvre les Edge, pas la substitution).
9. Consequences : reviser ADR-025 (regle 4) ; les policies existantes restent telles quelles grace au hook.
10. Perimetre : backend (migration 0057 et 0074 de la PR #30, Edge), contrat partage.
11. Dependances : PR #30 (et #10, #20, #28 variantes) ; arbitrage de numerotation.
12. Criteres : un jeton d'agent obtient 401 sur create-room-token et creer-profil-enfant ; auth.uid() vaut le profil observe seulement apres agent_pre_request.
13. Tests : scenarios_agent_identity.sql (PR #30) ; test Deno de refus ; recette STAGING.
14. Decision requise : validation technique ; mise a jour de l'ADR par la direction.

### CP-IDS-05 - Comptes privilegies suspendus, geste de suspension et MFA du controleur (situations 1 et 3)

1. Identifiant : CP-IDS-05.
2. Source : AUD-IDS-028 a AUD-IDS-030 ; 55 policies par role seul.
3. Constat : la PR B-13 ne corrige qu'une policy ; 55 policies admin, comptable ou controleur n'exigent pas app_account_valid ; aucun geste de suspension ne passe par une RPC tracee ; aucune MFA.
4. Risque : securite (un compte suspendu garde ses pouvoirs une heure), administration.
5. Gravite : P1.
6. Regle : DM 171.
7. Contre-proposition : ecrire une macro de garde (fonction app_privileged(role)) combinant role et validite et l'appliquer a toutes les policies par une migration generee et revue ; creer une RPC suspendre_compte avec motif, trace et fin de session ; activer TOTP pour le controleur et exiger aal2 dans les policies de pieces.
8. Options : n'ajouter que le controle des tables sensibles (kyc, audit, finance, appareils) dans un premier lot.
9. Consequences : cout moyen en migration ; benefice : suspension effective ; MFA dependante du plan Supabase et de l'ecran d'enrolement.
10. Perimetre : backend, frontend (ecran de suspension, enrolement), gouvernance (plan).
11. Dependances : lot G-02 ; B-13 (PR #23, #27, #31, #17).
12. Criteres : un administrateur, comptable ou controleur desactive obtient zero ligne et un refus d'ecriture sur toutes les tables ; la suspension laisse une ligne d'audit.
13. Tests : extension de scenarios_b13 a l'ensemble des tables ; test aal2 du controleur.
14. Decision requise : arbitrage du directeur sur MFA et plan.

### CP-IDS-06 - Revocation d'appareil qui coupe la session (situation 2)

1. Identifiant : CP-IDS-06.
2. Source : AUD-IDS-061 a AUD-IDS-063 ; 0004:731-766, 794-814 ; session-enfant/index.ts.
3. Constat : revoquer un appareil n'efface que son jeton ; le compte Auth de l'enfant garde ses refresh tokens ; la reouverture ne verifie pas l'etat du compte ; la regle d'un seul appareil en seance est absente.
4. Risque : securite et protection des mineurs (tablette perdue).
5. Gravite : impact moyen a eleve, vraisemblance moyenne, P1.
6. Regle : ADR-010.
7. Contre-proposition : remplacer l'appel direct par une fonction Edge qui revoque puis appelle auth.admin.signOut(scope global) sur le compte enfant, la reouverture par jeton d'appareil restant possible pour les autres appareils ; verifier account_status et access_until dans profil_du_jeton_appareil ; refuser un second jeton video actif pour un meme profil.
8. Options : ajouter un identifiant d'appareil dans la revendication du jeton et le tester dans app_account_valid (plus invasif).
9. Consequences : l'autre appareil de l'enfant doit rouvrir sa session ; effet visible mais acceptable.
10. Perimetre : backend (RPC, Edge), frontend (message apres revocation).
11. Dependances : fonction Edge supplementaire ; plan de promotion.
12. Criteres : apres revocation, le refresh token de l'appareil revoque echoue ; un foyer suspendu n'ouvre plus de session enfant.
13. Tests : scenario SQL sur profil_du_jeton_appareil ; test Deno ; recette sur STAGING.
14. Decision requise : validation technique.

### CP-IDS-07 - Isolation et purge du stockage local (situation 2)

1. Identifiant : CP-IDS-07.
2. Source : AUD-IDS-032 a AUD-IDS-034 ; app_database.dart:11-150, service_auth.dart:67.
3. Constat : la base Drift n'a pas de proprietaire de compte et n'est pas videe a la deconnexion ; la file de cahiers rejoue sous la session courante ; PurgePhotos n'a pas d'appelant.
4. Risque : confidentialite sur appareil partage (cahiers, prenoms d'enfants).
5. Gravite : P1.
6. Regle : DM 175.
7. Contre-proposition : ajouter la colonne compte_id aux tables locales sensibles et filtrer ; vider RapportsEnAttente apres envoi ou changement de compte ; brancher PurgePhotos sur l'evenement de synchronisation ; ecouter signedOut pour purger.
8. Options : une base locale par compte (cle de fichier).
9. Consequences : migration de schema Drift ; le choix de profil enfant hors ligne reste (c'est sa fonction).
10. Perimetre : frontend.
11. Dependances : version du schema Drift.
12. Criteres : apres deconnexion, aucune ligne de cahier ni de seance ne subsiste ; un second compte ne voit pas la file du premier.
13. Tests : test Dart de purge, test de file multi-comptes.
14. Decision requise : aucune.

### CP-IDS-08 - Debit et messages du code d'appairage (situation 2)

1. Identifiant : CP-IDS-08.
2. Source : AUD-IDS-059 ; session-enfant/index.ts:13-20 et 54 ; 0004:671-679.
3. Constat : aucun plafond de debit ; les messages distinguent inconnu, deja utilise et expire.
4. Risque : securite (essai massif, oracle).
5. Gravite : P1.
6. Regle : commentaire de clients.ts:26-30 (messages uniformes).
7. Contre-proposition : un seul message externe ; compteur d'essais par adresse reseau et par jour dans rate_limits (table existante, sans usage) ; limite de codes vivants par foyer.
8. Options : alphabet plus long ou duree plus courte (moins efficace).
9. Consequences : une table existante est enfin utilisee ; faux positifs derriere un meme NAT a prevoir.
10. Perimetre : backend.
11. Dependances : aucune.
12. Criteres : au-dela de N essais par fenetre, refus uniforme ; aucun message ne distingue les etats.
13. Tests : scenario SQL et test Deno.
14. Decision requise : validation technique du seuil.

### CP-IDS-09 - Decision de dossier : etat attendu et exigences lues par le serveur (situation 1)

1. Identifiant : CP-IDS-09.
2. Source : AUD-IDS-044, AUD-IDS-045 ; 0004:523-585 ; REG-35 section 7.
3. Constat : decider_dossier ne controle pas l'etat courant ; la checklist est locale.
4. Risque : integrite des decisions, double decision silencieuse.
5. Gravite : P1.
6. Regle : annexe 11 citee par REG-35 (version attendue, refus d'un dossier deja decide).
7. Contre-proposition : ajouter un parametre de version attendue et refuser un dossier deja decide avec un code (stale_dossier, already_decided) ; calculer cote serveur ce qui bloque la validation (contrats signes) ; faire passer la case a cocher par la RPC.
8. Options : verrou d'optimisme sur updated_at.
9. Consequences : le contrat de la RPC change ; l'ecran doit gerer deux nouveaux refus.
10. Perimetre : contrat partage, backend, frontend.
11. Dependances : ALIGN-1410-BACK et ALIGN-1410-FRONT (PR #35).
12. Criteres : une seconde decision est refusee ; une validation sans contrat signe est refusee.
13. Tests : extension de ADM-02a a c.
14. Decision requise : aucune.

### CP-IDS-10 - Plan de reconciliation des migrations (situation 3)

1. Identifiant : CP-IDS-10.
2. Source : AUD-IDS-001 a AUD-IDS-010 ; LEDGER-25.
3. Constat : HEAD n'a pas 0039 a 0042 (appliquees en PROD) ni 0044 a 0048 ; quatre PR se disputent les numeros 0049 a 0061 ; huit entrees de ledger PROD sans source ; aucun registre dans la branche auditee ; CI sans run sur HEAD.
4. Risque : fiabilite et securite (impossible de prouver qu'un test sur HEAD vaut pour PROD).
5. Gravite : P1, avec P0 pour les fermetures de securite en attente de GO.
6. Regle : DM 138-143.
7. Contre-proposition : ramener sur la branche de travail un registre unique (nom, version distante, hash normalise, SHA, statut) ; arbitrer un schema de version horodate pour toute nouvelle migration ; fusionner 0039 a 0048 depuis ccr dans la branche principale apres revue ; executer le rejeu complet sur PostgreSQL 17 neuf et STAGING avant tout GO ; declencher la CI aussi sur push.
8. Options : conserver main comme tronc de production et ne promouvoir que par cherry-pick (plus lent).
9. Consequences : evite les collisions ; demande une decision de numerotation.
10. Perimetre : gouvernance, backend.
11. Dependances : B-01, PR #25, PR #32, PR #26.
12. Criteres : rejeu de zero vert, schema obtenu equivalent au catalogue PROD, ledger sans entree orpheline non documentee.
13. Tests : rejeu complet, comparaison de catalogue.
14. Decision requise : arbitrage du directeur (schema de version, GO PROD).

### CP-IDS-11 - Adulte autonome, second adulte, cohortes et matricule (situation 3)

1. Identifiant : CP-IDS-11.
2. Source : AUD-IDS-069 a AUD-IDS-074 ; PR #29 ; REG-35.
3. Constat : l'adulte est un tuteur-foyer sans profil eleve, les branches RLS autonomes sont mortes, le second adulte n'existe pas, les cohortes et le matricule different des sources recentes.
4. Risque : coherence metier et securite des droits delegues.
5. Gravite : P1.
6. Regle : DM 163, 922, 924.
7. Contre-proposition : rapatrier B-07 (profil titulaire sur le meme compte) et B-03 (invitation) de la PR #29 apres revue des droits delegues ; aligner cohortes et format de matricule sur la decision du 12-13/10 ; ajouter les tests de frontiere.
8. Options : conserver ADR-009 tel quel et creer le profil eleve a la premiere connexion de l'adulte.
9. Consequences : revision d'ADR-009 ; ecrans de foyer a adapter.
10. Perimetre : gouvernance, contrat partage, backend, frontend.
11. Dependances : PR #29, #13 ; ADR a reviser.
12. Criteres : un adulte suit un cours sous son propre profil sans enfant fictif ; le second adulte n'a que les droits delegues.
13. Tests : scenarios_b03 et b07 de la PR #29 plus frontieres d'age.
14. Decision requise : arbitrage du directeur.

### CP-IDS-12 - Conservation des pieces d'identite (situation 3)

1. Identifiant : CP-IDS-12.
2. Source : AUD-IDS-047 ; 0004:117 et 136-138 ; 0034:40-42.
3. Constat : une date de purge est ecrite, aucun mecanisme n'efface.
4. Risque : vie privee et conformite.
5. Gravite : P1.
6. Regle : DM 167 (verifier contre les obligations legales).
7. Contre-proposition : tache planifiee de purge respectant le gel legal (legal_hold_since de 0034) apres validation de la duree.
8. Options : purge manuelle encadree par l'administration.
9. Consequences : necessite un ordonnanceur (pg_cron ou tache externe).
10. Perimetre : backend, gouvernance.
11. Dependances : decision de duree.
12. Criteres : aucune piece au-dela de l'echeance, hors gel.
13. Tests : scenario de purge avec gel.
14. Decision requise : validation juridique de la duree, hors regle religieuse.

### CP-IDS-13 - Hygiene de configuration et d'exposition (situation 2)

1. Identifiant : CP-IDS-13.
2. Source : AUD-IDS-031, 050, 056, 057, 079, 080.
3. Constat : localhost dans les redirections, limites de fichiers cote client seulement, jeton d'agent en query, request.url non assaini, secret HS256 unique, commentaires de configuration inexacts.
4. Risque : securite de second ordre.
5. Gravite : P2.
6. Regle : lettre A du devoir de regard.
7. Contre-proposition : retirer localhost de la liste de production ; definir file_size_limit et allowed_mime_types par seau ; transporter le jeton d'agent dans le fragment ; assainir request.url dans beforeSend ; evaluer les cles de signature asymetriques ; corriger les commentaires.
8. Options : traiter au fil des lots.
9. Consequences : faibles.
10. Perimetre : backend, frontend, gouvernance.
11. Dependances : aucune.
12. Criteres : chaque point verifie par test ou lecture de configuration.
13. Tests : test de beforeSend, scenario de depot hors limite.
14. Decision requise : aucune.

## 5. Etats d'ecran et applicabilite

Legende : P present (preuve de lecture), A absent, NA non applicable (justifie), ND non demontre.
Source commune : PageShell integre OfflineBanner (lib/core/widgets/page_shell.dart:119), donc l'etat hors ligne est applicable a tout ecran construit sur PageShell. Rien n'a ete execute.

| Ecran (fiche) | Chargement | Contenu | Vide | Erreur | Hors ligne | Session expiree | Acces refuse | Reprise |
|---|---|---|---|---|---|---|---|---|
| Connexion (TUT-00), connexion_page.dart | P (_envoi, :96-114) | P | NA (formulaire) | P (t.connexion.erreurEnvoi, :110 ; message fournisseur Google :156) | P via PageShell | NA (point d'entree) | NA | A (pas de reprise de destination, redirection.dart:37-47) |
| Connexion eleve (ELV-01), eleve_connexion_page.dart | P (_enCours) | P | P (aucun profil local : bascule sur saisie de code, :235-240) | P (_erreurCode, message codeErreur) | P (profils locaux Drift) | ND | P (jeton revoque : profil oublie, :232-241) | ND |
| Inscription (TUT-00c), inscription_page.dart | P (_envoi) | P | NA | P (_erreur, :108) | ND | ND | P (porte inscription, redirection.dart:55-62) | P (rafraichir() apres creation, source_session.dart:21-26) |
| Portail d'attente (TUT-00b), attente_page.dart | P | P | NA | P (hasError, :53) | ND | ND | P (pending_kyc et disabled : redirection_test.dart:24-111) | P (EtatDossier) |
| Accuse, contrat, depot (TUT-00c/a/b/c), signature_page.dart, depot_piece_page.dart | P (_envoi) | P | NA | P (t.kyc.erreur, t.kyc.tropVolumineux) | ND | ND | P (RLS) | ND |
| Compte (compte_page.dart) | P | P | P (EmptyState, :385, :448) | P (error: EmptyState, :377, :432) | P via PageShell | ND | NA | P (invalidation des providers) |
| Foyer et appareils (TUT-02), appareils_page.dart, appairage_page.dart, ajouter_enfant_page.dart | P | P | P (EmptyState, appareils_page.dart:62) | P (_erreur) | P (appareils_page.dart:32-33) | P (code expire avec compte a rebours, appairage_page.dart:87-124) | P (RPC) | P (RefreshIndicator) |
| Validation des dossiers (ADM-02), dossiers_page.dart | P | P | P (EmptyState, :116) | P (hasError, :111-114) | P | ND | P (genre inconnu : exception dediee) | ND |
| Comptes (ADM-08), comptes_page.dart | P | P | P (:229) | P (hasError, :84) | P via PageShell | ND | NA (lecture) | ND |
| Acces des agents (ADM-07), acces_agents_page.dart | P (_emission) | P | P (EmptyState, :358, :366, :513) | P (_erreur) | ND | P (etat expire du jeton, :436) | P (RPC) | ND |
| Entree d'un agent (AGT-00), agent_entree_page.dart | P (amorce dans main()) | P | NA | P (jeton refuse sans distinguer inconnu, revoque, expire, :119-123) | ND | ND (expireA conserve, session_agent.dart:12-39 ; re-echange a l'expiration non lu) | P | A (le jeton n'est pas range, choix documente) |

Etats globaux non applicables ou absents :

- Donnees revoquees pendant la session : applicable aux comptes suspendus ; absent cote interface (AUD-IDS-027).
- Contenu supprime : NA pour ce domaine (pieces en suppression logique, non affichees).
- Operation reussie confirmee : P pour le depot de piece et la decision ; ND pour la revocation d'appareil.
- Etat partiel multi-profils : NA pour un compte enfant (un profil par compte Auth) ; ND pour un tuteur a plusieurs enfants sur un meme appareil.

## 6. Non verifie et limites de la preuve

- Aucun test n'a ete execute : Flutter, Dart, psql et Deno sont absents. Tous les tests sont "lus, non executes". Aucune reproduction des failles des alertes ; chaines lues en entier.
- Etat reel de PROD et STAGING : non lu. Les informations de PROD proviennent de PROD-SNAP et LEDGER-25 (Codex, PR non fusionnees, 10/10/2026) et ne sont pas verifiees par moi. Elles datent de quatre jours.
- Comptages par script : 71 tables, 148 policies vivantes, 196 definitions de fonctions dont 188 SECURITY DEFINER, 55 policies "role seul" ; heuristiques par expressions regulieres, quelques faux positifs ou faux negatifs possibles (surcharges de fonctions, DO dynamiques). Aucune connexion a une base.
- Corpus coranique 0013 (1,48 Mo) : non analyse (donnees), hors balayages.
- Comparaison HEAD et ccr des migrations : par empreinte git pour tous les fichiers ; ligne a ligne pour 0006 seulement.
- Non lus : docs/design/00-bible-frontend-v2.md, docs/design/README.md, docs/architecture/etape-3-auth-kyc.md (les douze scenarios), fiches du catalogue hors index, PR #13, #20, #21, #24, #26, #28, #32, #34, #8, #7 (titres seulement). Les variantes #20 et #28 sont presentees comme voisines de #10 et #30 d'apres leurs titres, sans lecture de leurs fichiers.
- Fonctions Edge piece-identite-depot, piece-identite-confirme, archive-seance-acces, livekit-webhook (au-dela des 60 premieres lignes) : non lues en entier.
- Webhooks, LiveKit, finance, pedagogie, calendrier : hors domaine IDS ; signales seulement quand ils touchent l'identite ou l'habilitation (presence, comptable).
- Comportement de Supabase Auth non demontre : acceptation par auth.getUser() d'un jeton sans session_id (AUD-IDS-054), refresh tokens apres revocation d'appareil (AUD-IDS-061), privileges par defaut de la plateforme sur les nouvelles fonctions (inferes de PROD-SNAP).
- Parametres du projet distant (signup, redirections, mot de passe, MFA, hook actif) : lus seulement dans supabase/config.toml.
- Historique git : 76 commits locaux uniquement ; branches distantes non recuperees.
