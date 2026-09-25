# Lot O (Observation) : rapport de recette

Poste A. Branche `ui/tuteur-v1-o` (depuis `ui/tuteur-v1` @ `cefab7f`), worktree `D:\RA_TUTEUR\lot-o`. Commits locaux, **aucun push**.

## Sous-paquet 1 : Entrée et explication (24/09/2026, 21 h 30 à 22 h 45)

### Commits

| Hash | Message |
|---|---|
| `5609390` | feat(observation): entree du tuteur, verification prealable et explication |
| `ed8065f` | fix(observation): ecarts de la planche M2 et captures de recette |

Fichiers (tous du lot O, `00_OWNERSHIP.md` §3 C-obs) : `lib/features/tc_observation_ui/{entree_observation_page,explication_premiere_visite,verification_prealable,ouverture_observation}.dart` (3 neufs), `lib/core/tc_observation/{libelles_observation,moteur_visite_observation}.dart` (commentaire faux corrigé : aucun code serveur ne referme l'intervalle), `assets/i18n/fr.i18n.json` (espace `tc.observation.*` seulement : `entree.retourClasse`, `explication.*`, `disponibilite.*`, `connexion.*`, `duree.*`) + `strings.g.dart`, `strings_fr.g.dart` régénérés, tests `test/teaching_core/g/{entree_explication_test,entree_observation_navigation_test,entree_explication_capture_test}.dart` (neufs), `ecrans_observation_test.dart`, `faux/faux_observation.dart`, `support/hote_tc_g.dart`.

Frontière `git diff --stat cefab7f...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets web/vercel.json .firebaserc` : **vide**. Aucun fichier du coordinateur modifié.

### Écran livré : le vestibule de l'observation

Route existante `/tc/observation/:seanceId?classe=&eleve=` (hors coquille, tâche focalisée). Pour le tuteur, la page commence par un vestibule :

1. **Vérification préalable, en lecture seule** (`verification_prealable.dart`) : `budget_observation` (aucun intervalle ouvert), `politique_observation_effective(groupe)` quand la classe est connue, présence de l'enfant (`presence_seance_v`, indicative), mémoire « explication déjà lue » (par compte, sur l'appareil ; en mémoire seule sur le web). Décision par le contrat K4 `disponibiliteObservation`, seule règle.
2. **Explication de première utilisation** (maquette V8 M2, `explication_premiere_visite.dart`), dans l'ordre de M2 : « Un aperçu de son apprentissage », trois points à médaillon (« {n} visites de {durée} » + « Par séance et par parent, même si plusieurs de vos enfants sont dans la classe. » ; écoute ; sans micro ni caméra), filet, conseils (revenir plus tard, **visite écourtée consommée**, sans intervenir), encart « Votre enfant et son enseignant sont informés. », « Observer maintenant → », « Pas maintenant ». Chiffres lus sur la politique effective ou le budget, jamais en dur (test : 3 visites de 1 min 30 s). Texte de référence du mandat observation §6 couvert en entier. « 1/2 visite restante pour cette séance » affiché au-dessus du CTA dès qu'une visite est consommée ; « revenez plus tard » retiré quand il ne restera plus de visite.
3. **Connexion et vérification** (logigramme V7 N13) : écran résultat, indicateur d'activité, phrase de connexion prolongée après `AppDelais.chargementProlonge`, aucun retour pendant la demande en vol (une demande abandonnée laisserait un intervalle ouvert : DB-OBS-03).

**Le compteur ne démarre qu'après l'entrée confirmée** : seule l'entrée appelle `entrer_observation()` ; aucun flux de budget, aucun panneau de visite avant (test : `rolesDemandes` vide et `abonnements == 0` pendant l'explication).

**Aucune visite sans geste, jamais au rechargement.** La classe transmet le geste « Observer la séance » par `DemandeEntreeObservation` en `extra` : objet non JSON, que `go_router` ne sait pas écrire dans l'historique (lu dans `go_router-18.0.1/lib/src/match.dart:1010-1020`), donc perdu au rechargement, au retour arrière et sur lien direct. Explication déjà lue + geste = connexion directe (V7 « Explication déjà vue ») ; sinon l'explication s'affiche et attend « Observer maintenant ». L'ancien écran « confirmation » dérivé et son second lien « Comment ça marche ? » ont été retirés (une fonction = un seul endroit : ce lien vit dans la classe, M1).

**États** : chargement (squelette), contenu, indisponibilités par motif avec icône propre (présence en vérification jamais « absent », visites épuisées, temps épuisé, séance hors fenêtre, observation désactivée, aucun enfant dans la séance, visite déjà ouverte, capacité absente), erreur serveur (« Vérification impossible », Réessayer relit), hors ligne (état système hors ligne + bandeau), connexion prolongée, connexion impossible (Réessayer relit puis relance l'entrée), refus serveur à l'entrée (motif), observation réelle fermée (P3 : aucun appel serveur, « Observation pas encore ouverte », retour à la classe), identifiant illisible (introuvable), `?classe=` illisible ignoré (jamais un chemin). « Comment ça marche ? » quand l'entrée est impossible : l'explication, le motif à la place du CTA, « Retour à la classe ».

**Formats** : 390 (colonne pleine), tablette et bureau (colonne de lecture centrée bornée à `AppPage.largeurDialogue` 560, jamais la feuille mobile étirée), clair et sombre, texte à 200 % sans débordement.

### Carte des fonctions (sous-paquet 1)

| Fonction | Écran unique | Route | Place dans la maquette |
|---|---|---|---|
| Ouvrir l'observation depuis la classe (« Observer la séance ») | Classe, bloc Observation (**lot C**, C2) ; geste fourni par `ouvrirObservation(context, seanceId:, classeId:, eleveId:)` | `/tc/observation/:seanceId?classe=&eleve=` + `extra` | M1, CTA dominant du bloc |
| Lire l'explication (« Comment ça marche ? ») | Vestibule, explication | même route, sans geste (`ouvrirObservation(..., entrer: false)`) | M1 lien sous le CTA -> M2 entier |
| Explication de première utilisation | Vestibule, explication | même route | M2 |
| Entrer (« Observer maintenant ») | Vestibule, explication | même route ; `entrer_observation` | M2, CTA dominant en bas |
| Entrer directement, explication déjà lue | Vestibule, connexion et vérification | même route + geste | V7 N10 -> N13 |
| Renoncer sans rien consommer (« Pas maintenant », disque retour, retour système) | Vestibule | `/tuteur/classes/:classeId?eleve=` (sinon écran précédent, sinon racine) | M2 lien bas, chevron d'en-tête |
| Revérifier (présence, réseau) | Vestibule, état en page | même route, relecture | dérivé M5 (manifeste §6.3) |
| Réessayer après connexion impossible | Vestibule, état en page | même route | V7 N14 -> N10 |

Aucune fonction en double : le lien « Comment ça marche ? » n'existe qu'une fois (classe, M1) ; le vestibule n'en a pas.

### Statut de preuve

| Élément | Statut |
|---|---|
| Vestibule, explication, connexion, états | UI réalisée ; **testée en simulation** (doubles `test/teaching_core/g/faux`) ; **branchée** aux ports existants (`PolitiqueObservationSupabase`, `PortVisiteObservation`, `ServicePresenceSupabase`, `stockagePreferencesProvider`) derrière l'interrupteur P3 |
| Production | `OBSERVATION_TUTEUR_REELLE` faux : « Observation pas encore ouverte », aucun appel (DB-OBS-01 jeton vidéo, DB-OBS-05 présence non exigée par le serveur) |
| Présence de l'enfant | indicative seulement (DB-OBS-05) |
| Temps compté dès l'entrée, connexion vidéo comprise | dit à l'écran (DB-OBS-07) |
| Visite déjà ouverte | motif dédié (DB-OBS-06) |
| Atteignabilité (registre §5 bis a) | `graphe_imports.ps1 -Repo D:\RA_TUTEUR\lot-o -Ref ed8065f` : `explication_premiere_visite.dart`, `verification_prealable.dart`, `ouverture_observation.dart` atteignables depuis `lib/main.dart` ; `disponibilite_observation.dart` et `seance_famille.dart` (contrats de phase 0) le deviennent |
| Bouton qui y mène (b) | sur cette branche : « Assister » de l'Accueil de la base (carte de l'enfant, séance en cours), testé en touchant depuis la vraie coquille ; après intégration avec le lot C : le bloc Observation de la classe (C2), demande O-3 |
| Texte dans `main.dart.js` servi (c) | à faire par le coordinateur après aperçu |
| Vérifié réellement | rien (aucun appareil, aucun Supabase) |

### Commandes et résultats exacts (toutes sous `flutter-verrou.ps1`)

| Commande | Résultat |
|---|---|
| `dart run slang` | `Translations generated successfully` |
| `dart analyze --fatal-infos lib/features/tc_observation_ui lib/core/tc_observation test/teaching_core/g` (1re passe) | 2 erreurs (import manquant, faux de présence homonyme) ; corrigées |
| `flutter test ... entree_explication_test, entree_observation_navigation_test, ecrans_observation_test` (1re passe) | `+15 -8` : la **salle de la base** (`panneau_observation_tuteur.dart:148`, compteur) déborde de 49 px à 390 ; les tests qui entrent en salle passent sur une fenêtre de tablette ou de bureau, l'entrée et l'explication restent éprouvées à 390 (refonte de la salle = sous-paquet 2) |
| `dart run tool/verifier_jetons.dart` | `Jetons verifies : 421 fichiers, aucune violation.` |
| Finale : `dart analyze --fatal-infos lib/features/tc_observation_ui lib/core/tc_observation lib/core/i18n test/teaching_core/g` | `No issues found!` |
| Finale (avec `CAPTURE_DIR`) : `flutter test --no-pub test/teaching_core/g test/tc_observation test/config/fixtures_isolees_test.dart test/i18n test/teaching_core/q/q03_quota_observation_tuteur_test.dart test/features/accueil_famille_test.dart test/features/observation_groupe_admin_test.dart test/router/navigation_test.dart` | `+280: All tests passed!` (journal `o1_tests.log`) |
| Frontière | vide |

Tests du sous-paquet : 27 dans `entree_explication_test.dart` (parcours touchés depuis une classe double qui appelle `ouvrirObservation` : Observer la séance, Comment ça marche ?, Observer maintenant, Pas maintenant, disque retour, Réessayer, Retour à la classe ; états ; 1440 ; sombre ; 200 %), 3 dans `entree_observation_navigation_test.dart` (**vraie coquille** : Accueil -> Assister -> explication -> Pas maintenant -> Accueil ; disque retour ; bureau -> Observer maintenant -> visite). Non lancés : analyse complète, suite complète, build web (coordinateur).

### Captures (`captures/`, lues)

`o1_explication_390x844@3_{light,dark}`, `o1_explication_390x1100@2_page_entiere_{light,dark}`, `o1_explication_1440x900@1_{light,dark}`, `o1_explication_1024x768@1_light`, `o1_connexion_390x844@3_{light,dark}`, `o1_connexion_1440x900@1_{light,dark}`, `o1_deuxieme_visite_390x1100@2_light`, `o1_visites_epuisees_390x1100@2_light`, `o1_presence_verification_390x844@3_light`, `o1_pas_ouverte_390x844@3_light`, `o1_erreur_390x844@3_light`, `o1_hors_ligne_390x844@3_light`, `o1_chargement_390x844@3_light`, `o1_connexion_prolongee_390x844@3_light`, `o1_connexion_impossible_390x844@3_light` ; planche `o1_explication_mobile_contre_maquette_M2.png` (+ `_capture.png`), maquette découpée `maquettes/M2_explication.png` (planche mobile x 590-947, y 79-593). Données fictives uniquement.

Corrigés après lecture des planches (`ed8065f`) : bouton inerte « Observer maintenant » sur l'écran de connexion remplacé par un indicateur ; icône générique (main) des motifs remplacée par une icône par motif ; conseils en retrait moindre que les points, comme M2 ; phrase de connexion prolongée qui répétait le titre.

Écarts de planche restants, assumés : titre de l'en-tête sur deux lignes à 390 (composant partagé `EntetePage`, `headlineSmall` 28 du manifeste §3.3, M2 ≈ 19 dp sur une planche plus dense) ; disque retour 48 au lieu du chevron (manifeste §3.4) ; sablier au lieu de l'horloge, haut-parleur au lieu du casque, flèches au lieu de « i » (icônes absentes d'`AppIcons`, demande O-4) ; troisième conseil (visite écourtée, directeur §1 bis-4) et textes du mandat au lieu de ceux de l'image (§6 prime ; coquille « quii » non reprise) ; fond de l'application au lieu du blanc de M2 (jetons) ; encart sur deux lignes à 390 ; pas de rail en tablette et bureau (route hors coquille, demande O-5).

### Écarts restants pour les sous-paquets suivants (même lot)

- Salle de la base : compteur « Visite n sur N » + « n s restantes » qui déborde à 390, commandes réduites à « Quitter », support jamais rendu : sous-paquet 2 (bandeau pleine largeur, décompte seconde par seconde, visites restantes).
- Fin de visite (base : `EmptyState` + retour) : sous-paquet 3 (M5, « Voir mes observations »).
- `tc.observation.refus.politiqueDesactivee` dit « ce groupe » (écran admin et contrôleur) : à reprendre au sous-paquet 3 (vocabulaire « Classe »).

### Demandes au coordinateur

`demandes/O.md` (O-1 à O-8) : constructeur de route, STUB `/tuteur/classes/:classeId/observer` (fichier du coordinateur), contrat du geste pour le lot C, icônes, rail, texte « Comment ça marche ? » (lot A), mode démonstration, icône de la nature « indisponible ».

### Défauts hors périmètre consignés

Aucun nouveau défaut hors périmètre relevé (les défauts de la salle sont du lot O, sous-paquet 2).
