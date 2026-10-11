# X2-03 — Catalogue des RPC exposées à `authenticated`

Sources locales uniquement : migrations suivies `0001–0048` sur `origin/ccr-1b1bfa0b-m1kvkk`. Une entrée par signature dédupliquée à partir des `GRANT EXECUTE` directs à `authenticated`; définition source et grants historiques indiqués. Aucun accès distant ni test runtime.

## Méthode et limites

- Paramètres et retour repris de la définition `CREATE FUNCTION` correspondante; `source` pointe vers la déclaration.
- Erreurs : `RAISE EXCEPTION` explicites repérées dans le corps, avec `P0001` par défaut si aucun SQLSTATE explicite. Les erreurs des fonctions/contraintes appelées ne sont pas exhaustives.
- Effets : écritures détectées par motifs `INSERT/UPDATE/DELETE`; une requête dynamique peut échapper au relevé.
- Idempotence : mécanisme explicite repéré ou absence de marqueur explicite; aucune propriété n’est prouvée par exécution.
- Port Dart : recherche statique des noms RPC/fonction dans `lib/**/*.dart`; « aucun port repéré » signifie aucune occurrence trouvée.
- Les RPC grantées à un rôle supplémentaire le mentionnent; la capacité métier requise demeure celle des gardes SQL.

Limite d'exhaustivité : 110 signatures canoniques sont documentées à partir des grants directs. La migration `0048_revoke_public_volatile_function_execute.sql:12-42` accorde aussi conditionnellement `EXECUTE` à `authenticated` pour toute fonction volatile publique qui avait déjà ce droit. Les signatures de cet ensemble dépendent des ACL juste avant la migration; sans rejouer les migrations et lire `pg_proc`/`has_function_privilege`, elles ne sont pas reconstructibles avec certitude. Le critère « toutes les RPC exposées » reste donc partiellement non vérifié; ne pas traiter ce catalogue comme exhaustif tant que cette liste n'a pas été capturée.

## Catalogue
### `public.agent_pre_request()`

- **Paramètres:** aucun.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, anon, authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `42501` — `jeton agent revoque ou expire`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0014_acces_agent.sql:527`](../../../../supabase/migrations/0014_acces_agent.sql:527); grants: `supabase/migrations/0014_acces_agent.sql:793`.

### `public.ajouter_eleve_groupe(uuid, uuid, text)`

- **Paramètres:** p_groupe_id uuid; p_student_profile_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `ajout d'un eleve a un groupe reserve a l'administration`; `P0001` — `un motif est requis pour ajouter un eleve a un groupe`; `P0001` — `cet eleve n'existe pas ou son compte n'est pas valide`; `P0001` — `cet eleve appartient deja a un groupe actif`.
- **Effets:** `public.groupe_membres`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0019_groupes_durcissement.sql:134`](../../../../supabase/migrations/0019_groupes_durcissement.sql:134); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:422`.

### `public.ajouter_niveau_programme(uuid, text, text, text, int, text)`

- **Paramètres:** p_version_id uuid; p_code_technique text; p_nom_humain text; p_cycle text; p_ordre int; p_description text default null.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `modification du programme reservee a l'administration`; `P0001` — `version introuvable`; `P0001` — `version publiee ou archivee : creez une nouvelle version pour modifier le programme`.
- **Effets:** `public.programme_niveaux`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:134`](../../../../supabase/migrations/0020_programme_pedagogique.sql:134); grants: `supabase/migrations/0020_programme_pedagogique.sql:368`.

### `public.annonce_observation_pour_moi(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `reserve a l'eleve du groupe de cette seance`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_annonce_observation.dart`.
- **Source:** [`supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:141`](../../../../supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:141); grants: `supabase/migrations/0040_tuteur_masque_et_annonce_reservee_a_son_enfant.sql:325, supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:194`.

### `public.annonces_observation(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `reserve a l'enseignant de la seance`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_annonce_observation.dart`.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:1263`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:1263); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1302`.

### `public.annuler_evaluation(uuid, text)`

- **Paramètres:** p_evaluation_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `annulation d'une evaluation reservee a l'administration`; `P0001` — `un motif est requis pour annuler une evaluation`; `P0001` — `evaluation introuvable ou deja realisee/annulee`.
- **Effets:** `public.evaluations`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_evaluations.dart`.
- **Source:** [`supabase/migrations/0023_evaluations.sql:160`](../../../../supabase/migrations/0023_evaluations.sql:160); grants: `supabase/migrations/0023_evaluations.sql:249`.

### `public.anomalies_qualite()`

- **Paramètres:** aucun.
- **Retour:** `table( type_anomalie text, ref_id uuid, student_id uuid, student_prenom text, student_nom text, teacher_id uuid, teacher_prenom text, teacher_nom text, depuis timestamptz, controle_statut text, controle_note text )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_qualite.dart`, `lib/features/admin_pedagogie_qualite/qualite_page.dart`, `lib/features/revue_groupe/anomalies_revue.dart`.
- **Source:** [`supabase/migrations/0024_qualite_pedagogique.sql:107`](../../../../supabase/migrations/0024_qualite_pedagogique.sql:107); grants: `supabase/migrations/0024_qualite_pedagogique.sql:198`.

### `public.app_config_int(text, int)`

- **Paramètres:** p_key text; p_defaut int.
- **Retour:** `int`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0007_coran_structure_position_presence.sql:150`](../../../../supabase/migrations/0007_coran_structure_position_presence.sql:150); grants: `supabase/migrations/0007_coran_structure_position_presence.sql:421`.

### `public.assister_seance(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `assister est reserve au tuteur du foyer`; `P0002` — `seance introuvable`; `42501` — `cette seance n'est pas celle d'un enfant du foyer`; `23514` — `seance close`; `23514` — `seance pas encore commencee`; `23514` — `seance terminee`; `23514` — `ce profil participe deja a cette seance a un autre titre`.
- **Effets:** `public.session_participants`.
- **Idempotence:** idempotence mechanism explicit (ON CONFLICT/idempotency marker).
- **Port Dart:** `lib/core/tc_observation/port_visite_observation.dart`, `lib/core/video/service_video.dart`.
- **Source:** [`supabase/migrations/0012_observation_controleur.sql:398`](../../../../supabase/migrations/0012_observation_controleur.sql:398); grants: `supabase/migrations/0012_observation_controleur.sql:450`.

### `public.attribuer_eleve(uuid, uuid, int, int, text)`

- **Paramètres:** p_student_profile_id uuid; p_teacher_profile_id uuid; p_weekday int; p_hour int; p_motif text default null.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `attribution manuelle reservee a l'administration`; `P0001` — `cet enseignant n'existe pas ou son compte n'est pas valide`; `P0001` — `ce creneau n'est pas propose par ce foyer`; `P0001` — `attribuer hors des disponibilites de cet enseignant exige un motif`; `P0001` — `cet eleve a deja un enseignant`; `P0001` — `cet eleve vient d'etre pris par un enseignant`.
- **Effets:** `public.teacher_student_assignments`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/matching/service_attribution.dart`.
- **Source:** [`supabase/migrations/0008_attribution_manuelle.sql:219`](../../../../supabase/migrations/0008_attribution_manuelle.sql:219); grants: `supabase/migrations/0008_attribution_manuelle.sql:316`.

### `public.autoriser_ecoute_archive(uuid)`

- **Paramètres:** p_recording_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `compte non valide`; `22023` — `archive non precisee`; `42501` — `archive introuvable`; `42501` — `ecoute refusee : aucune relation avec cette seance`; `42501` — `archive revoquee`; `42501` — `archive expiree`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0034_r2_stockage.sql:442`](../../../../supabase/migrations/0034_r2_stockage.sql:442); grants: `supabase/migrations/0034_r2_stockage.sql:556`.

### `public.autoriser_lecture_piece_identite(uuid)`

- **Paramètres:** p_document_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `controller`
- **Erreurs SQL explicites:** `42501` — `lecture des pieces d'identite reservee a l'administration`; `42501` — `compte non valide`; `22023` — `document non precise`; `42501` — `piece introuvable ou hors de votre perimetre`; `42501` — `piece supprimee`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0034_r2_stockage.sql:141`](../../../../supabase/migrations/0034_r2_stockage.sql:141); grants: `supabase/migrations/0034_r2_stockage.sql:218`.

### `public.brouillon_cahier(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`, `teacher`
- **Erreurs SQL explicites:** `42501` — `cahier refuse`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/enseignant/modeles_enseignant.dart`, `lib/core/enseignant/service_enseignant.dart`, `lib/core/tc_parcours/port_post_cours.dart`, `lib/features/cahier/cahier_page.dart`, `lib/features/demo/enseignant_demo.dart`.
- **Source:** [`supabase/migrations/0026_durcissement_execute_enseignant.sql:83`](../../../../supabase/migrations/0026_durcissement_execute_enseignant.sql:83); grants: `supabase/migrations/0025_role_enseignant.sql:370, supabase/migrations/0026_durcissement_execute_enseignant.sql:215`.

### `public.budget_observation(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/disponibilite_observation.dart`, `lib/core/tc_observation/port_politique_observation.dart`, `lib/features/tc_observation_ui/verification_prealable.dart`.
- **Source:** [`supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:169`](../../../../supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:169); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1076, supabase/migrations/0036_observation_defauts_academie_et_plafond_visite_groupe.sql:402, supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:321`.

### `public.choisir_offre_horaire(uuid, uuid, text)`

- **Paramètres:** p_membre_id uuid; p_offre_id uuid; p_fuseau_vue text.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `ce profil n'est pas le votre ni celui de votre foyer`; `P0001` — `cette offre n'est pas compatible avec ce profil, ou n'est plus publiee`; `P0001` — `cet apprenant a deja une preference horaire enregistree`.
- **Effets:** `public.intentions_horaire`, `public.student_profiles`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/offres/service_offres.dart`.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:769`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:769); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:826`.

### `public.clore_exception_progression(uuid, text)`

- **Paramètres:** p_exception_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `cloture d'une exception de progression reservee a l'administration`; `P0001` — `un motif est requis pour clore une exception`; `P0001` — `exception introuvable ou deja cloturee`.
- **Effets:** `public.progression_exceptions`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_progression.dart`.
- **Source:** [`supabase/migrations/0022_progression_suivi.sql:104`](../../../../supabase/migrations/0022_progression_suivi.sql:104); grants: `supabase/migrations/0022_progression_suivi.sql:255`.

### `public.clore_regle(uuid, text)`

- **Paramètres:** p_override_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `seul un administrateur clot une regle`; `P0001` — `une cloture sans motif ne se relit pas`; `P0001` — `regle introuvable ou deja close`.
- **Effets:** `public.rule_overrides`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/regles/service_regles.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:1213`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:1213); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1239`.

### `public.cloturer_groupe(uuid, text)`

- **Paramètres:** p_groupe_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `cloture de groupe reservee a l'administration`; `P0001` — `un motif est requis pour cloturer un groupe`; `P0001` — `groupe introuvable ou deja cloture`.
- **Effets:** `public.groupe_membres`, `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0019_groupes_durcissement.sql:209`](../../../../supabase/migrations/0019_groupes_durcissement.sql:209); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:424`.

### `public.compte_en_parcours()`

- **Paramètres:** aucun.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:174`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:174); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:192`.

### `public.comptes_admin()`

- **Paramètres:** aucun.
- **Retour:** `TABLE(profile_id uuid, immutable_id text, prenom text, nom text, role app_role, etat_compte account_status, inscrit_le timestamp with time zone, acces_jusqu_au timestamp with time zone, foyer_id uuid, etat_piece text, contrats integer, a_enseignant boolean, enfants_du_foyer integer)`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/enseignants_classe.dart`, `lib/core/admin/personnes_proposables.dart`, `lib/core/admin/service_comptes.dart`.
- **Source:** [`supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:6`](../../../../supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:6); grants: `supabase/migrations/0015_administration_voit_les_personnes.sql:340, supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:290`.

### `public.creer_code_appairage(uuid)`

- **Paramètres:** p_student_profile_id uuid.
- **Retour:** `table (code text, expires_at timestamptz)`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `seul un tuteur au compte valide appaire un appareil`; `P0001` — `cet eleve n'appartient pas a votre foyer`; `P0001` — `plafond d'appareils atteint`.
- **Effets:** `public.device_pairing_codes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/appairage/service_appairage.dart`.
- **Source:** [`supabase/migrations/0004_inscription_kyc_appairage.sql:580`](../../../../supabase/migrations/0004_inscription_kyc_appairage.sql:580); grants: `supabase/migrations/0004_inscription_kyc_appairage.sql:647`.

### `public.creer_groupe(uuid, text, text, smallint, smallint, smallint)`

- **Paramètres:** p_teacher_profile_id uuid; p_type_public text; p_libelle text; p_weekday smallint; p_hour_local smallint; p_seuil_max smallint DEFAULT NULL::smallint.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `creation de groupe reservee a l'administration`; `P0001` — `cet enseignant n'existe pas ou son compte n'est pas valide`; `P0001` — `type de public inconnu : %`.
- **Effets:** `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:118`](../../../../supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:118); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:420, supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:294`.

### `public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)`

- **Paramètres:** p_teacher_profile_id uuid; p_type_public text; p_libelle text; p_weekday smallint; p_hour_local smallint; p_seuil_max smallint; p_timezone_iana text; p_couleur_jeton smallint DEFAULT NULL::smallint.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `creation de groupe reservee a l'administration`; `P0001` — `cet enseignant n'existe pas ou son compte n'est pas valide`; `P0001` — `fuseau IANA inconnu : %`; `P0001` — `type de public inconnu : %`.
- **Effets:** `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:10`](../../../../supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:10); grants: `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:292, supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:71`.

### `public.creer_jeton_agent(text, uuid, integer, boolean)`

- **Paramètres:** p_libelle text; p_profil_observe uuid; p_duree_heures integer default 8; p_identite_masquee boolean default true.
- **Retour:** `table (jeton text, jeton_id uuid, expire_le timestamptz)`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `emission reservee a l administration`; `22023` — `un jeton sans libelle ne se revoque jamais : libelle obligatoire`; `22023` — `duree hors bornes : de 1 a 24 heures`; `23503` — `profil observe introuvable, supprime ou inactif`.
- **Effets:** `public.jetons_agent`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/agent/service_agent.dart`.
- **Source:** [`supabase/migrations/0014_acces_agent.sql:273`](../../../../supabase/migrations/0014_acces_agent.sql:273); grants: `supabase/migrations/0014_acces_agent.sql:775`.

### `public.creer_offre_horaire(text, text, text, smallint[], smallint, smallint)`

- **Paramètres:** p_type_public text; p_langue_code text; p_fuseau_iana text; p_jours smallint[]; p_heure_locale smallint; p_duree_minutes smallint default null.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `creation d'offre reservee a l'administration`; `P0001` — `public inconnu : %`; `P0001` — `fuseau IANA inconnu : %`; `P0001` — `jours invalides : un tableau non vide de jours ISO distincts est attendu`; `P0001` — `l'academie annonce % seances par semaine, % jours fournis`.
- **Effets:** `public.offres_horaires`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:1050`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:1050); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:1321`.

### `public.creer_profil_inscription(text, text, text, public.gender, text)`

- **Paramètres:** p_role text; p_first_name text; p_last_name text; p_gender public.gender default null; p_timezone text default 'Europe/Paris'.
- **Retour:** `public.profiles`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `aucune session`; `P0001` — `role non ouvert a l'inscription publique : %`; `P0001` — `ce compte a deja un profil`; `P0001` — `prenom et nom sont requis`.
- **Effets:** `public.households`, `public.profiles`, `public.teacher_profiles`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/dossier/service_dossier.dart`.
- **Source:** [`supabase/migrations/0004_inscription_kyc_appairage.sql:347`](../../../../supabase/migrations/0004_inscription_kyc_appairage.sql:347); grants: `supabase/migrations/0004_inscription_kyc_appairage.sql:424`.

### `public.creer_version_programme(uuid)`

- **Paramètres:** p_source_version_id uuid default null.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `creation de version de programme reservee a l'administration`; `P0001` — `version source introuvable`.
- **Effets:** `public.programme_niveaux`, `public.programme_versions`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:94`](../../../../supabase/migrations/0020_programme_pedagogique.sql:94); grants: `supabase/migrations/0020_programme_pedagogique.sql:367`.

### `public.decider_demande(uuid, boolean, text)`

- **Paramètres:** p_request_id uuid; p_accepte boolean; p_motif text default null.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `seul un administrateur tranche une demande`; `P0001` — `un refus exige un motif`; `P0001` — `demande introuvable ou deja tranchee`.
- **Effets:** `public.matching_requests`, `public.teacher_student_assignments`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_admin.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:1243`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:1243); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1308`.

### `public.decider_dossier(uuid, boolean, text)`

- **Paramètres:** p_document_id uuid; p_approuve boolean; p_motif text default null.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `seul un administrateur decide d'un dossier`; `P0001` — `un refus exige un motif`; `P0001` — `dossier introuvable ou hors du perimetre de lecture`.
- **Effets:** `public.kyc_documents`, `public.profiles`, `public.teacher_profiles`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/dossier/service_validation.dart`.
- **Source:** [`supabase/migrations/0004_inscription_kyc_appairage.sql:523`](../../../../supabase/migrations/0004_inscription_kyc_appairage.sql:523); grants: `supabase/migrations/0004_inscription_kyc_appairage.sql:574`.

### `public.decider_placement(uuid, uuid, text)`

- **Paramètres:** p_student_id uuid; p_niveau_id uuid; p_motif text.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `decision de placement reservee a l'administration`; `P0001` — `un motif est requis pour decider un placement`; `P0001` — `cet eleve n'existe pas ou son compte n'est pas valide`; `P0001` — `ce niveau de programme n'existe pas`; `P0001` — `cet eleve a deja un niveau decide : passez par Progression pour le modifier`.
- **Effets:** `public.progression_historique`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_diagnostics.dart`.
- **Source:** [`supabase/migrations/0021_diagnostics_placement.sql:53`](../../../../supabase/migrations/0021_diagnostics_placement.sql:53); grants: `supabase/migrations/0021_diagnostics_placement.sql:145`.

### `public.definir_politique_observation_groupe(uuid, text, smallint, integer)`

- **Paramètres:** p_groupe_id uuid; p_source text; p_max_visites smallint; p_max_secondes integer.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `42501` — `reserve a l'administration`; `22023` — `source de politique inconnue : %`; `P0002` — `groupe introuvable ou deja cloture`.
- **Effets:** `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_politique_observation.dart`.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:1304`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:1304); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1345`.

### `public.definir_politique_observation_groupe(uuid, text, smallint, integer, integer)`

- **Paramètres:** p_groupe_id uuid; p_source text; p_max_visites smallint; p_max_secondes integer; p_max_secondes_par_visite integer default null.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `42501` — `reserve a l'administration`; `22023` — `source de politique inconnue : %`; `P0002` — `groupe introuvable ou deja cloture`.
- **Effets:** `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_politique_observation.dart`.
- **Source:** [`supabase/migrations/0036_observation_defauts_academie_et_plafond_visite_groupe.sql:206`](../../../../supabase/migrations/0036_observation_defauts_academie_et_plafond_visite_groupe.sql:206); grants: `supabase/migrations/0036_observation_defauts_academie_et_plafond_visite_groupe.sql:273`.

### `public.demander(text, uuid, text, text, int)`

- **Paramètres:** p_kind text; p_subject_profile_id uuid; p_motif text; p_rule_key text default null; p_rule_value int default null.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `compte non valide`; `P0001` — `une demande sans motif ne se tranche pas`; `P0001` — `vous n'etes pas partie a ce dossier`; `P0001` — `un plafond se demande pour soi`; `P0001` — `un plafond demande est un entier positif`; `P0001` — `regle non modifiable par demande : %`; `P0001` — `une regle demandee est un entier positif`; `P0001` — `cet eleve n'a pas d'enseignant a changer`; `P0001` — `sorte de demande inconnue : %`; `P0001` — `une demande de cette sorte est deja en attente pour ce dossier`.
- **Effets:** `public.matching_requests`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/matching/service_matching.dart`, `lib/core/widgets/confirm_destructive.dart`, `lib/features/_dev/playground/faux.dart`, `lib/features/admin_acces_agents/acces_agents_page.dart`, `lib/features/admin_invitations/invitations_page.dart`, `lib/features/admin_pedagogie_bibliotheque/attribution/attribution_page.dart`, `lib/features/admin_pedagogie_bibliotheque/publication/publication_page.dart`, `lib/features/admin_reprises/reprises_page.dart`, `lib/features/appareils/appareils_eleve_page.dart`, `lib/features/comptable/paiements/ligne_obligation.dart`, `lib/features/compte/compte_tuteur_page.dart`, `lib/features/creneaux/feuille_plage.dart`, `lib/features/foyer/invitation_conjoint.dart`, `lib/features/foyer/reprise_foyer.dart`, `lib/features/foyer/sortie_forfait.dart`, `lib/features/paiements_recus/recevoir_paiements_page.dart`, `lib/features/profil_enseignant/profil_enseignant_page.dart`, `lib/features/reglages_enfant/reglages_enfant_page.dart`, `lib/features/salle/salle_page.dart`, `lib/features/salle_seance/commandes_pedagogiques.dart`, `lib/features/salle_seance/dock_seance.dart`, `lib/features/tc_classe_live/classe_live_page.dart`, `lib/features/tc_espace_groupe/feuille_carte_classe.dart`, `lib/features/tc_observation_ui/entree_observation_page.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:1093`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:1093); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1170`.

### `public.demandes_en_attente()`

- **Paramètres:** aucun.
- **Retour:** `table ( id uuid, kind text, subject_profile_id uuid, subject_first_name text, subject_immutable_id text, rule_key text, rule_value jsonb, reason text, requester_role public.app_role, requested_by uuid, created_at timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `file des demandes reservee a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_admin.dart`, `lib/core/matching/service_matching.dart`, `lib/features/admin_traitement/elements_a_traiter.dart`.
- **Source:** [`supabase/migrations/0016_masquage_coherent_en_observation.sql:124`](../../../../supabase/migrations/0016_masquage_coherent_en_observation.sql:124); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1395, supabase/migrations/0016_masquage_coherent_en_observation.sql:473`.

### `public.derniere_position_groupe(uuid)`

- **Paramètres:** p_groupe_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `groupe introuvable ou acces refuse`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:1417`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:1417); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1460`.

### `public.diagnostics_a_traiter()`

- **Paramètres:** aucun.
- **Retour:** `table( student_id uuid, student_immutable_id text, student_prenom text, student_nom text, inscrit_depuis timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_diagnostics.dart`, `lib/features/admin_pedagogie_diagnostics/diagnostics_page.dart`.
- **Source:** [`supabase/migrations/0021_diagnostics_placement.sql:107`](../../../../supabase/migrations/0021_diagnostics_placement.sql:107); grants: `supabase/migrations/0021_diagnostics_placement.sql:146`.

### `public.doit_demander_feedback(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:1355`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:1355); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1415`.

### `public.dossiers_en_attente()`

- **Paramètres:** aucun.
- **Retour:** `table ( profile_id uuid, immutable_id text, first_name text, last_name text, role public.app_role, account_status public.account_status, inscrit_le timestamptz, document_id uuid, doc_type text, document_gender public.gender, object_key text, depose_le timestamptz, etat_piece text )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`
- **Erreurs SQL explicites:** `42501` — `validation des dossiers reservee a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_admin.dart`, `lib/core/dossier/service_validation.dart`, `lib/features/admin_traitement/elements_a_traiter.dart`.
- **Source:** [`supabase/migrations/0029_fermeture_dossiers_en_attente_anon.sql:73`](../../../../supabase/migrations/0029_fermeture_dossiers_en_attente_anon.sql:73); grants: `supabase/migrations/0004_inscription_kyc_appairage.sql:521, supabase/migrations/0015_administration_voit_les_personnes.sql:339, supabase/migrations/0016_masquage_coherent_en_observation.sql:472, supabase/migrations/0029_fermeture_dossiers_en_attente_anon.sql:157`.

### `public.eleves_sans_enseignant()`

- **Paramètres:** aucun.
- **Retour:** `table ( student_id uuid, first_name text, immutable_id text, household_id uuid, level text, interface_mode public.interface_mode, depuis timestamptz, creneaux jsonb )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `attribution manuelle reservee a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/matching/service_attribution.dart`.
- **Source:** [`supabase/migrations/0016_masquage_coherent_en_observation.sql:242`](../../../../supabase/migrations/0016_masquage_coherent_en_observation.sql:242); grants: `supabase/migrations/0008_attribution_manuelle.sql:116, supabase/migrations/0016_masquage_coherent_en_observation.sql:475`.

### `public.enregistrer_profil_apprentissage(uuid, text, text, text, text, text)`

- **Paramètres:** p_membre_id uuid; p_langue_code text; p_cohorte text; p_niveau_declare text; p_objectif text; p_fuseau_iana text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `ce profil n'est pas le votre ni celui de votre foyer`; `P0001` — `cohorte inconnue ou retiree : %`; `P0001` — `langue de cours inconnue ou retiree : %`; `P0001` — `un fuseau est requis : c'est lui qui fixe l'heure affichee`; `P0001` — `fuseau IANA inconnu : %`; `P0001` — `aucune fiche eleve vivante pour ce profil`.
- **Effets:** `public.households`, `public.student_profiles`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/offres/service_offres.dart`.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:585`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:585); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:660`.

### `public.enregistrer_resultat_evaluation(uuid, text, text)`

- **Paramètres:** p_evaluation_id uuid; p_resultat text; p_notes text default null.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `enregistrement d'un resultat reserve a l'administration`; `P0001` — `evaluation introuvable`; `P0001` — `cette evaluation n'est plus planifiee`.
- **Effets:** `public.evaluations`, `public.progression_historique`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_evaluations.dart`.
- **Source:** [`supabase/migrations/0023_evaluations.sql:107`](../../../../supabase/migrations/0023_evaluations.sql:107); grants: `supabase/migrations/0023_evaluations.sql:248`.

### `public.enseignants_pour(uuid)`

- **Paramètres:** p_student_profile_id uuid.
- **Retour:** `table ( teacher_id uuid, first_name text, last_name text, immutable_id text, country text, eleves_actifs integer, plafond integer, creneaux_communs jsonb )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `attribution manuelle reservee a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/matching/service_attribution.dart`.
- **Source:** [`supabase/migrations/0016_masquage_coherent_en_observation.sql:305`](../../../../supabase/migrations/0016_masquage_coherent_en_observation.sql:305); grants: `supabase/migrations/0008_attribution_manuelle.sql:201, supabase/migrations/0016_masquage_coherent_en_observation.sql:476`.

### `public.entrer_observation(uuid, text)`

- **Paramètres:** p_session_id uuid; p_role text.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `22023` — `role d'observation inconnu : %`; `42501` — `compte non valide`; `42501` — `observation reservee au tuteur`; `42501` — `observation reservee a l'administration`.
- **Effets:** `public.guardian_session_visit`, `public.session_participants`.
- **Idempotence:** idempotence mechanism explicit (ON CONFLICT/idempotency marker).
- **Port Dart:** `lib/core/tc_observation/port_visite_observation.dart`, `lib/features/tc_observation_ui/entree_observation_page.dart`.
- **Source:** [`supabase/migrations/0037_entrer_observation_rend_l_enfant_concerne.sql:56`](../../../../supabase/migrations/0037_entrer_observation_rend_l_enfant_concerne.sql:56); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1196, supabase/migrations/0037_entrer_observation_rend_l_enfant_concerne.sql:186`.

### `public.est_du_foyer(uuid)`

- **Paramètres:** p_profile_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_groupe/groupes_supabase.dart`.
- **Source:** [`supabase/migrations/0030_tc_socle.sql:47`](../../../../supabase/migrations/0030_tc_socle.sql:47); grants: `supabase/migrations/0030_tc_socle.sql:63, supabase/migrations/0046_agent_ro_household_predicate.sql:6`.

### `public.est_observateur_masque(uuid, uuid)`

- **Paramètres:** p_session_id uuid; p_profile_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:94`](../../../../supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:94); grants: `supabase/migrations/0012_observation_controleur.sql:250, supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:114`.

### `public.etat_dossier()`

- **Paramètres:** aucun.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `aucune session`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/capacites/port_consentements.dart`, `lib/core/dossier/etat_dossier.dart`, `lib/core/dossier/resignature_contrat.dart`, `lib/core/dossier/service_dossier.dart`, `lib/core/dossier/versions_contrat.dart`, `lib/features/dossier/attente_page.dart`.
- **Source:** [`supabase/migrations/0004_inscription_kyc_appairage.sql:431`](../../../../supabase/migrations/0004_inscription_kyc_appairage.sql:431); grants: `supabase/migrations/0004_inscription_kyc_appairage.sql:487`.

### `public.etat_presence(uuid, uuid)`

- **Paramètres:** p_session_id uuid; p_profile_id uuid.
- **Retour:** `public.presence_state`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`, `guardian`
- **Erreurs SQL explicites:** `42501` — `compte non valide`; `42501` — `acces refuse`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_classe/session_live_vm.dart`, `lib/core/tc_horloge/duree_academique.dart`, `lib/core/tc_horloge/fenetre_seance.dart`, `lib/features/cahier/vue_cahier.dart`, `lib/features/salle/salle_page.dart`, `lib/features/suivi_foyer/vue_suivi_foyer.dart`.
- **Source:** [`supabase/migrations/0042_etat_presence_fermee_et_jeton_video_verifie_le_compte.sql:34`](../../../../supabase/migrations/0042_etat_presence_fermee_et_jeton_video_verifie_le_compte.sql:34); grants: `supabase/migrations/0007_coran_structure_position_presence.sql:420, supabase/migrations/0042_etat_presence_fermee_et_jeton_video_verifie_le_compte.sql:163`.

### `public.evaluations_admin()`

- **Paramètres:** aucun.
- **Retour:** `table( evaluation_id uuid, student_id uuid, student_immutable_id text, student_prenom text, student_nom text, niveau_id uuid, niveau_nom_humain text, type text, statut text, date_prevue date, date_realisee date, resultat text, notes text )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_evaluations.dart`.
- **Source:** [`supabase/migrations/0023_evaluations.sql:195`](../../../../supabase/migrations/0023_evaluations.sql:195); grants: `supabase/migrations/0023_evaluations.sql:250`.

### `public.geler_archive_seance(uuid, text, boolean)`

- **Paramètres:** p_recording_id uuid; p_motif text; p_gel boolean default true.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`
- **Erreurs SQL explicites:** `42501` — `gel de conservation reserve a l'administration`; `22023` — `archive non precisee`; `22023` — `sens du gel non precise`; `22023` — `un gel de conservation exige un motif`; `42501` — `archive introuvable`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0034_r2_stockage.sql:661`](../../../../supabase/migrations/0034_r2_stockage.sql:661); grants: `supabase/migrations/0034_r2_stockage.sql:726`.

### `public.groupe_detail(uuid)`

- **Paramètres:** p_groupe_id uuid.
- **Retour:** `table( student_id uuid, student_immutable_id text, student_prenom text, student_nom text, joined_at timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`, `lib/core/enseignant/service_enseignant.dart`, `lib/core/tc_classe/port_roster_enseignant.dart`, `lib/core/tc_classe/roster_enseignant.dart`.
- **Source:** [`supabase/migrations/0019_groupes_durcissement.sql:279`](../../../../supabase/migrations/0019_groupes_durcissement.sql:279); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:426`.

### `public.groupe_roster_enseignant(uuid)`

- **Paramètres:** p_groupe_id uuid.
- **Retour:** `table ( student_id uuid, first_name text, immutable_id text, level text, riwaya text, interface_mode public.interface_mode, curriculum_path text, current_unit text, active_goals text[], resume_page int, resume_sourate int, resume_verset int )`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`, `teacher`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:787`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:787); grants: `supabase/migrations/0033_tc_vues_rpc.sql:858`.

### `public.groupes_admin()`

- **Paramètres:** aucun.
- **Retour:** `table( groupe_id uuid, libelle text, type_public text, seuil_max smallint, teacher_id uuid, teacher_immutable_id text, teacher_prenom text, teacher_nom text, weekday smallint, hour_local smallint, nombre_membres integer, actif boolean, created_at timestamptz, timezone_iana text, couleur_jeton smallint, nom_cours text, programme_niveau_id uuid )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/port_classes_admin.dart`, `lib/core/admin/service_groupes.dart`, `lib/core/enseignant/modeles_enseignant.dart`, `lib/core/tc_groupe/port_groupes.dart`.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:694`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:694); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:425, supabase/migrations/0033_tc_vues_rpc.sql:732`.

### `public.horloge_seance(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `table ( session_id uuid, debut_utc timestamptz, fin_prevue_utc timestamptz, join_opens_at_utc timestamptz, fenetre_minutes int, grace_minutes int, maintenant_utc timestamptz, tz_utilisateur text, heure_utilisateur text, jour_iso_utilisateur int, date_utilisateur date, tz_groupe text, heure_groupe text, jour_iso_groupe int, date_groupe date )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/seance_famille/port_seances_famille.dart`, `lib/core/seance_famille/seance_famille.dart`, `lib/core/tc_groupe/groupes_supabase.dart`, `lib/core/tc_horloge/horloge_supabase.dart`, `lib/core/tc_horloge/port_horloge_seance.dart`.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:427`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:427); grants: `supabase/migrations/0033_tc_vues_rpc.sql:488`.

### `public.indicateurs_admin()`

- **Paramètres:** aucun.
- **Retour:** `table( dossiers_en_attente integer, foyers_sans_enseignant integer, rapports_manquants integer, incidents_24h integer, comptes_echus integer, demandes_en_attente integer )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `centre de commande reserve a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_admin.dart`.
- **Source:** [`supabase/migrations/0015_administration_voit_les_personnes.sql:205`](../../../../supabase/migrations/0015_administration_voit_les_personnes.sql:205); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1359, supabase/migrations/0015_administration_voit_les_personnes.sql:341`.

### `public.instant_creneau(int, int, text, int)`

- **Paramètres:** p_weekday int; p_hour int; p_tz text; p_semaine_offset int default 0.
- **Retour:** `timestamptz`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_horloge/port_horloge_seance.dart`, `lib/core/tc_horloge/session_clock_vm.dart`.
- **Source:** [`supabase/migrations/0006_rattrapage_semaine_utc_et_foyer.sql:23`](../../../../supabase/migrations/0006_rattrapage_semaine_utc_et_foyer.sql:23); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:524`.

### `public.jetons_agent_actifs()`

- **Paramètres:** aucun.
- **Retour:** `table ( id uuid, libelle text, prefixe text, parcours public.app_role, profil_observe uuid, observe_identifiant text, observe_prenom text, identite_masquee boolean, expire_le timestamptz, revoque_le timestamptz, cree_le timestamptz, derniere_remise_le timestamptz, remises integer, etat text )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/agent/service_agent.dart`.
- **Source:** [`supabase/migrations/0016_masquage_coherent_en_observation.sql:376`](../../../../supabase/migrations/0016_masquage_coherent_en_observation.sql:376); grants: `supabase/migrations/0014_acces_agent.sql:781, supabase/migrations/0016_masquage_coherent_en_observation.sql:477`.

### `public.journal_audit(uuid, text, timestamptz, integer, timestamptz, bigint)`

- **Paramètres:** p_acteur uuid default null; p_action text default null; p_depuis timestamptz default null; p_limite integer default 50; p_avant_date timestamptz default null; p_avant_id bigint default null.
- **Retour:** `table ( entree_id bigint, survenu_le timestamptz, acteur uuid, role_acteur text, nom_acteur text, type_evenement text, table_visee text, ligne_visee text, details jsonb )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `journal d'audit reserve a l'administration`; `P0001` — `limite hors bornes`; `P0001` — `curseur incomplet`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/journal/service_journal.dart`, `lib/features/admin_tableau/activite_recente.dart`.
- **Source:** [`supabase/migrations/0016_masquage_coherent_en_observation.sql:167`](../../../../supabase/migrations/0016_masquage_coherent_en_observation.sql:167); grants: `supabase/migrations/0009_journal_audit.sql:139, supabase/migrations/0016_masquage_coherent_en_observation.sql:474`. `int` et `integer` sont des alias PostgreSQL d'une même signature; l'entrée n'est comptée qu'une fois.

### `public.journal_audit_filtres()`

- **Paramètres:** aucun.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `journal d'audit reserve a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/journal/service_journal.dart`.
- **Source:** [`supabase/migrations/0015_administration_voit_les_personnes.sql:260`](../../../../supabase/migrations/0015_administration_voit_les_personnes.sql:260); grants: `supabase/migrations/0009_journal_audit.sql:213, supabase/migrations/0015_administration_voit_les_personnes.sql:342`.

### `public.jours_iso_valides(smallint[])`

- **Paramètres:** p_jours smallint[].
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:299`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:299); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:311`.

### `public.maintenant_serveur()`

- **Paramètres:** aucun.
- **Retour:** `timestamptz`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/seance_famille/port_seances_famille.dart`, `lib/core/seance_famille/seance_famille.dart`, `lib/core/tc_horloge/horloge_supabase.dart`, `lib/core/tc_horloge/port_horloge_seance.dart`, `lib/features/accueil_famille/ancre_horloge_serveur.dart`.
- **Source:** [`supabase/migrations/0030_tc_socle.sql:67`](../../../../supabase/migrations/0030_tc_socle.sql:67); grants: `supabase/migrations/0030_tc_socle.sql:76`.

### `public.maj_eleve_pedagogie(uuid, text, text)`

- **Paramètres:** p_profile_id uuid; p_level text default null; p_riwaya text default null.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `seul un administrateur modifie le niveau ou la riwaya`.
- **Effets:** `public.student_profiles`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:570`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:570); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:594`.

### `public.maj_profil_enseignant(text, text[], text)`

- **Paramètres:** p_country text default null; p_languages text[] default null; p_timezone text default null.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `authentification requise`; `P0001` — `fuseau inconnu`; `P0001` — `aucun profil enseignant`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/profil/service_declaration.dart`, `lib/features/profil_enseignant/declaration_choix.dart`.
- **Source:** [`supabase/migrations/0027_maj_profil_enseignant.sql:38`](../../../../supabase/migrations/0027_maj_profil_enseignant.sql:38); grants: `supabase/migrations/0027_maj_profil_enseignant.sql:81`.

### `public.mes_rapports_en_attente()`

- **Paramètres:** aucun.
- **Retour:** `table ( session_id uuid, started_at timestamptz, ended_at timestamptz, groupe_id uuid, groupe_libelle text, nb_participants int, heures_de_retard int )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`, `teacher`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/enseignant/modeles_enseignant.dart`, `lib/core/enseignant/service_enseignant.dart`, `lib/features/demo/enseignant_demo.dart`.
- **Source:** [`supabase/migrations/0025_role_enseignant.sql:376`](../../../../supabase/migrations/0025_role_enseignant.sql:376); grants: `supabase/migrations/0025_role_enseignant.sql:426`.

### `public.modifier_groupe(uuid, text, smallint, smallint, smallint)`

- **Paramètres:** p_groupe_id uuid; p_libelle text; p_seuil_max smallint; p_weekday smallint; p_hour_local smallint.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `modification de groupe reservee a l'administration`; `P0001` — `ce groupe compte deja % membres actifs, seuil demande trop bas (%)`; `P0001` — `groupe introuvable ou deja cloture`.
- **Effets:** `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:215`](../../../../supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:215); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:421, supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:298`.

### `public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint)`

- **Paramètres:** p_groupe_id uuid; p_libelle text; p_seuil_max smallint; p_weekday smallint; p_hour_local smallint; p_timezone_iana text; p_couleur_jeton smallint DEFAULT NULL::smallint.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `modification de groupe reservee a l'administration`; `P0001` — `fuseau IANA inconnu : %`; `P0001` — `ce groupe compte deja % membres actifs, seuil demande trop bas (%)`; `P0001` — `groupe introuvable ou deja cloture`.
- **Effets:** `public.groupes`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:74`](../../../../supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:74); grants: `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:296, supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:122`.

### `public.modifier_niveau_programme(uuid, text, text, int, text)`

- **Paramètres:** p_niveau_id uuid; p_nom_humain text; p_cycle text; p_ordre int; p_description text default null.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `modification du programme reservee a l'administration`; `P0001` — `niveau introuvable`; `P0001` — `version publiee ou archivee : creez une nouvelle version pour modifier le programme`.
- **Effets:** `public.programme_niveaux`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:176`](../../../../supabase/migrations/0020_programme_pedagogique.sql:176); grants: `supabase/migrations/0020_programme_pedagogique.sql:369`.

### `public.mon_fuseau()`

- **Paramètres:** aucun.
- **Retour:** `text`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/planning/service_planning.dart`, `lib/features/compte/informations_page.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:407`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:407); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:421`.

### `public.mon_groupe_detail(uuid)`

- **Paramètres:** p_groupe_id uuid.
- **Retour:** `table ( student_id uuid, identifiant_immuable text, prenom text, niveau text, riwaya text, joined_at timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/enseignant/modeles_enseignant.dart`, `lib/core/enseignant/service_enseignant.dart`.
- **Source:** [`supabase/migrations/0025_role_enseignant.sql:133`](../../../../supabase/migrations/0025_role_enseignant.sql:133); grants: `supabase/migrations/0025_role_enseignant.sql:174`.

### `public.offres_admin()`

- **Paramètres:** aucun.
- **Retour:** `table ( offre_id uuid, type_public text, langue_code text, langue_nom text, jours smallint[], heure_locale smallint, fuseau_iana text, duree_minutes smallint, etat text, capacite smallint, minimum_lancement smallint, vivier int, non_affectes int, groupes_publies int, lancable boolean, created_at timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:998`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:998); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:1048`.

### `public.offres_compatibles(uuid, text)`

- **Paramètres:** p_membre_id uuid; p_fuseau_vue text.
- **Retour:** `table ( offre_id uuid, type_public text, langue_code text, langue_nom text, jours_locaux smallint[], heures_locales smallint[], heure_source smallint, fuseau_source text, duree_minutes smallint, rythme text, pause_minutes smallint, capacite smallint, deja_choisie boolean )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/offres/offre_horaire.dart`, `lib/core/offres/service_offres.dart`.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:682`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:682); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:765`.

### `public.partie_concernee(uuid)`

- **Paramètres:** p_profile_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `auth.uid()`, `controller`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:238`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:238); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:277`.

### `public.personnes_observables()`

- **Paramètres:** aucun.
- **Retour:** `table ( id uuid, immutable_id text, first_name text, last_name text, role public.app_role )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/agent/service_agent.dart`, `lib/core/widgets/selecteur_personne.dart`.
- **Source:** [`supabase/migrations/0016_masquage_coherent_en_observation.sql:430`](../../../../supabase/migrations/0016_masquage_coherent_en_observation.sql:430); grants: `supabase/migrations/0016_masquage_coherent_en_observation.sql:478`.

### `public.peut_decrire_apprenant(uuid)`

- **Paramètres:** p_profile_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`, `guardian`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:197`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:197); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:231`.

### `public.peut_deposer_piece_identite(uuid)`

- **Paramètres:** p_profile_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`, `controller`, `guardian`, `teacher`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0034_r2_stockage.sql:274`](../../../../supabase/migrations/0034_r2_stockage.sql:274); grants: `supabase/migrations/0034_r2_stockage.sql:310`.

### `public.peut_poser_disponibilite(uuid)`

- **Paramètres:** p_profile_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`, `guardian`, `teacher`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:425`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:425); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:453`.

### `public.planifier_evaluation(uuid, uuid, text, date)`

- **Paramètres:** p_student_id uuid; p_niveau_id uuid; p_type text; p_date_prevue date.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `planification d'une evaluation reservee a l'administration`; `P0001` — `cet eleve n'existe pas ou son compte n'est pas valide`; `P0001` — `ce niveau de programme n'existe pas`.
- **Effets:** `public.evaluations`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_evaluations.dart`.
- **Source:** [`supabase/migrations/0023_evaluations.sql:64`](../../../../supabase/migrations/0023_evaluations.sql:64); grants: `supabase/migrations/0023_evaluations.sql:247`.

### `public.politique_observation_effective(uuid)`

- **Paramètres:** p_groupe_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0002` — `groupe introuvable`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_politique_observation.dart`, `lib/features/admin_groupes/feuille_observation_groupe.dart`.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:941`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:941); grants: `supabase/migrations/0033_tc_vues_rpc.sql:999`.

### `public.pool_offre(uuid)`

- **Paramètres:** p_offre_id uuid.
- **Retour:** `table ( eleve_id uuid, immutable_id text, prenom text, nom text, niveau_declare text, niveau_officiel text, diagnostic_statut text, intention_etat text, intention_depuis timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:1171`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:1171); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:1335`.

### `public.poser_exception_progression(uuid, text, text)`

- **Paramètres:** p_student_id uuid; p_type text; p_motif text.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `pose d'une exception de progression reservee a l'administration`; `P0001` — `un motif est requis pour poser une exception`; `P0001` — `cet eleve n'existe pas ou son compte n'est pas valide`; `P0001` — `une exception de ce type est deja active pour cet eleve`.
- **Effets:** `public.progression_exceptions`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_progression.dart`.
- **Source:** [`supabase/migrations/0022_progression_suivi.sql:55`](../../../../supabase/migrations/0022_progression_suivi.sql:55); grants: `supabase/migrations/0022_progression_suivi.sql:254`.

### `public.poser_regle(uuid, text, int, text)`

- **Paramètres:** p_profile_id uuid; p_key text; p_value int; p_motif text.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `seul un administrateur pose une regle`; `P0001` — `une regle sans motif ne se relit pas six mois plus tard`.
- **Effets:** `public.rule_overrides`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/regles/service_regles.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:1175`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:1175); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1211`.

### `public.prendre_eleve(uuid, int, int)`

- **Paramètres:** p_student_profile_id uuid; p_weekday int; p_hour int.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `seul un enseignant au compte valide prend un eleve`; `P0001` — `ce creneau n'est pas propose par ce foyer`; `P0001` — `ce creneau ne figure pas dans vos disponibilites`; `P0001` — `cet eleve a deja un enseignant`; `P0001` — `cet eleve vient d'etre pris par un autre enseignant`.
- **Effets:** `public.teacher_student_assignments`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/matching/service_matching.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:1017`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:1017); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:1090`.

### `public.preparer_depot_piece_identite(uuid, text)`

- **Paramètres:** p_profile_id uuid; p_doc_type text.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `authentification requise`; `42501` — `depot refuse pour ce profil`; `22023` — `type de piece inconnu`.
- **Effets:** `public.kyc_documents`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0034_r2_stockage.sql:315`](../../../../supabase/migrations/0034_r2_stockage.sql:315); grants: `supabase/migrations/0034_r2_stockage.sql:370`.

### `public.programme_niveaux_admin(uuid)`

- **Paramètres:** p_version_id uuid.
- **Retour:** `table( niveau_id uuid, code_technique text, nom_humain text, cycle text, ordre int, description text )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`, `lib/core/widgets/selecteur_niveau_programme.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:331`](../../../../supabase/migrations/0020_programme_pedagogique.sql:331); grants: `supabase/migrations/0020_programme_pedagogique.sql:373`.

### `public.programme_versions_admin()`

- **Paramètres:** aucun.
- **Retour:** `table( version_id uuid, statut text, numero_version int, cree_par_immutable_id text, cree_par_prenom text, cree_par_nom text, publiee_at timestamptz, nombre_niveaux int, created_at timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`, `lib/features/admin_pedagogie_programmes/programmes_page.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:298`](../../../../supabase/migrations/0020_programme_pedagogique.sql:298); grants: `supabase/migrations/0020_programme_pedagogique.sql:372`.

### `public.progression_admin()`

- **Paramètres:** aucun.
- **Retour:** `table( student_id uuid, student_immutable_id text, student_prenom text, student_nom text, groupe_id uuid, groupe_libelle text, niveau_id uuid, niveau_nom_humain text, niveau_cycle text, niveau_depuis timestamptz, exception_active_id uuid, exception_active_type text )`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_progression.dart`.
- **Source:** [`supabase/migrations/0022_progression_suivi.sql:185`](../../../../supabase/migrations/0022_progression_suivi.sql:185); grants: `supabase/migrations/0022_progression_suivi.sql:257`.

### `public.progression_promouvoir(uuid, uuid, text)`

- **Paramètres:** p_student_id uuid; p_niveau_id uuid; p_motif text.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `promotion de progression reservee a l'administration`; `P0001` — `un motif est requis pour promouvoir un eleve`; `P0001` — `cet eleve n'a encore aucun niveau decide : passez par Diagnostics`; `P0001` — `ce niveau de programme n'existe pas`.
- **Effets:** `public.progression_historique`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_progression.dart`.
- **Source:** [`supabase/migrations/0022_progression_suivi.sql:139`](../../../../supabase/migrations/0022_progression_suivi.sql:139); grants: `supabase/migrations/0022_progression_suivi.sql:256`.

### `public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)`

- **Paramètres:** p_session_id            uuid; p_resource_id           uuid; p_resource_version_id   uuid; p_content_position      jsonb; p_content_range         jsonb; p_display_mode          text; p_hidden_ranges         jsonb; p_semantic_markers      jsonb; p_group_resume_position jsonb; p_revision              integer.
- **Retour:** `public.session_shared_content`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `[message explicite absente; ERRCODE seul dans la source]`.
- **Effets:** `public.session_shared_content`.
- **Idempotence:** idempotence mechanism explicit (ON CONFLICT/idempotency marker).
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:868`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:868); grants: `supabase/migrations/0033_tc_vues_rpc.sql:927`.

### `public.publier_groupe_depuis_offre(uuid, uuid, text, uuid[])`

- **Paramètres:** p_offre_id uuid; p_teacher_profile_id uuid; p_libelle text; p_eleve_ids uuid[].
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `publication de groupe reservee a l'administration`; `P0001` — `offre introuvable ou non publiee`; `P0001` — `un groupe se lance a partir de % eleves, % fournis`; `P0001` — `la capacite de ce public est de %, % fournis`; `P0001` — `cet eleve n'a pas de preference vivante sur cette offre : %`.
- **Effets:** `public.groupe_creneaux`, `public.groupes`, `public.intentions_horaire`.
- **Idempotence:** idempotence mechanism explicit (ON CONFLICT/idempotency marker).
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:1214`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:1214); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:1347, supabase/migrations/0043_offres_horaires_et_intentions.sql:1352`.

### `public.publier_offre_horaire(uuid)`

- **Paramètres:** p_offre_id uuid.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `publication d'offre reservee a l'administration`; `P0001` — `offre introuvable ou deja publiee`.
- **Effets:** `public.offres_horaires`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:1111`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:1111); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:1326`.

### `public.publier_version_programme(uuid, text)`

- **Paramètres:** p_version_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `publication du programme reservee a l'administration`; `P0001` — `un motif est requis pour publier une version`; `P0001` — `version introuvable`; `P0001` — `cette version est deja publiee ou archivee`; `P0001` — `impossible de publier une version sans aucun niveau`.
- **Effets:** `public.programme_versions`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:254`](../../../../supabase/migrations/0020_programme_pedagogique.sql:254); grants: `supabase/migrations/0020_programme_pedagogique.sql:371`.

### `public.quitter_salle(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `non inscrit a cette seance`.
- **Effets:** `public.session_events`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/video/service_video.dart`.
- **Source:** [`supabase/migrations/0010_video_jeton_presence.sql:472`](../../../../supabase/migrations/0010_video_jeton_presence.sql:472); grants: `supabase/migrations/0010_video_jeton_presence.sql:676`.

### `public.read_kyc_documents()`

- **Paramètres:** aucun.
- **Retour:** `SETOF kyc_documents`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `auth.uid()`, `controller`
- **Erreurs SQL explicites:** `P0001` — `acces KYC refuse`; `P0001` — `genre du lecteur inconnu : renseignez-le avant de consulter un dossier`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/dossier/service_validation.dart`, `lib/features/admin_tableau/tableau_de_bord_page.dart`.
- **Source:** [`supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:250`](../../../../supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:250); grants: `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:300`.

### `public.regle_effective(uuid, text)`

- **Paramètres:** p_profile_id uuid; p_key text.
- **Retour:** `int`.
- **Roles explicitement grantés dans l’historique source:** `authenticated, service_role` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `regles hors du perimetre de lecture`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/domain/enums.dart`, `lib/core/planning/journee.dart`, `lib/core/regles/service_regles.dart`, `lib/core/tc_observation/guardian_observation_policy.dart`, `lib/features/admin_demandes/demandes_page.dart`, `lib/features/journee/journee_page.dart`, `lib/features/reglages_enfant/reglages_enfant_page.dart`, `lib/features/tc_observation_ui/etat_reglages_observation.dart`.
- **Source:** [`supabase/migrations/0005_dashboards_affectation_regles.sql:314`](../../../../supabase/migrations/0005_dashboards_affectation_regles.sql:314); grants: `supabase/migrations/0005_dashboards_affectation_regles.sql:327`.

### `public.regles_academie()`

- **Paramètres:** aucun.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/offres/offre_horaire.dart`, `lib/core/offres/service_offres.dart`, `lib/features/parcours_offres/libelles_parcours.dart`.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:548`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:548); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:569`.

### `public.rejoindre_observation(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `observation reservee au controle qualite`; `P0002` — `seance introuvable`; `23514` — `seance close`; `23514` — `seance pas encore commencee`; `23514` — `seance terminee`; `23514` — `observer une seance dont on est partie prenante est interdit`.
- **Effets:** `public.session_participants`.
- **Idempotence:** idempotence mechanism explicit (ON CONFLICT/idempotency marker).
- **Port Dart:** `lib/core/controle/service_controle.dart`, `lib/core/tc_observation/port_visite_observation.dart`, `lib/core/video/service_video.dart`.
- **Source:** [`supabase/migrations/0012_observation_controleur.sql:299`](../../../../supabase/migrations/0012_observation_controleur.sql:299); grants: `supabase/migrations/0012_observation_controleur.sql:380`.

### `public.renoncer_intention_horaire(uuid, text)`

- **Paramètres:** p_membre_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `ce profil n'est pas le votre ni celui de votre foyer`; `P0001` — `un motif est requis pour renoncer a une preference`; `P0001` — `aucune preference horaire vivante pour cet apprenant`.
- **Effets:** `public.intentions_horaire`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/offres/service_offres.dart`.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:830`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:830); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:865`.

### `public.ressources_du_groupe(uuid)`

- **Paramètres:** p_groupe_id uuid.
- **Retour:** `setof public.library_resource`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `groupe introuvable ou acces refuse`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0035_ressources_du_groupe_rejoue_visibilite.sql:58`](../../../../supabase/migrations/0035_ressources_du_groupe_rejoue_visibilite.sql:58); grants: `supabase/migrations/0033_tc_vues_rpc.sql:779, supabase/migrations/0035_ressources_du_groupe_rejoue_visibilite.sql:132`.

### `public.retirer_eleve_groupe(uuid, uuid, text)`

- **Paramètres:** p_groupe_id uuid; p_student_profile_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `retrait d'un eleve d'un groupe reserve a l'administration`; `P0001` — `un motif est requis pour retirer un eleve d'un groupe`; `P0001` — `cet eleve n'est pas membre actif de ce groupe`.
- **Effets:** `public.groupe_membres`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_groupes.dart`.
- **Source:** [`supabase/migrations/0019_groupes_durcissement.sql:177`](../../../../supabase/migrations/0019_groupes_durcissement.sql:177); grants: `supabase/migrations/0017_groupes_pedagogiques.sql:423`.

### `public.retirer_offre_horaire(uuid, text)`

- **Paramètres:** p_offre_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `retrait d'offre reserve a l'administration`; `P0001` — `un motif est requis pour retirer une offre`; `P0001` — `offre introuvable ou deja retiree`.
- **Effets:** `public.offres_horaires`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:1137`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:1137); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:1331`.

### `public.revoquer_appareil(uuid)`

- **Paramètres:** p_device_id uuid.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`
- **Erreurs SQL explicites:** `P0001` — `seul un tuteur ou un administrateur revoque un appareil`; `P0001` — `cet appareil n'appartient pas a votre foyer`.
- **Effets:** `public.devices`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/appairage/service_appairage.dart`.
- **Source:** [`supabase/migrations/0004_inscription_kyc_appairage.sql:731`](../../../../supabase/migrations/0004_inscription_kyc_appairage.sql:731); grants: `supabase/migrations/0004_inscription_kyc_appairage.sql:769`.

### `public.revoquer_jeton_agent(uuid)`

- **Paramètres:** p_id uuid.
- **Retour:** `boolean`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `42501` — `revocation reservee a l administration`.
- **Effets:** `public.jetons_agent`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/agent/service_agent.dart`.
- **Source:** [`supabase/migrations/0014_acces_agent.sql:358`](../../../../supabase/migrations/0014_acces_agent.sql:358); grants: `supabase/migrations/0014_acces_agent.sql:778`.

### `public.signaler_horaire_insatisfait(uuid, jsonb)`

- **Paramètres:** p_membre_id uuid; p_detail jsonb.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `ce profil n'est pas le votre ni celui de votre foyer`; `P0001` — `compte sans role`.
- **Effets:** `public.matching_requests`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/offres/service_offres.dart`.
- **Source:** [`supabase/migrations/0043_offres_horaires_et_intentions.sql:880`](../../../../supabase/migrations/0043_offres_horaires_et_intentions.sql:880); grants: `supabase/migrations/0043_offres_horaires_et_intentions.sql:929`.

### `public.sortir_observation(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_visite_observation.dart`.
- **Source:** [`supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:331`](../../../../supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:331); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1233, supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:370`.

### `public.supprimer_niveau_programme(uuid, text)`

- **Paramètres:** p_niveau_id uuid; p_motif text.
- **Retour:** `void`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `P0001` — `modification du programme reservee a l'administration`; `P0001` — `un motif est requis pour supprimer un niveau`; `P0001` — `niveau introuvable`; `P0001` — `version publiee ou archivee : impossible de supprimer un niveau publie`.
- **Effets:** `public.programme_niveaux`.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/admin/service_programme.dart`.
- **Source:** [`supabase/migrations/0020_programme_pedagogique.sql:217`](../../../../supabase/migrations/0020_programme_pedagogique.sql:217); grants: `supabase/migrations/0020_programme_pedagogique.sql:370`.

### `public.traiter_anomalie_qualite(text, uuid, text)`

- **Paramètres:** p_type_anomalie text; p_ref_id uuid; p_note text default null.
- **Retour:** `uuid`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `app_account_valid()`, `auth.uid()`
- **Erreurs SQL explicites:** `P0001` — `traitement d'une anomalie qualite reserve a l'administration`; `P0001` — `type d'anomalie inconnu : %`.
- **Effets:** `public.controles_qualite`.
- **Idempotence:** idempotence mechanism explicit (ON CONFLICT/idempotency marker).
- **Port Dart:** `lib/core/admin/service_qualite.dart`.
- **Source:** [`supabase/migrations/0024_qualite_pedagogique.sql:61`](../../../../supabase/migrations/0024_qualite_pedagogique.sql:61); grants: `supabase/migrations/0024_qualite_pedagogique.sql:197`.

### `public.transitions_fuseau_a_venir(int)`

- **Paramètres:** p_jours int default 30.
- **Retour:** `table ( groupe_id uuid, fuseau text, transition_utc timestamptz, heure_avant text, heure_apres text, jours_restants int )`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `app_account_valid()`
- **Erreurs SQL explicites:** `42501` — `reserve a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:498`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:498); grants: `supabase/migrations/0033_tc_vues_rpc.sql:556`.

### `public.unite_curriculum(uuid)`

- **Paramètres:** p_student_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `agent_ro, authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/enseignant/modeles_enseignant.dart`.
- **Source:** [`supabase/migrations/0025_role_enseignant.sql:180`](../../../../supabase/migrations/0025_role_enseignant.sql:180); grants: `supabase/migrations/0025_role_enseignant.sql:237`.

### `public.verifier_chaine_audit(int)`

- **Paramètres:** p_limite int default 200.
- **Retour:** `table ( verifiees int, rompues int, premiere_rompue bigint, rompue_le timestamptz )`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `P0001` — `journal d'audit reserve a l'administration`; `P0001` — `limite hors bornes`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/journal/service_journal.dart`.
- **Source:** [`supabase/migrations/0009_journal_audit.sql:243`](../../../../supabase/migrations/0009_journal_audit.sql:243); grants: `supabase/migrations/0009_journal_audit.sql:306`.

### `public.video_config_lire()`

- **Paramètres:** aucun.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** aucune condition app_role/app_account_valid/auth.uid detectee par motifs.
- **Erreurs SQL explicites:** `42501` — `reserve a l'administration`.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** aucun port repéré.
- **Source:** [`supabase/migrations/0010_video_jeton_presence.sql:607`](../../../../supabase/migrations/0010_video_jeton_presence.sql:607); grants: `supabase/migrations/0010_video_jeton_presence.sql:679`.

### `public.visites_observation(uuid)`

- **Paramètres:** p_session_id uuid.
- **Retour:** `jsonb`.
- **Roles explicitement grantés dans l’historique source:** `authenticated` (les grants historiques ne prouvent pas l’ACL runtime).
- **Capacites/gardes observees:** `admin`, `auth.uid()`
- **Erreurs SQL explicites:** aucun `RAISE EXCEPTION` détecté dans le corps.
- **Effets:** aucune mutation directe détectée.
- **Idempotence:** no explicit idempotence mechanism detected statically.
- **Port Dart:** `lib/core/tc_observation/port_visite_observation.dart`.
- **Source:** [`supabase/migrations/0033_tc_vues_rpc.sql:1235`](../../../../supabase/migrations/0033_tc_vues_rpc.sql:1235); grants: `supabase/migrations/0033_tc_vues_rpc.sql:1257`.

## Portee exacte de la migration 0048

La boucle de `supabase/migrations/0048_revoke_public_volatile_function_execute.sql:12-42` parcourt chaque fonction `public` non-extension (`prokind = 'f'`, pas d'entree `pg_depend` de type extension) dont `provolatile = 'v'`. Avant la revocation, elle photographie `has_function_privilege('authenticated', oid, 'EXECUTE')`; elle retire ensuite EXECUTE a `PUBLIC`, `anon` et `agent_ro`, puis accorde explicitement EXECUTE a `authenticated` uniquement si cette photographie est vraie. La verification `:46-70` s'assure qu'aucune fonction volatile reste executable par `agent_ro`.

Le catalogue de 110 entrées recense les signatures canoniques dont un GRANT direct à `authenticated` est retrouvé dans les migrations; les alias `int`/`integer` d'une même signature sont dédupliqués. Il n'inclut pas de membres conditionnels inventés pour 0048: cette appartenance dépend de l'ACL effective juste avant la migration, y compris les privilèges hérités de PUBLIC et les default privileges du rôle applicateur. Pour fermer cet écart, il faut rejouer les migrations avec le même rôle/default ACL et capturer les signatures effectives juste avant et après 0048. Aucune base locale Postgres n'est disponible et aucune base distante n'a été consultée.
