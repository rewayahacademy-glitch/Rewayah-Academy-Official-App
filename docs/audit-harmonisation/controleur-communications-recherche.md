# Registre de conformite - Controleur, Communications et Studio, notifications, Recherche transverse

- SHA code audite : 4a7aa2b (le HEAD de travail ff01c087 n'ajoute que des fichiers sous docs/audit-harmonisation)
- Date : 14/10/2026
- Auditeur : agent Claude (Sonnet 5.5), lecture seule, aucun test execute (Flutter et Dart absents de l'environnement)
- Domaine : COM (Controleur, Communications et Studio, notifications, Recherche transverse)

## 1. Perimetre, sources lues, sources introuvables

Sources lues :
- Document maitre, lignes 500-552 (lots G12 et G13), 779-830 (statuts et definitions d'ecart), 948-971 (recherche transversale).
- Prompt de mission (devoir de regard A, B, G).
- Depot : CLAUDE.md racine, docs/design/08-catalogue-ecrans.md (fiche CTR-01, lignes 53, 56, 2244-2356), docs/architecture/decisions.md (ADR-011, ligne 334), docs/HANDOFF.md par grep cible (lignes 424-454, 1939-1960, 2260-2270, 2630-2690, 3534-3545), docs/PROGRESS.md par grep.
- Code : lib/features/controleur/planning_page.dart et vue_planning.dart, lib/core/controle/service_controle.dart, lib/core/video/service_video.dart:120-130, lib/core/router/{app_router,routes,redirection}.dart, lib/features/compte/compte_page.dart:299-315, lib/core/preferences/preferences_locales.dart, lib/core/tc_bibliotheque/recherche_catalogue.dart, lib/core/tc_coran/corpus_service_coran.dart:100-230, lib/core/tc_observation/port_annonce_observation.dart.
- SQL : supabase/migrations/0001 (device_tokens, rls), 0012_observation_controleur.sql, 0014_acces_agent.sql:888-925 (mes_seances_v), 0025, supabase/config.toml:303-322 (MFA), supabase/tests/scenarios_ctr01.sql (en-tete).
- Tests lus sans execution : test/features/planning_controleur_test.dart, test/controle/vue_planning_test.dart, test/router/redirection_test.dart (nom seulement), test/teaching_core/q/q04_capacites_admin_controleur_test.dart (nom seulement).
- Branche non fusionnee ui/controleur-v1 (commit 39a702ae), lue via get_file_contents : liste du dossier lib/features/controleur, garde_controle.dart, mission_controle.dart. Les autres fichiers de cette branche ne sont pas lus.
- PR draft #17 (F2 support) : liste des fichiers et patch des migrations 0059_canal_support.sql et 0060_notifications_privatives.sql lus. #21 (F2) : liste des fichiers seulement.

Sources introuvables :
- RECH-01 et RECH-02 : aucun fichier de ce nom dans docs/, lib/, supabase/, ni dans les documents fournis. Leur contenu n'est pas reconstitue. Les 22 menaces SEC-R01 a SEC-R22 et les 14 recettes REC-01 a REC-14 ne sont donc pas verifiables.
- COM-BR-01..16 (messagerie metier) : aucune occurrence dans le depot.
- Decision du 02/10 sur la retention de 12 mois du rapport brut : aucune occurrence dans le depot (grep "12 mois", "rapport brut").
- Decision du directeur du 27/09/2026 (jamais un planning) : citee seulement dans le commentaire de mission_controle.dart sur la branche ui/controleur-v1.
- Fichiers 14_controleur/CT-BR.md, doc 08 P-CTR-xx de la branche ui : non lus.

## 2. Registre par exigence

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-COM-001 | Le module Controleur existe et a une racine unique sans barre de navigation (doc maitre 15.1 ; ADR-011) | Controleur, arrivee apres connexion | /controleur, PlanningControleurPage | CONFORME_PROUVÉ | lib/core/router/routes.dart:159,352,363 ; lib/core/router/app_router.dart:372-374 ; test/router/redirection_test.dart:48 (test lu, non execute) | - | - | frontend | CTR-01 (docs/design/08-catalogue-ecrans.md:53) |
| AUD-COM-002 | Shell Controle, Historique, Echanges, Compte (doc maitre 15.1) | Controleur | Pages controle_page, historique_controleur_page, echanges_controleur_page sur la branche ui/controleur-v1 | ABSENT | HEAD : lib/features/controleur ne contient que planning_page.dart et vue_planning.dart. Branche ui/controleur-v1 (39a702ae) : liste du dossier lue, fichiers hors garde_controle et mission_controle non lus | Absent de HEAD. Existe sur une branche non fusionnee. Etat de raccordement de cette branche non demontre | P1 | frontend (fusion), backend pour les donnees | aucune tache existante trouvee (la branche est citee par le document maitre seulement) |
| AUD-COM-003 | Carte de mission avec "Commencer le controle" seulement si une seance est reellement ouverte, pas de planning global (doc maitre 15.1) | Controleur | HEAD : planning global ; branche ui : MissionControle | CONTRADICTOIRE | HEAD : lib/features/controleur/planning_page.dart:152 (planningGlobalProvider) ; lib/core/controle/service_controle.dart:47-58 (toutes les seances, plafond 200). Branche ui : mission_controle.dart, fournisseur neutre qui rend null | Voir CTR-COM-01 | P1 | gouvernance puis frontend | aucune tache existante trouvee |
| AUD-COM-004 | Entree en observation : role controller, compte valide, fenetre debut a fin plus 15 minutes, seance non close, pas partie prenante, acces journalise | Controleur, bouton Observer | RPC rejoindre_observation(uuid) ; ServiceVideo.observerEnControle | CONFORME_PROUVÉ | supabase/migrations/0012_observation_controleur.sql:299-378 ; lib/core/video/service_video.dart:125-128 ; supabase/tests/scenarios_ctr01.sql (fichier lu en en-tete, non execute ici, rejoue par la CI selon CLAUDE.md) | - | - | backend | CTR-01 |
| AUD-COM-005 | Le bouton d'entree n'est pose que sur une seance en cours ; ailleurs aucun bouton grise | Controleur | PlanningControleurPage, VuePlanning | CONFORME_PROUVÉ | test/features/planning_controleur_test.dart:99-127 (le cours en direct porte le bouton, pas celui qui arrive) ; test/controle/vue_planning_test.dart:52-91 ; barriere serveur 0012:299-378 | - | - | frontend | CTR-01 |
| AUD-COM-006 | Entrer puis ouvrir la salle, billet par extra et jamais par l'URL ; refus sans ouverture de salle | Controleur | planning_page.dart _observer, Routes.salle, BilletSalle | CONFORME_PROUVÉ | lib/features/controleur/planning_page.dart:110-139 ; test/features/planning_controleur_test.dart:128-172 (assertions video.observations, billet, message de refus lues) | - | - | frontend | CTR-01 |
| AUD-COM-007 | Invisibilite sur toutes les surfaces : le controleur n'apparait ni dans les pairs, ni dans les participants, ni dans les evenements, sauf pour l'administration | Controleur, enseignant, tuteur | session_peers_v, policies session_participants, session_events | CONFORME_PROUVÉ | supabase/migrations/0012_observation_controleur.sql:132-165 (vue et policies filtrent masked_controller) ; supabase/tests/scenarios_ctr01.sql (controles de lecture, non executes ici) | - | - | backend | CTR-01 |
| AUD-COM-008 | MFA obligatoire pour le controleur (doc maitre 15.2) | Controleur, connexion | auth.mfa.totp, controle aal2 | ABSENT | supabase/config.toml:310-312 (enroll_enabled = false, verify_enabled = false). Aucune occurrence de aal2 ni de mfa dans lib/ ni dans supabase/migrations (grep). rejoindre_observation ne teste pas le niveau d'assurance (0012:299-378) | Aucun controle MFA cote serveur ni cote application. docs/PROGRESS.md:167 note que les options TOTP ont ete remises a false | P0 | backend (reglage Auth, garde RPC), gouvernance pour le niveau exige | aucune tache existante trouvee (PROGRESS.md:167 signale seulement le reglage ecrase) |
| AUD-COM-009 | Acces limite au roster minimal et au perimetre d'une mission active (doc maitre 15.2) | Controleur | mes_seances_v ; rejoindre_observation | CONTRADICTOIRE | supabase/migrations/0014_acces_agent.sql:888-925 (la vue rend toutes les seances au role controller) ; 0012:299-378 (aucune notion de mission, toute seance dans la fenetre est ouvrable) | Aucune table de mission ni attribution de mission au controleur. Voir CTR-COM-01 | P1 | backend (modele de mission), gouvernance | aucune tache existante trouvee |
| AUD-COM-010 | Le controleur ne recoit ni contenu KYC ni finances | Controleur | policies sur kyc_documents, wallets | IMPLÉMENTÉ_NON_PROUVÉ | Aucune policy lue ouvrant ces tables au role controller dans 0012 ni dans 0014:888-925. Lecture exhaustive des policies de 0001 non faite pour ces deux tables | Non demontre : verification des policies kyc et finance a faire | P1 | backend | aucune tache existante trouvee |
| AUD-COM-011 | Le controleur ne publie ni micro ni camera en observation | Controleur, salle | jeton video, drapeau hidden | CONFORME_PARTIEL | supabase/migrations/0012_observation_controleur.sql:1-60 (en-tete : autoriser_jeton_video deduit hidden de masked_controller depuis 0010) ; test/teaching_core/q/q04_capacites_admin_controleur_test.dart:58 (le controleur est incognito, test lu par nom) | Les droits de publication du jeton LiveKit n'ont pas ete lus dans 0010 ni dans la fonction d'emission | P1 | backend | N2, CTR-01 |
| AUD-COM-012 | Identite du controleur non divulguee aux familles et enseignants (annonces de presence, notifications, exports) | Enseignant, tuteur | port_annonce_observation ; vues de presence | CONFORME_PARTIEL | lib/core/tc_observation/port_annonce_observation.dart:11-40 (le tuteur observateur n'est pas nomme, mais cela ne couvre pas le controleur) ; 0012:132-165 (pairs et participants) | Notifications et exports : canal absent (AUD-COM-025) ; politique d'export de visite non lue. Non demontre | P1 | backend, gouvernance | aucune tache existante trouvee |
| AUD-COM-013 | Identite des eleves et enseignants visible au controleur limitee par le contrat (pas de prenom d'eleve si le contrat l'interdit, doc maitre 15.2) | Controleur, liste CTR-01 | mes_seances_v, colonnes affichees | À_ARBITRER | supabase/migrations/0014_acces_agent.sql:888-925 (student_first_name, student_immutable_id, teacher_first_name) ; lib/features/controleur/planning_page.dart (colonnes "prenom + identifiant", ADR-008 : prenom seulement, jamais de nom de famille) | Le document maitre demande de verifier si le contrat interdit le prenom de l'eleve. La fiche CTR-01 et ADR-008 l'autorisent. Decision a prendre | P1 | gouvernance | aucune tache existante trouvee |
| AUD-COM-014 | Rapport brut reserve a son auteur et a l'administration habilitee (doc maitre 15.2) | Controleur, administrateur | Table de rapport de controle | ABSENT | Aucune table de rapport de controle dans supabase/migrations (grep "create table" : controles_qualite concerne les anomalies pedagogiques, 0024:25). Branche ui : compte_rendu_controle_page.dart existe, non lue | Pas de stockage serveur du rapport. CTR-03 non tranche (docs/HANDOFF.md:3538 ; docs/design/08-catalogue-ecrans.md:2349) | P1 | backend, gouvernance | CTR-03 (docs/HANDOFF.md:2674-2683, perimetre MVP-0 ou V1 non tranche) |
| AUD-COM-015 | Retention du rapport brut : 12 mois apres envoi, prolongee si un dossier est ouvert (decision du 02/10) | Controleur, administrateur | Parametre de conservation | ABSENT | lib/features/admin_configuration_conservation_donnees/ : deux delais seulement (enregistrements, ligne 19). Aucune occurrence de la decision du 02/10 dans le depot | Aucun parametre de retention du rapport. Decision source introuvable | P1 | backend, gouvernance | aucune tache existante trouvee |
| AUD-COM-016 | Contestation ouverte 7 jours apres publication de la synthese mensuelle | Controleur, enseignant | Workflow de contestation | ABSENT | Aucune occurrence de "contestation" dans lib/ ni supabase/ (grep) | Workflow non present | P2 | backend, gouvernance | aucune tache existante trouvee |
| AUD-COM-017 | Mission non assignee, expiree ou annulee ; appareil sans MFA ; session suspendue (recette 15.4) | Controleur | etats de mission | PRÉSENT_MAIS_NON_RACCORDÉ | Branche ui : mission_controle.dart (EtatMissionControle.indisponible ; fournisseur neutre qui rend null), garde_controle.dart (AccesControle.refuse). HEAD : aucun equivalent | La branche porte l'etat sans source serveur. Session suspendue : app_account_valid() dans rejoindre_observation (0012:299-310) est la seule barriere prouvee | P1 | frontend, backend | aucune tache existante trouvee |
| AUD-COM-018 | Etat chargement, vide, erreur du planning ; relecture automatique toutes les minutes | Controleur | PlanningControleurPage | CONFORME_PROUVÉ | lib/features/controleur/planning_page.dart:79-107,260-330 ; test/features/planning_controleur_test.dart:222-318 (vide, erreur avec reessai, squelette) | Etat hors ligne dedie absent (voir section 5) | - | frontend | CTR-01 |
| AUD-COM-019 | Rappel permanent de la journalisation de la visite (ADR-011) | Controleur | AppCard visiteJournalisee | CONFORME_PROUVÉ | lib/features/controleur/planning_page.dart:227-234 ; test/features/planning_controleur_test.dart:173-190 | - | - | frontend | CTR-01 |
| AUD-COM-020 | Recherche dans ses seuls rapports ; export administrateur uniquement ; echange sur un cas ; rapport hors ligne en brouillon ; envoi idempotent (recette 15.4) | Controleur, administrateur | Historique, Echanges, compte rendu | ABSENT | HEAD : aucun code. Branche ui/controleur-v1 : fichiers presents (echanges_controleur_page.dart, compte_rendu_controle_page.dart), contenu non lu | Rien de raccorde cote serveur. Le signalement d'incident a l'admin est explicitement non construit (docs/design/08-catalogue-ecrans.md:2352) | P1 | frontend, backend | CTR-03 |
| AUD-COM-021 | Les donnees de mineurs restent cloisonnees jusque dans les erreurs | Controleur | message d'erreur d'entree | CONFORME_PROUVÉ | lib/features/controleur/planning_page.dart:117-127 (le refus ne se detaille pas) ; test/features/planning_controleur_test.dart:151-172 | - | - | frontend | CTR-01 |
| AUD-COM-022 | Messagerie metier : fils rattaches a des objets metier, paires d'acteurs autorisees, vocaux et pieces, annonces, communaute d'enseignants, Studio (doc maitre 16.1, COM-BR-01..16) | Tous roles | Messagerie et Studio | ABSENT | Recherche faite : lib/, supabase/migrations (aucune table message ou thread), docs/. Aucune table, route ni ecran. docs/HANDOFF.md:2672 classe la messagerie contextuelle hors MVP-0. PR draft #17 et #21 : listes de fichiers sans table de messages | Module entier absent de HEAD et des PR lues. COM-BR-01..16 introuvables | P2 | gouvernance (perimetre), backend, frontend | aucune tache existante trouvee (HANDOFF.md:2672 mentionne le report) |
| AUD-COM-023 | Les etats envoye, recu, lu ne valent pas preuve d'un changement de Classe, de paiement ou de decision academique | Tous roles | Messagerie | NON_APPLICABLE_JUSTIFIÉ | Messagerie absente (AUD-COM-022) : regle sans objet tant que le module n'existe pas | A reprendre dans la fiche du module | - | gouvernance | - |
| AUD-COM-024 | Retention des communications : 60 jours maximum pour certains contenus, a verifier contre la politique finale | Gouvernance | Politique de conservation | À_ARBITRER | Document maitre 16.1 ; aucune politique de communication dans le depot | Politique finale non trouvee. Ne pas appliquer 60 jours a tous les journaux | P2 | gouvernance | aucune tache existante trouvee |
| AUD-COM-025 | Canal de notification reel (push ou courriel) pour KYC valide, affectation, fin de seance (doc maitre 16.2) | Tuteur, enseignant | device_tokens ; envoi | ABSENT | supabase/migrations/0001_fondations.sql:348-354 (table), 385 (RLS activee), 1190-1191 (revoke anon) : aucune policy ni ecriture. grep device_tokens dans lib/ et supabase/functions : aucun resultat. docs/HANDOFF.md:2637-2639 : canal non livre ; docs/design/08-catalogue-ecrans.md:2466 | Aucun enregistrement d'appareil ni envoi. PR draft #17 ajoute une boite append-only (voir ligne suivante) mais pas de push | P1 | backend (canal), frontend (enregistrement) | Etape D de l'onboarding (docs/HANDOFF.md:2262) ; B-09 notifications (PR #17) |
| AUD-COM-026 | Boite de notifications serveur : destinataire isole, evenements types, lien canonique, lu non lu | Tuteur, enseignant | table notifications, marquer_notification_lue | BLOQUÉ_DÉPENDANCE | HEAD : aucune table notifications (grep "create table", migrations 0001 a 0043). PR draft #17, migration 0060_notifications_privatives.sql : table avec RLS destinataire = auth.uid(), 6 evenements, 2 destinations, params limites a 8192 octets | Absent de HEAD, present dans la PR draft #17 non fusionnee. La dependance (fusion de #17) est reelle. Les evenements du doc maitre 16.2 (T-20, evaluation, compte rendu, solde, mission de controle) ne figurent pas dans les 6 evenements de la PR | P1 | backend (Codex) | PR #17, scenarios_b09_notifications.sql dans la PR |
| AUD-COM-027 | Une notification contient objet, contexte, destinataire autorise, etat confirme, lien canonique et version ; permissions revalidees a l'ouverture | Tous roles | notifications.destination | IMPLÉMENTÉ_NON_PROUVÉ | PR #17 0060 : destination bornee par contrainte check a deux routes ; colonne de version absente ; revalidation a l'ouverture non demontree (aucun ecran de boite sur HEAD) | Pas de colonne version ni d'objet type. Absent de HEAD | P1 | backend, frontend | PR #17 |
| AUD-COM-028 | Pas de nom ni de motif sensible sur l'ecran verrouille ; une notification perdue ne casse pas la machine metier | Tous roles | Contenu de notification | NON_APPLICABLE_JUSTIFIÉ | Aucun envoi push sur HEAD (AUD-COM-025) ; la regle s'appliquera a l'implementation du canal. PR #17 0060 : les params sont un objet libre, aucune regle de redaction | A inscrire comme critere d'acceptation du canal | - | backend, gouvernance | aucune tache existante trouvee |
| AUD-COM-029 | Preferences de notification de l'utilisateur | Tuteur, enseignant | Compte, preferencesLocales | PRÉSENT_MAIS_NON_RACCORDÉ | lib/features/compte/compte_page.dart:299-315 (deux interrupteurs) ; lib/core/preferences/preferences_locales.dart:30-31,46-49 (booleens locaux, vrai par defaut) | Les interrupteurs n'agissent sur aucun canal, aucune preference n'est envoyee au serveur | P2 | frontend, backend | aucune tache existante trouvee |
| AUD-COM-030 | Canal de support minimal configure par l'administration | Tous roles, admin | canal_support, configurer_canal_support | BLOQUÉ_DÉPENDANCE | HEAD : aucune fonction canal_support (grep). PR draft #17 : migration 0059_canal_support.sql (admin actif seulement pour ecrire, lien https ou courriel valide) | Absent de HEAD. Fusion de #17 requise | P2 | backend (Codex) | PR #17 (B-10), scenarios_b10_support.sql dans la PR |
| AUD-COM-031 | Recherche commune : surface unique contextualisee, pas de nouvel onglet permanent, une fonction canonique rechercherApp vers rechercherDomaine | Tous roles | rechercherApp, rechercherDomaine | ABSENT | grep rechercherApp et rechercherDomaine dans lib/, supabase/, docs/ : aucun resultat. RECH-01 et RECH-02 introuvables | Aucun contrat de recherche transversale. Recherches par module existantes seulement (lignes suivantes) | P1 | gouvernance (contrat), backend, frontend | aucune tache existante trouvee |
| AUD-COM-032 | Un resultat ouvre une route canonique typee sans ecriture ; la destination re-autorise l'acces | Tous roles | Resultat de recherche | ABSENT | Aucun type de resultat transversal. Seul type local : ResultatRechercheCoran (lib/core/tc_coran/corpus_service_coran.dart:118-212), navigue vers une page du Mushaf | Sans objet tant que AUD-COM-031 est absent | P1 | frontend, contrat partage | aucune tache existante trouvee |
| AUD-COM-033 | Recherche du catalogue de ressources dans le module Bibliotheque | Eleve, tuteur, enseignant | RechercheCatalogue.chercher, catalogue_local | CONFORME_PARTIEL | lib/core/tc_bibliotheque/recherche_catalogue.dart:13-130 (fonctions pures, normalisation d'accents par table) ; lib/core/tc_bibliotheque/catalogue_local.dart:75-80 ; vue_catalogue.dart:169-214 | Recherche cote client sur des ressources deja chargees ; la liste chargee est bornee par la RLS du catalogue (non relue ici). Pas de pg_trgm, pas de curseur. Normalisation limitee au francais (pas d'arabe vocalise, translitteration) | P2 | frontend, contenu | TC-x catalogue (docs/teaching-core, non relu) |
| AUD-COM-034 | Recherche Coran : reference, juz, page, nom de sourate ; recherche textuelle separee du texte canonique | Eleve, enseignant | CorpusServiceCoran.rechercher | CONFORME_PARTIEL | lib/core/tc_coran/corpus_service_coran.dart:102-230 (plafond de 12 resultats ligne 224 ; commentaire lignes 193-197 : index texte existe en base, jamais interroge) ; supabase/migrations/0030_tc_socle.sql (texte_recherche, non relu en detail) | Recherche textuelle du Coran non raccordee ; voir REC sur vocalise et non vocalise non demontre | P2 | frontend, backend | N6, TC (docs/teaching-core/TC_AGENT_C_REPORT.md, non relu) |
| AUD-COM-035 | Aucun corps de message indexe ; recherche de message dans son module ; aucun compteur de resultats masques ; pas d'annuaire de matricules RA ; egalite exacte pour RA et EV | Tous roles | Index de recherche | NON_APPLICABLE_JUSTIFIÉ | Aucun index ni RPC de recherche de personnes ou de messages sur HEAD (grep ilike : aucune recherche generalisee dans lib/ ni migrations ; les "like" trouves en 0035-0037 sont des tests de source de fonction). A inscrire en critere d'acceptation | - | backend, contrat partage | aucune tache existante trouvee |
| AUD-COM-036 | La recherche n'interrompt pas la session LiveKit ; ouvrir un resultat documentaire ne le partage pas aux eleves | Enseignant, salle | Selecteur de bibliotheque en classe | CONFORME_PARTIEL | lib/features/tc_catalogue/class_library_picker.dart et surface_bibliotheque.dart presents (recherche en classe, filtres) ; partage aux eleves et lien avec la salle non relus | Non demontre : absence de coupure LiveKit et de partage automatique non lue | P2 | frontend | N6 (canal du document partage non tranche, docs/HANDOFF.md:2689) |
| AUD-COM-037 | Pas de SELECT etoile, pas de scan non borne depuis le client, pas de ILIKE generalise | Tous roles | Lectures Supabase | CONFORME_PARTIEL | lib/core/controle/service_controle.dart:52-57 : .select() sans liste de colonnes sur la vue mes_seances_v, filtre sur ended_at, limite 200. Aucun ilike dans lib/ | Le select() sans colonnes est un select etoile sur une vue de 12 colonnes dont des identifiants d'eleves | P2 | frontend | aucune tache existante trouvee |
| AUD-COM-038 | Tests de recherche : foyers A et B, remplacement expire, curseur croise, FR, EN, Poular, arabe, XSS SQL, panne d'un domaine | Qualite | Tests | ABSENT | Aucun test de recherche transversale dans test/. Tests existants limites a la recherche locale du catalogue et du Coran | Sans objet tant que le contrat de recherche n'existe pas | P2 | frontend, backend | aucune tache existante trouvee |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Perimetre | Decision la plus recente applicable | Statut | Consequence |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| CTR-COM-01 | Document maitre 15.1 et commentaire de lib/features/controleur/mission_controle.dart sur la branche ui/controleur-v1 : pas de planning global, une carte de mission, decision du directeur du 27/09/2026 | ADR-011 (docs/architecture/decisions.md:334, "Consulter le planning global") et fiche CTR-01 (docs/design/08-catalogue-ecrans.md:53, construit le 13/09) ; code HEAD planning_page.dart:152 | Accueil du controleur | La decision du 27/09/2026 est plus recente que le 13/09, mais n'est lisible que dans un commentaire de code sur une branche. ADR-011 n'est pas formellement remplace dans decisions.md | ouvert | HEAD expose toutes les seances du jour a tout controleur. Il faut un ADR de remplacement ou de maintien avant toute reecriture |
| CTR-COM-02 | docs/HANDOFF.md:2674-2683 et :3538 : CTR-03 et ADM-03 reportes en V1 | docs/historique/couverture-specs.md (cite par HANDOFF.md:3538) les place au MVP-0 | Rapport du controleur et exports | Aucune ; a trancher par l'operateur (HANDOFF.md:2683 point 2) | ouvert | Les lignes AUD-COM-014 a 016 et 020 restent sans perimetre |
| CTR-COM-03 | Document maitre 15.2 : controleur limite a un roster minimal et a une mission active | Code HEAD : mes_seances_v rend toutes les seances aux controleurs ; rejoindre_observation sans mission | Perimetre d'acces | La regle du document maitre n'est pas encore une decision d'architecture ; ADR-011 dit "Voir et entendre toute seance en cours" | ouvert | Soit ADR-011 est amende, soit une table de mission est requise (backend) |
| CTR-COM-04 | docs/design/08-catalogue-ecrans.md:2352 : le signalement d'incident figure dans le tableau peut/ne peut pas d'ADR-011 mais n'est pas construit | Document maitre 15.4 : "echange sur un cas" | Echanges du controleur | Aucune | ouvert | Echange et signalement sans canal ni table |

## 4. Devoir de regard - contre-propositions

Les trois situations sont distinguees dans le champ "Source". Aucune regle religieuse ou scientifique n'est touchee.

### CP-COM-01 - Exiger un second facteur pour le controleur
1. Identifiant : CP-COM-01.
2. Source : document maitre 15.2 (MFA obligatoire) ; ADR-011.
3. Constat : decision tranchee, implementation absente. supabase/config.toml:310-312 laisse TOTP desactive ; rejoindre_observation (0012:299-310) ne teste que le role et la validite du compte.
4. Risque : un mot de passe compromis suffit a observer en secret des mineurs.
5. Gravite et priorite : haute, P0 (lettre A).
6. Regle actuelle : role controller et compte valide.
7. Contre-proposition : refuser rejoindre_observation si le jeton n'est pas de niveau aal2, activer TOTP dans la configuration Auth, afficher un ecran d'enrolement avant l'acces a /controleur.
8. Options : TOTP (support natif Supabase) ; WebAuthn ; exception temporaire journalisee pour la recette.
9. Consequences : le plan Supabase doit autoriser MFA (config.toml:303 le dit reserve au plan Pro) ; recette a quatre comptes a ajuster.
10. Perimetre : backend (config, RPC), frontend (enrolement), gouvernance (niveau exige).
11. Dependances : choix du plan Supabase, PR #22 SEC-PROD a relire pour recouvrement.
12. Criteres d'acceptation : un controleur en aal1 recoit un refus de la RPC ; un controleur en aal2 entre.
13. Tests : scenario SQL avec deux niveaux de jeton ; test Flutter du refus.
14. Decision requise : operateur, niveau MFA et calendrier.

### CP-COM-02 - Borner l'acces du controleur a une mission
1. Identifiant : CP-COM-02.
2. Source : contradiction reelle entre sources actives (CTR-COM-01 et CTR-COM-03).
3. Constat : mes_seances_v (0014:888-925) rend toutes les seances au role controller, avec prenoms et identifiants d'eleves ; planning_page.dart:152 les affiche toutes.
4. Risque : surveillance sans mission, volume de donnees de mineurs expose a un compte unique.
5. Gravite et priorite : haute, P1.
6. Regle actuelle : toute seance en cours, journalisee.
7. Contre-proposition : si la decision du 27/09 est confirmee, introduire une attribution de mission cote serveur, restreindre la vue et la RPC a cette attribution, et remplacer le planning par la carte de mission de la branche ui/controleur-v1.
8. Options : maintenir ADR-011 tel quel (aucun changement) ; mission attribuee par l'admin ; mission tiree au sort par le serveur.
9. Consequences : la detection de surveillance abusive d'ADR-011 (visites repetees) reste valable.
10. Perimetre : gouvernance, backend, frontend.
11. Dependances : AUD-COM-002, ADR de remplacement.
12. Criteres d'acceptation : un controleur sans mission recoit un refus serveur ; un controleur avec mission ne voit que cette seance.
13. Tests : scenarios SQL sur deux controleurs, test de la carte de mission.
14. Decision requise : operateur, choix entre les options et ADR.

### CP-COM-03 - Minimiser les identites dans la liste du controleur
1. Identifiant : CP-COM-03.
2. Source : decision tranchee, risque nouveau (document maitre 15.2).
3. Constat : la colonne affiche prenom et identifiant immuable de l'eleve (planning_page.dart, tests lignes 26-27 de planning_controleur_test.dart).
4. Risque : divulgation du prenom d'un mineur a un role de supervision.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : ADR-008, prenom seulement.
7. Contre-proposition : n'afficher que l'identifiant immuable ou un compteur d'eleves, comme la carte de mission de la branche ui.
8. Options : identifiant seul ; prenom conserve avec justification ecrite.
9. Consequences : lisibilite moindre pour le controleur.
10. Perimetre : contrat partage (vue), frontend.
11. Dependances : CP-COM-02.
12. Criteres d'acceptation : la vue ne contient plus student_first_name pour le role controller.
13. Tests : SQL de colonnes, widget.
14. Decision requise : operateur.

### CP-COM-04 - Rapport de controle et retention
1. Identifiant : CP-COM-04.
2. Source : decision du 02/10 (12 mois), citee par le document maitre 15.3, introuvable dans le depot.
3. Constat : aucune table de rapport, aucun parametre de retention (AUD-COM-014, 015).
4. Risque : donnees de controle conservees sans duree ou perdues.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : aucune.
7. Contre-proposition : ecrire la decision dans decisions.md avec sa source, puis ajouter un parametre de conservation lu depuis le serveur, affichant la date effective.
8. Options : parametre dans app_config ; colonne de purge par rapport.
9. Consequences : conformite legale a valider.
10. Perimetre : gouvernance, backend, frontend.
11. Dependances : CTR-COM-02 (perimetre CTR-03).
12. Criteres d'acceptation : la date affichee vient du serveur.
13. Tests : SQL de purge.
14. Decision requise : operateur et conseil juridique.

### CP-COM-05 - Notifications sans fuite
1. Identifiant : CP-COM-05.
2. Source : decision tranchee, risque nouveau (document maitre 16.2).
3. Constat : la PR #17 (0060) accepte params jsonb libres jusqu'a 8192 octets sans regle de redaction ; HEAD n'a aucun canal.
4. Risque : un parametre contenant un nom d'enfant parvient a l'ecran verrouille.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : aucune.
7. Contre-proposition : liste blanche de cles de params par evenement, gabarit de texte d'ecran verrouille sans nom, colonne de version, lien canonique revalide a l'ouverture.
8. Options : texte generique sur l'ecran verrouille ; contenu detaille apres deverrouillage.
9. Consequences : gabarits a rediger en francais et en arabe.
10. Perimetre : backend, frontend, contenu.
11. Dependances : fusion de PR #17.
12. Criteres d'acceptation : aucune notification ne contient de prenom dans le gabarit verrouille.
13. Tests : scenarios_b09 etendu.
14. Decision requise : operateur sur le gabarit.

### CP-COM-06 - Cadrer la recherche transversale avant tout code
1. Identifiant : CP-COM-06.
2. Source : decision tranchee (document maitre 29), sources RECH-01 et RECH-02 absentes.
3. Constat : aucun contrat rechercherApp, aucune route de resultat typee, aucun test (AUD-COM-031, 032, 038).
4. Risque : une recherche improvisee par module ferait fuir des champs non autorises.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : recherches locales par module.
7. Contre-proposition : retrouver ou reecrire RECH-01 et RECH-02, definir un contrat par domaine avec champs lisibles seulement, curseur lie a l'appelant, puis un ADR avant ecran.
8. Options : ne livrer que les recherches par module ; livrer la surface commune par etapes (Bibliotheque puis Classes).
9. Consequences : la barre globale n'est pas un onglet.
10. Perimetre : contrat partage, backend, frontend, gouvernance.
11. Dependances : sources RECH.
12. Criteres d'acceptation : SEC-R01 a R22 et REC-01 a REC-14 deroulees.
13. Tests : voir 16.5 du document maitre.
14. Decision requise : operateur, retrouver les sources.

## 5. Etats d'ecran et applicabilite

| Etat | CTR-01 sur HEAD | Autres surfaces du domaine |
| :-- | :-- | :-- |
| Chargement | Present (Skeleton.liste, planning_page.dart:77) | Messagerie, notifications, recherche transversale : non applicables, modules absents |
| Contenu | Present | idem |
| Vide | Present, deux variantes (vide, vide sous filtre) | idem |
| Erreur | Present avec reessai (planning_page.dart:66-71) | idem |
| Hors ligne | Absent en tant qu'etat dedie : une erreur reseau tombe dans l'etat erreur | idem |
| Session expiree | Non demontre ici (gere par la redirection globale, non relue) | idem |
| Acces refuse | Refus d'entree en salle present (planning_page.dart:121-126). Garde d'acces perdue : seulement sur la branche ui/controleur-v1 (garde_controle.dart) | idem |
| Reprise | Relecture chaque minute (planning_page.dart:91-99) ; reprise apres perte reseau pendant une observation non demontree | idem |

## 6. Non verifie et limites de la preuve

- Aucun test execute : Flutter, Dart et Postgres de test absents. Les mentions "test lu" ne valent pas execution.
- scenarios_ctr01.sql lu en en-tete seulement, ses controles C1 et suivants ne sont pas relus un par un.
- Policies sur kyc_documents et tables financieres : non relues pour l'exclusion du controleur.
- Droits de publication du jeton LiveKit : 0010 non relue.
- Branche ui/controleur-v1 : seuls garde_controle.dart et mission_controle.dart lus ; le reste, y compris les donnees de demonstration, non lu.
- PR draft : #17 (fichiers et deux migrations) lue ; #21, #29, #31 et autres non lues pour ce domaine. PR #35 et ses documents de pedagogie non lus.
- RECH-01, RECH-02, COM-BR-01..16, SEC-R01..R22, REC-01..REC-14 : introuvables, couverture non evaluee, pas de conclusion d'absence sur leur contenu.
- Migrations 0044 a 0058 non relues pour la presence d'une table de messages ou de notifications ; seule la liste des tables creees (grep) a ete consultee, ce qui ne couvre que les fichiers presents dans supabase/migrations.
- Tout chiffre de performance (p95, debounce) est un objectif non mesure.
