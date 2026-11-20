// ENTREE-PRAXIS : la regie de la scene d'entree. Elle tient l'horloge du
// theatre de Praxis (`scene_entree.dart`) et decide quand elle tourne :
//
// - elle avance du temps reellement ecoule ;
// - elle se tait quand plus rien ne bouge (Praxis s'endort : plus aucune
//   image n'est demandee), et se reveille au premier evenement ;
// - elle s'arrete quand l'application n'est plus au premier plan ;
// - sous « Reduire les effets », aucune horloge ne tourne hors d'une scene.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'gestes_praxis.dart';
import 'lumiere_entree.dart';
import 'scene_entree.dart';

/// Une scene : ce que Praxis fait, pas a pas, sur l'horloge du theatre. Elle
/// recoit le numero de sa generation et s'arrete seule quand une autre scene
/// la remplace (les attentes du theatre levent [Annule]).
typedef ScenePraxis = Future<void> Function(Theatre th, int g);

/// La regie : un theatre, une horloge, un sommeil.
class RegiePraxis with WidgetsBindingObserver {
  /// Cree la regie ; [vsync] donne l'horloge de l'ecran.
  RegiePraxis(TickerProvider vsync) {
    _horloge = vsync.createTicker(_image);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Le theatre : Praxis, la porte, la route, les mots.
  final Theatre th = Theatre();

  /// La geometrie de la scene pour un recul de camera donne ; relue a chaque
  /// image (la camera accompagne l'approche de Praxis).
  Geo Function(double cam)? cadrage;

  /// Appele a chaque image, apres le pas du theatre (suivre un texte des
  /// yeux, adoucir une hauteur).
  void Function(double dt)? surImage;

  late final Ticker _horloge;
  Duration _avant = Duration.zero;
  int _scenes = 0;
  double _dernierActe = 0;
  bool _ferme = false;
  bool _visible = true;

  /// Le temps de repos, en secondes d'horloge, apres lequel Praxis s'endort :
  /// les ressorts (toque, pompon, mains) ont fini de se poser.
  static const double _veille = 5;

  /// Sous mouvement reduit, rien ne bouge au repos : l'horloge s'arrete des
  /// que la derniere image de la scene est peinte.
  static const double _veilleReduite = 0.6;

  /// Vrai quand l'horloge tourne (une image est demandee a chaque trame).
  bool get eveillee => _horloge.isActive;

  /// Vrai sous « Reduire les effets ».
  bool get reduit => th.reduit;
  set reduit(bool valeur) {
    th.reduit = valeur;
    th.px.reduit = valeur;
  }

  /// Prepare les textures de lumiere (grain, rais, poussiere, ombre) : une
  /// fois pour l'application, **apres** la premiere image, pour ne pas
  /// retarder le champ et le bouton. La scene se peint sans elles en attendant.
  static void preparerLumiere() {
    if (_lumiereDemandee) return;
    _lumiereDemandee = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      unawaited(
        Atelier.preparer().catchError((Object _) {
          // Sans textures, la scene reste lisible : le grain et les rais
          // manquent, rien d'autre.
        }),
      );
    });
  }

  static bool _lumiereDemandee = false;

  /// Reveille l'horloge : un evenement vient d'arriver.
  void reveiller() {
    if (_ferme) return;
    _dernierActe = th.temps;
    if (!_visible || _horloge.isActive) return;
    _avant = Duration.zero;
    _horloge.start();
  }

  void _image(Duration d) {
    final double dt = _avant == Duration.zero
        ? 0
        : (d - _avant).inMicroseconds / 1e6;
    _avant = d;
    final Geo Function(double cam)? c = cadrage;
    if (c != null) th.geo = c(th.cam.x);
    if (dt > 0) {
      th.avancer(dt);
      surImage?.call(dt);
    }
    final bool occupe = _scenes > 0 || th.parole != null || !th.px.arrive;
    if (occupe) {
      _dernierActe = th.temps;
    } else if (th.temps - _dernierActe > (reduit ? _veilleReduite : _veille)) {
      _horloge.stop();
    }
  }

  /// Joue [scene]. [depuisPorte] remet Praxis derriere la lumiere d'abord ;
  /// sinon la scene en cours est remplacee la ou il se trouve.
  Future<void> jouer(ScenePraxis scene, {bool depuisPorte = false}) async {
    if (_ferme) return;
    final Geo Function(double cam)? c = cadrage;
    if (c != null) th.geo = c(th.cam.x);
    if (depuisPorte) {
      th.initial();
      if (c != null) th.geo = c(th.cam.x);
    } else {
      th.gen++;
    }
    final int g = th.gen;
    _scenes++;
    reveiller();
    try {
      await scene(th, g);
    } on Annule {
      // Une autre scene a commence, ou l'ecran s'est ferme.
    } finally {
      _scenes--;
      _dernierActe = th.temps;
    }
  }

  /// Une reaction courte, sans remplacer la scene en cours (un toucher).
  Future<void> reagir(ScenePraxis reaction) async {
    if (_ferme) return;
    final int g = th.gen;
    _scenes++;
    reveiller();
    try {
      await reaction(th, g);
    } on Annule {
      // La scene a change entre-temps.
    } finally {
      _scenes--;
      _dernierActe = th.temps;
    }
  }

  /// Vrai si [point] (repere de la scene) touche Praxis.
  bool touche(Offset point) =>
      th.present &&
      (point - th.centrePraxis).distance < th.largeurPraxis * 0.5;

  /// Pose Praxis au premier plan, de face, sans scene (premiere image sous
  /// mouvement reduit, captures).
  void poser({Expr expression = Expr.sourire}) {
    final Geo Function(double cam)? c = cadrage;
    if (c != null) th.geo = c(1);
    th.initial();
    th.px
      ..placer(1)
      ..poser(expression);
    th.px.fondu.x = th.px.fondu.cible = 1;
    th.eclat.x = th.eclat.cible = 1;
    th.cam.x = th.cam.cible = 1;
    if (c != null) th.geo = c(1);
    reveiller();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (!_visible) {
      _horloge.stop();
    } else if (_scenes > 0 || th.parole != null) {
      reveiller();
    }
  }

  /// Ferme la regie : l'horloge s'arrete, toute scene en cours se termine.
  void fermer() {
    if (_ferme) return;
    _ferme = true;
    WidgetsBinding.instance.removeObserver(this);
    th.fermer();
    _horloge.dispose();
  }

  /// Le plus petit cote utile d'une scene : en dessous, elle ne se lit plus.
  static double hauteurScene({
    required double ecran,
    required double besoin,
    required double recouvrement,
  }) => math.max(
    ecran * 0.38,
    math.min(ecran * 0.56, ecran - besoin + recouvrement),
  );
}
