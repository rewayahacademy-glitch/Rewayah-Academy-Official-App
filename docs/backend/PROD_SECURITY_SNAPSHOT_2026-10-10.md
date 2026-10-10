# Instantané de sécurité Supabase PROD — 2026-10-10

> Archive de lecture seule préparée avant toute remédiation. Ne pas exécuter ce fichier : il contient des définitions extraites du catalogue, pas un plan d'application. Projet observé : `gggmtelinlpseweouyav` (Rewayah PROD), URL vérifiée `https://gggmtelinlpseweouyav.supabase.co`. Ledger lu le 2026-10-10 : 50 entrées jusqu'à `0042_etat_presence_fermee_et_jeton_video_verifie_le_compte`. Les sources sont `pg_get_functiondef`, `pg_get_viewdef`, `pg_policies`, `information_schema.role_table_grants` et les ACL calculées par `has_function_privilege`. Aucun contenu de profil, KYC, objet Storage ou secret n'a été lu.

## Résumé de l'état catalogué

- 15 vues public identifiées par l'advisor sécurité comme SECURITY DEFINER; toutes ci-dessous ont `security_barrier=true` ou aucune option, sans `security_invoker=true`.
- 334 fonctions utilisateur cataloguées dans public/app_private; 141 SECURITY DEFINER dans cet ensemble.
- 39 fonctions SECURITY DEFINER contiennent une garde négative sur `app_role()`; elles sont capturées intégralement ci-dessous, avec `autoriser_lecture_piece_identite(uuid)` et `guard_profile_privileged_columns()`.
- 27 fonctions SECURITY DEFINER sont exécutables par `anon`; 118 par `authenticated`; 48 par `agent_ro`. La liste nominative des 118 fonctions authenticated est ci-dessous.
- Policies KYC/Storage et grants des 15 vues + `kyc_documents` sont archivés. Les grants sur `storage.objects` sont listés par rôle; la policy de lecture KYC est ci-dessous.
- L'advisor du 2026-10-10 a aussi relevé `btree_gist` dans public, 7 tables RLS sans policy (à distinguer de l'audit demandé), et 15 vues security-definer.

## 118 fonctions SECURITY DEFINER exécutables par authenticated

| Fonction | anon EXECUTE | authenticated EXECUTE | agent_ro EXECUTE | Empreinte MD5 du corps complet |
|---|---:|---:|---:|---|
| `public.agent_identite_masquee()` | true | true | true | `d840394e84b8b4c9ba497dffaad20d54` |
| `public.agent_pre_request()` | true | true | true | `6b20cd70194775bf54db14725128a3c5` |
| `public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)` | false | true | false | `5c001c226d18ba90fdaf5a7581be9a66` |
| `public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)` | false | true | false | `cee5a197b02fbed73038efe1113f45cb` |
| `public.annonce_observation_pour_moi(p_session_id uuid)` | false | true | false | `a527cfa220e0f6b3af044b1634ea152c` |
| `public.annonces_observation(p_session_id uuid)` | false | true | false | `4c3f4797c0e0a55d197fc4bb701a7300` |
| `public.annuler_evaluation(p_evaluation_id uuid, p_motif text)` | false | true | false | `4f9fd8b123ac1e3994921a19839ea657` |
| `public.anomalies_qualite()` | false | true | true | `cc4216e342fc0346371a6980b2399bea` |
| `public.app_account_valid()` | true | true | true | `25ef4708ed7b2d0b81a58f3c13675f95` |
| `public.app_config_int(p_key text, p_defaut integer)` | true | true | true | `8e952a7f94ab026e910b91aa34871768` |
| `public.app_household_id()` | true | true | true | `542ef88e02409f5373959100cd7a3d0c` |
| `public.app_role()` | true | true | true | `b20471b9c758fed68602f39e075717c1` |
| `public.app_user_id()` | true | true | true | `662840b5e2b92eb18413856d550b1af3` |
| `public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text)` | false | true | false | `0f45793b6620c4126fb8021f9ad85f71` |
| `public.autoriser_ecoute_archive(p_recording_id uuid)` | false | true | false | `43b6560d4add3f778326e832a251088c` |
| `public.autoriser_lecture_piece_identite(p_document_id uuid)` | false | true | false | `f3e4c7db59cc2000fd609e2fbe6f5cf3` |
| `public.brouillon_cahier(p_session_id uuid)` | false | true | true | `6abe6bbcb1515130213fb637cdd5cfb7` |
| `public.budget_observation(p_session_id uuid)` | false | true | false | `390f9c621dccf161c23501b6f7937c22` |
| `public.clore_exception_progression(p_exception_id uuid, p_motif text)` | false | true | false | `ee94547ce13af07a6bb3a526c1b93019` |
| `public.clore_regle(p_override_id uuid, p_motif text)` | false | true | false | `69c2d22a82d2d06431a75488e9b96aad` |
| `public.cloturer_groupe(p_groupe_id uuid, p_motif text)` | false | true | false | `c08ce88599444254b4155baff166302f` |
| `public.completer_kyc_document()` | true | true | false | `55e4cc15937dcb0b70a28ac0471ef7b8` |
| `public.comptes_admin()` | true | true | true | `78817cf3395a6a3c301c91f45934e80f` |
| `public.creer_code_appairage(p_student_profile_id uuid)` | false | true | false | `ed5103a9093421c68265efdef96ed16b` |
| `public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint)` | true | true | true | `97c8c9e666653e03584e0d875ad00c33` |
| `public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint)` | false | true | false | `d85b1b126ac26ab5628777ee722b71b0` |
| `public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer, p_identite_masquee boolean)` | false | true | false | `0084e98d6eada6c376364bfead236b22` |
| `public.creer_profil_inscription(p_role text, p_first_name text, p_last_name text, p_gender gender, p_timezone text)` | false | true | false | `4564536aa08e2389235fcecf00117611` |
| `public.creer_version_programme(p_source_version_id uuid)` | false | true | false | `b72ca828b9c07f40cb69b8a2f6e11de3` |
| `public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text)` | false | true | false | `7e1986d430bef88eec0dffa29e290acf` |
| `public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text)` | false | true | false | `9b1f8d0d3baea020be07d676c34de6e2` |
| `public.decider_placement(p_student_id uuid, p_niveau_id uuid, p_motif text)` | false | true | false | `57f9459ec3a73dbbc3b6b3dea0a0015d` |
| `public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer)` | false | true | false | `967659fc78d48da104daa224138b2de6` |
| `public.demander(p_kind text, p_subject_profile_id uuid, p_motif text, p_rule_key text, p_rule_value integer)` | false | true | false | `ebb7508bf33843ce0602e66bbcf8dc82` |
| `public.demandes_en_attente()` | false | true | true | `a9003a8e91895e4b6d7674e584a7fe75` |
| `public.derniere_position_groupe(p_groupe_id uuid)` | false | true | false | `73ddd94f8f873fb5ebed000d501b8ed6` |
| `public.diagnostics_a_traiter()` | false | true | true | `b1294c4ac77aeeb86a308246beb5059d` |
| `public.doit_demander_feedback(p_session_id uuid)` | false | true | false | `03d6f39788bbe7ff8df48985b70ea879` |
| `public.dossiers_en_attente()` | false | true | true | `b31b4fbc58d5a55117b4ed951a3403b5` |
| `public.eleves_sans_enseignant()` | false | true | true | `d3e14512ba428ffec5e9623d8e8bacbd` |
| `public.enregistrer_resultat_evaluation(p_evaluation_id uuid, p_resultat text, p_notes text)` | false | true | false | `4bd65c40df79915136eece059762a525` |
| `public.enseignants_pour(p_student_profile_id uuid)` | false | true | true | `f2446791e27fe948db4a172470be5940` |
| `public.entrer_observation(p_session_id uuid, p_role text)` | false | true | false | `9da9386bb2c6b2d07eae3fadee3c2010` |
| `public.est_du_foyer(p_profile_id uuid)` | false | true | false | `cf01e3f9efe82d50ca05275ce30428e9` |
| `public.est_observateur_masque(p_session_id uuid, p_profile_id uuid)` | false | true | true | `a5e13b2fbdbff5a32f21616bb7637fff` |
| `public.etat_dossier()` | false | true | true | `8029881e3743ba27d7838fef226813a4` |
| `public.etat_presence(p_session_id uuid, p_profile_id uuid)` | false | true | true | `6915fe061c06c9f5617c7d9e9bf0f051` |
| `public.evaluations_admin()` | false | true | true | `71eff9577dda431a05fb4766db2c2032` |
| `public.geler_archive_seance(p_recording_id uuid, p_motif text, p_gel boolean)` | false | true | false | `cdab571836d441c57694f9bea5099f40` |
| `public.groupe_detail(p_groupe_id uuid)` | false | true | true | `dec65463d891f3cef2ec314efebe2051` |
| `public.groupe_roster_enseignant(p_groupe_id uuid)` | false | true | false | `20212f9b34187cef242bc98ce2fa57a2` |
| `public.groupes_admin()` | true | true | true | `948e0562c8ef4086dd00f6fb70c7d1e2` |
| `public.guard_app_config_history()` | true | true | false | `99b0223e1ea4211510dab2699c048d9b` |
| `public.guard_assignment_cap()` | true | true | false | `8f663d8b6fe5b4e7ceca82229e3ac43b` |
| `public.guard_audit_logs_immutable()` | true | true | false | `a582efceb101d5541fd511cb7c0c7a91` |
| `public.guard_contract_acceptances_immutable()` | true | true | false | `572baa09d163a0b386a7a98d7006b02b` |
| `public.guard_devices_max_reactivation()` | true | true | false | `fd517074a8ada2d32fabe95def07ec44` |
| `public.guard_devices_max()` | true | true | false | `f43bd4724f00b05af103bdafcbe8a714` |
| `public.guard_prayer_adjustments()` | true | true | false | `f358ae78bf49c71bf2316a9271c61d78` |
| `public.guard_profile_immutable_id()` | true | true | false | `1fff46e37cbb5c465e4109b910b76d1d` |
| `public.guard_profile_privileged_columns()` | true | true | false | `0e0b9d7f966e64b2e5182a0a9d5495eb` |
| `public.guard_rule_override_coherente()` | true | true | false | `3f5931edc446d04c9cd03fbfd5387052` |
| `public.guard_rule_override_immutable()` | true | true | false | `458c3ca2dfc2858b89472aa0e6e988de` |
| `public.guard_session_state_transition()` | true | true | false | `6337e0fa1c9f05b12440c7dd66a18b63` |
| `public.horloge_seance(p_session_id uuid)` | false | true | true | `879eb5957f8cabd0f25278807c5e0576` |
| `public.indicateurs_admin()` | false | true | true | `d7e1209572394c2ab6d5f9dae3834aaa` |
| `public.jetons_agent_actifs()` | false | true | true | `0712f58e294f778705822aab96d9bea4` |
| `public.journal_audit_filtres()` | false | true | true | `49c1360b67ef589d2aaef8468ecc31bc` |
| `public.journal_audit(p_acteur uuid, p_action text, p_depuis timestamp with time zone, p_limite integer, p_avant_date timestamp with time zone, p_avant_id bigint)` | false | true | true | `973fec3923b807963042e424ef181e50` |
| `public.log_sensitive_access(p_action text, p_table_name text, p_row_id text, p_payload jsonb)` | false | true | false | `f8bd87ae2b78060f31362ccf7697cbc4` |
| `public.maintenant_serveur()` | false | true | true | `544d5e02a1e48495e4d4aac532bc498b` |
| `public.maj_eleve_pedagogie(p_profile_id uuid, p_level text, p_riwaya text)` | false | true | false | `f9164b5c4b9a7bbc582ae7675ff94678` |
| `public.maj_profil_enseignant(p_country text, p_languages text[], p_timezone text)` | false | true | false | `62a32e47dabb25ff2d1161077944eb83` |
| `public.materialiser_seances(p_assignment_id uuid)` | false | true | false | `3033a4a29b4fac32a7ba2cc093b5f09b` |
| `public.mes_rapports_en_attente()` | false | true | true | `f5f2f30e05982a7880583244c343dd21` |
| `public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint)` | true | true | true | `713d5acca4971058883ea90e06bb6ad4` |
| `public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint)` | false | true | false | `5bfb604429ef9b20ac632197218f9784` |
| `public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)` | false | true | false | `b61928f62425d1439e3ac806c96a7f8c` |
| `public.mon_fuseau()` | false | true | true | `df015b341503e85ecebe9e57fefb086b` |
| `public.mon_groupe_detail(p_groupe_id uuid)` | false | true | true | `2a294f40be8845fb7df1b98655ffea78` |
| `public.next_immutable_id(role_code app_role, initials text)` | false | true | false | `b33f7d92b9211e63497e47240599ce72` |
| `public.partie_concernee(p_profile_id uuid)` | false | true | true | `1eb8c65b41d86791b900ab7e40208389` |
| `public.personnes_observables()` | true | true | true | `0f42e63032d25873d2658c53ea669399` |
| `public.peut_deposer_piece_identite(p_profile_id uuid)` | false | true | true | `363d0e5c384d1dbf1dc9c72765dca799` |
| `public.peut_poser_disponibilite(p_profile_id uuid)` | false | true | true | `73be37213e5c5f3ceb6cf11bdcc36605` |
| `public.planifier_evaluation(p_student_id uuid, p_niveau_id uuid, p_type text, p_date_prevue date)` | false | true | false | `edeae79dea1ee637962a2f9f68e45968` |
| `public.politique_observation_effective(p_groupe_id uuid)` | false | true | false | `fe478b6be57c4b0e11648dedfd6a8417` |
| `public.poser_exception_progression(p_student_id uuid, p_type text, p_motif text)` | false | true | false | `476c9fbc67014db1aba74e764b0acf67` |
| `public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text)` | false | true | false | `b42b46c02c394102058503378bc35c6e` |
| `public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer)` | false | true | false | `b5ac5d0c855282281567be91c3d211c1` |
| `public.preparer_depot_piece_identite(p_profile_id uuid, p_doc_type text)` | false | true | false | `a5f61b7f8dad3d63938248b34ec77934` |
| `public.profil_de_mon_foyer(p_profile_id text)` | true | true | true | `9a229eac8bc0751df03eac3693c279d5` |
| `public.programme_niveaux_admin(p_version_id uuid)` | false | true | true | `528cede3db466e4026bd81f48b65abc2` |
| `public.programme_versions_admin()` | false | true | true | `0c527e4b9077b9c58db1abd84de39b08` |
| `public.progression_admin()` | false | true | true | `68b358b2d8edf96816388202a8abaca9` |
| `public.progression_promouvoir(p_student_id uuid, p_niveau_id uuid, p_motif text)` | false | true | false | `e538d880616ae549860df58ebe06b15f` |
| `public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)` | false | true | false | `af005c1a3ad93786c1aed15c0e9fae0b` |
| `public.publier_version_programme(p_version_id uuid, p_motif text)` | false | true | false | `c7715e24d0d338cea4113a3c787580c2` |
| `public.quitter_salle(p_session_id uuid)` | false | true | false | `c36b13c2df7b623747bb070bfea6279c` |
| `public.read_kyc_documents()` | false | true | true | `cccb3f874b090ea4b6de084ca6ef70ff` |
| `public.record_session_event(p_session_id uuid, p_profile_id uuid, p_event_type session_event_type, p_source text)` | false | true | false | `380de00d3a207f33eee34e98c9287a4c` |
| `public.regle_effective(p_profile_id uuid, p_key text)` | false | true | true | `778d4a4cde1a262d94e15cf74931130d` |
| `public.rejoindre_observation(p_session_id uuid)` | false | true | false | `11297b9563e6816b369cf55bc842af5e` |
| `public.ressources_du_groupe(p_groupe_id uuid)` | false | true | true | `7f3868abf037296891b446a5ff3a83ee` |
| `public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)` | false | true | false | `fcf523b2cdbebec969a5e2253de26aba` |
| `public.revoquer_appareil(p_device_id uuid)` | false | true | false | `94514a938b71c72c9c480554c0ac6bb1` |
| `public.revoquer_jeton_agent(p_id uuid)` | false | true | false | `fc536a7b55da1011ebd638ca0c269206` |
| `public.rls_auto_enable()` | true | true | false | `6998ea6b4c2480f5d2e34b5dcf3f8d36` |
| `public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid)` | false | true | true | `92f8a2b8ccf6814a0226c9ae2c339387` |
| `public.session_has_participant(p_session_id uuid, p_uid uuid)` | false | true | true | `c72c6cbc12f9af1c5e7e1ff64adec966` |
| `public.session_in_household(p_session_id uuid, p_household_id uuid)` | false | true | true | `146fb204821facbc32ef2013fd421758` |
| `public.sortir_observation(p_session_id uuid)` | false | true | false | `51afae46db2d837c08fb32f7b8671aac` |
| `public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)` | false | true | false | `21449ed510bae1e51bd71972989b0fa7` |
| `public.traiter_anomalie_qualite(p_type_anomalie text, p_ref_id uuid, p_note text)` | false | true | false | `8a78c8c8605e0bad66f15f62f406462b` |
| `public.transitions_fuseau_a_venir(p_jours integer)` | false | true | false | `c90a4ebcfe6a2f303dac10960cabddff` |
| `public.verifier_chaine_audit(p_limite integer)` | false | true | true | `cf28eb75e08bd5cdd0cb8d18067c720b` |
| `public.video_config_lire()` | false | true | true | `4af82d0a2db1602453eeeaf40a10e9cc` |
| `public.visites_observation(p_session_id uuid)` | false | true | false | `fac9c7bb4194a98c08c7455afc18cd6c` |

## Policies KYC et Storage observées

| Objet | Policy | Rôles | Commande | USING | WITH CHECK |
|---|---|---|---|---|---|
| public.kyc_documents | kyc_admin_all | authenticated | ALL | (app_role() = 'admin'::app_role) | (app_role() = 'admin'::app_role) |
| public.kyc_documents | kyc_guardian_insert | authenticated | INSERT |  | ((app_role() = 'guardian'::app_role) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = kyc_documents.profile_id) AND (p.household_id = app_household_id()) AND (p.deleted_at IS NULL))))) |
| public.kyc_documents | kyc_staff_self_insert | authenticated | INSERT |  | ((profile_id = auth.uid()) AND (app_role() = ANY (ARRAY['teacher'::app_role, 'controller'::app_role]))) |
| storage.objects | kyc_depot_self | authenticated | INSERT |  | ((bucket_id = 'kyc'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)) |
| storage.objects | kyc_lecture_admin | authenticated | SELECT | ((bucket_id = 'kyc'::text) AND (app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role]))) |  |

## Grants table/view observés

| Objet | Grantee | Privilège | Grantable |
|---|---|---|---|
| public.concern_famille_v | authenticated | DELETE | NO |
| public.concern_famille_v | authenticated | INSERT | NO |
| public.concern_famille_v | authenticated | REFERENCES | NO |
| public.concern_famille_v | authenticated | SELECT | NO |
| public.concern_famille_v | authenticated | TRIGGER | NO |
| public.concern_famille_v | authenticated | TRUNCATE | NO |
| public.concern_famille_v | authenticated | UPDATE | NO |
| public.concern_famille_v | postgres | DELETE | YES |
| public.concern_famille_v | postgres | INSERT | YES |
| public.concern_famille_v | postgres | REFERENCES | YES |
| public.concern_famille_v | postgres | SELECT | YES |
| public.concern_famille_v | postgres | TRIGGER | YES |
| public.concern_famille_v | postgres | TRUNCATE | YES |
| public.concern_famille_v | postgres | UPDATE | YES |
| public.concern_famille_v | service_role | DELETE | NO |
| public.concern_famille_v | service_role | INSERT | NO |
| public.concern_famille_v | service_role | REFERENCES | NO |
| public.concern_famille_v | service_role | SELECT | NO |
| public.concern_famille_v | service_role | TRIGGER | NO |
| public.concern_famille_v | service_role | TRUNCATE | NO |
| public.concern_famille_v | service_role | UPDATE | NO |
| public.eleves_en_attente_v | agent_ro | SELECT | NO |
| public.eleves_en_attente_v | authenticated | DELETE | NO |
| public.eleves_en_attente_v | authenticated | INSERT | NO |
| public.eleves_en_attente_v | authenticated | REFERENCES | NO |
| public.eleves_en_attente_v | authenticated | SELECT | NO |
| public.eleves_en_attente_v | authenticated | TRIGGER | NO |
| public.eleves_en_attente_v | authenticated | TRUNCATE | NO |
| public.eleves_en_attente_v | authenticated | UPDATE | NO |
| public.eleves_en_attente_v | postgres | DELETE | YES |
| public.eleves_en_attente_v | postgres | INSERT | YES |
| public.eleves_en_attente_v | postgres | REFERENCES | YES |
| public.eleves_en_attente_v | postgres | SELECT | YES |
| public.eleves_en_attente_v | postgres | TRIGGER | YES |
| public.eleves_en_attente_v | postgres | TRUNCATE | YES |
| public.eleves_en_attente_v | postgres | UPDATE | YES |
| public.eleves_en_attente_v | service_role | DELETE | NO |
| public.eleves_en_attente_v | service_role | INSERT | NO |
| public.eleves_en_attente_v | service_role | REFERENCES | NO |
| public.eleves_en_attente_v | service_role | SELECT | NO |
| public.eleves_en_attente_v | service_role | TRIGGER | NO |
| public.eleves_en_attente_v | service_role | TRUNCATE | NO |
| public.eleves_en_attente_v | service_role | UPDATE | NO |
| public.kyc_documents | authenticated | DELETE | NO |
| public.kyc_documents | authenticated | INSERT | NO |
| public.kyc_documents | authenticated | REFERENCES | NO |
| public.kyc_documents | authenticated | SELECT | NO |
| public.kyc_documents | authenticated | TRIGGER | NO |
| public.kyc_documents | authenticated | TRUNCATE | NO |
| public.kyc_documents | authenticated | UPDATE | NO |
| public.kyc_documents | postgres | DELETE | YES |
| public.kyc_documents | postgres | INSERT | YES |
| public.kyc_documents | postgres | REFERENCES | YES |
| public.kyc_documents | postgres | SELECT | YES |
| public.kyc_documents | postgres | TRIGGER | YES |
| public.kyc_documents | postgres | TRUNCATE | YES |
| public.kyc_documents | postgres | UPDATE | YES |
| public.kyc_documents | service_role | DELETE | NO |
| public.kyc_documents | service_role | INSERT | NO |
| public.kyc_documents | service_role | REFERENCES | NO |
| public.kyc_documents | service_role | SELECT | NO |
| public.kyc_documents | service_role | TRIGGER | NO |
| public.kyc_documents | service_role | TRUNCATE | NO |
| public.kyc_documents | service_role | UPDATE | NO |
| public.mes_affectations_v | agent_ro | SELECT | NO |
| public.mes_affectations_v | authenticated | DELETE | NO |
| public.mes_affectations_v | authenticated | INSERT | NO |
| public.mes_affectations_v | authenticated | REFERENCES | NO |
| public.mes_affectations_v | authenticated | SELECT | NO |
| public.mes_affectations_v | authenticated | TRIGGER | NO |
| public.mes_affectations_v | authenticated | TRUNCATE | NO |
| public.mes_affectations_v | authenticated | UPDATE | NO |
| public.mes_affectations_v | postgres | DELETE | YES |
| public.mes_affectations_v | postgres | INSERT | YES |
| public.mes_affectations_v | postgres | REFERENCES | YES |
| public.mes_affectations_v | postgres | SELECT | YES |
| public.mes_affectations_v | postgres | TRIGGER | YES |
| public.mes_affectations_v | postgres | TRUNCATE | YES |
| public.mes_affectations_v | postgres | UPDATE | YES |
| public.mes_affectations_v | service_role | DELETE | NO |
| public.mes_affectations_v | service_role | INSERT | NO |
| public.mes_affectations_v | service_role | REFERENCES | NO |
| public.mes_affectations_v | service_role | SELECT | NO |
| public.mes_affectations_v | service_role | TRIGGER | NO |
| public.mes_affectations_v | service_role | TRUNCATE | NO |
| public.mes_affectations_v | service_role | UPDATE | NO |
| public.mes_appareils_v | agent_ro | SELECT | NO |
| public.mes_appareils_v | anon | DELETE | NO |
| public.mes_appareils_v | anon | INSERT | NO |
| public.mes_appareils_v | anon | REFERENCES | NO |
| public.mes_appareils_v | anon | SELECT | NO |
| public.mes_appareils_v | anon | TRIGGER | NO |
| public.mes_appareils_v | anon | TRUNCATE | NO |
| public.mes_appareils_v | anon | UPDATE | NO |
| public.mes_appareils_v | authenticated | DELETE | NO |
| public.mes_appareils_v | authenticated | INSERT | NO |
| public.mes_appareils_v | authenticated | REFERENCES | NO |
| public.mes_appareils_v | authenticated | SELECT | NO |
| public.mes_appareils_v | authenticated | TRIGGER | NO |
| public.mes_appareils_v | authenticated | TRUNCATE | NO |
| public.mes_appareils_v | authenticated | UPDATE | NO |
| public.mes_appareils_v | postgres | DELETE | YES |
| public.mes_appareils_v | postgres | INSERT | YES |
| public.mes_appareils_v | postgres | REFERENCES | YES |
| public.mes_appareils_v | postgres | SELECT | YES |
| public.mes_appareils_v | postgres | TRIGGER | YES |
| public.mes_appareils_v | postgres | TRUNCATE | YES |
| public.mes_appareils_v | postgres | UPDATE | YES |
| public.mes_appareils_v | service_role | DELETE | NO |
| public.mes_appareils_v | service_role | INSERT | NO |
| public.mes_appareils_v | service_role | REFERENCES | NO |
| public.mes_appareils_v | service_role | SELECT | NO |
| public.mes_appareils_v | service_role | TRIGGER | NO |
| public.mes_appareils_v | service_role | TRUNCATE | NO |
| public.mes_appareils_v | service_role | UPDATE | NO |
| public.mes_codes_appairage_v | agent_ro | SELECT | NO |
| public.mes_codes_appairage_v | anon | DELETE | NO |
| public.mes_codes_appairage_v | anon | INSERT | NO |
| public.mes_codes_appairage_v | anon | REFERENCES | NO |
| public.mes_codes_appairage_v | anon | SELECT | NO |
| public.mes_codes_appairage_v | anon | TRIGGER | NO |
| public.mes_codes_appairage_v | anon | TRUNCATE | NO |
| public.mes_codes_appairage_v | anon | UPDATE | NO |
| public.mes_codes_appairage_v | authenticated | DELETE | NO |
| public.mes_codes_appairage_v | authenticated | INSERT | NO |
| public.mes_codes_appairage_v | authenticated | REFERENCES | NO |
| public.mes_codes_appairage_v | authenticated | SELECT | NO |
| public.mes_codes_appairage_v | authenticated | TRIGGER | NO |
| public.mes_codes_appairage_v | authenticated | TRUNCATE | NO |
| public.mes_codes_appairage_v | authenticated | UPDATE | NO |
| public.mes_codes_appairage_v | postgres | DELETE | YES |
| public.mes_codes_appairage_v | postgres | INSERT | YES |
| public.mes_codes_appairage_v | postgres | REFERENCES | YES |
| public.mes_codes_appairage_v | postgres | SELECT | YES |
| public.mes_codes_appairage_v | postgres | TRIGGER | YES |
| public.mes_codes_appairage_v | postgres | TRUNCATE | YES |
| public.mes_codes_appairage_v | postgres | UPDATE | YES |
| public.mes_codes_appairage_v | service_role | DELETE | NO |
| public.mes_codes_appairage_v | service_role | INSERT | NO |
| public.mes_codes_appairage_v | service_role | REFERENCES | NO |
| public.mes_codes_appairage_v | service_role | SELECT | NO |
| public.mes_codes_appairage_v | service_role | TRIGGER | NO |
| public.mes_codes_appairage_v | service_role | TRUNCATE | NO |
| public.mes_codes_appairage_v | service_role | UPDATE | NO |
| public.mes_groupes_famille_v | agent_ro | SELECT | NO |
| public.mes_groupes_famille_v | authenticated | DELETE | NO |
| public.mes_groupes_famille_v | authenticated | INSERT | NO |
| public.mes_groupes_famille_v | authenticated | REFERENCES | NO |
| public.mes_groupes_famille_v | authenticated | SELECT | NO |
| public.mes_groupes_famille_v | authenticated | TRIGGER | NO |
| public.mes_groupes_famille_v | authenticated | TRUNCATE | NO |
| public.mes_groupes_famille_v | authenticated | UPDATE | NO |
| public.mes_groupes_famille_v | postgres | DELETE | YES |
| public.mes_groupes_famille_v | postgres | INSERT | YES |
| public.mes_groupes_famille_v | postgres | REFERENCES | YES |
| public.mes_groupes_famille_v | postgres | SELECT | YES |
| public.mes_groupes_famille_v | postgres | TRIGGER | YES |
| public.mes_groupes_famille_v | postgres | TRUNCATE | YES |
| public.mes_groupes_famille_v | postgres | UPDATE | YES |
| public.mes_groupes_famille_v | service_role | DELETE | NO |
| public.mes_groupes_famille_v | service_role | INSERT | NO |
| public.mes_groupes_famille_v | service_role | REFERENCES | NO |
| public.mes_groupes_famille_v | service_role | SELECT | NO |
| public.mes_groupes_famille_v | service_role | TRIGGER | NO |
| public.mes_groupes_famille_v | service_role | TRUNCATE | NO |
| public.mes_groupes_famille_v | service_role | UPDATE | NO |
| public.mes_groupes_v | agent_ro | SELECT | NO |
| public.mes_groupes_v | authenticated | DELETE | NO |
| public.mes_groupes_v | authenticated | INSERT | NO |
| public.mes_groupes_v | authenticated | REFERENCES | NO |
| public.mes_groupes_v | authenticated | SELECT | NO |
| public.mes_groupes_v | authenticated | TRIGGER | NO |
| public.mes_groupes_v | authenticated | TRUNCATE | NO |
| public.mes_groupes_v | authenticated | UPDATE | NO |
| public.mes_groupes_v | postgres | DELETE | YES |
| public.mes_groupes_v | postgres | INSERT | YES |
| public.mes_groupes_v | postgres | REFERENCES | YES |
| public.mes_groupes_v | postgres | SELECT | YES |
| public.mes_groupes_v | postgres | TRIGGER | YES |
| public.mes_groupes_v | postgres | TRUNCATE | YES |
| public.mes_groupes_v | postgres | UPDATE | YES |
| public.mes_groupes_v | service_role | DELETE | NO |
| public.mes_groupes_v | service_role | INSERT | NO |
| public.mes_groupes_v | service_role | REFERENCES | NO |
| public.mes_groupes_v | service_role | SELECT | NO |
| public.mes_groupes_v | service_role | TRIGGER | NO |
| public.mes_groupes_v | service_role | TRUNCATE | NO |
| public.mes_groupes_v | service_role | UPDATE | NO |
| public.mes_seances_enseignant_v | agent_ro | SELECT | NO |
| public.mes_seances_enseignant_v | authenticated | DELETE | NO |
| public.mes_seances_enseignant_v | authenticated | INSERT | NO |
| public.mes_seances_enseignant_v | authenticated | REFERENCES | NO |
| public.mes_seances_enseignant_v | authenticated | SELECT | NO |
| public.mes_seances_enseignant_v | authenticated | TRIGGER | NO |
| public.mes_seances_enseignant_v | authenticated | TRUNCATE | NO |
| public.mes_seances_enseignant_v | authenticated | UPDATE | NO |
| public.mes_seances_enseignant_v | postgres | DELETE | YES |
| public.mes_seances_enseignant_v | postgres | INSERT | YES |
| public.mes_seances_enseignant_v | postgres | REFERENCES | YES |
| public.mes_seances_enseignant_v | postgres | SELECT | YES |
| public.mes_seances_enseignant_v | postgres | TRIGGER | YES |
| public.mes_seances_enseignant_v | postgres | TRUNCATE | YES |
| public.mes_seances_enseignant_v | postgres | UPDATE | YES |
| public.mes_seances_enseignant_v | service_role | DELETE | NO |
| public.mes_seances_enseignant_v | service_role | INSERT | NO |
| public.mes_seances_enseignant_v | service_role | REFERENCES | NO |
| public.mes_seances_enseignant_v | service_role | SELECT | NO |
| public.mes_seances_enseignant_v | service_role | TRIGGER | NO |
| public.mes_seances_enseignant_v | service_role | TRUNCATE | NO |
| public.mes_seances_enseignant_v | service_role | UPDATE | NO |
| public.mes_seances_v | agent_ro | SELECT | NO |
| public.mes_seances_v | authenticated | DELETE | NO |
| public.mes_seances_v | authenticated | INSERT | NO |
| public.mes_seances_v | authenticated | REFERENCES | NO |
| public.mes_seances_v | authenticated | SELECT | NO |
| public.mes_seances_v | authenticated | TRIGGER | NO |
| public.mes_seances_v | authenticated | TRUNCATE | NO |
| public.mes_seances_v | authenticated | UPDATE | NO |
| public.mes_seances_v | postgres | DELETE | YES |
| public.mes_seances_v | postgres | INSERT | YES |
| public.mes_seances_v | postgres | REFERENCES | YES |
| public.mes_seances_v | postgres | SELECT | YES |
| public.mes_seances_v | postgres | TRIGGER | YES |
| public.mes_seances_v | postgres | TRUNCATE | YES |
| public.mes_seances_v | postgres | UPDATE | YES |
| public.mes_seances_v | service_role | DELETE | NO |
| public.mes_seances_v | service_role | INSERT | NO |
| public.mes_seances_v | service_role | REFERENCES | NO |
| public.mes_seances_v | service_role | SELECT | NO |
| public.mes_seances_v | service_role | TRIGGER | NO |
| public.mes_seances_v | service_role | TRUNCATE | NO |
| public.mes_seances_v | service_role | UPDATE | NO |
| public.presence_seance_v | agent_ro | SELECT | NO |
| public.presence_seance_v | anon | DELETE | NO |
| public.presence_seance_v | anon | INSERT | NO |
| public.presence_seance_v | anon | REFERENCES | NO |
| public.presence_seance_v | anon | SELECT | NO |
| public.presence_seance_v | anon | TRIGGER | NO |
| public.presence_seance_v | anon | TRUNCATE | NO |
| public.presence_seance_v | anon | UPDATE | NO |
| public.presence_seance_v | authenticated | DELETE | NO |
| public.presence_seance_v | authenticated | INSERT | NO |
| public.presence_seance_v | authenticated | REFERENCES | NO |
| public.presence_seance_v | authenticated | SELECT | NO |
| public.presence_seance_v | authenticated | TRIGGER | NO |
| public.presence_seance_v | authenticated | TRUNCATE | NO |
| public.presence_seance_v | authenticated | UPDATE | NO |
| public.presence_seance_v | postgres | DELETE | YES |
| public.presence_seance_v | postgres | INSERT | YES |
| public.presence_seance_v | postgres | REFERENCES | YES |
| public.presence_seance_v | postgres | SELECT | YES |
| public.presence_seance_v | postgres | TRIGGER | YES |
| public.presence_seance_v | postgres | TRUNCATE | YES |
| public.presence_seance_v | postgres | UPDATE | YES |
| public.presence_seance_v | service_role | DELETE | NO |
| public.presence_seance_v | service_role | INSERT | NO |
| public.presence_seance_v | service_role | REFERENCES | NO |
| public.presence_seance_v | service_role | SELECT | NO |
| public.presence_seance_v | service_role | TRIGGER | NO |
| public.presence_seance_v | service_role | TRUNCATE | NO |
| public.presence_seance_v | service_role | UPDATE | NO |
| public.profils_du_foyer_v | agent_ro | SELECT | NO |
| public.profils_du_foyer_v | anon | DELETE | NO |
| public.profils_du_foyer_v | anon | INSERT | NO |
| public.profils_du_foyer_v | anon | REFERENCES | NO |
| public.profils_du_foyer_v | anon | SELECT | NO |
| public.profils_du_foyer_v | anon | TRIGGER | NO |
| public.profils_du_foyer_v | anon | TRUNCATE | NO |
| public.profils_du_foyer_v | anon | UPDATE | NO |
| public.profils_du_foyer_v | authenticated | DELETE | NO |
| public.profils_du_foyer_v | authenticated | INSERT | NO |
| public.profils_du_foyer_v | authenticated | REFERENCES | NO |
| public.profils_du_foyer_v | authenticated | SELECT | NO |
| public.profils_du_foyer_v | authenticated | TRIGGER | NO |
| public.profils_du_foyer_v | authenticated | TRUNCATE | NO |
| public.profils_du_foyer_v | authenticated | UPDATE | NO |
| public.profils_du_foyer_v | postgres | DELETE | YES |
| public.profils_du_foyer_v | postgres | INSERT | YES |
| public.profils_du_foyer_v | postgres | REFERENCES | YES |
| public.profils_du_foyer_v | postgres | SELECT | YES |
| public.profils_du_foyer_v | postgres | TRIGGER | YES |
| public.profils_du_foyer_v | postgres | TRUNCATE | YES |
| public.profils_du_foyer_v | postgres | UPDATE | YES |
| public.profils_du_foyer_v | service_role | DELETE | NO |
| public.profils_du_foyer_v | service_role | INSERT | NO |
| public.profils_du_foyer_v | service_role | REFERENCES | NO |
| public.profils_du_foyer_v | service_role | SELECT | NO |
| public.profils_du_foyer_v | service_role | TRIGGER | NO |
| public.profils_du_foyer_v | service_role | TRUNCATE | NO |
| public.profils_du_foyer_v | service_role | UPDATE | NO |
| public.regles_profil_v | agent_ro | SELECT | NO |
| public.regles_profil_v | authenticated | DELETE | NO |
| public.regles_profil_v | authenticated | INSERT | NO |
| public.regles_profil_v | authenticated | REFERENCES | NO |
| public.regles_profil_v | authenticated | SELECT | NO |
| public.regles_profil_v | authenticated | TRIGGER | NO |
| public.regles_profil_v | authenticated | TRUNCATE | NO |
| public.regles_profil_v | authenticated | UPDATE | NO |
| public.regles_profil_v | postgres | DELETE | YES |
| public.regles_profil_v | postgres | INSERT | YES |
| public.regles_profil_v | postgres | REFERENCES | YES |
| public.regles_profil_v | postgres | SELECT | YES |
| public.regles_profil_v | postgres | TRIGGER | YES |
| public.regles_profil_v | postgres | TRUNCATE | YES |
| public.regles_profil_v | postgres | UPDATE | YES |
| public.regles_profil_v | service_role | DELETE | NO |
| public.regles_profil_v | service_role | INSERT | NO |
| public.regles_profil_v | service_role | REFERENCES | NO |
| public.regles_profil_v | service_role | SELECT | NO |
| public.regles_profil_v | service_role | TRIGGER | NO |
| public.regles_profil_v | service_role | TRUNCATE | NO |
| public.regles_profil_v | service_role | UPDATE | NO |
| public.session_peers_v | agent_ro | SELECT | NO |
| public.session_peers_v | authenticated | DELETE | NO |
| public.session_peers_v | authenticated | INSERT | NO |
| public.session_peers_v | authenticated | REFERENCES | NO |
| public.session_peers_v | authenticated | SELECT | NO |
| public.session_peers_v | authenticated | TRIGGER | NO |
| public.session_peers_v | authenticated | TRUNCATE | NO |
| public.session_peers_v | authenticated | UPDATE | NO |
| public.session_peers_v | postgres | DELETE | YES |
| public.session_peers_v | postgres | INSERT | YES |
| public.session_peers_v | postgres | REFERENCES | YES |
| public.session_peers_v | postgres | SELECT | YES |
| public.session_peers_v | postgres | TRIGGER | YES |
| public.session_peers_v | postgres | TRUNCATE | YES |
| public.session_peers_v | postgres | UPDATE | YES |
| public.session_peers_v | service_role | DELETE | NO |
| public.session_peers_v | service_role | INSERT | NO |
| public.session_peers_v | service_role | REFERENCES | NO |
| public.session_peers_v | service_role | SELECT | NO |
| public.session_peers_v | service_role | TRIGGER | NO |
| public.session_peers_v | service_role | TRUNCATE | NO |
| public.session_peers_v | service_role | UPDATE | NO |
| public.teacher_roster_v | agent_ro | SELECT | NO |
| public.teacher_roster_v | authenticated | DELETE | NO |
| public.teacher_roster_v | authenticated | INSERT | NO |
| public.teacher_roster_v | authenticated | REFERENCES | NO |
| public.teacher_roster_v | authenticated | SELECT | NO |
| public.teacher_roster_v | authenticated | TRIGGER | NO |
| public.teacher_roster_v | authenticated | TRUNCATE | NO |
| public.teacher_roster_v | authenticated | UPDATE | NO |
| public.teacher_roster_v | postgres | DELETE | YES |
| public.teacher_roster_v | postgres | INSERT | YES |
| public.teacher_roster_v | postgres | REFERENCES | YES |
| public.teacher_roster_v | postgres | SELECT | YES |
| public.teacher_roster_v | postgres | TRIGGER | YES |
| public.teacher_roster_v | postgres | TRUNCATE | YES |
| public.teacher_roster_v | postgres | UPDATE | YES |
| public.teacher_roster_v | service_role | DELETE | NO |
| public.teacher_roster_v | service_role | INSERT | NO |
| public.teacher_roster_v | service_role | REFERENCES | NO |
| public.teacher_roster_v | service_role | SELECT | NO |
| public.teacher_roster_v | service_role | TRIGGER | NO |
| public.teacher_roster_v | service_role | TRUNCATE | NO |
| public.teacher_roster_v | service_role | UPDATE | NO |
| public.tendance_feedback_v | authenticated | DELETE | NO |
| public.tendance_feedback_v | authenticated | INSERT | NO |
| public.tendance_feedback_v | authenticated | REFERENCES | NO |
| public.tendance_feedback_v | authenticated | SELECT | NO |
| public.tendance_feedback_v | authenticated | TRIGGER | NO |
| public.tendance_feedback_v | authenticated | TRUNCATE | NO |
| public.tendance_feedback_v | authenticated | UPDATE | NO |
| public.tendance_feedback_v | postgres | DELETE | YES |
| public.tendance_feedback_v | postgres | INSERT | YES |
| public.tendance_feedback_v | postgres | REFERENCES | YES |
| public.tendance_feedback_v | postgres | SELECT | YES |
| public.tendance_feedback_v | postgres | TRIGGER | YES |
| public.tendance_feedback_v | postgres | TRUNCATE | YES |
| public.tendance_feedback_v | postgres | UPDATE | YES |
| public.tendance_feedback_v | service_role | DELETE | NO |
| public.tendance_feedback_v | service_role | INSERT | NO |
| public.tendance_feedback_v | service_role | REFERENCES | NO |
| public.tendance_feedback_v | service_role | SELECT | NO |
| public.tendance_feedback_v | service_role | TRIGGER | NO |
| public.tendance_feedback_v | service_role | TRUNCATE | NO |
| public.tendance_feedback_v | service_role | UPDATE | NO |
| storage.objects | anon | DELETE | NO |
| storage.objects | anon | INSERT | NO |
| storage.objects | anon | REFERENCES | NO |
| storage.objects | anon | SELECT | NO |
| storage.objects | anon | TRIGGER | NO |
| storage.objects | anon | TRUNCATE | NO |
| storage.objects | anon | UPDATE | NO |
| storage.objects | authenticated | DELETE | NO |
| storage.objects | authenticated | INSERT | NO |
| storage.objects | authenticated | REFERENCES | NO |
| storage.objects | authenticated | SELECT | NO |
| storage.objects | authenticated | TRIGGER | NO |
| storage.objects | authenticated | TRUNCATE | NO |
| storage.objects | authenticated | UPDATE | NO |

## Définitions des 15 vues observées

### public.eleves_en_attente_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT e.id AS student_id,
        CASE
            WHEN agent_identite_masquee() THEN e.immutable_id
            ELSE e.first_name
        END AS first_name,
    e.immutable_id,
    sp.level,
    sp.interface_mode,
    we.weekday,
    we.hour_local,
    we.timezone_iana,
    attente.depuis
   FROM profiles e
     JOIN student_profiles sp ON sp.profile_id = e.id AND sp.deleted_at IS NULL
     JOIN weekly_availability we ON we.profile_id = e.id
     JOIN weekly_availability wt ON wt.profile_id = auth.uid() AND instant_creneau(wt.weekday::integer, wt.hour_local::integer, wt.timezone_iana) = instant_creneau(we.weekday::integer, we.hour_local::integer, we.timezone_iana)
     JOIN LATERAL ( SELECT min(w2.created_at) AS depuis
           FROM weekly_availability w2
          WHERE w2.profile_id = e.id) attente ON true
  WHERE e.role = 'student'::app_role AND e.deleted_at IS NULL AND (e.account_status = ANY (ARRAY['active'::account_status, 'provisional_active'::account_status])) AND app_role() = 'teacher'::app_role AND NOT (EXISTS ( SELECT 1
           FROM teacher_student_assignments a
          WHERE a.student_id = e.id AND a.ended_at IS NULL));
```

### public.regles_profil_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT p.id AS profile_id,
    c.key,
    (c.value #>> '{}'::text[])::integer AS valeur_plateforme,
    (r.value #>> '{}'::text[])::integer AS valeur_surchargee,
    COALESCE((r.value #>> '{}'::text[])::integer, (c.value #>> '{}'::text[])::integer) AS valeur_effective,
    r.id AS override_id,
    r.reason AS motif,
    r.created_at AS pose_le
   FROM profiles p
     JOIN app_config c ON p.role = 'teacher'::app_role AND c.key = 'max_students_per_teacher'::text OR p.role = 'student'::app_role AND (c.key = ANY (ARRAY['session_duration_minutes'::text, 'session_paid_minimum_minutes'::text, 'break_minutes_between_sessions'::text]))
     LEFT JOIN rule_overrides r ON r.profile_id = p.id AND r.key = c.key AND r.ended_at IS NULL
  WHERE p.deleted_at IS NULL AND partie_concernee(p.id);
```

### public.teacher_roster_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT s.id AS session_id,
    p.id AS student_id,
        CASE
            WHEN agent_identite_masquee() THEN p.immutable_id
            ELSE p.first_name
        END AS first_name,
    p.immutable_id,
    sp.level,
    sp.riwaya,
    sp.interface_mode,
    prog.cycle AS curriculum_path,
    prog.nom_humain AS current_unit,
    COALESCE(goals.objectifs, '{}'::text[]) AS active_goals,
    pos.page_mushaf AS resume_page,
    pos.sourate AS resume_sourate,
    pos.verset AS resume_verset
   FROM sessions s
     JOIN session_participants spart ON spart.session_id = s.id
     JOIN profiles p ON p.id = spart.profile_id
     JOIN student_profiles sp ON sp.profile_id = p.id
     LEFT JOIN LATERAL ( SELECT pn.cycle,
            pn.nom_humain
           FROM progression_historique ph
             JOIN programme_niveaux pn ON pn.id = ph.niveau_id
          WHERE ph.student_id = p.id
          ORDER BY ph.created_at DESC
         LIMIT 1) prog ON true
     LEFT JOIN LATERAL ( SELECT srp.page_mushaf,
            srp.sourate,
            srp.verset
           FROM student_reading_position srp
          WHERE srp.student_profile_id = p.id
          ORDER BY srp.updated_at DESC
         LIMIT 1) pos ON true
     LEFT JOIN LATERAL ( SELECT ARRAY( SELECT la.purpose
                   FROM learning_assignment la
                  WHERE (la.student_id = p.id OR la.student_id IS NULL AND la.group_id = s.groupe_id) AND (la.status = ANY (ARRAY['a_faire'::text, 'en_cours'::text]))
                  ORDER BY la.due_at, la.starts_at
                 LIMIT 3) AS objectifs) goals ON true
  WHERE s.teacher_id = auth.uid() AND s.deleted_at IS NULL AND spart.deleted_at IS NULL AND p.deleted_at IS NULL;
```

### public.mes_codes_appairage_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT c.id,
    c.student_profile_id,
    c.expires_at,
    c.consumed_at,
    c.created_at
   FROM device_pairing_codes c
     JOIN profiles p ON p.id = c.student_profile_id
  WHERE c.deleted_at IS NULL AND p.deleted_at IS NULL AND p.household_id IS NOT NULL AND p.household_id = app_household_id();
```

### public.mes_groupes_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT g.id AS groupe_id,
    g.libelle,
    g.type_public,
    g.seuil_max,
    g.weekday,
    g.hour_local,
    g.timezone_iana,
    g.created_at,
    count(m.id) FILTER (WHERE m.left_at IS NULL)::integer AS nb_membres
   FROM groupes g
     LEFT JOIN groupe_membres m ON m.groupe_id = g.id
  WHERE g.ended_at IS NULL AND g.teacher_id = auth.uid()
  GROUP BY g.id, g.libelle, g.type_public, g.seuil_max, g.weekday, g.hour_local, g.timezone_iana, g.created_at;
```

### public.mes_seances_enseignant_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT s.id AS session_id,
    s.started_at,
    s.ended_at,
    s.status,
    s.session_type,
    s.prayer_pause_minutes,
    s.groupe_id,
    g.libelle AS groupe_libelle,
    g.type_public,
    g.seuil_max,
    count(DISTINCT sp.profile_id) FILTER (WHERE sp.role = 'student'::participant_role AND sp.deleted_at IS NULL)::integer AS nb_participants,
    (EXISTS ( SELECT 1
           FROM lesson_reports lr
          WHERE lr.session_id = s.id AND lr.deleted_at IS NULL)) AS cahier_depose
   FROM sessions s
     LEFT JOIN groupes g ON g.id = s.groupe_id
     LEFT JOIN session_participants sp ON sp.session_id = s.id
  WHERE s.deleted_at IS NULL AND s.teacher_id = auth.uid()
  GROUP BY s.id, s.started_at, s.ended_at, s.status, s.session_type, s.prayer_pause_minutes, s.groupe_id, g.libelle, g.type_public, g.seuil_max;
```

### public.mes_appareils_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT d.id,
    d.profile_id,
        CASE
            WHEN agent_identite_masquee() THEN p.immutable_id
            ELSE p.first_name
        END AS first_name,
    d.platform,
    d.label,
    d.paired_at,
    d.last_used_at,
    d.revoked_at
   FROM devices d
     JOIN profiles p ON p.id = d.profile_id
  WHERE d.deleted_at IS NULL AND p.deleted_at IS NULL AND p.household_id IS NOT NULL AND p.household_id = app_household_id();
```

### public.mes_seances_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT s.id AS session_id,
    s.started_at,
    s.ended_at,
    s.status,
    s.session_type,
    s.prayer_pause_minutes,
    eleve.id AS student_id,
        CASE
            WHEN agent_identite_masquee() THEN eleve.immutable_id
            ELSE eleve.first_name
        END AS student_first_name,
    eleve.immutable_id AS student_immutable_id,
    ens.id AS teacher_id,
        CASE
            WHEN agent_identite_masquee() THEN ens.immutable_id
            ELSE ens.first_name
        END AS teacher_first_name,
    ens.immutable_id AS teacher_immutable_id
   FROM sessions s
     JOIN session_participants spe ON spe.session_id = s.id AND spe.role = 'student'::participant_role AND spe.deleted_at IS NULL
     JOIN profiles eleve ON eleve.id = spe.profile_id AND eleve.deleted_at IS NULL
     JOIN profiles ens ON ens.id = s.teacher_id AND ens.deleted_at IS NULL
  WHERE s.deleted_at IS NULL AND (s.teacher_id = auth.uid() OR spe.profile_id = auth.uid() OR eleve.household_id IS NOT NULL AND eleve.household_id = app_household_id() OR (app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role])));
```

### public.profils_du_foyer_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT p.id,
        CASE
            WHEN agent_identite_masquee() THEN p.immutable_id
            ELSE p.first_name
        END AS first_name,
    p.immutable_id,
    sp.interface_mode,
    sp.camera_policy,
    sp.avatar_storage_key,
    p.access_until
   FROM profiles p
     JOIN student_profiles sp ON sp.profile_id = p.id
  WHERE p.household_id IS NOT NULL AND p.household_id = app_household_id() AND p.role = 'student'::app_role AND p.deleted_at IS NULL AND sp.deleted_at IS NULL;
```

### public.mes_affectations_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT a.id,
    a.teacher_id,
        CASE
            WHEN agent_identite_masquee() THEN ens.immutable_id
            ELSE ens.first_name
        END AS teacher_first_name,
    ens.immutable_id AS teacher_immutable_id,
    a.student_id,
        CASE
            WHEN agent_identite_masquee() THEN eleve.immutable_id
            ELSE eleve.first_name
        END AS student_first_name,
    eleve.immutable_id AS student_immutable_id,
    a.weekday,
    a.hour_local,
    a.timezone_iana,
    a.created_at,
    a.ended_at
   FROM teacher_student_assignments a
     JOIN profiles ens ON ens.id = a.teacher_id AND ens.deleted_at IS NULL
     JOIN profiles eleve ON eleve.id = a.student_id AND eleve.deleted_at IS NULL
  WHERE a.teacher_id = auth.uid() OR partie_concernee(a.student_id);
```

### public.presence_seance_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT sp.session_id,
    sp.profile_id,
    sp.role,
        CASE
            WHEN agent_identite_masquee() THEN p.immutable_id
            ELSE p.first_name
        END AS prenom,
    p.immutable_id AS identifiant_immuable,
    etat_presence(sp.session_id, sp.profile_id) AS etat,
    ( SELECT
                CASE
                    WHEN min(e.server_ts) IS NOT NULL THEN GREATEST(min(e.server_ts), s.started_at)
                    ELSE NULL::timestamp with time zone
                END AS "case"
           FROM session_events e
          WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id AND e.event_type = 'joined'::session_event_type) AS entre_le,
    ( SELECT max(e.server_ts) AS max
           FROM session_events e
          WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id) AS derniere_trace_le,
    o.etat IS NOT NULL AS consolide,
    o.decide_le AS consolide_le,
    s.started_at,
    s.ended_at,
    s.status AS statut_seance
   FROM session_participants sp
     JOIN sessions s ON s.id = sp.session_id
     JOIN profiles p ON p.id = sp.profile_id
     LEFT JOIN session_presence_override o ON o.session_id = sp.session_id AND o.profile_id = sp.profile_id
  WHERE sp.deleted_at IS NULL AND s.deleted_at IS NULL AND p.deleted_at IS NULL AND ((app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role])) OR s.teacher_id = auth.uid() OR app_role() = 'guardian'::app_role AND est_du_foyer(p.id) OR sp.profile_id = auth.uid()) AND ((sp.role <> ALL (ARRAY['masked_controller'::participant_role, 'admin_masked'::participant_role])) OR app_role() = 'admin'::app_role);
```

### public.session_peers_v

Owner: `postgres`; options: `(aucune)`.

```sql
 SELECT DISTINCT sp.session_id,
    p2.id AS peer_id,
    p2.first_name,
    p2.immutable_id
   FROM session_participants sp
     JOIN session_participants sp2 USING (session_id)
     JOIN profiles p2 ON p2.id = sp2.profile_id
  WHERE sp.profile_id = auth.uid() AND sp.deleted_at IS NULL AND sp2.deleted_at IS NULL AND p2.deleted_at IS NULL AND sp2.profile_id <> sp.profile_id AND ((sp2.role <> ALL (ARRAY['masked_controller'::participant_role, 'admin_masked'::participant_role, 'guardian_observer'::participant_role])) OR app_role() = 'admin'::app_role);
```

### public.concern_famille_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT id,
    categorie,
    family_summary,
    transmis_le,
    transmis_a
   FROM student_concern c
  WHERE statut = 'transmis'::concern_status AND family_summary IS NOT NULL AND (est_du_foyer(student_id) OR student_id = auth.uid());
```

### public.mes_groupes_famille_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT g.id AS groupe_id,
    g.libelle,
    g.type_public,
    g.seuil_max,
    g.weekday,
    g.hour_local,
    g.timezone_iana,
    g.couleur_jeton,
    g.nom_cours,
    g.programme_niveau_id,
    g.teacher_id,
        CASE
            WHEN agent_identite_masquee() THEN NULL::text
            ELSE tp_p.first_name
        END AS teacher_prenom,
    tp.titre AS teacher_titre,
    tp.photo_storage_key AS teacher_photo_cle,
    count(m2.id) FILTER (WHERE m2.left_at IS NULL)::integer AS nb_membres
   FROM groupes g
     JOIN groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
     JOIN profiles tp_p ON tp_p.id = g.teacher_id
     LEFT JOIN teacher_profiles tp ON tp.profile_id = g.teacher_id
     LEFT JOIN groupe_membres m2 ON m2.groupe_id = g.id
  WHERE g.ended_at IS NULL AND app_account_valid() AND (m.student_id = auth.uid() OR est_du_foyer(m.student_id))
  GROUP BY g.id, g.libelle, g.type_public, g.seuil_max, g.weekday, g.hour_local, g.timezone_iana, g.couleur_jeton, g.nom_cours, g.programme_niveau_id, g.teacher_id, tp_p.first_name, tp.titre, tp.photo_storage_key;
```

### public.tendance_feedback_v

Owner: `postgres`; options: `security_barrier=true`.

```sql
 SELECT f.groupe_id,
    f.question_id,
    count(*) AS nombre_echantillons,
    count(*) FILTER (WHERE f.reponse = 'difficile'::text) AS n_difficile,
    count(*) FILTER (WHERE f.reponse = 'bien'::text) AS n_bien,
    count(*) FILTER (WHERE f.reponse = 'tres_bien'::text) AS n_tres_bien
   FROM session_feedback f
     JOIN groupes g ON g.id = f.groupe_id
  WHERE g.teacher_id = auth.uid() OR app_role() = 'admin'::app_role
  GROUP BY f.groupe_id, f.question_id
 HAVING count(*) >= app_config_int('feedback_seuil_tendance'::text, 5);
```

## Définitions de fonctions avec gardes négatives (39), KYC, et garde profils

### public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'ajout d''un eleve a un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour ajouter un eleve a un groupe';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.role = 'student'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if exists (
    select 1 from public.groupe_membres where student_id = p_student_profile_id and left_at is null
  ) then
    raise exception 'cet eleve appartient deja a un groupe actif';
  end if;

  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);

  perform public.log_sensitive_access(
    'eleve_ajoute_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$

```

### public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)

```sql
CREATE OR REPLACE FUNCTION public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  select statut into v_statut from public.programme_versions where id = p_version_id;

  if v_statut is null then
    raise exception 'version introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  end if;

  insert into public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre, description)
  values (p_version_id, p_code_technique, p_nom_humain, p_cycle, p_ordre, p_description)
  returning id into v_id;

  perform public.log_sensitive_access(
    'niveau_programme_ajoute', 'programme_niveaux', v_id::text,
    jsonb_build_object('version_id', p_version_id, 'code_technique', p_code_technique)
  );

  return v_id;
end;
$function$

```

### public.assister_seance(p_session_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.assister_seance(p_session_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance public.sessions%rowtype;
  v_role   public.participant_role;
begin
  if public.app_role() <> 'guardian' or not public.app_account_valid() then
    raise exception 'assister est reserve au tuteur du foyer'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if not public.session_in_household(p_session_id, public.app_household_id()) then
    raise exception 'cette seance n''est pas celle d''un enfant du foyer'
      using errcode = 'insufficient_privilege';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;
  if now() < v_seance.started_at then
    raise exception 'seance pas encore commencee' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'seance terminee' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id and sp.profile_id = auth.uid()
     and sp.deleted_at is null;
  if found and v_role <> 'guardian_observer' then
    raise exception 'ce profil participe deja a cette seance a un autre titre'
      using errcode = 'check_violation';
  end if;

  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), 'guardian_observer')
  on conflict (session_id, profile_id) do update
    set deleted_at = null, role = 'guardian_observer';

  return p_session_id;
end;
$function$

```

### public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_tz         text;
  v_instant    timestamptz;
  v_hors       boolean;
  v_motif      text := nullif(btrim(coalesce(p_motif, '')), '');
  v_assignment uuid;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  select w.timezone_iana into v_tz
  from public.weekly_availability w
  join public.profiles p on p.id = w.profile_id
  where w.profile_id = p_student_profile_id
    and w.weekday = p_weekday and w.hour_local = p_hour
    and p.role = 'student' and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_tz is null then
    raise exception 'ce creneau n''est pas propose par ce foyer';
  end if;

  v_instant := public.instant_creneau(p_weekday, p_hour, v_tz);

  v_hors := not exists (
    select 1 from public.weekly_availability wt
    where wt.profile_id = p_teacher_profile_id
      and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  );

  if v_hors and v_motif is null then
    raise exception 'attribuer hors des disponibilites de cet enseignant exige un motif';
  end if;

  if exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = p_student_profile_id and a.ended_at is null
  ) then
    raise exception 'cet eleve a deja un enseignant';
  end if;

  begin
    insert into public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    values (p_teacher_profile_id, p_student_profile_id, p_weekday, p_hour, v_tz)
    returning id into v_assignment;
  exception
    when unique_violation then
      raise exception 'cet eleve vient d''etre pris par un enseignant';
  end;

  perform public.materialiser_seances(v_assignment);

  perform public.log_sensitive_access('affectation_attribuee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
                       'teacher_id', p_teacher_profile_id,
                       'weekday', p_weekday, 'hour_local', p_hour,
                       'hors_disponibilite', v_hors,
                       'motif', v_motif));

  return v_assignment;
end;
$function$

```

### public.clore_regle(p_override_id uuid, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.clore_regle(p_override_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur clot une regle';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une cloture sans motif ne se relit pas';
  end if;

  update public.rule_overrides
  set ended_at = now(), ended_by = auth.uid(), end_reason = btrim(p_motif)
  where id = p_override_id and ended_at is null;

  if not found then
    raise exception 'regle introuvable ou deja close';
  end if;

  perform public.log_sensitive_access('regle_close', 'rule_overrides',
    p_override_id::text, jsonb_build_object('motif', btrim(p_motif)));
end;
$function$

```

### public.cloturer_groupe(p_groupe_id uuid, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.cloturer_groupe(p_groupe_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'cloture de groupe reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour cloturer un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = 'groupe cloture : ' || p_motif
  where groupe_id = p_groupe_id and left_at is null;

  update public.groupes
  set ended_at = now(), ended_by = auth.uid(), end_reason = p_motif
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access('groupe_cloture', 'groupes', p_groupe_id::text, jsonb_build_object('motif', p_motif));
end;
$function$

```

### public.creer_code_appairage(p_student_profile_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.creer_code_appairage(p_student_profile_id uuid)
 RETURNS TABLE(code text, expires_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  -- 32 caracteres, sans 0 O 1 I : 256 est un multiple de 32, donc le tirage est
  -- uniforme sans biais de modulo. 32^6, soit environ 1,07 milliard.
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code text;
  v_expire timestamptz;
  v_max int;
  v_actifs int;
begin
  if public.app_role() <> 'guardian' or not public.app_account_valid() then
    raise exception 'seul un tuteur au compte valide appaire un appareil';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.household_id is not null
      and p.household_id = public.app_household_id()
      and p.role = 'student'
      and p.deleted_at is null
  ) then
    raise exception 'cet eleve n''appartient pas a votre foyer';
  end if;

  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into v_max;
  select count(*) into v_actifs from public.devices d
  where d.profile_id = p_student_profile_id
    and d.revoked_at is null and d.deleted_at is null;
  if v_actifs >= v_max then
    raise exception 'plafond d''appareils atteint';
  end if;

  -- Un seul code vivant par eleve : en demander un nouveau perime le precedent.
  update public.device_pairing_codes
  set deleted_at = now()
  where student_profile_id = p_student_profile_id
    and consumed_at is null and deleted_at is null;

  select string_agg(substr(v_alphabet, 1 + (get_byte(s.b, i) % 32), 1), '' order by i)
  into v_code
  from (select extensions.gen_random_bytes(6) as b) s,
       generate_series(0, 5) as i;

  v_expire := now() + make_interval(mins =>
    coalesce((public.get_config('pairing_code_ttl_minutes', '10'::jsonb) #>> '{}')::int, 10));

  insert into public.device_pairing_codes (student_profile_id, code_hash, created_by, expires_at)
  values (
    p_student_profile_id,
    encode(extensions.digest(convert_to(v_code, 'UTF8'), 'sha256'), 'hex'),
    auth.uid(),
    v_expire
  );

  perform public.log_sensitive_access('appairage_code_cree', 'device_pairing_codes',
    p_student_profile_id::text, '{}'::jsonb);

  return query select v_code, v_expire;
end;
$function$

```

### public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint)

```sql
CREATE OR REPLACE FUNCTION public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_seuil smallint;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'creation de groupe reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  v_seuil := coalesce(
    p_seuil_max,
    case p_type_public
      when 'enfant' then 5
      when 'adulte' then 6
      else null
    end
  );

  if v_seuil is null then
    raise exception 'type de public inconnu : %', p_type_public;
  end if;

  insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
  values (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$

```

### public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint)

```sql
CREATE OR REPLACE FUNCTION public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint DEFAULT NULL::smallint, p_timezone_iana text DEFAULT NULL::text, p_couleur_jeton smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_seuil smallint;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'creation de groupe reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_teacher_profile_id
      and p.role = 'teacher'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet enseignant n''existe pas ou son compte n''est pas valide';
  end if;

  if p_timezone_iana is not null then
    perform 1 from pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  v_seuil := coalesce(
    p_seuil_max,
    case p_type_public
      when 'enfant' then 5
      when 'adulte' then 6
      else null
    end
  );

  if v_seuil is null then
    raise exception 'type de public inconnu : %', p_type_public;
  end if;

  insert into public.groupes
    (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, couleur_jeton)
  values
    (p_teacher_profile_id, p_type_public, v_seuil, p_libelle, p_weekday, p_hour_local,
     coalesce(p_timezone_iana, 'Europe/Paris'), p_couleur_jeton)
  returning id into v_id;

  perform public.log_sensitive_access(
    'groupe_cree', 'groupes', v_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id, 'type_public', p_type_public, 'seuil_max', v_seuil)
  );

  return v_id;
end;
$function$

```

### public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer, p_identite_masquee boolean)

```sql
CREATE OR REPLACE FUNCTION public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer DEFAULT 8, p_identite_masquee boolean DEFAULT true)
 RETURNS TABLE(jeton text, jeton_id uuid, expire_le timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_secret text;
  v_role public.app_role;
  v_id uuid;
  v_expire timestamptz;
  v_immuable text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'emission reservee a l administration'
      using errcode = '42501';
  end if;
  if coalesce(btrim(p_libelle), '') = '' then
    raise exception 'un jeton sans libelle ne se revoque jamais : libelle obligatoire'
      using errcode = '22023';
  end if;
  if p_duree_heures is null or p_duree_heures < 1 or p_duree_heures > 24 then
    raise exception 'duree hors bornes : de 1 a 24 heures'
      using errcode = '22023';
  end if;

  select p.role, p.immutable_id into v_role, v_immuable
  from public.profiles p
  where p.id = p_profil_observe
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_role is null then
    raise exception 'profil observe introuvable, supprime ou inactif'
      using errcode = '23503';
  end if;

  v_secret := 'rag_' || encode(extensions.gen_random_bytes(32), 'hex');
  v_expire := now() + make_interval(hours => p_duree_heures);

  insert into public.jetons_agent (
    libelle, prefixe, empreinte, profil_observe, parcours,
    identite_masquee, expire_le, cree_par
  )
  values (
    btrim(p_libelle),
    left(v_secret, 12),
    encode(extensions.digest(convert_to(v_secret, 'UTF8'), 'sha256'), 'hex'),
    p_profil_observe,
    v_role,
    coalesce(p_identite_masquee, true),
    v_expire,
    auth.uid()
  )
  returning public.jetons_agent.id into v_id;

  perform public.log_sensitive_access(
    'agent_token_issued', 'jetons_agent', v_id::text,
    jsonb_build_object(
      'libelle', btrim(p_libelle),
      'parcours', v_role::text,
      'profil_observe', v_immuable,
      'identite_masquee', coalesce(p_identite_masquee, true),
      'expire_le', v_expire
    )
  );

  return query select v_secret, v_id, v_expire;
end;
$function$

```

### public.creer_version_programme(p_source_version_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.creer_version_programme(p_source_version_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_numero int;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'creation de version de programme reservee a l''administration';
  end if;

  if p_source_version_id is not null and not exists (
    select 1 from public.programme_versions where id = p_source_version_id
  ) then
    raise exception 'version source introuvable';
  end if;

  select coalesce(max(numero_version), 0) + 1 into v_numero from public.programme_versions;

  insert into public.programme_versions (statut, numero_version, cree_par)
  values ('brouillon', v_numero, auth.uid())
  returning id into v_id;

  if p_source_version_id is not null then
    insert into public.programme_niveaux (version_id, code_technique, nom_humain, cycle, ordre, description)
    select v_id, code_technique, nom_humain, cycle, ordre, description
    from public.programme_niveaux
    where version_id = p_source_version_id;
  end if;

  perform public.log_sensitive_access(
    'programme_version_creee', 'programme_versions', v_id::text,
    jsonb_build_object('numero_version', v_numero, 'source_version_id', p_source_version_id)
  );

  return v_id;
end;
$function$

```

### public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_d public.matching_requests;
  v_assignment uuid;
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur tranche une demande';
  end if;
  if not p_accepte and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un refus exige un motif';
  end if;

  select * into v_d from public.matching_requests
  where id = p_request_id and status = 'pending';
  if v_d.id is null then
    raise exception 'demande introuvable ou deja tranchee';
  end if;

  if p_accepte then
    if v_d.kind = 'reassignment' then
      -- L'affectation se clot, et les seances a venir tombent avec elle : une
      -- famille ne doit pas voir un cours planifie avec un enseignant qui ne la
      -- suit plus.
      update public.teacher_student_assignments
      set ended_at = now(), ended_by = auth.uid(),
          end_reason = coalesce(btrim(p_motif), btrim(v_d.reason))
      where student_id = v_d.subject_profile_id and ended_at is null
      returning id into v_assignment;

      update public.sessions s
      set status = 'canceled', updated_at = now()
      where s.deleted_at is null
        and s.status = 'planned'
        and s.started_at > now()
        and exists (
          select 1 from public.session_participants sp
          where sp.session_id = s.id and sp.profile_id = v_d.subject_profile_id
            and sp.deleted_at is null
        );
    else
      perform public.poser_regle(
        v_d.subject_profile_id, v_d.rule_key, (v_d.rule_value #>> '{}')::int,
        'demande accordee : ' || v_d.reason);
    end if;
  end if;

  update public.matching_requests
  set status = case when p_accepte then 'approved' else 'rejected' end,
      decided_by = auth.uid(), decided_at = now(),
      decision_reason = btrim(p_motif)
  where id = p_request_id;

  perform public.log_sensitive_access('demande_tranchee', 'matching_requests',
    p_request_id::text,
    jsonb_build_object('accepte', p_accepte, 'kind', v_d.kind));
end;
$function$

```

### public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_doc public.kyc_documents;
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur decide d''un dossier';
  end if;

  -- Un refus sans motif laisserait TUT-00b sans rien a dire, et la famille sans
  -- rien a corriger.
  if not p_approuve and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un refus exige un motif';
  end if;

  -- Le filtre de genre s'applique a la decision, pas seulement a l'affichage :
  -- sinon il suffirait de connaitre un identifiant pour le contourner.
  select * into v_doc from public.read_kyc_documents() k where k.id = p_document_id;
  if v_doc.id is null then
    raise exception 'dossier introuvable ou hors du perimetre de lecture';
  end if;

  update public.kyc_documents
  set status = case when p_approuve then 'approved'::public.kyc_doc_status
                    else 'rejected'::public.kyc_doc_status end,
      rejection_reason = case when p_approuve then null else btrim(p_motif) end,
      verified_by = auth.uid(),
      verified_at = now()
  where id = p_document_id;

  if p_approuve then
    update public.profiles
    set account_status = 'active', updated_at = now()
    where id = v_doc.profile_id and account_status = 'pending_kyc';
  end if;

  update public.teacher_profiles
  set kyc_status = case when p_approuve then 'approved' else 'rejected' end
  where profile_id = v_doc.profile_id;

  perform public.log_sensitive_access('kyc_decision', 'kyc_documents', p_document_id::text,
    jsonb_build_object('approuve', p_approuve, 'motif', btrim(coalesce(p_motif, ''))));
end;
$function$

```

### public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer)

```sql
CREATE OR REPLACE FUNCTION public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_par_visite integer;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  if p_source not in ('academie', 'groupe', 'desactivee') then
    raise exception 'source de politique inconnue : %', p_source using errcode = 'invalid_parameter_value';
  end if;

  -- La revision est bumpee par le declencheur existant
  -- (tc_groupes_observation_bump_revision, 0030) : rien a faire ici. Ce
  -- declencheur surveille deja observation_max_secondes_par_visite, donc un
  -- changement du seul plafond de visite fait bouger policy_version.
  update public.groupes
     set observation_source = p_source,
         observation_max_visites = p_max_visites,
         observation_max_secondes = p_max_secondes,
         -- Nul en entree = retomber sur ce que le groupe porte deja, puis sur
         -- le defaut d'Academie. Jamais nul en sortie : « illimite par visite »
         -- n'est pas un reglage. Le `least` rejoue l'invariant de
         -- plafondDeVisite et satisfait groupes_observation_plafond_visite.
         observation_max_secondes_par_visite = least(
           coalesce(
             p_max_secondes_par_visite,
             groupes.observation_max_secondes_par_visite,
             public.app_config_int('observation.max_seconds_per_visit', 120)
           ),
           p_max_secondes
         )
   where id = p_groupe_id and ended_at is null
   returning observation_max_secondes_par_visite into v_par_visite;

  if not found then
    raise exception 'groupe introuvable ou deja cloture' using errcode = 'no_data_found';
  end if;

  -- La valeur journalisee est celle REELLEMENT ecrite, pas celle demandee :
  -- avec un parametre nul, les deux different.
  perform public.log_sensitive_access(
    'observation_politique_groupe_modifiee', 'groupes', p_groupe_id::text,
    jsonb_build_object('source', p_source, 'max_visites', p_max_visites,
                       'max_secondes', p_max_secondes,
                       'max_secondes_par_visite', v_par_visite)
  );

  return public.politique_observation_effective(p_groupe_id);
end;
$function$

```

### public.demandes_en_attente()

```sql
CREATE OR REPLACE FUNCTION public.demandes_en_attente()
 RETURNS TABLE(id uuid, kind text, subject_profile_id uuid, subject_first_name text, subject_immutable_id text, rule_key text, rule_value jsonb, reason text, requester_role app_role, requested_by uuid, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() not in ('admin', 'controller') then
    raise exception 'file des demandes reservee a l''administration';
  end if;
  return query
  select m.id, m.kind, m.subject_profile_id,
         case when v_masque then null else p.first_name end,
         p.immutable_id, m.rule_key, m.rule_value, m.reason,
         m.requester_role, m.requested_by, m.created_at
  from public.matching_requests m
  join public.profiles p on p.id = m.subject_profile_id
  where m.status = 'pending'
  order by m.created_at asc;
end;
$function$

```

### public.eleves_sans_enseignant()

```sql
CREATE OR REPLACE FUNCTION public.eleves_sans_enseignant()
 RETURNS TABLE(student_id uuid, first_name text, immutable_id text, household_id uuid, level text, interface_mode interface_mode, depuis timestamp with time zone, creneaux jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;
  return query
  select e.id,
    case when v_masque then null else e.first_name end,
    e.immutable_id, e.household_id, sp.level, sp.interface_mode,
    creneau.depuis, coalesce(creneau.cases, '[]'::jsonb)
  from public.profiles e
  join public.student_profiles sp
    on sp.profile_id = e.id and sp.deleted_at is null
  left join lateral (
    select min(w.created_at) as depuis,
      jsonb_agg(jsonb_build_object(
        'weekday', w.weekday, 'hour_local', w.hour_local,
        'timezone_iana', w.timezone_iana, 'created_at', w.created_at)
        order by w.weekday, w.hour_local) as cases
    from public.weekly_availability w where w.profile_id = e.id
  ) creneau on true
  where e.role = 'student' and e.deleted_at is null
    and e.account_status in ('active', 'provisional_active')
    and not exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = e.id and a.ended_at is null)
  order by creneau.depuis asc nulls last,
    case when v_masque then e.immutable_id else e.first_name end asc;
end;
$function$

```

### public.enseignants_pour(p_student_profile_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.enseignants_pour(p_student_profile_id uuid)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, eleves_actifs integer, plafond integer, creneaux_communs jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;
  return query
  select ens.id,
    case when v_masque then null else ens.first_name end,
    case when v_masque then null else ens.last_name end,
    ens.immutable_id, tp.country, charge.actifs::int,
    public.regle_brute(ens.id, 'max_students_per_teacher'),
    coalesce(communs.cases, '[]'::jsonb)
  from public.profiles ens
  join public.teacher_profiles tp
    on tp.profile_id = ens.id and tp.deleted_at is null
  join lateral (
    select count(*) as actifs from public.teacher_student_assignments a
    where a.teacher_id = ens.id and a.ended_at is null
  ) charge on true
  left join lateral (
    select jsonb_agg(jsonb_build_object(
      'weekday', we.weekday, 'hour_local', we.hour_local,
      'timezone_iana', we.timezone_iana)
      order by we.weekday, we.hour_local) as cases
    from public.weekly_availability we
    join public.weekly_availability wt on wt.profile_id = ens.id
     and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana)
       = public.instant_creneau(we.weekday, we.hour_local, we.timezone_iana)
    where we.profile_id = p_student_profile_id
  ) communs on true
  where ens.role = 'teacher' and ens.deleted_at is null
    and ens.account_status in ('active', 'provisional_active')
  order by (coalesce(jsonb_array_length(communs.cases), 0) > 0) desc,
    charge.actifs asc,
    case when v_masque then ens.immutable_id else ens.first_name end asc;
end;
$function$

```

### public.entrer_observation(p_session_id uuid, p_role text)

```sql
CREATE OR REPLACE FUNCTION public.entrer_observation(p_session_id uuid, p_role text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance    public.sessions%rowtype;
  v_role      public.participant_role;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_enfant    uuid;
  v_pol       jsonb;
  v_budget    jsonb;
  v_visite    public.guardian_session_visit;
  v_visit_num smallint;
begin
  if p_role not in ('guardian_observer', 'admin_masked', 'admin_visible') then
    raise exception 'role d''observation inconnu : %', p_role using errcode = 'invalid_parameter_value';
  end if;
  v_role := p_role::public.participant_role;

  if not public.app_account_valid() then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';
  end if;

  -- 1. La seance existe et est dans la fenetre.
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return jsonb_build_object('autorise', false, 'motif_refus', 'seance_non_active');
  end if;
  if now() < coalesce(v_seance.join_opens_at, v_seance.started_at - make_interval(mins => v_fenetre))
     or now() > v_seance.ended_at + make_interval(mins => v_grace) then
    return jsonb_build_object('autorise', false, 'motif_refus', 'hors_fenetre');
  end if;

  -- 2. Le droit de tenir CE role.
  if v_role = 'guardian_observer' and public.app_role() <> 'guardian' then
    raise exception 'observation reservee au tuteur' using errcode = 'insufficient_privilege';
  end if;
  if v_role in ('admin_masked', 'admin_visible') and public.app_role() <> 'admin' then
    raise exception 'observation reservee a l''administration' using errcode = 'insufficient_privilege';
  end if;

  -- 3. Lien tuteur-enfant dans CE groupe -- guardian_observer seulement.
  if v_role = 'guardian_observer' then
    select m.student_id into v_enfant
      from public.groupe_membres m
     where m.groupe_id = v_seance.groupe_id
       and m.left_at is null
       and public.est_du_foyer(m.student_id)
     limit 1;
    if v_enfant is null then
      return jsonb_build_object('autorise', false, 'motif_refus', 'lien_tuteur_absent');
    end if;
  end if;

  -- 4. Politique du groupe -- guardian_observer seulement.
  v_pol := public.politique_observation_effective(v_seance.groupe_id);
  if v_role = 'guardian_observer' and not (v_pol->>'observation_activee')::boolean then
    return jsonb_build_object('autorise', false, 'motif_refus', 'policy_desactivee');
  end if;

  -- 5. Quota -- guardian_observer seulement.
  if v_role = 'guardian_observer' then
    v_budget := public.budget_observation(p_session_id);
    if not (v_budget->>'peut_entrer')::boolean then
      return jsonb_build_object(
        'autorise', false,
        'motif_refus', v_budget->>'motif_refus',
        'budget', v_budget
      );
    end if;
  end if;

  -- 6. Alors seulement : ecriture, y compris pour un role incognito.
  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), v_role)
  on conflict (session_id, profile_id) do update set role = excluded.role, deleted_at = null;

  select coalesce(max(v.visit_number), 0) + 1 into v_visit_num
    from public.guardian_session_visit v
   where v.session_id = p_session_id and v.observateur_profile_id = auth.uid();

  insert into public.guardian_session_visit (
    session_id, groupe_id, observateur_profile_id, role, enfant_profile_id,
    visit_number, policy_version
  ) values (
    p_session_id, v_seance.groupe_id, auth.uid(), v_role, v_enfant,
    v_visit_num, coalesce(v_pol->>'policy_version', '')
  )
  returning * into v_visite;

  perform public.log_sensitive_access(
    'observation_entree', 'guardian_session_visit', v_visite.id::text,
    jsonb_build_object('session_id', p_session_id, 'role', v_role, 'enfant_profile_id', v_enfant)
  );

  return jsonb_build_object(
    'autorise', true,
    'motif_refus', null,
    -- L'intervalle COMPLET. `enfant_profile_id` est la raison d'etre de ce
    -- bloc : sans lui, le panneau du tuteur ne peut reconnaitre son enfant
    -- dans la salle.
    'visite', jsonb_build_object(
      'id',                     v_visite.id,
      'session_id',             v_visite.session_id,
      'groupe_id',              v_visite.groupe_id,
      'observateur_profile_id', v_visite.observateur_profile_id,
      'role',                   v_visite.role,
      'enfant_profile_id',      v_visite.enfant_profile_id,
      'entered_at',             v_visite.entered_at,
      'left_at',                v_visite.left_at,
      'duration_seconds',       v_visite.duration_seconds,
      'visit_number',           v_visite.visit_number,
      'policy_version',         v_visite.policy_version,
      'fin_de_visite',          v_visite.fin_de_visite
    ),
    'budget', case when v_role = 'guardian_observer' then public.budget_observation(p_session_id) else null end
  );
end;
$function$

```

### public.guard_profile_privileged_columns()

```sql
CREATE OR REPLACE FUNCTION public.guard_profile_privileged_columns()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin'
     and (old.role is distinct from new.role
          or old.household_id is distinct from new.household_id
          or old.account_status is distinct from new.account_status
          or old.access_until is distinct from new.access_until)
  then
    raise exception 'seul un admin modifie r�le, foyer, statut ou acc�s';
  end if;
  return new;
end;
$function$

```

### public.indicateurs_admin()

```sql
CREATE OR REPLACE FUNCTION public.indicateurs_admin()
 RETURNS TABLE(dossiers_en_attente integer, foyers_sans_enseignant integer, rapports_manquants integer, incidents_24h integer, comptes_echus integer, demandes_en_attente integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'centre de commande reserve a l''administration';
  end if;

  return query
  select
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'),
    (select count(distinct p.household_id)::int
       from public.profiles p
      where p.role = 'student' and p.deleted_at is null
        and p.account_status in ('active', 'provisional_active')
        and not exists (
          select 1 from public.teacher_student_assignments a
          where a.student_id = p.id and a.ended_at is null)),
    (select count(*)::int from public.sessions s
      where s.status = 'ended' and s.deleted_at is null
        and not exists (
          select 1 from public.lesson_reports r
          where r.session_id = s.id and r.deleted_at is null)),
    (select count(*)::int from public.sessions s
      where s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'),
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'provisional_active'
        and p.access_until is not null and p.access_until < now()),
    (select count(*)::int from public.matching_requests m
      where m.status = 'pending');
end;
$function$

```

### public.journal_audit(p_acteur uuid, p_action text, p_depuis timestamp with time zone, p_limite integer, p_avant_date timestamp with time zone, p_avant_id bigint)

```sql
CREATE OR REPLACE FUNCTION public.journal_audit(p_acteur uuid DEFAULT NULL::uuid, p_action text DEFAULT NULL::text, p_depuis timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limite integer DEFAULT 50, p_avant_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_avant_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(entree_id bigint, survenu_le timestamp with time zone, acteur uuid, role_acteur text, nom_acteur text, type_evenement text, table_visee text, ligne_visee text, details jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;
  if p_limite < 1 or p_limite > 200 then
    raise exception 'limite hors bornes';
  end if;
  if (p_avant_date is null) <> (p_avant_id is null) then
    raise exception 'curseur incomplet';
  end if;
  return query
  select a.id, a.created_at, a.actor, a.actor_role,
    case
      when v_masque then p.immutable_id
      else coalesce(
        nullif(trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')), ''),
        p.immutable_id)
    end,
    a.action, a.table_name, a.row_id, a.payload
  from public.audit_logs a
  left join public.profiles p on p.id = a.actor
  where (p_acteur is null or a.actor = p_acteur)
    and (p_action is null or a.action = p_action)
    and (p_depuis is null or a.created_at >= p_depuis)
    and (p_avant_date is null or (a.created_at, a.id) < (p_avant_date, p_avant_id))
  order by a.created_at desc, a.id desc
  limit p_limite;
end;
$function$

```

### public.journal_audit_filtres()

```sql
CREATE OR REPLACE FUNCTION public.journal_audit_filtres()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_resultat jsonb;
  v_masque boolean := public.agent_identite_masquee();
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  select jsonb_build_object(
    'total', (select count(*) from public.audit_logs),
    'premiere', (select min(x.created_at) from public.audit_logs x),
    'actions', coalesce((
      select jsonb_agg(
        jsonb_build_object('action', t.action, 'n', t.n)
        order by t.n desc, t.action asc
      )
      from (
        select a.action, count(*) as n
        from public.audit_logs a
        group by a.action
      ) t
    ), '[]'::jsonb),
    'acteurs', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', u.actor,
          'nom', u.nom,
          'identifiant', u.identifiant,
          'role', u.role,
          'n', u.n
        )
        order by u.n desc, u.nom asc
      )
      from (
        select
          a.actor,
          count(*) as n,
          (array_agg(a.actor_role order by a.created_at desc, a.id desc))[1] as role,
          max(p.immutable_id) as identifiant,
          case
            when v_masque then coalesce(max(p.immutable_id), a.actor::text)
            else coalesce(
              nullif(trim(coalesce(max(p.first_name), '') || ' ' || coalesce(max(p.last_name), '')), ''),
              max(p.immutable_id),
              a.actor::text
            )
          end as nom
        from public.audit_logs a
        left join public.profiles p on p.id = a.actor
        where a.actor is not null
        group by a.actor
      ) u
    ), '[]'::jsonb)
  ) into v_resultat;

  return v_resultat;
end;
$function$

```

### public.maj_eleve_pedagogie(p_profile_id uuid, p_level text, p_riwaya text)

```sql
CREATE OR REPLACE FUNCTION public.maj_eleve_pedagogie(p_profile_id uuid, p_level text DEFAULT NULL::text, p_riwaya text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur modifie le niveau ou la riwaya';
  end if;

  update public.student_profiles
  set level = coalesce(p_level, level),
      riwaya = coalesce(p_riwaya, riwaya)
  where profile_id = p_profile_id and deleted_at is null;

  perform public.log_sensitive_access('maj_pedagogie', 'student_profiles',
    p_profile_id::text,
    jsonb_build_object('level', p_level, 'riwaya', p_riwaya));
end;
$function$

```

### public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint)

```sql
CREATE OR REPLACE FUNCTION public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actifs int;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle, seuil_max = p_seuil_max, weekday = p_weekday, hour_local = p_hour_local
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$

```

### public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint)

```sql
CREATE OR REPLACE FUNCTION public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text DEFAULT NULL::text, p_couleur_jeton smallint DEFAULT NULL::smallint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actifs int;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification de groupe reservee a l''administration';
  end if;

  if p_timezone_iana is not null then
    perform 1 from pg_timezone_names where name = p_timezone_iana;
    if not found then
      raise exception 'fuseau IANA inconnu : %', p_timezone_iana;
    end if;
  end if;

  select count(*) into v_actifs from public.groupe_membres
  where groupe_id = p_groupe_id and left_at is null;

  if v_actifs > p_seuil_max then
    raise exception 'ce groupe compte deja % membres actifs, seuil demande trop bas (%)', v_actifs, p_seuil_max;
  end if;

  update public.groupes
  set libelle = p_libelle,
      seuil_max = p_seuil_max,
      weekday = p_weekday,
      hour_local = p_hour_local,
      timezone_iana = coalesce(p_timezone_iana, timezone_iana),
      couleur_jeton = coalesce(p_couleur_jeton, couleur_jeton)
  where id = p_groupe_id and ended_at is null;

  if not found then
    raise exception 'groupe introuvable ou deja cloture';
  end if;

  perform public.log_sensitive_access(
    'groupe_modifie', 'groupes', p_groupe_id::text,
    jsonb_build_object('seuil_max', p_seuil_max, 'weekday', p_weekday, 'hour_local', p_hour_local)
  );
end;
$function$

```

### public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)

```sql
CREATE OR REPLACE FUNCTION public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  select pv.statut into v_statut
  from public.programme_niveaux pn
  join public.programme_versions pv on pv.id = pn.version_id
  where pn.id = p_niveau_id;

  if v_statut is null then
    raise exception 'niveau introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : creez une nouvelle version pour modifier le programme';
  end if;

  update public.programme_niveaux
  set nom_humain = p_nom_humain, cycle = p_cycle, ordre = p_ordre, description = p_description
  where id = p_niveau_id;

  perform public.log_sensitive_access(
    'niveau_programme_modifie', 'programme_niveaux', p_niveau_id::text,
    jsonb_build_object('nom_humain', p_nom_humain, 'cycle', p_cycle)
  );
end;
$function$

```

### public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
begin
  if public.app_role() <> 'admin' then
    raise exception 'seul un administrateur pose une regle';
  end if;
  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'une regle sans motif ne se relit pas six mois plus tard';
  end if;

  -- La precedente se clot, elle ne se remplace pas.
  update public.rule_overrides
  set ended_at = now(), ended_by = auth.uid(),
      end_reason = 'remplacee : ' || btrim(p_motif)
  where profile_id = p_profile_id and key = p_key and ended_at is null;

  insert into public.rule_overrides (profile_id, key, value, reason, set_by)
  values (p_profile_id, p_key, to_jsonb(p_value), btrim(p_motif), auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access('regle_posee', 'rule_overrides', v_id::text,
    jsonb_build_object('profile_id', p_profile_id, 'key', p_key, 'value', p_value));

  return v_id;
end;
$function$

```

### public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer)

```sql
CREATE OR REPLACE FUNCTION public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_tz text;
  v_instant timestamptz;
  v_assignment uuid;
begin
  if public.app_role() <> 'teacher' or not public.app_account_valid() then
    raise exception 'seul un enseignant au compte valide prend un eleve';
  end if;

  -- Le creneau demande doit etre un creneau POSE par le foyer : un enseignant ne
  -- choisit pas l'heure a la place de la famille.
  select w.timezone_iana into v_tz
  from public.weekly_availability w
  join public.profiles p on p.id = w.profile_id
  where w.profile_id = p_student_profile_id
    and w.weekday = p_weekday and w.hour_local = p_hour
    and p.role = 'student' and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_tz is null then
    raise exception 'ce creneau n''est pas propose par ce foyer';
  end if;

  v_instant := public.instant_creneau(p_weekday, p_hour, v_tz);

  -- Comparaison par instant et non par heure locale : la famille pose en heure
  -- de Paris, l'enseignant travaille en heure de Conakry.
  if not exists (
    select 1 from public.weekly_availability wt
    where wt.profile_id = auth.uid()
      and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  ) then
    raise exception 'ce creneau ne figure pas dans vos disponibilites';
  end if;

  if exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = p_student_profile_id and a.ended_at is null
  ) then
    raise exception 'cet eleve a deja un enseignant';
  end if;

  begin
    insert into public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    values (auth.uid(), p_student_profile_id, p_weekday, p_hour, v_tz)
    returning id into v_assignment;
  exception
    -- I4 : deux enseignants au meme instant. L'index unique partiel tranche, et
    -- le perdant recoit une phrase, pas un code d'erreur.
    when unique_violation then
      raise exception 'cet eleve vient d''etre pris par un autre enseignant';
  end;

  perform public.materialiser_seances(v_assignment);

  perform public.log_sensitive_access('affectation_creee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
                       'weekday', p_weekday, 'hour_local', p_hour));

  return v_assignment;
end;
$function$

```

### public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)

```sql
CREATE OR REPLACE FUNCTION public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)
 RETURNS session_shared_content
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_ligne public.session_shared_content;
begin
  if not public.session_belongs_to_teacher(p_session_id, auth.uid())
     and public.app_role() <> 'admin' then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  insert into public.session_shared_content as c (
    session_id, resource_id, resource_version_id, content_position,
    content_range, display_mode, hidden_ranges, semantic_markers,
    group_resume_position, revision, updated_by, updated_at
  ) values (
    p_session_id, p_resource_id, p_resource_version_id, p_content_position,
    p_content_range, p_display_mode, p_hidden_ranges, p_semantic_markers,
    p_group_resume_position, p_revision, auth.uid(), now()
  )
  on conflict (session_id) do update
    set resource_id           = excluded.resource_id,
        resource_version_id   = excluded.resource_version_id,
        content_position      = excluded.content_position,
        content_range         = excluded.content_range,
        display_mode          = excluded.display_mode,
        hidden_ranges         = excluded.hidden_ranges,
        semantic_markers      = excluded.semantic_markers,
        group_resume_position = excluded.group_resume_position,
        revision              = excluded.revision,
        updated_by            = excluded.updated_by,
        updated_at            = excluded.updated_at
    where c.revision < excluded.revision
  returning * into v_ligne;

  if v_ligne.session_id is null then
    select * into v_ligne from public.session_shared_content
      where session_id = p_session_id;
  end if;

  return v_ligne;
end;
$function$

```

### public.publier_version_programme(p_version_id uuid, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.publier_version_programme(p_version_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'publication du programme reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour publier une version';
  end if;

  select statut into v_statut from public.programme_versions where id = p_version_id;

  if v_statut is null then
    raise exception 'version introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'cette version est deja publiee ou archivee';
  end if;

  if not exists (select 1 from public.programme_niveaux where version_id = p_version_id) then
    raise exception 'impossible de publier une version sans aucun niveau';
  end if;

  update public.programme_versions
  set statut = 'publiee', publiee_at = now(), publiee_par = auth.uid()
  where id = p_version_id;

  perform public.log_sensitive_access(
    'programme_version_publiee', 'programme_versions', p_version_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$

```

### public.read_kyc_documents()

```sql
CREATE OR REPLACE FUNCTION public.read_kyc_documents()
 RETURNS SETOF kyc_documents
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  reader_gender public.gender;
begin
  if public.app_role() not in ('admin', 'controller') then
    raise exception 'acces KYC refuse';
  end if;

  select p.gender into reader_gender
  from public.profiles p
  where p.id = auth.uid() and p.deleted_at is null;

  -- I9 : un genre inconnu ferme, il ne filtre pas a moitie. Un repli silencieux
  -- rendait la moitie des dossiers invisible sans que personne ne le sache.
  --
  -- Ce refus precede volontairement la journalisation : une exception annule la
  -- transaction, donc journaliser d'abord ecrirait la trace d'une lecture qui
  -- n'a jamais eu lieu, puis l'effacerait. On refuse, puis on journalise ce qui
  -- va reellement sortir.
  if reader_gender is null then
    raise exception 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier';
  end if;

  -- Chaque lecture est journalisee avant que la moindre ligne ne sorte
  -- (invariant I8, scenario 12 de l'etape 1).
  perform public.log_sensitive_access('kyc_read', 'kyc_documents', null::text,
    jsonb_build_object('reader_gender', reader_gender));

  return query
    select k.* from public.kyc_documents k
    where k.deleted_at is null and k.gender = reader_gender;
end;
$function$

```

### public.rejoindre_observation(p_session_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.rejoindre_observation(p_session_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance public.sessions%rowtype;
  v_role   public.participant_role;
begin
  if public.app_role() <> 'controller' or not public.app_account_valid() then
    raise exception 'observation reservee au controle qualite'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  if now() < v_seance.started_at then
    raise exception 'seance pas encore commencee' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'seance terminee' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id and sp.profile_id = auth.uid()
     and sp.deleted_at is null;
  if found and v_role <> 'masked_controller' then
    raise exception 'observer une seance dont on est partie prenante est interdit'
      using errcode = 'check_violation';
  end if;
  if v_seance.teacher_id = auth.uid() then
    raise exception 'observer une seance dont on est partie prenante est interdit'
      using errcode = 'check_violation';
  end if;

  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), 'masked_controller')
  on conflict (session_id, profile_id) do update
    set deleted_at = null, role = 'masked_controller';

  perform public.log_sensitive_access(
    'controller_observation_started',
    'session_participants',
    p_session_id::text,
    jsonb_build_object(
      'teacher_id', v_seance.teacher_id,
      'started_at', v_seance.started_at,
      'hidden', true
    )
  );

  return p_session_id;
end;
$function$

```

### public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'retrait d''un eleve d''un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour retirer un eleve d''un groupe';
  end if;

  update public.groupe_membres
  set left_at = now(), left_by = auth.uid(), left_reason = p_motif
  where groupe_id = p_groupe_id and student_id = p_student_profile_id and left_at is null;

  if not found then
    raise exception 'cet eleve n''est pas membre actif de ce groupe';
  end if;

  perform public.log_sensitive_access(
    'eleve_retire_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$

```

### public.revoquer_appareil(p_device_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.revoquer_appareil(p_device_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_profil uuid;
begin
  if public.app_role() not in ('guardian', 'admin') then
    raise exception 'seul un tuteur ou un administrateur revoque un appareil';
  end if;

  select d.profile_id into v_profil
  from public.devices d
  join public.profiles p on p.id = d.profile_id
  where d.id = p_device_id
    and d.deleted_at is null
    and p.deleted_at is null
    and (
      public.app_role() = 'admin'
      or (p.household_id is not null and p.household_id = public.app_household_id())
    );

  if v_profil is null then
    raise exception 'cet appareil n''appartient pas a votre foyer';
  end if;

  update public.devices
  set revoked_at = now(), token_hash = null
  where id = p_device_id and revoked_at is null;

  -- Le jeton est efface en meme temps que la revocation : un appareil revoque
  -- dont le jeton survivrait resterait utilisable jusqu'a la prochaine lecture.
  perform public.log_sensitive_access('appareil_revoque', 'devices',
    p_device_id::text, jsonb_build_object('profile_id', v_profil));
end;
$function$

```

### public.revoquer_jeton_agent(p_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.revoquer_jeton_agent(p_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_libelle text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'revocation reservee a l administration'
      using errcode = '42501';
  end if;

  update public.jetons_agent
     set revoque_le = now(), revoque_par = auth.uid()
   where id = p_id and revoque_le is null
  returning libelle into v_libelle;

  if v_libelle is null then
    return false;
  end if;

  perform public.log_sensitive_access(
    'agent_token_revoked', 'jetons_agent', p_id::text,
    jsonb_build_object('libelle', v_libelle)
  );
  return true;
end;
$function$

```

### public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)

```sql
CREATE OR REPLACE FUNCTION public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_statut text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'modification du programme reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour supprimer un niveau';
  end if;

  select pv.statut into v_statut
  from public.programme_niveaux pn
  join public.programme_versions pv on pv.id = pn.version_id
  where pn.id = p_niveau_id;

  if v_statut is null then
    raise exception 'niveau introuvable';
  end if;

  if v_statut <> 'brouillon' then
    raise exception 'version publiee ou archivee : impossible de supprimer un niveau publie';
  end if;

  delete from public.programme_niveaux where id = p_niveau_id;

  perform public.log_sensitive_access(
    'niveau_programme_supprime', 'programme_niveaux', p_niveau_id::text,
    jsonb_build_object('motif', p_motif)
  );
end;
$function$

```

### public.transitions_fuseau_a_venir(p_jours integer)

```sql
CREATE OR REPLACE FUNCTION public.transitions_fuseau_a_venir(p_jours integer DEFAULT 30)
 RETURNS TABLE(groupe_id uuid, fuseau text, transition_utc timestamp with time zone, heure_avant text, heure_apres text, jours_restants integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;

  return query
    with occurrences as (
      select
        g.id as gid,
        g.timezone_iana as tz,
        i,
        public.instant_creneau(g.weekday, g.hour_local, g.timezone_iana, i) as debut
      from public.groupes g
      cross join generate_series(0, 4) as i
      where g.ended_at is null
    ),
    paires as (
      -- Le decalage UTC d'un instant dans un fuseau : la difference entre son
      -- heure murale dans ce fuseau et son heure murale en UTC. `extract
      -- (timezone from ...)` ne s'applique qu'a un `timestamptz`, jamais au
      -- `timestamp` nu que rend `AT TIME ZONE` -- cette soustraction est la
      -- forme correcte.
      select
        o1.gid, o1.tz, o1.debut as debut_semaine, o2.debut as debut_semaine_suivante,
        (o1.debut at time zone o1.tz) - (o1.debut at time zone 'UTC') as decalage_avant,
        (o2.debut at time zone o1.tz) - (o2.debut at time zone 'UTC') as decalage_apres
      from occurrences o1
      join occurrences o2 on o2.gid = o1.gid and o2.i = o1.i + 1
    )
    select
      p.gid,
      p.tz,
      p.debut_semaine_suivante,
      to_char(p.debut_semaine at time zone p.tz, 'HH24:MI'),
      to_char(p.debut_semaine_suivante at time zone p.tz, 'HH24:MI'),
      extract(day from p.debut_semaine_suivante - now())::int
    from paires p
    where p.decalage_avant is distinct from p.decalage_apres
      and p.debut_semaine_suivante <= now() + make_interval(days => p_jours)
      and p.debut_semaine_suivante >= now();
end;
$function$

```

### public.verifier_chaine_audit(p_limite integer)

```sql
CREATE OR REPLACE FUNCTION public.verifier_chaine_audit(p_limite integer DEFAULT 200)
 RETURNS TABLE(verifiees integer, rompues integer, premiere_rompue bigint, rompue_le timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin' then
    raise exception 'journal d''audit reserve a l''administration';
  end if;

  if p_limite < 1 or p_limite > 5000 then
    raise exception 'limite hors bornes';
  end if;

  return query
  with fenetre as (
    select a.id, a.created_at, a.actor, a.actor_role, a.action, a.table_name,
           a.row_id, a.payload, a.prev_hash, a.hash
    from public.audit_logs a
    order by a.created_at desc, a.id desc
    limit p_limite + 1
  ),
  chainee as (
    select f.*,
           lag(f.hash) over (order by f.created_at, f.id) as hash_precedent,
           row_number() over (order by f.created_at desc, f.id desc) as rang
    from fenetre f
  ),
  controle as (
    select
      c.id,
      c.created_at,
      c.hash = encode(extensions.digest(convert_to(
        c.prev_hash || encode(extensions.digest(convert_to(
          coalesce(c.actor::text, '') || coalesce(c.actor_role, '') || c.action ||
          c.table_name || coalesce(c.row_id, '') || c.payload::text, 'UTF8'),
        'sha256'), 'hex'), 'UTF8'), 'sha256'), 'hex')
      and (c.hash_precedent is null or c.prev_hash = c.hash_precedent) as intacte
    from chainee c
    where c.rang <= p_limite
  )
  select
    count(*)::int,
    count(*) filter (where not k.intacte)::int,
    min(k.id) filter (where not k.intacte),
    min(k.created_at) filter (where not k.intacte)
  from controle k;
end;
$function$

```

### public.video_config_lire()

```sql
CREATE OR REPLACE FUNCTION public.video_config_lire()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_config public.video_config%rowtype;
begin
  if public.app_role() <> 'admin' then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;
  select * into v_config from public.video_config where id;
  return jsonb_build_object(
    'active_provider', v_config.active_provider,
    'canary_provider', v_config.canary_provider,
    'canary_percentage', v_config.canary_percentage,
    'ws_url_override', v_config.ws_url_override,
    'token_ttl_seconds', v_config.token_ttl_seconds,
    'updated_at', v_config.updated_at
  );
end;
$function$

```

### public.autoriser_lecture_piece_identite(p_document_id uuid)

```sql
CREATE OR REPLACE FUNCTION public.autoriser_lecture_piece_identite(p_document_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_piece public.kyc_documents;
begin
  -- Exigence POSITIVE : `app_role()` rend NULL pour un appelant anonyme, et un
  -- refus ecrit `<> 'admin'` ne se declencherait pas sur NULL (`0029`).
  if not coalesce(public.app_role() in ('admin', 'controller'), false) then
    raise exception 'lecture des pieces d''identite reservee a l''administration'
      using errcode = '42501';
  end if;

  -- Un compte suspendu ou expire garde son role dans son jeton jusqu'a
  -- expiration de celui-ci.
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte non valide' using errcode = '42501';
  end if;

  if p_document_id is null then
    raise exception 'document non precise' using errcode = '22023';
  end if;

  select k.* into v_piece
  from public.read_kyc_documents() k
  where k.id = p_document_id;

  if not found then
    -- Volontairement indistinct de << ce document n'existe pas >> : la
    -- difference renseignerait sur le contenu du coffre.
    raise exception 'piece introuvable ou hors de votre perimetre'
      using errcode = '42501';
  end if;

  if v_piece.deleted_at is not null then
    raise exception 'piece supprimee' using errcode = '42501';
  end if;

  -- `doc_type` n'entre PAS dans la trace : `audit_logs` est lisible par toute
  -- l'administration, genres confondus, alors que la piece ne l'est pas.
  perform public.log_sensitive_access(
    'kyc_document_open',
    'kyc_documents',
    v_piece.id::text,
    jsonb_build_object(
      'profile_id', v_piece.profile_id,
      'storage_backend', v_piece.storage_backend,
      'status', v_piece.status
    )
  );

  -- `object_key` sort d'ici vers la couche de signature, jamais vers le client.
  return jsonb_build_object(
    'document_id', v_piece.id,
    'profile_id', v_piece.profile_id,
    'object_key', v_piece.object_key,
    'storage_backend', v_piece.storage_backend,
    'doc_type', v_piece.doc_type
  );
end;
$function$

```

### public.guard_profile_privileged_columns()

```sql
CREATE OR REPLACE FUNCTION public.guard_profile_privileged_columns()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.app_role() <> 'admin'
     and (old.role is distinct from new.role
          or old.household_id is distinct from new.household_id
          or old.account_status is distinct from new.account_status
          or old.access_until is distinct from new.access_until)
  then
    raise exception 'seul un admin modifie r�le, foyer, statut ou acc�s';
  end if;
  return new;
end;
$function$

```

## Limites et conditions de changement

Cet instantané ne prouve ni l'exploitation via Auth/PostgREST ni la réussite d'une correction. Il ne remplace pas le rejeu 0001–0042, les tests négatifs/positifs par rôle, la validation STAGING, les advisors avant/après et la revue Claude. Le script de remédiation doit être un artefact distinct, revu contre cet instantané et l'état du projet. Aucun changement PROD n'a été fait pendant cette collecte.
