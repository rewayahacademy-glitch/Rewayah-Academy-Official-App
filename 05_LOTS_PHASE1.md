# 05 - Mandats des lots de la phase 1 (chantier frontend Tuteur V1)

Date : 24/09/2026. Un lot = un parcours complet, livré sur SA branche, par UN agent exécutant à la fois (sous-paquets en séquence).
Répartition : **Poste A** (ce poste, coordinateur) : lots **C** (Cours), **E** (Compte / Historique), **O** (Observation). **Poste B** (second ordinateur) : lots **A** (Admission), **B** (Foyer), **D** (Appareils).

## 0. Règles communes (s'imposent à chaque lot)

**À lire avant tout** (chemins relatifs à la racine du dossier de pilotage `PILOTAGE`, et du dépôt `DEPOT`) :
1. `PILOTAGE/BRIEF.md`, `PILOTAGE/03_DECISIONS_COORDINATEUR.md` (le §1 bis, 1 ter, 1 ter bis PRIMENT : réponses du directeur).
2. `DEPOT/CLAUDE.md`, `DEPOT/lib/CLAUDE.md`, le mandat `LANCEMENT/REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (les deux parties).
3. `PILOTAGE/01_visuel/00_MANIFESTE.md` et les rapports `01_visuel/V*.md` de tes écrans ; les maquettes elles-mêmes dans `LANCEMENT/tutuor image/` (ouvre-les réellement).
4. `PILOTAGE/02_code/00_MAPPING_ROUTES.md` (tes lignes), `00_CONTRATS_PARTAGES.md`, `00_OWNERSHIP.md` (tes fichiers), `00_DEPENDANCES_BACKEND.md`, le rapport `02_code/C0x` de ton domaine.
5. `PILOTAGE/04_phase0/0c1_composants.md`, `0c2_coquille_routeur.md`, `0d_contrats.md`, `0b_jetons.md` : ce qui existe déjà (composants partagés, contrats K1-K7, STUBS à remplacer, outil de capture `test/capture/`).

**Git** : worktree dédié, branche `ui/tuteur-v1-<lot>` créée depuis `ui/tuteur-v1` (la plus récente disponible). Commits locaux fréquents, en français, style du dépôt. **Jamais** : push vers `main`, merge dans `main`, PR, `workflow_dispatch`, migration, modification de `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, `assets/fonts`, `lib/core/theme/**`, `lib/core/router/**`, `lib/core/widgets/**` (composants partagés), `lib/core/capacites/port_*.dart` et contrats K1-K7 (fichiers du coordinateur). Besoin d'un changement dans un fichier du coordinateur : l'écrire dans `PILOTAGE/demandes/<lot>.md` (fichier, besoin, signature voulue) et continuer autrement.

**Fichiers** : uniquement ceux de ton lot dans `00_OWNERSHIP.md` §3 (existants possédés, à créer, tests). Les STUBS « // STUB PHASE 0 : propriété du lot X » de ton lot sont à REMPLACER ; aucun ne doit subsister à la fin du lot.

**i18n** : seulement tes espaces de noms (`00_OWNERSHIP.md` §4), dans `assets/i18n/fr.i18n.json` ; puis `dart run slang` et commit du généré. Jamais une clé d'un autre lot.

**Règles du directeur (non négociables)** :
- **Layout = maquettes high-fi** (ordre des sections, colonnes, regroupements, place exacte de chaque fonction et bouton). Couleurs = jetons gelés (aucun changement de jeton).
- **Une fonction = un seul endroit, aucun doublon.** Livre une **carte des fonctions** du lot : fonction | écran unique | route | place dans la maquette.
- **Carte groupée = UN rectangle**, éléments séparés par de fines lignes (composant partagé `groupe_reglages` / équivalent de phase 0) ; jamais un rectangle par ligne.
- **Navigation, retour, déconnexion** toujours accessibles ; aucune impasse ; retour visible sur chaque écran de niveau 2 et chaque tâche focalisée.
- **Web = vraie version desktop** : compositions en colonnes dès 1200, rail dès 600 ; aucune feuille mobile étirée.
- **Vocabulaire** : « Classe » (jamais « groupe » à l'écran), « Séance », Sayyid / Sayyida, Interface guidée, « Ajouter un profil élève » ; interdits : « Session », « Cours en cours », « Ajouter enfant », « mode enfant », codes internes.
- **Honnêteté** : capacité sans service = état `indisponible` compréhensible (K5), jamais un faux succès ni une fixture en production. Chaque écran a ses états chargement, contenu, vide, erreur, hors ligne.
- **Tri** : tout `.order(...)` écrit ou consommé précise `ascending`.
- **Coran** : ne jamais modifier `lib/core/coran`, `lib/core/tc_coran`, `lib/features/tc_mushaf`. Défaut hors périmètre découvert = une ligne dans `PILOTAGE/08_BACKLOG_VAGUE_CLASSE_VISIO.md`, jamais corrigé en passant.

**Définition de « fait »** (registre §5 bis) : fichier atteignable depuis `lib/main.dart` ; un bouton, un onglet ou un lien y mène ; **un test de widget touche ce bouton** depuis la navigation (un `routeur.go` seul ne prouve rien) ; captures produites.

**Preuves à produire par lot** (dans `PILOTAGE/05_recette/<lot>/`) :
- captures via `test/capture/` (lire `test/capture/LISEZ-MOI.md`) : chaque écran à 390x844 et 1440x900, clair ET sombre ; pour chaque écran qui a une maquette, planche maquette | rendu à la même taille, écarts corrigés avant de déclarer conforme ;
- `RAPPORT.md` : écrans livrés, carte des fonctions, statut de chaque écran (UI réalisée / branchée au service existant / testée en simulation / dépendance backend DB-xxx), tests lancés et résultats exacts, demandes au coordinateur, défauts hors périmètre consignés.

**Machine** : commandes Flutter lourdes via `PILOTAGE/outils/flutter-verrou.ps1` (un seul `dart analyze` / `flutter test` à la fois) ; préférer analyse et tests ciblés. Le coordinateur fait l'analyse complète et la suite complète à l'intégration.

**Fin de lot** : analyse ciblée sans erreur, `dart run tool/verifier_jetons.dart` propre, tests du lot verts, aucun STUB du lot restant, frontière `git diff --stat <base>...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` vide, rapport écrit. Puis livraison de la branche au coordinateur (voir `COORDINATION.md`).

## A - Admission (poste B)

Références : maquettes `onboarding Mble.png`, `onboarding Mble d.png`, `onboarding mobile 1.png`, `Onboarding mobile 2.png`, `mobile/tuteur observation mobile light.png` (écran M6 consentement) ; manifeste §1 lignes 10-17, 23 et §6 ; `02_code/C03_admission.md` ; mapping lignes 1-7, C1, C2, C3, C7, C11.
Sous-paquets en séquence :
1. **Bienvenue, connexion, récupération** (`/bienvenue`, `/connexion`, `/connexion/recuperation`) : renvoyer le lien, lien expiré ou déjà utilisé, accès appareil élève discret, état envoi / attente / erreur.
2. **Inscription par étapes** (`/inscription/usage|identite|genre|recapitulatif`) : choix d'usage à DEUX cartes (« Moi uniquement » : « Je souhaite suivre les cours avec mon propre profil élève. » ; « Moi et ma famille » : « Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment. »), sans carte « Autre », lien discret « Je suis enseignant » ; en-tête d'étape (retour 48 dp, « n sur N » calculé) ; CTA en pilule ; aucune présélection ; erreurs sous les champs ; double soumission bloquée ; déconnexion possible ; impasse après refreshSession corrigée ; récapitulatif avec « Modifier » par ligne.
3. **Dossier `/attente`** (accusé, contrat, pièce) refondu : fini les cartes empilées et les trois CTA pleins ; statut exact et UNE prochaine action ; **nouvelle version du texte signé** = texte existant (notice d'enregistrement audio CONSERVÉE) + paragraphe d'observation clair et bienveillant (décisions §1 bis-3), variantes responsable légal / élève adulte, case non précochée, enregistrement par le mécanisme existant ; **invite pour comptes existants** `/tuteur/compte/consentements` (lecture des acceptations, aucune acceptation présumée) ; texte « Comment ça marche ? » de l'observation en clés `consentement.*` paramétrées par la politique effective (2 visites par parent et par séance, visite écourtée consommée).
4. **Questionnaire par élève** `/tuteur/parcours/:eleveId` : branches utiles seulement (débutant / non-débutant selon les règles rendues par le serveur, aucun code interne), prénom de l'élève en contexte, retour sans perte, reprise ; en production le backend `0043` n'est pas appliqué : état indisponible honnête ; appeler `renoncer_intention_horaire` avant un nouveau choix ; enchaînement fin d'admission -> `/tuteur/foyer/ajouter` (route, aucun import du lot B).

## B - Foyer et fiche élève (poste B)

Références : anciennes captures `mobile/Foyer Member.png`, `mobile/Profil.png` (CONTENU seulement) ; rendu dérivé des high-fi Compte (`mon compte tuteur ...`) ; manifeste §2 ; `02_code/C04_foyer_fiche.md` ; mapping lignes 10-17 ; contrat K3.
1. **Foyer** `/tuteur/foyer` : titre, action « Ajouter un profil élève », liste des membres en carte groupée (avatar ou initiale, prénom, classe ou inscription en cours, statut d'accès textuel, chevron), section Appareils partagés (ligne vers `/tuteur/foyer/appareils`, écran du lot D), option discrète « Créer mon profil élève » (écran `creer_mon_profil_indisponible.dart`, DB-FOY-01) ; pas de compteurs décoratifs ; vide honnête.
2. **Ajout de profil** `/tuteur/foyer/ajouter` (+ `?pour=moi`) : widget `formulaire_profil_eleve.dart` sur le contrat K3 (Pour un enfant ou mineur / proche adulte et moi-même visibles mais indisponibles et expliqués), erreurs sous champs, `CreationIncertaine` gérée, enchaînement vers la fiche.
3. **Fiche élève** `/tuteur/foyer/:eleveId` et sous-pages `informations` (photo : sélection, aperçu, envoi, progression, reprise ; jamais mélangée à la pièce d'identité), `inscription` (synthèse, liens vers questionnaire et choix de classe), `interface` (« Interface guidée », politique réelle, aucune bascule qui élève les droits), `camera` (caméra en cours, distincte de la permission du scanner), `acces` (statut, date, « expiré » affiché si dépassé, sans inventer de motif) ; ligne « Appareils » vers `/tuteur/foyer/:eleveId/appareils` (écran du lot D, aucun import) ; « introuvable » pour un id inconnu ; onglet actif Foyer. Place réservée pour un futur **solde par enfant** (rien construit).

## D - Appareils (poste B)

Références : `02_code/C05_appareils.md` (protocole exact : le téléphone du tuteur AFFICHE le QR, l'appareil élève sans session le LIT) ; manifeste §2 lignes appareils ; mandat §7 ; mapping lignes 18-24.
1. **Émetteur QR** `/tuteur/foyer/appairer/:eleveId` : grand QR noir sur fond blanc dans LES DEUX thèmes, code manuel lisible, consigne « Sur l'autre appareil », durée de validité réelle, états préparation / actif / validation / confirmé / expiré / remplacé / erreur / réseau ; dès confirmation, QR ET code retirés de l'écran et de l'arbre sémantique puis « Appareil connecté » ; pas de nouveau code à chaque rechargement si un code actif existe (sinon consigner la dépendance) ; mouvement réduit respecté.
2. **Scanner et saisie** `/connexion/eleve/scanner`, `/connexion/eleve/code` : caméra réelle via `mobile_scanner` (port `LecteurQr` + adaptateur du lot), permission demandée à l'ouverture, états refus / refus durable / occupée / absente / non supportée / erreur, saisie manuelle toujours accessible, format validé `^[2-9A-HJ-NP-Z]{6}$`, jamais une URL ouverte, lectures suspendues après détection, caméra libérée à la sortie et en arrière-plan ; desktop : panneau centré. Refus serveur différenciés (inconnu, expiré, déjà utilisé, révoqué), aucune donnée d'un autre foyer.
3. **Appareil partagé et appareils** : `/connexion/eleve` choix du profil puis PIN (ajout d'un 2e élève sur un appareil partagé), erreurs du pavé visibles ; `/tuteur/foyer/appareils` et `/tuteur/foyer/:eleveId/appareils` : liste, retrait avec confirmation et réponse du service (dire que la session ouverte n'est pas fermée : DB-APP-03) ; aucune limite codée en dur. Le code personnel ne quitte jamais l'appareil (`test/appairage/code_local_test.dart`).

## C - Cours (poste A)

Références : `mobile/accueil  tuteur mobile light mode.png`, `acceuil tuteur desktop light.png`, `acceuil tuteur desktop dark.png`, `mobile/tuteur observation mobile light.png` (M1 classe) ; ancienne capture `mobile/Classe Details.png` (contenu) ; manifeste §1 lignes 1-4, 18 ; `02_code/C06_cours_classes.md` ; mapping lignes 8, 25-30 ; contrats K1, K2, K4, K6.
1. **Accueil** `/tuteur` : sélecteur de profils (K1), carte classe (nom de classe, parcours lisible, photo et nom de l'enseignant avec Sayyid/Sayyida), bloc séance (jour, date, heure locale + fuseau, durée, « Cours dans 3 h 28 », salle ouverte selon la fenêtre serveur, « Séance toujours en direct » sans compteur négatif, `horaireIncertain` sans horloge serveur), CTA « Voir la classe », UN blocage prioritaire confirmé par les données, « Avant le prochain cours » (3 actions max), « Dernière séance » (présence, lien Historique ; réseau seulement si mesuré), vide = inscription ou ajout de profil ; desktop à deux colonnes comme la maquette.
2. **Classe** `/tuteur/classes/:classeId` + `planning`, `travail`, `ressources`, `progression`, lien Historique filtré : enseignant, prochaine séance, bloc Observation construit depuis `DisponibiliteObservation` (K4) qui navigue vers l'écran du lot O ; aucune entrée « Rejoindre » pour le tuteur ; planning récurrent sans décalage UTC fixe ; ressources via la bibliothèque existante.
3. **Catalogue** `/tuteur/classes/catalogue` : vraies classes (enseignant, toutes les séances, fuseau, places) ; production : indisponible honnête ; parcours complet démontrable en simulation.

## E - Compte et suivi (poste A)

Références : `mon compte tuteur desktop light mode.png`, `mobile/mon compte tuteur mobile light mode.png`, `mobile/mon compte tuteur desktop dark mode.png` (= mobile sombre), `réglages tutor mobile dark mode.png`, `tuteur observation desktop light.png` (D2 historique observations, D3 admin, D4 détail) ; ancienne capture `mobile/Historique.png` ; `02_code/C08_compte_historique.md` ; mapping lignes 9, 32-41, C2, C4.
1. **Mon compte** `/tuteur/compte` et sous-pages `informations`, `securite`, `acces`, `paiements`, `preferences` (+ `apparence` : Système / Clair / Sombre relié au thème), `aide`, `informations-legales`, ligne Foyer, « Créer mon profil élève » (route du lot B), déconnexion séparée avec confirmation ; ordre et composition des maquettes ; paiements et moyens de paiement indisponibles proprement ; place réservée au futur solde par enfant.
2. **Historique** `/tuteur/suivi` (alias `/tuteur/historique`) : sélecteur d'élève, segment Séances / Observations, filtres classe / période / statut, lignes séparées ; détail de séance `/tuteur/seances/:seanceId` ; détail des observations `/tuteur/seances/:seanceId/observations?eleve=` (adaptateur `historique_observations_supabase.dart` sur `guardian_session_visit` sous RLS) ; fuseau explicite ; « En cours de vérification » pour une présence incertaine.
3. **Notifications** `/tuteur/notifications` (indisponible honnête, cloche sans pastille) et **consultation admin des observations** (écran du lot, route demandée au coordinateur).

## O - Observation (poste A)

Références : `mobile/tuteur observation mobile light.png` (M2-M5), `tuteur observation desktop light.png` (D1), `tutor observation map.png` (enchaînements) ; décisions §1 bis-4, 5, 6 ; `02_code/C07_observation.md` ; mapping ligne 31, C3 ; contrat K4.
1. **Entrée** : explication de première utilisation (« Comment ça marche ? », 2 visites de 2 minutes par parent et par séance, visite écourtée consommée, micro et caméra désactivés), vérification préalable ; le compteur ne démarre qu'après l'entrée confirmée.
2. **Salle d'observation** : visio épurée, très peu de commandes (son reçu, agrandir le support, quitter) ; **bandeau pleine largeur en haut** : décompte du temps restant seconde par seconde et « 1/2 visite restante pour cette séance » (pluriel ; « Aucune visite restante pour cette séance » à 0) ; support dominant, vignettes secondaires ; aucun micro, caméra, chat, réaction ; reconnexion sans faux direct ni remise à zéro ; mobile, paysage, tablette, desktop.
3. **Fins et états** : sortie volontaire, durée atteinte, fin de séance, visites épuisées, enfant absent, présence en vérification, séance non commencée ou terminée, désactivée, connexion prolongée, échec, reconnexion, caméra désactivée, aucun support ; retour à la classe avec le contexte de l'enfant. En production, `OBSERVATION_TUTEUR_REELLE` reste faux : parcours complet en simulation. Notices côté enseignant et élève : HORS périmètre.
