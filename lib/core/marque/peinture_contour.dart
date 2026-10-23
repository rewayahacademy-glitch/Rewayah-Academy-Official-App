import 'package:flutter/painting.dart';

import '../widgets/brand_logo.dart' show cheminDepuisTrace;
import 'dessin_contour.dart';

/// Peint le symbole en contour [dessin], son coin haut gauche en [origine],
/// large de [largeur], d'un trait de l'unique couleur [couleur].
///
/// **Le symbole du directeur, jamais redessine.** Les traces sont ceux de
/// `contour_traces.g.dart`, recopies mot pour mot depuis
/// `assets/brand/logo/*/symbole-contour.svg` ; le trait a l'epaisseur du
/// fichier (`stroke-width`), dans les unites du `viewBox`, donc il grossit avec
/// le dessin comme dans le SVG, et sa jointure est ronde comme dans le fichier.
///
/// **Toujours dans son sens d'origine** : aucune rotation, aucun miroir, ni
/// vertical ni horizontal, en LTR comme en RTL. La seule transformation est une
/// translation et une echelle homogene positive ; la fonction n'a donc pas de
/// parametre de rotation. Le dessin peut depasser du canevas : c'est le canevas
/// qui le coupe (un filigrane agrandi, que l'on ne voit qu'en partie).
///
/// Les deux traces forment **un seul chemin**, peint en un seul trait : une
/// [couleur] translucide ne s'assombrit pas la ou ils se touchent.
void peindreContour(
  Canvas canvas,
  DessinContour dessin,
  Offset origine,
  double largeur,
  Color couleur,
) {
  final double echelle = largeur / dessin.largeur;
  canvas
    ..save()
    ..translate(origine.dx, origine.dy)
    ..scale(echelle);
  canvas.drawPath(
    _trace(dessin),
    Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = dessin.epaisseur
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true,
  );
  canvas.restore();
}

final Map<DessinContour, Path> _traces = <DessinContour, Path>{};

Path _trace(DessinContour d) => _traces.putIfAbsent(d, () {
  final Path chemin = Path();
  for (final String trace in d.traces) {
    chemin.addPath(cheminDepuisTrace(trace), Offset.zero);
  }
  return chemin;
});
