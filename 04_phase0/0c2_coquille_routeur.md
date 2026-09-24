# 0c2 : coquille tuteur, routeur, redirections, états transverses

Date : 24/09/2026, de 11:26 à 13:45 (+03:00). Worktree `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`.
Statut global : **7 commits locaux, aucun push, aucune PR, aucun merge.** Frontière backend vide. Statut de preuve : « UI réalisée » et « testée en simulation » (tests de widget sur le vrai routeur, captures) ; rien n'est « vérifié réellement » (aucun appareil, aucun Supabase).

## 0. À lire en premier

1. **Prérequis non commité de 0c1.** `EtatSysteme`, `EntetePage`, `BasculeTheme`, `BlocAsynchrone`, `SelecteurProfils` et les clés `commun.*` / `nav.tuteur.historique|compte` dont la coquille dépend étaient dans l'arbre, non commités (rapport 0c1 §2). Je les ai commités tels quels (`981a0c6`), après avoir **rétabli à la valeur de `3cf3544`** les deux libellés d'enregistrement laissés par 0a (`salle.bandeauPermanent`, `enseignant.profil.contratAccuse`), comme l'exige la décision du directeur (`03` §1 bis-2). Tests de 0c1 relancés avant ce commit, y compris ceux que 0c1 n'avait pas pu lancer : PASS (§3, n° 3).
2. **Reprise 0a toujours non commitée** : `lib/core/tc_groupe/port_groupes.dart`, `lib/core/tc_horloge/port_horloge_seance.dart`, `groupes_supabase.dart`, `horloge_supabase.dart`, `test/teaching_core/a/groupes_supabase_test.dart` restent modifiés ou non suivis dans l'arbre ; je n'y ai pas touché. Tous mes tests ont tourné **sur l'arbre de travail** (donc avec ces fichiers), pas sur HEAD isolé. Seul échec constaté : K7 « dette résorbée », attendu tant que 0a n'est pas commité (§3, n° 15).
3. **Écart assumé aux STUB** : 32 écrans réservés rendent `EtatSysteme(nature: indisponible)` ; **6 délèguent à l'écran existant** que la route servait déjà (Foyer, Compte, informations, préférences, fiche élève, classe), sinon le tuteur perdait des fonctions réelles (sa **déconnexion**, le choix d'apparence, les appareils du foyer, l'Espace Groupe). Tous portent `// STUB PHASE 0 : propriété du lot X, à remplacer`. Détail §2.2.

## 1. Commits (branche `ui/tuteur-v1`, locaux)

| Hash | Message | Contenu |
|---|---|---|
| `981a0c6` | feat(widgets): etats systeme, en-tete, bascule de theme et cles commun (0c1) | travail de 0c1 (5 composants, galerie, test, i18n) + 2 libellés d'enregistrement rétablis à `3cf3544` ; `strings*.g.dart` régénérés |
| `b3b6759` | feat(coquille): navigation tuteur a quatre destinations et shell adaptatif | `nav_shell.dart` (réécrit), `page_shell.dart`, `app_icons.dart` (+3), `preferences_locales.dart` (repli par appareil), `app.dart`, `app_router.dart` (coquille à 4 branches, en-tête), `routes.dart`, galerie, i18n `nav.*` |
| `b5c8895` | feat(routeur): arbre du tuteur, alias, redirections et ecrans reserves aux lots | `routes.dart`, `app_router.dart`, `redirection.dart`, `page_etat.dart` (nouveau), `admin_domaine.dart` (`ongletsSecurite()`), 38 fichiers STUB |
| `5edba3d` | feat(routeur): page introuvable, acces refuse, retour apres connexion, hors ligne et demarrage | `etats_routeur.dart` (nouveau), `app_router.dart` (`errorBuilder`, `/acces-refuse`, `/hors-ligne`, `/`), `redirection.dart`, `routes.dart`, `session_state.dart`, `source_session.dart`, i18n `commun.*` |
| `b039196` | test(routeur): coquille tuteur, arbre, alias, redirections et etats transverses | `navigation_test`, `redirection_test`, `etats_transverses_test` (nouveau), `support_routeur` (nouveau), `parcours_enseignant_test`, `nav_shell_adaptatif_test`, `composants_test`, `test/agent/acces_agent_test.dart` |
| `97b9ddf` | fix(coquille): soulignement au bord de la barre et disque du bouton de repli | écarts visibles sur les planches (§4) |
| `125fe78` | test(capture): coquille du tuteur sur le vrai routeur et planches | `test/capture/coquille_capture_test.dart`, `LISEZ-MOI.md`, `support_routeur` (faux d'appairage) |

## 2. Ce qui est fait

### 2.1 Coquille (`lib/core/widgets/nav_shell.dart`, `page_shell.dart`, `app_router.dart`)

- `destinationsPour(guardian)` = Accueil (`AppIcons.accueil`) · Foyer (`AppIcons.foyer`) · Historique (`AppIcons.historique`) · Compte (`AppIcons.profil`, `enPied: true`) ; chemins `/tuteur`, `/tuteur/foyer`, `/tuteur/suivi`, `/tuteur/compte`, chacun une branche. `secondairesPour` vide pour **tous** les rôles. Élève, enseignant, contrôleur, comptable, admin : destinations inchangées.
- Icône Historique : Phosphor `clock-counter-clockwise` **0xe1a0**, relevée dans `phosphor_flutter-2.1.0` (`phosphor_icons_regular.dart` et `_fill.dart`) et vérifiée dans la table `cmap` des deux polices embarquées (script de lecture `cmap`, témoin négatif `0xffff1` absent) ; idem `caret-double-left/right` 0xe128 / 0xe12a (repli, `matchTextDirection`).
- Barre basse flottante < 600 : pilule `surfaceRaised`, filet `contourCarte`, `AppRadius.md`, `AppElevation.niveau1`, hauteur mini 64 ; actif = icône Fill + libellé `inkAccent` 600 + soulignement 3 dp (40 dp, au bord bas) ; un nœud sémantique par onglet (bouton, libellé, `selected`) ; libellés bornés à 150 % d'échelle de texte, lus en entier.
- Colonne ≥ 600 : repliée (rail 80, icônes seules, infobulles) par défaut sur tablette, dépliée (256, mot-symbole « Rewayah », libellés) par défaut sur bureau ; bouton de repli / dépli (disque 40 dans une cible 48) ; le choix est **une préférence de cet appareil** (`navigationReplieeProvider`, persistée comme le thème, clé `navigation.repliee`, montée par `RewayahApp`). Compte épinglé en bas (`Destination.enPied`). Actif : `washAccent` en clair, `surfacePrimary` plein en sombre.
- En-tête : `PageShell` rend `EntetePage` quand il y a disque retour, sous-titre ou actions ; la coquille tuteur pose `ActionsEnteteCoquille` = bascule de thème (tablette et bureau) + cloche (`/tuteur/notifications`, pas de point : DB-CPT-04). Nouveaux paramètres `PageShell.onRetour`, `sousTitre`, `actionsEntete`.
- Tâche focalisée : `Routes.estTacheFocalisee` (ajout de profil, émetteur QR, parcours, préférences et apparence, consentements) ; `NavShell.masquerBarreBasse` efface la barre sur téléphone ; la colonne reste sur tablette et bureau.
- **Double zone sûre corrigée** (C11 §5.6) : la barre consomme l'encart bas et ne reçoit plus l'encart haut (`MediaQuery.removePadding`), le contenu ne reçoit plus l'encart bas ; la colonne retire l'encart de son côté. Mesuré en test (encart haut 47 conservé, bas 0, barre bien sous le contenu, pied à 844).
- `goBranch` n'est plus appelé sur un index sans branche (Compte de l'élève, C01 §3.3-6) : `go` ; sur `/compte`, la barre de l'élève reste avec Compte actif.

### 2.2 Routeur (`routes.dart`, `app_router.dart`, `redirection.dart`)

Structure §5 du mapping, toutes les lignes des §3 et §4 :

| Branche | Routes |
|---|---|
| 0 Accueil | `/tuteur` ; `notifications` ; `classes/catalogue?eleve=` ; `classes/:classeId?eleve=` + `planning`, `travail`, `ressources`, `progression` |
| 1 Foyer | `/tuteur/foyer` ; `ajouter` (`?pour=moi` : écran d'indisponibilité B) ; `appareils` ; `appairer/:eleveId` ; `:eleveId` + `informations`, `inscription`, `interface`, `camera`, `acces`, `appareils` ; `/tuteur/parcours/:eleveId` ; `/tuteur/reglages` (gardée jusqu'à la fiche B, C6) |
| 2 Historique | `/tuteur/suivi` + `observations` ; `/tuteur/seances/:seanceId` + `observations?eleve=` |
| 3 Compte | `/tuteur/compte` + `informations`, `securite`, `acces`, `paiements`, `preferences` (+ `apparence`), `aide`, `informations-legales`, `consentements` |
| Public | `/bienvenue`, `/connexion/recuperation`, `/connexion/eleve/scanner`, `/connexion/eleve/code` ; `/inscription/{usage,identite,genre,recapitulatif}` |
| Admin | `/admin/securite-audit/observations` + `ongletsSecurite()` (Journal, Observations) |

- Alias (routes `redirect`, déclarées avant la coquille) : `/tuteur/accueil` → `/tuteur` ; `/tuteur/historique(/observations)` → `/tuteur/suivi(/observations)` ; `/tuteur/foyer/ajouter-enfant` → `/tuteur/foyer/ajouter` (requête gardée) ; `/tuteur/disponibilites` → `/tuteur/foyer` ; `/tuteur/foyer/:id/appareils/connexion` → `/tuteur/foyer/appairer/:id` ; `/tuteur/classes/:id/observer` → `/tuteur/classes/:id` (voir §5).
- Pour le **seul tuteur** (`deciderRedirection`) : `/compte` → `/tuteur/compte`, `/compte/profil` → `…/informations`, `/compte/reglages` → `…/preferences`, `/compte/profils` → `/tuteur/foyer`, `/compte/profils/:id` → `/tuteur/foyer/:id`, autre `/compte/x` → `/tuteur/compte/x` ; `/tc/groupes` → `/tuteur`, `/tc/groupes/:id` → `/tuteur/classes/:id`. Les autres rôles gardent `/compte` et `/tc/groupes`.
- R1 à R7 : tout sous `/tuteur`, `prefixePour(guardian)` inchangé ; public sous `/connexion` ; portes d'accès inchangées ; statiques avant dynamiques ; sous-pages dans leur branche ; aucun secret en URL ; `retour` validé par `cheminRetourValide`. G-PUB lit enfin la liste unique `Routes.publiques` (connexion, bienvenue, agent).
- `Routes.tuteurAjouterEnfant` vaut désormais `/tuteur/foyer/ajouter` (nom gardé pour ses 5 appelants) ; nouvelles constantes et constructeurs (`ficheElevePour`, `classePour`, `seancePour`, `observationsSeancePour`, `compteTuteurSousPage`…).
- **38 STUB** (chemins exacts de `00_OWNERSHIP` §3, commentaire `// STUB PHASE 0 : propriété du lot X, à remplacer`) :
  - A (7) : `bienvenue/bienvenue_page.dart`, `connexion/recuperation_page.dart`, `inscription/etapes/{usage,identite,genre,recapitulatif}_etape.dart`, `consentements/consentement_observation_page.dart` ;
  - B (8) : `foyer/foyer_page.dart` (**délègue** à `AppareilsPage`), `foyer/fiche_eleve_page.dart` (**délègue** à `ProfilEnfantPage`), `foyer/fiche/{informations,inscription,interface,camera,acces}_page.dart`, `foyer/creer_mon_profil_indisponible.dart` ;
  - C (6) : `classe_tuteur/{catalogue_classes,classe_tuteur,planning_classe,travail_classe,ressources_classe,progression_classe}_page.dart` (`ClasseTuteurPage` **délègue** à `EspaceGroupePage` en `RoleEspaceGroupe.tuteur`, sans « Rejoindre ») ;
  - D (3) : `appareils/appareils_eleve_page.dart`, `eleve_connexion/{scanner,saisie_code}_page.dart` ;
  - E (14) : `compte/{compte_tuteur,informations,securite,acces,paiements,preferences,apparence,aide,informations_legales}_page.dart` (`CompteTuteurPage` → `ComptePage`, `InformationsComptePage` → `ProfilPersonnelPage`, `PreferencesComptePage` → `ReglagesComptePage` : **délégations**), `suivi_foyer/{observations,detail_seance,detail_observations}_page.dart`, `notifications/notifications_page.dart`, `admin_observations/observations_admin_page.dart`.
  - Les STUB purs passent par `lib/core/router/page_etat.dart` (`PageEtat` : `PageShell` + `EtatSysteme` page, action par défaut « Retour à l'accueil » vers `/`, que la garde renvoie à la bonne porte : aucune impasse). Écrans existants non écrasés.

### 2.3 États transverses (`etats_routeur.dart`, `redirection.dart`, session)

- `errorBuilder` → `PageIntrouvable` (EtatSysteme introuvable) : « Retour à l'accueil » (racine du rôle) ou « Se connecter » sans session. `deciderRedirection(routeConnue: etat.error == null)` laisse passer un chemin qu'aucune route ne sert, pour toute porte : aucune donnée n'est montrée.
- Accès refusé : route connue d'un autre rôle, ou `/tc/*` fermé au rôle → `/acces-refuse` (`PageAccesRefuse`, ouverte à tout rôle actif), action vers la racine du rôle. La salle sans billet garde son renvoi (ADR-005).
- Session expirée / lien profond sans session : `/connexion?retour=<chemin+requête>` si `cheminRetourValide` l'accepte ; une fois actif sur `/connexion`, reprise de `retour` s'il est ouvert au rôle (sinon racine) ; jamais le tunnel lui-même, la salle, la classe, l'agent, une URL externe.
- Hors ligne au démarrage : `_lireProfil` borné par `AppDelais.requeteMax` ; `PostgrestException` ou `TypeError` = `LectureProfil.echouee` (portail d'attente, inchangé) ; toute autre exception (réseau, délai) = `LectureProfil.injoignable` → `PorteAcces.horsLigne` → toute adresse mène à `/hors-ligne` (`PageHorsLigne`, « Réessayer » = `SourceSession.rafraichir()`, relance aussi au retour du réseau). Aucun accès ouvert.
- `/` : `EcranDemarrage` (MarquePage, progression lue « Ouverture de Rewayah », puis après `AppDelais.chargementProlonge` l'état « La connexion prend plus de temps que prévu » avec relance). `EcranAConstruire` n'est plus monté (fichier conservé, suppression sur accord).
- i18n (espace COORD) : `nav.principale`, `nav.motSymbole`, `nav.replier`, `nav.deplier`, `commun.etats.horsLigneDemarrage`, `commun.etats.actions.seConnecter`, `commun.demarrage.ouverture` ; slang régénéré et commité.

## 3. Commandes et résultats exacts (toutes sous `flutter-verrou.ps1`)

| # | Commande | Résultat | Statut |
|---|---|---|---|
| 1 | `dart run slang` (après rétablissement des 2 libellés) | `Translations generated successfully. (1.791 seconds)` | PASS |
| 2 | `dart analyze --fatal-infos lib/core/widgets lib/core/i18n lib/features/_dev test/widgets` | `No issues found!`, 390 s | PASS |
| 3 | `flutter test composants_etats_test, catalogue_galerie_test, journee_test, classe_live_page_test, q07, q12, test/i18n` (journal `0c2_tests_prealable.log`) | `02:00 +105: All tests passed!` (dont les 4 non exécutés par 0c1) | PASS |
| 4 | `dart run slang && dart analyze` coquille | 1 erreur (`AppInkColor` non importé), 1 import inutile, 1 info | FAIL puis corrigé |
| 5 | `dart analyze` coquille + tests | 2 infos `containsSemantics` déprécié | FAIL puis corrigé (`isSemantics`) |
| 6 | `flutter test nav_shell_adaptatif, composants, catalogue_galerie, theme_applique` (`0c2_tests_coquille.log`) | `01:38 +80: All tests passed!` | PASS |
| 7 | `dart run tool/verifier_jetons.dart` | `416 fichiers, aucune violation.` | PASS |
| 8 | `dart format` + `dart analyze --fatal-infos lib/core/router lib/core/admin/admin_domaine.dart` + 38 STUB | `No issues found!`, 94 s | PASS |
| 9 | `flutter test test/router/navigation_test.dart` (état commit 2, `0c2_tests_navigation.log`) | `00:40 +64: All tests passed!` | PASS |
| 10 | `dart run slang && dart analyze lib/core/router lib/core/session lib/core/i18n` | 1 import inutile | FAIL puis corrigé |
| 11 | `dart analyze --fatal-infos lib/core/router lib/core/session test/router test/agent/acces_agent_test.dart` | `No issues found!`, 23 s | PASS |
| 12 | `flutter test test/router test/agent/acces_agent_test.dart test/foyer/creation_profil_eleve_test.dart` (`0c2_tests_routeur.log`) | `+289 -1` : le test « aucune route orpheline » n'avait pas de session hors ligne pour `/hors-ligne` ; corrigé dans le test | FAIL puis corrigé |
| 13 | `dart run tool/verifier_jetons.dart` | `417 fichiers, aucune violation.` | PASS |
| 14 | non-régression `flutter test test/router test/widgets test/accessibilite test/features test/theme test/icons test/i18n test/agent test/teaching_core/a test/config test/foyer test/capacites` (`0c2_tests_nonreg.log`) | `12:18 +1116 -1` : seul échec **K7 « dette résorbée »** (`GroupesDemonstrationLocale`, `HorlogeSeanceDemonstration`), dû aux fichiers 0a non commités, attendu (0d §4.1-4, 0c1 n° 12) | PASS hors échec attendu de 0a |
| 15 | `dart analyze` capture | 4 erreurs (nom `stabiliser` ambigu, 2 `String?`) | FAIL puis corrigé |
| 16 | captures `flutter test test/capture/coquille_capture_test.dart` avec `CAPTURE_DIR` et 2 maquettes (`0c2_captures.log`) | `00:30 +13: All tests passed!` | PASS |
| 17 | final : `dart format` ; `dart analyze --fatal-infos nav_shell.dart test/capture` ; `verifier_jetons` ; `flutter test nav_shell_adaptatif, composants, catalogue_galerie, navigation_test, coquille_capture_test` (`0c2_tests_correctifs.log`) | `No issues found!` ; `417 fichiers, aucune violation.` ; `01:43 +150: All tests passed!` | PASS |
| 18 | `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc dart_define.example.json` | vide | PASS |

**Non exécutés** : analyse complète du dépôt et suite complète (réservées au coordinateur ; la non-régression n° 14 couvre 12 dossiers, pas `test/teaching_core/{b..q}`, `test/appairage`, `test/planning`, `test/presence`, `test/suivi`, etc.) ; HEAD isolé de l'arbre de travail ; `dart run build_runner` (aucune source générée touchée) ; build web ; appareil réel, Android, iOS. `etats_transverses_test` et `redirection_test` n'ont pas été relancés après `97b9ddf` (correctif purement visuel de `nav_shell.dart`).

Tests couverts par le n° 12/14 : 4 destinations tuteur et 6 rôles ; 36 routes tuteur construites sur le vrai routeur avec leur destination parente active ; 15 alias et redirections ; 404 (toutes portes) ; lien profond inconnu sans plantage (5 chemins) ; identifiants inconnus (classe, élève) ; accès refusé et retour ; session expirée puis retour à la destination ; retour externe ignoré ; hors ligne (jamais d'accès, relance) ; démarrage sans « Écran à construire » puis chargement prolongé ; aucune route orpheline (chaque route déclarée est ouverte à au moins une session) ; rien sous `/appareils` (R1).

## 4. Captures (`04_phase0\captures_0c\`, lues)

`coquille_{accueil,compte,foyer}_390x844@3_{light,dark}.png` (zone sûre 47/34), `coquille_accueil_1440x900@1_{light,dark}.png`, `coquille_historique_1024x768@1_{light,dark}.png` (rail replié), planches `coquille_accueil_bureau_contre_maquette.png` (contre `acceuil tuteur desktop light.png`, 1440 logiques) et `coquille_compte_mobile_contre_maquette.png` (contre `mobile\mon compte tuteur mobile light mode.png`, 390 logiques), avec leurs `_capture.png`. Données : foyer fictif A (`test/fixtures/tuteur/foyers.dart`), aucun service réel.

- Conformes à la maquette bureau : mot-symbole, bouton de repli, Accueil actif en pastille, Foyer et Historique, Compte épinglé en bas, bascule soleil / lune et cloche à droite du titre ; sombre : pastille pleine `surfacePrimary`.
- Conforme à la maquette mobile : 4 onglets, Compte actif (icône pleine, libellé et soulignement d'accent), pilule flottante au-dessus de la zone sûre, contenu arrêté au-dessus de la barre (plus de bande vide).
- Écarts corrigés (`97b9ddf`) : soulignement déplacé au bord bas de la pilule et élargi à 40 ; bouton de repli en disque cerclé.
- Écarts non corrigés, assumés : icônes inactives au trait (Regular) alors que la maquette bureau les montre pleines grises (arbitrage du manifeste §3.4) ; icône Historique `clock-counter-clockwise` (la maquette mobile montre une horloge simple) ; la maquette mobile est environ 1,4 fois plus dense qu'un vrai 390 dp (manifeste §3.2), la planche compare donc la structure, pas les tailles ; titres et contenu des pages (« Votre foyer », Mon compte) relèvent des lots C et E ; cloche sans point (aucune source, DB-CPT-04).

## 5. Écarts, décisions, demandes

1. **Délégations de STUB** (§0.3) : 6 écrans rendent l'existant ; au lot de remplacer le fichier. Les routes n'auront pas à changer.
2. **Accès refusé pour tous les rôles** : un rôle qui tape la route d'un autre voit `/acces-refuse` au lieu d'un renvoi muet ; `parcours_enseignant_test` et `test/agent/acces_agent_test.dart` (hors lots) mis à jour en conséquence. **[COORD/DIRECTEUR : confirmer]**
3. **Shell commun à tous les rôles** : la barre flottante, la colonne repliable et le rail replié à infobulles s'appliquent aussi à l'élève et à l'enseignant (même composant) ; destinations inchangées, testé. Sur tablette, l'enseignant voit désormais ses libellés en infobulle. **[DIRECTEUR : confirmer, captures des autres rôles à produire]**
4. `/bienvenue` existe mais le visiteur est encore renvoyé sur `/connexion` : la bascule suivra l'écran du lot A (sinon la porte d'entrée serait « indisponible »). `/inscription` garde son écran existant ; les 4 routes d'étape rendent un STUB. **Demande A** : à la livraison, COORD bascule G-PUB et `/inscription` ; la page de connexion peut lire `retour` pour dire « session expirée ».
5. `/tuteur/classes/:id/observer` ramène à la classe : la résolution de la séance en cours appartient à C et C-obs (`/tc/observation/:seanceId` inchangé).
6. `/tuteur/disponibilites` redirige vers le Foyer (code de `DisponibilitesPage` conservé, plus aucune route ne le monte) ; `/tuteur/reglages` reste servie jusqu'à la fiche B (C6).
7. **Demande E** : `journal_page.dart` et `observations_admin_page.dart` doivent poser `SousNavigationDomaine(onglets: ongletsSecurite())` ; d'ici là, `/admin/securite-audit/observations` n'a pas d'entrée d'interface (route atteignable par URL, testée). `ComptePage` et `ReglagesEnfantPage` poussent encore `/compte/*` (redirigé pour le tuteur) : à remplacer par `Routes.compteTuteurSousPage`.
8. **Demande C** : le lien « Mes groupes » de l'Accueil (`/tc/groupes`) ramène désormais le tuteur sur `/tuteur` ; le lien « Appareils du foyer » vise `Routes.tuteurFoyer` (sert `AppareilsPage` par délégation) : viser `Routes.tuteurFoyerAppareils` quand le Foyer sera livré. **Demande D** : idem pour le retour de `appairage_page.dart:97`.
9. Retour après connexion : perdu par le lien magique et Google, qui reviennent sur l'origine (DB-TRV-04) ; il ne survit qu'à une connexion sur la même page (mot de passe de démonstration) ou à un refresh.
10. Hors ligne : classification par type d'exception (`PostgrestException`/`TypeError` = refus, le reste = injoignable), plus un délai de 20 s (`AppDelais.requeteMax`, valeur proposée, non mesurée). `source_session_agent.dart` inchangé (garde « échouée »).
11. `EcranAConstruire` et les clés `aConstruire.*` ne sont plus utilisés : suppression sur accord seulement.
12. Au commit de la reprise 0a : retirer les 2 entrées de `_detteConnue` (K7), comme 0d et 0c1 l'ont écrit.
