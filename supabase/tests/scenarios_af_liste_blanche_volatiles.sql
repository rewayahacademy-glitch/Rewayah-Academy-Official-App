-- Liste blanche des fonctions volatiles de `public` executables par un compte
-- connecte. Audit final 16/10/2026, lot L1-09. Toute fonction qui apparait ici
-- a ete relue : garde positive sur le role ET app_account_valid(), ou fonction
-- d'ecriture volontairement ouverte. Ajouter une ligne = une relecture.
-- La presence dans la liste ne prouve pas la garde (cas geler_archive_seance, corrige
-- par L1-08-reprise) : la requete de controle est
--   select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
--    where n.nspname = 'public' and p.provolatile = 'v' and p.prosecdef
--      and has_function_privilege('authenticated', p.oid, 'execute')
--      and p.prosrc like '%app_role()%' and p.prosrc not like '%app_account_valid%';
-- et elle rend zero ligne.
--
-- Ce scenario ne vaut que sous le stub de `stub_auth.sql` qui pose les
-- privileges par defaut de Supabase : sur l'ancien stub, `authenticated` n'avait
-- aucun EXECUTE explicite et le scenario echouait pour la mauvaise raison (anon,
-- authenticated vides) ou ne mesurait rien.
--
-- Comparaison avec STAGING (MESURES-2026-10-16.md section 3) : NON VERIFIABLE
-- CONTRE STAGING fonction par fonction (aucun acces a STAGING cette nuit). Les
-- totaux concordent : 552 fonctions dans `public`, 313 SECURITY DEFINER, 165
-- DEFINER volatiles executables par `authenticated`, comme sur STAGING. Le
-- rejeu local en liste 169 au total : les 4 de plus sont des fonctions
-- SECURITY INVOKER (guard_profile_privileged_columns, guard_jeton_agent_immuable,
-- tc_groupes_observation_bump_revision, signer_contrat), que la section 3 ne
-- compte pas.
--
-- Les trois lignes marquees `A RETIRER PAR L1-01` sont les fonctions que le
-- lot L1-01 ferme (P0-1). Ce scenario echoue tant qu'une fonction hors liste
-- est ouverte ; une fois L1-01 appliquee, retirer ces trois lignes, et il doit
-- toujours passer.
--
-- Cote anon : une seule exception documentee, `agent_pre_request()`, ouverte a
-- anon, authenticated, service_role et agent_ro par 0014 (section 7) car
-- PostgREST l'appelle avant chaque requete, sous n'importe quel role ; elle ne
-- prend aucun parametre et ne lit que le jeton de l'appelant.
begin;
set local search_path = public, pg_catalog;
do $$
declare
  v_liste text[] := array[
    'abandonner_reprise_tresorerie(bigint,text)',
    'accepter_demande_presentation(uuid)',
    'accorder_capacite_controle(uuid,timestamp with time zone,timestamp with time zone,boolean,uuid[],uuid[],uuid)',
    'admin_library_review_rights(uuid,uuid,jsonb,integer)',
    'affecter_enseignant_classe_c11bis(uuid,uuid)',
    'agent_pre_request()',
    'ajouter_eleve_groupe(uuid,uuid,text)',
    'ajouter_niveau_programme(uuid,text,text,text,integer,text)',
    'annuler_evaluation(uuid,text)',
    'annuler_invitation_conjoint()',
    'annuler_upload_bibliotheque(uuid)',
    'attribuer_eleve(uuid,uuid,integer,integer,text)',
    'autoriser_ecoute_archive(uuid)',
    'autoriser_lecture_piece_identite(uuid)',
    'autoriser_lecture_version(uuid)',
    'changer_affichage_evaluation(uuid,text)',
    'choisir_offre_horaire(uuid,uuid,text)',
    'clore_exception_progression(uuid,text)',
    'clore_regle(uuid,text)',
    'cloturer_groupe(uuid,text)',
    'com_annonce_marquer_lue(uuid)',
    'com_annonce_publier(text,text,text,timestamp with time zone,uuid)',
    'com_envoyer_message(uuid,text,uuid)',
    'com_fil_pour_objet(text,uuid)',
    'com_marquer_lu(uuid)',
    'com_ouvrir_conversation(text,uuid,text)',
    'completer_kyc_document()',
    'completer_niveau_demande_horaire(uuid)',
    'configurer_canal_support(text,text)',
    'confirmer_import_inscriptions(text,text,jsonb)',
    'confirmer_upload_bibliotheque(uuid,text,bigint,text,text)',
    'controleur_ajouter_complement(uuid,text,text)',
    'controleur_envoyer_message(uuid,uuid,text)',
    'controleur_fil_de_mission(uuid)',
    'controleur_lister_fils()',
    'controleur_lister_rapports()',
    'creer_classe_depuis_regroupement(uuid,uuid,text)',
    'creer_code_appairage(uuid)',
    'creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)',
    'creer_jeton_agent(text,uuid,integer,boolean)',
    'creer_offre_horaire(text,text,text,smallint[],smallint,smallint)',
    'creer_profil_eleve_titulaire()',
    'creer_profil_enfant(uuid,uuid,text,text,integer,text)',
    'creer_profil_enfant(uuid,uuid,text,text,integer,text,text)',
    'creer_profil_inscription(text,text,text,gender,text,boolean)',
    'creer_version_programme(uuid)',
    'decider_demande(uuid,boolean,text)',
    'decider_dossier(uuid,boolean,text)',
    'decider_placement(uuid,uuid,text)',
    'decider_reprise_foyer(uuid,boolean,uuid)',
    'decider_tresorerie_duree(bigint,timestamp with time zone,timestamp with time zone)',
    'decider_tresorerie_montant(bigint,bigint,text)',
    'declarer_absence_seance(uuid,uuid)',
    'declarer_conflit_mission(uuid,uuid)',
    'definir_politique_observation_groupe(uuid,text,smallint,integer,integer)',
    'demander_creneau_personnalise(uuid,text,smallint[],smallint)',
    'demander_presentation_standard()',
    'demander(text,uuid,text,text,integer)',
    'demander_upload_bibliotheque(uuid,text,text,text,bigint,text)',
    'demandes_en_attente()',
    'demarrer_mission_controle(uuid)',
    'deposer_reprise_foyer(uuid)',
    'deposer_student_concern(text,uuid,uuid,text,text,text)',
    'designer_remplacant_admin(uuid,uuid,uuid)',
    'dossiers_en_attente()',
    'effacer_etat_partage(uuid)',
    'eleves_sans_enseignant()',
    'enregistrer_profil_apprentissage(uuid,text,text,text,text,text)',
    'enregistrer_regles_tirage(jsonb,uuid)',
    'enregistrer_resultat_evaluation(uuid,text,text)',
    'enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)',
    'enseignants_pour_classe(uuid)',
    'enseignants_pour(uuid)',
    'entrer_observation(uuid,text)',
    'fusionner_classes(uuid,uuid,text)',
    'geler_archive_seance(uuid,text,boolean)',
    'guard_app_config_history()',
    'guard_assignment_cap()',
    'guard_audit_logs_immutable()',
    'guard_contract_acceptances_immutable()',
    'guard_devices_max()',
    'guard_devices_max_reactivation()',
    'guard_jeton_agent_immuable()',
    'guard_prayer_adjustments()',
    'guard_profile_immutable_id()',
    'guard_profile_privileged_columns()',
    'guard_rule_override_coherente()',
    'guard_rule_override_immutable()',
    'guard_session_state_transition()',
    'indicateurs_admin()',
    'inscrire_enseignant_invite(text,text,text,gender)',
    'inviter_conjoint(text,uuid)',
    'inviter_enseignant(text)',
    'journal_audit_filtres()',
    'journal_audit(uuid,text,timestamp with time zone,integer,timestamp with time zone,bigint)',
    'library_attribuer(uuid,uuid[],boolean,integer)',
    'library_creer_brouillon(jsonb)',
    'library_get_detail(uuid)',
    'library_mettre_a_jour(uuid,jsonb,integer)',
    'library_nouvelle_version(uuid)',
    'library_publier_version(uuid,uuid,integer,text)',
    'library_retirer(uuid,text,integer)',
    'lire_cahier_admin(uuid,uuid)',
    'lire_upload_bibliotheque(uuid)',
    'ma_capacite_controle_active()',
    'maj_eleve_pedagogie(uuid,text,text)',
    'maj_profil_enseignant(text,text[],text)',
    'modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)',
    'modifier_niveau_programme(uuid,text,text,integer,text)',
    'mon_invitation_en_cours()',
    'pause_reglage_ecrire(uuid,boolean,integer,integer,text,text)',
    'pause_seance_demarrer(uuid,text)',
    'pause_seance_terminer(uuid,text)',
    'planifier_evaluation(uuid,uuid,text,date)',
    'poser_exception_progression(uuid,text,text)',
    'poser_regle(uuid,text,integer,text)',
    'prendre_eleve(uuid,integer,integer)',
    'prendre_remplacement(uuid,uuid)',
    'preparer_depot_piece_identite(uuid,text)',
    'presenter_support(uuid,uuid,integer,text,jsonb)',
    'previsualiser_import_inscriptions(text,text)',
    'progression_promouvoir(uuid,uuid,text)',
    'publier_etat_partage(uuid,uuid,uuid,jsonb,jsonb,text,jsonb,jsonb,jsonb,integer)',
    'publier_evaluation(uuid,text,text)',
    'publier_offre_horaire(uuid)',
    'publier_resume_seance(uuid,uuid,text,text)',
    'publier_version_programme(uuid,text)',
    'quitter_salle(uuid)',
    'read_kyc_documents()',
    'rech_d1_curseur_creer(text,text,text,uuid,bigint)',
    'rech_d1_curseur_lire(uuid,text,text,bigint)',
    'rech_d1_rechercher_classes(text,uuid,integer)',
    'rech_d1_rechercher_supports(text,uuid,integer)',
    'rechercher_personne_par_matricule(text)',
    'reclamer_preinscription_apres_preuve()',
    'refuser_demande_horaire(uuid,text)',
    'refuser_demande_presentation(uuid)',
    'refuser_reprise_foyer(uuid)',
    'rejoindre_observation(uuid)',
    'renoncer_intention_horaire(uuid,text)',
    'repondre_invitation_conjoint(text,uuid)',
    'reprendre_alimentation_tresorerie()',
    'retirer_capacite_controle(uuid,text,uuid)',
    'retirer_creneau_personnalise(uuid)',
    'retirer_demande_horaire(uuid,text)',
    'retirer_eleve_groupe(uuid,uuid,text)',
    'retirer_offre_horaire(uuid,text)',
    'revoquer_appareil(uuid)',
    'revoquer_invitation_enseignant(text)',
    'revoquer_jeton_agent(uuid)',
    'revoquer_resume_seance(uuid,uuid,text,text)',
    'signaler_horaire_insatisfait(uuid,jsonb)',
    'signer_contrat(text,text)',
    'sortir_observation(uuid)',
    'soumettre_feedback(uuid,text,text)',
    'supprimer_niveau_programme(uuid,text)',
    'tc_annuler_derniere_annotation(uuid)',
    'tc_groupes_observation_bump_revision()',
    'tc_poser_annotation_marqueur(uuid,uuid,jsonb,text,text)',
    'traiter_anomalie_qualite(text,uuid,text)',
    'transferer_eleve(uuid,uuid,uuid,text)',
    'transmettre_student_concern(uuid,text)',
    'verifier_chaine_audit(integer)'
  ];
  v_anon_ok text[] := array['agent_pre_request()'];
  v_hors_liste text;
  v_anon text;
begin
  select string_agg(p.oid::regprocedure::text, ', ' order by p.oid::regprocedure::text)
    into v_hors_liste
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prokind = 'f' and p.provolatile = 'v'
     and has_function_privilege('authenticated', p.oid, 'execute')
     and not (p.oid::regprocedure::text = any (v_liste));
  if v_hors_liste is not null then
    raise exception 'AF-LB: fonctions volatiles executables par authenticated hors liste blanche : %', v_hors_liste;
  end if;

  select string_agg(p.oid::regprocedure::text, ', ' order by p.oid::regprocedure::text)
    into v_anon
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prokind = 'f' and p.provolatile = 'v'
     and has_function_privilege('anon', p.oid, 'execute')
     and not (p.oid::regprocedure::text = any (v_anon_ok))
     and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e');
  if v_anon is not null then
    raise exception 'AF-LB: fonctions volatiles executables par anon : %', v_anon;
  end if;
end $$;
rollback;
