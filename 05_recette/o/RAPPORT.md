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

## Sous-paquet 2 : Salle d'observation avec bandeau de décompte (25/09/2026, 02 h 50 à 05 h 10)

### Commits

| Hash | Message |
|---|---|
| `f847cae` | feat(observation): salle epuree, bandeau du decompte et visites restantes |
| `18a7d82` | test(observation): captures de recette de la salle et planches M4, M3, D1 |

Reprise : aucun travail du sous-paquet 2 n'était laissé par l'agent précédent ; `strings_ar.g.dart` et `windows/flutter/generated_*` modifiés = fins de ligne seulement, non commités.

Fichiers (tous C-obs) : `lib/features/tc_observation_ui/panneau_observation_tuteur.dart` (réécrit : la salle), **neufs** `compteur_visite.dart` (bandeau), `barre_commandes_observation.dart` (3 commandes), `contexte_salle_observation.dart` (en-tête lu par le port K6 des classes du foyer) ; `entree_observation_page.dart` (salle hors coquille plein cadre, retour système = Quitter + confirmation, état du lien suivi, visite refermée au démontage) ; `fr.i18n.json` espace `tc.observation.visite.*` seulement (+19 clés, −4 clés mortes `mediaFerme`, `enfantAbsent`, `restant`, `visites`) + générés ; tests `salle_observation_test.dart`, `salle_observation_capture_test.dart` (neufs), `ecrans_observation_test.dart`, `entree_explication_test.dart` (entrée en salle désormais à 390), `entree_observation_navigation_test.dart`, `support/hote_tc_g.dart` (`horloge`, `autres`). Frontière (`cefab7f...HEAD`, supabase, .github, vercel.json, pubspec.yaml, theme, router, widgets) : **vide**.

### Écran livré : la salle (M3, M4, D1, directeur §1 bis-5)

Du haut vers le bas : **bandeau pleine largeur** (sablier, décompte `mm:ss` en chiffres tabulaires seconde par seconde + « restantes » ; à droite « 1/2 visite restante pour cette séance », pluriel « 2/3 visites restantes… », « Aucune visite restante pour cette séance » à 0 ; lavande, ton d'avertissement dans les 30 dernières secondes ; « Temps restant non confirmé » si la relecture échoue ; lu en une phrase par le lecteur d'écran) ; en-tête (nom de la classe et « Mariam · Sayyid/Sayyida X » quand la classe du foyer se lit, sinon « Observation en cours » et les noms de la salle ; pastille d'état **réel** : En direct / Connexion / Reconnexion / Vidéo indisponible) ; **support dominant** (emplacement : aucun support partagé n'existe encore dans le produit, phrase discrète) ; deux vignettes 4:3 (enseignant, enfant ; image si publiée, sinon initiale et « Caméra fermée » ; « Pas encore dans la salle », jamais « absent » ; liseré d'accent et ondes seulement sur `parle` réel ; aucun camarade exposé) ; **barre de 3 commandes** : « Son reçu » (témoin, O-9), « Agrandir / Réduire » (support seul ; bandeau et Quitter restent), « Quitter » (pilule rouge douce) → confirmation « Quitter la visite ? Il vous reste 1 min 42 s. Une visite quittée avant la fin compte comme une visite entière… ». Aucun micro, caméra, chat, réaction. Pas de chevron (une fonction = un endroit : la sortie est « Quitter » ; retour système = même confirmation).

Formats : téléphone M4 (vignettes côte à côte, barre en ligne ; défile si hauteur < 300 ou texte > 130 %, commandes icône au-dessus du libellé) ; dès 600 : **une carte** comme D1 (support ~78 %, vignettes en colonne à droite, barre son | agrandir | quitter) sous le bandeau ; paysage 844x390 ; clair et sombre.

Reconnexion : pastille « Reconnexion » + phrase, son « interrompu », décompte continu jamais remis à zéro (test). Visite quittée par une autre voie (démontage de la page) : `sortir()` appelé (test) ; onglet tué = serveur (DB-OBS-03).

### Carte des fonctions (sous-paquet 2)

| Fonction | Écran unique | Route | Place dans la maquette |
|---|---|---|---|
| Voir le temps restant et les visites restantes | Salle, bandeau | `/tc/observation/:seanceId` (phase visite) | directeur §1 bis-5 (remplace la pastille « Visite 1/2 · 01:42 » de M3/M4/D1) |
| Savoir si le direct tient | Salle, pastille d'en-tête | même | M3/M4 « En direct », D1 « Séance en direct » |
| Regarder le support | Salle, zone dominante | même | M3/M4 carte support, D1 ~77 % |
| Voir l'enseignant et son enfant | Salle, 2 vignettes | même | M4 sous le support, D1 colonne droite |
| Son reçu (témoin) | Barre | même | M4 1re commande, D1 gauche |
| Agrandir / réduire le support | Barre | même | M4 2e, D1 centre |
| Quitter (avec confirmation) | Barre ; retour système = même geste | même → fin (base, sous-paquet 3) | M4 3e (pilule rouge), D1 droite |

Aucun doublon : pas de chevron de retour concurrent de « Quitter ».

### Statut de preuve

| Élément | Statut |
|---|---|
| Salle, bandeau, commandes, états | UI réalisée ; testée en simulation ; branchée aux ports existants (moteur de visite, `moteurSalleProvider`, `PortClassesFoyer`) derrière l'interrupteur P3 |
| En-tête nom de classe | production : `PortClassesFoyer` indisponible (DB-TRV-07, adaptateur du lot C) → titre générique, testé |
| Atteignabilité (a) | `graphe_imports.ps1 -Ref 18a7d82` : les 4 fichiers atteignables depuis `lib/main.dart` |
| Bouton qui y mène (b) | « Assister » (Accueil de la base) → « Observer maintenant » → salle, **touché depuis la vraie coquille à 390** (navigation_test) ; après C2 : bloc Observation de la classe (O-3) |
| (c) `main.dart.js` servi | au coordinateur |
| Vérifié réellement | rien |

### Commandes et résultats exacts (toutes sous `flutter-verrou.ps1`)

| Commande | Résultat |
|---|---|
| `dart run slang` | `Translations generated successfully` |
| `dart analyze --fatal-infos lib/features/tc_observation_ui lib/core/tc_observation lib/core/i18n test/teaching_core/g` | 1re passes : 1 erreur (`Override`), 1 avertissement, 1 info ; finale `No issues found!` |
| `flutter test salle_observation_test` (passes intermédiaires) | `+1 -?` : décompte non repeint (un `pump` ne suffisait pas → `pumpAndSettle`) ; `sortir` serveur jamais atteint en test (annulation d'abonnement = futur de zone racine, non avancé par l'horloge simulée → tour de vraie boucle `runAsync`) ; débordements à 200 % (barre, bandeau) corrigés |
| `dart run tool/verifier_jetons.dart` | `Jetons verifies : 424 fichiers, aucune violation.` |
| Finale : `flutter test --no-pub test/teaching_core/g test/tc_observation test/config/fixtures_isolees_test.dart test/i18n test/teaching_core/q/q03_quota_observation_tuteur_test.dart test/features/accueil_famille_test.dart test/features/observation_groupe_admin_test.dart test/router/navigation_test.dart` | `03:58 +277 ~43: All tests passed!` (journal `o2_tests.log` ; ~43 = captures sautées) |
| Captures (`CAPTURE_DIR`, `CAPTURE_MAQUETTE_M4/M3/D1`) | `+21: All tests passed!` |

18 tests dans `salle_observation_test.dart` (tous partent d'une classe double et TOUCHENT Observer la séance, Observer maintenant, Agrandir, Réduire, Quitter, Annuler, Quitter la visite, retour système) + 1 parcours depuis la vraie coquille à 390 (Assister → Observer maintenant → salle → Agrandir → Quitter → confirmer).

### Captures (`captures/`, lues)

`o2_salle_390x844@3_{light,dark}`, `o2_salle_1440x900@1_{light,dark}`, `o2_quitter_390x844@3_{light,dark}`, `o2_quitter_1440x900@1_light`, `o2_salle_1024x768@1_light`, `o2_salle_844x390@3_paysage_light`, `o2_agrandi_{390x844@3,1440x900@1}_light`, `o2_reconnexion_390x844@3_light`, `o2_fin_proche_390x844@3_light`, `o2_derniere_visite_390x844@3_light`, `o2_salle_vide_390x844@3_light`, `o2_video_indisponible_390x844@3_light`, `o2_texte200_390x844@2_light` ; planches `o2_salle_mobile_contre_maquette_M4`, `o2_salle_mobile_sombre_contre_maquette_M3`, `o2_salle_bureau_contre_maquette_D1` ; maquettes découpées `maquettes/{M4_salle_claire,M3_salle_sombre,D1_salle_bureau}.png`. « Vidéos » = aplats de test, jamais une photo.

Corrigés après lecture des planches : libellés de commandes coupés à 390 (« Agrandi / r ») → `labelMedium` sur téléphone ; état vide du support en titre de page → phrase discrète ; titre d'en-tête trop grand → `titleMedium` ; bureau en éléments posés sur le fond → une carte comme D1 ; vignettes masquées sur écran court → seuil de défilement abaissé.

Écarts de planche restants, assumés : bandeau du décompte au lieu de la pastille « Visite n/N · mm:ss » (décision du directeur) ; bandeau à la largeur du contenu, 24 dp sous le haut (O-11) ; support vide (aucun support partagé dans le produit ; contenu arabe des maquettes non reproduit, V8) ; pas de chevron (sortie unique = Quitter) ; icône « Agrandir » = cible du dock (O-10) ; « Son reçu » témoin et non bouton (O-9) ; sur la planche M4 (maquette tronquée à ~564 dp) les vignettes passent sous le pli et la salle défile, elles sont visibles à 390x844 ; M3 sombre : « Quitter » en pilule rouge douce (un style par format, manifeste §5) au lieu du bouton plein.

### Écarts restants pour le sous-paquet 3

Fin de visite (base : `EmptyState` + retour) : M5 et variantes ; `refus.politiqueDesactivee` (« groupe ») ; si la visite se termine pendant que la confirmation est ouverte, la feuille reste jusqu'à « Annuler » (sans effet).

### Demandes au coordinateur (nouvelles)

`demandes/O.md` O-9 (commande du son reçu dans `VideoSessionProvider`), O-10 (icônes agrandir/réduire), O-11 (emplacement de bandeau pleine largeur dans `PageShell`).

## Sous-paquet 3 : Fins de visite et états particuliers (25/09/2026, reprise poste B à 08 h 18)

Commits : `9bfbb6a` (travail de l'agent coupé du poste A), `cb66783` (validation par le coordinateur B, sans changement de code).

Écran livré : fin de visite M5 (`resultat_visite_page.dart`), sans en-tête ni navigation, retour système = « Retour à la classe ». Variantes : première / dernière visite, durée atteinte (budget épuisé par le serveur), fin de séance (`seanceNonActive`, `horsFenetre`), observation interrompue (reconnexion échouée : `interrompre()` referme l'intervalle), observation retirée (`policyDesactivee`, `lienTuteurAbsent`), visites restantes relues au serveur (en lecture, lues, illisibles : rien de supposé), sortie non confirmée, confirmation « Quitter » refermée si le serveur termine la visite. « Voir mes observations » ouvre l'Historique, segment Observations. Décisions respectées : 2 visites de 2 min par parent et par séance, lues sur la politique (jamais en dur) ; visite écourtée consommée ; `OBSERVATION_TUTEUR_REELLE` inchangé (fermé en production). Vocabulaire « classe » dans `refus.politiqueDesactivee`.

Commandes (sous verrou) : `dart analyze --fatal-infos lib/features/tc_observation_ui lib/core/tc_observation lib/core/i18n test/teaching_core/g` : No issues found! ; `flutter test --no-pub test/teaching_core/g test/tc_observation test/i18n test/router/navigation_test.dart` (CAPTURE_DIR) : `+307 ~5: All tests passed!` ; frontière (supabase, .github, vercel.json, pubspec.yaml, theme, router, widgets, Coran) : vide.

Tests qui tapent : Retour à la classe, Voir mes observations, retour système, Quitter + confirmer (`fin_visite_test.dart`, 17 cas) ; vraie coquille Accueil -> Assister -> Observer maintenant -> Quitter -> fin -> Voir mes observations (`entree_observation_navigation_test.dart`).

Captures (lues) : `o3_fin_390x844@3_{light,dark}`, `o3_fin_1440x900@1_{light,dark}`, `o3_duree_atteinte`, `o3_fin_seance`, `o3_visites_epuisees`, `o3_interrompue_390x844@3_light`, `o3_interrompue_1440x900@1_dark`, `o3_restantes_inconnues`, `o3_texte200`. Écart assumé : sablier au lieu de l'horloge de M5 (icône absente d'AppIcons, demande O-4) ; titre sur une ligne à 390. Planche automatique sautée (maquette M5 attendue sous l'ancien chemin D:\) ; planche du 25/09 06 h 51 conservée.
