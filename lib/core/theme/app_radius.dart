import 'package:flutter/widgets.dart';

/// Les cinq rayons de l'application, pas un de plus.
///
/// Source : `docs/produit/design-tokens.md` section 8.
/// `tool/verifier_jetons.dart` echoue sur tout `BorderRadius.circular` construit
/// avec une valeur litterale ailleurs que dans ce fichier : c'est ainsi qu'un
/// rayon de 20 invente au fil d'un ecran ne peut pas entrer dans le produit.
///
/// **Le rayon d'un enfant est plus petit que celui de son parent.** Une vignette
/// dans une carte [md] prend [sm]. L'inverse produit l'effet de bulle qui date
/// le produit. [enfantDe] applique la regle sans avoir a s'en souvenir.
abstract final class AppRadius {
  /// Pastilles, petits controles, vignettes.
  static const double xs = 8;

  /// Champs, boutons.
  static const double sm = 12;

  /// Cartes.
  static const double md = 16;

  /// Tuiles Bento, feuilles de bas d'ecran.
  static const double lg = 24;

  /// Avatars, pilules d'etat. Volontairement enorme : c'est un demi-cercle
  /// quelle que soit la hauteur du controle.
  static const double full = 999;

  /// L'echelle complete, du plus serre au plus ouvert. Sert aux tests et a la
  /// verification. [full] en est exclu : ce n'est pas un cran de l'echelle,
  /// c'est une forme.
  static const List<double> echelle = <double>[xs, sm, md, lg];

  /// Arrondi de pastille.
  static const BorderRadius arrondiXs = BorderRadius.all(Radius.circular(xs));

  /// Arrondi de champ ou de bouton.
  static const BorderRadius arrondiSm = BorderRadius.all(Radius.circular(sm));

  /// Arrondi de carte.
  static const BorderRadius arrondiMd = BorderRadius.all(Radius.circular(md));

  /// Arrondi de tuile Bento ou de feuille.
  static const BorderRadius arrondiLg = BorderRadius.all(Radius.circular(lg));

  /// Arrondi d'avatar ou de pilule.
  static const BorderRadius arrondiFull = BorderRadius.all(
    Radius.circular(full),
  );

  /// Le plus grand cran strictement inferieur a [parent].
  ///
  /// Un rayon deja au plus serre le reste : on ne descend jamais sous [xs].
  /// [full] n'etant pas un cran de l'echelle, son enfant est [lg].
  static double enfantDe(double parent) {
    double resultat = xs;
    for (final double cran in echelle) {
      if (cran < parent) {
        resultat = cran;
      }
    }
    return resultat;
  }

  /// L'arrondi correspondant au cran immediatement inferieur a [parent].
  static BorderRadius arrondiEnfantDe(double parent) =>
      BorderRadius.all(Radius.circular(enfantDe(parent)));
}
