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
    -- Lot (A) tarifs particuliers (02/11) : acces offert ou prix special saisi par la direction ; garde private.fac_direction() (admin, compte valide).
    'accorder_tarif_particulier(uuid,text,integer,bigint,date,text)',
    'admin_library_review_rights(uuid,uuid,jsonb,integer)',
    'affecter_enseignant_classe_c11bis(uuid,uuid)',
    -- Salle 3 (03/11) : l'affectation d'une candidate, lecture de la direction de son cote, journalisee hors portee ; garde positive admin et app_account_valid().
    'affectation_candidat(uuid)',
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
    -- BIBLIOTHEQUE-UNE (20261123921000, 12/11/2026) : la vignette d'un document, deposee en deux temps comme son fichier ; direction active de son cote (garde positive admin et app_account_valid), intention propre a l'appelant, confirmation signee relue par la base ; seule ecriture : library_resource.vignette_cle.
    'annuler_vignette_bibliotheque(uuid)',
    'confirmer_vignette_bibliotheque(uuid,text,bigint,text,text)',
    'demander_vignette_bibliotheque(uuid,text,bigint,text)',
    'lire_vignette_bibliotheque(uuid)',
    -- CAND-L3 (23/10) : apercu d'import des formulaires, super-admin en double verification (aal2) exigee en base, aucune ecriture sauf le journal d'acces.
    'apercu_import_formulaires(text,text,text,jsonb,text)',
    -- INVITATIONS-PERSONNELLES (20261120000000, 07/11) : apercu des candidats importes a inviter, direction active super-admin en aal2 (garde role ET app_account_valid, puis private.inv_cand_garde), comptes seulement, audit.
    'apercu_invitations_candidats_importes()',
    -- CAND-PREVENIR (24/10, porte par CANDIDATS-FLUX 06/11) : apercu des personnes a prevenir par e-mail (direction active de son cote, compteurs seulement, audit).
    'apercu_prevenir_par_courriel()',
    -- CAND-L2A2 (22/10) : apercu d'une action groupee, direction active de son cote (trace des candidatures hors portee).
    'apercu_lot_candidats(text,uuid[])',
    'autoriser_ecoute_archive(uuid)',
    'autoriser_lecture_piece_identite(uuid)',
    'autoriser_lecture_version(uuid)',
    -- REVENUS-VERITE point 5 (20261110210000, 06/11/2026) : la direction annule un autre revenu (annule_le, jamais d'effacement) ; garde admin et compte valide ; journalisé ; relue deux fois.
    'autre_revenu_annuler(uuid)',
    -- REVENUS-VERITE point 5 (20261110210000, 06/11/2026) : la direction attribue une aide Internet, une prime ou une mission du mois ; garde admin et compte valide ; idempotence par clé ; journalisé ; relue deux fois.
    'autre_revenu_attribuer(uuid,date,text,text,bigint,text)',
    -- CALENDRIER-ET-PAUSES (12/11) : la direction saisit une date du calendrier de l'ecole ; garde positive admin et app_account_valid().
    'calendrier_ecole_enregistrer(uuid,text,text,text,date,date,text,text,uuid)',
    -- CALENDRIER-ET-PAUSES (12/11) : la direction publie ou retire de la publication ; garde positive admin et app_account_valid().
    'calendrier_ecole_publier(uuid,boolean)',
    'changer_affichage_evaluation(uuid,text)',
    -- COULEUR-PROFIL 22 i (20261110500000, 06/11/2026) : couleur d'un profil, garde tuteur du foyer ou adulte autonome ; relue deux fois.
    'choisir_accent_profil(uuid,text)',
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
    -- CAND nom latin (23/10, porte par CANDIDATS-FLUX 06/11) : la personne confirme son nom en lettres latines.
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
    -- Classe a plusieurs creneaux et mixite (29/10), duree par creneau (30/10) :
    -- direction active seulement.
    'creer_classe_creneaux_admin(uuid,text,text,smallint,text,jsonb,text,smallint)',
    'modifier_creneau_classe_admin(uuid,integer,integer,integer,integer,integer,text)',
    'ajouter_creneau_classe_admin(uuid,integer,integer,integer)',
    -- Surcharge a 3 arguments (20261025020000), toujours presente a cote de celle a 4 : direction active seulement (app_account_valid ET admin).
    'ajouter_creneau_classe_admin(uuid,integer,integer)',
    -- CALENDRIER-ET-PAUSES (12/11) : le tuteur, l'adulte ou la direction annule une pause avant son debut ; garde private.pause_famille_peut ou admin, compte valide.
    'pause_annuler(uuid)',
    -- CALENDRIER-ET-PAUSES (12/11) : la direction accepte ou refuse une pause au-dela du plafond ; garde positive admin et app_account_valid().
    'pause_decider(uuid,boolean,text)',
    -- CALENDRIER-ET-PAUSES (12/11) : le tuteur (enfant) ou l'adulte autonome demande une pause d'un mois ; garde private.pause_famille_peut (foyer ou soi, jamais l'enfant), compte valide.
    'pause_demander(uuid,date)',
    -- CALENDRIER-ET-PAUSES (12/11) : la direction accorde une pause d'exception (motif, fin, nom) ; garde positive admin et app_account_valid().
    'pause_exception_accorder(uuid,date,date,text)',
    -- CALENDRIER-ET-PAUSES (13/11) : la direction termine une pause d'exception plus tot (geste trace) ; garde positive admin et app_account_valid().
    'pause_exception_terminer(uuid,date)',
    -- CALENDRIER-ET-PAUSES (13/11) : la direction retire une fermeture, en confirmant au besoin d'abandonner des seances qui ne se retablissent pas (geste trace) ; garde positive admin et app_account_valid().
    'calendrier_ecole_retirer(uuid,integer)',
    -- CALENDRIER-ET-PAUSES (13/11) : la liste des conflits d'un retrait simule le retablissement puis le defait (aucune ecriture ne subsiste) ; garde positive admin et app_account_valid().
    'calendrier_retrait_conflits(uuid)',
    'retirer_creneau_classe_admin(uuid,integer,integer,text)',
    -- HORLOGE-ET-LIEU (13/11/2026) : l'heure saisie avec son fuseau, direction active
    -- seulement (app_account_valid ET admin), le serveur convertit vers le fuseau de la classe.
    'ajouter_creneau_classe_fuseau(uuid,integer,integer,integer,text)',
    'modifier_creneau_classe_fuseau(uuid,integer,integer,integer,integer,integer,text,text)',
    'modifier_groupe_fuseau(uuid,text,smallint,smallint,smallint,text,smallint)',
    -- HORLOGE-ET-LIEU (13/11/2026) : la ville de la personne (tuteur ou enseignant, compte valide,
    -- identifiant lu dans le JWT), et la verification de la ville d'un enseignant (direction active).
    'enregistrer_ma_ville(bigint)',
    'reporter_ma_ville()',
    'verifier_lieu_enseignant(uuid)',
    'regler_genre_classe_admin(uuid,text,text)',
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
    -- N3 (03/11) : le controleur de la mission joint son compte rendu (aal2, capacite active, visite commencee).
    'controleur_envoyer_compte_rendu(uuid,text,jsonb,uuid)',
    'deposer_reprise_foyer(uuid)',
    'deposer_student_concern(text,uuid,uuid,text,text,text)',
    -- PHOTOS-1 (03/11) : chaque adulte au compte valide pose sa photo ; le tuteur actif celle de son enfant mineur (garde role ET app_account_valid).
    'poser_ma_photo(text)',
    -- CAND-PHOTO (06/11) : la photo du candidat (titulaire d'une candidature en cours) et son accord de
    -- publication (enseignant ou candidat, garde positive, nom signe relu au serveur).
    'poser_photo_candidat(text)',
    'accepter_accord_publication(text)',
    'retirer_accord_publication()',
    'poser_photo_eleve(uuid,text)',
    -- V1-a (03/11) : la direction active, de son cote, planifie et consigne un entretien (moteur des candidatures : version attendue, cle, journal ; garde role ET app_account_valid), choisit et retire ses participants (cote impose, fondateurs comptes), tient la coche fondateur ; un participant ecrit son compte rendu.
    'planifier_entretien(uuid,timestamp with time zone,integer,uuid[],integer,text)',
    'consigner_entretien(uuid,text,text,integer,text)',
    'ajouter_participant_entretien(uuid,uuid)',
    'retirer_participant_entretien(uuid,uuid)',
    'poser_fondateur(uuid,boolean)',
    'ecrire_compte_rendu_entretien(uuid,text,text,text,text,text[],text)',
    -- V1-b (03/11) : la direction ouvre et annule un creneau d'entretien de son cote (super-admin des deux cotes) ; le candidat reserve (moteur des candidatures, auteur candidat : version, cle, journal).
    'ouvrir_creneau_entretien(gender,timestamp with time zone,integer,text[],uuid[])',
    'annuler_creneau_entretien(uuid)',
    'reserver_creneau_entretien(uuid,integer,text)',
    -- D1-bis (03/11) : la direction active traite un signalement (examiner, rediger le message pour la famille, clore) ; garde role ET app_account_valid, journal a chaque geste.
    'examiner_student_concern(uuid)',
    'rediger_resume_student_concern(uuid,text)',
    'clore_student_concern(uuid,text)',
    'designer_remplacant_admin(uuid,uuid,uuid)',
    -- Remplacements direction (31/10) : R12, libre a l'heure exacte, genre souple sur choix explicite trace ; direction active.
    'designer_remplacant_admin(uuid,uuid,uuid,boolean)',
    -- A3 (31/10) : un enseignant actif candidat se declare pret pendant la pre-alerte ; le premier gagne.
    'se_declarer_pret_remplacement(uuid)',
    -- FN-115c (02/11) : « Rembourser » confirme par la direction ; garde private.fn115c_direction() (admin, compte valide), plafond arrete par le serveur.
    'remboursement_confirmer(uuid,uuid,bigint,uuid)',
    -- Horloge de classe (25/10) : la seance a rejoindre d'une classe, lue par la direction, l'enseignant, l'eleve ou le tuteur de la classe ; compte valide exige (lecture non declaree STABLE).
    'seance_a_rejoindre(uuid)',
    'dossiers_en_attente()',
    'effacer_etat_partage(uuid)',
    'eleves_sans_enseignant()',
    -- FAC-B-01, FAC-C-01 (17/10) : direction ou comptabilite, compte valide.
    'emettre_factures_mois(date)',
    -- FINANCE-ENSEIGNANT (20261110700000, 06/11/2026) : garde positive (titulaire enseignant au compte valide, ou direction admin/accountant au compte valide par private.versement_direction) ; relue deux fois (garde-cap 06/11, ancien garde-cap 07/11).
    'enregistrer_mes_coordonnees_versement(text,text,text,text,text,text,text,text,text,text,boolean,text,boolean)',
    'enregistrer_paiement(uuid,bigint,text,text,uuid)',
    'enregistrer_parrainage(uuid,uuid)',
    -- CAHIER-C1 (20261110100000, 06/11/2026) : enseignant effectif de la séance, compte valide, fenêtre de la séance ; relue deux fois.
    'enregistrer_page_presentee(uuid,integer)',
    'enregistrer_profil_apprentissage(uuid,text,text,text,text,text)',
    'enregistrer_regles_tirage(jsonb,uuid)',
    'enregistrer_resultat_evaluation(uuid,text,text)',
    'enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)',
    -- CAND-L6 (21/10) : referentiel de paiement, direction ou comptabilite, compte valide.
    -- REAFFECTER-CLASSE (31/10) : la direction retire une Classe a son enseignant (verifier_affectation_enseignant, verrou par enseignant) ; direction active.
    'enseignants_pour_reaffectation(uuid)',
    'enregistrer_ligne_referentiel_paiement(uuid,text,text,text,text,text,text,text,date,text,integer,text)',
    -- CAND-AUTRES (22/10) : les autres competences du candidat, titulaire d'une candidature enseignant au compte valide (apres l'envoi de la Salle d'examen, version attendue, cle d'idempotence ; aucune garde de role).
    'enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)',
    -- I1 (02/11) : la direction active envoie l'invitation d'un foyer importe, ou de tous apres confirmation du nombre (garde role ET app_account_valid).
    'envoyer_invitation_famille_importee(uuid)',
    -- INVITATIONS-PERSONNELLES (20261120000000, 07/11) : invitation a code et son e-mail pour les candidats importes, super-admin en aal2, nombre attendu, 200 par geste, plafond propre de 300 par 24 h.
    'envoyer_invitations_candidats_importes(integer,integer)',
    'envoyer_invitations_familles_importees(integer)',
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
    -- INVITATIONS-PERSONNELLES (20261120000000, 07/11) : « Copier le lien » d'une reponse importee, super-admin en aal2 ; reutilise ou emet une invitation, aucun e-mail, journal sans code ni adresse.
    'lien_invitation_candidat_importe(uuid,text)',
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
    'inscrire_titulaire(text,text,text,gender,text,boolean,jsonb)',
    -- ADMISSION lot C (30/10) : gestes de la direction sur les familles et
    -- les eleves adultes (direction active seulement), et le lien d'un enfant
    -- de la demande a son profil (le titulaire, sur sa demande confirmee).
    'accepter_admission(uuid,integer,text)',
    'refuser_admission(uuid,text,text,integer,text)',
    'annuler_refus_admission(uuid,text,integer,text)',
    'annuler_admission(uuid,text,integer,text)',
    'demander_precisions_admission(uuid,text,integer,text)',
    'contacter_admission(uuid,text,text,text)',
    'lier_apprenant_profil(uuid,uuid)',
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
    -- CAHIER-C2 (06/11) : direction seulement, compte valide, brouillon seulement.
    'modifier_contenu_niveau(uuid,text[],jsonb,jsonb)',
    'modifier_niveau_programme(uuid,text,text,integer,text)',
    'mon_invitation_en_cours()',
    'pause_reglage_ecrire(uuid,boolean,integer,integer,text,text)',
    'pause_seance_demarrer(uuid,text)',
    -- PAUSE-SERVEUR (12/11/2026) : le Non a la pause proposee ; memes gardes que pause_seance_demarrer (enseignant titulaire, compte valide, seance en cours).
    'pause_seance_refuser(uuid,text)',
    'pause_seance_terminer(uuid,text)',
    'planifier_evaluation(uuid,uuid,text,date)',
    'poser_exception_progression(uuid,text,text)',
    -- FINANCE-ENSEIGNANT (20261110700000, 06/11/2026) : garde positive (titulaire enseignant au compte valide, ou direction admin/accountant au compte valide par private.versement_direction) ; relue deux fois (garde-cap 06/11, ancien garde-cap 07/11).
    'poser_modele_wise(jsonb)',
    'poser_regle(uuid,text,integer,text)',
    'prendre_remplacement(uuid,uuid)',
    -- PRIERE-1 (12/11/2026) : l'enseignant ajuste ses heures (role teacher et app_account_valid(), pour lui seul) ;
    -- la direction pose ou retire un lieu, ou relance le recalcul (admin et app_account_valid(), aal2 pour le recalcul).
    'priere_ajuster(text,integer)',
    'priere_lieu_definir(uuid,text,numeric,numeric,text,text,text,boolean,time without time zone,time without time zone)',
    'priere_lieu_retirer(uuid)',
    'priere_ma_position(numeric,numeric,text)',
    'priere_corriger(uuid,text,text,boolean,time without time zone,time without time zone)',
    'priere_recalculer_maintenant()',
    'preparer_depot_piece_identite(uuid,text)',
    -- CAHIER-C2 (06/11) : direction seulement, compte valide, brouillon vide.
    'preremplir_bases_programme(uuid)',
    -- CAND-PREVENIR (24/10, porte par CANDIDATS-FLUX 06/11) : met en file l'invitation, une par adresse (direction active de son cote).
    'prevenir_par_courriel(integer)',
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
    -- Salle en groupe (30/10) : l'enseignant effectif readmet un eleve sorti (garde positive, compte valide).
    -- REAFFECTER-CLASSE (31/10) : direction active, seances futures, journal enseignant_reaffecte_classe.
    'reaffecter_enseignant_classe(uuid,uuid,text)',
    'readmettre_eleve_salle(uuid,uuid)',
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
    -- MA-PROGRESSION (08/11) : la direction regle les sourates, les heures de revision et les
    -- repetitions d'une etape (garde positive app_role() = 'admin' et app_account_valid()).
    'regler_etape_progression(text,numeric,integer)',
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
    -- FINANCE-ENSEIGNANT (20261110700000, 06/11/2026) : garde positive (titulaire enseignant au compte valide, ou direction admin/accountant au compte valide par private.versement_direction) ; relue deux fois (garde-cap 06/11, ancien garde-cap 07/11).
    'retirer_mes_coordonnees_versement()',
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
    -- FINANCE-ENSEIGNANT (20261110700000, 06/11/2026) : garde positive (titulaire enseignant au compte valide, ou direction admin/accountant au compte valide par private.versement_direction) ; relue deux fois (garde-cap 06/11, ancien garde-cap 07/11).
    'valider_coordonnees_versement(uuid,uuid)',
    -- Salle 3 (03/11) : valider la piece d'une candidate (transition 14), direction active de son cote (moteur, controles nommes, tout ou rien).
    'valider_piece_candidat(uuid,integer,text)',
    -- FINANCE-ENSEIGNANT (20261110700000, 06/11/2026) : garde positive (titulaire enseignant au compte valide, ou direction admin/accountant au compte valide par private.versement_direction) ; relue deux fois (garde-cap 06/11, ancien garde-cap 07/11).
    'versement_export_wise(date)',
    -- FINANCE-ENSEIGNANT (20261110710000, 06/11/2026) : la direction ou la comptabilite annule un versement note (annule_le, motif exige, jamais d'effacement) ; garde positive admin ou comptable et compte valide ; CONFORME du garde-cap 01:41, ajout par l'integration selon la regle du 07/11.
    'versement_paie_annuler(uuid,text)',
    -- FINANCE-ENSEIGNANT (20261110710000, 06/11/2026) : la direction ou la comptabilite note un versement a un enseignant ; garde positive admin ou comptable et compte valide ; idempotence par cle ; CONFORME du garde-cap 01:41, ajout par l'integration selon la regle du 07/11.
    'versement_paie_noter(uuid,bigint,text,date,text,text,date,text,uuid)',
    'verifier_chaine_audit(integer)',
    -- COURRIELS-1 et 2 (23/10) : la direction ecrit, relance et regle les
    -- adresses d'envoi (garde is_admin_user en tete) ; chacun regle la langue
    -- de ses propres e-mails (auth.uid()).
    'admin_courriel_categorie_regler(text,text,text,text,boolean)',
    'admin_courriel_envoyer(uuid,text,text,text,text,uuid)',
    'admin_courriel_reessayer(uuid)',
    'ma_langue_communication_regler(text)',
    'ma_preference_theme_regler(text)',
    -- COURRIELS-1 : la desinscription par le lien d'un e-mail, sans compte
    -- (jeton a usage unique, seule son empreinte sha256 est gardee).
    'courriel_desinscrire(text)',
    -- AVIS-PUBLICS (19/10) : liens de collecte et moderation par la direction
    -- (garde positive app_role() = 'admin' et compte valide) ; depot par le
    -- formulaire, avec ou sans compte (jeton de lien verifie dans la fonction).
    'avis_lien_creer(text,integer,integer)',
    'avis_lien_fermer(uuid)',
    'avis_moderer(uuid,text,text)',
    'avis_deposer(text,text,text,text,date,integer,text,text,boolean)',
    -- SNT (03/11) : la direction fixe la nouvelle date d'une seance reportee
    -- (garde positive app_account_valid() et app_role() = 'admin', celle de C1).
    'fixer_nouvelle_date_seance(uuid,timestamp with time zone)',
    -- SUPPRIMER (03/11) : la direction retire une selection de comptes (garde
    -- positive app_role() = 'admin', app_account_valid() et app_aal() = 'aal2').
    'direction_supprimer_comptes(uuid[],text,boolean)',
    -- SUPPRIMER (03/11) : un tuteur retire le profil d'un mineur de son foyer
    -- (garde positive app_role() = 'guardian' et app_account_valid()).
    'tuteur_supprimer_profil_enfant(uuid)',
    -- SUPPRIMER-bis (03/11) : la direction restaure des retraits non encore
    -- anonymises (garde positive app_role() = 'admin', app_account_valid() et
    -- app_aal() = 'aal2').
    'direction_restaurer_comptes(uuid[])',
    -- PUSH-1 (07/11) : chacun inscrit, retire et regle les notifications de
    -- SON appareil (auth.uid() ; garde positive private.push_compte_autorise :
    -- compte valide, role adulte, jamais un enfant ; la desinscription ne
    -- touche que les abonnements de l'appelant).
    'push_inscrire(text,text,text,text)',
    'push_desinscrire(text)',
    'push_regler_categorie(text,boolean)',
    -- INVITATION-SECOND-ADULTE (07/11) : le titulaire renvoie l'invitation en
    -- attente de son foyer (garde positive app_role() = 'guardian' et
    -- app_account_valid(), titulaire du foyer actif ; trois renvois au plus).
    'renvoyer_invitation_conjoint(uuid)',
    -- INVITATION-ACCUEIL (09/11) : la personne invitee dans un foyer, sans
    -- profil, accepte en creant son compte dans le foyer qui invite, ou refuse
    -- sans rien creer (garde positive : session, adresse confirmee, AUCUN
    -- profil, invitation de foyer en attente pour cette adresse ; pas de
    -- app_role(), puisqu'elle n'a pas encore de role).
    'accepter_invitation_nouveau_compte(text,text,gender,uuid)',
    'refuser_invitation_sans_compte(uuid)',
    -- NOUVEAUTES (07/11) : la personne a ouvert une fonctionnalite signalee
    -- (garde positive app_account_valid() et role de la ligne ; idempotent).
    'marquer_nouveaute_vue(text)',
    -- PHOTO-FIGEE (07/11) : la direction lit la photo figee d'un dossier de
    -- candidature (garde positive app_role() = 'admin' et app_account_valid(),
    -- genre du lecteur ; journalise l'exception super admin, d'ou VOLATILE).
    'photo_dossier_candidat(uuid)',
    -- PARTAGE-GENERIQUE (20261123700000, 11/11/2026) : l'enseignant effectif
    -- de la seance retient la page presentee d'un support autre que le Coran
    -- (garde positive app_account_valid() ET app_role() = 'teacher' ET
    -- private.c29_enseignant_effectif_session(seance) = auth.uid() ; fenetre
    -- de la seance a 60 minutes pres ; support, version et page bornes ; une
    -- ligne par Classe et par support). Relue par le pilote de la salle le
    -- 11/11/2026 (la CI l'avait refusee hors liste, a raison).
    'enregistrer_position_support(uuid,text,text,integer,integer)',
    -- RESEAU-PREUVE (20261123700100, 11/11/2026, BROUILLON non installe) :
    -- un participant ecrit SA ligne du releve de qualite de connexion.
    -- Qui peut appeler : l'enseignant ou un eleve ADULTE de la seance, pour
    -- lui-meme ; un tuteur pour un eleve adulte de son foyer. Garde positive :
    -- app_account_valid() ET (p_profile_id = auth.uid() OU (app_role() =
    -- 'guardian' ET est_du_foyer(p_profile_id))) ET un jeton video
    -- d'enseignant ou d'eleve delivre pour cette seance (video_token_grants ;
    -- par le chemin du tuteur, un jeton d'eleve seulement) ET aucune
    -- opposition acceptee ET, pour un eleve, student_type = 'autonomous'
    -- (aucun eleve mineur) ET la fenetre de la seance a 60 minutes pres ;
    -- 42501 sinon. Ce qu'elle peut ecrire : UNE
    -- ligne dans releve_qualite_lien (etat parmi bon, faible, perdu ; micro
    -- ouvert ou non ; heure du serveur), au plus toutes les 8 s, jamais deux
    -- fois le meme etat, 400 au plus par personne et par seance ; aucune
    -- modification, aucun effacement. Relue par l'agent du lot le 11/11/2026.
    'noter_qualite_lien(uuid,uuid,text,boolean)',
    -- RESEAU-PREUVE (meme migration) : la direction lit le releve de qualite
    -- d'une seance. Garde positive app_account_valid() ET app_role() =
    -- 'admin' ; 42501 sinon. VOLATILE parce qu'elle ecrit chaque lecture au
    -- journal d'audit (log_sensitive_access, action lecture_releve_qualite) :
    -- c'est sa seule ecriture. Relue par l'agent du lot le 11/11/2026.
    'releve_qualite_seance(uuid)',
    -- SUIVI-ATTENTE (12/11/2026, migration 20261123960000) : l'enseignant
    -- regle ce que les familles de ses classes voient de lui (visibilite, deux
    -- pays, mot de presentation). Garde positive app_account_valid() ET
    -- app_role() = 'teacher' ; 42501 sinon ; une seule ligne ecrite, la
    -- sienne (profile_id = auth.uid()). VOLATILE : elle ecrit. Relue par
    -- l'agent du lot le 12/11/2026.
    'regler_presentation_aux_familles(boolean,text,text,text)',
    -- CORRIGER-SOURATE (migration 20261123820000) : retirer une sourate
    -- validee par erreur. Garde positive app_account_valid() ET (app_role() =
    -- 'admin', ou app_role() = 'teacher' ET auteur de la validation dans les
    -- 24 h) ; 42501 sinon, la meme reponse que la sourate existe ou non. Ce
    -- qu'elle peut ecrire : le marquage retiree_le, retiree_par, motif (500
    -- signes au plus) d'UNE ligne de sourates_validees, jamais d'effacement ;
    -- et une ligne d'audit (log_sensitive_access, action sourate_retiree).
    -- Relue par l'agent du lot le 12/11/2026.
    'retirer_sourate_validee(uuid,integer,text)',
    -- HORS-SALLE-2 (migration 20261124200000) : l'accord du journal des
    -- sorties de l'application, par eleve. Garde positive
    -- private.sorties_peut_decider (app_account_valid() ET eleve reconnu par
    -- sa fiche ET, soit lui-meme ET ma_capacite_eleve() (eleve autonome, quel
    -- que soit son role), soit app_role() = 'guardian' ET un autre eleve de
    -- son foyer non autonome) ; 42501 sinon. Ce qu'elles peuvent
    -- ecrire : le marquage retire_le, retire_par de l'accord en cours et UNE
    -- ligne d'accord (accepter, journal allume, version en cours seulement),
    -- jamais d'effacement ; une ligne d'audit (log_sensitive_access).
    -- Relues par l'agent du lot le 13/11/2026.
    'accepter_accord_sorties(uuid,text)',
    'retirer_accord_sorties(uuid)',
    -- HORS-SALLE-2 (meme migration) : noter une sortie de l'application.
    -- Garde positive app_account_valid() ET (eleve reconnu par sa fiche pour
    -- lui-meme, ou 'guardian' ET est_du_foyer(eleve) non autonome, D6) ET
    -- eleve participant
    -- de la seance en cours ET journal allume ET accord valide ; sinon rend
    -- {"note": false} sans rien ecrire. Ce qu'elle peut ecrire : UNE ligne de
    -- journal_sorties_app, heures du serveur, 200 au plus par seance et par
    -- eleve, une par seconde au plus. Relue par l'agent du lot le 13/11/2026.
    'noter_sortie_app(uuid,integer,boolean,uuid)'
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
