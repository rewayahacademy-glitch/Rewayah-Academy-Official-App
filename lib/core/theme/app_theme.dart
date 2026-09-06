import 'package:flutter/material.dart';

import '../domain/enums.dart';
import 'app_metriques.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Construction du theme de l'application.
///
/// Le mode enfant et le mode standard partagent la meme palette et la meme
/// arborescence : seule l'echelle typographique et la cible tactile changent
/// (`docs/architecture/etape-2-core-flutter.md` section 1).
abstract final class AppTheme {
  /// Le theme correspondant a un mode d'interface.
  static ThemeData pour(InterfaceMode mode) {
    final AppPalette palette = AppPalette.claire();
    final TextTheme echelle = mode == InterfaceMode.enfant
        ? AppTypography.enfant
        : AppTypography.standard;

    final TextTheme texte = echelle.apply(
      bodyColor: palette.surfaceBase.onBackground,
      displayColor: palette.surfaceBase.onBackground,
    );

    final AppMetriques metriques = AppMetriques.pour(mode);
    final double cible = metriques.cibleTactile;

    return ThemeData(
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[palette, metriques],
      colorScheme: _schemaDepuisPalette(palette),
      scaffoldBackgroundColor: palette.surfaceBase.background,
      textTheme: texte,
      // Toutes les cibles tactiles respectent le minimum du mode courant, y
      // compris celles des widgets Material que nous n'aurions pas enrobes.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: NoSplash.splashFactory,
      dividerTheme: DividerThemeData(
        color: palette.borderDefault.asBorderSide().color,
        space: AppSpacing.lg,
        thickness: 1,
      ),
      iconTheme: IconThemeData(
        color: palette.surfaceBase.onBackground,
        size: mode == InterfaceMode.enfant ? AppSpacing.xxxl : AppSpacing.xxl,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surfaceBase.background,
        foregroundColor: palette.surfaceBase.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: texte.titleLarge,
      ),
      // La hauteur minimale des controles suit la cible tactile du mode.
      inputDecorationTheme: InputDecorationTheme(
        constraints: BoxConstraints(minHeight: cible),
        filled: true,
        fillColor: palette.surfaceBase.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: palette.borderDefault.asBorderSide(),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: palette.borderDefault.asBorderSide(),
        ),
        // Le focus et l'erreur ne s'appuient pas sur borderDefault : ce jeton
        // est decoratif et ne passe pas le seuil de contraste des elements
        // porteurs de sens. Voir AppPalette.borderDefault.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(
            color: palette.surfacePrimary.background,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(
            color: palette.surfaceAlert.background,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Le [ColorScheme] Material derive integralement des paires : aucune couleur
  /// n'est inventee ici, sinon Material en reintroduirait une hors palette.
  static ColorScheme _schemaDepuisPalette(AppPalette palette) {
    return ColorScheme(
      brightness: Brightness.light,
      primary: palette.surfacePrimary.background,
      onPrimary: palette.surfacePrimary.onBackground,
      secondary: palette.surfaceSuccess.background,
      onSecondary: palette.surfaceSuccess.onBackground,
      tertiary: palette.surfaceWarning.background,
      onTertiary: palette.surfaceWarning.onBackground,
      error: palette.surfaceAlert.background,
      onError: palette.surfaceAlert.onBackground,
      surface: palette.surfaceBase.background,
      onSurface: palette.surfaceBase.onBackground,
      outline: palette.borderDefault.asBorderSide().color,
    );
  }
}
