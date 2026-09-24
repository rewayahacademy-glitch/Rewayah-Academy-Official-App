# C06 - Cours et classes : cartographie du code (lecture seule)

Date : 24/09/2026. Agent de cartographie C06. Dépôt `D:\RA _APP\RA -OFFICIAL-APP`, checkout `c0/configuration-baseline-2026-09-23` (HEAD non modifié, aucun fichier du dépôt créé ni modifié, aucune commande Flutter lancée, aucune requête vers la base de production).

Périmètre : accueil tuteur, classe (Espace Groupe), catalogue, planning, travail à préparer, ressources, progression, entrée de salle/observation (entrée seulement).

## 0. Méthode et limites de preuve

- Lecture du code et des migrations sur la branche courante ; lecture d'autres branches par `git show` / `git diff` uniquement.
- **Le code `lib/` de C0 est fonctionnellement identique à `main`** : `git diff main HEAD -- lib` ne montre que des chemins de documentation réécrits dans des commentaires (ex. `lib/core/tc_groupe/port_groupes.dart:19`, `lib/features/accueil_famille/accueil_famille_page.dart:35`). Les numéros de ligne ci-dessous sont ceux de C0.
- Statut de chaque constat : « lu dans le code » (constaté par lecture), jamais « testé ». Les tests existants (`test/teaching_core/a/*`, `test/features/accueil_famille_test.dart`, `test/suivi/vue_suivi_foyer_test.dart`, `test/parcours/parcours_offres_test.dart`) **n'ont pas été exécutés** par cet agent.
- L'état de la production est repris de `docs/current/CONFIGURATION_BASELINE_2026-09-23.md` (§3 et §4), non re-mesuré.

## 1. Synthèse (ce qu'il faut retenir)

1. **Ce que le tuteur voit aujourd'hui** : `/tuteur` = `AccueilFamillePage` (données réelles, mais modèle 1-à-1 « affectation » hérité du matching), barre Accueil / Disponibilités / Réglages / Suivi (`lib/core/widgets/nav_shell.dart:79-100`). L'Espace Groupe `/tc/groupes` n'est atteint que par une ligne de menu « Mes groupes » (`accueil_famille_page.dart:463-468`) et **sert six groupes fictifs** (`lib/core/tc_groupe/port_groupes.dart:37-39` rend `GroupesDemonstrationLocale()` sans condition ; horloge ancrée au 21/09/2026 11:32 UTC, `lib/core/tc_horloge/demonstration_horloge.dart:24`, `port_horloge_seance.dart:54-55`).
2. **Les maquettes high-fi reprennent littéralement ce double de démonstration** : « Classe An-Nour, Sayyida Amina, Règles de lecture, Niveau 1, Lundi 21 septembre 13:45 Paris, Salle ouverte, dans 13 min, 1 h 30 » = `demonstration_groupes.dart:57-72` + `demonstration_horloge.dart:127-143`. Preuve supplémentaire que noms, heures, durée, capacité sont illustratifs : aucune de ces valeurs ne doit devenir une constante.
3. **`v0/verite-produit` (commit `33503fe`) remplace le double par des lectures réelles** (`mes_groupes_famille_v`, `horloge_seance()`, `maintenant_serveur()`) mais laisse `prochaineSeance` toujours nul : en production la carte de séance est donc **toujours vide**, sans compte à rebours ni entrée (limite assumée dans le commit). Non fusionné.
4. **Modèle temporel solide côté client** (`FenetreSeance` / `SessionClockVM` : UTC, fenêtre et grâce venues du serveur, jamais de compte à rebours négatif, phase `prolongee`), **mais aucun modèle d'exception** : pas de report, pas de remplacement, et l'horloge serveur ne rend pas le statut de séance (une séance annulée garderait son compte à rebours).
5. **T-20** : configurable côté serveur (`app_config.join_window_minutes = 20`, `sessions.join_opens_at`, `supabase/migrations/0030_tc_socle.sql:33-41, 84-90` ; barrière `autoriser_jeton_video`, `0033_tc_vues_rpc.sql:1663, 1688-1691`). Côté client subsistent des constantes : 10 min (`lib/core/video/pre_vol.dart:22`), 20 min (`lib/core/router/billet_salle.dart:31`), 15 min (`lib/core/controle/service_controle.dart:22`).
6. **Catalogue de classes : inexistant pour une famille.** `tc_catalogue` est la **Bibliothèque de ressources**, pas un catalogue de classes. Le seul « choix » côté famille est la vitrine d'offres horaires (`0043`, `lib/core/offres/`, `/tuteur/parcours/:eleveId`) qui, **par conception**, n'affiche ni enseignant, ni places, ni classe, et **n'est pas appliquée en production** (baseline §3 l.129). Contradiction frontale avec `01_PRODUIT_ET_PARCOURS.md:20-21`, `06_SPEC_FONCTIONNELLE_MVP.md:15` et le mandat.
7. **Travail à préparer, ressources, progression : non branchés.** Tables présentes en base (`learning_assignment`, `library_resource`...), mais adaptateurs Flutter absents : `portTravailAVenirProvider` = `null`, `portAssignationsProvider` lève, `portCatalogueProvider` = catalogue local vide, `BlocProgression` affiche toujours « Bientôt disponible ».
8. **L'entrée « Assister » de l'accueil tuteur est cassée en production** : elle appelle la RPC `assister_seance` (`lib/core/video/service_video.dart:131-134`, `accueil_famille_page.dart:182`), révoquée pour `authenticated` par `0041` appliquée en production (branche `observation/lot-2026-09-21`, `0041_...sql:226`). Le recâblage vers `/tc/observation/:seanceId` n'existe que sur la branche d'observation.
9. **Libellé interdit « Cours en cours »** présent : `tc.groupe.temps.enCours` (`assets/i18n/fr.i18n.json:1700`, utilisé par `libelles_tc_groupe.dart:146-147, 316-318`), `enseignant.journee.coursEnCours` (l.1379), `tc.classe.barre.titre` (l.2023).
10. **Risque de confidentialité à faire trancher côté serveur** : un foyer lit la ligne `lesson_reports` entière d'une séance où figure son enfant (`0001_fondations.sql:1070-1078`), or le contenu d'un cahier de groupe contient les décisions de **tous** les élèves (`lib/core/enseignant/modeles_enseignant.dart:631-676`). Le cahier ne doit donc pas servir de « résumé famille » sans projection serveur.

## 2. Ce qui est servi au tuteur aujourd'hui, et d'où

| Route | Écran | Entrée de navigation | Source des données | Réel / démo |
|---|---|---|---|---|
| `/tuteur` | `AccueilFamillePage` (`lib/features/accueil_famille/accueil_famille_page.dart:131`) | Onglet 1 (`nav_shell.dart:80-84`) | `elevesDuFoyerProvider` (`profils_du_foyer_v`), `seancesProvider` (`mes_seances_v`), `affectationsProvider` (`mes_affectations_v`) (`:204-210`), `BlocParcours` (`v_parcours_onboarding`, `regles_academie`, `:236`) | Réel. `BlocParcours` lit des objets de `0043` absents en production : il se tait en erreur (`lib/features/parcours_offres/bloc_parcours.dart:46-48`) |
| `/tuteur/disponibilites` | `DisponibilitesPage` | Onglet 2 | `weekly_availability` | Réel, mais relève du matching abandonné (`00_LIRE_D_ABORD.md:26`) |
| `/tuteur/reglages` | `ReglagesEnfantPage` | Onglet 3 | hors C06 | Réel |
| `/tuteur/suivi` | `SuiviFoyerPage` (`lib/features/suivi_foyer/suivi_foyer_page.dart:47`) | Onglet 4 | `mes_seances_v` + `presence_seance_v` (`lib/core/suivi/service_suivi.dart:57-87`) | Réel. `routes.dart:103` le décrit comme « suivi des cahiers de transmission » : faux, c'est un historique de séances et de présence |
| `/tuteur/parcours/:eleveId` | `ParcoursOffresPage` | CTA de `BlocParcours` | `lib/core/offres/service_offres.dart` (RPC `0043`) | Réel en code, **mort en production** (`0043` non appliquée) |
| `/tc/groupes` | `MesGroupesPage` (`lib/features/tc_mes_groupes/mes_groupes_page.dart:28`) | Ligne « Mes groupes » (`accueil_famille_page.dart:463-468`) | `mesGroupesProvider` -> `GroupesDemonstrationLocale` | **Démo** (6 groupes inventés) |
| `/tc/groupes/:groupeId` | `EspaceGroupePage` (`lib/features/tc_espace_groupe/espace_groupe_page.dart:40`) | Carte de groupe | `groupeProvider`, `horlogeGroupeProvider` (démo), `portCatalogueProvider` (vide), `portTravailAVenirProvider` (`null`) | **Démo** + emplacements « non branchés » |
| `/tc/bibliotheque[?groupe=]` | `BibliothequePage` | « Voir tout » de l'Espace Groupe (`espace_groupe_page.dart:256-263`) | `CatalogueLocal()` vide (`lib/core/tc_bibliotheque/donnees_catalogue.dart:32-34`) | Vide (aucune donnée, aucune démo) |
| `/salle` | `SallePage` | « Assister » (`accueil_famille_page.dart:358-360`) après `assister_seance` | `core/video` | Porte **refusée en production** (voir §10) |
| `/tc/observation/:seanceId` | `EntreeObservationPage` (`lib/features/tc_observation_ui/routes_tc_g.dart:37-45`) | **Aucune** sur C0/main | ports observation réels (`lib/core/tc_observation/port_politique_observation.dart:307-310`) | Route autorisée au tuteur (`lib/core/router/redirection.dart:144-147`) mais orpheline |

Constats de navigation :
- `/tc/classe` n'est autorisée qu'à l'enseignant et à l'élève (`redirection.dart:138-140`). Le « Rejoindre » de l'Espace Groupe (`lib/features/tc_mes_groupes/routes_tc_a.dart:47-48, 63-83`) envoie donc un tuteur vers `/tuteur` : impasse déjà consignée (baseline §4, l.140).
- Sur la liste « Mes groupes », `MesGroupesPage` est construite sans `onRejoindre` (`routes_tc_a.dart:36`) : quand la fenêtre est ouverte, la carte rend un bouton « Rejoindre » **grisé** (`lib/features/tc_mes_groupes/carte_groupe.dart:94-97`, `lib/core/widgets/action_principale.dart:63-64, 91`), contraire à `lib/CLAUDE.md` (« un bouton qui ne peut pas aboutir n'est pas rendu »).
- **Rôle de l'Espace Groupe figé au démarrage** : `routeurProvider` lit `sessionProvider` une seule fois (`lib/core/router/app_router.dart:91-93`) alors que la session démarre en `chargement` sans rôle (`lib/core/session/session_controleur.dart:74`) et que rien n'invalide ce provider (seul `lib/app.dart:42` le regarde). `_roleEspaceGroupePour(null)` rend `eleve` (`app_router.dart:692-700`). Par lecture, un tuteur reçoit donc `RoleEspaceGroupe.eleve`. Sans effet visible aujourd'hui (les deux sont « côté famille »), mais bloquant dès qu'un CTA propre au tuteur (Observer) sera décidé par ce rôle. Non vérifié à l'exécution.

## 3. Modèles de classe, séance, occurrence

### 3.1 Groupe / classe : `GroupSummaryVM` (`lib/core/tc_groupe/group_summary_vm.dart:194-301`)
Champs : `groupeId`, `libelle`, `couleurJeton` (index de palette + code stable, jamais d'hexadécimal, `:79-99`), `enseignant: EnseignantVM`, `nomCours?`, `niveauHumain?`, `nombreMembres`, `seuilMax` (serveur, assertion `> 0`), `typePublic` (enfant/adulte), `actif`, `prochaineSeance?`, `horloge?`. Dérivés : `complet`, `placesLibres` (`:256-262`), `rejoindreOuvert` (délégué à l'horloge, `:300`).
- **Aucun champ** : langue du cours, parcours distinct du « cours », liste des créneaux hebdomadaires, fuseau de référence du groupe (seulement via l'occurrence), date de début, état ouvert/complet/liste d'attente, élève concerné du foyer.
- `EnseignantVM` (`:111-139`) : `enseignantId`, `titre` (Sayyid/Sayyida, `depuisSql` rend `null` sur valeur inconnue, `:30-37`), `nomAffichage`, `photoUrlOuCle` (clé de stockage, jamais d'URL signée). `photoManquante` déclenche un état explicite (`lib/features/tc_mes_groupes/photo_enseignant.dart:50-88`). **Aucun service ne résout la clé en URL signée** : `IdentiteGroupe` accepte `urlPhoto` (`espace_groupe_page.dart:314-320`) mais personne ne la fournit, donc l'avatar retombe sur des initiales même quand la photo existe.
- `GroupHomeVM` (`lib/core/tc_groupe/group_home_vm.dart:113-203`) : page verticale identique pour les 4 rôles, `avantProchainCours` borné à 3 par assertion (`:124-127`), `SlotBibliotheque`, `SlotProgression`, `SlotRoster` (enseignant/admin seulement, `:128-133`). **Aucun `studentId`** : le contexte « élève sélectionné » du mandat n'existe pas dans ce modèle.

### 3.2 Occurrence : `OccurrenceSeance` (`group_summary_vm.dart:150-178`)
`debutUtc`, `duree` (> 0), `fuseauReferenceGroupe` (IANA), `sessionId?` (nul si non matérialisée). `finPrevueUtc = debutUtc + duree` (arithmétique UTC, `:177`). Pas de statut, pas d'enseignant d'occurrence, pas de motif.

### 3.3 Temps : `FenetreSeance` / `SessionClockVM` / `HorlogeAffichee` / `NoticeDst`
- `FenetreSeance` (`lib/core/tc_horloge/fenetre_seance.dart:55-151`) : `debutUtc`, `finPrevueUtc`, `fenetreAcces`, `graceApresFin` (données serveur, pas de constante). `joinOpensAtUtc = debut - fenetre`, `finGraceUtc = fin + grâce`. `phaseA()` (`:100-117`), `restantA()` (`:125-137`), `rejoindreOuvertA()` (`:144-150`).
- `PhaseSeance` (`:10-30`) : `avantFenetre`, `salleOuverte`, `attenteAvantT0`, `enCours`, `prolongee`, `terminee`.
- `SessionClockVM` (`lib/core/tc_horloge/session_clock_vm.dart:125-257`) : bornes UTC, `horlogeUtilisateur`, `horlogeContrepartie?` (nulle si même fuseau, `:193-197`), `phase`, `restant?`, `rejoindreOuvert`, `noticeDst?`, `calculeeAUtc` (instant serveur, jamais `DateTime.now()`). Assertions : prolongée ou terminée => `restant == null`, jamais négatif (`:146-157`).
- `HorlogeAffichee` (`:18-55`) : `fuseauIana`, `libelleVille`, `heureLocaleRendue`, `dateLocaleRendue` **déjà rendues par le serveur**. Le client n'a aucune bibliothèque de fuseaux (`pubspec.yaml` : pas de `timezone`/`intl` direct ; `intl` n'est que transitive) : toute conversion IANA doit venir du serveur. Conforme au mandat (« aucun décalage UTC fixe »).
- `NoticeDst` (`:74-105`) : transition, deux heures rendues, échéance J30/J7/J1. **Aucune source accessible au tuteur** : `transitions_fuseau_a_venir` est réservée à l'administration (`0033_tc_vues_rpc.sql:513-515`) et `horloge_seance` ne rend pas de notice.
- Le commentaire de `fenetre_seance.dart:35-40` recense trois calculs de temps concurrents (planning, accueil élève, journée enseignant) : non unifiés à ce jour ; l'accueil tuteur en ajoute un quatrième (minuteur 1 min, `accueil_famille_page.dart:160-163`).

### 3.4 Séance du planning réel : `Seance` (`lib/core/planning/service_planning.dart:73-155`)
Lue dans `mes_seances_v` (`0014_acces_agent.sql:888-920`), **une ligne par (séance, élève)**. Champs : `id`, `debut`/`fin` (convertis en fuseau **de l'appareil** par `toLocal()`), `statut`, élève (id, prénom, identifiant immuable), enseignant de l'occurrence (id, prénom, identifiant), `minutesInterruption`.
- **Pas de `groupe_id`** dans la vue, alors que `sessions.groupe_id` existe (`0025_role_enseignant.sql:47`) : on ne peut pas rattacher une séance de l'accueil à un groupe sans nouvelle projection.
- **Repli silencieux** : un `started_at`/`ended_at` illisible devient `DateTime.now()` (`service_planning.dart:93-98`), ce qui peut fabriquer une séance « en cours ».
- `mon_fuseau()` retombe sur `'Europe/Paris'` (`:257-260`), `Creneau.depuisJson` aussi (`:30`), et `ParcoursOffresPage._fuseauVu` aussi (`lib/features/parcours_offres/parcours_offres_page.dart:88`).

### 3.5 Exceptions, annulation, report, remplacement
- `StatutSeance` (`lib/core/domain/enums.dart:224-272`) : `planned`, `preflight`, `in_progress`, `ended`, `teacher_absent`, `student_absent`, `tech_failure`, `canceled_late`, `canceled`. `estAnnulee` couvre les deux annulations.
- Exploité par l'accueil tuteur : `prochainCours` écarte les annulées, `seanceAnnuleeDuJour` annonce l'annulation du jour (`lib/core/planning/journee.dart:145-204`) ; phase `seanceAnnulee` avec motif tardif (`accueil_famille_page.dart:399-413`). Le suivi distingue annulé / non tenu / tenu (`lib/features/suivi_foyer/vue_suivi_foyer.dart:195-205`).
- **Report : aucun concept** (ni statut, ni lien ancienne/nouvelle occurrence) dans `lib/` ni dans `supabase/migrations/`.
- **Remplacement : aucun concept.** L'enseignant d'occurrence (`sessions.teacher_id`, exposé par `mes_seances_v`) peut différer de l'enseignant du groupe (`mes_groupes_famille_v.teacher_id`), mais rien ne dit si c'est un remplacement tracé ; en déduire un « remplacement » côté client serait une invention. Une implémentation existe sur `integration/core24-classes-v2` (`lib/core/planning/service_remplacement_session.dart`, migration `..._core24_enseignant_remplacement_admin.sql`) : branche déclarée **non conforme**, référence de contrat uniquement, jamais d'intégration.
- `horloge_seance()` (`0033_tc_vues_rpc.sql:427-485`) ne rend **ni statut ni motif** : l'Espace Groupe afficherait un compte à rebours et « Salle ouverte » pour une séance annulée.

### 3.6 Récurrence
- `groupes.weekday/hour_local/timezone_iana` : **un seul créneau hebdomadaire** par groupe. `mes_groupes_famille_v` n'expose que lui (`0033_tc_vues_rpc.sql:140-170`).
- `groupe_creneaux` (plusieurs jours par semaine) n'existe que dans `0043` (`0043_offres_horaires_et_intentions.sql:452-459`), **non appliquée**, et `materialiser_seances_groupe` n'en tient pas compte : elle ne matérialise que l'ancre (`0033_tc_vues_rpc.sql:341-373`), sur un horizon glissant `matching_horizon_weeks` (défaut 4) relancé seulement à la création/modification du groupe ou à une adhésion (`:298-306, 396-418`). Un groupe stable cesse donc de produire des séances au bout de l'horizon.
- Conséquence : le « Planning habituel » à trois jours des maquettes (lundi/mercredi/samedi) n'a **aucune source** aujourd'hui.

## 4. Fenêtre d'ouverture (T-20)

| Endroit | Valeur | Nature | Référence |
|---|---|---|---|
| `app_config.join_window_minutes` | 20 | Configurable serveur | `0030_tc_socle.sql:33-35` |
| `sessions.join_opens_at` | écrit à la matérialisation | Par occurrence | `0030_tc_socle.sql:84-90`, `0033:359-364` |
| `autoriser_jeton_video` | `coalesce(join_opens_at, started_at - fenêtre)` ; fin = `ended_at + grâce` | **Barrière réelle** | `0033_tc_vues_rpc.sql:1663, 1688-1691` |
| `horloge_seance` | rend `join_opens_at_utc`, `fenetre_minutes`, `grace_minutes`, `maintenant_utc` | Lecture | `0033:427-458` |
| `pre_vol.dart` | 10 min | **Constante client** (journée enseignant) | `lib/core/video/pre_vol.dart:22`, `lib/features/journee/journee_page.dart:403` |
| `BilletSalle.duree` | 20 min | Constante client (validité du billet d'entrée) | `lib/core/router/billet_salle.dart:31` |
| `graceApresFin` | 15 min | Constante client (contrôle) | `lib/core/controle/service_controle.dart:22` |
| Double de démo | 20 / 15 | Fixture | `demonstration_horloge.dart:100-101` |

Écart à signaler dans l'adaptateur v0 : `horlogeDepuisLigne` reconstruit la fenêtre à partir de `fenetre_minutes` (configuration courante) et **ignore `join_opens_at_utc`** (v0 `lib/core/tc_horloge/horloge_supabase.dart:68-72`). Si la configuration change après matérialisation, l'écran proposerait l'entrée à un autre instant que celui que le serveur accepte. Il retombe aussi sur 0 minute si la valeur manque (`?? 0`, même ligne).

## 5. Séance prolongée et compte à rebours

- Phase `prolongee` : après `finPrevueUtc`, tant que le serveur déclare la séance ouverte, sinon tant que `now < fin + grâce` (`fenetre_seance.dart:114-116`). Aucun nombre : libellé `tc.groupe.temps.prolongee` = « Cours toujours en cours » (`fr.i18n.json:1702`), pastille « En dépassement » (`:1703`, `libelles_tc_groupe.dart:164`).
- **Le serveur ne fournit pas `seanceOuverte`** (`horloge_seance` ne rend pas `sessions.status`) : en production, la prolongation serait décidée par la seule heuristique de grâce ; une séance réellement encore ouverte au-delà de la grâce passerait « terminée ».
- Compte à rebours : `LibellesGroupe.compteARebours` (`libelles_tc_groupe.dart:263-275`) rend « Cours dans {h} h {mm} » / « Cours dans {n} min » / « Cours imminent » (`fr.i18n.json:1690-1692`), directement réutilisable pour « Cours dans 3 h 28 ». Pendant le cours : « Cours en cours · Reste … » (`:1700`) **à remplacer** (libellé interdit).
- Rafraîchissement : cadence fixée par le port (30 s en démo, `demonstration_horloge.dart:260` ; v0 : polling RPC toutes les 30 s, `horloge_supabase.dart:141`, **sans émission immédiate**, première valeur après 30 s).
- L'accueil tuteur actuel n'a pas de compte à rebours : « aujourd'hui à HH:MM avec {prénom} » (`accueil_famille_page.dart:378-383`), heure du fuseau de l'appareil sans libellé de fuseau (`:581-583`), durée écoulée pendant le cours (`:573-578`).
- Chaînes visibles en dur : `dureeLisible` rend `'$minutes min'`, `'$heures h'` hors slang (`libelles_tc_groupe.dart:290-300`) ; v0 ajoute des noms de jours et de mois en dur et **sans accents** (« fevrier », « aout », « decembre », v0 `horloge_supabase.dart:12-33`) et une ville dérivée de l'identifiant IANA en anglais (« Riyadh », `:47-50`).

## 6. Catalogue

### 6.1 `lib/features/tc_catalogue` n'est pas un catalogue de classes
C'est la Bibliothèque de ressources (routes `/tc/bibliotheque` et `/tc/bibliotheque/:resourceId`, `lib/features/tc_catalogue/routes_tc_b.dart:21-94`). Voir §8.

### 6.2 Le « choix » réellement codé : offres horaires vitrines (`0043`)
- Tables `offres_horaires` et `intentions_horaire`, RPC `offres_compatibles`, `choisir_offre_horaire`, `renoncer_intention_horaire`, `signaler_horaire_insatisfait`, vue `v_parcours_onboarding` (`0043_offres_horaires_et_intentions.sql:313-446, 682-983`). Service Flutter réel `ServiceOffresSupabase` (`lib/core/offres/service_offres.dart:91-213`), écran `ParcoursOffresPage` (`/tuteur/parcours/:eleveId`, `app_router.dart:294-298`).
- **Par conception** : aucun enseignant, aucun compteur d'inscrits, aucune place restante (`0043:313-318`, `parcours_offres_page.dart:580-587`) ; le choix est une **intention**, pas une réservation (`0043:767-768`) ; « aucun horaire ne convient » crée un signal dans `matching_requests` et non une liste d'attente (`0043:867-915`). Capacité rendue = règle générique (`groupe.capacite_enfant/adulte`), pas des places réelles (`0043:727-730`).
- **Non appliquée en production** (baseline §3 l.129 ; `08` l.79). En production, `BlocParcours` se tait et `ParcoursOffresPage` échouerait.
- **Contradiction à trancher (ne pas résoudre silencieusement)** : `01_PRODUIT_ET_PARCOURS.md:20-21` et `06_SPEC_FONCTIONNELLE_MVP.md:15` exigent enseignant, places disponibles, liste d'attente, inscription atomique et « dernière place réservée une fois » ; le mandat aussi (§5 Catalogue). `0043` fait le choix inverse, documenté, et `08` (l.38, l.52, l.67) classe le catalogue réel en V1 « bloquée CORE24, parcours catalogue absent ».

### 6.3 Places, liste d'attente, dernière place, confirmation
| Besoin du mandat | État du code | État serveur |
|---|---|---|
| Places réelles X/Y | `GroupSummaryVM.nombreMembres/seuilMax/placesLibres` (groupe déjà rejoint seulement) | `mes_groupes_famille_v.nb_membres/seuil_max` (groupes du foyer seulement) ; rien pour les classes ouvertes |
| Toutes les séances hebdomadaires | absent | `groupe_creneaux` (0043, non appliquée) ; matérialisation mono-créneau |
| Liste d'attente | absent (seulement « signaler horaire insatisfait ») | absent |
| Dernière place perdue | absent | plafond tenu par déclencheur `guard_groupe_membre_cap` (`0017:99`) sur `ajouter_eleve_groupe`, **réservé à l'administration** |
| Confirmation / refus | absent | absent pour la famille |

## 7. Travail à préparer (« Avant le prochain cours »)

- `lib/features/cahier` est le **cahier de transmission enseignant** (`ENS-04`, route `/enseignant/seance/:id/cahier`, `app_router.dart:352-356`) : écriture dans `lesson_reports` (`lib/core/enseignant/service_enseignant.dart:137-166`). Ce n'est pas le « travail à préparer » de la famille.
- Donnée cible : table `learning_assignment` (`0032_tc_catalogue.sql:354-397`, appliquée en production), **lisible par le foyer** (policy `learning_assignment_membres`, `:385-394`), **sans droit d'écriture famille** (pas de policy `update` hors enseignant) : « marquer fait » est impossible sans RPC.
- Ports : `PortTravailAVenir` et sa composition `TravailAVenir` (`lib/core/tc_parcours/port_travail_a_venir.dart:21-128`, 3 actions max, filtre par `studentId`) existent ; le provider vaut `null` (`:154-155`) ; `portAssignationsProvider` lève `UnimplementedError` (`lib/core/tc_outils/port_assignations.dart:175-180`). **Aucun adaptateur Supabase** de `PortAssignations` sur aucune branche locale.
- Widget réel non branché : `BlocAvantProchainCours` (`lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart:36`, lit `travailAVenirProvider` avec `studentId`, `:60`) n'est utilisé nulle part.
- **Défaut latent de l'Espace Groupe** : la page ne lit que la présence du port (`espace_groupe_page.dart:179`) et construit `GroupHomeVM.pourRole` **sans actions** (`:180-183`). Le jour où le port sera branché, `EmplacementAvantProchainCours` affichera « Rien à préparer » (bonne nouvelle) à tort (`lib/features/tc_espace_groupe/emplacements_groupe.dart:73-80`).
- Maquettes : cases à cocher « Avant / Après la séance » : l'écriture « fait » est une dépendance backend ; « fait » ne vaut pas compétence acquise (mandat).

## 8. Ressources (Bibliothèque et lecteur)

- Contrat `PortCatalogue` (`lib/core/tc_bibliotheque/port_catalogue.dart:99-120`), composition `DonneesCatalogue` robuste au refus du groupe (`donnees_catalogue.dart:137-189`), recherche/filtre/reprise (`catalogue_local.dart`, `recherche_catalogue.dart`).
- **Implémentation active = `CatalogueLocal()` vide** (`donnees_catalogue.dart:32-34`). Commentaire périmé : « aucune table `library_resource` n'est en base » (`catalogue_local.dart:12-17`), alors que `0032`/`0033`/`0035` sont appliquées (baseline §3 l.122-124). Idem « aucun bucket » alors que `0030:207-213` et `0034_r2_stockage.sql` existent.
- Barrière serveur `ressources_du_groupe` : décrite comme contournant la visibilité par ressource (`routes_tc_b.dart:50-62`) ; `0035_ressources_du_groupe_rejoue_visibilite.sql`, appliquée selon la baseline, vise à corriger ce point (le commentaire Flutter est donc à revérifier, non re-mesuré ici). Le fichier `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md` est contredit par la baseline (0034-0037 identiques en production, l.124).
- **Lecteur** : aucun moteur PDF (`detail_ressource_page.dart:26-32`), `urlEphemere` lève (`catalogue_local.dart:208-212`). Le Mushaf (`/tc/mushaf`, `/eleve/coran`) est réservé à l'élève (`redirection.dart:141-143`). Pour le tuteur, « lecteur existant » = aucun.
- Espace Groupe : le bloc Bibliothèque affiche « Bientôt disponible » quand la liste est **vide**, même si le port est branché (`emplacements_groupe.dart:156-160`) ; le `FutureBuilder` recrée sa requête à chaque reconstruction (`:149-150`), soit à chaque tic d'horloge.

## 9. Progression partageable

- `BlocProgression` : toujours `EmplacementNonBranche` (`emplacements_groupe.dart:183-201`).
- Données existantes :
  - `progression_historique` : lecture **admin seulement** (`0021_diagnostics_placement.sql:44-46`) ; `programme_niveaux` vide en production (`0043:25-32`).
  - `concern_famille_v` : résumé transmis à la famille, projection sûre colonne par colonne (`0033_tc_vues_rpc.sql:272-282`) ; **aucun lecteur Flutter**.
  - `presence_seance_v` + `mes_seances_v` : présence et séances passées (réel, `service_suivi.dart`).
  - `lesson_reports` : lisible par le foyer (`0001_fondations.sql:1070-1078`) mais contenu non projeté (voir §1 point 10). **Ne pas l'afficher côté tuteur sans projection serveur** ; à remonter à l'agent sécurité / au coordinateur (constat de lecture, non vérifié sur la base).
- Aucune notion d'« observation partageable » ni de résumé destiné à la famille par séance.

## 10. Entrée de salle et d'observation (entrée seulement)

- Accueil tuteur : « Assister » n'apparaît que si la phase est `enCours` (`accueil_famille_page.dart:358-360`), appelle `assisterEnTuteur` puis `go(Routes.salle, extra: BilletSalle)` (`:180-197`). En production, `assister_seance` est révoquée (`0041` sur `observation/lot-2026-09-21`, l.197-226 : quotas contournés et observation silencieuse, d'où la fermeture). Le tuteur obtient donc « Le cours n'a pas pu être rejoint » (`tuteur.accueil.assisterRefuse`, `fr.i18n.json:1261`) à chaque tentative. Constat de lecture croisé avec la baseline, non reproduit.
- La branche d'observation remplace ce geste par `go(Routes.tcObservation(seanceId))` (`observation/lot-2026-09-21:lib/features/accueil_famille/accueil_famille_page.dart:172-191`).
- Politique serveur : défauts 2 visites, 120 s par visite, 240 s au total (`0036_...sql:190-193`, appliquée) ; `01_PRODUIT_ET_PARCOURS.md:30` (« une visite, 120 secondes ») est périmé face au mandat et à `0036`.
- La porte d'observation exige un `seanceId` : impossible depuis l'Espace Groupe en production tant que `prochaineSeance.sessionId` reste nul (v0).

## 11. Comparaison avec `v0/verite-produit` (`33503fe`)

`git log main..v0/verite-produit` : `4e9903c` (docs, déjà dans C0) + `33503fe`. `33503fe` modifie 10 fichiers (+524/-24) :

| Fichier | Apport |
|---|---|
| `lib/core/tc_groupe/groupes_supabase.dart` (nouveau) | `GroupesSupabase` lit `mes_groupes_famille_v` (`:71-94`) ; `groupeDepuisLigne` pur, lève si `seuil_max` absent (`:28-30`) |
| `lib/core/tc_horloge/horloge_supabase.dart` (nouveau) | `HorlogeSeanceSupabase` : `horloge_seance(p_session_id)`, `maintenant_serveur()` ; `null` sans `sessionId` (`:123, 138`) |
| `port_groupes.dart`, `port_horloge_seance.dart` | `portGroupesSelon/portHorlogeSelon(demo: Env.playgroundActif)` : le double ne sort que sous `PLAYGROUND=true` |
| `test/teaching_core/a/groupes_supabase_test.dart` | 8 tests purs (ligne -> VM, horloge, pas de temps négatif) |
| `assets/i18n/fr.i18n.json`, `strings_fr.g.dart` | libellés d'enregistrement (hors C06) |
| `docs/current/08`, `09`, `CLAUDE.md` | registre V0 |

Ce que v0 **ne règle pas** (lu dans le code) :
1. `prochaineSeance` jamais renseignée (`groupes_supabase.dart:20`), et `horlogeGroupeProvider` appelle `suivre(groupeId)` sans `sessionId` (`port_horloge_seance.dart:62-66` inchangé) : flux vide. **Aucune séance, aucun compte à rebours, aucune entrée en production.**
2. Replis silencieux : titre absent -> Sayyid (`:50`, en contradiction avec `group_summary_vm.dart:27-29`), public absent -> enfant (`:60`), couleur -> 0 (`:39`), effectif -> 0 (`:56`).
3. `niveauHumain` jamais rempli (la vue ne joint pas `programme_niveaux`).
4. La vue n'identifie pas **quel enfant** du foyer est dans le groupe (pas de `student_id`) : impossible d'alimenter « élève sélectionné » ou « Mariam · Classe An-Nour ».
5. Libellés rendus en dur et sans accents (§5), fenêtre recalculée sans `join_opens_at_utc` (§4).
6. Aucun changement de routeur, de navigation, d'accueil tuteur, de Bibliothèque ou de travail.

Recommandation : reprendre les deux adaptateurs et leurs tests (cherry-pick ou copie ciblée par le coordinateur, conflits probables seulement dans `docs/current/08` et `CLAUDE.md`, non vérifié) **et** les corriger sur les points 2, 5 ; ne jamais réactiver le double hors Playground.

## 12. Défauts et écarts constatés (par lecture)

| # | Constat | Référence | Gravité |
|---|---|---|---|
| D1 | Groupes et horloge de démonstration servis en production au tuteur | `port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55`, entrée `accueil_famille_page.dart:463-468` | Bloquant |
| D2 | « Assister » appelle une RPC révoquée en production | `service_video.dart:131-134`, `accueil_famille_page.dart:182` ; `0041` l.226 | Bloquant |
| D3 | « Rejoindre » de l'Espace Groupe mène le tuteur à une impasse (`/tc/classe` interdit) | `routes_tc_a.dart:63-83`, `redirection.dart:138-140`, `carte_session.dart:58-63` | Majeur |
| D4 | « Rejoindre » grisé sur la liste (callback nul) | `routes_tc_a.dart:36`, `mes_groupes_page.dart:187` | Mineur (règle `lib/CLAUDE.md`) |
| D5 | Rôle d'Espace Groupe figé à `eleve` au démarrage | `app_router.dart:91-93, 692-700`, `session_controleur.dart:74` | Majeur dès qu'un CTA tuteur en dépend |
| D6 | Travail : actions jamais chargées, « Rien à préparer » à tort une fois le port branché | `espace_groupe_page.dart:179-183`, `emplacements_groupe.dart:73-80` | Majeur latent |
| D7 | Libellé interdit « Cours en cours » | `fr.i18n.json:1379, 1700, 2023`, `libelles_tc_groupe.dart:146-147` | Majeur (mandat) |
| D8 | Heures de l'accueil au fuseau de l'appareil, sans libellé de fuseau | `service_planning.dart:93-98`, `accueil_famille_page.dart:581-583` | Majeur (mandat : fuseau utile) |
| D9 | Replis silencieux de fuseau `Europe/Paris` et de date `DateTime.now()` | `service_planning.dart:30, 93-98, 259`, `parcours_offres_page.dart:88` | Moyen |
| D10 | Constantes de fenêtre côté client (10/20/15 min) | §4 | Moyen |
| D11 | Chaînes visibles hors slang (`min`, `h`, jours/mois v0) | `libelles_tc_groupe.dart:290-300`, v0 `horloge_supabase.dart:12-33` | Mineur |
| D12 | Commentaires périmés affirmant l'absence de tables/colonnes existantes | `demonstration_groupes.dart:10-19` (`sessions.groupe_id` existe depuis `0025:47`, `timezone_iana` lue par `horloge_seance`), `catalogue_local.dart:12-17`, `port_travail_a_venir.dart:149-153` | Documentation |
| D13 | Photo enseignant jamais résolue en URL signée | `espace_groupe_page.dart:314-320`, `photo_enseignant.dart:21-26` | Moyen |
| D14 | Séance annulée non visible dans l'horloge de groupe | `0033:427-485` (pas de statut) | Majeur (mandat : annulée ≠ cours normal) |
| D15 | Accueil tuteur : un élève en groupe hors horizon de matérialisation s'affiche « en recherche d'un enseignant » (l'état « affecté » ne lit que `teacher_student_assignments`) | `accueil_famille_page.dart:84-86, 256-258`, `0014:922-944`, `0033:298-306` | Moyen |

## 13. Services et composants réutilisables

- Temps : `FenetreSeance`, `SessionClockVM`, `PhaseSeance`, `HorlogeAffichee`, `NoticeDst`, `dureeAcademique` (`lib/core/tc_horloge/*`) ; `LibellesGroupe.compteARebours/ligneEtat/dureeLisible/phase` (après correction des libellés).
- Carte de séance : `CarteSession` (`lib/features/tc_espace_groupe/carte_session.dart:28-98`, horloges double fuseau, notice DST, conseil d'appareil « Tablette ou ordinateur conseillé » = maquette), `IdentiteGroupe` (`espace_groupe_page.dart:312-397`), `PhotoEnseignant`, `LisereGroupe`, `StatusPill`.
- Données réelles du foyer : `elevesDuFoyerProvider` (`lib/core/appairage/service_appairage.dart:293`), `seancesProvider`/`affectationsProvider` (`service_planning.dart:337-346`), `prochainCours`, `seanceAnnuleeDuJour`, `interruptionsDe` (`lib/core/planning/journee.dart:145-219`), `phaseEnfant` (`accueil_famille_page.dart:74-93`, pure et testée).
- Historique/présence : `ServiceSuivi` + `VueSuiviFoyer` (`sortDe`, facettes par enfant, plafond 200) : base directe de « Dernière séance » et de l'Historique.
- Offres (si `0043` appliquée ou remplacée) : `ServiceOffres`, `OffreHoraire`, `etapeParcours`.
- Travail : `TravailAVenir`, `BlocAvantProchainCours`, `SlotAction`, `IntentionPedagogique`.
- Bibliothèque : `PortCatalogue`, `DonneesCatalogue`, `SurfaceBibliotheque`, `CarteRessource`, `VignetteRessource`, `DetailRessourcePage`.
- Adaptateurs v0 : `GroupesSupabase`, `HorlogeSeanceSupabase` (+ tests).
- Observation (autre domaine) : `PortPolitiqueObservation`, `PortVisiteObservation`, `EntreeObservationPage`, route `/tc/observation/:seanceId`.

## 14. Dépendances backend manquantes (entrée / sortie / impact)

| # | Service attendu | Entrée | Sortie | Impact si absent |
|---|---|---|---|---|
| B1 | Classes du foyer par élève (extension de `mes_groupes_famille_v` ou RPC `mes_classes_foyer()`) | appelant (RLS foyer) | par ligne : `student_id`, prénom élève, `groupe_id`, libellé, parcours/`nom_cours`, niveau humain (jointure `programme_niveaux`), langue, public, enseignant (prénom, titre, clé photo), `seuil_max`, `nb_membres`, `timezone_iana`, état | Sans `student_id` : pas de sélecteur d'élève cohérent, pas d'en-tête « Mariam · Classe An-Nour » |
| B2 | Prochaine occurrence par classe et par élève | `groupe_id` (+ `student_id`) | `session_id`, `debut_utc`, `fin_prevue_utc`, `join_opens_at_utc`, **statut** (planifiée/annulée/reportée), enseignant d'occurrence + drapeau `remplacement` + motif, heures rendues (fuseau foyer et fuseau groupe), `seance_ouverte` | Sans elle : carte de séance vide (v0), aucun compte à rebours, aucune entrée |
| B3 | Planning daté | `groupe_id`, période | liste d'occurrences datées avec heure rendue dans le fuseau foyer **et** de référence, statut, motif, remplaçant, notice DST | « Planning habituel » et exceptions impossibles ; aucune conversion IANA possible côté client |
| B4 | Récurrence multi-créneaux matérialisée | créneaux du groupe | séances pour chaque jour de `groupe_creneaux`, horizon entretenu par ordonnanceur | Classes à 3 séances/semaine impossibles ; planning qui s'arrête après l'horizon |
| B5 | Report / remplacement tracés | action admin | occurrence modifiée avec lien, motif, enseignant remplaçant | Mandat : « annulée/reportée, absence, remplacement ne se présentent pas comme un cours normal » |
| B6 | Notice DST pour la famille | `session_id` ou `groupe_id` | transition, heures avant/après rendues, échéance | `NoticeDst` sans source hors admin |
| B7 | Catalogue de classes ouvertes | `membre_id`, `fuseau_vue` | classes compatibles avec enseignant, toutes les séances locales, durée, fuseau, **places restantes serveur**, état (ouverte, complète, liste d'attente) | Écran catalogue du mandat impossible ; contradiction `0043` (§6) |
| B8 | Inscription atomique | `classe_id`, `membre_id`, clé d'idempotence | `inscrit` / `en_attente_validation` / `liste_attente` / `refuse` + motif (`derniere_place_perdue`, `incompatible`, `deja_inscrit`, `prerequis`) | Pas de confirmation, pas de liste d'attente, pas de « dernière place » |
| B9 | URL signée courte de la photo enseignant | clé `photos_enseignants` | URL expirante | Photo publique jamais affichée |
| B10 | Travail : adaptateur possible sans backend pour la lecture (`learning_assignment` lisible) ; **RPC famille `marquer_travail_fait`** pour l'écriture | `assignment_id`, `student_id` | nouveau statut, horodatage | Cases à cocher des maquettes non actionnables |
| B11 | Progression famille | `student_id` | niveau humain courant, jalons, résumés transmis (`concern_famille_v`), observations partageables | Bloc « Progression » vide |
| B12 | Résumé de séance destiné à la famille | `session_id`, `student_id` | résumé filtré par élève, sans décisions des autres élèves ni note interne | Aujourd'hui seule source = `lesson_reports` non projeté (risque §9) |
| B13 | Application ou remplacement de `0043` | décision directeur | objets offres/parcours en production | `BlocParcours` muet, `ParcoursOffresPage` en échec |
| B14 | Rattachement séance -> groupe dans `mes_seances_v` | ajout `groupe_id` | colonne | Accueil et Historique ne savent pas à quelle classe appartient une séance |

## 15. Mapping routes cible -> existant (domaine C06)

| Route logique du mandat | Existant | Commentaire |
|---|---|---|
| `/tuteur/accueil` | `/tuteur` (`Routes.tuteurAccueil`, `routes.dart:65`) | Conserver l'identifiant ; alias si besoin |
| `/tuteur/classes/catalogue` | aucun ; le plus proche `/tuteur/parcours/:eleveId` (offres) | Dépend de B7/B8 et d'un arbitrage `0043` |
| `/tuteur/classes/:classeId` | `/tc/groupes/:groupeId` (`EspaceGroupePage`) | Alias ou déplacement sous `/tuteur` (le préfixe `/tuteur` éviterait l'exception `_teachingCoreAutorise`) ; ajouter le contexte élève |
| `.../planning` | section implicite de `CarteSession` | Nouveau sous-écran ; dépend de B3 |
| `.../travail` | `EmplacementAvantProchainCours` / `BlocAvantProchainCours` | Adaptateur `PortAssignations` à écrire ; écriture = B10 |
| `.../ressources` | `/tc/bibliotheque?groupe=` | Adaptateur `PortCatalogue` Supabase à écrire ; lecteur PDF absent |
| `.../progression` | `BlocProgression` (vide) | Dépend de B11 |
| `.../observer` | `/tc/observation/:seanceId` | Entrée à brancher depuis la classe ; domaine observation |
| `/tuteur/historique` | `/tuteur/suivi` (`SuiviFoyerPage`) | Domaine Compte/Suivi |

## 16. Contradictions à arbitrer par le coordinateur ou le directeur

1. Catalogue : `0043` (vitrine sans enseignant ni place, intention non engageante) contre `01`/`06`/mandat (enseignant, places, inscription atomique). Aucun des deux n'est en production.
2. « Cours toujours en cours » est demandé explicitement (mandat §5, `01:25`) alors que la partie observation interdit « Cours en cours » ; le premier n'est pas le libellé interdit, mais l'esprit de la règle peut viser les deux. À confirmer avant de toucher `fr.i18n.json:1702, 1923`.
3. Politique d'observation : `01:30` (1 visite, 120 s) périmé face au mandat et à `0036` (2 × 120 s, 240 s).
4. Rôle d'entrée du tuteur : `/salle` (chemin vivant fixé par `08` §3 selon la baseline l.140) ou `/tc/observation` (branche d'observation, appliquée côté base) ; l'accueil de `main` est entre les deux.
5. Maquette « Classe Details » (capture historique selon le mandat §2) : planning à trois jours et double fuseau Paris/Abidjan ; le serveur ne sait produire qu'un créneau par groupe.

## 17. Pistes de lot frontend pour l'agent Cours (sans backend)

- Reprendre les adaptateurs v0 (groupes, horloge) corrigés ; supprimer les replis silencieux ; lire `join_opens_at_utc`.
- Remplacer « Rejoindre » par l'action contextuelle famille (« Voir la classe » à l'accueil, « Observer la séance » dans la classe via la porte d'observation), ne rien rendre quand l'action ne peut pas aboutir.
- Corriger D5 (rôle lu depuis la session à chaque construction de route), D6, D7, D11.
- Écrire `PortAssignations` (lecture `learning_assignment`) et `PortCatalogue` (lecture `library_resource` / `ressources_du_groupe`) côté Flutter, en déclarant indisponible l'écriture « fait ».
- Pour catalogue, planning daté, exceptions, progression : écrans honnêtes « indisponible » + fixtures isolées en test, jamais en repli de production.
