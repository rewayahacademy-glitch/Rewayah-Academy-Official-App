// TB-7a (plan V2 §9, §13 ; TB19) : le repere des notes est la page, jamais
// la boite de la surface ni la fenetre.
//
// Une seule geometrie, lue par le rendu ET par la saisie :
//   1. le rectangle reel de la page apres `BoxFit.contain` ([rectanglePage]) ;
//   2. la transformation locale de lecture (zoom, deplacement), commune a
//      l'image et a l'encre : une matrice de `TransformationController` ;
//   3. un point de la surface -> `toScene` (inverse du zoom et du
//      deplacement) -> retrait de l'offset du placement -> normalisation
//      dans la page ; un point hors page est REJETE (jamais rabattu sur le
//      bord, §9.4).
// Rien n'est stocke en pixels : seul le `PointNormalise` sort d'ici.

import 'package:flutter/widgets.dart';

import '../../core/tc_outils/annotation_layer.dart' show PointNormalise;
import 'surface_page_fixe.dart' show rectanglePage;

/// Le repere de la page dans la surface, a un instant donne.
@immutable
class ReperePage {
  /// Un repere : la page placee dans sa boite, et la transformation locale
  /// de lecture (identite = 100 %, sans deplacement).
  ReperePage({required this.page, Matrix4? lecture})
    : lecture = lecture ?? Matrix4.identity();

  /// Le repere d'une page de [ratio] dans la [boite] de la surface, lue au
  /// [zoom] local autour du centre de la boite, puis deplacee de
  /// [deplacement] (en points de la surface). Le centre de la page est celui
  /// de la boite (`Alignment.center`) : le zoom garde la page centree,
  /// comme le `Transform.scale` de TB-6.
  factory ReperePage.de({
    required double ratio,
    required Size boite,
    double zoom = 1,
    Offset deplacement = Offset.zero,
  }) {
    final Offset centre = boite.center(Offset.zero);
    final Matrix4 lecture = Matrix4.identity()
      ..translateByDouble(
        deplacement.dx + centre.dx,
        deplacement.dy + centre.dy,
        0,
        1,
      )
      ..scaleByDouble(zoom, zoom, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
    return ReperePage(
      page: rectanglePage(ratio: ratio, boite: boite),
      lecture: lecture,
    );
  }

  /// Le rectangle de la page dans la boite, avant la lecture locale
  /// (`BoxFit.contain`, centre).
  final Rect page;

  /// La transformation locale de lecture, appliquee ENSEMBLE a l'image et
  /// aux notes. Jamais diffusee (plan V2 §8 : zoom local).
  final Matrix4 lecture;

  /// Le controleur de la transformation : `toScene` est l'inverse du zoom
  /// et du deplacement (plan V2 §9.2).
  TransformationController controleur() => TransformationController(lecture);

  /// Le point de la page sous [pointSurface] (coordonnees de la boite de la
  /// surface), normalise dans la page reelle ; `null` hors de la page : le
  /// geste est rejete, pas rabattu sur le bord (§9.4).
  PointNormalise? versPage(Offset pointSurface) {
    final TransformationController c = controleur();
    final Offset scene = c.toScene(pointSurface);
    c.dispose();
    // Retrait de l'offset du placement `BoxFit.contain`.
    final Offset dansPage = scene - page.topLeft;
    if (dansPage.dx < 0 ||
        dansPage.dy < 0 ||
        dansPage.dx > page.width ||
        dansPage.dy > page.height) {
      return null;
    }
    return PointNormalise(dansPage.dx / page.width, dansPage.dy / page.height);
  }

  /// Le point de la surface ou se peint [point] de la page : l'operation
  /// inverse de [versPage].
  Offset versSurface(PointNormalise point) => MatrixUtils.transformPoint(
    lecture,
    page.topLeft + Offset(point.x * page.width, point.y * page.height),
  );

  /// Le rectangle de la page tel qu'il se voit a l'ecran (lecture comprise).
  Rect get pageALEcran => MatrixUtils.transformRect(lecture, page);
}
