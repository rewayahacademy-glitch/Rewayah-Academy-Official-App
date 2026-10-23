import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/dessin_logo.dart';
import 'package:rewayah_academy/core/marque/logo_traces.g.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';

import '../../../tool/generer_logo.dart'
    show cheminGenere, dossiersCouleur, genererSourceLogo, lireSvgLivre;

/// Les traces generees du logo (LOGO-APP) : octet pour octet ceux des SVG du
/// directeur, a jour, et contenus dans leur `viewBox`.
const Map<String, DessinLogo> _generes = <String, DessinLogo>{
  'logo-horizontal.svg': logoHorizontal,
  'logo-vertical.svg': logoVertical,
  'symbole-plein.svg': logoSymbole,
};

void main() {
  final String racine = Directory.current.path;

  for (final MapEntry<String, DessinLogo> e in _generes.entries) {
    for (final String dossier in dossiersCouleur) {
      test('${e.key} ($dossier) : traces identiques octet pour octet', () {
        final String svg = File('$racine/assets/brand/logo/$dossier/${e.key}')
            .readAsStringSync();
        // Lecture independante du generateur : chaque attribut d="...".
        final List<String> source = <String>[
          for (final RegExpMatch m in RegExp(r'\sd="([^"]*)"').allMatches(svg))
            m.group(1)!,
        ];
        expect(e.value.traces, source);
        final RegExpMatch boite = RegExp(r'viewBox="([^"]*)"').firstMatch(svg)!;
        expect(
          boite.group(1),
          '0 0 ${e.value.largeur.toInt()} ${e.value.hauteur.toInt()}',
        );
        expect(e.value.pairImpair, svg.contains('fill-rule="evenodd"'));
        expect(e.value.source, 'assets/brand/logo/violet/${e.key}');
      });
    }

    test('${e.key} : les traces tiennent dans le viewBox et le touchent', () {
      Rect? union;
      for (final String d in e.value.traces) {
        final Rect b = cheminDepuisTrace(d).getBounds();
        union = union == null ? b : union.expandToInclude(b);
      }
      // Dans la boite, jamais au-dela (au demi-point d'arrondi pres) ...
      const double tolerance = 0.5;
      expect(union!.left, greaterThanOrEqualTo(-tolerance));
      expect(union.top, greaterThanOrEqualTo(-tolerance));
      expect(union.right, lessThanOrEqualTo(e.value.largeur + tolerance));
      expect(union.bottom, lessThanOrEqualTo(e.value.hauteur + tolerance));
      // ... et la remplissant : le dessin livre touche au moins trois bords
      // et laisse moins de 0,5 % de la boite de chaque cote (le mot-marque
      // des logos s'arrete a un point du bord droit dans la source).
      expect(union.width / e.value.largeur, greaterThan(0.995));
      expect(union.height / e.value.hauteur, greaterThan(0.995));
    });
  }

  test('le fichier genere est a jour (dart run tool/generer_logo.dart)', () {
    expect(
      File('$racine/$cheminGenere').readAsStringSync(),
      genererSourceLogo(racine),
    );
  });

  test('le generateur refuse ce qu il ne reproduirait pas a l identique', () {
    expect(
      () => lireSvgLivre(
        '<svg viewBox="10 0 5 5"><path d="M0 0L1 1Z"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
    expect(
      () => lireSvgLivre(
        '<svg viewBox="0 0 5 5"><path transform="scale(2)" d="M0 0Z"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
    expect(
      () => lireSvgLivre(
        '<svg viewBox="0 0 5 5"><path d="M0 0A1 1 0 0 1 2 2"/></svg>',
        'x',
      ),
      throwsFormatException,
    );
  });
}
