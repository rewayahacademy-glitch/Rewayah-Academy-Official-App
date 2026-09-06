import 'package:flutter/widgets.dart';

/// Echelle d'espacement fixe : 4, 8, 12, 16, 20, 24, 32.
///
/// Aucune valeur ponctuelle en dehors de cette echelle
/// (`docs/produit/design-tokens.md` section 7). `tool/verifier_jetons.dart`
/// echoue sur toute valeur d'espacement litterale hors echelle dans `lib/`.
abstract final class AppSpacing {
  /// 4 points.
  static const double xs = 4;

  /// 8 points.
  static const double sm = 8;

  /// 12 points.
  static const double md = 12;

  /// 16 points.
  static const double lg = 16;

  /// 20 points.
  static const double xl = 20;

  /// 24 points.
  static const double xxl = 24;

  /// 32 points.
  static const double xxxl = 32;

  /// L'echelle complete, dans l'ordre. Sert aux tests et a la verification.
  static const List<double> echelle = <double>[xs, sm, md, lg, xl, xxl, xxxl];
}

/// Cibles tactiles minimales.
///
/// 72pt en mode enfant, 44pt en mode standard
/// (`docs/architecture/etape-2-core-flutter.md` section 2, ligne `BentoTile`).
abstract final class AppTouchTarget {
  /// Cible minimale en mode enfant.
  static const double enfant = 72;

  /// Cible minimale en mode standard.
  static const double standard = 44;
}

/// Espaces verticaux et horizontaux prets a l'emploi, pour eviter les
/// `SizedBox(height: 12)` litteraux disperses dans les ecrans.
abstract final class Ecart {
  /// Espace vertical de 4.
  static const Widget vXs = SizedBox(height: AppSpacing.xs);

  /// Espace vertical de 8.
  static const Widget vSm = SizedBox(height: AppSpacing.sm);

  /// Espace vertical de 12.
  static const Widget vMd = SizedBox(height: AppSpacing.md);

  /// Espace vertical de 16.
  static const Widget vLg = SizedBox(height: AppSpacing.lg);

  /// Espace vertical de 20.
  static const Widget vXl = SizedBox(height: AppSpacing.xl);

  /// Espace vertical de 24.
  static const Widget vXxl = SizedBox(height: AppSpacing.xxl);

  /// Espace vertical de 32.
  static const Widget vXxxl = SizedBox(height: AppSpacing.xxxl);

  /// Espace horizontal de 4.
  static const Widget hXs = SizedBox(width: AppSpacing.xs);

  /// Espace horizontal de 8.
  static const Widget hSm = SizedBox(width: AppSpacing.sm);

  /// Espace horizontal de 12.
  static const Widget hMd = SizedBox(width: AppSpacing.md);

  /// Espace horizontal de 16.
  static const Widget hLg = SizedBox(width: AppSpacing.lg);

  /// Espace horizontal de 20.
  static const Widget hXl = SizedBox(width: AppSpacing.xl);

  /// Espace horizontal de 24.
  static const Widget hXxl = SizedBox(width: AppSpacing.xxl);
}
