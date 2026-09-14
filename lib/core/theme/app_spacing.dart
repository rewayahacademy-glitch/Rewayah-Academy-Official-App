import 'package:flutter/widgets.dart';

/// Echelle d'espacement fixe : 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
///
/// Aucune valeur ponctuelle en dehors de cette echelle
/// (`docs/produit/design-tokens.md` section 7). `tool/verifier_jetons.dart`
/// echoue sur toute valeur d'espacement litterale hors echelle dans `lib/`.
///
/// La refonte l'a etendue vers le haut : les paliers courts servaient
/// l'interieur des composants, ceux du rythme de page manquaient. Les trois
/// nouveaux portent un nom d'usage plutot qu'un rang, parce qu'ils n'ont
/// chacun qu'un emploi et qu'un `xxxxxl` ne se lit pas.
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

  /// 40 points : ecart entre deux sections, avec [xxxl].
  static const double section = 40;

  /// 48 points : marge haute d'un titre d'ecran.
  static const double titreEcran = 48;

  /// 64 points : respiration d'un ecran vide ou d'un accueil enfant.
  static const double respiration = 64;

  /// L'echelle complete, dans l'ordre. Sert aux tests et a la verification.
  static const List<double> echelle = <double>[
    xs,
    sm,
    md,
    lg,
    xl,
    xxl,
    xxxl,
    section,
    titreEcran,
    respiration,
  ];
}

/// Le rythme de la page : gouttieres, largeur de contenu, largeur de lecture.
///
/// Source : `docs/produit/design-tokens.md` section 7 et
/// `docs/design/01-systeme-visuel.md` section 6.
abstract final class AppPage {
  /// Gouttiere laterale sur mobile.
  static const double gouttiereMobile = AppSpacing.lg;

  /// Gouttiere laterale sur tablette.
  static const double gouttiereTablette = AppSpacing.xxl;

  /// Gouttiere laterale sur desktop.
  static const double gouttiereDesktop = AppSpacing.xxxl;

  /// Largeur maximale du contenu. Au dela, la colonne se centre.
  static const double largeurMaxContenu = 1200;
  static const double largeurFormulaire = 640;
  static const double largeurReglages = 760;
  static const double largeurLecture = 800;
  static const double largeurGestion = 1440;
  static const double largeurEtatVide = 400;
  static const double hauteurBouton = 52;
  static const double hauteurChoix = 112;
  static const double hauteurReglage = 64;

  /// Largeur maximale d'un formulaire d'acces centre.
  static const double largeurFormulaire = 640;

  /// Largeur de lecture, en caracteres, pour tout texte suivi.
  ///
  /// En caracteres et non en pixels : c'est la mesure qui survit au changement
  /// de taille de police. Un paragraphe pose sur 1200 pixels ne se lit pas, il
  /// se survole.
  static const int largeurLectureCaracteres = 68;
}

/// Cibles tactiles minimales.
///
/// 72pt en mode enfant, 48pt en mode standard
/// (`docs/architecture/etape-2-core-flutter.md` section 2, ligne `BentoTile`).
abstract final class AppTouchTarget {
  /// Cible minimale en mode enfant.
  static const double enfant = 72;

  /// Cible minimale en mode standard.
  static const double standard = 48;
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

  /// Espace vertical de 40 : entre deux sections.
  static const Widget vSection = SizedBox(height: AppSpacing.section);

  /// Espace vertical de 48 : au dessus d'un titre d'ecran.
  static const Widget vTitreEcran = SizedBox(height: AppSpacing.titreEcran);

  /// Espace vertical de 64 : respiration d'un ecran vide.
  static const Widget vRespiration = SizedBox(height: AppSpacing.respiration);

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
