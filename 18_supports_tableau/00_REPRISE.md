# Supports et tableau dans la salle : reprise (lire ceci d'abord)

> **Décision de l'orchestrateur (02/10, ménage du tableau) — prime sur TB-F plus bas.**
> Q2 tranchée : oui. `ui/supports-tableau-v1` part de `origin/corrections/revue-directeur-2026-10` **après INTEG-RC-1** (qui y réunit déjà ui/accessibilite-v1, donc CommandesMasquables) et SALLE-200-2. TB-F n'a plus de fusion séparée à faire. TB-1a (revue UX, document) peut démarrer tout de suite. Voie du tableau : **TB** (une session à la fois). Question Q1 au directeur : dépôt `A-q-TB-1`.

Préparé le 02/10/2026 (étape TB-0), en lecture seule sur le code. Aucun fichier des worktrees applicatifs n'a été modifié.

## 1. Objet

Compléter la salle de classe **existante** sans la refaire :
- montrer un support (page fixe) à toute la classe, l'annoter sur un calque solidaire de la page ;
- trois affichages partagés : **Support**, **Avec notes**, **Tableau** ; masquer ne supprime rien ;
- ranger un support dans la bibliothèque et le reprendre, un tableau libre indépendant ;
- commandes en trois familles : visio (Micro, Caméra, Quitter) révélée au toucher, à la souris ou au clavier ; pédagogie derrière un seul bouton « Commandes » ; capsule compacte (avatar, enregistrement, œil) pendant le partage ;
- desktop équilibré (Participants à gauche, surface au centre, Commandes à droite si ouvertes) et focus local.

Périmètre : écrans en **démonstration**, sans serveur (K-28, K-35). Chaque besoin serveur ou temps réel va dans `TB-BR.md` (BR-1).

## 2. Sources

| Quoi | Où |
|---|---|
| Plan du directeur V2 (01/10/2026, 68 Ko, 23 sections) | `18_supports_tableau/V/REWAYAH_PLAN_SUPPORTS_TABLEAU_V2.md` (lire par section, § cité dans chaque étape) |
| Planches (8 images, et non 7 : toutes copiées) | `18_supports_tableau/V/*.png`, relevé au §5 ci-dessous |
| Règles de la salle | `10_classe/` (00_REPRISE, 02_DIRECTION_VISUELLE, UX_REVIEW_CL-4, UX_REVIEW_CL-7), R1 à R21 (K-40) |
| Modèle de préparation | `16_eleves_adultes/00_REPRISE.md`, `02_DECOUPAGE.md` |
| Erreurs à ne pas refaire | `05_recette/**/REVUE_*.md`, `RAPPORT.md` (synthèse au §8) |
| Décisions déjà prises | `DECISIONS_DELEGUEES_2026-10-02.md`, K-53, K-61 |

## 3. Branche et worktree proposés

- **Branche** `ui/supports-tableau-v1`, à créer par l'étape TB-F depuis `origin/corrections/revue-directeur-2026-10` @ `0796f75` (ou plus récent), **après** SALLE-200-1 et SALLE-200-2.
- **Worktree** `D:\RA_TUTEUR\tableau`. Pas encore créés.
- **Pourquoi cette base** (comparaison du 02/10, `git log -3` et `merge-base --is-ancestor`) :
  - `corrections/revue-directeur-2026-10` (21:28) contient déjà `ui/classe-v1`, `ui/tuteur-v1`, `ui/admin-v1` et toutes les corrections récentes de la salle : ETATS-BTN-1 (états des bascules), VIDEO-TUILE-1 (`TuileSansImage`), CTRL-SALLE-1, NAV-FLECHES-1, SALLE-200-1 (`page_immersive.dart`, `salle_page.dart`).
  - `ui/enseignant-v1` n'a que 2 commits de plus (cahier EN-IND, EN-7c) : aucun fichier de salle.
  - `ui/controleur-v1` (19 commits de plus) ne touche la salle qu'en 7 lignes de `salle_page.dart`.
  - `ui/accessibilite-v1` (31 commits de plus, 20:30) porte la **dernière version de la salle en Mode Accessibilité** et surtout `CommandesMasquables` (MA-CMD-1, délai 4 s, révélation au toucher, toujours visibles au clavier et au lecteur d'écran). C'est exactement la politique de révélation demandée (§4.1, §18). Elle n'est **pas** dans la branche de corrections.
  - Essai à blanc (`git merge-tree`, sans toucher aux worktrees) : fusionner `ui/accessibilite-v1` dans les corrections donne 12 fichiers en conflit, dont `dock_seance.dart`, `nav_shell.dart`, `page_shell.dart`, `setting_row.dart`, `groupe_reglages.dart`, les fichiers slang générés et 4 tests.
  - D'où l'étape **TB-F** (fusion préalable dans la branche TB, jamais dans `main`), soumise à la question Q2. Sans elle, TB-2 devrait recopier `CommandesMasquables` (interdit, K-10).

## 4. Existant à réutiliser (K-10, K-51 : jamais recréer)

Références sur `origin/corrections/revue-directeur-2026-10` @ `0796f75`, sauf mention.

**Deux salles, un gabarit.** `SalleSeance` est la salle unique de l'élève, de l'Interface guidée et de l'enseignant (`/tc/classe`, `classe_live_page.dart:401`, et `/demo/salle`, `demo_salle_page.dart:415`). `SallePage` (`/salle`, `salle_page.dart:79`, sur `PageImmersive`) garde le rendu du tuteur observateur et du contrôleur ; elle « ne présente aucun contenu elle-même » (en-tête du fichier).

| Responsabilité du plan (§8, §17) | Existant | Fichier:ligne |
|---|---|---|
| Salle, rôle effectif | `SalleSeance`, `RoleSeance` (eleve, guidee, enseignant) | `lib/features/salle_seance/salle_seance.dart:60`, `vue_seance.dart:19` |
| État local (focus, zoom, micro) | `EtatLocalSeance` (`agrandi` = focus local) | `salle_seance.dart:41` |
| Clavier des panneaux (Échap, retour du focus) | `_FocusPanneaux` | `salle_seance.dart:206` |
| Raccourcis enseignant (E19) | `RaccourciSalle` | `salle_seance.dart:471` |
| Barre visio | `DockSeance`, `BoutonAppel` (états ETATS-BTN-1), `_BarreBasse` desktop | `dock_seance.dart:139`, `:81`, `salle_seance.dart:1250` |
| Révélation temporisée (VIS-01) | `CommandesMasquables` (4 s) | **`ui/accessibilite-v1`** : `lib/core/accessibilite/commandes_masquables.dart:25`, `:48` ; utilisé `salle_seance.dart:161` de cette branche |
| En-tête, enregistrement | `ChromeSeance`, `MentionSeance`, `PointDirect` (pulsation) | `chrome_seance.dart:30`, `mention_seance.dart:20`, `lib/core/widgets/pastille_etat_seance.dart:87` |
| Œil, observation | `IndicateurObservation`, `VisiteSeance` | `lib/features/tc_observation_ui/indicateur_observation.dart:73`, `vue_seance.dart:146` |
| Avatar sans vidéo | `TuileSansImage`, `VignetteVideo` | `lib/core/widgets/avatar_nom.dart:267`, `vignette_video.dart:89` |
| Surface pédagogique | `ZoneSupport`, état vide `_RienPartage` | `zone_support.dart:25`, `:759` |
| Panneau (colonne, volet, feuille) | `PanneauSeance`, `FormePanneau` | `panneau_seance.dart:64`, `:45` |
| Participants (PER-01) | `PanneauEleves` (cartes, `_ActionsEleve`) | `panneau_eleves.dart:65`, `:504` |
| Bibliothèque en salle (LIB-01) | `PanneauSupports`, `SelecteurRessources`, `SupportDisponible` | `panneau_supports.dart:35`, `selecteur_ressources.dart:26`, `vue_seance.dart:199` |
| Catalogue commun (R14 : une seule bibliothèque) | `VueCatalogue`, `SurfaceBibliotheque`, `ClassLibraryPicker` | `lib/core/tc_bibliotheque/vue_catalogue.dart:79`, `lib/features/tc_catalogue/surface_bibliotheque.dart:52`, `class_library_picker.dart:26` |
| Pages, zoom local | `PaginationSupport`, `ZoomLocal`, `IndicateurPage` | `barre_support.dart:59`, `:105`, `:24` |
| Outils enseignant actuels | `OutilsEnseignement` (Pointeur, Marquer, Masquer, Annoter) | `outils_enseignement.dart:61`, `actions_seance.dart:13` |
| Calque d'annotation (dormant, jamais monté) | `CoucheAnnotation`, `PolitiqueSaisie` (stylet/doigt), `_PeintreAnnotations` | `lib/features/tc_dock/couche_annotation.dart:74`, `:35`, `:386` |
| Barre stylet, dock d'enseignement (dormants) | `BarreStylet`, `TeachingDock`, `HoteDockSalle` | `tc_dock/barre_stylet.dart:29`, `teaching_dock.dart:45`, `salle_seance/outils_dock_salle.dart:22` |
| Modèle des traits | `PointNormalise`, `TraitVectoriel`, `OutilTrait`, `PorteeAnnotation`, `AnnotationLayer` | `lib/core/tc_outils/annotation_layer.dart:82`, `:126`, `:46`, `:11`, `:247` |
| Trait en cours (aperçu puis version compacte) | `TraitEnCours`, `simplifierTrait` (RDP, sans dépendance) | `tc_outils/compaction_trait.dart:91`, `:17` |
| Événements d'outils | `EvenementTraitEnCours`, `…Termine`, `…Retire`, `EvenementPointeur`, `EvenementMasquage`, `DiffusionOutils` | `tc_outils/evenements_outils.dart:36`, `:79`, `:120`, `:145`, `:238`, `:268` |
| Annotations en mémoire | `PortAnnotations`, `AnnotationsMemoire` | `tc_outils/port_annotations.dart:17`, `:61` |
| Masquer des versets (préserver) | `PlanMasquage` | `tc_outils/masquage.dart:16` |
| État partagé (révision) | `SharedContentState`, `ModeAffichagePartage` (page, verse, focus), `ReducteurEtatPartage`, `ServiceEtatPartage` | `lib/core/tc_etat_partage/shared_content_state.dart:62`, `:11`, `reducteur_etat_partage.dart:59`, `service_etat_partage.dart:47` |
| Temps réel pédagogique | `PortRealtimePedagogique`, `ServiceRealtimePedagogique` (doublons), `CanalFiabilite`, `TransportMemoire`, `AdaptateurTransportLiveKit`, `sujetProtocolePedagogique` | `lib/core/tc_realtime/port_realtime_pedagogique.dart:124`, `service_realtime_pedagogique.dart:41`, `:13`, `transport_memoire.dart:62`, `adaptateur_transport_livekit.dart:62`, `types_message.dart:51` |
| Contenu présenté (socle) | `ContenuPresente`, `presenterContenu` | `lib/core/video/video_session_provider.dart:278`, `:472` |
| Coran (rendu intouché) | `VuePageMushaf`, `VueVersetAgrandi`, `VueFocusClasse`, `PresentateurCoran` | `lib/features/tc_mushaf/`, `lib/features/salle_enseignant/presentation_coran.dart:88` |
| Mouvement | `AppMouvement` (180, 220 ms ; pulsation 1200 ms) ; `lib/core/mouvement/` | `lib/core/theme/app_mouvement.dart:25`, `:28`, `:53` |
| Démonstration et captures | `/demo/salle` ; `test/capture/outil_capture.dart` ; modèle `test/features/salle_seance/salle_seance_capture_test.dart`, `test/features/salle_200_test.dart` | — |
| Contrat durable déjà en base (lecture seule) | `annotation_layer`, `annotation_trait`, `session_shared_content` (`display_mode in ('page','verse','focus')`) | `supabase/migrations/0032_tc_catalogue.sql:228`, `:280`, `:404` |

**Ce qui manque** :
- l'affichage partagé Support / Avec notes / Tableau (il n'existe que page, verset, focus) et le tableau libre sans support ;
- un support à **page fixe** dans la salle : `SupportSeance` est une diapositive de texte (chapitre, titre, points), sans image de page ;
- le montage de `CoucheAnnotation` dans `ZoneSupport` (jamais monté nulle part) ; un repère de **page** (le modèle normalise par bloc ancré) ;
- le déclencheur « Commandes » et le panneau pédagogique unique ; la capsule compacte ; la révélation de la visio pour tous les rôles ;
- prévisualisation personnelle, « Présenter », « Ranger dans la bibliothèque », reprise ;
- l'autorisation d'écrire sur la ligne de l'élève ; la vue en lecture seule des observateurs dans `SallePage` ;
- les états de synchronisation et de conservation du §12.

## 5. Contrôle des planches (§22.6)

Les 8 images portent « Support illustratif, non canonique ». Les lignes pointillées et les médaillons ne sont **pas** un Mushaf : on ne les reproduit pas comme du Coran.

| Planche | On garde | On corrige (preuve) |
|---|---|---|
| 1 « Les panneaux restent à la demande » | Profil déplié avec « Réduire » ; Commandes en feuille ; visio sous la feuille | Onglets « Support / Outils » : le plan dit Bibliothèque en première action et « Écrire » qui ouvre la sous-barre (§4.2) → Q1. Phrase « Cours enregistré, visite de contrôle possible. » : texte existant, à garder compact (D4). |
| 2 « La visio apparaît au toucher » | Repos sans visio ; toucher → Micro, Caméra, Quitter ; Commandes au-dessus | Icône Caméra différente d'une planche à l'autre (appareil photo ici) : garder l'icône existante. Pas de Pointeur ni Terminer dans Outils (§4.2, §20). |
| 3 « Présentation immersive » (web) | Capsule en haut, page dominante, « Commandes » discret en bas à droite | Conforme. |
| 4 « Focus, visio révélée » (web) | Visio en bas au mouvement | « Vue complète » : le texte du plan est « Quitter le focus » (§20). La barre recouvre le bas de la page : §18.2 demande de ne pas couvrir le contenu (marge de lecture ou pan). |
| 5 « Tableau blanc » (web) | Fond clair, encre lisible | La feuille doit garder son ratio et son repère (§3) : fond clair plein écran permis, coordonnées jamais étirées. |
| 6 « Commandes ouvertes » (web) | Panneau droit : modes, Focus, Bibliothèque, pages | « Page 24 » → « Page {numéro} sur {total} » (§20). Bibliothèque en bas → en premier (§4.2). Avatar en grand rond hors capsule : la capsule le remplace (§4.3). |
| 7 « Mobile, focus » | Focus sans encombrement, capsule, Commandes | « Vue complète » → « Quitter le focus ». |
| 8 « Classe An-Nour, panneaux équilibrés » | Participants à gauche, « Peut écrire » sur la ligne, Commandes à droite, surface au centre | L'action « Autoriser à écrire » doit exister sur la ligne (§4.3, §20). Avatar enseignant hors capsule. Micro barré sur toutes les lignes : état réel seulement. |

## 6. Contradictions relevées (signalées, pas résolues en silence)

1. **Mode d'affichage.** Le plan veut Support / Avec notes / Tableau ; le code et la base n'ont que `page`, `verse`, `focus` (`shared_content_state.dart:11`, `0032:404`). Ce sont deux axes différents. En démonstration : un champ d'affichage dans `VueSeance` ; en base : ligne TB-BR (aucune migration).
2. **perfect_freehand** (§9.5) n'est pas dans `pubspec.yaml`, qui est interdit (K-19). Le code existant a choisi de s'en passer (`compaction_trait.dart:9-11`). On rend avec `_PeintreAnnotations` ; la question va en TB-BR.
3. **Repère.** `PointNormalise` est normalisé par bloc ancré, le plan veut la page entière. Une page fixe = un seul bloc couvrant la page : on réutilise le modèle, sans le changer (TB-1a le vérifie).
4. **Mode Accessibilité.** Le plan (§4.2) garde « pictogramme et mot » en Interface guidée ; MA-CMD-1 (directeur, 02/10 14:36, plus récent) impose des icônes seules compactes, nom au lecteur d'écran et en infobulle. MA-CMD-1 prime (K-61 n° 4). Le mot d'état des bascules reste (décision déléguée du 02/10).
5. **Vignette de l'enseignant.** MA-5 (A6, 27/09) : « la vignette de l'enseignant défile ». Le plan (01/10) : pendant le partage, une capsule sans vidéo remplace la grande carte. Le plan est plus récent : il s'applique au partage ; hors partage, la vignette reste.
6. **Outils actuels.** Pointeur, Marquer, Masquer, Annoter (CLV-06, validés) deviennent Pointeur, Écrire, et les capacités existantes (marqueurs, masquer des versets) sous leur entrée contextuelle (§4.2) : rien n'est supprimé, Annoter devient Écrire.
7. **Libellé.** Le panneau existant s'appelle « Supports » (CLV-08) ; le plan dit « Bibliothèque » (§20). On suit le plan (texte), sans créer de seconde bibliothèque.

## 7. Interdits

- `main`, PR, `supabase/` (lecture seule), `.github/`, `vercel.json`, **`pubspec.yaml`** (donc pas de nouveau paquet), secrets, `dart_define.json` (K-19).
- **Coran** : jamais toucher au rendu du Mushaf (`lib/features/tc_mushaf/`, `lib/core/tc_coran/`, `lib/core/coran/`, assets) ; le calque se pose au-dessus, rien en dessous ; jamais inversé en sombre ; aucun Mushaf composé ni image générée présentée comme Coran.
- **Thème et couleurs** : rien ; toute idée de couleur = une ligne TH-2 (K-37). Aucun nouveau jeton.
- Aucune migration, aucun serveur de tableau, aucun second client LiveKit, aucune seconde bibliothèque ni second dock (§13, §22).
- `dart format` sur un dossier (K-23) ; traduction avant LG-1 (K-41) ; texte en dur.
- Rouvrir une étape faite : la dette va en HU-1 (K-38). Composant partagé de `lib/core/widgets` : évolution additive seulement, jamais une copie ; un écart d'un écran commun = ligne « Harmonisation : … » (K-51).

## 8. Erreurs des revues à ne pas refaire

- Bouton qui ne fait rien ou faux succès (« Sauvegardé » sur simple envoi) ; bouton grisé sans raison écrite (CL-4 M1, m2).
- Commande d'un autre rôle visible (élève qui voit Ranger, observateur qui voit Écrire) : brancher par rôle, test pour chaque rôle (CL-4 m8, CT-R C5).
- Tests qui montent la page seule : taper le vrai bouton depuis la coquille (K-07 ; EA-R m15).
- Captures non relues, « déjà conforme » cru sur parole : l'orchestrateur ouvre la capture du même état que la planche (K-61 n° 1, 2).
- 200 % : icônes seules sans infobulle, libellé tronqué, débordement à 320 (MA-R M1, SALLE-200-1/2).
- Focus clavier non rendu à la fermeture d'un panneau (CL-R §3).
- Textes en dur, genre en dur, « admin » visible, mot technique (K-41, K-53).
- Échec qui affirme un non-envoi : dire « non confirmé », la cause et la suite (K-59, D5).
- Données de démonstration incohérentes entre écrans : une seule source par entité (EN-R M7).

## 9. Règles du chantier (TB1 à TB30)

Chaque règle cite le plan V2. Elles s'ajoutent à R1–R21 (K-40), E1–E20 (K-43), DESIGN-GOV et K-42.

1. **TB1** Salle existante gardée ; on améliore seulement l'élément concerné, captures avant et après (§1, §13, §21).
2. **TB2** Une seule surface et une seule bibliothèque, ouverte dans la salle sans changer de connexion ; un seul support présenté à la fois (§2, §8).
3. **TB3** Trois affichages partagés, un clic chacun : Support, Avec notes, Tableau. Masquer ne supprime rien (§2, §3).
4. **TB4** Tableau : feuille claire, même repère et même ratio que la page ; jamais étirée ; pan et zoom ; pas de canevas infini (§3).
5. **TB5** Ranger n'efface pas. Le tableau libre revient ; les traits du support n'y sont jamais copiés. Pas de confirmation ; « Support rangé » discret côté enseignant (§2, §3).
6. **TB6** Remplacer : prévisualisation personnelle, la classe garde l'ancien jusqu'à « Présenter » ; jamais une page vide ; erreur avec « Réessayer » et « Revenir aux supports » (§3, §12).
7. **TB7** Visio = Micro, Caméra, Quitter, dans cet ordre, hors de « Commandes », jamais dans un menu. Révélée au toucher, au mouvement de souris, au Tab ; masquée après 4 s seulement sans survol, focus, panneau ni lecteur d'écran (§4.1, §18.1).
8. **TB8** La révélation ne vole pas le geste : un contact commencé sur le contenu ne devient jamais un clic sur Quitter ; la barre se pose par-dessus, sans relayout (§18.2, UX-03).
9. **TB9** Pédagogie seulement derrière « Commandes » : feuille au-dessus de la zone visio sur mobile, panneau droit sur bureau. Un seul panneau secondaire ouvert sur mobile ; Commandes et Bibliothèque partagent le panneau droit (§4.2, §17, §18.3).
10. **TB10** Outils : Pointeur, Écrire → Stylo, Surligner, Gomme (par trait), Annuler ; Couleur et Épaisseur en choix courts ; sur téléphone, panneau fermé = palette courte (outil, Annuler, Terminer) (§4.2, §7).
11. **TB11** Pendant le partage, capsule compacte : avatar statique, témoin d'enregistrement réel, œil ; ni nom, ni réseau ; cibles de 48. Toucher la capsule ouvre le panneau existant ; l'œil l'ouvre à la section contrôle (§4.3, §19.6).
12. **TB12** L'œil informe, il ne donne aucun droit : « Contrôle possible » ou « Contrôle actif » selon la donnée, sinon rien. Pas de point rouge sans enregistrement réel. Les notices obligatoires survivent au focus (§4.3, UX-12).
13. **TB13** L'enseignant dirige automatiquement support, page et affichage : aucun bouton « Suivre » ; le zoom reste local (§1, §5, §8).
14. **TB14** L'élève ne voit ni Ranger, ni les trois affichages, ni la page partagée, ni Présenter. Écrire seulement après autorisation explicite et par choix volontaire ; Gomme et Annuler portent sur ses propres traits (§5, §19.3).
15. **TB15** L'autorisation d'écrire se donne sur la ligne de l'élève dans Participants ; une seule gestion des participants (§4.3, §12).
16. **TB16** Observateurs (tuteur, contrôleur) : présentation en lecture seule, aucune commande de dessin, de page ou de rangement ; règles du rôle inchangées (§5, UX-21).
17. **TB17** Bureau développé équilibré : Participants à gauche, surface au centre, Commandes à droite si ouvertes ; aucun panneau vide. Focus replie les deux ; Commandes en focus n'ouvre que la droite (§6, §18.3, §19.4).
18. **TB18** Focus local, jamais diffusé ; « Quitter le focus » toujours atteignable ; sortie = composition précédente si elle tient (§6, §18.1, §20).
19. **TB19** Géométrie : page normalisée après `BoxFit.contain` et transformation inverse du zoom ; geste hors page rejeté ; image et encre transformées ensemble ; l'épaisseur suit la page, les poignées non (§9).
20. **TB20** Pas d'encre libre sur un texte qui se recompose (verset agrandi) : marqueurs existants (§9).
21. **TB21** Gestes : un doigt dessine seulement en Écrire, deux doigts déplacent ; le stylet écrit s'il est détecté (`PolitiqueSaisie`) ; pas de tour de page par balayage pendant un trait (§7).
22. **TB22** Textes du §12 et du §20 mot pour mot, par clés i18n ; Sayyid ou Sayyida selon le profil ; « Séance en direct », jamais « Cours en cours » (§5, §20).
23. **TB23** Aucun faux succès : jamais « Sauvegardé » sur un envoi ; en démonstration « Les notes sont conservées dans cette séance uniquement. » ; ce qui est simulé est marqué (§11, §12, §22).
24. **TB24** Synchronisation honnête : « Vos nouvelles notes ne sont pas partagées. », « Le tableau se reconnecte. », écriture suspendue jusqu'à la reprise ; en démonstration, des situations nommées (§10, §12, §19.5).
25. **TB25** Accessibilité : 48 dp (avatar et œil compris), contraste AA, texte 200 %, focus visible, état jamais par la seule couleur ; Échap ferme le panneau le plus récent, puis le focus, jamais l'appel (§6, §18.3).
26. **TB26** Mouvement : rangement 180 à 250 ms par `lib/core/mouvement` ; mouvement réduit = fondu ou immédiat ; pulsation d'enregistrement lente, fixe si réduit ; aucun état ne dépend d'une animation (§3, §6, K-12).
27. **TB27** Coran : rendu intouché, jamais inversé en sombre ; calque au-dessus seulement (§6, §11).
28. **TB28** Ne pas construire : CRDT, serveur de tableau, canevas infini, OCR, gomme au pixel, replay, plusieurs enseignants, nouvelle navigation, réglages techniques pour les élèves (§13).
29. **TB29** Mode Accessibilité : commandes de MA-CMD-1 (icônes seules, nom lu et en infobulle, masquables), mot d'état des bascules gardé ; tutoiement selon l'âge (A4) (§4.2 corrigé par MA-CMD-1).
30. **TB30** Devoir de regard : une instruction fausse est contredite avec preuve, jamais corrigée en silence ; statuts autorisés : spécifié, présent dans le code, testé localement, bloqué, non vérifié (§22).

## 10. Outils

- Commandes lourdes : toujours par `flutter-verrou.ps1`, une seule à la fois ; tests par dossiers (K-61 n° 6).
- Démonstration : `/demo/salle?role=…&tb=<situation>` (TB-1b), gardée par `environnementAutoriseDemo`.
- Captures : `test/capture/outil_capture.dart`, nouveau squelette `test/features/tb_recette/captures_tb_test.dart`.
