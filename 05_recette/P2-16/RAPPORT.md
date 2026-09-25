# P2-16 : effets et animations du role Tuteur (etape 1 : socle et transitions)

Branche `ui/tuteur-v1-anim` (base origin/ui/tuteur-v1 @ f93272b), commit `1b7a0c7`. Session B-2026-09-25-coord.

## Etat des lieux (avant)
Presque rien : un `AnimatedSwitcher` (lib/core/widgets/local_feedback.dart), un `ScaleTransition` au toucher (lib/core/widgets/pressable.dart, accueil_eleve). Aucune transition de page personnalisee : go_router utilisait la transition par defaut de la plateforme ; changement d'onglet sec.

## Socle livre : lib/core/mouvement/
- `mouvement.dart` : durees 150 / 220 / 280 ms (borne 300), echelon 35 ms, 8 elements echelonnes maximum, courbes easeOutCubic / easeInCubic / easeInOutCubicEmphasized ; `Mouvement.reduit(context)` et `Mouvement.duree(context, d)` (zero si « reduire les animations »).
- `apparition_douce.dart` : `ApparitionDouce` (fondu + glisse de 12 px, une seule fois, TweenAnimationBuilder implicite, RepaintBoundary), `ElementEchelonne`, `ListeEchelonnee` (seuls les 8 premiers s'animent).
- `bascule_etat.dart` : `BasculeEtat` (AnimatedSwitcher chargement -> contenu -> erreur, fondu 220 ms).
- `transitions.dart` : `pageGlissee` / `glissee(...)` (CustomTransitionPage : glisse de 6 % depuis le bord de lecture, sens inverse en arabe, + fondu ; 280 ms entree, 220 ms retour) et `FonduOnglet` (fondu 220 ms quand l'onglet change, sans recreer les branches).
Tout est neutralise quand `MediaQuery.disableAnimations` est vrai. Aucune boucle, aucune dependance ajoutee.

## Routeur
- Les 34 routes de la coquille Tuteur (Accueil, Foyer, Historique, Compte et leurs sous-pages) passent de `builder` a `pageBuilder: glissee(...)`.
- `_CoquilleNavigation` : `FonduOnglet` autour du `navigationShell` pour le seul role tuteur (eleve et enseignant inchanges).

## Verifications (sous verrou)
- `dart analyze --fatal-infos` (projet entier) : aucun probleme.
- `flutter test test/mouvement test/router` + navigation/bienvenue, foyer, historique, compte, classe_tuteur, notifications, accueil_famille : 622 verts.
- `flutter test test/capture/coquille_capture_test.dart test/widgets` : 157 verts.
- Tests du socle (test/mouvement/mouvement_test.dart) : durees bornees, disableAnimations = aucune animation pour chaque composant, pumpAndSettle se termine.

## Reste a faire pour clore P2-16
Branchement du socle dans les ecrans (apparition des listes et cartes, BasculeEtat sur les etats de chargement), retour visuel au toucher homogene, barre de navigation animee, mesure de performance avant/apres (60 i/s), captures.

# Etape 2 : socle branche dans les ecrans (commit e53eb6d)

Branche `ui/tuteur-v1-anim` @ e53eb6d (poussee). Branchement fait dans les widgets partages, ce qui couvre d'un coup Accueil, Foyer, fiche enfant, Historique, Compte, Catalogue et Classe, sans surcharger chaque ecran :
- `BlocAsynchrone` (lib/core/widgets/bloc_asynchrone.dart) : chaque passage squelette -> contenu / vide / echec / indisponible se fait par `BasculeEtat` (fondu 220 ms). Un rafraichissement qui reste dans le meme etat ne relance rien. C'est l'apparition douce du contenu de tous les ecrans qui lisent une valeur asynchrone.
- Retour au toucher : l'enfoncement 0.98 de `Pressable` existait deja pour toutes les cartes et boutons partages ; pas de doublon. `AppCard` passe en `AnimatedContainer` (150 ms) : fond et contour de survol, pression et selection changent en fondu au lieu de sauter.
- Cartes de choix (`ChoiceCardGroup`) : la selection passe d'une teinte a l'autre en 150 ms, le point du radio grandit a sa pose.
- Barre de navigation flottante (`nav_shell.dart`) : le soulignement de l'onglet actif s'etire depuis son centre (220 ms, courbe emphasized).
- Compte tuteur : les cartes s'echelonnent (35 ms, 8 premieres au plus).
Tout est coupe quand `MediaQuery.disableAnimations` est vrai ; aucune boucle, aucune dependance.

## Verifications (sous verrou)
- `dart analyze --fatal-infos lib test` : aucun probleme.
- `flutter test` (suite entiere) : 2720 verts, 572 sautes (preexistants), 0 echec.
- Un seul test ajuste : `composants_etats_test.dart` (BlocAsynchrone perdu) attend la fin du fondu (`pump(Mouvement.maximum)`) avant de verifier que le squelette a disparu ; assertion inchangee.

## Reste pour clore P2-16
Echelonnement fin des listes propres a certains ecrans (Historique, Catalogue) si juge utile apres revue visuelle ; mesure de performance (profil 60 i/s sur telephone) ; captures avant/apres.

# Etape 3 : echelonnement Historique et Catalogue, captures (commit 2c82790)

Branche `ui/tuteur-v1-anim` @ 2c82790 (poussee).
- Historique (Seances et Observations) : `CarteLignes` (lib/features/suivi_foyer/composants_historique.dart) fait apparaitre ses lignes en decale via `ElementEchelonne` (8 premieres au plus, les suivantes sans animation). Une seule carte, filets inchanges.
- Catalogue des classes : chaque `CarteClasseOuverte` passe par `ElementEchelonne`.
- Coupe si `disableAnimations` ; aucune boucle ; aucune dependance.

## Verifications (sous verrou)
- `flutter analyze --fatal-infos` : aucun probleme.
- Tests des ecrans touches (historique, classe_tuteur, foyer, notifications, admin_observations, router, rtl_echelle_texte) : 595 verts, 0 echec. Aucun test modifie.
- Captures « apres » (etat final, animations terminees) : 68 images dans `05_recette\P2-16\captures_apres\` (Historique, Compte, coquille ; 390x844, 1024x768, 1440x900 ; clair et sombre). Rendu identique a l'avant une fois le mouvement fini : aucune regression visuelle.

## Reste pour clore P2-16
Mesure de performance (profil 60 i/s) sur le telephone Android du directeur : aucun appareil branche (`adb devices` vide). Demande : brancher le telephone en debogage USB, puis `flutter run --profile` sur Historique, Compte et Catalogue.

# Etape 4 (suite, session B-2026-09-25-coord) : mesure de performance automatisee, suite complete, taille web

Branche `ui/tuteur-v1-anim` @ `c5e43d0` (poussee).

## Mesure de performance (test automatique, remplace la mesure au telephone : aucun appareil branche)
Nouveau `test/mouvement/performance_parcours_test.dart` : compte les images dessinees (valeur renvoyee par `tester.pumpAndSettle()`) sur 3 parcours du role Tuteur, verifie qu'elles restent sous 40 (soit sous 0,7 s), et qu'aucune animation ne tourne plus une fois stabilise (`tester.binding.hasScheduledFrame` faux).

| Parcours | Images dessinees | Limite | 
|---|---|---|
| Ouverture Accueil | 1 | < 40 |
| Accueil -> Foyer | 4 | < 40 |
| Foyer -> fiche d'un enfant | 4 | < 40 |
| Ouverture Historique | 1 | < 40 |

Sous verrou : test seul verifie 3/3 verts (durée 12 s).

## Reste ouvert a la fin de cette session (35 min)
Au moment de committer, deux mesures longues tournaient encore sous le meme verrou machine (une a la fois, 4 coeurs) et n'ont pas eu le temps de finir dans la fenetre de 35 minutes :
- `flutter test` (suite complete) : lancee, progression saine (aucun echec vu dans le journal partiel), non terminee.
- `flutter build web` (pour la taille de `main.dart.js`, comparaison avant/apres) : en attente du verrou (derriere la suite de tests), non lancee au moment de committer.
- `flutter analyze --fatal-infos` (projet entier, apres ajout du test) : **fait, aucun probleme**.

Reference "avant" deja disponible pour la comparaison de taille web : `C:\RA\lot-fin\build\web\main.dart.js` (build P2-13, base f93272b, sans animations) = **5 926 632 octets (5,65 Mo)**. A comparer au build de `C:\RA\lot-anim` une fois termine.

Captures : aucun ecran modifie depuis l'etape 3 (seul un fichier de test ajoute) -> les 68 captures `05_recette/P2-16/captures_apres` restent valables, pas de regeneration necessaire.

**P2-16 reste en_cours** : prochain agent doit relancer sous verrou (`flutter test` puis `flutter build web`), verifier 0 echec, mesurer `main.dart.js`, completer ce rapport avec les chiffres finaux, puis cloturer (tableau -> fait).
