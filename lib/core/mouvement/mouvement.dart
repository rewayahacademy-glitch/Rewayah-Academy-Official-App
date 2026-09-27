import 'package:flutter/widgets.dart';

/// Constantes de mouvement partagees (P2-16) : durees courtes, courbes
/// standard, aucune boucle. Tout composant anime lit ses valeurs ici et
/// passe par [Mouvement.duree] pour respecter « reduire les animations ».
abstract final class Mouvement {
  /// Retour visuel bref (toucher, bascule).
  static const Duration court = Duration(milliseconds: 150);

  /// Changement d'etat (chargement vers contenu, fondu d'onglet).
  static const Duration moyen = Duration(milliseconds: 220);

  /// Entree d'une page empilee.
  static const Duration long = Duration(milliseconds: 280);

  /// Borne haute : aucune animation de l'application ne la depasse.
  static const Duration maximum = Duration(milliseconds: 300);

  /// Decalage entre deux elements d'une liste echelonnee.
  static const Duration echelon = Duration(milliseconds: 35);

  /// A partir de ce rang, un element de liste apparait sans animation.
  static const int maxEchelonnes = 8;

  /// Distance du leger glisse d'apparition, en pixels logiques.
  static const double glisse = 12;

  /// Courbe d'entree standard.
  static const Curve entree = Curves.easeOutCubic;

  /// Courbe de sortie standard.
  static const Curve sortie = Curves.easeInCubic;

  /// Courbe « emphasized » de Material 3, pour les transitions de page.
  static const Curve accentuee = Curves.easeInOutCubicEmphasized;

  /// Vrai quand le systeme demande de reduire les animations.
  static bool reduit(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [voulue], ou zero quand les animations sont reduites.
  static Duration duree(BuildContext context, Duration voulue) =>
      reduit(context) ? Duration.zero : voulue;
}
