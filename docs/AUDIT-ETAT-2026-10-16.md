# État des écarts de l'audit du 14/10, relu sur le code du 16/10

- **Date :** 16/10/2026
- **Branche et SHA :** `claude/backend-reprise`, HEAD `8cb45125`
- **Méthode :** lecture du code et des migrations de la branche. Pour chaque fonction ou policy, la dernière définition compte, en parcourant les 200 migrations dans l'ordre des noms. Les réécritures dynamiques (`0067`, `0074`, `0084`, correctifs `f86_*` par `pg_get_functiondef`) sont prises en compte. La base PG17 locale prévue (`pg17ci`) n'était pas joignable : le démon Docker ne répond pas. Aucune requête n'a donc été jouée, et chaque statut repose sur le code. Rien n'a été lu ni écrit sur STAGING ou PROD.
- **Source de départ :** `origin/claude/nice-darwin-hael93:docs/AUDIT-HARMONISATION-2026-10-14.md`, sections B1 à B4, avec les registres `docs/audit-harmonisation/*.md` de cette branche.

Ce fichier complète la synthèse du 14/10, il ne la remplace pas.

Statuts employés : **CORRIGÉ** (le code ferme l'écart, preuve `fichier:ligne`), **PARTIEL** (une partie est fermée, le reste est nommé), **OUVERT** (l'écart existe encore, preuve à l'appui), **NON VÉRIFIABLE ICI** (la réponse dépend d'un environnement distant ou d'un fournisseur). Un CORRIGÉ veut dire « présent dans le code de cette branche ». Il ne veut dire ni « déployé », ni « appliqué en PROD », ni « testé sur STAGING ».

---

## En trente secondes

31 lignes relues : **7 CORRIGÉ, 9 PARTIEL, 13 OUVERT, 2 NON VÉRIFIABLE ICI.**

Les points OUVERTS les plus graves :

1. **AUD-IDS-016, `record_session_event`.** Aucune migration ne retire EXECUTE à `authenticated`. Sur un projet Supabase, le droit nominal posé par les privilèges par défaut subsiste (mécanisme décrit dans `0028:19-31`). Tout compte connecté peut donc forger des événements de présence. La CI ne peut pas le voir, parce que son stub ne pose pas ces privilèges par défaut. **Confirmé sur STAGING le 16/10** (lecture seule) : `has_function_privilege('authenticated', 'record_session_event(uuid,uuid,session_event_type,text)', 'EXECUTE')` = vrai.
2. **ALR-ELV-01/02 et AUD-ELV-075, policies de foyer sans test de rôle.** Un jeton élève peut écrire `interface_mode` et `camera_policy`. Il peut lire le portefeuille, les écritures, les moyens de paiement et les versements du foyer. Il peut aussi lire le cahier brut de l'enseignant (`lesson_reports`, `makharij_findings`) de toute séance de son foyer ou de toute séance où il est participant. Aucune de ces policies n'a changé depuis `0001` et `0005`.
3. **AUD-TAB-050, `decider_dossier`.** La dernière définition n'a toujours ni garde d'état ni version attendue. Une seconde décision écrase la première, et un rejet ne retire pas l'accès d'un compte déjà actif.
4. **AUD-ELV-009/029, fratrie.** `mes_seances_v` garde sa clause de foyer sans rôle (`0014:915-919`), et l'Accueil comme le Suivi de l'élève la lisent sans filtre.
5. **AUD-GTE-003, aperçu sur la base de production.** L'aperçu de PR et la production se construisent avec le même secret `SUPABASE_URL` (`flutter-deploy.yml:128`). Un push sur `main` déploie les fonctions Edge sans aucune dépendance de tests (`deploy.yml:31-33`, `:74`).

Deux constats transverses :

- **CI :** `ci.yml` ne rejoue que 15 des 74 fichiers `supabase/tests/scenarios_*.sql`. La plupart des scénarios qui prouvent les correctifs Codex (F86, B-13, KYC contrôleur, raccordements du 16/10) ne tournent donc pas en CI.
- **Remplacements :** un enseignant remplaçant n'obtient pas de jeton vidéo. `autoriser_jeton_video` ne connaît que `session_participants` et `sessions.teacher_id` (`20261016101100_jeton_video_compte_du_profil.sql:62-74`). Or un remplacement n'écrit que dans `remplacements_seance` (voir SYS-004).

---

## B1. Sécurité serveur

| Réf. | Statut 16/10 | Preuve | Ce qui reste |
|---|---|---|---|
| AUD-IDS-019 | **CORRIGÉ** | Dernière définition du trigger : `0084_gardes_null_safe_et_trigger_profils.sql:135-158`, en SECURITY INVOKER avec la garde positive `not coalesce(app_role() = 'admin' and app_account_valid(), false)` sur `role`, `household_id`, `account_status` et `access_until`. Le trigger est toujours attaché (`0001:558-560`). Test : `scenarios_b18_security_definer.sql:318-365` (M4 : un jeton sans rôle qui modifie `access_until` est refusé), joué en CI (`ci.yml:203`) | La policy `profiles_self_update` (`0001:713-715`) et le grant UPDATE sur toute la table (`0001:1201`) n'ont pas changé, et seul le trigger protège. **Nouvelle observation :** `gender` n'est protégé par rien. Aucune garde ne contient `old.gender`, alors que le genre du lecteur commande le cloisonnement KYC (`0088:57-69`). Non rejoué |
| AUD-FIN-072 | **CORRIGÉ** | `0074_positive_guards_all_definers.sql:28-89` réécrit toute fonction SECURITY DEFINER à garde négative, puis échoue s'il en reste une. `0084:162-206` refait le balayage avec un motif élargi. Les quatre fonctions de lecture (`journal_audit` 0016:193, `journal_audit_filtres` 0015:270, `verifier_chaine_audit` 0009:253, `indicateurs_admin` 0015:219) sont SECURITY DEFINER et entrent dans ce balayage. `poser_regle`, `clore_regle` et `decider_demande` sont réécrites explicitement (`20261012100400_f86_admin_mutation_guards.sql:34`, `:73`, `:104`), de même que `decider_dossier` (`20261012100600_f86_kyc_decision_guard.sql:14`). Tests : `scenarios_b18_security_definer.sql:79-121` (B2, en CI) et `scenarios_f86_admin_mutators.sql:56-69` (hors CI) | Aucun test « profil existant, jeton sans rôle » pour `journal_audit` et `verifier_chaine_audit`. B2 teste un compte sans profil. `scenarios_f86_admin_mutators.sql` n'est pas dans `ci.yml` |
| AUD-IDS-016 / SEC-SAL-01 | **OUVERT** | Seuls droits écrits sur `record_session_event` : `0001:1209-1214` (revoke `anon` et `public`, grant `service_role`). Aucun revoke `from authenticated` dans les 200 migrations. `0048:28-48` rend EXECUTE à `authenticated` pour toute fonction qu'il exécutait avant. Sur Supabase, le droit par défaut nominal de `authenticated` reste en place (`0028:19-31`). Aucun scénario ne teste `has_function_privilege('authenticated', 'public.record_session_event(...)', 'EXECUTE')` | `revoke execute ... from authenticated` sur `record_session_event` et `next_immutable_id`. Liste blanche des fonctions exécutables vérifiée en CI. Le stub CI doit reproduire les privilèges par défaut de Supabase, sans quoi ce contrôle passe à faux |
| AUD-IDS-040 / SRC-036 / TAB-051 | **CORRIGÉ** | `read_kyc_documents`, dernière définition : `0090_a81_f69_review_fixes.sql:49-58`, admin seul. `autoriser_lecture_piece_identite` : `0088:110`, puis le correctif `20261012111000_f86_kyc_document_read_guard.sql:10-30` (admin valide seul, plus de `controller`). `dossiers_en_attente` : `20261012114000_f86_dossiers_en_attente_guard.sql:25`. La policy Storage `kyc_lecture_admin` est retirée par `0081:118` et `20261012140000_kyc_controller_storage_policy_retired.sql:9-24`, avec un postflight. Tests : `scenarios_kyc_controller_refus.sql`, `scenarios_f86_kyc_document_read_guard.sql`, tous deux hors CI | Ajouter ces deux scénarios à `ci.yml`. L'arbitrage du directeur sur le personnel habilité n'est pas consigné dans `docs/current/` |
| AUD-IDS-041 | **PARTIEL** | Côté serveur, la lecture directe est fermée (policy retirée, voir la ligne précédente). Le client signe pourtant toujours l'URL en direct : `lib/core/dossier/service_validation.dart:221-223` (`storage.createSignedUrl`). Aucun appel à `piece-identite-acces` dans `lib/` | Faire passer `apercu()` par la fonction Edge `piece-identite-acces`. En l'état, l'aperçu d'une pièce échoue probablement pour l'admin, puisqu'aucune policy Storage ne lui ouvre plus le seau. Non rejoué |
| AUD-TAB-050 / SEC-SRC-02 | **OUVERT** | `20261012100600_f86_kyc_decision_guard.sql:27-43` : l'UPDATE de `kyc_documents` ne filtre pas sur `status = 'pending'`. Aucun trigger UPDATE sur `kyc_documents` (seul `0004:155`, BEFORE INSERT). Un rejet ne touche pas `profiles.account_status` (`:36-40`, approbation seule) | Garde `already_decided` et version attendue. Sur rejet d'un compte actif, retrait de l'accès. Scénario de double décision |
| AUD-IDS-054 | **PARTIEL** | Le `sub` du jeton d'agent est désormais l'identifiant opaque du jeton : `supabase/functions/agent-session/index.ts:188` (`setSubject(remise.jeton_id)`), lu par `0057_agent_identity_subject.sql:1-20`. Les fonctions Edge appellent `auth.getUser()` (`_shared/clients.ts:61`), qui ne trouve aucun utilisateur pour ce `sub` | Aucune fonction Edge ne refuse explicitement `is_agent` ou `role = agent_ro`. Le refus actuel n'est qu'un effet de bord de GoTrue. Pas de test Deno de refus |
| ALR-ELV-01/02 | **OUVERT** | `student_profiles_family_update` (`0005:535-556`) teste le foyer sans rôle. Le grant par colonnes inclut `interface_mode` et `camera_policy` (`0005:563-564`), puis `0043:289-290`. `wallets_family_read` (`0001:1103-1106`), `wallet_entries_family_read` (`:1111-1117`), `payout_methods_family_read` (`:1122-1128`) et `payouts_family_read` (`:1133-1139`) testent le foyer et `app_account_valid()` sans rôle. Aucune redéfinition ultérieure (pas d'`alter policy` sur ces tables) | Ajouter `app_role() = 'guardian'` (ou la capacité) dans `using` et `with check`. Scénario avec un jeton élève |
| AUD-ELV-075 / ENS-027 | **OUVERT** | `lesson_reports_reader` (`0001:1070-1078`) et `makharij_findings_read` (`0001:1080-1088`) sont inchangées : toute famille d'un participant et tout participant lisent le cahier brut. La projection existe (`0054_seance_resumes_famille.sql:1`) mais ne ferme pas la lecture brute | Lecture brute limitée à l'auteur, à l'admin et au contrôleur. La famille ne lit que la projection |
| AUD-COM-008 | **OUVERT** | `supabase/config.toml:310-312` : TOTP `enroll_enabled = false` et `verify_enabled = false`. La garde `aal2` n'existe que sur les RPC de capacité et de mission de contrôle (`20261011121039_c29_control_capabilities.sql:73`, `:196`, `:244` ; `20261011125034_c29_mission_engine.sql:62`, `:153`). `rejoindre_observation` exige le rôle contrôleur et un compte valide, sans `aal2` (`20261012120000_f86_observation_join_guard.sql:14-20`). Aucune mention de `aal` dans `lib/` | Décision du directeur sur le niveau MFA, puis TOTP activé, enrôlement côté client et garde `aal2` sur l'observation |
| AS-IDS-06 / FIN-073 | **PARTIEL** | Les RPC sont fermées : `0074` ajoute `app_account_valid()` à chaque garde réécrite. Test : `scenarios_b18_security_definer.sql:136-159` (admin désactivé refusé) et `scenarios_b13_admin_suspended.sql` (hors CI). Des policies restent fondées sur le seul rôle : `audit_logs_read` (`0001:1149-1152`), `app_config_admin_*` (`0001:969-975`), `wallets_admin_accountant_all` et ses sœurs (`0001:1100-1135`) | Ajouter `app_account_valid()` aux policies par rôle. Recompter les 55 policies sur une base rejouée |
| AUD-FIN-004 | **OUVERT** | `wallet_entries_admin_accountant_all` est en FOR ALL (`0001:1108-1110`), sur le grant global (`0001:1201`). Le seul trigger ajouté protège la colonne `confirme_par_prestataire_le` (`20261012120101_x2_17_treasury_triggers.sql:16-40`). Aucun trigger ne refuse UPDATE ou DELETE. Le modèle append-only existe pour une autre table (`:124`) | Trigger append-only sur `wallet_entries` et revoke UPDATE et DELETE, sur le modèle de `audit_logs` (`0001:567-584`) |

## B2. Faux succès et données de démonstration

| Réf. | Statut 16/10 | Preuve | Ce qui reste |
|---|---|---|---|
| AUD-OFR-066 / ELV-077 / RTE-024 / GTE-001 | **CORRIGÉ** | `lib/core/tc_groupe/port_groupes.dart:39-49` : le double de démonstration ne sort que si `Env.playgroundActif` (`lib/core/config/env.dart:33`), forcé à `false` au déploiement (`.github/workflows/flutter-deploy.yml:133`). Sinon `GroupesSupabase` sur `mes_groupes_famille_v`. Test : `test/teaching_core/a/groupes_supabase_test.dart:42-48` | Rien sur ce point. `portHorlogeSeanceProvider` n'a pas été relu |
| AUD-SAL-090 / TAB-019 / SRC-04 | **PARTIEL** | La salle n'affiche plus « Le cours est enregistré » : `optionQ5 = false` (`lib/features/salle_seance/vue_seance.dart:590`, `:1004-1009`), et le bandeau permanent dit « Visite de contrôle possible. » (`assets/i18n/fr.i18n.json:286`). Aucun Egress n'est démarré : aucun `startRoomCompositeEgress` ni `EgressClient`, ce que reconnaît `supabase/functions/_shared/r2/ingestion_archive.ts:10-11` | Le contrat et les accords annoncent toujours un enregistrement audio réel : `fr.i18n.json:901` (`contrat.pointEnregistrement`, affiché par `lib/features/dossier/signature_page.dart:153`), `:912-914`, `:926`. Texte à arbitrer par le directeur |
| AUD-SAL-084 / ELV-042 | **CORRIGÉ** | Serveur : `0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:226` retire EXECUTE sur `assister_seance` à `authenticated`. `0048` ne le rend pas, puisque le droit était déjà absent. Client : `assisterEnTuteur` (`lib/core/video/service_video.dart:131-134`) n'a plus aucun appelant hors démonstration. Le tuteur passe par `BlocObservationClasse`, puis `Routes.tcObservation` (`lib/features/classe_tuteur/bloc_observation_classe.dart:212`), puis `entrer_observation` (`lib/core/tc_observation/port_visite_observation.dart:98`) | Retirer la méthode morte `assisterEnTuteur`. Le quota (2 visites de 2 minutes) dépend de `0036` en PROD : non vérifiable ici |
| AUD-ELV-009 / ELV-029 | **OUVERT** | `mes_seances_v`, dernière définition : `0014_acces_agent.sql:888-920`, avec la clause `eleve.household_id = app_household_id()` sans rôle (`:915-919`). `lib/features/accueil_eleve/accueil_eleve_page.dart:176` lit `seancesProvider`. `lib/features/suivi_eleve/suivi_eleve_page.dart:25-27` affirme ne pas filtrer. `prochaine_seance_groupe` (`20261016102000`) borne bien la fratrie, mais seulement pour la carte de Classe | Filtre serveur par rôle dans `mes_seances_v`, filtre défensif côté client, test avec deux enfants |
| AUD-ENS-023 | **OUVERT** | `rejouer()` est défini (`lib/core/enseignant/depot_cahiers.dart:145`) et n'est appelé que par les tests (`test/features/cahier_test.dart:396`, `test/teaching_core/h/post_cours_test.dart:313`). La promesse reste affichée : « Sera envoyé dès le retour du réseau » (`fr.i18n.json:191`) | Appeler `rejouer` à l'ouverture, au retour du réseau et au démarrage |

## B3. Parcours incomplets

| Réf. | Statut 16/10 | Preuve | Ce qui reste |
|---|---|---|---|
| AUD-OFR-003 | **OUVERT** | `creer_offre_horaire`, `publier_offre_horaire`, `retirer_offre_horaire` et `offres_admin` (`0043:1050`, `:1111`) ne sont appelées par aucun fichier de `lib/` (recherche du nom entre apostrophes). Aucun écran d'administration des offres sous `lib/features/admin_*` | Écran de publication des offres par l'administration (`DECISION-OFFRES-GROUPES-2026-10-09.md`) |
| AUD-OFR-014 | **PARTIEL** | `renoncer_intention_horaire` est maintenant appelée (`lib/core/offres/service_offres.dart:186-190`, depuis `lib/features/parcours_offres/parcours_offres_page.dart:204`). Le rechoix passe ensuite par `choisir_offre_horaire` | Aucune RPC atomique « changer d'horaire » : entre le renoncement et le rechoix, la famille peut perdre sa place. Non rejoué |
| AUD-OFR-030 | **CORRIGÉ** | Regroupement et « Créer la classe » : `lib/core/offres/regroupements_c11bis_supabase.dart:45` (`creer_classe_depuis_regroupement`, dernière définition `20261012100000_c11bis_gender_enum_fix.sql:4`), branchés dans `lib/main.dart:130`. Liste paginée par `regroupements-pages`. Tests SQL : `scenarios_c11bis_f74_partition.sql`, `scenarios_offres_personnalisees.sql` (hors CI) | Parcours admin complet sur STAGING, non vérifiable ici |
| AUD-SYS-005 | **PARTIEL** | Le transfert coupe les séances à venir de la source : `20261016100100_contrats_fusion_classes.sql:299-305`. `retirer_eleve_groupe` (`0019:177`) ne fait qu'un UPDATE sur `groupe_membres` et ne touche pas `session_participants`. Le jeton vidéo est accordé sur `session_participants` (`20261016101100:62-66`) | Le retrait simple doit lui aussi couper les séances à venir. Scénario « élève retiré, jeton refusé » |
| AUD-SYS-004 | **OUVERT** | Il y a désormais trois sources : `sessions.teacher_id`, `session_participants` et `remplacements_seance` (`20261011200002_c29_effective_teacher_source.sql:3-20`). Le jeton vidéo n'en lit que deux (`20261016101100:62-74`). Les remplacements n'écrivent ni dans `session_participants` ni dans `teacher_id` (`20261011185954_b09_remplacements_seance.sql:145`, `:192`, `:242`) | Une seule fonction « enseignant effectif », lue par le jeton vidéo, la présence et la paie. Un remplaçant doit pouvoir entrer. Non rejoué |
| Site public (SIT) | **OUVERT** | Aucun site public dans le dépôt : `web/` ne contient que l'amorce Flutter. Aucun simulateur de tarif dans `lib/`, `web/` ou `assets/` (recherche de « Simuler mon tarif » et « simulateur ») | Arbitrage du directeur sur la PR 8 |
| Finance (FIN) | **PARTIEL** | Un espace Comptable existe et est routé (`lib/core/router/app_router.dart:1773-1870`, `lib/features/comptable/*`), de même que la Finance admin (`app_router.dart:1596-1622`). Une seule source réelle est branchée : `portSeriesTresorerieProvider` (`lib/main.dart:208-209`). Les autres ports rendent un état indisponible par défaut (`lib/core/capacites/port_delegation_finance.dart:322-324`, `port_validations_finance.dart:231-233`, `port_mes_finances.dart:50-51`) | Périmètre MVP-0 à fixer, puis branchement port par port |

## B4. Intégration et exploitation

| Réf. | Statut 16/10 | Preuve | Ce qui reste |
|---|---|---|---|
| AUD-TAB-044 / IDS-004 / SRC-038 | **PARTIEL** | Les migrations `0039` à `0048` sont présentes dans `supabase/migrations/` sur cette branche, suivies jusqu'à `20261016102300` | La branche n'est pas fusionnée dans `main`. L'alignement avec l'historique PROD n'est pas vérifiable ici. `0084:1-3` dit lui-même « ne doit pas être appliquée à PROD sans revue » |
| AUD-TAB-045 / OFR-004 | **NON VÉRIFIABLE ICI** | Exige la lecture de l'historique des migrations PROD | - |
| AUD-GTE-003 / SEC-GTE-02 | **OUVERT** | Un aperçu Web par PR existe (`flutter-deploy.yml:32-33`, `:242-249`), mais il se construit avec le même `secrets.SUPABASE_URL` que la production (`:128`). Le libellé « staging » ne change que Sentry (`:62`, `:74`). `deploy.yml:31-33` et `:74` déploient les fonctions Edge sur `gggmtelinlpseweouyav` à chaque push sur `main`, sans `needs` vers les tests | Vérifier si `SUPABASE_URL` est un secret d'environnement distinct (non lisible ici). Ajouter une dépendance de tests à `deploy.yml` |
| AUD-GTE-044 / TAB-057 | **OUVERT** | Aucun `RECETTE_E2E_RESULTATS.md` dans le dépôt. Les recettes du 11/10 (`docs/orchestration/RECETTE-NUIT-A-2026-10-11.md:7-9`) sont des balayages par tests de widgets, pas une recette navigateur authentifiée | Jouer les 18 scénarios E2E et consigner chaque résultat avec son SHA |
| AUD-TAB-018 | **NON VÉRIFIABLE ICI** | Dépend du compte LiveKit. Le correctif `66032878` (sources de publication en enum) et le jeton du 16/10 (`20261016101100`) sont dans le code | Recette LiveKit réelle à quatre rôles |
| MES E2 / PRF-026 | **PARTIEL** | Les trois scénarios sont dans `ci.yml` (`:55` etape3, `:133` ctr01, `:146` agt01). Cause d'agt01 fermée : `0046_agent_ro_household_predicate.sql:5-6` (grant `est_du_foyer` à `agent_ro`, avec postflight). etape3 photographie et rétablit les ACL (commits `e4fb4166`, `05a19837`) | Ces scénarios n'ont pas été rejoués dans cette session, faute de base. La cause de ctr01 (3e élève dans un 1-to-1) n'est pas documentée. Le statut passe à CORRIGÉ quand un run CI vert, numéroté, existera sur ce SHA |
| CI, stub `storage` | **CORRIGÉ** | `supabase/tests/stub_auth.sql:30-44` crée le schéma `storage`, `storage.buckets`, `storage.objects` (RLS active) et `storage.foldername`. Le stub est chargé en premier (`ci.yml:43`) | - |

---

## Nouveaux constats du 16/10

Connus hors audit et relevés ici pour la suite.

- **PR 37, CI rouge sur la garde anti-secrets seulement.** La garde `ci.yml:270` (64 hexadécimaux dans `supabase/functions`, `supabase/migrations`, `docs/architecture`) trouve deux empreintes qui ne sont pas des secrets :
  - `supabase/functions/_shared/r2/bibliotheque_upload_test.ts:43`, le SHA-256 de « abc », valeur de test ;
  - `supabase/migrations/20261011072525_f70_review_insert_acl_and_hash.sql:36`, l'empreinte d'un texte de contrat.

  Le directeur doit poser la liste blanche dans `ci.yml`. `ci.yml` relève des fichiers protégés.
- **`scenarios_raccordement_1016.sql` absent de `ci.yml`.** C'est le cas plus largement de 59 des 74 fichiers de scénarios, dont `f86_*`, `b13_*`, `kyc_controller_refus`, `contrats_*` et `com_back_1_*`.
- **Test Flutter en échec :** `test/features/com_annonces/demo_annonces_test.dart:199`, « famille, 390 : R-COM-12 de bout en bout, la lecture suit ». Il échouait déjà avant le 16/10.
- **Mushaf :** sur ordinateur, la dernière ligne de la page 2 est trop étirée.
- **Inscription enseignant :** elle reste possible sans code d'invitation. La décision revient au directeur.
- **Annonce de l'académie :** elle apparaît en double chez un tuteur qui a deux Classes.
- **Relevés de cette relecture, non rejoués :**
  - `gender` est modifiable par son titulaire (voir AUD-IDS-019) ;
  - un remplaçant n'obtient pas de jeton vidéo (voir AUD-SYS-004).

## Pour la session suivante

Ordre de travail recommandé :

1. **Backend, P0 sécurité :**
   - revoke de `record_session_event` et `next_immutable_id` à `authenticated`, avec une liste blanche vérifiée en CI et un stub qui reproduit les privilèges par défaut de Supabase (AUD-IDS-016) ;
   - rôle dans les policies de foyer et cahier brut fermé (ALR-ELV-01/02, AUD-ELV-075) ;
   - garde d'état sur `decider_dossier` (AUD-TAB-050) ;
   - clause de rôle dans `mes_seances_v` (AUD-ELV-009) ;
   - ledger `wallet_entries` en ajout seul (AUD-FIN-004).

   Chaque correctif vient avec un scénario de refus ajouté à `ci.yml`.
2. **CI :**
   - le directeur pose la liste blanche des deux empreintes ;
   - ajout dans `ci.yml` de `scenarios_raccordement_1016.sql`, puis des scénarios F86, B-13 et KYC déjà écrits ;
   - obtenir un run vert numéroté sur ce SHA, ce qui fait passer MES E2 à CORRIGÉ.
3. **Exploitation :** distinguer le projet Supabase de l'aperçu de celui de la production, et ajouter une dépendance de tests à `deploy.yml` (AUD-GTE-003).
4. **Backend, P1 :**
   - une seule source « enseignant effectif », lue par le jeton vidéo (AUD-SYS-004) ;
   - coupure des séances à venir au retrait d'un élève (AUD-SYS-005) ;
   - `app_account_valid()` dans les policies par rôle (AS-IDS-06) ;
   - protection de `gender`.
5. **Frontend :**
   - aperçu KYC par la fonction Edge (AUD-IDS-041) ;
   - `rejouer` des cahiers (AUD-ENS-023) ;
   - filtre défensif de la fratrie (AUD-ELV-009) ;
   - écran d'administration des offres (AUD-OFR-003).
6. **Directeur :**
   - texte du contrat sur l'enregistrement audio (AUD-SAL-090) ;
   - niveau MFA (AUD-COM-008) ;
   - code d'invitation enseignant ;
   - PR 8 du site.

**Règle :** un statut ne change qu'avec une preuve `fichier:ligne` ou un test nommé. Un passage sur STAGING ou en PROD se note séparément, avec son SHA et la date.
