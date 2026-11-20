// VIVANT (directeur, 20/11/2026 : maquette validee « pour aller vite »,
// PARCOURS-ENSEIGNANT/PLAN §13) : le ressort commun a tout ce qui bouge.
//
// Tout part du toucher, depasse un peu, se pose, puis se tait : quand tous les
// ressorts d'un composant sont au repos, son horloge s'arrete et plus aucune
// image n'est produite. Seule l'eau ([VieDesRessorts.toujours]) continue.
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../accessibilite/mode_accessibilite.dart';

/// Un ressort : une position, une vitesse, une cible.
///
/// [raideur] le tire vers sa cible, [frein] l'amortit. Plus de raideur : plus
/// vif ; moins de frein : il depasse davantage avant de se poser.
class Ressort {
  /// Cree un ressort pose en [x].
  Ressort(this.x, {this.raideur = 220, this.frein = 16}) : cible = x;

  /// La position courante.
  double x;

  /// La vitesse courante.
  double v = 0;

  /// La position ou il va se poser.
  double cible;

  /// La force de rappel.
  final double raideur;

  /// L'amortissement.
  final double frein;

  /// Pose : assez pres de la cible et assez lent pour ne plus se voir.
  bool get repos => (x - cible).abs() < 0.001 && v.abs() < 0.01;

  /// Avance de [dt] secondes.
  void pas(double dt) {
    v += ((cible - x) * raideur - v * frein) * dt;
    x += v * dt;
  }

  /// Se pose tout de suite sur la cible, sans mouvement (effets reduits).
  void poser() {
    x = cible;
    v = 0;
  }
}

/// Fait vivre des ressorts tant qu'ils bougent, puis se tait.
///
/// Le composant declare ses [ressorts], change leurs cibles puis appelle
/// [reveil]. Sous « Reduire les effets » (reglage du compte ou du systeme),
/// [reveil] pose chaque ressort sur sa cible sans produire d'image animee.
mixin VieDesRessorts<W extends StatefulWidget>
    on State<W>, SingleTickerProviderStateMixin<W> {
  late final Ticker _horloge = createTicker(_tic);
  Duration _avant = Duration.zero;

  /// Le temps vecu, en secondes : la phase des dessins qui ondulent.
  double temps = 0;

  /// Les ressorts que l'horloge fait avancer.
  Iterable<Ressort> get ressorts;

  /// Vrai pour ce qui ne se tait jamais tant qu'il est a l'ecran (l'eau).
  bool get toujours => false;

  /// Faux tant qu'un mouvement hors ressort (chute, larme) n'est pas fini.
  bool get finiAussi => true;

  /// Le mouvement hors ressort, appele a chaque pas.
  void surPas(double dt) {}

  /// Appele une fois quand les effets sont reduits : poser l'etat final de
  /// ce qui n'est pas un ressort.
  void surPoseSansMouvement() {}

  /// L'horloge tourne : une image sera produite au prochain rafraichissement.
  bool get enMouvement => _horloge.isActive;

  /// Les effets sont reduits : rien ne s'anime.
  bool get effetsReduits =>
      EffetsReduits.de(context) ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// A appeler apres avoir change une cible ou donne une impulsion.
  void reveil() {
    if (!mounted) return;
    if (effetsReduits) {
      _horloge.stop();
      for (final Ressort r in ressorts) {
        r.poser();
      }
      surPoseSansMouvement();
      setState(() {});
      return;
    }
    if (!_horloge.isActive) {
      _avant = Duration.zero;
      // Le futur de l'horloge ne se complete qu'a son arret : on ne l'attend
      // pas.
      // ignore: discarded_futures
      _horloge.start();
    }
  }

  void _tic(Duration d) {
    final double dt = math.min(0.032, (d - _avant).inMicroseconds / 1e6);
    _avant = d;
    temps += dt;
    for (final Ressort r in ressorts) {
      r.pas(dt);
    }
    surPas(dt);
    if (!toujours && finiAussi && ressorts.every((Ressort r) => r.repos)) {
      for (final Ressort r in ressorts) {
        r.poser();
      }
      _horloge.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _horloge.dispose();
    super.dispose();
  }
}
