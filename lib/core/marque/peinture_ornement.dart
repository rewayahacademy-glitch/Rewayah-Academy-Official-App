import 'package:flutter/painting.dart';

import '../widgets/brand_logo.dart' show cheminDepuisTrace;
import 'dessin_ornement.dart';

/// Peint [dessin] au centre de [centre], haut de [hauteur], de l'unique
/// couleur de [peinture].
///
/// **Toujours dans son sens d'origine, celui du SVG** (decision du directeur,
/// 11/10/2026) : aucune rotation, aucun miroir, ni vertical ni horizontal, en
/// haut comme en bas, en LTR comme en RTL. La seule transformation est une
/// translation et une echelle homogene positive ; c'est pourquoi la fonction
/// n'a pas de parametre de rotation.
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
  Paint peinture,
) {
  final double echelle = hauteur / dessin.hauteur;
  canvas
    ..save()
    ..translate(
      centre.dx - dessin.largeur * echelle / 2,
      centre.dy - hauteur / 2,
    )
    ..scale(echelle);
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
