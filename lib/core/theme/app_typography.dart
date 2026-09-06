import 'package:flutter/material.dart';

/// Les quatre familles de l'application, pas une de plus.
///
/// Source : `docs/produit/design-tokens.md` section 2. Si un style manque, on
/// etend l'une des quatre par une variation de graisse, on n'en ajoute pas une
/// cinquieme.
abstract final class AppFontFamily {
  /// Arabe, documents : Coran, hadiths, livres, lettres, textes pedagogiques.
  static const String arabeDocument = 'UthmanTahaNaskh';

  /// Arabe, interface : RTL, menus, boutons, labels, navigation.
  static const String arabeInterface = 'NotoSansArabic';

  /// Francais, corps de texte, labels, navigation.
  static const String corps = 'NotoSans';

  /// Francais, titres et elements d'accent.
  static const String titre = 'VarelaRound';

  /// Ordre de repli. Un texte francais qui contient de l'arabe reste lisible
  /// sans que l'ecran ait a choisir sa police lui-meme.
  static const List<String> repli = <String>[arabeInterface];
}

/// Les deux echelles typographiques de l'application.
///
/// Une echelle standard pour les roles adultes, une echelle agrandie d'environ
/// 20 pour cent pour le mode enfant. L'agrandissement se decide **ici et nulle
/// part ailleurs** : aucun ecran n'applique de multiplicateur de son cote,
/// sinon les deux echelles divergent silencieusement
/// (`docs/architecture/etape-2-core-flutter.md` section 1).
abstract final class AppTypography {
  /// Facteur d'agrandissement du mode enfant.
  static const double facteurEnfant = 1.2;

  /// Echelle des roles adultes et du mode standard.
  static final TextTheme standard = _construire(facteur: 1);

  /// Echelle du mode enfant, environ 20 pour cent plus grande.
  static final TextTheme enfant = _construire(facteur: facteurEnfant);

  /// Style de rendu d'un document arabe : Coran, hadith, livre, lettre.
  ///
  /// Volontairement hors du [TextTheme] : ce n'est pas un role d'interface,
  /// c'est un rendu de document, et sa taille se pilote au cas par cas.
  static TextStyle document({double taille = 28, double interligne = 2}) {
    return TextStyle(
      fontFamily: AppFontFamily.arabeDocument,
      fontSize: taille,
      height: interligne,
    );
  }

  static TextTheme _construire({required double facteur}) {
    // L'interligne s'ouvre legerement en mode enfant : un texte plus gros dans
    // le meme interligne se lit moins bien, pas mieux.
    final double aere = facteur > 1 ? 0.08 : 0;

    return TextTheme(
      displayLarge: _titre(40 * facteur, 1.12 + aere),
      displayMedium: _titre(34 * facteur, 1.15 + aere),
      displaySmall: _titre(28 * facteur, 1.18 + aere),
      headlineLarge: _titre(26 * facteur, 1.2 + aere),
      headlineMedium: _titre(22 * facteur, 1.24 + aere),
      headlineSmall: _titre(20 * facteur, 1.28 + aere),
      titleLarge: _corps(18 * facteur, 1.3 + aere, FontWeight.w600),
      titleMedium: _corps(16 * facteur, 1.32 + aere, FontWeight.w600),
      titleSmall: _corps(14 * facteur, 1.34 + aere, FontWeight.w600),
      bodyLarge: _corps(17 * facteur, 1.45 + aere, FontWeight.w400),
      bodyMedium: _corps(15 * facteur, 1.47 + aere, FontWeight.w400),
      bodySmall: _corps(13 * facteur, 1.5 + aere, FontWeight.w400),
      labelLarge: _corps(15 * facteur, 1.2 + aere, FontWeight.w600),
      labelMedium: _corps(13 * facteur, 1.2 + aere, FontWeight.w600),
      labelSmall: _corps(12 * facteur, 1.2 + aere, FontWeight.w600),
    );
  }

  /// Varela Round n'a qu'une graisse : pas de variation a piloter.
  static TextStyle _titre(double taille, double interligne) {
    return TextStyle(
      fontFamily: AppFontFamily.titre,
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
    );
  }

  /// Noto Sans est une police variable : la graisse se pilote par l'axe `wght`,
  /// [FontWeight] seul ne suffirait pas et Flutter synthetiserait un faux gras.
  static TextStyle _corps(double taille, double interligne, FontWeight poids) {
    return TextStyle(
      fontFamily: AppFontFamily.corps,
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
      fontWeight: poids,
      fontVariations: <FontVariation>[
        FontVariation('wght', poids.value.toDouble()),
      ],
    );
  }
}
