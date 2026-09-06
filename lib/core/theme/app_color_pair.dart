import 'package:flutter/widgets.dart';

/// Une paire indissociable (fond, texte).
///
/// Le theme n'expose jamais une couleur seule : il expose des paires, pour que
/// l'erreur de contraste devienne structurellement impossible plutot que
/// dependante de la vigilance de qui ecrit l'ecran.
/// Voir `docs/produit/design-tokens.md` section 1.
///
/// Un widget qui prend `background` sans `onBackground`, ou l'inverse, est un
/// signal de revue de code a corriger avant fusion.
@immutable
class AppColorPair {
  /// Cree une paire fond-texte.
  const AppColorPair({required this.background, required this.onBackground});

  /// Couleur de fond de la surface.
  final Color background;

  /// Couleur du texte et des icones poses sur [background].
  final Color onBackground;

  /// Applique la couleur de texte de la paire a un style existant.
  ///
  /// Preferer cette methode a une lecture directe de [onBackground] : elle rend
  /// visible, a la lecture, que le texte appartient bien a cette surface.
  TextStyle applyTo(TextStyle base) => base.copyWith(color: onBackground);

  /// Construit une decoration de surface a partir de la paire.
  BoxDecoration decoration({BorderRadius? borderRadius, BorderSide? side}) {
    return BoxDecoration(
      color: background,
      borderRadius: borderRadius,
      border: side == null ? null : Border.fromBorderSide(side),
    );
  }

  /// Interpolation, requise par [ThemeExtension].
  static AppColorPair lerp(AppColorPair a, AppColorPair b, double t) {
    return AppColorPair(
      background: Color.lerp(a.background, b.background, t)!,
      onBackground: Color.lerp(a.onBackground, b.onBackground, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppColorPair &&
      other.background == background &&
      other.onBackground == onBackground;

  @override
  int get hashCode => Object.hash(background, onBackground);
}

/// Une encre : couleur valable uniquement en premier plan.
///
/// Deux jetons de `design-tokens.md` n'ont pas de fond associe
/// (`borderDefault`, `textOnLightAccent`). Les exposer en [Color] nu
/// permettrait de les poser en fond, donc de creer la paire illisible que
/// [AppColorPair] cherche justement a empecher.
///
/// Cette classe n'expose donc aucune couleur brute : seulement les deux usages
/// legitimes, le texte et le trait.
@immutable
class AppInkColor {
  /// Cree une encre de premier plan.
  const AppInkColor(this._value);

  final Color _value;

  /// Applique l'encre a un style de texte.
  TextStyle applyTo(TextStyle base) => base.copyWith(color: _value);

  /// Construit un trait de bordure de cette encre.
  BorderSide asBorderSide({double width = 1}) =>
      BorderSide(color: _value, width: width);

  /// Construit un theme d'icone de cette encre.
  ///
  /// A envelopper autour d'une icone plutot que de lui passer une couleur :
  /// c'est ce qui evite d'avoir a exposer la valeur brute.
  IconThemeData asIconTheme({double? size}) =>
      IconThemeData(color: _value, size: size);

  /// Valeur brute, reservee aux tests de contraste et aux outils de
  /// verification. Ne pas utiliser dans un widget.
  @visibleForTesting
  Color get debugValue => _value;

  /// Interpolation, requise par [ThemeExtension].
  static AppInkColor lerp(AppInkColor a, AppInkColor b, double t) =>
      AppInkColor(Color.lerp(a._value, b._value, t)!);

  @override
  bool operator ==(Object other) =>
      other is AppInkColor && other._value == _value;

  @override
  int get hashCode => _value.hashCode;
}
