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
  static final TextTheme standard = _construire(facteur: 1);

  /// Echelle du mode enfant, environ 20 pour cent plus grande.
  static final TextTheme enfant = _construire(facteur: facteurEnfant);

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

  static TextTheme _construire({required double facteur}) {
    // L'interligne s'ouvre legerement en mode enfant : un texte plus gros dans
    // le meme interligne se lit moins bien, pas mieux.
    final double aere = facteur > 1 ? 0.08 : 0;

    return TextTheme(
      // Les trois roles d'affichage portent les chiffres tabulaires d'office :
      // leur emploi documente est le chiffre geant d'ELV-02 et le nombre d'une
      // tuile de statistique, c'est-a-dire exactement des chiffres qui
      // changent en place (`01-systeme-visuel.md` section 5).
      displayLarge: tabulaire(_titre(40 * facteur, 1.05 + aere)),
      displayMedium: tabulaire(_titre(34 * facteur, 1.08 + aere)),
      displaySmall: tabulaire(_titre(28 * facteur, 1.1 + aere)),
      headlineLarge: _titre(26 * facteur, 1.2 + aere, poids: FontWeight.w600),
      headlineMedium: _titre(22 * facteur, 1.24 + aere, poids: FontWeight.w600),
      headlineSmall: _titre(20 * facteur, 1.28 + aere, poids: FontWeight.w600),
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

  /// Bricolage Grotesque : trois axes a piloter, et aucun ne peut etre laisse
  /// a son defaut.
  ///
  /// `opsz` se regle **sur la taille rendue**, borne aux limites du fichier.
  /// Une police de titre dessinee pour 96 points et affichee a 20 paraitrait
  /// fragile, l'inverse molle : c'est exactement l'effet "pas fini" du premier
  /// rendu.
  static TextStyle _titre(
    double taille,
    double interligne, {
    FontWeight poids = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: AppFontFamily.titre,
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
      fontWeight: poids,
      letterSpacing: crenage(taille),
      fontVariations: <FontVariation>[
        FontVariation('wght', poids.value.toDouble()),
        FontVariation(
          'opsz',
          taille.clamp(AppFontAxis.opszMin, AppFontAxis.opszMax),
        ),
      ],
    );
  }

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
