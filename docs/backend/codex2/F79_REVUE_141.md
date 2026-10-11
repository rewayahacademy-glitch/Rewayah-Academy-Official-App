# F79 — Revue statique des 141 fonctions SECURITY DEFINER

Base: `origin/ccr-1b1bfa0b-m1kvkk` (`030ab8858bd7b1556f7c47b12104ebbf22d7f5c2`). Inventaire: `codex/backend-sec-prod-allowlist` (`cb390b2e6ef11d39c918691dee654d4e9034ae1d`), `docs/backend/SECURITY_DEFINER_INVENTORY_PROD_2026-10-11.json.

## Périmètre et limites

Revue des sources suivies du dépôt seulement. Les signatures viennent de l’inventaire versionné nommé ci-dessus; corps, gardes, `search_path`, appels de déclencheurs et droits attendus dérivés des migrations (0001–0048). Les résultats GRANT/REVOKE décrivent l’intention de la chaîne source, pas les privilèges effectifs d’une base. Aucun accès STAGING/PROD ni clé `service_role`; aucun rejeu PostgreSQL local.

Couverture: 140/141 définitions trouvées; 1 source absente. Verdicts: {'OK': 53, 'À CORRIGER': 1, 'INVOKER POSSIBLE': 68, 'TRIGGER': 19}.

Les absences de définition sont signalées sans corps ni permissions inventés; le verdict À CORRIGER pour cette entrée signifie que la source de l’inventaire doit être réconciliée, pas que le corps absent a été audité. Les corrections proposées ne sont pas appliquées. « Tables écrites détectées » est une extraction statique et peut omettre du SQL dynamique.

## 1. `public.agent_identite_masquee()`

- **Définition la plus récente suivie:** `supabase/migrations/0014_acces_agent.sql:238`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 2. `public.agent_jeton_vivant(p_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0014_acces_agent.sql:257`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 3. `public.agent_pre_request()`

- **Définition la plus récente suivie:** `supabase/migrations/0014_acces_agent.sql:527`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 4. `public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0019_groupes_durcissement.sql:134`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()` ; `not exists ( select 1 from public.profiles p where p.id = p_student_profile_id and p.role = 'student' and p.deleted_at is null and p.account_status in ('active', 'provisional_active') )` ; `exists ( select 1 from public.groupe_membres where student_id = p_student_profile_id and left_at is null )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupe_membres`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 5. `public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:134`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.programme_niveaux`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 6. `public.annonce_observation_pour_moi(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:141`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not exists ( select 1 from public.sessions s join public.groupe_membres m on m.groupe_id = s.groupe_id and m.left_at is null where s.id = p_session_id and s.deleted_at is null and m.student_id = auth.uid() and public.app_account_valid() )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 7. `public.annonces_observation(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:1263`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not found or v_seance.teacher_id <> auth.uid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 8. `public.annuler_evaluation(p_evaluation_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0023_evaluations.sql:160`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.evaluations`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 9. `public.anomalies_qualite()`

- **Définition la plus récente suivie:** `supabase/migrations/0024_qualite_pedagogique.sql:107`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 10. `public.app_account_valid()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:412`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 11. `public.app_config_int(p_key text, p_defaut integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0007_coran_structure_position_presence.sql:150`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 12. `public.app_household_id()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:398`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 13. `public.app_role()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:391`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 14. `public.app_user_id()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:405`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 15. `public.assister_seance(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0012_observation_controleur.sql:398`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'guardian' or not public.app_account_valid()` ; `found and v_role <> 'guardian_observer'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_participants`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 16. `public.attacher_partition_audit(p_debut date)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:953`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 17. `public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0008_attribution_manuelle.sql:219`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()` ; `not exists ( select 1 from public.profiles p where p.id = p_teacher_profile_id and p.role = 'teacher' and p.deleted_at is null and p.account_status in ('active', 'provisional_active') )` ; `exists ( select 1 from public.teacher_student_assignments a where a.student_id = p_student_profile_id and a.ended_at is null )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.teacher_student_assignments`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 18. `public.autoriser_ecoute_archive(p_recording_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:442`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_account_valid(), false)` ; `not coalesce( v_role in ('admin', 'controller') or public.session_belongs_to_teacher(v_archive.session_id, auth.uid()) or ( v_foyers <= 1 and public.session_in_household(v_archive.session_id, public.app_household_id()) ), false )` ; `not coalesce( v_archive.legal_hold_since is not null and v_role in ('admin', 'controller'), false )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 19. `public.autoriser_jeton_video(p_session_id uuid, p_profile_id uuid, p_ws_url_cloud text, p_ws_url_self_hosted text)`

- **Définition la plus récente suivie:** `supabase/migrations/0042_etat_presence_fermee_et_jeton_video_verifie_le_compte.sql:169`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not public.app_account_valid()` ; `v_role = 'guardian_observer'` ; `v_role = 'teacher'` ; `v_role = 'guardian_observer'` ; `v_role = 'admin_visible'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.video_token_grants`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 20. `public.autoriser_lecture_piece_identite(p_document_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:141`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() in ('admin', 'controller'), false)` ; `not coalesce(public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 21. `public.brouillon_cahier(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0026_durcissement_execute_enseignant.sql:83`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce( auth.uid() is not null and v_seance.teacher_id = auth.uid() and public.app_role() = 'teacher' and public.app_account_valid(), false )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 22. `public.budget_observation(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:169`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 23. `public.clore_exception_progression(p_exception_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0022_progression_suivi.sql:104`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.progression_exceptions`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 24. `public.clore_regle(p_override_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:1213`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.rule_overrides`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 25. `public.cloturer_groupe(p_groupe_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0019_groupes_durcissement.sql:209`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupe_membres`, `public.groupes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 26. `public.completer_kyc_document()`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:129`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 27. `public.comptes_admin()`

- **Définition la plus récente suivie:** `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:6`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 28. `public.confirmer_depot_piece_identite(p_document_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:381`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 29. `public.consommer_code_appairage(p_code text, p_device_fingerprint text, p_platform text)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:651`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.device_pairing_codes`, `public.devices`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 30. `public.creer_code_appairage(p_student_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:580`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'guardian' or not public.app_account_valid()` ; `not exists ( select 1 from public.profiles p where p.id = p_student_profile_id and p.household_id is not null and p.household_id = public.app_household_id() and p.role = 'student' and p.deleted_at is null )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.device_pairing_codes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 31. `public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint)`

- **Définition la plus récente suivie:** `supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:10`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)` ; `not exists ( select 1 from public.profiles p where p.id = p_teacher_profile_id and p.role = 'teacher' and p.deleted_at is null and p.account_status in ('active', 'provisional_active') )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 32. `public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint)`

- **Définition la plus récente suivie:** `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:118`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)` ; `not exists ( select 1 from public.profiles p where p.id = p_teacher_profile_id and p.role = 'teacher' and p.deleted_at is null and p.account_status in ('active', 'provisional_active') )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 33. `public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer, p_identite_masquee boolean)`

- **Définition la plus récente suivie:** `supabase/migrations/0014_acces_agent.sql:273`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()` ; `v_role is null`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.jetons_agent`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 34. `public.creer_profil_enfant(p_auth_user_id uuid, p_guardian_id uuid, p_first_name text, p_last_name text, p_age integer, p_level text)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:828`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.profiles`, `public.student_profiles`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 35. `public.creer_profil_inscription(p_role text, p_first_name text, p_last_name text, p_gender gender, p_timezone text)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:347`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** none (forme de garde non classée comme positive coalesce ou négative; conditions ci-dessous).
  - Conditions observées: `v_role = 'guardian'` ; `v_role = 'guardian'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.households`, `public.profiles`, `public.teacher_profiles`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 36. `public.creer_version_programme(p_source_version_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:94`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.programme_niveaux`, `public.programme_versions`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 37. `public.custom_access_token_hook(event jsonb)`

- **Définition la plus récente suivie:** `supabase/migrations/0038_hook_jeton_foyer_absent.sql:50`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 38. `public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:1243`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.matching_requests`, `public.teacher_student_assignments`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 39. `public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:523`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.kyc_documents`, `public.profiles`, `public.teacher_profiles`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 40. `public.decider_placement(p_student_id uuid, p_niveau_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0021_diagnostics_placement.sql:53`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.progression_historique`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 41. `public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0036_observation_defauts_academie_et_plafond_visite_groupe.sql:206`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 42. `public.demander(p_kind text, p_subject_profile_id uuid, p_motif text, p_rule_key text, p_rule_value integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:1093`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `v_role is null or not public.app_account_valid()` ; `not public.partie_concernee(p_subject_profile_id)` ; `not (v_role = 'admin' or (v_role = 'teacher' and p_subject_profile_id = auth.uid()))` ; `not exists ( select 1 from public.teacher_student_assignments a where a.student_id = p_subject_profile_id and a.ended_at is null )`
- **`EXCEPTION WHEN`:** oui.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.matching_requests`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 43. `public.demandes_en_attente()`

- **Définition la plus récente suivie:** `supabase/migrations/0016_masquage_coherent_en_observation.sql:124`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() not in ('admin', 'controller')`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 44. `public.derniere_position_groupe(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:1417`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not v_autorise`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 45. `public.diagnostics_a_traiter()`

- **Définition la plus récente suivie:** `supabase/migrations/0021_diagnostics_placement.sql:107`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 46. `public.doit_demander_feedback(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:1355`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not exists ( select 1 from public.session_participants sp where sp.session_id = p_session_id and sp.profile_id = auth.uid() and sp.role = 'student' and sp.deleted_at is null )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 47. `public.dossiers_en_attente()`

- **Définition la plus récente suivie:** `supabase/migrations/0029_fermeture_dossiers_en_attente_anon.sql:73`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin', false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 48. `public.eleves_sans_enseignant()`

- **Définition la plus récente suivie:** `supabase/migrations/0016_masquage_coherent_en_observation.sql:242`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 49. `public.enregistrer_archive_seance(p_room_name text, p_egress_id text, p_object_key text, p_duration_seconds integer, p_size_bytes bigint, p_codec text)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:576`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** oui.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_recordings`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 50. `public.enregistrer_resultat_evaluation(p_evaluation_id uuid, p_resultat text, p_notes text)`

- **Définition la plus récente suivie:** `supabase/migrations/0023_evaluations.sql:107`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.evaluations`, `public.progression_historique`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 51. `public.enregistrer_webhook_livekit(p_event_id text, p_event_type text, p_room_name text, p_profile_id uuid, p_server_ts timestamp with time zone, p_detail jsonb)`

- **Définition la plus récente suivie:** `supabase/migrations/0010_video_jeton_presence.sql:388`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `v_session_id is null or p_profile_id is null` ; `v_type = 'left' and exists ( select 1 from public.session_events e where e.session_id = v_session_id and e.profile_id = p_profile_id and e.event_type = 'left' and e.source = 'user_action' and e.server_ts > p_server_ts - interval '30 seconds' )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.livekit_webhook_deliveries`, `public.session_events`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 52. `public.enseignants_pour(p_student_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0016_masquage_coherent_en_observation.sql:305`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 53. `public.entrer_observation(p_session_id uuid, p_role text)`

- **Définition la plus récente suivie:** `supabase/migrations/0037_entrer_observation_rend_l_enfant_concerne.sql:56`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not public.app_account_valid()` ; `v_role = 'guardian_observer' and public.app_role() <> 'guardian'` ; `v_role in ('admin_masked', 'admin_visible') and public.app_role() <> 'admin'` ; `v_role = 'guardian_observer'` ; `v_role = 'guardian_observer' and not (v_pol->>'observation_activee')::boolean` ; `v_role = 'guardian_observer'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.guardian_session_visit`, `public.session_participants`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 54. `public.est_du_foyer(p_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0030_tc_socle.sql:47`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 55. `public.est_observateur_masque(p_session_id uuid, p_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql:94`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 56. `public.etat_dossier()`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:431`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `auth.uid() is null`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 57. `public.etat_presence(p_session_id uuid, p_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0042_etat_presence_fermee_et_jeton_video_verifie_le_compte.sql:34`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not public.app_account_valid()` ; `not ( public.app_role() = any (array['admin', 'controller']::public.app_role[]) or (v_seance_trouvee and v_seance.teacher_id = auth.uid()) or (public.app_role() = 'guardian' and public.est_du_foyer(p_profile_id)) or p_profile_id = auth.uid() )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 58. `public.evaluations_admin()`

- **Définition la plus récente suivie:** `supabase/migrations/0023_evaluations.sql:195`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 59. `public.geler_archive_seance(p_recording_id uuid, p_motif text, p_gel boolean)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:661`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin', false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 60. `public.get_config(p_key text, p_default jsonb)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:930`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 61. `public.groupe_detail(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0019_groupes_durcissement.sql:279`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 62. `public.groupe_roster_enseignant(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:787`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 63. `public.groupes_admin()`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:694`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 64. `public.guard_app_config_history()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:938`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.app_config_history`
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 65. `public.guard_assignment_cap()`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:192`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 66. `public.guard_audit_logs_immutable()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:567`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 67. `public.guard_contract_acceptances_immutable()`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:246`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 68. `public.guard_devices_max_reactivation()`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:78`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** negative.
  - Conditions observées: `(select count(*) from public.devices d where d.profile_id = new.profile_id and d.id <> new.id and d.revoked_at is null and d.deleted_at is null) >= max_devices`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 69. `public.guard_devices_max()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:792`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** negative.
  - Conditions observées: `(select count(*) from public.devices d where d.profile_id = new.profile_id and d.revoked_at is null and d.deleted_at is null ) >= max_devices`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 70. `public.guard_groupe_membre_cap()`

- **Définition la plus récente suivie:** `supabase/migrations/0017_groupes_pedagogiques.sql:99`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 71. `public.guard_prayer_adjustments()`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:846`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 72. `public.guard_profile_immutable_id()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:523`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 73. `public.guard_profile_privileged_columns()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:541`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' and (old.role is distinct from new.role or old.household_id is distinct from new.household_id or old.account_status is distinct from new.account_status or old.access_until is distinct from new.access_until)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 74. `public.guard_rule_override_coherente()`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:82`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** negative.
  - Conditions observées: `new.key = 'max_students_per_teacher' and v_role is distinct from 'teacher'` ; `new.key <> 'max_students_per_teacher' and v_role is distinct from 'student'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 75. `public.guard_rule_override_immutable()`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:110`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** negative.
  - Conditions observées: `new.profile_id <> old.profile_id or new.key <> old.key or new.value <> old.value or new.reason <> old.reason or new.set_by <> old.set_by or new.created_at <> old.created_at`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 76. `public.guard_session_overlap()`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:1504`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** negative.
  - Conditions observées: `exists ( select 1 from public.session_participants sp join public.sessions s1 on s1.id = sp.session_id join public.sessions s2 on s2.id = new.session_id where sp.profile_id = new.profile_id and sp.deleted_at is null and sp.role in ('teacher', 'student') and s1.deleted_at is null and s2.deleted_at is null and s1.status in ('planned', 'preflight', 'in_progress') and tstzrange(s1.started_at, s1.ended_at, '[)') && tstzrange(s2.started_at, s2.ended_at, '[)') and s1.id <> s2.id )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 77. `public.guard_session_participant_cap()`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:1470`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 78. `public.guard_session_state_transition()`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:885`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 79. `public.horloge_seance(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:427`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 80. `public.indicateurs_admin()`

- **Définition la plus récente suivie:** `supabase/migrations/0015_administration_voit_les_personnes.sql:205`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 81. `public.jetons_agent_actifs()`

- **Définition la plus récente suivie:** `supabase/migrations/0016_masquage_coherent_en_observation.sql:376`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 82. `public.journal_audit_filtres()`

- **Définition la plus récente suivie:** `supabase/migrations/0015_administration_voit_les_personnes.sql:260`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 83. `public.journal_audit(p_acteur uuid, p_action text, p_depuis timestamp with time zone, p_limite integer, p_avant_date timestamp with time zone, p_avant_id bigint)`

- **Définition la plus récente suivie:** `supabase/migrations/0016_masquage_coherent_en_observation.sql:167`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 84. `public.log_sensitive_access(p_action text, p_table_name text, p_row_id text, p_payload jsonb)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:594`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.audit_logs`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 85. `public.maintenant_serveur()`

- **Définition la plus récente suivie:** `supabase/migrations/0030_tc_socle.sql:67`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 86. `public.maj_eleve_pedagogie(p_profile_id uuid, p_level text, p_riwaya text)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:570`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.student_profiles`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 87. `public.maj_profil_enseignant(p_country text, p_languages text[], p_timezone text)`

- **Définition la plus récente suivie:** `supabase/migrations/0027_maj_profil_enseignant.sql:38`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 88. `public.materialiser_seances_groupe(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:315`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_participants`, `public.sessions`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 89. `public.materialiser_seances(p_assignment_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:952`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_participants`, `public.sessions`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 90. `public.mes_rapports_en_attente()`

- **Définition la plus récente suivie:** `supabase/migrations/0025_role_enseignant.sql:376`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 91. `public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint)`

- **Définition la plus récente suivie:** `supabase/migrations/0045_disambiguate_creer_groupe_overloads.sql:74`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 92. `public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint)`

- **Définition la plus récente suivie:** `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:215`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupes`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 93. `public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:176`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.programme_niveaux`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 94. `public.mon_fuseau()`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:407`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 95. `public.mon_groupe_detail(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0025_role_enseignant.sql:133`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 96. `public.next_immutable_id(role_code app_role, initials text)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:501`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.id_sequences`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 97. `public.partie_concernee(p_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:238`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 98. `public.personnes_observables()`

- **Définition la plus récente suivie:** `supabase/migrations/0016_masquage_coherent_en_observation.sql:430`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 99. `public.peut_deposer_piece_identite(p_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:274`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 100. `public.peut_poser_disponibilite(p_profile_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:425`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 101. `public.planifier_evaluation(p_student_id uuid, p_niveau_id uuid, p_type text, p_date_prevue date)`

- **Définition la plus récente suivie:** `supabase/migrations/0023_evaluations.sql:64`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.evaluations`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 102. `public.politique_observation_effective(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:941`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 103. `public.poser_exception_progression(p_student_id uuid, p_type text, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0022_progression_suivi.sql:55`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.progression_exceptions`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 104. `public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:1175`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.rule_overrides`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 105. `public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:1017`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'teacher' or not public.app_account_valid()` ; `not exists ( select 1 from public.weekly_availability wt where wt.profile_id = auth.uid() and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant )` ; `exists ( select 1 from public.teacher_student_assignments a where a.student_id = p_student_profile_id and a.ended_at is null )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.teacher_student_assignments`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 106. `public.preparer_depot_piece_identite(p_profile_id uuid, p_doc_type text)`

- **Définition la plus récente suivie:** `supabase/migrations/0034_r2_stockage.sql:315`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.kyc_documents`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 107. `public.profil_de_mon_foyer(p_profile_id text)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:322`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 108. `public.profil_du_jeton_appareil(p_token text)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:794`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.devices`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 109. `public.programme_niveaux_admin(p_version_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:331`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 110. `public.programme_versions_admin()`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:298`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 111. `public.progression_admin()`

- **Définition la plus récente suivie:** `supabase/migrations/0022_progression_suivi.sql:185`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 112. `public.progression_promouvoir(p_student_id uuid, p_niveau_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0022_progression_suivi.sql:139`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.progression_historique`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 113. `public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:868`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not public.session_belongs_to_teacher(p_session_id, auth.uid()) and public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_shared_content`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 114. `public.publier_version_programme(p_version_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:254`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.programme_versions`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 115. `public.quitter_salle(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0010_video_jeton_presence.sql:472`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not public.session_has_participant(p_session_id, auth.uid())`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_events`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 116. `public.read_kyc_documents()`

- **Définition la plus récente suivie:** `supabase/migrations/0044_securiser_rpc_admin_et_kyc.sql:250`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() in ('admin', 'controller'), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 117. `public.record_session_event(p_session_id uuid, p_profile_id uuid, p_event_type session_event_type, p_source text)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:912`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_events`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 118. `public.regle_brute(p_profile_id uuid, p_key text)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:284`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 119. `public.regle_effective(p_profile_id uuid, p_key text)`

- **Définition la plus récente suivie:** `supabase/migrations/0005_dashboards_affectation_regles.sql:314`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not public.partie_concernee(p_profile_id)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 120. `public.rejoindre_observation(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0012_observation_controleur.sql:299`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'controller' or not public.app_account_valid()` ; `found and v_role <> 'masked_controller'` ; `v_seance.teacher_id = auth.uid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_participants`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 121. `public.remettre_session_agent(p_jeton text)`

- **Définition la plus récente suivie:** `supabase/migrations/0014_acces_agent.sql:392`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.jetons_agent`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 122. `public.ressources_du_groupe(p_groupe_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0035_ressources_du_groupe_rejoue_visibilite.sql:58`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not exists ( select 1 from public.groupes g where g.id = p_groupe_id and public.app_account_valid() and ( g.teacher_id = auth.uid() or public.app_role() = 'admin' or exists ( select 1 from public.groupe_membres m where m.groupe_id = g.id and m.left_at is null and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id)) ) ) )`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 123. `public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0019_groupes_durcissement.sql:177`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.groupe_membres`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 124. `public.revoquer_appareil(p_device_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0004_inscription_kyc_appairage.sql:731`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() not in ('guardian', 'admin')`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.devices`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 125. `public.revoquer_jeton_agent(p_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0014_acces_agent.sql:358`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.jetons_agent`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 126. `public.rls_auto_enable()`

- **Source:** absente des migrations suivies 0001–0048; No CREATE FUNCTION declaration for this signature was found in tracked supabase/migrations/*.sql on the ccr base (0001–0048).
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=unknown (source absent); authenticated=unknown (source absent); agent_ro=unknown (source absent); service_role=unknown (source absent). Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** unknown (source absent).
- **Rôles censés appeler selon les gardes et usages repérés:** unknown (source absent).
- **Garde:** impossible à déterminer depuis la source absente.
- **`search_path`:** `inconnu (source absente)`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **À CORRIGER**.
- **Correction proposée (non appliquée):** Réconcilier la définition public.rls_auto_enable() dans les sources suivies ou retirer cette entrée de l’inventaire source; ne pas inférer son corps ni modifier un environnement distant.

## 127. `public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:431`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 128. `public.session_has_participant(p_session_id uuid, p_uid uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:453`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 129. `public.session_in_household(p_session_id uuid, p_household_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0001_fondations.sql:441`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 130. `public.sortir_observation(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql:331`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 131. `public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)`

- **Définition la plus récente suivie:** `supabase/migrations/0020_programme_pedagogique.sql:217`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.programme_niveaux`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 132. `public.tc_materialiser_apres_adhesion()`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:401`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 133. `public.tc_materialiser_apres_creation_groupe()`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:382`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 134. `public.tc_session_feedback_calculer_empreinte()`

- **Définition la plus récente suivie:** `supabase/migrations/0032_tc_catalogue.sql:521`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** trigger only.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **TRIGGER**.
- **Correction proposée (non appliquée):** Retirer SECURITY DEFINER et conserver le déclencheur en SECURITY INVOKER; qualifier les objets nécessaires. Correctif non appliqué.

## 135. `public.traiter_anomalie_qualite(p_type_anomalie text, p_ref_id uuid, p_note text)`

- **Définition la plus récente suivie:** `supabase/migrations/0024_qualite_pedagogique.sql:61`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.controles_qualite`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 136. `public.transitions_fuseau_a_venir(p_jours integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:498`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin' or not public.app_account_valid()`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 137. `public.unite_curriculum(p_student_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0025_role_enseignant.sql:180`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 138. `public.verifier_chaine_audit(p_limite integer)`

- **Définition la plus récente suivie:** `supabase/migrations/0009_journal_audit.sql:243`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 139. `public.video_config_lire()`

- **Définition la plus récente suivie:** `supabase/migrations/0010_video_jeton_presence.sql:607`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** authenticated with the observed authorization predicates.
- **Garde:** negative.
  - Conditions observées: `public.app_role() <> 'admin'`
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.

## 140. `public.video_route_de_seance(p_session_id uuid, p_ws_url_cloud text, p_ws_url_self_hosted text)`

- **Définition la plus récente suivie:** `supabase/migrations/0010_video_jeton_presence.sql:177`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=False; authenticated=True; agent_ro=False; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** authenticated, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** `public.session_video_route`
- **Verdict:** **OK**.
- **Correction proposée (non appliquée):** Aucun correctif proposé sur la seule analyse statique des sources; confirmer les hypothèses de rôle par tests négatifs. Aucun changement appliqué.

## 141. `public.visites_observation(p_session_id uuid)`

- **Définition la plus récente suivie:** `supabase/migrations/0033_tc_vues_rpc.sql:1235`
- **EXECUTE dérivé des migrations + modèle documenté en 0028:** anon=True; authenticated=True; agent_ro=True; service_role=True. Pas un état runtime.
- **Rôles pouvant appeler (dérivation ACL):** anon, authenticated, agent_ro, service_role.
- **Rôles censés appeler selon les gardes et usages repérés:** no narrower intended caller role established statically.
- **Garde:** none (aucune garde IF d’autorisation détectée).
- **`EXCEPTION WHEN`:** non.
- **`search_path`:** `''`.
- **Tables écrites détectées:** aucune par motifs SQL statiques; relire si SQL dynamique est présent.
- **Verdict:** **INVOKER POSSIBLE**.
- **Correction proposée (non appliquée):** Évaluer SECURITY INVOKER afin de laisser RLS contrôler les lectures; valider les permissions des appelants avant changement. Correctif non appliqué.
