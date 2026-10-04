# Communications V1 : revue L0 du dépôt (COM-0)

Complété par COM-0b (revue REVUE_COM-0.md, 04/10). Chaque ajout porte l'id de l'écart de la revue (UX_REV-nn, 02_DEC-11). Les ajouts qui changent le travail du socle sont marqués **[COM-F]** ; leur liste est au §7. Les réponses Q1, Q2 et Q4 restent telles quelles : seules leurs conséquences techniques sont ajoutées.

Spec §29 L0, lecture seule. Références sur `origin/corrections/revue-directeur-2026-10` @ `f6ac3658` (04/10/2026), lues par `git show` et `git grep`, sans checkout. Chemins relatifs au dépôt `D:\RA _APP\RA -OFFICIAL-APP`.

Règle de style (00_REPRISE §1) : d'une maquette on prend la composition, jamais le style. Shell réel du rôle, jamais « Tuteur / Foyer » des images.

## 1. Inventaire de l'existant (K-10, K-51 : jamais recréer)

### 1.1 Routes et gardes

| Quoi | Existant | Fichier:ligne |
|---|---|---|
| Table des chemins | `Routes` (une seule arborescence) | `lib/core/router/routes.dart:10` |
| Préfixe réservé par rôle (une route hors préfixe est refusée, Web compris) | `Routes.prefixePour` : `/eleve`, `/tuteur`, `/enseignant`, `/controleur`, `/admin`, `/comptable` | `routes.dart:612` |
| Racine par rôle | `Routes.racinePour` | `routes.dart:601` |
| Notifications du tuteur (seule route de notifications) | `/tuteur/notifications`, pose sous l'Accueil, `NotificationsPage` | `routes.dart:260`, `lib/core/router/app_router.dart:443` |
| Espace Classe du tuteur | `/tuteur/classes/:classeId` (+ `planning`, `travail`, `ressources`, `progression`) → `ClasseTuteurPage` | `routes.dart:207`, `:220` ; `app_router.dart:456` |
| Compte tuteur, Aide | `/tuteur/compte/aide` ; l'Aide n'a volontairement aucun bouton « Contacter » | `routes.dart:228`, `lib/features/compte/aide_page.dart:21` |
| Classes de l'enseignant | `/enseignant/classes` → `MesClassesPage` (« page provisoire jusqu'à EN-3 ») | `routes.dart:284`, `app_router.dart:744`, `lib/features/enseignant_classes/mes_classes_page.dart:133` |
| Fiche de Classe (groupe) de l'enseignant | `/enseignant/groupe/:groupeId` → `FicheGroupePage`, `SortieEspaceClasse` | `routes.dart:322`, `:325` ; `app_router.dart:793` ; `lib/features/fiche_groupe/fiche_groupe_page.dart:68`, `:116` |
| Échanges du contrôleur (fils par mission) | `/controleur/echanges`, `?mission=` ; « Écrire à l'administration » | `routes.dart:344`, `:348`, `:355` ; `app_router.dart:842` |
| Admin : huit domaines gelés, routes imbriquées par domaine | `/admin`, `/admin/operations/*`, `/admin/personnes/*`, `/admin/pedagogie/*`, `/admin/configuration/*`, `/admin/securite-audit/*` | `routes.dart:368-462`, `lib/core/admin/admin_domaine.dart:12`, `:92` |
| Démonstrations | `/demo/salle`, `/demo/classe`, `/demo/enseignant`, `/demo/controleur`, `/demo/accessibilite`, `/demo/adulte` ; tuteur `?demo=tuteur`, admin `?demo=admin` | `routes.dart:499-520`, `lib/features/demo/mode_demonstration.dart:57`, `:157` |
| Écran « à construire » | `ecran_a_construire.dart` | `lib/core/router/ecran_a_construire.dart` |

**Aucune route** ne porte aujourd'hui Messages métier, Communauté, Le Studio, Annonces ou Administration des communications.

### 1.2 Shells par rôle (destinations actuelles, place restante)

| Rôle | Shell | Destinations | Place restante | Cloche | Fichier:ligne |
|---|---|---|---|---|---|
| Tuteur | `NavShell` | Accueil, Foyer, Historique, Compte | **0** (4/4, `maxDestinations = 4`, assertion) | oui, `ClocheNotifications` → `/tuteur/notifications`, sans point (DB-CPT-04) | `lib/core/widgets/nav_shell.dart:128-147`, `:389` ; `app_router.dart:1436-1446` |
| Élève adulte | `NavShell` à 4 destinations (démonstration seulement, `/demo/adulte`) ; **en production, rôle `guardian`, donc coquille tuteur** (UX_REV-09, note sous le tableau) | Accueil, Ma classe, Coran, Mon espace | **0** (4/4) | oui, posée par la page (`AccueilAdultePage`) → `NotificationsPage` de démonstration | `lib/features/demo/demo_adulte_page.dart:452`, `:1120` ; `lib/features/accueil_adulte/accueil_adulte_page.dart:171`, `:204` |
| Enseignant | `NavShell` | Aujourd'hui, Classes, Disponibilités, Profil (E10, 26/09) | **0** (4/4) | **non** | `nav_shell.dart:158-179` ; maximum `:389`, assertion `:224-228` ; `routes.dart:292-296` |
| Contrôleur | `NavShell` + `GardeControle` | Contrôle, Historique, Échanges, Compte (C13) | **0** (4/4) | **non** | `nav_shell.dart:186-205`, `app_router.dart:1432` |
| Admin | `AdminShell` (tiroir < 600, rail, barre latérale ≥ 1200), plafond de huit domaines | **7 domaines visibles** : Accueil, Opérations, Personnes, Pédagogie, Finance (inerte), Configuration, Sécurité et audit. Direction **masqué** tant que `peutVoirDirection` est faux (UX_REV-10) | plafond de **8** (`maxDomaines`, assertion) ; Finance visible sans route, Direction ni route ni libellé. La place libre ne rouvre ni Q1 ni Q4 | **non** : « Pas de cloche tant qu'aucun service de notifications n'existe (Q5) » ; ce « Q5 » est celui du chantier admin (commit `d3cb8575`), pas la Q5 de `QUESTIONS.md` | `lib/core/widgets/admin_shell.dart:20`, `:48-49`, `:66`, `:94` ; `admin_domaine.dart:12-49`, `:99`, `:108-128` (`if (voitDirection)`) ; `session_state.dart:140` ; `app_router.dart:1308`, `:1467` |
| Comptable | aucun écran (ADR-003) | sans objet | sans objet | sans objet | `lib/core/domain/enums.dart:13`, `nav_shell.dart:217` |

Sous-navigation d'un domaine admin (onglets pairs, sans second niveau de barre) : `SousNavigationDomaine`, `ongletsPedagogie`, `ongletsConfiguration` (`lib/core/widgets/sous_navigation_domaine.dart:25`, `admin_domaine.dart:153`, `:185`). Recherche de navigation admin : `ciblesRechercheAdmin` (`admin_domaine.dart:137`).

Notes COM-0b :

- **Élève adulte (UX_REV-09).** En production, l'élève adulte a le rôle `guardian` : il est son propre tuteur (ADR-009, `lib/core/domain/enums.dart:22` ; `lib/features/dossier/attente_page.dart:189-191`). Il a donc la coquille tuteur, `ClasseTuteurPage` et la cloche `/tuteur/notifications` (`routes.dart:601-618`). La coquille à 4 destinations (Accueil, Ma classe, Coran, Mon espace) n'existe qu'en démonstration (`/demo/adulte`, `demo_adulte_page.dart:1-13`).
- **Seuls Pédagogie et Configuration ont une sous-navigation** (`admin_domaine.dart:85-91`). Opérations n'en a pas : sa racine redirige vers Groupes (`app_router.dart:868-878`). Voir COM-W04 au §3 (UX_REV-03).
- **Configuration annonce déjà une fonction « Notifications »** (modèles globaux, lot CFG-03, sans route ni écran : `admin_domaine.dart:38-40`, `:174-181`). Elle reste hors COM. **[COM-F]** ne l'ajoute pas à `ongletsConfiguration`. La frontière entre ces modèles globaux et le catalogue COM §13.2 est à tracer, sans dupliquer `/admin/operations/communications` (QUESTI-07, sans rouvrir Q4).

### 1.3 Notifications

| Quoi | Existant | Fichier:ligne |
|---|---|---|
| Page | `NotificationsPage` (tuteur ; l'élève adulte la réutilise avec son propre retour, sans fork) : une carte à filets, date à gauche, chevron si destination. **Retour par défaut vers `/tuteur`** quand `onRetour` est nul ; **dépend de `suivi_foyer/`** (`ColonneHistorique`, `NoteHistorique`). Une route copiée de celle du tuteur (`const NotificationsPage()`) renverrait un autre rôle vers `/tuteur` (UX_REV-07). La note de fuseau est neutre : rien à changer | `lib/features/notifications/notifications_page.dart:22-36`, `:107` ; retour `:38-42`, `:51` ; imports `:19-20`, usages `:52`, `:89` ; route tuteur `app_router.dart:443-445` |
| États | indisponible (`EtatSysteme`, sans « Réessayer »), vide, liste ; `BlocAsynchrone` | `notifications_page.dart:54`, `:64` |
| Modèle | `NotificationTuteur` : `id`, `titre`, `date`, `destination` ; **ni niveau, ni lu/non lu, ni type** | `lib/core/capacites/port_notifications.dart:9-30` |
| Port | `PortNotifications.liste()`, `.detail(id)` ; production `NotificationsIndisponibles` | `port_notifications.dart:34`, `:45`, `:63` |
| Cloche | `ClocheNotifications({onPress, nonLues})`, point de non-lus, lue « Notifications » | `lib/core/widgets/entete_page.dart:158-201` |
| Actions de coquille | `ActionsEnteteCoquille` (cloche en dernier). `ActionsEnteteCoquille.de` lit **le plus proche**, sans fusion : deux `ActionsEnteteCoquille` empilés se masquent (voir 02_DEC-03 dans `02_DECOUPAGE.md`, raccourci Espaces CT-9 de `EnteteEspaces`) | `lib/core/widgets/page_shell.dart:258-273`, `:282-286` ; `lib/features/compte/espaces_compte.dart:415-424` ; `app_router.dart:1427-1433` |
| Cloche de la Classe live (UX_REV-08) | Une **seconde cloche** existe : elle ouvre une feuille locale « Les notifications ne sont pas encore disponibles », pas `NotificationsPage`. Visible seulement sur ordinateur, pour l'enseignant et l'élève standard (`_CoinComplet`). L'enfant en interface guidée ne la voit pas (`_CoinGuide`, sans cloche) ; sur téléphone et web étroit, pas de coin droit | `lib/features/tc_classe_live/classe_live_page.dart:312-329`, `:421` ; `lib/features/salle_seance/chrome_seance.dart:24-30`, `:209-212`, `:511-535`, `:560-585` ; `vue_seance.dart:550` |
| Doubles de test | `FauxNotifications` | `test/fixtures/tuteur/faux_capacites.dart:122`, `test/features/notifications/notifications_test.dart:27` |

### 1.4 Fil Contrôleur et composants de discussion

| Quoi | Existant | Fichier:ligne |
|---|---|---|
| Fil générique partagé | `FilDiscussion` (liste + champ + Envoyer ; Entrée = retour à la ligne ; région live polie pour les nouveaux messages ; champ au-dessus du clavier) | `lib/core/widgets/fil_discussion.dart:117-151` |
| Message | `MessageFil` | `fil_discussion.dart:23` |
| Textes injectés par le rôle | `TextesFilDiscussion` | `fil_discussion.dart:51` |
| État d'envoi | `EtatEnvoiMessage` : `enCours`, `envoye`, `echec` (texte gardé, « Réessayer ») | `fil_discussion.dart:98-107` |
| Bulle, saisie | `_Bulle`, `_Saisie` (privées) | `fil_discussion.dart:270`, `:370` |
| Domaine Échanges | `FilEchange` (un fil par mission, `missionId`, `classe`, `debutMission`, `etat`), `MessageEchange`, `AuteurEchange` (contrôleur, administration), `EtatFilEchange` | `lib/features/controleur/echanges_controleur.dart:17-92` |
| Port | `PortEchanges` (`fils`, `filDeMission`, `envoyer`) ; production `EchangesIndisponibles` (tout échoue par `StateError`, pas par `CapaciteIndisponible` : voir §1.6, UX_REV-12) | `echanges_controleur.dart:95-129`, `:109-123` |
| Page | `EchangesControleurPage` : liste des fils ou fil ouvert ; contexte de visite épinglé non modifiable `_ContexteEpingle` | `lib/features/controleur/echanges_controleur_page.dart:36`, `:144`, `:207` |
| Démonstration | `EchangesDemo` | `lib/features/demo/demo_controleur_page.dart:322`, `:486` |
| Textes | `controleur.echanges.*` (dont `echec` honnête, `nouveauMessage`) | `assets/i18n/fr.i18n.json:3538-3558` |
| Tests | `test/features/controleur/echanges_controleur_test.dart:93` (`_EchecPuisSucces`) | sans objet |

**CTRL-MSG-1 (`02a36bdf`) n'est pas dans la référence** (UX_REV-13) : `git merge-base --is-ancestor 02a36bdf f6ac3658` rend 1 ; le commit n'est que sur `origin/corrections/c1-ctrl`. Malgré son nom, il ne touche pas le fil (`fil_discussion.dart`, venu de CT-6, inventorié ci-dessus) : il corrige des messages d'erreur du compte rendu et de l'observation (`compte_rendu_controle_page.dart`, `observation_controle_page.dart`). Il touche aussi `fr.i18n.json`, `strings.g.dart`, `strings_fr.g.dart` et `tool/libelles_sources.json`, que COM modifie : conflit attendu, réglé à COM-FUS en régénérant.

**Côté admin, aucun écran ne lit ni ne répond aux fils du contrôleur.** Aucun composer avec pièce jointe ou vocal, aucune liste de fils multi-objets, aucun panneau de contexte de fil n'existe.

### 1.5 Messages, annonces, signalement, modération

| Quoi | Existant | Fichier:ligne |
|---|---|---|
| Signalement pédagogique structuré (enseignant → administration, sur un élève) | `PortSignalement`, `SignalementMemoire` ; feuille | `lib/core/tc_parcours/port_signalement.dart:17`, `:56`, `:141` ; `lib/features/tc_flux_academique/feuille_signalement.dart:217` |
| Signaler un besoin (fiche élève enseignant) | `SignalementBesoin`, `SignalerBesoin` | `lib/features/fiche_groupe/fiche_eleve_enseignant.dart:307`, `:347` |
| Signalement en séance | `signalement_seance.dart` | `lib/features/salle_seance/signalement_seance.dart` |
| Annonce | **aucune** (les « annonce » du code sont des annonces lecteur d'écran) | sans objet |
| Modération de contenus | **aucune** | sans objet |

Ces signalements sont pédagogiques ; ils ne sont **pas** la modération communautaire du §5.5 et ne doivent pas être réutilisés pour elle (objets et destinataires différents).

### 1.6 Ports, démonstration, environnement

| Quoi | Existant | Fichier:ligne |
|---|---|---|
| Environnement compilé | `Env.environnement`, `Env.configuree`, drapeaux `GALERIE`, `PLAYGROUND` | `lib/core/config/env.dart:14`, `:97`, `:103` |
| Garde de démonstration (production et environnement vide ferment) | `environnementAutoriseDemo`, `demoTuteurActive`, `demoAdminDemandee` | `mode_demonstration.dart:63`, `:74`, `:160` |
| Surcharges tuteur et admin | listes d'`overrideWithValue` | `mode_demonstration.dart:102-152`, `:185-200` |
| Branchement des ports réels | `main.dart` | `lib/main.dart:32`, `:190` |
| Modèle de port neutre | **`NotificationsIndisponibles` seul** (rend `CapaciteIndisponible`). Tout port COM neutre lève `CapaciteIndisponible('COM-BR-nn')` et l'écran rend `EtatSysteme(NatureEtat.indisponible)`, sans « Réessayer ». **Écart connu, non modifié** : `EchangesIndisponibles` lève `StateError` ; `BlocAsynchrone` en fait un échec avec « Réessayer » (UX_REV-12, même cause que COM-BR-A09) | `port_notifications.dart:45-59` ; `echanges_controleur.dart:109-123` ; `lib/core/widgets/bloc_asynchrone.dart:27-28`, `:236` ; `lib/core/capacites/` |
| Stockage local approuvé | `StockagePreferencesDrift` (préférences seulement), `StockagePreferencesMemoire` | `lib/core/preferences/preferences_locales.dart:218`, `:249` |
| Fichiers | `SelecteurFichier` (dossier KYC), `PortEnregistrementFichier`, `LecteurArtefact` | `lib/core/dossier/selecteur_fichier.dart:15`, `lib/core/tc_telechargement/port_enregistrement_fichier.dart:14`, `port_telechargement.dart:27` |
| Paquets | `just_audio` (lecture), `file_picker`, `drift`, `slang` ; **ni `record`, ni `permission_handler`, ni `url_launcher`** | `pubspec.yaml:36-63` |

### 1.7 Thème et composants partagés

| Quoi | Existant | Fichier:ligne |
|---|---|---|
| Palette (lavande, accent, CTA unique) | `AppPalette` | `lib/core/theme/app_palette.dart:27`, `:258` |
| Polices (DM Sans titres, Plus Jakarta Sans corps) | `AppFontFamily` | `lib/core/theme/app_typography.dart:26`, `:29` |
| Espacements, largeurs de page | `AppSpacing`, `AppPage` (`largeurLecture` 800, `largeurGestion` 1440), `AppTouchTarget`, `Ecart` | `lib/core/theme/app_spacing.dart:13`, `:63`, `:74-79`, `:102`, `:112` |
| Rayons, contours, élévation, mouvement | `AppRadius`, `AppContour`, `AppElevation`, `AppMouvement` | `app_radius.dart:13`, `app_contour.dart:7`, `app_elevation.dart:32`, `app_mouvement.dart:17` |
| Seuils de largeur (600, 840, 1200), `ClasseLargeur`, rail 80, barre 256 | `AppGabarit` | `lib/core/theme/app_gabarit.dart:56-121` |
| Page | `PageShell` (`titre`, `onRetour`, `actionsEntete`, `defilante`, `actionsCoquille`) | `lib/core/widgets/page_shell.dart:46-83` |
| En-tête, retour | `EntetePage`, `DisqueRetour` | `entete_page.dart:26`, `:111` |
| Cartes groupées (un rectangle, filets) | `CarteGroupee`, `FiletCarte`, `CarteLignes`, `LigneDansCarte`, `AppCard` | `carte_groupee.dart:9`, `:34` ; `carte_lignes.dart:16`, `:55` ; `app_card.dart:28` |
| États | `EtatSysteme` (`NatureEtat`, `PorteeEtat`), `EmptyState`, `BlocAsynchrone<T>`, `Skeleton`, `OfflineBanner` | `etat_systeme.dart:19`, `:59`, `:79` ; `empty_state.dart:46` ; `bloc_asynchrone.dart:41` ; `skeleton.dart:27` ; `offline_banner.dart:35` |
| Actions | `ActionPrincipale` (`NiveauAction`), `RangeeActions`, `BoutonIcone`, `MenuActions`/`EntreeAction`, `ConfirmDestructive`, `LienFleche` | `action_principale.dart:20`, `:52`, `:415` ; `bouton_icone.dart:26` ; `menu_actions.dart:10`, `:37` ; `confirm_destructive.dart:27` ; `lien_fleche.dart:21` |
| Filtres et onglets | `FilterPill`, `ControleSegmente<T>`, `SelecteurSection<T>`, `MenuFiltre<T>` | `filter_pill.dart:25`, `controle_segmente.dart:41`, `selecteur_section.dart:57`, `menu_filtre.dart:54` |
| Statuts | `StatusPill` (`TonEtat`), `PointRappel`, `LocalFeedback`, `PermanentNotice` | `status_pill.dart:14`, `:61` ; `point_rappel.dart:27` ; `local_feedback.dart:27` ; `permanent_notice.dart:28` |
| Avatars | `AvatarNom`, `AvatarTile`, `AvatarSansImage` | `avatar_nom.dart:45`, `:414` ; `avatar_tile.dart:46` |
| Feuille, modale | `AppBottomSheet` (`FormeModale`) | `app_bottom_sheet.dart:22`, `:49` |
| Lignes de réglage, clé-valeur, chronologie | `GroupeReglages`, `LigneRubrique`, `SettingRow`, `LigneCleValeur`, `TimelineRow`, `SectionHeader` | `groupe_reglages.dart:17`, `:108` ; `setting_row.dart:13` ; `ligne_cle_valeur.dart:21` ; `timeline_row.dart:20` ; `section_header.dart:20` |
| Tableau admin | `DataCollection<T>`, `ColonneDonnees<T>`, `StatTile` | `data_collection.dart:37`, `:96` ; `stat_tile.dart:22` |
| Audio (lecture) | `AudioLabel` | `audio_label.dart:23` |
| Panneau colonne / volet / feuille (salle) | `PanneauSeance`, `FormePanneau` | `lib/features/salle_seance/panneau_seance.dart:64` |
| Liste + détail admin (modèle) | `FileDossiers` + `DetailDossier`, `SqueletteDetail` | `lib/features/admin_dossiers/detail_dossier.dart:32`, `:140` |
| Icônes | `AppIcons` (dont `notifications`) | `lib/core/icons/app_icons.dart:40` |

**Il n'existe pas** de coquille à 2 ou 3 panneaux générique (`ResponsiveWorkspaceShell` est à créer, sur `AppGabarit`).

### 1.8 Rôle « équipe interne »

`AppRole` a six valeurs : `admin`, `accountant`, `controller`, `teacher`, `guardian`, `student` (`lib/core/domain/enums.dart:9-26`). **Aucun rôle « équipe interne », aucune capability Studio.** `SessionState.peutVoirDirection` rend toujours `false` (`lib/core/session/session_state.dart:140`). Le comptable n'a aucun écran. Le contrôleur est un observateur qualité externe à préfixe `/controleur` : une route `/admin/*` lui est refusée par `prefixePour` (`routes.dart:612`).

**Conséquence V1** : seul l'**admin** peut entrer dans Le Studio sans nouvelle décision ni changement de garde. Voir QUESTIONS Q1.

### 1.9 i18n

- Un seul fichier par langue : `assets/i18n/fr.i18n.json` (4 650 lignes), `assets/i18n/ar.i18n.json` ; slang 4.19 (`pubspec.yaml:36`), `slang.yaml` : `flat_map: true`, interpolation en accolades, sortie `lib/core/i18n/strings*.g.dart`.
- Convention `role.ecran.element`. Blocs existants utiles : `notifications` (`fr.i18n.json:2544`), `controleur.echanges` (`:3538`), `adulte.notifications` (`:4580`), `nav` (`:2148`), `etat` (`:138`), `reseau` (`:132`).
- Aucun bloc `com`. Le lexique §22 est absent.

## 2. Matrice Garder / Améliorer / Ajouter / Supprimer sur validation (spec §19)

| Composant §19 | Équivalent existant | Décision | Étape |
|---|---|---|---|
| `ResponsiveWorkspaceShell` | aucun ; bases `AppGabarit` (600/840/1200), `PanneauSeance` (formes colonne/volet/feuille) | **Ajouter** sur `AppGabarit`, sans copier `PanneauSeance` | COM-F |
| `ContextThreadHeader` | `_ContexteEpingle` (privé, contrôleur) | **Ajouter** ; `_ContexteEpingle` reste tel quel (aucune modification du contrôleur avant COM-FUS) | COM-MSG-1 |
| `ThreadContextPanel` | aucun | **Ajouter** | COM-MSG-1 |
| Fil / composer texte | `FilDiscussion`, `MessageFil`, `EtatEnvoiMessage` | **Améliorer** : paramètres optionnels non cassants (emplacement vocal, pièce jointe, en-tête) ; le contrôleur doit rester identique (test existant vert) | COM-F |
| `VoiceMessageComposer` | `AudioLabel`, `just_audio` (lecture seule) | **Ajouter** derrière un port d'enregistrement neutre (aucun paquet `record`) | COM-VOC-1 |
| `UnreadUrgencyBadge` | `ClocheNotifications.nonLues`, `PointRappel`, `StatusPill` | **Ajouter** en composant au-dessus de `StatusPill` (texte + icône) | COM-F |
| `NotificationCenter` | `NotificationsPage`, `PortNotifications` | **Améliorer** la page existante (filtres, niveaux, lu), jamais un second centre | COM-ANN-1 |
| Cloche de la Classe live (UX_REV-08) | `_voirNotifications` : feuille locale « indisponible » (§1.3) | **Améliorer** pour l'enseignant, **Supprimer** pour l'élève (réponse à Q5 du 04/10) : pour l'enseignant, elle ouvre le centre partagé (`/enseignant/notifications`, choisi par `RoleSeance.enseignant`, déjà lu par `_routeDuGroupe`, `classe_live_page.dart:306-310`) ; pour l'élève, elle disparaît : seul l'élève mineur entre en Classe live (`redirection.dart:326-327`, `AppRole.teacher` ou `AppRole.student`), l'élève adulte (`guardian`) n'y entre pas aujourd'hui. Quand une entrée adulte existera, elle passera `/tuteur/notifications` par un champ optionnel de `ContexteClasseLive` (`classe_live_page.dart:54`), construit aujourd'hui seulement par `routes_tc_a.dart:92` ; ce manque est signalé au tableau, hors COM. Jamais `AppRole` ni `InterfaceMode` (le mode standard couvre aussi les enfants de 9 ans et plus, `enums.dart:89`). Seul fichier touché : `classe_live_page.dart` ; `lib/features/salle_seance/` reste interdit | COM-ANN-1 |
| `ClassAnnouncementCard` | aucun | **Ajouter** (sur `CarteGroupee`) | COM-ANN-1 |
| `CommunityCategoryTabs` | `FilterPill`, `ControleSegmente`, `SelecteurSection` | **Garder** : réutiliser `SelecteurSection`/`FilterPill`, pas de nouveau composant d'onglets | COM-COMU-1 |
| `PostComposerEntry` | `ActionPrincipale`, `AppBottomSheet` | **Ajouter** (entrée unique + feuille/panneau) | COM-COMU-1 |
| `ReplyThread` | `FilDiscussion` (bulles) | **Ajouter** une liste de réponses ; ne pas forcer `FilDiscussion` (réponses ≠ conversation) | COM-COMU-1 |
| `ModerationActions` | `MenuActions`, `ConfirmDestructive` | **Ajouter** sur `MenuActions`, actions visibles seulement avec la capacité « modérer » (COM-BR-16) | COM-COMU-1 (signaler), COM-ANN-2 (masquer, restaurer, rejeter) |
| `CommunityPromotionGuard` / `PromotionPolicyGuard` | aucun | **Ajouter un seul composant** (`CommunityPromotionGuard`) ; `PromotionPolicyGuard` = sa politique (motifs), pas un second composant | COM-COMU-2 |
| `StudioTodayBoard` | `GrilleBento`/`BentoTile` (accueil), `CarteGroupee` | **Ajouter** sur `CarteGroupee` | COM-STU-2 |
| `ActivityInbox` | `CarteLignes`, `TimelineRow` | **Ajouter** | COM-STU-2 |
| `DraftPersistence` | `BrouillonCahier`, `BrouillonProfilEleve` (brouillons métier), `StockagePreferencesDrift` (préférences) | **Ajouter** en mémoire de session ; Drift non approuvé pour des messages | COM-F (port), COM-STU-2 |
| `SavedForLater` | `MarquePage` | **Ajouter** (références seulement), réutiliser l'icône `MarquePage` si elle convient | COM-COMU-1 et COM-STU-1 (chacun son usage), port en COM-F |
| `StudioChannelList` | aucun | **Ajouter** | COM-STU-1 |
| `StudioSharedAssetsPanel` | aucun (ne pas réutiliser la Bibliothèque `VueCatalogue`) | **Ajouter** | COM-STU-1 |
| `StudioChannelVisibility` | aucun | **Ajouter** (consomme un statut) | COM-STU-1 |
| `StudioFocusToggle`, `FocusExitDock`, `MinimalComposer`, `FocusStateRestorer` | `EtatLocalSeance.agrandi`, `_FocusPanneaux` (salle, privé) comme modèle de lecture | **Ajouter** ; ne pas modifier la salle | COM-STU-3 |
| `AnnouncementPublisher` | `PageEtape`/`RangeeEtape` (étapes) | **Ajouter** sur `PageEtape` | COM-ANN-2 |
| `AudienceRulesMatrix` | `DataCollection<T>` | **Ajouter** sur `DataCollection` | COM-ANN-2 |
| `ModerationQueue` | `FileDossiers` + `DetailDossier` (modèle file + détail) | **Ajouter** sur le même gabarit | COM-ANN-2 |
| `AttachmentPolicyPort` + carte pièce jointe | `SelecteurFichier` (KYC), `LecteurArtefact` | **Ajouter** (port neutre + carte), sans réutiliser le sélecteur KYC | COM-F |
| `CommunicationScopeGuard` (maquettes seulement, absent de §19) | `prefixePour`, `redirection.dart`, statut fourni par le port | **Supprimer sur validation** : pas de composant ; la portée vient de la garde de route et de l'absence de donnée (leçon 15) | aucune |
| `EchangesControleurPage` | existe | **Garder** ; le contrôleur garde « Échanges » (C13). Rapprochement avec Messages métier : COM-FUS seulement, sur validation | aucune |
| `NotificationTuteur` (nom) | existe | **Garder** le nom, ajouter des champs optionnels ; renommage = Supprimer sur validation | COM-ANN-1 |

## 3. Écrans : shell réel, entrée réelle, route

Les routes « à créer » sont toutes créées par **COM-F** (routes, routeur, coquilles), avec un écran provisoire honnête (`ecran_a_construire.dart`) ; chaque voie remplace ensuite son écran dans son propre dossier.

| Écran | Rôle | Shell réel | Entrée réelle | Route existante / à créer |
|---|---|---|---|---|
| COM-M01 / COM-W01 Messages métier | Tuteur | `NavShell` tuteur (Accueil actif, pose) | 1) Espace Classe `ClasseTuteurPage` : « Écrire à l'enseignant » ; 2) cloche → notification de message ; pas de 5e destination | **à créer** `/tuteur/messages`, `/tuteur/messages/:filId` |
| COM-M01 / COM-W01 | Enseignant | `NavShell` enseignant (Classes actif) | 1) `MesClassesPage` et `FicheGroupePage` : entrée **contextuelle** (un fil avec une famille ou sur un élève, §3.2), jamais un bloc « Messages » général ; le libellé « Messages de la Classe » ne vient pas de la spec et n'est pas repris (02_DEC-11, §5 point 22) ; 2) fiche élève enseignant (contexte élève/famille) ; 3) cloche de la coquille (Q5 répondue oui le 04/10, voir COM-M06) | **à créer** `/enseignant/messages`, `/enseignant/messages/:filId` |
| COM-M01 / COM-W01 | Élève adulte | **production** : coquille tuteur (rôle `guardian`, UX_REV-09) ; **démonstration** : `NavShell` adulte | production : mêmes entrées que le tuteur (`ClasseTuteurPage`, cloche `/tuteur/notifications`) ; démonstration : `MaClasseAdultePage` « Écrire à l'enseignant », cloche de `AccueilAdultePage` | production : routes tuteur ; démonstration `/demo/adulte` (écran `messages`). Les tests d'entrée de COM-MSG-2 et COM-ANN-1 couvrent l'adulte par la voie tuteur |
| COM-M01 / COM-W01 | Admin | `AdminShell`, domaine Opérations | onglet « Messages » de l'Administration des communications ; dossier (`DetailDossier`) « Écrire à la famille » en COM-MSG-2 | **à créer** `/admin/operations/communications/messages`, `…/messages/:filId` (Q4) |
| COM-M01 / COM-W01 | Contrôleur | `NavShell` contrôleur | existante : destination Échanges + « Écrire à l'administration » (`Routes.controleurEcrireAdmin`) | **existante** `/controleur/echanges`, gardée telle quelle |
| COM-M02 / COM-W02 Communauté enseignants | Enseignant | `NavShell` enseignant (Aujourd'hui actif, pose) | raccourci sur `JourneePage` (Aujourd'hui) + notification ; pas de destination (4/4, E10), Q2. **Le raccourci n'est pas un 5e bloc** : JourneePage est limitée à « Quatre blocs, pas un de plus » (K-42, `journee_page.dart:3-5`). C'est la ligne retenue par Q2, posée **dans un bloc toujours rendu**, pas dans « Alertes utiles » (rendu seulement s'il n'est pas vide, `:4-5`). **[COM-F]** pose l'emplacement vide dans `journee_page.dart` (widget `EntreeCommunaute` appartenant à `com_communaute/`) ; COM-COMU-1 le remplit sans rouvrir la page. Le test vérifie qu'il reste quatre blocs au plus (UX_REV-01) | **à créer** `/enseignant/communaute`, `/enseignant/communaute/:publicationId` |
| COM-M03 / COM-W03 Le Studio, canal | Admin (seul rôle possible en V1) | **coquille propre du Studio** (navigation Aujourd'hui / Canaux, sur `ResponsiveWorkspaceShell`), sortie vers `/admin` ; hors `AdminShell` pour que le Focus masque toute navigation | action « Le Studio » dans l'en-tête de l'`AdminShell` (pas un 9e domaine), Q1. **Sous 600, l'en-tête n'a aucune action** : l'`AdminShell` rend `contenu(avecActions: false)` sous `_BarreMobile` (menu, recherche, compte seulement). **[COM-F]** pose donc aussi « Le Studio » pour le gabarit barre basse, dans `_BarreMobile` ou dans `_Tiroir`, en plus de `ActionsEnteteCoquille` à partir de 600 (UX_REV-02, `admin_shell.dart:43-48`, `:134-140`, `:159-162`, `:704-708`). Le test d'entrée de COM-STU-1 tape ce bouton à 390 | **à créer** `/admin/studio/canaux/:canalId` |
| COM-M04 / COM-W00 Le Studio, Aujourd'hui | Admin | coquille du Studio | même entrée ; racine du Studio | **à créer** `/admin/studio` |
| COM-M05 / COM-W03F Focus | Admin | coquille du Studio, état local | bouton « Mode focus » du canal | **aucune route** (état de COM-W03, §17) |
| COM-M06 Notifications et annonce | Tuteur | `NavShell` tuteur | cloche existante | **existante** `/tuteur/notifications` ; détail d'annonce **à créer** `/tuteur/notifications/:id` seulement si le contenu dépasse la carte (§18) |
| COM-M06 | Enseignant, contrôleur | leur `NavShell` | cloche **à poser** par COM-F dans `_CoquilleNavigation` (Q5 répondue le 04/10 : oui pour l'enseignant, le contrôleur, l'admin et l'élève adulte) (QUESTI-01, §5 point 7). **[COM-F]** : seulement pour `AppRole.teacher` et `AppRole.controller`, **jamais pour `AppRole.student`**, qui passe par la même branche `role != AppRole.guardian` (`app_router.dart:315-316`, `:1427-1434`) et ne désigne que l'élève mineur créé par son tuteur (`student_type = 'minor'`, `0004_inscription_kyc_appairage.sql:892`) ; l'adulte autonome est `guardian` (`enums.dart:22`) ; l'élève adulte (`guardian`) a déjà la cloche du tuteur (UX_REV-06, UX_REV-09). La cloche entre dans **une seule** liste d'actions composée avec le raccourci Espaces de `EnteteEspaces` (02_DEC-03, §1.3) | **à créer** `/enseignant/notifications`, `/controleur/notifications`. **[COM-F]** : chaque route passe son `onRetour` vers la racine du rôle (`Routes.racinePour`), jamais le défaut `/tuteur` de `NotificationsPage` (UX_REV-07) |
| COM-M06 | Admin | `AdminShell` | cloche **à poser** dans l'en-tête admin (aujourd'hui absente, `admin_shell.dart:48-49`) (Q5 répondue le 04/10 : oui pour l'enseignant, le contrôleur, l'admin et l'élève adulte). **[COM-F]** : comme « Le Studio », la cloche est posée aussi pour le gabarit barre basse (`_BarreMobile` ou `_Tiroir`), sinon elle n'existe pas sur téléphone (UX_REV-02) | **à créer** `/admin/notifications`, montée dans `_CoquilleAdmin(domaine: AdminDomaine.accueil)` (domaine obligatoire, `app_router.dart:1467-1468`), retour vers `/admin` (UX_REV-11, UX_REV-07) |
| COM-M06 | Élève adulte | production : coquille tuteur (UX_REV-09) ; démonstration : `NavShell` adulte | production : cloche tuteur existante ; démonstration : cloche d'`AccueilAdultePage` | production : `/tuteur/notifications` ; démonstration existante (`demo_adulte_page.dart:1120`) |
| COM-M06 | Enseignant, élève standard, en Classe live | en-tête de la salle (ordinateur seulement) | cloche existante de la Classe live, feuille locale « indisponible » (UX_REV-08, §1.3) | aucune route ; COM-ANN-1 la rebranche sur le centre partagé pour l'enseignant et la retire pour l'élève, l'élève adulte n'entrant pas en Classe live (Q5, §1.3) |
| Annonce de Classe (lecture) | Tuteur, adulte | leur shell | Espace Classe (`ClasseTuteurPage`, `MaClasseAdultePage`) + notification | dans la page de Classe, pas de route propre |
| Annonce de Classe (publication) | Enseignant | `NavShell` enseignant | `FicheGroupePage` (Espace Classe enseignant, §14) | **à créer** `/enseignant/groupe/:groupeId/annonce` (tâche focalisée) |
| COM-W04 Administration des communications | Admin | `AdminShell`, domaine **Opérations**, onglets `SousNavigationDomaine` : Annonces, Modération, Messages | 1) une ligne « Communications » dans la `CarteLignes` des raccourcis de `TableauDeBordPage` (`tableau_de_bord_page.dart:140-163`), **posée par [COM-F]** et non par COM-ANN-2 ; 2) la cible de recherche admin. **Taper « Opérations » ne mène jamais aux Communications** : la racine du domaine redirige vers Groupes et Opérations n'a pas de sous-navigation (`app_router.dart:868-878`, `admin_domaine.dart:85-91`). Le domaine Opérations reste surligné (Q4) (UX_REV-03) | **à créer** `/admin/operations/communications` (+ `/annonces`, `/moderation`, `/messages`), Q4 |
| Démonstration Communications | tous | shells réels | route de démonstration hors production | **à créer** `/demo/communications?role=` (garde `environnementAutoriseDemo`) |

**Recherche dans Messages métier (ThreadSearch, COM-M01 et COM-W01, UX_REV-04).** La spec en fait un état de la liste des fils (spec l.818-826, §18 l.1022-1036). Ce n'est ni une route ni un écran : sur ordinateur, un champ en tête de la colonne des fils, résultats et filtres dans la même surface, le retour garde la position ; sur mobile, une surface plein écran temporaire dont le retour restaure la liste. Confiée à COM-MSG-1 (fichier `recherche_fils.dart` dans `com_messages/`). Les résultats se limitent aux fils que la personne a le droit de lire (contrat : `rechercher(texte)` de COM-BR-01 dans `COM-BR.md`, revue COM-BR-A05).

## 4. Écarts de style des maquettes à NE PAS reprendre

Ce ne sont **pas** des lignes TH-2 : on applique les tokens existants (`AppPalette`, `AppRadius`, `AppTypography`, `CarteGroupee`).

- Fond lavande pastel des planches, dégradé violet en haut de la maquette sombre, arc décoratif.
- Bulles de message violet saturé (« Vous ») et bulles grises : on garde `_Bulle` de `FilDiscussion`.
- Pastilles rondes rouges ou roses « 2 », « 1 », « ! » (non-lus, urgence) : `UnreadUrgencyBadge` dit le texte (« 2 non lus », « Action requise »), jamais la couleur seule.
- Pastilles de statut colorées : vert « Publiée », orange « Planifiée », rose « En attente », « Oui » orange et « Non » gris de la matrice, coches vertes : on utilise `StatusPill` et ses `TonEtat`.
- Tuiles d'icône sur fond coloré (rose, orange, vert, violet) des indicateurs W04, des annonces et de la file de modération ; avatars colorés des canaux de la maquette sombre ; icône PDF rouge.
- Points verts et gris de présence en ligne (W01, W03).
- Cœurs rouges, émojis de réaction, bouton d'envoi rond violet plein, interrupteurs violets, bouton flottant « Nouvelle publication » en pilule.
- Capsules d'onglets pleines (« Messages métier / Communauté / Le Studio ») et onglets de catégories en pilule lavande.
- Ombres portées et grands rayons des cartes, photos d'avatars, polices des maquettes (on garde DM Sans et Plus Jakarta Sans).
- Médaillons d'annotation des planches (« ContextThreadHeader… », traits pointillés) : légendes, pas des écrans.
- Coquille « Rewayah / Accueil / Foyer / Communications / Historique / Compte » et identité « Tuteur, Classe Al-Fajr » sur toutes les planches.

## 5. Conflits spec / dépôt / maquettes (spec §30.15)

Chaque conflit est signalé ici et non résolu en silence. Les points qui bloquent une étape sont dans QUESTIONS.md.

1. **Onglets « Messages métier / Communauté enseignants / Le Studio »** sur toutes les maquettes : contredit §0 (univers distincts), §6.1 (un enseignant n'entre pas dans le Studio), §14 (une fonction, un endroit). Non repris : chaque univers a sa propre entrée selon le rôle.
2. **COM-M01 montre un fil de Classe** où l'enseignant écrit « Bonjour à tous » et où deux familles (Ahmed, Fatima) se lisent : contredit §3.2 (Famille A / Famille B : jamais) et §13.3 (un message à toute la Classe est une annonce). Le fil COM-M01 est **un fil enseignant ↔ une famille**, contexte Classe et élève.
3. **COM-W01 liste « Classe An-Nour : Rappel, sortie scolaire »** parmi les fils : une annonce dans Messages, contre §13.3. Non repris.
4. **Shells pleins** : tuteur, enseignant, contrôleur et adulte ont 4 destinations sur 4 (`nav_shell.dart:389`, assertion). §21 l'admet pour le tuteur ; pour l'enseignant, §14 dit « Communauté : destination Enseignant » mais §21 « seulement si le shell validé l'intègre » et E10 l'a fixé à quatre. → Q2. Conséquence de Q2 sur JourneePage : point 23.
5. **Admin gelé à huit domaines** (`admin_shell.dart:20`, `admin_domaine.dart:12`) : W04 montre un domaine « Communications » et une barre inventée (Utilisateurs, Contenus, Paramètres). → Q4 (sous-domaine d'Opérations). Précision COM-0b : 7 domaines sont visibles, Direction masqué, 8 est un plafond (UX_REV-10, §1.2) ; cela ne change rien à Q4. L'entrée réelle est la ligne du tableau de bord et la recherche, pas le domaine Opérations (UX_REV-03, §3).
6. **Aucun rôle « équipe interne »** (`enums.dart:9`) alors que §6.1 en liste huit profils ; le contrôleur ne peut pas atteindre `/admin/*` (`routes.dart:612`). → Q1.
7. **Pas de cloche chez l'admin, l'enseignant et le contrôleur** (`admin_shell.dart:48-49`, `app_router.dart:1427-1446`) alors que §14 veut « cloche des shells ». Ajout par COM-F, Q5 répondue oui le 04/10 (complément ci-dessous), cloche sans point tant que le port est indisponible (comme le tuteur).
   Complément COM-0b (UX_REV-06, QUESTI-01) : cette absence vient de **trois décisions validées**, que l'ajout remplacerait : enseignant (`12_enseignant/V/00_MAQUETTES_ENSEIGNANT.md:51`, « cloche retirée », et `journee_page.dart:10-12`, retirée d'EN-2), contrôleur (`14_controleur/V/00_MAQUETTES_CONTROLEUR.md:56`, C13 ; `14_controleur/UX_REVIEW_08_CONTROLEUR.md:53`), admin (`admin_shell.dart:48-49`, « Pas de cloche tant qu'aucun service de notifications n'existe (Q5) », Q5 du chantier admin, commit `d3cb8575`). La spec demande de signaler un tel conflit avant de choisir (§30 point 15, l.1710). §14 (l.781) les remplacerait pour COM **sous réserve de la réponse du directeur à Q5** (question ajoutée dans `QUESTIONS.md`). **Réponse du directeur le 04/10 : oui pour l'enseignant, le contrôleur, l'admin et l'élève adulte.** Dans `_CoquilleNavigation`, cloche pour `AppRole.teacher` et `AppRole.controller` seulement (l'admin a la sienne dans l'`AdminShell`, §3 COM-M06), jamais pour `AppRole.student` (même branche `_CoquilleNavigation`, `app_router.dart:315-316`, `:1427-1434`), qui ne désigne que l'élève mineur créé par son tuteur (`student_type = 'minor'`, `0004_inscription_kyc_appairage.sql:892`) ; l'adulte autonome est `guardian` (`enums.dart:22`) : l'élève adulte a le rôle `guardian` et déjà la cloche du tuteur (UX_REV-09) ; la cloche ouvre le centre partagé, sans nombre en production. La cloche de la Classe live (§1.3, UX_REV-08) suit la même réponse.
8. **Modèle de notification** sans niveau, ni lu, ni type (`port_notifications.dart:9`) ; en production la source est indisponible (DB-CPT-04) : les filtres §13.1 ne se voient qu'en démonstration. COM-BR-09.
9. **Contrôleur : « Échanges »** (C13, `nav_shell.dart:198`) contre le lexique §22 « Messages ». On garde « Échanges » (décision plus ancienne mais validée et non contredite explicitement) ; aucun écran admin ne répond aujourd'hui à ces fils : l'onglet Messages de W04 les liste (COM-MSG-2).
10. **Vocal** : ni `record`, ni `permission_handler`, ni `url_launcher` dans `pubspec.yaml` (interdit de le modifier, K-19). Le composer vocal est entièrement derrière un port ; « Ouvrir les réglages » (§11.3) n'est pas possible → « Fermer » seulement. COM-BR-03.
11. **Réactions et compteurs « J'aime »** (cœurs 12, 8, 5) sur la Communauté : absents des §4 et §5.3, et §32 refuse le score de popularité. Non repris dans la Communauté ; dans le Studio, réactions secondaires (§10.4) sans compteur mis en avant.
12. **W02 « Ressources utiles »** (guides, modèles, audio téléchargeables) et sous-titre « de Classe An-Nour » : la Communauté est transversale, et un panneau de ressources concurrencerait la Bibliothèque (R14). Colonne droite = À propos + Règles (§23).
13. **W01 « Paramètres de la conversation » (Suivi, Mode silencieux)**, accusés de lecture (doubles coches), présence en ligne : aucun contrat ; non repris (COM-BR-09 pour un futur réglage).
14. **W03 « 1 événement »**, crayon « nouveau » dans la liste des canaux ; **maquette sombre** « Tâches », visio, « Nouvel espace », « Projets », « Travail », « Décisions » en navigation, « Favoris », ⌘K : hors §9, §14, §32. Navigation Studio = Aujourd'hui, Canaux, Recherche, Éléments enregistrés, Brouillons (§15).
15. **Taxonomie des canaux** : maquette (Organisation, Produit & Technique, Contenus pédagogiques, Qualité & suivi) contre §9.1 (8 sections). La spec prime.
16. **W04** : flèche de tendance « ↑ 3 », vues et commentaires sur les annonces (contre §13.3), ligne « Familles : peut publier Oui » (contre §13.4), file de modération contenant « Message d'un parent » (la modération §5.5 vise la Communauté, pas les fils métier). Non repris ; matrice sur capabilities ou fixtures marquées démonstration.
17. **Catégories de la Communauté** : la spec ne les liste pas ; la maquette montre Toutes, Pédagogie, Ressources, Gestion. Elles viennent du port ; la démonstration reprend ces quatre libellés, marqués démonstration. Non bloquant.
18. **Brouillons** : `StockagePreferencesDrift` existe mais n'est approuvé que pour des préférences ; `DraftPersistence` reste en mémoire de session (§8.2, §20).
19. **Élève adulte sans coquille adulte de production** sur la branche : la coquille à 4 destinations n'existe qu'en démonstration (`/demo/adulte`). Correction COM-0b (UX_REV-09) : en production, l'élève adulte a le rôle `guardian` (ADR-009, `enums.dart:22`), donc les entrées tuteur (coquille tuteur, `ClasseTuteurPage`, `/tuteur/notifications`). Ses entrées Communications de production sont celles du tuteur ; les tests d'entrée de COM-MSG-2 et COM-ANN-1 le couvrent par la voie tuteur.
20. **i18n en un seul fichier** (`fr.i18n.json`, `ar.i18n.json`) partagé par cinq voies parallèles, et fichiers générés `strings*.g.dart` : voir la règle de 02_DECOUPAGE (blocs réservés par COM-F, régénération slang à COM-FUS).
   Complément COM-0b (UX_REV-14) : le contrôle `libelle-sans-source` cherche chaque texte dans `docs/` (plus `--corpus`) sans retirer les accents (`tool/verifier_revue.dart:45`, `:285-300`). La spec COM est hors du dépôt et sans accents : les libellés accentués des voies doivent être déclarés dans `tool/libelles_sources.json` (`lib/CLAUDE.md:96`). C'est un **second fichier partagé**. **[COM-F]** le pose (une entrée par libellé du lexique §22, une ancre par voie) ; les ajouts des voies sont réunis à COM-FUS. Autre voie possible : lancer `verifier_revue` avec `--corpus=19_communications/V` et ne déclarer que les formes accentuées. Règle hors CI, d'où mineur.
21. **« admin » interdit au client** (`lib/CLAUDE.md:94`) : côté famille, l'interlocuteur s'affiche « Administration » ou « la direction », comme `controleur.echanges.auteurAdmin`.
22. **Revue enseignant validée contre Messages sur ENS-07 et cloche sur ENS-02** (02_DEC-11, renvoyé à COM-F). `12_enseignant/UX_REVIEW_04_ENSEIGNANT.md:54` (ENS-02, « Refuser : ... la cloche ») et `:60` (ENS-07, « Refuser : ... « Messages » », K-42 points 4 à 6) ; `fiche_groupe_page.dart:39`. COM-0 posait « Messages de la Classe » et les annonces dans `FicheGroupePage`, et une cloche dans la coquille enseignant, sans le signaler. Règle retenue : l'entrée de COM-MSG-2 dans `FicheGroupePage` reste **contextuelle** (un fil avec une famille ou sur un élève, §3.2), jamais un bloc « Messages » général ; le libellé « Messages de la Classe » (absent de la spec) n'est pas repris. La cloche est dans la **coquille**, jamais dans la page ENS-02 (Q5 répondue oui le 04/10, point 7).
23. **JourneePage limitée à quatre blocs** (K-42, `journee_page.dart:3-5`) contre le raccourci « Communauté enseignants » retenu par Q2 (UX_REV-01, sans rouvrir Q2). Le raccourci n'est pas un 5e bloc : c'est une ligne dans un bloc toujours rendu (« Alertes utiles » ne l'est pas, `:4-5`). **[COM-F]** pose l'emplacement vide dans `journee_page.dart` ; COM-COMU-1 le remplit depuis `com_communaute/`, ce qui respecte la règle 3 du découpage (la voie ne rouvre pas la page hôte, 02_DEC-10). Le test vérifie qu'il reste quatre blocs au plus.
24. **AdminShell sans action d'en-tête sous 600** (`admin_shell.dart:159-162`, `_BarreMobile` « Rien d'autre n'y vit », `:704-708`) contre Q1 (« Le Studio » dans l'en-tête) et la cloche admin (UX_REV-02, sans rouvrir Q1). **[COM-F]** pose « Le Studio » et la cloche (Q5) aussi pour le gabarit barre basse (`_BarreMobile` ou `_Tiroir`). Fichier déjà attribué à COM-F, pas de conflit. En production, le Studio affiche l'état indisponible (règle des ports, `COM-BR.md`).

## 6. Ce que COM-0 n'a pas vérifié

- Le rendu réel des écrans (aucun Flutter lancé) : les entrées proposées seront prouvées par un test qui tape le vrai bouton (K-07) à COM-MSG-2, COM-COMU-1, COM-ANN-1, et à COM-STU-1 pour « Le Studio » à 390 (barre basse admin, UX_REV-02). Ajout COM-0b : Q5 posant les cloches (réponse du 04/10), un test COM-F avec un compte à **plusieurs espaces** vérifie que la cloche et le raccourci Espaces sont visibles tous les deux (un compte à un seul espace ne voit pas le masquage, 02_DEC-03).
- La page « Espace Classe enseignant » exacte pour publier une annonce : `FicheGroupePage` d'après `SortieEspaceClasse` (`fiche_groupe_page.dart:116`) ; COM-ANN-1 confirme en lisant la page.

## 7. Ce qui touche COM-F (ajouts COM-0b)

Liste des ajouts de ce document qui changent le travail du socle. Les fichiers à ajouter à la liste de COM-F sont tenus dans `02_DECOUPAGE.md` ; ici, seulement le pourquoi et l'emplacement.

| Id | Ce que COM-F fait | Où c'est écrit ici |
|---|---|---|
| UX_REV-01 | Poser l'emplacement vide de la ligne « Communauté enseignants » dans un bloc toujours rendu de `journee_page.dart` (pas un 5e bloc, pas « Alertes utiles ») ; COM-COMU-1 le remplit | §3 COM-M02, §5 point 23 |
| UX_REV-02 | Poser « Le Studio » aussi dans la barre basse admin (`_BarreMobile` ou `_Tiroir`), en plus de l'en-tête à partir de 600 ; même chose pour la cloche admin (Q5) | §3 COM-M03, COM-M06 admin, §5 point 24 |
| UX_REV-03 | Poser la ligne « Communications » dans la `CarteLignes` de `TableauDeBordPage`, et la cible de recherche ; pas d'entrée par le domaine Opérations | §3 COM-W04 |
| UX_REV-06, QUESTI-01 | Poser la cloche de l'enseignant, du contrôleur et de l'admin (Q5 répondue oui le 04/10) ; jamais pour `AppRole.student` (l'élève mineur) ; l'élève adulte garde la cloche du tuteur | §3 COM-M06, §5 point 7 |
| 02_DEC-03 | Pour l'enseignant et le contrôleur (Q5), une seule liste d'actions dans `app_router.dart` (`RaccourciEspaces` puis la cloche), jamais un second `ActionsEnteteCoquille` ; test avec un compte à plusieurs espaces | §1.3, §3 COM-M06, §6 |
| UX_REV-07, UX_REV-11 | Chaque route de notifications passe son `onRetour` vers la racine du rôle ; `/admin/notifications` dans `_CoquilleAdmin(domaine: AdminDomaine.accueil)` | §1.3, §3 COM-M06 |
| UX_REV-12 | Tout port COM neutre lève `CapaciteIndisponible('COM-BR-nn')`, jamais `StateError` | §1.6 |
| UX_REV-14 | Poser `tool/libelles_sources.json` comme fichier partagé (ou lancer `verifier_revue` avec `--corpus`) | §5 point 20 |
| 02_DEC-11 | Aucun bloc « Messages » dans `FicheGroupePage`, entrée contextuelle seulement ; cloche dans la coquille, jamais dans ENS-02 | §3 COM-M01 enseignant, §5 point 22 |
| QUESTI-07 | Ne pas ajouter « Notifications » à `ongletsConfiguration` | §1.2 (notes) |

Hors COM-F : UX_REV-04 (recherche des fils, COM-MSG-1), UX_REV-08 (cloche de la Classe live, COM-ANN-1, Q5 répondue), UX_REV-09 (élève adulte par la voie tuteur, tests COM-MSG-2 et COM-ANN-1), UX_REV-10 (texte seulement), UX_REV-13 (conflit CTRL-MSG-1 à COM-FUS).
