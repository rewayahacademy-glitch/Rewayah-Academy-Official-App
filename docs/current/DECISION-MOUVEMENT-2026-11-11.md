# Décision : la grammaire du mouvement (directeur, 11/11/2026)

Lot TRANSITIONS, validé par le directeur le 11/11/2026 : « finir une fois pour toutes ». Ce
document vient du conseil de Fable et des arbitrages du garde-cap. Un agent l'applique tel quel :
il ne réinvente pas une transition, il choisit son type dans le catalogue.

## 1. Le sens des axes

| Relation entre deux surfaces | Mouvement | Type du catalogue |
| :--- | :--- | :--- |
| Avancer ou reculer dans une hiérarchie (liste vers fiche, retour) | **horizontal** : axe partagé, en miroir en arabe | `TypeTransition.descente` |
| Deux destinations de même niveau (onglets) | **sur place** : fondu enchaîné, sans glissement | `TypeTransition.onglet` |
| Une surface temporaire qui monte du bas | **vertical** : montée, fermeture en tirant | `TypeTransition.feuille` |
| Une fenêtre au-dessus (dialogue, confirmation) | **profondeur** : zoom léger (0,94 vers 1) et fondu | `TypeTransition.fenetre` |

Jamais deux axes pour la même relation. Sur ordinateur, la même surface devient une fenêtre
dès la classe étendue (840 px, `AppGabarit.seuilEtendu`) : une feuille du bas y est une boîte de
dialogue (`AppBottomSheet.ouvrir`).

## 2. Le catalogue, à un seul endroit

- **`lib/core/mouvement/app_transitions.dart`** (`AppTransitions`) : seul fichier qui définit une
  transition.
- **Durées et courbes : `lib/core/theme/app_mouvement.dart`**, sans seconde échelle :
  - `navigation` vaut 220 ms (ordinateur) et `descente` 280 ms (téléphone) ;
  - `feuilleOuverture` vaut 180 ms et `feuilleFermeture` 120 ms ;
  - `echelon` vaut 35 ms et `plafond` 400 ms ;
  - les courses de l'axe partagé valent 30 (téléphone) et 24 (écran large).
- **La sortie dure environ les deux tiers de l'entrée** (`AppTransitions.sortieDe`).
- **Deux familles de mouvement :**
  - ce qui se déplace suit une courbe d'entrée ou un ressort sans dépassement (`AppMouvement.ressort`, `ratio: 1`) ;
  - les fondus suivent une courbe simple (`AppMouvement.selection`).
  - Ni rebond, ni secousse.
- **Le catalogue est appliqué à trois endroits, jamais écran par écran :**
  1. le thème (`AppTheme.pour`, `pageTransitionsTheme: AppTransitions.theme`) : toutes les pages Material, donc toutes les routes `builder` du routeur ;
  2. `pageGlissee` (`lib/core/mouvement/transitions.dart`) : les routes `pageBuilder` ;
  3. `AppBottomSheet` (`lib/core/widgets/app_bottom_sheet.dart`) : feuilles du bas et dialogues.
- **Test-garde :** `test/mouvement/catalogue_transitions_test.dart` refuse toute transition définie ailleurs (`CustomTransitionPage`, `PageRouteBuilder`, `transitionsBuilder`, `showDialog`, `showModalBottomSheet`…).

## 3. Les règles

1. **Onglets :** fondu enchaîné, 200 à 220 ms, sans glissement (`FonduOnglet`, sur le fond opaque du thème).
2. **Liste vers fiche :** axe partagé horizontal, inversé au retour, en miroir en arabe.
   - Sur ordinateur : course courte (24) et 220 ms. Sur téléphone : 30 et 280 ms.
   - En deux volets, aucun changement de page : fondu enchaîné dans le volet.
3. **Pas de « la carte devient la page » pour la navigation.** Séance, enfant et classe se
   rejoignent par l'axe partagé, comme toute fiche. L'agrandissement d'une carte est réservé aux
   aperçus modaux fermés par un bouton (photo, support).
4. **Feuilles du bas :** montée, fermeture en tirant. **Confirmations :** zoom léger et fondu.
5. **Listes en décalé (`ApparitionDouce`) :**
   - les 6 à 8 premiers éléments, 35 ms d'écart, moins de 300 ms en tout ;
   - jamais après un rafraîchissement, au retour sur la page ou juste après un squelette.
6. **Squelette vers contenu :** un fondu, sans saut de mise en page (`BasculeEtat`, dans `BlocAsynchrone`).
7. **Échec d'une action instantanée** (`DECISION-FLUIDITE`) : retour doux et une phrase, jamais de secousse.
8. **Interruption :** un nouveau geste reprend d'où en est la transition. Aucune entrée n'est bloquée pendant une transition.
9. **Web :**
   - un retour (bouton ou geste du navigateur) joue un fondu court, jamais une seconde animation par-dessus celle du navigateur ;
   - un retour par la flèche de l'application joue l'axe partagé inverse, comme ailleurs ;
   - le retour prédictif d'Android ne concerne que l'application du magasin ;
   - ne pas compter sur les View Transitions.
10. **Natif :** iOS et macOS gardent la transition du système, avec le retour par glissement. Android garde le retour prédictif.
11. **Position de défilement :** elle est conservée au retour sur une liste.
12. **Accessibilité :**
    - au changement de page, le focus va au titre et le lecteur d'écran l'annonce (WCAG 2.4.3) ;
    - rien ne clignote ;
    - **mouvement réduit = rien** (durée nulle), ou un fondu seul.
13. **Une seule animation d'entrée par arrivée :** pas de page qui glisse, plus une liste en décalé, plus un halo.
    - Rien ne se rejoue au rechargement, à la reconnexion ou au retour de veille.
14. **Budget :**
    - un seul grand calque animé à la fois ;
    - jamais de flou ni d'ombre animés ;
    - toute transition se termine ; une boucle a son interrupteur dans `flutter_test_config`.
15. **Fonds :** ils suivent le thème choisi, et aucune image claire ne passe en sombre (`SOMBRE-SANS-ECLAIR`, PR 430).

## 4. Hors de ce catalogue

- **La goutte d'huile reste un indicateur local** (barre de navigation, rangée des profils). Elle ne sert pas aux transitions de page.
- **Les halos et les lumières** suivent `A-FAIRE-LUMIERE-ACCUEILS.md` : une seule lumière en mouvement par écran.
- **La salle (`/salle`) appartient à Fable** (directeur, 10/11/2026) : entrée, sortie, réduire et redéplier. Elle n'est pas dans ce catalogue.

## 5. Ce qui reste à faire, constaté le 11/11/2026

- Les deux pages poussées à la main (`admin_offres_page.dart`, `foyer_page.dart`) suivent déjà le
  catalogue par le thème. Les ramener au routeur (routes, redirections, tests) reste à faire.
- Focus au titre et annonce au changement de page (règle 12) : non vérifié écran par écran.
- Position de défilement au retour (règle 11) : non vérifiée écran par écran.
- Distinguer, sur le web, un retour venu du navigateur d'un retour par la flèche de
  l'application : **présent dans le code** (`lib/core/mouvement/retour_navigateur.dart`,
  test `test/mouvement/retour_navigateur_test.dart`). Un `popstate` du navigateur marque les
  600 ms suivantes : le retour joue le fondu court ; la flèche de l'application joue l'axe
  partagé inverse. **Non prouvé dans un navigateur** : qu'une flèche de l'application ne
  déclenche aucun `popstate` reste à vérifier sur un aperçu.
