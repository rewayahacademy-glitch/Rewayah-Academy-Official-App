import 'package:flutter/material.dart';

import '../domain/enums.dart';
import 'app_metriques.dart';
import 'app_palette.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Existing application adapter. No service/provider is consulted by the theme.
abstract final class AppTheme {
  static ThemeData pour(InterfaceMode mode, Brightness brightness) => depuis(
    brightness == Brightness.dark ? AppPalette.sombre() : AppPalette.claire(),
    mode,
    brightness,
  );

  /// Le theme d'une palette donnee : celle d'une surface qui n'est ni le
  /// clair ni le sombre de l'application ([AppPalette.surMarque], la
  /// connexion), pour que les composants partages posent leurs paires
  /// lisibles sur cette surface sans qu'un ecran ait a les redemander.
  static ThemeData depuis(
    AppPalette palette,
    InterfaceMode mode,
    Brightness brightness,
  ) {
    final metriques = AppMetriques.pour(mode);
    final texte =
        (metriques.estEnfant ? AppTypography.enfant : AppTypography.standard)
            .apply(
              bodyColor: palette.surfaceCanvas.onBackground,
              displayColor: palette.surfaceCanvas.onBackground,
            );
    final scheme = _schemaDepuisPalette(palette, brightness);
    // Boutons et champs au rayon `sm` (12), comme le documente `AppRadius` et
    // comme le mesurent les maquettes (decisions du coordinateur, section 3,
    // point 2). Les cartes gardent `md` (16).
    const forme = RoundedRectangleBorder(borderRadius: AppRadius.arrondiSm);
    const formeCarte = RoundedRectangleBorder(
      borderRadius: AppRadius.arrondiMd,
    );
    final bouton = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(
          0,
          metriques.estEnfant ? AppTouchTarget.enfant : AppPage.hauteurBouton,
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
      shape: const WidgetStatePropertyAll(forme),
      textStyle: WidgetStatePropertyAll(texte.labelLarge),
      elevation: const WidgetStatePropertyAll(0),
      overlayColor: WidgetStateProperty.resolveWith((etats) {
        if (etats.contains(WidgetState.pressed)) {
          return palette.calqueInteraction(presse: true);
        }
        if (etats.contains(WidgetState.hovered) ||
            etats.contains(WidgetState.focused)) {
          return palette.calqueInteraction();
        }
        return null;
      }),
    );
    OutlineInputBorder bord(AppInkColorSource source, {double largeur = 1}) =>
        OutlineInputBorder(
          borderRadius: AppRadius.arrondiSm,
          borderSide: BorderSide(
            color: source == AppInkColorSource.erreur
                ? scheme.error
                : source == AppInkColorSource.focus
                ? palette.inkAccent.asBorderSide().color
                : source == AppInkColorSource.contourInerte
                ? scheme.outlineVariant
                : scheme.outline,
            width: largeur,
          ),
        );
    return ThemeData(
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[palette, metriques],
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.surfaceCanvas.background,
      textTheme: texte,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: NoSplash.splashFactory,
      hoverColor: palette.calqueInteraction(),
      highlightColor: palette.calqueInteraction(presse: true),
      focusColor: palette.calqueInteraction(),
      disabledColor: palette.inkMuted.asBorderSide().color,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      iconTheme: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: texte.titleLarge,
      ),
      // Le bouton plein est le CTA dominant : `surfaceActionDouce` (lavande
      // doux et encre `inkStrong` en clair, accent plein et encre sombre en
      // sombre), jamais l'aplat violet sature qu'aucune maquette claire ne
      // montre. `ActionPrincipale` peint la meme paire.
      filledButtonTheme: FilledButtonThemeData(
        style: bouton.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? palette.surfaceSunken.background
                : palette.surfaceActionDouce.background,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? scheme.onSurfaceVariant
                : palette.surfaceActionDouce.onBackground,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: bouton.copyWith(
          foregroundColor: WidgetStatePropertyAll(
            palette.inkAccent.asBorderSide().color,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: bouton.copyWith(
          foregroundColor: WidgetStatePropertyAll(
            palette.inkAccent.asBorderSide().color,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: formeCarte,
        margin: EdgeInsets.zero,
      ),
      // Un onglet est un libelle de navigation : Plus Jakarta Sans
      // (`labelLarge`), pas le `titleSmall` DM Sans que Material 3 pose par
      // defaut (decisions du coordinateur 3.4, revue phase 0, jetons D5).
      tabBarTheme: TabBarThemeData(
        labelStyle: texte.labelLarge,
        unselectedLabelStyle: texte.labelLarge,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceOverlay.background,
        barrierColor: palette.voile,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.arrondiLg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceOverlay.background,
        modalBarrierColor: palette.voile,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.arrondiFeuille,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        constraints: BoxConstraints(minHeight: metriques.cibleTactile),
        filled: true,
        fillColor: palette.surfaceSunken.background,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        // Le texte d'invite est une invite, pas une valeur : il se pose en
        // `inkFaint`, la seule encre du produit qui ne pretend pas etre du
        // contenu. Sans ce style, il heritait de l'encre du corps et un champ
        // vide se lisait comme un champ deja rempli.
        hintStyle: palette.inkFaint.applyTo(
          texte.bodyLarge ?? const TextStyle(),
        ),
        border: bord(AppInkColorSource.contour),
        enabledBorder: bord(AppInkColorSource.contour),
        // **Un champ inerte et un champ actif ne peuvent pas porter le meme
        // filet.** Les deux appelaient `contour` a l'identique : rien, a
        // l'ecran, ne distinguait un champ qui attend une frappe d'un champ qui
        // n'en acceptera jamais. Sur un fond `surfaceSunken`, deja creux, le
        // champ courriel de `TUT-00` se lisait donc comme desactive. L'inerte
        // passe au filet le plus faible de la rampe, l'actif garde le filet
        // porteur de sens (`01-systeme-visuel.md` section 2).
        disabledBorder: bord(AppInkColorSource.contourInerte),
        focusedBorder: bord(AppInkColorSource.focus, largeur: 2),
        errorBorder: bord(AppInkColorSource.erreur, largeur: 2),
        focusedErrorBorder: bord(AppInkColorSource.erreur, largeur: 2),
      ),
    );
  }

  static ColorScheme _schemaDepuisPalette(
    AppPalette p,
    Brightness brightness,
  ) => ColorScheme(
    brightness: brightness,
    primary: p.surfacePrimary.background,
    onPrimary: p.surfacePrimary.onBackground,
    primaryContainer: p.washAccent.background,
    onPrimaryContainer: p.washAccent.onBackground,
    secondary: p.inkMuted.asBorderSide().color,
    onSecondary: p.surfaceCanvas.background,
    secondaryContainer: p.surfaceSunken.background,
    onSecondaryContainer: p.surfaceSunken.onBackground,
    tertiary: p.inkAccent.asBorderSide().color,
    onTertiary: p.surfaceCanvas.background,
    tertiaryContainer: p.washAccent.background,
    onTertiaryContainer: p.washAccent.onBackground,
    error: p.surfaceAlert.background,
    onError: p.surfaceAlert.onBackground,
    errorContainer: p.washAlert.background,
    onErrorContainer: p.washAlert.onBackground,
    surface: p.surfaceRaised.background,
    onSurface: p.surfaceRaised.onBackground,
    onSurfaceVariant: p.inkMuted.asBorderSide().color,
    surfaceContainerLowest: p.surfaceCanvas.background,
    surfaceContainerLow: p.surfaceCanvas.background,
    surfaceContainer: p.surfaceSunken.background,
    surfaceContainerHigh: p.surfaceOverlay.background,
    surfaceContainerHighest: p.surfaceOverlay.background,
    surfaceDim: p.surfaceSunken.background,
    surfaceBright: p.surfaceOverlay.background,
    surfaceTint: p.surfaceRaised.background,
    inverseSurface: p.surfaceInverse.background,
    onInverseSurface: p.surfaceInverse.onBackground,
    inversePrimary: brightness == Brightness.dark
        ? AppPalette.claire().surfacePrimary.background
        : AppPalette.sombre().surfacePrimary.background,
    outline: p.borderStrong.asBorderSide().color,
    outlineVariant: p.borderHairline.asBorderSide().color,
    scrim: p.voile,
  );
}

enum AppInkColorSource { contour, contourInerte, focus, erreur }
