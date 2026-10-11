import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/env.dart';
import '../../core/marque/dessin_ornement.dart';
import '../../core/marque/ornement_traces.g.dart';
import '../../core/widgets/brand_logo.dart' show cheminDepuisTrace;

/// Le cadre ornemental d'une page du Mushaf de Medine (MUSHAF-15L).
///
/// Trois propositions, que le drapeau `MUSHAF_15L_CADRE` choisit tant que le
/// directeur n'a pas tranche :
///
/// - [a] sobre : un filet double et l'ornement-contour aux quatre coins ;
/// - [b] classique : un bandeau d'ornements, plein et contour en alternance
///   (plus riche sur les pages 1 et 2, comme dans les Mushafs imprimes) ;
/// - [c] minimal pour telephone : un ornement en haut et en bas, sans bords.
enum StyleCadreMushaf {
  /// Filet double, ornement-contour aux coins.
  a,

  /// Bandeau d'ornements, plein et contour en alternance.
  b,

  /// Ornement en haut et en bas seulement.
  c;

  /// Le style que designe [code] (`A`, `B`, `C`, sans egard a la casse) ;
  /// `A` pour toute autre valeur.
  static StyleCadreMushaf depuisCode(String code) =>
      switch (code.trim().toUpperCase()) {
        'B' => StyleCadreMushaf.b,
        'C' => StyleCadreMushaf.c,
        _ => StyleCadreMushaf.a,
      };

  /// Un style impose par les tests et les captures, qui ne peuvent pas changer
  /// le drapeau de compilation ; `null` en production.
  @visibleForTesting
  static StyleCadreMushaf? surcharge;

  /// Le style que le drapeau `MUSHAF_15L_CADRE` choisit.
  static StyleCadreMushaf get courant =>
      surcharge ?? depuisCode(Env.mushaf15LCadre);
}

/// Les cotes du cadre autour d'une page.
///
/// **Le cadre vit dans la marge et reste mince** : ses bandes du haut et du
/// bas prennent chacune [epaisseurRelative] de la hauteur de la page, soit 4 %
/// en tout, la limite fixee par le directeur. Les bords lateraux sont plus
/// etroits encore ; le style C n'en a pas.
@immutable
class GeometrieCadreMushaf {
  /// Cree la geometrie d'un cadre de style [style] sur une page haute de
  /// [hauteurPage].
  const GeometrieCadreMushaf({required this.style, required double hauteurPage})
    : epaisseur = hauteurPage * epaisseurRelative;

  /// La part de la hauteur de page que prend chaque bande, en haut et en bas.
  static const double epaisseurRelative = 0.02;

  /// Le style du cadre.
  final StyleCadreMushaf style;

  /// L'epaisseur des bandes du haut et du bas.
  final double epaisseur;

  /// L'epaisseur des bords lateraux (rien pour le style C).
  double get lateral => style == StyleCadreMushaf.c ? 0 : epaisseur * 0.6;

  /// La hauteur d'un ornement de coin.
  double get hauteurCoin => epaisseur * 1.6;

  /// La largeur d'un ornement de coin.
  double get largeurCoin => hauteurCoin * ornementPlein.proportion;

  /// Ce que le cadre retire de la hauteur utile, en haut et en bas.
  double get hauteurPrise => 2 * epaisseur;
}

/// Peint [dessin] au centre de [centre], haut de [hauteur], tourne de
/// [rotation] radians. Le contour est peint comme le fichier le declare : le
/// trace epais, prive de la forme pleine qui le masque.
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

/// Le cadre d'une page : un dessin dans son propre `RepaintBoundary`, separe du
/// texte, repeint seulement quand sa taille, son style ou sa couleur changent.
///
/// Aucune couleur n'est ecrite ici : [couleur] vient de la palette. Aucun
/// degrade, aucune ombre, rien derriere le texte : le cadre reste dans la
/// marge ([GeometrieCadreMushaf]).
class CadreMushaf extends StatelessWidget {
  /// Cree le cadre de la page.
  const CadreMushaf({
    required this.geometrie,
    required this.couleur,
    this.riche = false,
    super.key,
  });

  /// Les cotes du cadre.
  final GeometrieCadreMushaf geometrie;

  /// L'unique couleur du cadre.
  final Color couleur;

  /// Vrai pour les pages 1 et 2 : une version plus riche du bandeau.
  final bool riche;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PeintreCadre(
        style: geometrie.style,
        epaisseur: geometrie.epaisseur,
        couleur: couleur,
        riche: riche,
      ),
      size: Size.infinite,
    ),
  );
}

class _PeintreCadre extends CustomPainter {
  _PeintreCadre({
    required this.style,
    required this.epaisseur,
    required this.couleur,
    required this.riche,
  });

  final StyleCadreMushaf style;
  final double epaisseur;
  final Color couleur;
  final bool riche;

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
    switch (style) {
      case StyleCadreMushaf.a:
        _filetsDoubles(canvas, size, filet, e);
        _coins(canvas, size, plein, ornementContour, e * 1.6);
      case StyleCadreMushaf.b:
        _bandeau(canvas, size, plein, e);
        _filetsDoubles(canvas, size, filet, e, interieur: riche);
        _coins(canvas, size, plein, ornementPlein, e * (riche ? 2.0 : 1.6));
      case StyleCadreMushaf.c:
        _hautEtBas(canvas, size, plein, filet, e);
    }
  }

  /// Les quatre coins, l'ornement tourne vers le centre de la page.
  void _coins(
    Canvas canvas,
    Size size,
    Paint peinture,
    DessinOrnement dessin,
    double hauteur,
  ) {
    final double largeur = hauteur * dessin.proportion;
    for (final bool haut in <bool>[true, false]) {
      for (final bool gauche in <bool>[true, false]) {
        peindreOrnement(
          canvas,
          dessin,
          Offset(
            gauche ? largeur / 2 : size.width - largeur / 2,
            haut ? hauteur / 2 : size.height - hauteur / 2,
          ),
          hauteur,
          peinture,
          rotation: haut ? math.pi : 0,
        );
      }
    }
  }

  /// Le filet double, interrompu aux coins ; [interieur] ajoute un troisieme
  /// filet, plus fin, pour la version riche.
  void _filetsDoubles(
    Canvas canvas,
    Size size,
    Paint filet,
    double e, {
    bool interieur = false,
  }) {
    final double coin = e * 1.6 * ornementPlein.proportion + e * 0.35;
    final double coinHaut = e * 1.6 + e * 0.35;
    final List<double> retraits = <double>[
      e * 0.14,
      e * 0.14 + e * 0.24,
      if (interieur) e * 0.14 + e * 0.48,
    ];
    for (final double r in retraits) {
      canvas
        ..drawLine(Offset(coin, r), Offset(size.width - coin, r), filet)
        ..drawLine(
          Offset(coin, size.height - r),
          Offset(size.width - coin, size.height - r),
          filet,
        )
        ..drawLine(
          Offset(r, coinHaut),
          Offset(r, size.height - coinHaut),
          filet,
        )
        ..drawLine(
          Offset(size.width - r, coinHaut),
          Offset(size.width - r, size.height - coinHaut),
          filet,
        );
    }
  }

  /// Le bandeau du style B : des ornements, plein et contour en alternance,
  /// sur les quatre bords.
  void _bandeau(Canvas canvas, Size size, Paint peinture, double e) {
    final double hauteur = e * 0.62;
    final double pas = hauteur * ornementPlein.proportion * (riche ? 2.1 : 2.8);
    final double reserve = e * 1.6 * ornementPlein.proportion + e * 0.9;
    final double reserveHaut = e * 1.6 + e * 0.9;
    final double fond = e * 0.5;

    void rangee(
      Offset debut,
      Offset fin,
      double rotation, {
      double? hauteurRangee,
      double? pasRangee,
    }) {
      final double longueur = (fin - debut).distance;
      final int n = math.max(1, (longueur / (pasRangee ?? pas)).floor());
      for (int i = 0; i < n; i++) {
        final double t = (i + 0.5) / n;
        peindreOrnement(
          canvas,
          i.isEven ? ornementPlein : ornementContour,
          Offset.lerp(debut, fin, t)!,
          hauteurRangee ?? hauteur,
          peinture,
          rotation: rotation,
        );
      }
    }

    rangee(
      Offset(reserve, fond + hauteur / 2),
      Offset(size.width - reserve, fond + hauteur / 2),
      math.pi,
    );
    rangee(
      Offset(reserve, size.height - fond - hauteur / 2),
      Offset(size.width - reserve, size.height - fond - hauteur / 2),
      0,
    );
    final double cote = e * 0.3;
    rangee(
      Offset(cote, reserveHaut),
      Offset(cote, size.height - reserveHaut),
      0,
      hauteurRangee: e * 0.56,
      pasRangee: e * 1.5,
    );
    rangee(
      Offset(size.width - cote, reserveHaut),
      Offset(size.width - cote, size.height - reserveHaut),
      0,
      hauteurRangee: e * 0.56,
      pasRangee: e * 1.5,
    );
  }

  /// Le style C : un ornement plein entre deux contours, un filet de chaque
  /// cote, en haut et en bas seulement.
  void _hautEtBas(
    Canvas canvas,
    Size size,
    Paint peinture,
    Paint filet,
    double e,
  ) {
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
        peinture,
        rotation: rotation,
      );
      for (final int sens in <int>[-1, 1]) {
        peindreOrnement(
          canvas,
          ornementContour,
          Offset(centre + sens * ecart, y),
          petite,
          peinture,
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
      ancien.style != style ||
      ancien.epaisseur != epaisseur ||
      ancien.couleur != couleur ||
      ancien.riche != riche;
}

/// Le cartouche d'un nom de sourate : deux filets, et l'ornement de la marque
/// a chaque extremite (contour pour A, plein et contour pour B, plein pour
/// C). Meme couleur et meme regle que le cadre de la page : un dessin dans son
/// propre `RepaintBoundary`.
class FiletsCartoucheMushaf extends StatelessWidget {
  /// Cree le dessin du cartouche.
  const FiletsCartoucheMushaf({
    required this.style,
    required this.couleur,
    super.key,
  });

  /// Le style du cadre de la page, que le cartouche reprend.
  final StyleCadreMushaf style;

  /// L'unique couleur du dessin.
  final Color couleur;

  /// La largeur que prennent les ornements d'une extremite, pour une
  /// hauteur de cartouche [hauteur] : le texte doit rester en dehors.
  static double reserve(StyleCadreMushaf style, double hauteur) {
    final double ornement = hauteur * _partOrnement * ornementPlein.proportion;
    return switch (style) {
      StyleCadreMushaf.b => ornement * 2.3 + hauteur * 0.2,
      _ => ornement * 1.2 + hauteur * 0.2,
    };
  }

  static const double _partOrnement = 0.6;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PeintreCartouche(style: style, couleur: couleur),
      size: Size.infinite,
    ),
  );
}

class _PeintreCartouche extends CustomPainter {
  _PeintreCartouche({required this.style, required this.couleur});

  final StyleCadreMushaf style;
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
    final double reserve = FiletsCartoucheMushaf.reserve(style, h);
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
    for (final int sens in <int>[-1, 1]) {
      // `sens` -1 : extremite gauche ; 1 : extremite droite.
      final double bord = sens < 0 ? 0 : size.width;
      double x(double decalage) => bord - sens * decalage;
      const double tourne = 0;
      switch (style) {
        case StyleCadreMushaf.a:
          peindreOrnement(
            canvas,
            ornementContour,
            Offset(x(h * 0.1 + ow * 0.6), h / 2),
            oh,
            plein,
            rotation: tourne,
          );
        case StyleCadreMushaf.b:
          peindreOrnement(
            canvas,
            ornementPlein,
            Offset(x(h * 0.1 + ow * 0.6), h / 2),
            oh,
            plein,
            rotation: tourne,
          );
          peindreOrnement(
            canvas,
            ornementContour,
            Offset(x(h * 0.1 + ow * 1.7), h / 2),
            oh,
            plein,
            rotation: tourne,
          );
        case StyleCadreMushaf.c:
          peindreOrnement(
            canvas,
            ornementPlein,
            Offset(x(h * 0.1 + ow * 0.6), h / 2),
            oh,
            plein,
            rotation: tourne,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreCartouche ancien) =>
      ancien.style != style || ancien.couleur != couleur;
}
