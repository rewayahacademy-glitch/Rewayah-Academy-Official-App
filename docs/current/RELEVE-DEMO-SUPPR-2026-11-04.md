# Relevé DEMO-SUPPR, étape P (04/11/2026)

Décision du directeur, 04/11/2026 : « Supprime la demo ». Lot confié à C1 par le pilote le 04/11/2026,
découpé en trois étapes, une PR chacune : **P** (ce relevé, documentation seule), **D** (les doublures
de test qui servent ailleurs passent dans `test/support`), **R** (retrait de `lib/features/demo`, de
la route `/demo` et de « Essayer la démonstration »). Relevé fait sur `main` `efb00a726`.

## Ce qui est faux ou plus gros que prévu, d'abord

1. **La démo sert de banc d'essai à 430 fichiers de test hors de `test/features/demo`**, dont 79
   fichiers de capture. Au total, 449 fichiers de test importent `lib/features/demo`. Les 19 de
   `test/features/demo` partent avec elle ; les 430 autres non. L'étape D est donc **beaucoup plus
   grosse que « déplacer quelques doublures »** :
   - 74 tests lisent `seance_demo.dart` et 41 `adulte_demo.dart`, des données de séance et d'élève
     adulte qui servent de jeux d'essai à des écrans réels ;
   - 49 tests montent l'écran réel de la salle **à travers `demo_salle_page.dart`**, et de même 44
     pour `demo_adulte_page.dart`, 30 pour `demo_enseignant_page.dart` et 29 pour
     `demo_controleur_page.dart`. Ces pages câblent les surcharges que l'écran réel attend. Les
     retirer impose de déplacer ce câblage dans `test/support` (un harnais par rôle), sinon ces
     tests tombent.

   Le lot n'est pas « S ». Je propose de couper D en deux (voir « Ordre proposé »).
2. **La connexion par mot de passe du banc local (`tool/e2e`, `AUTH_PAR_MOT_DE_PASSE=true`) n'est pas
   dans `lib/features/demo`.** Elle vit dans `lib/core/session/session_controleur.dart`
   (`demoAuthActiveProvider`, `accesDemoDepuisCourriel`). Le retrait la garde : sans elle, aucun robot
   E2E ne se connecte. Seul `environnementAutoriseDemo`, qui garde aussi `/demo/*`, est à réécrire là
   où la connexion le lit.
3. **Treize fichiers « démo » vivent hors de `lib/features/demo`** et sont hors de ce périmètre
   (tableau plus bas). Cinq sont l'implémentation **par défaut d'un port réel** : pause de séance,
   offres de la direction, groupes `/tc/groupes`, partage pédagogique, horloge de séance. Les retirer
   changerait le comportement d'écrans réels ; c'est un autre lot, à décider.
4. **En production, la démo n'était déjà pas compilée** (`Env.demoCompilee`, constante ; mesuré par
   DEMO-PROD #230). Le retrait allège les constructions de staging et de développement, et le dépôt :
   60 fichiers, 28408 lignes. Il ne change rien à ce que reçoit une famille.

## Qui importe la démo dans `lib/` (hors `lib/features/demo`)

| Fichier | Ce qu'il lit | Au retrait |
| :--- | :--- | :--- |
| `lib/core/router/app_router.dart` | les 9 pages `/demo/*` | les routes partent avec la garde `Env.demoCompilee` |
| `lib/core/router/routes.dart` | les 9 chemins `Routes.demo*` | partent |
| `lib/core/router/redirection.dart` | `environnementAutoriseDemo` (accès sans session à `/demo/salle`, `/demo/classe`…) | la branche part |
| `lib/main.dart` | `?demo=tuteur` et `?demo=admin` (`surchargesDemoTuteur`, `surchargesDemoAdmin`, `dossiers_demo`, `RepereDemonstration`), `RacineDemonstrable` | `runApp(RacineReelle(...))` partout |
| `lib/features/connexion/connexion_page.dart` | `EntreeDemonstration` (« Essayer la démonstration »), `environnementAutoriseDemo` | l'entrée part ; la garde du mot de passe lit `Env` directement |

## Par fichier de `lib/features/demo`

« Tests hors `test/features/demo` » compte les fichiers de test qui l'importent ailleurs.
La liste nominative est dans `RELEVE-DEMO-SUPPR-2026-11-04-importeurs.txt`.

| Fichier | Lignes | Importé hors démo (lib) | Tests hors `test/features/demo` | Verdict |
| :--- | ---: | :--- | ---: | :--- |
| `accessibilite_demo.dart` | 197 | — | 34 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `admin_x_demo.dart` | 148 | — | 0 | Part (R) |
| `adulte_demo.dart` | 927 | — | 41 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `alertes_demo.dart` | 96 | — | 2 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `bibliotheque_admin_demo.dart` | 847 | — | 10 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `cartes_classe_demo.dart` | 121 | — | 8 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `catalogue_demo.dart` | 89 | — | 0 | Part (R) |
| `classe_demo.dart` | 344 | — | 30 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `classe_form_demo.dart` | 200 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `classes_admin_demo.dart` | 241 | — | 3 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `classes_disponibles_demo.dart` | 314 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `communications/com_annonces_demo.dart` | 1267 | — | 10 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `communications/com_communaute_demo.dart` | 757 | — | 15 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `communications/com_messages_demo.dart` | 840 | — | 15 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `communications/com_studio_demo.dart` | 1101 | — | 18 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `communications/com_vocal_demo.dart` | 481 | — | 10 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `communications/demo_communications_page.dart` | 198 | `core/router/app_router.dart` | 27 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `comptable/aujourdhui_demo.dart` | 275 | — | 2 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/beneficiaires_demo.dart` | 610 | — | 8 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/contractuels_demo.dart` | 480 | — | 4 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/direction_demo.dart` | 400 | — | 4 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/encaissements_demo.dart` | 632 | — | 7 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/paiements_demo.dart` | 889 | — | 7 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/series_demo.dart` | 106 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/socle_comptable_demo.dart` | 224 | — | 12 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/tresorerie_demo.dart` | 260 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `comptable/validations_demo.dart` | 426 | — | 5 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `controleur_demo.dart` | 510 | — | 24 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `coran_demo_accessibilite.dart` | 74 | — | 0 | Part (R) |
| `coran_demo_adulte.dart` | 52 | — | 2 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `demo_accessibilite_page.dart` | 585 | `core/router/app_router.dart` | 28 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_adulte_page.dart` | 1899 | `core/router/app_router.dart` | 44 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_classe_page.dart` | 660 | `core/router/app_router.dart` | 22 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_comptable_page.dart` | 422 | `core/router/app_router.dart` | 16 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_controleur_page.dart` | 787 | `core/router/app_router.dart` | 29 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_enseignant_page.dart` | 593 | `core/router/app_router.dart` | 30 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_finance_page.dart` | 146 | `core/router/app_router.dart` | 11 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `demo_salle_page.dart` | 1031 | `core/router/app_router.dart` | 49 | Part (R), avec sa route `/demo/…` ; tests à réécrire sur l’écran réel (D) |
| `dossiers_demo.dart` | 819 | `main.dart` | 18 | Part (R) : seule la démonstration `?demo=tuteur` de `main.dart` le lit ; doublures à garder pour les tests (D) |
| `enseignant_demo.dart` | 642 | — | 35 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `espaces_controleur_demo.dart` | 284 | — | 3 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `finance_demo.dart` | 1985 | — | 21 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `fusion_demo.dart` | 342 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `historique_controleur_demo.dart` | 136 | — | 2 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `mode_demonstration.dart` | 916 | `main.dart`, `core/router/redirection.dart`, `features/connexion/connexion_page.dart` | 70 | Part (R). `environnementAutoriseDemo` quitte `redirection.dart` et la connexion avec les routes. La connexion par mot de passe du banc local reste : elle vit dans `core/session` (`demoAuthActiveProvider`), pas ici |
| `observation_demo.dart` | 155 | — | 0 | Part (R) |
| `pilotage_demo.dart` | 208 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `planning_incidents_demo.dart` | 113 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `presence_demo.dart` | 35 | — | 0 | Part (R) |
| `racine_demonstrable.dart` | 119 | `main.dart`, `features/connexion/connexion_page.dart` | 2 | Part (R) : `main.dart` lance `RacineReelle` partout ; « Essayer la démonstration » quitte la connexion |
| `recrutement_demo.dart` | 250 | — | 7 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `regroupements_demo.dart` | 332 | — | 4 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `remplacements_demo.dart` | 197 | — | 1 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `repere_demonstration.dart` | 112 | `main.dart` | 45 | Part (R) ; tests à revoir (D) |
| `salle_controleur_demo.dart` | 224 | — | 3 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `salle_observateur_demo.dart` | 170 | — | 6 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `seance_demo.dart` | 919 | — | 74 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `services_admin_demo.dart` | 167 | — | 4 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `suivi_demandes_demo.dart` | 668 | — | 6 | Doublure de test : passe dans `test/support` (D), le reste part (R) |
| `tirage_demo.dart` | 386 | — | 2 | Doublure de test : passe dans `test/support` (D), le reste part (R) |

## Hors périmètre : les fichiers « démo » hors de `lib/features/demo`

| Fichier | Lu par | Statut |
| :--- | :--- | :--- |
| `core/pause_seance/pause_seance_demonstration.dart` | `port_pause_seance.dart` (défaut du port) | port réel : autre lot |
| `core/offres/offres_admin_demo.dart` | `port_offres_admin.dart` (défaut du port) | port réel : autre lot |
| `core/tc_groupe/demonstration_groupes.dart` | `port_groupes.dart` (`/tc/groupes`, connu de `CLAUDE.md`) | port réel : autre lot |
| `core/capacites/partage_pedagogique_demonstration.dart` | `port_partage_pedagogique.dart` | port réel : autre lot |
| `core/tc_horloge/demonstration_horloge.dart` | `port_horloge_seance.dart`, `demonstration_groupes.dart` | port réel : autre lot |
| `core/recherche/moteur_recherche_demo.dart`, `corpus_demo_recherche.dart` | entre eux et `moteurs_demo_recherche.dart` | non branchés (tolérés) |
| `core/recherche/moteurs_demo_recherche.dart`, `core/identite/matricule_demo.dart`, `features/recherche/domaines/familles_eleves/resolution_ra_demo.dart` | `mode_demonstration.dart` seul | partent avec la démo (R) ; retirés de `branchement_tolere.txt` |
| `core/capacites/avis_demonstration.dart`, `courriels_demonstration.dart`, `langues_communication_demonstration.dart` | aucun fichier de `lib/` | non branchés (tolérés, « supprimé le 08/11 ») : à retirer au même moment |

## Ordre proposé (une PR à la fois, P6)

1. **P** : ce relevé, comparé par le garde-cap.
2. **D1, données** : les jeux d'essai purs lus hors démo (`seance_demo`, `adulte_demo`,
   `enseignant_demo`, `classe_demo`, `controleur_demo`, `finance_demo`, les sept fichiers de
   `communications/` et `comptable/`, etc.) passent dans `test/support/demo/`, sans changer une ligne
   de leur contenu. Les imports des tests suivent.
3. **D2, harnais** : le câblage des pages `demo_*_page.dart` dont dépendent des tests d'écrans réels
   (salle, adulte, enseignant, contrôleur, classe, comptable, finance, accessibilité, communications)
   devient un harnais par rôle dans `test/support/`. Les tests qui ne vérifient que la démonstration
   elle-même partent en R.
4. **R** : retrait de `lib/features/demo`, des routes, de `?demo=`, de `RacineDemonstrable` et de
   « Essayer la démonstration ». Mesure de `main.dart.js` avant et après sur une construction staging.
   Le SHA de `main` d'avant le retrait est écrit dans la PR.

Aucune migration. Suite complète avant chaque push.
