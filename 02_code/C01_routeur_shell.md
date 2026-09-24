# C01 - Routeur, shell et navigation (cartographie en lecture seule)

Date : 24/09/2026. Dépôt `D:\RA _APP\RA -OFFICIAL-APP`, branche `c0/configuration-baseline-2026-09-23`, HEAD `3cf3544`.
Aucun fichier du dépôt modifié, aucune branche changée, aucune commande Flutter exécutée.

Légende employée dans tout le rapport :

- **CODE** : ce que le code fait, cité `fichier:ligne`.
- **DOC** : ce qu'un commentaire ou une spec prétend.
- **DÉDUIT** : conséquence tirée de la lecture, non reproduite à l'exécution (aucun PASS).
- **ÉCART** : le code contredit son commentaire, une spec ou le mandat.

Numéros de ligne = lignes physiques (outil Read). Le brief annonce `app_router.dart` à 820 lignes : c'est le compte de lignes non vides ; le fichier en a 865 physiques.

Lu intégralement : `lib/core/router/{app_router,routes,redirection,billet_salle,ecran_a_construire}.dart`, `lib/core/widgets/{nav_shell,page_shell,admin_shell,sous_navigation_domaine}.dart`, `lib/core/theme/app_gabarit.dart`, `lib/features/*/routes_tc_{a,b,c,e,g}.dart`, `chemins_tc_a.dart`, `lib/core/session/{session_state,session_controleur,source_session,claims_jwt}.dart`, `lib/app.dart`, `lib/main.dart`, `lib/core/auth/service_auth.dart`, `lib/core/agent/amorce_agent.dart`, `vercel.json`, `web/index.html`, `lib/features/compte/compte_page.dart`, `reglages_enfant_page.dart`, `ajouter_enfant_page.dart`, `test/router/navigation_test.dart`.
Lu partiellement : `accueil_famille_page.dart` (1-520), `appareils_page.dart` (1-100), `appairage_page.dart` (1-110), `eleve_connexion_page.dart` (1-280), `inscription_page.dart` (14-133), `entree_observation_page.dart` (96-392), `espace_groupe_page.dart` (40-190), `group_home_vm.dart` (140-203), `test/router/redirection_test.dart` (1-240), en-têtes de `suivi_foyer`, `disponibilites`, `parcours_offres`, `connexion`, `feuille_appareil_eleve`.
Paquet `go_router` 18.0.1 (`pubspec.lock:560-567`) lu dans le cache pub pour les comportements par défaut.
Maquettes ouvertes (navigation seulement) : `mobile/accueil  tuteur mobile light mode.png`, `acceuil tuteur desktop light.png`, `mobile/mon compte tuteur mobile light mode.png`, `mon compte tuteur desktop light mode.png`, tuiles `01_visuel/tuiles_V2/L_01_rail_haut.png`, `L_08_rail_bas.png`, `D_T04_tab_rail.png`.

---

## 0. Synthèse

1. **Un seul `GoRouter`** (`app_router.dart:79-632`), 72 chemins déclarés dont 12 redirections pures et 2 routes de développement compilées seulement sous `GALERIE`. Garde unique : fonction pure `deciderRedirection` (`redirection.dart:16-117`), par préfixe de rôle ; DOC et CODE s'accordent : commodité, pas barrière (`redirection.dart:13-15`, `lib/CLAUDE.md:56-57`).
2. **Rôle tuteur** = `app_metadata.role == 'guardian'` dans le JWT, statut `active` ou `provisional_active` lu dans `profiles`. Racine et préfixe de garde = `/tuteur` (`routes.dart:65, 350, 361`).
3. **Navigation tuteur actuelle** : Accueil, Disponibilités, Réglages, Suivi (`nav_shell.dart:79-100`) + « Mon compte » secondaire rendu seulement à partir de 600 px. **Sur téléphone, aucun chemin UI ne mène à `/compte`, donc le tuteur n'a aucune déconnexion** (DÉDUIT, §3.3).
4. Foyer, ajout d'enfant, appairage, parcours, classes `/tc/*`, observation : **hors coquille, aucune navigation rendue** (`app_router.dart:278-298, 596-600`).
5. **Aucun `errorBuilder`** : un chemin inconnu dans un sous-arbre autorisé tombe sur l'écran par défaut de go_router, en anglais, qui affiche l'exception brute. Accès refusé = redirection silencieuse. Session expirée = retour silencieux sur `/connexion`, destination perdue. Aucune mémoire de retour.
6. **Web** : stratégie d'URL par défaut (hash). `context.push` ne reflète pas l'URL en go_router 18 : refresh et précédent incohérents sur les sous-pages de compte (DÉDUIT).
7. **`EcranAConstruire`** n'a qu'un usage : l'écran de `/` pendant la résolution de session. Chaque démarrage affiche « Écran à construire / Cet écran arrive à l'étape 3 ».
8. **Mapping §4** : 13 lignes ont un équivalent existant (conserver l'identifiant ou aliaser), les autres sont absentes. Piège principal : `prefixePour(guardian)` renvoie `tuteurAccueil` ; changer la valeur de `Routes.tuteurAccueil` casserait la garde de tout `/tuteur/*`.
9. **Secret dans une URL** : seulement `/agent?jeton=rag_...` (hors tuteur). Code d'appairage, billet de salle, contexte de classe restent hors URL. Les identifiants UUID en chemin ne sont pas des secrets (RLS), mais **`/tuteur/foyer/appairer/:eleveId` émet un nouveau code à chaque ouverture**, refresh compris.
10. **4e destination** : recommandation **Historique** (§6), seul candidat adossé à un écran et à un service existants (`/tuteur/suivi`, TUT-06), déjà branche de la coquille, et exigé par le complément observation (§8 du mandat).

---

## 1. Architecture du routeur et des coquilles

### 1.1 Construction (CODE)

| Point | Preuve |
|---|---|
| Provider unique `routeurProvider` | `app_router.dart:79` |
| Rafraîchissement sur changement de session (`ref.listen` + `ChangeNotifier`) | `app_router.dart:80-85, 97, 638-640` |
| `initialLocation: '/'` | `app_router.dart:96` |
| Redirection globale, session relue à chaque décision (`ref.read`) | `app_router.dart:98-105` |
| Rôle de l'Espace Groupe lu **une seule fois** à la construction | `app_router.dart:91-93` (voir ÉCART §3.3-5) |
| Aucune `errorBuilder` / `errorPageBuilder` / `onException` / `debugLogDiagnostics` | grep sur `lib/` : aucune occurrence |
| `MaterialApp.router(routerConfig: ...)` | `app.dart:45-69` |
| `themeMode` = paramètre, `ThemeMode.system` par défaut ; `main.dart:68` n'en passe aucun | `app.dart:32, 50` |
| Stratégie d'URL web : aucun `usePathUrlStrategy`, aucun `flutter_web_plugins` | grep `lib/`, `pubspec.yaml`, `web/` : aucune occurrence, donc hash par défaut (DÉDUIT du défaut Flutter) |
| Réécriture Vercel tout vers `index.html` (utile seulement en stratégie « path ») | `vercel.json:6-8` |
| La CI refuse un second `GoRouter` | `tool/verifier_jetons.dart:134, 262-275` |

### 1.2 Les coquilles

| Coquille | Définition | Routes enveloppées | Comportement |
|---|---|---|---|
| `_CoquilleNavigation` | `app_router.dart:777-824` | branches des `StatefulShellRoute.indexedStack` élève (`193-229`), tuteur (`236-277`), enseignant (`301-333`) | `NavShell(indexActif: currentIndex)` ; destination → `goBranch(index)` si le chemin figure dans la liste (`803-815`) ; secondaires → `GoRouter.go` (`820`) |
| `_CoquilleSecondaire` | `app_router.dart:727-775` | les 5 routes `/compte*` (`159-186`) | rôle lu dans la session ; admin → `AdminShell` sans domaine actif (`751-759`) ; autres → `NavShell(indexActif: null)` (`761-773`) |
| `_CoquilleAdmin` | `app_router.dart:840-864` | toutes les routes `/admin/*` | `AdminShell` avec domaine explicite |
| aucune | - | `/`, `/connexion*`, `/inscription`, `/agent`, `/attente*`, poses tuteur (`278-298`), poses enseignant (`347-366`), `/controleur`, `/comptable`, `/tc/*`, `/salle`, `/_galerie*` | l'écran seul |

**`NavShell`** (`nav_shell.dart:202-345`) :

- 4 destinations au plus (assert `225-237`, `maxDestinations = 4` ligne `285`) ; moins de 2 destinations : aucun chrome (`292-294`).
- Forme choisie par la largeur seule (`AppGabarit.de`, `app_gabarit.dart:91-107`) : barre basse sous 600, rail de 600 à 1199, tiroir permanent à partir de 1200 (`app_gabarit.dart:26-35, 60-66`). Aucun état « replié/déplié » choisi par l'usager.
- Barre basse `NavigationBar` M3 plate, filet haut (`nav_shell.dart:348-399`) ; **omise quand `indexActif == null`** (`304`), donc sur toutes les pages `/compte*` en mobile.
- Rail `NavigationRail` 80 px, libellés toujours visibles (`labelType: all`, `433`), secondaires en `trailing`, icône seule + infobulle (`455-473`).
- Tiroir `NavigationDrawer` 256 px (`app_gabarit.dart:121`), secondaires sous un séparateur (`nav_shell.dart:504-535`).
- Les secondaires ne sont jamais rendues dans la barre basse ; DOC `nav_shell.dart:269-274` l'assume et renvoie aux « tuiles Outils du tableau de bord ».
- Aucune marque « Rewayah », aucun bouton replier, aucune cloche, aucune bascule de thème.

**`PageShell`** (`page_shell.dart:31-142`) : `titre` (headlineLarge), `entete` non défilant, `actions` collées en bas, `defilante`, `OfflineBanner`, colonne bornée. **Pas d'emplacement d'actions d'en-tête** (cloche, bascule clair/sombre des maquettes desktop), **pas de bouton retour**.

**`AdminShell`** (`admin_shell.dart:43-184`) : 8 domaines, tiroir sous 600, rail, sidebar 288 ; barre supérieure recherche + notifications + compte. La cloche ouvre une feuille vide statique (`459-472`) : aucune donnée de notification.

**`SousNavigationDomaine`** (`sous_navigation_domaine.dart:21-69`) : onglets dont chacun est une route (`TabBar` + `GoRouter.go`, `55-67`). Réutilisable pour les onglets « Séances / Observations » de l'Historique.

### 1.3 Session et porte d'accès

`SessionState.porte` (`session_state.dart:133-172`) :

| Situation | Porte |
|---|---|
| session non résolue | `chargement` (`134-136`) |
| pas de `profileId` | `deconnecte` (`137-139`) |
| lecture `profiles` pas encore faite | `chargement` (`143-144`) |
| lecture réussie, aucune ligne | `inscription` (`148-149`) |
| lecture en échec (réseau ou refus) | `attente` (`153-154`) |
| profil présent, jeton sans rôle | `attente` (`160-162`) |
| `active` / `provisional_active` | `actif` (`164-165`) |
| `disabled` | `suspendu` (`166`) |
| `pending_kyc` ou statut illisible | `attente` (`169`) |

Source réelle : rôle et foyer tirés du JWT (`source_session.dart:56-59`), statut et mode d'interface lus dans `profiles` (`source_session.dart:77-105`), toute exception → `echouee` (`106-123`).

---

## 2. Liste exhaustive des routes existantes

### 2.1 Codes de garde (`redirection.dart`)

| Code | Règle | Lignes |
|---|---|---|
| G-CHG | tant que la porte est `chargement`, **aucune** redirection : toute route se construit | `34-35` |
| G-PUB | déconnecté : seuls les sous-arbres `/connexion` et `/agent` passent, le reste → `/connexion` ; un compte actif qui les demande → racine | `39-49`, `81-87` |
| G-INS | porte `inscription` : seul le sous-arbre `/inscription`, sinon → `/inscription` | `55-58` |
| G-ATT | portes `attente`/`suspendu` : seul le sous-arbre `/attente`, sinon → `/attente` | `64-68` |
| G-CPT | sous-arbre `/compte` : tout rôle actif | `100-102` |
| G-TC | `/tc/groupes*` et `/tc/bibliotheque*` : élève, tuteur ; `/tc/classe` : enseignant, élève ; `/tc/mushaf` : élève ; `/tc/observation*` : tuteur, admin, contrôleur | `108-110`, `133-150` |
| G-PRE | sinon, le chemin doit être dans le préfixe du rôle, sinon → racine du rôle | `114-115`, `routes.dart:359-366` |
| G-SAL | `/salle` : billet `extra` présent et âgé de moins de 20 min, sinon → racine | `93-96`, `billet_salle.dart:31-35` |
| G-DEV | `/_galerie*` échappe à toute garde si `Env.galerieActive` | `25-29` |

Racines : élève `/eleve`, tuteur `/tuteur`, enseignant `/enseignant/journee`, contrôleur `/controleur`, admin `/admin`, comptable `/comptable` (`routes.dart:348-355`). Préfixes : `/eleve`, `/tuteur`, `/enseignant`, `/controleur`, `/admin`, `/comptable` (`routes.dart:359-366`).

### 2.2 Routes publiques, admission, compte

| Chemin | Constante | Écran | Coquille | Accès effectif | Garde | Entrées UI |
|---|---|---|---|---|---|---|
| `/` | `Routes.racine` (`routes.dart:12`) | `EcranAConstruire("Chargement")` (`app_router.dart:107-111`) | aucune | visible seulement en `chargement` ; sinon redirigé | G-CHG puis G-PUB/INS/ATT ; actif → racine (`81`) | démarrage, retour lien magique/Google (`service_auth.dart:48`) |
| `/connexion` | `connexion` (`15`) | `ConnexionPage` TUT-00 (`112-115`) | aucune | déconnecté | G-PUB | redirection |
| `/connexion/eleve` | `connexionEleve` (`21`) | `EleveConnexionPage` ELV-01 (`116-120`) | aucune | déconnecté (appareil enfant) | G-PUB | `connexion_page.dart:166-168` |
| `/inscription` | `inscription` (`28`) | `InscriptionPage` TUT-00c, 4 pages internes (`121-124`) | aucune | porte `inscription` | G-INS | redirection |
| `/agent` (`?jeton=`) | `agentEntree` (`260`), `entreePour` (`263`) | `AgentEntreePage` AGT-00 (`128-131`) | aucune | déconnecté | G-PUB | lien remis à l'agent |
| `/attente` | `attente` (`31`) | `AttentePage` (`134-137`) | aucune | `attente`/`suspendu` | G-ATT | redirection, `signature_page.dart:107`, `depot_piece_page.dart:81` |
| `/attente/accuse` | `attenteAccuse` (`37`) | `AccusePage` (`138-141`) | aucune | idem | G-ATT | `attente_page.dart:140` |
| `/attente/contrat` | `attenteContrat` (`40`) | `ContratPage` (`142-145`) | aucune | idem | G-ATT | `attente_page.dart:145` |
| `/attente/piece` | `attentePiece` (`43`) | `DepotPiecePage` (`146-149`) | aucune | idem | G-ATT | `attente_page.dart:150, 201` |
| `/compte` | `compte` (`291`) | `ComptePage` (`159-163`, `compte_page.dart:30-114`) | secondaire | tout rôle actif | G-CPT | secondaire NavShell ≥ 600 (`nav_shell.dart:162-168`), `planning_page.dart:172`, bouton compte d'`AdminShell` |
| `/compte/profil` | `compteProfil` (`294`) | `ProfilPersonnelPage` (`164-168`) | secondaire | tout rôle actif | G-CPT | `compte_page.dart:59`, `reglages_enfant_page.dart:63`, `profil_enseignant_page.dart:597` |
| `/compte/reglages` | `compteReglages` (`297`) | `ReglagesComptePage` (`169-173`) | secondaire | tout rôle actif | G-CPT | `compte_page.dart:65`, `reglages_enfant_page.dart:75`, `profil_enseignant_page.dart:603` |
| `/compte/profils` | `compteProfils` (`300`) | `ProfilsComptePage` (`174-178`) | secondaire | **tout rôle actif** ; entrée montrée au seul tuteur (`compte_page.dart:67-73`) | G-CPT | `compte_page.dart:72, 181`, `reglages_enfant_page.dart:69` |
| `/compte/profils/:profilId` | `compteProfilEnfantPour` (`306-307`) | `ProfilEnfantPage` (`179-186`) | secondaire | tout rôle actif | G-CPT | `compte_page.dart:400-402` |

### 2.3 Espaces de rôle

| Chemin | Constante | Écran | Coquille | Rôle | Garde | Entrées UI |
|---|---|---|---|---|---|---|
| `/eleve` | `eleve` (`48`) | `AccueilElevePage` (`199-203`) | navigation, branche 0 | élève | G-PRE | barre |
| `/eleve/coran` | `eleveCoran` (`51`) | `MushafPage` (`208-216`) | branche 1 | élève | G-PRE | barre |
| `/eleve/suivi` | `eleveSuivi` (`54`) | `SuiviElevePage` (`221-225`) | branche 2 | élève | G-PRE | barre |
| `/tuteur` | `tuteurAccueil` (`65`) | `AccueilFamillePage` TUT-01, titre « Votre foyer » (`242-246`) | navigation, branche 0 | tuteur | G-PRE | barre, racine, `parcours_offres_page.dart:170, 514, 567` |
| `/tuteur/disponibilites` | `tuteurDisponibilites` (`98`) | `DisponibilitesPage` TUT-04 (`251-255`) | branche 1 | tuteur | G-PRE | barre, `accueil_famille_page.dart:352-354` |
| `/tuteur/reglages` | `tuteurReglages` (`101`) | `ReglagesEnfantPage` TUT-05 (`260-264`) | branche 2 | tuteur | G-PRE | barre, `accueil_famille_page.dart:452-457`, `compte_page.dart:615` |
| `/tuteur/suivi` | `tuteurSuivi` (`104`) | `SuiviFoyerPage` TUT-06 (`269-273`) | branche 3 | tuteur | G-PRE | barre seulement |
| `/tuteur/foyer` | `tuteurFoyer` (`68`) | `AppareilsPage` TUT-02, titre « Appareils » (`278-281`) | **aucune** | tuteur | G-PRE | `accueil_famille_page.dart:445-450`, `compte_page.dart:79, 345` (libellé « Foyer »), `appairage_page.dart:97`, `ajouter_enfant_page.dart:74, 96` |
| `/tuteur/foyer/ajouter-enfant` | `tuteurAjouterEnfant` (`71`) | `AjouterEnfantPage` (`282-285`) | aucune | tuteur | G-PRE | `accueil_famille_page.dart:245`, `appareils_page.dart:68, 93`, `reglages_enfant_page.dart:84`, `compte_page.dart:390` |
| `/tuteur/foyer/appairer/:eleveId` | `appairerPour` (`77-80`) | `AppairagePage` QR + code (`286-290`) | aucune | tuteur | G-PRE | `appareils_page.dart:167` |
| `/tuteur/parcours/:eleveId` | `parcoursPour` (`89-95`) | `ParcoursOffresPage` (`294-298`) | aucune | tuteur | G-PRE | `bloc_parcours.dart:149` |
| `/enseignant/journee` | `enseignantJournee` (`109`) | `JourneePage` (`307-311`) | navigation, branche 0 | enseignant | G-PRE | barre |
| `/enseignant/creneaux` | `enseignantCreneaux` (`112`) | `CreneauxPage` (`316-320`) | branche 1 | enseignant | G-PRE | barre |
| `/enseignant/profil` | `enseignantProfil` (`115`) | `ProfilEnseignantPage` (`325-329`) | branche 2 | enseignant | G-PRE | barre |
| `/enseignant/bienvenue` | `enseignantBienvenue` (`133`) | `BienvenueEnseignantPage` (`347-351`) | aucune | enseignant | G-PRE | - |
| `/enseignant/seance/:seanceId/cahier` | `cahierPour` (`142-143`) | `CahierPage` (`352-356`) | aucune | enseignant | G-PRE | - |
| `/enseignant/groupe/:groupeId` | `groupePour` (`149`) | `FicheGroupePage` (`357-361`) | aucune | enseignant | G-PRE | - |
| `/enseignant/groupe/:groupeId/revue` | `revuePour` (`153-154`) | `RevueGroupePage` (`362-366`) | aucune | enseignant | G-PRE | - |
| `/controleur` | `controleur` (`159`) | `PlanningControleurPage` (`371-375`) | aucune | contrôleur | G-PRE | racine |
| `/comptable` | `comptable` (`269`) | `ComptePage` (`585-588`) | aucune | comptable | G-PRE | racine |

### 2.4 Administration (condensé, hors périmètre tuteur)

Toutes sous `_CoquilleAdmin`, garde G-PRE admin (`app_router.dart:385-582`) :
`/admin` (TableauDeBord) ; `/admin/operations` → redirection `/admin/operations/groupes` ; `/admin/operations/{groupes,attributions,demandes}` ; `/admin/personnes` → `/admin/personnes/dossiers` ; `/admin/personnes/{dossiers,comptes}` ; `/admin/pedagogie` → `/admin/pedagogie/diagnostics` ; `/admin/pedagogie/{diagnostics,progression,evaluations,programmes,qualite}` ; `/admin/configuration` → `/admin/configuration/regles` ; `/admin/configuration/{regles,fonctionnalites,conservation-donnees}` ; `/admin/securite-audit` → `/admin/securite-audit/journal` ; `/admin/securite-audit/{journal,acces-agents}` ; anciennes routes plates redirigées : `/admin/tableau-de-bord`, `/admin/dossiers`, `/admin/comptes`, `/admin/attribution`, `/admin/demandes`, `/admin/journal`, `/admin/acces-agents` (`549-582`). Au total 28 chemins dont 12 redirections. Il n'existe **aucune** vue admin des observations (le complément observation §8 en demande une).

### 2.5 Teaching Core, salle, développement

| Chemin | Source | Écran | Coquille | Rôles (G-TC) | Paramètres | Entrées UI (C0) |
|---|---|---|---|---|---|---|
| `/tc/groupes` | `chemins_tc_a.dart:14`, `routes_tc_a.dart:34-37` | `MesGroupesPage` | aucune | élève, tuteur | - | `accueil_famille_page.dart:463-468`, `espace_groupe_page.dart:109` |
| `/tc/groupes/:groupeId` | `routes_tc_a.dart:38-50` | `EspaceGroupePage(role: sessionRole)` | aucune (sortie propre `espace_groupe_page.dart:95-113`) | élève, tuteur | `groupeId` | `mes_groupes_page.dart:183` |
| `/tc/bibliotheque` (`?groupe=`) | `routes_tc_b.dart:78-82, 101-105` | `BibliothequePage` | aucune | élève, tuteur | requête `groupe` | `espace_groupe_page.dart:262` |
| `/tc/bibliotheque/:resourceId` | `routes_tc_b.dart:84-91` | `DetailRessourcePage` | aucune | élève, tuteur | `resourceId` | `bibliotheque_page.dart:46` |
| `/tc/mushaf` | `routes_tc_c.dart:24-29` | `MushafPage` | aucune | élève | - | aucune (l'élève passe par `/eleve/coran`) |
| `/tc/classe` | `routes_tc_e.dart:34-49` | `ClasseLivePage` si `extra` est `ContexteClasseLive`, sinon `_ClasseSansContexte` | aucune | enseignant, élève | `extra` | `routes_tc_a.dart:68-82` (« Rejoindre ») |
| `/tc/observation/:seanceId` | `routes_tc_g.dart:37-45` | `EntreeObservationPage` | aucune | tuteur, admin, contrôleur | `seanceId` | **aucune sur C0** (grep `tcObservation`/`versObservation` : définitions seulement) |
| `/salle` | `routes.dart:278`, `app_router.dart:609-616` | `SallePage` | aucune | tout rôle actif avec billet | `extra BilletSalle` | tuteur « Assister » `accueil_famille_page.dart:192-196` ; `accueil_eleve_page.dart:398`, `journee_page.dart:536`, `planning_page.dart:134` |
| `/_galerie`, `/_galerie/compte` | `routes.dart:283-286`, `app_router.dart:619-629` | galeries de dev | aucune | tous si compilé | - | outil de dev (`CLAUDE.md:82-83`) |

### 2.6 Constats sur la table

- **Trois noms pour un écran** : `/tuteur/foyer` rend `AppareilsPage` titrée « Appareils » (`fr.i18n.json` `appareils.titre`), documentée « Foyer et appareils » (`routes.dart:67`), atteinte par une ligne « Foyer » (`compte.appareils`) dans Mon compte (`compte_page.dart:74-82`) et par « Appareils du foyer » dans l'accueil. Inversement `/tuteur` est titrée « Votre foyer » mais s'appelle « Accueil » dans la barre avec l'icône `AppIcons.foyer` (`nav_shell.dart:80-83`).
- `/compte/profils*` est ouvert à tout rôle actif (G-CPT) alors que l'entrée n'est montrée qu'au tuteur ; les données restent bornées par la RLS (DÉDUIT).
- `/tc/observation/:seanceId` est **orpheline sur C0**. Elle est branchée sur `observation/lot-2026-09-21` (`accueil_famille_page.dart:191` de cette branche, qui retire l'appel `assisterEnTuteur` et le passage par `/salle`).
- Code mort : `Routes.publiques` (`routes.dart:341-345`) n'est lu nulle part, la garde tient sa propre liste en dur ; `racineDe` et `cheminsDeclares` (`app_router.dart:655-678`) sont `@visibleForTesting` mais aucun test ne les appelle (grep).
- État des autres branches pour ce domaine : entre `main` et C0, les fichiers du routeur et des coquilles ne diffèrent que par des chemins cités en commentaire (vérifié : aucune ligne de code modifiée). `v0/verite-produit` : même différence de commentaires dans le routeur. `observation/lot-2026-09-21` : aucun changement du routeur, change l'entrée « Assister ». `codex/r2-adaptive-shell` : 116 commits de retard, sa refonte M3 de `NavShell` (barre, rail, tiroir, clés) est déjà présente en substance sur `main`. `core24/fable-frontend` modifie `/salle` (`EntreeSalle`) et `billet_salle.dart` : branche déclarée non conforme, à ne pas intégrer.

---

## 3. Rôle tuteur : détection, redirection, navigation

### 3.1 Détection (CODE)

1. Le hook SQL pose `app_metadata.role` et `app_metadata.household_id` dans le JWT ; le client les décode sans vérifier la signature, pour orienter la navigation seulement (`claims_jwt.dart:5-16, 62-71`).
2. `AppRole.depuisSql('guardian')` → `AppRole.guardian` (`enums.dart:23, 36-43`) ; un rôle inconnu donne `null`, jamais un rôle par défaut.
3. Le statut vient de `profiles.account_status` (`source_session.dart:77-105`). Porte `actif` si `active` ou `provisional_active` (`session_state.dart:163-165`).
4. L'élève adulte autonome est aussi `guardian` : « son propre tuteur » (`enums.dart:22`, `inscription_page.dart:35-41` : les choix « tuteur » et « élève adulte » écrivent tous deux `AppRole.guardian`).
5. Démonstration : un courriel `tuteur@...` ou `guardian@...` ouvre une session locale `guardian` quand `DEMO_AUTH` est compilé (`session_controleur.dart:33-34, 78-91`).
6. Un seul rôle effectif par session (`compte_page.dart:703-705`) : un tuteur ne peut pas atteindre `/eleve/*` (G-PRE). « Ouvrir mon espace élève » (mandat §5 Foyer) exige donc un autre mécanisme de session ou de rôle : **dépendance auth/backend**.

### 3.2 Redirection (CODE)

- Tuteur actif sur `/`, `/connexion*`, `/inscription*`, `/agent*`, `/attente*` → `/tuteur` (`redirection.dart:81-87`).
- Toute route hors `/tuteur`, `/compte`, `/tc/groupes`, `/tc/bibliotheque`, `/tc/observation` → `/tuteur`, sans message (`114-115`).
- `/tc/classe` et `/tc/mushaf` refusés au tuteur (`138-143`).
- `/salle` sans billet valide → `/tuteur` (`93-96`).

### 3.3 Navigation actuelle du tuteur

| Ordre | Libellé (`fr.i18n.json` `nav.tuteur`) | Icône | Chemin | Écran |
|---|---|---|---|---|
| 1 | Accueil | `AppIcons.foyer` | `/tuteur` | `AccueilFamillePage` |
| 2 | Disponibilités | `AppIcons.disponibilites` | `/tuteur/disponibilites` | `DisponibilitesPage` |
| 3 | Réglages | `AppIcons.reglages` | `/tuteur/reglages` | `ReglagesEnfantPage` |
| 4 | Suivi | `AppIcons.suivi` | `/tuteur/suivi` | `SuiviFoyerPage` |
| secondaire | Mon compte | `AppIcons.sortie` (icône de sortie) | `/compte` | `ComptePage` |

Sources : `nav_shell.dart:79-100, 160-168`. La clé `nav.tuteur.foyer` (« Foyer ») existe dans `fr.i18n.json` mais n'est utilisée par aucune destination.

Par largeur :

- **Sous 600** : barre basse aux 4 destinations, rendue seulement sur les 4 routes de branche ; aucune entrée Compte ; sur `/compte*` aucune barre (`nav_shell.dart:304`) ; sur les poses (`/tuteur/foyer*`, `/tuteur/parcours/*`, `/tc/*`) aucun chrome.
- **600 à 1199** : rail avec libellés, « Mon compte » en icône seule dans `trailing`.
- **1200 et plus** : tiroir permanent 256 px, « Mon compte » sous un séparateur.

Défauts constatés (DÉDUIT sauf mention) :

1. **Pas de déconnexion sur téléphone pour le tuteur.** La seule déconnexion d'un compte actif non enseignant est `compte_page.dart:103-109`. Recensement de tous les `Routes.compte` (grep `lib/`) : secondaire NavShell (≥ 600), `planning_page.dart:172` (contrôleur), bouton compte d'`AdminShell`. `/tuteur/reglages` mène à `/compte/profil`, `/compte/profils`, `/compte/reglages` (`reglages_enfant_page.dart:58-76`) mais jamais à `/compte`. **ÉCART** avec la DOC `nav_shell.dart:269-274` : aucune « tuile Outils » ne mène au compte sur `AccueilFamillePage` (`_GererLeFoyer`, `accueil_famille_page.dart:437-471` : appareils, réglages, mes groupes).
2. **Poses sans chrome ni sortie** : `/tuteur/foyer` n'a aucun bouton retour (seuls liens `appareils_page.dart:68, 93, 167`) ; `/tc/groupes` non plus (seul lien `mes_groupes_page.dart:183`) ; `/tc/observation/:id` rend un `PageShell` sans sortie, et ses états `terminee`/`refusee` sont des `EmptyState` sans action (`entree_observation_page.dart:158-159, 182-196`). Ces pages sont atteintes par `go`, sans pile : le retour système Android ferme l'application.
3. **Perte d'état en quittant la coquille** : aller sur une route hors `StatefulShellRoute` démonte la coquille et l'état de ses branches (sélection, défilement).
4. **« Rejoindre » sans destination pour le tuteur** : `onRejoindre` est toujours câblé (`routes_tc_a.dart:47-48`) vers `/tc/classe` (`68-82`), route refusée au tuteur (`redirection.dart:138-140`) : retour silencieux sur `/tuteur`.
5. **Rôle de l'Espace Groupe figé** : `sessionRole` est lu par `ref.read` à la construction (`app_router.dart:91-93`) ; le provider n'est jamais reconstruit (seulement `ref.listen`, `82-85` ; seul consommateur `app.dart:42`). Au premier rendu, la session vaut `chargement` (`session_controleur.dart:74`), donc rôle `null` → `RoleEspaceGroupe.eleve` (`app_router.dart:692-700`). **ÉCART** avec le commentaire `app_router.dart:87-90` (« une reconnexion recrée ce provider »). Impact actuel faible pour le tuteur, car élève et tuteur sont tous deux « côté famille » (`group_home_vm.dart:201-202`), mais à corriger avant toute différence tuteur/élève dans l'Espace Groupe.
6. **Même mécanisme, rôle élève** : la destination « Compte » (`nav_shell.dart:73-77`) n'a pas de branche (3 branches, `app_router.dart:196-228`) ; `onAller` appelle `goBranch(3)` (`810-814`), qui viole l'assert `index < route.branches.length` (go_router `route.dart:1473`) puis accède à `branches[3]`. Aucun test ne tape « Compte » (grep). À ne pas reproduire quand Compte deviendra une destination tuteur.
7. Icône « Mon compte » = `AppIcons.sortie`, l'icône de sortie ; icône « Accueil » = `AppIcons.foyer`.

### 3.4 Ce que montrent les maquettes (navigation seulement)

| Maquette | Destinations | Placement |
|---|---|---|
| `mobile/accueil  tuteur mobile light mode.png` | Accueil, Foyer, Compte (3) | barre basse flottante arrondie ; cloche en haut à droite ; « Voir l'historique » dans la carte Dernière séance |
| `mobile/mon compte tuteur mobile light mode.png` | Accueil, Foyer, Historique (horloge), Compte (4) | barre basse flottante ; engrenage en haut à droite |
| `acceuil tuteur desktop light.png` | Accueil, Foyer, Historique (carrés empilés) + Compte en pied | sidebar avec « Rewayah » et bouton replier « « » ; bascule clair/sombre et cloche en haut à droite |
| `mon compte tuteur desktop light mode.png` | Accueil, Foyer, Historique (horloge), Compte (4e, en ligne) | sidebar avec logo livre + « Rewayah », sans bouton replier |
| `tuiles_V2/D_T04_tab_rail.png` (tablette sombre) | 3 icônes sans libellé + Compte en pied | rail replié, bouton déplier « » » |

Les maquettes se contredisent (3 ou 4 onglets mobiles, Compte en pied ou en ligne, deux icônes Historique). Le mandat §4 tranche : « Accueil · Foyer · Historique · Compte, même ordre et mêmes destinations partout ; les captures à trois destinations ne justifient pas une navigation variable ». Le brief ne cite que la maquette mobile d'accueil (3 onglets) ; celle de Mon compte mobile en montre 4.

---

## 4. 404, accès refusé, session expirée, retour, liens profonds, refresh

| Situation | Ce que fait le code | Preuve | Écart au mandat §8 |
|---|---|---|---|
| Chemin inconnu **hors** du préfixe (actif) | redirection silencieuse vers la racine du rôle | `redirection.dart:114-115` | pas de page 404 |
| Chemin inconnu, déconnecté | → `/connexion` | `redirection.dart:47-49` | idem |
| Chemin inconnu **dans** un sous-arbre autorisé (`/tuteur/historique`, `/compte/x`, `/connexion/x`, `/tc/groupes/a/b`) | écran par défaut go_router : `AppBar("Page Not Found")`, `SelectableText(error.toString())`, bouton « Home » vers `/` | go_router 18.0.1 `lib/src/pages/material.dart:42-53`, `builder.dart:354` | anglais, exception technique affichée, hors charte |
| Ressource d'un autre foyer ou supprimée | selon l'écran : Espace Groupe « groupe introuvable », état subi (`espace_groupe_page.dart:157-166`) ; `ProfilEnfantPage` filtre la liste du foyer côté client et affiche « aucun profil » (`compte_page.dart:439-455`) ; `AppairagePage` affiche l'erreur de `creerCode` (`appairage_page.dart:58-79`) | idem | pas de distinction « existe mais interdit » (bon : aucune fuite) ; pas de retour contextualisé |
| Route d'un autre rôle | redirection silencieuse, aucun message | `redirection.dart:114-115` | « Vous n'avez pas accès à cette page » absent |
| Compte en attente ou suspendu | portail `/attente` avec déconnexion | `redirection.dart:64-68`, `attente_page.dart:60-62` | conforme dans l'esprit |
| Réseau coupé au démarrage | lecture `profiles` en échec → porte `attente` → le tuteur actif voit le portail dossier | `source_session.dart:106-123`, `session_state.dart:153-154` | choix documenté (« on ferme ») mais contraire à l'état « Hors ligne » du mandat : **à trancher** |
| Chargement de session | `/` rend `EcranAConstruire` (« Chargement », « Écran à construire », « Cet écran arrive à l'étape 3 ») ; aucun délai, aucun message de chargement prolongé | `app_router.dart:107-111`, `ecran_a_construire.dart:24-37` | « La connexion prend plus de temps que prévu » absent ; une lecture `profiles` sans réponse laisse l'écran indéfiniment (DÉDUIT, pas de timeout `source_session.dart:77-83`) |
| Session expirée ou déconnexion | `onAuthStateChange` → `SessionState.deconnecte` → toute route → `/connexion`, sans paramètre ni message | `source_session.dart:38-41, 52-54`, `redirection.dart:47-49` | pas de « session expirée », pas de retour |
| Retour après reconnexion | actif sur `/connexion` → racine ; lien magique et Google reviennent sur `Uri.base.origin`, donc `/` | `redirection.dart:81-87`, `service_auth.dart:48, 52, 64` | destination perdue |
| Lien profond pendant la résolution | G-CHG laisse tout passer : l'écran demandé se construit avant que la session soit connue, puis la redirection s'applique | `redirection.dart:34-35` | flash d'écran ; données protégées par RLS (DÉDUIT) |
| Refresh `/salle` | `extra` perdu → racine | `redirection.dart:93-96`, `billet_salle.dart:8-13` | conforme ADR-005 |
| Refresh `/tc/classe` | `extra` perdu → texte `_ClasseSansContexte`, **sans redirection ni bouton** ; le commentaire annonce une redirection jamais faite (**ÉCART**) | `routes_tc_e.dart:38-47, 51-66` | impasse |
| Refresh `/tuteur/foyer/appairer/:id` | `initState` redemande un code, le précédent est périmé | `appairage_page.dart:20-22, 43-46, 58-66` | effet de bord à chaque ouverture, lien direct compris |
| Refresh d'une route à paramètre (`:eleveId`, `:groupeId`, `:seanceId`, `:profilId`) | survit, identifiant dans le chemin | `routes.dart:75-76, 93-94` | conforme |
| Précédent / avance web | `go` crée l'entrée d'historique ; `context.push` ne met pas l'URL à jour (`GoRouter.optionURLReflectsImperativeAPIs = false`, jamais modifié dans `lib/`) | go_router `router.dart:354` ; `push` dans `compte_page.dart:59, 65, 72, 79, 181, 345, 390, 400, 615`, `reglages_enfant_page.dart:63-75` | refresh d'une sous-page de compte = page parente ; précédent navigateur saute la sous-page (DÉDUIT) |
| Retour système Android | routes atteintes par `go`, sans pile : sortie d'application | DÉDUIT | pas de retour stable |

---

## 5. `ecran_a_construire.dart`

- DOC (`ecran_a_construire.dart:7-14`) : feuille de route temporaire de l'étape 2, qui nomme la destination pour qu'un test de navigation dise où il a mené.
- CODE (`15-38`) : `Scaffold` + `AppBar(title: destination)` + `OfflineBanner` + `EmptyState(aConstruire.titre, aConstruire.detail)`, soit « Écran à construire » / « Cet écran arrive à l'étape 3. » (`fr.i18n.json`).
- Usages : **un seul**, la route `/` avec `destination: t.commun.chargement` (`app_router.dart:107-111`). Aucun test ne le référence (grep).
- Conséquence : l'écran de démarrage de tous les rôles est ce placeholder, visible le temps de résoudre la session. AppBar Material brut, texte de chantier, hors charte.
- Recommandation : remplacer à `/` par un écran de démarrage neutre (marque, progression, message de chargement prolongé après un seuil documenté), et **ne pas s'en servir comme placeholder d'écran tuteur** : le mandat §11.1 interdit un `TODO` maquillé. Une fonction sans service reçoit un écran honnête d'indisponibilité, pas « Écran à construire ». Supprimer la classe ensuite seulement sur accord.

---

## 6. Quatrième destination : Historique ou autre chose ?

Le directeur demande si « Historique » est la bonne quatrième destination. Candidats comparés :

| Candidat | Écran et service existants | Pour | Contre |
|---|---|---|---|
| **Historique** | `/tuteur/suivi` `SuiviFoyerPage` TUT-06 : cours passés, présence, filtre enfant (`suivi_foyer_page.dart:22-47, 146-150`) ; déjà branche 3 de la coquille (`app_router.dart:267-275`) | données réelles déjà lues ; complément observation §8 exige un Historique « Séances / Observations » ; maquettes desktop et mobile Compte l'affichent ; coût de routage minimal (renommer le libellé) | la distinction « Observations » demande un journal de visites (dépendance à confirmer) |
| Classe(s) | `/tc/groupes` et `/tc/groupes/:id` | accès direct au cours | **groupes de démonstration sur C0** (`CLAUDE.md:71-73`) ; contexte propre à l'élève sélectionné, déjà atteint par « Voir la classe » de l'Accueil ; doublerait le sélecteur d'élève |
| Notifications | aucune (ni table, ni service : grep `lib/` et `supabase/migrations`) | - | rien à afficher ; les maquettes la placent en cloche d'en-tête |
| Appareils | `/tuteur/foyer` actuel | - | sous-partie du Foyer |
| Paiements / accès | aucun écran finance | - | aucun service ; relève du Compte |

**Recommandation : garder Historique.** C'est le seul candidat qui mène à un écran réel adossé à des données réelles, et il ne coûte qu'un libellé. Ordre : Accueil · Foyer · Historique · Compte, partout. Retirer « Disponibilités » et « Réglages » de la barre : le premier relève du matching individuel remplacé (`docs/current/00_LIRE_D_ABORD.md:26`), le second migre dans la fiche élève du Foyer. Aucune icône nommée « historique » n'existe dans `AppIcons` (liste de `app_icons.dart:47-489`) : utiliser `AppIcons.suivi` ou ajouter une entrée horloge (fichier du coordinateur).

---

## 7. Mapping de l'arbre du mandat §4

Statuts : **EXISTE** (équivalent fonctionnel), **PARTIEL**, **ABSENTE**. Les recommandations respectent « un alias ou une redirection vaut mieux qu'une deuxième route concurrente ».

Contraintes de routage qui s'appliquent à toutes les lignes :

- **C1** : tout chemin tuteur authentifié doit rester sous `/tuteur` (G-PRE), sinon il est renvoyé à `/tuteur`. Un chemin racine `/appareils/...` serait inatteignable pour le tuteur.
- **C2** : `prefixePour(guardian)` renvoie `tuteurAccueil` (`routes.dart:361`). Changer la valeur de `Routes.tuteurAccueil` en `/tuteur/accueil` réduirait le préfixe de garde et refuserait `/tuteur/foyer` et tous les autres. Découpler d'abord (`guardian => '/tuteur'`).
- **C3** : un écran vu **sans session** (appareil de l'enfant, récupération d'accès) doit vivre dans un sous-arbre public (`/connexion/...`) ou exiger un amendement de G-PUB.
- **C4** : l'admission suit la porte : avant profil, seul `/inscription/...` passe ; dossier en attente, seul `/attente/...` ; compte actif, `/tuteur/...`. Un préfixe `/onboarding` serait redirigé dans les trois cas.
- **C5** : un segment dynamique (`:eleveId`, `:classeId`) doit être déclaré **après** les segments statiques frères (`ajouter`, `appareils`, `appairer`, `catalogue`), sinon il les capture.
- **C6** : pour garder la barre et l'état, une sous-page doit vivre **dans la branche** de sa destination (une `StatefulShellBranch` accepte plusieurs routes racines et des routes enfants).

| Route logique | Existant équivalent | Statut | Recommandation |
|---|---|---|---|
| `/bienvenue` | aucune ; `/` = `EcranAConstruire` pendant le chargement, déconnecté → `/connexion` | ABSENTE | Soit un premier état « Bienvenue » dans `/connexion` (aucun changement de garde), soit une route publique `/bienvenue` : amender G-PUB (`redirection.dart:39-49`) en câblant enfin `Routes.publiques` comme liste unique, rediriger le déconnecté vers `/bienvenue`, ajouter le test. |
| `/connexion` | `/connexion` `ConnexionPage` : lien magique, Google, mot de passe de démo, entrée appareil élève (`connexion_page.dart:29-37, 166-168`) | EXISTE | Conserver l'identifiant. |
| `/recuperation` | aucune ; connexion sans mot de passe (`connexion_page.dart:31-33`), état « lien envoyé » ; aucun traitement des erreurs de lien expiré | ABSENTE | Sous-route publique `/connexion/recuperation` (C3, sans changer la garde) ; `/recuperation` en alias seulement si la garde est amendée. |
| `/inscription` | `/inscription` `InscriptionPage`, 4 pages internes : rôle, identité, genre, récapitulatif (`inscription_page.dart:16-24, 119-124`) | EXISTE | Conserver ; les étapes internes n'ont pas d'URL. Des sous-routes `/inscription/<étape>` sont possibles sans toucher la garde (`redirection.dart:56`). |
| `/onboarding/usage` | page 1 de `/inscription`, `_ChoixRole` : tuteur, élève adulte, enseignant (`inscription_page.dart:38-41`) ; tuteur et élève adulte écrivent tous deux `guardian` | PARTIEL | Pas de préfixe `/onboarding` (C4) : `/inscription/usage` ou état interne. Les deux choix du directeur correspondent à `eleveAdulte` et `tuteur` ; l'inscription enseignant reste le 3e choix existant. |
| `/onboarding/...` (questionnaire) | identité et genre : pages 2-3 de `/inscription` ; élèves : `/tuteur/foyer/ajouter-enfant` (prénom, nom, âge 3 à 18, `ajouter_enfant_page.dart:42-53`) ; langue, objectif, niveau et choix d'horaire : `/tuteur/parcours/:eleveId` (`parcours_offres_page.dart:23-41`), qui dépend de la migration `0043` (`offres_compatibles`, `choisir_offre_horaire`, `0043:682, 769`) **non appliquée en production** (`08` §5 bis, ligne du 23/09) ; pièces et contrat : `/attente/{accuse,contrat,piece}` | PARTIEL, éclaté | Répartir par porte (C4) : pré-profil sous `/inscription/...`, dossier en attente sous `/attente/...`, compte actif sous `/tuteur/...`. Dépendance backend `0043`. À instruire par l'agent Admission. |
| `/onboarding/recapitulatif` | page 4 de `/inscription` (récapitulatif avant création) ; état du dossier et prochaine action : `/attente` | PARTIEL | Conserver ; le récapitulatif de dossier vit sous `/attente` pour un compte en attente. |
| `/tuteur/accueil` | `/tuteur` `AccueilFamillePage` TUT-01 (`app_router.dart:242-246`) | EXISTE | Conserver `/tuteur` ; alias `GoRoute('/tuteur/accueil', redirect: → /tuteur)`. Respecter C2. |
| `/tuteur/notifications` | aucune ; aucun service ni table (grep) ; admin : feuille vide statique (`admin_shell.dart:459-472`) | ABSENTE | Nouvelle route dans la branche Accueil (C6) avec état d'indisponibilité honnête ; dépendance backend. L'entrée « cloche » exige un emplacement d'actions d'en-tête dans `PageShell` (absent, `page_shell.dart:31-60`), fichier du coordinateur. |
| `/tuteur/foyer` | `/tuteur/foyer` rend `AppareilsPage` (enfants, appareils, révocation, ajout ; `appareils_page.dart:18-99`), hors coquille ; liste des membres aussi dans `/compte/profils` (`compte_page.dart:362-412`) | PARTIEL | **Conserver l'identifiant `/tuteur/foyer`** pour le nouvel écran Foyer, et en faire la **branche 1** de la coquille tuteur. Déplacer `AppareilsPage` sur `/tuteur/foyer/appareils`. Rediriger `/compte/profils` vers `/tuteur/foyer` pour le tuteur. « Créer mon profil élève » et « Ouvrir mon espace élève » : dépendance auth (§3.1-6). |
| `/tuteur/foyer/ajouter` | `/tuteur/foyer/ajouter-enfant` `AjouterEnfantPage` (enfant seulement, âge 3 à 18) | PARTIEL | Enfant de la branche Foyer. Soit conserver `ajouter-enfant` et poser l'alias `ajouter`, soit l'inverse avec redirection de l'ancien chemin ; les 5 appelants passent par la constante `Routes.tuteurAjouterEnfant`, donc un seul point à changer. « Pour moi » absent de l'écran et de `creerEnfant(age)` : dépendance métier. |
| `/tuteur/foyer/:eleveId` | `/compte/profils/:profilId` `ProfilEnfantPage`, lecture seule : identifiant, mode, caméra, fin d'accès, lien réglages (`compte_page.dart:415-460, 558-622`) ; carte par enfant de `/tuteur/reglages` | PARTIEL | Nouvelle route enfant de la branche Foyer, **après** les segments statiques (C5). Rediriger `/compte/profils/:id` vers `/tuteur/foyer/:id`. |
| `.../informations` | lecture seule dans `ProfilEnfantPage` ; photo dans la carte de `/tuteur/reglages` | PARTIEL | Nouvelle sous-route. |
| `.../inscription` | `/tuteur/parcours/:eleveId` `ParcoursOffresPage` (entrée `bloc_parcours.dart:149`) | PARTIEL (dépend de `0043`) | Alias `/tuteur/foyer/:eleveId/inscription` → `/tuteur/parcours/:eleveId`, identifiant du flux conservé. |
| `.../interface` | mode d'interface dans la carte enfant de `/tuteur/reglages` (`reglages_enfant_page.dart:26-38`) | PARTIEL | Nouvelle sous-route qui réutilise le réglage ; ensuite `/tuteur/reglages` → redirection `/tuteur/foyer`. |
| `.../camera` | politique caméra dans la même carte ; lecture dans `ProfilEnfantPage` (`compte_page.dart:596-602`) | PARTIEL | Nouvelle sous-route. |
| `.../acces` | `_BlocAcces` de l'accueil (`accueil_famille_page.dart:281-284`), ligne statut de `ProfilEnfantPage` (`compte_page.dart:603-609`) | PARTIEL | Nouvelle sous-route. |
| `.../appareils` | bloc de l'enfant dans `AppareilsPage` (`appareils_page.dart:71-88`) + `/tuteur/foyer/appairer/:eleveId` | PARTIEL | Nouvelle sous-route, ou `/tuteur/foyer/appareils?eleve=`. |
| `/tuteur/foyer/appareils` | `/tuteur/foyer` actuel (`AppareilsPage`) | EXISTE (à déplacer) | Nouveau chemin statique (C5) qui rend l'écran existant. |
| `/appareils/connexion` (émetteur) | `/tuteur/foyer/appairer/:eleveId` `AppairagePage` : QR `qr_flutter`, code, délai (`appairage_page.dart:17-23, 173`) | EXISTE (avec élève) | **Conserver l'identifiant** ou alias `/tuteur/foyer/:eleveId/appareils/connexion`. Jamais `/appareils/...` à la racine (C1). Refresh = nouveau code (§4). |
| `/appareils/scanner` | aucune ; aucune dépendance de lecture QR (`pubspec.yaml:52` : `qr_flutter` seulement ; `feuille_appareil_eleve.dart:17-19` : « aucun lecteur de code n'existe ») | ABSENTE | Sens du protocole existant : l'appareil du **tuteur affiche**, l'appareil de **l'enfant saisit** sans session (`eleve_connexion_page.dart:115-128`). Le scanner vit donc côté enfant et doit être public (C3) : `/connexion/eleve/scanner`. Dépendance ajoutée par le coordinateur. |
| `/appareils/code` | `/connexion/eleve`, moment `saisieCode` (`eleve_connexion_page.dart:30-31, 111`) | EXISTE (état interne) | Conserver `/connexion/eleve` ; sous-route `/connexion/eleve/code` possible sans changer la garde. |
| `/appareil/profils` | `/connexion/eleve`, moment `choixProfil`, profils locaux (`33-34, 162-177`) | EXISTE (état interne) | Conserver l'état interne. Un appareil qui porte une session tuteur active ne peut pas ouvrir `/connexion/eleve` (`redirection.dart:81-87`) : l'appareil partagé suppose la déconnexion du tuteur, à confirmer par l'agent Appareils. |
| `/appareil/pin` | `/connexion/eleve`, moments `creationCode` et `saisieCodePersonnel` ; comparaison **locale** puis `ouvrirSession(jeton)` (`179-262`) | EXISTE (état interne) | Pas d'URL pour le PIN : un refresh revient au choix de profil, ce qui est sûr. |
| `/tuteur/classes/catalogue` | aucune ; le plus proche, `/tuteur/parcours/:eleveId`, ne montre que des « horaires vitrines » sans enseignant, places ni groupe (`parcours_offres_page.dart:34-36, 580-587`) | ABSENTE | Nouvelle route statique déclarée avant `:classeId` (C5), élève concerné en paramètre (`?eleve=`). Dépendance backend : catalogue de classes réelles avec places (non trouvé ; `0043` = offres vitrines, non appliquée). |
| `/tuteur/classes/:classeId` | `/tc/groupes/:groupeId` `EspaceGroupePage` (`routes_tc_a.dart:38-50`), autorisé au tuteur ; **groupes de démonstration sur C0** (`CLAUDE.md:71-73`), données réelles seulement sur `v0/verite-produit` (suspendu) | PARTIEL | Alias `/tuteur/classes/:classeId` → `/tc/groupes/:classeId`, ou route tuteur qui rend `EspaceGroupePage(role: tuteur)` explicitement (corrige §3.3-5). Porter l'élève concerné (`?eleve=`) : un groupe peut réunir plusieurs enfants du foyer. Masquer « Rejoindre » pour le tuteur (§3.3-4). |
| `.../planning` | Session Card = prochaine occurrence seulement (`carte_session.dart:15-28`) | ABSENTE | Nouvelle sous-route ; dépendance : occurrences datées, à confirmer par l'agent Cours. |
| `.../travail` | emplacement « Avant le prochain cours » (`emplacements_groupe.dart:38-50`), port de l'agent H non branché depuis `main` (`CLAUDE.md:65-68`) | PARTIEL | Nouvelle sous-route. |
| `.../ressources` | `/tc/bibliotheque?groupe=<id>` + `/tc/bibliotheque/:resourceId` (`routes_tc_b.dart:63-66, 78-94`) | EXISTE | Conserver ; alias `/tuteur/classes/:id/ressources` → `RoutesTcB.avecGroupe(id)`. Écart de sécurité documenté : `ressources_du_groupe` ne filtre pas `access_policy` (`routes_tc_b.dart:54-62`). |
| `.../progression` | emplacement `BlocProgression` (`emplacements_groupe.dart:182-200`) | PARTIEL | Nouvelle sous-route ; dépendance données. |
| `.../observer` | `/tc/observation/:seanceId` `EntreeObservationPage`, RPC `entrer_observation` présente (`0033_tc_vues_rpc.sql:1086`, `0037:56`) ; orpheline sur C0, « Assister » mène à `/salle` (`accueil_famille_page.dart:180-197`) | EXISTE, non raccordée | Conserver `/tc/observation/:seanceId` ; alias `/tuteur/classes/:classeId/observer` qui résout la séance en cours puis redirige. La clé est `seanceId`, pas `classeId`. Ajouter la sortie « Retour à la classe » (absente, `entree_observation_page.dart:182-196`). Quotas : lot Observation. |
| `/tuteur/historique` | `/tuteur/suivi` `SuiviFoyerPage` TUT-06 | EXISTE | Conserver l'identifiant `/tuteur/suivi` (branche 3, tests existants) avec le libellé « Historique », et poser l'alias `/tuteur/historique` → `/tuteur/suivi` ; ou l'inverse, l'ancien chemin devenant une redirection. Onglets « Séances / Observations » via `SousNavigationDomaine`. |
| `/tuteur/seances/:seanceId` | aucune ; `SuiviFoyerPage` n'a « aucune action » (`suivi_foyer_page.dart:42-46`) | ABSENTE | Nouvelle route, 2e route racine de la branche Historique (C6). |
| `/tuteur/compte` | `/compte` `ComptePage`, commun à tous les rôles (G-CPT) | EXISTE (hors coquille tuteur) | Recommandé : branche 4 `/tuteur/compte` qui rend `ComptePage`, avec redirection `/compte*` → `/tuteur/compte*` pour le seul tuteur ; `/compte` reste pour les autres rôles. Variante minimale : garder `/compte`, faire `go` dans `_CoquilleNavigation.onAller` pour une destination sans branche et calculer l'index actif dans `_CoquilleSecondaire`, au prix de la perte d'état des branches. |
| `.../informations` | `/compte/profil` `ProfilPersonnelPage`, lecture seule : identifiant UUID, contact et fuseau « non disponible » (`compte_page.dart:117-187`) | PARTIEL | Alias vers l'écran existant. |
| `.../securite` | seulement la ligne « Se déconnecter » (`compte_page.dart:103-109`) ; aucun mot de passe en production (`connexion_page.dart:31-32`) | ABSENTE | Nouvelle sous-route. La maquette « Email et mot de passe » est fausse pour la production (lien magique + Google). |
| `.../acces` | fin d'accès par enfant seulement (accueil, `ProfilEnfantPage`) | ABSENTE | Nouvelle sous-route ; dépendance. |
| `.../paiements` | aucun écran finance (`/comptable` rend `ComptePage`, `app_router.dart:585-588`) | ABSENTE | Nouvelle sous-route, état indisponible ; dépendance. |
| `.../preferences` | `/compte/reglages` `ReglagesComptePage` : thème, animations, effets, langue, fuseau, notifications locales, données (`compte_page.dart:190-359`) | EXISTE | Alias. **ÉCART** : le thème choisi n'est lu par personne (grep `preferencesLocalesProvider` : `compte_page.dart` seulement) et `app.dart:50` reste en `ThemeMode.system`. La bascule clair/sombre des maquettes desktop est donc aujourd'hui sans effet. |
| `.../aide` | aucune | ABSENTE | Nouvelle sous-route. |
| `.../informations-legales` | ligne « Confidentialité » désactivée (`compte_page.dart:83-88, 349-354`) | ABSENTE | Nouvelle sous-route. |
| Fallback (404, accès refusé, session expirée, ressource indisponible) | écran par défaut go_router, redirections silencieuses (§4) | ABSENTE | `errorBuilder` (ou `onException`) dans `app_router.dart` rendant l'écran d'état commun : 404 avec retour à l'accueil si session, sinon connexion. Accès refusé : garder la redirection (aucune fuite) avec une notice, ou une route dédiée. Session expirée : paramètre `retour` validé (§9). |

Routes existantes du tuteur sans ligne dans l'arbre du mandat :

- `/tuteur/disponibilites` (TUT-04, « matching inverse », `disponibilites_page.dart:14-18`) : retirer de la barre, garder la route (préserver l'existant) en 2e route de la branche Foyer. À arbitrer : les disponibilités ne servent plus à l'affectation (`00`, contradictions résolues).
- `/tuteur/reglages` (TUT-05) : absorbé par la fiche élève, puis redirection.
- `/tuteur/parcours/:eleveId` : conservé comme flux d'inscription par élève.
- `/salle` : l'« Assister » du tuteur y mène sur C0 ; la cible du mandat est l'observation bornée (`/tc/observation`).

---

## 8. Routes et paramètres sensibles dans l'URL

| Chemin | Donnée dans l'URL | Nature | Constat |
|---|---|---|---|
| `/agent?jeton=rag_...` | **jeton d'observation d'agent IA** en paramètre de requête | secret porteur | `routes.dart:260-263`, `amorce_agent.dart:19-29`, lien construit sur `Uri.base` (`agent_entree_page.dart:91-93`). Seule route à secret dans l'URL. Hors périmètre tuteur, mais **modèle à ne pas reproduire** pour l'appairage : historique du navigateur, en-tête `Referer`, journaux d'accès. |
| `/tuteur/foyer/appairer/:eleveId` | UUID de l'élève | identifiant | Non secret, protégé par RLS ; le **code d'appairage** reste en mémoire d'écran (`appairage_page.dart:20-23, 36`) et dans le QR, jamais dans l'URL (bon). Chaque ouverture **émet un nouveau code** (§4). |
| `/tuteur/parcours/:eleveId`, `/compte/profils/:profilId` | UUID de l'élève | identifiant | RLS ; `ProfilEnfantPage` filtre la liste du foyer côté client (`compte_page.dart:439-446`) : aucune lecture par identifiant arbitraire. |
| `/tc/groupes/:groupeId`, `/tc/bibliotheque?groupe=`, `/tc/bibliotheque/:resourceId` | UUID de groupe ou de ressource | identifiant | RLS ; `ressources_du_groupe` en `security definer` ne filtre pas `access_policy` (`routes_tc_b.dart:54-62`), écart serveur connu. |
| `/tc/observation/:seanceId`, `/enseignant/seance/:seanceId/cahier` | UUID de séance | identifiant | L'entrée est vérifiée côté serveur par `entrer_observation` (lien, quota, politique : `entree_observation_page.dart:26-39`). |
| `/salle`, `/tc/classe` | rien : billet et contexte passent par `extra` | - | Conforme ADR-005 (`billet_salle.dart:5-17`, `routes_tc_e.dart:26-30`). |
| `/connexion/eleve` | rien : code d'appairage, jeton appareil et PIN restent hors URL (coffre sécurisé, comparaison locale) | - | Conforme (`eleve_connexion_page.dart:130-135, 222-228`). |
| Retour du lien magique ou de Google | paramètres d'auth ajoutés par Supabase à `Uri.base.origin` | jeton ou code d'auth | Traités par le SDK, pas par une route (`service_auth.dart:48-64`) ; aucune gestion côté route des erreurs de lien expiré. |

Règles à tenir pour les nouvelles routes : aucune route `/appareils/...` ne doit porter le code ou un jeton ; un QR ne doit contenir que le code attendu (le QR actuel encode le code brut, `appairage_page.dart:110, 173`), jamais une URL à ouvrir ; un paramètre `retour` éventuel doit être un chemin interne validé (pas d'URL absolue, pas `/salle`, `/tc/classe` ni `/agent`).

---

## 9. Écarts code / commentaires / docs à consigner

1. `app_router.dart:87-90` : « une reconnexion recrée ce provider ». Faux : `ref.read` + `ref.listen`, jamais reconstruit ; rôle d'Espace Groupe figé à `eleve` (§3.3-5).
2. `nav_shell.dart:269-274` : les entrées secondaires sous 600 « se rejoignent par les tuiles Outils du tableau de bord ». Aucune tuile Compte côté tuteur : pas de déconnexion mobile (§3.3-1).
3. `routes_tc_e.dart:42-45` : « Agent Z branchera la redirection vers la racine du rôle ». Non fait : `/tc/classe` sans contexte affiche un texte sans issue.
4. `routes_tc_g.dart:31-36` : « l'entrée du tuteur se greffe sur `accueil_famille_page.dart` ». Pas sur C0 (« Assister » → `/salle`) ; fait sur `observation/lot-2026-09-21`.
5. `routes.dart:67` « Foyer et appareils », titre d'écran « Appareils », libellé « Foyer » dans Mon compte (§2.6).
6. `routes.dart:341-345` `Routes.publiques` : déclaré « routes atteignables sans session », jamais lu.
7. `docs/current/01_PRODUIT_ET_PARCOURS.md:30` : observation « une visite, 120 secondes cumulées » ; le complément du mandat la remplace (2 visites de 120 s, 240 s au total). Hors routeur, signalé pour le lot Observation.
8. Brief : « la maquette mobile montre 3 onglets ». Seule la maquette d'accueil mobile en montre 3 ; celle de Mon compte mobile en montre 4 (§3.4).
9. `app.dart:19-24` : « aucune bascule manuelle n'existe encore » ; il en existe une dans `/compte/reglages`, mais elle n'est pas lue (§7, preferences).

---

## 10. Recommandations au coordinateur (propriétaire du routeur et du shell)

Ordre proposé, fichiers partagés seulement :

1. **Coquille tuteur à 4 branches** dans `app_router.dart:236-277` : Accueil `/tuteur` ; Foyer `/tuteur/foyer` (déplacé depuis `278-285`, sous-routes `ajouter`, `appareils`, `appairer/:eleveId`, puis `:eleveId/...`, plus `/tuteur/parcours/:eleveId` et `/tuteur/disponibilites` en routes racines de la branche) ; Historique `/tuteur/suivi` (+ `/tuteur/seances/:seanceId`) ; Compte `/tuteur/compte` (+ 7 sous-routes). `destinationsPour(guardian)` (`nav_shell.dart:79-100`) : Accueil (`AppIcons.accueil`), Foyer (`AppIcons.foyer`), Historique, Compte ; `secondairesPour(guardian)` vidé (`162-168`), sinon Compte apparaît deux fois. Chaque destination doit correspondre à une branche (§3.3-6).
2. **Alias** : `/tuteur/accueil`, `/tuteur/historique`, `/tuteur/foyer/ajouter`, `/tuteur/foyer/:id/inscription`, `/tuteur/classes/...`, et redirections `/compte*` → `/tuteur/compte*` et `/compte/profils*` → `/tuteur/foyer*` pour le tuteur (dans `deciderRedirection` ou par `redirect` de route). Respecter C2 et C5.
3. **Shell conforme aux maquettes** : marque « Rewayah » en tête du tiroir, Compte en pied (ordre inchangé), bouton replier/déplier en option (nouvel état d'interface), barre basse flottante arrondie, emplacement d'actions d'en-tête dans `PageShell` (cloche, bascule de thème), et branchement de la préférence de thème dans `app.dart`. Tous ces fichiers sont partagés avec les autres rôles : vérifier élève, enseignant, contrôleur et admin après changement.
4. **États globaux** : `errorBuilder` localisé ; écran de démarrage à la place d'`EcranAConstruire` avec message de chargement prolongé ; paramètre `retour` sur la redirection vers `/connexion` (chemin interne validé, liste d'exclusion `/salle`, `/tc/classe`, `/agent`), repris à l'arrivée en porte `actif`. Limite : le lien magique et Google reviennent sur l'origine, donc le `retour` doit survivre au trajet, par un paramètre de `emailRedirectTo` autorisé côté Supabase (configuration serveur) ou par un stockage de session local non sensible.
5. **Web** : décider la stratégie d'URL (hash actuel ou `usePathUrlStrategy` ; `vercel.json` réécrit déjà tout vers `index.html`), et remplacer les `context.push` des pages de compte par des routes de branche ou par `go`, pour que refresh et précédent soient cohérents.
6. **Corrections de câblage signalées** : rôle d'Espace Groupe relu depuis la session ; « Rejoindre » masqué pour le tuteur ; sortie « Retour à la classe » dans l'observation ; `/tc/classe` sans contexte redirigé ; `Routes.publiques` câblé ou supprimé.
7. **Tests à mettre à jour** (preuve locale après changement, jamais un PASS supposé) : `test/router/navigation_test.dart:24-29` (fige Accueil, Disponibilités, Réglages, Suivi) ; `test/router/redirection_test.dart:29-59` (liste des routes protégées) et `127-136, 159` ; galerie `lib/features/_dev/galerie/catalogue_galerie.dart:200-210`. À ajouter : destination Compte tapée par l'élève et par le tuteur, alias, 404, retour après connexion, ordre des segments statiques et dynamiques.

Points à trancher par le directeur (produit, pas code) : réseau coupé au démarrage (portail d'attente ou état hors ligne) ; sort de Disponibilités ; route publique `/bienvenue` ou état de `/connexion` ; « Ouvrir mon espace élève » pour un parent (un seul rôle par session) ; Compte en pied de sidebar ou en ligne (les deux maquettes desktop divergent).
