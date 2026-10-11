import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/marque/ornement_traces.g.dart';
import '../../core/marque/peinture_ornement.dart';

/// Les cotes du cadre ornemental d'une page du Mushaf de Medine (MUSHAF-15L).
///
/// **Un seul cadre, le plus simple** (decision du directeur, 11/10/2026 :
/// « plus c'est simple et moins charge mieux c'est ») : un ornement de la
/// marque en haut et en bas de la page, entre deux filets, sans bords lateraux.
/// Il vit dans la marge et reste mince : chaque bande prend [epaisseurRelative]
/// de la hauteur de la page, soit 4 % en tout.
@immutable
class GeometrieCadreMushaf {
  /// Cree la geometrie du cadre d'une page haute de [hauteurPage].
  const GeometrieCadreMushaf({required double hauteurPage})
    : epaisseur = hauteurPage * epaisseurRelative;

  /// La part de la hauteur de page que prend chaque bande, en haut et en bas.
  static const double epaisseurRelative = 0.02;

  /// L'epaisseur des bandes du haut et du bas.
  final double epaisseur;

  /// Ce que le cadre retire de la hauteur utile, en haut et en bas.
  double get hauteurPrise => 2 * epaisseur;
}

/// Le cadre d'une page : un dessin dans son propre `RepaintBoundary`, separe du
/// texte, repeint seulement quand sa taille ou sa couleur changent.
///
/// Aucune couleur n'est ecrite ici : [couleur] vient de la palette. Aucun
/// degrade, aucune ombre, rien derriere le texte : le cadre reste dans la
/// marge ([GeometrieCadreMushaf]).
class CadreMushaf extends StatelessWidget {
  /// Cree le cadre de la page.
  const CadreMushaf({
    required this.geometrie,
    required this.couleur,
    super.key,
  });

  /// Les cotes du cadre.
  final GeometrieCadreMushaf geometrie;

  /// L'unique couleur du cadre.
  final Color couleur;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PeintreCadre(epaisseur: geometrie.epaisseur, couleur: couleur),
      size: Size.infinite,
    ),
  );
}

class _PeintreCadre extends CustomPainter {
  _PeintreCadre({required this.epaisseur, required this.couleur});

  final double epaisseur;
  final Color couleur;

  /// Un ornement plein entre deux contours, un filet de chaque cote, en haut et
  /// en bas.
  @override
  void paint(Canvas canvas, Size size) {
    final double e = epaisseur;
    final Paint plein = Paint()
      ..color = couleur
      ..isAntiAlias = true;
    final Paint filet = Paint()
      ..color = couleur
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.75, e * 0.07);
    final double centre = size.width / 2;
    final double hauteur = e * 0.8;
    final double largeur = hauteur * ornementPlein.proportion;
    final double petite = hauteur * 0.68;
    final double ecart = largeur * 1.5;
    for (final bool haut in <bool>[true, false]) {
      final double y = haut ? e / 2 : size.height - e / 2;
      final double rotation = haut ? math.pi : 0;
      peindreOrnement(
        canvas,
        ornementPlein,
        Offset(centre, y),
        hauteur,
        plein,
        rotation: rotation,
      );
      for (final int sens in <int>[-1, 1]) {
        peindreOrnement(
          canvas,
          ornementContour,
          Offset(centre + sens * ecart, y),
          petite,
          plein,
          rotation: rotation,
        );
        canvas.drawLine(
          Offset(centre + sens * (ecart + largeur * 0.9), y),
          Offset(sens < 0 ? e * 0.5 : size.width - e * 0.5, y),
          filet,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreCadre ancien) =>
      ancien.epaisseur != epaisseur || ancien.couleur != couleur;
}

/// Le cartouche d'un nom de sourate : deux filets, et l'ornement plein de la
/// marge a chaque extremite. Meme couleur et meme regle que le cadre de la
/// page : un dessin dans son propre `RepaintBoundary`.
class FiletsCartoucheMushaf extends StatelessWidget {
  /// Cree le dessin du cartouche.
  const FiletsCartoucheMushaf({required this.couleur, super.key});

  /// L'unique couleur du dessin.
  final Color couleur;

  static const double _partOrnement = 0.6;

  /// La largeur que prennent les ornements d'une extremite, pour une hauteur de
  /// cartouche [hauteur] : le texte doit rester en dehors.
  static double reserve(double hauteur) =>
      hauteur * _partOrnement * ornementPlein.proportion * 1.2 + hauteur * 0.2;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PeintreCartouche(couleur: couleur),
      size: Size.infinite,
    ),
  );
}

class _PeintreCartouche extends CustomPainter {
  _PeintreCartouche({required this.couleur});

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final Paint plein = Paint()
      ..color = couleur
      ..isAntiAlias = true;
    final Paint filet = Paint()
      ..color = couleur
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.75, h * 0.03);
    final double oh = h * FiletsCartoucheMushaf._partOrnement;
    final double ow = oh * ornementPlein.proportion;
    final double reserve = FiletsCartoucheMushaf.reserve(h);
    final double marge = h * 0.12;
    canvas
      ..drawLine(
        Offset(reserve, marge),
        Offset(size.width - reserve, marge),
        filet,
      )
      ..drawLine(
        Offset(reserve, h - marge),
        Offset(size.width - reserve, h - marge),
        filet,
      );
    for (final double x in <double>[
      h * 0.1 + ow * 0.6,
      size.width - h * 0.1 - ow * 0.6,
    ]) {
      peindreOrnement(canvas, ornementPlein, Offset(x, h / 2), oh, plein);
    }
  }

  @override
  bool shouldRepaint(_PeintreCartouche ancien) => ancien.couleur != couleur;
}
