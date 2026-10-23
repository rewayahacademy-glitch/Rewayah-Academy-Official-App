// Le symbole en contour (grand format decoratif, filigrane de la carte de
// partage) : ses traces sont ceux des SVG du directeur, octet pour octet, a
// jour, et peints dans leur sens d'origine, sans rotation ni miroir.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/contour_traces.g.dart';
import 'package:rewayah_academy/core/marque/dessin_contour.dart';
import 'package:rewayah_academy/core/marque/peinture_contour.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';

import '../../../tool/generer_contour.dart'
    show
        cheminGenere,
        dossiersCouleur,
        fichierContour,
        genererSourceContour,
        lireContour;

/// Un canevas qui note les transformations demandees et les compose dans une
/// matrice, comme le test de l'ornement.
class _CanevasEspion extends Fake implements Canvas {
  final List<String> appels = <String>[];
  final List<Matrix4> pile = <Matrix4>[];
  Matrix4 courante = Matrix4.identity();
  final List<Matrix4> auTrace = <Matrix4>[];
  final List<Paint> peintures = <Paint>[];

  @override
  void save() => pile.add(courante.clone());

  @override
  void restore() => courante = pile.removeLast();

  @override
  void translate(double dx, double dy) {
    appels.add('translate');
    courante = courante.multiplied(Matrix4.translationValues(dx, dy, 0));
  }

  @override
  void scale(double sx, [double? sy]) {
    appels.add('scale');
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
    peintures.add(paint);
  }
}

void main() {
  final String racine = Directory.current.path;

  for (final String dossier in dossiersCouleur) {
    test(
      'symbole-contour.svg ($dossier) : traces identiques octet pour octet',
      () {
        final String svg = File(
          '$racine/assets/brand/logo/$dossier/$fichierContour',
        ).readAsStringSync();
        final List<String> source = <String>[
          for (final RegExpMatch m in RegExp(r'\sd="([^"]*)"').allMatches(svg))
            m.group(1)!,
        ];
        expect(source, symboleContour.traces);
        final RegExpMatch boite = RegExp(r'viewBox="([^"]*)"').firstMatch(svg)!;
        expect(
          boite.group(1),
          '0 0 ${symboleContour.largeur.toInt()} '
          '${symboleContour.hauteur.toInt()}',
        );
        // Un trait, jamais un aplat : l'epaisseur et la jointure du fichier.
        expect(
          RegExp(r'stroke-width="([^"]*)"').firstMatch(svg)!.group(1),
          '${symboleContour.epaisseur.toInt()}',
        );
        expect(svg, contains('stroke-linejoin="round"'));
      },
    );
  }

  test('le symbole genere vient du fichier violet', () {
    expect(
      symboleContour.source,
      'assets/brand/logo/violet/symbole-contour.svg',
    );
  });

  test('les traces tiennent dans le viewBox (trait compris)', () {
    for (final String trace in symboleContour.traces) {
      final Rect t = cheminDepuisTrace(trace).getBounds();
      final double demi = symboleContour.epaisseur / 2;
      expect(t.left - demi, greaterThanOrEqualTo(-1));
      expect(t.top - demi, greaterThanOrEqualTo(-1));
      expect(t.right + demi, lessThanOrEqualTo(symboleContour.largeur + 1));
      expect(t.bottom + demi, lessThanOrEqualTo(symboleContour.hauteur + 1));
    }
  });

  test('le fichier genere est a jour (dart run tool/generer_contour.dart)', () {
    expect(
      File('$racine/$cheminGenere').readAsStringSync(),
      genererSourceContour(racine),
    );
  });

  test('le generateur refuse ce qu il ne reproduirait pas a l identique', () {
    // Un viewBox qui ne part pas de l'origine.
    expect(
      () => lireContour(
        '<svg viewBox="10 0 5 5"><path d="M0 0L1 1Z" stroke="#fff" '
            'stroke-width="1" stroke-linejoin="round"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
    // Une transformation.
    expect(
      () => lireContour(
        '<svg viewBox="0 0 5 5"><path transform="x" d="M0 0L1 1Z" '
            'stroke="#fff" stroke-width="1" stroke-linejoin="round"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
    // Un aplat : le contour est un trait.
    expect(
      () => lireContour(
        '<svg viewBox="0 0 5 5"><path d="M0 0L1 1Z" fill="#fff"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
    // Une jointure autre que ronde.
    expect(
      () => lireContour(
        '<svg viewBox="0 0 5 5"><path d="M0 0L1 1Z" stroke="#fff" '
            'stroke-width="1" stroke-linejoin="miter"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
  });

  group('peindreContour', () {
    test('ni rotation ni miroir : une translation et une echelle homogene', () {
      final _CanevasEspion c = _CanevasEspion();
      peindreContour(
        c,
        symboleContour,
        const Offset(-120, 40),
        648,
        const Color(0x14FFFFFF),
      );
      expect(c.appels, isNot(contains('rotate')));
      expect(c.appels, isNot(contains('skew')));
      expect(c.appels, isNot(contains('transform')));
      expect(c.appels, isNot(contains('clipPath')));
      expect(c.auTrace, hasLength(1), reason: 'un seul trait pour les deux');
      final Matrix4 m = c.auTrace.single;
      expect(m.entry(0, 0), greaterThan(0));
      expect(m.entry(1, 1), greaterThan(0));
      expect(m.entry(0, 0), closeTo(m.entry(1, 1), 1e-9));
      expect(m.entry(1, 0), 0);
      expect(m.entry(0, 1), 0);
      // La largeur demandee, l'origine demandee.
      expect(m.entry(0, 0) * symboleContour.largeur, closeTo(648, 1e-9));
      expect(m.entry(0, 3), -120);
      expect(m.entry(1, 3), 40);
    });

    test('un trait a l\'epaisseur et a la jointure du fichier', () {
      final _CanevasEspion c = _CanevasEspion();
      peindreContour(
        c,
        symboleContour,
        Offset.zero,
        300,
        const Color(0xFFFFFFFF),
      );
      final Paint p = c.peintures.single;
      expect(p.style, PaintingStyle.stroke);
      expect(p.strokeWidth, symboleContour.epaisseur);
      expect(p.strokeJoin, StrokeJoin.round);
    });
  });

  test('la proportion est celle du fichier, 743 x 734', () {
    expect(symboleContour.proportion, closeTo(743 / 734, 1e-12));
    expect(
      const DessinContour(
        source: 'x',
        largeur: 2,
        hauteur: 1,
        epaisseur: 1,
        traces: <String>[],
      ).proportion,
      2,
    );
  });

  // Lu pour que l'import de la peinture ne soit pas retire : la chaine est
  // testee en vrai (une image se peint sans lever).
  test('peindre sur un vrai canevas ne leve pas', () {
    final ui.PictureRecorder enregistreur = ui.PictureRecorder();
    final Canvas canevas = Canvas(enregistreur);
    peindreContour(
      canevas,
      symboleContour,
      Offset.zero,
      400,
      const Color(0xFFFFFFFF),
    );
    final ui.Picture image = enregistreur.endRecording();
    expect(image.approximateBytesUsed, greaterThan(0));
    image.dispose();
  });
}
