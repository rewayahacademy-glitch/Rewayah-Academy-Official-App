import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// Constantes de mouvement partagees (P2-16). Ce fichier ne definit plus de
/// valeur : chaque constante renvoie a un jeton de [AppMouvement]
/// (DESIGN-GOV contrat E, audit final L3-03).
///
/// Correspondance :
/// - court   = AppMouvement.micro          (150 ms devient 120 ms)
/// - moyen   = AppMouvement.navigation     (220 ms, aucun effet)
/// - long    = AppMouvement.navigation     (280 ms devient 220 ms)
/// - maximum = AppMouvement.plafond        (300 ms devient 400 ms)
/// - entree  = AppMouvement.entree         (identique)
/// - sortie  = AppMouvement.sortie         (identique)
///
/// Deux constantes restent litterales faute de jeton : echelon (35 ms) et
/// accentuee. Jeton a creer sur decision du directeur, question A-13.
abstract final class Mouvement {
  /// Retour visuel bref (toucher, bascule).
  static const Duration court = AppMouvement.micro;

  /// Changement d'etat (chargement vers contenu, fondu d'onglet).
  static const Duration moyen = AppMouvement.navigation;

  /// Entree d'une page empilee.
  static const Duration long = AppMouvement.navigation;

  /// Borne haute : aucune animation de l'application ne la depasse.
  static const Duration maximum = AppMouvement.plafond;

  /// Decalage entre deux elements d'une liste echelonnee.
  static const Duration echelon = AppMouvement.echelon;

  /// A partir de ce rang, un element de liste apparait sans animation.
  static const int maxEchelonnes = 8;

  /// Distance du leger glisse d'apparition, en pixels logiques.
  static const double glisse = 12;

  /// Courbe d'entree standard.
  static const Curve entree = AppMouvement.entree;

  /// Courbe de sortie standard.
  static const Curve sortie = AppMouvement.sortie;

  /// Courbe « emphasized » de Material 3, pour les transitions de page.
  static const Curve accentuee = AppMouvement.accentuee;

  /// Vrai quand le systeme demande de reduire les animations.
  static bool reduit(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [voulue], ou zero quand les animations sont reduites.
  static Duration duree(BuildContext context, Duration voulue) =>
      reduit(context) ? Duration.zero : voulue;
}
