# FABLE_CLASSROOM_TEST_MATRIX — ce qui a été exécuté, et ce qui ne l'a pas été

Agent Fable · lot 2 « Classroom Experience » · branche `core24/fable-frontend` · 22/09/2026.
Valeurs : **PASS** (exécuté, vert) · **FAIL** (exécuté, rouge) · **NOT EXECUTED** (possible ici, pas fait) · **BLOCKED BY ENVIRONMENT** (impossible sur ce poste). Jamais PASS sans exécution.

Poste : Windows 10 Pro 19045, Flutter stable, `flutter devices` = Windows (desktop), Chrome 153, Edge 151. Aucun appareil Android connecté, aucun macOS.

## 1. Validation technique (§21)

| Étape | Commande | Résultat |
|---|---|---|
| Format | `dart format` sur les 31 fichiers Dart touchés | PASS (0 changé après passe) |
| Analyse | `dart analyze lib test` | PASS (No issues found) |
| Jetons de design | `dart run tool/verifier_jetons.dart` | PASS (358 fichiers, 0 violation) |
| Tests ciblés lot 2 | `flutter test` sur `test/teaching_core/{c,e,f}` + routeur + points d'entrée | PASS (voir §2) |
| Suite existante | `flutter test --concurrency 2` | voir ligne « Suite complète » en §2 |
| Goldens | goldens Coran du lot C (`corpus_reference`) réutilisés par les tests de sélection et de support | PASS (aucun golden d'image modifié) |
| Build web | `flutter build web --release` (relancé sur l'état final commité, 345 s) | PASS (`main.dart.js` 5 419 976 octets) |
| Lancement réel Chrome | `flutter run -d chrome` sur une séance vivante | NOT EXECUTED (exige un compte connecté, une séance planifiée et un jeton LiveKit émis par le serveur ; non fait dans ce lot) |
| Android build/test | `flutter build apk` / test sur appareil | NOT EXECUTED (aucun appareil ni émulateur connecté pendant le lot) |
| iOS | build ou test | BLOCKED BY ENVIRONMENT (aucun macOS) |

## 2. Tests automatisés, par fonction

Chaque ligne est un fichier exécuté sur ce poste. « Comportement » dit ce que le test prouve, pas l'existence d'un widget.

| Fichier | Comportement prouvé | Résultat |
|---|---|---|
| `test/teaching_core/f/adaptateur_transport_livekit_test.dart` (12) | transport complet ; capacités recopiées du jeton ; refus de droit avant tout ; hors salle refusé ; canal fiable sous sujet nu, éphémère sous suffixe `-l` ; destinataires transmis ; réception fiable/éphémère ; refus moteur → `EchecTransport` ; rien ne part par la primitive coranique du socle | PASS |
| `test/teaching_core/e/support_coran_classe_test.dart` (7) | deux appareils, un bus, un backend mémoire : B sans support l'élève le lit ; A présenter arrive chez les deux ; A aller à un verset déplace la classe ; B l'élève qui feuillette voit « revenir », jamais avant, et ne publie rien ; A le pilote qui feuillette publie une fois après l'arrêt ; A un focus devient une révision et l'élève passe en focus ; zoom élève survit à une page tournée (D-21) ; arrivant tardif reçoit la republication | PASS |
| `test/teaching_core/c/selection_verset_test.dart` (3) | sous la portée un tap sélectionne, un second désélectionne ; hors portée un tap ne fait rien ; la page du mushaf sélectionne aussi | PASS |
| `test/teaching_core/e/lot2_classe_test.dart` (14 déclarations, le rappel joué par rôle) | ordre des états périphérique ; seuls fermé/ouvert se règlent ; caméra absente dite, pas cachée ; lien sain muet ; commandes rondes, micro par son acte ; téléphone portrait vignette SOUS le support ; téléphone paysage composition courte ; dock hébergé sans couvrir ; élève sans dock et lit sa présence ; rappel par rôle (contrôleur, admin incognito, tuteur) ; sans groupe le cours a un nom ; enseignant sort vers le cahier ; élève sort vers sa racine ; écran court = téléphone | PASS |
| `test/teaching_core/e/classe_live_page_test.dart` (20) | bureau roster en colonne ; téléphone roster en feuille ; sans support la vidéo reprend la place ; support non branché dit ; photo manquante dite ; roster indisponible ≠ vide ; élève sans liste des camarades ; 15 élèves tiennent ; démonter ne coupe pas ; Bibliothèque ne déconnecte pas ; retour de suspension ; quitter annonce avant de déconnecter ; reconnexion dite, salle montée ; lien sain muet ; rappel qui échoue seul parle ; choisir pour réciter ne change pas le support ; annonces tuteur avec temps restant ; élève ne lit pas les annonces | PASS |
| `test/core/router/*`, `test/features/{journee,accueil_eleve,accueil_famille,controleur}*` | `/salle` rend la coque unique à partir d'un `BilletSalle` ; les quatre points d'entrée construisent le billet (groupe, libellé, prénom, seuil) | PASS |
| Suite complète (`flutter test --concurrency 2`) | tout le dépôt : 1786 tests, 0 échec, 10 min 56 s (départ du lot : 1808 ; les 2 fichiers de l'ancienne coque retirés, les nouveaux ajoutés) | PASS |

Supprimés avec l'ancienne coque : `test/features/salle_test.dart`, `test/features/salle_enseignant_test.dart` (leurs comportements encore pertinents sont repris dans `lot2_classe_test.dart` et `classe_live_page_test.dart` ; les comportements propres à `PanneauEnseignantSalle` disparaissent avec lui).

## 3. Scénarios à prouver (§19)

| Scénario | Preuve automatisée | Preuve sur appareil réel |
|---|---|---|
| A. Enseignant : entrer → Bibliothèque → Coran → page/verset → navigation → outil → sortie | PASS par widgets : Bibliothèque (panneau/feuille), « Présenter le Coran », déplacement, focus, publication après arrêt, sortie vers le cahier | NOT EXECUTED |
| B. Élève : bascule propre → suivi → changement page/verset → aucune commande enseignant → réseau instable → reconnexion → état restauré | PASS par widgets : suivi, « revenir au professeur », pas de dock ni de pilotage, reconnexion dite ; restauration = republication à l'arrivée (test « arrivant tardif ») | NOT EXECUTED |
| C. Mobile portrait sans overflow ni contrôle couvrant le Coran | PASS à 390×844 (vignette sous le support, dock hébergé, aucun overflow levé par le framework) | NOT EXECUTED (aucun Android) |
| D. Web/Desktop : resize, clavier, focus, panneau Bibliothèque, dock | PASS par widgets au gabarit bureau (panneau latéral, Échap ferme le panneau) ; resize réel et navigation clavier complète | NOT EXECUTED |
| E. Aucun support : salle équilibrée | PASS (« sans support, la vidéo reprend la place », « aucun support » dit une fois par surface) | NOT EXECUTED |
| F. Observation : tuteur / admin visible / admin incognito / contrôleur | PASS par widgets : rappel par rôle, élève sans liste, capacités depuis le jeton (inchangées, lot N3/CTR-01) | NOT EXECUTED |

## 4. Plateformes (§20)

| Plateforme | Résultat | Détail |
|---|---|---|
| Android téléphone compact portrait | NOT EXECUTED | composition prouvée par widgets à 390×844 seulement |
| Android téléphone paysage | NOT EXECUTED | composition prouvée par widgets à 844×390 seulement |
| Android tablette | NOT EXECUTED | gabarit tablette couvert par les tests existants de `classe_live_page_test.dart` |
| Web fenêtre étroite | NOT EXECUTED | build web PASS ; rendu réel non ouvert |
| Web laptop | NOT EXECUTED | idem |
| Web grand écran | NOT EXECUTED | idem |
| iPhone portrait/paysage | BLOCKED BY ENVIRONMENT | aucun macOS ; iOS n'est pas annoncé validé |
| iPad | BLOCKED BY ENVIRONMENT | idem |

## 5. Ce que la matrice ne dit pas

- Le transport LiveKit réel n'a été exercé que par le faux moteur (`FauxMoteurSalle`) : la primitive `publierDonnees`/`donneesRecues` du socle est appelée telle quelle, mais aucun paquet n'a traversé un SFU pendant ce lot.
- La persistance serveur de l'état partagé reste en mémoire (`EtatPartageMemoire`) : voir `CONTRACT_REQUEST_FABLE_CLASSROOM.md` demande 1. Un élève qui recharge la page dépend donc de la republication de l'enseignant (déclenchée à chaque arrivée de participant).
- Lecteur d'écran, contraste et RTL n'ont pas été mesurés avec un outil ; seules les étiquettes sémantiques ajoutées (verset sélectionné, commandes rondes) sont couvertes par les tests.
