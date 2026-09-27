# Vague Contrôleur : reprise (lire ceci d'abord)

1. **Décisions du directeur du 27/09** : `projet/ressources:specs/08_controleur/00_DECISIONS_DIRECTEUR.md`. Elles priment sur tout : la visite a lieu **pendant le cours** ; le rapport est **transmis automatiquement** à l'administration, le bouton sert seulement à lui écrire directement.
2. **Règles** : `projet/ressources:memoire/CONTROLEUR-2026-09-27.md` (C1 à C21). Elles s'ajoutent à DESIGN-GOV, à K-42 (style CL-4) et à CLASSE-ENTREE (R1 à R21, le contrôleur entre dans la salle).
3. **Planches et rectifications** : `14_controleur/V/00_MAQUETTES_CONTROLEUR.md` (G garder, P prendre, C corriger ; ce qui touche d'autres rôles).
4. **Étapes** : `14_controleur/02_DECOUPAGE.md` (CT-0 à CT-RC), avec le tableau de suivi, vague « Contrôleur ».
5. **Code** : branche proposée `ui/controleur-v1`, depuis la pointe de `ui/enseignant-v1` (1108a4a au 27/09), worktree `C:\RA\controleur` à créer en CT-1b. Ne jamais travailler dans `C:\RA\enseignant`.
6. **Document source** : `projet/ressources:specs/08_controleur/08_CONTROLEUR_V1_UX_SECURITE.md` (1 072 lignes). Ne le lire que par section, à la demande de l'étape (§ indiqué).

**Inventaire de l'existant (27/09, lecture seule, `ui/enseignant-v1` @ 1108a4a).**

| Élément | Fichier | État |
|---|---|---|
| CTR-01 Planning du contrôle | `lib/features/controleur/planning_page.dart` (498 l.), `vue_planning.dart` (255 l.) | Planning **global** de toutes les séances (heure locale et UTC, borne 200 séances), lecture `mes_seances_v`. Contredit C1 et C3 : à refondre (CT-2). |
| Service | `lib/core/controle/service_controle.dart` (72 l.) | `ServiceControle.planning()` ; grâce de 15 min après la fin (ADR-005). |
| Route | `lib/core/router/routes.dart:335` `Routes.controleur = '/controleur'` ; `app_router.dart:793` | Une seule destination, sans barre de navigation. |
| Coquille | `lib/core/widgets/nav_shell.dart:151-161` | « Le contrôleur observe et signale : une seule destination ». À remplacer par 4 destinations (C13). |
| CTR-02 Salle | `/salle` : `lib/features/salle/vue_salle.dart:60` (`masked_controller` → `RoleSalle.controleur`), `salle_page.dart:726` (rappel), `:1388` (libellé muet) | Observation sans micro ni caméra ; rappel « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » (`fr.i18n.json:427`). À garder. |
| Préflight | `lib/features/tc_classe_live/pre_vol_classe.dart:76` | Le rôle contrôleur y est déjà traité (pas de micro ni caméra). |
| Compte, Espaces | `lib/features/compte/compte_page.dart:718-760` (`_espacesPour`) | Un seul rôle effectif par session ; pas de commutation Enseignant ou Admin → Contrôle (besoin serveur, BR-1). |
| Porte tuteur | `lib/features/tc_observation_ui/`, `/tc/observation/:seanceId` ; `lib/core/tc_observation/` | Au tuteur seulement. Ne pas en faire un second système contrôleur (doc §2.1). |
| Démonstration | `lib/features/demo/` (`demo_salle_page.dart`, `enseignant_demo.dart`, `demo_enseignant_page.dart`, `observation_demo.dart`, `mode_demonstration.dart`) | Aucune démonstration contrôleur. |
| Admin (révision 2fac423, `ui/admin-v1`) | `admin_observations/observations_admin_page.dart`, `admin_tableau/` | Historique des observations (MAN #26). Aucun rapport contrôleur, aucun fil d'échanges. Branche non fusionnée (`13_fusion`). |
| Composants | `lib/core/widgets/` : `PageParcours`, `PageEtape`, `PageImmersive`, `ChoiceCardGroup`, `GroupeReglages`, `LigneCleValeur`, `EcranResultat`, `EtatSysteme`, `DataCollection`, `FilterPill`, `MenuFiltre`, `StatusPill`, `PermanentNotice`… ; `PhotoEnseignant` (`tc_mes_groupes/photo_enseignant.dart`), `PhotoEleve` (`foyer/photo_eleve.dart`) | Tous présents. |

**Ce qui manque** :
- la mission automatique pendant la séance en direct (CTR-01 refondu) ;
- les commandes Son reçu et Agrandir le support dans la salle contrôleur ;
- CTR-03 Compte rendu, CTR-03A Observation, CTR-03B Complément ;
- CTR-04 Échanges : **aucun composant de fil de discussion n'existe** dans `lib/` ;
- CTR-05 Historique et CTR-06 Détail ;
- la navigation à 4 destinations et la commutation d'espace ;
- les données et la route de démonstration `/demo/controleur` ;
- tout le serveur (BR-1) : capacité, missions, faits, rapports, fils, audit.

**Outils de capture** :
- `test/capture/outil_capture.dart` ;
- modèle : `test/features/enseignant_recette/captures_en_test.dart` et `navigation_reelle_test.dart`.

**Hors lot** : le contrôleur invité (planche 5, doc §1.3) ; la synthèse mensuelle enseignant (doc §12) ; les écrans Admin (doc §13) ; le chrono (LIVE-CHRONO-01).
