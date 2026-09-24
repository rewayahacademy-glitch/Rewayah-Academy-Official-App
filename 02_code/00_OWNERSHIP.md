# 00 - Ownership fichier par fichier

Date : 24/09/2026. Proposition pour le coordinateur, fondée sur `C01` à `C11`, `00_MAPPING_ROUTES.md` et `00_CONTRATS_PARTAGES.md`. Inventaire des fichiers relu dans le dépôt (lecture seule : `lib/features/*`, `lib/core/*`, `test/**`).

Règle : **un fichier = un propriétaire**. Un lot qui a besoin d'un changement dans un fichier qu'il ne possède pas dépose une demande courte (fichier, besoin, signature voulue) au coordinateur ; il ne modifie pas le fichier pour se débloquer. Un composant utilisé par un seul lot vit dans le dossier de ce lot ; dès qu'un second lot en a besoin, COORD le promeut dans `lib/core/widgets/`.

---

## 0. Base, branches, machine

- Base : `c0/configuration-baseline-2026-09-23` @ `3cf3544` (revérifier le hash au moment de créer), **nouveau worktree** d'intégration `ui/tuteur-v1` (proposition `C10` : `D:\RA_TUTEUR`). Le checkout principal `D:\RA _APP\RA -OFFICIAL-APP` reste sur C0, rien n'y est commité.
- Lots : une branche par lot issue de `ui/tuteur-v1` après la phase 0 (`ui/tuteur-v1-a`, `-b`, `-c`, `-cobs`, `-d`, `-e`), un worktree chacun ; COORD intègre par fusion dans `ui/tuteur-v1`. Chaque worktree exige `flutter pub get` et une copie locale de `dart_define.json` (jamais affichée).
- Machine : 4 cœurs, RAM libre 0,5 à 2 Go. Toute commande Flutter lourde passe par `D:\RA _APP\pilotage-tuteur-v1\outils\flutter-verrou.ps1` ; préférer `dart analyze <dossiers>` (~65 s) et `flutter test <fichier>` ; analyse complète (~9 min), suite complète (15-25 min estimées) et build web (~4 min, 1,5 Go) réservés à COORD (`C11` §2, §8).
- Frontière : `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc dart_define.example.json` doit rester **vide** (mesure contre C0, pas contre `main`).
- Reprises en bloc par COORD en phase 0, commits séparés, nommés, réversibles (point P8) : `33503fe` partie `lib/ test/ assets/` (7 fichiers) et `observation/lot-2026-09-21` partie `lib/ test/ assets/` (20 fichiers, sans `strings.g.dart`, régénéré). Appliquer par `cmd /c` ou fichier patch binaire, jamais par un pipe PowerShell 5.1 (`C10` §8.5).
- [critique] La reprise « en bloc » de `33503fe` n'est pas neutre : ses 7 fichiers comprennent `lib/core/i18n/strings_fr.g.dart` (à régénérer, pas à appliquer, comme pour la branche observation) et un morceau de `assets/i18n/fr.i18n.json` qui réécrit `contrat.pointEnregistrement` (texte **signé**) et `enseignant.profil.contratAccuse` sous la même `VersionsContrat.courante = '2026-09'` (`versions_contrat.dart:13`), ce que l'action de X10 interdit. Exclure ces deux clés de la reprise tant que P2 n'est pas tranché ; `salle.bandeauPermanent` (non signé) peut suivre. Voir X40.

## 1. Fichiers réservés au coordinateur

| Groupe | Fichiers |
|---|---|
| Routeur | `lib/core/router/app_router.dart`, `routes.dart`, `redirection.dart`, `billet_salle.dart`, `ecran_a_construire.dart` ; fichiers de routes des features : `lib/features/tc_mes_groupes/routes_tc_a.dart`, `chemins_tc_a.dart`, `lib/features/tc_catalogue/routes_tc_b.dart`, `lib/features/tc_mushaf/routes_tc_c.dart`, `lib/features/tc_classe_live/routes_tc_e.dart`, `lib/features/tc_observation_ui/routes_tc_g.dart` |
| Shell | `lib/core/widgets/nav_shell.dart`, `page_shell.dart`, `page_immersive.dart`, `admin_shell.dart`, `sous_navigation_domaine.dart`, `marque_page.dart` ; `lib/core/admin/admin_domaine.dart` (`ongletsSecurite()` **à créer** [critique] : n'existe pas sur la base, `admin_domaine.dart:152-180` n'a que Pédagogie et Configuration) |
| Thème, icônes, polices | `lib/core/theme/**` (dont nouveau `app_delais.dart`), `lib/core/icons/app_icons.dart`, `assets/fonts/**` |
| i18n | `assets/i18n/fr.i18n.json`, `assets/i18n/ar.i18n.json`, `lib/core/i18n/*.g.dart`, `slang.yaml` (procédure §4) |
| Point d'injection et configuration | `lib/app.dart`, `lib/main.dart`, `lib/core/config/**`, `lib/core/session/**`, `lib/core/auth/service_auth.dart`, `lib/core/reseau/**`, `lib/core/preferences/**` |
| Dépendances et outillage | `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `build.yaml` s'il existe, `tool/**` (dont `verifier_jetons.dart`) |
| Plateformes | `android/**` (permission CAMERA, `uses-feature` non requis, liens profonds), `ios/**` (`Info.plist` : `NSCameraUsageDescription`, schémas), `web/**` **sauf** `web/vercel.json` (script de décodage QR auto-hébergé), `windows/**`, `macos/**`, `linux/**` |
| Composants partagés existants | `lib/core/widgets/*` : `action_principale`, `app_bottom_sheet`, `app_card`, `audio_label`, `avatar_tile`, `bento_tile`, `child_card`, `choice_card_group`, `confirm_destructive`, `data_collection`, `empty_state`, `filter_pill`, `ligne_presence`, `local_feedback`, `menu_actions`, `menu_filtre`, `offline_banner`, `page_parcours`, `permanent_notice`, `pin_pad`, `pressable`, `rosace_verset`, `schedule_option`, `section_header`, `selecteur_niveau_programme`, `setting_row`, `signal_row`, `skeleton`, `stat_tile`, `status_pill`, `timeline_row`, `bandeau_observation` |
| Composants partagés à créer (phase 0) | `lib/core/widgets/etat_systeme.dart`, `bloc_asynchrone.dart`, `selecteur_profils.dart` (Accueil + Historique), `entete_page.dart` (retour rond, actions, cloche), `groupe_reglages.dart` (Compte + fiche élève), `lien_fleche.dart`, `ligne_cle_valeur.dart` (détail de séance + détail d'observation), `ecran_resultat.dart`, `bascule_theme.dart`, `controle_segmente.dart` (Historique + admin) |
| Contrats (K1 à K7) | `lib/core/foyer/selection_eleve.dart`, `profil_eleve_brouillon.dart`, `port_creation_profil_eleve.dart` ; `lib/core/seance_famille/seance_famille.dart`, `port_seances_famille.dart` ; `lib/core/capacites/capacite_indisponible.dart`, `lib/core/capacites/port_*.dart` et leurs implémentations « indisponible » (les adaptateurs réels `lib/core/capacites/*_supabase.dart` et `acces_foyer_depuis_eleves.dart` appartiennent aux lots du §3) ; `lib/core/tc_observation/{guardian_observation_policy,guardian_session_visit,port_politique_observation,port_visite_observation,echec_observation,disponibilite_observation,port_historique_observations}.dart` |
| Sources partagées entre lots | `lib/core/appairage/service_appairage.dart` (B et D), `lib/core/planning/**` (accueil tuteur, journée enseignant), `lib/core/presence/**` (élève, enseignant, historique), `lib/core/tc_groupe/{port_groupes,groupes_supabase,demonstration_groupes,group_summary_vm}.dart`, `lib/core/tc_horloge/**` (dont `horloge_supabase.dart` repris de v0), `lib/core/video/**`, `lib/core/cache/secure/stockage_securise.dart` |
| Dev et démonstration | `lib/features/_dev/**` (galerie, playground, personas tuteur, fixtures de démonstration) |
| Tests transverses | `test/router/**`, `test/theme/**`, `test/widgets/**`, `test/icons/**`, `test/i18n/**`, `test/accessibilite/**`, `test/support/harnais.dart`, `test/planning/**`, `test/presence/**`, `test/config/**`, `test/video/**`, `test/features/compte_galerie_test.dart`, `test/teaching_core/a/{fenetre_seance_test,session_clock_vm_test,group_summary_vm_test,routes_tc_a_test,groupes_supabase_test}.dart`, `test/teaching_core/b/routes_tc_b_test.dart`, `test/teaching_core/g/politique_observation_test.dart`, `test/teaching_core/q/q03_quota_observation_tuteur_test.dart`, `test/teaching_core/fixtures/**`, nouveau `test/fixtures/tuteur/**` (faux des ports K1 à K6) |
| Écrans transverses | page de démarrage de `/`, page d'erreur du routeur (`errorBuilder`), pages accès refusé et session expirée |

## 2. Fichiers réservés à d'autres chantiers ou interdits

| Groupe | Chemins | Raison |
|---|---|---|
| Interdits du mandat | `supabase/**`, `.github/**`, `vercel.json`, `web/vercel.json`, `.firebaserc`, `dart_define*.json`, tout secret | Mandat §3, BRIEF « interdits absolus » |
| Chantier C0 (PR #2) | `CLAUDE.md`, `lib/CLAUDE.md`, `supabase/CLAUDE.md`, `docs/**` (dont `docs/current/**`), `FABLE_*.md`, `.claude/` | Mise à jour de `docs/current/01:30` ou `08` : par le directeur ou COORD avec accord, hors branche UI |
| CORE24 gelé : chemins à ne **pas** créer | `lib/features/classes/**`, `lib/features/tuteur_classes/**`, `lib/features/enseignant_classes/**`, `lib/features/admin_groupes/creation_classe_page.dart`, `lib/core/admin/service_classes_admin.dart`, `lib/core/interface_guidee/**`, `lib/core/planning/service_remplacement_session.dart`, `lib/features/tc_classe_live/{bibliotheque_en_classe,commandes_classe,entree_salle,etat_partage_classe,hote_dock_classe,support_coran_classe}.dart`, `lib/features/tc_mushaf/selection_verset.dart` | Collision future avec une branche non conforme (`C10` §7-E) |
| Rôle élève | `lib/features/accueil_eleve/**`, `suivi_eleve/**`, `tc_mushaf/**` (hors `routes_tc_c.dart`), `tc_classe_live/**` (hors reprise en bloc COORD), `lib/core/tc_classe/**`, `lib/core/tc_coran/**`, `lib/core/coran/**` | Hors périmètre ; lecture seule |
| Rôle enseignant | `lib/features/journee/**`, `cahier/**`, `creneaux/**`, `profil_enseignant/**`, `salle_enseignant/**`, `fiche_groupe/**`, `revue_groupe/**`, `presence_correction/**`, `bienvenue_enseignant/**`, `tc_dock/**`, `lib/core/enseignant/**`, `lib/core/tc_outils/**` (sauf §3 lot C), `lib/core/tc_realtime/**`, `lib/core/profil/{service_declaration,service_profil_enseignant}.dart` | Hors périmètre |
| Salle | `lib/features/salle/**` : reprise en bloc COORD (notices de la branche observation), puis lecture seule | LiveKit central hors périmètre |
| Administration | `lib/features/admin_*/**` sauf `admin_journal/journal_page.dart` (E) et `admin_groupes/feuille_observation_groupe.dart` (C-obs) ; `lib/core/admin/**` sauf `admin_domaine.dart` (COORD) | Hors périmètre sauf consultation des observations |
| Autres | `lib/features/controleur/**`, `agent_entree/**`, `lib/core/agent/**`, `lib/core/matching/**`, `lib/core/priere/**`, `lib/core/controle/**`, `lib/core/journal/**`, `lib/core/regles/**`, `lib/core/observabilite/**`, `lib/core/marque/**`, `lib/core/cache/{db,media,sync}/**`, `lib/core/tc_telechargement/**`, `lib/core/tc_etat_partage/**` (lu par C-obs) | Lecture seule |
| Gelé sans propriétaire | `lib/features/disponibilites/**` (route redirigée par COORD, code conservé), `lib/core/widgets/child_card.dart` n'est plus appelé une fois l'Accueil refait (suppression seulement sur accord) | Matching abandonné |
| [critique] Non classés jusqu'ici, lecture seule | `lib/core/tc_parcours/**` **sauf** `port_travail_a_venir.dart` (C) : `port_post_cours`, `post_cours_vm`, `port_feedback`, `feedback_memoire`, `rotation_feedback`, `session_feedback`, `port_signalement`, `student_concern`, `plage_lisible`, `source_contenu_seance` ; `lib/features/tc_flux_academique/**` **sauf** `bloc_avant_prochain_cours.dart` (C) : `carte_feedback_seance`, `feuille_signalement`, `panneau_post_cours` | Post-cours élève et enseignant ; `student_concern` relève de DB-CPT-05 |
| Autres worktrees | tout `D:\RA_*`, `D:\ra-pwa-*`, `…\WindowsTerminal\rewayah-*`, `.gemini\…`, dont le fichier non suivi `D:\RA_OBS\supabase\migrations\0043_autoriser_jeton_video…` | Aucune écriture, aucun retrait |

## 3. Fichiers par lot

### A - Admission

| Statut | Fichiers |
|---|---|
| Existants possédés | `lib/features/connexion/connexion_page.dart`, `lib/features/inscription/inscription_page.dart`, `lib/features/dossier/{attente_page,signature_page,depot_piece_page}.dart`, `lib/features/parcours_offres/{parcours_offres_page,bloc_parcours,libelles_parcours}.dart`, `lib/core/dossier/{service_dossier,etat_dossier,versions_contrat,service_validation,selecteur_fichier}.dart`, `lib/core/offres/{offre_horaire,service_offres}.dart`, `lib/core/profil/service_acceptations.dart` |
| À créer | `lib/features/bienvenue/bienvenue_page.dart`, `lib/features/connexion/recuperation_page.dart`, `lib/features/inscription/etapes/{usage,identite,genre,recapitulatif}_etape.dart`, `lib/features/inscription/brouillon_inscription.dart` (mémoire), `lib/features/consentements/{texte_observation,explication_observation,consentement_observation_page}.dart`, adaptateur `lib/core/capacites/consentements_supabase.dart` (port K6 `PortConsentements`) |
| Tests | `test/features/{connexion,inscription,attente,dossier,dossiers_sans_piece}_test.dart`, `test/parcours/**`, nouveaux `test/features/admission/**` |
| Lecture seule | `lib/core/auth/service_auth.dart` (demandes à COORD : erreur de lien expiré, préremplissage Google), contrat K3 (enchaînement vers le formulaire B), K4 (politique effective pour le texte) |
| Non-régression | inscription enseignant (même tunnel), `profil_enseignant_page.dart` lit `service_acceptations.dart` ; [critique] `libelles_parcours.dart` est importé hors lot A par `lib/core/tc_parcours/port_travail_a_venir.dart`, `lib/features/tc_flux_academique/{bloc_avant_prochain_cours,feuille_signalement,panneau_post_cours}.dart` : aucune signature publique retirée sans demande COORD |

### B - Foyer et fiche élève

| Statut | Fichiers |
|---|---|
| Existants possédés | `lib/features/appareils/ajouter_enfant_page.dart` (reste à son chemin), `lib/features/reglages_enfant/reglages_enfant_page.dart` (contenu déplacé vers la fiche, route redirigée ensuite par COORD), `lib/core/appairage/service_avatar.dart` |
| À créer | `lib/features/foyer/foyer_page.dart`, `ligne_membre.dart`, `fiche_eleve_page.dart`, `fiche/{informations,inscription,interface,camera,acces}_page.dart`, `photo_eleve.dart`, `formulaire_profil_eleve.dart` (widget du contrat K3, dès que K3 est figé), `creer_mon_profil_indisponible.dart` |
| Tests | `test/features/reglages_enfant_test.dart`, nouveaux `test/features/foyer/**` |
| Lecture seule | `service_appairage.dart` (COORD ; demandes : lecture du `label`, rien d'autre), `compte_page.dart` (E ; `ProfilsComptePage` et `ProfilEnfantPage` deviennent inaccessibles au tuteur par redirection COORD, B n'y touche pas), `lib/features/appareils/appareils_page.dart` (D ; la fiche intègre le widget « appareils d'un élève » de D), `bloc_parcours.dart` (A) |

### C - Cours (Accueil, Classe, catalogue, planning, travail, ressources, progression)

| Statut | Fichiers |
|---|---|
| Existants possédés | `lib/features/accueil_famille/accueil_famille_page.dart` (après reprise COORD du hunk « Assister » de la branche observation), `lib/features/tc_espace_groupe/{espace_groupe_page,carte_session,emplacements_groupe}.dart`, `lib/features/tc_mes_groupes/{carte_groupe,mes_groupes_page,photo_enseignant}.dart`, `lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart`, `lib/features/tc_catalogue/{bibliotheque_page,carte_ressource,class_library_picker,detail_ressource_page,libelles_bibliotheque,surface_bibliotheque,vignette_ressource}.dart`, `lib/core/tc_groupe/{group_home_vm,libelles_tc_groupe,palette_groupe}.dart`, `lib/core/tc_bibliotheque/**`, `lib/core/tc_parcours/port_travail_a_venir.dart`, `lib/core/tc_outils/{port_assignations,learning_assignment}.dart` |
| À créer | `lib/features/accueil_famille/{carte_classe_seance,bloc_seance,bandeau_blocage,liste_preparation,ligne_derniere_seance}.dart`, `lib/features/classe_tuteur/{classe_tuteur_page,planning_classe_page,travail_classe_page,ressources_classe_page,progression_classe_page,catalogue_classes_page}.dart`, adaptateurs `lib/core/capacites/classes_foyer_supabase.dart` (port K6 `PortClassesFoyer`), `lib/core/tc_bibliotheque/catalogue_supabase.dart`, `lib/core/tc_outils/assignations_supabase.dart` |
| Tests | `test/features/accueil_famille_test.dart`, `test/teaching_core/a/{carte_groupe_test,espace_groupe_page_test,mes_groupes_page_test,responsive_test}.dart` (+ `faux/`, `support/`), `test/teaching_core/b/**` sauf `routes_tc_b_test.dart`, `test/teaching_core/h/{bloc_avant_prochain_cours_test,travail_a_venir_test}.dart`, `test/teaching_core/d/assignations_test.dart` (non-régression), nouveaux `test/features/classe_tuteur/**` |
| Lecture seule | contrats K1, K2, K4 (bloc « Observer la séance » affiché dans la classe à partir de `DisponibiliteObservation`, écran fourni par C-obs), `lib/core/planning/**`, `lib/core/tc_horloge/**` |
| Non-régression | l'Espace Groupe et la Bibliothèque servent aussi l'élève (`/tc/groupes`, `/tc/bibliotheque`) ; `port_assignations.dart` sert le dock enseignant |
| [critique] Compléments | `lib/features/tc_espace_groupe/roster_enseignant_slot.dart` n'avait pas de propriétaire : rattaché à C (même dossier), modification seulement pour non-régression enseignant. `group_home_vm.dart` (C) porte `RoleEspaceGroupe`, importé par `app_router.dart:62` et `routes_tc_a.dart` (COORD) : toute modification de cet enum passe par une demande COORD. `port_travail_a_venir.dart` (C) est aussi importé par `lib/core/tc_parcours/port_post_cours.dart` (élève). `libelles_parcours.dart` (A) est importé par `port_travail_a_venir.dart` et `bloc_avant_prochain_cours.dart` (C) : lecture seule pour C |

### C-obs - Observation

| Statut | Fichiers |
|---|---|
| Existants possédés | `lib/features/tc_observation_ui/{entree_observation_page,choix_entree_observation,options_entree_observation,panneau_observation_tuteur,vue_observation_tuteur,indicateur_observation,etat_reglages_observation,module_reglages_observation}.dart`, `lib/core/tc_observation/{moteur_visite_observation,vue_budget_observation,libelles_observation,port_annonce_observation,capacites_observateur,mode_entree_admin}.dart`, `lib/features/admin_groupes/feuille_observation_groupe.dart` (replis 1/120/`a1` à aligner) |
| À créer | `lib/features/tc_observation_ui/{salle_observation_page,barre_commandes_observation,compteur_visite,resultat_visite_page,bloc_disponibilite_observation}.dart` |
| Tests | `test/teaching_core/g/**` sauf `politique_observation_test.dart`, `test/features/observation_groupe_admin_test.dart` |
| Lecture seule | contrat K4 (COORD), textes d'explication et de consentement (A), `lib/core/video/**`, `lib/core/tc_etat_partage/**` (support partagé), `lib/features/salle/**` et `tc_classe_live/**` (notices déjà montées par la reprise) |
| [critique] Non-régression | `port_annonce_observation.dart` (C-obs) est importé par `lib/features/tc_classe_live/{classe_live_page,entete_classe}.dart` (classe élève et enseignant, lecture seule) ; les clés `tc.observation.annonce.*` s'affichent côté élève et enseignant. Rendu du support : composants `tc_mushaf`, `tc_classe_live`, `lib/core/tc_coran` réutilisés sans modification (demande COORD sinon) |

### D - Appareils

| Statut | Fichiers |
|---|---|
| Existants possédés | `lib/features/appareils/{appairage_page,appareils_page}.dart`, `lib/features/eleve_connexion/eleve_connexion_page.dart`, `lib/features/connexion/feuille_appareil_eleve.dart`, `lib/core/appairage/{service_enfant,code_local,profils_locaux}.dart` |
| À créer | `lib/features/appareils/{appareils_eleve_page,liste_appareils_eleve,emetteur_qr}.dart`, `lib/features/eleve_connexion/{scanner_page,saisie_code_page}.dart`, `lib/core/appairage/{lecteur_qr,lecteur_qr_mobile_scanner,statut_code_appairage}.dart` (ports K6 et adaptateurs) |
| Tests | `test/appairage/**`, `test/features/{appareils,eleve_connexion}_test.dart`, nouveaux `test/features/appareils/**` |
| Lecture seule | `service_appairage.dart`, `pin_pad.dart`, `stockage_securise.dart`, `app_palette.dart` (paire QR noir sur blanc dans les deux thèmes : demande à COORD), permissions plateforme (COORD) |
| Contraintes | test lexical `code_local_test.dart` couvre tout `lib/` : aucun code ni jeton dans un journal, une URL, Sentry ou une capture |
| [critique] Non-régression | `profils_locaux.dart` (D) est importé par `lib/core/enseignant/depot_cahiers.dart` (rôle enseignant) : tests enseignant concernés à relancer à chaque changement de ce fichier |

### E - Compte et suivi (Compte, Historique, détail, notifications, aide, légal, consultation admin des observations)

| Statut | Fichiers |
|---|---|
| Existants possédés | `lib/features/compte/compte_page.dart` (découpé), `lib/features/suivi_foyer/{suivi_foyer_page,vue_suivi_foyer}.dart`, `lib/core/suivi/service_suivi.dart`, `lib/features/admin_journal/journal_page.dart` (libellés `observation_entree`, `observation_sortie`, `observation_politique_groupe_modifiee`, en-tête à sous-navigation) |
| À créer | `lib/features/compte/{compte_tuteur_page,informations_page,securite_page,acces_page,paiements_page,preferences_page,apparence_page,aide_page,informations_legales_page}.dart`, `lib/features/suivi_foyer/{observations_page,detail_seance_page,detail_observations_page,filtres_historique}.dart`, `lib/features/notifications/notifications_page.dart`, `lib/features/admin_observations/observations_admin_page.dart`, adaptateurs `lib/core/capacites/{identite_titulaire_supabase,acces_foyer_depuis_eleves}.dart`, `lib/core/tc_observation/historique_observations_supabase.dart` (implémente le port K4) |
| Tests | `test/features/{compte,suivi_foyer,journal_admin}_test.dart`, `test/suivi/**`, nouveaux `test/features/historique/**`, `test/features/admin_observations/**` |
| Lecture seule | `lib/core/presence/**` et `ligne_presence.dart` (table d'affichage unique ; demande à COORD pour « En cours de vérification »), `service_acceptations.dart` (A), `preferences_locales.dart` et `app.dart` (COORD) |
| Non-régression | `compte_page.dart` sert enseignant, contrôleur, comptable, admin (`/compte`) ; `vue_suivi_foyer.dart` sert `suivi_eleve_page.dart` (`test/features/suivi_eleve_test.dart` doit rester vert) ; [critique] `service_suivi.dart` est aussi importé par `suivi_eleve_page.dart` |

### Q - Revue indépendante

Aucun fichier du dépôt. Sorties dans `D:\RA _APP\pilotage-tuteur-v1\` (proposition `05_recette/`), planches comparatives produites par l'outil de capture de `C11`.

## 4. i18n : un fichier, un propriétaire, des espaces de noms réservés

`assets/i18n/fr.i18n.json` et les fichiers générés sont à COORD. Pour ne pas bloquer la compilation des lots :

1. Phase 0 : COORD crée les squelettes de clés par espace de noms à partir du mapping (titres, états, actions).
2. Un lot ajoute localement dans son worktree les clés de **son** espace de noms pour compiler, mais ne committe ni `fr.i18n.json` ni `*.g.dart` ; il dépose le fragment dans `D:\RA _APP\pilotage-tuteur-v1\04_i18n\<lot>.json` avec la liste des clés retirées.
3. COORD fusionne par lots, régénère (`dart run slang`), vérifie `tool/verifier_jetons.dart` (emoji, M-dash), committe.

| Lot | Espaces de noms |
|---|---|
| COORD | `nav.*`, `commun.*` (dont `commun.etats.*`), `reseau.*`, `galerie.*` |
| A | `bienvenue.*`, `connexion.*` (hors `connexion.feuilleAppareil.*`), `inscription.*`, `attente.*`, `accuse.*`, `contrat.*`, `parcours.*`, `consentement.*` |
| B | `foyer.*`, `enfant.*`, `reglagesEnfant.*`, `ficheEleve.*` |
| C | `tuteur.accueil.*`, `classe.*`, `tc.groupe.*` (dont le remplacement de « Cours en cours »), `tc.bibliotheque.*` |
| C-obs | `tc.observation.*` |
| D | `appareils.*`, `eleveConnexion.*`, `connexion.feuilleAppareil.*` |
| E | `compte.*`, `historique.*`, `suivi.*`, `notifications.*`, `admin.observations.*`, `admin.journal.evenements.*` |

Les noms exacts des blocs existants sont à relever par COORD dans `fr.i18n.json` au moment de la phase 0 ; une clé existante utilisée par plusieurs lots reste à COORD.

[critique] Espaces de noms non attribués qui portent le libellé interdit « … en cours » : `tc.classe.barre.titre` (l. 2023 « Cours en cours »), `tc.classe.entete.coursEnCours` (l. 1923 « Cours toujours en cours »), `enseignant.journee.coursEnCours` (l. 1379). Ils relèvent de COORD (espace de noms sans lot) ; ce sont des écrans élève et enseignant, d'où la décision de portée X41. Dans le lot C : `tc.groupe.temps.enCours` (l. 1700) et `tc.groupe.temps.prolongee` (l. 1702). Hors ces clés, `salle.refusAccesDetail` (l. 52) et `enseignant.journee.lancementPlusTard` (l. 1385) affirment « dix minutes » alors que la fenêtre serveur est de 20 min (`0030:33-41`) : écrans hors tuteur, à signaler, sans correction dans ce chantier.

## 5. Séquencement

| Phase | Qui | Contenu | Sortie attendue |
|---|---|---|---|
| 0.a | COORD | Worktree, suite complète de tests sous verrou pour figer la base, reprises `33503fe` et branche observation (si P8), régénération slang | base verte mesurée |
| 0.b | COORD | Polices DM Sans et Plus Jakarta Sans, `_titre()` avec `opsz`, style chiffre, jetons d'arbitrage, règle `police-hors-typographie`, tests de thème | jetons stabilisés, captures galerie clair et sombre |
| 0.c | COORD | Coquille tuteur à 4 branches, alias et redirections, `errorBuilder`, écran de démarrage, `PageShell` à en-tête, correction double zone sûre, thème branché | `navigation_test` et `redirection_test` mis à jour |
| 0.d | COORD | Contrats K1 à K7, composants partagés, squelettes i18n, fixtures `test/fixtures/tuteur/`, personas Playground | contrats figés et testés |
| 1 | A, B, C, C-obs, D, E en parallèle | Parcours de chaque lot sur ses fichiers | parcours navigables, états, tests ciblés |
| 1 bis | B puis A | K3 figé → B livre le formulaire → A branche l'enchaînement fin d'admission | pas de dépendance circulaire |
| 2 | COORD | Intégration progressive, redirection de `/tuteur/reglages` après B, retrait des entrées mortes, captures comparatives | branche `ui/tuteur-v1` intégrée |
| 2 bis | Q | Revue fidélité, parcours, responsive et accessibilité, frontière sécurité | défauts rendus aux propriétaires |

## 6. Points chauds résolus

| Fichier | Prétendants | Propriétaire retenu | Raison |
|---|---|---|---|
| `lib/core/appairage/service_appairage.dart` | B (élèves, réglages), D (appareils, codes) | COORD | Source partagée (`C05` §10) |
| `lib/features/appareils/ajouter_enfant_page.dart` | B, D (dossier `appareils`) | B | Domaine d'ajout de profil |
| `lib/features/appareils/appareils_page.dart` | B (Foyer), D | D | Liste et retrait d'appareils ; le Foyer de B est un nouvel écran |
| `lib/features/accueil_famille/accueil_famille_page.dart` | C, reprise observation | COORD pour la reprise, puis C | Une seule écriture concurrente |
| `lib/core/tc_observation/*` | C-obs, E (historique), admin | partage §3 : modèles et ports à COORD, moteur et affichage à C-obs, adaptateur d'historique à E | Modèles stabilisés avant les écritures |
| `lib/features/compte/compte_page.dart` | E, B (fiche élève) | E | B passe par ses propres routes ; redirection COORD |
| `lib/features/connexion/feuille_appareil_eleve.dart` | A (dossier `connexion`), D | D | Entrée du parcours appareil élève |
| `ligne_presence.dart`, `vue_presence.dart` | E (historique), élève, enseignant | COORD | Table de libellés de présence unique |
| `lib/core/tc_groupe/group_summary_vm.dart` | C, contrat K2 | COORD | `EnseignantVM`, `TitreEnseignant`, `OccurrenceSeance` portés par le contrat |
| `lib/core/tc_groupe/libelles_tc_groupe.dart` | C, K2 | C | Libellés d'affichage (remplacement de « Cours en cours ») |
| `lib/features/admin_groupes/feuille_observation_groupe.dart` | C-obs, admin | C-obs | Seul changement : replis de politique périmés |

### 6 bis. [critique] Imports entre lots en phase 1 (contraires à la règle du préambule)

Quatre widgets ou adaptateurs créés par un lot sont consommés par un autre pendant la phase parallèle ; tel quel, le consommateur ne compile pas avant le producteur. Proposition, à valider par COORD :

| Élément (producteur) | Consommateur | Proposition |
|---|---|---|
| `liste_appareils_eleve.dart` (D) intégré dans la fiche | B | La fiche montre une ligne « Appareils » (résumé + chevron) vers `/tuteur/foyer/:eleveId/appareils` (écran D) ; aucun import de D |
| `bloc_disponibilite_observation.dart` (C-obs) intégré dans la classe | C | C construit le bloc depuis `DisponibiliteObservation` (K4, COORD) et navigue vers `/tc/observation/:seanceId` ; C-obs garde l'écran immersif. Ou promotion du bloc en `lib/core/widgets/` par COORD |
| `texte_observation.dart`, `explication_observation.dart` (A) repris dans l'observation | C-obs | Textes portés par des clés i18n `consentement.*` paramétrées (COORD fusionne) plutôt qu'un import Dart ; ou promotion COORD |
| `acces_foyer_depuis_eleves.dart` (E) lu par la fiche | B | Le provider de production vit dans le fichier du port (COORD) ; B lit le provider, jamais le fichier de E ; implémentation « indisponible » tant que E n'a pas livré |
