# Registre de conformité - Élève enfant (Interface guidée), élève adulte, tuteur et foyer

- SHA audité : 4a7aa2b (branche claude/nice-darwin-hael93, commit du 22/09/2026, identique à origin/main)
- Date de l'audit : 14/10/2026
- Auditeur : agent d'audit en lecture seule (Claude Sonnet 5.5), aucun fichier du dépôt modifié hors ce registre
- Domaine : ELV, élève enfant (Interface guidée), élève adulte, tuteur et foyer
- Devoir de regard appliqué : lettres A (sécurité et protection des personnes), B (fiabilité fonctionnelle), G (cohérence morale et institutionnelle), H (cohérence visuelle et expérience)

Conventions de lecture. Toutes les preuves sont des lectures du dépôt à HEAD 4a7aa2b, sauf mention "hors HEAD". Aucun test n'a été exécuté (Flutter, Dart et Postgres absents de l'environnement) : tout test cité est "lu, non exécuté". Une fuite ou une faille est établie par la lecture de la policy, de la vue ou de la RPC serveur, jamais par un rejeu avec un jeton réel. Abréviations : DM = document maître (REWAYAH_DOCUMENT_MAITRE_ULTIME_AUDIT_CONFORMITE_2026-10-14.md, numéros de ligne du fichier fourni) ; Mission = prompt d'audit d'harmonisation du 14/10/2026 ; ccr = branche ccr-1b1bfa0b-m1kvkk (base des PR Codex, non fusionnée) ; PR n = pull request draft numéro n. Un statut ABSENT signifie "absent à HEAD 4a7aa2b", jamais "absent du produit" : la branche ccr et la PR 3 contiennent des dossiers de la verticale Tuteur et foyer qui n'existent pas à HEAD. Aucune RÉGRESSION n'est établie : sans historique de build ni test exécuté, aucune capacité "auparavant fonctionnelle" n'est démontrée cassée.

## 1. Périmètre, sources lues, sources introuvables

### 1.1 Périmètre

Interface guidée (élève enfant), élève standard et adulte autonome, tuteur, foyer, second adulte, observation par le tuteur, abonnement et solde, appairage des appareils, compte et préférences. Écrans de départ de la mission : lib/features/{accueil_eleve, accueil_famille, reglages_enfant, suivi_eleve, suivi_foyer, compte, eleve_connexion, appareils, cahier}. Le dossier cahier est l'écran ENS-04 de l'enseignant : côté famille il n'a aucun consommateur à HEAD (voir AUD-ELV-074 et AUD-ELV-075).

### 1.2 Sources lues

Fournies avec la mission :
- Mission, lignes 146 à 380 (devoir de regard A à H, format de contre-proposition, harmonisation).
- DM lignes 238 à 313 (G04, G05, G06), 779 à 1065 (statuts, hiérarchie, non-régression, réconciliation, recherche, Teaching Core, design), 920 à 937 (rôles, profils, observation). Lectures ciblées : DM 163 et DM 393 à 396.

Dans le dépôt, à HEAD :
- CLAUDE.md racine, lib/CLAUDE.md, supabase/CLAUDE.md (reçus en contexte).
- docs/PROGRESS.md lignes 1 à 80 et grep ; docs/HANDOFF.md par grep ciblé (Assister, suivi élève, mode enfant, B-07, B-08, DB-FOY) et lignes 1886 à 1895, 2116 à 2130. Jamais lu en entier.
- docs/architecture/decisions.md : ADR-009 (lignes 267 à 317) et liste des titres d'ADR.
- docs/design/08-catalogue-ecrans.md : tableau des écrans (lignes 30 à 110), fiche ELV-02 (lignes 305 à 393), grep des fiches TUT-02 ; docs/design/02-regles-ux.md par grep (destructif). docs/design/README.md non lu en détail.
- docs/produit/parcours-utilisateurs.md lignes 150 à 200 et grep.
- docs/teaching-core/TC_AGENT_A_REPORT.md lignes 330 à 350.
- Code : lib/features/accueil_eleve, accueil_famille, reglages_enfant, suivi_eleve, suivi_foyer, compte, eleve_connexion, appareils lus intégralement ou presque ; cahier (en-tête de cahier_page.dart) ; lib/core/router (app_router, routes, redirection), lib/core/widgets/nav_shell.dart, lib/core/session, lib/core/appairage, lib/core/planning, lib/core/suivi, lib/core/preferences, lib/core/theme (métriques, cibles), lib/core/tc_groupe/port_groupes.dart et début de demonstration_groupes.dart, lib/core/tc_observation (extraits), lib/core/tc_parcours/port_travail_a_venir.dart, lib/features/tc_observation_ui/indicateur_observation.dart, lib/features/tc_classe_live/entete_classe.dart (lignes 185 à 213), lib/features/tc_mes_groupes et tc_espace_groupe (extraits), lib/main.dart, lib/app.dart, assets/i18n/fr.i18n.json (clés des domaines).
- SQL : supabase/migrations 0001, 0004, 0005, 0011, 0012, 0014, 0025, 0030, 0033, 0036, 0038, 0043 et LISEZ-MOI-0035-0037-non-appliquees.md ; supabase/tests scenarios_etape3, etape4, n2, n4, ctr01 (grep et plages).
- Tests Dart : noms et assertions de test/features/{accueil_eleve, accueil_famille, suivi_eleve, suivi_foyer, reglages_enfant, compte, appareils, eleve_connexion}_test.dart, test/router/{navigation, redirection}_test.dart, test/suivi/vue_suivi_foyer_test.dart, test/accessibilite/rtl_echelle_texte_ecrans_test.dart, test/appairage/code_local_test.dart, test/teaching_core/q/q09_interface_guidee_cibles_test.dart. Tous lus, non exécutés.
- Registres voisins (lecture ciblée) : docs/audit-harmonisation/identite-securite.md (AUD-IDS-058, 059, 061, 069) et offres-classes-calendrier.md (AUD-OFR-021, 066).

Hors HEAD, en lecture seule via get_file_contents :
- ccr : liste de lib/features, de docs/current et de docs/current/captures ; docs/current/00_LIRE_D_ABORD.md et 01_PRODUIT_ET_PARCOURS.md ; lib/core/widgets/nav_shell.dart (listes de destinations).
- PR 29 : liste des fichiers, migrations 0052, 0053, 0054. PR 3 (ui/tuteur-v1, base main) : liste partielle des fichiers, lib/core/capacites/port_acces_foyer.dart, lib/core/foyer/selection_eleve.dart.

### 1.3 Sources introuvables ou non lues

- Maquettes du Tuteur citées par le DM (Accueil, Profil, Foyer Member, Historique, Classe Details) : aucune image dans le dépôt à HEAD (recherche des png, jpg, svg, webp, pdf : seul web/favicon.png existe). Sur ccr, docs/current/captures contient des dossiers du type AR-FAMILLE-1, AR-SUIVI-FAMILLE, AR-ELEVE-1, AR-ADULTE-1, non lus. La conformité visuelle à ces maquettes est donc "non démontrée".
- docs/current/ (00_LIRE_D_ABORD à 09, DECISION-IMMATRICULATION, REVUE-DIRECTEUR-2026-10) : absent de HEAD ; seuls 00_LIRE_D_ABORD.md et 01_PRODUIT_ET_PARCOURS.md ont été lus sur ccr. COHABITATION.md : non repéré.
- REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md, REFERENTIEL_ACADEMIQUE_V1, RECH-02 et sources de recherche : hors périmètre de ce domaine, non lus.
- Branches des PR 13, 17, 21 et contenu de la PR 3 au-delà des deux fichiers cités : non lus. Les migrations 0039 à 0042 n'existent pas à HEAD (numérotation 0038 puis 0043).

## 2. Registre par exigence

Colonnes : ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, HEAD 4a7aa2b) | Écart minimal | Priorité | Responsable | Tâche existante.

### 2.1 Interface guidée : modèle, terminologie, autorité

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-001 | Le libellé visible "Interface guidée" remplace "mode enfant" (DM 242, 926 ; docs/current/00_LIRE_D_ABORD.md sur ccr, "Contradictions résolues") | Tuteur, élève, admin ; Compte, Réglages par enfant, Règles | compte_page.dart (ProfilsComptePage, ProfilEnfantPage) ; reglages_enfant_page.dart (_CarteEnfant) ; regles_page.dart | CONTRADICTOIRE | assets/i18n/fr.i18n.json:1161-1162 ("Mode enfant", "Mode standard") rendus par compte_page.dart:547-548 et :590-593 ; fr.i18n.json:1309-1312 ("Grand affichage", "Affichage courant") ; fr.i18n.json:592-593 ("interface enfant", "interface simplifiée") ; seul libellé conforme : tc.classe.fiche.interfaceGuidee, fr.i18n.json:1957 ; 18 fichiers Dart (commentaires, non visibles) et 25 documents du dépôt hors archives écrivent encore "mode enfant" | Quatre vocabulaires pour une notion. Choisir un libellé unique pour les trois familles de clés ; le contraire d'Interface guidée n'est nommé dans aucune source lue | P1 | frontend ; gouvernance (nom du contraire) | Aucune tâche existante trouvée ; décision D-07 citée dans lib/features/tc_classe_live/fiche_seance.dart:139 et lib/core/tc_classe/teacher_student_projection.dart:198 |
| AUD-ELV-002 | L'Interface guidée est une présentation du même produit : ni second système de droits, ni autre arborescence (DM 242, 926) | Élève, tous parcours | app_router.dart:193-227 ; nav_shell.dart:49-78 ; redirection.dart:114-115 | CONFORME_PROUVÉ | Une seule StatefulShellRoute élève ; destinationsPour(role, mode) ne change que la liste affichée (nav_shell.dart:54-78) ; le préfixe se décide par rôle, jamais par mode (redirection.dart:114-115) ; aucune policy RLS ne lit interface_mode (grep supabase/migrations : colonnes, vues, 0005:976 pour sessions.session_type, sans effet de droit) ; tests lus : test/router/navigation_test.dart:8-14, test/router/redirection_test.dart:436 ("une seule arborescence pour les deux modes") | - | - | frontend | ADR-009 |
| AUD-ELV-003 | Un adulte peut choisir l'Interface guidée (DM 242, 926) | Adulte, Compte et Réglages | ReglagesComptePage ; student_profiles.interface_mode | ABSENT | compte_page.dart:195-340 : aucune option d'affichage guidé ; seul le tuteur bascule un enfant (reglages_enfant_page.dart:276-283) ; cohortes_age.adulte_18_plus fixe 'standard' (0043:113) ; enregistrer_profil_apprentissage réécrit interface_mode depuis la cohorte (0043:628-635) ; l'adulte n'a pas de ligne student_profiles à HEAD (seul INSERT : 0004:892, student_type 'minor') ; PR 29 migration 0052 (B-07) crée le profil titulaire en 'standard' | Commande "Interface guidée" dans les réglages personnels, écrite par une RPC qui valide l'autorité (soi-même pour un adulte autonome) | P1 | frontend ; backend | B-07 (PR 29) ; aucune tâche à HEAD |
| AUD-ELV-004 | L'Interface guidée est proposée par défaut aux mineurs selon la politique effective ; ne pas imposer une frontière d'âge issue d'une ancienne configuration (DM 242) | Tuteur, ajout d'enfant et onboarding | creer_profil_enfant ; cohortes_age ; app_config child_ui_mode_max_age | CONTRADICTOIRE | creer_profil_enfant lit child_ui_mode_max_age, défaut 8 (0004:869 ; 0001:959 "à trancher") ; 0043:108-113 écrit en dur cinq cohortes (5-10 ans 'child', 11 ans et plus 'standard') et commente "valait 10 le 22 septembre 2026" ; deux sources pour une frontière ; l'onboarding écrase le réglage posé par le tuteur (0043:628-635) | Une source unique de frontière ; ne pas écraser silencieusement un réglage du tuteur ; valeur effective à confirmer | P1 | backend ; gouvernance | Aucune tâche existante trouvée (voir CTR-ELV-08) |
| AUD-ELV-005 | L'enfant ne peut pas activer une interface standard en contournant le serveur, ni changer ses droits (DM 254) | Élève (jeton de l'appareil enfant) | PostgREST student_profiles ; policy student_profiles_family_update | CONTRADICTOIRE | 0005:535-552 : la policy ne teste ni le rôle guardian ni la capacité, seulement le foyer ; 0005:563-564 : GRANT UPDATE (interface_mode, camera_policy, avatar_storage_key) à authenticated ; 0043:289-290 ajoute langue_cours, cohorte, niveau_declare, objectif, onboarding_fait_le ; le hook de jeton pose role et household_id pour un élève (0001:489-490, 0038) ; l'appareil enfant reçoit une session pour le profil élève (lib/core/appairage/service_enfant.dart:58-93) ; test lu : supabase/tests/scenarios_etape4.sql:645-705 (S6a, S6b) n'essaie que le rôle guardian, aucun test avec un jeton student | Un jeton élève peut, sur le papier, réécrire son interface, sa politique caméra et celle de sa fratrie. Ajouter le rôle à using et with check ; non rejoué | P0 | backend | AUD-OFR-021 (même policy, angle cohorte) ; aucune tâche existante trouvée |
| AUD-ELV-006 | Les demandes de bascule de l'enfant utilisent l'autorité du tuteur ou du serveur, avec trace (DM 242) | Tuteur, Réglages par enfant | service_appairage.dart majReglages | CONFORME_PARTIEL | service_appairage.dart:262-283 : UPDATE direct de student_profiles, sans RPC ; aucun appel à log_sensitive_access pour un changement d'interface_mode ou camera_policy (grep supabase/migrations) ; le test reglages_enfant_test.dart:190 vérifie que seul le mode part | La bascule existe côté tuteur mais n'est ni tracée ni protégée contre un autre jeton (voir AUD-ELV-005) | P1 | backend ; frontend | Aucune tâche existante trouvée |

### 2.2 Accueil et parcours de l'élève (enfant et standard)

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-007 | L'accueil enfant n'affiche ni donnée financière, KYC, publicité, classement, calendrier professionnel ou nombre de sièges (DM 246) | Élève enfant, /eleve | AccueilElevePage | CONFORME_PROUVÉ | Route racine du rôle (routes.dart racinePour, redirection.dart:75-82) ; accueil_eleve_page.dart:218-228 ne rend que _BlocPrincipal et _BlocCoran ; tests lus : accueil_eleve_test.dart:386 ("quel que soit l'état, l'écran ne rend que deux blocs"), :416 | - | - | frontend | R1 (catalogue 08, fiche ELV-02) |
| AUD-ELV-008 | En premier, le Prochain cours dans ses états (DM 246) | Élève enfant et standard | _BlocPrincipal, etatAccueilEleve | CONFORME_PARTIEL | Six états prouvés par tests lus : accueil_eleve_test.dart:151-385 et :531-669 ; chaîne : seancesProvider (service_planning.dart:337) puis mes_seances_v (0014:888-920) ; la séance retenue n'est pas bornée à l'élève connecté (voir AUD-ELV-009) ; aucune relecture périodique : le minuteur de la page ne relit que l'horloge (accueil_eleve_page.dart:146-158), seancesProvider n'est invalidé que dans creneaux_page.dart:417 | Une annulation ou un nouveau cours posé après le chargement n'apparaît qu'à la relance | P1 | frontend | R1 |
| AUD-ELV-009 | Aucun nom d'autres élèves ni donnée d'un autre enfant dans les vues personnelles (DM 254) | Élève, foyer de plusieurs enfants | ELV-02 puis seancesProvider puis mes_seances_v | CONTRADICTOIRE | accueil_eleve_page.dart:166-188 et journee.dart:145-165 retiennent la première séance de la liste sans filtre sur le profil connecté ; mes_seances_v : clause "or (eleve.household_id = public.app_household_id())" sans test de rôle (0014:915-918) ; le jeton élève porte household_id (0001:489-490) ; le commentaire service_suivi.dart:25-28 affirme "sa seule séance" ; aucun test SQL avec un jeton élève sur cette vue (scenarios_etape4.sql:810-833 utilise le rôle guardian) | Un enfant d'un foyer à deux enfants peut recevoir la prochaine séance, le prénom de l'enseignant et le bouton Rejoindre de son frère ou de sa sœur. Non rejoué | P0 | backend ; frontend | Aucune tâche existante trouvée |
| AUD-ELV-010 | Un seul CTA dynamique : Voir ma Classe, Rejoindre, Reprendre, Voir le travail (DM 246) | Élève enfant | _CoursEnDirect | CONFORME_PARTIEL | Seul Rejoindre existe, rendu pendant le direct (accueil_eleve_page.dart:394-407) ; "Voir ma Classe", "Reprendre", "Voir le travail" : aucune occurrence dans lib/ ni fr.i18n.json (hors "Reprendre ta lecture" du lecteur du Coran, eleve.coran.reprendre) | Trois CTA sur quatre absents | P1 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-011 | Rejoindre reste plus évident que lire un historique (DM 250) | Élève | ELV-02, billet de salle | CONFORME_PARTIEL | Test lu accueil_eleve_test.dart:262 ; billet par extra (accueil_eleve_page.dart:396-403, redirection.dart:93-95) ; en Interface guidée aucune navigation donc aucun historique atteignable (navigation_test.dart:8-14) ; l'admission réelle en salle relève du registre salle | Entrée en salle non re-prouvée ici | P2 | frontend | R1 |
| AUD-ELV-012 | Hors ligne : Rejoindre inerte, état compréhensible (DM 1062, 32.3) | Élève | ELV-02, OfflineBanner | CONFORME_PROUVÉ | accueil_eleve_page.dart:394-430 (bouton inerte et pictogramme) ; PageShell rend OfflineBanner (page_shell.dart:119) ; tests lus : accueil_eleve_test.dart:351, :538 | - | - | frontend | R1 |
| AUD-ELV-013 | Une lecture en échec ne se présente pas comme "aucun cours" ; état erreur propre (DM 1062 ; lib/CLAUDE.md) | Élève | ELV-02 | ABSENT | accueil_eleve_page.dart:166-176 : seances.value ?? [] ; aucune occurrence de hasError ni de message d'erreur dans le fichier ; la page affiche alors "Pas de cours aujourd'hui" ; catalogue 08 fiche ELV-02 : "loading / error : pas d'état dédié, dette assumée" ; aucun test d'erreur dans accueil_eleve_test.dart (noms lus) | Faux vide présenté à un enfant, y compris pour un accès daté expiré (session_state.dart:163-170 ne lit pas access_until) | P1 | frontend | Dette déclarée dans catalogue 08, fiche ELV-02 ; aucune tâche de reprise trouvée |
| AUD-ELV-014 | Deux accès simples : Mon Coran / mes supports, et Ce que je prépare (DM 246) | Élève enfant | _BlocCoran | CONFORME_PARTIEL | _BlocCoran présent (accueil_eleve_page.dart:555-590, route /eleve/coran, app_router.dart:206-218) ; "mes supports" et "Ce que je prépare" absents ; la fiche ELV-02 et le test figent "deux blocs, rien d'autre" (accueil_eleve_test.dart:386 ; indicateur_observation.dart:119-122) | Le DM demande deux accès sous le CTA ; le catalogue en fige un seul. Arbitrer la structure | P1 | frontend ; gouvernance | Aucune tâche existante trouvée |
| AUD-ELV-015 | Pendant la séance : "Tu attends ton tour" / "C'est ton tour" si l'état est réellement servi (DM 250) | Élève enfant, salle | Classe Live, récitation | ABSENT | Aucune occurrence de "ton tour" dans fr.i18n.json ni lib/ ; mécanisme de file présent : lib/core/tc_classe/controleur_recitation.dart, libellés "{prenom} récite", "Récite" (fr.i18n.json, tc.classe.recitation) ; "Le professeur vous appelle" vouvoie (tc.classe.rappel.recu, marqué TC-Z-SUIVI dans lib/core/tc_classe/rappel_discret.dart:22) | Libellés enfant absents ; mécanisme non rejoué | P2 | frontend ; contrat partagé | TC-Z-SUIVI (marqueur dans le code, absent de PROGRESS et HANDOFF) |
| AUD-ELV-016 | Après séance : Travail à préparer et Ce que j'apprends, uniquement des objectifs validés ; Fait n'est pas Maîtrisé (DM 250, 941) | Élève, tuteur | Espace Groupe, PortTravailAVenir | PRÉSENT_MAIS_NON_RACCORDÉ | portTravailAVenirProvider vaut null par défaut (lib/core/tc_parcours/port_travail_a_venir.dart:154-155), jamais surchargé (grep lib/, main.dart:105-131) ; emplacement explicite (tc_espace_groupe/emplacements_groupe.dart:17-31 et :62-74) ; l'Espace Groupe lui-même tourne sur des données de démonstration (voir AUD-ELV-077) ; aucun écran "Ce que j'apprends" ; aucun bouton "Fait" (grep) | Travail et objectifs invisibles pour l'élève. Contrat Fait / Maîtrisé à écrire | P1 | frontend ; contrat partagé | lib/core/tc_parcours (lot H) ; docs/teaching-core/TC_AGENT_A_REPORT.md:343 |
| AUD-ELV-017 | Tutoiement, phrases courtes, icône et libellé parlé (DM 258) | Élève enfant | AudioLabel, ClesAudio | CONFORME_PARTIEL | Tutoiement et AudioLabel sur ELV-02 (fr.i18n.json, eleve.accueil ; accueil_eleve_page.dart:333, :380, :580) ; vouvoiement ailleurs : tc.classe.rappel.recu, eleve.suivi.videDetail ("Vos cours"), compte.* | Registre de langue non unifié pour un profil en Interface guidée ; couverture audio hors ELV-02 non vérifiée | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-018 | Cibles tactiles confortables, au moins 48 dp (DM 258, 1060) | Élève, tuteur | AppTouchTarget, Pressable | CONFORME_PARTIEL | lib/core/theme/app_spacing.dart:94-101 (72 en guidé, 48 en standard) ; app_metriques.dart:18-31 ; test lu test/teaching_core/q/q09_interface_guidee_cibles_test.dart:38-63 ; exceptions explicites respecterCibleTactile: false (accueil_famille_page.dart:497, eleve_connexion_page.dart:409) compensées par minHeight | Vérification par composant, pas par écran réel | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-019 | Agrandissement à 200 pour cent et RTL sans écrêtage (DM 258, 1059-1060) | Tous | ELV-01, ELV-02, TUT-01, TUT-02, TUT-05, TUT-06 | CONFORME_PARTIEL | Tests lus test/accessibilite/rtl_echelle_texte_ecrans_test.dart:161, 259, 291, 300, 310, 332, 350, 407 et groupes :651, :665 (rendu sans exception) ; suivi_eleve_test.dart:202 ; compte_test.dart:76, :129 ; l'interface n'a que le français (compte.arabe "Bientôt disponible") | Rendu réel, contraste mesuré et lecteur d'écran non démontrés | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-020 | Absence d'animations anxiogènes (DM 258) | Élève enfant | _Pulsation | CONFORME_PARTIEL | Pulsation douce du bloc imminent, échelle 1,02 (accueil_eleve_page.dart:599-650) ; remplacée par une bordure fixe sous mouvement réduit, test lu accueil_eleve_test.dart:208 | Qualifier "anxiogène" est un jugement à faire valider (direction) ; point non tranché ici | P2 | gouvernance | ADR-017 |

### 2.3 Élève adulte autonome

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-021 | Navigation canonique : Aujourd'hui, Apprendre, Suivi, Profil (DM 266) | Adulte autonome | nav_shell.dart destinationsPour | ABSENT | Barre élève : Accueil, Coran, Suivi, Compte (nav_shell.dart:58-76 ; navigation_test.dart:16-25) ; l'adulte inscrit en guardian reçoit la barre Tuteur (nav_shell.dart:79-100) ; hors HEAD : ccr contient accueil_adulte, mon_espace_adulte, ma_classe_adulte et une barre élève Accueil, Ma classe, Coran, Mon espace | Navigation adulte à créer ou à reprendre depuis ccr, sans copier celle du Tuteur | P1 | frontend | Aucune tâche existante trouvée à HEAD |
| AUD-ELV-022 | Pas d'obligation de se déclarer parent ; pas de faux tuteur ni foyer parental créé pour lui (DM 266, 922, 163) | Adulte apprenant, inscription | inscription_page.dart ; ADR-009 | À_ARBITRER | inscription_page.dart:35-41 (eleveAdulte vaut AppRole.guardian) ; decisions.md:267-300 (foyer d'une personne, tuteur de lui-même) ; l'adulte atterrit sur /tuteur "Aucun enfant dans le foyer, ajoutez votre premier enfant" (accueil_famille_page.dart:240-247, fr.i18n.json tuteur.accueil.aucunEnfant) ; PR 29 migration 0052 garde role guardian et ajoute student_profiles.titulaire_profile_id | Deux sources actives en désaccord (CTR-ELV-02, CTR-IDS-01) | P1 | gouvernance puis backend | B-07 (PR 29) ; AUD-IDS-069 |
| AUD-ELV-023 | Aujourd'hui : prochaine séance dans son fuseau, enseignant attitré après confirmation, autres séances et annulations, devoir, accès support, notifications (DM 270) | Adulte | ELV-02 | ABSENT | ELV-02 compte à rebours en minutes, sans heure ni fuseau, une seule séance, pas de devoir (accueil_eleve_page.dart:656-669) ; Compte "Fuseau horaire : Non disponible" (compte_page.dart:156, :287-294) ; households.timezone écrit par 0043:652 mais lu par aucun écran ; ccr : accueil_adulte (hors HEAD) | Écran adulte à construire ou reprendre ; ne pas gonfler ELV-02 (voir CTR-ELV-06) | P1 | frontend | Aucune tâche existante trouvée à HEAD |
| AUD-ELV-024 | Les champs absents restent absents : pas de professeur fictif ni de statut "réussi" non confirmé (DM 270) | Élève, tuteur | ELV-02 ; Mes groupes | CONFORME_PARTIEL | ELV-02 n'affiche que seance.enseignantPrenom issu de la base (accueil_eleve_page.dart:342, :383) ; Mes groupes affiche six Classes et des enseignants inventés (voir AUD-ELV-077) | Conforme sur ELV-02, non conforme sur Mes groupes | P1 | frontend | Voir AUD-ELV-077 |
| AUD-ELV-025 | Apprendre : classe actuelle, bibliothèque, Coran, ressources, travail, reprise (DM 274) | Élève standard et adulte | /tc/groupes, /tc/bibliotheque, /eleve/coran | PRÉSENT_MAIS_NON_ROUTÉ | /tc/groupes et /tc/bibliotheque sont autorisés à l'élève (redirection.dart:133-138) mais aucun lien d'élève : Routes.tcGroupes n'est référencé que par accueil_famille_page.dart:467 ; Routes.tcBibliotheque par aucun écran (grep lib/features) | L'élève atteint ces routes seulement en tapant l'URL | P1 | frontend | docs/teaching-core/TC_AGENT_A_REPORT.md:333-340 (entrée de navigation, arbitrage produit) |
| AUD-ELV-026 | Reprise de la lecture du Coran (DM 274) | Élève | /eleve/coran, MushafPage | IMPLÉMENTÉ_NON_PROUVÉ | lib/features/tc_mushaf/mushaf_page.dart:171-175 (_Reprises : la sienne et celle du groupe) ; table student_reading_position (0007:86-100) ; test non lu pour cette fonction ; audité par le registre Bibliothèque et Coran | Non démontré dans ce domaine | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-027 | Suivi : niveau humain, jalons réels, À renforcer / Acquis / Stable seulement si décidés, évaluations et attestations émises (DM 278) | Élève, adulte | /eleve/suivi | ABSENT | suivi_eleve_page.dart:150-190 ne rend que date, "Cours de Coran", enseignant, présence ; aucun niveau, jalon, évaluation ni attestation ; projection famille de la progression : PR 29 migration 0054 (B-08, progression_famille) | Projection académique officielle absente à HEAD | P1 | contrat partagé ; backend ; frontend | B-08 (PR 29) |
| AUD-ELV-028 | Aucun indicateur de compétence dérivé d'un taux de présence ou d'un nombre de séances (DM 278, 941-942) | Élève, tuteur | SuiviElevePage, VueSuiviFoyer | CONFORME_PROUVÉ | vue_suivi_foyer.dart (lu en entier) ne calcule aucun taux ; suivi_eleve_page.dart:150-190 ne rend que l'état de chaque séance ; "un cours annulé ne rend pas une présence" ; tests lus : suivi_eleve_test.dart:70, :117, :133 | - | - | frontend | R3 (docs/PROGRESS.md:27-36 ; HANDOFF.md:2458) |
| AUD-ELV-029 | Le suivi de l'élève ne montre que ses séances et sa présence (DM 254, 278) | Élève standard | /eleve/suivi | CONTRADICTOIRE | La présence est bornée à sa ligne (presence_seance_v, 0011:104-107 ; scenarios_n4.sql:137-160, P1) mais la liste des cours vient de mes_seances_v, qui ajoute les séances de la fratrie (0014:915-918) ; la page ne filtre rien (suivi_eleve_page.dart:60-70 ; service_suivi.dart:25-28) | Lignes de la fratrie affichées avec la présence "inconnu". Même cause que AUD-ELV-009 | P0 | backend ; frontend | Aucune tâche existante trouvée |
| AUD-ELV-030 | Adulte anciennement mineur : transition documentée sans transfert de données privées à l'ancien tuteur ; frontières d'âge testées (DM 163, 286) | Élève devenu majeur | cohortes_age, student_type | ABSENT | Aucune occurrence de transition vers l'autonomie (grep supabase/migrations, lib/) ; le student_type 'autonomous' n'est produit par aucune RPC à HEAD (creer_profil_enfant n'écrit que 'minor', 0004:892) | Chemin de transition et tests de frontière absents | P1 | gouvernance ; backend | B-07 (PR 29) pour le profil titulaire seulement |

### 2.4 Tuteur et foyer : navigation, contexte, accueil

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-031 | Conserver le shell validé Accueil, Foyer, Historique, Compte (DM 294) | Tuteur | nav_shell.dart destinationsPour(guardian) | CONTRADICTOIRE | HEAD : Accueil, Disponibilités, Réglages, Suivi (nav_shell.dart:79-100 ; test figé navigation_test.dart:21-26) ; la clé nav.tuteur.foyer existe mais ne sert qu'à la galerie (catalogue_galerie.dart:198) ; ccr : Accueil, Foyer, Historique, Compte avec le commentaire "mandat Tuteur V1, décisions du 24/09/2026" (hors HEAD) | Le code de HEAD suit un état antérieur au mandat Tuteur V1 | P1 | frontend | Aucune tâche existante trouvée à HEAD ; ccr (hors HEAD) |
| AUD-ELV-032 | Aucune nouvelle destination globale Rapports ou Évaluations (DM 294) | Tuteur | NavShell | CONFORME_PROUVÉ | nav_shell.dart:79-100 ne contient que quatre destinations ; assertion de plafond à quatre (nav_shell.dart:225-229) ; tests lus navigation_test.dart:16-72 et :74 | - | - | frontend | ADR-018 |
| AUD-ELV-033 | Une fonction, un emplacement ; réglages personnels et apparence dans Compte (DM 294) | Tuteur | TUT-01, TUT-02, TUT-05, Compte | CONTRADICTOIRE | Appareils atteints par l'Accueil (accueil_famille_page.dart:441-446) et par Compte (compte_page.dart:73-82) ; Réglages par enfant par l'Accueil (:448-453) et la barre ; TUT-05 mêle trois lignes du Compte et les réglages par enfant (reglages_enfant_page.dart:56-77) ; "Disponibilités" reste en barre alors que la Classe stable remplace le matching individuel (DM 914) | Doublons d'entrée et destination héritée | P2 | frontend | AUD-OFR (Disponibilités) |
| AUD-ELV-034 | Sortie de session atteignable sur téléphone pour le tuteur | Tuteur, téléphone | NavShell, ComptePage | ABSENT | Les entrées secondaires (dont Compte, qui porte "Se déconnecter", compte_page.dart:104-108) ne sont rendues que par le rail et la barre latérale, à partir de 600 (nav_shell.dart:160-185 pour secondairesPour, :315-341 pour le rail et la barre latérale qui reçoivent les entrées secondaires) ; la barre basse ne les reçoit pas (nav_shell.dart:304-314) ; aucun écran du tuteur ne pointe vers Routes.compte (grep) ; TUT-05 pointe vers compteProfil, compteProfils, compteReglages (reglages_enfant_page.dart:56-77), aucun ne porte la déconnexion ; ccr corrige explicitement ce point (commentaire nav_shell.dart ccr) | Un tuteur sur téléphone ne peut pas fermer sa session par l'interface. Non rejoué | P1 | frontend | Aucune tâche existante trouvée à HEAD |
| AUD-ELV-035 | Contexte élève fiable : choix explicite de l'enfant, conservé dans liens, historiques, notifications et retours (DM 298) | Tuteur, foyer de plusieurs enfants | Contexte actif | ABSENT | TUT-01 montre tous les enfants (accueil_famille_page.dart:248-262) ; TUT-06 filtre en état local _enfantId (suivi_foyer_page.dart:75-103) ; aucun provider de contexte, aucun paramètre ?eleve= ; hors HEAD : PR 3 lib/core/foyer/selection_eleve.dart (selectionEleveProvider, providers .family) | Aucun écran de détail par enfant à HEAD (accueil_famille_page.dart:329-332), donc risque faible aujourd'hui, exigence non remplie | P1 | frontend | DB-FOY-01 (marqueur de code PR 3) |
| AUD-ELV-036 | Aucun mélange de données quand le profil actif change (DM 298, 310) | Tuteur | Contexte actif | NON_APPLICABLE_JUSTIFIÉ | À HEAD aucun profil actif n'existe (AUD-ELV-035) ; TUT-06 filtre une liste déjà chargée, sans donnée par enfant à vider (vue_suivi_foyer.dart:160-190) | À rejouer dès l'introduction du contexte (CP-ELV-09) | - | frontend | Aucune |
| AUD-ELV-037 | Vue foyer multienfants : total informatif des soldes et sous-solde par enfant, pas de portefeuille transférable (DM 298) | Tuteur | TUT-01 | ABSENT | _BlocAcces n'affiche que la date de fin d'accès (accueil_famille_page.dart:541-565) ; wallets : une ligne unique par foyer (0001:246-251, household_id unique) | Modèle de données à un portefeuille par foyer (CTR-ELV-13) | P1 | backend ; gouvernance | ADR-003 |
| AUD-ELV-038 | TUT-01 : l'état en direct de chaque enfant en cinq phases (DM 294 ; catalogue TUT-01) | Tuteur, /tuteur | AccueilFamillePage, phaseEnfant | CONFORME_PROUVÉ | Racine du rôle (routes.dart racinePour) ; providers elevesDuFoyer, seances, affectations (accueil_famille_page.dart:205-215) ; vues bornées au foyer pour le rôle guardian (scenarios_etape4.sql:810-833 ; scenarios_n4.sql:243-272, P5) ; tests lus : accueil_famille_test.dart:196-520, :598-705 | - | - | frontend | R2 (catalogue 08, fiche TUT-01) |
| AUD-ELV-039 | TUT-01 : en cas d'échec de lecture, ne pas présenter un état métier faux | Tuteur | AccueilFamillePage | CONFORME_PARTIEL | accueil_famille_page.dart:214-218 et :275-283 affichent un message d'erreur ; les cartes continuent avec seances.value ?? [] (:206-212) et peuvent dire "En recherche d'un enseignant" ou "Rien aujourd'hui" ; aucun test d'erreur dans accueil_famille_test.dart (noms lus) | Les cartes devraient s'effacer ou se marquer "inconnu" | P2 | frontend | R2 |
| AUD-ELV-040 | Assister n'est câblé que pendant une séance en cours et inscrit le tuteur avant d'ouvrir la salle | Tuteur | TUT-01, assister_seance | CONFORME_PROUVÉ | accueil_famille_page.dart:180-199 et :358-360 ; service_video.dart:131-134 ; RPC assister_seance : rôle guardian, séance du foyer, fenêtre (0012:398-443) ; tests : scenarios_ctr01.sql:505-560 (C10), accueil_famille_test.dart:250, :280, :308 | Cette porte ne consomme pas le quota d'observation (AUD-ELV-042) | - | backend ; frontend | HANDOFF.md:1955 |

### 2.5 Observer (tuteur) : limites, annonce, libellés

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-041 | Le tuteur observateur n'a ni micro ni caméra (DM 302, 934) | Tuteur | autoriser_jeton_video | IMPLÉMENTÉ_NON_PROUVÉ | 0033:1719 : v_publier exclut guardian_observer ; triggers d'exemption 0012:78, :129 ; tests SQL existants testent enseignant, élève, contrôleur (scenarios_n2.sql:278-311), aucun pour guardian_observer | Aucun test nommé sur le jeton de l'observateur | P1 | backend | Aucune tâche existante trouvée |
| AUD-ELV-042 | Deux visites de deux minutes par parent et par séance ; visite interrompue consommée ; jamais l'horloge cliente (DM 302, 934) | Tuteur observateur | assister_seance, budget_observation, entrer_observation | CONTRADICTOIRE | La porte réellement utilisée (accueil_famille_page.dart:182 puis service_video.dart:131) n'écrit que session_participants (0012:398-443) ; guardian_session_visit n'est écrite que par entrer_observation (0033:1172 ; 0037:142) ; budget_observation compte ces visites (0033:1020-1050) et vaut donc zéro visite pour la porte actuelle ; le jeton est borné à min(ttl, restant) (0033:1732-1735) mais se redemande sans limite ; défauts appliqués 0030:37-38 : 1 visite, 120 s au total ; 0036 (2 visites, 120 s par visite, 240 au total) et 0037 non appliquées en production d'après LISEZ-MOI-0035-0037-non-appliquees.md (état du 21/09) | Le quota produit n'est pas consommé par la porte en service. Non rejoué | P0 | backend ; frontend | LISEZ-MOI-0035-0037-non-appliquees.md ; entete_classe.dart:185-213 (bascule en attente volontaire) |
| AUD-ELV-043 | Annonce ciblée à l'enfant observé, jamais aux autres élèves (DM 254, 302) | Élève enfant | IndicateurObservationEnfant | PRÉSENT_MAIS_NON_RACCORDÉ | indicateur_observation.dart:19-37 et :106-163 : composant et prédicat sans appelant (aucun fichier de lib/ ne les monte) ; annonces_observation réservée à l'enseignant (0033:1276) ; RLS de guardian_session_visit sans lecture par l'élève (0032:488-492) ; marqué TC-Z-SUIVI | L'enfant n'est pas informé. Il manque une RPC de lecture limitée à sa propre ligne | P1 | backend ; frontend | TC-Z-SUIVI (marqueur de code, absent de PROGRESS et HANDOFF) |
| AUD-ELV-044 | La porte d'observation du module Teaching Core est atteignable par le tuteur | Tuteur | /tc/observation/:seanceId | PRÉSENT_MAIS_NON_ROUTÉ | Route enregistrée (routes_tc_g.dart:18-21 ; redirection.dart:144-147) ; RoutesTcG.versObservation n'a aucun appelant (entete_classe.dart:197-200) ; le bouton Assister utilise l'ancienne porte | Deux portes pour une fonction (CTR-ELV-14) | P1 | frontend | entete_classe.dart:185-213 |
| AUD-ELV-045 | Historique des observations dans son écran existant et dans l'administration (DM 302) | Tuteur, admin | TUT-06, ADM | ABSENT | guardian_session_visit lisible par l'observateur et l'administrateur (0032:488-492) mais aucun écran ; TUT-06 n'a pas de ligne d'observation ; admin_groupes règle la politique (feuille_observation_groupe.dart), pas l'historique ; admin_observations existe sur ccr (hors HEAD) | Aucun historique côté famille ni administration | P2 | frontend ; backend | Aucune tâche existante trouvée |
| AUD-ELV-046 | Proscrire le libellé "Cours en cours" (DM 302) | Tous, observation et classe | fr.i18n.json | À_ARBITRER | "Cours en cours" reste utilisé : fr.i18n.json:1379 (Journée enseignant), :1700 (carte du groupe vue par l'élève et le tuteur), :2023 (barre compacte de la Classe Live) ; aucune occurrence dans l'interface d'observation (tc.observation.*) | La portée du rejet (observation seule ou partout) n'est écrite dans aucune source lue | P2 | gouvernance | Aucune tâche existante trouvée (CTR-ELV-09) |
| AUD-ELV-047 | La fonction s'appelle Observer (DM 302) | Tuteur | Bouton de TUT-01 | CONTRADICTOIRE | fr.i18n.json:1260 ("Assister") ; accueil_famille_page.dart, ChildCard | Libellé et nom de fonction différents du DM | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-048 | Aucune présence ne dépasse son temps maximum par manipulation d'horloge cliente (DM 302, 934) | Tuteur | budget_observation, autoriser_jeton_video | CONFORME_PARTIEL | Le calcul serveur lit now() (0033:1033-1046, :1732-1735) ; le plafond par visite n'est tenu que côté client (guardian_observation_policy.dart:161-167) tant que 0036 n'est pas appliquée | Plafond par visite non tenu par le serveur en l'état de la base | P1 | backend | LISEZ-MOI-0035-0037-non-appliquees.md |
| AUD-ELV-049 | Les autres élèves du groupe ne sont pas interrompus par l'observation d'un parent (DM 254 ; indicateur_observation.dart:21-24) | Élèves du groupe | participants de la salle | IMPLÉMENTÉ_NON_PROUVÉ | La porte actuelle inscrit un participant visible et non masqué (0033:1718 : v_invisible exclut guardian_observer ; 0012:396 "muet et visible") ; l'enseignant le lit (scenarios_ctr01.sql:505-560, "attendu 1") ; rendu côté élèves non lu (domaine salle) | À vérifier avec le registre salle | P1 | frontend ; backend | Aucune tâche existante trouvée |

### 2.6 Abonnement, solde, second adulte

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-050 | Le tuteur lit le solde du foyer et sa répartition (DM 298, 306) | Tuteur | Solde | ABSENT | grep solde, recharg, portefeuille, wallet dans lib/ : aucun écran ; tables wallets et wallet_entries "schéma seulement, aucune interface" (0001:242-262) ; hors HEAD : PR 3 port_paiements_foyer.dart, ccr foyer/finances_foyer.dart | Surface entière à construire sur un contrat financier décidé | P1 | backend ; frontend | ADR-003 ; DB-FOY-05 (marqueur PR 3) |
| AUD-ELV-051 | Adulte : historique et rechargement de son propre solde, moyens de paiement, factures (DM 282) | Adulte | Profil | ABSENT | Même constat ; compte_page.dart:96-110 sans rubrique finance ; ccr mon_espace_adulte/mes_finances_page.dart (hors HEAD) | Idem | P1 | backend ; frontend | Aucune tâche existante trouvée à HEAD |
| AUD-ELV-052 | Recharger un ou plusieurs profils = un seul paiement externe, allocations immuables par profil vérifiées côté serveur (DM 306) | Tuteur, adulte | Recharge | ABSENT | Aucune table d'allocation ni RPC (grep supabase/migrations) ; ccr foyer/recharge_foyer.dart (hors HEAD) | Idem | P1 | backend ; contrat partagé | Aucune tâche existante trouvée |
| AUD-ELV-053 | Remises, absence du professeur, pause, annulation d'accès, factures et retour de crédit suivent la version de politique financière effective (DM 306) | Tuteur | Politique financière | BLOQUÉ_DÉPENDANCE | Aucune table de politique financière versionnée à HEAD (grep) ; dépend de la décision de politique et de AUD-ELV-052 | Dépendance réelle et prouvée par l'absence | P2 | gouvernance ; backend | Aucune tâche existante trouvée |
| AUD-ELV-054 | La lecture d'un solde n'autorise pas à recharger (DM 298, 924) | Tuteur, second adulte | wallets, wallet_entries, payouts | IMPLÉMENTÉ_NON_PROUVÉ | Seules policies de famille : SELECT (0001:1103-1140) ; aucune policy d'écriture famille ; aucun test nommé ; aucun écran | Preuve par test SQL à ajouter avec les capacités (CP-ELV-08) | P1 | backend | Aucune tâche existante trouvée |
| AUD-ELV-055 | L'enfant ne consulte pas le solde parental et ne voit pas la raison monétaire (DM 254, 306) | Élève | RLS wallets, vue profils_du_foyer_v | CONTRADICTOIRE | L'interface enfant n'a aucune donnée financière (AUD-ELV-007) ; mais wallets_family_read, wallet_entries_family_read, payouts_family_read, payout_methods_family_read ne testent que le foyer (0001:1103-1140) ; profils_du_foyer_v rend access_until (0014:828-846) sans test de rôle | Lisible par un jeton élève. Non rejoué | P1 | backend | Aucune tâche existante trouvée |
| AUD-ELV-056 | Si l'adulte responsable n'a pas finalisé l'accès : écran calme avec explication, jamais "vous n'avez pas payé" (DM 254) | Élève enfant | Portail d'attente | CONTRADICTOIRE | Le profil enfant copie le statut du tuteur à sa création (0004:878-888) ; une session enfant en attente ou suspendue reçoit AttentePage, écrite pour un adulte (session_state.dart:156-168 ; attente_page.dart:25-60 ; fr.i18n.json attente.* : "Votre dossier n'a pas été validé", "Votre compte est suspendu", "Déposer ma pièce") ; aucune variante enfant ; propagation d'une suspension du tuteur vers ses enfants non démontrée | Ton, vouvoiement et motif administratifs montrés à un enfant | P1 | frontend ; gouvernance (ton) | Aucune tâche existante trouvée |
| AUD-ELV-057 | Le second adulte ne reçoit que les droits explicitement délégués (DM 298, 924, 163) | Second adulte | Foyer | ABSENT | Aucun modèle de délégation ni de second adulte (grep delegu, co_tuteur, household_members : seulement des commentaires) ; hors HEAD : PR 29 migration 0053 (invitations_foyer, repondre_invitation_conjoint) place l'invité dans le household du titulaire avec role guardian, donc tous les droits tuteur ; ccr foyer/invitation_conjoint.dart | Aucun droit délégué n'est exprimable (CP-ELV-08) | P1 | backend ; gouvernance | B-03 (PR 29) |
| AUD-ELV-058 | Lecture des paiements pour le second adulte sans droit de recharger ni d'approuver (DM 298) | Second adulte | Capacités | BLOQUÉ_DÉPENDANCE | Dépend de AUD-ELV-057 (modèle de capacités) et de AUD-ELV-052 (paiements), tous deux absents à HEAD | Dépendances réelles | P1 | backend | B-03 (PR 29) |

### 2.7 Appairage, connexion de l'enfant, appareils

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-059 | Seul le tuteur du foyer appaire un appareil ; plafond de deux appareils vérifié en base ; à la limite le bouton est remplacé par un message (ADR-010) | Tuteur | /tuteur/foyer, /tuteur/foyer/appairer/:eleveId | CONFORME_PROUVÉ | accueil_famille_page.dart:441-446 puis app_router.dart:278-292 ; creer_code_appairage : rôle guardian, enfant du foyer, plafond (0004:580-612) ; tests : scenarios_etape3.sql:383-418 (S7a, S7b), appareils_test.dart:64-100 | - | - | backend ; frontend | R4 ; AUD-IDS-058 |
| AUD-ELV-060 | ELV-01 : un appareil déjà appairé ne redemande pas de code ; l'enfant choisit son profil | Élève enfant | /connexion/eleve | CONFORME_PARTIEL | eleve_connexion_page.dart:99-118 ; tests lus eleve_connexion_test.dart:52, :69 ; route publique (redirection.dart:39-47) ; fonction Edge session-enfant lue par le registre identité | Choix hors ligne non testé par nom | P2 | frontend | R4 |
| AUD-ELV-061 | Le code personnel de l'enfant ne quitte jamais l'appareil (ADR-005) | Élève enfant | CodeLocal, ELV-01 | CONFORME_PROUVÉ | code_local.dart:1-40 ; eleve_connexion_page.dart:214-236 (comparaison locale) ; tests lus test/appairage/code_local_test.dart:72, :103, :127 (relisent le code source) | - | - | frontend | etape-3-journal.md |
| AUD-ELV-062 | Un frère ou une sœur n'ouvre pas le profil d'un autre enfant sur l'appareil partagé | Élève enfant | PinPad, ELV-01 | CONFORME_PARTIEL | Code local de 4 chiffres, aucun compteur d'essais ni délai (eleve_connexion_page.dart:214-252 ; PinPad) ; limite reconnue par l'auteur (code_local.dart:20-27) | Rendre le code plus coûteux à deviner par essais répétés | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-063 | Révoquer un appareil coupe l'accès de l'enfant sur cet appareil | Tuteur | TUT-02 | ABSENT | Le registre identité établit que la révocation n'efface que le jeton d'appareil et ne coupe pas la session (AUD-IDS-061 ; 0004:757-759) | L'écran dit "retiré", la session de l'enfant peut rester vivante | P1 | backend | AUD-IDS-061 |
| AUD-ELV-064 | Un échec de révocation se dit à l'écran | Tuteur | TUT-02 | ABSENT | appareils_page.dart:83-86 et :151 (unawaited, aucune capture) ; test appareils_test.dart:139 | Exception non attrapée, aucun message | P2 | frontend | Aucune tâche existante trouvée |

### 2.8 Réglages par enfant, ajout d'enfant

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-065 | Le tuteur règle photo, caméra et affichage de chaque enfant, trois colonnes seulement | Tuteur | /tuteur/reglages | CONFORME_PROUVÉ | reglages_enfant_page.dart:120-150 ; service_appairage.dart:262-283 ; GRANT par colonnes 0005:562-565 ; tests : scenarios_etape4.sql:645-684 (S6a), reglages_enfant_test.dart:155, :190 | Limité au rôle guardian (voir AUD-ELV-005) | - | backend ; frontend | R4 |
| AUD-ELV-066 | Le tuteur ne règle que les enfants de son foyer | Tuteur | student_profiles | CONFORME_PROUVÉ | Policy 0005:535-552 (foyer) ; test scenarios_etape4.sql:687-705 (S6b) | - | - | backend | R4 |
| AUD-ELV-067 | Le tuteur ne peut pas modifier le niveau, la riwaya ni le type d'élève | Tuteur | student_profiles | CONFORME_PROUVÉ | GRANT par colonnes 0005:562-565 ; 0043:289-290 (liste nominative sans level, diagnostic_statut, student_type) ; test scenarios_etape4.sql:661-684 | - | - | backend | R4 |
| AUD-ELV-068 | La photo de l'enfant reste visible du seul foyer, jamais de l'enseignant ni des autres élèves (ADR-012) | Tuteur | seau avatars | IMPLÉMENTÉ_NON_PROUVÉ | Policies de stockage : écriture réservée au rôle guardian du foyer, lecture foyer et enfant (0004:1021-1060) ; la clé n'apparaît que dans profils_du_foyer_v (0014:838) ; tests Dart reglages_enfant_test.dart:211-285 ; aucun test SQL sur le stockage (grep avatar) | Preuve SQL absente | P2 | backend | Aucune tâche existante trouvée |
| AUD-ELV-069 | Un réglage s'applique à la séance suivante, jamais pendant un cours | Tuteur | TUT-05 | IMPLÉMENTÉ_NON_PROUVÉ | Le mode est lu à la résolution de session (source_session.dart:76-105) donc à la relance ou au rafraîchissement du jeton ; la caméra est lue à l'émission du jeton vidéo (0033:1725-1730) ; aucun test ne couvre le délai | Délai effectif du mode non mesuré | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-070 | Un écran n'est fini qu'avec ses états loading, content, empty, error, offline (CLAUDE.md racine) | Tuteur | TUT-02, TUT-05 | CONFORME_PARTIEL | reglages_enfant_page.dart:42-48 et appareils_page.dart:44-100 lisent .value ?? [] sans squelette ni erreur ; le bouton "Ajouter un enfant" apparaît même quand la lecture échoue ; tirage-pour-rafraîchir retiré (appareils_page.dart:30-41) | Chargement et erreur absents sur deux écrans | P2 | frontend | R4 |
| AUD-ELV-071 | Ajout d'un enfant : âge, mode et caméra dérivés en base (ADR-009) | Tuteur | /tuteur/foyer/ajouter-enfant | CONFORME_PARTIEL | ajouter_enfant_page.dart:42-46 (3 à 18 ans) ; creer_profil_enfant accepte 3 à 99 (0004:862) ; cohortes à partir de 5 ans (0043:110) ; aucun ajout de second adulte ni d'adulte | Trois bornes d'âge différentes | P2 | frontend ; backend | Aucune tâche existante trouvée |

### 2.9 Suivi, historique, cahier, classe

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-072 | Un incident de réseau, un cours annulé ou un enseignant absent ne devient ni absence ni faute de l'élève (DM 932-933) | Tuteur | /tuteur/suivi | CONFORME_PROUVÉ | vue_suivi_foyer.dart:19-35 (SortDuCours) et :195-210 (sortDe) ; chaîne : barre Suivi, SuiviFoyerPage, mes_seances_v et presence_seance_v ; tests : test/suivi/vue_suivi_foyer_test.dart:93, :121, :163, test/features/suivi_foyer_test.dart:155, :175, :219 ; scenarios_n4.sql:243-272 | - | - | frontend | R3 ; TUT-06 |
| AUD-ELV-073 | L'historique du foyer est une lecture : aucune action de correction pour la famille | Tuteur | TUT-06 | CONFORME_PROUVÉ | suivi_foyer_page.dart:14-60 ; test lu suivi_foyer_test.dart:132 ; la famille n'a aucune policy d'écriture sur session_presence_override ni sessions (0001:983-1060) | - | - | frontend | TUT-06 |
| AUD-ELV-074 | Résumé d'une séance depuis Historique, puis Détail (DM 294, 944) | Tuteur | /tuteur/suivi/:seance | ABSENT | Une seule route Suivi (routes.dart:tuteurSuivi) ; aucune route de détail ; projection partageable absente à HEAD ; PR 29 migration 0054 (seance_resumes, enregistrer_resume_seance, progression_famille) ; ccr suivi_famille (hors HEAD) | Détail et résumé publiés à construire | P1 | backend ; frontend | B-08 (PR 29) |
| AUD-ELV-075 | Le cahier de l'enseignant n'est pas recopié ni lu tel quel par la famille ; projection autorisée, publication et révocation (DM 944) | Tuteur, élève, camarades | lesson_reports, makharij_findings | CONTRADICTOIRE | lesson_reports_reader : lecture par tout membre du foyer d'un participant (session_in_household) et par tout participant de la séance (session_has_participant) (0001:1070-1078) ; makharij_findings_read idem (0001:1080-1088) ; content contient une décision par élève (point phonétique, objectif personnel, travail maison, motif d'exception) pour toute la séance (lib/core/enseignant/modeles_enseignant.dart:620-690) ; aucun test sur cette lecture (grep supabase/tests) ; aucune lecture famille dans lib/ | Le tuteur d'un enfant et chaque élève d'un groupe peuvent lire les notes sur les autres enfants de la séance. Non rejoué | P0 | backend | B-08 (PR 29) pour la projection ; aucune tâche sur la lecture brute |
| AUD-ELV-076 | Présence : l'élève voit sa seule ligne, le tuteur son foyer, jamais un nom de famille (ADR-008) | Élève, tuteur | presence_seance_v | CONFORME_PROUVÉ | 0011:68-130 (prédicats par rôle) ; tests scenarios_n4.sql:137-160 (P1), :243-272 (P5), :295-303 (P6, aucune colonne de nom de famille) | - | - | backend | N4 |
| AUD-ELV-077 | Page de Classe côté famille et élève : groupe, enseignant attitré, prochaine séance, travail (DM 294 ; maquette Classe Details) | Tuteur, élève | /tc/groupes, /tc/groupes/:id | PRÉSENT_MAIS_NON_RACCORDÉ | portGroupesProvider vaut GroupesDemonstrationLocale (port_groupes.dart:34-39) ; aucune surcharge (main.dart:105-131, app.dart) ; six Classes et enseignants inventés (demonstration_groupes.dart:41-150) ; seul lien : accueil_famille_page.dart:462-468 ; portHorlogeSeanceProvider également de démonstration (port_horloge_seance.dart:54-55) | En production une famille voit six groupes fictifs. Même constat dans AUD-OFR-066 | P0 | frontend ; contrat partagé | TC_AGENT_A_REPORT.md:343 ; AUD-OFR-066 |

### 2.10 Compte, préférences, dignité, visuel

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-078 | Mode d'affichage, préférences et notifications effectifs (DM 282, 294) | Tous | ReglagesComptePage | PRÉSENT_MAIS_NON_RACCORDÉ | preferencesLocalesProvider n'est lu que par compte_page.dart:197, :205 ; RewayahApp reçoit toujours ThemeMode.system (main.dart:68, :107, :130 ; app.dart:48-50) ; modèle "volontairement en mémoire" (preferences_locales.dart:19-24) ; aucun consommateur d'economieDonnees, lectureGrande, notificationsCours, notificationsFoyer ; aucune dépendance de notification (pubspec.yaml) ; test lu compte_test.dart:28 vérifie le modèle, pas l'effet | Choisir "Sombre" ou "Réduire les animations" ne change rien et rien n'est conservé | P1 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-079 | Identité du profil (nom, contact, fuseau) sans valeur fictive ni code interne | Tous | ProfilPersonnelPage | PRÉSENT_MAIS_NON_RACCORDÉ | compte_page.dart:139-157 : "Identifiant" affiche le UUID du profil, "Contact" et "Fuseau" valent "Non disponible" en dur ; le titre du Compte montre le rôle et non la personne (compte_page.dart:462-495) ; DM 927 : ne pas montrer de codes internes | Champs sans source ; UUID visible | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-080 | Titre de la fiche d'un profil enfant lisible | Tuteur | /compte/profils/:id | CONTRADICTOIRE | compte_page.dart:429 passe t.compte.nonDisponible comme prénom ; fr.i18n.json:1170 | Titre toujours "Profil de Non disponible" | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-081 | Confidentialité des familles : consentements, consultation, export, suppression | Tuteur, adulte | Compte, Confidentialité | ABSENT | compte_page.dart:84-88 et :350-354 : entrée désactivée "Bientôt disponible" (fr.i18n.json:1107) ; aucun flux de consentement ni d'export dans lib/ | Droits des familles non offerts (exigence portée par la lettre G, non par DM 238-313) | P1 | gouvernance ; backend ; frontend | Aucune tâche existante trouvée |
| AUD-ELV-082 | Les messages d'erreur sont humains et ne montrent pas de texte technique | Tuteur | TUT-05 | CONFORME_PARTIEL | reglages_enfant_page.dart:603-611 extrait le message d'une exception Postgrest et l'affiche ("L'enregistrement n'a pas abouti : {message}") | Texte serveur montré tel quel | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-083 | Notifications : rappels de cours, activité du foyer, observation (DM 270, 254) | Tous | Compte, push | ABSENT | Voir AUD-ELV-078 : aucune infrastructure de notification (grep firebase, fcm, flutter_local_notifications : aucun résultat) ; deux interrupteurs sans effet | Rien n'est envoyé | P1 | backend ; frontend | Aucune tâche existante trouvée |
| AUD-ELV-084 | Polices : DM Sans pour les titres, Plus Jakarta Sans pour le reste (Mission, lettre H ; DM 1046) | Tous | app_typography.dart | CONTRADICTOIRE | lib/core/theme/app_typography.dart:23-26 (InstrumentSans, BricolageGrotesque) ; assets/fonts sans DMSans ni PlusJakartaSans ; les polices demandées sont ajoutées par la PR 3 (hors HEAD) | Relève du registre design system ; signalé ici car il touche tous les écrans du domaine | P2 | frontend | PR 3 (hors HEAD) |
| AUD-ELV-085 | Accès refusé : une route d'un autre rôle renvoie chez soi | Élève, tuteur | deciderRedirection | CONFORME_PROUVÉ | redirection.dart:114-115 ; tests lus redirection_test.dart:116, :127, :138 ; la protection réelle reste la RLS (lib/CLAUDE.md) | - | - | frontend | Etape 2 |
| AUD-ELV-086 | Session expirée ou fermée : retour à la connexion | Tous | SessionControleur | CONFORME_PARTIEL | redirection.dart:39-47 ; tests lus redirection_test.dart:280-300 ; l'événement d'expiration vient de supabase_flutter, non rejoué ; aucune reprise du contexte (page demandée) après reconnexion | Reprise après reconnexion non prévue | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-087 | Dans la salle pédagogique : Sayyid ou Sayyida selon la convention active ; pas de code interne (DM 927) | Élève, tuteur | ELV-02, Classe Live | CONFORME_PARTIEL | Titres dans la Classe Live et les groupes (fr.i18n.json:1681-1682, :1918-1919 ; lib/core/tc_groupe/group_summary_vm.dart) ; ELV-02 écrit "Avec {prenom}" sans titre (fr.i18n.json eleve.accueil.avec) | Convention active non définie dans les sources lues | P2 | contenu académique ; frontend | Aucune tâche existante trouvée |

### 2.11 Maquettes du Tuteur citées par le DM

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve | Écart minimal | Priorité | Responsable | Tâche existante |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| AUD-ELV-088 | Maquette Accueil (DM 865, liste des sources de la section 26.2) | Tuteur | TUT-01 | IMPLÉMENTÉ_NON_PROUVÉ | Écran TUT-01 existant (AUD-ELV-038) ; maquette introuvable à HEAD | Conformité visuelle non démontrée | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-089 | Maquette Profil | Tuteur | ComptePage, ProfilPersonnelPage | CONFORME_PARTIEL | Pages présentes (AUD-ELV-079, 080) mais champs fictifs ; maquette introuvable | Contenu et visuel non démontrés | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-090 | Maquette Foyer Member (fiche d'un membre du foyer) | Tuteur | Fiche enfant | ABSENT | Aucune route par enfant ; ProfilEnfantPage en lecture seule est la plus proche (compte_page.dart:415-455) ; ccr foyer/fiche_eleve_page.dart (hors HEAD) | Fiche membre à construire ou reprendre | P1 | frontend | Aucune tâche existante trouvée à HEAD |
| AUD-ELV-091 | Maquette Historique | Tuteur | TUT-06 | IMPLÉMENTÉ_NON_PROUVÉ | Écran existant (AUD-ELV-072, 073) ; maquette introuvable ; pas de détail (AUD-ELV-074) | Visuel non démontré | P2 | frontend | Aucune tâche existante trouvée |
| AUD-ELV-092 | Maquette Classe Details | Tuteur | /tc/groupes/:id | PRÉSENT_MAIS_NON_RACCORDÉ | Voir AUD-ELV-077 ; maquette introuvable | Écran existant mais sur données fictives | P0 | frontend ; contrat partagé | AUD-OFR-066 |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Périmètre | Décision la plus récente applicable | Statut | Conséquence |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| CTR-ELV-01 | DM 242 et 926 ; docs/current/00_LIRE_D_ABORD.md sur ccr (23/09/2026) : "Mode enfant devient Interface guidée" | assets/i18n/fr.i18n.json:1161-1162, :1309-1312, :592-593 ; ADR-009 ; 25 documents du dépôt | Libellés visibles et documents | Interface guidée (décision du 23/09, reprise par le DM du 14/10) | Résolu pour la décision, non appliqué dans le code et les documents de HEAD | Quatre vocabulaires visibles (AUD-ELV-001) |
| CTR-ELV-02 | ADR-009 (decisions.md:267-300) : l'élève adulte est son propre tuteur, foyer d'une personne | DM 266, 922, 163 : pas de faux tuteur ni de foyer parental créé pour lui | Rôle technique de l'adulte apprenant | Non tranchée : DM 163 tolère "une ancienne structure nommée guardian" si l'adulte a son propre profil élève (ce que la PR 29 apporte) | Ouvert, À_ARBITRER (voir CTR-IDS-01) | Navigation et accueil de l'adulte (AUD-ELV-021, 022) |
| CTR-ELV-03 | Migration 0030:37-38 et docs/current/01_PRODUIT_ET_PARCOURS.md : observation par défaut, 1 visite, 120 s au total | DM 302 et 934 ; migration 0036 (21/09) : 2 visites, 120 s par visite, 240 au total | Quota d'observation | La règle produit dictée le 21/09 et reprise par le DM | Résolu pour la règle, ouvert pour l'application (0036 non appliquée, porte en service sans quota) | AUD-ELV-042, 048 |
| CTR-ELV-04 | nav_shell.dart:79-100 et navigation_test.dart:21-26 : Accueil, Disponibilités, Réglages, Suivi | DM 294 ; commentaire de nav_shell.dart sur ccr : Accueil, Foyer, Historique, Compte (mandat Tuteur V1, 24/09) | Barre du tuteur | Accueil, Foyer, Historique, Compte | Résolu pour la décision, ouvert dans le code de HEAD | AUD-ELV-031, 034 |
| CTR-ELV-05 | HEAD : élève Accueil, Coran, Suivi, Compte | DM 266 : adulte Aujourd'hui, Apprendre, Suivi, Profil ; ccr : Accueil, Ma classe, Coran, Mon espace | Barre de l'élève standard et adulte | Le DM vise l'adulte ; pour l'élève standard de 9 ans et plus aucune source lue ne tranche | Ouvert | AUD-ELV-021 |
| CTR-ELV-06 | docs/produit/parcours-utilisateurs.md:174-178 : ELV-02 gagne en mode standard la semaine à venir, les cahiers et les annonces | Catalogue 08, fiche ELV-02 : "deux blocs, rien d'autre ; le niveau B ne gagne pas de densité" ; DM 270 : Aujourd'hui de l'adulte riche | Contenu d'ELV-02 | Le catalogue gouverne le code (CLAUDE.md) ; le DM gouverne l'adulte | Ouvert | AUD-ELV-014, 023 |
| CTR-ELV-07 | Catalogue 08, fiche ELV-02 : cibles à 44 en standard | app_spacing.dart:94-101 : 48 ; DM 1060 : 48 dp | Cibles tactiles | 48 dp (code et DM) | Résolu ; catalogue obsolète | AUD-ELV-018 |
| CTR-ELV-08 | creer_profil_enfant : child_ui_mode_max_age défaut 8 (0004:869) ; ADR-009 : 6 à 8 ans | 0043:108-113 : valeur de 10 au 22/09 et cohortes 5-10 ans en dur | Frontière d'âge de l'Interface guidée | Non tranchée | Ouvert, À_ARBITRER | AUD-ELV-004 |
| CTR-ELV-09 | DM 302 : le libellé "Cours en cours" est rejeté par la direction | fr.i18n.json:1379, :1700, :2023 | Libellé de la classe en cours | Portée du rejet inconnue | Ouvert, À_ARBITRER | AUD-ELV-046 |
| CTR-ELV-10 | Catalogue 08 ligne 66 : "Suivi élève : à construire" | Code : SuiviElevePage branchée (app_router.dart:222-224) ; HANDOFF.md:2458 | Statut documentaire de /eleve/suivi | Le code ; la fiche manque toujours au catalogue | Obsolète | Écran sans fiche, contraire à la règle d'inscription au catalogue |
| CTR-ELV-11 | service_suivi.dart:25-28 : les vues rendent "sa seule séance" à l'élève | mes_seances_v (0014:915-918) : clause de foyer sans rôle | Suivi élève | Le SQL fait foi | Ouvert (situation 1) | AUD-ELV-009, 029 |
| CTR-ELV-12 | Catalogue 08, fiche ELV-02 : "loading / error : pas d'état dédié, dette" | accueil_eleve_page.dart:172-175 : squelette présent et testé (accueil_eleve_test.dart:126) | États d'ELV-02 | Le code pour le chargement | Obsolète pour le chargement, ouvert pour l'erreur | AUD-ELV-013 |
| CTR-ELV-13 | 0001:246-251 : un portefeuille par foyer | DM 298 et 306 : sous-solde par enfant, allocations immuables par profil | Modèle financier du foyer | Non tranchée | Ouvert, À_ARBITRER (finance) | AUD-ELV-037, 052 |
| CTR-ELV-14 | HANDOFF.md:1955 : le bouton Assister de TUT-01 est câblé sur assister_seance | entete_classe.dart:185-213 et 0033 : la porte d'observation du module Teaching Core est entrer_observation | Deux portes d'observation | La porte du module Teaching Core (quota, annonce) | Ouvert | AUD-ELV-042, 044 |
| CTR-ELV-15 | Matrice d'accès de l'étape 1 : "Élève L soi" (commentaires 0001:703 et :723) ; profiles_family_select et session_participants_family_read testent le rôle guardian | student_profiles_family (0001:726), student_profiles_family_update (0005:535), wallets_family_read (0001:1103), lesson_reports_reader (0001:1070), mes_seances_v (0014:888) ne le testent pas | RLS et vues de foyer | La matrice | Ouvert (situation 1) | AUD-ELV-005, 009, 055, 075 |

## 4. Devoir de regard : contre-propositions

Treize contre-propositions sont formulées. Chacune suit le format à 14 champs. La situation est indiquée dans le champ 6 : situation 1 (décision tranchée, implémentation défectueuse), situation 2 (décision tranchée, risque nouveau), situation 3 (contradiction entre sources actives).

#### CP-ELV-01 - Les policies de foyer doivent exclure le jeton d'un élève

1. Identifiant : CP-ELV-01.
2. Source : DM 254 ; matrice d'accès de l'étape 1 ; AUD-ELV-005, 009, 029, 055 ; CTR-ELV-15.
3. Constat vérifiable : treize objets portent le prédicat de foyer sans test de rôle : student_profiles_family (0001:726) et student_profiles_family_update (0005:535), wallets_family_read, wallet_entries_family_read, payout_methods_family_read, payouts_family_read (0001:1103-1140), session_recordings_teacher_family (0001:1053), sessions_family_read (0001:1000), devices_family (0001:782), mes_seances_v (0014:888), family_sessions_v (0001:671), profils_du_foyer_v (0014:828), mes_appareils_v (0014:848), plus lesson_reports et makharij_findings (voir CP-ELV-02). Les objets voisins testent le rôle guardian (profiles_family_select 0001:708, session_participants_family_read :1026, session_events_family_read :1043, households_guardian_select :700). Le jeton de l'appareil enfant porte role student et household_id (0001:489-490).
4. Risque : sécurité et confidentialité (un enfant lit ou écrit le dossier du foyer et de sa fratrie).
5. Gravité et priorité : gravité élevée, vraisemblance moyenne (outils de développement du navigateur sur la PWA suffisent pour un adolescent), exposition : tout appareil enfant appairé ; P0.
6. Règle actuelle : "Élève L soi" ; situation 1, la décision est tranchée et l'implémentation est inégale.
7. Contre-proposition : une fonction unique est_tuteur_du_foyer(profil) (role guardian, compte valide, même foyer) réutilisée par tous les objets listés ; pour l'élève, lecture limitée à sa ligne ; UPDATE de student_profiles réservé au tuteur ; vues recréées avec une branche élève (student_id égale auth.uid()) ; access_until masqué pour l'élève.
8. Options : (a) ajouter app_role() = 'guardian' dans chaque policy, simple mais dispersé ; (b) fonction unique, recommandée ; (c) vues distinctes par rôle, plus lourdes.
9. Conséquences : ferme les fuites entre enfants ; coût : une migration et des tests ; compatibilité : l'écran élève doit filtrer défensivement ; risque résiduel : agent_ro et contrôleur à revoir.
10. Périmètre : backend (migration), contrat partagé (vues), frontend (filtre défensif).
11. Dépendances : AUD-OFR-021 ; migrations 0035 à 0037 en attente ; aucune tâche existante trouvée.
12. Critères d'acceptation : un jeton student ne peut ni modifier student_profiles ni lire, hors de sa ligne, les objets listés ; le jeton guardian reste inchangé ; les scénarios S6a et S6b restent verts.
13. Tests et preuves : nouveaux scénarios SQL avec un foyer de deux enfants et un jeton student (select, update, insert) ; test Dart : ELV-02 ne rend que ses séances.
14. Décision requise : aucune (règle déjà tranchée) ; validation technique par le propriétaire backend.

#### CP-ELV-02 - Le cahier de transmission ne se lit pas brut hors de l'enseignant

1. Identifiant : CP-ELV-02.
2. Source : DM 944 ; AUD-ELV-075.
3. Constat vérifiable : lesson_reports_reader (0001:1070-1078) et makharij_findings_read (0001:1080-1088) autorisent tout membre d'un foyer dont un enfant participe à la séance, et tout participant de la séance. Le contenu d'un cahier de groupe liste une décision par élève (modeles_enseignant.dart:620-690). Aucune lecture famille n'existe dans lib/, aucun test SQL ne couvre cette lecture.
4. Risque : confidentialité des familles, dignité (notes pédagogiques sur d'autres enfants), pédagogie (le brouillon n'est pas une décision validée).
5. Gravité et priorité : élevée ; vraisemblance moyenne (requête directe à l'API) ; P0.
6. Règle actuelle : le cahier de l'enseignant n'est pas recopié dans le compte rendu familial, une projection autorisée est servie ; situation 1.
7. Contre-proposition : limiter ces deux policies à l'auteur, au contrôleur et à l'administrateur ; servir la famille et l'élève par une projection publiée et révocable (modèle de PR 29, migration 0054, seance_resumes, lecture réservée au rôle guardian et à publie_le non nul).
8. Options : (a) correctif immédiat de la seule policy, sans conséquence pour l'interface actuelle puisqu'aucun écran ne lit ces tables ; (b) fusionner la projection de la PR 29 après revue.
9. Conséquences : plus aucune lecture brute ; la famille ne voit que le texte publié ; compatibilité totale avec l'existant ; risque résiduel : contenu publié à valider avec l'équipe pédagogique.
10. Périmètre : backend ; contrat partagé (projection) ; contenu académique pour la forme du texte famille.
11. Dépendances : B-08 (PR 29), CP-ELV-01.
12. Critères d'acceptation : un jeton guardian ou student reçoit zéro ligne de lesson_reports et makharij_findings ; la projection ne rend que les lignes publiées de son propre enfant.
13. Tests et preuves : scénarios SQL multi-foyers (deux foyers dans une séance de groupe) ; test de révocation d'une publication.
14. Décision requise : aucune pour (a) ; arbitrage du directeur sur le contenu partageable pour (b).

#### CP-ELV-03 - Observation du tuteur : une porte, un quota consommé, une annonce à l'enfant

1. Identifiant : CP-ELV-03.
2. Source : DM 254, 302, 934-935 ; AUD-ELV-042, 043, 044, 047, 048, 049 ; CTR-ELV-03, 14.
3. Constat vérifiable : le bouton Assister appelle assister_seance (service_video.dart:131) qui n'écrit pas guardian_session_visit ; budget_observation vaut donc zéro visite ; le jeton est renouvelable sans limite. La porte conforme (entrer_observation, /tc/observation/:seanceId) n'a aucun appelant (entete_classe.dart:197-200). L'annonce à l'enfant n'est pas montée (indicateur_observation.dart:19-37). 0036 et 0037 ne sont pas appliquées au 21/09.
4. Risque : protection des mineurs et confiance des familles ; fiabilité (règle produit non tenue).
5. Gravité et priorité : élevée pour l'observation illimitée, moyenne pour l'annonce ; P0.
6. Règle actuelle : deux visites de deux minutes par parent et par séance (DM, 0036) ; situations 1 et 3 (la valeur par défaut diffère dans docs/current/01).
7. Contre-proposition : (1) appliquer 0036 et 0037 après revue ; (2) remplacer l'appel à assister_seance par l'entrée du module Teaching Core, ou faire écrire guardian_session_visit par assister_seance en solution minimale ; (3) ajouter une RPC de lecture réservée à l'élève concerné (sa seule ligne) et monter IndicateurObservationEnfant dans un bloc existant ; (4) renommer le bouton "Observer".
8. Options : A, conserver assister_seance et lui faire consommer le quota (rapide, deux portes subsistent) ; B, supprimer assister_seance du parcours famille (une porte, recommandée).
9. Conséquences : quota réel, enfant informé, un seul chemin ; coût : migration, bascule du bouton, tests ; risque résiduel : l'enseignant continue de lire un observateur visible.
10. Périmètre : backend ; contrat partagé (RPC de lecture enfant) ; frontend.
11. Dépendances : LISEZ-MOI-0035-0037-non-appliquees.md ; TC-Z-SUIVI ; CP-ELV-01.
12. Critères d'acceptation : le troisième passage d'un parent dans la même séance est refusé par le serveur ; la visite interrompue est consommée ; l'enfant concerné, et lui seul, reçoit l'annonce.
13. Tests et preuves : scénario SQL de bout en bout (trois entrées, horloge serveur) ; test Dart de l'indicateur enfant avec deux élèves.
14. Décision requise : arbitrage du directeur sur la valeur par défaut (1 visite de 120 s selon 0030 et docs/current/01, 2 visites de 120 s selon 0036 et le DM) ; validation compétente sur la protection des mineurs.

#### CP-ELV-04 - Interface guidée : un nom, une source de frontière, un choix pour l'adulte

1. Identifiant : CP-ELV-04.
2. Source : DM 242, 926 ; AUD-ELV-001, 003, 004, 006 ; CTR-ELV-01, 08.
3. Constat vérifiable : quatre libellés visibles (fr.i18n.json:1161, :1309, :592, :1957) ; frontière d'âge lue à deux endroits (child_ui_mode_max_age 0004:869 et cohortes_age 0043:110-113) ; l'onboarding écrase le réglage du tuteur (0043:628-635) ; aucune commande pour un adulte.
4. Risque : cohérence UX et fiabilité (deux règles divergentes) ; dignité (un adulte ne peut pas choisir).
5. Gravité et priorité : moyenne ; P1.
6. Règle actuelle : décision du 23/09 sur le nom ; situation 1 pour le libellé, situation 3 pour la frontière.
7. Contre-proposition : un seul libellé "Interface guidée" dans les trois familles de clés ; une seule source de frontière (la table cohortes_age lue par creer_profil_enfant, ou l'inverse) ; l'onboarding ne remplace plus un réglage fait par le tuteur ; commande personnelle "Interface guidée" validée par une RPC.
8. Options : conserver le seuil dans app_config (réglable par l'administration, ADM-15) ou dans cohortes_age (lisible par l'onboarding) ; recommandation : cohortes_age avec écriture depuis ADM-15.
9. Conséquences : vocabulaire cohérent ; une migration légère ; risque résiduel : valeur du seuil à confirmer.
10. Périmètre : frontend (libellés, commande) ; backend (source unique).
11. Dépendances : B-07 (PR 29) pour l'adulte ; CP-ELV-05.
12. Critères d'acceptation : aucun libellé "Mode enfant" ni "Grand affichage" dans l'interface ; un seul seuil lu ; un adulte bascule sans passer par un tuteur.
13. Tests et preuves : test i18n qui échoue si "Mode enfant" réapparaît ; scénario SQL de dérivation unique.
14. Décision requise : arbitrage du directeur (nom du mode opposé, seuil effectif d'âge).

#### CP-ELV-05 - Adulte apprenant : profil élève titulaire et navigation propre

1. Identifiant : CP-ELV-05.
2. Source : DM 163, 266, 922 ; AUD-ELV-021, 022, 023, 030 ; AUD-IDS-069 ; CTR-ELV-02, 05.
3. Constat vérifiable : l'inscription adulte donne role guardian (inscription_page.dart:35-41), aucune ligne student_profiles n'est créée pour lui (0004:892), il arrive sur /tuteur avec l'invitation "Ajoutez votre premier enfant" ; PR 29 migration 0052 crée le profil titulaire ; ccr contient accueil_adulte, mon_espace_adulte, ma_classe_adulte.
4. Risque : fiabilité (parcours impossible à terminer pour un adulte seul), cohérence institutionnelle.
5. Gravité et priorité : élevée pour la cohorte adulte ; P1.
6. Règle actuelle : en désaccord entre ADR-009 et le DM ; situation 3.
7. Contre-proposition : reprendre B-07 de la PR 29 (profil titulaire sur le même compte, rôle technique conservé), exposer une capacité "apprenant" dans SessionState (jamais un test de rôle dans un écran), dériver la barre Aujourd'hui, Apprendre, Suivi, Profil de cette capacité, et retirer l'invitation à ajouter un enfant quand le foyer n'a que le titulaire.
8. Options : (a) maintenir le foyer d'une personne avec profil titulaire (compromis de la PR 29) ; (b) séparer le rôle technique, plus lourd.
9. Conséquences : parcours adulte complet ; compatibilité avec l'ancien rôle guardian conservée ; coût : migration 0052, nouveau shell, tests de transition.
10. Périmètre : gouvernance (arbitrage), backend, frontend.
11. Dépendances : B-07 (PR 29), CP-ELV-01, CP-ELV-04.
12. Critères d'acceptation : un adulte nouveau voit sa Classe, son Coran et son suivi sans créer d'enfant ; un compte guardian existant reste compatible.
13. Tests et preuves : recette 08.6 du DM (compte nouveau, ancien guardian, un seul profil, ancien mineur).
14. Décision requise : arbitrage du directeur (CTR-ELV-02).

#### CP-ELV-06 - Barre du tuteur et sortie de session sur téléphone

1. Identifiant : CP-ELV-06.
2. Source : DM 294 ; AUD-ELV-031, 033, 034 ; CTR-ELV-04.
3. Constat vérifiable : la barre est Accueil, Disponibilités, Réglages, Suivi (nav_shell.dart:79-100) ; le Compte (déconnexion) n'est une entrée que sur rail et barre latérale (nav_shell.dart:160-185, :300-338) ; aucun écran du tuteur ne mène à Routes.compte.
4. Risque : fiabilité (parcours critique : fermer sa session sur un téléphone partagé avec l'enfant), cohérence.
5. Gravité et priorité : moyenne ; P1.
6. Règle actuelle : shell validé Accueil, Foyer, Historique, Compte ; situation 1.
7. Contre-proposition : correctif immédiat, une ligne "Mon compte" dans TUT-05 vers Routes.compte ; puis destinationsPour(guardian) = Accueil, Foyer (Routes.tuteurFoyer), Historique (Routes.tuteurSuivi), Compte (branche), TUT-05 déplacé sous la fiche du Foyer, Disponibilités retiré de la barre après arbitrage du lot offres.
8. Options : reprendre la liste de ccr (déjà écrite) ou la réécrire ; recommandation : reprise de ccr, sans nouvelle destination.
9. Conséquences : une barre conforme, un seul chemin de déconnexion ; coût : test navigation_test à mettre à jour ; risque : les liens existants vers /tuteur/reglages.
10. Périmètre : frontend.
11. Dépendances : AUD-OFR (Disponibilités) ; décision du 24/09 à confirmer comme active.
12. Critères d'acceptation : sur 360 px, le tuteur ferme sa session en deux gestes ; la barre porte les quatre destinations du DM.
13. Tests et preuves : navigation_test.dart mis à jour ; test de widget sur 360 px.
14. Décision requise : aucune (décision déjà tranchée) ; confirmer la source docs/current absente de HEAD.

#### CP-ELV-07 - Aucune donnée de démonstration en production

1. Identifiant : CP-ELV-07.
2. Source : DM 270, 294 ; AUD-ELV-016, 024, 077, 092 ; AUD-OFR-066.
3. Constat vérifiable : portGroupesProvider et portHorlogeSeanceProvider ont un défaut de démonstration jamais surchargé (port_groupes.dart:34-39 ; port_horloge_seance.dart:54-55 ; main.dart:105-131) ; portTravailAVenirProvider vaut null.
4. Risque : fiabilité (faux succès), confiance des familles (six Classes inventées).
5. Gravité et priorité : élevée ; P0.
6. Règle actuelle : ne jamais présenter un état de démonstration comme réel ; situation 1.
7. Contre-proposition : retirer la ligne "Mes groupes" de _GererLeFoyer tant que l'adaptateur réel n'existe pas (drapeau d'environnement du type GALERIE) ; ajouter un test qui échoue si le provider de production renvoie GroupesDemonstrationLocale ; brancher les adaptateurs réels dès que le contrat de classes (PR 13 ou 29) est fusionné.
8. Options : masquer l'entrée (immédiat) ou brancher (dépend du backend).
9. Conséquences : plus de faux contenu ; la page de Classe disparaît du parcours jusqu'au raccordement.
10. Périmètre : frontend ; contrat partagé.
11. Dépendances : docs/teaching-core/TC_CONTRACT_REQUEST_A.md ; PR 13, 29.
12. Critères d'acceptation : aucune chaîne de demonstration_groupes.dart atteignable dans le build de production.
13. Tests et preuves : test de garde-fou sur la composition du ProviderScope de production ; capture du build réel.
14. Décision requise : aucune.

#### CP-ELV-08 - Second adulte : capacités déléguées explicites

1. Identifiant : CP-ELV-08.
2. Source : DM 298, 924, 163 ; AUD-ELV-054, 057, 058.
3. Constat vérifiable : à HEAD aucun modèle ; la PR 29 (migration 0053) rattache l'invité au household du titulaire avec role guardian, donc tous les droits tuteur (appareils, réglages des enfants, observation). Cette migration relève temporairement les claims JWT au rôle admin dans une fonction SECURITY DEFINER pour contourner le trigger de household_id (section repondre_invitation_conjoint).
4. Risque : sécurité (privilèges excessifs, élévation de claims), finance (lecture confondue avec recharge).
5. Gravité et priorité : élevée avant fusion de la PR 29 ; P1.
6. Règle actuelle : le second adulte ne reçoit que les droits délégués ; situation 2 (risque nouveau découvert dans une PR non fusionnée).
7. Contre-proposition : table de capacités (lire_suivi, lire_paiements, recharger, approuver, gerer_appareils, gerer_reglages_enfant) liée au profil et au foyer, fonction a_capacite() testée par chaque RPC et policy ; par défaut le second adulte reçoit lire_suivi seulement ; remplacer l'élévation de claims par un drapeau transactionnel lu par le trigger.
8. Options : capacités par table (recommandé) ou deux rôles fixes (titulaire, délégué) plus simples mais rigides.
9. Conséquences : droits lisibles et auditables ; coût : modèle et tests ; compatible avec le rôle guardian existant.
10. Périmètre : backend ; contrat partagé (capacités exposées à SessionState) ; gouvernance.
11. Dépendances : B-03 (PR 29), CP-ELV-01, finance.
12. Critères d'acceptation : un second adulte avec lire_paiements ne peut ni recharger ni approuver ; chaque capacité révocable.
13. Tests et preuves : scénarios SQL par capacité ; test de non-régression du titulaire.
14. Décision requise : arbitrage du directeur (droits par défaut du second adulte).

#### CP-ELV-09 - Contexte élève fiable et détail d'une séance dans l'Historique

1. Identifiant : CP-ELV-09.
2. Source : DM 294, 298, 944 ; AUD-ELV-035, 036, 074, 090.
3. Constat vérifiable : aucun contexte actif (accueil_famille_page.dart:248-262 ; suivi_foyer_page.dart:75-103) ; aucun détail de séance ; PR 3 fournit selectionEleveProvider (lib/core/foyer/selection_eleve.dart).
4. Risque : fiabilité (mélange d'enfants dès qu'un écran par enfant arrive), dignité.
5. Gravité et priorité : moyenne ; P1.
6. Règle actuelle : choix explicite de l'enfant, données vidées au changement ; situation 1.
7. Contre-proposition : un seul provider de contexte, des providers .family indexés par eleveId, paramètre ?eleve= validé contre le foyer ; route Historique puis Détail lisant la projection publiée (CP-ELV-02).
8. Options : réutiliser le code de la PR 3 (recommandé) ou le réécrire.
9. Conséquences : aucun mélange par construction ; dépend de CP-ELV-01 et CP-ELV-02.
10. Périmètre : frontend ; contrat partagé.
11. Dépendances : DB-FOY-01 (PR 3), B-08 (PR 29).
12. Critères d'acceptation : changer d'enfant ne laisse aucune donnée du précédent à l'écran.
13. Tests et preuves : recette 09.5 du DM (trois enfants, Classe différente par enfant).
14. Décision requise : aucune.

#### CP-ELV-10 - Préférences et notifications : les appliquer ou les retirer

1. Identifiant : CP-ELV-10.
2. Source : DM 282, 294 ; AUD-ELV-078, 079, 083.
3. Constat vérifiable : preferencesLocalesProvider n'est lu que par compte_page.dart ; main.dart passe toujours ThemeMode.system ; le modèle est en mémoire ; aucune infrastructure de notification.
4. Risque : fiabilité (actions sans effet), accessibilité (le choix de thème ou de grand texte ne s'applique pas).
5. Gravité et priorité : moyenne ; P1.
6. Règle actuelle : "un bouton qui ne peut pas aboutir n'est pas rendu" (lib/CLAUDE.md) ; situation 1.
7. Contre-proposition : brancher themeMode, animations réduites et lecture en grand texte sur RewayahApp et le lecteur, avec persistance locale (le dépôt a déjà drift) ; retirer des réglages les interrupteurs sans consommateur (notifications, économie de données) jusqu'à leur raccordement ; remplacer l'UUID et les "Non disponible" par la personne.
8. Options : tout masquer jusqu'au raccordement ou brancher par lots.
9. Conséquences : réglages honnêtes ; coût modéré.
10. Périmètre : frontend ; backend pour les notifications.
11. Dépendances : aucune tâche existante trouvée.
12. Critères d'acceptation : choisir Sombre change le thème et survit à la relance ; aucun interrupteur sans effet.
13. Tests et preuves : test de widget sur RewayahApp avec préférence modifiée ; test de persistance.
14. Décision requise : aucune.

#### CP-ELV-11 - États manquants et écran calme pour l'enfant

1. Identifiant : CP-ELV-11.
2. Source : DM 254, 1062 ; AUD-ELV-013, 039, 056, 064, 070, 082.
3. Constat vérifiable : ELV-02 présente un échec de lecture comme "Pas de cours aujourd'hui" (accueil_eleve_page.dart:166-176) ; TUT-02 et TUT-05 n'ont ni squelette ni erreur ; la révocation d'appareil n'attrape aucune erreur ; un enfant en attente ou suspendu reçoit le portail d'attente d'un adulte (attente_page.dart).
4. Risque : fiabilité, dignité de l'enfant, cohérence institutionnelle.
5. Gravité et priorité : moyenne ; P1.
6. Règle actuelle : cinq états par écran ; écran calme pour l'enfant ; situation 1.
7. Contre-proposition : état erreur d'ELV-02 à hauteur d'enfant (pictogramme, libellé parlé, Réessayer) et relecture à la reconnexion ; variante enfant du portail d'attente ("Ton accès n'est pas encore prêt. Demande à un adulte de ta famille."), sans motif monétaire ni administratif ; squelettes et erreurs sur TUT-02 et TUT-05 ; capture de l'échec de révocation ; messages d'erreur sans texte serveur.
8. Options : variante dédiée ou paramètre du composant existant ; recommandation : écran propre sous le même routeur.
9. Conséquences : états complets ; coût : textes et audios à valider.
10. Périmètre : frontend ; gouvernance pour le ton.
11. Dépendances : CP-ELV-04.
12. Critères d'acceptation : un échec réseau d'ELV-02 n'affiche jamais "aucun cours" ; aucun texte "dossier" ou "pièce" sur un profil enfant.
13. Tests et preuves : tests d'erreur d'ELV-02 et de TUT-02 ; test de la porte d'attente avec role student.
14. Décision requise : validation du directeur sur le texte destiné à l'enfant.

#### CP-ELV-12 - Code personnel de l'enfant : limiter les essais

1. Identifiant : CP-ELV-12.
2. Source : AUD-ELV-062 ; code_local.dart:20-27.
3. Constat vérifiable : code à quatre chiffres vérifié localement sans compteur ni délai (eleve_connexion_page.dart:214-252).
4. Risque : confidentialité entre frère et sœur sur l'appareil partagé.
5. Gravité et priorité : faible ; P2.
6. Règle actuelle : le code dissuade un frère ou une sœur, la barrière réelle est le jeton d'appareil ; situation 2 mineure.
7. Contre-proposition : délai croissant après trois erreurs, compteur stocké dans le coffre local, message calme.
8. Options : verrouillage temporaire ou allongement du code à six chiffres.
9. Conséquences : léger coût d'interface ; aucun effet serveur.
10. Périmètre : frontend.
11. Dépendances : aucune.
12. Critères d'acceptation : dix essais successifs ne sont plus possibles en moins d'une minute.
13. Tests et preuves : test unitaire du compteur.
14. Décision requise : aucune.

#### CP-ELV-13 - Solde du foyer : trancher le modèle avant tout écran

1. Identifiant : CP-ELV-13.
2. Source : DM 298, 306 ; AUD-ELV-037, 050, 051, 052, 053 ; CTR-ELV-13.
3. Constat vérifiable : un portefeuille unique par foyer (0001:246-251) face à l'exigence d'un sous-solde par enfant et d'allocations immuables ; aucun écran ni RPC.
4. Risque : finance (solde fantôme, double allocation) si une interface est bâtie sur le mauvais modèle.
5. Gravité et priorité : moyenne ; P1.
6. Règle actuelle : ADR-003 (finance hors MVP-0) face au DM ; situation 3.
7. Contre-proposition : écrire le contrat (portefeuille du foyer, sous-soldes par profil, allocations immuables, un paiement externe) et la politique financière versionnée avant toute interface ; l'argent reste un entier en unités mineures (déjà le cas : wallet_entries.amount_minor).
8. Options : sous-soldes comme lignes d'allocation dans wallet_entries, ou table dédiée.
9. Conséquences : évite une reprise ; aucun coût de code avant la décision.
10. Périmètre : gouvernance ; backend ; contrat partagé.
11. Dépendances : ADR-003 ; PR 3 (port_paiements_foyer.dart), ccr (recharge_foyer.dart) à auditer par le registre finance.
12. Critères d'acceptation : contrat signé ; chaque écran de solde cite la version de politique financière.
13. Tests et preuves : scénarios SQL d'allocation immuable.
14. Décision requise : arbitrage du directeur.

## 5. États d'écran et applicabilité

Légende : P présent (avec preuve), PART partiel, A absent, NA non applicable (avec raison).

| Écran | Chargement | Contenu | Vide | Erreur | Hors ligne | Session expirée | Accès refusé | Reprise |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| ELV-01 connexion enfant | PART : texte "chargement" (eleve_connexion_page.dart:278), pas de squelette | P | NA : sans profil on demande un code | P : message de code (:153), base locale indisponible (test :52) | PART : le choix de profil marche hors ligne, l'appairage non | P : jeton absent, message "codeExpire" (:241) | NA : route publique | PART : revient au choix de profil, pas de reprise d'un code saisi |
| ELV-02 accueil élève | P : squelette (accueil_eleve_page.dart:172-175 ; test :126) | P : six états | P : aucun cours, annulée | A : faux vide (AUD-ELV-013) | P : test :351 | Routeur (AUD-ELV-086) | Routeur (AUD-ELV-085) | PART : minuteur d'une minute, aucune relecture (AUD-ELV-008) |
| Suivi élève | P : squelette (suivi_eleve_test.dart:152) | P | P : test :172 | P : message et Réessayer (test :182) | PART : bandeau de PageShell, pas de cache démontré | Routeur | Routeur | P : bouton Réessayer |
| Compte et profils | NA pour le compte (session synchrone) ; P pour les profils (compte_test.dart:188) | PART : champs fictifs (AUD-ELV-079) | P : aucun profil | P : compte_test.dart:206 | PART : bandeau | Routeur | Routeur | P : Réessayer |
| TUT-01 accueil famille | P : squelette (accueil_famille_test.dart:167) | P : cinq phases | P : aucun enfant, invitation à en ajouter | PART : message sans retrait des cartes (AUD-ELV-039) | PART : bandeau ; Assister échoue avec message (:280) | Routeur | Routeur | PART : minuteur ; aucune relecture automatique |
| TUT-02 foyer et appareils | A | P | P : aucun enfant (appareils_test.dart:131) | A (AUD-ELV-070, 064) | PART : bandeau | Routeur | Routeur | A : tirage-pour-rafraîchir retiré (appareils_page.dart:30-41) |
| TUT-02/a ajout d'un enfant | P : enCours | P | NA | P : t.enfant.erreur | PART : échec générique | Routeur | Routeur | PART : saisie conservée dans la page |
| TUT-02/b appairage | P : texte de chargement | P : QR et code | NA | P : message et Réessayer (appareils_test.dart:194) | PART | Routeur | NA | P : code expiré, régénérer (test :176) |
| TUT-05 réglages par enfant | A | P | P : aucun enfant | PART : erreur d'écriture en texte brut (AUD-ELV-082) | PART : bandeau | Routeur | Routeur | PART : relecture après écriture |
| TUT-06 suivi du foyer | P : squelette (suivi_foyer_test.dart:334) | P | P : trois états vides (test :241-282) | P : message et réessayer (test :315) | PART : bandeau | Routeur | Routeur | P : relire |
| Mes groupes et Espace Groupe | P (squelette de cartes) | PRÉSENT_MAIS_NON_RACCORDÉ : données fictives | P | P : message et Réessayer (mes_groupes_page.dart:60-70) | P : paramètre horsLigne | Routeur | Routeur | PART |
| Observation TC-G | P | PRÉSENT_MAIS_NON_ROUTÉ | NA | P : motifs de refus (libelles_observation.dart) | PART | Routeur | P : refus serveur typés | NA |

Applicabilité. "Session expirée" et "Accès refusé" sont traités par le routeur (redirection.dart:39-47, :114-115) et valent pour tous les écrans ; l'accès refusé réel est la RLS, qui renvoie des lignes vides ou une erreur, jamais un écran dédié. "Données révoquées" et "contenu supprimé" ne s'appliquent à aucun écran de ce domaine à HEAD (aucun support téléchargé, aucune projection publiée). "Opération réussie confirmée" n'existe que pour les demandes du tuteur (reglages_enfant_page.dart, "demandeEnvoyee").

## 6. Non vérifié et limites de la preuve

- Aucun test n'a été exécuté (Flutter, Dart et Postgres absents). Les tests cités sont "lus, non exécutés". Les statuts CONFORME_PROUVÉ reposent sur une chaîne lue de bout en bout et un test nommé ou une contrainte SQL, pas sur un résultat vert.
- Les fuites et écritures indues (AUD-ELV-005, 009, 029, 055, 075) sont établies par la lecture des policies, des vues et des grants. Elles n'ont pas été rejouées avec un jeton élève réel : elles sont donc "non rejouées". Le hook de jeton (0001:489-490, 0038) donne role et household_id à un élève ; si l'environnement émettait un jeton différent, la conclusion serait à réviser.
- L'état réel des bases staging et production (migrations 0035 à 0037, 0043 et suivantes appliquées ou non) n'est pas connu. La seule source est LISEZ-MOI-0035-0037-non-appliquees.md, datée du 21/09. Les migrations 0039 à 0042 n'existent pas à HEAD.
- Le contenu de ccr n'a pas été audité : les dossiers cités (accueil_adulte, foyer, classe_tuteur, suivi_famille, mon_espace_adulte, consentements, paiements_recus) sont des pointeurs, pas des preuves de conformité. Seules deux parties de la PR 3 et trois migrations de la PR 29 ont été lues.
- Les fonctions Edge (session-enfant, creer-profil-enfant) ont été lues par le registre identité ; elles ne sont pas relues ici.
- Rendu visuel, contraste mesuré, lecteur d'écran, navigation clavier, zoom réel et RTL réel : non vérifiables sans build. Les tests de rendu vérifient l'absence d'exception.
- Les maquettes du Tuteur et les captures de ccr n'ont pas été lues : aucune conformité visuelle n'est affirmée.
- La convention active Sayyid ou Sayyida, la qualification "anxiogène" d'une animation, la forme du texte partageable avec les familles et la distinction Fait / Maîtrisé relèvent de la direction et de l'autorité académique. Aucune règle religieuse ou scientifique n'a été décidée ici ; les validations pédagogiques du référentiel (DM 946) restent à afficher comme dépendances.
- Les recettes du DM (08.6, 09.5) ne sont pas rejouables à HEAD : aucun compte adulte autonome, second adulte ni solde n'existe dans le code audité.
- Le natif Android et iPad n'est pas prouvé ; seul le comportement du code partagé a été lu.
- Aucune RÉGRESSION n'est déclarée : l'historique Git n'a pas été comparé version par version pour ce domaine.
