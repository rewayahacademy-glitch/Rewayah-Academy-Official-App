# C07 - Observation tuteur : cartographie du code, du serveur et des écarts

Date : 24/09/2026. Agent de cartographie C07, phase LECTURE SEULE.
Checkout lu : `D:\RA _APP\RA -OFFICIAL-APP` sur `c0/configuration-baseline-2026-09-23`. Pour tous les fichiers
cités ici, le code est identique à `main` : le diff `main..HEAD` sur `lib/core/tc_observation`,
`lib/features/tc_observation_ui`, `accueil_famille`, `salle`, `core/video`, `admin_groupes` et
`supabase/migrations` ne contient que des lignes de commentaire (liens réécrits vers `docs/archive`). Les numéros
de ligne sont ceux du checkout C0.

Légende des statuts : **CODE** = ce que le code fait (lu) ; **PRÉTENDU** = ce qu'un commentaire ou un document affirme ;
**MESURÉ PROD** = requête en lecture seule faite par moi aujourd'hui ; **REVENDIQUÉ** = mesure affirmée par un
document ou une archive, non refaite par moi ; **DÉDUIT** = conséquence logique du code, non exécutée.

## 0. Ce que j'ai fait, et ce que je n'ai pas fait

- Lu : brief, `CLAUDE.md`, `lib/CLAUDE.md`, le mandat (deux parties), `docs/current/01`, `08`, bilan C0, les 20 fichiers
  `lib/core/tc_observation` + `lib/features/tc_observation_ui`, les usages dans `salle`, `accueil_famille`,
  `tc_classe_live`, `core/video`, `admin_groupes`, `admin_journal`, `core/admin`, les migrations `0010`, `0012`,
  `0032`, `0033`, `0036`, `0037`, les migrations `0039`-`0042` de `observation/lot-2026-09-21` (via `git show`),
  l'Edge Function `create-room-token` du dépôt, l'archive `_archive/2026-09-23_worktrees/RA_OBS/.../0043_autoriser_jeton_video_verifie_le_bon_compte.sql`,
  les trois images d'observation du dossier `docs de lancement\tutuor image\`.
- Production (projet `gggmtelinlpseweouyav`), **lecture seule** : `list_migrations`, `get_edge_function create-room-token`,
  un `SELECT` sur `app_config`, les droits et les compteurs (aucune écriture, aucune ligne laissée).
- Git : `log`, `diff`, `show`, `ls-tree`, `worktree list`, et un `git merge-tree --write-tree main observation/...`
  pour prévisualiser la fusion. **Transparence** : cette dernière commande écrit des objets arbre non référencés dans
  `.git/objects` (aucune ref, aucun fichier de travail, aucune branche modifiée).
- Aucun fichier du dépôt modifié, aucune branche changée, aucun test ni `flutter`/`dart` lancé.

## 1. Synthèse en douze faits

1. **Politique en production (MESURÉ PROD)** : `app_config` = `observation.activee: true`, `max_visits_per_session: 2`,
   `max_seconds_per_visit: 120`, `max_total_seconds: 240`, `policy_version: "a2"`. Posée par `0036` (appliquée le 21/09).
   Donc **2 visites x 120 s, 240 s au total** : c'est déjà la règle du mandat. Surcharge possible par groupe
   (`groupes.observation_source/_max_visites/_max_secondes/_max_secondes_par_visite`), réglée par l'admin.
2. **Mais le code de `main` et les specs actives disent encore « 1 visite, 120 s »** :
   `guardian_observation_policy.dart:74-84` (`defautsNormatifs`), `feuille_observation_groupe.dart:49-55` (replis
   `a1`/1/120), `docs/current/01_PRODUIT_ET_PARCOURS.md:30`. La branche d'observation réaligne le Dart
   (`guardian_observation_policy.dart:93-95` sur la branche), pas `docs/current/01`.
3. **Sur `main` (donc en production côté Flutter), le tuteur n'emprunte PAS la porte d'observation.** Le bouton
   « Assister » appelle `assister_seance` puis ouvre `/salle` (`accueil_famille_page.dart:180-197`,
   `service_video.dart:131-134`). Or `0041` a **révoqué** `assister_seance` pour `authenticated` en production
   (MESURÉ PROD : `assister_seance` auth=false). Le bouton « Assister » de la production échoue donc toujours
   (« Le cours n'a pas pu être rejoint... »). `/tc/observation/:seanceId` est enregistrée
   (`app_router.dart:600`) mais **aucun écran de `main` n'y navigue**.
4. **La vidéo est probablement coupée pour tous les rôles en production.** `0042` (appliquée, MESURÉ PROD : dernière
   migration `20260921133843`) a ajouté `if not public.app_account_valid() then raise` en tête de
   `autoriser_jeton_video` (`0042:198`). Cette fonction est appelée par `create-room-token` avec la **clé de service**
   (`create-room-token/index.ts:59-69`, `_shared/clients.ts:34-41`, version déployée identique, MESURÉ PROD) : `auth.uid()`
   y vaut NULL, donc `app_account_valid()` rend faux et tout jeton est refusé. REVENDIQUÉ par l'archive RA_OBS `0043`
   (« mesure en base : auth.uid()=<NULL>, app_account_valid()=f ») ; le correctif n'est ni appliqué ni commité
   (`docs/current/08` ligne 79, bilan C0 ligne 130). **Aucune observation réelle n'est vérifiable tant que ce point
   n'est pas corrigé côté serveur.**
5. **Le quota est tenu à l'entrée, pas à l'émission du jeton.** `entrer_observation` (appelée par le client, avec
   `auth.uid()` = tuteur) vérifie politique et quota avant d'ouvrir l'intervalle (`0037:102-131`). En revanche le
   contrôle « quota avant jeton » de `autoriser_jeton_video` appelle `budget_observation`, qui filtre sur
   `auth.uid()` (`0039:212,226,245`) : sous la clé de service, il calcule le budget d'un observateur NULL
   (0 visite, 0 s), rend toujours `peut_entrer = true` et `restant = 120`. DÉDUIT : le TTL de 120 s mesuré le 21/09
   prouve le plafond par visite, pas la prise en compte de la consommation réelle.
6. **Aucune fin de visite n'est imposée par le serveur.** Aucun appel `RoomServiceClient`/`removeParticipant` dans
   `supabase/` (Grep : 0 résultat). Le TTL LiveKit ne borne que l'entrée dans la salle (connaissance LiveKit, non
   vérifiée dans ce dépôt : un participant connecté n'est pas expulsé à l'expiration de son jeton). La fin est
   décidée par le client (`moteur_visite_observation.dart:279-281`, `:306-313`).
7. **Présence de l'enfant : non exigée par le serveur.** `entrer_observation` exige seulement qu'un enfant du foyer
   soit membre actif du groupe (`0037:102-113`), pas qu'il soit présent dans la séance.
8. **Un intervalle non fermé n'est jamais fermé.** Seule `sortir_observation` écrit `left_at`
   (`0039:331-349`) ; le webhook LiveKit date de `0010` et ignore la table ; `EntreeObservationPage.dispose` n'appelle
   pas la sortie (`entree_observation_page.dart:114-126`). PRÉTENDU le contraire : « le serveur referme l'intervalle
   à l'expiration du jeton » (`moteur_visite_observation.dart:251-253`, `entree_observation_page.dart:118-122`). Effet
   DÉDUIT : quitter la page sans « Quitter » (retour, fermeture d'onglet, crash) brûle la seconde visite (index unique
   `guardian_visit_ouvert_uidx`, `0032:478-480`, puis `temps_epuise`).
9. **Journal persistant : oui, table `guardian_session_visit` (`0032:449-492`)**, lisible par l'observateur lui-même
   et par l'admin (RLS `guardian_visit_self`, `guardian_visit_admin`), `SELECT` accordé à `authenticated`
   (MESURÉ PROD). RPC `visites_observation(p_session_id)` (`0033:1235-1257`). **0 visite, 0 groupe, 0 séance en
   production** (MESURÉ PROD). Aucun écran ne lit ce journal (`PortVisiteObservation.visites` n'a aucun appelant).
   Le motif de fin est pauvre : le seul écrit possible est `sortie_volontaire` (y compris quand le client ferme sur
   quota, `moteur_visite_observation.dart:316-331` appelle toujours `sortir`).
10. **Médias** : le jeton tuteur ne publie rien (`can_publish`/`video`/`data` faux, `0040:191` et suivantes), il est
    masqué (`hidden = true`, `0040:191`), mais `can_subscribe = true` sans filtre de piste : le client **reçoit**
    l'audio et la vidéo de tous les participants ; seul le client filtre l'affichage à l'enseignant et à un enfant
    (`vue_observation_tuteur.dart:36-70`). Le support partagé n'est jamais rendu (`entree_observation_page.dart:47-50`,
    `panneau_observation_tuteur.dart:101-106`).
11. **Notices** : enseignant « Tuteur de {prenom} observe » (`fr.i18n.json:2094`) ; enfant « Ton tuteur regarde le
    cours » (`fr.i18n.json:2096`). Sur `main`, aucune n'est montée dans une salle atteignable ; la branche
    d'observation les monte dans `/salle` et `/tc/classe`. Le libellé du mandat (« Votre parent... », « Votre
    maman... » si le lien est connu) n'existe pas, et aucune donnée serveur ne fournit le lien familial à l'enfant.
12. **Branches** : `observation/lot-2026-09-21` (`0bfc9e4`, worktree `D:/RA_OBS`) porte les migrations appliquées
    `0039`-`0042` et le branchement Flutter (Assister -> porte d'observation, notices). Fusion simulée dans `main` :
    un seul conflit, dans le fichier généré `lib/core/i18n/strings.g.dart`. `teaching-core/g-observation`
    (`3545f8c`, worktree `D:/RA_TC/g`) est **entièrement contenue dans `main`** (0 commit d'avance) : rien à en tirer.

## 2. Carte du code (checkout C0 = code de `main`)

### 2.1 `lib/core/tc_observation/` (domaine, ports, adaptateurs Supabase)

| Fichier | Ce que le code fait | Remarques |
|---|---|---|
| `guardian_observation_policy.dart` | `SourcePolitique` (academie/groupe/desactivee, `:9-37`) ; `GuardianObservationPolicy` lu depuis `politique_observation_effective` (`:91-108`) ; `plafondDeVisite = min(parVisite, restantTotal)` (`:161-167`) ; micro/caméra/data jamais lus, toujours faux (`:86-90`) | `defautsNormatifs` = 1 visite / 120 s / pas de plafond par visite (`:74-84`) : **périmé** vs prod |
| `guardian_session_visit.dart` | `RoleObservateur` (`guardian_observer`, `admin_masked`, `admin_visible`, `masked_controller`, `:14-54`) ; `FinDeVisite` (5 valeurs, `:57-87`) ; modèle d'une ligne du journal (`:100-182`) | `depuisJson` retombe sur `tuteur` et l'époque 1970 si clés absentes (`:118-138`) |
| `port_politique_observation.dart` | `MotifRefusObservation` (6 motifs, `:17-50`) ; `BudgetObservation` (`:60-120`) ; `PolitiqueObservationSupabase` : RPC `politique_observation_effective`, `budget_observation`, `definir_politique_observation_groupe` (5 args), relecture du budget toutes les 5 s (`:168`, `:210-248`) ; traduction d'erreur : `42883`/`PGRST202` -> `capaciteAbsente`, **tout le reste -> `reseau`** (`:301-304`) | Commentaires périmés : « aucune des quatre fonctions n'existe encore en base » (`:170-177`), « 0036 n'est PAS appliquée » (`:262-275`). Une violation d'index unique (23505) sera affichée comme panne réseau |
| `port_visite_observation.dart` | `entrer_observation(p_session_id, p_role)` (`:92-112`), `sortir_observation` sans avaler l'échec (`:115-125`), `visites_observation` (`:128-141`) | `visites()` : **aucun appelant** dans `lib/`. Commentaire périmé « aucune des trois fonctions n'existe » (`:77-84`) |
| `moteur_visite_observation.dart` | Machine `horsVisite -> demande -> enVisite -> terminee/refusee/indisponible` (`:15-33`) ; entrée (`:190-244`) ; fin locale quand le budget serveur dit 0 (`:279-281`) ou quand le décompte local tombe à 0 (`:306-313`) ; `_terminer` appelle `sortir` **pour toute fin**, y compris quota (`:316-331`) ; `dispose` ne ferme pas l'intervalle (`:254-257`) | Ne produit que `sortieVolontaire` et `quotaAtteint` ; `seanceTerminee`, `revocationServeur`, `deconnexion` ne sont jamais émis. Aucun lien avec l'état de la salle LiveKit |
| `vue_budget_observation.dart` | Compte à rebours borné par la dernière valeur serveur, jamais négatif, horloge reculée neutralisée (`:44-61`) ; `rangVisite = visitesUtilisees` (`:92`) | Pur, testé (`test/teaching_core/g/vue_budget_observation_test.dart`) |
| `port_annonce_observation.dart` | Relit `annonces_observation` toutes les 10 s pour l'enseignant (`:53`, `:61-121`) ; compose « Tuteur de {prenom} observe » (`:130-139`) | Côté enfant absent sur `main` (ajouté sur la branche) |
| `capacites_observateur.dart`, `mode_entree_admin.dart` | Tables de capacités par rôle, lisibles, jamais appliquées (`capacites_observateur.dart:55-88`, `mode_entree_admin.dart:78-105`) | Double documentaire ; `ProfilObservateur.ecartsAvecJeton` (`mode_entree_admin.dart:126-142`) **n'est appelé par aucun écran** |
| `echec_observation.dart` | `capaciteAbsente` / `reseau` / `reponseIllisible` ; seul `reseau` se réessaye (`:9-43`) | Commentaire périmé `:12-15` |
| `libelles_observation.dart` | Libellés refus / fin / unités (`:6-35`) | |

### 2.2 `lib/features/tc_observation_ui/` (écrans)

| Fichier | Ce que le code fait | Écart au mandat |
|---|---|---|
| `entree_observation_page.dart` | Page `PageShell` (sans barre, sans bouton retour : `page_shell.dart:114-134`). Choix -> `entrer_observation` -> si `enVisite`, demande de jeton `create-room-token` et contrôle que le rôle rendu est bien `guardian_observer` (`:240-306`, test `:260`), puis `moteurSalleProvider` (la seule `Room`). Gère la fin de visite pendant la connexion (`:285-299`). N'écoute que la liste des participants (`:105`), **pas l'état de lien** de la salle. En fin de visite : `EmptyState` sans action (`:182-189`) ; refus : `EmptyState` sans action (`:190-196`) | Pas d'entrée depuis une Classe, pas de retour, pas de « visites restantes » après la fin, pas de reconnexion affichée, pas de pré-vérification (budget) avant « Entrer » |
| `choix_entree_observation.dart` | Texte d'intro + bouton « Entrer » ; choix de mode pour l'admin seulement (`:58-102`) | N'affiche ni visites disponibles ni durée ; pas de « Comment ça marche ? » |
| `options_entree_observation.dart` | Qui observe : tuteur, admin (2 modes), contrôleur ; autres rôles refusés (`:33-56`) | |
| `panneau_observation_tuteur.dart` | Compteur « Visite {rang} sur {total} » + pastille « {n} s restantes » (seuil d'alerte 30 s, `:21`, `:148-173`) ; support = `EmptyState` « Le support partagé par l'enseignant s'affiche ici » (`:101-106`) ; deux vignettes enseignant / « Votre enfant » (`:108-119`) ; rappel micro/caméra fermés (`:124`) ; une seule commande : « Quitter » (`:126-130`) | Pas de « Son reçu », pas d'« Agrandir », format non `mm:ss`, support jamais rendu, composition en colonne de cartes (maquette : support dominant + 2 vignettes) |
| `vue_observation_tuteur.dart` | Ne laisse sortir que l'enseignant (`role == 'teacher'`) et l'enfant désigné par le serveur ; les autres sont comptés, jamais exposés (`:36-70`) | Un seul enfant ; frère ou soeur dans la même séance non exposé |
| `indicateur_observation.dart` | `IndicateurObservation` (enseignant, `:48-99`) ; `IndicateurObservationEnfant` (`:131-163`) **non monté** sur `main` (commentaire `:106-130`) | Remplacé sur la branche (oeil, prénoms repliables) |
| `etat_reglages_observation.dart`, `module_reglages_observation.dart` | Réglage admin par groupe : hériter / personnaliser / désactiver ; visites 1..10, total 30 s..30 min par pas de 30 s, plafond par visite borné au total (`etat_reglages_observation.dart:54-79`, `:105-111`, `:195-214`) | Commentaires « 0036 non appliquée » périmés (`module_reglages_observation.dart:28-31`, `:150-155`) |
| `routes_tc_g.dart` | `/tc/observation/:seanceId` (`:18-21`, `:37-45`) | Promue dans `routes.dart:338`, autorisée tuteur/admin/contrôleur par `redirection.dart:144-148`, enregistrée hors coquille tuteur (`app_router.dart:600` ; coquille tuteur `:236-277`) |

### 2.3 Entrées et chemins réels sur `main`

- **Tuteur** : `ChildCard` « Assister » visible seulement en phase `enCours` (`accueil_famille_page.dart:87-88`,
  `:358-359`, `child_card.dart:318-322`) -> `_assister` -> RPC `assister_seance` -> `go(Routes.salle, extra: BilletSalle)`
  (`accueil_famille_page.dart:180-197`). En production, `assister_seance` est révoquée (`0041:226`, MESURÉ PROD) :
  impasse garantie.
- **Porte d'observation** : aucune navigation vers `Routes.tcObservation` sur `main` (Grep `tcObservation|versObservation` :
  seulement les déclarations). Constat déjà écrit dans `entete_classe.dart:183-210` et `docs/current` (mémoire
  « Routes sans entrée : `/tc/observation/:id` »).
- **Enseignant** : l'annonce n'est montée que dans `tc_classe_live/entete_classe.dart:211-214`, écran sans entrée
  effective sur `main` ; la salle réellement utilisée (`/salle`) n'a aucune annonce sur `main`.
- **Admin** : Opérations > Groupes > action « Réglages d'observation » -> feuille (`groupes_page.dart:77-78`,
  `:226-227`, `:346-356`, `feuille_observation_groupe.dart:79-205`). Aucune vue des visites.

### 2.4 `/salle` quand le jeton porte `guardian_observer` (chemin historique « Assister »)

`VueSalle` connaît `RoleSalle.tuteurObservateur` (`vue_salle.dart:59`) ; rappel « Vous assistez au cours. Vous n'êtes
pas entendu. » (`salle_page.dart:480-485`) ; commandes micro/caméra non rendues faute de capacité
(`salle_page.dart:1240-1255`) ; **mais la scène affiche en galerie TOUS les participants distants**
(`vue_salle.dart:210-228`, `salle_page.dart:752-773`) avec leur nom (`salle_page.dart:908`). Aucun compteur, aucun quota.
Ce chemin ne respecte ni « pas de roster » ni la limite de temps ; il est de toute façon fermé côté serveur depuis `0041`.

### 2.5 `lib/core/video/`

- `ServiceVideo.assisterEnTuteur` (`service_video.dart:60-65`, `:131-134`) : seule porte utilisée par `main`, révoquée en prod.
- `AccesSalle` lit `role`, `capabilities` (dont `hidden`, `can_subscribe`) et `expire_le` (`video_session_provider.dart:40-99`).
- Moteur LiveKit : `RoomOptions(adaptiveStream, dynacast)` sans option d'abonnement sélectif (`livekit_session_provider.dart:124-141`) :
  abonnement automatique par défaut du SDK (connaissance du SDK, non vérifiée ici) donc réception de toutes les pistes.
- Nom affiché d'un participant = `p.name` sinon `p.identity` (`livekit_session_provider.dart:447`) ; le jeton ne pose
  aucun `name` (`_shared/livekit.ts:81-83`) : DÉDUIT, les vignettes enseignant/enfant du panneau afficheraient un UUID
  de profil comme prénom (`panneau_observation_tuteur.dart:108-119` lit `vue.enseignant?.nom`).

### 2.6 `lib/core/widgets/bandeau_observation.dart`

**Hors sujet tuteur** : bandeau d'une session d'observation par un **agent IA** en lecture seule (ADR-025,
`bandeau_observation.dart:10-34`), piloté par `SessionState.observation`. Ne pas le réutiliser pour le tuteur.

### 2.7 Admin

- `feuille_observation_groupe.dart` : lit les défauts d'Académie dans `app_config` via `ServiceConfiguration.lire`
  (`:29-60`, replis 1 visite / 120 s / `a1`, `:49-55`) et la politique du groupe via RPC ; écrit par
  `definir_politique_observation_groupe` (5 arguments, `0036:206-265`, appliquée). Couleur d'erreur via
  `Theme.of(context).colorScheme.error` (`:133`), à vérifier contre `verifier_jetons`.
- Défauts d'Académie : aucun écran ne les édite (`service_configuration.dart:119-131`), mais `ServiceConfiguration.ecrire`
  (`:83-89`) et la RLS `app_config_admin_update` (`0001_fondations.sql:973-974`) le permettraient sans backend
  (attention : `policy_version` se bumpe à la main pour l'Académie, alors qu'un groupe la bumpe par déclencheur).
- Journal d'audit (`admin_journal/journal_page.dart:595-617`) : `observation_entree`, `observation_sortie`,
  `observation_politique_groupe_modifiee` (écrits par `log_sensitive_access`, `0037:151-154`, `0039:352-355`) n'ont pas
  de libellé et s'affichent en code brut (`:617`).

### 2.8 Tests existants

`test/teaching_core/g/` (7 fichiers + faux + support), `test/teaching_core/q/q03_quota_observation_tuteur_test.dart`,
`test/features/observation_groupe_admin_test.dart`, `test/teaching_core/fixtures/fixtures_observation.dart`. Tous sur
doubles : aucun ne touche la base. Sur `main`, `q03` encode l'ancienne règle (« une seule visite, et la seconde est
refusée », `q03...:51`), corrigée sur la branche. Non exécutés ici.

## 3. Branches

### 3.1 `observation/lot-2026-09-21` (`0bfc9e4`, 11 commits hors `main`, worktree `D:/RA_OBS`)

Commits (21/09) : annonce enseignant, réglages admin depuis le groupe, fermeture de salle si la visite finit pendant la
connexion, jeton sur la visite en cours (`0039`), docs d'état, tuteur masqué et annonce enfant (`0040`), fusion de
`origin/main`, six surfaces d'invisibilité (`0041`), `etat_presence` fermée à `anon` + jeton vérifie le compte (`0042`).
`git diff main...branche --stat` : 26 fichiers, +3044/-265.

Changements Flutter (lus par `git diff`) :

| Fichier | Changement |
|---|---|
| `accueil_famille_page.dart` | « Assister » -> `go(Routes.tcObservation(seanceId))` (branche `:190-191`), retrait de `assisterEnTuteur` et du retour local |
| `salle_page.dart` | Élève : `IndicateurObservationEnfant` si `monTuteurObserveProvider` (branche `:300`, `:510`) ; enseignant : `IndicateurObservation` sur `annonces_observation` (branche `:313`, `:517`) |
| `classe_live_page.dart` | Même témoin enfant (branche `:353`) |
| `port_annonce_observation.dart` | `prenomEnfant` nu ; port enfant sur `annonce_observation_pour_moi` (branche `:205`, provider `:252`), relu toutes les 10 s, éteint sur toute erreur |
| `indicateur_observation.dart` | Oeil `AppIcons.observationEnCours` (`0xe220`), prénoms tronqués repliables derrière l'oeil à partir de 2 observateurs, libellé sémantique complet (branche `:169`, `:247`, `:389`) |
| `guardian_observation_policy.dart` | `defautsNormatifs` = 2 / 240 / 120 (branche `:93-95`) |
| `fr.i18n.json` | + `tc.observation.annonce.tuteursObservent` |
| tests | `q03` réécrit (2e visite acceptée, 3e refusée), `salle_test`, `accueil_famille_test`, `classe_live_page_test`, `ecrans_observation_test` |

**Inchangés sur la branche** : `entree_observation_page.dart`, `panneau_observation_tuteur.dart`,
`choix_entree_observation.dart`, `moteur_visite_observation.dart`, `port_visite_observation.dart`. Les lacunes d'écran
listées en 2.2 restent donc vraies après fusion.

Fusion simulée (`git merge-tree --write-tree main observation/lot-2026-09-21`) : un seul conflit,
`lib/core/i18n/strings.g.dart` (généré : se régénère par `dart run slang`). Le coordinateur décide ; la PR C0 ne contient
pas ces commits.

Migrations (appliquées en prod, identiques aux fichiers selon le bilan C0 `CONFIGURATION_BASELINE_2026-09-23.md:125-128`,
présence confirmée par `list_migrations` aujourd'hui) :

| Migration | Objet | Effet utile pour le front |
|---|---|---|
| `0039` | `budget_observation` : le quota de visites n'est exigé que s'il n'y a pas d'intervalle ouvert (`0039:285`) ; refus dès que `restant <= 0` (`:287`) ; `restant = min(reste total, reste de la visite)` (`:303`) ; clé informative `visite_en_cours` ; `sortir_observation` réparée (plus d'écriture de la colonne générée, `fin_de_visite = 'sortie_volontaire'`, `:331-349`) | La 2e visite devient possible ; le compte à rebours affiché = temps de la visite en cours ; sortie volontaire enfin enregistrable |
| `0040` | `autoriser_jeton_video` : `guardian_observer` masqué (`:191`) ; ACL `service_role` seul (`:264`) ; nouvelle RPC `annonce_observation_pour_moi` (`:270-312`) | Le tuteur n'apparaît plus dans la galerie LiveKit des élèves ; témoin enfant possible |
| `0041` | `session_peers_v` masque le tuteur (`:53`) ; `est_observateur_masque` reconnaît `guardian_observer` (`:94`) ; annonce enfant étendue au foyer (frères, `:179`) ; **révocation de `assister_seance`** (`:226`) | Casse le bouton « Assister » de `main` |
| `0042` | `etat_presence` bornée et fermée à `anon` ; **`app_account_valid()` en tête de `autoriser_jeton_video` (`:198`)** | Voir fait 4 : bloque vraisemblablement tout jeton vidéo |

### 3.2 `teaching-core/g-observation` (`3545f8c`, worktree `D:/RA_TC/g`)

`git log main..teaching-core/g-observation` = 0 commit ; `merge-base --is-ancestor` : ancêtre de `main`. Le lot G
d'origine (ports, moteur, écrans, `routes_tc_g.dart`) est déjà dans `main`. Ses documents (`TC_CONTRACT_REQUEST_G.md`,
`TC_AGENT_G_REPORT.md`) sont archivés dans `docs/archive/2026-09-pre-remise-a-plat/teaching-core/`. Rien à intégrer.

## 4. Politique actuelle : valeur, stockage, résolution, réglage

| Question | Réponse | Source |
|---|---|---|
| 1 visite / 120 s cumulées ? | **Non en production** : c'était la valeur `a1` jusqu'au 21/09 | `0033:981-984` (replis 1 / 120 / `a1`) |
| 2 visites de 120 s ? | **Oui en production** : `a2` = 2 visites, 120 s par visite, 240 s au total | MESURÉ PROD ; `0036:190-198` |
| Où est-elle stockée ? | Défauts d'Académie : `public.app_config` (clés `observation.*`, plus l'interrupteur global `observation.activee`) ; surcharge par groupe : colonnes `groupes.observation_*` + `observation_revision` | `0033:962-985`, `0036:190-198`, `0036:231-248` |
| Qui la résout ? | `politique_observation_effective(p_groupe_id)` : interrupteur global prioritaire, puis `desactivee`, `groupe` (version `groupe:<revision>`), sinon Académie | `0033:941-996` |
| Qui la règle ? | Admin seulement (`app_role() = 'admin'` et compte valide) via `definir_politique_observation_groupe` ; plafond par visite jamais nul, borné au total | `0036:206-265` |
| Quota par qui ? | **Par compte observateur** (`observateur_profile_id = auth.uid()`) et **par séance**, tous enfants confondus | `0039:208-249` |
| Version journalisée ? | Oui, `policy_version` sur chaque visite | `0037:142-148` |
| Et la spec active ? | `docs/current/01:30` dit encore « une visite, 120 secondes cumulées » : **contradiction** avec prod et mandat | à corriger par le coordinateur (doc) |

## 5. Ce que le SERVEUR garantit réellement (état production)

| Garantie attendue | Réalité | Preuve | Statut |
|---|---|---|---|
| Rôle tuteur et compte valide à l'entrée | Oui | `0037:79-81`, `:95-97` | CODE |
| Lien tuteur-enfant | Oui, **par appartenance au groupe** (enfant du foyer membre actif) | `0037:102-113` | CODE |
| Enfant **présent** dans la séance | **Non** | idem, aucune lecture de présence | CODE |
| Séance « en cours » | **Non strict** : fenêtre `join_opens_at` ou T-20 jusqu'à fin + 15 min ; statut de séance non lu à l'entrée (lu seulement au jeton) | `0037:89-92` ; `0042` (statut `ended/canceled` refusé au jeton) | CODE |
| Politique désactivée | Oui, refus `policy_desactivee` | `0037:115-119` | CODE |
| Quota de visites et de temps à l'ouverture | Oui, pour l'appelant ; l'intervalle est écrit après les contrôles | `0037:121-149`, `0039:285-287` | CODE |
| Quota au moment du jeton | **Aveugle** : `budget_observation` sous clé de service lit un observateur NULL -> toujours « peut entrer », restant = plafond par visite | `create-room-token/index.ts:59-69`, `0039:212-249`, `0042:232` | DÉDUIT (+ REVENDIQUÉ par l'archive `0043`) |
| Jeton borné | TTL = `min(token_ttl_seconds, restant)` = 120 s avec `a2`, mais calculé sur le budget NULL, pas sur la visite en cours | `0040:206` | DÉDUIT |
| Jeton émis du tout | **Probablement plus pour personne** depuis `0042` | `0042:198` + clé de service | REVENDIQUÉ (archive `RA_OBS/0043`, lignes 1-11), non re-mesuré |
| Fin de visite imposée | **Non** : aucune expulsion LiveKit ; fin décidée par le client | Grep `RoomServiceClient|removeParticipant` = 0 | CODE |
| Fermeture d'un intervalle abandonné | **Non** : seul `sortir_observation` ferme ; un intervalle ouvert bloque toute nouvelle visite (index unique) puis passe `temps_epuise` | `0032:478-480`, `0039:239-249`, `0039:331-349` | CODE + DÉDUIT |
| Motif de fin fiable | **Non** : `sortir_observation` écrit toujours `sortie_volontaire` | `0039:346` | CODE |
| Un seul intervalle ouvert par (séance, observateur) | Oui | `0032:478-480` | CODE |
| Aucune publication (micro, caméra, data) | Oui, décidé en base et signé | `0040` capacités ; `_shared/livekit.ts:95-107` | CODE |
| Tuteur invisible des autres élèves | Oui depuis `0040`/`0041` (galerie, `session_peers_v`, `session_events`) | `0040:191`, `0041:53-94` | CODE |
| Notice enseignant | Oui, RPC réservée à l'enseignant de la séance (prénom de l'enfant + secondes restantes de la visite) | `0033:1263-1302` | CODE |
| Notice enfant (lui seul, ou son foyer) | Oui, `annonce_observation_pour_moi` rend `{observe, depuis}` sans compteur | `0040:270-312`, `0041:141-190` | CODE |
| Droit résiduel après la visite | La ligne `session_participants` (`guardian_observer`) **n'est jamais retirée** : lecture de `session_shared_content` conservée (`ssc_participant_read`, `0032:427-436`) et, DÉDUIT, éligibilité à de nouveaux jetons de 120 s sans nouvelle visite dès que `0042` sera corrigée de la façon proposée par l'archive | `0037:133-136`, `0039:331-349` | DÉDUIT |

## 6. Ce que le client affiche aujourd'hui

| Élément | `main` | Branche d'observation |
|---|---|---|
| Entrée tuteur | « Assister » -> `/salle` (cassé en prod) | « Assister » -> `/tc/observation/:id` |
| Avant l'entrée | Intro statique « Vous pouvez regarder un court moment... » + « Entrer » ; aucun chiffre | idem |
| Pendant | « Observation en cours » + « Visite {rang} sur {total} » + « {n} s restantes » (alerte sous 30 s) + rappel micro/caméra + « Quitter » | idem |
| Budget non confirmé | « Temps restant non confirmé par le serveur. » (`budgetIncertain`) | idem |
| Vidéo indisponible | « La vidéo de la séance n'a pas pu s'ouvrir. Votre temps d'observation continue de s'écouler. » | idem |
| Après | Message de fin sans action, sans visites restantes, sans retour | idem |
| Refus | Message du motif (6 motifs), sans action ; panne réseau -> « Entrer » à nouveau | idem |
| Notice enseignant | Seulement dans `/tc/classe` (non atteinte) | `/salle` et `/tc/classe`, oeil + prénoms |
| Notice enfant | Non montée | « Ton tuteur regarde le cours », `/salle` et `/tc/classe` |
| Micro/caméra/chat tuteur | Aucune commande (`panneau_observation_tuteur.dart:88-133`) | idem |

## 7. Sortie, reconnexion, visite écourtée : comportement réel

- **Sortie volontaire** : « Quitter » -> `sortir_observation` -> `left_at`, `sortie_volontaire`, durée calculée en base
  (colonne générée, `0032:458-461`) -> la salle est quittée (`entree_observation_page.dart:143-156`, `:331-344`).
- **Durée atteinte** : le client ferme quand le budget serveur relu toutes les 5 s vaut 0 ou quand son décompte local
  tombe à 0 ; il appelle aussi `sortir_observation`, donc le journal dit `sortie_volontaire`, pas `quota_atteint`.
- **Fin de séance pendant la visite** : non détectée ; `budget_observation` ne lit pas la fin de séance, le client ne
  lit pas l'état de la salle. La visite continue jusqu'au plafond ou jusqu'à la coupure LiveKit.
- **Coupure réseau pendant la visite** : le SDK LiveKit tente de se reconnecter ; l'écran d'observation n'écoute pas
  `EtatSalle` et ne le dit pas ; le budget, s'il ne se relit plus, passe `budgetIncertain` et le décompte local
  continue de raccourcir (jamais d'allongement : `vue_budget_observation.dart:44-61`). Pas de remise à zéro du compteur :
  le temps court côté serveur tant que l'intervalle est ouvert.
- **Rechargement / retour / fermeture d'onglet** : l'intervalle reste ouvert (`dispose` ne sort pas). DÉDUIT : une
  nouvelle entrée dans les 120 s heurte l'index unique -> erreur 23505 -> affichée comme panne réseau
  (`port_politique_observation.dart:301-304`) ; au-delà, `temps_epuise`. **La seconde visite est perdue** ; la fraude
  inverse (repartir de zéro) est impossible côté serveur.
- **Visite écourtée** : une visite de 30 s compte pour une visite ; la suivante a de nouveau 120 s (reste total 210 s,
  borné à 120). Les 90 s non utilisées ne sont pas reportées. Aucune décision canonique trouvée.
- **Échec de connexion vidéo** : l'intervalle est ouvert avant le jeton (`0037:133-149`) ; un échec de jeton ou de
  connexion consomme donc la visite et son temps (le texte d'écran le dit, `fr.i18n.json` `visite.videoIndisponible`).

## 8. Journal persistant des observations

- **Table** `public.guardian_session_visit` (`0032:449-492`) : `session_id`, `groupe_id`, `observateur_profile_id`,
  `role`, `enfant_profile_id`, `entered_at`, `left_at`, `duration_seconds` (générée), `visit_number`, `policy_version`,
  `fin_de_visite` (5 valeurs admises). Aucune politique d'écriture ; ni suppression ni édition prévues côté client.
  `on delete cascade` sur `session_id` (une séance supprimée physiquement emporte ses visites ; les séances sont
  normalement supprimées logiquement).
- **Lecture tuteur** : RLS `guardian_visit_self` (`observateur_profile_id = auth.uid()`) + `SELECT` accordé
  (MESURÉ PROD). Un second responsable du même foyer ne voit **pas** les visites du premier.
- **Lecture admin** : RLS `guardian_visit_admin` (toutes les lignes).
- **RPC** : `visites_observation(p_session_id)` (propres lignes ou admin, `0033:1235-1257`) rend 7 colonnes seulement
  (pas `enfant_profile_id`, `session_id`, `groupe_id`, `policy_version`). Pas de RPC de liste multi-séances : la liste se
  lit directement dans la table.
- **Audit** : `audit_logs` via `log_sensitive_access` (`observation_entree`, `observation_sortie`,
  `observation_politique_groupe_modifiee`), affiché brut dans le Journal admin.
- **Données en production** : 0 visite, 0 groupe, 0 séance (MESURÉ PROD).
- **Écrans** : aucun (ni tuteur, ni admin).

## 9. Médias autorisés au tuteur

| Mandat | Réalité |
|---|---|
| Entend l'enseignant et tous les élèves au micro actif | Oui (jeton `can_subscribe = true`, abonnement automatique) |
| Voit le support partagé | **Non** : jamais rendu. Contrat lisible pour le tuteur inscrit : `session_shared_content` (RLS participant, `0032:427-436`) ; module `core/tc_etat_partage` présent mais non branché (`CLAUDE.md` du dépôt) |
| Voit l'enseignant et son enfant | Oui à l'écran (filtre client) ; noms probablement affichés en UUID (2.5) ; caméra de l'enfant souvent fermée (politique `forbidden` par défaut), message « Votre enfant n'a pas d'image ouverte » |
| Ne voit pas le roster ni les autres élèves | **Seulement à l'écran** : le client reçoit identités et flux de tous (pas de permission de piste côté serveur) |
| Aucun micro, caméra, chat, réaction, annotation | Oui, refusé dans le jeton signé et aucune commande à l'écran |
| Couper le son reçu, agrandir le support (local) | **Absents** |

## 10. Écart avec la partie « observation » du mandat

| Exigence du mandat | État | Nature |
|---|---|---|
| 2 visites max, 120 s par visite, 240 s total, pas de visite unique de 4 min | Tenu **à l'entrée** et par le `restant` de `budget_observation` ; jeton borné à 120 s ; fin de visite non imposée par le serveur | Serveur partiel ; front à aligner (`defautsNormatifs`, replis admin, `docs/current/01`) |
| Paramètres configurables par l'admin, UI consomme la politique effective | Réglage par groupe existant ; défauts Académie sans écran ; l'UI tuteur ne lit ni politique ni budget avant l'entrée | Front faisable (`budget_observation` avant entrée) |
| Enfant présent requis ; présence incertaine = vérification | Non garanti par le serveur ; présence lisible par le tuteur via `presence_seance_v` (`service_presence.dart:23-67`, `:232`) | **Dépendance backend** pour la garantie ; affichage « vérification » faisable côté front mais **ne doit pas activer l'observation réelle seul** |
| Entend tous les micros actifs, voit support + enseignant + son enfant | Audio oui ; support non ; enfant unique | Front (support) ; décision (plusieurs enfants) |
| Aucun micro/caméra/chat/réaction/annotation/commande | Oui | - |
| Pas de roster ni fiches des autres | Écran oui, flux non | Dépendance backend pour une vraie restriction (permissions de piste) |
| Notice enseignant + enfant concerné, rien aux autres | Serveur prêt (`annonces_observation`, `annonce_observation_pour_moi`) ; montage sur la branche seulement | Front (intégrer la branche) |
| « Votre maman... » si lien connu, sinon « Votre parent... » | Texte actuel « Ton tuteur regarde le cours » ; aucun lien familial exposé à l'enfant | Front pour « Votre parent... » ; **backend** pour « Votre maman... » |
| Garanties serveur, timer non contractuel | Voir section 5 : quota à l'entrée seulement, jeton aveugle, pas d'expulsion, `0042` bloquant | **Dépendance backend** |
| Parcours Classe -> disponibilité -> explication -> connexion -> observation -> sortie -> retour classe -> historique | Pas de page Classe tuteur, pas d'explication, pas de retour, pas d'historique ; route hors coquille sans bouton retour | Front |
| États : 2 visites / 1 restante / épuisées | Données disponibles (`visites_utilisees`, `visites_max`, `peut_entrer`, `motif_refus`) mais non affichées avant/après | Front |
| Enfant absent, présence en vérification | Non gérés | Front (affichage) + backend (garantie) |
| Séance non commencée / terminée / observation désactivée | `hors_fenetre`, `policy_desactivee` existent ; « non commencée » dès T-20 côté serveur ; fin de séance non détectée pendant la visite | Front + décision |
| Chargement, connexion prolongée, échec, reconnexion | Chargement et échec d'entrée oui ; reconnexion non affichée | Front |
| Caméra enfant désactivée, pas de support, support indisponible | Caméra : oui ; support : message fixe | Front |
| Sortie volontaire, durée atteinte, fin de séance | Deux premiers oui ; fin de séance non | Front + backend (motif fiable) |
| « Visite 1/2 · 01:42 » ; compteur non démarré pendant l'explication | Format « Visite 1 sur 2 » + « 102 s restantes » ; le temps démarre au clic « Entrer », connexion vidéo comprise | Front (format) ; décision/backend (ouvrir l'intervalle après connexion) |
| Consentement onboarding, comptes existants non présumés consentants | Mécanisme existant `contract_acceptances` versionné (`0004_inscription_kyc_appairage.sql:221-259`, kinds `guardian_terms`, `recording_and_control_notice`) ; nouvelle version insérable par le client ; **aucune vérification serveur du consentement avant une visite** | Front (recueil) ; backend (exigence avant visite, si voulue) |
| Salle : support dominant, 2 vignettes, Son reçu, Agrandir, Quitter | Seul Quitter | Front |
| Historique « Séances / Observations », vue tuteur et vue admin | Aucun écran ; données en table | Front (lecture directe), avec limites 8 et 12 |
| Libellé « Cours en cours » interdit | Présent dans 3 clés i18n (`fr.i18n.json:1379`, `:1700`, `:2023`) dont `tc.groupe.temps.enCours` (espace groupe tuteur) | Front |
| Aucun changement backend dans le diff | La branche d'observation contient 4 migrations : l'intégrer telle quelle ajoute des fichiers `supabase/` (déjà appliqués) | Décision coordinateur |

Maquettes : deux planches d'observation présentes (`tutuor image\tuteur observation desktop light.png`,
`tutuor image\mobile\tuteur observation mobile light.png`) plus `tutor observation map.png`. **La troisième planche
annoncée par le mandat (« États particuliers et notices de présence ») est absente du dossier.** La planche desktop
montre des motifs de fin « Limite atteinte », « Départ volontaire », « Interrompue » : seul « Départ volontaire »
(`sortie_volontaire`) peut aujourd'hui être écrit par le serveur.

## 11. Ce que le front peut consommer sans modifier le backend

| Besoin d'écran | Contrat existant en prod | Limite à afficher honnêtement |
|---|---|---|
| Disponibilité avant entrée (visites, durée, motif) | RPC `budget_observation(p_session_id)` -> `visites_utilisees`, `visites_max`, `restant_secondes` (= plafond de la prochaine visite), `peut_entrer`, `motif_refus` ; `budgetObservationProvider` existe, inutilisé (`port_politique_observation.dart:322-326`) | Lecture sans effet : n'ouvre pas d'intervalle (le compteur ne démarre pas) |
| Durée par visite / par séance à afficher | RPC `politique_observation_effective(p_groupe_id)` -> `max_visits_per_session`, `max_seconds_per_visit`, `max_total_observation_seconds`, `source`, `policy_version` | Nécessite le `groupe_id` de la séance |
| Entrer, sortir | `entrer_observation`, `sortir_observation` (moteur existant) | L'intervalle démarre au clic, avant la vidéo |
| Présence de l'enfant (indicatif) | Vue `presence_seance_v` via `presenceSeanceProvider` (états `presente`, `en_retard`, `en_reconnexion`, `deconnectee`, `inconnu`...) | Indication seulement, pas une barrière |
| Notice enseignant | `annonces_observation(p_session_id)` | Réservée à l'enseignant de la séance |
| Notice enfant | `annonce_observation_pour_moi(p_session_id)` -> `{observe, depuis}` | Pas de lien familial ni d'identité |
| Support partagé | Table `session_shared_content` (lisible par un participant inscrit) + canal data LiveKit reçu ; module `core/tc_etat_partage` | Aucun rendu tuteur existant ; « aucune fausse page du Coran » |
| Historique tuteur | `SELECT` direct sur `guardian_session_visit` (RLS : ses propres lignes) ; libellé de classe, enseignant (prénom, titre, photo) via `mes_groupes_famille_v` (`0033:140-173`) ; prénom de l'enfant via les profils du foyer | `mes_groupes_famille_v` ne rend que les groupes **actifs** (`g.ended_at is null`, membres actuels) : une classe terminée perd son libellé ; motif de fin quasi toujours `sortie_volontaire` ou vide ; visites orphelines sans `left_at` |
| Historique admin | `SELECT` direct sur `guardian_session_visit` (RLS admin) + profils (lecture admin, `0015`) + groupes ; filtres tuteur / élève / classe / période / statut faisables en requête PostgREST | Pas de recherche serveur dédiée ; 0 ligne aujourd'hui ; navigation admin gelée à huit domaines (`admin_domaine.dart`) : emplacement à décider |
| Réglage Académie | `ServiceConfiguration.ecrire` + RLS `app_config_admin_update` | `policy_version` à incrémenter à la main ; hors mandat tuteur, à ne faire que sur décision |
| Consentement | Insert `contract_acceptances` nouvelle version (policy `contract_acceptances_self_insert`) | Pas d'exigence serveur avant visite |

**Inconsommable tant que le serveur n'est pas corrigé** : la vidéo elle-même (fait 4). Toute recette réelle d'observation
est BLOQUÉE ; seules des recettes sur doubles sont possibles, à étiqueter « testée en simulation ».

## 12. Dépendances backend à documenter (entrée / sortie / impact)

1. **Jeton vidéo** : `autoriser_jeton_video` doit valider le compte désigné par `p_profile_id` (correctif archivé
   `RA_OBS/0043`, à renuméroter `0044` selon `docs/current/08`). Impact : sans lui, aucune salle, aucune observation.
2. **Quota au jeton** : `budget_observation` doit pouvoir être évalué pour `p_profile_id` (paramètre ou variante interne)
   quand il est appelé depuis `autoriser_jeton_video`. Entrée : `(session_id, profile_id)` ; sortie : budget de CET
   observateur. Impact : sinon le TTL et le refus au jeton ne reflètent pas la consommation.
3. **Fin de visite serveur** : expulsion LiveKit (ou révocation de droit d'abonnement) à l'épuisement, et fermeture
   serveur des intervalles orphelins (webhook `participant_left` du `guardian_observer`, ou tâche planifiée) avec le bon
   `fin_de_visite` (`quota_atteint`, `seance_terminee`, `deconnexion`). Entrée : événement LiveKit ; sortie : ligne close.
4. **`sortir_observation(p_session_id, p_motif)`** ou équivalent, pour que la fin sur quota ne s'écrive pas
   `sortie_volontaire` ; et retrait (soft delete) du `session_participants` observateur à la sortie.
5. **Présence de l'enfant exigée** dans `entrer_observation` (et éventuellement au jeton), avec un motif neuf distinct
   (`enfant_absent`, `presence_incertaine`) que le Dart saura lire (`MotifRefusObservation.depuisSql` rend `null` sur
   valeur inconnue, `port_politique_observation.dart:42-49`).
6. **Reprise d'une visite interrompue** (même intervalle après reconnexion) plutôt qu'une erreur d'index unique ; ou, à
   défaut, un motif lisible (`visite_deja_ouverte`) au lieu d'une 23505 traitée comme panne réseau.
7. **Ouverture de l'intervalle après connexion vidéo** (ou « visite non comptée si la connexion échoue »), pour tenir
   « le compteur ne démarre pas pendant une vérification ».
8. **Restriction des pistes reçues** (enseignant + enfant + support) si « ne voit pas les autres élèves » doit être une
   garantie et non un filtre d'écran.
9. **Nom affichable** des participants dans le jeton LiveKit (`name`) ou résolution côté client depuis une source
   autorisée, sinon vignettes en UUID.
10. **Lien familial** exposé à l'enfant (type de lien de l'observateur) si « Votre maman... » est voulu.
11. **Historique** : vue ou RPC de liste qui joint classe, enseignant et enfant sans dépendre de l'appartenance actuelle au
    groupe ; lecture partagée entre responsables d'un même foyer si c'est la décision.
12. **Consentement** : exigence serveur d'une acceptation (version à jour) avant toute visite, si le produit la veut.

## 13. Questions ouvertes (aucune décision canonique trouvée) : à isoler, ne pas trancher

| Question | Comportement serveur actuel | Où c'est lu |
|---|---|---|
| Quota partagé ou individuel entre responsables d'un même foyer | **Individuel par compte** : deux responsables = 2 x 2 visites ; chacun ne voit que ses visites | `0039:208-249`, RLS `0032:488-492` |
| Plusieurs enfants dans la même séance | **Un budget par séance** pour le tuteur, pas par enfant ; enfant désigné par `limit 1` sans ordre (arbitraire) ; seul cet enfant est exposé dans le panneau ; le témoin s'allume chez tous les enfants du foyer depuis `0041` | `0037:104-109`, `vue_observation_tuteur.dart:55-60`, `0041:179` |
| Visite écourtée | Compte comme une visite entière ; temps non reporté | `0039:285-303` |
| Déconnexion de l'enfant pendant la visite | Aucun effet serveur ni client | - |
| Observation avant le début (T-20 à T0) | Autorisée par le serveur (fenêtre d'entrée) | `0037:89-92` |
| Échec vidéo après entrée | Visite consommée | `0037:133-149` |
| Consentement des familles observées vs visite d'un parent | Non relié côté serveur | - |

Les specs d'origine (archive `SPEC_TEACHING_CORE_V1.md` §11.1-11.4, lignes 496-535) prévoyaient 1 visite / 120 s et « sortie
client + révocation/expulsion serveur si nécessaire » ; la règle 2 x 120 s est une décision opérateur du 21/09 reprise dans
`0036:5-10`. Aucune des questions ci-dessus n'y est tranchée.

## 14. Affirmations périmées ou fausses à ne pas recopier

- « Les fonctions d'observation n'existent pas encore en base » : `echec_observation.dart:12-15`,
  `port_politique_observation.dart:170-177`, `port_visite_observation.dart:77-84`, `port_annonce_observation.dart:55-60`.
  Faux depuis `0033` (20/09).
- « `0036` n'est pas appliquée » : `port_politique_observation.dart:262-275`, `module_reglages_observation.dart:28-31`,
  `:150-155`, `feuille_observation_groupe.dart:179-192`. Faux depuis le 21/09.
- « Le serveur referme l'intervalle à l'expiration du jeton » : `moteur_visite_observation.dart:251-253`,
  `entree_observation_page.dart:118-122`. Aucun code serveur ne le fait.
- « Le ttl = 120 prouve que 0036 et 0039 tiennent » (`ETAT_OBSERVATION_2026-09-21.md` sur la branche) : prouve le plafond
  par visite, pas la consommation (budget calculé pour un `auth.uid()` NULL).
- « 1 visite, 120 s cumulées » : `docs/current/01_PRODUIT_ET_PARCOURS.md:30`, `guardian_observation_policy.dart:74-84`,
  `feuille_observation_groupe.dart:49-55`, `q03_quota_observation_tuteur_test.dart:51`.
- `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md` (présent sur C0/main) : périmé, supprimé sur la branche.
- Mémoire du 21/09 soir : « 0042 PAS appliquée » ; faux, elle l'est (`list_migrations`).

## 15. Proposition de périmètre pour l'agent Cours (observation UI), à valider par le coordinateur

Fichiers candidats (propriétaire unique) : `lib/features/tc_observation_ui/*` (hors `etat_reglages_observation.dart` et
`module_reglages_observation.dart`, côté admin), plus un écran d'explication et l'entrée depuis la future page Classe.
À réserver au coordinateur : `routes.dart`, `app_router.dart` (alias `.../observer` -> `/tc/observation/:seanceId`, mise
sous coquille ou bouton retour), `fr.i18n.json` et générés, `app_icons.dart` (oeil `0xe220` de la branche),
`lib/core/tc_observation/*` (modèles partagés politique/visite : à stabiliser avant les écritures parallèles, dont
`defautsNormatifs`), et la décision d'intégrer ou non `observation/lot-2026-09-21` (qui touche `salle_page.dart`,
`accueil_famille_page.dart`, `classe_live_page.dart`, `entete_classe.dart`, et apporte 4 fichiers `supabase/`).
Agent Compte/Historique : onglet « Observations » tuteur et vue admin sur lecture directe de `guardian_session_visit`.
Agent Admission : consentement via `contract_acceptances` (nouvelle version), sans présumer les comptes existants.
