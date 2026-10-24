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
    -- FAC-E-01 (18/10) : la direction accorde et retire les bourses, note les parrainages.
    'accorder_bourse(uuid,text)',
    'accorder_capacite_controle(uuid,timestamp with time zone,timestamp with time zone,boolean,uuid[],uuid[],uuid)',
    'admin_library_review_rights(uuid,uuid,jsonb,integer)',
    'affecter_enseignant_classe_c11bis(uuid,uuid)',
    -- CAND-L2A2 (22/10) : admission en Salle de verification (transition 10), direction active de son cote (moteur, controles nommes).
    'admettre_salle_verification(uuid,integer,text)',
    'agent_pre_request()',
    'ajouter_eleve_groupe(uuid,uuid,text)',
    'ajouter_niveau_programme(uuid,text,text,text,integer,text)',
    'annuler_evaluation(uuid,text)',
    'annuler_invitation_conjoint()',
    -- CPT-SUPPR-EXPORT (18/10) : la personne annule sa demande de suppression (compte valide).
    'annuler_suppression_compte()',
    'annuler_upload_bibliotheque(uuid)',
    -- CAND-L3 (23/10) : apercu d'import des formulaires, super-admin en double verification (aal2) exigee en base, aucune ecriture sauf le journal d'acces.
    'apercu_import_formulaires(text,text,text,jsonb,text)',
    -- CAND-L2A2 (22/10) : apercu d'une action groupee, direction active de son cote (trace des candidatures hors portee).
    'apercu_lot_candidats(text,uuid[])',
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
    -- CAND-L3 (23/10) : confirmation de l'import des formulaires (super-admin, aal2, cle d'idempotence, jeton HMAC).
    'confirmer_import_formulaires(text,text,text,text,jsonb,text,jsonb,text)',
    'confirmer_import_inscriptions(text,text,jsonb)',
    -- CAND-NOM-LATIN (23/10) : le titulaire d'une candidature confirme son nom en lettres latines (garde positive sur la candidature du compte valide ; aucune garde de role ; jamais la direction).
    'confirmer_nom_latin(text)',
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
    -- PED-APRES-BACK (18/10) : la direction regle le partage pedagogique d'une classe et d'un eleve.
    'definir_partage_classe(uuid,boolean,text,text)',
    -- CAND-L2A2 (22/10) : confirmation et retrait consignes par la direction (transitions 24 et 17), direction active de son cote (moteur).
    'confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)',
    -- CAND-L3 (23/10) : personne prevenue par le lien d'inscription (transition 26), direction active de son cote (moteur).
    'consigner_prevenu_candidat(uuid,text,text,date,integer,text)',
    'consigner_retrait_candidat(uuid,text,date,text,integer,text)',
    'definir_politique_observation_groupe(uuid,text,smallint,integer,integer)',
    -- CAND-L2A2 (22/10) : responsable d'une candidature (transition 28), direction active de son cote (moteur).
    'definir_responsable_candidat(uuid,uuid,integer,text)',
    'definir_regle_partage_eleve(uuid,uuid,text,text,text)',
    -- CAND-L2A2 (22/10) : complement demande (transitions 7 et 23), direction active de son cote (moteur, liste fermee).
    'demander_complement_candidat(uuid,text[],text,integer,text)',
    'demander_creneau_personnalise(uuid,text,smallint[],smallint)',
    'demander_presentation_standard()',
    'demander(text,uuid,text,text,integer)',
    -- CPT-SUPPR-EXPORT (18/10) : la personne demande la suppression de son compte (compte valide).
    'demander_suppression_compte(text)',
    'demander_upload_bibliotheque(uuid,text,text,text,bigint,text)',
    'demandes_en_attente()',
    'demarrer_mission_controle(uuid)',
    'deposer_reprise_foyer(uuid)',
    'deposer_student_concern(text,uuid,uuid,text,text,text)',
    'designer_remplacant_admin(uuid,uuid,uuid)',
    'dossiers_en_attente()',
    'effacer_etat_partage(uuid)',
    'eleves_sans_enseignant()',
    -- FAC-B-01, FAC-C-01 (17/10) : direction ou comptabilite, compte valide.
    'emettre_factures_mois(date)',
    'enregistrer_paiement(uuid,bigint,text,text,uuid)',
    'enregistrer_parrainage(uuid,uuid)',
    'enregistrer_profil_apprentissage(uuid,text,text,text,text,text)',
    'enregistrer_regles_tirage(jsonb,uuid)',
    'enregistrer_resultat_evaluation(uuid,text,text)',
    'enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)',
    -- CAND-L6 (21/10) : referentiel de paiement, direction ou comptabilite, compte valide.
    'enregistrer_ligne_referentiel_paiement(uuid,text,text,text,text,text,text,text,date,text,integer,text)',
    -- CAND-AUTRES (22/10) : les autres competences du candidat, titulaire d'une candidature enseignant au compte valide (apres l'envoi de la Salle d'examen, version attendue, cle d'idempotence ; aucune garde de role).
    'enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)',
    -- CAND-AUTRES (22/10) : le catalogue des competences, ecriture reservee a la direction active (ajout ou modification par version attendue, cle d'idempotence, jamais de suppression ; journal en ajout seul).
    'enregistrer_competence_catalogue(text,text,integer,text,text,boolean,integer,text)',
    -- CAND-L2A1 (22/10) : brouillon de la Salle d'examen, titulaire de la candidature (moteur, version du brouillon, cle).
    'enregistrer_reponses_salle_examen(text,jsonb,integer,text)',
    -- CAND-L2A1 (22/10) : envoi du questionnaire (transition 6), titulaire de la candidature (moteur, version des conditions).
    'envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)',
    'enseignants_pour_classe(uuid)',
    'enseignants_pour(uuid)',
    'entrer_observation(uuid,text)',
    -- FAC-D-01 (18/10) : la direction decide les demandes de la comptabilite.
    -- FAC-F-01 (18/10) : la direction (AAL2) lance a la main les relances et la suspension pour paiement.
    -- CAND-L2A2 (22/10) : execution d'une action groupee, direction active de son cote (jeton, nombre, moteur ligne par ligne).
    'executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)',
    'fac_traiter_relances_du_jour()',
    'finance_validation_decider(uuid,text,text,uuid)',
    'fusionner_classes(uuid,uuid,text)',
    -- CAND-L3 (23/10) : reponse importee gardee pour suivi (transition 2), direction active de son cote.
    'garder_formulaire_pour_suivi(uuid)',
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
    -- CAND-L1 (21/10) : candidatures, lectures journalisees par la direction.
    'historique_candidature(uuid,bigint,integer)',
    'lire_candidature(uuid)',
    'lire_contact_candidature(uuid)',
    -- CAND-L6 (21/10) : referentiel de paiement, lecture qui journalise l'exception super-admin.
    'lire_referentiel_paiement(text)',
    -- CAND-L3 (23/10) : listes de la direction (personnes a prevenir, reponses importees), lecture bornee a son cote et journalisee.
    'lister_a_prevenir_candidats(boolean,integer)',
    'lister_formulaires_importes(jsonb,integer)',
    'lister_candidatures(jsonb,text,integer)',
    'lister_rapprochements_candidats(integer)',
    'indicateurs_admin()',
    -- CAND-L3 (23/10) : inscription publique ou sur invitation (compte, accord, plafond horaire ; la candidature suit la confirmation du courriel).
    'inscrire_candidat(text,text,text,gender,text,text,text)',
    'inscrire_comptable_invite(text,text,text,gender)',
    'inscrire_titulaire(text,text,text,gender,text,boolean)',
    'inscrire_enseignant_invite(text,text,text,gender)',
    -- CAND-L2A2 (22/10) : infirmation d'un moyen de paiement declare (transition 25), direction active de son cote (moteur, motif).
    'infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)',
    'inviter_conjoint(text,uuid)',
    'inviter_comptable(text)',
    'inviter_enseignant(text)',
    -- CAND-L2A1 (22/10) : journal borne par genre (C15) ; ecrit la trace de l'exception super-admin.
    'journal_audit_filtres()',
    'journal_audit(uuid,text,timestamp with time zone,integer,timestamp with time zone,bigint)',
    -- CAND-L2A2 (22/10) : levee de la pause (transition 18), direction active de son cote (moteur).
    'lever_pause_candidat(uuid,integer,text,text)',
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
    -- CPT-SUPPR-EXPORT (18/10) : la copie des donnees de la personne (journalisee).
    'mes_donnees_export()',
    -- CAND-L2A2 (22/10) : pose de la pause (transition 18), direction active de son cote (moteur, motif et modele).
    'mettre_en_pause_candidat(uuid,text,text,date,integer,text)',
    'modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)',
    'modifier_niveau_programme(uuid,text,text,integer,text)',
    'mon_invitation_en_cours()',
    'pause_reglage_ecrire(uuid,boolean,integer,integer,text,text)',
    'pause_seance_demarrer(uuid,text)',
    'pause_seance_terminer(uuid,text)',
    'planifier_evaluation(uuid,uuid,text,date)',
    'poser_exception_progression(uuid,text,text)',
    'poser_regle(uuid,text,integer,text)',
    'prendre_remplacement(uuid,uuid)',
    'preparer_depot_piece_identite(uuid,text)',
    'presenter_support(uuid,uuid,integer,text,jsonb)',
    'previsualiser_import_inscriptions(text,text)',
    'progression_promouvoir(uuid,uuid,text)',
    'publier_etat_partage(uuid,uuid,uuid,jsonb,jsonb,text,jsonb,jsonb,jsonb,integer)',
    'publier_evaluation(uuid,text,text)',
    'publier_offre_horaire(uuid)',
    -- FAC-A-01 (17/10) : direction, compte valide, double verification.
    'publier_politique_commerciale(jsonb)',
    'publier_resume_seance(uuid,uuid,text,text)',
    'publier_version_programme(uuid,text)',
    'quitter_salle(uuid)',
    'read_kyc_documents()',
    'rech_d1_curseur_creer(text,text,text,uuid,bigint)',
    'rech_d1_curseur_lire(uuid,text,text,bigint)',
    'rech_d1_rechercher_classes(text,uuid,integer)',
    'rech_d1_rechercher_supports(text,uuid,integer)',
    -- FI-BR-06 (18/10) : titulaire du foyer, compte valide (bf1_est_titulaire).
    'recharge_payer(uuid,uuid)',
    'recharge_verifier_montants(jsonb)',
    -- CAND-L3 (23/10) : reponse importee rattachee a une candidature par la direction (transition 27), direction active de son cote (moteur).
    'rattacher_formulaire_candidat(uuid,uuid,integer,text)',
    'rechercher_personne_par_matricule(text)',
    'reclamer_preinscription_apres_preuve()',
    -- CAND-L2A2 (22/10) : refus d'une candidature (transition 16), direction active de son cote (moteur, motif et modele).
    'refuser_candidat(uuid,text,text,integer,text)',
    'refuser_demande_horaire(uuid,text)',
    'refuser_demande_presentation(uuid)',
    'refuser_reprise_foyer(uuid)',
    'rejoindre_observation(uuid)',
    'renoncer_intention_horaire(uuid,text)',
    'repondre_invitation_conjoint(text,uuid)',
    'reprendre_alimentation_tresorerie()',
    -- CAND-L2A1 (22/10) : retrait par le candidat (transition 17), titulaire de la candidature (moteur).
    'retrait_candidat(integer,text)',
    -- CAND-L2A2 (22/10) : reouverture d'une candidature refusee ou retiree (transition 19), direction active de son cote (moteur, controles nommes).
    'rouvrir_candidat(uuid,text,integer,text)',
    -- CAND-AUTRES (22/10) : retrait des reponses et de l'accord, meme titulaire (a toute issue de la candidature ; version attendue, cle d'idempotence).
    'retirer_autres_competences(integer,text)',
    'retirer_bourse(uuid,text)',
    'retirer_capacite_controle(uuid,text,uuid)',
    'retirer_creneau_personnalise(uuid)',
    'retirer_demande_horaire(uuid,text)',
    'retirer_eleve_groupe(uuid,uuid,text)',
    'retirer_offre_horaire(uuid,text)',
    'revoquer_appareil(uuid)',
    'revoquer_invitation_comptable(text)',
    'revoquer_invitation_enseignant(text)',
    'revoquer_jeton_agent(uuid)',
    'revoquer_resume_seance(uuid,uuid,text,text)',
    -- SES-CLOTURE-AUTO (18/10) : la direction (aal2) declenche la cloture des seances echues.
    'ses_cloturer_seances_echues_maintenant()',
    'signaler_horaire_insatisfait(uuid,jsonb)',
    'signer_contrat(text,text)',
    'sortir_observation(uuid)',
    'soumettre_feedback(uuid,text,text)',
    'supprimer_niveau_programme(uuid,text)',
    'tc_annuler_derniere_annotation(uuid)',
    'tc_groupes_observation_bump_revision()',
    'tc_poser_annotation_marqueur(uuid,uuid,jsonb,text,text)',
    'traiter_anomalie_qualite(text,uuid,text)',
    -- CPT-SUPPR-EXPORT (18/10) : la direction anonymise un compte (double verification).
    'traiter_demande_suppression(uuid)',
    'transferer_eleve(uuid,uuid,uuid,text)',
    'transmettre_student_concern(uuid,text)',
    'verifier_chaine_audit(integer)',
    -- COURRIELS-1 et 2 (23/10) : la direction ecrit, relance et regle les
    -- adresses d'envoi (garde is_admin_user en tete) ; chacun regle la langue
    -- de ses propres e-mails (auth.uid()).
    'admin_courriel_categorie_regler(text,text,text,text,boolean)',
    'admin_courriel_envoyer(uuid,text,text,text,text,uuid)',
    'admin_courriel_reessayer(uuid)',
    'ma_langue_communication_regler(text)',
    -- COURRIELS-1 : la desinscription par le lien d'un e-mail, sans compte
    -- (jeton a usage unique, seule son empreinte sha256 est gardee).
    'courriel_desinscrire(text)',
    -- AVIS-PUBLICS (19/10) : liens de collecte et moderation par la direction
    -- (garde positive app_role() = 'admin' et compte valide) ; depot par le
    -- formulaire, avec ou sans compte (jeton de lien verifie dans la fonction).
    'avis_lien_creer(text,integer,integer)',
    'avis_lien_fermer(uuid)',
    'avis_moderer(uuid,text,text)',
    'avis_deposer(text,text,text,text,date,integer,text,text,boolean)'
  ];
  -- Ouvertes a anon par choix : la desinscription d'un e-mail et le depot d'un
  -- avis se font sans compte.
  v_anon_ok text[] := array['agent_pre_request()', 'courriel_desinscrire(text)',
    'avis_deposer(text,text,text,text,date,integer,text,text,boolean)'];
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
