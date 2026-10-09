# Index de l'export du tableau « Suivi Rewayah » (09/10/2026)

Une ligne par fiche, avant le ménage du 09/10. Le contenu complet de chaque fiche est dans `export_tableau_2026-10-09.tar.gz` (un fichier JSON par fiche : `<collection>/<id>.json`).

## etapes (457)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| AD-1 | verifie |  | Relevé du code existant (§3, §24) : route et entrées d'ADM-02, 3 libellés exacts des vérifications, blocage lié au genre, politique Super Ad |
| AD-10 | verifie |  | Parcours tuteur, famille et titulaire : famille sans pièce requise, /attente après refus puis Corriger, retour après validation (P-ADM-08, 0 |
| AD-11 | verifie |  | Recette : accessibilité (reflow 320, clavier, focus jamais masqué, texte à 200 %), planche de validation (4 captures par écran) |
| AD-2 | verifie |  | Revue UX 2026 des dispositions proposées (règles gelées §4) |
| AD-3 | verifie |  | Maquettes : 6 images fournies par le directeur (02A bureau sombre, 02A mobile clair, 02B mobile sombre, 02C bureau sombre, 02D bureau sombre |
| AD-3R | verifie |  | Relevé des maquettes : compléter V/00_MAQUETTES.md avec les libellés réels (AD-1) et les textes de la spec, rectifications écrites, aucun re |
| AD-4 | verifie |  | Socle de démonstration admin : ports des services du §17 sans serveur, jeu de données synthétique (« Document fictif »), mention Démonstrati |
| AD-5 | verifie |  | ADM-02A, file des dossiers : 390 / 768 / bureau 1440 en maître-détail (file 336, écart 24, détail 728), squelettes, 7 états |
| AD-6 | verifie |  | ADM-02B, revue du dossier : 4 cartes, vérifications réelles (AD-1), 8 états |
| AD-7 | verifie |  | ADM-02C, visionneuse de pièce : modale sur ordinateur, plein écran sur mobile, zoom, Échap et retour du focus, 6 états |
| AD-8 | verifie |  | ADM-02D refus et ADM-02E validation, décision réussie, résultat inconnu sans double décision (P-ADM-10) |
| AD-9 | verifie |  | Politique de genre KYC (D-ADM-KYC-GENRE-01) : réglage réservé au Super Admin ; désactivée, le genre ne filtre plus rien ; profil du reviewer |
| AD-9-ONGLET-PROD | fait | 03/10 | Admin, politique de genre : ne pas montrer l'onglet réservé sur la route avant de connaître la capacité |
| AD-BR | verifie |  | Besoins serveur de la spec 03 (§16, §17, §28) : RPC, RLS, audit, atomicité, concurrence, politique de genre côté serveur |
| AD-FOCUS-MD | fait | 03/10 | Admin, file des dossiers : garder le focus après la décision quand il n'y a pas de dossier suivant |
| AD-G0 | fait |  | Publier les règles gelées DESIGN-GOV-2026-09-26 : mémoire, CLAUDE.md, lib/CLAUDE.md, charte UX, tableau |
| AD-G1 | verifie |  | Contrôle par une seconde session : les règles gelées sont présentes et identiques mot pour mot dans les 4 emplacements |
| AD-M2-CAPT | verifie | 04/10 20:00 UTC | Captures admin HL-A-5 : écran 3 (lien vers la carte Vérifications), écran 16 publié, comptes des fiches |
| AD-M2-PLANCHE | fait | 03/10 | Planche admin : remplacer les écrans /attente d'AD-10 par les captures HL-A-5 |
| AD-M3-PROD | fait | 03/10 | Admin : fermer en production le refus et l'aperçu des pièces jusqu'à BR-1 (décision S1 → a du 27/09) |
| AD-M3-PROD-R | fait | 04/10 | Revue croisée AD-M3-PROD, CTRL-BR-OBS-1 et AD-T-LECTURE (corrections/c1-adm3) |
| AD-M4-DEFIL | fait | 03/10 | PageShell : garder la position de défilement à la bascule de structure, test sur une vraie page |
| AD-NETTOYAGE | fait | 03/10 | Admin : mineurs restants d'AD-R et d'AD-RC, références de commits d'AD-RC.md |
| AD-NETTOYAGE-2 | verifie | 04/10 20:00 UTC | Admin : mineurs restants d'AD-R/AD-RC (attente_page m6-m8, m11 ; n1, n3-n8, n10-n12 ; PageShell et decider()) |
| AD-R | verifie | 27/09 | Revue croisée du lot Admin par une autre session |
| AD-RC | fait | 27/09 | Corriger les majeurs de la revue AD-R (M1, M2, M4, M5 partie CL-4, M3 partie sans arbitrage) |
| AD-S | verifie |  | Coque admin (visible sur 02A) : AdminShell existant aligné, barre latérale 288 à 7 entrées (routes existantes), en-tête titre, sous-titre, t |
| AD-T-LECTURE | fait | 03/10 | Admin, revue des pièces : un test qui prouve la porte de lecture, titres de test exacts |
| AD-X | verifie |  | Reste du rôle admin d'après les images V/coque/ : accueil (SHELL-01), espace de traitement (SHELL-02), collection et inspecteur (SHELL-03) |
| ALERTE-1 | fait | 01/10 | Alertes urgentes : en haut de l'écran dès leur arrivée, et signalées immédiatement par les notifications |
| ALERTE-1b | fait | 05/10 | ALERTE-1b — Réserves de ALERTE-1 (fusionné ; décision du 05/10 confirmée, choix a : urgent = sécurité d'un enfant signalée en séance, incide |
| ANNUL-VIS-1 | verifie | 01/10 | Séance annulée : visuel distinct en rouge (couleur d'erreur des jetons) + icône + texte |
| AR-COMPLET-1 | a_faire | 08/10 | Interface arabe hors Communications : 3531 clés françaises sans traduction arabe (admin 601, tc 421, enseignant 398, …) |
| ASSETS-DIR-1 | a_verifier | 05/10 | Intégrer les assets du directeur : coordonnées légales (fait, à revoir), puis logo |
| AVATAR-1 | verifie | 01/10 | Avatar : petit cercle, moins de texte, centré (pas aligné à gauche) |
| BENTO-1 | fait | 01/10 | Tableaux de bord en vraie grille Bento : cartes de tailles variées (longues, larges, carrées) imbriquées |
| BENTO-1b | fait | 03/10 | Grille Bento : ne pas tomber à une seule colonne sur ordinateur dès 115 % de texte ; déclarer les 2 libellés nouveaux |
| BENTO-1b-R | fait | 03/10 | Revue croisée de BENTO-1b (grille Bento selon la largeur par colonne) |
| BENTO-1c | fait | 03/10 | Grille Bento, mineurs de BENTO-1b : tests à valeurs fixes, rien ne change à 100 %, palier à 3 colonnes, règle D12 |
| BENTO-1c-R | fait | 03/10 | Revue croisée BENTO-1c |
| BENTO-2 | fait | 02/10 | Grille Bento sur les autres tableaux de bord (élève, tuteur, enseignant, élève adulte, contrôleur) |
| BENTO-2-R | fait | 03/10 | Revue croisée BENTO-2 |
| BENTO-2b | fait | 03/10 | Grille Bento : corriger les défauts de la revue BENTO-2-R (carte classe de l'accueil famille coupée sur tablette) |
| BENTO-2b-R | fait | 03/10 | Revue croisée BENTO-2b |
| BENTO-2c | fait | 04/10 | Grille Bento : corriger la revue BENTO-2b-R (« À terminer » coupé à 320 x2 avec « Voir tout », famille 600-630 x2, tests et docs) |
| BENTO-2c-R | fait | 04/10 | Revue croisée BENTO-2c (corrections de BENTO-2b-R) |
| BENTO-3 | fait | 02/10 | Grille Bento : contrôleur et élève adulte (suite de BENTO-2) |
| BENTO-3-R | fait | 04/10 | Revue croisée BENTO-3 |
| BENTO-3b | fait | 04/10 | Réserves de BENTO-3-R : encodage du test adulte, fusion dans la branche commune, captures 320x2 refaites |
| BENTO-3b-R | fait | 04/10 | Revue croisée BENTO-3b (réserves de BENTO-3-R) |
| BENTO-3c | fait | 04/10 | Réserves de BENTO-3b-R : tests d'ordre à texte ×2, test du contrôle « mot coupé » en vraie police, largeurMinCarteClasse partagée |
| BENTO-3d | fait | 05/10 | test de bascule du seuil côte à côte du squelette de chargement de l'accueil adulte (largeurMinCarteClasse × max(1, échelle)) avec contre-ép |
| BLOC-BIB-1 | fait | 04/10 | Bloc Bibliothèque : titre « Ressources de la classe » rétréci à texte ×2 et « Voir tout » à part |
| BLOC-BIB-1b | fait | 05/10 | test et captures du titre « Ressources de la classe » sur Ma classe de l'élève adulte ; captures 1440 x2, 390 x2 sombre RTL et Interface gui |
| BR-1 | a_faire |  | Branchement backend et configuration, en une seule fois, après validation de TOUS les visuels |
| BTN-CENTRE-1 | verifie | 01/10 | Appliquer K-54 : centrer le contenu de tous les boutons (horizontal + vertical) dans toute l'app |
| BTN-TESTER-1 | verifie | 01/10 | Préparation de séance (enseignant) : bouton « Tester la caméra » mal placé, doit prendre la largeur de la carte |
| BUG-PROG-1 | verifie | 01/10 | Programmes (admin) : il faut cliquer deux fois sur « Créer une version » pour ouvrir la feuille du formulaire |
| C1-ADM3-SUITE | dev_ok | 04/10 | Suite de AD-M3-PROD-R : commentaires périmés, test du contrôleur durci |
| C1-CTRL-R | fait | 04/10 | Revue croisée du lot contrôleur (CTRL-MSG-1, CTRL-SEANCE-1, CTRL-RETOUR-1, CTRL-DELAI-1) |
| C1-DEMOENV-R | fait | 04/10 | Revue croisée c1-demoenv (DEMO-ENV-1, AD-FOCUS-MD, AD-9-ONGLET-PROD, AD-M4-DEFIL) |
| C1-DEMOENV-SUITE | dev_ok | 04/10 | Suite de C1-DEMOENV-R : garde de démonstration testée, libération des défileurs, état hors ligne de la politique |
| C1-FORM-R | fait | 04/10 | Revue croisée des formulaires automatisés (FORM-L2, L4-11-12, L5, L6) |
| C1-LIB-R | fait | 04/10 | Revue croisée du lot libellés et documents (LIB-LOT3-2, INTEG-MINEURS-1, DOC-VERIF-1, AD-NETTOYAGE) |
| C1-MA-R | fait | 04/10 | Revue croisée du lot Mode Accessibilité (MA-CORAN-TETE-1, MA-APRES-1, MA-DEC-1, MA-TUTOIEMENT-1) |
| C1-SALLE-R | fait | 04/10 | Revue croisée du lot salle (CTRL-SON-1, CTRL-AGRANDIR-1, CTRL-PREVOL-1, SALLE-CORR-3, SALLE-200-2) |
| CAPT-AD-HLA5-1 | verifie | 08/10 | Tests de capture ad10_parcours et ad6_revue rouges sur la base (bouton « Valider le dossier » / « Approuver » caché tant que les vérificatio |
| CAPT-L1-2 | verifie | 04/10 20:00 UTC | Refaire les captures « après » de MA-NAV-1 (postérieures à 703ca08) et d'ONGLETS-1 (vrais écrans, ×2, sombre) |
| CARTES-ECART-1 | verifie | 01/10 | Appliquer K-55 : décoller les cartes sur tous les écrans (style des écrans tuteur) |
| CARTES-PERSO-1 | fait | 01/10 | Cartes de la classe personnalisables par l'enseignant, visibles du tuteur et des élèves (enfant et adulte) |
| CARTES-PERSO-1b | fait | 05/10 | CARTES-PERSO-1b — Reprise de CARTES-PERSO-1 (branche corrections/c2-cartes-perso @ bcb25e20, déjà corrigée une fois : feuille de l'enseignan |
| CARTES-PERSO-1c | en_cours | 09/10 | CARTES-PERSO-1c — Réserves de CARTES-PERSO-1b (rapport REVUE_CARTES-PERSO-1b-R.md) : (1) isole dans leur sens de lecture les lignes « Échéan |
| CI-D2 | fait | 02/10 | Contrôle automatique des demandes de fusion vers ui/** (D2) : validation du directeur |
| CLASSE-FORM-1 | a_faire | 01/10 | Formulaire de création de classe semi-automatique et complet (le mot « groupe » devient « classe ») |
| CLASSE-LIVE-ENCRE-1 | verifie | 05/10 nuit | Classe en direct : « Vous êtes seul dans la salle pour le moment » écrit sombre sur le fond sombre de PageImmersive (thème clair) |
| COM-0 | fait | 04/10 | Préparation Communications V1 : inventaire L0 du dépôt, UX_REVIEW_COMMUNICATIONS_L0, COM-BR, questions |
| COM-0b | dev_ok | 04/10 | Complément de COM-0 : appliquer les 37 réserves de REVUE_COM-0 dans UX_REVIEW, COM-BR, 02_DECOUPAGE, QUESTIONS (Q5) |
| COM-ANN-1 | verifie | 04/10 | NotificationCenter partagé et annonces de Classe : filtres, niveaux, ClassAnnouncementCard, détail (COM-M06) |
| COM-ANN-2 | verifie | 04/10 | Administration des communications (COM-W04) : AnnouncementPublisher, annonces planifiées, AudienceRulesMatrix, ModerationQueue |
| COM-CAPT | verifie | 04/10 | Captures Communications : chaque écran COM-* en 390, 768 et 1440, clair et sombre, avec les états clés |
| COM-COMU-1 | verifie | 04/10 | Communauté enseignants : flux, catégories, publication, réponses, Enregistrer, Signaler (COM-M02, COM-W02) |
| COM-COMU-2 | verifie | 04/10 | CommunityPromotionGuard : politique anti-promotion, états bloqué et averti, 4 états de lien, motifs de signalement |
| COM-F | fait | 04/10 | Socle Communications (L1) : branche ui/communications-v1, modèles UI, badge non lu, composer texte, pièces jointes, états, ResponsiveWorkspa |
| COM-F-Q5 | verifie | 04/10 | Cloches enseignant, contrôleur et admin (réponse COM-Q5), sur ui/communications-v1 |
| COM-F-Q5-R | fait | 04/10 | Revue adverse indépendante de COM-F-Q5 (cloches, ui/communications-v1 @ d04bbeba) |
| COM-F-R | fait | 04/10 | Revue de COM-F (socle Communications) sur ui/communications-v1 @ b0cc9243 |
| COM-F-b | verifie | 04/10 | Corrections de COM-F-R (compléments COM-0b, galerie des composants) |
| COM-F-b-R | fait | 04/10 | Revue de COM-F-b (compléments COM-0b, galerie des composants) sur ui/communications-v1 @ e31df591 |
| COM-FUS | verifie | 04/10 | Fusion Communications : 5 sous-branches dans ui/communications-v1, vocal branché dans Messages et Studio, suite complète |
| COM-IMPACT-ACCUEIL | fait | 08/10 | Report hors COM : le compte à rebours de l'Accueil famille et de l'Accueil élève arrondit désormais au supérieur |
| COM-MSG-1 | verifie | 04/10 | Messages métier : liste des fils, fil contextuel, ContextThreadHeader, ThreadContextPanel (COM-M01, COM-W01) |
| COM-MSG-2 | verifie | 04/10 | Messages métier : entrées réelles par rôle (Classes enseignant, cloche, Espace Classe tuteur, admin, mission contrôleur) |
| COM-Q | fait | 04/10 | Questions du directeur sur Communications V1 (après COM-0) |
| COM-Q5 | fait | 04/10 | Question au directeur : remettre la cloche chez l'enseignant, le contrôleur et l'admin (et rebrancher celle de la Classe live) ? |
| COM-R | fait | 04/10 | Revue croisée Communications V1 (L6) : produit, UX/UI, sécurité communautaire, accessibilité, architecture |
| COM-R-2 | fait | 05/10 | Contre-vérification de COM-RC (R-01 à R-28 de REVUE_COM-R.md) |
| COM-R-3 | fait | 05/10 | Contre-vérification du tour 4 de COM-RC |
| COM-R-4 | fait | 05/10 | Contre-verification de COM-RC-5 (decisions du 05/10 + 8 mineurs) a a1a33222 |
| COM-R-5 | fait | 05/10 | Contre-verification de COM-RC-6 (3 mineurs de COM-R-4 et captures) a 145af740 |
| COM-R-6 | fait | 08/10 | Contre-verification de COM-RC-7 (tous les defauts restants) a 5c0bffa3 |
| COM-R-7 | fait | 08/10 | Contre-vérification de COM-RC-8 à 8b1240ac |
| COM-RC | verifie | 04/10 | Corrections de la revue Communications |
| COM-RC-5 | verifie | 05/10 | Communications : appliquer les décisions du 05/10 (R-03, R-08, R-12, R-16, R-19, R-27, R-28, focus 320, icônes, fiches UX Studio, libellés)  |
| COM-RC-6 | verifie | 05/10 | Communications : 3 mineurs de COM-R-4 (§8.3) et captures COM-CAPT après le tour 5 |
| COM-RC-7 | verifie | 08/10 | Communications : corriger TOUS les défauts restants (Envoyer à 1440, micro à 320x2, retrait de Mode focus, champ du Studio à 390, ligne de c |
| COM-RC-8 | verifie | 08/10 | Communications : mineurs de COM-R-6 (§10.3) — trace des libellés du tour 7, guillemets arabes en ordre logique |
| COM-STU-1 | verifie | 04/10 | Le Studio, canal : liste des canaux, visibilité, fil, panneau Fichiers/Épinglés/Membres, recherche, Enregistrer (COM-M03, COM-W03) |
| COM-STU-2 | verifie | 04/10 | Le Studio, Aujourd'hui : StudioTodayBoard, ActivityInbox, brouillons (COM-W00, COM-M04) |
| COM-STU-3 | verifie | 04/10 | Le Studio, Mode focus : état local de COM-W03, sortie Échap, restauration complète (COM-W03F, COM-M05) |
| COM-VOC-1 | verifie | 04/10 | VoiceMessageComposer : 17 états, limite 3:00, pré-écoute, permission micro (sans serveur) |
| CONTRASTE-SUPPORT-1 | a_faire | 02/10 | Salle : texte du support partagé en encre sombre sur fond sombre (« Présenté : page 42 », « 42 / 604 », titre d'erreur) |
| CORAN-320-1 | fait | 04/10 | Page Coran (mushaf) à 320 px et texte x2 : presque aucune ligne de texte visible (en-tête de sourate, mentions, pagination) |
| CORAN-320-1b | en_cours | 09/10 | CORAN-320-1b — Réserves de CORAN-320-1 (rapport REVUE_CORAN-320-1-R.md). Exception déléguée du 05/10 élargie à l'habillage seul : le texte d |
| CORAN-CARTE-1 | fait | 04/10 | Accueil élève : carte « Le Coran / À lire quand tu veux » — icônes mal disposées, tout collé ; chaque élément à part et lisible |
| CORR-SUITE-1 | verifie | 03/10 | Remettre au vert la branche des corrections (5 tests rouges trouvés par VERIF-CORR-SUITE) |
| CORR-SUITE-1-R | fait | 03/10 | Revue croisée de CORR-SUITE-1 (3 commits sur la branche des corrections) |
| CORR-SUITE-2 | fait | 03/10 | Mineurs de CORR-SUITE-1 : borne de 200 px des marques de Mes Classes sur ordinateur, test RTL, galerie Bento fidèle |
| COUPE-MOTS-1 | fait | 03/10 | Mots coupés en plein milieu à 320 px (surtout texte ×2) : titres de page, « À terminer », photo, Réglages |
| COUPE-MOTS-1-R | fait | 03/10 | Revue croisée du lot « mots coupés » (COUPE-MOTS-1, PASTILLE-COUPE-1, CORR-SUITE-2) |
| COUPE-MOTS-1b | verifie | 04/10 20:00 UTC | Réserves de COUPE-MOTS-1-R : rail enseignant qui annule le texte à 200 %, mesure « écran entier » par rôle en CI, mineurs |
| COUPE-MOTS-2 | fait | 03/10 | Restes « mots coupés » dans les pages de la voie Bento : « À terminer » de la Journée, capture de la Journée, légende de Mes Classes en arab |
| COUPE-MOTS-2-R | fait | 04/10 | Revue croisée COUPE-MOTS-2 (légende de Mes Classes en arabe) |
| COUPE-MOTS-3 | fait | 05/10 | Mots coupés relevés par les revues des réserves : « Chapit / re 1 » dans la ligne « Progression de la Classe » de l'Espace Classe enseignant |
| COUPE-MOTS-3b | fait | 05/10 | COUPE-MOTS-3b — Réserves de COUPE-MOTS-3 (fusionné) : (1) captures manquantes en sombre, à 390 et à 1440 (en plus de 320 x2 clair) pour les  |
| COUPE-MOTS-4 | en_cours | 09/10 | COUPE-MOTS-4 — Mots coupés à 320 px texte x2 relevés par les relectures du lot 4 : (1) ChoiceCardGroup (composant partagé du core) coupe « n |
| COUPE-MOTS-CTRL-1 | verifie | 04/10 20:00 UTC | Contrôle à 320 px texte ×2 : « à observer maintenant » coupé en pleine lettre |
| CPT-0 | verifie | 04/10 20:00 UTC | Préparation Comptable V1 (FIN-L0) : UX_REVIEW_FINANCE_COMPTABLE_L0, DEVOIR_DE_REGARD_FINANCE, CPT-BR, fichiers par étape |
| CPT-BEN-1 | fait | 04/10 | Bénéficiaires vus par le Comptable (FIN-L4a) : W07 profil de paiement masqué, Relancer, Demander une mise à jour, Suspendre |
| CPT-BEN-2 | fait | 04/10 | Recevoir mes paiements (FIN-L4b) : surface personnelle de l'enseignant et du contractuel, notice infos manquantes, bénéficiaire externe invi |
| CPT-CAPT | fait | 04/10 | Recette visuelle Comptable : captures 390 et 1440, clair et sombre, 320 texte ×2, RTL, R-FIN-24 à 29 |
| CPT-COM | a_faire | 04/10 | Relancer branché sur les vrais Messages métier de Communications V1 (R-FIN-20) |
| CPT-CTR-1 | fait | 04/10 | Contractuels & obligations (FIN-L7) : W06, récurrent et ponctuel, Nouvelle obligation selon délégation, vue des approbations |
| CPT-DIR-1 | fait | 04/10 | Delta Direction (FIN-L8) : StrategicReservePolicyPanel et FinanceDelegationPolicyPanel dans la Finance Direction existante |
| CPT-DIR-2 | verifie | 05/10 | Comptable : pourcentages masqués avec les montants (Q-9), espace traduit en arabe (Q-10), registre des écrans dans UX_REVIEW (Q-11 = b : ins |
| CPT-ENC-1 | fait | 04/10 | Encaissements (FIN-L6a) : W05 table avec filtres et panneau détail, M02 écran 2 |
| CPT-ENC-2 | fait | 04/10 | Rapprochement et remboursements (FIN-L6b) : ReconciliationWorkspace, doublon potentiel, avoirs |
| CPT-F | verifie | 04/10 20:30 UTC | Socle Comptable (FIN-L1) : branche ui/comptable-v1, shell et navigation du rôle, routes de toutes les surfaces, SensitiveAmount, statuts, vi |
| CPT-FUS | fait | 04/10 | Fusion Comptable : 6 sous-branches dans ui/comptable-v1, liens d'Aujourd'hui vers les vrais écrans, suite complète |
| CPT-JOUR | fait | 04/10 | Aujourd'hui du Comptable (FIN-L2) : FIN-CPT-W01 et premier écran de M01, file d'attention, alertes, carte Réserve stratégique en lecture |
| CPT-PAY-1 | fait | 04/10 | Paiements à effectuer (FIN-L3a) : liste W02 avec filtres, détail explicable W03, versions mobile M01 (Paiements, Détail) |
| CPT-PAY-2 | fait | 04/10 | Payer (FIN-L3b) : PayoutConfirmationSheet, lot avec préflight, Validation supplémentaire, auto-payout bloqué, infos manquantes |
| CPT-Q | fait | 04/10 | Questions Comptable V1 au directeur (seulement si CPT-0 trouve un point bloquant) |
| CPT-R | fait | 04/10 | Revue croisée Comptable V1 : ordre de regard §59 (16 questions), sécurité §47, recettes R-FIN-01 à 29 |
| CPT-RC | verifie | 04/10 | Corrections de la revue Comptable, suite complète et fermeture selon les critères §61 |
| CPT-TRES-1 | fait | 04/10 | Trésorerie & coffres (FIN-L5a) : W04 et M02 écran 1, 7 coffres, TreasuryVaultCard, StrategicReserveCard et ses indicateurs |
| CPT-TRES-2 | fait | 04/10 | Mouvements entre coffres (FIN-L5b) : TreasuryInternalTransfer, Alimenter la Réserve stratégique, retrait sensible, historique, prévision |
| CPT-VAL-1 | verifie | 05/10 | Direction : onglet « À valider » de la Finance qui reçoit les demandes du Comptable (Q-8 = a ; Valider / Refuser, motif obligatoire, jamais  |
| CT-0 | verifie | 27/09 | Préparation : planches, règles C1-C21, découpage, reprise |
| CT-10 | verifie | 02/10 | Lexique, CT-BR.md, bloquants et impacts sur les autres rôles au tableau |
| CT-11 | verifie | 27/09 | Revue des données visibles : champs interdits, aucune démonstration en production |
| CT-12 | verifie | 02/10 | Recette : 32 scénarios du doc §16, captures 390/768/1440 clair et sombre, 200 %, RTL, clavier |
| CT-1a | fait | 27/09 | UX_REVIEW_08_CONTROLEUR.md (DESIGN-GOV §4), obligatoire avant le code |
| CT-1b | verifie | 27/09 | Socle : coquille à 4 destinations, controleur_demo, route /demo/controleur gardée, squelette de captures |
| CT-1m | verifie | 27/09 | CONTROLEUR_EXISTING_MAPPING.md : fonction, route, composant (fichier:ligne) |
| CT-2 | verifie | 27/09 | CTR-01 Contrôle refondu : une seule carte de mission, « Commencer le contrôle » seulement pendant le cours |
| CT-3 | fait | 27/09 | CTR-02 Observation dans /salle (Contrôle Rewayah, son reçu, agrandir, quitter) |
| CT-4 | verifie | 27/09 | CTR-03 Compte rendu initial : faits automatiques, 3 choix, transmission automatique à l'administration |
| CT-5 | verifie | 27/09 | CTR-03A Observation structurée : nature, domaine, personne, texte, récapitulatif |
| CT-6 | verifie | 27/09 | CTR-04 Échanges avec l'administration : fils par mission, contexte épinglé |
| CT-7 | verifie | 02/10 | CTR-05 Historique et CTR-06 Détail |
| CT-8 | verifie | 02/10 | CTR-03B Complément, rapport d'origine intact |
| CT-9 | verifie | 27/09 | Changement d'espace et états transverses (révoqué, indisponible, sans capacité) |
| CT-BLQ-06 | fait | 02/10 | DPIA du contrôle |
| CT-R | verifie | 02/10 | Revue croisée par une autre session (C1-C21, R1-R21, K-42, contrats A-E, décisions du 27/09) |
| CT-RC | verifie | 02/10 | Corrections de la revue, puis planche web du directeur |
| CT-RC-m4 | verifie | 02/10 | Auteur d'un complément affiché (« date, heure · auteur ») |
| CTA-FIN-1 | fait | 01/10 | Bouton principal d'une séance selon son moment : avant / en direct / temps écoulé → « Remplir le cahier de transmission » |
| CTRL-AGRANDIR-1 | fait | 03/10 | « Agrandir le support » agrandit l'enseignant, aucun support dans /salle |
| CTRL-BR-OBS-1 | fait | 03/10 | inscrire à BR-1 l'appel observerEnControle avant /salle (BR-CT-19) |
| CTRL-DELAI-1 | dev_ok | 03/10 | Contrôleur : un envoi sans réponse ne bloque plus l'écran |
| CTRL-MSG-1 | dev_ok | 03/10 | Contrôleur : message juste quand la visite n'est plus en mémoire, et échec d'observation sans texte |
| CTRL-MSG-2 | verifie | 04/10 20:00 UTC | Corrections de C1-CTRL-R (séance inconnue sans sortie, échec d'envoi à 320 x2) |
| CTRL-PREVOL-1 | fait | 03/10 | un contrôleur sans micro peut entrer dans /salle |
| CTRL-RETOUR-1 | dev_ok | 03/10 | Contrôleur : retour système dans le Complément recule d'une étape, tests de rattachement manquants |
| CTRL-ROSTER-C7-1 | fait | 03/10 | liste de l'observation en prénom et initiale du nom (décision C7 = a) |
| CTRL-ROSTER-C7-1b | fait | 05/10 | isoler le libellé « Prénom N. » (U+2068…U+2069, comme _isole de mes_classes_page.dart, idéalement factorisé et partagé avec l'Historique) ;  |
| CTRL-SALLE-1 | verifie | 02/10 | Salle vue par le contrôleur : avatars trop gros et débordants, notice « visite de contrôle » inutile pour lui, un seul contrôle à la fois pa |
| CTRL-SEANCE-1 | dev_ok | 03/10 | Contrôleur : relevé et liste des élèves rattachés à la séance, contrat serveur à jour |
| CTRL-SON-1 | fait | 03/10 | appliquer C5 = a, retirer « Son reçu » de la salle du contrôleur jusqu'à BR-1 |
| DASH-1 | fait | 01/10 | Tableau de bord = résumé + liens vers les pages dédiées ; étudier une stratégie éprouvée de disposition et de contenu |
| DASH-ADM-1 | fait | 03/10 | Centre de commande selon la stratégie DASH-1 §3.1 (liste retirée, noms cliquables, Groupes, squelette Bento, erreurs) |
| DASH-ADM-1-R | fait | 04/10 | Revue croisée DASH-ADM-1 (Centre de commande selon DASH_STRATEGIE §3.1) |
| DASH-ADM-ECHUS | fait | 03/10 | Comptes : filtre « accès échus » ouvrable par une adresse (lien depuis le Centre de commande) |
| DASH-ADM-ECHUS-R | fait | 04/10 | Revue croisée DASH-ADM-ECHUS (Comptes filtrée sur les accès échus) |
| DASH-ADM-ECHUS-b | fait | 04/10 | Corrections de DASH-ADM-ECHUS après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| DASH-ADM-INC | a_faire | 03/10 | Journal filtré par adresse (« incidents des 24 dernières heures »), puis tuile Incidents en lien |
| DASH-ADM-PLANNING | a_faire | 03/10 | Page « Planning » de la direction (absente) ; aucun lien d'ici là |
| DASH-EA-PROD | fait | 03/10 | Accueil élève adulte : route réelle (sans serveur avant BR-1) et « Voir tout » des dernières séances |
| DASH-EA-PROD-R | fait | 04/10 | Revue croisée DASH-EA-PROD (accueil adulte sur une route réelle, historique des séances) |
| DASH-EA-PROD-b | fait | 04/10 | Corrections de DASH-EA-PROD après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| DASH-ELV-ERR | fait | 03/10 | Accueil élève : distinguer l'erreur de lecture du « aucun cours » |
| DASH-ELV-ERR-R | fait | 04/10 | Revue croisée DASH-ELV-ERR (accueil élève : erreur de lecture distincte de « aucun cours ») |
| DASH-ELV-ERR-b | fait | 04/10 | Réserves de DASH-ELV-ERR-R : test sur une vraie panne réseau (Exception, 38 s de squelette), cause probable K-59, condition hasError && !has |
| DASH-ELV-ERR-c | fait | 05/10 | captures RTL de l'état d'erreur de l'accueil élève (320 x2, 390, 1440, clair et sombre) ; les deux libellés réécrits restent à valider par l |
| DASH-ENS-LISTES | fait | 03/10 | Aujourd'hui (enseignant) : où lire les remplacements au-delà de 3 et toutes les « Alertes utiles » |
| DASH-ENS-LISTES-R | fait | 04/10 | Revue croisée DASH-ENS-LISTES (remplacements et alertes : listes complètes à leur adresse) |
| DASH-ENS-ROUTE | fait | 03/10 | Aujourd'hui (enseignant) : donner une route à la liste complète « À terminer » |
| DASH-ENS-ROUTE-R | fait | 04/10 | Revue croisée DASH-ENS-ROUTE (adresse de la liste « À terminer ») |
| DASH-ENS-b | fait | 04/10 | Corrections de DASH-ENS-ROUTE après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) et réserves de DA |
| DASH-LIB | verifie | 03/10 | Déclarer les libellés nouveaux des tableaux de bord (annexe B de DASH_STRATEGIE) dans tool/libelles_sources.json |
| DASH-MA-PROD | fait | 03/10 | Mode Accessibilité : monter l'Accueil hors démonstration et donner une route réelle à l'Aide |
| DASH-MA-PROD-R | fait | 04/10 | Revue croisée DASH-MA-PROD (Accueil du Mode Accessibilité hors démonstration) |
| DASH-MA-PROD-b | fait | 04/10 | Corrections de DASH-MA-PROD après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| DASH-TUT-CTA | fait | 03/10 | Accueil famille : « Connecter un appareil » en action principale en cas de blocage ; carte-lien au lieu de « Voir la classe » |
| DASH-TUT-CTA-R | fait | 04/10 | Revue croisée DASH-TUT-CTA (un seul bouton dominant, accueil famille) |
| DASH-TUT-CTA-b | fait | 04/10 | Corrections de DASH-TUT-CTA après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| DEMO-ENV-1 | fait | 03/10 | Démos : fermées aussi quand l'environnement n'est pas déclaré (AD-R m13) |
| DIR-REP-1 | en_cours | 04/10 | Appliquer les décisions du 05/10 (63 questions, 66 libellés) prises par délégation |
| DISPO-1 | verifie | 01/10 | Disponibilités enseignant : un créneau par ligne (jour / de / à), saisie par plage plutôt qu'heures exactes |
| DISPO-1b | verifie | 09/10 | DISPO-1b — Réserves de DISPO-1 : test de l'intersection avec les heures posées, phrase de fusion d'une plage identique, filets des lignes à  |
| DOC-08-NON-POUSSE | a_faire | 2026-10-02 | Deux notes du document 08 restées sur le poste A, à envoyer sur GitHub avec l'accord du directeur |
| DOC-RESSOURCES-1 | verifie | 04/10 20:00 UTC | ressources-git/LISEZ-MOI.md:10 : résumé DESIGN-GOV complet (§4.3, exception §4 bis.8) |
| DOC-VERIF-1 | fait | 03/10 | Documents : résumés DESIGN-GOV, relevé Admin, Q31/Q40, décompte CT-1a, pièces juridiques signées encore « projet » |
| DOCK-X2-1 | verifie | 05/10 | Salle hors Mode Accessibilité, bureau à texte ×2 : le mot des bascules du dock est coupé (« Camér / a allu… ») |
| DUREE-INSECABLE-1 | fait | 04/10 | Durées « Cours dans 3 h 28 » / « 2 h 59 » scindées sur deux lignes à 320 px texte x2 (carte de séance, accueil famille, Accueil MA) ; « Aucu |
| DUREE-INSECABLE-2 | fait | 05/10 | faire passer TOUTES les durées affichées par LibellesGroupe.insecable et poser l'ancre de sens sur les durées isolées (liste exacte dans les |
| DUREE-INSECABLE-3 | fait | 05/10 | Réserves de DUREE-INSECABLE-2 : |
| DUREE-INSECABLE-4 | en_cours | 05/10 | DUREE-INSECABLE-4 — Réserves de DUREE-INSECABLE-3 (fusionné) : (1) ancres de sens U+200E encore glissées au milieu d'un libellé (valeur pass |
| DUREE-INSECABLE-5 | en_cours | 09/10 | DUREE-INSECABLE-5 — Suite de DUREE-INSECABLE-4 (refusée trois fois, non fusionnée ; branche corrections/c2-duree-4 @ ad992d25, à reprendre t |
| EA-0 | verifie | 27/09 | Préparation : planches, règles F1-F24, découpage, reprise |
| EA-10 | verifie | 27/09 | Recharge un, plusieurs ou tous, récapitulatif séparé, paiement sans faux succès |
| EA-11 | verifie | 27/09 | Demande de reprise du foyer (succession) |
| EA-12 | verifie | 27/09 | Recette : tests §21, captures 390/768/1440 clair et sombre, 200 %, rapport, EA-BR.md |
| EA-1a | verifie | 27/09 | UX_REVIEW_07_ELEVES_ADULTES.md (DESIGN-GOV §4), obligatoire avant tout écran |
| EA-1b | verifie | 27/09 | Socle : coquille, démonstration foyer Diallo (25 états du §18), route /demo/adulte gardée, squelette de captures |
| EA-2 | verifie | 27/09 | Accueil élève adulte, téléphone et ordinateur |
| EA-3 | verifie | 27/09 | Ma classe en sections, photos des participants |
| EA-4 | verifie | 27/09 | Mon espace, entrée unique « Ajouter ma famille », variante second adulte |
| EA-5 | verifie | 27/09 | Ma famille du titulaire, place adulte, retrait de « Un proche adulte » |
| EA-6 | verifie | 27/09 | Invitation du conjoint ou de la conjointe, 2 étapes et états du §5.2 |
| EA-7 | verifie | 27/09 | Acceptation par le second adulte, inéligible, autre foyer, validation administrative |
| EA-8 | verifie | 27/09 | Retrait ou départ, notifications des deux côtés, délai à date rendue par le serveur |
| EA-9 | verifie | 27/09 | Paiements du foyer, solde par bénéficiaire (sans taux ni montant inventé) |
| EA-HL-DOUBLE-1 | fait | 03/10 | hors ligne dit une seule fois, bandeau ou carte, pas les deux |
| EA-HL-DOUBLE-1c | fait | 05/10 | la relire, la mettre à jour sur la branche commune, et traiter AUSSI les défauts du passage accepté : notes hors ligne des écrans enseignant |
| EA-HL-DOUBLE-1d | fait | 05/10 | Réserves de EA-HL-DOUBLE-1c (K-42, règle écrite dans 03 : ni bloc, ni carte, ni note, ni icône ne redit le hors ligne sous le bandeau) : |
| EA-HL-DOUBLE-1e | fait | 05/10 | EA-HL-DOUBLE-1e — Réserves de EA-HL-DOUBLE-1d (fusionné ; décision du 05/10 confirmée : le bandeau en haut seulement, partout, choix a). (1) |
| EA-HL-DOUBLE-1f | en_cours | 09/10 | EA-HL-DOUBLE-1f — Même cause inexacte hors ligne, hors des textes de EA-HL-DOUBLE-1e : « le serveur n'a pas répondu » des séances prochaines |
| EA-HORS-LIGNE-1 | fait | 03/10 | le bandeau hors ligne partagé promet « l'envoi attendra » alors que la page d'invitation dit « Rien n'est envoyé » |
| EA-HORS-LIGNE-1-R | fait | 04/10 | Revue croisée EA-HORS-LIGNE-1 (bandeau hors ligne sans promesse) |
| EA-HORS-LIGNE-1b | fait | 04/10 | Corrections de EA-HORS-LIGNE-1 après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| EA-R | verifie | 02/10 | Revue croisée par une autre session (F1-F24, R, K-42, DESIGN-GOV, matrice §16, sécurité §17) |
| EA-RC | verifie | 27/09 | Corrections et planche web du directeur |
| EA-ROLE-1 | a_faire | 04/10 | Élève adulte : l'accueil adulte et la salle lisent la capacité « élève autonome », pas AppRole.student |
| EA-ROLE-BR | a_faire | 04/10 | Serveur : capacité « élève autonome » servie avec la session (EA-BR-01) |
| ELV-VIDE-COUPE-1 | fait | 04/10 | Accueil élève, état « Pas de cours aujourd'hui » : « aujourd'hui » coupé à 320 px texte x2 (standard et Interface guidée, LTR/RTL) |
| EN-0 | verifie | 26/09 | Préparation : classement et comparaison des 5 planches avec l'existant, rectifications, règles E1 à E20, avis sur le document 04, découpage |
| EN-7 | verifie | 27/09 | ENS-04 Cahier de séance perfectionné : ordre de la planche 4, deux colonnes sur bureau, sans IA, sans « Justifiée », sans faux succès |
| EN-7c | verifie | 02/10 | Cahier : échelle de performance et faiblesses (décision N1 = b), « Ajustez la suggestion » conditionnelle, « RA-NOUR » en double |
| EN-7c-200 | fait | 03/10 | Cahier : feuille « Ajuster » (niveaux, faiblesses) jamais testée ni capturée à 200 % de texte |
| EN-7c-MINEURS | verifie | 04/10 20:00 UTC | Mineurs de EN-7c-R : captures sombres à 200 % de la feuille « Ajuster », LISEZMOI, troncature après saisie, translittération ه / ح |
| EN-7c-R | fait | 03/10 | Revue croisée de EN-7c-200 et EN-7c-SUGG-T (feuille « Ajuster » à 200 %, suggestion de devoir) |
| EN-7c-SUGG-T | fait | 03/10 | Cahier : « Ajustez la suggestion » sans cas positif testé, et aucune suggestion n'est jamais préremplie |
| EN-IND | verifie | 02/10 | Indicateur par élève (ENS-07, roster) : en attente du directeur, ne rien inventer |
| ENS-DRAPEAU-1 | verifie | 05/10 | Pays de l'enseignant : drapeaux en images libres (assets) pour Windows et partout où l'emoji ne se dessine pas (Q-5 = a, pubspec autorisé po |
| ENS-PAYS-1 | verifie | 04/10 nuit | Pays de l'enseignant (avec drapeau si possible) affiché publiquement sur sa carte, pour tous les rôles : tuteur, élèves enfant et adulte, co |
| ENS-PAYS-SALLE-1 | verifie | 08/10 | Classe en direct : retirer le pays (et son drapeau) de l'en-tête selon la décision pays-salle Q-4 = b |
| ETATS-BTN-1 | fait | 01/10 | Boutons sensibles (bascules de salle : micro, caméra, etc.) : états actif / inactif très marqués |
| ETATS-MA-1 | verifie | 03/10 | Salle en Mode Accessibilité au-delà de 130 % : le mot d'état des bascules doit rester visible |
| FI-0 | verifie | 02/10 | Préparation de la vague Finance (sources, inventaire, règles FI1-FI24, découpage, FI-BR, questions) |
| FI-10 | dev_ok | 02/10 | Enseignant : Revenus |
| FI-11a | dev_ok | 02/10 | Finance : vue globale (direction) |
| FI-11b | dev_ok | 02/10 | Politiques commerciales |
| FI-11c | dev_ok | 02/10 | Aperçu et historique des politiques |
| FI-12 | dev_ok | 02/10 | Recette de la vague Finance |
| FI-1a | fait | 02/10 | UX_REVIEW_08_FINANCE avant tout écran |
| FI-1b | fait | 02/10 | Socle 1 : branche ui/finance-v1, domaine Finance, route /demo/finance |
| FI-1b-R | fait | 03/10 | Revue croisée FI-1b |
| FI-1c | fait | 02/10 | Socle 2 : politique et foyer de démonstration, ports, squelette de captures |
| FI-1c-CORR | fait | 04/10 | Corriger les doubles de démonstration Finance (réserves M1, M2 de FI-1c-R) |
| FI-1c-CORR-R | fait | 04/10 | Revue croisée FI-1c-CORR |
| FI-1c-MINEURS | dev_ok | 04/10 | Mineurs de FI-1c-CORR-R : contrat de la marge, « À régulariser », cohérence des jeux de démonstration Finance |
| FI-1c-R | fait | 04/10 | Revue croisée FI-1c |
| FI-2 | dev_ok | 02/10 | Identité de profil (ProfileIdentityAvatar, ProfileIdentityRow) |
| FI-2-CORR | fait | 04/10 | Couleur de profil : corriger la revue FI-2-R (flèche du Foyer au bout de la carte) |
| FI-2-CORR-MINEURS | dev_ok | 04/10 | Mineurs de la revue FI-2-CORR-R (légende couleur en chargement/échec, tests prenomsJoints, captures 320 et RTL) |
| FI-2-CORR-R | fait | 04/10 | Revue croisée FI-2-CORR |
| FI-2-R | fait | 04/10 | Revue croisée FI-2 (couleur de profil) |
| FI-3-R | fait | 04/10 | Revue croisée FI-3a, FI-3b et FI-1c-MINEURS (composants d'argent, jeux de démonstration) |
| FI-3a | dev_ok | 02/10 | Composants d'argent 1 : montants et lignes |
| FI-3b | dev_ok | 02/10 | Composants d'argent 2 : statuts, bandeau, moyen de paiement |
| FI-3c | dev_ok | 04/10 | Corrections de FI-3-R : montants au bord de fin et en colonne, compteur d'essai, teinte de l'essai, tests sombre et sans couleur |
| FI-4 | dev_ok | 02/10 | Foyer, soldes et paiements (téléphone) |
| FI-5 | dev_ok | 02/10 | Foyer, soldes et paiements (ordinateur 1440) |
| FI-5b | dev_ok | 04/10 | Foyer sur ordinateur : vraie composition bureau (grille des enfants, dernières transactions) |
| FI-6a | dev_ok | 02/10 | Fiche élève : Finances |
| FI-6b | dev_ok | 02/10 | Mouvements d'un profil et reçu |
| FI-7 | dev_ok | 02/10 | Recharge multi-profils (téléphone et ordinateur) |
| FI-8 | dev_ok | 02/10 | États du paiement et résultat |
| FI-9a | dev_ok | 02/10 | Accès, essai et impayé (enfant, tuteur, adulte) |
| FI-9b | dev_ok | 02/10 | Élève adulte : mes finances |
| FI-ACCENT-1 | fait | 03/10 | accent de profil sans étape qui le porte ; la note FI-2 du tableau dit encore « teintesIdentite » |
| FI-COUPE-2 | dev_ok | 04/10 | Mots coupés à 320 px x2 relevés par FI-2-CORR-MINEURS |
| FI-DIR-1 | verifie | 05/10 | Finance : décisions du 05/10 FI-Q1 à FI-Q21, FI-R6 (corriger les trois écarts), noteAbsences raccourcie |
| FI-R | a_faire | 02/10 | Revue croisée Finance |
| FI-RC | a_faire | 02/10 | Corrections de revue et planche du directeur |
| FI-VAGUE-CORR | verifie | 04/10 | Corrections de la revue croisée de la vague Finance (FI-4 à FI-11b) |
| FI-VAGUE-CORR-R | fait | 05/10 | Revue croisée des corrections de la vague Finance (FI-VAGUE-CORR) |
| FI-VAGUE-R | fait | 04/10 | Revue croisée de la vague Finance (FI-4 à FI-11c, FI-5b, FI-9a/9b) |
| FILTERPILL-ETAT-1 | verifie | 09/10 | FilterPill : l'état choisi se voit aussi autrement que par la couleur (coche ou icône), dans le composant partagé |
| FILTRES-1 | fait | 01/10 | Écran à filtres : trop peu de possibilités et interface en désordre, surtout les boutons de filtre |
| FILTRES-1b | en_cours | 09/10 | FILTRES-1b — Réserves de FILTRES-1 (rapport REVUE_FILTRES-1-R.md). (1) MAJEUR antérieur : lib/features/admin_pedagogie_qualite/qualite_page. |
| FORM-AUTO-1 | dev_ok | 01/10 | Appliquer K-57 : auditer tous les formulaires de l'app et les rendre semi-automatiques |
| FORM-CORR-1 | verifie | 04/10 20:00 UTC | Corrections de C1-FORM-R (galerie, Pressable, calendrier et étiquettes à 320 x2) |
| FORM-L1-7-13 | verifie | 04/10 | Formulaires : motifs en puces, phrases-types des signalements, valeurs proposées des réglages (listes à valider) |
| FORM-L2 | dev_ok | 04/10 | Formulaires admin : choisir l'élève ou l'enseignant dans une liste au lieu de taper un identifiant |
| FORM-L4-11-12 | dev_ok | 04/10 | Formulaires : date par sélecteur, carte « Autre » du dépôt de pièce, libellé de jeton généré, courriel de récupération prérempli |
| FORM-L5 | dev_ok | 04/10 | Programme : cycle, ordre et code proposés ou déduits (ajouter/modifier un niveau) |
| FORM-L6 | dev_ok | 04/10 | Foyer : nom prérempli et âge choisi (profil d'élève, invitation du conjoint) |
| FORM-L8-9 | verifie | 04/10 20:00 UTC | Formulaires enseignant : pays et langues choisis, reprise du cahier par sourate et verset |
| FORM-MINEURS | verifie | 04/10 20:00 UTC | Formulaires : restes à 320 x2 (calendrier, mots coupés, page Programmes qui déborde) |
| FOY-COUL-1 | fait | 01/10 | Foyer : bandeau de couleur derrière la photo de chaque profil, couleur choisie par le tuteur |
| FOYER-ADMIN-1 | verifie | 01/10 | « Foyer » chez l'admin : libellé incompris, à renommer d'après ce qu'il compte |
| GALERIE-BENTO-2 | fait | 03/10 | Galerie GrilleBento : montrer les vraies tuiles du Centre de commande |
| GALERIE-BENTO-2-R | fait | 03/10 | Revue croisée GALERIE-BENTO-2 |
| HIER-1 | verifie | 01/10 | Hiérarchie des titres : nom et titre ne doivent jamais avoir la même taille |
| HL-A-1 | verifie |  | Restes d'AD-5 et d'AD-S : capture du squelette de la file (port en attente réservé aux captures), pastille d'état placée de façon cohérente  |
| HL-A-2 | verifie |  | Restes d'AD-6 : (1) en production, la validation est fermée tant que la pièce n'est pas consultable : AD-7 doit rouvrir la consultation par  |
| HL-A-3 | verifie |  | Restes : lien « Terminez les vérifications requises. » aligné en fin comme les actions à 200 % ; GroupeReglages : passage du contrôle sous l |
| HL-A-4 | verifie |  | Restes d'AD-8 : preuve du glisser de la feuille contre PopScope et du clavier ouvert à 390 ; captures hors ligne au moment du clic, validati |
| HL-A-5 | verifie |  | Appliquer le style de référence CL-4 (K-42, STYLE-REFERENCE-CL4) aux écrans d'AD-6 à AD-10 : air, un seul bouton dominant, emplacement d'éta |
| HL-A-6 | verifie |  | Retirer le KYC du parcours tuteur sans tout reprendre : inscription tuteur sans dépôt de pièce ni portail d'attente (suite directe vers la s |
| HU-1 | a_faire |  | Harmonisation UI globale, après les visuels de tous les rôles : appliquer les contrats A à E et les squelettes aux écrans déjà faits (dont l |
| INTEG-C1 | fait | 04/10 | Intégration des sous-branches CORR-1 (c1-adm3, c1-demoenv, c1-salle, c1-ctrl, c1-ma, c1-lib, c1-form-a, c1-form-b) et une suite complète |
| INTEG-MINEURS-1 | fait | 03/10 | Mineurs de l'intégration des rôles (barre du bas à 320 px, dock MA, jetons, source d'echecEnvoi) |
| INTEG-RC-1 | fait | 02/10 | Réunir les branches de rôle dans la branche des corrections (enseignant, contrôleur, accessibilité, élèves adultes) |
| INTEG-RC-1-R | fait | 03/10 | Revue croisée de INTEG-RC-1 (réunion des branches de rôle dans la branche des corrections) |
| JONCTION-4 | en_cours | 09/10 | JONCTION-4 — Provenance des libellés selon DIR-REP-1 et preuve des commits de jonction du lot 4. (1) Dans tool/libelles_sources.json, toute  |
| JUR-APP-1 | verifie | 04/10 20:00 UTC | Porter dans l'app les textes juridiques validés (information enfants et parents, A0, A3, E1, clause enseignant) |
| JUR-LIEN-385-1 | verifie | 05/10 | Salle : lien « En savoir plus » caché sous ~385 de large (Q-3 = b) ; signataires de 2026-09 invités à signer la nouvelle version quand la po |
| JUR-SUITE-1 | fait | 02/10 | Juridique : document de politique appropriée, charte du contrôleur, DPIA de la Classe (audio), corrections des textes A0 et A3 |
| KYC-LECTURE-1 | a_faire | 02/10 | Pièce d'identité (KYC) : retirer le contrôleur de la règle de lecture du bucket kyc |
| KYC-PHOTO-1 | fait | 01/10 | Photo de l'enseignant : marquer obligatoire (point rouge) et expliquer pourquoi ; cas du voile intégral |
| LG-1 | a_faire |  | Étape langues : français, anglais, arabe, espagnol, portugais (après les visuels de tous les rôles) : audit des textes en dur et des écarts  |
| LIB-ABS-1 | verifie | 01/10 | Enseignant : « Déclarer une absence » ne dit pas de qui ; c'est l'absence de l'enseignant lui-même |
| LIB-CAHIER-1 | fait | 01/10 | Enseignant : « Cahier » seul est incompréhensible, description banale ; dire à quoi il sert et qu'il est obligatoire |
| LIB-DIR-1 | verifie | 05/10 | Libellés tranchés le 05/10 : « cahier de transmission » (Q-6, retour à la ligne sans coupure), élision « d'Aïcha » dans toute l'app (57 text |
| LIB-ERR-1 | fait | 01/10 | Appliquer K-59 : messages d'erreur partielle avec cause et conduite à tenir (d'abord « Ma journée » enseignant) |
| LIB-ERR-2 | verifie | 04/10 20:00 UTC | Reste de LIB-ERR-1 : le message d'erreur partielle cite les cahiers en retard, et un test du bloc |
| LIB-LOT3-2 | fait | 03/10 | Libellés du lot 3 : élision devant un prénom à voyelle, message d'erreur partielle exact, dernier « cahiers », tests des libellés |
| LIB-OBJ-1 | fait | 01/10 | Cahier : « Objectif personnel » ne dit ni pour qui ni pour quel élève |
| LIVE-CHRONO-01 | a_faire |  | LIVE-CHRONO-01 Chrono interne de la salle, DISCRET : écoulé et restant jusqu'à 00:00:00 |
| LIVE-PAUSE-01 | a_faire |  | LIVE-PAUSE-01 Pause de séance configurable à l'avance par l'enseignant |
| LOGO-1 | a_faire |  | LOGO-1 Logo officiel : intégration en une seule fois quand le directeur le fournit |
| MA-0 | verifie | 27/09 | Préparation : planches, règles MA1-MA24, découpage, reprise |
| MA-10 | verifie | 02/10 | Lexique : fin de « mode enfant » et « Interface guidée » dans les textes visibles |
| MA-11 | verifie | 02/10 | Passe technique : états, focus et clavier, Semantics, cibles, mouvement |
| MA-12 | verifie | 02/10 | Recette : 390/768/1440, clair/sombre, 200 %, lecteur d'écran, animations réduites, RTL, rapport, MA-BR |
| MA-1a | verifie | 27/09 | UX_REVIEW_06_ACCESSIBILITE.md (DESIGN-GOV §4), obligatoire avant le code |
| MA-1b | verifie | 27/09 | Socle : réglage du mode sur InterfaceMode, fournisseur unique, démonstration, route /demo/accessibilite gardée, squelette de captures |
| MA-2 | verifie | 27/09 | Navigation élève à 4 destinations dans les deux présentations |
| MA-2COL-1 | fait | 04/10 | Accueil Mode Accessibilité : rétablir les deux colonnes à partir de 840 / facteur de texte, comme la fiche ELV-0x le prévoit |
| MA-2COL-1b | fait | 05/10 | le BlocAsynchrone de l'Accueil Mode Accessibilité ne doit pas être recréé quand la largeur ou le facteur de texte franchit le seuil des deux |
| MA-3 | verifie | 27/09 | Accueil élève (doc §5, planches 1 et 3) |
| MA-4 | verifie | 27/09 | Ma classe avant la séance et préparation guidée |
| MA-5 | verifie | 27/09 | Salle pendant la séance, mobile et bureau |
| MA-6 | verifie | 27/09 | Après la séance |
| MA-7 | verifie | 27/09 | Coran : contrôles autour du rendu, sans le toucher |
| MA-8 | verifie | 02/10 | Mon espace : ligne Mode Accessibilité et préférences d'affichage |
| MA-9 | verifie | 02/10 | Côté tuteur (page interface) et enseignant (fiche de séance) |
| MA-APRES-1 | dev_ok | 03/10 | Après la séance en Mode Accessibilité, un seul écran (décision A7 = a) |
| MA-APRES-1b | verifie | 04/10 20:00 UTC | Corrections de C1-MA-R : « prochaine séance » fausse après Quitter |
| MA-CMD-1 | verifie | 02/10 | Mode Accessibilité : commandes compactes qui s'effacent (salle et lecteur du Coran), barre du bas adaptée |
| MA-CORAN-TETE-1 | dev_ok | 03/10 | Lecteur du Coran en Mode Accessibilité : en-tête sur une ligne à texte ×2 |
| MA-CORAN-X2-1 | verifie | 04/10 | États sans texte du lecteur du Coran illisibles à texte x2 (question au directeur) |
| MA-DEC-1 | dev_ok | 03/10 | Mode Accessibilité, appliquer les décisions A3, A5 et A8 du 27/09 |
| MA-GR-1 | verifie | 02/10 | GroupeReglages : la valeur reste collée au libellé à 1440 ; double écart avant l'aide dans Mon espace MA |
| MA-HORSLIGNE-CLASSE-1 | verifie | 08/10 | Accueil du Mode Accessibilité hors ligne : « Voir ma classe » masqué alors que Ma classe reste consultable |
| MA-NAV-1 | verifie | 02/10 | Mode Accessibilité / guidé : la barre de navigation du bas doit aussi s'adapter |
| MA-R | verifie | 02/10 | Revue croisée par une autre session |
| MA-RC | verifie | 02/10 | Corrections et planche web du directeur (avec bascule 200 %) |
| MA-RC-MINEURS | verifie | 02/10 | Mode Accessibilité : mineurs restants de la revue MA-R |
| MA-TITRE-1 | verifie | 02/10 | Salle MA à 200 % : le titre « Ma séance » est tronqué (points de suspension) |
| MA-TUTOIEMENT-1 | dev_ok | 03/10 | vouvoyer l'adulte dans le lecteur du Coran et dans la salle réelle (décision A4 = a) |
| MUSHAF-DIR-1 | verifie | 04/10 | Lecteur du Coran : point final des phrases françaises placé en tête (« .votre page se rouvre ici ») |
| NAV-FLECHES-1 | fait | 02/10 | Boutons de navigation précédent / suivant trop laids : flèches façon lecteur MP3 |
| OBS-COUPE-1 | fait | 04/10 | Salle d'observation du tuteur : mots coupés dans la barre de commandes et en-tête rogné à 320 px texte x2 |
| OBS-COUPE-1-R | fait | 04/10 | Revue croisée OBS-COUPE-1 (barre de la salle d'observation) |
| OBS-COUPE-1b | fait | 04/10 | Corrections de OBS-COUPE-1 après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| ON-AIR-1 | fait | 01/10 | Séance en direct : état « En direct » avec un point qui clignote subtilement |
| ONGLETS-1 | verifie | 01/10 | Trop d'onglets en rangée qui défile : on ne devine pas que c'est un groupe d'onglets ; adopter le standard |
| ONGLETS-COUPE-1 | verifie | 04/10 | Constats de CAPT-L1-2 : « Fonctionnalité / s » coupé dans SelecteurSection à 320 x2 ; débordements des pages Pédagogie (Progression, Évaluat |
| PAGESHELL-200-1 | fait | 04/10 | PageShell (_Bascule) : sur mobile à 200 %, le corps non défilant reçoit toute la hauteur sous la tête ; la barre de la salle d'observation p |
| PAGESHELL-200-1b | fait | 05/10 | régression en portrait à hauteurs atypiques (320x568, 320x580, 320x520 à 200 %) et aggravation en paysage 200 % avec barres système ; le cor |
| PAGESHELL-200-1c | fait | 05/10 | Réserves de PAGESHELL-200-1b : |
| PAGESHELL-200-1d | fait | 05/10 | PAGESHELL-200-1d — Réserves de PAGESHELL-200-1c (fusionné). Décision déléguée du 05/10 (consigne la plus récente du directeur) : sur télépho |
| PAGESHELL-200-1e | en_cours | 09/10 | PAGESHELL-200-1e — Tu es SEUL sur lib/core/widgets/page_shell.dart, lib/core/widgets/admin_shell.dart et lib/features/admin_journal. Réserve |
| PAQ-CT-ADX | a_faire | 02/10 | Contrôleur : impacts côté administration (avec AD-X) |
| PAQ-CT-BR1 | a_faire | 02/10 | Contrôleur : bloquants avant production, impacts et recette à brancher (BR-1) |
| PAQ-CT-DIR | fait | 02/10 | Contrôleur : questions ouvertes au directeur |
| PAQ-DIR-EA | a_faire | 02/10 | Élèves adultes : documents et points attendus du directeur |
| PASTILLE-COUPE-1 | fait | 03/10 | Pastille « Remplacement » coupee au milieu du mot a texte x2 (Mes Classes) |
| PHOTO-LIEN-1 | verifie | 01/10 | « Choisir une photo » : bouton trop imposant, à remplacer par un simple lien avec une flèche |
| PROP-CODE-1 | fait | 05/10 | Propriété du code source : LICENSE et règle permanente |
| PT-A-20261002-4a9ebcbe | verifie | 2026-10-02 | Réessayer pleine largeur sur ordinateur |
| PT-A-20261002-a0eb1cc5 | verifie | 2026-10-02 | Ajouter ma famille (adulte seul) |
| PT-A-20261002-df9fb69f | verifie | 04/10 20:00 UTC | Mineurs CORR-SUITE-1 |
| PT-B-20260927-9fa5135b | fait | 2026-09-27 | Élèves adultes : vraie page Coran |
| PT-B-20260927-cfbdb7a5 | fait | 2026-09-27 | Harmonisation : carte du support en pile |
| PT-B-20260927-f33e8cac | verifie | 2026-09-27 | Contrôleur : règles légales avant la mise en service |
| PT-B-20261001-e14d420a | verifie | 2026-10-01 | Fusion PR n°4 cloud dans ui/controleur-v1 |
| PUB-1 | fait | 01/10 | Pages publiques de présentation avant la connexion (3 à 5 cartes, défilement automatique) |
| PUB-1b | en_cours | 09/10 | PUB-1b — Réserves de PUB-1 (rapport REVUE_PUB-1-R2.md) : (1) docs/current/REVUE-DIRECTEUR-2026-10.md:28 décrit encore une pause « au survol  |
| REMPL-1 | a_faire | 01/10 | Remplacements : écran dédié commun à tous les enseignants (premier arrivé, premier servi) + alerte d'urgence très visible |
| RTL-ISOL-1 | en_cours | 09/10 | RTL-ISOL-1 — Valeurs et phrases françaises réordonnées en RTL (interface ar), relevées par les relectures du lot 4. Isole chaque valeur ou p |
| SALLE-200-1 | fait | 02/10 | Salle (PageImmersive) : débordement à 320 et 390 px avec texte ×2 (bandeau + commandes) |
| SALLE-200-2 | fait | 02/10 | Salle enseignant à 320 px, texte ×1 : RenderFlex déborde de 37 px à droite (contenu de la salle) |
| SALLE-CORR-3 | fait | 03/10 | Salle : débordement 8 px enseignant à 320, commandes illisibles (sombre sur sombre, contrôleur), rappel du contrôleur, bandeau collé, séance |
| SALLE-CORR-4 | verifie | 04/10 20:00 UTC | Textes du support enseignant illisibles dans /salle (réserve R1 de C1-SALLE-R) |
| SALLE-ENCRE-1 | verifie | 04/10 20:00 UTC | Salle : textes illisibles sur le fond de la salle (panneau enseignant, colonne Présence, « Ouvrir le Coran » en sombre) |
| SALLE-ERR-320-1 | verifie | 04/10 nuit | Salle, enseignant, 320 px texte x2 : l'état d'erreur du support coupe son détail et le bouton « Réessayer » (titre sur 3 lignes qui remplit  |
| SUPERPOS-1 | fait | 02/10 | Écran illisible : un bloc d'infos recouvre le message du dessous ; zone de texte trop laide |
| SUPERPOS-1b | en_cours | 09/10 | SUPERPOS-1b — Réserves de SUPERPOS-1 (rapport REVUE_SUPERPOS-1-R2.md) : (1) test qui protège FilDiscussion.minimumListe(context) (hauteur mi |
| TB-0 | verifie | 02/10 | Préparation du chantier Supports et tableau (sources, inventaire, règles TB1-TB30, découpage, TB-BR, questions) |
| TB-10 | a_faire | 02/10 | Élève, Mode Accessibilité et autorisation d'écrire |
| TB-11a | a_faire | 02/10 | Tuteur observateur et contrôleur : présentation en lecture seule |
| TB-11b | a_faire | 02/10 | États de synchronisation et de conservation (sans faux succès) |
| TB-12 | a_faire | 02/10 | Recette du chantier Supports et tableau |
| TB-1a | fait | 02/10 | UX_REVIEW_TB et revue critique avant code (L0, §22) |
| TB-1b | dev_ok | 02/10 | Socle : affichages Support / Avec notes / Tableau dans VueSeance, page fixe de démo, /demo/salle?tb=, squelette de captures |
| TB-2 | dev_ok | 02/10 | Visio Micro, Caméra, Quitter révélée au toucher, à la souris et au clavier |
| TB-3 | dev_ok | 02/10 | Capsule compacte (avatar, enregistrement réel, œil) et contexte enseignant |
| TB-4 | verifie | 02/10 | Bouton « Commandes » et panneau pédagogique (Bibliothèque, affichages, pages, Focus, outils) |
| TB-5 | a_faire | 02/10 | Ordinateur équilibré (Participants à gauche), tablette et focus local |
| TB-6 | a_faire | 02/10 | Surface : page fixe, trois affichages et tableau libre |
| TB-7a | a_faire | 02/10 | Calque d'annotation au repère de la page (géométrie) |
| TB-7b | a_faire | 02/10 | Écrire : Pointeur, Stylo, Surligner, Gomme, Annuler, options, palette courte |
| TB-8 | a_faire | 02/10 | Bibliothèque en séance : catalogue, aperçu personnel, Présenter, erreurs |
| TB-9 | a_faire | 02/10 | Ranger dans la bibliothèque, reprendre, effacer les notes |
| TB-F | fait | 02/10 | Créer la branche ui/supports-tableau-v1 |
| TB-R | a_faire | 02/10 | Revue croisée du chantier Supports et tableau |
| TB-RC | a_faire | 02/10 | Corrections de la revue et planche web du directeur |
| TB-STYLET-1 | fait | 03/10 | TB21 perd « lorsque Écrire est actif » ; le code et la revue TB-1a laissent le stylet écrire hors Écrire |
| TH-2 | a_faire |  | Thème 2 « chrome / noir et blanc » (monochrome), en option dans les paramètres de chaque rôle, à côté du thème actuel chrome / violet |
| THEME-SW-1 | verifie | 01/10 | Choix du thème : un petit sélecteur horizontal à 3 segments (soleil, système, lune), pas 3 cartes verticales |
| TUILE-TUTEUR-1 | fait | 02/10 | Vignette d'observation du tuteur : passer au composant TuileSansImage |
| TUILE-TUTEUR-1-R | fait | 04/10 | Revue croisée TUILE-TUTEUR-1 (vignette d'observation sans image) |
| TUILE-TUTEUR-1b | fait | 04/10 | Corrections de TUILE-TUTEUR-1 après revue croisée (équipe de relecteurs spécialistes, autorisée par le directeur le 04/10) |
| VERIF-AD | fait | 02/10 | K-03 Admin, validation des dossiers (code) |
| VERIF-AD-2 | fait | 03/10 | K-03 Admin, validation des dossiers : les étapes non couvertes par VERIF-AD |
| VERIF-AD-DOC | fait | 02/10 | K-03 Admin, documents (règles gelées, relevés, maquettes, AD-BR) |
| VERIF-CORR-1 | fait | 02/10 | K-03 corrections lot 1 (composants partagés) |
| VERIF-CORR-2 | fait | 02/10 | K-03 corrections salle et séance (dont VIDEO-TUILE-1, demande répétée) |
| VERIF-CORR-3 | fait | 02/10 | K-03 BENTO-1 (demande répétée) et libellés du lot 3 |
| VERIF-CORR-SUITE | fait | 02/10 | Branche réunie des corrections : tests par dossiers, puis passer à « fait » les 9 étapes dev_ok |
| VERIF-CT-1 | fait | 02/10 | K-03 Contrôleur, début de vague (socle à CT-5, CT-9, CT-11, PR n°4) |
| VERIF-CT-2 | fait | 02/10 | K-03 Contrôleur, fin de vague (CT-6 à CT-RC) |
| VERIF-CT-DOC | fait | 02/10 | K-03 Contrôleur, documents et juridique |
| VERIF-EA-1 | fait | 02/10 | K-03 Élèves adultes, début de vague (préparation à EA-6) |
| VERIF-EA-2 | fait | 02/10 | K-03 Élèves adultes, fin de vague (EA-7 à EA-RC) et EA-PL |
| VERIF-EN | fait | 02/10 | K-03 Enseignant, restes du 02/10 |
| VERIF-FUSIONS-1 | verifie | 05/10 | Relecture par une troisième session des cinq corrections fusionnées par la session iPad (TUILE-TUTEUR-1, OBS-COUPE-1, DASH-ADM-ECHUS, DASH-T |
| VERIF-MA-1 | fait | 02/10 | K-03 Mode Accessibilité, début de vague (préparation à MA-7) |
| VERIF-MA-2 | fait | 02/10 | K-03 Mode Accessibilité, fin de vague (MA-8 à MA-TITRE-1) |
| VERIF-PREP | fait | 02/10 | K-03 préparation des nouveaux rôles (FI-0, TB-0) et leçons |
| VIDEO-TUILE-1 | verifie | 02/10 | Tuiles vidéo : nom centré sous le cercle, aucune tuile qui déborde de l'écran |
| ZOOM-LIB-1 | verifie | 09/10 | Salle, barre du support de l'élève : libellé « Zoom local, sans effet sur les autres » tronqué (« Zoom loc… », absent à 1200 ×2) ; borne MA- |

## archive_etapes (188)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| CL-1 | fait |  | Planches de la salle refaite (D1-D10) : mobile + desktop, clair + sombre, élève / guidée / enseignant, états support, rien de partagé, focus |
| CL-2 | fait |  | Fondations : plan de fusion des deux salles (/salle et /tc/classe), permissions micro/caméra (Android, iOS), fenêtre d'entrée unique, jeton  |
| CL-3 | fait |  | Socle commun de la salle, tous rôles (gabarit G10) : SalleSeance, ChromeSeance, ZoneSupport (+ vide + focus), VignetteVideo, DockSeance, Pas |
| CL-4 | verifie |  | CL-4.0 Entrée : relevé des maquettes, classement par rôle, rectifications, harmonisation, règles R1 à R21 |
| CL-4.1 | verifie |  | CL-4.1 Revue UX 2026 de l'entrée (DESIGN-GOV §4) : 10_classe/UX_REVIEW_CL-4.md |
| CL-4.2 | verifie |  | CL-4.2 Socle de démonstration : horloge de séance depuis horodatages, 9 états de la carte, route /demo/classe |
| CL-4.3 | verifie |  | CL-4.3 Espace Classe élève (CLS-ELV-01/02) : évolution d'EspaceGroupePage, 390 / 768 / 1440 |
| CL-4.4 | verifie |  | CL-4.4 Espace Classe enseignant (CLS-ENS-01/02) : évolution de FicheGroupePage, « Préparer l'entrée » |
| CL-4.5 | verifie |  | CL-4.5 Préparation enseignant (PRE-ENS-01) : aperçu coupé, équipement, contexte, « Entrer dans la classe » |
| CL-4.6 | verifie |  | CL-4.6 Préparation élève (PRE-ELV-01, PRE-ERR-01) : presque silencieuse, blocage via les écrans de CL-7 |
| CL-4.7 | verifie |  | CL-4.7 Recette de l'entrée : accessibilité, captures clair et sombre, planche web pour le directeur |
| CL-4.R | fait |  | CL-4.R Revue croisée de l'entrée en classe |
| CL-5 | fait |  | Salle élève : CLV-04 standard, CLV-05 Interface guidée, CLV-09 Fin de séance élève |
| CL-6 | fait |  | Salle enseignant : CLV-06, CLV-07 Élèves (enseignant uniquement), CLV-08 Supports, CLV-10 Fin de séance enseignant |
| CL-7 | fait |  | Résilience : reconnexion, réseau faible, micro refusé, caméra interdite, séance prolongée, salle terminée ou accès retiré (P05, P06, P09-P12 |
| CL-F | fait |  | Intégration dans ui/classe-v1 : analyze + suite complète + recette en démonstration |
| CL-R | fait |  | Revue adversariale de chaque lot : rôle effectif respecté, rien d'interdit affiché, jetons du thème, i18n |
| CO-01 | fait | 24/09 | Registre du code non livré et sauvegardes |
| CO-02 | fait | 24/09 | Dossier de pilotage publié sur GitHub (branche pilotage/tuteur-v1) |
| CO-03 | fait | 24/09 | Base commune publiée (branche ui/tuteur-v1) |
| CO-05 | fait | 24/09 | Tableau de suivi du chantier (cette page) |
| CO-06 | fait | 24/09 | Ressources du projet publiées pour tous les agents (branche projet/ressources) |
| CO-07 | fait | 24/09 | Prompt et dossier ChatGPT pour les specs verticales de tous les rôles |
| CT-BLQ-01 | fait | 02/10 | Niveau de connexion pour observation privilégiée |
| CT-BLQ-02 | fait | 02/10 | MFA / step-up du Contrôleur |
| CT-BLQ-03 | fait | 02/10 | Procédure de retrait immédiat d'un accès |
| CT-BLQ-04 | fait | 02/10 | Durée de conservation des rapports |
| CT-BLQ-05 | fait | 02/10 | Base légale du suivi des enseignants |
| CT-BLQ-07 | fait | 02/10 | Contestation d'un rapport par l'enseignant |
| CT-BLQ-08 | fait | 02/10 | Données sensibles captées par hasard (vidéo, audio) |
| CT-BLQ-09 | fait | 02/10 | Transferts hors Royaume-Uni |
| CT-BLQ-10 | fait | 02/10 | Capture d'écran et filigrane |
| CT-BLQ-11 | fait | 02/10 | Brouillon de compte rendu sur l'appareil |
| CT-BLQ-12 | fait | 02/10 | Information légale élèves, parents, enseignants |
| CT-BLQ-13 | fait | 02/10 | Qui lit un rapport brut |
| CT-BLQ-14 | fait | 02/10 | Qui peut exporter un rapport |
| CT-BLQ-15 | fait | 02/10 | Identité du Contrôleur après publication mensuelle |
| CT-BR1-RECETTE | fait | 02/10 | Recette à brancher : reconnexion sans faux direct (scénario 10) et bandeau hors ligne dans l'espace Contrôle (scénario 29) |
| CT-IMP-AD-01 | fait | 02/10 | Attribuer et retirer la capacité Contrôleur |
| CT-IMP-AD-02 | fait | 02/10 | Définir le périmètre du contrôleur |
| CT-IMP-AD-03 | fait | 02/10 | Contrôleur externe permanent |
| CT-IMP-AD-04 | fait | 02/10 | Rotation et couverture des classes |
| CT-IMP-AD-05 | fait | 02/10 | Missions réalisées en temps réel |
| CT-IMP-AD-06 | fait | 02/10 | File de rapports reçus |
| CT-IMP-AD-07 | fait | 02/10 | Signalements urgents |
| CT-IMP-AD-08 | fait | 02/10 | Canal de discussion avec le Contrôleur (côté administration) |
| CT-IMP-AD-09 | fait | 02/10 | Historique immuable |
| CT-IMP-AD-10 | fait | 02/10 | Détection des contrôleurs qui valident tout |
| CT-IMP-AD-11 | fait | 02/10 | Calibration entre contrôleurs |
| CT-IMP-AD-12 | fait | 02/10 | Conflits d'intérêt |
| CT-IMP-AD-13 | fait | 02/10 | Validation de la synthèse mensuelle enseignant |
| CT-IMP-AD-14 | fait | 02/10 | Publier ou non un signal qualité aux familles |
| CT-IMP-AD-15 | fait | 02/10 | Contrôleur ou évaluateur invité |
| CT-IMP-AD-16 | fait | 02/10 | Retrait immédiat d'un accès privilégié |
| CT-IMP-AD-17 | fait | 02/10 | Revue périodique des privilèges |
| CT-IMP-AD-18 | fait | 02/10 | Journal d'audit séparé de la gestion des droits |
| CT-IMP-EN-01 | fait | 02/10 | Synthèse mensuelle de l'enseignant |
| CT-IMP-EN-02 | fait | 02/10 | Réponses et échanges autorisés de l'enseignant |
| CT-IMP-EN-03 | fait | 02/10 | Historique qualité, badges, promotions |
| CT-IMP-EN-04 | fait | 02/10 | Aucune vitesse d'élève comme score d'enseignant |
| CT-IMP-EN-05 | fait | 02/10 | Pas d'alerte immédiate à l'enseignant observé |
| CT-IMP-TU-01 | fait | 02/10 | Aucun rapport de contrôle brut côté famille |
| CT-IMP-TU-02 | fait | 02/10 | Signal « Suivi qualité effectué ce mois-ci » |
| EN-10 | verifie | 27/09 | Salle B : Teaching Dock compact raccordé à /salle et sélecteur de ressources (Récents, Cette Classe, Tous, recherche) |
| EN-11 | verifie | 27/09 | ENS-08 Revue de Classe au style K-42, puis nettoyage du lexique enseignant (E17) |
| EN-12 | verifie | 27/09 | Recette : tests depuis la vraie coquille, captures 390/768/1440 clair/sombre, 200 %, arabe simulé, rapport en français, besoins serveur EN-B |
| EN-1a | verifie | 26/09 | UX_REVIEW_04_ENSEIGNANT.md : sources officielles datées, décision par écran (DESIGN-GOV §4, doc §36) |
| EN-1b | verifie | 26/09 | Socle : coquille à 4 destinations (Aujourd'hui, Classes, Disponibilités, Profil), route /enseignant/classes, données de démonstration enseig |
| EN-2 | verifie | 26/09 | ENS-02 Aujourd'hui : carte Prochaine séance (EmplacementEntree, E11), Ma journée, À terminer, Alertes utiles ; retrait de « Élèves en attent |
| EN-3 | verifie | 27/09 | ENS-09 Mes Classes (nouvelle page) et ENS-07 Espace Classe perfectionné (ressources récentes, progression, ligne élève cliquable, 2 colonnes |
| EN-4 | verifie | 27/09 | ENS-11 Fiche élève hors séance (feuille / panneau, une colonne) et ENS-12 Signaler un besoin |
| EN-5 | verifie | 27/09 | ENS-06 Disponibilités (hebdomadaires, sans matching) et ENS-06B détail d'une Classe disponible, confirmation, succès honnête |
| EN-6 | verifie | 27/09 | ENS-01 Premiers pas, ENS-05 Profil (photo en tête) et ENS-05A Photo publique |
| EN-8 | verifie | 27/09 | ENS-13 Absence sur une séance et ENS-13B offre de remplacement (Alerte utile, confirmation, carte Remplacement) |
| EN-9 | verifie | 27/09 | Salle A : panneau Élèves et File de récitation, fiche élève en séance (Faire réciter, Appeler discrètement, Noter, Signaler), notice discrèt |
| EN-KB | verifie | 27/09 | Raccourcis clavier de la salle sur bureau (accordés par le directeur le 26/09) : M micro, V caméra, R roster, B bibliothèque, Échap ; actifs |
| EN-R | verifie | 27/09 | Revue croisée par une autre session (E1-E20, R1-R21, K-42, 14 questions anti-cauchemar) |
| EN-RC | verifie | 27/09 | Corrections de la revue, puis planche web du directeur au format CL-4 |
| HL-B-1 | fait | 2026-09-25 | Icones manquantes : femme/homme (genre) et horloge (fin d'observation) |
| HL-B-2 | fait | 2026-09-25 | Catalogue des classes : jours, heures, fuseau et parcours (C-14) |
| HL-B-3 | fait | 25/09 18:31 | Réparer la construction Android (APK) |
| HL-B-5 | fait | 25/09 | Vérification finale du rôle Tuteur et correction des 3 derniers restes mineurs |
| LA-1 | verifie | 25/09 01:42 | Bienvenue, connexion, récupération d'accès |
| LA-2 | fait | 2026-09-25 08:10 | Inscription par étapes (usage à deux choix, identité, genre, récapitulatif) |
| LA-4 | verifie | 2026-09-25 04:13 | Questionnaire par élève et enchaînement vers l'ajout de profil |
| LA-F | fait | 2026-09-25 08:12 | Corrections et branche ui/tuteur-v1-a publiée |
| LA-R | verifie |  | Revue indépendante du lot A |
| LB-1 | verifie | 2026-09-25 05:15 | Écran Foyer : membres, ajout de profil, appareils partagés |
| LB-2 | verifie | 2026-09-25 05:15 | Ajout d'un profil élève (formulaire commun) |
| LB-3 | verifie | 24/09 21:59 | Fiche élève et ses sous-pages (informations, inscription, interface, caméra, accès) |
| LB-F | verifie | 2026-09-25 05:15 | Corrections et branche ui/tuteur-v1-b publiée |
| LB-R | verifie | 24/09 22:12 | Revue indépendante du lot B |
| LC-1 | verifie | 24/09 | Accueil : sélecteur, carte classe, séance, blocage, préparation, dernière séance |
| LC-2 | verifie | 25/09 | Classe et sous-pages (planning, travail, ressources, progression) |
| LC-3 | verifie | 2026-09-25 | Catalogue des classes |
| LC-F | fait |  | Corrections et branche ui/tuteur-v1-c publiée |
| LC-R | verifie |  | Revue indépendante du lot C |
| LD-1 | fait | 24/09 20:51 | Émetteur QR et code, tous ses états |
| LD-2 | fait | 24/09 21:25 | Scanner caméra et saisie du code |
| LD-3 | fait | 24/09 22:13 | Appareil partagé (profil, code personnel) et liste des appareils |
| LD-F | fait | 24/09 22:58 | Corrections et branche ui/tuteur-v1-d publiée |
| LD-R | verifie | 24/09 22:26 | Revue indépendante du lot D |
| LE-1 | verifie | 24/09 | Mon compte et ses sous-pages, déconnexion |
| LE-2 | verifie | 25/09 | Historique Séances / Observations, détail de séance et d'observation |
| LE-3 | verifie | 2026-09-25 | Notifications et consultation admin des observations |
| LE-F | fait |  | Corrections et branche ui/tuteur-v1-e publiée |
| LE-R | fait |  | Revue indépendante du lot E |
| LO-1 | fait | 24/09 | Entrée et explication (Comment ça marche ?) |
| LO-2 | fait | 2026-09-25 | Salle d'observation épurée avec bandeau de décompte et visites restantes |
| LO-3 | fait | 2026-09-25 | Fins de visite et états particuliers |
| LO-F | fait |  | Corrections et branche ui/tuteur-v1-o publiée |
| LO-R | fait |  | Revue indépendante du lot O |
| LT-1 | fait | 25/09 | Sélecteur de thème : 3 icônes (soleil, lune, système) en colonne compacte, partagé, défaut système, mémorisé, test qui tape chaque icône |
| LT-10 | fait | 25/09 | Web : Soldes, Recharge, Accès en deux colonnes |
| LT-11 | fait | 25/09 | Fiche : photo Prendre / Choisir / Annuler ; scanner : Ouvrir les réglages ; retour du détail de ressource |
| LT-12 | fait | 25/09 | Paiements : détail ; séance passée : lien mouvements ; notifications : filtre et cible supprimée |
| LT-13 | fait | 25/09 | Captures 390x844 et 1440x900 clair et sombre + planches maquette / rendu |
| LT-2 | fait | 25/09 | Ports finance neutres + modèles (soldes, mouvements, devis, recharge, accès) + démonstration isolée ; dépendances DB-FIN-01 à 06 |
| LT-3 | fait | 25/09 | Composants partagés : résumé de solde, ligne bénéficiaire, sélection de profils, résultat par profil |
| LT-4 | fait | 25/09 | Foyer (total + solde par membre) et Compte (entrée Soldes et recharges) → S01 |
| LT-5 | fait | 25/09 | S02 : solde d'un profil dans la fiche, dernière remise, ligne discrète sur l'Accueil |
| LT-6 | fait | 25/09 | S07-S08 : mouvements (filtres) et détail d'un mouvement / d'une remise |
| LT-7 | fait | 25/09 | S03-S04 : recharge, sélection nominative et répartition |
| LT-8 | fait | 25/09 | S05-S06 : vérifier la recharge et résultat par profil (paiement indisponible en production) |
| LT-9 | fait | 25/09 | S09-S11 : gérer les accès, conséquences, résultat |
| LT-D | fait | 25/09 | Dette de revue LT : constats 12, 15, 17 et relecture de la planche LT-6 détail |
| LT-F | fait | 25/09 | Corrections, suite complète, branche ui/tuteur-v1-t publiée (le poste B intègre) |
| LT-R | fait | 25/09 | Revue du lot T |
| P0-01 | fait | 24/09 | Manifeste visuel des maquettes (33 écrans relevés) |
| P0-02 | fait | 24/09 | Cartographie code, specs et branches (mapping des 42 routes) |
| P0-03 | fait | 24/09 | Décisions du coordinateur et réponses du directeur |
| P0-04 | fait | 24/09 | Base mesurée et reprises front (vraies classes, observation) sans migration |
| P0-05 | fait | 24/09 | Jetons gelés : DM Sans et Plus Jakarta Sans, palette, thème appliqué |
| P0-06 | fait | 24/09 | Contrats partagés K1 à K7 et données de test isolées |
| P0-07 | fait | 24/09 | Composants partagés, espaces i18n, outil de capture, dépendance caméra |
| P0-08 | fait | 24/09 | Navigation à 4 destinations, routeur complet, pages d'erreur et de retour |
| P0-09 | fait | 24/09 | Revues indépendantes (jetons et accessibilité, routes et contrats) |
| P0-10 | fait | 24/09 | Corrections des défauts relevés par les revues |
| P0-11 | fait | 24/09 | Vérification complète : analyse, suite de tests, frontière backend |
| P2-01 | fait | 25/09 | Intégration du lot C dans ui/tuteur-v1 |
| P2-02 | fait | 2026-09-25 09:48 | Intégration du lot E |
| P2-03 | fait | 2026-09-25 10:03 | Intégration du lot O |
| P2-04 | fait |  | Intégration du lot B |
| P2-05 | fait | 25/09 | Intégration du lot D |
| P2-06 | fait |  | Intégration du lot A |
| P2-07 | fait |  | Mode démonstration tuteur sur l'aperçu (jamais en production) |
| P2-08 | fait |  | Revue de fidélité aux maquettes (planches maquette / rendu) |
| P2-09 | fait | 25/09 | Revue des parcours et routes (boutons touchés, aucune impasse, carte des fonctions) |
| P2-10 | fait |  | Revue mobile, tablette, desktop et accessibilité |
| P2-11 | fait |  | Revue sécurité et honnêteté (aucun faux succès, aucune modification backend) |
| P2-12 | fait |  | Corrections issues des revues |
| P2-13 | fait | 25/09 | Vérification complète finale et build web |
| P2-15 | fait | 25/09 | Matrice de recette et rapport au directeur |
| P2-16 | fait |  | Effets et animations modernes du rôle Tuteur, sans perte de performance |
| PB-01 | fait |  | Claude Code installé et connecté au compte |
| PB-02 | fait | 24/09 19:45 | Git et Flutter 3.47.2 installés, flutter doctor sans erreur |
| PB-03 | fait | 24/09 19:45 | Dépôt cloné en C:\RA\depot, pilotage en C:\RA\pilotage, dépendances installées |
| PB-04 | fait | 24/09 19:35 | Coordination et mandats lus, écriture dans ce tableau vérifiée |
| PT-A-20260927-1855bd1e | fait | 2026-09-27 | M5 partie enseignant |
| PT-A-20260927-23701dda | fait | 2026-09-27 | Harmonisation : CarteIdentiteCompte et GroupeReglages (Ma famille) |
| PT-A-20260927-76026f25 | fait | 2026-09-27 | Harmonisation : CarteSession et BlocBibliotheque |
| PT-A-20260927-95f9bd6a | fait | 2026-09-27 | Harmonisation : TimelineRow, EntetePage, ClocheNotifications |
| PT-A-20260927-b3338418 | fait | 2026-09-27 | Harmonisation : BlocProgression et ligne de participant |
| PT-A-20260927-c3141f46 | fait | 2026-09-27 | Harmonisation : PaiementsComptePage et Foyer |
| PT-A-20260927-e0b2c3b2 | fait | 2026-09-27 | Harmonisation : EmplacementAvantProchainCours |
| PT-A-20260927-eb96eba0 | fait | 2026-09-27 | Coquille adulte à 200 % |
| PT-A-20260927-fe71b248 | fait | 2026-09-27 | Harmonisation : CarteIdentiteCompte du tuteur |
| PT-A-20261002-150fe450 | fait | 2026-10-02 | Harmonisation : Compte tuteur, LienFleche, ChoiceCardGroup |
| PT-A-20261002-25554758 | fait | 2026-10-02 | EA-RC délais du menu de démonstration |
| PT-A-20261002-51537228 | fait | 2026-10-02 | En-tête Ajouter ma famille |
| PT-A-20261002-8818882d | fait | 2026-10-02 | Harmonisation : ActionPrincipale |
| PT-A-20261002-8d9412ea | fait | 2026-10-02 | TH-2 bouton principal pâle |
| PT-A-20261002-98727b14 | fait | 2026-10-02 | Bientôt épuisé (seuil serveur) |
| PT-A-20261002-9be1424b | fait | 2026-10-02 | Harmonisation : notifications et confirmations |
| PT-A-20261002-a4a8025f | fait | 2026-10-02 | Harmonisation : NavShell et PageShell |
| PT-A-20261002-aa507883 | fait | 2026-10-02 | Icônes acceptée et refusée peu distinctes |
| PT-A-20261002-d1366b21 | fait | 2026-10-02 | Points au directeur pour la planche EA-RC |
| PT-A-20261002-fa385f0a | fait | 2026-10-02 | Harmonisation : GroupeReglages |
| PT-A-20261002-pageparcours | fait | 02/10 | Harmonisation : PageParcours (en-tête décalé à 1440, question sous l'en-tête à 390, bouton pleine largeur hors mobile) |
| PT-A-20261002-settingrow | fait | 02/10 | Harmonisation : SettingRow, valeur sous la légende à l'étroit |
| PT-B-20260927-18603ba6 | fait | 2026-09-27 | Harmonisation : NavShell, libellés sur deux lignes |
| PT-B-20260927-1ab2a969 | fait | 2026-09-27 | HU-1 : lisibilité de la salle élève et enseignant |
| PT-B-20260927-ba1364f5 | fait | 2026-09-27 | Harmonisation : identité de Classe et Bibliothèque à 200 % |
| PT-B-20260927-bfdc3dfa | fait | 2026-09-27 | Fusion : 8 choix d'apparence |
| PT-B-20260927-c6b3f1b8 | fait | 2026-09-27 | Harmonisation : options ajoutées aux composants communs |
| PT-B-20260927-cae9ce91 | fait | 2026-09-27 | Documents manquants du directeur |
| PT-B-20260927-d857422d | fait | 2026-09-27 | Harmonisation : lecteur Coran |
| PT-B-20261001-ce25f8e2 | fait | 2026-10-01 | D1 stratégie de branchement serveur |

## feuille_de_route (37)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| CO-04 | a_faire |  | Pull request brouillon ui/tuteur-v1 vers main et adresse d'aperçu |
| DIR-01 | a_faire |  | Validation des captures et de l'aperçu, lot par lot |
| DIR-02 | a_faire |  | Décision de fusion dans main (mise en production) |
| HL-B-4 | a_faire | 25/09 | Questionnaire d'accueil : à traiter APRÈS tous les rôles (noyau de l'app et de l'académie) |
| HL-B-6 | en_cours | 25/09 | Consentements conformes (Rewayah Academy Ltd, droit anglais) : 9 textes v2, charte pour tous les rôles |
| LA-3 | en_cours | 2026-09-25 07:52 | Dossier et consentements (nouvelle version avec l'observation) |
| P2-14 | a_faire |  | Aperçu à jour et vérification des textes dans l'app servie |
| R-01 | en_cours | 24/09 | Vague Tuteur V1 : tous les écrans et parcours du tuteur (frontend) |
| R-02 | a_faire |  | Vague Classe et visio : un élève et un enseignant se rencontrent et se voient (priorité n° 1) |
| R-03 | a_faire |  | Validation des dossiers enseignants par l'administration (débloque le rôle enseignant) |
| R-04 | a_faire |  | Backend T1 : garanties serveur du tuteur, sécurité, CI verte |
| R-05 | a_faire |  | Lecteur du Coran fidèle au Mushaf du complexe du roi Fahd |
| R-06 | en_cours |  | Rôle enseignant |
| R-07 | a_faire |  | Rôle élève adulte |
| R-08 | a_faire |  | Rôle élève enfant (Interface guidée, accessibilité) |
| R-09 | a_faire |  | Administration |
| R-10 | a_faire |  | Contrôleur et contrôleur invité |
| R-11 | a_faire |  | Finance et comptable |
| R-12 | a_faire |  | Bibliothèque et ressources pédagogiques |
| R-13 | a_faire |  | Solde par enfant et recharge (tuteur) |
| R-14 | a_faire |  | Landing page de la web app |
| R-15 | a_faire |  | Publication iOS, Play Store et Windows |
| R-16 | a_faire |  | Nettoyage Git sur liste validée par le directeur (branches, worktrees) |
| S-00 | a_faire |  | 00 Guides transverses : UX/UI et copywriting |
| S-01 | a_faire |  | 01 Tuteur : compléments (52 écrans sans maquette, planche 3, solde et recharge) |
| S-02 | fait | 25/09 | 02 Classe et visio : élève et enseignant se rencontrent et se voient |
| S-03 | fait |  | 03 Administration : validation des dossiers |
| S-04 | fait |  | 04 Enseignant |
| S-05 | a_faire |  | 05 Élève adulte |
| S-06 | a_faire |  | 06 Élève enfant (Interface guidée) |
| S-07 | a_faire |  | 07 Administration (tous les domaines) |
| S-08 | a_faire |  | 08 Contrôleur et contrôleur invité |
| S-09 | a_faire |  | 09 Finance et comptable |
| S-10 | a_faire |  | 10 Bibliothèque et ressources |
| S-11 | a_faire |  | 11 Lecteur du Coran |
| S-12 | a_faire |  | 12 Pages publiques et landing web |
| S-13 | a_faire |  | 13 Publication (stores, enfants, logo, e-mails, légal) |

## consignes (50)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| K-00 |  |  | Chacun sert le suivant |
| K-01 |  |  | Lire 4 choses, pas 30, au démarrage ET avant chaque étape |
| K-02 |  |  | Où sont les choses (tout poste) |
| K-03 |  |  | Réserver avant de coder, prouver, faire vérifier |
| K-04 |  |  | Git, PowerShell, format : commandes qui marchent du premier coup |
| K-05 |  |  | Toujours le verrou pour Flutter lourd, un dossier de tests à la fois |
| K-07 |  |  | Définition de « fait » |
| K-08 |  |  | Traductions (slang) |
| K-09 |  |  | Ports : neutre par défaut, réel dans main.dart |
| K-10 |  |  | Composants et écrans existants d'abord, jamais recopiés |
| K-11 |  |  | Icônes : chercher sous tous les noms |
| K-12 |  |  | Animations : sobres et coupables |
| K-14 |  |  | Fusionner une branche de rôle : une seule session, cet ordre |
| K-15 |  |  | Le bon modèle pour chaque tâche |
| K-16 |  |  | Tâches de moins de 40 minutes, poussées morceau par morceau |
| K-17 |  |  | Garde contre les messages relayés |
| K-18 |  |  | Donner le diagnostic, pas la recherche |
| K-19 |  |  | Ce qui reste interdit sans accord écrit du directeur |
| K-21 |  |  | Parler au directeur |
| K-26 |  |  | Consentements et textes légaux : suivre la charte |
| K-28 |  |  | Serveur et configuration : seulement dans les étapes BR-1 ; ailleurs, démonstration |
| K-29 |  |  | Pendant et après une suite de tests |
| K-30 |  |  | Un seul agent qui committe par worktree |
| K-32 |  |  | Jamais « faute de temps » en fin de lot |
| K-33 |  |  | Relire une planche contre le document, et relire soi-même un défaut |
| K-37 |  |  | Thème figé : chrome / violet |
| K-38 |  |  | 🧊 Règles gelées DESIGN-GOV-2026-09-26 : autorité, validation UX 2026, contrats A à E |
| K-40 |  |  | Classe : règles réutilisables de l'entrée en classe et de la salle (R1 à R21), pour tous les agents |
| K-41 |  |  | Langues : préparer la traduction dès maintenant, traduire seulement à l'étape LG-1 |
| K-42 |  |  | Style de référence : celui de l'entrée en classe (CL-4), à généraliser à tous les lots |
| K-43 |  |  | Enseignant : règles E1 à E20, planches rectifiées, perfectionner l'existant sans recommencer |
| K-44 |  |  | Photo de l'élève : elle s'affiche chez son enseignant, à l'administration et chez ses camarades de Classe |
| K-45 |  |  | Cahier de séance : il conditionne la paye, évalue chaque élève, guide le remplaçant, en moins de 45 s, de bonne foi |
| K-47 |  |  | KYC : réservé à l'enseignant ; le tuteur n'a ni pièce d'identité ni attente de validation |
| K-48 |  |  | Le tableau (YAADEN) est obligatoire pour toute session et tout agent |
| K-49 |  |  | Avant de commencer un nouveau rôle : signaler d'abord au directeur les points prioritaires |
| K-50 |  |  | Contrôleur, Mode Accessibilité, Élèves adultes : où sont les règles ; la visite du contrôleur |
| K-52 |  |  | Session cloud : vérifier l'accès au dépôt avant de promettre une étape |
| K-53 |  |  | Décisions du directeur du 27/09 : définitives, plus de choix provisoires |
| K-54 |  |  | Tout bouton : contenu centré horizontalement ET verticalement, partout |
| K-55 |  |  | Jamais de cartes collées : reprendre le style des écrans tuteur |
| K-56 |  |  | Hiérarchie des boutons : un seul bouton plein par écran, bien placé, au style de l'app |
| K-57 |  |  | Formulaires semi-automatiques partout (web et mobile) : préremplir, proposer, ne faire saisir qu'en dernier recours |
| K-58 |  |  | Tout choix proposé s'explique : quand le choisir, et ce qu'il entraîne |
| K-59 |  |  | Tout message d'erreur ou de données incomplètes dit : la cause probable, et quoi faire en attendant |
| K-60 |  |  | Aucune tâche n'appartient à un poste : toute session prend la suivante dans l'ordre |
| K-61 |  | 02/10 | Ne pas refaire les erreurs de la session des corrections (02/10) : une correction n'est faite que si le directeur la voit à l'endroit exact  |
| K-62 |  |  | Couleur de profil : choisie par le tuteur, bandeau derrière l'avatar |
| K-63 |  |  | Maquette nouvelle : on prend la composition, jamais son style |
| K-64 |  |  | Pages publiques (landing, vitrine) : chantier d'un autre agent, ne pas y toucher |

## relais (420)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| A-20260927-02486d3c |  | 2026-09-27 | Invitation du conjoint en cours de code, puis EA-7 à EA-11 dans la même chaîne |
| A-20260927-1b9caf96 |  | 2026-09-27 | Ma classe en sections, participants avec photo ; vue conjoint en état indisponible (EA-BR-13) ; captures relues |
| A-20260927-406e31da |  | 2026-09-27 | Correction : le travail enseignant 0b01297 et 1108a4a est bien sur GitHub, dans ui/eleves-adultes-v1 (7cbdaaa). La partie enseignant de M5 e |
| A-20260927-54ae87ac |  | 2026-09-27 | Accueil de l'élève adulte, téléphone et ordinateur, réutilise CarteSession, EmplacementEntree, TimelineRow et BlocBibliotheque ; revue refus |
| A-20260927-698e5fd3 |  | 2026-09-27 | YAADEN obligatoire : relais forcé par le hook Stop, rappel de boîte, poste A orchestrateur |
| A-20260927-a29a12af |  | 2026-09-27 | Arrêt faute de tokens hebdo : correction de la revue EA-5 non commitée dans D:\RA_TUTEUR\adultes ; reprise décrite dans le dépôt A-handoff-2 |
| A-20260927-a6bc62c1 |  | 2026-09-27 | Poste A : EA-5 à EA-11 enchaînés (code, captures, revue, correction), K-51 appliqué, EA-BR numérotés à partir de 14 |
| A-20260927-a8f900a6 |  | 2026-09-27 | ui/admin-v1 poussée sur GitHub (2fac423..a8dfcb3), pilotage aea7db3 poussé ; prêt pour la vérification par une autre session |
| A-20260927-b5aef346 |  | 2026-09-27 | Workflow lancé : fusion CL-4 (M5 partiel), M1, M3 partie client, M4, M2 planche, revue adversariale, suite complète |
| A-20260927-be33eedd |  | 2026-09-27 | Ma famille du titulaire adulte (place adulte F21, libellés selon le genre F3, « Un proche adulte » retiré F2), Accueil de la conjointe sans  |
| A-20260927-c1d55a99 |  | 2026-09-27 | Poste A : EA-2, EA-3 et EA-4 en chaîne dans le worktree D:\RA_TUTEUR\adultes (code, captures, revue, correction), réutilisation K-51 |
| A-20260927-cf7cc27d |  | 2026-09-27 | Points prioritaires au directeur avant tout nouveau rôle ; AD-RC confiée à une nouvelle session |
| A-20260927-d0500cad |  | 2026-09-27 | installé sur le poste A, attend l'avis et l'installation du poste B |
| A-20260927-e7fddf12 |  | 2026-09-27 | M2 : planche.json à jour dans le pilotage (commit 2fac423, écrans tuteur HL-A-5 et HL-A-6, captures AD-10 marquées périmées K-47) |
| A-20260927-fc692278 |  | 2026-09-27 | Mon espace (Ma famille, Forfait famille pour le conjoint), plus de pastille « Compte validé » pour l'état normal ; EA-BR-04 à 13 dans le pil |
| A-20261001-6dbad2a8 |  | 2026-10-01 | Poste B éteint le 01/10 : CT-7, MA-8, EN-7c et la correction de CT-6 sont perdus. Reprise depuis les branches GitHub, voir le dépôt A-poste- |
| A-20261001-c6792d2f |  | 2026-10-01 | Reprise 01/10 : corrections EA-4c (confidentialité F6/F7), EA-5c (E5, E6), EA-6c (revue cloud, D5, E4), puis EA-7 à EA-11, décisions K-53 ap |
| A-20261002-010b5500 |  | 2026-10-02 | K-60 file commune : 90 étapes ouvertes à « tous », PLUS_TARD poste tous + auteur, Maintenant v44, dépôt A-retrait-poste-A-2026-10-02 |
| A-20261002-20082ab5 |  | 2026-10-02 | 3 causes corrigées (galerie Bento, tests des dossiers admin, débordement Mes Classes), relues : 0 bloquant ; revue croisée CORR-SUITE-1-R à  |
| A-20261002-23675d1f |  | 2026-10-02 | Stratégie des tableaux de bord + 7 fiches, relue (9 majeurs corrigés) |
| A-20261002-23d4f157 |  | 2026-10-02 | EtatSysteme borné à la largeur de lecture, Réessayer à sa taille au bord de fin, une icône par état d'invitation, icône « Validation refusée |
| A-20261002-2a1de9d3 |  | 2026-10-02 | Corrections galerie Bento, dossiers admin, débordement Mes Classes |
| A-20261002-2ac8edfb |  | 2026-10-02 | Reprise du foyer des deux côtés ; suite complète 3600 / 0 échec @ 43e0682 (EA-BR-27, 28) |
| A-20261002-2d26ec8f |  | 2026-10-02 | Pilotage : EA-BR-16 à 28 et captures ea5c, ea6c |
| A-20261002-350edb77 |  | 2026-10-02 | Décisions de la revue Finance reportées dans le plan Finance ; 12 contradictions laissées ouvertes, Q-FI-10 ajoutée au coin des questions (7 |
| A-20261002-3528d1ed |  | 2026-10-02 | Contrôle des documents Admin |
| A-20261002-359c8a8e |  | 2026-10-02 | 5 vérifiées dont la tuile vidéo ; 4 avec défauts dans la salle → SALLE-CORR-3 ; « en direct » non vérifiable en démonstration |
| A-20261002-362fbb7c |  | 2026-10-02 | Revue rectifiée : M1 et M3 annulés (E3 = b, K-53.8 ; K-53.6), RAPPORT critère 1 « non construit » (m14) |
| A-20261002-368762e0 |  | 2026-10-02 | Mineurs m1-m4 m6-m8 m13 m15-m17 |
| A-20261002-3f0fd9b9 |  | 2026-10-02 | M5 état hors ligne de page sur Accueil et Ma classe adultes, paramètre reseau=coupe |
| A-20261002-42137202 |  | 2026-10-02 | Pilotage : rapport de recette 05_recette/EA/RAPPORT.md, planche.json, captures ea12 |
| A-20261002-478c75b4 |  | 2026-10-02 | Les 8 composants partagés sont vérifiés ; mots coupés et captures anciennes → COUPE-MOTS-1, CAPT-L1-2 |
| A-20261002-50c1b937 |  | 2026-10-02 | Contrôle des documents Contrôleur |
| A-20261002-5106c205 |  | 2026-10-02 | UX_REVIEW_08_FINANCE relue et corrigée, questions Q-FI-1 à 9 |
| A-20261002-58a35a48 |  | 2026-10-02 | captures_ea12_test.dart : 50 captures de recette ; suite complète 3820 / 0 échec |
| A-20261002-65bc53af |  | 2026-10-02 | Suite par tranches lancée sous verrou, worktree corrections @ 0796f75 |
| A-20261002-6970a892 |  | 2026-10-02 | Invitation reçue côté second adulte, Accepter et Refuser de même poids, notifications (EA-BR-20) |
| A-20261002-6f7353c2 |  | 2026-10-02 | Paiements du foyer, soldes rendus tels quels, Recharger (EA-BR-23) |
| A-20261002-78903c76 |  | 2026-10-02 | EA-RC réservée, corrections M2 M4 M5 M6 et mineurs en cours sur ui/eleves-adultes-v1 |
| A-20261002-789c4677 |  | 2026-10-02 | 20 captures « avant » de la salle (élève, élève guidé, enseignant, à 3 largeurs), relues ; comparaison avec la revue en cours |
| A-20261002-79da1d78 |  | 2026-10-02 | Sortie du forfait famille, page Forfait famille, notifications du départ (EA-BR-21, 22) |
| A-20261002-7b12d9d9 |  | 2026-10-02 | Reprise des 2 relectures : totaux marqués, Continuer sans vraie connexion, garde hors ligne après confirmation ; suite complète verte |
| A-20261002-7b91e6d8 |  | 2026-10-02 | Pilotage : 66 captures earc régénérées ; planche https://claude.ai/artifact/WDY9JSeRA97kJe3V97PnQR mise à jour, commentaires du directeur tr |
| A-20261002-7f07cbee |  | 2026-10-02 | Passage 1 : 5 tests rouges (3 causes), correction en CORR-SUITE-1 |
| A-20261002-84e4722f |  | 2026-10-02 | EA-6c : réponse tardive après annulation, D5, E4, libellés provisoires D4 ; revue acceptée |
| A-20261002-8827c0c8 |  | 2026-10-02 | M6 déconnexion de démo locale (fermerDemo + faux service), M2 Paiements personnels seulement après lecture de la ligne famille |
| A-20261002-88b03262 |  | 2026-10-02 | Tests de recette recette_ea12_test.dart : aucun mot admin, aucun montant ni délai en dur, confidentialité du second adulte, démonstration fe |
| A-20261002-8fe99550 |  | 2026-10-02 | EA-5c : E5 « Validation refusée par la direction » + « Faire une nouvelle demande », E6 carte du titulaire en tête |
| A-20261002-91232baf |  | 2026-10-02 | Maquette 09 reçue ; écarts relevés (§A, §C) ; attente levée |
| A-20261002-922aece8 |  | 2026-10-02 | La grille Bento ne doit plus tomber à une seule colonne sur ordinateur quand le texte est agrandi |
| A-20261002-98e17fb3 |  | 2026-10-02 | Reprise des 2 relectures : rangée de boutons partagée, second adulte non rattaché, titre Invitation acceptée, états finaux sans flèche, band |
| A-20261002-a2fa45df |  | 2026-10-02 | Recette : 220 tests (aucun mot admin, aucun montant ni délai en dur, confidentialité du second adulte, démo fermée en production), 50 captur |
| A-20261002-a3b6179d |  | 2026-10-02 | M4 _Carte sur AppCard, résultats sur EcranResultat, _Actions noté HU-1 (tests foyer verts, suite plus bas) |
| A-20261002-a61e7c18 |  | 2026-10-02 | 4 vérifiées ; pièces juridiques signées encore marquées « projet » → DOC-VERIF-1 |
| A-20261002-a98e5805 |  | 2026-10-02 | Vérification des corrections de la salle, dont la tuile vidéo |
| A-20261002-ae6724b1 |  | 2026-10-02 | Captures EA-RC ; pilotage e86a89f ; planche https://claude.ai/artifact/WDY9JSeRA97kJe3V97PnQR |
| A-20261002-b002b8a1 |  | 2026-10-02 | Étape avant les changements (L0) levée : 20 captures de la salle ouvertes et décrites, chacune des 35 lignes de la revue comparée aux images |
| A-20261002-ba683044 |  | 2026-10-02 | UX_REVIEW_08_FINANCE en rédaction, relecture adverse prévue |
| A-20261002-bcf26f0c |  | 2026-10-02 | Recette : tests §21 et F1-F24, captures complètes, suite |
| A-20261002-bd98b89b |  | 2026-10-02 | Vérification des composants partagés du lot 1 |
| A-20261002-bd9a44eb |  | 2026-10-02 | Maquette 08 reçue ; écarts relevés (17_finance/ECARTS_MAQUETTES_08_10.md §A, §B) ; attente levée |
| A-20261002-c071526c |  | 2026-10-02 | UX_REVIEW_TB écrite et relue ; captures L0 en cours |
| A-20261002-c25cae1f |  | 2026-10-02 | ui/tuteur-v1-t : commit local du 26/09 (S10 bureau) poussé avant retrait |
| A-20261002-c8451f31 |  | 2026-10-02 | 6 vérifiées ; résumés de la règle design pas à jour → DOC-VERIF-1 |
| A-20261002-cbef06de |  | 2026-10-02 | Préparation Supports du tableau (18_supports_tableau : reprise, découpage TB-0 à TB-RC, TB-BR, questions) ; à vérifier par une autre session |
| A-20261002-ce9fed0e |  | 2026-10-02 | Maquette 10 reçue ; écarts relevés (§A, §D) ; attente levée |
| A-20261002-cfcf27ec |  | 2026-10-02 | 2 vérifiées (Foyer admin, absence) ; 5 avec défauts (Bento, cahier, objectif, erreur, photo) → COUPE-MOTS-1, BENTO-1b, LIB-LOT3-2 |
| A-20261002-d016427e |  | 2026-10-02 | Vérification de la grille Bento et des libellés du lot 3 (captures sur 98e3f9d) |
| A-20261002-d035d93d |  | 2026-10-02 | Note de stratégie et fiches en rédaction, branche corrections/c2-dash1 |
| A-20261002-d4d4b006 |  | 2026-10-02 | EA-4c : confidentialité F6/F7 (25 états testés), ligne famille avec chargement, erreur et hors ligne, E3 paiements du second adulte |
| A-20261002-e154b25b |  | 2026-10-02 | Pilotage : 60 captures dans 16_eleves_adultes/captures/earc |
| A-20261002-e1d536f6 |  | 2026-10-02 | T0 analyse 0 problème ; T1 1 échec catalogue_galerie (entrée de galerie manquante, suspect grille_bento) ; jetons 36 et revue 1400 en échec, |
| A-20261002-e1f080db |  | 2026-10-02 | Réunion des 4 branches de rôle lancée dans une branche à part ; la branche commune n'avance qu'après une suite entièrement verte |
| A-20261002-e3add5e2 |  | 2026-10-02 | Recharge en deux étapes, paiement non confirmé D5 (EA-BR-24 à 26) |
| A-20261002-e97ae7d3 |  | 2026-10-02 | Enseignant (0c0b739) puis contrôleur (f4c917c) fusionnés et relus : aucune intention perdue, analyse propre ; élèves adultes en cours |
| A-20261002-ee8febd8 |  | 2026-10-02 | Tableau rangé en 5 voies, 14 lots de vérification, 4 paquets en attente, 25 relevés fusionnés dans HU-1 ; consignes 55→47 ; LECONS_DES_ROLES |
| A-20261002-f10a77af |  | 2026-10-02 | Parcours « Ajouter ma famille » en démonstration (spec foyer §2 et §4), clé provisoire supprimée |
| A-20261002-f1dfee38 |  | 2026-10-02 | Passage 2 entièrement vert (analyse 0 ; 876, 912, 981, 983 et 821 tests passés, 0 échec), branche commune avancée et poussée ; les 9 étapes  |
| A-20261002-f2f81bdf |  | 2026-10-02 | Revue croisée à confier à une autre session que le poste A (le poste B est éteint ; une session cloud peut la faire) |
| A-20261002-f5590ac2 |  | 2026-10-02 | UX_REVIEW_TB en rédaction, relecture adverse prévue |
| A-20261002-fcc203cd |  | 2026-10-02 | Préparation Finance (17_finance : reprise, découpage FI-0 à FI-RC, FI-BR, questions) ; à vérifier par une autre session (VERIF-PREP) |
| A-20261003-00da2c24 |  | 2026-10-03 | Élèves adultes fusionnée et relue ; toute la suite relancée après les changements de composants partagés : 5046 tests passés, 0 échec ; acce |
| A-20261003-05b4d50d |  | 2026-10-03 | Revue acceptée : colonnes recalculées et justes, 144 cas mesurés sans débordement. Mineurs portés par BENTO-2b. |
| A-20261003-0604d396 |  | 2026-10-03 | Deux questions de la fusion de l'accessibilité ajoutées au coin des questions (I-Q1 : le Coran dans la barre, I-Q2 : le mot d'état des bouto |
| A-20261003-07a806f7 |  | 2026-10-03 | Revue acceptée : FI-1b passe à « fait » et FI-1c est débloquée. Mineurs portés par COUPE-MOTS-1 et DEMO-ENV-1. |
| A-20261003-0a3e7c9a |  | 2026-10-03 | fusion de c2-bento1b poussée sur corrections/revue-directeur-2026-10, analyse propre. |
| A-20261003-0b7a1916 |  | 2026-10-03 | Revue refusée : sur tablette, des mots sont coupés dans la carte classe de l'accueil famille. Correctifs portés par BENTO-2b (rapport pilota |
| A-20261003-0fb4823d |  | 2026-10-03 | Réservée par la session 90248232 ; un agent vérifie en lecture seule ui/eleves-adultes-v1 @ 5629693 (dossier v-ea1), puis un contradicteur i |
| A-20261003-10213d8f |  | 2026-10-03 | Question I-Q2 précisée au coin des questions : mesures, deux choix, recommandation |
| A-20261003-108aea2c |  | 2026-10-03 | Contrôleur et élève adulte en Bento ; base = branche commune fusionnée fa64a6ad + c2-dash1 (DASH_STRATEGIE) |
| A-20261003-13ce9079 |  | 2026-10-03 | Réservée par la session 90248232 ; un agent vérifie en lecture seule ui/eleves-adultes-v1 @ 5629693 (dossier v-ea2), puis un contradicteur i |
| A-20261003-2608d141 |  | 2026-10-03 | Revue croisée à faire par une autre session que b0cfa272 |
| A-20261003-30d5c8cb |  | 2026-10-03 | « Ajustez la suggestion » ne s'affiche que pour une vraie suggestion, et rien n'est inventé. Questions C-Q1 et C-Q2 posées. |
| A-20261003-31dfa152 |  | 2026-10-03 | règle D12 et recensement Bento mis à jour sur corrections/c2-dash1 |
| A-20261003-39514995 |  | 2026-10-03 | Suite complète arrêtée par manque de mémoire de la machine, ce n'est pas un échec de test. Elle reste à relancer avant d'avancer la branche  |
| A-20261003-42df0dce |  | 2026-10-03 | Réservée par la session 90248232 ; un agent vérifie le pilotage seulement (FI-0, TB-0, leçons des rôles), puis un contradicteur indépendant  |
| A-20261003-44f9d28d |  | 2026-10-03 | Lot « mots coupés » avec PASTILLE-COUPE-1 et COUPE-MOTS-1, sans toucher aux fichiers de la grille Bento. |
| A-20261003-5087e308 |  | 2026-10-03 | La feuille « Ajuster » du cahier en texte ×2 et le cas positif de la suggestion (EN-7c-SUGG-T) sont en cours dans le workflow wf_4fb45bc1-f9 |
| A-20261003-5345c549 |  | 2026-10-03 | Lot relu par un autre agent, 4 défauts majeurs corrigés (8097103a), 5330 tests réussis sur 8097103a. Travail Bento repris dans la branche, s |
| A-20261003-571871b3 |  | 2026-10-03 | La marque de Mes Classes n'est plus bornée à 200 px, test en arabe ajouté. La relecture et les tests restent à faire. |
| A-20261003-5b2237d0 |  | 2026-10-03 | 7 étapes sur 8 passent à « vérifié ». CT-3 n'est pas vérifiée : décision C5 non appliquée, « Agrandir » sans support, contrôleur sans micro  |
| A-20261003-5da8b015 |  | 2026-10-03 | galerie GrilleBento = vraies tuiles du Centre de commande, captures 390/1440 clair/sombre ; revue croisée GALERIE-BENTO-2-R demandée |
| A-20261003-6087760b |  | 2026-10-03 | Mode Accessibilité fin de vague vérifié sur ui/accessibilite-v1 @ 7885b35 : analyse 0, +850 verts, captures 390 ×2 salle et Coran (visibles, |
| A-20261003-60b54257 |  | 2026-10-03 | réservée ; 3 lots de vérification lecture seule + 3 contrôles adverses lancés |
| A-20261003-63425e90 |  | 2026-10-03 | revue croisée par une session autre que 00166a22 |
| A-20261003-6795d674 |  | 2026-10-03 | Vérifiée : 8 étapes passent à « vérifié ». Analyse 0, +613 verts, 23 captures ouvertes. Un mineur devient l'étape EA-HORS-LIGNE-1. Le contra |
| A-20261003-69e61949 |  | 2026-10-03 | Les quatre branches de rôle sont réunies et la branche commune est avancée ; une autre session doit faire la revue INTEG-RC-1-R. |
| A-20261003-6ac7cad7 |  | 2026-10-03 | features 2475/0, router 277/0, widgets 230/0, accessibilite 314/0 ; suite de nouveau arrêtée par manque de mémoire pendant teaching_core ; r |
| A-20261003-6e671275 |  | 2026-10-03 | FI-0 et TB-0 passent à « vérifié ». Nouvelles étapes : FI-ACCENT-1 (FI-2 l'attend) et TB-STYLET-1 (TB-7b l'attend, et elle corrige aussi « 1 |
| A-20261003-751e1e79 |  | 2026-10-03 | La pastille « Remplacement » n'est plus coupée au milieu du mot. La relecture et les tests restent à faire. |
| A-20261003-7ad82a8b |  | 2026-10-03 | PASS avec 2 réserves, nouvelles étapes EN-7c-200 et EN-7c-SUGG-T |
| A-20261003-8094a032 |  | 2026-10-03 | Les flèches du Coran disparaissent de nouveau en bout de livre (test ajouté) ; la revue du directeur est mise à jour ; la décision sur le mo |
| A-20261003-878c060c |  | 2026-10-03 | Le point 3 est déjà réglé par GALERIE-BENTO-2 (la galerie montre les vraies tuiles du Centre de commande). |
| A-20261003-89d43e91 |  | 2026-10-03 | Suite complète 5360/0, branche commune avancée et poussée |
| A-20261003-94f53724 |  | 2026-10-03 | Inclus dans af20f6c2, suite 5360/0 |
| A-20261003-9a5e324c |  | 2026-10-03 | Fusionnée via c2-bento2b après BENTO-1c-R acceptée ; D12 reprise dans c2-bento3 |
| A-20261003-aae0fe50 |  | 2026-10-03 | Réservée par la session 90248232 ; un agent vérifie en lecture seule ui/controleur-v1 @ 39a702a (dossier v-ct1), puis un contradicteur indép |
| A-20261003-ada09dd6 |  | 2026-10-03 | Réservée par la session 90248232 ; un agent vérifie en lecture seule ui/accessibilite-v1 @ 7885b35 (dossier v-ma1), puis un contradicteur in |
| A-20261003-af2dbae0 |  | 2026-10-03 | Code et captures poussés ; analyze 0, core 648/0 ; suite features arrêtée par manque de mémoire (autre suite Flutter en même temps), à relan |
| A-20261003-b354e9a5 |  | 2026-10-03 | Fusionnée après BENTO-2b ; analyze 0, tous les dossiers de tests verts (0 échec) ; ETAT_A pilotage b6e563e8 |
| A-20261003-b592680b |  | 2026-10-03 | Inclus dans af20f6c2, suite 5360/0 |
| A-20261003-c3f3f8ab |  | 2026-10-03 | Revue croisée en lecture seule (wf_e122d4e5-c85), lancée en même temps que BENTO-1c-R et FI-1b-R. |
| A-20261003-c3fb1cf3 |  | 2026-10-03 | Revue croisée acceptée : 0 bloquant, 0 moyen, 0 mineur ; analyse 0, +583 verts ; tuiles déplacées sans recopie, galerie conforme au vrai Cen |
| A-20261003-cfa0ca3a |  | 2026-10-03 | La feuille « Ajuster » est testée et capturée avec le texte à 200 % (390 et 320 px) ; la relecture et la suite complète restent à faire. |
| A-20261003-db4e8dbf |  | 2026-10-03 | réservée, sous-branche corrections/c2-bento1c depuis c2-bento2 |
| A-20261003-dca2d8d1 |  | 2026-10-03 | fusion de c2-galerie2 poussée sur corrections/revue-directeur-2026-10, conflit tableau_de_bord résolu |
| A-20261003-e0e074ee |  | 2026-10-03 | 9 étapes passent à « vérifié », les 3 majeurs de MA-7 restent corrigés. Six décisions du directeur du 27/09 (A3 à A8) ne sont pas appliquées |
| A-20261003-e11d66e8 |  | 2026-10-03 | Question I-Q2 précisée et envoyée au dépôt de pilotage |
| A-20261003-e5ef6b4c |  | 2026-10-03 | La grille Bento garde ses colonnes et ses tuiles de tailles variées sur ordinateur avec un texte agrandi ; 341 tests passés, captures ouvert |
| A-20261003-e6436916 |  | 2026-10-03 | Vérifiée : 10 étapes passent à « vérifié ». Analyse 0, +801 tests ciblés et +3875 sur la suite complète, tous verts. Un mineur devient l'éta |
| A-20261003-e66b5541 |  | 2026-10-03 | tuiles du Centre de commande publiques et réutilisées par la galerie, branche corrections/c2-galerie2 poussée ; analyse et tests en attente  |
| A-20261003-e6f9febb |  | 2026-10-03 | A pass ; B : « Remplacement » coupé à ×2 → PASTILLE-COUPE-1 ; C : galerie Bento simplifiée → GALERIE-BENTO-2 |
| A-20261003-fa761b96 |  | 2026-10-03 | Relecture faite et défauts corrigés ; je verse le travail dans la branche commune quand la suite relancée est verte. |
| A-20261003-fd74af16 |  | 2026-10-03 | Voie CORR-2 reprise : correctifs de la revue BENTO-2-R refusée, avant fusion de c2-bento2 et c2-bento1c puis BENTO-3 |
| A-20261003-ffb50254 |  | 2026-10-03 | La feuille « Ajuster » est testée et capturée en entier à 200 % (390 et 320 px). La revue EN-7c-R est à faire par une autre session. |
| A-20261004-01cd6c0a |  | 2026-10-04 | message juste après rechargement |
| A-20261004-06cd04a6 |  | 2026-10-04 | corrections/c1-adm3 : refus et aperçu des pièces fermés en production jusqu'à BR-1 ; revue AD-M3-PROD-R créée en VERIF |
| A-20261004-0cd224e9 |  | 2026-10-04 | corrections/c1-demoenv : démos fermées en publication sans ENVIRONNEMENT déclaré |
| A-20261004-0e191a9b |  | 2026-10-04 | en-tête Coran MA sur une ligne à x2 |
| A-20261004-0ee095f6 |  | 2026-10-04 | analyze 0, 27 dossiers verts, fixtures 5582/1 (catalogue : ChampDate et SelecteurPersonne), widgets et racine à relancer après le correctif, |
| A-20261004-1100b287 |  | 2026-10-04 | revue croisée des formulaires à faire par une autre session |
| A-20261004-126a4ab6 |  | 2026-10-04 | intégration des 8 sous-branches CORR-1, puis suite complète |
| A-20261004-16626e56 |  | 2026-10-04 | ChampDate et SelecteurPersonne déclarés au catalogue et à la galerie, catalogue_galerie_test 17/0 |
| A-20261004-1691235c |  | 2026-10-04 | décisions A3, A5, A8 |
| A-20261004-178f0ac8 |  | 2026-10-04 | pré-vol micro seulement pour qui parle |
| A-20261004-246c0718 |  | 2026-10-04 | réponses du directeur : Studio admin seul, Communauté raccourci, administration sous Opérations ; voie COM laissée aux sessions cloud |
| A-20261004-255531bd |  | 2026-10-04 | déjà conforme après SALLE-CORR-3 |
| A-20261004-2825d2db |  | 2026-10-04 | commandes de la salle à 320, encre, titre du rappel, cours annulé |
| A-20261004-2bc2f54b |  | 2026-10-04 | Agrandir retiré tant qu'aucun support n'est rendu |
| A-20261004-36efc64c |  | 2026-10-04 | vouvoiement de l'adulte |
| A-20261004-3cd012a8 |  | 2026-10-04 | corrections/c1-adm3 : test de la porte de lecture et de l'état indisponible de la visionneuse ; contre-épreuve laissée à AD-M3-PROD-R |
| A-20261004-4d897f1b |  | 2026-10-04 | Comptes et mineurs admin ; reste dans AD-NETTOYAGE-2 |
| A-20261004-4f2e8837 |  | 2026-10-04 | marge barre MA 320, jetons, source echecEnvoi |
| A-20261004-54ea1538 |  | 2026-10-04 | corrections/c1-demoenv : PageShell garde la position de défilement à la bascule |
| A-20261004-5a308792 |  | 2026-10-04 | recensement des 40 formulaires (73 champs saisis → 36), conversions découpées en étapes FORM-L*, listes de motifs en attente du directeur |
| A-20261004-5baffe29 |  | 2026-10-04 | chantier Communications V1 créé : 17 étapes COM (1300-1353 + COM-Q), 6 voies, consigne K-63, inventaire L0 lancé |
| A-20261004-60715cac |  | 2026-10-04 | niveau du programme proposé, sans saisie |
| A-20261004-735ebd77 |  | 2026-10-04 | correctif du catalogue intégré ; reste fixtures, widgets et racine à relancer avec l'accord du directeur |
| A-20261004-78e1be95 |  | 2026-10-04 | corrections/c1-demoenv : focus au titre après la dernière décision, 390 et 1440 |
| A-20261004-7cc917b4 |  | 2026-10-04 | le retour système recule d'une étape, texte gardé ; contrôleur 189/0, contre-épreuve rouge |
| A-20261004-7e383f41 |  | 2026-10-04 | refus et aperçu des pièces fermés en production jusqu'à BR-1 ; suite complète par dossiers en cours sur corrections/c1-adm3 |
| A-20261004-7fdf50e8 |  | 2026-10-04 | suite complète verte : fixtures 5583/0, widgets 281/0, racine 1/0, 27 autres dossiers verts sur 6a7b0c4a |
| A-20261004-88cfe5d8 |  | 2026-10-04 | corrections/c1-demoenv : ni titre ni onglet réservé tant que la capacité n'est pas confirmée |
| A-20261004-897d6413 |  | 2026-10-04 | M1 levé et prouvé ; reste un mot coupé dans « À terminer » à 320 ×2 avec 4 cahiers ou plus, non couvert par le test ; rapport en cours d'écr |
| A-20261004-9096704a |  | 2026-10-04 | relevé et roster par séance |
| A-20261004-a8e33d3b |  | 2026-10-04 | 6 sous-branches CORR-1 intégrées sur corrections/c1-integ2, suite complète en cours |
| A-20261004-b330cb29 |  | 2026-10-04 | page de décisions publiée pour le directeur (11 questions, 50 libellés) : https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW |
| A-20261004-b659241d |  | 2026-10-04 | délai maximal sur les envois du contrôleur |
| A-20261004-ba02398b |  | 2026-10-04 | un seul écran de fin en MA |
| A-20261004-c3ff2bc5 |  | 2026-10-04 | Son reçu retiré de la salle du contrôleur jusqu'à BR-1 |
| A-20261004-d3650ca0 |  | 2026-10-04 | résumés DESIGN-GOV, pièces juridiques marquées signées (pilotage d3ea5fe9) |
| A-20261004-da495f7a |  | 2026-10-04 | suite complète par dossiers 0 échec (features 2475, fixtures 5329, teaching_core 912, core 648…) ; revue BENTO-3-R créée en VERIF (exclut 0c |
| A-20261004-db1a65d4 |  | 2026-10-04 | date au calendrier, « Autre pièce officielle », libellé de jeton prérempli, courriel de récupération repris |
| A-20261004-dd25baa4 |  | 2026-10-04 | BR-CT-19 inscrit au pilotage (5c703347) et test du chemin par défaut de « Commencer » sur corrections/c1-adm3 |
| A-20261004-e360f739 |  | 2026-10-04 | réponses du directeur inscrites dans 19_communications/QUESTIONS.md |
| A-20261004-e89b07ab |  | 2026-10-04 | âge en puces, nom prérempli |
| A-20261004-ebfa3928 |  | 2026-10-04 | Revue croisée lancée : 6 angles et vérification adverse, en lecture seule |
| A-20261004-ed6f4326 |  | 2026-10-04 | sélecteur de personne à la place des identifiants tapés |
| A-20261004-f5a4cf43 |  | 2026-10-04 | relance de fixtures, widgets et racine sous le verrou, accord du directeur donné |
| A-20261004-f9e8372b |  | 2026-10-04 | libellés du lot 3 |
| A-20261004-fc86dcba |  | 2026-10-04 | Revue refusée : M1 levé, « À terminer » encore coupé à 320 ×2 avec « Voir tout » ; correction BENTO-2c créée en CORR-2 |
| B-20260927-022eaaf7 |  | 2026-09-27 | Revue UX de l'Accessibilité en cours |
| B-20260927-064d120c |  | 2026-09-27 | Socle du Contrôleur en cours |
| B-20260927-06e77984 |  | 2026-09-27 | Revue UX de l'Accessibilité : 18 lignes ; 3 réglages existants n'agissent sur rien, réparation au socle |
| B-20260927-0768f6c7 |  | 2026-09-27 | Salle et préparation en Mode Accessibilité en cours |
| B-20260927-077b418a |  | 2026-09-27 | Besoin serveur des échanges (BR-CT-13) |
| B-20260927-089b5da4 |  | 2026-09-27 | Vérification EN-7b par une autre session : captures build/captures/en7b, relevés dans la fiche EN-7 |
| B-20260927-092794b7 |  | 2026-09-27 | Socle Accessibilité : mode lu à un seul endroit, « Réduire les animations » enfin actif partout, démonstration /demo/accessibilite ; à vérif |
| B-20260927-09b0c0de |  | 2026-09-27 | Socle des Élèves adultes en cours (poste B ; le poste A reprend à EA-2) |
| B-20260927-0b0d5377 |  | 2026-09-27 | Compte rendu du contrôleur : faits automatiques, 3 choix, aucun faux succès ; suite complète à relancer |
| B-20260927-1105406e |  | 2026-09-27 | Carte du support à 200 % puis écran « Après la séance » en cours |
| B-20260927-129ee8bd |  | 2026-09-27 | Poste B : prouver la transmission automatique des faits dès la sortie de la salle (même avec « Plus tard ») ; boutons empilés sur ordinateur |
| B-20260927-179f9f2c |  | 2026-09-27 | Navigation élève à 4 destinations dans les deux présentations ; à vérifier par une autre session |
| B-20260927-181a4b74 |  | 2026-09-27 | Compte rendu : faits transmis automatiquement dès la sortie de la salle (même avec « Plus tard »), état honnête, boutons corrigés ; à vérifi |
| B-20260927-1a11174e |  | 2026-09-27 | Coran en Mode Accessibilité en cours, autour du rendu sans y toucher |
| B-20260927-1b26da79 |  | 2026-09-27 | Préparation du rôle Contrôleur lancée (document, 5 planches, décisions du directeur de notes.txt) |
| B-20260927-1e2d6327 |  | 2026-09-27 | Ma classe en Mode Accessibilité en cours (avec le nom coupé à 200 % et le titre « Mes classes ») |
| B-20260927-1fcb9fa0 |  | 2026-09-27 | Mon espace en Mode Accessibilité en cours (page commune réutilisée) |
| B-20260927-226c7f93 |  | 2026-09-27 | Plan de fusion Admin + Enseignant livré au poste A (dépôt B-plan-fusion-2026-09-27) : 7 conflits, 2 erreurs cachées, 8 choix provisoires |
| B-20260927-2352a142 |  | 2026-09-27 | Ma classe en Mode Accessibilité : titre aligné, nom entier à 200 %, tutoiement, Mon suivi ; à vérifier par une autre session |
| B-20260927-2665443c |  | 2026-09-27 | Préparation du Mode Accessibilité lancée (document, 4 planches) |
| B-20260927-28bd50ba |  | 2026-09-27 | Échanges du contrôleur avec l'administration en cours (fil de discussion réutilisable) |
| B-20260927-2e0f40c2 |  | 2026-09-27 | Vérification CT-5 par une autre session : captures build/captures/ct5 |
| B-20260927-31c3fde7 |  | 2026-09-27 | Salle Mode Accessibilité : test de parcours réparé, nom de l'élève suivi, textes de /salle lisibles ; reste la carte du support à 200 % |
| B-20260927-33f2b76f |  | 2026-09-27 | Mode Accessibilité préparé : planches, règles MA1-MA24, 16 étapes, branche ui/accessibilite-v1 |
| B-20260927-35fc79bd |  | 2026-09-27 | Observation structurée du contrôleur en cours |
| B-20260927-36b09fc5 |  | 2026-09-27 | Navigation élève à 4 destinations en cours |
| B-20260927-3a3e50c1 |  | 2026-09-27 | Ma classe en Mode Accessibilité : travail fait non enregistré, reprise par un nouvel agent (suite complète, captures, enregistrement) |
| B-20260927-3f032951 |  | 2026-09-27 | Compte rendu du contrôleur en cours, transmission automatique à l'administration |
| B-20260927-4aa48d28 |  | 2026-09-27 | Plan de fusion Admin + Enseignant en préparation (lecture seule, 7 conflits, vérification croisée), destiné au poste A |
| B-20260927-528edfe2 |  | 2026-09-27 | Revue UX des Élèves adultes : 19 lignes, textes T1 à T3 à valider |
| B-20260927-54910503 |  | 2026-09-27 | Écran Contrôle en cours : une seule carte de mission, entrée seulement pendant le cours |
| B-20260927-57659e4f |  | 2026-09-27 | Vérification du socle Contrôleur par une autre session : captures build/captures/ct1b |
| B-20260927-5776cf35 |  | 2026-09-27 | Observation du contrôleur dans la salle en cours |
| B-20260927-63e24a34 |  | 2026-09-27 | Vérification MA-2 par une autre session : captures build/captures/ma2 ; défauts relevés à 200 % dans la fiche |
| B-20260927-69e1c20c |  | 2026-09-27 | Vérification du socle Accessibilité par une autre session : captures build/captures/ma1b |
| B-20260927-71cef09f |  | 2026-09-27 | revue croisée Admin finie : 5 majeurs, rapport 05_recette/AD/REVUE_AD-R.md |
| B-20260927-80c06848 |  | 2026-09-27 | Accueil élève en Mode Accessibilité : ordre du document, un seul bouton ; suite complète tuée par manque de mémoire, relancée avec correctio |
| B-20260927-81ec2040 |  | 2026-09-27 | Besoins serveur du Contrôleur (CT-BR.md, 9 lignes) |
| B-20260927-8320a24e |  | 2026-09-27 | Relu par le poste B : titre et libellés de la salle du contrôleur presque illisibles sur fond sombre ; correction en cours |
| B-20260927-85979034 |  | 2026-09-27 | page du tableau : section « Relais entre postes » ajoutée, YAADEN actif sur le poste B |
| B-20260927-8aebd0a7 |  | 2026-09-27 | Socle Élèves adultes terminé : captures corrigées (l'erreur venait de l'outil de capture), 42 captures bonnes ; à vérifier par une autre ses |
| B-20260927-8bdb0658 |  | 2026-09-27 | Observation structurée du contrôleur : 5 étapes, texte obligatoire selon la gravité, envoi honnête ; à vérifier par une autre session |
| B-20260927-8c5d2130 |  | 2026-09-27 | Revue UX des Élèves adultes en cours (poste B, pour le poste A) |
| B-20260927-8cf4d2eb |  | 2026-09-27 | Socle de l'Accessibilité en cours |
| B-20260927-8d8b72e6 |  | 2026-09-27 | Ressources : documents du directeur Contrôleur et Accessibilité, règles C1-C21 et MA1-MA24 (documents seulement) |
| B-20260927-9030b0ce |  | 2026-09-27 | Contrôleur préparé : planches, règles C1-C21, 17 étapes, branche ui/controleur-v1 |
| B-20260927-938a02c9 |  | 2026-09-27 | Captures : l'écran « Ma famille » affiche une page d'erreur (6 captures) ; correction en cours avant de marquer le socle fait |
| B-20260927-9478105c |  | 2026-09-27 | Vérification du socle Élèves adultes par une autre session : captures build/captures/ea1b |
| B-20260927-95ac6928 |  | 2026-09-27 | Socle des Élèves adultes : 4 destinations, foyer Diallo de démonstration, /demo/adulte ; captures en cours |
| B-20260927-99757cb5 |  | 2026-09-27 | Revue UX du Contrôleur en cours |
| B-20260927-9e2f6f1b |  | 2026-09-27 | Après la séance en Mode Accessibilité : un seul bouton, sans « Très bien ! » ni confettis ; à vérifier par une autre session |
| B-20260927-9ebcf729 |  | 2026-09-27 | Coran en Mode Accessibilité : entrée simple, vrai lecteur réutilisé, « Lecture en grand texte » enfin active ; rendu du Coran intact ; à vér |
| B-20260927-a4b172f7 |  | 2026-09-27 | Échanges avec l'administration : fil par mission, envoi honnête, lien depuis le compte rendu ; suite complète relancée au début de CT-7 |
| B-20260927-aa835371 |  | 2026-09-27 | Vérification MA-7 par une autre session : captures build/captures/ma7 |
| B-20260927-aaaf640b |  | 2026-09-27 | Revue UX du Contrôleur : 20 lignes, 13 questions, rien de bloquant pour la démonstration |
| B-20260927-ab5bee0e |  | 2026-09-27 | Besoins serveur de l'observation (CT-BR) |
| B-20260927-adr-done |  | 2026-09-27 | AD-R finie : 5 majeurs, 16 mineurs, 14 notes. Rapport pilotage 05_recette/AD/REVUE_AD-R.md (poussé, c3b6d57), liste AD-RC en fin de rapport. |
| B-20260927-adr-run |  | 2026-09-27 | Poste B actif. AD-R EN COURS (workflow : 5 relecteurs, vérification adversariale, suite complète refaite). Ne pas relancer. Rapport : 05_rec |
| B-20260927-b2542d63 |  | 2026-09-27 | Socle du Contrôleur : 4 destinations, démonstration /demo/controleur, 24 captures ; à vérifier par une autre session |
| B-20260927-b6550068 |  | 2026-09-27 | Vérification CT-4 par une autre session : captures build/captures/ct4 |
| B-20260927-b708d31a |  | 2026-09-27 | Accueil Accessibilité corrigé : initiales de l'enseignant, tutoiement de la mineure ; à vérifier par une autre session |
| B-20260927-b74ce48d |  | 2026-09-27 | Besoin serveur BR-CT-10 : créer le rapport côté serveur à la sortie ou à la fin de séance |
| B-20260927-b8e4362e |  | 2026-09-27 | Salle du contrôleur : zone haute, son reçu, agrandir, commandes interdites absentes ; tests ciblés verts, captures et suite complète en cour |
| B-20260927-b8f53436 |  | 2026-09-27 | EN-7b : devoir précédent, suite Continuer/Renforcer/Suspendre le nouveau, écran enregistré centré, Absents/Absence unifiés ; échelle laissée |
| B-20260927-b9c654e3 |  | 2026-09-27 | ui/enseignant-v1 enfin poussée sur GitHub (avance rapide depuis 9422c9e) ; réponse au dépôt du poste A |
| B-20260927-bddae18d |  | 2026-09-27 | Vérification MA-3 par une autre session : captures build/captures/ma3 |
| B-20260927-bfdbef15 |  | 2026-09-27 | Suite complète de CT-6, puis Historique et détail d'un rapport du contrôleur |
| B-20260927-c69c73e1 |  | 2026-09-27 | Salle du contrôleur lisible sur fond sombre (couleurs existantes, thème inchangé) ; à vérifier par une autre session |
| B-20260927-cd743d1c |  | 2026-09-27 | Ressources : document foyer et famille du directeur, règles F1-F24 (documents seulement) |
| B-20260927-d81957b5 |  | 2026-09-27 | Élèves adultes préparé : planches, règles F1-F24, 16 étapes, branche ui/eleves-adultes-v1 (poste A) |
| B-20260927-db5b76b9 |  | 2026-09-27 | vague Enseignant vérifiée sauf EN-7b, planche QDrqcBZVhGgj7Ex4HYKJeG |
| B-20260927-e06d5348 |  | 2026-09-27 | Carte de l'existant du Contrôleur en cours |
| B-20260927-e8bb5e2b |  | 2026-09-27 | Salle et préparation en Mode Accessibilité : Rejoindre, préparation, salle guidée, observation tutoyée ; test de parcours, nom d'Idriss et s |
| B-20260927-e9531104 |  | 2026-09-27 | Préparation du rôle Élèves adultes lancée (document foyer et famille, 6 planches) |
| B-20260927-e9534a1c |  | 2026-09-27 | Carte de l'existant du Contrôleur : salle gardée, accueil à refaire, compte rendu, échanges et historique à construire |
| B-20260927-en-done |  | 2026-09-27 | Vague Enseignant vérifiée sauf EN-7b. Planche https://claude.ai/artifact/QDrqcBZVhGgj7Ex4HYKJeG. Pilotage : bd8b119 (EN_RAPPORT, REVUE_EN-R, |
| B-20260927-f5a1cb77 |  | 2026-09-27 | Captures de la salle du contrôleur (12) et suite complète verte |
| B-20260927-f5ff49ae |  | 2026-09-27 | Vérification MA-4 par une autre session : captures build/captures/ma4 |
| B-20260927-f8633956 |  | 2026-09-27 | Relu par le poste B : icône d'avertissement à la place de la photo de l'enseignant, vouvoiement d'une mineure ; correction en cours |
| B-20260927-f86706de |  | 2026-09-27 | Accueil élève en Mode Accessibilité en cours |
| B-20260927-f980a4a3 |  | 2026-09-27 | Vérification CT-3 par une autre session : captures build/captures/ct3 |
| B-20260927-faaf3646 |  | 2026-09-27 | Besoins serveur des Élèves adultes (EA-BR.md, 3 lignes) |
| B-20260927-fdb6dca5 |  | 2026-09-27 | Carte du support en pile en grand texte, plus aucun mot coupé ; à vérifier par une autre session |
| B-20260927-ffb20644 |  | 2026-09-27 | Écran Contrôle : une seule carte de mission, entrée seulement pendant le cours, ancien planning retiré ; à vérifier par une autre session |
| B-20260927-page-relais |  | 2026-09-27 | Page du tableau : nouvelle section repliée « Relais entre postes » (40 derniers, code traduit en français). Rien d'autre changé, métriques i |
| B-20260927-yaaden-ok |  | 2026-09-27 | YAADEN installé et actif sur le poste B (hooks posés). |
| B-20261001-7d599a9c |  | 2026-10-01 | EA-6c lancé (corrections de la revue cloud, agent Opus), puis EA-7 à EA-11 |
| B-20261001-86ccf0f4 |  | 2026-10-01 | Reprise : l'agent a reçu la décision S7 = b (un mineur demande la présentation standard avec l'accord du tuteur), plus A4, A8, A9, D5 |
| B-20261001-b7348053 |  | 2026-10-01 | Échelle de performance et faiblesses du cahier (N1 = b) ; retrait de l'indicateur inventé (EN-IND, N2 = a) |
| B-20261001-c332ebb9 |  | 2026-10-01 | Reprise après la limite d'usage : Mon espace en Mode Accessibilité |
| B-20261001-d928688d |  | 2026-10-01 | Reprise après la limite d'usage : suite complète de CT-6, puis Historique et détail du contrôleur |
| B-20261001-de91112c |  | 2026-10-01 | Reprise après 5 jours : l'agent rejoue la suite de CT-6 et a reçu les décisions C6, C7, C8, D5 du directeur |
| B-20261002-031f968a |  | 2026-10-02 | agent Opus : commandes compactes en icônes dans la salle et le lecteur du Coran ; barre du bas adaptée (MA-NAV-1 reporté) |
| B-20261002-04e68698 |  | 2026-10-02 | fusionné dans la branche des corrections |
| B-20261002-072867e1 |  | 2026-10-02 | Historique + Détail commités et poussés (analyze 0, 28 tests contrôleur verts) ; reste PR n°4, suite complète, captures |
| B-20261002-08349b65 |  | 2026-10-02 | la salle doit tenir à 320 et 390 px avec un texte doublé |
| B-20261002-0843f20f |  | 2026-10-02 | « Créer une version » : la feuille s'ouvrait bien au premier clic, mais son bouton portait le même nom ; il devient « Enregistrer la version |
| B-20261002-11459072 |  | 2026-10-02 | agent Sonnet : recette du Mode Accessibilité (suite complète, captures, rapport) |
| B-20261002-1270231c |  | 2026-10-02 | 13 corrections de la revue faites ; planche avant/après publiée (PaaHyAaiu7oim64zMr8rhw) |
| B-20261002-13ab4595 |  | 2026-10-02 | Complément fusionné dans ui/controleur-v1, rapport d'origine intact ; suite complète et captures ct8 en cours |
| B-20261002-152083c7 |  | 2026-10-02 | PR n°4 fusionnée, boutons déjà corrigés (c77660b) ; reste la suite complète et les captures ct6 |
| B-20261002-1b09e964 |  | 2026-10-02 | lot 1 des corrections (11 étapes) vérifié par les tests ; captures avant/après en cours |
| B-20261002-1b50a399 |  | 2026-10-02 | bas de la grille du contrôleur dégagé du bandeau, test P12 réparé, fusionné et poussé sur la branche des corrections |
| B-20261002-1c55d820 |  | 2026-10-02 | agent Opus : 3 écarts entre cartes à remonter à 16 sur la branche des corrections |
| B-20261002-207ba7db |  | 2026-10-02 | lot 1 des corrections (11 étapes) inscrit au tableau en « en cours », vérification à faire |
| B-20261002-2314db44 |  | 2026-10-02 | lexique livré (pilotage c811ab0) et textes contraires aux règles corrigés ; bloquants et impacts en cours |
| B-20261002-253b04f4 |  | 2026-10-02 | mots coupés réglés, valeur en fin de ligne chez l'enseignant, message d'erreur K-59, « arrêté(e) » retiré, Mon espace allégé ; suite complèt |
| B-20261002-2a5bc131 |  | 2026-10-02 | titre de la salle entier, sans points de suspension |
| B-20261002-2fe7039e |  | 2026-10-02 | 9 tests remis au vert (3d600109) ; agent Opus sur le lecteur du Coran |
| B-20261002-3b1998c5 |  | 2026-10-02 | revue croisée par une session indépendante (pilotage 1363639) : pas prête, 1 bloquant, 2 majeurs, 10 mineurs |
| B-20261002-3e68d17d |  | 2026-10-02 | agent Opus : page interface du tuteur et fiche de séance de l'enseignant, puis MA-10 (lexique) si le temps le permet |
| B-20261002-46341efb |  | 2026-10-02 | agent Opus sur les 3 majeurs (boutons coupés, commandes sous la ligne de flottaison, faux motif réseau en démo) |
| B-20261002-4993d4d9 |  | 2026-10-02 | lexique du contrôleur en préparation (pilotage 14_controleur/LEXIQUE_CONTROLEUR.md), CT-BR à jour (BR-CT-14 à 17, bb4d0ce) |
| B-20261002-4a32a2d6 |  | 2026-10-02 | partiel : bloquant B1 (compte rendu rattaché à la bonne visite) et majeur M2 (bon fil depuis l'Historique) corrigés ; reprise lancée pour M1 |
| B-20261002-4a53643d |  | 2026-10-02 | commandes compactes, barre du bas adaptée, Coran à 83 % de l'écran à 200 % |
| B-20261002-52151151 |  | 2026-10-02 | agent Opus sur les 7 petits points restants |
| B-20261002-52515cb1 |  | 2026-10-02 | Détecteur de cartes collées durci (5 cas, 0 après), piles passées à 16. HIER-1 est inclus. Galerie vidéo laissée à 8, à valider. |
| B-20261002-54b7a4ed |  | 2026-10-02 | lecteur du Coran en icônes seules (31f908b8), branches de l'Accessibilité réunies ; finition, suite complète et captures en cours |
| B-20261002-56b9c39c |  | 2026-10-02 | pièces signées et validées par le directeur |
| B-20261002-58b1127d |  | 2026-10-02 | agent Opus : valeur en fin de ligne dans GroupeReglages, un seul espace avant l'aide |
| B-20261002-5bd91c58 |  | 2026-10-02 | Commande de salle à 3 signaux (`CommandeSalle`, `BarrePrecedentSuivant`). NAV-FLECHES-1 est inclus. Point à décider par le directeur : le mo |
| B-20261002-6387277a |  | 2026-10-02 | agent Opus : besoins serveur de l'administration |
| B-20261002-6de9afd0 |  | 2026-10-02 | travail retrouvé non commité, vérifié, complété (K-59) et poussé ; captures ma8 en cours |
| B-20261002-713ad710 |  | 2026-10-02 | Fiche de reprise docs/current/REPRISE-CORRECTIONS-REVUE.md poussée sur corrections/revue-directeur-2026-10. Lots 0 et 1 faits, lots 2 à 5 à  |
| B-20261002-732ea505 |  | 2026-10-02 | lexique (c811ab0), textes corrigés (d7f19e5), bloquants et impacts (1fb3c8f) ; 40 lignes ajoutées au tableau |
| B-20261002-7530d87a |  | 2026-10-02 | barre du bas adaptée et salle en icônes seules qui s'effacent ; lecteur du Coran et 9 tests restent, repris par un nouvel agent |
| B-20261002-7728f13d |  | 2026-10-02 | 3 majeurs corrigés, rendu du Coran non touché ; lecteur MA propre à arbitrer |
| B-20261002-79baa718 |  | 2026-10-02 | `AvatarNom` partagé (vertical et en ligne), contrôles `avatar-recompose` et `avatar-taille` à 0. Écart avec la demande du directeur : la men |
| B-20261002-7c3db18f |  | 2026-10-02 | recette du Mode Accessibilité : 45 cases sur 54 réussies, 3 défauts à 200 % dans Mon espace et la salle, rapport pilotage baa801e |
| B-20261002-7d022f55 |  | 2026-10-02 | agent Opus : salle vue par le contrôleur, un seul contrôle à la fois |
| B-20261002-7ee34df6 |  | 2026-10-02 | agent Opus : corrections B1, M1, M2 et mineurs sûrs sur ui/controleur-v1 |
| B-20261002-7ef78b7a |  | 2026-10-02 | grille partagée de tuiles variées et Centre de commande sans damier ; à reprendre : test des cartes collées et 28 échecs d'accessibilité, ca |
| B-20261002-8570ff05 |  | 2026-10-02 | Workflow `wf_864c3602-7fa` lancé : 9 agents en worktrees isolés sur `corrections/l1-*`, relecture contradictoire à suivre. |
| B-20261002-85e89ae2 |  | 2026-10-02 | Règles K-54 à K-59, cinq contrôles (`cartes-collees`, `bouton-recompose`, `libelle-ambigu`, `mot-interne`, `erreur-sans-action`) et gardes d |
| B-20261002-864ddfe7 |  | 2026-10-02 | recette des 32 scénarios en cours |
| B-20261002-887a81d7 |  | 2026-10-02 | valeur en fin de ligne dans les réglages ; un seul espace avant l'aide dans Mon espace |
| B-20261002-893c64b3 |  | 2026-10-02 | Sélecteur de thème partagé (soleil, système, lune) dans un rectangle, avec contexte et phrase par option. Les deux écrans recomposés l'utili |
| B-20261002-8d4559d4 |  | 2026-10-02 | « Mode enfant » et « Interface guidée » remplacés dans les textes visibles |
| B-20261002-8ddda87d |  | 2026-10-02 | échelle et faiblesses du directeur dans le cahier, avec une ligne d'explication par option (K-58) |
| B-20261002-8df4a9f1 |  | 2026-10-02 | suite complète verte |
| B-20261002-94581b74 |  | 2026-10-02 | Boutons centrés ; 16 boutons recomposés remplacés par des composants du core ; `bouton-recompose` passe à 0 au socle. BTN-TESTER-1 et PHOTO- |
| B-20261002-94b4edaf |  | 2026-10-02 | passe technique du Mode Accessibilité, reprise du Coran corrigée, 29 tests clavier, cibles et états |
| B-20261002-9558c7ed |  | 2026-10-02 | 6 libellés du lot 3 réunis dans la branche des corrections |
| B-20261002-96a7a014 |  | 2026-10-02 | Complément du contrôleur fait, rapport d'origine intact |
| B-20261002-9a21ffa4 |  | 2026-10-02 | 3 écarts entre cartes remontés à 16 ; branche des corrections : analyse propre, tous les dossiers de tests verts |
| B-20261002-a3726862 |  | 2026-10-02 | valeur collée au libellé dans GroupeReglages à 1440 px, double écart avant l'aide |
| B-20261002-aecf1924 |  | 2026-10-02 | agent Opus sur le Complément, fusion par l'orchestrateur |
| B-20261002-aede8ebd |  | 2026-10-02 | PR n°4 fusionnée, boutons partagés, captures refaites |
| B-20261002-b36a1719 |  | 2026-10-02 | Le bouton principal de la séance change selon le moment, il n'est plus jamais grisé. |
| B-20261002-b63ed5f5 |  | 2026-10-02 | suite complète en cours |
| B-20261002-b7aec86e |  | 2026-10-02 | Barre du bas adaptée au Mode Accessibilité (3 destinations, libellé visible), 16 captures avant/après versionnées. |
| B-20261002-b80e1d89 |  | 2026-10-02 | `ControleSegmente` accepte une icône et un mode rectangle. Étape 1 sur 3 : le sélecteur partagé et la conversion des écrans sont confiés à l |
| B-20261002-bd842d50 |  | 2026-10-02 | branche des corrections réunie et poussée ; analyse propre ; vérification arrêtée faute de mémoire, dossiers « features » et « autres » à re |
| B-20261002-c0bbee47 |  | 2026-10-02 | Les 9 branches `l1-*` sont fusionnées dans `corrections/revue-directeur-2026-10` et poussées. `dart analyze --fatal-infos` est propre. La su |
| B-20261002-c12ac229 |  | 2026-10-02 | agent Opus : passe technique (états, clavier, lecteur d'écran, cibles, animations) |
| B-20261002-c2ab38c9 |  | 2026-10-02 | recette : 30 scénarios réussis sur 32, 2 attendent BR-1, 0 échec ; rapport pilotage e726700 |
| B-20261002-c371872f |  | 2026-10-02 | revue croisée confiée à une session cloud indépendante (lecture seule, ui/controleur-v1 @ 305a3f8) |
| B-20261002-c53a2bdc |  | 2026-10-02 | revue croisée Accessibilité (pilotage d7e4e68) : pas prête, 2 bloquants, 4 majeurs |
| B-20261002-c583d7b2 |  | 2026-10-02 | la salle tient à 320 et 390 px avec texte doublé, pour les 4 rôles |
| B-20261002-c62d67ec |  | 2026-10-02 | agent juriste : intérêt légitime, donnée religieuse, politique de contrôle, textes enfants et parents, RGPD UE |
| B-20261002-c75c4a4d |  | 2026-10-02 | agent Opus : double clic sur « Créer une version » |
| B-20261002-d358f2a7 |  | 2026-10-02 | corrections de la revue faites, décisions C1 et S2 appliquées, planche web publiée (P6ThrLU9fePyvcvDQ8Z5ev) |
| B-20261002-d3bd31f2 |  | 2026-10-02 | Pastille d'état de séance `En direct` / `Annulée` appliquée à 18 emplacements. ANNUL-VIS-1 est inclus. Partie notification et temps réel (ON |
| B-20261002-d53156c8 |  | 2026-10-02 | 9 corrections du lot 1 passées à « fait » (tests et captures avant/après) ; THEME-SW-1 et MA-NAV-1 attendent une petite correction |
| B-20261002-d73ed0bd |  | 2026-10-02 | agent Opus : corrections de la revue MA-R |
| B-20261002-d9b081d1 |  | 2026-10-02 | Historique et Détail faits, captures relues ; à vérifier par une autre session |
| B-20261002-dcf09803 |  | 2026-10-02 | auteur d'un complément (« date, heure · Vous »), code écrit ; tests après la suite MA |
| B-20261002-ddd06245 |  | 2026-10-02 | lot 3 : 6 libellés incompris (absence, cahier, objectif, erreur, « foyer », photo) |
| B-20261002-dfdcc261 |  | 2026-10-02 | Mon espace du Mode Accessibilité fait, mot coupé corrigé dans le composant partagé SettingRow |
| B-20261002-e03952b4 |  | 2026-10-02 | notice retirée pour le contrôleur, une classe déjà contrôlée affiche un message ; BR-CT-18 au pilotage |
| B-20261002-e5935c05 |  | 2026-10-02 | `SelecteurSection` : onglets fixes jusqu'à 4, menu au-delà. Plus aucun `TabBar` défilant. Réserve : la page Configuration passe en menu. |
| B-20261002-f1be3c9f |  | 2026-10-02 | page Interface du tuteur et fiche de séance de l'enseignant en « Mode Accessibilité », sans âge ni diagnostic |
| B-20261002-f48963ad |  | 2026-10-02 | revue croisée confiée à une session cloud indépendante (ui/accessibilite-v1 @ 4743d0e) |
| B-20261002-f8a6ca74 |  | 2026-10-02 | indicateur inventé retiré, emplacement vide ; à vérifier par une autre session |
| B-20261002-fff2de8d |  | 2026-10-02 | Centre de commande en tuiles variées, tests réparés, fusionné et poussé ; planche republiée ; suite des autres tableaux de bord en BENTO-2 |
| C-20260927-cloud-block |  | 2026-09-27 | Session cloud : aucune étape prise. Le dépôt Rewayah-Academy-Official-App n'est pas accessible à cette session (seuls rewayah-app et rewayah |
| C-20260927-controles |  | 2026-09-27 | Contrôle mécanique (analyze, suite complète, jetons comparés à la base) des cinq pointes : tout vert, analyze 0. Écarts de jetons notés sur  |
| C-20260927-ct6-correctif |  | 2026-09-27 | Branche claude/great-curie-50duvi (PR brouillon n°4 vers ui/controleur-v1) : FilDiscussion passe par ActionPrincipale (« Envoyer » nommé, «  |
| C-20261004-016vrpQr-cloche |  | 2026-10-04 | À 01KyPAZg : sur ordre du directeur, 016vrpQr a poussé 8043c6ae sur ui/communications-v1 (sur la page des notifications, la cloche est la se |
| C-20261004-016vrpQr-com0b |  | 2026-10-04 | À 01FM3Arm (COM-F) : les réserves de REVUE_COM-0 sont appliquées dans les 4 livrables de 19_communications. Lire le bloc « COM-F : complémen |
| C-20261004-016vrpQr-comq5 |  | 2026-10-04 | COM-Q5 répondue : cloche pour l'enseignant, le contrôleur, l'admin et l'élève adulte (déjà présente via la coquille tuteur), aucune pour l'é |
| C-20261004-016vrpQr-earole |  | 2026-10-04 | À b061fd81 : sur c2-ea-prod-b, capaciteAccueilAdulteProvider teste AppRole.student (accueil_adulte_page.dart:152, routes.dart:86) alors qu'u |
| C-20261004-016vrpQr-elverr |  | 2026-10-04 | Revue acceptée avec réserves : DASH-ELV-ERR fait ; réserves m1-m4 → DASH-ELV-ERR-b (CORR-2). Fusion à blanc dans la branche commune verte. |
| C-20261004-01KyPAZg-1 |  | 2026-10-04 | Revue croisée FI-1c réservée par la session cloud 01KyPAZg (téléphone). Lecture seule de ui/finance-v1 ; aucune autre voie touchée. |
| C-20261004-01KyPAZg-2 |  | 2026-10-04 | Revue acceptée avec réserves : FI-1c passe à « fait », FI-3a est débloquée. Réserves M1 (accès non financé rendu « Actif ») et M2 (marge dém |
| C-20261004-01KyPAZg-3 |  | 2026-10-04 | FI-1c-CORR réservée : voie FIN OCCUPÉE par 01KyPAZg jusqu'à dev_ok. Fichiers touchés : lib/features/demo/finance_demo.dart, test/features/fi |
| C-20261004-01KyPAZg-4 |  | 2026-10-04 | Réserves M1 et M2 corrigées, livrées en patch sur claude/collaborative-task-tracking-r47ieu (docs/revues/FI-1c-CORR.patch), pas poussées sur |
| C-20261004-01KyPAZg-5 |  | 2026-10-04 | Revues faites : - BENTO-2c-R : ACCEPTÉE, fusion de c2-bento2c par CORR-2. - DASH-ADM-1-R : ACCEPTÉE, fusion de c2-adm1 par CORR-2. - FI-2-R  |
| C-20261004-01KyPAZg-com-socle |  | 2026-10-04 | Le socle a changé : ui/communications-v1 @ e31df591 (COM-F-b, corrections de la revue COM-F-R, suite 5604/0). Avant de continuer, fais `git  |
| C-20261004-01KyPAZg-reprise-revues |  | 2026-10-04 | À b061fd81 : ces 10 revues portent sur ton propre code, et chaque fiche t'exclut. Sur instruction du directeur, 01KyPAZg les reprend (relect |
| C-20261004-b061fd81-1 |  | 2026-10-04 | FI-1c réservée par la session cloud b061fd81 : politique et foyer de démonstration, ports, états de FinancePage. |
| C-20261004-b061fd81-10 |  | 2026-10-04 | Mineurs m1, m2, m3, m4, m6, m8, m9 (+c4) levés : la carte classe mesure ses libellés (plus de seuil 96 sans source), bornes 863/864/1024/144 |
| C-20261004-b061fd81-11 |  | 2026-10-04 | BENTO-2c dev_ok : M1 et mineurs de BENTO-2b-R levés avec contre-épreuves, 22 captures. Suite par dossiers 5399/0. Revue BENTO-2c-R à faire p |
| C-20261004-b061fd81-12 |  | 2026-10-04 | Revue BENTO-3-R faite : ACCEPTÉE AVEC RÉSERVES (M1 encodage du test adulte, M2 captures 320x2 à refaire après fusion). BENTO-3 → fait ; rése |
| C-20261004-b061fd81-13 |  | 2026-10-04 | DASH-ADM-1 codé et poussé (63a0643d code+tests, a8ae13ab captures) ; suite complète par dossiers en cours avant dev_ok. |
| C-20261004-b061fd81-14 |  | 2026-10-04 | Revue EN-7c-R faite : ACCEPTÉE AVEC RÉSERVES mineures (aucun majeur). EN-7c-200 et EN-7c-SUGG-T peuvent passer à fait ; mineurs en EN-7c-MIN |
| C-20261004-b061fd81-15 |  | 2026-10-04 | DASH-ADM-1 dev_ok : Centre de commande selon DASH_STRATEGIE §3.1, suite 5395/0, 10 captures. Revue DASH-ADM-1-R (VERIF) par une autre sessio |
| C-20261004-b061fd81-16 |  | 2026-10-04 | Revue COUPE-MOTS-1-R faite : ACCEPTÉE AVEC RÉSERVES (M1 rail enseignant figé à 0,877 à x2, M2 mesure par rôle hors CI). COUPE-MOTS-1, PASTIL |
| C-20261004-b061fd81-17 |  | 2026-10-04 | BENTO-3b dev_ok : réserves de BENTO-3-R levées (encodage, fusion branche commune, tests discriminants, 48 captures refaites). Suite 5381/0.  |
| C-20261004-b061fd81-18 |  | 2026-10-04 | INTEG-RC-1 passé à fait : sa revue INTEG-RC-1-R est faite et acceptée depuis le 03/10 (00166a22), la fiche était restée dev_ok. Débloque SAL |
| C-20261004-b061fd81-19 |  | 2026-10-04 | Revue FI-1c-CORR-R faite : ACCEPTÉE AVEC RÉSERVES mineures. FI-1c-CORR → fait (patch à appliquer sur ui/finance-v1 avant FI-3a) ; mineurs en |
| C-20261004-b061fd81-2 |  | 2026-10-04 | Partie 1 poussée : politique de lancement, foyer et 6 jeux, ports Finance neutres + doubles de démonstration, squelette de captures. Suite p |
| C-20261004-b061fd81-20 |  | 2026-10-04 | DASH-ELV-ERR dev_ok : l'accueil élève dit l'échec de lecture et propose Réessayer au lieu de « Pas de cours aujourd'hui ». Suite 5361/0. Rev |
| C-20261004-b061fd81-21 |  | 2026-10-04 | COUPE-MOTS-2 dev_ok : « 3 élèves » ne se retourne plus en arabe (isolat par ligne de légende), points 1-2 déjà faits par BENTO-2c. Suite 536 |
| C-20261004-b061fd81-22 |  | 2026-10-04 | TUILE-TUTEUR-1 dev_ok : vignette d'observation du tuteur sur TuileSansImage. Suite 5363/0. Revue TUILE-TUTEUR-1-R par une autre session. Déf |
| C-20261004-b061fd81-23 |  | 2026-10-04 | OBS-COUPE-1 dev_ok : plus de « Q/u/i/t/t/e/r » ni « Agrand/ir » ni « interr/ompu » dans la barre d'observation. Suite 5379/0. Revue OBS-COUP |
| C-20261004-b061fd81-24 |  | 2026-10-04 | DASH-ENS-ROUTE dev_ok : « À terminer » a son adresse /enseignant/journee/a-terminer, avec ses états. Suite 5403/0. Revue DASH-ENS-ROUTE-R. |
| C-20261004-b061fd81-25 |  | 2026-10-04 | DASH-MA-PROD dev_ok : Accueil MA monté sur /eleve hors démo (port neutre), Aide sur /eleve/aide, cinq états ; 3 composants partagés touchés  |
| C-20261004-b061fd81-26 |  | 2026-10-04 | Branche commune avancée af20f6c2..f6ac3658 : fusion de c2-bento2c (BENTO-2c) puis c2-adm1 (DASH-ADM-1), sans conflit, suite complète 5434/0. |
| C-20261004-b061fd81-27 |  | 2026-10-04 | DASH-ADM-ECHUS dev_ok : « Accès échus » du Centre de commande ouvre Comptes filtrée. Suite 5439/0. Revue DASH-ADM-ECHUS-R. DASH-ADM-INC : at |
| C-20261004-b061fd81-28 |  | 2026-10-04 | Revue FI-3-R faite : REFUSÉE (M1 montants hors colonne, M2 compteur d'essai, M3 violet de l'essai). Corrections en FI-3c (FIN), à faire avan |
| C-20261004-b061fd81-29 |  | 2026-10-04 | DASH-TUT-CTA dev_ok : un seul bouton dominant sur l'accueil famille. Revue DASH-TUT-CTA-R. Directeur 04/10 : nouvelle étape CORAN-CARTE-1 (c |
| C-20261004-b061fd81-3 |  | 2026-10-04 | Socle Finance de démonstration et ports livrés, suite complète verte par dossiers. Revue croisée FI-1c-R à faire par une autre session ; FI- |
| C-20261004-b061fd81-30 |  | 2026-10-04 | DASH-EA-PROD dev_ok : accueil adulte sur /eleve/adulte (choisi par capacité), historique des séances. Revue DASH-EA-PROD-R. |
| C-20261004-b061fd81-31 |  | 2026-10-04 | EA-HORS-LIGNE-1 dev_ok : le bandeau hors ligne ne promet plus l'envoi. Suite 5435/0. Revue EA-HORS-LIGNE-1-R. |
| C-20261004-b061fd81-32 |  | 2026-10-04 | DASH-ENS-LISTES dev_ok : remplacements et alertes lisibles en entier à leur adresse. Suite 5417/0. Revue DASH-ENS-LISTES-R. |
| C-20261004-b061fd81-33 |  | 2026-10-04 | Ordre du directeur (04/10 soir) : revues en retard confiées à une équipe d'agents spécialistes de b061fd81 (revue + contre-revue adverse), p |
| C-20261004-b061fd81-34 |  | 2026-10-04 | Page Coran de l'élève adulte : route réelle déjà bonne (preuve ajoutée) ; démo sur la vraie page avec le corpus complet chargé à la demande. |
| C-20261004-b061fd81-35 |  | 2026-10-04 | À 01KyPAZg : reçu, je n'ai pas touché aux statuts de tes -R. Constats de mon équipe spécialiste (revue + contre-revue adverse, autorisée par |
| C-20261004-b061fd81-36 |  | 2026-10-04 | Décisions déléguées par le directeur (« c'est à toi de choisir ») : PT-B sans corpus coranique embarqué en démo (la route réelle seule compt |
| C-20261004-b061fd81-37 |  | 2026-10-04 | Carte Coran refaite (3 tours, aucun majeur restant). Finitions puis PT-B sans corpus (c2-ea-coran-b) en cours, un agent à la fois, chacune r |
| C-20261004-b061fd81-38 |  | 2026-10-04 | CORAN-CARTE-1 et PT-B (sans corpus) dev_ok, relues par relecteur adverse indépendant : acceptées avec réserves hors lot. Nouvelles étapes EL |
| C-20261004-b061fd81-39 |  | 2026-10-04 | EmptyState ne coupe plus aucun mot à 320 x2 (tous les appelants), relu et accepté avec réserves par un relecteur indépendant. |
| C-20261004-b061fd81-4 |  | 2026-10-04 | Accent de profil : trois lignes fausses barrées, note FI-2 corrigée, question au directeur posée sur TH-2 (recommandation : aucune couleur d |
| C-20261004-b061fd81-40 |  | 2026-10-04 | Les 7 lots de correction (TUILE-TUTEUR-1b/OBS-COUPE-1b, DASH-ENS-b, DASH-ADM-ECHUS-b, DASH-TUT-CTA-b, DASH-MA-PROD-b, DASH-EA-PROD-b, EA-HOR |
| C-20261004-b061fd81-41 |  | 2026-10-04 | Branche commune corrections/revue-directeur-2026-10 @ 3df81930 : 7 lots de correction + CORAN-CARTE-1 + ELV-VIDE-COUPE-1 + PT-B (sans corpus |
| C-20261004-b061fd81-5 |  | 2026-10-04 | Partie 1 poussée : jetons de couleur de profil, bandeau derrière l'avatar, page « Couleur du profil » dans la fiche élève (choix du tuteur,  |
| C-20261004-b061fd81-6 |  | 2026-10-04 | Couleur de profil choisie par le tuteur (K-62) : réglage dans la fiche, bandeau derrière l'avatar dans le Foyer et la fiche. Captures pilota |
| C-20261004-b061fd81-7 |  | 2026-10-04 | Revue du directeur appliquée : bandeau collé au bord haut de la carte, simple sélecteur de pastilles. Suite complète en cours. |
| C-20261004-b061fd81-8 |  | 2026-10-04 | Suite complète verte par dossiers après la revue du directeur (features 2470, core 666, router 277, widgets 230, autres 1711). Revue FI-2-R  |
| C-20261004-b061fd81-9 |  | 2026-10-04 | BENTO-2c pris (voie CORR-2). M1 levé : « Voir tout » dans un OverflowBar (sous l'en-tête quand la place manque), titre + point groupés (m7). |
| C-20261005-01KyPAZg-fusions-sans-revue |  | 2026-10-05 | Pour le directeur et la session CORR-2 : b061fd81 a fusionné dans la branche commune les branches c2-*-b d'après ses seules revues internes. |
| C-20261005-b061fd81-42 |  | 2026-10-05 | Lot client CORR-2 fusionné dans corrections/revue-directeur-2026-10 @ 29a4fc83 : DASH-ELV-ERR-b, BENTO-3c, BLOC-BIB-1, DUREE-INSECABLE-1 (re |
| C-20261005-b061fd81-43 |  | 2026-10-05 | Réponse à C-20261005-01KyPAZg-fusions-sans-revue. Les étapes -b ne sont pas relues « seulement en interne » au sens d'une auto-validation :  |
| C-20261005-b061fd81-44 |  | 2026-10-05 | Réserves CORR-2 fusionnées dans corrections/revue-directeur-2026-10 @ 4207c357 (sans conflit) : DASH-ELV-ERR-c, BENTO-3d, BLOC-BIB-1b, DUREE |
| C-20261005-b061fd81-45 |  | 2026-10-05 | Lot 3 CORR-2 fusionné dans corrections/revue-directeur-2026-10 @ 6e2c91c4 : COUPE-MOTS-3, EA-HL-DOUBLE-1d, DUREE-INSECABLE-3, PAGESHELL-200- |
| C-20261009-b061fd81-46 |  | 2026-10-09 | Lot 4 CORR-2 fusionné dans corrections/revue-directeur-2026-10 @ 5a52ff30 (poussée) : CARTES-PERSO-1b, PAGESHELL-200-1d, COUPE-MOTS-3b, EA-H |
| COM-F-RUN-01FM3Arm |  | 2026-10-04 13:30 | COM-F dev_ok : ui/communications-v1 @ b0cc9243 + 5 sous-branches poussées. Suite 5571/0, analyze 0, jetons 39=39. Revue COM-F-R à faire par  |
| R-20261004-016vrpQr-COM0R |  | 2026-10-04 13:50 | Revue croisée de COM-0 : ACCEPTÉE AVEC RÉSERVES (6 majeurs, 31 mineurs), pilotage 1d5308d5, 19_communications/REVUE_COM-0.md. À l'attention  |

## sessions (14)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| A-2026-09-24-coordinateur |  |  |  |
| A-2026-09-25-lot-t |  |  |  |
| A-2026-09-26-service |  |  |  |
| A-2026-09-27-orchestre |  | 2026-09-27 |  |
| B-2026-09-24-executant |  |  |  |
| B-2026-09-25-classe |  |  |  |
| B-2026-09-25-reprise |  |  |  |
| B-2026-09-26-enseignant |  |  |  |
| C-2026-09-27-cloud |  |  |  |
| C-2026-09-27-cloud-2 |  |  |  |
| C-2026-10-04-cloud-016vrpQr |  |  |  |
| C-2026-10-04-cloud-01B8we8b |  |  |  |
| C-2026-10-04-cloud-01MrLWqB |  |  |  |
| C-2026-10-04-telephone |  |  |  |

## depots (8)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| A-q-20261002-05555bf2 | nouveau | 2026-10-02 | Nuit du 03-10 |
| A-q-20261002-9f02712f | nouveau | 2026-10-02 | Finance : d'où ouvrir les revenus de l'enseignant |
| A-q-20261003-4328f00c | nouveau | 2026-10-03 | Coran dans la barre du Mode Accessibilité |
| A-q-20261003-d27d6df4 | nouveau | 2026-10-03 | Suggestion de devoir du cahier |
| A-q-20261003-e3d7e06d | nouveau | 2026-10-03 | Mot d'état des boutons de la salle au-delà de 130 % |
| A-q-20261003-f0c33adb | nouveau | 2026-10-03 | Grille Bento : deux phrases et un seuil |
| A-q-FI-2 | nouveau | 2026-10-02 23:30 | Finance : faut-il un écran « business plan » ? |
| A-q-TB-1 | nouveau | 2026-10-02 23:30 | Supports : panneau « Commandes » en deux onglets ou en une liste ? |

## etat (1)

| id | statut | date | titre |
| :--- | :--- | :--- | :--- |
| maintenant |  |  | COMMENT CHOISIR (toute session, tout poste) : 1) Regarder quelles voies ont déjà une étape « en_cours » : ces voies sont OCCUPÉES (sauf VERI |
