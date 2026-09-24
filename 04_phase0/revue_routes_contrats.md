# Revue indépendante phase 0 : routeur, coquille, contrats, frontière de sécurité

Date : 24/09/2026, 13:40 à 14:10 (+03:00). Relecteur adversarial, **lecture seule** du dépôt.
Objet : worktree `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, HEAD `125fe78`, base `3cf3544` (24 commits).
Arbre de travail constaté identique avant et après la revue (`git status` : reprise 0a non commitée, `windows/flutter/*`).

## 0. Preuves produites (hors dépôt)

| # | Commande (sous `flutter-verrou.ps1`, dossier `D:\RA_TUTEUR\integration`) | Résultat |
|---|---|---|
| T1 | `flutter test --no-pub test/router test/agent/acces_agent_test.dart test/config/fixtures_isolees_test.dart` | `01:39 +283 -1`. Seul échec : K7 « dette résorbée » (`GroupesDemonstrationLocale`, `HorlogeSeanceDemonstration`), attendu **sur l'arbre de travail** qui porte la reprise 0a non commitée. Journal : `revue_routes_tests_routeur.log`. Couvre `etats_transverses_test` et `redirection_test`, non relancés par 0c2 après `97b9ddf`. |
| T2 | `flutter test --no-pub -r expanded <scratchpad>\revue_routes_sondes_test.dart` (sondes S1 à S7, fichier hors dépôt qui importe `test/router/support_routeur.dart` par URI) | `00:08 +12`, sorties `S1`..`S7` lues. Journal : `revue_routes_sondes.log` ; source : `revue_routes_sondes_test.dart.txt`. |
| G | `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc dart_define.example.json` | vide |

Réserve : T1 et T2 tournent sur l'arbre de travail (HEAD + reprise 0a non commitée), pas sur HEAD isolé. Aucun worktree n'a été créé, pour ne pas modifier le dépôt.

## 1. Défauts

### D1. BLOQUANT : HEAD sert encore des doubles en production ; reprises P8 absentes de HEAD

- Preuve : `git show HEAD:lib/core/tc_groupe/port_groupes.dart` l. 38 `(Ref ref) => GroupesDemonstrationLocale()` ; `git show HEAD:lib/core/tc_horloge/port_horloge_seance.dart` l. 55 `HorlogeSeanceDemonstration()`. La nouvelle route tuteur `/tuteur/classes/:classeId` monte `EspaceGroupePage` (`lib/features/classe_tuteur/classe_tuteur_page.dart:31`), qui lit `groupeProvider` et `horlogeGroupeProvider` (`espace_groupe_page.dart:133,173`), donc ces doubles. K7 ne passe sur HEAD que par l'exemption `_detteConnue` (`test/config/fixtures_isolees_test.dart:55-58`).
- Reprise `33503fe` : fichiers seulement dans l'arbre (`M port_groupes.dart`, `M port_horloge_seance.dart`, `?? groupes_supabase.dart`, `?? horloge_supabase.dart`, `?? groupes_supabase_test.dart`). Reprise `observation/lot-2026-09-21` : non appliquée hors les hunks K4 (`git diff HEAD observation/lot-2026-09-21` montre encore `port_annonce_observation.dart`, `accueil_famille_page.dart`, `salle_page.dart`, `entete_classe.dart`, `app_icons.dart`).
- Correction attendue : commiter l'étape 2 de 0a (8 fichiers, sans `windows/`), appliquer et commiter l'étape 3 (commit séparé, `git apply --3way` à cause des hunks K4 déjà présents), retirer les 2 entrées de `_detteConnue`, rejouer K7 et `test/router` **sur HEAD**. Tant que ce n'est pas fait, la phase 0 ne peut pas être déclarée conforme à « aucune fixture servie en production ».

### D2. MAJEUR : `OBSERVATION_TUTEUR_REELLE` n'est branché nulle part, et son forçage ne couvre pas les aperçus

- Non branché : `Env.observationTuteurReelleActive` (`lib/core/config/env.dart:63`) n'a **aucun** consommateur dans `lib/` ; seul le paramètre pur `activationReelle` existe (`disponibilite_observation.dart:131`), sans appelant. Pendant ce temps, `/tc/observation/:seanceId` reste ouvert au tuteur (`redirection.dart:288-291` ; sonde S6 : `guardian /tc/observation/s1 -> null`) et `EntreeObservationPage` appelle l'entrée réelle (`entree_observation_page.dart:384-385`). Préexistant à la base, mais P3 annonce « en production : bloc Observation avec motif pas encore ouverte ».
- Forçage en liste d'exclusion : `observationTuteurReelleSelon` = `demandee && environnement != 'production'` (`env.dart:69-72`). Les aperçus sont compilés avec `ENVIRONNEMENT=staging` et **les mêmes secrets Supabase de production** (`.github/workflows/flutter-deploy.yml:68-74, 128-130`). Sonde S5 : `staging -> true`, `Production -> true`. L'aperçu que regarde le directeur tape la base de production.
- Correction attendue : liste d'autorisation (`environnement == 'developpement'`, ou `Env.playgroundActif`) ; brancher dès maintenant l'interrupteur sur l'autorisation tuteur de `/tc/observation` (ou sur `EntreeObservationPage`), avec test.

### D3. MAJEUR : les autres rôles ne sont pas inchangés

- Libellés élève et enseignant réécrits par `981a0c6` : `assets/i18n/fr.i18n.json:1510` `enseignant.journee.coursEnCours` (lu par `journee_page.dart:427`), `:2054` `tc.classe.entete.coursEnCours` (`entete_classe.dart:32`), `:2154` `tc.classe.barre.titre` (`barre_cours_en_cours.dart:63`). Hors périmètre tuteur (`03` §3.7), hors espaces COORD (`00_OWNERSHIP` §4) ; 0c1 le signale « à confirmer », 0c2 ne le reprend pas.
- Redirection : une route d'un autre rôle mène désormais à `/acces-refuse` pour **tous** les rôles (`redirection.dart:186-189` ; sonde S6 : enseignant et élève sur `/tuteur` -> `/acces-refuse`), et les tests d'autres rôles ont été réécrits pour l'accepter (`test/router/parcours_enseignant_test.dart`, `test/agent/acces_agent_test.dart`).
- Coquille : sur tablette, l'enseignant perd ses libellés visibles (rail replié, infobulles seules ; diff de `parcours_enseignant_test.dart`). Aucune capture des autres rôles produite.
- Correction attendue : rétablir les 3 clés à leur valeur `3cf3544` ou obtenir la décision écrite du directeur ; idem pour l'accès refusé et le rail des autres rôles, avec captures enseignant et élève.

### D4. MAJEUR : tâche focalisée sans disque retour (`/tuteur/compte/preferences`)

- Preuve : `Routes.estTacheFocalisee` masque la barre basse sur `/tuteur/compte/preferences` (`routes.dart:273`), mais l'écran délégué `ReglagesComptePage` construit `PageShell` sans `onRetour` (`lib/features/compte/compte_page.dart:208`). Sonde S2 (390x844) : `barreBasse=0 disqueRetour=0 cloche=1` ; même état après la ligne « Réglages » du Compte (S2b). Seule sortie : la cloche, puis la page d'état des notifications. Contraire au manifeste §4.2 point 5 et à « aucune impasse ».
- Correction attendue : `onRetour` vers `/tuteur/compte` dans la délégation (`preferences_page.dart`), ou retirer `preferences` de `estTacheFocalisee` jusqu'au lot E ; test de widget.

### D5. MINEUR : un lien profond mal encodé plante le routeur

- Preuve : sondes S1 (`go('/tuteur/foyer/%E0%A4')`, `.../informations`, `/tuteur/classes/%C3`) : `FormatException: Unfinished UTF-8 octet sequence`, aucune `PageIntrouvable`. Sonde S7, démarrage à froid sur ce lien (`defaultRouteName`) : deux exceptions, **écran vide** (ni `PageIntrouvable`, ni `EcranDemarrage`, ni coquille) ; témoin `/tuteur/inconnue` : page introuvable correcte. Cause : `Uri.decodeComponent` de go_router 18.0.1 (`match.dart:207`), hors `errorBuilder`. Le test « lien profond inconnu ne fait pas planter » (`etats_transverses_test.dart:46-60`) ne couvre pas ce cas.
- Correction attendue : assainir l'adresse avant `GoRouter` (analyseur d'information de route enveloppé qui rattrape `FormatException` et sert l'introuvable), plus un test.

### D6. MINEUR : le retour après connexion peut viser `/acces-refuse`

- Preuve : `_reprise` (`redirection.dart:195-216`) n'exclut que racine, connexion, inscription et attente. Sonde S4 : `retour=/acces-refuse -> /acces-refuse` : l'utilisateur qui se reconnecte atterrit sur « Accès refusé ».
- Correction attendue : exclure `Routes.accesRefuse` (et `horsLigne`) dans `_reprise`, test.

### D7. MINEUR : Compte délégué empile le Foyer dans la branche Compte

- Preuve : `ComptePage` pousse `/compte/profils` (`compte_page.dart:72`), redirigé vers `/tuteur/foyer`. Sonde S3b : `FoyerPage` affichée avec `indexActif=3` (Compte actif). La ligne « Foyer » (`compte_page.dart:79`, push direct) donne bien `indexActif=1` (S3).
- Correction attendue : `go(Routes.tuteurFoyer)` au lieu de `push('/compte/profils')` pour le tuteur (demande E déjà émise en 0c2 §5.7, sans cette conséquence).

### D8. MINEUR : `observer` et « Rejoindre » ne font pas ce que disent les commentaires

- `/tuteur/classes/:classeId/observer` ramène à la classe, « qui porte le bloc d'observation » (`app_router.dart:376-386`), mais la classe déléguée n'en a aucun (0 occurrence de « observ » dans `lib/features/tc_espace_groupe`) : la ligne 31 de l'arbre n'a aucune entrée, sans marque STUB.
- `ClasseTuteurPage` se dit « sans Rejoindre » (`classe_tuteur_page.dart` commentaire), mais `CarteSession` rend encore `ActionPrincipale(Rejoindre, onPress: null)` quand la fenêtre est ouverte (`carte_session.dart:58-62`). Lecture de code, non capturé.
- Correction attendue : marquer l'alias comme STUB (lot C-obs) et masquer « Rejoindre » pour `RoleEspaceGroupe.tuteur`.

### D9. MINEUR : angle mort de K7

- Preuve : `portCatalogueProvider` sert `CatalogueLocal()` vide et `VersionsLocales()` en production (`lib/core/tc_bibliotheque/donnees_catalogue.dart:32-34, 38`) : « liste vide trompeuse » interdite par les principes de `00_CONTRATS_PARTAGES`, atteignable par le tuteur (`/tc/bibliotheque`, `redirection.dart:278-280`). Le détecteur ne cherche que `Faux*|*Demonstration*|*Memoire` (`fixtures_isolees_test.dart:21-23`). Préexistant.
- Correction attendue : ajouter `*Local*` au détecteur avec exemption nominative ou implémentation `Indisponible` (lot C).

### D10. MINEUR : constante métier dans K3

- `BornesAge.clientActuelle = BornesAge(min: 3, max: 18)` (`lib/core/foyer/profil_eleve_brouillon.dart:59`, défaut de `port_creation_profil_eleve.dart:101`). Conforme au texte de K3, contraire au principe « aucune constante métier » ; 0d le signale. Décision à consigner.

## 2. Vérifié conforme

- **Arbre §4** : les 42 lignes ont une route ou un état interne justifié (lignes 23-24 : moments internes de `/connexion/eleve` ; ligne 6 : répartie par porte ; ligne 31 : alias, voir D8 ; ligne 42 : `errorBuilder`, `/acces-refuse`, `/hors-ligne`, `retour`). Compléments C2, C4, C5, C6, C7, C9 présents.
- **38 STUB** tous marqués `// STUB PHASE 0` (39 fichiers avec `page_etat.dart`), tous montés par `app_router.dart` ; les 6 délégations sont déclarées dans 0c2 §0.3.
- **Alias** : `/tuteur/accueil`, `/tuteur/historique(/observations)`, `ajouter-enfant` (requête gardée), `disponibilites`, `:eleveId/appareils/connexion`, `/compte*` et `/tc/groupes*` du seul tuteur ; déclarés avant la coquille, précédés de la garde de rôle.
- **Préfixe** : `prefixePour(guardian) = /tuteur`, toutes les routes tuteur sous `/tuteur` ; rien sous `/appareil*` (test R1).
- **Public** : `Routes.publiques` = connexion (dont `eleve/scanner`, `eleve/code`, `recuperation`), bienvenue, agent ; compte actif renvoyé à sa racine depuis ces sous-arbres.
- **`cheminRetourValide`** (`chemin_retour.dart`) refuse schéma, hôte, `//`, antislash, fragment, contrôle, `.`/`..`/vide, `%2F`, encodage invalide, `/salle`, `/tc/classe`, `/agent` en toute casse ; `retour=https%3A%2F%2F...` ignoré (test).
- **Aucun secret en URL** dans les routes ajoutées (`?eleve=`, `?pour=moi`, `retour` validé) ; le jeton `/agent?jeton=` est préexistant (ADR-025).
- **404 et identifiants inconnus** : page d'état sans données, pour toutes les portes (T1), hors D5.
- **Coquille** : une seule liste `destinationsPour(guardian)` (Accueil, Foyer, Historique, Compte) alimente barre, rail et barre latérale ; `secondairesPour` vide ; destinations élève et enseignant identiques à `3cf3544` (hors D3).
- **K6** : les 12 providers de `lib/core/capacites/` servent une implémentation `…Indisponible`. **K2/K3/K4** : aucun `catch` qui rend une fixture dans le code neuf (`port_creation_profil_eleve.dart:169-171` rend `CreationIncertaine`, `port_seances_famille.dart:266` ne choisit qu'une ligne). `defautsNormatifs` non appelé dans `lib/`.
- **Textes signés** : `salle.bandeauPermanent`, `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse` identiques à `3cf3544` sur HEAD et dans l'arbre ; aucune migration dans le diff.
- **Frontière backend** : diff vide (G).
