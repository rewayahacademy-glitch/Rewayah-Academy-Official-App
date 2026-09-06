import 'package:flutter/material.dart';

import 'app_color_pair.dart';

/// La palette de l'application, exposee comme extension de theme.
///
/// **C'est le seul fichier du depot autorise a contenir une valeur de couleur
/// litterale.** `tool/verifier_jetons.dart` echoue si un `Color(0x...)` ou un
/// `Colors.` apparait ailleurs dans `lib/`.
///
/// Source : `docs/produit/design-tokens.md` section 1. Les valeurs corrigees
/// y sont figees telles quelles, elles ne se recalculent pas.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Cree une palette.
  const AppPalette({
    required this.surfaceBase,
    required this.surfacePrimary,
    required this.surfaceSuccess,
    required this.surfaceWarning,
    required this.surfaceAlert,
    required this.borderDefault,
    required this.textOnLightAccent,
  });

  /// La palette de l'application. Une seule, le mode sombre n'est pas
  /// implemente a l'etape 2 (design-tokens.md section 8).
  factory AppPalette.claire() => const AppPalette(
    // Fond general.
    surfaceBase: AppColorPair(
      background: Color(0xFFF1E3E4),
      onBackground: Color(0xFF1C1D21),
    ),
    // Actions principales.
    surfacePrimary: AppColorPair(
      background: Color(0xFF8652E6),
      onBackground: Color(0xFFFFFFFF),
    ),
    // Succes. Jamais de texte blanc : mesure a 1.46:1.
    surfaceSuccess: AppColorPair(
      background: Color(0xFF70EE9C),
      onBackground: Color(0xFF1C1D21),
    ),
    // Avertissement. Jamais de texte blanc : mesure a 1.75:1.
    surfaceWarning: AppColorPair(
      background: Color(0xFFFFB703),
      onBackground: Color(0xFF1C1D21),
    ),
    // Alerte. Rouge assombri : l'original 0xFFFF385C echouait a 3.51:1.
    surfaceAlert: AppColorPair(
      background: Color(0xFFB01B3C),
      onBackground: Color(0xFFFFFFFF),
    ),
    // Bordure remontee en luminance : l'original 0xFFCCBCBC etait a 1.47:1.
    //
    // ATTENTION, mesure : 0xFFB8A6A6 sur surfaceBase donne 1.86:1, ce qui reste
    // sous le seuil de 3:1 de la regle WCAG 1.4.11 sur les elements non
    // textuels. Ce jeton est donc DECORATIF uniquement. Il ne doit jamais etre
    // le seul moyen d'identifier un controle ou son etat : un focus, une erreur
    // ou une selection passent par surfaceAlert, surfacePrimary ou
    // textOnLightAccent, qui eux passent le seuil.
    // Valeur atteignant 3.03:1 si l'operateur veut des bordures porteuses de
    // sens : 0xFF8F8080. Voir docs/architecture/etape-2-journal.md.
    borderDefault: AppInkColor(Color(0xFFB8A6A6)),
    // Violet assombri pour texte sur fond clair : l'original echouait a 3.83:1.
    textOnLightAccent: AppInkColor(Color(0xFF5B36B0)),
  );

  /// Fond general de l'application.
  final AppColorPair surfaceBase;

  /// Actions principales.
  final AppColorPair surfacePrimary;

  /// Succes et validation.
  final AppColorPair surfaceSuccess;

  /// Avertissement.
  final AppColorPair surfaceWarning;

  /// Alerte et erreur.
  final AppColorPair surfaceAlert;

  /// Bordure decorative. Voir l'avertissement de mesure ci-dessus.
  final AppInkColor borderDefault;

  /// Accent violet lisible sur fond clair.
  final AppInkColor textOnLightAccent;

  /// Raccourci de lecture depuis un widget.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    AppColorPair? surfaceBase,
    AppColorPair? surfacePrimary,
    AppColorPair? surfaceSuccess,
    AppColorPair? surfaceWarning,
    AppColorPair? surfaceAlert,
    AppInkColor? borderDefault,
    AppInkColor? textOnLightAccent,
  }) {
    return AppPalette(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSuccess: surfaceSuccess ?? this.surfaceSuccess,
      surfaceWarning: surfaceWarning ?? this.surfaceWarning,
      surfaceAlert: surfaceAlert ?? this.surfaceAlert,
      borderDefault: borderDefault ?? this.borderDefault,
      textOnLightAccent: textOnLightAccent ?? this.textOnLightAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      surfaceBase: AppColorPair.lerp(surfaceBase, other.surfaceBase, t),
      surfacePrimary: AppColorPair.lerp(
        surfacePrimary,
        other.surfacePrimary,
        t,
      ),
      surfaceSuccess: AppColorPair.lerp(
        surfaceSuccess,
        other.surfaceSuccess,
        t,
      ),
      surfaceWarning: AppColorPair.lerp(
        surfaceWarning,
        other.surfaceWarning,
        t,
      ),
      surfaceAlert: AppColorPair.lerp(surfaceAlert, other.surfaceAlert, t),
      borderDefault: AppInkColor.lerp(borderDefault, other.borderDefault, t),
      textOnLightAccent: AppInkColor.lerp(
        textOnLightAccent,
        other.textOnLightAccent,
        t,
      ),
    );
  }
}
