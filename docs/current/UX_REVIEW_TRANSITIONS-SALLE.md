# UX_REVIEW — lot TRANSITIONS-SALLE (11/11/2026)

Demande du directeur (11/11/2026, relayée par le garde-cap) : les transitions de la salle (entrer,
sortir, ouvrir et fermer un panneau, le tiroir, passer d'un support à l'autre, le chrono), dans le
même langage que le reste de l'application. Règles arbitrées : avis du pilote retenu par le
garde-cap. Statut : **présent dans le code, testé localement** (tests de widgets, captures de
test). **Rien n'est vu sur la vraie application.**

## Règles appliquées, source, conclusion

| # | Règle | Source | Conclusion dans le code |
|---|---|---|---|
| 1 | Ce qui se déplace suit un mouvement physique, sans rebond pour un élément d'interface utilitaire | Material 3 Motion (« Easing and duration », springs) ; décision du directeur du 10/11 (aucun rebond) | `AppMouvement.ressortDeplacement` : ressort à amortissement critique ramené à la durée du jeton (aucun dépassement, testé sur 100 points) |
| 2 | Un fondu suit une courbe simple | Material 3 Motion (fade through, « emphasized decelerate » pour les entrées) | `AppMouvement.courbeFondu` (`easeOut`) |
| 3 | La sortie est plus rapide que l'entrée | Material 3 Motion (« exit transitions are shorter ») | Sortie = 2/3 de l'entrée pour chaque paire de jetons (testé : 0,6 à 0,72) |
| 4 | Durées de 200 à 300 ms, plus courtes sur ordinateur | Material 3 Motion (durées « medium ») ; Apple HIG Motion (« brief and precise ») | Téléphone 280 / 190 ms ; ordinateur 240 / 160 ms ; fondus 200 / 130 ms |
| 5 | Aucun retard au toucher ; transition interruptible | Apple HIG Motion (« don't make people wait », animations interruptibles) | Les contrôleurs repartent de leur valeur courante (testé à mi-course pour les panneaux, le voile, le fondu de support) ; les voiles ne reçoivent aucun geste |
| 6 | Le mouvement peut être réduit | WCAG 2.2 SC 2.3.3 (Animation from Interactions, AAA) ; Apple HIG (Reduce Motion) | `mouvementReduit` : panneaux et feuilles posés sans mouvement ; arche et retour depuis l'île en fondu seul ; fondu de support supprimé (testé) |
| 7 | Rien qui clignote ; rien qui bouge plus de 5 s sans commande d'arrêt | WCAG 2.2 SC 2.3.1 (Three Flashes) et 2.2.2 (Pause, Stop, Hide) | L'arche joue une fois (700 ms) puis reste immobile ; aucune boucle ajoutée (testé : plus aucune animation après) |
| 8 | Une seule animation d'entrée par arrivée ; jamais rejouée à une reconnexion, au retour d'une veille, après un rechargement | Arbitrage du pilote | Panneaux : rien au montage ; arche : une fois par écran, jamais si l'appel est tenu (retour depuis l'île) ni si `RepriseSalle` porte la séance (rechargement) ; testé |
| 9 | Rien ne réduit ni ne pousse la page du Coran ; un panneau qui s'ouvre ne fait pas sauter la page | Règle absolue du directeur | La page de l'ordinateur change de largeur sur le MÊME ressort que le panneau, l'écart de 16 compris : aucun saut (testé : aucune image ne prend plus de 40 % du chemin, aucun retour) |
| 10 | L'arche se joue pendant le délai réel, jamais en plus | Arbitrage du pilote | La salle prête remplace l'arche à la même image qu'avant (test qui compte les images avec et sans arche : égales) ; un voile qui ne prend aucun geste s'efface en 150 ms par-dessus la salle déjà utilisable |
| 11 | Logo : jamais redessiné, déformé, recoloré, animé | `assets/brand/logo/README.md`, compétence `marque-rewayah` | Le symbole passe par `BrandLogo`, violet sur la lumière claire de la porte ; il n'est pas animé : la porte, peinte à part (une forme simple), s'ouvre devant lui |

## Ce qui est livré, transition par transition

1. **Entrer : le moment de l'arche** (`lib/core/widgets/entree_arche.dart`, `EntreeArche`). Pendant
   la vérification du matériel, la demande du jeton et la connexion, l'arche tient la place de la
   scène d'attente : la carte de la salle s'assombrit (couche sombre dans les deux thèmes), le
   contour d'une arche paraît, la porte s'ouvre par le milieu sur une lumière claire où se tient le
   symbole, la lumière s'étire au sol. 700 ms, puis immobile. Les mots de l'attente restent en tête,
   « Quitter » reste en bas, la mention « Visite de contrôle possible. » reste lisible. Salle prête :
   `PassageSalle` (voile, 150 ms) passe la main. Mouvement réduit : l'image finale en un fondu.
2. **Sortir** (`PassageSalle`, `FaconPassage.fondu`) : de la salle vers l'écran de fin ou une
   impasse, un fondu de 150 ms, sans voile ni arche. Une sortie vers un autre écran de
   l'application (`go`) garde la transition de page du routeur (non touchée).
3. **Réduire la salle et y revenir (version sobre)** : l'île arrive en se resserrant vers sa place
   (`_RepliVersIle`, `barre_seance_en_direct.dart`) ; « Retourner dans la salle » redéplie la salle
   depuis le haut (`FaconPassage.depuisIle` : échelle 0,94 vers 1, fondu, ressort). **Version
   sobre, et c'est voulu** : la vraie morphose « la surface devient l'île » demanderait une
   transition de page sur mesure pour `/salle` dans le routeur (hors de ma zone) ; la transition
   de page du routeur s'ajoute donc à ces deux mouvements.
4. **Panneaux de l'ordinateur** (`PanneauGlissant`, `salle_ordinateur.dart`) : glissement depuis
   leur bord sur le ressort, contenu en fondu, fermeture plus rapide, la page suit sans saut.
   **Tiroir et feuille du téléphone** (`MonteeDuBas`, `telephone_enseignant.dart`) : montée du bas
   dans leur propre place, rognée à leurs bords : jamais par-dessus la pilule.
5. **D'un support à l'autre** (`FonduAuChangement`, `zone_support.dart`) : fondu court quand le
   support change (scène, tableau, page fixe et laquelle, diapositive, rien). Tourner la page ne
   change pas l'identité. **Tourner la page** : `GlisserPage` vérifié, inchangé : le geste suit le
   sens du support (mushaf : glisser vers la droite amène la suivante), en français comme en arabe ;
   déjà testé (`test/features/salle_seance/glisser_page_test.dart`, « le sens est celui du support,
   pas celui de l'interface »).
6. **Chrono et île** : vérifiés, non modifiés. `IleLiquide` ne bouge que quand sa taille cible
   change ; `ChronoVivant` respire à son arrivée et à chaque changement d'état (calme, bientôt,
   dépassement, fini), rien entre deux. **Écart relevé** : la respiration d'arrivée du chrono se
   rejoue quand la salle est remontée (retour depuis l'île), ce qui contredit la règle 8 ; à
   corriger dans `chrono_vivant.dart` (hors de ma zone).
7. **Annonces de tête** (`annonce_geste.dart`, `entreeParLeHaut`) : entrée par le haut (40 % de leur
   hauteur) sur le ressort en 280 ms, sortie en fondu seul en 190 ms.

## Écarté, et pourquoi

- **Le paquet `animations` et le « container transform »** pour la navigation : interdits par
  l'arbitrage (`pubspec.yaml` interdit, aucune dépendance) et trop chargés pour ce public.
- **Une arche plein écran qui recouvre tout pendant l'attente** : elle aurait caché « Quitter » et
  la mention de la visite de contrôle pendant une connexion qui peut durer ; l'arche vit dans la
  carte de la salle, l'en-tête et les commandes restent.
- **Une arche jouée même sans attente (600 à 800 ms imposées)** : ce serait « en plus » ; l'arche
  n'existe que pendant une attente réelle. Si la salle s'ouvre avant la fin des 700 ms, l'arche est
  retirée inachevée.
- **Un fondu enchaîné qui superpose deux supports** : écarté pour la règle LG-FLASH (deux textes
  mêlés) ; le nouveau support apparaît en fondu court sur la surface, l'ancien n'est plus là.
- **Une porte qui se referme à la sortie** : interdite (sortie immédiate, aucun moment de marque).
- **Animer la sortie du tiroir et de la feuille du téléphone** : ils sont retirés de l'arbre par
  `telephone_plein_ecran.dart` (zone d'un autre agent) ; seule l'entrée est animée. Leur sortie
  reste immédiate (non conforme à « fermeture plus rapide », à faire dans ce fichier).

## Preuves

- `test/core/mouvement/transitions_salle_test.dart` (22 tests) : ressort sans dépassement, rapport
  sortie / entrée, panneau au départ, à l'arrivée, interrompu, en mouvement réduit, en arabe ;
  feuille qui monte sans passer sur la pilule ; voile qui laisse passer les gestes ; sortie en
  fondu ; retour depuis l'île ; fondu de support ; arche qui finit et ne boucle pas ; annonces.
- `test/features/salle_test.dart`, groupe « TRANSITIONS-SALLE » : la vraie salle sur un moteur
  lent ; l'arche pendant la connexion ; la salle arrive à la même image avec et sans arche, et
  reçoit les gestes à cette image.
- Captures de test (décor de l'écran réel, `SallePage` montée) :
  `docs/current/captures/E2E/transitions-salle/` (arche à trois instants, passage, salle ; 390 et
  1440, clair et sombre, une série en arabe).
