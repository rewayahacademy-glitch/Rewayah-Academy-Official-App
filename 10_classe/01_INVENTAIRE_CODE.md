# 01 - Inventaire du code existant pour « Classe et visio »

Date : 25/09/2026. Worktree `C:\RA\depot`, branche `ui/tuteur-v1`, commit `3b41b12`.
Lecture seule, aucune modification. Source spec : `C:\Users\Dynah\Downloads\Classe\02_CLASSE_ET_VISIO.md` (écrans CLV-01 à CLV-10, §8).
Source registre : `C:\RA\ressources\registre\00_REGISTRE.md` (daté 24/09, sur `main` @ `4a7aa2b` et `ui/tuteur-v1` @ `436c290` — le commit courant `3b41b12` est postérieur, certains constats du registre y sont donc déjà dépassés, signalé au cas par cas).

But : ne rien recoder qui existe déjà. Conclusion courte : **le socle vidéo/salle est largement écrit et branché** (deux salles réelles, pas des maquettes). Ce qui manque surtout, c'est la **consolidation en une seule salle canonique `/salle`** exigée par la spec, et le **branchement réel** de plusieurs pièces déjà écrites (Teaching Dock, support partagé, cahier).

---

## 1. Dépendances

- `livekit_client: ^2.12.0` **présent** — `C:\RA\depot\pubspec.yaml:47`. Dépendance transitive `flutter_webrtc` (audit historique la donnait en 1.6.0).
- `supabase_flutter: ^2.17.2`, `go_router: ^18.0.1`, `flutter_riverpod: ^3.4.3` — présents, `pubspec.yaml:16-20`.
- Import du SDK LiveKit strictement confiné à `lib/core/video/` : `lib/core/video/livekit_session_provider.dart` et `lib/core/video/pre_vol.dart` (seuls fichiers du dépôt à importer `package:livekit_client`, règle vérifiable par grep, cf. `docs/archive/2026-09-pre-remise-a-plat/parallel-reports/SOCLE_SALLE_REPORT.md:261-272`).
- Aucune URL/clé LiveKit en dur côté Flutter (confirmé par l'audit `docs/archive/.../parallel-reports/02-livekit-audit.md:112-133`).

## 2. Routes et écrans existants vs CLV-01..10

**Point dur non résolu** : la spec §0 et §3 exige une salle unique `/salle` ; le dépôt a **deux implémentations réelles et concurrentes**, exactement comme la spec le décrit en «CONFLIT» :

| Route | Fichier | Rôle actuel |
|---|---|---|
| `/salle` (`Routes.salle`, `routes.dart:454`) | `lib/features/salle/salle_page.dart` (1486 lignes) | Salle générique élève/enseignant/tuteur observateur/contrôleur, pilotée par le rôle du **jeton** LiveKit, pas par le rôle de compte |
| `/tc/classe` (`Routes.tcClasse`, `routes.dart:510`, `RoutesTcE.classe`, `lib/features/tc_classe_live/routes_tc_e.dart:30`) | `lib/features/tc_classe_live/classe_live_page.dart` (743 lignes) | « Classe Live » : même moteur vidéo, mais session persistante inter-écrans (ne quitte pas LiveKit en naviguant), roster pédagogique, slot support/bibliothèque/dock |

Correspondance avec les écrans de la spec (à partir du code réellement branché) :

| Écran spec | État | Preuve |
|---|---|---|
| CLV-01 Espace Classe élève | **partiel** — route actuelle `/tc/groupes/:groupeId` (`EspaceGroupePage`), pas encore le contrat `get_student_class_home` ni le layout desktop 3-colonnes décrit | `lib/features/tc_mes_groupes/routes_tc_a.dart:34-53` |
| CLV-02 Espace Classe enseignant | **absent/à vérifier** — pas trouvé d'équivalent enseignant symétrique à `EspaceGroupePage` dans ce grep ; `/enseignant/groupe/:groupeId` existe comme route (`routes.dart:317-320`) mais fiche non lue en détail | `routes.dart:317` |
| CLV-03 Préparation technique enseignant | **partiel** — `pre_vol.dart`/`preVolProvider` fait la vérification micro/réseau/caméra, mais pas de surface dédiée `Entrer dans la séance` isolée trouvée à ce commit | `lib/core/video/pre_vol.dart` |
| CLV-04 Salle élève standard | **existe** — `salle_page.dart` couvre micro/caméra/reconnexion/observation/support si branché | `lib/features/salle/salle_page.dart:64-371` |
| CLV-05 Salle Interface guidée | **partiel** — même moteur que CLV-04, mais pas de rendu "guidé" à cibles 72dp/dock 3-4 boutons identifié séparément ; à confirmer si `salle_page.dart` sait déjà distinguer profil guidé | non confirmé dans le temps alloué |
| CLV-06 Salle enseignant | **existe** — `ClasseLivePage` a roster, support dominant, dock flottant, sortie « Terminer pour moi » (`quitterQuestion`/cahier) | `lib/features/tc_classe_live/classe_live_page.dart:812-861` (texte i18n `tc.classe.commandes`) |
| CLV-07 Roster enseignant | **existe** — `PanneauRoster`, `RosterClasseVM`, `TeacherStudentProjection`, fiche élève (`FicheSeance`) | `lib/core/tc_classe/roster_classe_vm.dart`, `roster_enseignant.dart`, `classe_live_page.dart:252-283` |
| CLV-08 Choix du support | **écrit, NON branché en salle réelle** — `ClassLibraryPicker` existe et est référencé par `ContexteClasseLive.bibliotheque`, mais l'unique appel réel `_rejoindre()` ne remplit ni `support`, ni `dock`, ni `bibliotheque` | `lib/features/tc_mes_groupes/routes_tc_a.dart:70-82` (aucun de ces 3 champs passé) |
| CLV-04/05/06 support partagé | **contrat écrit, tuyau non branché** — `SharedContentState`/`ContenuPresente` existent (canal LiveKit data), mais `contexte.support` reste `null` sur le seul chemin de navigation réel | `lib/core/tc_etat_partage/shared_content_state.dart`, `lib/core/video/video_session_provider.dart` (§ »ContenuPresente« du rapport SOCLE_SALLE_REPORT) |
| Reconnexion (états) | **existe et testé** — `EtatSalle{absent,connexion,connecte,instable,reconnexion,retabli,echec}`, `PhaseSalle`, textes "Connexion interrompue…"/"Connexion rétablie." | `lib/features/salle/vue_salle.dart`, `SOCLE_SALLE_REPORT.md:107-121` |
| Notice observation tuteur | **existe et branché** — `IndicateurObservationEnfant` (élève), `IndicateurObservation`/`annoncesObservationProvider` (enseignant), lues via RPC `annonce_observation_pour_moi`/`annonces_observation` | `lib/features/salle/salle_page.dart:293-334, 496-519`, `lib/features/tc_classe_live/classe_live_page.dart:328-354` |
| CLV-09 Fin de séance élève | **partiel** — sortie gère le retour, pas d'écran bref dédié identifié séparément (à vérifier) | `salle_page.dart:193-241` |
| CLV-10 Passage au cahier | **existe** — `Routes.cahierPour(sessionId)` → `ENS-04`, déclenché à la sortie enseignant si un cours a eu lieu | `lib/core/router/routes.dart:313-314`, `salle_page.dart:204-227` |
| Barre de reprise « Revenir à la séance » | **non retrouvé** à ce commit sous ce nom exact (le registre 24/09 indiquait `barre_cours_en_cours.dart` non branchée, 0 importeur) — grep de ce commit ne trouve aucun fichier de ce nom ni de ce composant | grep négatif, cf. §5 point 2 |

Vocabulaire interdit par la spec (§6.2) encore présent en dur dans le code/i18n à vérifier avant la vague : `groupe`, `room`, `LiveKit`, `token` apparaissent largement dans les noms de fichiers et commentaires internes (acceptable, ce sont des identifiants techniques) mais méritent une passe sur les **textes visibles** (`t.*`) avant livraison.

## 3. Couche données : repositories/providers/RPC vs contrats §8

Aucun nom de RPC du §8 (`get_student_class_home`, `get_teacher_class_home`, `request_session_join`, `refresh_session_join`, `get_session_shared_state`, `publish_session_shared_state`, `get_session_teacher_roster`, `send_student_nudge`, `get_session_recording_state`, `get_session_observer_notice`, `attendance_event_ingest`, `get_attendance_live_projection`, `finalize_attendance`, `prepare_teacher_notebook`) n'existe **littéralement** dans `supabase/migrations/*.sql` (grep exact = 0 résultat). La spec le prévoyait déjà (« ce sont des contrats cibles », §8) : il faut **mapper l'existant avant de créer un doublon**. Équivalents fonctionnels déjà en base (`supabase/migrations/0033_tc_vues_rpc.sql`) :

| Besoin du §8 | Équivalent trouvé | Ligne |
|---|---|---|
| `request_session_join` / jeton | `autoriser_jeton_video(...)`, appelé par la edge function `create-room-token` | `0033_tc_vues_rpc.sql:1643` ; `supabase/functions/create-room-token/index.ts` |
| Webhook présence signé (`attendance_event_ingest`) | edge function `livekit-webhook`, RPC `enregistrer_webhook_livekit` | `supabase/functions/livekit-webhook/index.ts` |
| Présence dérivée | `etat_presence(...)`, vue `presence_seance_v` | `0033_tc_vues_rpc.sql:1535` |
| `get_session_shared_state` / `publish_session_shared_state` | `publier_etat_partage(...)` | `0033_tc_vues_rpc.sql:868` |
| `get_session_teacher_roster` | `groupe_roster_enseignant(...)` | `0033_tc_vues_rpc.sql:787` |
| `get_session_observer_notice` | `entrer_observation`, `sortir_observation`, `visites_observation`, `annonces_observation`, `annonce_observation_pour_moi` | `0033_tc_vues_rpc.sql:1086-1304` |
| Horloge de séance | `horloge_seance(p_session_id)` | `0033_tc_vues_rpc.sql:427` |
| `prepare_teacher_notebook` | à vérifier — pas trouvé de RPC dédiée « cahier », probable **à créer** | non trouvé |
| `get_student_class_home` / `get_teacher_class_home` | pas de RPC équivalente identifiée ; l'écran élève actuel (`EspaceGroupePage`) semble composer plusieurs lectures côté client plutôt qu'un contrat unique — **à créer ou à extraire** | non confirmé |

Couche Flutter (providers/repositories déjà écrits, réutilisables) :

- `lib/core/video/video_session_provider.dart` + `livekit_session_provider.dart` — contrat moteur salle (accès, capacités, états, participants, qualité, `ContenuPresente`).
- `lib/core/video/service_video.dart` — appel `create-room-token`, inscription tuteur/contrôleur, `annoncerSortie`.
- `lib/core/presence/service_presence.dart`, `presenceSeanceProvider` — lecture présence pour l'écran.
- `lib/core/tc_classe/session_persistante.dart`, `ControleurSessionPersistante` — le contrôleur qui garde LiveKit vivant pendant la navigation interne, exactement l'exigence de la spec §2.4 (« la salle continue d'exister pendant la navigation »).
- `lib/core/router/billet_salle.dart` (`BilletSalle`) — billet d'entrée non sérialisé dans l'URL, correspond à l'exigence spec « aucun lien public de salle », déjà implémenté pour `/salle` (durée 20 min).
- `lib/core/tc_etat_partage/*` — `SharedContentState`, service, ports (persistant + éphémère), codec. Écrit, testé, mais son seul consommateur réel à ce commit est le lecteur du Coran (`lib/core/coran`), pas encore la salle (cf. §2 ci-dessus).
- `lib/core/tc_observation/*_supabase.dart` — historiques d'observation admin/tuteur déjà câblés en Supabase.

## 4. Composants réutilisables déjà présents

- `PageImmersive` (`registre: RegistreImmersif.salle`) — gabarit d'écran immersif déjà utilisé par les deux salles ; à réutiliser pour toute nouvelle surface CLV.
- `PermanentNotice` — bandeau permanent unique (enregistrement), déjà partagé par les deux salles (`salle_page.dart:553`, `classe_live_page.dart:415`).
- `IndicateurObservation` / `IndicateurObservationEnfant` (`lib/features/tc_observation_ui/indicateur_observation.dart`) — le même composant sert déjà côté élève et côté enseignant dans les deux salles.
- `StatusPill`, `LignePresence`, `AvatarTile`, `ConfirmDestructive`, `AppBottomSheet`, `ActionPrincipale` — briques `core/widgets` déjà employées par les deux salles, directement réutilisables pour CLV-04/05/06/07/08.
- `_Galerie`/`_Cadre`/`_Seul`/`_ListePresence` de `salle_page.dart` — galerie vidéo adaptative (1 à 6 participants), **privée au fichier**, pas encore promue dans `lib/core/widgets/` (dette assumée, cf. `SOCLE_SALLE_REPORT.md` §3.5 et §7 point 4). À réutiliser en la promouvant plutôt qu'en la réécrivant si CLV-05 (Interface guidée) a besoin d'une scène similaire.
- `RosterClasseVM`, `PanneauRoster`, `FicheSeance` (`tc_classe`) — correspond directement à CLV-07.
- `ClassLibraryPicker`, `EmplacementBibliothequeEnClasse`, `SurfaceBibliotheque` (`tc_catalogue`) — correspond directement à CLV-08, écrit mais pas branché (cf. §2).
- `TeachingDock`, `CoucheAnnotation`, `BarreStylet`, `PuceIntention` (`lib/features/tc_dock/`) — correspond à l'« outils pédagogiques contextuels » de CLV-06, écrit et déjà consommé ailleurs (`travail_classe_page.dart`) mais **pas branché dans `ClasseLivePage.dock`** (le seul appelant réel, `routes_tc_a.dart:70-82`, ne fournit pas ce champ).

## 5. Code du registre non livré, réutilisable pour cette vague

D'après `00_REGISTRE.md` (24/09) — à revérifier au commit courant, plusieurs éléments semblent déjà avoir avancé depuis (voir notes) :

1. **Teaching Dock + `tc_outils`** (registre item 1) — toujours partiellement débranché de la salle live à ce commit (confirmé au §4 ci-dessus). Réutilisable directement pour CLV-06 une fois câblé, mais l'enregistrement des annotations renvoie volontairement une erreur « aucune implémentation serveur » (`port_annotations.dart`, cité par le registre) : prévoir le contrat serveur avant d'activer l'UI.
2. **Synchronisation temps réel (`tc_realtime`)** (registre item 2) — le registre disait « transport indisponible par défaut » ; à ce commit `tc_realtime` est importé par `tc_etat_partage` (`providers_tc_etat_partage.dart`, `service_etat_partage.dart`), donc le tuyau existe mais reste **non branché à la salle** (§2/§3 ci-dessus).
3. **`tc_etat_partage` / reprise après coupure** (registre item 3) — toujours « utilisé seulement par le lecteur du Coran » à ce commit (confirmé, §2/§3), c'est exactement le contrat `SharedContentState`/`get_session_shared_state` demandé par la spec P07 et §8 : à câbler dans la salle plutôt qu'à réécrire.
4. **Après-cours prérempli** (`post_cours_vm.dart`, `port_post_cours.dart`, registre item 4) — correspond à CLV-10/cahier ; le fournisseur de données renvoyait une erreur volontaire au 24/09, à vérifier avant de s'appuyer dessus pour `prepare_teacher_notebook`.
5. **Bibliothèque ouverte pendant le cours** (registre item 8) — le registre le disait à 0 importeur ; **dépassé à ce commit** : `class_library_picker.dart` est bien importé par `classe_live_page.dart`/`slots_tc_classe.dart` (§4), reste seulement le branchement du champ `bibliotheque` au moment de la navigation réelle (§2).
6. **Barre « Cours en cours »** (`barre_cours_en_cours.dart`, registre item 9) — confirmé absent de ce commit (grep négatif), correspond exactement à la « Barre de reprise d'une salle active » exigée par la spec §2.4/§3 : **à créer**, rien à réutiliser tel quel.
7. **Seconde salle « Classe Live » et doublon `/salle`/`/tc/classe`** (registre item 15) — **toujours vrai à ce commit** (§2) : c'est exactement le point que la spec §0 demande de trancher (« consolidées par l'agent d'intégration »).
8. **Indicateur « on t'observe » côté enfant** (registre item 19) — **dépassé, déjà branché** dans les deux salles à ce commit (§2, §4).
9. **Vraies classes / horloge serveur au lieu de démonstration** (registre item 25) — probablement avancé dans `ui/tuteur-v1` (le registre le signalait déjà repris dans cette branche `436c290`) ; `SessionClockVM`/`horloge_seance` existent en base (§3) — à confirmer que `EspaceGroupePage` les consomme réellement plutôt qu'une donnée de démonstration.
10. **Observation, partie écran** (registre item 27) — le registre disait « repris dans `ui/tuteur-v1`, fermé hors développement » ; à ce commit le code d'observation (annonces, `entrer_observation`) est actif dans les deux salles (§2), la question de la fermeture « hors développement » (`env.dart`) reste à vérifier.

## 6. Tests existants liés

- `test/features/salle_test.dart`, `test/features/salle_enseignant_test.dart` — salle `/salle`.
- `test/video/modeles_video_test.dart`, `test/video/vue_salle_test.dart` — modèles moteur vidéo, `VueSalle`.
- `test/teaching_core/e/classe_live_page_test.dart`, `pre_cours_test.dart`, `roster_test.dart`, `session_persistante_test.dart`, `vue_classe_live_test.dart`, `pii_test.dart`, `rappel_discret_test.dart` — `ClasseLivePage` et sa périphérie.
- `test/teaching_core/q/*` — `q05_etat_partage_restauration_test.dart` (reprise après coupure du support), `q12_navigation_session_persistante_test.dart`.
- `test/teaching_core/f/adaptateur_transport_livekit_test.dart` — adaptateur transport LiveKit du canal de données.
- `test/router/navigation_test.dart`, `redirection_test.dart`, `chemin_retour_test.dart` — garde de routes, y compris `/salle`.
- `test/features/classe_tuteur/*` (catalogue, capture, échelle de texte) — probablement issus du chantier Tuteur, à vérifier s'ils recoupent CLV-01/08.
- Aucun test trouvé qui exerce les deux salles ensemble contre l'exigence « une seule instance, jamais une seconde room » de la spec §2.4/§9.7 — à écrire.

## 7. Risques et pièges repérés

1. **Deux salles réelles concurrentes** (`/salle` et `/tc/classe`), toutes deux fonctionnelles et testées : la consolidation demandée par la spec est un vrai chantier de fusion, pas un choix entre une maquette et du réel.
2. **`ContexteClasseLive.support/dock/bibliotheque/onNoter/onSignaler` ne sont jamais remplis** au seul point d'entrée réel (`routes_tc_a.dart:70-82`) : le support partagé, le Teaching Dock et le cahier existent en code mais sont **invisibles en pratique** dans `/tc/classe` — piège classique déjà documenté par le registre (« code existe, dernier geste manque »).
3. **Aucune RPC du §8 n'existe sous ce nom exact** : risque réel de créer des doublons (`get_student_class_home` vs logique déjà éclatée dans `EspaceGroupePage`) si l'agent d'intégration ne mappe pas d'abord `0033_tc_vues_rpc.sql`.
4. **`_Galerie`/`_Cadre` de `salle_page.dart` sont privés**, non promus dans `lib/core/widgets/` à cause d'un test de catalogue déjà rouge : toute réutilisation pour CLV-05 doit soit dupliquer (dette), soit lever cette dette en amont.
5. **Fournisseur LiveKit distant non confirmé en exploitation réelle** (compte, URL wss, webhook déclaré) selon l'audit du 14/09 — à revérifier avant toute recette CLV-09.
6. **Barre de reprise « Revenir à la séance »** exigée par la spec §2.4/§3 n'existe pas du tout dans le code (confirmé par grep négatif) : c'est une pièce neuve, pas une pièce à réutiliser.
7. **Le registre du 24/09 est partiellement dépassé** par ce commit (`3b41b12` > `436c290`) : plusieurs statuts « non branché » se sont révélés faux à la vérification (bibliothèque, indicateur observation) — ne pas se fier au registre seul sans revérifier au commit courant.

---

## Résumé (10 lignes)

Le socle vidéo LiveKit (`livekit_client 2.12.0`, jeton signé côté serveur, webhook, présence) est écrit, branché et testé dans deux salles réelles et concurrentes : `/salle` (`salle_page.dart`) et `/tc/classe` (`classe_live_page.dart`), exactement le doublon que la spec §0 demande de fusionner. Les briques CLV-04/06/07 (média, roster, observation tuteur) fonctionnent déjà dans les deux. Le support partagé (`SharedContentState`) et le Teaching Dock existent en code mais ne sont pas câblés au seul point d'entrée réel de la Classe Live (`routes_tc_a.dart`), donc CLV-08 et les outils enseignant sont invisibles en pratique malgré le code écrit. La « barre de reprise » de session active n'existe pas du tout. Aucune RPC du §8 de la spec n'existe sous son nom cible ; des équivalents fonctionnels existent dans `0033_tc_vues_rpc.sql` et doivent être mappés avant toute création. CLV-01/02 (Espace Classe) restent à contrats à créer ou extraire. Le registre du 24/09 est partiellement dépassé par le commit courant : plusieurs statuts « non branché » se sont avérés faux à la revérification, donc toute décision doit revérifier au commit courant plutôt que citer le registre seul. Aucun test n'exerce encore la règle « une seule salle, jamais deux ». Priorité recommandée pour l'agent d'intégration : décider laquelle des deux salles devient `/salle` canonique avant d'écrire le moindre nouvel écran CLV.
