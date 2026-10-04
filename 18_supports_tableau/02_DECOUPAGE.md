# Supports et tableau dans la salle : découpage en étapes (TB-0 à TB-RC)

## Où et comment

- **Branche** `ui/supports-tableau-v1`, **worktree** `D:\RA_TUTEUR\tableau`, créés par TB-F depuis `origin/corrections/revue-directeur-2026-10` (raison : `00_REPRISE.md` §3).
- **Un seul agent qui committe à la fois** dans le worktree (K-30) ; tâches de moins de 35 minutes (K-16) ; prompt qui commence par la garde K-17.
- **Modèles** (K-15) : Opus pour le design, le code d'écran et la revue ; Sonnet pour les tests, captures et preuves ; Haiku pour le tableau.
- **Démonstration d'abord** (K-35), sans serveur (K-28) : les ports réels restent en place, la démonstration les surcharge. Le temps réel passe par `TransportMemoire` et `AnnotationsMemoire` existants ; rien n'est envoyé à LiveKit. Chaque besoin serveur = une ligne de `TB-BR.md`.
- **Lire avant chaque étape** : `00_REPRISE.md` (§4 existant, §9 règles TB1–TB30), puis seulement les § du plan cités par l'étape.

### Définition de « fait » (K-07, commune à toutes les étapes d'écran)

1. L'état est atteint depuis `lib/main.dart` : vraie coquille → `/demo/salle` → situation TB ; un test de widget **tape le vrai bouton** (Commandes, Bibliothèque, Présenter…) depuis cette coquille, jamais une page montée seule.
2. `dart analyze --fatal-infos` à 0 ; tests des dossiers touchés, un dossier à la fois par le verrou, relancés après la dernière correction (K-29, K-61 n° 6).
3. Captures 390×844, 768×1024 et 1440×900, clair et sombre, plus texte ×2 (200 %) aux trois tailles, et 320 px ×1 et ×2 pour la salle (SALLE-200-1/2).
4. Pour chaque étape qui touche ce que voient plusieurs profils : captures **enseignant ET élève**, et **Mode Accessibilité** (élève guidé) quand l'étape le concerne ; observateur quand l'étape le dit.
5. Aucun texte en dur (K-41) ; RTL forcé sans débordement (K-41 n° 12) ; mouvement réduit couvert quand il y a une animation.
6. L'orchestrateur ouvre lui-même les captures du **même état** que la planche citée avant de passer « fait » (K-61 n° 1, 2).

## Les étapes

| Ordre | Étape | Titre | Dépend de | Modèle, durée |
|---|---|---|---|---|
| 1200 | **TB-0** | Préparation : copie des sources, inventaire, contrôle des planches, règles TB1–TB30, découpage, TB-BR, questions | — | **fait** (02/10) |
| 1201 | **TB-1a** | UX_REVIEW et revue critique avant code (L0, §22) | TB-0 | Opus, 35 min |
| 1202 | **TB-F** | Branche et fusion préalable de `ui/accessibilite-v1` | TB-0, SALLE-200-1, SALLE-200-2, réponse Q2 | Opus, 35 min (×2 si besoin) |
| 1203 | **TB-1b** | Socle : modèle d'affichage, données et route de démonstration, squelette de captures | TB-F | Opus, 35 min |
| 1204 | **TB-2** | Visio révélée au toucher, à la souris et au clavier (L1) | TB-1a, TB-1b | Opus, 35 min |
| 1205 | **TB-3** | Capsule compacte et contexte enseignant (L1) | TB-2 | Opus, 35 min |
| 1206 | **TB-4** | Bouton « Commandes » et panneau pédagogique (L1, L2) | TB-2, réponse Q1 | Opus, 35 min |
| 1207 | **TB-5** | Bureau équilibré, tablette et focus local (L2) | TB-3, TB-4 | Opus, 35 min |
| 1208 | **TB-6** | Surface : page fixe, trois affichages, tableau libre (L3) | TB-4 | Opus, 35 min |
| 1209 | **TB-7a** | Calque d'annotation au repère de la page (géométrie, L3) | TB-6 | Opus, 35 min |
| 1210 | **TB-7b** | Écrire : outils, options, palette courte, gestes (L3) | TB-7a | Opus, 35 min |
| 1211 | **TB-8** | Bibliothèque en séance : catalogue, prévisualisation, Présenter, erreurs (L4) | TB-4 | Opus, 35 min |
| 1212 | **TB-9** | Ranger, reprendre, effacer les notes (L4) | TB-6, TB-8 | Opus, 35 min |
| 1213 | **TB-10** | Élève, Mode Accessibilité et autorisation d'écrire (L5) | TB-5, TB-7b | Opus, 35 min |
| 1214 | **TB-11a** | Observateurs en lecture seule (L5) | TB-6 | Opus, 30 min |
| 1215 | **TB-11b** | États de synchronisation et de conservation (L6) | TB-7b, TB-9 | Opus, 30 min |
| 1216 | **TB-12** | Recette (L7) | TB-2 à TB-11b | Sonnet, 35 min (×2 agents) |
| 1217 | **TB-R** | Revue croisée par une autre session | TB-12 | Opus, 30 min |
| 1218 | **TB-RC** | Corrections de la revue et planche web | TB-R | Opus, 35 min |

## Détail des étapes

### TB-1a — UX_REVIEW et revue critique (document seulement)
- **Lire** : plan §17, §21, §22, §23 ; `10_classe/UX_REVIEW_CL-4.md` (modèle), `UX_REVIEW_CL-7.md` ; `00_REPRISE.md` §4 à §6 ; les 8 planches.
- **Produire** `18_supports_tableau/UX_REVIEW_TB.md` :
  1. sources officielles datées (WCAG 2.2 : 2.4.11, 2.5.8, 1.4.4, 1.4.10, 4.1.3, 2.3.3 animation ; Flutter `applyBoxFit`, `TransformationController.toScene`, `CustomPainter` ; NN/g) ; GOV.UK exclu ;
  2. une ligne par disposition des planches (conforme, ajustée, dérogation du directeur) ;
  3. la matrice §22.3 : chaque exigence = conforme / contradiction / capacité manquante / non vérifiable, avec preuve ;
  4. le mapping de l'arbre §17 (SAL-00 à END-01) vers fichiers réels, sans classe supposée ;
  5. le plan de diff : fichiers gardés, modifiés, ajoutés, et pourquoi ; toute duplication signalée avant d'être créée.
- **Fait** : fichier écrit et poussé au pilotage ; chaque ligne problématique nomme l'exigence, la preuve et la correction minimale ; aucune règle R1–R21, E1–E20, TB1–TB30 réinterprétée.
- **Pièges** : ne pas « valider » une planche contre le plan sans la regarder ; Q1 tranchée ou non, écrire les deux variantes du panneau.

### TB-F — Branche et fusion préalable
- **Lire** : `00_REPRISE.md` §3 ; `13_fusion/PLAN_FUSION_ADMIN_ENSEIGNANT.md` (méthode) ; MA-CMD-1, MA-TITRE-1 au tableau.
- **Faire** : créer `ui/supports-tableau-v1` et `D:\RA_TUTEUR\tableau` ; si Q2 = oui, `git merge --no-ff origin/ui/accessibilite-v1` ; ~~12 conflits attendus~~ (sans objet depuis INTEG-RC-1, compte corrigé : 14) (`dock_seance.dart`, `nav_shell.dart`, `page_shell.dart`, `setting_row.dart`, `groupe_reglages.dart`, `compte_page.dart`, `demo_accessibilite_page.dart`, `module_reglages_observation.dart`, slang générés, 4 tests) ; union des deux intentions, slang régénéré par le verrou, jamais à la main.
- **Fait** : aucun marqueur de conflit ; analyze 0 ; dossiers `test/core`, `test/features`, `test/accessibilite`, `test/widgets` verts, cités ; `salle_200_test.dart` vert ; captures 390 ×1 et ×2 de la salle élève, guidée, enseignant identiques à celles des deux branches d'origine (relues). Poussé sur la branche TB seulement.
- **Pièges** : ne jamais fusionner dans `main` ni dans `corrections/…` ; ETATS-BTN-1 (3 signaux d'état) et MA-CMD-1 (icônes seules en MA) doivent survivre ensemble dans `dock_seance.dart`.

### TB-1b — Socle
- **Lire** : plan §2, §8 (trois états), §12, §17 ; `vue_seance.dart`, `demo_salle_page.dart`, `seance_demo.dart`, `outil_capture.dart`.
- **Faire** :
  1. dans `VueSeance` (données pures), un affichage partagé `support | avecNotes | tableau`, le support présenté (id, version, page, total), l'état du tableau libre, les droits d'écriture par élève ; **sans toucher** `ModeAffichagePartage` (contrat de base, TB-BR) ;
  2. un support démo à **page fixe** (image de page neutre « Support illustratif », ratio canonique fourni par les données ; aucune page de Coran fabriquée) ;
  3. données de démonstration : Classe An-Nour, Sayyid par défaut (K-42), 4 élèves avec photo (K-44), un élève « Peut écrire » ; une seule source pour toutes les étapes ;
  4. route `/demo/salle?role=…&tb=<situation>` (une situation nommée par état du §12 et par vue du §17), gardée par `environnementAutoriseDemo` ;
  5. la constante de 4 s rangée avec les constantes UI existantes (`CommandesMasquables.delaiParDefaut`), pas une seconde valeur ;
  6. squelette `test/features/tb_recette/captures_tb_test.dart`.
- **Fait** : chaque situation s'ouvre depuis la liste de `/demo/salle` (test qui tape) ; analyze 0 ; aucune disposition nouvelle à l'écran (peut tourner en parallèle de TB-1a).
- **Pièges** : ne pas créer de second modèle de séance ; `SupportSeance` (diapositive) reste pour l'existant.

### TB-2 — Visio révélée (VIS-01)
- **Lire** : plan §4.1, §18, UX-01 à UX-09, UX-23 ; `CommandesMasquables` ; `DockSeance`, `_BarreBasse`, `BoutonAppel`.
- **Faire** : la barre Micro, Caméra, Quitter dans `CommandesMasquables` pour l'élève, la guidée et l'enseignant, sur tous les gabarits : révélée au toucher (sans consommer le geste), au mouvement de souris, au Tab (« Commandes de l'appel ») ; maintenue au survol, au focus, panneau ouvert, lecteur d'écran, erreur critique ; par-dessus le contenu, sans relayout ; couche au-dessus des feuilles et scrims (UX-07). Agrandir et Réseau quittent la barre (Focus passe dans Commandes en TB-4 ; Réseau reste un indicateur, D5).
- **Fait** : K-07 ; tests UX-01 à UX-06 et UX-08 (dont un geste commencé sous la future barre qui n'active pas Quitter) ; captures repos et révélée, enseignant, élève, MA.
- **Pièges** : `CommandesMasquables` évolue de façon additive (survol souris, entrée Tab) sans copie ; les 3 signaux d'ETATS-BTN-1 restent ; Quitter jamais masqué au clavier ; micro interdit jamais rendu actif par la révélation.

### TB-3 — Capsule compacte et contexte (UI-01, CTX-01, CTX-02)
- **Lire** : plan §4.3, §19.6, §20 (avatar, œil, enregistrement), UX-10 à UX-12 ; `ChromeSeance`, `MentionSeance`, `PointDirect`, `IndicateurObservation`, `TuileSansImage`, `VignetteVideo`.
- **Faire** : pendant le partage, capsule en haut (avatar statique, point d'enregistrement réel, œil si la donnée existe) à la place de la vignette ; toucher l'avatar ouvre le contexte enseignant dans le panneau de personnes existant, l'œil l'ouvre à la section contrôle ; « Réduire » revient à la capsule. Hors partage, la vignette actuelle reste.
- **Fait** : K-07 ; tests : pas de point rouge quand l'enregistrement est inactif ou inconnu, noms accessibles du §20, cibles ≥ 48 ; captures enseignant, élève, MA (notice d'observation de l'enfant visible).
- **Pièges** : absorbe PT-B-20260927-cfbdb7a5 (pile de la vignette à 150 %) ; ne pas fabriquer « Contrôle actif » ; CTRL-SALLE-1 : pas de notice « visite de contrôle » au contrôleur lui-même.

### TB-4 — « Commandes » et panneau pédagogique (CMD-01)
- **Lire** : plan §4.2, §6, §18.3, §20 ; planches 1, 2, 6, 8 ; `PanneauSeance`, `OutilsEnseignement`, `PaginationSupport`, `ZoomLocal`, `_FocusPanneaux`.
- **Faire** : un seul déclencheur « Commandes » (mobile près du bas, au-dessus de la zone visio ; bureau, bord droit). Panneau : Bibliothèque en premier ; contexte du support (miniature, titre, menu du titre) ; Support / Avec notes / Tableau (invisible sans support) ; « Page {numéro} sur {total} » avec Page précédente, Page suivante ; Lecture (Ajuster à l'écran) ; Affichage (Focus) ; outils (structure selon Q1). Mobile : feuille temporaire, un seul panneau secondaire ; bureau : panneau droit repliable. « Réduire » ferme ; Échap ferme puis rend le focus.
- **Fait** : K-07 ; un clic par changement d'affichage (test) ; rien de l'enseignant chez l'élève (test par rôle) ; RTL : chevrons et noms des pages vérifiés ; captures fermé et ouvert.
- **Pièges** : pas d'onglet Visio ; outils jamais permanents ; marqueurs et masquer des versets conservés sous leur entrée.

### TB-5 — Bureau équilibré, tablette et focus (UI-02, UI-03)
- **Lire** : plan §6, §18.3, §19.4, UX-13 à UX-16, UX-24 ; planches 3, 4, 7, 8 ; `PanneauEleves`, `FormePanneau`.
- **Faire** : bureau développé : Participants compact à gauche (états micro, droit d'écrire), surface dominante, Commandes à droite seulement si ouvertes ; tablette : Participants si la largeur suffit, sinon temporaire ; Focus replie les deux côtés et la grande vidéo, garde capsule, Commandes et « Quitter le focus » ; sortie = composition précédente si elle tient ; décision sur la largeur de fenêtre divisée par le facteur de texte (UX_REVIEW_CL-4 n° 20).
- **Fait** : K-07 ; tests UX-14, UX-15, UX-16 ; aucune colonne vide ; captures 768 et 1440 développé et focus, ×1 et ×2.
- **Pièges** : ne pas reproduire le bureau surchargé ; focus jamais diffusé ; aucune reconnexion forcée au changement d'orientation.

### TB-6 — Surface : trois affichages et tableau libre (PED-01 à PED-04)
- **Lire** : plan §2, §3, §6 (dernier alinéa), §9, §12 (aucun support) ; `ZoneSupport`, `_RienPartage`.
- **Faire** : page fixe en `BoxFit.contain` dans `ZoneSupport` ; Support (calque caché), Avec notes, Tableau (fond masqué, feuille claire au même ratio, notes visibles) ; tableau libre quand aucun support (« Choisissez un support ou écrivez au tableau. » côté enseignant ; élève : tableau sans consigne technique).
- **Fait** : K-07 ; test : masquer puis réafficher garde les traits ; capture des trois affichages, enseignant et élève, clair et sombre (page jamais inversée).
- **Pièges** : aucune déformation ; marges de placement hors repère ; le Mushaf n'entre pas dans cette étape.

### TB-7a — Calque au repère de la page
- **Lire** : plan §7, §9, §13 (lignes géométrie) ; `CoucheAnnotation`, `PointNormalise`, `TraitEnCours`, `simplifierTrait`, `AnnotationsMemoire`.
- **Faire** : monter `CoucheAnnotation` au-dessus de la page, une page = un bloc ancré couvrant la page ; conversion point → `toScene` (inverse zoom/pan) → retrait de l'offset `applyBoxFit` → normalisation ; gestes hors page rejetés ; image et encre dans la même transformation ; épaisseur relative à la page.
- **Fait** : tests unitaires : même point normalisé à 390, 768, 1440, zoom 1 et 2, portrait et paysage ; geste en marge rejeté ; un cercle reste sur le même endroit de la page après zoom (capture).
- **Pièges** : jamais le Stack extérieur comme repère ; `PointNormalise` n'est pas modifié (contrat de base) ; rien n'est stocké en pixels.

### TB-7b — Écrire (CMD-02, CMD-03)
- **Lire** : plan §4.2, §7, §19.1, §20 (outils, options) ; `BarreStylet`, `PolitiqueSaisie`, `OutilsEnseignement`.
- **Faire** : Pointeur (temporaire, sans trace), Écrire → Stylo, Surligner, Gomme par trait, Annuler (dernière opération personnelle) ; Couleur et Épaisseur en choix courts lisibles par forme, texte et couleur (couleurs des jetons existants seulement) ; téléphone : panneau fermé → palette courte (outil actif, Annuler, Terminer) ; Terminer revient à la lecture ; changement de page pendant un trait = trait résolu dans son contexte.
- **Fait** : K-07 ; tests : un doigt ne dessine qu'en Écrire ; le stylet n'écrit que si Écrire est actif (TB21) ; deux doigts déplacent ; Annuler ne retire pas le trait d'un autre ; captures palette courte 390, panneau ouvert 1440 et « le stylet n'écrit que si Écrire est actif » (trait au stylet refusé en lecture).
- **Pièges** : pas de nouvelle couleur (TH-2) ; pas de perfect_freehand (pubspec interdit) ; repaint ciblé, traits terminés mis en cache (§13).

### TB-8 — Bibliothèque en séance (LIB-01 à LIB-04)
- **Lire** : plan §3 (remplacer), §12 (catalogue), §19.1, UX-17 ; `PanneauSupports`, `SelecteurRessources`, `VueCatalogue`, `ClassLibraryPicker`, R14.
- **Faire** : la Bibliothèque remplace le contenu du panneau droit (ou de la feuille) ; recherche, cartes, vide (« Aucun support ne correspond à votre recherche. », « Effacer la recherche ») ; carte → prévisualisation personnelle, la classe garde l'ancien ; « Présenter » → « Ouverture du support… » puis activation d'un bloc (support, page, affichage) ; échec : « Ce support ne peut pas être ouvert. », « Réessayer », « Revenir aux supports », ancien support intact.
- **Fait** : K-07 ; tests UX-17 et « fichier non chargé ne remplace jamais » ; captures catalogue, prévisualisation, chargement, erreur.
- **Pièges** : aucune seconde bibliothèque : on réutilise le catalogue et la rubrique Récents existants ; libellé « Bibliothèque » par clé i18n.

### TB-9 — Ranger, reprendre, effacer
- **Lire** : plan §2 (tableau des actions), §3 (ranger), §12 (effacement), §19.2, UX-18, UX-19, UX-22.
- **Faire** : « Ranger dans la bibliothèque » dans le menu du titre ; copie visuelle qui rejoint la carte ou le bouton Bibliothèque (180 à 250 ms, `lib/core/mouvement`, fondu ou immédiat si mouvement réduit) ; tableau libre au premier plan, distinct ; carte avec point de reprise ; « Présenter » restaure page et notes de la séance ; « Effacer les notes » avec `ConfirmDestructive` (« Effacer toutes les notes de cette page ? » / « … du tableau ? », « Annuler », « Effacer les notes »).
- **Fait** : K-07 ; tests UX-18, UX-19, mouvement réduit ; captures avant et après rangement.
- **Pièges** : l'état change indépendamment de l'animation ; aucune confirmation pour ranger ; aucun toast aux élèves.

### TB-10 — Élève, Mode Accessibilité, autorisation d'écrire (PER-01)
- **Lire** : plan §5, §12 (autorisation, droit retiré), §19.3, UX-20 ; K-44 ; MA-CMD-1, MA-5 ; `PanneauEleves`.
- **Faire** : Commandes de l'élève (lecture, ajuster, focus, Écrire seulement si autorisé) ; « Autoriser à écrire » / « Retirer l'autorisation d'écrire » sur la ligne de l'élève ; information courte « Tu peux écrire sur le tableau. » (enfant) ou « Vous pouvez écrire sur le tableau. » (adulte, selon l'âge, A4) ; Stylo, Gomme, Annuler, Terminer ; retrait : « Sayyid reprend le tableau. » ou « Sayyida … », outils retirés, trait en cours résolu dans son contexte ; Mode Accessibilité : commandes de MA-CMD-1.
- **Fait** : K-07 ; tests par rôle (élève, guidée, enseignant) ; UX-20 ; captures élève standard, MA (390 ×1 et ×2), enseignant avec l'élève autorisé.
- **Pièges** : écrire n'ouvre aucun droit de page ou de support ; les gestes de lecture ne deviennent jamais des traits.

### TB-11a — Observateurs en lecture seule
- **Lire** : plan §5 (tableau des profils), UX-21 ; `SallePage` (`salle_page.dart:79`, `_CommandesControle` `:1000`), CTRL-SALLE-1.
- **Faire** : tuteur observateur et contrôleur voient la présentation (support, page, affichage, notes) en lecture seule dans `/salle`, par réutilisation de `ZoneSupport` ; leurs commandes et notices restent celles du rôle.
- **Fait** : K-07 ; test : aucune commande d'écriture, de page ou de rangement pour ces rôles ; captures tuteur et contrôleur, 390 et 1440.
- **Pièges** : la mention de visite n'est pas montrée au contrôleur ; SALLE-200-1/2 ne doivent pas régresser (texte ×2, 320).

### TB-11b — Synchronisation et conservation (ERR-01 à ERR-03)
- **Lire** : plan §10 (règles côté interface), §11, §12 (lignes réseau et sauvegarde), §19.5, K-59, D5.
- **Faire** : situations de démonstration : « Vos nouvelles notes ne sont pas partagées. » (enseignant, traits non partagés marqués), « Le tableau se reconnecte. » (élève), « Reprise du tableau… » / « Le tableau revient. », écriture suspendue pendant la reprise ; « Les notes sont conservées dans cette séance uniquement. » dans le contexte de conservation de l'enseignant ; « Les notes de cette séance ne sont pas sauvegardées. » sans « Réessayer » tant que le contrat durable n'existe pas.
- **Fait** : K-07 ; test : aucun « Sauvegardé » nulle part (recherche dans le code et les clés) ; captures des quatre états.
- **Pièges** : l'audio n'est jamais interrompu par une erreur de panneau ; pas de notification par trait ; arrivée tardive = état actuel, aucun bouton Suivre.

### TB-12 — Recette
1. Tests depuis la vraie coquille pour chaque bouton du lot.
2. Les scénarios du §15 et UX-01 à UX-24 du §23, un test chacun quand la démonstration le permet ; les autres marqués « non vérifiable sans BR-1 » (réseau, reconnexion réelle, mémoire sur appareil, iPad vers téléphone).
3. Captures 390, 768, 1440, clair et sombre, ×1 et ×2, 320 ×1 et ×2, RTL forcé, mouvement réduit ; enseignant, élève, MA, tuteur, contrôleur.
4. Rapport `05_recette/TB/TB_RAPPORT.md` en français simple, matrice de preuve avec les statuts du §22 ; `TB-BR.md` complété.
- **Pièges** : une capture ne prouve pas le réseau (§22) ; ne pas retirer une assertion pour verdir.

### TB-R — Revue croisée
Par une session qui n'a écrit aucun code TB (K-60 n° 4) : contre TB1–TB30, R1–R21, E1–E20, DESIGN-GOV (contrats A à E), K-42, K-54 à K-59, le §22 (points contradictoires) et la recette §15/§23. Modèle `05_recette/CL/REVUE_CL-4.md`. Résultat `05_recette/TB/REVUE_TB-R.md`.

### TB-RC — Corrections et planche
Corrections de la revue, puis planche web du directeur (format CL-4 : Téléphone, Tablette, Ordinateur ; Clair, Sombre ; trois points simples par écran ; cas particuliers en bas), publiée par l'orchestrateur. « Corrigé selon votre remarque » seulement après avoir ouvert la capture (K-61 n° 9).

## Étapes déjà au tableau

| Étape existante | Sort | Raison |
|---|---|---|
| PT-B-20260927-cfbdb7a5 « Harmonisation : carte du support en pile » | **Absorbée par TB-3**, à fermer comme doublon une fois TB-3 vérifiée | La capsule remplace la vignette pendant le partage (§4.3) ; la pile à 150 % est redéfinie là. |
| LIVE-CHRONO-01 | Séparée | Chrono discret de l'en-tête, reporté par le directeur ; la capsule ne doit pas lui retirer sa place future. |
| LIVE-PAUSE-01 | Séparée | Fonction distincte, attend une décision. |
| CONTRASTE-SUPPORT-1 | Séparée (attend TH-2) | Couleurs interdites (K-37). TB-6 ne doit pas aggraver ; si le défaut reparaît, une note sur cette ligne. |
| PT-B-20260927-1ab2a969 « lisibilité de la salle » | Séparée (HU-1) | Couleurs de `salle_page.dart` ; hors périmètre, TB-11a ne la rouvre pas. |
| SALLE-200-1, SALLE-200-2 | Séparées, **préalables** à TB-F | Même branche de base et mêmes fichiers (`page_immersive.dart`, `salle_page.dart`) : finir avant de brancher. |
| VIDEO-TUILE-1 | Séparée, préalable (`TuileSansImage` réutilisé en TB-3) | Déjà fusionnée dans la base. |
| ETATS-BTN-1 | Séparée (faite) | Contrainte pour TB-2 : garder ses trois signaux. |
| CTRL-SALLE-1 | Séparée (faite) | Contrainte pour TB-3 et TB-11a. |
| MA-5 | Séparée (faite) | Contrainte pour TB-10 (A4, A6 revue par le §4.3). |
| MA-CMD-1 | Séparée (faite) | Réutilisée par TB-2 et TB-10 via TB-F. |
