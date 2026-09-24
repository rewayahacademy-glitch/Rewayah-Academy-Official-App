# R4 - Ce qui a été annoncé contre ce que l'utilisateur peut atteindre (hors tuteur)

Relevé en **lecture seule** le 24/09/2026 (+03:00). Référence mesurée : **`main` = `origin/main` = `4a7aa2b`** (22/09 09:02, `git rev-parse main origin/main`). Le checkout principal est sur `c0/configuration-baseline-2026-09-23` @ `5113656` : il n'a pas été touché (aucun checkout, commit, stash, fetch, worktree). Le code de `main` a été lu par `git show`, `git grep`, `git log`, `git blame`, et par une copie `git archive 4a7aa2b lib test assets/i18n pubspec.yaml` extraite dans le scratchpad de la session (hors dépôt). `D:\RA_TUTEUR` n'a pas été lu. Le rôle tuteur n'est pas refait ici : voir `02_code\00_MAPPING_ROUTES.md`.

Seules écritures : ce rapport, et un petit script de preuve (§5.2) dans le scratchpad de la session, hors de tout dépôt.

## Légende

| Classe | Définition appliquée |
|---|---|
| **Atteignable** | route déclarée sur `main` **et** au moins un appel de navigation dans `lib/` (onglet, bouton, lien, menu, racine du rôle) **et** la garde `redirection.dart` laisse passer le rôle. Atteignable ne veut **pas** dire « fonctionne » : la dernière colonne dit ce qu'on voit. |
| **Route sans entrée** | route déclarée, mais aucun appel de navigation de `lib/` n'y mène pour le rôle visé, ou la garde refuse le seul rôle qui a l'entrée. On ne l'atteint qu'en tapant l'URL (web) ou par un test qui appelle `routeur.go(...)`. |
| **Code sans route** | code présent sur `main` mais monté par aucun écran atteignable : fichier non relié à `lib/main.dart` (liste R1), ou classe jamais instanciée, ou paramètre jamais passé. |
| **Absent de main** | n'existe pas sur `main` (seulement sur une branche non fusionnée, ou nulle part). |

Statut de preuve : **constaté** (commande rejouée ici, citée) ; **prétendu** (écrit dans un document ou un commentaire, non revérifié) ; **INCONNU**.

---

## 0. En clair, pour le directeur

1. **55 fonctions ou écrans annoncés comme livrés** ont été confrontés au code de `main` (hors tuteur). **31 sont atteignables** par l'utilisateur, dont 17 écrans d'administration. **8 ont une route mais aucun bouton ni lien qui y mène. 10 sont du code qu'aucun écran ne monte. 6 n'existent pas sur `main`.** Hors administration : 38 éléments, dont **14 seulement** sont atteignables.
2. **Comment « c'est fait » a pu être dit sans être vrai** : les écrans étaient déclarés dans le routeur et un test les « visitait » en appelant le routeur directement (`routeur.go(chemin)`, `test/router/parcours_enseignant_test.dart:148-159`), jamais en touchant un bouton. Exemple : la Bienvenue enseignant (`ENS-01`) est annoncée « écran neuf, routé » (`TEACHER_INTEGRATION_REPORT.md:40`) ; aucun bouton de l'application n'y mène.
3. **Tout le « Teaching Core »** (groupes, classe en direct, bibliothèque, porte d'observation, outils de l'enseignant) n'a, sur `main`, **qu'une seule entrée** : la ligne « Mes groupes » de l'accueil du **tuteur**, qui affiche des **groupes de démonstration**. L'élève, l'enseignant et l'administration n'ont aucune entrée vers `/tc/...` ; l'enseignant y est même refusé par la garde.
4. **La page du Coran que l'enseignant « présente » à sa classe n'est affichée que chez l'enseignant.** Aucun écran élève ne la reçoit.
5. **Le Coran qui « se lit en marche arrière et du bas vers le haut » : cause trouvée et prouvée.** La lecture des versets d'une page demande un tri **décroissant** sans le vouloir (la bibliothèque `postgrest` 2.9.1 trie à l'envers quand on n'écrit pas `ascending: true`). La page commence donc par son **dernier** verset en haut et finit par le **premier** en bas. Constat simple à faire : à la page 1, le premier verset (la basmala) devrait être **en bas**. Le défaut est présent depuis le 13/09 (`090ae6f`), dans le lecteur de l'élève **et** dans le panneau de l'enseignant en salle. Le piège était connu et corrigé ailleurs dans le même dépôt (`service_matching.dart:199-205`). Aucun test ne lit la vraie requête. **Rien n'a été corrigé.**

---

## 1. Méthode et preuves

| Étape | Commande | Résultat constaté |
|---|---|---|
| Référence | `git -C "D:\RA _APP\RA -OFFICIAL-APP" rev-parse HEAD main origin/main` | HEAD `5113656` (C0), `main` = `origin/main` = `4a7aa2b` |
| Routes | lecture de `main:lib/core/router/{routes,app_router,redirection}.dart` et des 5 fichiers `routes_tc_{a,b,c,e,g}.dart` | table §2 |
| Entrées de navigation | `git grep -n -E "Routes\.[a-zA-Z]+\|Chemins[A-Za-z]*\.\|RoutesTc[A-Z]\.\|RoutesCoran\." 4a7aa2b -- lib` (hors routeur) ; `git grep -n -E "MaterialPageRoute\|Navigator\.(of\|push)" 4a7aa2b -- lib` | aucune navigation par `Navigator.push` d'écran (seulement des `pop`) ; aucune URL littérale dans un `go`/`push` |
| Classes d'écran | `git grep -n -E "^class [A-Z][A-Za-z]*(Page\|Ecran\|Screen)\b" 4a7aa2b -- lib` | 58 classes ; seule `PresenceCorrectionPage` n'est ni routée ni instanciée |
| Code non relié | rapport `06_registre\R1_fichiers_non_atteignables.md` (45 fichiers, graphe d'imports) | repris, non recalculé |
| Annonces | lecture de `docs/archive/2026-09-pre-remise-a-plat/` : `PROGRESS.md`, `AGENT_HANDOFF.md`, `HANDOFF.md` (en-tête, §10, §12.10), `parallel-reports/AGENT_{A..E}_REPORT.md`, `SOCLE_{SALLE,CATALOGUE}_REPORT.md`, `teaching-core/TC_AGENT_{A,C,E,G,Q}_REPORT.md` (B, D, F, H par recherche ciblée et via R1), `design/08-catalogue-ecrans.md` (registre §1, invariants), `architecture/TEACHER_{INTEGRATION,PREMERGE}_REPORT.md` | tableaux §3 |
| Commits | `git log main --format="%h\|%ad\|%s"` (193 commits) ; `git log --all --not main --source` (101 commits hors `main`) ; `git show --stat` des commits de câblage | tableaux §3 et §3.7 |
| Coran | lecture de la chaîne de rendu, `git blame`, lecture de la bibliothèque verrouillée, script d'exécution hors dépôt | §5 |

---

## 2. Ce que `main` expose réellement (hors tuteur)

`app_router.dart` et `redirection.dart` sur `main` @ `4a7aa2b`.

| Route | Déclarée | Rôles admis par la garde | Entrées de navigation dans `lib/` |
|---|---|---|---|
| `/` | `app_router.dart:107-111` (`EcranAConstruire`) | tous (redirigé) | - |
| `/connexion`, `/connexion/eleve` | `:112-120` | public | `connexion_page.dart:168` |
| `/inscription` | `:121-124` | porte inscription (`redirection.dart:55-58`) | redirection |
| `/agent` | `:128-131` | public (`redirection.dart:44-46`) | lien fabriqué par `acces_agents_page.dart:549` (`Routes.entreePour`) |
| `/attente` et 3 pages | `:134-149` | porte attente (`redirection.dart:64-68`) | `attente_page.dart:140-150, 201` |
| `/compte` et 4 sous-pages | `:159-186` | tout rôle actif (`redirection.dart:100-102`) | élève `nav_shell.dart:73-77` ; enseignant `profil_enseignant_page.dart:597, 603` ; contrôleur `planning_page.dart:172` ; admin `app_router.dart:756, 860` |
| `/eleve` | `:199-203` | élève | racine du rôle (`routes.dart:349`) ; `nav_shell.dart:58-62` |
| `/eleve/coran` | `:208-216` (rend `MushafPage`) | élève | `nav_shell.dart:63-67` ; `accueil_eleve_page.dart:566` |
| `/eleve/suivi` | `:221-225` | élève | `nav_shell.dart:68-72` **seulement** (0 destination en interface guidée, `nav_shell.dart:55-56`) |
| `/enseignant/journee`, `/creneaux`, `/profil` | `:307-311`, `:316-320`, `:325-329` | enseignant | `nav_shell.dart:108-124` |
| `/enseignant/bienvenue` | `:347-351` | enseignant | **aucune** |
| `/enseignant/seance/:id/cahier` | `:352-356` | enseignant | `journee_page.dart:718` ; `salle_page.dart:215-222` |
| `/enseignant/groupe/:id` | `:357-361` | enseignant | `journee_page.dart:487` |
| `/enseignant/groupe/:id/revue` | `:362-366` | enseignant | `fiche_groupe_page.dart:156` |
| `/controleur` | `:371-375` | contrôleur | racine du rôle (`routes.dart:352`) |
| `/admin/**` (16 pages, 5 redirections de domaine, 7 anciennes routes redirigées) | `:385-582` | admin | barre latérale `admin_shell.dart:107-116` via `admin_domaine.dart:92-100` ; sous-navigation `SousNavigationDomaine` (8 pages) ; `tableau_de_bord_page.dart:69, 87, 225, 233, 262, 267, 272, 282` |
| `/comptable` | `:585-588` (rend `ComptePage`) | comptable | racine du rôle |
| `/tc/groupes`, `/tc/groupes/:id` | `routes_tc_a.dart:32-54` (monté `app_router.dart:596`) | élève, tuteur (`redirection.dart:134-137`) | `accueil_famille_page.dart:463-468` (**tuteur seulement**) ; `mes_groupes_page.dart:183` (interne) |
| `/tc/bibliotheque`, `/:resourceId` | `routes_tc_b.dart:78-94` | élève, tuteur | `espace_groupe_page.dart:262` (depuis l'Espace Groupe) ; `bibliotheque_page.dart:46` (interne) |
| `/tc/mushaf` | `routes_tc_c.dart:24-29` | élève (`redirection.dart:141-143`) | **aucune** |
| `/tc/classe` | `routes_tc_e.dart:34-49` | enseignant, élève (`redirection.dart:138-140`) | `routes_tc_a.dart:63-83` seulement (bouton « Rejoindre » de l'Espace Groupe) |
| `/tc/observation/:seanceId` | `routes_tc_g.dart:37-45` | tuteur, admin, contrôleur (`redirection.dart:144-148`) | **aucune** (`RoutesTcG.versObservation` sans appelant ; `entete_classe.dart:196-199` le dit) |
| `/salle` | `app_router.dart:609-616` | tout rôle muni d'un billet valide (`redirection.dart:93-96`) | élève `accueil_eleve_page.dart:394-405` ; enseignant `journee_page.dart:536` ; tuteur `accueil_famille_page.dart:192` ; contrôleur `planning_page.dart:133-138` ; **admin : aucune** |

Aucune route n'a d'`errorBuilder` (`app_router.dart:95-632`).

---

## 3. Registre : annoncé comme livré, et ce que `main` en rend atteignable

Chaque élément n'est compté qu'une fois, dans la section où il est rangé.

### 3.1 Élève (7)

| # | Fonction ou écran | Annoncé où | Route | Entrée | Classe | Ce que l'élève voit |
|---|---|---|---|---|---|---|
| 1 | `ELV-02` Accueil élève | `08-catalogue-ecrans.md:50` « repris (R1) » | `app_router.dart:199-203` | racine ; `nav_shell.dart:58-62` | **Atteignable** | - |
| 3 | Suivi élève | `PROGRESS.md:21-32` « vient de rejoindre les écrans réels » | `app_router.dart:221-225` | `nav_shell.dart:68-72` seulement | **Atteignable en mode standard** ; en interface guidée, **route sans entrée** (`nav_shell.dart:55-56` rend 0 destination ; `git grep Routes.eleveSuivi` : aucun autre appelant) | - |
| 6 | Mes groupes, Espace Groupe | `TC_AGENT_A_REPORT.md` §1.3 ; commit `0007ff9` « câble les routes Teaching Core » | `routes_tc_a.dart:32-54` | aucune pour l'élève (seule entrée : `accueil_famille_page.dart:463-468`, tuteur) | **Route sans entrée** | données de démonstration servies en production (`port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55`) |
| 7 | Bibliothèque | `TC_AGENT_B_REPORT.md` ; `e78b6e1` « câble "Voir tout" de la Bibliothèque » | `routes_tc_b.dart:78-94` | `espace_groupe_page.dart:262`, dans un écran sans entrée pour l'élève | **Route sans entrée** | toujours vide : `portCatalogueProvider` = `CatalogueLocal()` (`donnees_catalogue.dart:29-34`) |
| 11 | Indicateur discret « on t'observe » côté enfant | `TC_AGENT_G_REPORT.md` §1 et §8.8 | - | `IndicateurObservationEnfant` défini (`indicateur_observation.dart:133`), **jamais instancié** (`git grep "IndicateurObservationEnfant("` : la définition seule) | **Code sans route** | - |
| 13 | Bloc « Avant le prochain cours » | `535947d` « flux académique - travail à venir… » | - | non relié à `main.dart` (R1 n° 42) ; l'emplacement affiche « Bientôt disponible » (`portTravailAVenirProvider` = `null`, `port_travail_a_venir.dart:154-155`) | **Code sans route** | - |
| 14 | Micro-avis de fin de séance | `535947d` | - | R1 n° 43 | **Code sans route** | - |

### 3.2 Enseignant (11)

| # | Fonction ou écran | Annoncé où | Route | Entrée | Classe | Ce que l'enseignant voit |
|---|---|---|---|---|---|---|
| 15 | `ENS-02` Journée | `TEACHER_INTEGRATION_REPORT.md:41` ; `0071557` « le rôle Enseignant complet, huit écrans » | `app_router.dart:307-311` | racine ; `nav_shell.dart:109-113` | **Atteignable** | - |
| 16 | `ENS-06` Créneaux | `:45` | `:316-320` | `nav_shell.dart:114-118` ; `journee_page.dart:360, 371` ; `bienvenue_page.dart:224` | **Atteignable** | modèle 1-à-1 abandonné par les specs actives (`CLAUDE.md` « État du code ») |
| 17 | `ENS-05` Profil (et déconnexion) | `:44` | `:325-329` | `nav_shell.dart:119-123` | **Atteignable** | - |
| 18 | `ENS-07` Fiche groupe | `:46` | `:357-361` | `journee_page.dart:487` (si la séance porte un groupe) | **Atteignable** | - |
| 19 | `ENS-08` Revue de groupe | `:47` « livré vide » | `:362-366` | `fiche_groupe_page.dart:156` | **Atteignable** | vide par construction (`AGENT_C_REPORT.md` §6, prétendu) |
| 20 | `ENS-04` Cahier de transmission | `:43` | `:352-356` | `journee_page.dart:718` ; sortie de salle `salle_page.dart:215-222` | **Atteignable** | - |
| 22 | `ENS-01` Bienvenue | `TEACHER_INTEGRATION_REPORT.md:40` « écran neuf, **routé** » | `app_router.dart:347-351` | **aucune** : `git grep enseignantBienvenue 4a7aa2b -- lib` ne trouve que `routes.dart:133` et `app_router.dart:348` ; la racine enseignant est la Journée (`routes.dart:351`) | **Route sans entrée** | l'agent auteur l'avait écrit (« rien ne mène à elle », `AGENT_E_REPORT.md:149-152, 367-368`) ; le test « de bout en bout » ne l'atteint que par `routeur.go` (`parcours_enseignant_test.dart:143-159`) |
| 25 | Roster pédagogique de l'Espace Groupe | `f2dfd64` « câble le slot roster de l'Espace Groupe » | `routes_tc_a.dart:43-50` | `/tc/groupes` est **refusé à l'enseignant** : `redirection.dart:134-137` puis `:114-115` le renvoie à `/enseignant/journee` | **Route sans entrée** (refusée au seul rôle visé) | hors séance, « indisponible » par construction (`roster_enseignant_slot.dart:14-25`) |
| 26 | Teaching Dock : annoter, marquer, masquer pour réciter, pointer | `TC_AGENT_D` ; `151bd41` ; fusion `68d277c` | - | 15 fichiers non reliés (R1 §3-§4) | **Code sans route** | `PortAnnotations` lève `UnimplementedError` (R1, `port_annotations.dart:211-217`) |
| 28 | Après-cours prérempli, signalement vers l'administration | `TC_AGENT_H` ; `535947d` | - | R1 §3 (lot H, 11 fichiers) | **Code sans route** | fournisseurs en `UnimplementedError` (R1) |
| 30 | Surface « propriétaire » de correction de présence | `f84580b` « add owner presence correction surface », intégrée par `cb3a220` | aucune | `PresenceCorrectionPage` jamais instanciée ; son propre en-tête le dit (`presence_correction_page.dart:17-21`). Le **panneau** est monté dans le cahier (`cahier_page.dart:574`) | **Code sans route** (la page) ; panneau atteignable via `ENS-04` | écriture serveur non livrée (`AGENT_C_REPORT.md` §9.3, prétendu) |

### 3.3 Administration (17)

Annonces : `PROGRESS.md:21` (« L'espace admin n'a plus un seul écran manquant »), `HANDOFF.md:3-150` (19/09), `08-catalogue-ecrans.md:72-87`, commits `b3be532`, `e3faea8`, `6a323b5`, `96efc5f`.

| # | Écran | Route | Entrée | Classe |
|---|---|---|---|---|
| 31 | `ADM-01` Centre de commande | `app_router.dart:385-391` | racine (`routes.dart:353`) ; barre latérale (`admin_domaine.dart:93`) | **Atteignable** |
| 32 | `ADM-09` Groupes | `:403-409` | barre latérale Opérations (`admin_domaine.dart:94`, redirection `:398-402`) | **Atteignable** |
| 33 | `ADM-05` Attribution | `:410-416` | `tableau_de_bord_page.dart:272` | **Atteignable** |
| 34 | `ADM-06` Demandes | `:420-426` | `tableau_de_bord_page.dart:87, 267` | **Atteignable** |
| 35 | `ADM-02` Dossiers | `:432-438` | barre latérale Personnes (`admin_domaine.dart:95`, `:427-431`) ; `tableau_de_bord_page.dart:69, 262` | **Atteignable** |
| 36 | `ADM-08` Comptes | `:444-450` | `tableau_de_bord_page.dart:225` | **Atteignable** |
| 37-41 | `ADM-10` à `ADM-14` Pédagogie (5) | `:461-495` | barre latérale Pédagogie (`admin_domaine.dart:96`) ; `SousNavigationDomaine` dans les 5 pages (`diagnostics_page.dart:94`, `progression_page.dart:50`, `evaluations_page.dart:51`, `programmes_page.dart:58`, `qualite_page.dart:55`) ; `ADM-14` aussi `tableau_de_bord_page.dart:282` | **Atteignables** |
| 42-44 | `ADM-15` à `ADM-17` Configuration (3) | `:505-525` | barre latérale (`admin_domaine.dart:97`) ; `SousNavigationDomaine` (`regles_page.dart:40-41`, `fonctionnalites_page.dart:36-37`, `conservation_donnees_page.dart:37-38`) | **Atteignables** |
| 45 | `ADM-04` Journal d'audit | `:531-537` | barre latérale Sécurité (`admin_domaine.dart:98`, `:526-530`) | **Atteignable** |
| 46 | `ADM-07` Accès des agents IA | `:539-545` | `tableau_de_bord_page.dart:233` | **Atteignable** |
| 47 | Réglage de l'observation par groupe (`96efc5f`) | feuille, pas de route | menu du groupe `groupes_page.dart:78` → `_ouvrirObservation` `:346-358` | **Atteignable** |

Annoncés comme **non faits**, donc non comptés : Finance et Direction (`admin_domaine.dart:99`, chemin nul), `SEC-01`/`SEC-02` « prêts à construire » (`HANDOFF.md:99-102`), `ADM-03` et `CTR-03` bloqués (`HANDOFF.md:2674-2677`). L'observation par l'administrateur est comptée en §3.4 (n° 48).

### 3.4 Salle (10)

| # | Fonction | Annoncé où | Route | Entrée | Classe | Remarque |
|---|---|---|---|---|---|---|
| 4 | `ELV-03` Salle, élève | `08-catalogue-ecrans.md:54` | `app_router.dart:609-616` | `accueil_eleve_page.dart:394-405` (« Rejoindre », fenêtre ouverte) | **Atteignable** | vidéo réelle : dépend du jeton LiveKit, **INCONNU** ici (C10 §8.4 prétend que `0042` refuserait tout jeton) |
| 21 | `ENS-03` Salle, enseignant, avec le panneau de présentation du Coran | `TEACHER_INTEGRATION_REPORT.md:42` et §3.3-3.4 | idem | `journee_page.dart:536` | **Atteignable, sous condition** | panneau monté seulement si `vue.role == enseignant && vue.peutPresenter` (`salle_page.dart:556-557`), c'est-à-dire si le jeton porte `can_publish_data` (`vue_salle.dart:220`) : dépendance serveur **INCONNUE** |
| 50 | `CTR-02` Observation invisible du contrôleur | `08-catalogue-ecrans.md:56` | idem | `planning_page.dart:133-138` | **Atteignable** | - |
| 8 | Classe Live `/tc/classe` (la seconde salle) | `TC_AGENT_E_REPORT.md` ; commentaire `routes.dart:331-334` « atteinte par le bouton Rejoindre et la barre Cours en cours » | `routes_tc_e.dart:34-49` | seule entrée `routes_tc_a.dart:63-83`, dans l'Espace Groupe : l'élève n'y a pas d'entrée (n° 6), l'enseignant y est refusé (n° 25), le tuteur l'atteint mais `/tc/classe` lui est refusée (`redirection.dart:138-140`) et il est renvoyé en silence vers `/tuteur` | **Route sans entrée** | confirme `CLAUDE.md:69-71` (« sans entrée effective sur main ») ; la barre « Cours en cours » n'est posée nulle part (n° 12) |
| 12 | Barre « Cours en cours » et session persistante | `TC_AGENT_E_REPORT.md` §1.2, §2.2 | - | `BarreCoursEnCours` non reliée (R1 n° 35) ; `ControleurSessionPersistante` lu seulement par la Classe Live | **Code sans route** | - |
| 24 | L'enseignant voit qu'un tuteur observe | `08d8edb` « l'annonce du tuteur arrive enfin à l'enseignant » | dans `/tc/classe` (`entete_classe.dart:211-214`) | aucune (n° 8) ; la vraie salle `/salle` ne la porte pas | **Route sans entrée** | `08d8edb` ne modifie que `classe_live_page.dart` et `entete_classe.dart` (`git show --stat`) |
| 27 | Temps réel pédagogique, état partagé, reprise après coupure | `TC_AGENT_F` ; `bf01953` | - | R1 (lot F, 15 fichiers) | **Code sans route** | persistance en mémoire seulement (R1) |
| 29 | Bibliothèque ouverte pendant le cours (`ClassLibraryPicker`) | `TC_AGENT_B` ; `d5bc5bf` | - | R1 n° 34 | **Code sans route** | - |
| 48 | Porte d'observation `/tc/observation/:id` (tuteur ; admin incognito ou visible ; contrôleur) | `TC_AGENT_G_REPORT.md` §0-§3 ; `24a5bd1` « brancher la salle réelle sur la visite du tuteur » | `routes_tc_g.dart:37-45` | **aucune** : « Assister » du tuteur va encore à `/salle` (`accueil_famille_page.dart:180-196`), « Observer » du contrôleur aussi (`planning_page.dart:133-138`), l'admin n'a aucun bouton ; `entete_classe.dart:196-202` l'écrit | **Route sans entrée** | `24a5bd1` ne touche que `entree_observation_page.dart` et `panneau_observation_tuteur.dart` (`git show --stat`) |
| 52 | L'annonce d'observation dans la **vraie** salle (enseignant et enfant concerné) | branche `observation/lot-2026-09-21` : `e8cd50e`, `3d377fe` | - | `git diff --stat main...observation/lot-2026-09-21 -- lib` : `salle_page.dart` +95, `indicateur_observation.dart` 373 lignes changées, non fusionnés | **Absent de main** | repris dans `ui/tuteur-v1` (`0401086`, chantier actif, non fusionné, non examiné) |

### 3.5 Coran (5)

| # | Fonction | Annoncé où | Route | Entrée | Classe | Remarque |
|---|---|---|---|---|---|---|
| 2 | `ELV-04` Lecteur du Coran, trois rendus (page, verset agrandi, focus) | `090ae6f` « Lot N5 : le Coran est dans le produit » ; `e938445` ; `08-catalogue-ecrans.md:62` | `app_router.dart:208-216` → `MushafPage` | `nav_shell.dart:63-67` ; `accueil_eleve_page.dart:566` | **Atteignable** | **le texte de chaque page est affiché à l'envers** (§5) |
| 5 | La page présentée par l'enseignant, vue par l'élève | `TEACHER_INTEGRATION_REPORT.md:35-36` « une salle qui sait présenter le Coran » ; ADR-026 (`SOCLE_CATALOGUE_REPORT.md` §1.4) ; message du panneau « le tour de page peut arriver en retard chez votre groupe » (`AGENT_B_REPORT.md` §5) | - | aucun écran élève ne lit `contenusPresentes` : `git grep` ne trouve que `presentation_coran.dart:53-55` et `panneau_enseignant.dart:75-76` (enseignant) ; `salle_page.dart:55-60` : « il ne présente aucun contenu lui-même » | **Absent de main** (côté élève) | l'enseignant tourne des pages que personne d'autre ne voit |
| 9 | `/tc/mushaf` | `TC_AGENT_C_REPORT.md` §7.6 ; `0007ff9` | `routes_tc_c.dart:24-29` | **aucune** (`git grep` : déclaration et garde seulement) | **Route sans entrée** | doublon de `/eleve/coran` (même `MushafPage`) |
| 10 | Suivi de la classe et « position de groupe » dans le lecteur | `TC_AGENT_C_REPORT.md` §4.4 (limite dite §6.7) | - | `MushafPage.sessionId` n'est jamais passé : `app_router.dart:215` et `routes_tc_c.dart:27` construisent `const MushafPage()` | **Code sans route** | - |
| 23 | Le Coran hors salle pour l'**enseignant** | `08-catalogue-ecrans.md:62` « `ELV-04` Coran - Élève, enseignant » | - | l'enseignant est hors du préfixe `/eleve` (`redirection.dart:112-115`), `/tc/mushaf` est réservé à l'élève (`:141-143`), aucune destination (`nav_shell.dart:108-124`) | **Absent de main** (pour ce rôle) | son seul accès au texte est le panneau de présentation en salle (n° 21) |

### 3.6 Autres rôles (2)

| # | Écran | Annoncé où | Route | Entrée | Classe |
|---|---|---|---|---|---|
| 49 | `CTR-01` Planning du contrôle | `08-catalogue-ecrans.md:53` | `app_router.dart:371-375` | racine du rôle | **Atteignable** |
| 51 | `AGT-00` Entrée d'un agent IA | `08-catalogue-ecrans.md:25` ; `c5b978d` | `:128-131` | lien fabriqué par `ADM-07` (`acces_agents_page.dart:549`) | **Atteignable** (avec un jeton) |

`/comptable` rend l'écran « Mon compte » (`app_router.dart:585-588`) : `CPT-01` est annoncé hors MVP-0 (`08-catalogue-ecrans.md:89`), ce n'est pas un écart.

### 3.7 Annonces portées par des commits hors de `main` (3)

`git log --all --not main --source` : 101 commits hors `main`. Ceux qui annoncent une fonction utilisateur :

| # | Commit, branche | Ce qu'il annonce | Sur `main` | Classe |
|---|---|---|---|---|
| 53 | `33503fe` (`v0/verite-produit`) | « la production ne sert plus de groupes fictifs ni d'enregistrement imaginaire » | `main` sert encore les doubles : `port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55` | **Absent de main** (repris dans `ui/tuteur-v1` `b6df316`, non fusionné) |
| 54 | `50fae3c` (`core24/fable-frontend`) | « une seule salle où le Coran est la surface » | non fusionné, déclaré NON CONFORME (`CLAUDE.md`, C10 §4.3) | **Absent de main** |
| 55 | `8f819d0`, `dcafddf` (`integration/core24-classes-v2`) | « complete teacher admin and replacement workflow », « connect onboarding and guided interface » | idem | **Absent de main** |

Hors comptage : `codex/r2-adaptive-shell` `65c564f` et `codex/vague5-integration` `dbcd380` (« read-only teacher profile ») sont remplacés par l'`ENS-05` de `main` ; `f84580b` (correction de présence) est arrivé par `cb3a220` (n° 30) ; `sauvegarde/r2-du-tiers` et `lot/onboarding-offres` ne portent pas d'écran ; `ui/tuteur-v1` et `ui/tuteur-v1-p0d` sont le chantier actif du 24/09 (non examinés).

Autre écart de message : `1ebf8dc` « défauts Académie 2x120s » ne modifie **aucun fichier de `lib/`** (`git show --stat` : une migration seule) ; le constructeur Dart `defautsNormatifs` garde 1 visite et 120 s (`guardian_observation_policy.dart:74-80`), sans effet visible puisque « aucun écran ne l'appelle » (`:72-73`).

---

## 4. Synthèse chiffrée

| Section | Atteignable | Route sans entrée | Code sans route | Absent de main | Total |
|---|---|---|---|---|---|
| Élève | 2 | 2 | 3 | 0 | 7 |
| Enseignant | 6 | 2 | 3 | 0 | 11 |
| Administration | 17 | 0 | 0 | 0 | 17 |
| Salle | 3 | 3 | 3 | 1 | 10 |
| Coran | 1 | 1 | 1 | 2 | 5 |
| Contrôleur, agent | 2 | 0 | 0 | 0 | 2 |
| Branches | 0 | 0 | 0 | 3 | 3 |
| **Total** | **31** | **8** | **10** | **6** | **55** |
| **Hors administration** | **14** | **8** | **10** | **6** | **38** |

Parmi les 14 « atteignables » hors administration, plusieurs affichent autre chose que ce qui était promis : le lecteur du Coran à l'envers (n° 2), la revue de groupe vide par construction (n° 19), la salle et le panneau de présentation suspendus à un jeton serveur non vérifié (n° 4, 21). Le tuteur, seul rôle à atteindre l'Espace Groupe, y voit des groupes inventés (`port_groupes.dart:37-39`).

---

## 5. Le Coran « se lit en marche arrière et du bas vers le haut »

### 5.1 La chaîne de rendu, de la route au texte

| Étape | Fichier:ligne (`main` @ `4a7aa2b`) | Effet sur l'ordre |
|---|---|---|
| Route élève | `app_router.dart:208-216` | `/eleve/coran` rend `const MushafPage()` |
| Écran | `mushaf_page.dart:178-184` ; mode d'ouverture `mushaf` (`etat_lecture_coran.dart:30-36`) | rend `VuePageMushaf` |
| Page demandée | `vue_page_mushaf.dart:182-184` → `moteur_mushaf.dart:48-74` | `pageMushafProvider` assemble corpus, sourates, layout |
| Corpus | `moteur_mushaf.dart:30-33` → `corpus_service_coran.dart:55-64`, `:237-250` | conversion un pour un, **aucun tri** |
| **Requête** | **`service_coran.dart:324-330`** | `.from('verset')...eq('page_numero', numero).order('sourate_numero').order('numero')`, **sans `ascending: true`** |
| Bibliothèque | `postgrest` **2.9.1** (verrouillée par `main:pubspec.lock`), `postgrest_transform_builder.dart:102-115` | `bool ascending = false` (ligne 104) ; construit `colonne.desc` (ligne 112) ; la documentation du paquet le dit (lignes 71-73) |
| Découpage | `page_mushaf_vm.dart:113-120`, `:199-212` → `vue_lecteur.dart:164-205` | garde l'ordre reçu ; les sections suivent l'ordre reçu |
| Rendu page | `vue_page_mushaf.dart:412-431` (sections), `:513-537` (versets d'un paragraphe) | pose les versets dans l'ordre reçu : de haut en bas, et de droite à gauche dans un paragraphe RTL |

Conséquence : sur chaque page, le **dernier** verset est posé en haut à droite, le **premier** en bas à gauche. Pour lire dans l'ordre révélé, il faut partir du bas et remonter, à rebours : exactement « en marche arrière et du bas vers le haut ». Constat simple pour le directeur : à la **page 1**, le verset 1 devrait apparaître **en bas** de la page et le verset 7 en haut ; à la **page 604**, An-Nas devrait apparaître avant Al-Ikhlas.

### 5.2 Preuve à l'exécution (hors dépôt, sans réseau)

La version et l'intégrité du paquet sont constatées : `main:pubspec.lock` fixe `postgrest` `2.9.1`, sha256 `b7f957273ba6a1c26cefa987ac524f4138e9ab7542fbb9e6abdfddacb9895a21`, identique à `%LOCALAPPDATA%\Pub\Cache\hosted-hashes\pub.dev\postgrest-2.9.1.sha256`. La même version est verrouillée à `090ae6f`, `0007ff9` et `4a7aa2b`.

Script écrit dans le scratchpad de la session (`...\scratchpad\preuve_order\bin\preuve_order.dart`), dépendances résolues hors ligne depuis le cache (`dart pub get --offline` : `+ postgrest 2.9.1`). Un client HTTP factice capture l'URL envoyée pour la requête **recopiée** de `service_coran.dart:324-330`, celle de `:306-309`, et un témoin écrit comme `service_matching.dart:205`. Sortie constatée :

```
/rest/v1/verset  order=sourate_numero.desc.nullslast,numero.desc.nullslast
/rest/v1/sourate  order=numero.desc.nullslast
/rest/v1/eleves_en_attente_v  order=depuis.asc.nullslast
```

(Le processus ne se terminait pas seul, l'isolat JSON de `postgrest` restant ouvert ; ses trois processus, lancés par moi, ont été arrêtés après lecture de la sortie.)

### 5.3 Effets secondaires du même défaut (déduits du code, non observés à l'écran)

- **Titres de sourate manquants** : `vue_lecteur.dart:189` pose `commenceLaSourate: courants.first.numero == 1`. En ordre décroissant, `first` est le plus grand numéro : le titre d'une sourate qui commence sur la page n'est pas posé (`vue_page_mushaf.dart:421`), sauf si la page n'en porte que le verset 1.
- **Titre d'écran faux** sur une page à plusieurs sourates : `mushaf_page.dart:208-210` affiche `sections.first`, donc la **dernière** sourate de la page.
- **Marque-page décalé** : la position mémorisée prend `versets.first` (`vue_verset_agrandi.dart:288-298`, appelée par `mushaf_page.dart:127`), donc le **dernier** verset de la page.
- **Mode « verset agrandi »** : mêmes versets du dernier au premier (`vue_verset_agrandi.dart:141-148`).
- **Panneau de l'enseignant en salle** : même requête (`panneau_enseignant.dart:282-289` via `pageCoranProvider`, `service_coran.dart:486-489`) et même rendu (`:359-389`). La page que l'enseignant présente est donc aussi à l'envers chez lui.
- **Liste des sourates décroissante** (`service_coran.dart:306-309`) : la recherche par nom propose d'abord les numéros élevés (`corpus_service_coran.dart:201-221`).
- **Ancien lecteur** (13/09 au 21/09) : `coran_page.dart` @ `090ae6f` lisait la même requête (`:126`, `:154`). `git blame` attribue les lignes `service_coran.dart:309, 329-330` à `090ae6f` (13/09), jamais modifiées depuis.

### 5.4 Pourquoi personne ne l'a vu

- **Le piège était connu** : `service_matching.dart:196-205` (« `order()` de postgrest trie en DESCENDANT quand on ne dit rien »), règle écrite au catalogue `08-catalogue-ecrans.md:280` (« le sens s'écrit toujours »), rappel dans `test/features/creneaux_test.dart:280`. Il n'a pas été appliqué au Coran.
- **Aucun test ne lit la vraie requête** : `git grep -n -E "ServiceCoranSupabase|ascending|\.order\(" 4a7aa2b -- test` ne rend qu'un commentaire de `creneaux_test.dart`. Les tests du moteur passent par des doubles en ordre croissant (`test/teaching_core/c/faux/faux_corpus_coran.dart`, `TC_AGENT_C_REPORT.md` §3 et §6.8) ; le « golden » Q-08 lit des numéros extraits de la migration `0013`, pas la requête (`TC_AGENT_Q_REPORT.md:113-119`).

### 5.5 Une seconde cause possible de « marche arrière », plus faible

Le feuilletage est un `PageView` placé sous `Directionality(rtl)` (`vue_page_mushaf.dart:133-152`) : la page suivante arrive par la **gauche**, et glisser le doigt de droite à gauche ramène à la page **précédente**. C'est voulu (`vue_lecteur.dart:145-149` : « c'est au rendu de placer le geste du bon côté »). Mais les boutons du bas restent dans le sens français : « Page précédente » à gauche, « Page suivante » à droite (`mushaf_page.dart:489-514`, hors de la zone RTL). Le geste et les boutons se contredisent : un lecteur qui glisse « comme dans le reste de l'application » recule. Cette cause peut produire la « marche arrière » d'une page à l'autre ; elle **ne produit pas** le « du bas vers le haut », que seule la requête explique. L'ouverture double page, elle, est dans le bon ordre (`page_mushaf_vm.dart:269-270`, `vue_page_mushaf.dart:224-245`).

### 5.6 Ce qui n'est pas prouvé

- Pas de capture d'écran de l'application, pas de lecture de la base de production (aucune requête lancée sur Supabase).
- La version exacte servie en production est **INCONNUE** (R1 §6 : bundle du 21/09, contient `/tc/mushaf`). Le défaut étant dans la requête depuis le 13/09 et la bibliothèque verrouillée depuis, il est attendu en production ; c'est une déduction, pas une observation.
- Emplacement d'une correction, pour information seulement (rien n'a été modifié) : écrire `ascending: true` aux lignes `service_coran.dart:309, 329, 330, 459, 460`, et ajouter un test qui lit l'URL réelle comme le script ci-dessus.

---

## 6. Le même piège ailleurs (effet à l'écran non vérifié)

`git grep -n -E "\.order\(" 4a7aa2b -- lib` : appels sans `ascending: true`, donc triés en décroissant.

| Appel | Source | Retrié côté client ? |
|---|---|---|
| `service_appairage.dart:212` `.order('paired_at')` | `mes_appareils_v` | non trouvé |
| `service_controle.dart:56` `.order('started_at')` | `mes_seances_v` | oui (`vue_planning.dart:158, 239-247`) |
| `service_enseignant.dart:74` `.order('started_at')` | `mes_seances_enseignant_v` | oui pour la Journée (`journee.dart:99, 126-128, 152, 201`) |
| `service_enseignant.dart:84` `.order('first_name')` | `teacher_roster_v` | non trouvé |
| `service_enseignant.dart:93-94` `weekday`, `hour_local` | `mes_groupes_v` | non trouvé |
| `service_offres.dart:115, 125` `.order('ordre')` | `langues_cours`, `cohortes_age` | non trouvé |
| `service_planning.dart:268-269, 304, 313` | `weekly_availability`, `mes_seances_v`, `mes_affectations_v` | partiel (`journee.dart`) |

Recherche de retri limitée à `lib/core/{planning,enseignant,controle,appairage,offres}` et aux écrans voisins ; l'effet visible de chaque ligne n'a pas été mesuré.

---

## 7. Limites

- **Atteignable n'est pas fonctionnel.** La classe dit si un chemin d'interface existe dans le code ; elle ne dit rien des données ni du serveur (jetons vidéo, RPC, migrations appliquées : non vérifiés ici).
- **Lecture statique.** Aucune application lancée, aucun test Flutter exécuté, aucune capture. Une entrée est un appel de navigation trouvé par `git grep` ; une entrée conditionnelle (fenêtre horaire, séance avec groupe, jeton) est signalée comme telle.
- **Annonces lues** : les sources nommées dans la tâche. `HANDOFF.md` (3 249 lignes) et `08-catalogue-ecrans.md` (3 186 lignes) ont été lus par sections (en-tête, §10, §12.10, registre §1, invariants), pas intégralement. Les rapports `TC_AGENT_B`, `D`, `F`, `H` ont été lus par recherche ciblée et via R1.
- **Code non relié** : repris de R1 (graphe d'imports), non recalculé.
- **Tuteur** : non refait (voir `00_MAPPING_ROUTES.md`), sauf quand il est le seul rôle à tenir une entrée partagée.
- **Branches `ui/tuteur-v1*`** (chantier actif) : non examinées au-delà des messages de commit.

---

## 8. Rejouer

```powershell
$r = "D:\RA _APP\RA -OFFICIAL-APP"
git -C $r rev-parse main origin/main                                    # 4a7aa2b...
git -C $r grep -n -E "Routes\.[a-zA-Z]+|Chemins[A-Za-z]*\.|RoutesTc[A-Z]\.|RoutesCoran\." 4a7aa2b -- lib
git -C $r grep -n -E "enseignantBienvenue|versObservation|tcMushaf|RoutesCoran\.mushaf|contenusPresentes|IndicateurObservationEnfant\(" 4a7aa2b -- lib
git -C $r show 4a7aa2b:lib/core/coran/service_coran.dart               # lignes 306-309, 324-330
git -C $r blame -L 324,331 4a7aa2b -- lib/core/coran/service_coran.dart # 090ae6f, 13/09
git -C $r grep -n -E "\.order\(" 4a7aa2b -- lib
git -C $r show --stat 24a5bd1 08d8edb f2dfd64 1ebf8dc -- lib
git -C $r diff --stat main...observation/lot-2026-09-21 -- lib
git -C $r log --all --not main --source --date=short --format="%h|%ad|%S|%s"
# Bibliotheque : %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\postgrest-2.9.1\lib\src\postgrest_transform_builder.dart, lignes 71-73 et 102-115
```

Script de preuve (§5.2), à placer dans un dossier hors dépôt avec un `pubspec.yaml` qui dépend de `postgrest: 2.9.1` et `http: any`, puis `dart pub get --offline` et `dart run` (arrêter le processus après les trois lignes) :

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:postgrest/postgrest.dart';

Future<void> main() async {
  final faux = MockClient((http.Request r) async {
    print('${r.url.path}  order=${r.url.queryParameters['order']}');
    return http.Response('[]', 200, headers: {'content-type': 'application/json'});
  });
  final client = PostgrestClient('http://exemple.invalide/rest/v1', httpClient: faux);
  Future<void> essai(Future<Object?> Function() f) async { try { await f(); } catch (_) {} }
  await essai(() async => await client.from('verset').select()
      .eq('mushaf_id', 'EDITION').eq('page_numero', 2)
      .order('sourate_numero').order('numero'));                 // service_coran.dart:324-330
  await essai(() async => await client.from('sourate').select().order('numero'));   // :306-309
  await essai(() async => await client.from('eleves_en_attente_v').select()
      .order('depuis', ascending: true));                        // temoin service_matching.dart:205
}
```
