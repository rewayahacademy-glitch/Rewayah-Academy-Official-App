import 'package:flutter/material.dart';

/// Les quatre familles de texte de l'application, pas une de plus.
///
/// Deux arabes, inchangees depuis la refonte, et deux francaises, choisies le
/// 24/09/2026 par le coordinateur du chantier Tuteur V1 (decisions, section 3,
/// point 4) : **DM Sans pour les titres, Plus Jakarta Sans pour tout le
/// reste**. Si un style manque, on etend l'une des quatre par une variation
/// d'axe, on n'en ajoute pas une cinquieme. `tool/verifier_jetons.dart`
/// refuse tout `fontFamily` pose hors de ce fichier et toute famille du
/// `pubspec.yaml` hors de cette liste.
///
/// Historique : Instrument Sans (corps) et Bricolage Grotesque (titres) sont
/// retirees des assets. Depuis la fusion `cb3a220` du 15/09/2026, Bricolage
/// n'etait plus employee par aucun style ; le passage a DM Sans reintroduit
/// donc une vraie famille de titres.
abstract final class AppFontFamily {
  /// Arabe, documents : Coran, hadiths, livres, lettres, textes pedagogiques.
  static const String arabeDocument = 'UthmanTahaNaskh';

  /// Arabe, interface : RTL, menus, boutons, labels, navigation.
  static const String arabeInterface = 'NotoSansArabic';

  /// Francais, corps : texte, libelles, navigation, boutons, champs,
  /// legendes, statuts, et **tous les chiffres** (Plus Jakarta Sans).
  static const String corps = 'PlusJakartaSans';

  /// Francais, titres : `headline*` et `title*` (DM Sans).
  static const String titre = 'DMSans';

  /// Ordre de repli. Un texte francais qui contient de l'arabe reste lisible
  /// sans que l'ecran ait a choisir sa police lui-meme.
  static const List<String> repli = <String>[arabeInterface];

  /// Les quatre familles de texte, miroir exact du `pubspec.yaml` (hors
  /// icones Phosphor, qui ne sont pas du texte).
  static const List<String> texte = <String>[
    arabeDocument,
    arabeInterface,
    corps,
    titre,
  ];
}

/// Les axes variables reellement presents dans les fichiers embarques.
///
/// Releves sur les binaires le 24/09/2026, pas supposes : la table `fvar` de
/// chaque fichier a ete lue, et `test/theme/typographie_test.dart` la relit a
/// chaque execution. Les valeurs par defaut comptent autant que les bornes :
///
/// - DM Sans a `opsz` par defaut a **9**. Un titre qui ne pose pas l'axe sort
///   avec le dessin prevu pour 9 points, plus large et plus lache, a 28 ou
///   36 px. Chaque style DM Sans pose donc `opsz` ET `wght` ;
/// - DM Sans n'a **aucune fonction `tnum`** : ses chiffres sont
///   proportionnels, et [AppTypography.tabulaire] bascule un style DM Sans sur
///   Plus Jakarta Sans plutot que de poser une fonction sans effet ;
/// - Plus Jakarta Sans a `wght` 200 a 800, defaut 400, et possede `tnum`.
abstract final class AppFontAxis {
  /// Borne basse de l'axe `opsz` de DM Sans (egale a son defaut).
  static const double opszTitreMin = 9;

  /// Borne haute de l'axe `opsz` de DM Sans.
  static const double opszTitreMax = 40;

  /// Borne basse de l'axe `wght` de DM Sans.
  static const double wghtTitreMin = 100;

  /// Borne haute de l'axe `wght` de DM Sans.
  static const double wghtTitreMax = 1000;

  /// Borne basse de l'axe `wght` de Plus Jakarta Sans.
  static const double wghtCorpsMin = 200;

  /// Borne haute de l'axe `wght` de Plus Jakarta Sans.
  static const double wghtCorpsMax = 800;
}

/// Les deux echelles typographiques de l'application.
///
/// Une echelle standard pour les roles adultes, une echelle agrandie d'environ
/// 20 pour cent pour le mode enfant (Interface guidee). L'agrandissement se
/// decide **ici et nulle part ailleurs** : aucun ecran n'applique de
/// multiplicateur de son cote, sinon les deux echelles divergent
/// silencieusement.
///
/// Repartition des familles (decisions du coordinateur, section 3, point 4) :
///
/// | Roles | Famille | Pourquoi |
/// |---|---|---|
/// | `headline*`, `title*` | DM Sans, `wght` + `opsz` | titres de page, de section, de carte |
/// | `body*`, `label*` | Plus Jakarta Sans | corps, boutons, champs, navigation, pastilles |
/// | `display*` | Plus Jakarta Sans tabulaire | dans ce produit, `display*` ne porte que des valeurs fortes (compte a rebours, `StatTile`, heure « 13:45 », monogramme) ; un titre de 36 px prend `headlineLarge` |
/// | [chiffre] | Plus Jakarta Sans tabulaire | horaires, codes, PIN, chronometre, initiales |
///
/// Graisses : titres de page (`headline*`) a 700 (manifeste visuel, section
/// 3.3), titres de section et de carte (`title*`) a 600, corps a 400,
/// libelles et boutons a 500-600, valeurs fortes a 700.
///
/// **Un style DM Sans ne se retaille pas par `copyWith(fontSize: ...)`** :
/// l'axe `opsz` resterait cale sur l'ancienne taille. Un autre corps de titre
/// se demande ici. Limite acceptee : sous un `TextScaler` systeme, `opsz` suit
/// `fontSize`, pas la taille rendue.
///
/// **C'est le seul fichier du depot autorise a poser un `letterSpacing` ou un
/// `fontFamily`** : `tool/verifier_jetons.dart` echoue partout ailleurs (hors
/// icones). Le crenage se calcule a partir de la taille rendue, il ne se
/// recopie pas.
abstract final class AppTypography {
  /// Facteur d'agrandissement du mode enfant.
  static const double facteurEnfant = 1.2;

  /// Echelle des roles adultes et du mode standard.
  static final TextTheme standard = _construire();

  /// Echelle du mode enfant, environ 20 pour cent plus grande.
  static final TextTheme enfant = standard.copyWith(
    headlineSmall: _titre(32, 40 / 32, FontWeight.w700),
    titleLarge: _titre(32, 40 / 32, FontWeight.w600),
    bodyLarge: _corps(20, 28 / 20, FontWeight.w400),
    bodyMedium: _corps(20, 28 / 20, FontWeight.w400),
    labelLarge: _corps(20, 28 / 20, FontWeight.w600),
    bodySmall: _corps(16, 24 / 16, FontWeight.w400),
  );

  /// Le crenage optique d'une taille rendue, en pixels logiques.
  ///
  /// Bareme exprime en em et converti ici : negatif au dessus de 18, neutre
  /// au corps, positif en dessous de 15. DM Sans pose deja un dessin resserre
  /// a `opsz` eleve : le cumul se juge sur capture, pas au calcul.
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

  /// La valeur de l'axe `opsz` de DM Sans pour une taille donnee : la taille
  /// elle-meme, bornee a l'axe du fichier (9 a 40).
  static double opszPour(double taille) =>
      taille.clamp(AppFontAxis.opszTitreMin, AppFontAxis.opszTitreMax);

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
  /// de 17 a 18 fait bouger toute la ligne.
  ///
  /// DM Sans n'a pas la fonction `tnum` (table GSUB relue le 24/09/2026) : un
  /// style de titre passe ici bascule donc sur Plus Jakarta Sans, a taille,
  /// interligne et graisse egales, plutot que de porter une fonction qui ne
  /// ferait rien. La couleur et le crenage sont conserves.
  static TextStyle tabulaire(TextStyle base) {
    final TextStyle source = base.fontFamily == AppFontFamily.titre
        ? _versCorps(base)
        : base;
    return source.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  /// Le style des chiffres : horaires, codes d'appairage, PIN, chronometre,
  /// compte a rebours, initiales d'avatar.
  ///
  /// Plus Jakarta Sans en chiffres tabulaires, jamais DM Sans (pas de `tnum`).
  /// L'interligne par defaut suit l'echelle du produit : la taille plus 8 px
  /// (36/44, 32/40, 18/26...). La couleur se pose ensuite par la paire ou
  /// l'encre de la surface, comme pour tout style.
  static TextStyle chiffre({
    double taille = 32,
    FontWeight poids = FontWeight.w600,
    double? interligne,
  }) => tabulaire(_corps(taille, interligne ?? (taille + 8) / taille, poids));

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
    displayLarge: chiffre(taille: 36, poids: FontWeight.w700),
    displayMedium: chiffre(taille: 36, poids: FontWeight.w700),
    displaySmall: chiffre(taille: 36, poids: FontWeight.w700),
    headlineLarge: _titre(36, 44 / 36, FontWeight.w700),
    headlineMedium: _titre(32, 40 / 32, FontWeight.w700),
    headlineSmall: _titre(28, 36 / 28, FontWeight.w700),
    titleLarge: _titre(22, 28 / 22, FontWeight.w600),
    titleMedium: _titre(18, 26 / 18, FontWeight.w600),
    titleSmall: _titre(16, 24 / 16, FontWeight.w600),
    bodyLarge: _corps(16, 24 / 16, FontWeight.w400),
    bodyMedium: _corps(14, 20 / 14, FontWeight.w400),
    bodySmall: _corps(12, 16 / 12, FontWeight.w400),
    labelLarge: _corps(16, 20 / 16, FontWeight.w600),
    labelMedium: _corps(12, 16 / 12, FontWeight.w500),
    labelSmall: _corps(12, 16 / 12, FontWeight.w500),
  );

  /// Un titre en DM Sans : `wght` ET `opsz` poses explicitement.
  ///
  /// Sans `opsz`, le fichier sortirait son dessin de 9 points ; sans `wght`,
  /// Flutter synthetiserait un faux gras sur la graisse 400 par defaut.
  static TextStyle _titre(double taille, double interligne, FontWeight poids) {
    return TextStyle(
      fontFamily: AppFontFamily.titre,
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
      fontWeight: poids,
      letterSpacing: crenage(taille),
      fontVariations: <FontVariation>[
        FontVariation(
          'wght',
          poids.value.toDouble().clamp(
            AppFontAxis.wghtTitreMin,
            AppFontAxis.wghtTitreMax,
          ),
        ),
        FontVariation('opsz', opszPour(taille)),
      ],
    );
  }

  /// Le corps en Plus Jakarta Sans : la graisse se pilote par l'axe `wght`,
  /// [FontWeight] seul ne suffirait pas et Flutter synthetiserait un faux gras.
  static TextStyle _corps(double taille, double interligne, FontWeight poids) {
    return TextStyle(
      fontFamily: AppFontFamily.corps,
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
      fontWeight: poids,
      letterSpacing: crenage(taille),
      fontVariations: <FontVariation>[_wghtCorps(poids)],
    );
  }

  /// Bascule un style DM Sans sur Plus Jakarta Sans, sans toucher a sa taille,
  /// son interligne, sa couleur ni son crenage. `opsz` disparait : Plus
  /// Jakarta Sans n'a pas cet axe.
  static TextStyle _versCorps(TextStyle base) => base.copyWith(
    fontFamily: AppFontFamily.corps,
    fontVariations: <FontVariation>[
      _wghtCorps(base.fontWeight ?? FontWeight.w400),
    ],
  );

  static FontVariation _wghtCorps(FontWeight poids) => FontVariation(
    'wght',
    poids.value.toDouble().clamp(
      AppFontAxis.wghtCorpsMin,
      AppFontAxis.wghtCorpsMax,
    ),
  );
}
