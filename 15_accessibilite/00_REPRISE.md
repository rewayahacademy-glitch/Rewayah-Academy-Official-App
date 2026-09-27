# Mode Accessibilité : reprise (lire ceci d'abord)

1. **Règles** : `projet/ressources:memoire/ACCESSIBILITE-2026-09-27.md` (MA1 à MA24). Elles s'ajoutent à DESIGN-GOV, à K-42 (style CL-4), à CLASSE-ENTREE (R1 à R21) et à ENSEIGNANT (E1 à E20) pour la salle.
2. **Planches et rectifications** : `15_accessibilite/V/00_MAQUETTES_ACCESSIBILITE.md` (comparaison G / P / C, rôles touchés, avis sur le doc).
3. **Étapes** : `15_accessibilite/02_DECOUPAGE.md` (MA-0 à MA-RC), avec les questions Q1 à Q11 et leurs choix provisoires ; tableau de suivi, collection `etapes`, vague « Mode Accessibilité ».
4. **Code** : branche proposée `ui/accessibilite-v1`, depuis `ui/enseignant-v1` (1108a4a au 27/09), worktree `C:\RA\accessibilite`, à créer en MA-1b. Rien n'est encore créé.
5. **Document source** : `projet/ressources:specs/06_accessibilite/REWAYAH_06_RECHERCHE_MODE_ACCESSIBILITE_V1.md`. Ne le lire que par section, à la demande de l'étape (§ indiqué).

**Terme** : « Mode Accessibilité ». Ne plus écrire « mode enfant » ; « Interface guidée » est remplacé dans les textes visibles (MA-10). Le code garde `InterfaceMode.enfant` (SQL `child`).

**Inventaire de l'existant (27/09, lecture seule, `ui/enseignant-v1` @ 1108a4a).**

| Sujet | Fichier | État |
|---|---|---|
| Modèle du mode | `lib/core/domain/enums.dart` | `InterfaceMode.enfant` (« 6 à 8 ans, zéro lecture, pictogrammes, audio, 72 pt ») et `standard`. |
| Choix par le tuteur | `lib/features/foyer/fiche/interface_page.dart` | « Interface guidée » / « Interface standard » ; valeur `student_profiles.interface_mode`, fixée par l'âge, changée par le tuteur seul ; pas de bascule élève (DB-FOY-04). |
| Réglages | `lib/features/compte/compte_page.dart` (`/compte/reglages`) | Sections Apparence et Accessibilité ; « Réduire les animations » ; ligne « Mode enfant » pour les profils enfants. |
| Préférences locales | `lib/core/preferences/preferences_locales.dart` | `animationsReduites`, `effetsReduits`, `lectureGrande` (« Lecture en grand texte »), `raccourcisSalle` ; persistance locale. |
| Taille du texte | `app_typography.dart`, `MediaQuery.textScalerOf` dans une quinzaine de widgets | Suit le réglage de l'appareil ; replis à 1,3 et 1,5 dans `groupe_reglages`, `panneau_eleves`, `salle_seance`. |
| Mouvement | `lib/core/mouvement/` (`mouvement.dart`, `transitions.dart`, `apparition_douce.dart`, `bascule_etat.dart`) et `core/theme/app_mouvement.dart` | `Mouvement.duree` rend 0 si `MediaQuery.disableAnimations`. À vérifier : la préférence locale `animationsReduites` est-elle branchée dessus (MA-1a). |
| Lecteur d'écran | `Semantics` dans les widgets partagés | Tests existants : `test/accessibilite/` (clavier, RTL et échelle de texte). |
| Navigation élève | `lib/core/widgets/nav_shell.dart` | Standard : Accueil, Coran, Suivi, Compte. Mode enfant : **aucune destination**. |
| Accueil élève | `lib/features/accueil_eleve/accueil_eleve_page.dart` | « Deux blocs, rien d'autre » en mode enfant. |
| Classe et salle | `lib/features/salle/`, `salle_seance/` (`vue_seance`, `vignette_video`, `zone_support`, `resultat_seance`) | Variante guidée CLV-05 ; « deux commandes seulement » ; préparation guidée (« une question, une action »). |
| Observation | traductions `votreParentObserve`, `tonParentObserve` | Indication à l'enfant observé déjà écrite. |
| Coran | `lib/features/tc_mushaf/` | Rendu intouchable ; mode verset, feuille de navigation. |
| Aide | `lib/features/compte/aide_page.dart` | Honnête : aucun canal décidé (DB-CPT-07). |
| Démonstration | `/demo/classe`, `/demo/salle`, `/demo/enseignant` | Gardées par `environnementAutoriseDemo`. |

**Ce qui manque** :
- le nom « Mode Accessibilité » partout (textes) ;
- la navigation à 4 destinations dans le Mode Accessibilité ;
- l'Accueil, Ma classe, l'après-séance et Mon espace à l'ordre du doc 06 ;
- la bascule de l'élève adulte (démonstration ; serveur à BR-1) ;
- les contrôles de confort du Coran autour du rendu ;
- la route `/demo/accessibilite` et ses captures (dont 200 % et animations réduites).

**Outils de capture** :
- `test/capture/outil_capture.dart` ;
- modèles : `test/features/classe_recette/captures_cl47_test.dart`, `test/accessibilite/rtl_echelle_texte_ecrans_test.dart`.
