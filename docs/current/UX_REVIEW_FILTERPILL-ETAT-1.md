# UX_REVIEW_FILTERPILL-ETAT-1 : l'état retenu d'une `FilterPill` (09/10/2026)

- **Étape** : FILTERPILL-ETAT-1, relevée par la vérification de DISPO-1 sur la feuille
  « Ajouter une plage » (jours retenus distingués par le seul fond et le seul contour).
- **Cadre** : `lib/CLAUDE.md` (« Un état ne se signale jamais par la couleur seule : texte
  ou icône en plus de la couleur ») ; `03_DESIGN_SYSTEM_ET_UX.md` ; DESIGN-GOV-2026-09-26
  (aucune couleur, police, durée ni jeton nouveau, K-37).
- **Sources** : WCAG 2.2, 1.4.1 Use of Color (une information ne passe pas par la seule
  couleur) et 4.1.2 Name, Role, Value (l'état est exposé aux technologies d'assistance) ;
  composants du dépôt qui le font déjà : `ChoiceCardGroup` (coche `AppIcons.succes` en graisse
  pleine sur une carte retenue) et `MenuFiltre` (même coche, taille `AppSpacing.lg`, devant la
  valeur courante). Pas de navigation web dans cette session : règles citées de mémoire.
- **Portée** : le seul composant partagé `lib/core/widgets/filter_pill.dart` ; tous les
  appelants (feuille de plage, filtres d'administration, cahier, catalogue, foyer, sélecteurs
  de niveau et de motif, galerie) en profitent sans être modifiés. Une seule exception, de
  mesure et non d'apparence : `RangeePuces` (`selecteur_motif.dart`) recopiait le retrait de
  la pilule ; il le lit désormais sur `FilterPill.retraitLargeur`.

| Point | Règle | Conclusion (décidé par délégation le 09/10) |
|---|---|---|
| Forme qui double la couleur | 1.4.1 ; `lib/CLAUDE.md` | Une **coche** (`AppIcons.succes.actif`, Phosphor plein, déjà employée par `ChoiceCardGroup` et `MenuFiltre`) devant le libellé, à la couleur du libellé (`washAccent.onBackground`), taille `AppSpacing.lg`, écart `AppSpacing.sm` (celui du compteur). Absente au repos. Fond doux et filet fort conservés. |
| Lecteur d'écran | 4.1.2 | Un **seul nœud** : bouton, `selected`, libellé (compteur compris) dit une fois. Avant : `selected` sur un nœud sans libellé, au-dessus d'un nœud qui disait le libellé deux fois (« Lundi Lundi », mesuré par le test). La coche n'ajoute aucun mot. |
| Largeur à la sélection | Stabilité de la mise en page sous le doigt | **Largeur constante** : la place de la coche est réservée dans les deux états, en air réparti des deux côtés du libellé au repos (libellé centré, K-54), occupée par la coche une fois retenue. Une pilule touchée ne grandit pas et ne renvoie pas ses voisines à la ligne dans un `Wrap` (jours, filtres admin). Prix : +24 px par pilule (16 + 8), mesuré. Rejeté : la pilule qui grandit (recomposition de la rangée à chaque touche) et une coche serrée dans le retrait existant (libellé à moins de 8 px du bord arrondi à texte ×2). |
| 320 px, texte ×2, RTL, clair et sombre | K-54 ; DESIGN-GOV | Coche dans la pilule, contenu (coche + libellé) centré à 1 px près, coche placée avant le libellé dans le sens de lecture (à droite en RTL), aucun débordement : tests du composant et garde K-54. |

Preuves : `test/core/widgets/filter_pill_test.dart` (contre-épreuve sur l'ancien composant :
6 échecs sur 11), `test/core/garde_interface_test.dart`, captures dans
`docs/current/captures/FILTERPILL-ETAT-1/`.
