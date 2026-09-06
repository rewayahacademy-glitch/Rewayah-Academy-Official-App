import 'package:flutter/material.dart';

import '../domain/enums.dart';
import 'app_spacing.dart';

/// Les mesures qui dependent du mode d'interface.
///
/// Portees par le theme plutot que par un parametre passe d'ecran en ecran :
/// un composant qui devrait recevoir le mode a chaque appel finirait par le
/// recevoir faux quelque part.
@immutable
class AppMetriques extends ThemeExtension<AppMetriques> {
  /// Cree un jeu de mesures.
  const AppMetriques({required this.mode, required this.cibleTactile});

  /// Les mesures correspondant a un mode.
  factory AppMetriques.pour(InterfaceMode mode) => AppMetriques(
    mode: mode,
    cibleTactile: mode == InterfaceMode.enfant
        ? AppTouchTarget.enfant
        : AppTouchTarget.standard,
  );

  /// Le mode d'interface courant.
  final InterfaceMode mode;

  /// Cible tactile minimale : 72pt en mode enfant, 44pt en mode standard
  /// (`docs/architecture/etape-2-core-flutter.md` section 2).
  final double cibleTactile;

  /// Vrai en mode enfant.
  bool get estEnfant => mode == InterfaceMode.enfant;

  /// Rayon d'arrondi des surfaces, plus genereux en mode enfant.
  double get rayon => estEnfant ? AppSpacing.xxl : AppSpacing.lg;

  /// Marge interne des surfaces.
  double get marge => estEnfant ? AppSpacing.xxl : AppSpacing.lg;

  /// Raccourci de lecture depuis un widget.
  static AppMetriques of(BuildContext context) =>
      Theme.of(context).extension<AppMetriques>()!;

  @override
  AppMetriques copyWith({InterfaceMode? mode, double? cibleTactile}) =>
      AppMetriques(
        mode: mode ?? this.mode,
        cibleTactile: cibleTactile ?? this.cibleTactile,
      );

  @override
  AppMetriques lerp(ThemeExtension<AppMetriques>? other, double t) {
    if (other is! AppMetriques) {
      return this;
    }
    return AppMetriques(
      mode: t < 0.5 ? mode : other.mode,
      cibleTactile:
          cibleTactile + (other.cibleTactile - cibleTactile) * t,
    );
  }
}
