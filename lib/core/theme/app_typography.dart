import 'package:flutter/material.dart';

/// Les quatre familles de l'application, pas une de plus.
///
/// Source : `docs/produit/design-tokens.md` section 2. Si un style manque, on
/// etend l'une des quatre par une variation d'axe, on n'en ajoute pas une
/// cinquieme.
///
/// **L'arabe n'a pas change a la refonte, le francais a change entierement**
/// (ADR-018). Varela Round n'avait qu'une graisse, donc aucune hierarchie
/// possible a l'interieur d'un titre, et des terminaisons arrondies dont le
/// registre appartient au debut des annees 2010 : c'est la police qui datait le
/// produit. Noto Sans pesait 2 Mo pour une interface francaise sans
/// personnalite.
abstract final class AppFontFamily {
  /// Arabe, documents : Coran, hadiths, livres, lettres, textes pedagogiques.
  static const String arabeDocument = 'UthmanTahaNaskh';

  /// Arabe, interface : RTL, menus, boutons, labels, navigation.
  static const String arabeInterface = 'NotoSansArabic';

  /// Francais, corps de texte, labels, navigation, boutons, tableaux.
  static const String corps = 'InstrumentSans';

  /// Francais, titres, en-tetes, chiffres de tuile.
  static const String titre = 'BricolageGrotesque';

  /// Ordre de repli. Un texte francais qui contient de l'arabe reste lisible
  /// sans que l'ecran ait a choisir sa police lui-meme.
  static const List<String> repli = <String>[arabeInterface];
}

/// Les axes variables reellement presents dans les fichiers embarques.
///
/// Releves sur les binaires le 7 septembre 2026, pas supposes : la table `fvar`
/// de chaque fichier a ete lue. Les valeurs par defaut comptent autant que les
/// bornes, et elles sont pieges :
///
/// - Bricolage Grotesque a `wght` par defaut a **800** et `opsz` par defaut a
///   **96**. Un titre qui ne declare pas ses axes sort donc en extra-gras
///   dessine pour 96 points ;
/// - Instrument Sans a `wght` par defaut a **400**, et **il n'y a pas de
///   graisse plus fine** : la hierarchie du texte se fait par la couleur, avec
///   les trois encres neutres, jamais par un gris clair obtenu en amaigrissant
///   la police.
abstract final class AppFontAxis {
  /// Borne basse de l'axe `opsz` de Bricolage Grotesque.
  static const double opszMin = 12;

  /// Borne haute de l'axe `opsz` de Bricolage Grotesque.
  static const double opszMax = 96;

  /// Borne basse de l'axe `wght` d'Instrument Sans.
  static const double wghtCorpsMin = 400;

  /// Borne haute de l'axe `wght` d'Instrument Sans.
  static const double wghtCorpsMax = 700;
}

/// Les deux echelles typographiques de l'application.
///
/// Une echelle standard pour les roles adultes, une echelle agrandie d'environ
/// 20 pour cent pour le mode enfant. L'agrandissement se decide **ici et nulle
/// part ailleurs** : aucun ecran n'applique de multiplicateur de son cote,
/// sinon les deux echelles divergent silencieusement
/// (`docs/architecture/etape-2-core-flutter.md` section 1).
///
/// **C'est le seul fichier du depot autorise a poser un `letterSpacing`** :
/// `tool/verifier_jetons.dart` echoue partout ailleurs. Le crenage se calcule a
/// partir de la taille rendue, il ne se recopie pas.
abstract final class AppTypography {
  /// Facteur d'agrandissement du mode enfant.
  static const double facteurEnfant = 1.2;

  /// Echelle des roles adultes et du mode standard.
  static final TextTheme standard = _construire();

  /// Echelle du mode enfant, environ 20 pour cent plus grande.
  static final TextTheme enfant = standard.copyWith(
    headlineSmall: _corps(32, 40 / 32, FontWeight.w600),
    titleLarge: _corps(32, 40 / 32, FontWeight.w600),
    bodyLarge: _corps(20, 28 / 20, FontWeight.w400),
    bodyMedium: _corps(20, 28 / 20, FontWeight.w400),
    labelLarge: _corps(20, 28 / 20, FontWeight.w600),
    bodySmall: _corps(16, 24 / 16, FontWeight.w400),
  );

  /// Le crenage optique d'une taille rendue, en pixels logiques.
  ///
  /// Bareme de `docs/produit/design-tokens.md` section 10, exprime en em et
  /// converti ici : negatif au dessus de 18, neutre au corps, positif en
  /// dessous de 15.
  ///
  /// Aucun `letterSpacing` n'etait pose nulle part avant la refonte, ce qui
  /// laissait les grands titres a l'espacement d'un corps de texte. C'est l'un
  /// des deux details qui datent le plus un ecran, avec l'absence d'elevation.
  static double crenage(double taille) => taille * _crenageEm(taille);

  static double _crenageEm(double taille) {
    if (taille >= 32) {
      return -0.02;
    }
    if (taille >= 24) {
      return -0.015;
    }
    if (taille >= 18) {
      return -0.01;
    }
    if (taille >= 15) {
      return 0;
    }
    return 0.01;
  }

  /// Le style d'un libelle rendu en capitales.
  ///
  /// Les capitales se serrent la ou les bas-de-casse s'aerent : sous 12 points,
  /// un libelle en capitales prend +0,06 em au lieu du bareme courant. C'est la
  /// seule ligne du bareme qui ne se deduit pas de la taille seule.
  static TextStyle capitales(TextStyle base) {
    final double taille = base.fontSize ?? 12;
    if (taille > 12) {
      return base;
    }
    return base.copyWith(letterSpacing: taille * 0.06);
  }

  /// Le meme style, en chiffres tabulaires.
  ///
  /// **Obligatoire partout ou un chiffre vit dans une colonne, un compteur, un
  /// minuteur ou une tuile de statistique.** Sans `tnum`, un compteur qui passe
  /// de 17 a 18 fait bouger toute la ligne. La fonction est presente dans les
  /// trois polices embarquees, verifiee sur les binaires.
  static TextStyle tabulaire(TextStyle base) => base.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );

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

  static TextTheme _construire() => TextTheme(
    displayLarge: tabulaire(_corps(36, 44 / 36, FontWeight.w600)),
    displayMedium: tabulaire(_corps(36, 44 / 36, FontWeight.w600)),
    displaySmall: tabulaire(_corps(36, 44 / 36, FontWeight.w600)),
    headlineLarge: _corps(36, 44 / 36, FontWeight.w600),
    headlineMedium: _corps(32, 40 / 32, FontWeight.w600),
    headlineSmall: _corps(28, 36 / 28, FontWeight.w600),
    titleLarge: _corps(22, 28 / 22, FontWeight.w600),
    titleMedium: _corps(18, 26 / 18, FontWeight.w600),
    titleSmall: _corps(16, 24 / 16, FontWeight.w600),
    bodyLarge: _corps(16, 24 / 16, FontWeight.w400),
    bodyMedium: _corps(14, 20 / 14, FontWeight.w400),
    bodySmall: _corps(12, 16 / 12, FontWeight.w400),
    labelLarge: _corps(16, 20 / 16, FontWeight.w600),
    labelMedium: _corps(12, 16 / 12, FontWeight.w500),
    labelSmall: _corps(12, 16 / 12, FontWeight.w500),
  );

  /// Instrument Sans est une police variable : la graisse se pilote par l'axe
  /// `wght`, [FontWeight] seul ne suffirait pas et Flutter synthetiserait un
  /// faux gras.
  static TextStyle _corps(double taille, double interligne, FontWeight poids) {
    return TextStyle(
      fontFamily: AppFontFamily.corps,
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
      fontWeight: poids,
      letterSpacing: crenage(taille),
      fontVariations: <FontVariation>[
        FontVariation(
          'wght',
          poids.value.toDouble().clamp(
            AppFontAxis.wghtCorpsMin,
            AppFontAxis.wghtCorpsMax,
          ),
        ),
      ],
    );
  }
}
