# 0d - Contrats K1 a K7 (phase 0, coordinateur)

Date : 24/09/2026, 07:29 a 09:20 (+03:00). Worktree : `D:\RA_TUTEUR\p0d`, branche `ui/tuteur-v1-p0d`, creee par `git worktree add -b ui/tuteur-v1-p0d D:\RA_TUTEUR\p0d HEAD` depuis `D:\RA_TUTEUR\integration`.
Statut global : **7 commits locaux, un par contrat, analyse ciblee et tests cibles verts. Aucun push, aucune fusion dans `ui/tuteur-v1`.**

## 0. Base reelle de la branche (a lire en premier)

- Au moment de la creation (07:29), `ui/tuteur-v1` pointait sur **`3cf3544`** : les reprises 0a (`33503fe`, branche observation) n'etaient **pas commitees** (rapport `0a_base.md`, « INTERROMPU a l'etape 2 »). `ui/tuteur-v1-p0d` part donc de `3cf3544`, sans `GroupesSupabase` ni `HorlogeSeanceSupabase`.
- A 09:19, `ui/tuteur-v1` porte 5 commits de 0b (`fce058b` a `1d411b7`), toujours sans 0a. Fusion simulee `git merge-tree --write-tree ui/tuteur-v1 ui/tuteur-v1-p0d` : **aucun conflit** (code 0, arbre `68fe93e`). Aucun objet ni ref modifie cote integration.
- Consequences pour K2 et K6 : horloge serveur non branchee, classes du foyer indisponibles (DB-TRV-07), et adaptateur `horloge_supabase.dart` **non corrige** (le fichier n'existe pas sur cette base). Voir section 4.

## 1. Commits (branche `ui/tuteur-v1-p0d`, 49 fichiers, +5525 / -56)

| Contrat | Commit | Contenu |
|---|---|---|
| K5 | `fc3b28a` | `lib/core/capacites/capacite_indisponible.dart`, `lib/core/theme/app_delais.dart` (8 s / 20 s, valeurs proposees, non mesurees), `lib/core/router/chemin_retour.dart` (`cheminRetourValide`, fichier neuf ; `app_router.dart` et `redirection.dart` intacts) ; tests `test/router/chemin_retour_test.dart`, `test/capacites/capacite_indisponible_test.dart` |
| K1 | `dd7b3b8` | `lib/core/foyer/selection_eleve.dart` (`ProfilEleveFoyer`, `NatureProfilEleve`, `profilsElevesFoyerProvider`, `SelectionEleveControleur`, `selectionEleveProvider`, `profilRetenu`, `eleveSelectionneProvider`) ; `test/fixtures/tuteur/foyers.dart` (deux foyers fictifs) ; `test/foyer/selection_eleve_test.dart` |
| K2 | `03b95e8` | `lib/core/seance_famille/seance_famille.dart` (`EtatSeanceFamille`, `EnseignantSeance`, `SeanceFamille`, `etatSeanceFamille`, `restantAvant`) ; `lib/core/seance_famille/port_seances_famille.dart` (`PortSeancesFamille`, `SeanceIntrouvable`, `seanceFamilleDepuis`, `avecHorlogeServeur`, `prochaineParmi`, `derniereParmi`, adaptateur `SeancesFamilleDepuisPlanning`, `portSeancesFamilleProvider`, `prochaineSeanceProvider`, `derniereSeanceProvider`) ; **correction** `lib/core/planning/service_planning.dart` (`Seance.depuisJson` strict, `Seance.lire`, `seances()` ecarte la ligne illisible) ; `test/fixtures/tuteur/faux_seances_famille.dart` ; `test/seance_famille/seance_famille_test.dart` ; `test/planning/seance_illisible_test.dart` |
| K3 | `fe625aa` | `lib/core/foyer/profil_eleve_brouillon.dart` (`PourQui`, `ChampProfilEleve`, `ErreurChamp`, `BornesAge`, `BrouillonProfilEleve.valider`) ; `lib/core/foyer/port_creation_profil_eleve.dart` (resultats scelles, `MotifRefusCreation`, `resultatDepuisRefus`, adaptateur `CreationProfilEleveAppairage`, `portCreationProfilEleveProvider`) ; `test/fixtures/tuteur/faux_creation_profil_eleve.dart` ; `test/foyer/creation_profil_eleve_test.dart`. Pas de widget (lot B). |
| K4 | `1644546` | `guardian_observation_policy.dart` (**memes hunks** que `observation/lot-2026-09-21` : 2 / 240 s / 120 s) ; `guardian_session_visit.dart` (`GuardianSessionVisit.lire` strict) ; `echec_observation.dart` (+`visiteDejaOuverte`) ; `port_politique_observation.dart` (23505 -> `visiteDejaOuverte`, `BudgetObservation.visiteEnCours`, commentaires perimes corriges) ; `port_visite_observation.dart` (commentaires perimes corriges) ; **nouveaux** `disponibilite_observation.dart` (`MotifIndisponibilite`, `DisponibiliteObservation`, `disponibiliteObservation`, `motifDepuisRefus`, `motifDepuisEchec`, `CompteurVisite`) et `port_historique_observations.dart` (`ObservationsSeance`, `grouperObservations`, ports tuteur et admin, implementations indisponibles `LOT-E`, providers) ; `lib/core/config/env.dart` (`OBSERVATION_TUTEUR_REELLE`) ; tests : memes hunks de la branche observation pour `politique_observation_test`, `etat_reglages_observation_test`, `q03_quota_observation_tuteur_test` et le dernier hunk de `ecrans_observation_test` ; `test/fixtures/tuteur/faux_observation.dart` ; `test/tc_observation/observation_contrat_test.dart` |
| K6 | `649cb47` | Douze ports `lib/core/capacites/port_{classes_foyer,catalogue_classes,progression_famille,resume_seance_famille,identite_titulaire,acces_foyer,paiements_foyer,notifications,support,consentements,profil_eleve_titulaire,preferences_persistantes}.dart`, chacun avec son implementation « Indisponible » et son provider de production ; `test/fixtures/tuteur/{faux_classes_foyer,faux_identite_titulaire,faux_capacites}.dart` ; `test/capacites/ports_capacites_test.dart` |
| K7 | `bb7f094` | `test/config/fixtures_isolees_test.dart` (controle lexical des providers de `lib/`) |

Aucune modification de `assets/i18n`, de fichier genere, de `lib/core/theme/**` (hors `app_delais.dart`), `assets/fonts`, `pubspec.yaml`, `lib/app.dart`, `lib/core/preferences/**`, `pin_pad`/`avatar_tile`/`action_principale`, `tool/**`, `test/theme/**`, `app_router.dart`, `redirection.dart`.

## 2. Commandes lancees et resultats exacts

Toutes les commandes Flutter/Dart sous `flutter-verrou.ps1`, dossier `D:\RA_TUTEUR\p0d`.

| # | Commande | Resultat exact | Statut |
|---|---|---|---|
| 1 | `git worktree add -b ui/tuteur-v1-p0d D:\RA_TUTEUR\p0d HEAD` | `HEAD is now at 3cf3544` | PASS |
| 2 | copie de `dart_define.json` (contenu non affiche) | `Test-Path` : `True` | PASS |
| 3 | `flutter pub get` | `Got dependencies!`, code 0, 19 s. Effet de bord : `windows/flutter/generated_plugin_registrant.{cc,h}`, `generated_plugins.cmake` (fins de ligne), **non commites** | PASS |
| 4 | `dart analyze --fatal-infos` K5 | `No issues found!`, 172 s | PASS |
| 5 | `flutter test` K5 (1er passage) | `+6 -1 Some tests failed` : `/tuteur/./foyer` accepte (`Uri.parse` retire les `.` avant `pathSegments`). Corrige : segments lus sur la chaine brute. | FAIL puis corrige |
| 6 | `dart format --output=none --set-exit-if-changed` sur fichiers existants + `dart format` fichiers neufs | `service_planning.dart`, `service_appairage.dart`, `env.dart`, `guardian_session_visit.dart`, `echec_observation.dart` propres ; **4 fichiers `tc_observation` deja non formates a la base** (`guardian_observation_policy`, `moteur_visite_observation`, `port_politique_observation`, `port_visite_observation`) : non reformates, editions faites a la main | information |
| 7 | `dart analyze --fatal-infos` K1, K2, K5, planning, suivi, controle | 4 infos `prefer_initializing_formals` (`port_seances_famille.dart:238-241`) ; corrige | FAIL puis corrige |
| 8 | `flutter test --no-pub test/router/chemin_retour_test.dart test/capacites test/foyer test/seance_famille test/planning` | `01:10 +63: All tests passed!`, 111 s | PASS |
| 9 | `dart analyze --fatal-infos` K2 a K4 + `tc_observation_ui`, `admin_groupes`, `planning`, `config` + tests `g`, `q`, admin | 2 erreurs `assignment_to_final_local` (`port_creation_profil_eleve.dart:163,166`) ; corrige ; relance : `No issues found!`, 34 s | PASS apres correction |
| 10 | `flutter test --no-pub test/foyer test/seance_famille test/tc_observation test/planning test/config test/teaching_core/g test/teaching_core/q test/features/observation_groupe_admin_test.dart` | `02:39 +291: All tests passed!`, 192 s. Journal : `0d_tests_k2k4.log` | PASS |
| 11 | `dart format` K6, K7 puis `dart analyze --fatal-infos lib/core/capacites lib/core/foyer lib/core/seance_famille lib/core/tc_observation lib/core/config lib/core/router/chemin_retour.dart lib/core/theme/app_delais.dart test/capacites test/fixtures test/config test/foyer test/seance_famille test/tc_observation test/router/chemin_retour_test.dart` | `No issues found!`, 85 s | PASS |
| 12 | `flutter test --no-pub test/capacites test/config test/router/chemin_retour_test.dart` | `00:24 +47: All tests passed!`, 46 s. Journal : `0d_tests_k6k7.log` | PASS |
| 13 | `dart run tool/verifier_jetons.dart` | `Jetons verifies : 364 fichiers, aucune violation.`, code 0, 34 s | PASS |
| 14 | Non-regression : `flutter test --no-pub test/teaching_core/e test/suivi test/controle` + `accueil_famille`, `suivi_foyer`, `suivi_eleve`, `planning_controleur`, `journee`, `fiche_groupe`, `reglages_enfant`, `accueil_eleve`, `widgets/composants`, `router/parcours_enseignant` | `02:55 +299: All tests passed!`, 204 s. Journal : `0d_tests_nonreg.log` | PASS |
| 15 | `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc dart_define.example.json` | vide | PASS |
| 16 | `git merge-tree --write-tree ui/tuteur-v1 ui/tuteur-v1-p0d` (09:19) | code 0, aucun conflit | PASS |

**Non executes** : `dart analyze` complet et suite complete (reserves au coordinateur) ; `dart run slang` et `build_runner` (sans objet : aucune cle i18n ni source generee touchee) ; `flutter build web`.

## 3. Ce que chaque contrat garantit (teste en simulation)

- **K5** : `cheminRetourValide` refuse URL absolue, `//`, antislash, fragment, caractere de controle, segments `.`, `..`, vides, `%2F`, encodage invalide, `/salle`, `/tc/classe`, `/agent` (toute casse, tout encodage), chaine > 1024. `CapaciteIndisponible(dependance)` : `DB-xxx` (registre backend) ou `LOT-x` (source existante, adaptateur du lot x).
- **K1** : repli sur le premier profil, id inconnu (y compris d'un autre foyer) ignore, foyer vide = `AsyncData(null)`, aucune valeur residuelle entre deux eleves (famille par `eleveId`, test avec lectures differees).
- **K2** : table de verite (avant fenetre, T-20 exact, fenetre prise sur `joinOpensAtUtc` et non sur la duree courante, debut, en direct, prolongee y compris apres la grace si le serveur dit `in_progress`, fin + grace, terminee, annulee, annulee tardive, non tenue x3, horloge absente, statut qui tranche sans horloge, `reportee` jamais produit, aucun restant negatif sur un balayage de 5 h, changement d'heure du 25/10/2026 : 12 h UTC et non 11 h murales). Adaptateur : annulation a venir = prochaine seance, `in_progress` prime, derniere seance passee, deux enfants d'une meme seance departages, planning `DB-CRS-03`, suivre et `SeanceIntrouvable`.
- **K3** : validation (requis dans l'ordre, espaces, bornes incluses, `sansAge`), `peutCreer` (enfant ou mineur ET porte `actif`), creation nettoyee + relecture du foyer, refus 4xx nommes sans relecture, statut 0 / 500 / 504 / autre erreur = `CreationIncertaine` + relecture, double soumission = meme futur, un seul envoi.
- **K4** : defauts normatifs 2 / 120 s / 240 s ; aucun appel `defautsNormatifs` dans `lib/` hors sa definition (test lexical) ; interrupteur faux par defaut et force a faux pour `ENVIRONNEMENT=production` ; disponibilite (activation coupee avec visites restantes, deux puis une visite, epuisees, temps, visite ouverte, seance a venir / terminee / sans lieu, horaire incertain non bloquant, budget absent, classe fermee, presence non confirmee = verification et jamais `enfantAbsent`) ; 23505 non reessayable ; compteur « Visite 1/2 » jamais allonge par une horloge qui recule ; historique groupe par (seance, enfant), ligne incomplete ecartee, duree non confirmee si une visite est ouverte ; ports historique `LOT-E`.
- **K6** : 22 appels de production verifies un par un (identifiant attendu, format `DB-xxx-nn` ou `LOT-x`), `etatAccesAffiche` (une echeance passee ou egale = expiree), destination de notification validee.
- **K7** : detecteur verifie sur pieges (3 releves attendus, branche Playground et fonction hors provider ignorees) ; sur `lib/`, 4 releves, tous exemptes nominativement (voir 4.3).

## 4. Ecarts, points ouverts et demandes

### 4.1 Consequences de la base sans 0a (a traiter par le coordinateur apres commit de 0a)

1. **Brancher l'horloge serveur dans K2** : dans `portSeancesFamilleProvider` (`port_seances_famille.dart`, fin de fichier), passer `lireMaintenantServeur` et `lireHorloge` a `HorlogeSeanceSupabase` repris de `33503fe` (jamais `HorlogeSeanceDemonstration`). Tant que ce n'est pas fait : `maintenantServeurUtc()` leve `DB-TRV-07`, toute seance dont le statut ne tranche pas est `horaireIncertain`.
2. **Adaptateur d'horloge `horloge_supabase.dart` non corrige** (absent de cette base). Ma lecture confirme les defauts de `C06` : `horlogeDepuisLigne` reconstruit la fenetre depuis `fenetre_minutes` au lieu de `join_opens_at_utc`, et `?? 0` sur fenetre et grace ; jours et mois en dur sans accents. K2 est deja protege : `avecHorlogeServeur` deduit la fenetre de `joinOpensAtUtc` du `SessionClockVM`, et l'adaptateur doit donc poser `joinOpensAtUtc` depuis `join_opens_at_utc`.
3. **Ordre d'integration avec la branche observation** : K4 contient a l'identique 5 hunks du patch `obs_front.patch` (politique + 4 tests). Si ce patch est applique par `git apply` **apres** la fusion de `ui/tuteur-v1-p0d`, ces hunks seront refuses comme deja appliques. Proposition : appliquer et commiter l'etape 3 de 0a **avant** de fusionner p0d (la fusion a trois voies accepte des changements identiques), ou utiliser `git apply --3way`.
4. **K7 va echouer volontairement apres la reprise de `33503fe`** : `test/config/fixtures_isolees_test.dart` tient une « dette connue » (`GroupesDemonstrationLocale` dans `port_groupes.dart`, `HorlogeSeanceDemonstration` dans `port_horloge_seance.dart`). Une fois ces doubles places derriere `Env.playgroundActif`, le test « chaque exemption nominative correspond encore a un releve » echoue avec « dette resorbee ... : retirer l entree » : retirer les deux lignes de `_detteConnue`.
5. **K6 `PortClassesFoyer`** reste indisponible (`DB-TRV-07`) meme apres 0a tant que le lot C n'a pas ecrit `classes_foyer_supabase.dart`.

### 4.2 Ecarts au texte du contrat (`00_CONTRATS_PARTAGES.md`), a valider

- K2 : `etatSeanceFamille` et `restantAvant` prennent `DateTime? maintenantServeurUtc` (`null` = pas d'horloge serveur, d'ou `horaireIncertain`) ; `seance()` et `suivre()` acceptent un `eleveId` facultatif (une ligne par couple seance-eleve) ; exception `SeanceIntrouvable` ajoutee ; `in_progress` avant la fenetre rend `salleOuverte`.
- K2 : l'adaptateur choisit la prochaine et la derniere seance avec l'horloge serveur si elle repond, **sinon avec l'horloge de l'appareil** (choix de ligne seulement, jamais un etat affiche). Une annulation a venir reste « la prochaine » (differe de `prochainCours()` de `journee.dart`, qui l'ecarte). Historique sans horloge par ligne (commentaire `ponytail:` avec plafond).
- K1 : `profilsElevesFoyerProvider` **trie par prenom puis identifiant** : la vue `profils_du_foyer_v` n'a pas d'`order by` et `eleves()` n'en pose pas ; l'ordre « rendu par la vue » n'est pas stable.
- K3 : `BornesAge.clientActuelle` (3-18) **est une constante metier** : c'est la borne deja en production (`ajouter_enfant_page.dart:44`) reprise pour qu'A et B n'en ecrivent pas deux ; la borne serveur (3-99) fait foi. **[A confirmer, la consigne dit « aucune constante metier ».]**
- K3 : `ProfilCree.eleveId` reste `null` : l'Edge `creer-profil-enfant` **rend pourtant `profile_id`**, mais `ServiceAppairage.creerEnfant` rend `void`. Demande : faire rendre l'identifiant (modifie aussi `FauxServiceAppairage` de `harnais.dart` et de `features/_dev/playground/faux.dart`).
- K4 : `MotifIndisponibilite` gagne `seanceNonTenue` (annulee, reportee, non tenue : « terminee » serait faux) et `horsFenetre` (refus serveur `hors_fenetre` / `seance_non_active`, trop tot ou trop tard non distingues) ; `disponibiliteObservation` prend un `etatSeance` facultatif (K2) ; `CompteurVisite.depuis(VueBudgetObservation)` ; `ObservationsSeance` vit dans `port_historique_observations.dart` avec `grouperObservations`.
- K4 : `GuardianSessionVisit.depuisJson` garde ses replis (1970, role tuteur) pour ne pas casser le moteur de visite ; l'historique passe par le nouveau `GuardianSessionVisit.lire` strict.
- K6 : convention d'identifiant `LOT-x` ajoutee (identite, acces, historique : `LOT-E` ; consentements signes : `LOT-A`). `PortTravailFamille` **non cree** (`PortAssignations` et `PortTravailAVenir` existent, un seul lot consommateur). Formes provisoires : `ClasseOuverte`, `ResultatInscription`, `ProgressionEleve`, `PaiementFoyer` (dont `statutServeur` en texte brut, jamais affiche). `AccesBeneficiaire.statutServeur` et `motif` : toujours `null` (DB-FOY-05).

### 4.3 Effets sur d'autres lots (a transmettre)

- **E et controle** : `Seance.depuisJson` leve desormais `FormatException` sur une borne illisible au lieu de fabriquer `DateTime.now()`. `service_suivi.dart` (E) et `service_controle.dart` (lecture seule) l'appellent encore : une ligne malformee ferait echouer la lecture entiere. Theorique (`sessions.started_at` et `ended_at` sont `not null`, `0001:166-167`) ; recommandation au lot E : `lignes.map(Seance.lire).nonNulls`.
- **C-obs** : une visite deja ouverte (23505) n'est plus une « panne reseau » reessayable mais `MotifEchecObservation.visiteDejaOuverte` (`seReessaye` faux). `entree_observation_page.dart` l'affiche aujourd'hui avec le message generique non-capacite : texte dedie a prevoir (`tc.observation.*`). Commentaires faux restants dans des fichiers C-obs : `moteur_visite_observation.dart:251-253` et `entree_observation_page.dart:118-122` (« le serveur referme l'intervalle a l'expiration du jeton »).
- **Exemptions K7 permanentes** : `PositionDockMemoire` (`etat_outils.dart`) et `EtatPartageMemoire` (`providers_tc_etat_partage.dart`), memoires legitimes et non des fixtures ; a revoir si le directeur juge autrement.
- **0b** : `port_preferences_persistantes.dart` et `faux_capacites.dart` importent `PreferencesLocales` (fichier de 0b). API verifiee compatible avec `ui/tuteur-v1` a 09:19 (constructeur `const`, `theme`, `PreferenceTheme.sombre`).

### 4.4 Interrupteur `OBSERVATION_TUTEUR_REELLE`

`Env.observationTuteurReelle` (`bool.fromEnvironment`, faux par defaut) et `Env.observationTuteurReelleActive` = demande ET `ENVIRONNEMENT != production` : **le forcage vit dans le code**, une compilation de production qui passerait `true` n'ouvre rien. Non fait (fichiers interdits) : ajout de `--dart-define=OBSERVATION_TUTEUR_REELLE=false` dans `.github/workflows/flutter-deploy.yml` et documentation dans `dart_define.example.json`. **Demande au directeur ou au coordinateur hors branche UI.**

### 4.5 Rien de plus que ce qui est ecrit

- Tous les resultats ci-dessus sont « testes en simulation » (doubles, horloge figee) ou « analyses » ; **rien n'est verifie reellement** contre Supabase, et aucune requete n'a ete faite vers la base.
- Arbre de travail laisse : propre hormis les 3 fichiers `windows/flutter/*` modifies par `pub get` (fins de ligne), non commites.
