import 'package:flutter/painting.dart';

import '../widgets/brand_logo.dart' show cheminDepuisTrace;
import 'dessin_ornement.dart';

/// Peint [dessin] au centre de [centre], haut de [hauteur], tourne de
/// [rotation] radians, de l'unique couleur de [peinture].
///
/// Le contour est peint comme le fichier le declare : le trace epais, prive de
/// la forme pleine qui le masque (le `<mask>` de `ornement-contour.svg`).
/// Aucun asset charge, aucune dependance SVG : les traces sont ceux de
/// `ornement_traces.g.dart`, recopies mot pour mot par
/// `tool/generer_ornement.dart`.
void peindreOrnement(
  Canvas canvas,
  DessinOrnement dessin,
  Offset centre,
  double hauteur,
  Paint peinture, {
  double rotation = 0,
}) {
  final double echelle = hauteur / dessin.hauteur;
  canvas
    ..save()
    ..translate(centre.dx, centre.dy)
    ..rotate(rotation)
    ..scale(echelle)
    ..translate(-dessin.largeur / 2, -dessin.hauteur / 2);
  if (dessin.masque != null) {
    canvas.clipPath(_decoupe(dessin), doAntiAlias: true);
  }
  canvas.drawPath(_trace(dessin), peinture);
  canvas.restore();
}

final Map<DessinOrnement, Path> _traces = <DessinOrnement, Path>{};
final Map<DessinOrnement, Path> _decoupes = <DessinOrnement, Path>{};

Path _trace(DessinOrnement d) =>
    _traces.putIfAbsent(d, () => cheminDepuisTrace(d.trace));

/// La part du plan qui reste hors de la forme du masque.
Path _decoupe(DessinOrnement d) => _decoupes.putIfAbsent(d, () {
  final Path plan = Path()
    ..addRect(
      Rect.fromLTWH(-d.largeur, -d.hauteur, d.largeur * 3, d.hauteur * 3),
    );
  return Path.combine(
    PathOperation.difference,
    plan,
    cheminDepuisTrace(d.masque!),
  );
});
