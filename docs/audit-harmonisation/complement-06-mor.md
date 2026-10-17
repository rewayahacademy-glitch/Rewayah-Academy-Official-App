# Registre de conformite - Coherence morale et institutionnelle et proportionnalite des controles non auditees de facon dediee

- SHA audite : 4a7aa2b (ancetre de la tete courante 2eebaf92 ; `git diff --stat 4a7aa2b HEAD -- lib supabase` est vide, seuls des documents ont change depuis)
- Branche : claude/nice-darwin-hael93
- Date : 14/10/2026
- Auditeur : agent d'audit de conformite en lecture seule (Claude), domaine complementaire MOR
- Domaine : coherence morale et institutionnelle, dignite, proportionnalite des controles, distinction entre recommandation, observation, validation et decision
- Mode : lecture seule. Flutter et Dart ne sont pas installes ici : tous les tests cites sont "test lu, non execute". Aucun fichier modifie hors de ce registre.

## 1. Perimetre, sources lues, sources introuvables

### 1.1 Perimetre

Le domaine verifie, sur tous les ecrans et toutes les projections serveur, cinq choses :

1. les libelles d'echec, de refus et de resultat ne stigmatisent ni un enfant ni un enseignant ;
2. une observation, une recommandation, une validation et une decision sont des objets distincts, nommes comme tels ;
3. un controle (observation tuteur, visite du controleur, signalement, feedback, motif de refus) est proportionne a son but et ne divulgue pas plus que necessaire ;
4. les promesses faites a l'utilisateur (notification, enregistrement, anonymat) sont tenues par le systeme ;
5. les messages d'erreur, les notifications et les exports ne portent pas d'information sur un mineur au-dela du besoin.

Les points deja audites ailleurs ne sont pas repris : ils sont cites par identifiant (section 1.4).

### 1.2 Sources lues

Prompt de mission : lignes 146-215 (devoir de regard), 286-310 (domaine G, format de contre-proposition, trois situations), 306-380 (harmonisation en systeme).

Document maitre : lignes 381-428 (G09 evaluations, jury, attestations), 500-518 (G12 controleur), 779-900 (statuts, hierarchie des sources, non-regression).

Depot, sur 4a7aa2b :
- CLAUDE.md racine ; docs/HANDOFF.md (grep cible : CTR-03, ADM-03, 0037, MFA ; lignes 87-123, 173, 2846-2858) ; docs/PROGRESS.md (grep cible) ;
- assets/i18n/fr.i18n.json (lecture par plages : lignes 24-125, 176-183, 340-420, 540-700, 1190-1230, 1596-1650, 1930-1975, 2035-2218) ; assets/i18n/ar.i18n.json (32 lignes, comptage seul) ;
- supabase/migrations : 0001 (app_config, kyc), 0004 (lignes 520-570), 0005 (teacher_roster_v), 0010 (ligne 373), 0012 (lignes 392-450), 0014 (vue mes_seances_v), 0016 (en-tete), 0023 (complete), 0024 (lignes 20-80), 0032 (lignes 500-640), 0033 (lignes 215-285, 1000-1075, 1128-1145, 1255-1302, 1640-1790) ;
- supabase/functions/session-enfant et create-room-token (lignes de capacites) ;
- lib/features : controleur/planning_page.dart, admin_pedagogie_evaluations/evaluations_page.dart, dossier/attente_page.dart, tc_observation_ui (panneau, indicateur, vue), tc_classe_live/entete_classe.dart, salle/salle_page.dart, accueil_famille/accueil_famille_page.dart, admin_groupes/feuille_observation_groupe.dart ; lib/core : tc_observation/port_annonce_observation.dart, widgets/permanent_notice.dart, admin/service_evaluations.dart, video/service_video.dart ;
- tests lus par nom et assertion : test/features/dossiers_admin_test.dart, planning_controleur_test.dart, salle_test.dart, revue_groupe_test.dart, test/teaching_core/g/vue_observation_tuteur_test.dart, ecrans_observation_test.dart ; supabase/tests/scenarios_etape4.sql (ligne 802), scenarios_ctr01.sql (en-tete) ;
- registres existants : controleur-communications-recherche.md, enseignant-pedagogie-evaluations.md, complement-04-vcx.md, eleves-tuteur-foyer.md, identite-securite.md, salle-bibliotheque-teaching-core.md (recherche par grep d'identifiants, lignes citees) ;
- branche origin/codex/backend-b09-notifications : migration 0063_notifications_privatives.sql (colonnes params et destination) lue via git show, pour la PR draft #17 (B-09).

### 1.3 Sources introuvables ou non lisibles

- REWAYAH_EVALUATIONS_FINAL_SPEC_V2.md, briefs high-fi, handoff Claude et matrice QA du 12/10 : absents du depot, connus par le document maitre (lignes 381-428) seulement. Le texte exact des trois formules publiques et des 45 scenarios n'a pas ete lu.
- Decision du 02/10 sur la retention du rapport brut du controleur (12 mois) : aucune occurrence dans le depot (confirme par AUD-COM-015).
- Politique d'anonymat retenue pour CTR-03 : citee par docs/HANDOFF.md:2853 sans texte ; non trouvee.
- RECH-01, RECH-02, COM-BR-01 a 16 : introuvables (deja signale par AUD-COM-022 et AUD-COM-031).
- Fichiers de la branche ui/controleur-v1 : non relus ici (couverts par AUD-COM-002).

### 1.4 Registres existants dont les lignes sont citees, non reprises

AUD-COM-007, 008, 009, 012, 013, 014, 015, 016, 019, 021, 025, 026, 028 (controleur, notifications) ; AUD-ENS-005, 027, 061, 065, 070, 074, 077, 078, 079 (evaluations, cahier, signalement) ; AUD-VCX-022 ; AUD-SAL-089, 090 ; AUD-IDS-064 ; AUD-ELV-078, 083 ; CTR-ENS-01, CTR-ENS-02, CTR-SAL-01, CTR-COM-02 ; CP-ENS-04.

## 2. Registre par exigence

Convention : "test lu, non execute" vaut pour chaque test cite. Les numeros de ligne sont ceux de 4a7aa2b.

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| AUD-MOR-001 | Decisions publiques individuelles : "Etape validee", "Quelques points sont a renforcer", "Une nouvelle verification est necessaire" ; aucun etat humiliant "Echec" (DM 412) | Administration aujourd'hui ; eleve et tuteur plus tard | ADM-12, EvaluationsPage, ResultatEvaluation | CONTRADICTOIRE | assets/i18n/fr.i18n.json:657 ("Echec") ; lib/core/admin/service_evaluations.dart:62-68 ; lib/features/admin_pedagogie_evaluations/evaluations_page.dart:246-251 ; 0023_evaluations.sql:30 (stockage reussi, echec, a_revoir). Deja note par AUD-ENS-077 et AUD-VCX-022 | Remplacer les trois libelles d'affichage avant toute exposition a une famille ; garder le stockage | P2 | frontend | CP-ENS-04 ; CTR-ENS-02 |
| AUD-MOR-002 | Le resultat brut d'une evaluation n'est lisible par aucun eleve, tuteur ni enseignant tant que les formules publiques ne sont pas livrees (DM 387, 393-394) | Eleve, tuteur, enseignant | policy evaluations_lecture ; evaluations_admin() | IMPLÉMENTÉ_NON_PROUVÉ | 0023_evaluations.sql: policy evaluations_lecture (select reserve a app_role() = 'admin' et app_account_valid()), revoke insert, update, delete ; fonction evaluations_admin() meme garde. Aucun test : grep evaluations dans supabase/tests et test/ ne rend rien | Regle serveur lue, mais aucun scenario SQL ni test Dart ne l'atteste | P2 | backend | aucune tache existante trouvee |
| AUD-MOR-003 | Une absence a l'appel, une coupure ou un incident technique n'est jamais un echec academique (DM 389, 412) | Eleve, evaluateur | colonne resultat de evaluations | ABSENT | 0023_evaluations.sql:30 : seuls reussi, echec, a_revoir ; aucun etat technique ni file d'appel. Voir AUD-ENS-070 | Un candidat injoignable ne peut etre trace que comme "annulee" avec motif ou comme "echec" : le second est possible a la main | P1 | backend, gouvernance | aucune tache existante trouvee |
| AUD-MOR-004 | Un resultat negatif s'accompagne d'une action pedagogique, pas d'un simple verdict (DM 387 : decision puis action pedagogique) | Administration, enseignant referent | enregistrer_resultat_evaluation | ABSENT | 0023_evaluations.sql:107-157 : p_resultat et p_notes facultatives, aucune exigence de motif ou d'action pour echec ou a_revoir (alors que l'annulation exige un motif, lignes 172-174) | Ni motif, ni suite pedagogique obligatoires pour un resultat negatif ; un "echec" se saisit en un geste | P1 | backend, gouvernance | CP-ENS-04 |
| AUD-MOR-005 | Une evaluation reussie n'est pas une promotion ; observation, evaluation, promotion et certification sont des actes distincts (DM 414-416) | Administration, eleve | enregistrer_resultat_evaluation, progression_historique | CONTRADICTOIRE | 0023_evaluations.sql:142-150 (un "reussi" sur reevaluation ou certification insere une ligne de progression). Deja note par AUD-ENS-078 | Un acte de resultat modifie le niveau d'un enfant sans decision distincte ni message a la famille | P1 | backend, gouvernance | CP-ENS-04 ; CTR-ENS-01 |
| AUD-MOR-006 | Le mot "ijazah" et tout document de diplome n'apparaissent qu'apres decision doctrinale ; aucune fabrication locale de PDF (DM 416) | Systeme | textes et generation de documents | CONFORME_PARTIEL | Recherche ijaz, diplom, certificat dans assets/i18n/fr.i18n.json : seules occurrences lignes 632, 642, 652 (filtre et type "Certification") ; aucun paquet ni fonction de PDF. Voir AUD-ENS-079 | Pas de test d'absence ; "les certifications obtenues" (ligne 632) suggere un acquis alors que rien n'est emis | P2 | gouvernance, frontend | REF-35 section 15 |
| AUD-MOR-007 | Les jures sont affectes selon une politique configurable, avis independants, aucune deliberation visible hors jury (DM 397, 407) | Jure, administration | jury, quorum | ABSENT | grep jury et quorum dans lib/ et supabase/migrations : zero occurrence (meme constat que AUD-ENS-072) | Rien a evaluer sur la proportionnalite du jury tant que le contrat n'existe pas | P1 | backend (contrat), contenu academique | aucune tache existante trouvee |
| AUD-MOR-008 | Le champ de notes libres d'une evaluation est une observation interne : il ne doit pas partir vers la famille avec le verdict (DM 387 ; distinction observation et decision) | Administration | evaluations.notes, champNotes | IMPLÉMENTÉ_NON_PROUVÉ | 0023_evaluations.sql:138-139 (notes ecrites avec le resultat), 195-225 (evaluations_admin rend notes) ; fr.i18n.json:670 ("Notes (optionnelles)"). Aucune colonne separee pour un message famille, contrairement a student_concern (0032:567-590) | Une seule colonne de texte libre : l'avenir du champ (interne ou transmissible) n'est pas decide | P2 | backend, gouvernance | CP-ENS-04 |
| AUD-MOR-009 | L'identite des personnes evaluees est masquee a un agent IA en lecture (ADR-008, 0015, 0016) | Agent IA | evaluations_admin() | CONFORME_PARTIEL | 0023_evaluations.sql:211-222 (case agent_identite_masquee() sur prenom et nom) ; lib/core/admin/service_evaluations.dart:116. scenarios_agt01.sql existe mais ne reference pas evaluations (grep) | Masquage lu cote serveur ; la colonne notes n'est pas filtree pour l'agent et peut contenir un nom | P1 | backend | AGT-01 (docs/HANDOFF.md) |
| AUD-MOR-010 | Observation d'un tuteur : un seul enfant (le sien), un seul enseignant, aucune fiche ni video d'un autre eleve (specification G 11.2) | Tuteur, panneau /tc/observation | VueObservationTuteur, PanneauObservationTuteur | PRÉSENT_MAIS_NON_ROUTÉ | lib/features/tc_observation_ui/vue_observation_tuteur.dart:10-67 (deux participants nommes, les autres comptes seulement) ; test/teaching_core/g/vue_observation_tuteur_test.dart:44,57,67,99,112 (test lu, non execute). Mais lib/features/tc_classe_live/entete_classe.dart:190-206 : "AUCUN fichier de lib/ ne navigue" vers /tc/observation ; accueil_famille_page.dart:180-182 appelle assister_seance | La presentation qui borne la vue n'est jamais atteinte ; voir CP-MOR-01 | P1 | frontend | aucune tache existante trouvee (la bascule est "en attente volontaire" dans entete_classe.dart:197-205) |
| AUD-MOR-011 | Le chemin reellement utilise par le tuteur ("Assister") respecte la politique d'observation : groupe desactive, quota de visites, budget de temps (specification G 11) | Tuteur, Accueil famille | assister_seance(uuid) ; budget_observation(uuid) | CONTRADICTOIRE | 0012_observation_controleur.sql:398-447 (assister_seance n'inscrit aucune visite, ne lit pas la politique) ; 0033_tc_vues_rpc.sql:1019-1033 (le budget ne compte que guardian_session_visit, ecrit par entrer_observation seulement) ; entete_classe.dart:190-197 le confirme. Le quota ne se consomme donc jamais sur ce chemin | Sur le chemin actif, un tuteur peut demander un nouveau jeton sans limite de visites ni de temps cumule ; seule la desactivation du groupe est lue par budget_observation a l'emission du jeton | P1 | backend, frontend | aucune tache existante trouvee |
| AUD-MOR-012 | L'enseignant est informe quand un tuteur observe sa classe, sans nommer le tuteur (specification G 11.3) | Enseignant en cours | annonces_observation(uuid), IndicateurObservation | PRÉSENT_MAIS_NON_ROUTÉ | lib/core/tc_observation/port_annonce_observation.dart:11-20 (tuteur non nomme) ; 0033_tc_vues_rpc.sql:1259-1302 (reserve a l'enseignant de la seance, ne lit que guardian_observer et left_at null dans guardian_session_visit) ; lib/features/tc_classe_live/entete_classe.dart:213 ; test/teaching_core/g/ecrans_observation_test.dart:197-232 (test lu, non execute) | Aucune annonce ne se produit sur le chemin assister_seance, qui n'ecrit pas guardian_session_visit | P1 | backend, frontend | aucune tache existante trouvee |
| AUD-MOR-013 | L'enfant est prevenu que son tuteur regarde : "Ton tuteur regarde le cours" (specification G 11.3) | Eleve | IndicateurObservationEnfant | PRÉSENT_MAIS_NON_RACCORDÉ | lib/features/tc_observation_ui/indicateur_observation.dart:131-160 ; assets/i18n/fr.i18n.json:2096. Aucun appelant hors definition (grep IndicateurObservationEnfant dans lib/) | Le composant existe, mais aucun ecran de l'enfant ne le monte | P1 | frontend | aucune tache existante trouvee |
| AUD-MOR-014 | Le jeton d'un observateur ne lui donne acces qu'aux pistes necessaires (aucun roster complet, DM 11.2 et specification G) | Tuteur observateur | autoriser_jeton_video, create-room-token | ABSENT | 0033_tc_vues_rpc.sql:1776 et 0010_video_jeton_presence.sql:373 : can_subscribe vaut true pour tout role ; la restriction a deux participants est faite dans VueObservationTuteur (client). lib/features/salle/salle_page.dart:796-806 : la galerie du chemin actif montre "tous" les participants distants | Aucune limite serveur de souscription ; en base, allow_multi_participant_sessions est false (0001:956), ce qui limite aujourd'hui l'exposition a l'enseignant et l'enfant | P1 (P0 si le reglage multi-participants est ouvert) | backend (LiveKit, jeton) | aucune tache existante trouvee |
| AUD-MOR-015 | Le tuteur observateur n'est jamais nomme a l'enseignant, et son foyer n'est pas deduit (specification G 11.3) | Enseignant | AnnonceObservation | CONFORME_PARTIEL | port_annonce_observation.dart:11-20 ; 0033:1280-1296 (la fonction rend le prenom de l'enfant et des secondes, jamais le tuteur) | Conforme dans le code lu ; non demontre en bout de chaine (AUD-MOR-012) et aucun scenario SQL de annonces_observation (grep tests : aucun) | P2 | backend | aucune tache existante trouvee |
| AUD-MOR-016 | Un tuteur qui a deux enfants dans le groupe n'observe que l'enfant choisi, pas un enfant arbitraire | Tuteur multi-enfants | entrer_observation, est_du_foyer | CONFORME_PARTIEL | 0033_tc_vues_rpc.sql:1133-1138 : select ... limit 1 sans ordre ni choix de l'appelant ; VueObservationTuteur.depuis recoit l'enfant "tel que le serveur l'a inscrit" (vue_observation_tuteur.dart:28-35) | Le choix de l'enfant n'est pas explicite ; deux freres dans la meme classe donnent un enfant imprevisible | P2 | backend | aucune tache existante trouvee |
| AUD-MOR-017 | Le bandeau permanent est identique pour l'enseignant, l'eleve, le tuteur et le controleur, que la visite ait lieu ou non (ADR-011) | Tous, salle | PermanentNotice | CONFORME_PROUVÉ | lib/core/widgets/permanent_notice.dart:1-30 (constructeur sans parametre) ; lib/features/salle/salle_page.dart:486 et lib/features/tc_classe_live/classe_live_page.dart:399 ; test/features/salle_test.dart:248,371,503,561 (test lu, non execute) ; tool/verifier_jetons.dart echoue si le constructeur gagne un parametre (en-tete de permanent_notice.dart) | - | - | frontend | ADR-011 |
| AUD-MOR-018 | Le contenu du bandeau permanent est vrai : "Cours enregistre" n'est affiche que si un enregistrement reel existe (DM 230 ; REG-35 section 5) | Tous, salle | assets/i18n/fr.i18n.json:30 | CONTRADICTOIRE | fr.i18n.json:30 et 180 ; voir AUD-SAL-090, AUD-ENS-005, CTR-SAL-01 | Phrase non prouvee par une chaine d'enregistrement (deja signale) | P1 | gouvernance, frontend | CTR-SAL-01 |
| AUD-MOR-019 | Le rappel d'invisibilite ne s'affiche que sur l'ecran de qui observe, jamais chez les participants | Controleur | _Rappel, bandeauControle | CONFORME_PROUVÉ | lib/features/salle/salle_page.dart:470-478 (condition vue.role == RoleSalle.controleur) ; assets/i18n/fr.i18n.json:76 ; test/features/salle_test.dart:370 (test lu, non execute) ; 0012_observation_controleur.sql:132-165 (invisibilite serveur, AUD-COM-007) | - | - | frontend | CTR-01 |
| AUD-MOR-020 | Un message d'echec d'entree ne detaille pas la raison pour un controleur (donnees de mineurs cloisonnees jusque dans les erreurs, DM 15.4) | Controleur | planning_page.dart _observer | CONFORME_PROUVÉ | lib/features/controleur/planning_page.dart:117-127 (message unique entreeRefusee) ; assets/i18n/fr.i18n.json:1630 ; test/features/planning_controleur_test.dart:151-172 (test lu, non execute). Voir AUD-COM-021 | - | - | frontend | CTR-01 |
| AUD-MOR-021 | La liste du controleur ne porte pas le prenom de l'eleve si le contrat l'interdit (DM 15.2) | Controleur | mes_seances_v ; planning_page.dart | À_ARBITRER | 0014_acces_agent.sql:888-925 (student_first_name et student_immutable_id rendus a role controller) ; fr.i18n.json:1624 ("{enseignant} et {eleve}"). Voir AUD-COM-013 | Decision de contrat non prise ; voir CP-MOR-07 | P1 | gouvernance | aucune tache existante trouvee |
| AUD-MOR-022 | Un controleur voit un echantillon limite a une mission, pas toutes les seances (proportionnalite, DM 15.2) | Controleur | mes_seances_v | CONTRADICTOIRE | 0014_acces_agent.sql:888-925 (app_role() in ('admin','controller') : toutes les seances) ; service_controle.dart:47-58 (plafond 200). Voir AUD-COM-009 | Aucun modele de mission ; un controleur peut ouvrir toute seance dans la fenetre | P1 | backend, gouvernance | aucune tache existante trouvee |
| AUD-MOR-023 | MFA obligatoire pour le controleur avant toute visite de mineurs (DM 15.2) | Controleur | auth.mfa, rejoindre_observation | ABSENT | Voir AUD-COM-008 (config.toml:310-312, TOTP a false ; docs/HANDOFF.md:173) | Aucun controle aal2 serveur | P0 | backend, gouvernance | aucune tache existante trouvee |
| AUD-MOR-024 | Rapport du controleur : brut reserve a son auteur et a l'administration, avec delai de contestation de 7 jours (DM 15.2, 15.3) | Controleur, enseignant | rapports de controle | ABSENT | Voir AUD-COM-014, 015, 016 ; aucune table de rapport | L'enseignant controle n'a ni lecture ni droit de reponse, aujourd'hui sans objet faute de rapport ; voir CP-MOR-09 | P1 | backend, gouvernance | CTR-03 (non tranche, docs/HANDOFF.md:2846-2858) |
| AUD-MOR-025 | Un refus de dossier d'identite exige un motif, en base et a l'ecran (dignite : la famille sait quoi corriger) | Administration, famille | verifier_document (0004) ; DossiersPage | CONFORME_PROUVÉ | 0004_inscription_kyc_appairage.sql:537-541 (raise "un refus exige un motif") ; test/features/dossiers_admin_test.dart:165-178 (un refus sans motif ne part pas, test lu, non execute) ; fr.i18n.json:346 | - | - | frontend, backend | ADM-02 |
| AUD-MOR-026 | Le motif de refus, en texte libre, est affiche tel quel a la famille et ne contient que des faits corrigeables | Famille, portail d'attente | _Refuse, rejection_reason | IMPLÉMENTÉ_NON_PROUVÉ | lib/features/dossier/attente_page.dart:174-198 (etat.motifRefus affiche sans filtre, ton alerte) ; 0004:553 (btrim seulement, aucune longueur ni gabarit) ; fr.i18n.json:110, 346 | Aucun gabarit de motifs ni relecture ; un administrateur peut ecrire une accusation ("document falsifie") sans garde | P1 | gouvernance, frontend | aucune tache existante trouvee |
| AUD-MOR-027 | Le refus d'une demande (reaffectation, plafond, regle) porte un motif lu par la seule partie concernee (DM : une phrase) | Administration, tuteur, enseignant | ADM-07 DemandesPage | IMPLÉMENTÉ_NON_PROUVÉ | fr.i18n.json:401-402 (motif requis : "la seule phrase que la partie recevra") ; 0008_attribution_manuelle.sql:273-277 (motif exige pour l'attribution hors disponibilites, pas lu pour le refus de demande) | Le garde serveur du motif de refus de demande n'a pas ete lu ; la partie destinataire ne voit pas ce motif dans un ecran dedie (non demontre) | P2 | backend, frontend | ADM-07 |
| AUD-MOR-028 | Le dossier refuse ou suspendu n'accuse pas la personne : phrase neutre et action de reprise | Famille, enseignant | attente.refuse, suspendu | CONFORME_PARTIEL | fr.i18n.json:110 ("Votre dossier n'a pas ete valide."), 111 et 124 (suspension : "joindre l'academie") ; attente_page.dart:174-198 (bouton "Reprendre mon dossier") ; test/features/attente_test.dart (etat refuse non relu assertion par assertion) | Aucune phrase de la suspension n'indique si une decision est contestable | P2 | frontend, gouvernance | aucune tache existante trouvee |
| AUD-MOR-029 | Le feedback des eleves est anonyme et agrege ; il ne suffit jamais seul a une decision (specification H) | Eleve, tuteur, enseignant, administration | session_feedback, tendance_feedback_v | CONTRADICTOIRE | fr.i18n.json:2180 ("Les retours sont anonymes et agreges") ; 0032_tc_catalogue.sql:515-519,556-559 (administrateur lit les lignes brutes avec session_id) ; 0033_tc_vues_rpc.sql:247-261 (seuil de cinq lignes par groupe et question, pas par auteur distinct) | Dans un groupe d'un ou deux eleves (cas normal, ADR-004) la "tendance" est la reponse d'une personne ; voir CP-MOR-03 | P1 | backend, gouvernance | aucune tache existante trouvee |
| AUD-MOR-030 | Le feedback est livre par un parcours reel ; l'enfant ne repond qu'a des questions sans reproche | Eleve | CarteFeedbackSeance | PRÉSENT_MAIS_NON_ROUTÉ | lib/features/tc_flux_academique/carte_feedback_seance.dart ; port_feedback.dart:99-107 (UnimplementedError) ; deja note par AUD-ENS-064 | Tant que le parcours n'est pas monte, la contradiction AUD-MOR-029 n'est pas atteinte en production | P2 | frontend, backend | PR #21, #17 ; TC-Z-SUIVI |
| AUD-MOR-031 | Signalement : la note interne ne part jamais a la famille, le resume famille est une decision de l'administration (DM 359) | Enseignant, administration, famille | student_concern, concern_famille_v | IMPLÉMENTÉ_NON_PROUVÉ | 0032_tc_catalogue.sql:572-590 (deux colonnes et contrainte), 593-621 (aucune policy famille) ; 0033_tc_vues_rpc.sql:272-279 (vue sans internal_details). Aucun scenario SQL (grep supabase/tests) ; adaptateur client absent (voir AUD-ENS-065) | Chaine non raccordee ; regle serveur lue | P2 | backend | PR #21 (0059) |
| AUD-MOR-032 | Un resume destine au tuteur n'est pas lisible par l'enfant mineur (proportionnalite) | Eleve mineur, tuteur | concern_famille_v | CONTRADICTOIRE | 0033_tc_vues_rpc.sql:272-279 : condition est_du_foyer(student_id) ou student_id = auth.uid(), sans lire transmis_a ; 0032:584 (transmis_a distingue tuteur_du_mineur et eleve_adulte) ; supabase/functions/session-enfant/index.ts:76-81 (l'enfant a une session d'auth) | Un jeton d'enfant lit un resume ecrit pour son tuteur ; voir CP-MOR-04 | P1 | backend | aucune tache existante trouvee |
| AUD-MOR-033 | Le libelle du signalement est neutre ("Signaler un besoin"), les categories ne qualifient pas l'enfant | Enseignant | FeuilleSignalement | CONFORME_PARTIEL | fr.i18n.json:1965 (action "Signaler un besoin"), 2186-2192 (categories pedagogique, presence, technique, changement, autre) ; feuille_signalement.dart non monte (AUD-ENS-064) | Libelles conformes ; aucun test de lexique | P2 | frontend | aucune tache existante trouvee |
| AUD-MOR-034 | Un enseignant signale et ne tranche pas ; l'academie decide (distinction recommandation et decision) | Enseignant | RevueGroupePage | CONFORME_PROUVÉ | lib/features/revue_groupe/revue_groupe_page.dart:120-150 (aucun bouton de decision) ; assets/i18n/fr.i18n.json:1602 ; test/features/revue_groupe_test.dart:135 (test lu, non execute). Voir AUD-ENS-061 | - | - | frontend | ENS-08 |
| AUD-MOR-035 | La revue de classe n'affiche pas un vide rassurant quand sa source n'est pas branchee | Enseignant | anomaliesGroupeProvider | PRÉSENT_MAIS_NON_RACCORDÉ | Voir AUD-ENS-060 (liste constante vide, titre "Rien ne demande votre attention") | Le message affirme l'absence d'anomalie, ce qui est une affirmation sur des eleves non verifiee | P1 | frontend | CP-ENS-07 ; question 34 (decisions.md) |
| AUD-MOR-036 | Les anomalies qualite sur un enseignant (rapports manquants) sont lisibles par l'administration seule, avec un traitement et une note | Administration | QualitePage, controles_qualite | CONFORME_PARTIEL | 0024_qualite_pedagogique.sql:53-57 (lecture admin seulement), 61-90 (traitement reserve a l'administration) ; fr.i18n.json:546-570 | L'enseignant ne voit pas ce qui est consigne sur lui et ne peut pas repondre ; voir CP-MOR-09 | P2 | gouvernance, backend | aucune tache existante trouvee |
| AUD-MOR-037 | Le nom de famille de l'eleve n'arrive jamais chez l'enseignant (ADR-008) | Enseignant | teacher_roster_v | CONFORME_PROUVÉ | 0005_dashboards_affectation_regles.sql:699-720 (vue sans last_name) ; supabase/tests/scenarios_etape4.sql:802 (controle information_schema sur la colonne last_name, test lu, non execute) | - | - | backend | ADR-008 |
| AUD-MOR-038 | Le contrat annonce en clair l'enregistrement et la visite de controle avant signature | Enseignant | contrat.pointControle | CONFORME_PARTIEL | assets/i18n/fr.i18n.json:180-181 ; la veracite du premier point est contestee par AUD-ENS-005 | La visite de controle est annoncee ; la retention de 30 jours et le mot "enregistre" ne sont pas prouves | P1 | gouvernance | CTR-SAL-01 |
| AUD-MOR-039 | Chaque consultation d'une piece d'identite est inscrite au journal avec le nom de qui consulte, et l'ecran le dit | Administration | journalisation, DossiersPage | IMPLÉMENTÉ_NON_PROUVÉ | fr.i18n.json:347 ; 0004_inscription_kyc_appairage.sql:478 (lecture des pieces par fonction) ; le journal lui-meme est audite par AUD-IDS ; aucun scenario lu pour cette inscription | La promesse affichee est coherente avec les fonctions lues ; ecriture au journal a chaque lecture non demontree ici | P1 | backend | AUD-IDS (identite-securite.md) |
| AUD-MOR-040 | Les delais de conservation affiches sont ceux du serveur (7 jours de contestation, 12 mois du rapport, 30 jours d'audio) | Administration | conservationDonnees | CONFORME_PARTIEL | fr.i18n.json:624-627 : deux delais seulement (enregistrements, documents d'identite). Voir AUD-COM-015 | Aucun delai pour le rapport, la contestation ni les retours des eleves | P1 | backend, gouvernance | aucune tache existante trouvee |
| AUD-MOR-041 | La promesse "Vous recevrez une notification" est tenue par un canal reel (honnetete envers l'utilisateur) | Famille, enseignant en attente | attente.enVerification | CONTRADICTOIRE | assets/i18n/fr.i18n.json:109 ; 0001_fondations.sql:348-354 (device_tokens sans ecriture) ; grep device_tokens dans lib/ et supabase/functions : aucun resultat ; voir AUD-COM-025 | La phrase promet un envoi qu'aucun code ne realise ; la personne attend a tort ; voir CP-MOR-05 | P1 | frontend (texte), backend (canal) | PR #17 (B-09) ; etape D de l'onboarding |
| AUD-MOR-042 | "Nous vous previendrons" apres un refus d'horaire ou la formation d'un groupe n'est dit que si un envoi existe | Famille | parcours.refusEnregistre, etatGroupeEnFormationDetail | CONTRADICTOIRE | assets/i18n/fr.i18n.json:1023, 1036 ; lib/features/parcours_offres/parcours_offres_page.dart:672 ; 0043_offres_horaires_et_intentions.sql:379-416 (intention enregistree, aucun envoi) | Meme ecart que AUD-MOR-041 ; l'intention est reelle, le "nous vous previendrons" ne l'est pas | P1 | frontend, backend | PR #17 (B-09) |
| AUD-MOR-043 | Une notification ne porte aucun nom d'enfant ni motif sensible sur un ecran verrouille | Tous | notifications.params | BLOQUÉ_DÉPENDANCE | Absent de HEAD (AUD-COM-026). Branche origin/codex/backend-b09-notifications : 0063_notifications_privatives.sql:16-17 (params libre limite a 8192 octets, aucune regle de redaction) | Dependance reelle sur la fusion de la PR #17 ; critere d'acceptation a inscrire (CP-MOR-05) | P1 | backend (Codex) | PR #17 |
| AUD-MOR-044 | Les textes de l'interface enfant tutoient et ne reprochent rien (tu, "Ton cours a commence") | Eleve, interface enfant | accueil_eleve | CONFORME_PARTIEL | assets/i18n/fr.i18n.json:1195-1218 (tutoiement, aucune formule de reproche) ; test/features/accueil_eleve_test.dart non relu assertion par assertion | Aucun test de lexique transversal ; le vouvoiement de l'interface adulte est distinct de droit | P2 | frontend | aucune tache existante trouvee |
| AUD-MOR-045 | Une panne technique n'est pas imputee a l'utilisateur ("Ce n'est pas votre appareil") | Tous, salle | salle.refusConfiguration, refusReseau | CONFORME_PROUVÉ | assets/i18n/fr.i18n.json:51-58 ; test/features/salle_test.dart:745 (texte refusConfiguration asserte, test lu, non execute) | - | - | frontend | R3 |
| AUD-MOR-046 | Un etat de presence inconnu n'est jamais ecrit comme une absence (DM 324, 933) | Enseignant, tuteur | etat_presence, libelles | CONFORME_PARTIEL | assets/i18n/fr.i18n.json:97-98 ("Etat inconnu"), 1938-1946 ; salle_page.dart:1079-1084 (repli en "inconnu", invariant J3). Voir AUD-ENS-007 | Le libelle "Absence" sans nuance cote tuteur n'a pas ete verifie sur l'ecran de suivi | P2 | frontend | AUD-ENS-007 |
| AUD-MOR-047 | Les activites d'un controleur ne sont pas visibles pour les familles et enseignants dans la boite de notifications ni les exports | Controleur | evenements | IMPLÉMENTÉ_NON_PROUVÉ | Voir AUD-COM-012 ; la liste des six evenements de la PR #17 ne comporte pas de visite de controle | A inscrire comme critere d'acceptation du canal | P1 | backend | PR #17 |
| AUD-MOR-048 | Exports et annuaires : aucune liste nominative de mineurs hors mission (proportionnalite, DM 15.2) | Administration, controleur | ADM-03 Exports | BLOQUÉ_DÉPENDANCE | docs/HANDOFF.md:87-88, 2846-2858 (ADM-03 bloque par CTR-03 non tranche) | Aucun export nominatif n'existe sur HEAD ; la regle d'anonymat n'est pas ecrite | P1 | gouvernance | ADM-03 ; CTR-03 |
| AUD-MOR-049 | Le lexique d'evaluation reste hors des cles reservees aux familles tant que les trois formules ne sont pas livrees | Famille | fr.i18n.json | ABSENT | Aucun test sur les cles : test/i18n ne contient pas de liste de mots interdits (grep Echec dans test/ : zero resultat) | Aucun garde-fou automatique contre "Echec", "Refuse", "Mauvais" dans les cles lues par une famille ; voir CP-MOR-08 | P2 | frontend | aucune tache existante trouvee |
| AUD-MOR-050 | Les interdictions de style (tiret cadratin, symbole de section) tiennent dans les textes visibles | Tous | fr.i18n.json | CONFORME_PROUVÉ | grep du tiret cadratin et du symbole de section dans assets/i18n/fr.i18n.json : 0 occurrence ; dans lib/ hors strings_*.g.dart : 0 fichier | - | - | frontend | R3 |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Perimetre | Decision la plus recente applicable | Statut | Consequence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| CTR-MOR-01 | Specification G de l'observation tuteur (quota, annonce a l'enseignant, indicateur enfant, vue restreinte) : lib/features/tc_observation_ui, 0033:1255-1302 | Chemin utilise par le bouton "Assister" : accueil_famille_page.dart:180-182, assister_seance 0012:398-447 | Observation des cours par un tuteur | La specification G, plus recente et plus precise (docs/teaching-core/TC_CONTRACT_REQUEST_G.md), l'emporte sur l'ancien chemin de 0012 | Ouvert (code non aligne, bascule volontairement reportee en attente de 0037) | AUD-MOR-010 a 013 : aucune des quatre garanties n'atteint le chemin reel |
| CTR-MOR-02 | Document maitre 15.2 : prenom de l'eleve a verifier dans les fils de controle | Fiche CTR-01 et ADR-008 : prenom et identifiant seulement | Liste du controleur | Aucune decision plus recente trouvee | A_ARBITRER (voir CTR-COM-01 pour la mission) | AUD-MOR-021 reste a arbitrer |
| CTR-MOR-03 | fr.i18n.json:2180 : retours anonymes | 0032:556-559 : lecture brute par l'administration avec session_id | Feedback | Politique de feedback de TC_CONTRACT_REQUEST_H.md (seuil par defaut de 5) | Ouvert | L'affirmation d'anonymat est fausse pour les petits groupes (AUD-MOR-029) |
| CTR-MOR-04 | Document maitre 12.4 (trois formules publiques) | fr.i18n.json:657 ("Echec") | Libelles d'evaluation | Document maitre, 12/10 | Ouvert, deja suivi par CTR-ENS-02 | AUD-MOR-001 |
| CTR-MOR-05 | ADR-011 (ligne permanente "cours enregistre, visite de controle possible") | Absence de chaine d'enregistrement prouvee | Salle | A trancher par la direction | Ouvert, deja suivi par CTR-SAL-01 | AUD-MOR-018 |
| CTR-MOR-06 | Document maitre 15.2 (controleur : roster minimal d'une mission active) | 0014:888-925 (toutes les seances) | Controleur | Document maitre 15.2 | Ouvert, deja suivi par AUD-COM-009 et CTR-COM-01 | AUD-MOR-022 |
| CTR-MOR-07 | 0032:584 (transmis_a distingue le tuteur de l'eleve adulte) | 0033:272-279 (la vue ignore transmis_a et ouvre au mineur) | Signalement | 0032, qui porte l'intention de ciblage | Ouvert (defaut de projection) | AUD-MOR-032 |

## 4. Devoir de regard - contre-propositions

Les contre-propositions sont numerotees CP-MOR-NN. Aucune ne transforme une recommandation en decision metier : le champ 14 dit qui tranche.

### CP-MOR-01 - L'observation du tuteur doit passer par la porte qui porte ses limites

1. Identifiant : CP-MOR-01.
2. Source : accueil_famille_page.dart:180-182 ; entete_classe.dart:190-206 ; 0012:398-447 ; 0033:1000-1075, 1255-1302.
3. Constat : le bouton "Assister" appelle assister_seance, qui ne consomme aucun quota (budget_observation ne compte que guardian_session_visit), n'alimente aucune annonce a l'enseignant et ne montre aucun indicateur a l'enfant ; la vue restreinte de VueObservationTuteur n'est montee que sur /tc/observation, vers laquelle aucun fichier ne navigue.
4. Risque : proportionnalite et dignite (un enseignant observe sans le savoir, un enfant regarde sans indicateur), cohesion institutionnelle (la politique configuree par groupe n'agit pas).
5. Gravite et priorite : moyenne a haute, vraisemblance elevee (chemin actif), P1.
6. Regle actuelle : specification G, section 11 (quota, annonce discrete, indicateur de l'enfant, aucun roster complet) ; ADR-011 pour la transparence generale.
7. Contre-proposition : remplacer l'appel du bouton par entrer_observation et le panneau de /tc/observation ; seule la migration 0037 (rendre enfant_profile_id) manque. Tant que 0037 n'est pas appliquee, ne pas rouvrir assister_seance silencieusement mais afficher un etat "observation non activee" plutot que le chemin sans limite.
8. Options : (a) basculer apres application de 0037 (recommandee) ; (b) durcir assister_seance pour qu'il ecrive guardian_session_visit et verifie la politique, ce qui evite de toucher a l'ecran.
9. Consequences : le tuteur voit moins (deux participants), son temps est plafonne ; les familles habituees a "Assister" perdent un acces illimite, a communiquer.
10. Perimetre : frontend (bascule), backend (0037, eventuellement durcissement), contrat partage (TC_CONTRACT_REQUEST_G).
11. Dependances : migration 0037 non appliquee (docs/HANDOFF.md, entete_classe.dart:197-205) ; AUD-MOR-010 a 013.
12. Criteres d'acceptation : un tuteur ne peut entrer qu'une fois par defaut et pas plus de la duree du budget ; l'enseignant lit "Tuteur de X observe" ; l'enfant lit "Ton tuteur regarde le cours" ; aucun autre enfant n'est rendu.
13. Tests et preuves : scenario SQL (deuxieme entree refusee, annonces_observation non vide) ; test de widget du bouton Assister qui verifie le chemin ; capture du build reel.
14. Decision requise : validation technique competente (ordre de bascule) ; aucune decision metier, la regle est tranchee.

### CP-MOR-02 - Limiter la souscription du jeton d'un observateur

1. Identifiant : CP-MOR-02.
2. Source : 0033:1776 ; 0010:373 ; salle_page.dart:796-806.
3. Constat : can_subscribe vaut true pour tout role ; la limite "deux participants" n'existe que dans une classe Dart.
4. Risque : confidentialite des mineurs et des enseignants si allow_multi_participant_sessions passe a true (reglage modifiable dans Admin > Fonctionnalites, fr.i18n.json:610-613).
5. Gravite et priorite : haute si le reglage est ouvert, aujourd'hui moyenne (reglage a false, 0001:956) ; P1.
6. Regle actuelle : specification G 11.2 (aucun roster complet).
7. Contre-proposition : appliquer cote serveur de salle (permissions de souscription par participant, ou jeton sans abonnement automatique et abonnement explicite a la piste de l'enseignant et de l'enfant concerne) ; interdire d'activer le multi-participants tant que cette limite n'existe pas.
8. Options : (a) permissions de souscription cote LiveKit (precis) ; (b) verrouiller le reglage multi-participants par une contrainte (plus simple, moins complet).
9. Consequences : travail backend sur la fonction d'emission de jeton et sur la Edge Function ; aucun changement visuel.
10. Perimetre : backend, contrat partage.
11. Dependances : CP-MOR-01 ; supabase/functions/create-room-token.
12. Criteres d'acceptation : un jeton guardian_observer ne recoit que deux pistes ; un test de salle avec trois eleves le prouve.
13. Tests et preuves : test d'integration LiveKit (hors portee de cet audit) ; scenario SQL sur les capacites emises.
14. Decision requise : validation technique competente.

### CP-MOR-03 - Rendre le feedback reellement anonyme ou retirer la promesse

1. Identifiant : CP-MOR-03.
2. Source : fr.i18n.json:2180 ; 0032:515-519,556-559 ; 0033:247-261.
3. Constat : l'administration lit les lignes brutes (session_id, reponse) ; le seuil de cinq compte des lignes, pas des auteurs distincts ; en groupe d'un eleve, la tendance et le nombre par reponse sont la reponse d'une seule personne ; la vue se rafraichit, ce qui permet de lire chaque nouveau vote par difference.
4. Risque : confidentialite et dignite de l'enfant, equite envers l'enseignant (un jugement sur un seul avis), fiabilite de l'affirmation affichee.
5. Gravite et priorite : moyenne, P1 (le parcours n'est pas monte, AUD-MOR-030, donc pas d'exposition immediate).
6. Regle actuelle : "anonymes et agreges, jamais seuls a une decision" (fr.i18n.json:2180) ; seuil par defaut de 5.
7. Contre-proposition : compter les auteurs distincts (empreintes) et exiger un minimum d'auteurs, pas de lignes ; ne publier qu'apres une periode (par semaine) pour interdire la lecture par difference ; supprimer la lecture brute par l'administration ou la restreindre a un role audite ; sinon changer la phrase.
8. Options : (a) corriger la vue ; (b) renoncer au feedback pour les groupes en dessous d'un effectif ; (c) reformuler la phrase sans promettre l'anonymat.
9. Consequences : les groupes d'un eleve ne donnent plus de tendance, ce qui est le bon resultat ; la vue gagne un count(distinct auteur_empreinte).
10. Perimetre : backend, gouvernance (effectif minimal), frontend (phrase).
11. Dependances : PR #21 et #17 (RPC de feedback) ; AUD-MOR-029 et 030.
12. Criteres d'acceptation : aucune tendance affichee sous le nombre d'auteurs distincts fixe ; aucun resultat en direct par difference ; la lecture brute est auditee.
13. Tests et preuves : scenario SQL (quatre votes d'un auteur : vue vide ; cinq auteurs : vue servie).
14. Decision requise : arbitrage du directeur sur l'effectif minimal et sur la lecture brute par l'administration.

### CP-MOR-04 - Ne pas ouvrir au mineur le resume destine a son tuteur

1. Identifiant : CP-MOR-04.
2. Source : 0033:272-279 ; 0032:584.
3. Constat : concern_famille_v accepte student_id = auth.uid() sans lire transmis_a ; les enfants disposent d'une session d'auth (session-enfant/index.ts:76-81).
4. Risque : dignite (un enfant lit un message pedagogique adresse a son tuteur), cohesion avec le mode enfant.
5. Gravite et priorite : moyenne, P1 (aucun consommateur Dart, vue non raccordee).
6. Regle actuelle : transmis_a distingue tuteur_du_mineur et eleve_adulte (0032:584).
7. Contre-proposition : dans la vue, ouvrir la ligne a l'eleve seulement si transmis_a = 'eleve_adulte' et si l'eleve est adulte ; au tuteur du foyer si transmis_a = 'tuteur_du_mineur'.
8. Options : aucune pertinente.
9. Consequences : correction d'une vue, sans effet sur l'interface.
10. Perimetre : backend.
11. Dependances : PR #21 (0059).
12. Criteres d'acceptation : un jeton d'enfant mineur ne lit aucune ligne ; un tuteur du foyer lit la sienne ; un eleve adulte lit la sienne.
13. Tests et preuves : scenario SQL dedie (aucun n'existe).
14. Decision requise : validation technique competente.

### CP-MOR-05 - Ne promettre une notification que si un canal existe

1. Identifiant : CP-MOR-05.
2. Source : fr.i18n.json:109, 1023, 1036 ; 0001:348-354.
3. Constat : trois textes promettent "vous recevrez une notification" ou "nous vous previendrons" sans canal d'envoi.
4. Risque : confiance et honnetete envers les familles, qui attendent en vain (cas du dossier en verification, ou la personne ne revient pas).
5. Gravite et priorite : moyenne, vraisemblance certaine ; P1.
6. Regle actuelle : REG-35 section 5 (ne pas annoncer ce qui n'est pas prouve) ; document maitre 16.2.
7. Contre-proposition : tant que B-09 n'est pas fusionnee, reformuler : "Revenez voir cette page : votre dossier y sera mis a jour", sans promesse d'envoi ; a la livraison du canal, ajouter le critere d'acceptation "aucun nom d'enfant ni motif dans le texte de notification verrouille" (AUD-COM-028, AUD-MOR-043).
8. Options : attendre le canal (la phrase ne change pas) ou changer la phrase maintenant.
9. Consequences : changement de trois cles de texte et regeneration slang ; aucun backend.
10. Perimetre : frontend (texte), backend (canal, PR #17).
11. Dependances : PR #17 ; AUD-COM-025, 026.
12. Criteres d'acceptation : chaque phrase de promesse a un envoi reel ou disparait.
13. Tests et preuves : test de cles i18n (liste de phrases de promesse reliees a un drapeau de canal).
14. Decision requise : aucune pour le texte ; la direction fixe la date du canal.

### CP-MOR-06 - Encadrer le motif de refus de dossier

1. Identifiant : CP-MOR-06.
2. Source : attente_page.dart:174-198 ; 0004:553 ; fr.i18n.json:346.
3. Constat : le motif est un texte libre non borne, affiche tel quel a la famille en couleur d'alerte.
4. Risque : dignite (accusation possible sans relecture), securite des donnees (le motif peut citer des donnees d'identite), coherence entre administrateurs.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : un refus exige un motif en une phrase (0004:537-541).
7. Contre-proposition : une liste courte de motifs types (piece illisible, piece expiree, nom different du compte) avec complement libre limite en longueur et un avertissement a l'administrateur ; le serveur garde le motif exige.
8. Options : conserver le libre avec seulement une borne de longueur.
9. Consequences : texte uniforme, plus de traductibilite ; un cout d'ecran dans ADM-02.
10. Perimetre : gouvernance (liste), frontend, backend (colonne de code de motif).
11. Dependances : ADM-02.
12. Criteres d'acceptation : le portail d'attente affiche une phrase issue d'un code ; aucune chaine libre de plus de 140 caracteres.
13. Tests et preuves : test dossiers_admin etendu ; scenario SQL sur la contrainte.
14. Decision requise : arbitrage du directeur sur la liste de motifs.

### CP-MOR-07 - Fixer la regle d'identite des mineurs dans les ecrans du controleur

1. Identifiant : CP-MOR-07.
2. Source : 0014:888-925 ; fr.i18n.json:1624 ; document maitre 15.2.
3. Constat : la liste montre prenom de l'eleve et identifiant a un controleur qui voit toutes les seances.
4. Risque : proportionnalite (le controle ne necessite pas l'identite d'un mineur), cohesion institutionnelle (ADR-008 autorise le prenom pour d'autres roles).
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : A_ARBITRER (CTR-MOR-02 ; AUD-COM-013).
7. Contre-proposition : par defaut, rendre l'identifiant immuable seul au controleur, et le prenom seulement apres entree en observation sur sa mission ; la direction peut choisir de garder le prenom.
8. Options : prenom conserve (statu quo) ; identifiant seul (recommande) ; initiales.
9. Consequences : une colonne de moins dans le planning ; test planning_controleur_test.dart a adapter.
10. Perimetre : backend (vue), frontend (colonne).
11. Dependances : CP-MOR-09 (mission) ; AUD-COM-009.
12. Criteres d'acceptation : la regle choisie est ecrite dans decisions.md et verifiee par un scenario SQL.
13. Tests et preuves : scenarios_ctr01.sql etendu.
14. Decision requise : arbitrage du directeur.

### CP-MOR-08 - Garde-fou de lexique pour les cles lues par une famille

1. Identifiant : CP-MOR-08.
2. Source : fr.i18n.json:657 ; AUD-ENS-077 ; AUD-VCX-022.
3. Constat : aucun test n'empeche l'arrivee de "Echec" ou de formules de reproche dans une cle montree a une famille.
4. Risque : coherence morale a long terme (le defaut revient au premier ecran famille d'evaluation).
5. Gravite et priorite : faible a moyenne, P2.
6. Regle actuelle : DM 412 (trois formules publiques) ; document maitre 25.3 (non conforme visuellement et UX).
7. Contre-proposition : un test sur assets/i18n/fr.i18n.json qui echoue si une cle sous les espaces famille, eleve ou tuteur contient une liste de mots a valider (echec, mauvais, nul, faible) ; completee par la liste des trois formules publiques comme seules valeurs admises pour une decision.
8. Options : relecture editoriale a la place.
9. Consequences : faux positifs possibles, liste maintenue par la direction pedagogique.
10. Perimetre : frontend, contenu academique (liste).
11. Dependances : CP-ENS-04.
12. Criteres d'acceptation : le test echoue sur "Echec" dans une cle famille et passe sur les trois formules.
13. Tests et preuves : test/i18n.
14. Decision requise : validation du contenu academique (liste de mots).

### CP-MOR-09 - Droit de reponse de l'enseignant et perimetre de mission du controleur

1. Identifiant : CP-MOR-09.
2. Source : AUD-COM-009, 014, 016 ; AUD-MOR-022, 024, 036 ; 0024:53-57.
3. Constat : le controleur voit toutes les seances ; aucun rapport n'est stocke ; l'enseignant ne lit pas ce que l'administration consigne sur lui (anomalies qualite) et ne peut pas repondre ; le delai de contestation de 7 jours n'a aucun support.
4. Risque : equite institutionnelle envers l'enseignant, dignite professionnelle, fiabilite des decisions de l'administration.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : document maitre 15.3 (contestation 7 jours apres la synthese mensuelle).
7. Contre-proposition : (a) introduire une mission (table, affectation) bornant la liste du controleur ; (b) donner a l'enseignant une lecture de ce qui est consigne sur lui, avec reponse datee ; (c) distinguer par le libelle un constat automatique ("rapport manquant") d'une appreciation humaine.
8. Options : ne livrer que (a) en MVP-0 et reporter (b) et (c) avec CTR-03.
9. Consequences : un modele de donnees et trois ecrans ; plus de transparence a l'enseignant.
10. Perimetre : backend, frontend, gouvernance.
11. Dependances : CTR-03, ADM-03 (docs/HANDOFF.md:2846-2858).
12. Criteres d'acceptation : un controleur ne lit que les seances de sa mission ; l'enseignant lit et conteste dans les 7 jours.
13. Tests et preuves : scenarios SQL de mission ; test de parcours enseignant.
14. Decision requise : arbitrage du directeur (perimetre MVP-0 ou V1).

## 5. Etats d'ecran et applicabilite

Legende : P present, A absent, NA non applicable (justifie).

| Surface | Chargement | Contenu | Vide | Erreur | Hors ligne | Session expiree | Acces refuse | Reprise |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ADM-12 Evaluations (evaluations_page.dart) | P (squelette lu) | P | P (fr.i18n.json:634-637) | P (ligne 633 "erreur") | A (non demontre) | NA (routeur) | P (redirection admin, redirection.dart) | A |
| Portail d'attente, dossier refuse (attente_page.dart) | P | P | NA | P | A | P (routeur) | P | P ("Reprendre mon dossier") |
| Observation tuteur /tc/observation | P | P | P (enfantAbsent, fr.i18n.json:2079) | P (refus et fin, lignes 2062-2092) | A (aucun etat hors ligne dedie) | A | P (refus, ligne 2063) | A |
| Annonce enseignant et indicateur enfant | NA (flux) | P | P (liste vide) | NA (flux silencieux) | A | A | NA | A |
| Planning du controleur | P | P | P | P | A (voir AUD-COM-018) | A | P | P (relecture a la minute) |
| Feedback et signalement (tc_flux_academique) | A (ports non implementes) | P (composants) | A | P (fr.i18n.json:2201) | A | A | A | A |
| Feedback tendance (revue enseignant) | A | P (sousSeuil) | P (ligne 2179) | A | A | A | A | A |

Applicabilite : la distinction recommandation, observation, validation et decision est tenue sur la revue de classe (AUD-MOR-034) et sur le signalement (champs separes, AUD-MOR-031) ; elle n'est pas encore tenue sur l'evaluation (AUD-MOR-005) ni sur la liste de la revue (AUD-MOR-035). Aucune surface eleve ou tuteur ne montre de resultat d'evaluation (AUD-ENS-074 : ABSENT), donc aucune exposition d'un echec d'enfant n'existe aujourd'hui, ce qui est un etat de fait et non une garantie.

## 6. Non verifie et limites de la preuve

- Aucun test n'a ete execute (Flutter et Dart absents). Tous les tests cites sont lus par nom et assertion.
- Les migrations 0035 a 0037 sont notees non appliquees en base (docs/HANDOFF.md ; entete_classe.dart:197-205) : l'etat reel de la base distante n'a pas ete lu (appel MCP interdit).
- Le contenu des quatre documents de specification d'evaluation du 12/10 et de la specification G du Teaching Core n'a ete lu que par ses extraits dans le depot (TC_CONTRACT_REQUEST_H.md lignes 39, 89, 118) ; les formules publiques exactes et le seuil par groupe sont repris du document maitre.
- La Edge Function create-room-token a ete lue par ses lignes de capacites seulement ; la regle effective de souscription cote serveur LiveKit n'a pas ete lue. L'ecart AUD-MOR-014 repose sur la valeur can_subscribe emise.
- Le comportement de assister_seance relie a budget_observation repose sur la lecture des deux fonctions et sur le commentaire de entete_classe.dart:190-197 ; il n'a pas ete rejoue sur une base.
- Les PR draft #21 et #17 ont ete lues par noms de fichiers et pour la migration 0063 de notifications seulement.
- Les etats "hors ligne" et "session expiree" des ecrans de la section 5 sont notes absents ou non demontres faute de recherche dediee sur chaque ecran.
- Les messages de l'interface arabe (assets/i18n/ar.i18n.json, 32 lignes) n'ont pas ete audites : couverture trop courte pour une conclusion.
