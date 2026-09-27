# CT-1m : carte de l'existant (contrôleur)

Lecture seule, worktree `C:\RA\controleur`, branche `ui/controleur-v1` @ `1108a4a` (pointe de `ui/enseignant-v1`, identique au 27/09). Aucune modification. Sources : `00_REPRISE.md`, `02_DECOUPAGE.md` (CT-1m), doc `08_CONTROLEUR_V1_UX_SECURITE.md` §17.2-3, code ci-dessous.

## Table 1 — CTR-01 à CTR-06 et fonctions transverses

| Fonction | Route | Fichier:ligne | Composant en place | État | Étape CT |
|---|---|---|---|---|---|
| CTR-01 Planning du contrôle | `/controleur` | `lib/features/controleur/planning_page.dart` (498 l.) + `vue_planning.dart` (255 l.) | Table/cartes de séances, `FilterPill`, `Skeleton`, `EmptyState`, `ActionPrincipale` | **Existe, à refondre** : planning global toutes séances (`mes_seances_v`, borne 200, grâce 15 min ADR-005), contredit C1/C3 (mission unique pendant le cours en direct) | CT-2 |
| Service planning | — | `lib/core/controle/service_controle.dart:34-72` (`ServiceControle`, `ServiceControleSupabase.planning()`) | Provider Riverpod `serviceControleProvider`, `planningGlobalProvider` | Existe, lit `mes_seances_v` ; à remplacer/compléter par une notion de mission (BR-1) | CT-2, CT-10 (BR) |
| CTR-02 Salle (observation) | `/salle` | `lib/features/salle/vue_salle.dart:56-63` (`RoleSalle.depuis`, `'masked_controller' → RoleSalle.controleur`) ; `salle_page.dart:726-731` (bandeau rappel), `:1388-1390` (nom masqué, libellé vide) | `_Rappel`, `PermanentNotice`, `PageImmersive` | **Existe, à garder** : invisible, muet, journalisé (ADR-011). Manque : commandes « Son reçu » et « Agrandir le support » | CT-3 |
| Préflight salle | — | `lib/features/tc_classe_live/pre_vol_classe.dart:65-89` | `DetailPreCours.aucun` pour `RoleSalle.controleur` (avec tuteur observateur, admin incognito/visible) | Existe, déjà correct (ni micro ni caméra) | CT-3 (vérif seulement) |
| CTR-03 Compte rendu (écran initial) | à créer | — | `PageParcours`, `ChoiceCardGroup`, `LigneCleValeur`, `EcranResultat`, `LocalFeedback` (tous présents ailleurs) | **Manque** entièrement | CT-4 |
| CTR-03A Observation structurée | à créer | — | `PageParcours`, `PageEtape`, `ChoiceCardGroup`, `GroupeReglages`, `LigneCleValeur` | **Manque** | CT-5 |
| CTR-03B Complément | à créer | — | Parcours de CT-5, `PermanentNotice` ou `EtatSysteme` pour le bandeau | **Manque** | CT-8 |
| CTR-04 Échanges | à créer | — | Aucun composant de fil de discussion dans `lib/core/widgets/` (vérifié : `signal_row.dart`, `groupe_reglages.dart` existent mais pas de widget « fil ») | **Manque**, y compris le composant lui-même | CT-6 |
| CTR-05 Historique | à créer | — | `DataCollection`, `FilterPill`, `MenuFiltre`, `GroupeReglages`, `SectionHeader` | **Manque** | CT-7 |
| CTR-06 Détail | à créer | — | `LigneCleValeur`, `GroupeReglages`, `SectionHeader` | **Manque** | CT-7 |
| Routes | — | `lib/core/router/routes.dart:332-335` (`Routes.controleur = '/controleur'`), `:556`, `:567` (résolution par `AppRole.controller`) | — | Existe : une seule route déclarée | CT-1b (4 destinations), CT-9 |
| Montage de la route | — | `lib/core/router/app_router.dart:793-799` | `PlanningControleurPage()` sur `Routes.controleur`, sans barre de navigation | Existe, à remplacer/étendre (3 nouvelles routes : historique, échanges, `/compte` déjà partagé) | CT-1b |
| Coquille / navigation | — | `lib/core/widgets/nav_shell.dart:151-163` | `AppRole.controller \|\| AppRole.accountant \|\| AppRole.admin => const <Destination>[]` | Existe : commentaire explicite « une seule destination, qui ne monte pas de barre » — **à remplacer par 4 destinations (C13)** | CT-1b |
| Redirection par rôle | — | `lib/core/router/redirection.dart:306` (commentaire seulement, pas de branche `controleur` dédiée trouvée) | — | Redirection générique par `AppRole` ; aucune branche spécifique contrôleur au-delà de `Routes.controleur` (routes.dart:556/567) | CT-1b, CT-9 |
| Rôle applicatif | — | `lib/core/domain/enums.dart:9` `enum AppRole { … controller … }` | — | Existe. **Piège de nom** : le doc/tâche parle de « RoleUtilisateur » — dans ce code c'est `AppRole` (rôle métier) à ne pas confondre avec `RoleSalle` (rôle dans `/salle`) ni avec la classe `SessionControleur` (`lib/core/session/session_controleur.dart`, un `Notifier` Riverpod — pur hasard de nom, aucun rapport avec le rôle contrôleur) | — |
| Commutation d'espace (`Compte > Espaces`) | `/compte` | `lib/features/compte/compte_page.dart:718-753` (`_espacesPour(AppRole role)`, cas `AppRole.controller` → un seul espace `'controleur'`) | `_EspaceCompte`, `AppIcons.controleQualite` | Existe **un seul rôle effectif par session** ; pas de cumul Enseignant/Admin → Contrôle (besoin serveur, projection multi-rôle, BR-1) | CT-9 |
| Démonstration | `/demo/*` | `lib/features/demo/` : `enseignant_demo.dart`, `demo_enseignant_page.dart`, `demo_salle_page.dart`, `demo_classe_page.dart`, `mode_demonstration.dart`, `catalogue_demo.dart`, `racine_demonstrable.dart` | `environnementAutoriseDemo` (mécanisme générique) | **Aucun fichier `controleur_demo.dart`, aucune route `/demo/controleur`** (vérifié : absent de `app_router.dart`) | CT-1b |
| Accès de démonstration par courriel | — | `lib/core/session/session_controleur.dart:23-39` (`accesDemoDepuisCourriel`) | `'controleur' \| 'controller' => AppRole.controller` déjà reconnu | Existe côté session ; aucune donnée de démo (missions, roster, rapports) derrière | CT-1b |
| Lexique | — | `lib/core/i18n/strings_fr.g.dart:83, 2196, 5313, 5642, 5807, 8529-…, 15420-15427` (`controleur.*`, `nav.controleur.*`, `admin.comptes.roleControleur`, etc.) | — | Existe pour planning global et rôle ; **à compléter/refondre** pour CTR-01 à CTR-06 (C16) | CT-10 |
| Historique Admin (hors branche fusionnée) | — | `lib/features/admin_observations/observations_admin_page.dart` (branche `ui/admin-v1`, non fusionnée) | — | Existe côté Admin seulement ; aucun rapport contrôleur, aucun fil. Non requis pour la démonstration contrôleur (13_fusion après BR-1) | Hors lot direct, mentionné CT-10 |
| Tests | — | `test/features/planning_controleur_test.dart` (planning global), `test/teaching_core/q/q04_capacites_admin_controleur_test.dart` | Harnais `support/harnais.dart` | Existe pour le planning **actuel** (à refondre avec CT-2) ; rien pour CTR-02 à 06 | CT-2, CT-12 |
| Outils de capture | — | `test/capture/outil_capture.dart`, modèle `test/features/enseignant_recette/captures_en_test.dart` et `navigation_reelle_test.dart` | — | Existe, réutilisable tel quel | CT-1b (squelette `captures_ct_test.dart`), CT-12 |

## États CTR-01/salle déjà couverts par le code (à réutiliser tels quels pour les nouveaux états CT-2)

- Grâce de 15 min après fin de séance : `service_controle.dart:16-22` (`graceApresFin`, ADR-005) — logique à conserver derrière la nouvelle notion de mission.
- Rôle salle sans jeton voix/caméra : `vue_salle.dart:280` (commentaire), `pre_vol_classe.dart:68-80` (`DetailPreCours.aucun`).
- Nom masqué en salle : `salle_page.dart:1388-1390` (`RoleSalle.controleur` → libellé vide, comme `administrateurIncognito`).
- Bandeau d'invisibilité déjà écrit et jugé correct (rappel `t.salle.bandeauControle`, `salle_page.dart:726-731`) — **à garder**, ne pas dupliquer.

## Composants partagés à réutiliser sans fork (`lib/core/widgets/`)

Tous présents dans le worktree (`ls` vérifié) : `page_parcours.dart`, `page_etape.dart`, `page_immersive.dart`, `choice_card_group.dart`, `groupe_reglages.dart`, `ligne_cle_valeur.dart`, `ecran_resultat.dart`, `etat_systeme.dart`, `data_collection.dart`, `filter_pill.dart`, `menu_filtre.dart`, `status_pill.dart`, `permanent_notice.dart`, `app_bottom_sheet.dart`, `app_card.dart`, `action_principale.dart`, `empty_state.dart`, `skeleton.dart`, `offline_banner.dart` *(nom exact non confirmé isolément mais référencé en CT-2 dans le découpage)*, `signal_row.dart`, `section_header.dart`, `nav_shell.dart`, `local_feedback.dart`.

Composants « photo » cités dans `00_REPRISE.md` : `PhotoEnseignant` → `lib/features/tc_mes_groupes/photo_enseignant.dart` ; `PhotoEleve` → `lib/features/foyer/photo_eleve.dart` (non re-vérifiés ligne à ligne ici, confiance à l'inventaire du 27/09).

`EmplacementEntree` (cité dans la consigne) : trouvé sous `lib/core/tc_horloge/emplacement_entree.dart`, utilisé notamment par `journee_page.dart` et le domaine classe (`tc_espace_groupe/carte_session.dart`) — composant du domaine Classe/Journée, pas spécifique au contrôleur ; à évaluer au cas par cas s'il sert à CTR-01 refondu (ligne de mission calme).

**À créer, aucun équivalent existant** : le composant de fil de discussion pour CTR-04 (aucun widget « fil »/« thread » dans `lib/core/widgets/` ni ailleurs dans `lib/`).

## Pièges relevés

1. **`planning_page.dart` / `vue_planning.dart`** : planning **global** de toutes les séances de l'académie (lecture `mes_seances_v`, borne 200, tri par heure locale et UTC). Contredit C1 et C3 (mission unique, pendant le cours en direct). À refondre entièrement en CT-2, pas à étendre.
2. **`SessionControleur`** (`lib/core/session/session_controleur.dart`) est un `Notifier` Riverpod générique (gestion de session) — un pur hasard de nommage avec le rôle « contrôleur ». Ne pas le confondre avec `AppRole.controller` ni le modifier en pensant traiter le rôle métier.
3. **`bandeau_observation.dart`** (`lib/core/widgets/`) : bandeau pour l'observation en lecture seule **par un agent IA** (ADR-025) — sans rapport avec le rôle contrôleur humain malgré le vocabulaire proche (« observation », « lecture seule »).
4. **`RoleSalle.controleur` vs `RoleSalle.administrateurIncognito`** : les deux sont invisibles et muets dans `/salle`, code souvent groupé par `||` dans les `switch` (ex. `salle_page.dart:1388`, `pre_vol_classe.dart:76`) — vérifier à chaque refonte qu'on ne casse pas le cas admin incognito en modifiant celui du contrôleur.
5. **Aucune route ni donnée `/demo/controleur`** : à créer intégralement en CT-1b, sur le modèle `demo_enseignant_page.dart` / `enseignant_demo.dart`, jamais en étendant `demo_salle_page.dart` seul (la salle n'est qu'un des écrans du parcours contrôleur).
6. **`observations_admin_page.dart`** (branche `ui/admin-v1`, non fusionnée) : ne pas s'appuyer dessus comme s'il existait dans `ui/controleur-v1` — il est absent du worktree tant que `13_fusion` n'a pas eu lieu.
7. **Redirection par rôle** (`redirection.dart`) : pas de branche `controleur` dédiée trouvée au-delà du commentaire ligne 306 ; la résolution passe par `routes.dart:556/567` (`AppRole.controller => controleur`) — vérifier ce chemin avant d'ajouter une redirection spécifique en CT-9.
