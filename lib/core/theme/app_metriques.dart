import 'package:flutter/material.dart';

import '../domain/enums.dart';
import 'app_radius.dart';
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

  /// Rayon d'arrondi des surfaces, plus genereux en mode enfant : la tuile
  /// Bento en mode enfant, la carte en mode standard
  /// (`docs/produit/design-tokens.md` section 8).
  double get rayon => estEnfant ? AppRadius.lg : AppRadius.md;

  /// L'arrondi correspondant a [rayon].
  BorderRadius get arrondi =>
      estEnfant ? AppRadius.arrondiLg : AppRadius.arrondiMd;

  /// L'arrondi d'un element pose DANS une surface de ce mode.
  ///
  /// Le rayon d'un enfant est plus petit que celui de son parent : une vignette
  /// dans une carte de rayon 16 prend 12. L'inverse produit l'effet de bulle
  /// qui date le produit.
  BorderRadius get arrondiInterieur => AppRadius.arrondiEnfantDe(rayon);

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
