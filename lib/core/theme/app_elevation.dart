import 'package:flutter/widgets.dart';

import 'app_color_pair.dart';
import 'app_palette.dart';

/// Les quatre niveaux d'elevation, pas un de plus.
///
/// Source : `docs/produit/design-tokens.md` section 9.
/// **C'est le seul fichier du depot autorise a construire une [BoxShadow]** :
/// `tool/verifier_jetons.dart` echoue si une ombre est composee ailleurs.
///
/// L'absence totale d'elevation etait l'un des deux defauts qui dataient le
/// plus le premier rendu, avec l'absence de crenage
/// (`docs/design/01-systeme-visuel.md` section 1).
///
/// Deux regles d'emploi, et elles se tiennent :
///
/// - **une carte n'est jamais posee sur une carte.** Deux plans suffisent a
///   tout le produit ; un troisieme signifie que la hierarchie de l'ecran est
///   fausse ;
/// - **une surface elevee porte un filet ET une ombre**, jamais l'un des deux
///   seul. Le filet tient sur un ecran mal calibre et en contraste eleve,
///   l'ombre donne la profondeur. Voir [avecFilet].
///
/// Les trois niveaux non nuls prennent la couleur d'ombre **de la palette
/// courante** (lot T3, mode sombre) plutot qu'une couleur figee : avant ce
/// lot, ils tiraient silencieusement `AppPalette.claire().ombre`, donc un
/// theme sombre aurait porte l'ombre du theme clair sans que rien ne le
/// signale. `AppPalette.claire().ombre` et `AppPalette.sombre().ombre`
/// valent aujourd'hui la meme teinte (voir la doc de `AppPalette.sombre`),
/// mais le mecanisme ne le suppose plus : il le demande a l'appelant.
abstract final class AppElevation {
  /// Ce qui est pose a plat : sections, separateurs.
  static const List<BoxShadow> niveau0 = <BoxShadow>[];

  /// Cartes, tuiles, lignes cliquables. **Le defaut.**
  ///
  /// Opacites remontees au lot T2 (0.05 -> 0.10/0.09) : a 5%, une carte ne se
  /// detachait pas du fond sur un ecran en plein jour, cause n3 mesuree du
  /// rejet du rendu deploye le 11 septembre 2026.
  static List<BoxShadow> niveau1(AppShadowColor ombre) => <BoxShadow>[
    ombre.asBoxShadow(y: 2, flou: 8, opacite: 0.04),
    ombre.asBoxShadow(y: 8, flou: 24, opacite: 0.06, etalement: -4),
  ];

  /// Ce qui flotte au dessus du contenu : menu, popover, barre collee, carte
  /// pressee. Opacites remontees au lot T2 (0.05/0.08 -> 0.08/0.14).
  static List<BoxShadow> niveau2(AppShadowColor ombre) => <BoxShadow>[
    ombre.asBoxShadow(y: 4, flou: 12, opacite: 0.08),
    ombre.asBoxShadow(y: 16, flou: 40, opacite: 0.10, etalement: -8),
  ];

  /// Ce qui recouvre : feuille de bas d'ecran, boite de dialogue. Opacite
  /// remontee au lot T2 (0.14 -> 0.22).
  static List<BoxShadow> niveau3(AppShadowColor ombre) => <BoxShadow>[
    ombre.asBoxShadow(y: 12, flou: 32, opacite: 0.22),
  ];

  /// Dialogues and menus use a dark raised surface rather than an artificial
  /// shadow in dark mode.
  static List<BoxShadow> dialogue(AppPalette palette) =>
      palette.estSombre ? niveau0 : niveau2(palette.ombreDialogue);

  /// La decoration complete d'une surface elevee : fond, arrondi, filet et
  /// ombre en une fois.
  ///
  /// Passer par ici plutot que de composer une [BoxDecoration] a la main :
  /// c'est ce qui rend impossible la surface qui porte une ombre sans filet,
  /// invisible en contraste eleve, ou un filet sans ombre, plat.
  ///
  /// [ombre] est toujours requis, meme quand [ombres] est fourni explicitement
  /// : c'est ce qui garantit que le niveau par defaut (calcule ici si
  /// [ombres] est omis) ne peut jamais retomber sur une couleur figee.
  static BoxDecoration avecFilet({
    required AppColorPair surface,
    required AppInkColor filet,
    required AppShadowColor ombre,
    required BorderRadius arrondi,
    List<BoxShadow>? ombres,
  }) {
    return BoxDecoration(
      color: surface.background,
      borderRadius: arrondi,
      border: Border.fromBorderSide(filet.asBorderSide()),
      boxShadow: ombres ?? niveau0,
    );
  }
}
