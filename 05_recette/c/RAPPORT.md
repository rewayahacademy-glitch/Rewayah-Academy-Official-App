# Lot C (Cours) : rapport de recette

Poste A. Branche `ui/tuteur-v1-c` (depuis `ui/tuteur-v1` @ `cefab7f`), worktree `D:\RA_TUTEUR\lot-c`. Commits locaux, **aucun push**.

## Sous-paquet 1 : Accueil `/tuteur` (24/09/2026, 18:10 à 19:15)

### Commits

| Hash | Message |
|---|---|
| `bd373d9` | feat(tuteur-classes): adaptateur Supabase des classes du foyer (K6) |
| `0e81763` | feat(tuteur-accueil): accueil refondu sur les maquettes V1 et V2 |
| `2382c3e` | test(tuteur-accueil): captures de recette de l'accueil (390, 1024, 1440, clair et sombre, planches) |
| `7e35822` | fix(tuteur-accueil): en-têtes de section sur une ligne à 390, comme la maquette V1 |

Fichiers : `lib/features/accueil_famille/{accueil_famille_page,carte_classe_seance,bloc_seance,bandeau_blocage,liste_preparation,ligne_derniere_seance}.dart`, `lib/core/capacites/classes_foyer_supabase.dart`, `lib/core/tc_groupe/libelles_tc_groupe.dart` (unités de durée en slang, défaut D11), `assets/i18n/fr.i18n.json` (espaces `tuteur.accueil.*`, `tc.groupe.*`) + `strings*.g.dart` régénérés, `test/features/accueil_famille_test.dart` (réécrit), `test/features/accueil_famille_capture_test.dart`. Aucun fichier du coordinateur modifié. Frontière `git diff --stat cefab7f...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets web/vercel.json .firebaserc` : **vide**. STUBS du lot C : l'Accueil n'en était pas un (écran existant remplacé) ; les 6 STUBS `classe_tuteur/*` relèvent des sous-paquets 2 et 3.

### Écran livré

Composition (maquettes V1 mobile, V2 A bureau clair, V2 B/C sombre) :
- téléphone < 600 : sélecteur, carte classe (bloc séance imbriqué `surfaceSunken`), bandeau de blocage, carte « Avant le prochain cours », carte « Dernière séance » ;
- tablette 600-1199 : sélecteur, carte classe mise en avant, puis UNE carte groupée (blocage / préparation / dernière séance, filets) ;
- bureau ≥ 1200 : deux colonnes ≈ 62/38 de hauteur égale, carte classe à gauche, carte groupée à droite.

Corrections de maquette appliquées : 4 destinations, « Ajouter » (étiquette « Ajouter un profil élève ») au lieu de « Ajouter enfant », « Cours dans 13 min » au lieu de « Session », « Avant le prochain cours », « Détails de la séance », un seul blocage (lien « fournir une photo » retiré, P6), photo/initiale de l'enseignant distincte du portrait élève, aucun réseau affiché, sélecteur et carte calculés par la même fonction (`AffichageSeance`), « Séance en direct » / « Séance toujours en direct » (clés `tc.groupe.temps.enCours|prolongee` remplacées), aucun compte à rebours négatif.

Retiré de l'Accueil (une fonction = un seul endroit) : « Assister » (observation depuis la classe, lot O), « Gérer le foyer » et dates d'accès (Foyer B, Compte E), « Mes groupes » (remplacé par « Voir la classe »), `BlocParcours` (fiche élève > Inscription, lot B ; voir demande C-7).

États : chargement (squelette + chargement prolongé de `BlocAsynchrone`), erreur de lecture des profils (échec + Réessayer borné), foyer vide (invitation « Ajouter un profil élève »), élève sans classe (invitation « Choisir une classe » → catalogue), classe indisponible (production aujourd'hui, pas de CTA), séance illisible / absente, horaire incertain sans horloge serveur (heure « de cet appareil »), salle ouverte, en direct, prolongée, annulée, non tenue, terminée ; hors ligne : bandeau de `PageShell` + échecs de bloc. Clair et sombre (même arbre, jetons gelés).

### Carte des fonctions

| Fonction | Écran unique | Route ouverte | Place dans la maquette |
|---|---|---|---|
| Choisir le profil élève affiché | Accueil, sélecteur | aucune (K1 `selectionEleveProvider`) | rangée d'avatars sous le titre (V1, V2) |
| Ajouter un profil élève (raccourci prévu) | Accueil, dernier item du sélecteur | `/tuteur/foyer/ajouter` (même flux que Foyer) | « + » en fin de rangée |
| Voir la classe | Accueil, carte classe, CTA dominant | `/tuteur/classes/:classeId?eleve=` | bas de la carte classe |
| Connecter un appareil (blocage) | Accueil, bandeau (mobile) / tête de colonne droite (tablette, bureau) | `/tuteur/foyer/appairer/:eleveId` | sous la carte classe (V1) ; haut de colonne droite (V2) |
| Voir tout le travail | Accueil, section « Avant le prochain cours » | `/tuteur/classes/:classeId/travail?eleve=` | à droite du titre de section |
| Voir l'historique de l'élève | Accueil, section « Dernière séance » | `/tuteur/suivi?eleve=` | à droite du titre de section |
| Détails de la séance | Accueil, section « Dernière séance » | `/tuteur/seances/:seanceId` | dernière ligne de la section (V2 ; sous la barre en V1) |
| Choisir une classe (élève sans classe) | Accueil, état vide de l'élève | `/tuteur/classes/catalogue?eleve=` | état dérivé (manifeste §6) |
| Notifications, thème | coquille (COORD) | `/tuteur/notifications` | en-tête |

Aucune fonction en double sur l'écran ; « Ajouter un profil élève » est le raccourci prévu par le mandat (même flux).

### Statut de preuve

| Élément | Statut |
|---|---|
| Accueil (3 compositions, tous états) | UI réalisée ; testée en simulation (fixtures K1/K2/K6/K7) ; **branchée** aux services existants : profils (`profils_du_foyer_v`), séances (`mes_seances_v` via K2), appareils (`mes_appareils_v`), présence (`presence_seance_v`) |
| Classe de l'élève | adaptateur réel écrit (`ClassesFoyerSupabase`, testé sur sa fonction pure) ; **non branché** : provider du port au coordinateur (demande C-1) ; en production l'écran dit « non disponible » |
| Horloge serveur | dépendance DB-TRV-07 côté K2 (demande C-2) : `horaireIncertain` en production |
| Travail à préparer | port `null` (sous-paquet 2) : phrase honnête, jamais « Rien à préparer » |
| Photo enseignant | DB-CRS-09 : initiale |
| Vérifié réellement | rien (aucun appareil, aucun Supabase) |

### Commandes et résultats exacts (toutes sous `flutter-verrou.ps1`)

| Commande | Résultat |
|---|---|
| `flutter pub get` | `Got dependencies!`, code 0 (attente du verrou 34 min) |
| `dart run slang` | `Translations generated successfully` |
| `dart analyze --fatal-infos lib/features/accueil_famille lib/core/capacites/classes_foyer_supabase.dart lib/core/tc_groupe test/features/accueil_famille_test.dart test/features/accueil_famille_capture_test.dart` | `No issues found!` |
| 1er `flutter test` ciblé | `+144 -12` : débordement de 12 px de l'en-tête de section à 324 px et 2 « En direct » attendus ; corrigés |
| `dart run tool/verifier_jetons.dart` | `Jetons verifies : 424 fichiers, aucune violation.` |
| `flutter test --no-pub -r failures-only test/features/accueil_famille_test.dart test/features/accueil_famille_capture_test.dart test/router/navigation_test.dart test/teaching_core/a/group_summary_vm_test.dart test/accessibilite/rtl_echelle_texte_ecrans_test.dart test/config/fixtures_isolees_test.dart` (avec `CAPTURE_DIR`) | `+174: All tests passed!` |

Tests du lot (`accueil_famille_test.dart`) : 7 parcours **touchés depuis la barre basse** sur le vrai routeur (Voir la classe, changement de profil puis Choisir une classe, Ajouter, Connecter un appareil, Voir l'historique puis Détails de la séance, Voir tout), 8 états, bureau à deux colonnes, fonctions pures (`AffichageSeance`, `aucunAppareilPret`, `classesDepuisLignes`), présence (table unique, jamais « Absence » deviné). Non lancés : analyse complète, suite complète (coordinateur), build web.

### Captures (`captures/`, lues)

`accueil_390x844@3_{light,dark}`, `accueil_390x1600@2_page_entiere_{light,dark}`, `accueil_1440x900@1_{light,dark}`, `accueil_1024x768@1_{light,dark}`, `accueil_390x844@3_vide`, `accueil_390x844@3_sans_classe`, `accueil_390x1600@2_horaire_incertain` ; planches `accueil_mobile_contre_maquette.png` (V1, 390 logiques) et `accueil_bureau_contre_maquette.png` (V2 A, 1440 logiques). Données fictives ; les 3 actions de travail viennent d'un faux de test (le port est `null` en production).

Écarts de planche restants, assumés : maquette mobile ≈ 1,4 fois plus dense qu'un vrai 390 (manifeste §3.2), donc tailles plus grandes au rendu ; sablier au lieu de l'horloge (C-5) ; texte du conseil d'appareil = clé existante (V1 #13) ; bouton « Connecter un appareil » sous le texte (V1 #17) ; « Présente » remplacé par la présence réelle (« État inconnu » dans les captures, faute de ligne de présence dans les fixtures) ; colonne droite en carte dans les deux thèmes (un seul arbre, V2 A retenue).

### Défauts hors périmètre consignés

Deux lignes ajoutées à `08_BACKLOG_VAGUE_CLASSE_VISIO.md` (effectif de `mes_groupes_famille_v`, repli du titre Sayyid). Demandes au coordinateur : `demandes/C.md` (C-1 à C-7).
