// ENTREE-PRAXIS : les outils communs de la scene d'entree, portes de la
// maquette « Praxis vous accueille » (vivant.dart) : les teintes [T], lues
// dans les jetons de la palette, et le ressort [R].
import 'package:flutter/widgets.dart';

import '../../theme/app_color_pair.dart';
import '../../theme/app_palette.dart';

Color _v(AppInkColor encre) => encre.asBorderSide().color;

/// Les teintes de la scene. [s] (theme sombre) est pose par la scene a chaque
/// construction ; les peintres le lisent au moment de peindre.
abstract final class T {
  /// Vrai en theme sombre.
  static bool s = false;
  static Color get fond => _v(s ? AppCouleursEntree.fondSombre : AppCouleursEntree.fondClair);
  static Color get surface => _v(s ? AppCouleursEntree.surfaceSombre : AppCouleursEntree.surfaceClair);
  static Color get surface2 => _v(s ? AppCouleursEntree.creuxSombre : AppCouleursEntree.creuxClair);
  static Color get encre => _v(s ? AppCouleursEntree.encreSombre : AppCouleursEntree.encreClair);
  static Color get filet => _v(s ? AppCouleursEntree.filetSombre : AppCouleursEntree.filetClair);
  static Color get pale => _v(s ? AppCouleursEntree.paleSombre : AppCouleursEntree.paleClair);
  static Color get corail => _v(s ? AppCouleursPraxis.corailSombre : AppCouleursPraxis.corailClair);
  static final Color lilas = _v(AppCouleursPraxis.lilas);
  static final Color nuit = _v(AppCouleursPraxis.encre);
  static final Color blanc = _v(AppCouleursPraxis.blanc);
  static final Color violet = _v(AppCouleursPraxis.violet);
  static final Color lavande = _v(AppCouleursEntree.lavande);
  static final Color noir = _v(AppCouleursEntree.noir);
}

/// Un ressort : position, vitesse, cible.
class R {
  R(this.x, {this.k = 220, this.c = 16}) : cible = x;
  double x, v = 0, cible, k, c;
  bool get repos => (x - cible).abs() < 0.001 && v.abs() < 0.01;
  void pas(double dt) {
    v += ((cible - x) * k - v * c) * dt;
    x += v * dt;
  }
}
