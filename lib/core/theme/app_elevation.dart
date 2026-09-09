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
abstract final class AppElevation {
  /// La couleur d'ombre du produit : chaude, jamais grise.
  static final AppShadowColor _ombre = AppPalette.claire().ombre;

  /// Ce qui est pose a plat : sections, separateurs.
  static const List<BoxShadow> niveau0 = <BoxShadow>[];

  /// Cartes, tuiles, lignes cliquables. **Le defaut.**
  static final List<BoxShadow> niveau1 = <BoxShadow>[
    _ombre.asBoxShadow(y: 1, flou: 2, opacite: 0.05),
    _ombre.asBoxShadow(y: 2, flou: 6, opacite: 0.05),
  ];

  /// Ce qui flotte au dessus du contenu : menu, popover, barre collee, carte
  /// pressee.
  static final List<BoxShadow> niveau2 = <BoxShadow>[
    _ombre.asBoxShadow(y: 2, flou: 4, opacite: 0.05),
    _ombre.asBoxShadow(y: 8, flou: 20, opacite: 0.08),
  ];

  /// Ce qui recouvre : feuille de bas d'ecran, boite de dialogue.
  static final List<BoxShadow> niveau3 = <BoxShadow>[
    _ombre.asBoxShadow(y: 12, flou: 32, opacite: 0.14),
  ];

  /// La decoration complete d'une surface elevee : fond, arrondi, filet et
  /// ombre en une fois.
  ///
  /// Passer par ici plutot que de composer une [BoxDecoration] a la main :
  /// c'est ce qui rend impossible la surface qui porte une ombre sans filet,
  /// invisible en contraste eleve, ou un filet sans ombre, plat.
  static BoxDecoration avecFilet({
    required AppColorPair surface,
    required AppInkColor filet,
    required BorderRadius arrondi,
    List<BoxShadow>? ombres,
  }) {
    return BoxDecoration(
      color: surface.background,
      borderRadius: arrondi,
      border: Border.fromBorderSide(filet.asBorderSide()),
      boxShadow: ombres ?? niveau1,
    );
  }
}
