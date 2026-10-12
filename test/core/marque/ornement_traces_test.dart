import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/dessin_ornement.dart';
import 'package:rewayah_academy/core/marque/ornement_traces.g.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';

import '../../../tool/generer_ornement.dart'
    show cheminGenere, dossiersCouleur, genererSourceOrnement, lireOrnement;

/// Les traces generees de l'ornement (BRAND-ORN-1) : octet pour octet ceux des
/// SVG du directeur, a jour, et contenus dans leur `viewBox`.
const Map<String, DessinOrnement> _generes = <String, DessinOrnement>{
  'ornement-plein.svg': ornementPlein,
  'ornement-contour.svg': ornementContour,
};

void main() {
  final String racine = Directory.current.path;

  for (final MapEntry<String, DessinOrnement> e in _generes.entries) {
    for (final String dossier in dossiersCouleur) {
      test('${e.key} ($dossier) : traces identiques octet pour octet', () {
        final String svg = File('$racine/assets/brand/logo/$dossier/${e.key}')
            .readAsStringSync();
        final List<String> source = <String>[
          for (final RegExpMatch m in RegExp(r'\sd="([^"]*)"').allMatches(svg))
            m.group(1)!,
        ];
        // Le contour porte son masque en premier, puis le trace peint.
        expect(source, <String>[?e.value.masque, e.value.trace]);
        final RegExpMatch boite = RegExp(r'viewBox="([^"]*)"').firstMatch(svg)!;
        expect(
          boite.group(1),
          '0 0 ${e.value.largeur.toInt()} ${e.value.hauteur.toInt()}',
        );
        expect(e.value.source, 'assets/brand/logo/violet/${e.key}');
      });
    }

    test('${e.key} : les traces tiennent dans le viewBox', () {
      final Rect b = cheminDepuisTrace(e.value.trace).getBounds();
      // Le contour deborde de 0,14 en bas : son masque couvre -1 a +1.
      const double tolerance = 1;
      expect(b.left, greaterThanOrEqualTo(-tolerance));
      expect(b.top, greaterThanOrEqualTo(-tolerance));
      expect(b.right, lessThanOrEqualTo(e.value.largeur + tolerance));
      expect(b.bottom, lessThanOrEqualTo(e.value.hauteur + tolerance));
    });
  }

  test('le contour porte un masque, le plein non', () {
    expect(ornementContour.masque, isNotNull);
    expect(ornementPlein.masque, isNull);
  });

  test(
    'le fichier genere est a jour (dart run tool/generer_ornement.dart)',
    () {
      expect(
        File('$racine/$cheminGenere').readAsStringSync(),
        genererSourceOrnement(racine),
      );
    },
  );

  test('le generateur refuse ce qu il ne reproduirait pas a l identique', () {
    expect(
      () => lireOrnement(
        '<svg viewBox="10 0 5 5"><path d="M0 0L1 1Z"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
    expect(
      () => lireOrnement(
        '<svg viewBox="0 0 5 5"><path transform="x" d="M0 0L1 1Z"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
  });
}
