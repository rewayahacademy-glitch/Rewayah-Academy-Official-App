import 'package:flutter/material.dart';

import '../domain/enums.dart';
import 'app_metriques.dart';
import 'app_palette.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Construction du theme de l'application.
///
/// Le mode enfant et le mode standard partagent la meme palette et la meme
/// arborescence : seule l'echelle typographique et la cible tactile changent
/// (`docs/architecture/etape-2-core-flutter.md` section 1).
///
/// Le theme pose les trois surfaces de la refonte : le fond de page est le
/// creme, les barres et les cartes sont sur la surface elevee, les champs sur
/// la surface enfoncee. C'est ce qui remplace l'ancien fond unique, ou la page,
/// la carte et le champ partageaient la meme couleur et ou aucune hierarchie
/// n'etait donc possible (`docs/design/01-systeme-visuel.md` section 2).
abstract final class AppTheme {
  /// Le theme correspondant a un mode d'interface.
  static ThemeData pour(InterfaceMode mode) {
    final AppPalette palette = AppPalette.claire();
    final TextTheme echelle = mode == InterfaceMode.enfant
        ? AppTypography.enfant
        : AppTypography.standard;

    final TextTheme texte = echelle.apply(
      bodyColor: palette.surfaceCanvas.onBackground,
      displayColor: palette.surfaceCanvas.onBackground,
    );

    final AppMetriques metriques = AppMetriques.pour(mode);
    final double cible = metriques.cibleTactile;

    return ThemeData(
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[palette, metriques],
      colorScheme: _schemaDepuisPalette(palette),
      scaffoldBackgroundColor: palette.surfaceCanvas.background,
      textTheme: texte,
      // Toutes les cibles tactiles respectent le minimum du mode courant, y
      // compris celles des widgets Material que nous n'aurions pas enrobes.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: NoSplash.splashFactory,
      dividerTheme: DividerThemeData(
        color: palette.borderHairline.asBorderSide().color,
        space: AppSpacing.lg,
        thickness: 1,
      ),
      iconTheme: palette.inkStrong.asIconTheme(
        size: mode == InterfaceMode.enfant ? AppSpacing.xxxl : AppSpacing.xxl,
      ),
      // La barre superieure est une surface elevee, comme toute barre de
      // navigation : elle porte donc un filet ET pas d'ombre Material, nos
      // ombres venant d'AppElevation et non de l'echelle de Material.
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surfaceRaised.background,
        foregroundColor: palette.surfaceRaised.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: palette.surfaceRaised.applyTo(
          texte.titleLarge ?? const TextStyle(),
        ),
        shape: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      // Un champ de saisie est une surface ENFONCEE : c'est le seul moyen de le
      // distinguer de la carte qui le contient sans lui coller un cadre lourd.
      // La hauteur minimale suit la cible tactile du mode.
      inputDecorationTheme: InputDecorationTheme(
        constraints: BoxConstraints(minHeight: cible),
        filled: true,
        fillColor: palette.surfaceSunken.background,
        border: OutlineInputBorder(
          borderRadius: AppRadius.arrondiSm,
          borderSide: palette.borderResting.asBorderSide(),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.arrondiSm,
          borderSide: palette.borderResting.asBorderSide(),
        ),
        // Le focus et l'erreur ne s'appuient pas sur borderResting : ce jeton
        // est decoratif et ne passe pas le seuil de 3:1 des elements porteurs
        // de sens. Ils passent par une couleur semantique, qui elle le passe.
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.arrondiSm,
          borderSide: BorderSide(
            color: palette.surfacePrimary.background,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.arrondiSm,
          borderSide: BorderSide(
            color: palette.surfaceAlert.background,
            width: 2,
          ),
        ),
        // Sans cette ligne, un champ en erreur qui prend le focus repasse au
        // violet et l'erreur disparait de l'ecran au moment ou on la corrige.
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.arrondiSm,
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
  ///
  /// Les quatre roles `container` recoivent les paires douces : c'est ce qui
  /// evite qu'un widget Material non enrobe ressorte un aplat sature la ou le
  /// produit veut une teinte pale (`01-systeme-visuel.md` section 3).
  static ColorScheme _schemaDepuisPalette(AppPalette palette) {
    return ColorScheme(
      brightness: Brightness.light,
      primary: palette.surfacePrimary.background,
      onPrimary: palette.surfacePrimary.onBackground,
      primaryContainer: palette.washAccent.background,
      onPrimaryContainer: palette.washAccent.onBackground,
      secondary: palette.surfaceSuccess.background,
      onSecondary: palette.surfaceSuccess.onBackground,
      secondaryContainer: palette.washSuccess.background,
      onSecondaryContainer: palette.washSuccess.onBackground,
      tertiary: palette.surfaceWarning.background,
      onTertiary: palette.surfaceWarning.onBackground,
      tertiaryContainer: palette.washWarning.background,
      onTertiaryContainer: palette.washWarning.onBackground,
      error: palette.surfaceAlert.background,
      onError: palette.surfaceAlert.onBackground,
      errorContainer: palette.washAlert.background,
      onErrorContainer: palette.washAlert.onBackground,
      surface: palette.surfaceCanvas.background,
      onSurface: palette.surfaceCanvas.onBackground,
      surfaceContainerLowest: palette.surfaceRaised.background,
      surfaceContainerHighest: palette.surfaceSunken.background,
      inverseSurface: palette.surfaceInverse.background,
      onInverseSurface: palette.surfaceInverse.onBackground,
      // `outline` porte du sens chez Material : c'est la bordure mesuree.
      // `outlineVariant` est le filet decoratif.
      outline: palette.borderStrong.asBorderSide().color,
      outlineVariant: palette.borderHairline.asBorderSide().color,
    );
  }
}
