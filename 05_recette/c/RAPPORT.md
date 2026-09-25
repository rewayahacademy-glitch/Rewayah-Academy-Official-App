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

## Sous-paquet 2 : Classe `/tuteur/classes/:classeId` et sous-pages (24/09 soir, repris le 25/09 après coupure de session)

### Commits

| Hash | Message |
|---|---|
| `ce5028a` | refactor(tuteur-accueil): ancre d'horloge serveur partagée avec la Classe |
| `b4c4e7b` | feat(tuteur-classe): Classe et sous-pages planning, travail, bibliothèque, progression |
| `24df91c` | test(tuteur-classe): parcours touchés depuis la navigation, états et fonctions pures |
| `dedc420` | fix(tuteur-classe): vraie composition bureau des sous-pages et planning sans source dit comme tel (travail non commité de l'agent coupé, repris et terminé) |
| `e83b91c` | test(tuteur-classe): doubles partagés, captures de recette, échec, hors ligne et bureau des sous-pages |

Fichiers : `lib/features/classe_tuteur/{classe_tuteur_page,carte_seance_classe,bloc_observation_classe,contexte_classe,planning_classe_page,travail_classe_page,ressources_classe_page,progression_classe_page}.dart`, `lib/features/accueil_famille/ancre_horloge_serveur.dart`, `lib/core/tc_parcours/port_travail_a_venir.dart`, `lib/features/tc_catalogue/detail_ressource_page.dart` (retour `?retour=` validé), clés `classe.*` + générés, `test/features/classe_tuteur/{classe_tuteur_test,classe_tuteur_capture_test,support_classe}.dart`. Tous possédés par C (`00_OWNERSHIP.md` §3). Les 5 STUBS du sous-paquet (classe, planning, travail, ressources, progression) sont remplacés ; reste `catalogue_classes_page.dart` (sous-paquet 3). Frontière `git diff --stat cefab7f...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets web/vercel.json .firebaserc` : **vide**.

### Écrans livrés

- **Classe** (maquette M1) : en-tête (retour, nom de classe, « prénom · Sayyid prénom », cloche) ; UNE carte : enseignant (initiale, DB-CRS-09), classe, parcours « cours · niveau » ; bandeau d'état (même calcul `AffichageSeance` que l'Accueil ; présence réelle à droite, jamais une absence devinée) ; jour/heure + durée à deux colonnes ; bloc Observation depuis `DisponibiliteObservation` (K4) : CTA « Observer la séance », « n visites disponibles · durée par visite », « Comment ça marche ? », ou un motif (P3 fermé, visites épuisées, présence en vérification, séance à venir…) ; puis UNE carte groupée à filets : Planning, Travail à préparer, Bibliothèque, Progression, Historique. Aucun « Rejoindre ». Bureau et tablette ≥ 840 : deux colonnes 62/38.
- **Planning** : séances programmées (K2), heure rendue serveur + fuseau dit une fois, pastilles annulée / en direct ; jamais une occurrence inventée ni un décalage UTC fixe (DB-CRS-03/04).
- **Travail à préparer** : sans limite de trois, statut du service, travail retiré masqué, non cochable (DB-CRS-10).
- **Bibliothèque** : ressources de la classe, ligne vers le détail existant `/tc/bibliotheque/:id?retour=` (retour revient ici).
- **Progression** : niveau en mots et étapes partagées ; jamais `lesson_reports`.
- Sous-pages : retour vers la classe, colonnes (contenu 62 %, précisions 38 %) ou largeur de lecture dès 840.

États : chargement (squelette + prolongé), échec + Réessayer borné (testé : relit et affiche la classe), classe indisponible (port K6 absent = production), introuvable (autre élève / autre foyer, retour à l'Accueil), aucune séance, horaire incertain (heure de l'appareil dite), annulée, sous-pages indisponibles (travail, bibliothèque, progression, planning sans source) et vides, hors ligne (bandeau de la coquille, contenu lisible). Clair et sombre.

### Carte des fonctions

| Fonction | Écran unique | Route ouverte | Place dans la maquette |
|---|---|---|---|
| Entrer dans la classe | Accueil, CTA « Voir la classe » (sous-paquet 1) | `/tuteur/classes/:classeId?eleve=` | bas de la carte classe (V1, V2) |
| Revenir | Classe, disque retour | `/tuteur` | chevron en tête (M1) |
| Observer la séance | Classe, bloc Observation | `/tc/observation/:seanceId?classe=&eleve=` (écran du lot O) | CTA lavande sous les horaires (M1) |
| Comment ça marche ? | Classe, bloc Observation | `/tc/observation/:seanceId?classe=&eleve=&aide=1` | lien sous le résumé des visites (M1) |
| Planning | Classe, carte groupée | `/tuteur/classes/:classeId/planning?eleve=` | « Planning habituel », 1re ligne (M1) |
| Travail à préparer | Classe, carte groupée | `.../travail?eleve=` | « Avant / Après la séance » (M1), rattaché à la destination existante (V8 §M1) |
| Bibliothèque | Classe, carte groupée | `.../ressources?eleve=` | idem |
| Progression | Classe, carte groupée | `.../progression?eleve=` | idem |
| Historique filtré | Classe, carte groupée | `/tuteur/suivi?eleve=&classe=` (destination Historique, pas une copie) | dernière ligne |
| Ouvrir une ressource | Bibliothèque de classe | `/tc/bibliotheque/:id?retour=` | ligne à chevron |

Aucune fonction en double. « Voir tout » de l'Accueil ouvre le même écran Travail (même route, pas une copie).

### Statut de preuve

| Élément | Statut |
|---|---|
| Classe et 4 sous-pages | UI réalisée ; testée en simulation ; atteignable depuis `main.dart` (routeur) et par boutons touchés depuis la barre basse |
| Classe en production | port K6 non branché (C-1/C-12) : « pas encore disponible » |
| Observation | P3 fermé en production (motif affiché) ; parcours en simulation |
| Planning | `mes_seances_v` via K2 (branché) ; planning daté serveur DB-CRS-03 |
| Travail, Bibliothèque, Progression | sources non branchées en production : phrases « pas encore relié(e) » (adaptateurs `assignations_supabase`, `catalogue_supabase` à écrire ; DB-CRS-11) |
| Vérifié réellement | rien (aucun appareil, aucun Supabase) |

### Commandes et résultats exacts (sous `flutter-verrou.ps1`, 25/09)

| Commande | Résultat |
|---|---|
| `dart run slang && dart format lib/features/classe_tuteur test/features/classe_tuteur && dart analyze --fatal-infos lib/features/classe_tuteur lib/features/accueil_famille lib/features/tc_catalogue/detail_ressource_page.dart lib/core/tc_parcours/port_travail_a_venir.dart test/features/classe_tuteur` | 2 infos `prefer_const_constructors` (support de test), corrigées |
| `dart analyze --fatal-infos test/features/classe_tuteur && flutter test --no-pub -r failures-only test/features/classe_tuteur/classe_tuteur_test.dart test/features/classe_tuteur/classe_tuteur_capture_test.dart` (avec `CAPTURE_DIR`, `CAPTURE_MAQUETTE_CLASSE_MOBILE`) | `No issues found!` puis `+73: All tests passed!` |
| `dart run tool/verifier_jetons.dart && flutter test --no-pub -r failures-only test/features/accueil_famille_test.dart test/router/navigation_test.dart test/router/etats_transverses_test.dart test/accessibilite/rtl_echelle_texte_ecrans_test.dart` | `Jetons verifies : 428 fichiers, aucune violation.` puis `+148 -1` : seul échec `etats_transverses_test.dart:81` « une classe inconnue du foyer » (attend le texte du STUB ; demande C-9, fichier du coordinateur) |

Tests du lot : 8 parcours touchés depuis la barre basse (Accueil > Voir la classe > chaque rubrique puis retour ; Bibliothèque > détail > retour ; Historique filtré ; Observer ; Comment ça marche), 17 états, bureau 1440 et téléphone 390, fonctions pures (bandeau, séances à venir, travaux, visites, motifs).

### Captures (`captures/`, lues)

`classe_390x844@3_{light,dark}`, `classe_1440x900@1_{light,dark}`, `classe_1024x768@1_{light,dark}`, `classe_390x1400@2_page_entiere_light`, `classe_{planning,travail,ressources,progression}_{390x844@3,1440x900@1}_{light,dark}`, états `classe_390x844@3_{production_p3,indisponible,visites_epuisees,echec,hors_ligne}`, `classe_{travail,ressources,progression}_390x844@3_production` ; planche `classe_mobile_contre_maquette.png` (M1, 390 logiques). Pas de maquette bureau de la Classe : composition dérivée de l'Accueil bureau (V2 A), deux colonnes 62/38.

Corrigé après lecture des captures : sous-pages en 1440 qui étiraient une liste de téléphone sur 1 100 px (colonnes / largeur de lecture), textes trop petits sur bureau, accompagnement du bandeau collé au milieu.

Écarts de planche restants, assumés : densité de la maquette (≈ 1,4) ; « Aujourd'hui 18:00 – 19:00 » / « Temps restant » remplacés par la date et l'heure rendues serveur et « Durée » (V8 : libellé non ambigu) ; « Mariam est présente » → « prénom : état de présence » (libellés de présence existants, sans accord de genre deviné) ; sablier au lieu de l'horloge (C-5) ; icône info devant « Comment ça marche ? » absente (`LienFleche` partagé sans icône de tête, demande C-13) ; 5 rubriques au lieu de 2 (V8 : « Avant / Après » rattaché aux destinations existantes) ; photo de l'enseignant = initiale (DB-CRS-09).

### Demandes au coordinateur

C-9 à C-12 (24/09), C-13 ajoutée (`demandes/C.md`).

## Sous-paquet 3 : Catalogue `/tuteur/classes/catalogue?eleve=` (25/09/2026)

Reprise : aucun travail non commité ni commit du sous-paquet 3 laissé par un agent précédent (seuls les `windows/flutter/generated_*`, fins de ligne, non commités).

### Commits

Voir le tableau en fin de section (renseigné après commit).

Fichiers : `lib/features/classe_tuteur/catalogue_classes_page.dart` (STUB remplacé), clés `classe.pageCatalogue.*` + générés, `test/features/classe_tuteur/{catalogue_classes_test,catalogue_classes_capture_test}.dart`, doubles ajoutés à `support_classe.dart` (`FauxCatalogueClasses`, `classesProposeesFictives`, `eleveA2`). Aucun fichier du coordinateur modifié ; **plus aucun STUB du lot C**. Frontière `git diff --stat cefab7f...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets web/vercel.json .firebaserc` : **vide**.

### Écran livré

Pas de maquette high-fi : composition dérivée de la carte classe de l'Accueil bureau (#1, colonne gauche) et des cartes E1 (manifeste §2, ligne `/tuteur/classes/catalogue`).
- **Liste** : en-tête (retour vers l'Accueil, « Choisir une classe », « Pour prénom »), « Classes proposées », UNE carte par classe : initiale de l'enseignant (DB-CRS-09), nom de la classe, « Sayyid/Sayyida prénom » (prénom seul si le titre n'est pas rendu, jamais deviné), filet, horaires, pastille d'état (Ouverte / Liste d'attente / Complète), places restantes rendues par le serveur, action secondaire « Choisir cette classe » ou « Rejoindre la liste d'attente » (aucune pour une classe complète). À droite dès 840 (62/38), carte groupée « Avant de choisir » (même enseignant, places lues au moment de la lecture, rien réservé avant confirmation).
- **Confirmation** (tâche focalisée, retour = liste) : phrase, carte de la classe, « Même classe et même enseignant pour toutes les séances de la semaine : … », UNE action principale « Confirmer l'inscription » / « Confirmer la liste d'attente ». Clé d'idempotence (uuid v4) fixée au choix et gardée à chaque « Réessayer » ; double pression bloquée.
- **Résultat** (grammaire M5, `EcranResultat`) : inscrit (« Voir la classe » → `/tuteur/classes/:id?eleve=`), demande à valider, liste d'attente, refus (« Voir les autres classes » relit la liste). Classes et Accueil invalidés après réponse.

États : chargement (squelette), échec + Réessayer, vide (aucune classe compatible), indisponible (production : `CatalogueClassesIndisponible` ou aucun fuseau → « Le choix de classe en ligne n'est pas encore ouvert. », sans Réessayer, **aucune réservation locale**), inscription indisponible (DB-CRS-08, aucun bouton), réponse perdue (« Réessayer ne crée pas de seconde inscription »), profil hors foyer (introuvable, retour Accueil), hors ligne (bandeau de la coquille). Clair et sombre, 390 / 1024 / 1440.

### Carte des fonctions

| Fonction | Écran unique | Route ouverte | Place |
|---|---|---|---|
| Ouvrir le choix de classe | Accueil, état « élève sans classe » (sous-paquet 1) | `/tuteur/classes/catalogue?eleve=` | CTA de l'état vide dérivé |
| Choisir une classe / rejoindre la liste d'attente | Catalogue, carte de la classe | aucune (tâche focalisée dans la page) | bas de chaque carte |
| Confirmer l'inscription | Catalogue, confirmation | appel `PortCatalogueClasses.inscrire` (K6) | action principale sous le récapitulatif |
| Voir la classe (après inscription) | Catalogue, résultat | `/tuteur/classes/:classeId?eleve=` (même écran que « Voir la classe » de l'Accueil) | action du résultat M5 |
| Voir les autres classes (après refus) | Catalogue, résultat | aucune (relit la liste) | action du résultat M5 |
| Revenir | disque retour | confirmation → liste ; liste → `/tuteur` | en-tête |

Aucune fonction en double. La fiche élève > Inscription (lot B) peut ouvrir la même route, jamais une copie.

### Statut de preuve

| Élément | Statut |
|---|---|
| Catalogue (liste, confirmation, 4 résultats, tous états) | UI réalisée ; testée en simulation (`FauxCatalogueClasses`) ; atteignable depuis `main.dart` (routeur) et par boutons touchés depuis la barre basse |
| Catalogue en production | dépendances DB-CRS-07 (source), DB-CRS-08 (inscription atomique), point P1 [DIRECTEUR] ; fuseau du foyer non lu (C-15) : « pas encore ouvert » |
| Séances hebdomadaires, fuseau, parcours, langue, motif de refus | absents du contrat `ClasseOuverte` (demande C-14) : phrase honnête sur la carte |
| Photo enseignant | DB-CRS-09 : initiale |
| Vérifié réellement | rien (aucun Supabase, aucun appareil) |

### Commandes et résultats exacts (sous `flutter-verrou.ps1`, 25/09)

| Commande | Résultat |
|---|---|
| `dart run slang && dart format ... && dart analyze --fatal-infos lib/features/classe_tuteur test/features/classe_tuteur` | 1 erreur (`elevesDuFoyerProvider` non importé) + 2 infos `only_throw_errors` dans le double ; corrigées |
| `dart analyze --fatal-infos lib/features/classe_tuteur test/features/classe_tuteur && flutter test --no-pub -r failures-only test/features/classe_tuteur/catalogue_classes_test.dart` | `No issues found!` puis `+18: All tests passed!` |
| idem + `catalogue_classes_capture_test.dart` (avec `CAPTURE_DIR`), après correction bureau | `No issues found!` puis `+39: All tests passed!` |

Tests du lot (`catalogue_classes_test.dart`, 18) : 7 parcours touchés depuis la barre basse (Accueil > profil Eleve A2 > « Choisir une classe » > carte > confirmation > résultat : inscrit puis « Voir la classe », liste d'attente puis Accueil, validation, refus puis autres classes, réponse perdue avec la même clé, double pression = une demande, retours), 8 états (production, source absente, inscription indisponible, vide, échec puis Réessayer, profil hors foyer, hors ligne, bureau 1440 en colonnes), 3 fonctions pures.

### Captures (`captures/`, lues)

`catalogue_{390x844@3,1440x900@1}_{light,dark}`, `catalogue_1024x768@1_light`, `catalogue_confirmation_{390x844@3,1440x900@1}_{light,dark}`, `catalogue_390x844@3_production_{light,dark}`, `catalogue_1440x900@1_production_light`, `catalogue_resultat_{inscrit,validation,liste_attente,refuse}_390x844@3_light`, `catalogue_confirmation_390x844@3_reponse_perdue`, `catalogue_390x844@3_{vide,echec,hors_ligne}`. Pas de planche (aucune maquette du catalogue). Données fictives.

Corrigé après lecture des captures : sur bureau, boutons étirés sur toute la carte (`ActionPrincipale` s'étire même avec `pleineLargeur: false`, contourné par `IntrinsicWidth`, demande C-16) ; textes de confirmation et de précisions trop petits à 1440.

### Demandes au coordinateur

C-14 (champs de `ClasseOuverte` et motif de refus), C-15 (fuseau du foyer), C-16 (`ActionPrincipale`), dans `demandes/C.md`.
