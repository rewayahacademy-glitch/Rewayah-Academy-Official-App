import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/ornement_traces.g.dart';
import 'package:rewayah_academy/core/marque/peinture_ornement.dart';
import 'package:rewayah_academy/features/tc_mushaf/cadre_ornement.dart';

/// Un canevas qui note les transformations demandees et les compose dans une
/// matrice : l'ornement doit rester dans le sens du SVG (decision du
/// directeur, 11/10/2026).
class _CanevasEspion extends Fake implements Canvas {
  final List<String> appels = <String>[];
  final List<Matrix4> pile = <Matrix4>[];
  Matrix4 courante = Matrix4.identity();

  /// Les matrices en vigueur a chaque trace dessine.
  final List<Matrix4> auTrace = <Matrix4>[];

  @override
  void save() {
    pile.add(courante.clone());
  }

  @override
  void restore() {
    courante = pile.removeLast();
  }

  @override
  void translate(double dx, double dy) {
    appels.add('translate');
    courante = courante.multiplied(Matrix4.translationValues(dx, dy, 0));
  }

  @override
  void scale(double sx, [double? sy]) {
    appels.add('scale');
    expect(sx, greaterThan(0), reason: 'echelle negative = miroir');
    expect(sy ?? sx, greaterThan(0), reason: 'echelle negative = miroir');
    courante = courante.multiplied(Matrix4.diagonal3Values(sx, sy ?? sx, 1));
  }

  @override
  void rotate(double radians) => appels.add('rotate');

  @override
  void skew(double sx, double sy) => appels.add('skew');

  @override
  void transform(Float64List matrix4) => appels.add('transform');

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) =>
      appels.add('clipPath');

  @override
  void drawPath(ui.Path path, Paint paint) {
    appels.add('drawPath');
    auTrace.add(courante.clone());
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => appels.add('drawLine');
}

void _verifierSensOrigine(_CanevasEspion c) {
  expect(c.appels, isNot(contains('rotate')));
  expect(c.appels, isNot(contains('skew')));
  expect(c.appels, isNot(contains('transform')));
  expect(c.auTrace, isNotEmpty);
  for (final Matrix4 m in c.auTrace) {
    // Matrice affine 2D : [a c . tx; b d . ty].
    final double a = m.entry(0, 0);
    final double b = m.entry(1, 0);
    final double cc = m.entry(0, 1);
    final double d = m.entry(1, 1);
    expect(a, greaterThan(0), reason: 'echelle horizontale positive');
    expect(d, greaterThan(0), reason: 'echelle verticale positive');
    expect(b, 0, reason: 'aucune rotation');
    expect(cc, 0, reason: 'aucune rotation');
    expect(a, closeTo(d, 1e-9), reason: 'echelle homogene');
  }
}

void main() {
  for (final String nom in <String>['plein', 'contour']) {
    test('peindreOrnement ($nom) : ni rotation ni miroir', () {
      final _CanevasEspion c = _CanevasEspion();
      peindreOrnement(
        c,
        nom == 'plein' ? ornementPlein : ornementContour,
        const Offset(100, 50),
        24,
        Paint(),
      );
      _verifierSensOrigine(c);
      // Le dessin est pose au centre demande, a la hauteur demandee.
      final Matrix4 m = c.auTrace.single;
      expect(
        m.entry(1, 1) *
            (nom == 'plein' ? ornementPlein.hauteur : ornementContour.hauteur),
        closeTo(24, 1e-9),
      );
    });
  }

  testWidgets(
    'le cadre du Coran peint tous ses ornements dans le sens du SVG',
    (WidgetTester tester) async {
      for (final TextDirection sens in TextDirection.values) {
        await tester.pumpWidget(
          Directionality(
            textDirection: sens,
            child: const SizedBox(
              width: 390,
              height: 700,
              child: CadreMushaf(
                geometrie: GeometrieCadreMushaf(hauteurPage: 700),
                couleur: Colors.black,
              ),
            ),
          ),
        );
        final CustomPaint peint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(CadreMushaf),
            matching: find.byType(CustomPaint),
          ),
        );
        final _CanevasEspion c = _CanevasEspion();
        peint.painter!.paint(c, const Size(390, 700));
        _verifierSensOrigine(c);
        // Six ornements (un plein et deux contours, en haut et en bas).
        expect(c.auTrace, hasLength(6));
      }
    },
  );

  testWidgets('le cartouche : meme regle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 300,
              height: 40,
              child: FiletsCartoucheMushaf(couleur: Colors.black),
            ),
          ],
        ),
      ),
    );
    for (final CustomPaint peint in tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    )) {
      if (peint.painter == null) continue;
      final _CanevasEspion c = _CanevasEspion();
      peint.painter!.paint(
        c,
        peint.size.isFinite ? peint.size : const Size(300, 40),
      );
      if (c.auTrace.isEmpty) continue;
      _verifierSensOrigine(c);
    }
  });
}
