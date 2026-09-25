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
